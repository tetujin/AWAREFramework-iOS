AWARE Plugin: Conversations
=========================================

This plugin detects if the user is engaged in a conversation or not. It follows a duty cycle of 1 minute audio collection, 3 minutes pause. It does not store the raw audio (it's disabled). 
This plugin was developed as a collaboration between Cornell and Dartmouth College for the StudentLife project and later extended to support the converstations start/end at the Center for Ubiquitous Computing at the University of Oulu.

# Settings
Parameters adjustable on the dashboard and client: 
- **status_plugin_studentlife_audio**: (boolean) activate/deactivate plugin

# Providers
## Conversations Data

Field | Type | Description
----- | ---- | -----------
_id | INTEGER | primary key auto-incremented
timestamp | REAL | unix timestamp in milliseconds of sample
device_id | TEXT | AWARE device ID
datatype | INTEGER |    identifier for what is in blob_feature: 0 = voice/noise and volume, 1 = audio features, 2 = conversations.
double_energy | REAL |  amplitude of audio sample (L2-norm of the audio frame)
inference | INTEGER |   0 = silence, 1 = noise, 2 = voice, 3 = unknown
blob_feature | BLOB |   audio raw sample. not stored by default (would be huge!)
double_convo_start | REAL | UNIX timestamp of beginning of sample (if datatype = 2)
double_convo_end | REAL |   UNIX timestamp of ending of sample (if datatype = 2)
