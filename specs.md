# MooBot conceptual specs #

* Set up working directory
* Read configuration file (some HASH that can be accessible later)
* PLUGINS: Go over @Commandlist
** Set up a COMMANDS hash, connecting "trigger command" to method in specific plugin.
* Set up a TRIGGERS hash, connecting "trigger phrase" to list of autoreplies in some yml file. The yml file will be dictated from config, based on language?
* Use configuration parameters to set up a connection to IRC server
* PLUGINS: READ THROUGH PLUGINS METHOD "On_Bot_Init"
* Join channels
* PLUGINS: READ THROUGH PLUGINS METHOD "On_Bot_AutoJoin"
* Listen to method calls on IRC connection
** Text accepted:
*** PLUGINS: READ THROUGH PLUGINS METHOD "On_Message" dependent on location (public, pvt, ctcp)?

Below could be the "core" plugin:
* Check if text starts with a command. If yes:
** Send command through the COMMANDS hash to the proper plugin sub to be processed
** If the process of the plugin results in a 'reply hash' (some reply to channel or user), send it as reply to appropriate location
---
* Check if text has trigger word (skip if already known it is a command, and work only on "Public" chat) If yes:
** Pick a random reply from array of possible replies, and respond back in the same channel.
