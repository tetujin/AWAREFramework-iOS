AWARE Plugin: Shared Google Calendar"s ESM Scheduler
==========================

This plugin allows you to schedule ESMs using a shared Google Calendar with your study participants. This plugin reads the events of a shared Google calendar. 

**Direct sharing** 
- Share the calendar directly with your participants" google account email address (automatically added to their calendar)

**Indirect sharing**
- Participants subscribe to your public shared calendar (you need to give them the calendar ical address).

This plugin assumes the following:
- You have a Google Calendar with the name "AWARE*" where * can be any string you want to distinguish between studies or groups of participants
- The event **title** starts with "ESM*" where * is the title is unique within a day schedule, to distinguish between different sets of questions
- The event **description** is the actual ESM JSON queue, with 1 or more questions (i.e., a JSONArray with ESM JSONObjects) (see [here](http://www.awareframework.com/esm/) for ESM documentation about the JSON structure and options). For example, here we are asking the users to rate their daily productivity using 1 ESM JSONObject of type 4 (i.e., Likert), with a 5-point scale:

```
[
{"esm":
{"esm_type":4,
"esm_likert_max":5,
"esm_likert_max_label":"Great",
"esm_likert_min_label":"Poor",
"esm_likert_step":1,
"esm_title":"Productivity",
"esm_instructions":"How productive was your day?",
"esm_submit":"OK"
}
},
...
]
```

# Settings
Parameters adjustable on the dashboard and client:
- **status_plugin_esm_scheduler**: (boolean) activate/deactivate plugin

# Providers
The data of this plugin is stored in the ESM"s sensor database table. To use this plugin, you **MUST** enable the ESM sensor for your study, otherwise no ESM will be triggered nor their data will be stored.
