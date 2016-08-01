#!/bin/bash
set -e

# Constants
bintray_user=$BINTRAY_SNOWPLOW_GENERIC_USER
bintray_repository=snowplow/snowplow-generic
scala_version=2.10
dist_path=dist
root=$(pwd)

# Next four arrays MUST match up: number of elements and order
declare -a kinesis_app_packages=( "snowplow-scala-stream-collector" "snowplow-stream-enrich" "snowplow-kinesis-elasticsearch-sink")
declare -a kinesis_app_paths=( "2-collectors/scala-stream-collector" "3-enrich/stream-enrich" "4-storage/kinesis-elasticsearch-sink" )
declare -a kinesis_fatjars=( "snowplow-stream-collector" "snowplow-stream-enrich" "snowplow-elasticsearch-sink" )
# TODO: version numbers shouldn't be hard-coded
declare -a kinesis_app_versions=( "0.7.0" "0.8.1" "0.7.0-rc1")

# Similar to Perl die
function die() {
    echo "$@" 1>&2 ; exit 1;
}

# Go to parent-parent dir of this script
function cd_root() {
    cd $root
}

# Assemble our fat jars
function assemble_fatjars() {
    for kinesis_app_path in "${kinesis_app_paths[@]}"
        do
            :
            app="${kinesis_app_path##*/}"
            echo "================================================"
            echo "ASSEMBLING FATJAR FOR ${app}"
            echo "------------------------------------------------"
            cd ${kinesis_app_path} && sbt assembly
            cd_root
        done
}

# Create our version in BinTray. Does nothing
# if the version already exists
#
# Parameters:
# 1. out_error (out parameter)
function create_bintray_packages() {
    [ "$#" -eq 1 ] || die "1 arguments required, $# provided"
    local __out_error=$1

    for i in "${!kinesis_app_packages[@]}"
        do
            :
            package_name="${kinesis_app_packages[$i]}"
            package_version="${kinesis_app_versions[$i]}"
            echo "========================================"
            echo "CREATING BINTRAY VERSION ${package_version} in package ${package_name} *"
            echo "* if it doesn't already exist"
            echo "----------------------------------------"

            http_status=`echo '{"name":"'${package_version}'","desc":"Release of '${package_name}'"}' | curl -d @- \
                "https://api.bintray.com/packages/${bintray_repository}/${package_name}/versions" \
                --write-out "%{http_code}\n" --silent --output /dev/null \
                --header "Content-Type:application/json" \
                -u${bintray_user}:${bintray_api_key}`

            http_status_class=${http_status:0:1}
            ok_classes=("2" "3")

            if [ ${http_status} == "409" ] ; then
                echo "... version ${package_version} in package ${package_name} already exists, skipping."
            elif [[ ! ${ok_classes[*]} =~ ${http_status_class} ]] ; then
                eval ${__out_error}="'BinTray API response ${http_status} is not 409 (package already exists) nor in 2xx or 3xx range'"
                break
            fi
        done
}

# Zips all of our applications
#
# Parameters:
# 1. out_artifact_names (out parameter)
# 2. out_artifact_paths (out parameter)
function build_artifacts() {
    [ "$#" -eq 2 ] || die "2 arguments required, $# provided"
    local __out_artifact_names=$1
    local __out_artifact_paths=$2

    echo "==========================================="
    echo "BUILDING ARTIFACTS"
    echo "-------------------------------------------"

    artifact_names=()
    artifact_paths=()

    for i in "${!kinesis_app_paths[@]}"
        do 
            :
            kinesis_fatjar="${kinesis_fatjars[$i]}-${kinesis_app_versions[$i]}"

            # Create artifact folder
            artifact_root="${kinesis_fatjar}"
            artifact_name=`echo ${kinesis_fatjar}.zip|tr '-' '_'`
            artifact_folder=./${dist_path}/${artifact_root}
            mkdir -p ${artifact_folder}

            # Copy artifact to folder
            fatjar_path="./${kinesis_app_paths[$i]}/target/scala-${scala_version}/${kinesis_fatjar}"
            [ -f "${fatjar_path}" ] || die "Cannot find required fatjar: ${fatjar_path}. Did you forget to update fatjar versions?"
            cp ${fatjar_path} ${artifact_folder}

            # Zip artifact
            artifact_path=./${dist_path}/${artifact_name}
            zip -rj ${artifact_path} ${artifact_folder}

            artifact_names+=($artifact_name)
            artifact_paths+=($artifact_path)
        done

    eval ${__out_artifact_names}=${artifact_names}
    eval ${__out_artifact_paths}=${artifact_paths}
}

