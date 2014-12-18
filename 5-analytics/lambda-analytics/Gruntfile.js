module.exports = function (grunt) {
    grunt.loadNpmTasks('grunt-typescript');
    grunt.loadNpmTasks('grunt-tsd');
    grunt.loadNpmTasks('grunt-contrib-watch');
 
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        typescript: {
            base: {
                src: ['lib/**/*.ts'],
                dest: 'js/analytics.js',
                options: {
                    module: 'amd',
                    target: 'es5'
                }
            }
        },
        watch: {
            files: '**/*.ts',
            tasks: ['typescript']
        },
        tsd: {
            refresh: {
                options: {
                    // execute a command
                    command: 'reinstall',

                    //optional: always get from HEAD
                    latest: true,

                    // specify config file
                    config: 'tsd.json',

                    // experimental: options to pass to tsd.API
                    opts: {
                        // props from tsd.Options
                    }
                }
            }
        }
    });
 
    grunt.registerTask('default', ['watch']);
 
}
