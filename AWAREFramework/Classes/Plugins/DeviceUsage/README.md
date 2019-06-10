AWARE Plugin: Device Usage
==========================

This plugin measures the device usage and non-usage sessions.

# Settings
Parameters adjustable on the dashboard and client:
- **status_plugin_device_usage**: (boolean) activate/deactivate plugin

# Providers
##  Device Usage Data

Field | Type | Description
----- | ---- | -----------
_id | INTEGER | primary key auto-incremented
timestamp | REAL | unix timestamp in milliseconds of sample
device_id | TEXT | AWARE device ID
double_elapsed_device_on | REAL | amount of time the device was on (milliseconds)
double_elapsed_device_off	| REAL | amount of time the device was off (milliseconds)