# Uploads our artifact to BinTray
#
# Parameters:
# 1. artifact_names
# 2. artifact_paths
# 3. out_error (out parameter)
function upload_artifacts_to_bintray() {
    [ "$#" -eq 3 ] || die "3 arguments required, $# provided"
    local __artifact_names=$1[@]
    local __artifact_paths=$2[@]
    local __out_error=$3

    artifact_names=("${!__artifact_names}")
    artifact_paths=("${!__artifact_paths}")

    echo "==============================="
    echo "UPLOADING ARTIFACTS TO BINTRAY*"
    echo "* 5-10 minutes"
    echo "-------------------------------"

    for i in "${!artifact_names[@]}"
        do
            :
            package_name="${kinesis_app_packages[$i]}"
            package_version="${kinesis_app_versions[$i]}"

            echo "Uploading ${artifact_names[$i]} to package ${package_name} under version ${package_version}..."  

            # Check if version already exists
            uploaded_file_count=`curl \
                "https://api.bintray.com/packages/${bintray_repository}/${package_name}/versions/${package_version}/files/" \
                -u${bintray_user}:${bintray_api_key} | python -c 'import json,sys;obj=json.load(sys.stdin);print len(obj)'`

            # If return code is 2xx or 3xx validate that uploaded version is equivalent
            # to local version
            if [ "${uploaded_file_count}" -ne "0" ] ; then

                echo "Artifact already uploaded; validating local and remote..."

                remote_zip_path="./${dist_path}/temp_${artifact_names[$i]}"
                remote_zip_url="https://bintray.com/${bintray_repository}/download_file?file_path=${artifact_names[$i]}"

                wget -O ${remote_zip_path} ${remote_zip_url}
                zipcmp ${remote_zip_path} ${artifact_paths[$i]}
                cmp_result=`echo $?`

                if [ "${cmp_result}" -ne "0" ]
                    then
                        eval ${__out_error}="'Uploaded file for version ${package_version} in package ${package_name} does not match local zip.'"
                        break
                else
                    echo "Local and remote are the same, skipping upload."
                fi
                continue
            fi

            # If file not yet uploaded
            http_status=`curl -T ${artifact_paths[$i]} \
                "https://api.bintray.com/content/${bintray_repository}/${package_name}/${package_version}/${artifact_names[$i]}?publish=1&override=0" \
                -H "Transfer-Encoding: chunked" \
                --write-out "%{http_code}\n" --silent --output /dev/null \
                -u${bintray_user}:${bintray_api_key}`

            http_status_class=${http_status:0:1}
            ok_classes=("2" "3")

            if [[ ! ${ok_classes[*]} =~ ${http_status_class} ]] ; then
                eval ${__out_error}="'BinTray API response ${http_status} is not in 2xx or 3xx range'"
                break
            fi
        done
}


cd_root

bintray_api_key=$BINTRAY_SNOWPLOW_GENERIC_API_KEY

assemble_fatjars

create_bintray_packages "error"
[ "${error}" ] && die "Error creating package: ${error}"

artifact_names=() && artifact_paths=() && build_artifacts "artifact_names" "artifact_paths"

upload_artifacts_to_bintray "artifact_names" "artifact_paths" "error"
if [ "${error}" != "" ]; then
    die "Error uploading package: ${error}"
fi
