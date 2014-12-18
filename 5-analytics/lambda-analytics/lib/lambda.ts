/*
 * Copyright (c) 2012-2015 Snowplow Analytics Ltd. All rights reserved.
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

/**
 * A Kinesis record. Note that data is
 * Base64-encoded.
 */
class KinesisRecord {
  data: string;

  decode() {
    new Buffer(this.data, 'base64').toString('ascii')
  }
}

/**
 * A Lambda record.
 */
interface LambdaRecord {
  eventID: string;
  eventName: string;
  kinesis?: KinesisRecord;
  s3?: any;
  Dynamodb?: any;
}

/**
 * A Lambda event could consist
 * of N Lambda records, or it could
 * just be a user application event,
 * which takes any structure.
 *
 * WARNING: we don't handle the edge case
 * where a user sends in a user application event
 * where Records is not an array.
 */
interface LambdaEvent {
	Records?: Array<any>;
}
