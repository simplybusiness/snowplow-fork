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
 * This is the Snowplow enriched event. Note that because unstruct_event and contexts
 * are set to any, this interface works for both pre- and post-shredded events.
 */
interface EnrichedEvent {

  // The application (site, game, app etc) this event belongs to, and the tracker platform
  app_id: string;
  platform: string;

  // Date/time
  etl_tstamp: string;
  collector_tstamp: string;
  dvce_tstamp: string;

  // Transaction (i.e. this logging event)
  event: string;
  event_id: string;
  txn_id: string;

  // Versioning
  name_tracker: string;
  v_tracker: string;
  v_collector: string;
  v_etl: string;

  // User and visit
  user_id: string;
  user_ipaddress: string;
  user_fingerprint: string;
  domain_userid: string;
  domain_sessionidx: number;
  network_userid: string;

  // Location
  geo_country: string;
  geo_region: string;
  geo_city: string;
  geo_zipcode: string;
  geo_latitude: number;
  geo_longitude: number;
  geo_region_name: string;

  // Other IP lookups
  ip_isp: string;
  ip_org: string;
  ip_domain: string;
  ip_netspeed: string;

  // Page
  page_url: string;
  page_title: string;
  page_referrer: string;

  // Page URL components
  page_urlscheme: string;  
  page_urlhost: string;   
  page_urlport: number; 
  page_urlpath: string;
  page_urlquery: string;
  page_urlfragment: string;

  // Referrer URL components
  refr_urlscheme: string;  
  refr_urlhost: string;   
  refr_urlport: number; 
  refr_urlpath: string;
  refr_urlquery: string;
  refr_urlfragment: string;  

  // Referrer details
  refr_medium: string;
  refr_source: string;
  refr_term: string;

  // Marketing
  mkt_medium: string;
  mkt_source: string;
  mkt_term: string;
  mkt_content: string;
  mkt_campaign: string;

  // Custom Contexts
  contexts: any;

  // Structured Event
  se_category: string;
  se_action: string;
  se_label: string;
  se_property: string;
  se_value: number;

  // Unstructured Event
  unstruct_event: any;

  // Ecommerce transaction (from querystring)
  tr_orderid: string;
  tr_affiliation: string;
  tr_total: string;
  tr_tax: string;
  tr_shipping: string;
  tr_city: string;
  tr_state: string;
  tr_country: string;

  // Ecommerce transaction item (from querystring)
  ti_orderid: string;
  ti_sku: string;
  ti_name: string;
  ti_category: string;
  ti_price: string;
  ti_quantity: string;

  // Page Pings
  pp_xoffset_min: number;
  pp_xoffset_max: number;
  pp_yoffset_min: number;
  pp_yoffset_max: number;
  
  // User Agent
  useragent: string;

  // Browser (from user-agent)
  br_name: string;
  br_family: string;
  br_version: string;
  br_type: string;
  br_renderengine: string;

  // Browser (from querystring)
  br_lang: string;
  // Individual feature fields for non-Hive targets (e.g. Infobright)
  br_features_pdf: boolean;
  br_features_flash: boolean;
  br_features_java: boolean;
  br_features_director: boolean;
  br_features_quicktime: boolean;
  br_features_realplayer: boolean;
  br_features_windowsmedia: boolean;
  br_features_gears: boolean;
  br_features_silverlight: boolean;
  br_cookies: boolean;
  br_colordepth: string;
  br_viewwidth: number;
  br_viewheight: number;

  // OS (from user-agent)
  os_name: string;
  os_family: string;
  os_manufacturer: string;
  os_timezone: string;

  // Device/Hardware (from user-agent)
  dvce_type: string;
  dvce_ismobile: boolean;

  // Device (from querystring)
  dvce_screenwidth: number;
  dvce_screenheight: number;

  // Document
  doc_charset: string;
  doc_width: number;
  doc_height: number;
}

function shredder(event : EnrichedEvent) {
    return "Hello, " + event.app_id;
}

var event = {app_id: "1"};

document.body.innerHTML = shredder(event);
