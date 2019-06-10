AWARE Plugin: Fused Location
===================================

This is the 

# Settings
Parameters adjusted on the dashboard and client:
* **status_google_fused_location**: (boolean) activate/deactivate plugin
* **frequency_google_fused_location**: (integer) How frequently to fetch user's location (in seconds), default 300 seconds
* **max_frequency_google_fused_location**: (integer) How fast are you willing to get the latest location (in seconds), default 60 seconds
* **accuracy_google_fused_location**: (integer) One of the following:
    * 100 (high power): uses GPS only - works best outdoors, highest accuracy
    * 102 (balanced): uses GPS, Network and Wifi - works both indoors and outdoors, good accuracy (default)
    * 104 (low power): uses only Network and WiFi - poorest accuracy, medium accuracy
    * 105 (no power) - scavenges location requests from other apps

# Providers
##  Locations Data
Field | Type | Description
----- | ---- | -----------
_id | INTEGER | primary key auto-incremented
timestamp | REAL | unix timestamp in milliseconds of sample
device_id | TEXT | AWARE device ID
double_latitude | REAL | the location’s latitude, in degrees
double_longitude	| REAL | the location’s longitude, in degrees
double_bearing | REAL |	the location’s bearing, in degrees
double_speed |	REAL | the speed if available, in meters/second over ground
double_altitude | REAL | the altitude if available, in meters above sea level
provider | TEXT | gps, network, fused (this column is not suppored on iOS)
accuracy | INTEGER | the estimated location accuracy
label | TEXT | Customizable label. Useful for data calibration and traceability

##  Visit
Field | Type | Description
----- | ---- | -----------
_id | INTEGER | primary key auto-incremented
timestamp | REAL | unix timestamp in milliseconds of sample
device_id | TEXT | AWARE device ID
accuracy  | REAL | the estimated location accuracy measured in meters
double_latitude | REAL | the location’s latitude, in degrees
double_longitude | REAL | the location’s longitude, in degrees
provider | TEXT | gps, network, fused (this column is not suppored on iOS)
name | TEXT | a name of the visited place
address | TEXT | an address of the visited place
double_departure | REAL | unix timestamp in milliseconds
double_arrival | REAL | unix timestamp in milliseconds
label | TEXT | Customizable label. Useful for data calibration and traceability
