/*
 * Copyright (c) 2012-2014 Snowplow Analytics Ltd. All rights reserved.
 *
 * This program is licensed to you under the Apache License Version 2.0,
 * and you may not use this file except in compliance with the Apache License Version 2.0.
 * You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the Apache License Version 2.0 is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.
 */
package com.snowplowanalytics.snowplow.enrich
package hadoop
package good

// Scala
import scala.collection.mutable.Buffer

// Specs2
import org.specs2.mutable.Specification

// Scalding
import com.twitter.scalding._

// Cascading
import cascading.tuple.TupleEntry

// This project
import JobSpecHelpers._

/**
 * Holds the input and expected data
 * for the test.
 */
object CljTomcatMailchimpEventSpec {

  val lines = Lines(
    "2014-10-09  16:28:31    -   13  255.255.255.255   POST    255.255.255.255   /com.mailchimp/v1   404 -  -    aid=email&cv=clj-0.6.0-tom-0.0.4&nuid=-   -   -   -   application%2Fx-www-form-urlencoded   dHlwZT1zdWJzY3JpYmUmZmlyZWRfYXQ9MjAxNC0xMS0wNCswOSUzQTQyJTNBMzEmZGF0YSU1QmlkJTVEPWU3Yzc3ZDM4NTImZGF0YSU1QmVtYWlsJTVEPWFnZW50c21pdGglNDBzbm93cGxvd3Rlc3QuY29tJmRhdGElNUJlbWFpbF90eXBlJTVEPWh0bWwmZGF0YSU1QmlwX29wdCU1RD04Mi4yMjUuMTY5LjIyMCZkYXRhJTVCd2ViX2lkJTVEPTIxMDgzMzgyNSZkYXRhJTVCbWVyZ2VzJTVEJTVCRU1BSUwlNUQ9YWdlbnRzbWl0aCU0MHNub3dwbG93dGVzdC5jb20mZGF0YSU1Qm1lcmdlcyU1RCU1QkZOQU1FJTVEPUFnZW50JmRhdGElNUJtZXJnZXMlNUQlNUJMTkFNRSU1RD1TbWl0aCZkYXRhJTVCbGlzdF9pZCU1RD1mMTI0M2EzYjEy"
    )

  val expected = List(
    "email",
    "srv",
    EtlTimestamp,
    "2014-10-09 16:28:31.000",
    null,
    "unstruct",
    null, // We can't predict the event_id
    null,
    null, // No tracker namespace
    "com.mailchimp-v1",
    "clj-0.6.0-tom-0.0.4",
    EtlVersion,
    null, // No user_id set
    "255.255.x.x",
    null,
    null,
    null,
    "-", // TODO: fix this, https://github.com/snowplow/snowplow/issues/1133
    null, // No geo-location for this IP address
    null,
    null,
    null,
    null,
    null,
    null,
    null, // No additional MaxMind databases used
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null, // Marketing campaign fields empty
    null, //
    null, //
    null, //
    null, //
    null, // No custom contexts
    null, // Structured event fields empty
    null, //
    null, //
    null, //
    null, //
    """{"schema":"iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0","data":{"schema":"iglu:com.mailchimp/subscribe/jsonschema/1-0-0","data":{"data":{"ip_opt":"82.225.169.220","merges":{"LNAME":"Smith","FNAME":"Agent","EMAIL":"agentsmith@snowplowtest.com"},"email":"agentsmith@snowplowtest.com","list_id":"f1243a3b12","email_type":"html","id":"e7c77d3852","web_id":"210833825"},"fired_at":"2014-11-04T09:42:31.000Z","type":"subscribe"}}}""",
    null, // Transaction fields empty
    null, //
    null, //
    null, //
    null, //
    null, //
    null, //
    null, //
    null, // Transaction item fields empty
    null, //
    null, //
    null, //
    null, //
    null, //
    null, // Page ping fields empty
    null, //
    null, //
    null, //
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null
    )
}

/**
 * Integration test for the EtlJob:
 *
 * For details:
 * https://forums.aws.amazon.com/thread.jspa?threadID=134017&tstart=0#
 */
class CljTomcatMailchimpEventSpec extends Specification {

  "A job which processes a Clojure-Tomcat file containing a POST raw event representing 1 valid completed call" should {
    EtlJobSpec("clj-tomcat", "2", true, List("geo")).
      source(MultipleTextLineFiles("inputFolder"), CljTomcatMailchimpEventSpec.lines).
      sink[TupleEntry](Tsv("outputFolder")){ buf : Buffer[TupleEntry] =>
        "correctly output 1 completed call" in {
          buf.size must_== 1
          val actual = buf.head
          for (idx <- CljTomcatMailchimpEventSpec.expected.indices) {
            actual.getString(idx) must beFieldEqualTo(CljTomcatMailchimpEventSpec.expected(idx), withIndex = idx)
          }
        }
      }.
      sink[TupleEntry](Tsv("exceptionsFolder")){ trap =>
        "not trap any exceptions" in {
          trap must beEmpty
        }
      }.
      sink[String](Tsv("badFolder")){ error =>
        "not write any bad rows" in {
          error must beEmpty
        }
      }.
      run.
      finish
  }
}