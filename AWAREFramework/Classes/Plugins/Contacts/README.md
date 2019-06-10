AWARE: Contacts List
====================

Collects a snapshot of participants' contact list information on a daily basis.

# Settings
- **status_plugin_contacts**: (boolean) activate/deactivate plugin
- **frequency_plugin_contacts**: (integer) interval between data snippets, in days. Default is every 1 day.
    
# Providers
## Contacts List

Field | Type | Description
----- | ---- | -----------
_id | INTEGER | primary key auto-incremented
timestamp | REAL | unix timestamp in milliseconds of sample
device_id | TEXT | AWARE device ID
name | TEXT | contact's name
phone_numbers	| TEXT | a JSONArray with all assigned phone numbers as a JSONObject {'type', 'number', 'hash'} where hash is the same as in call logs.
emails | TEXT |	a JSONArray with all assigned emails as a JSONObject {'type', 'email'}
groups |	TEXT | a JSONArray with all assigned contact groups with JSONObject {'type'}
sync_date | REAL | timestamp of snapshot
