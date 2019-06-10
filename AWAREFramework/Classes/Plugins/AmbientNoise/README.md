AWARE: Ambient Noise
====================

This plugin measures the ambient noise (Hz, dB) as noisy or silent moments. It adds the daily noise exposure on the stream, showing the average dB and Hz per hour throughout the day.

# Settings
- **status_plugin_ambient_noise**: (boolean) activate/deactivate ambient noise plugin
- **frequency_plugin_ambient_noise**: (integer) interval between audio data snippets, in minutes. Recommended value is every 5 minutes or higher.
- **plugin_ambient_noise_sample_size**: (integer) For how long we collect data, in seconds
- **plugin_ambient_noise_silence_threshold**: (integer) How many dB is a noisy environment?
- **plugin_ambient_noise_no_raw**: (boolean) to enable/disable raw audio recordings. By default, the plugin records the audio snippet. Enabling this, disables that.
    
# Providers
##  Ambient Noise Data

Field | Type | Description
----- | ---- | -----------
_id | INTEGER | primary key auto-incremented
timestamp | REAL | unix timestamp in milliseconds of sample
device_id | TEXT | AWARE device ID
double_frequency | REAL | sound frequency in Hz
double_decibels	| REAL | sound decibels in dB
double_rms | REAL |	sound RMS
is_silent |	INTEGER | 0 = not silent 1 = is silent
double_silence_threshold | REAL | the used threshold when classifying between silent vs not silent
raw | BLOB | the audio snippet raw data collected
