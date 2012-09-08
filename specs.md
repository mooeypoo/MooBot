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
* > Text accepted:
* >> PLUGINS: READ THROUGH PLUGINS METHOD "On_Message" dependent on location (public, pvt, ctcp)?

Below could be the "core" plugin:
* Check if text starts with a command. If yes:
* > Send command through the COMMANDS hash to the proper plugin sub to be processed
* > If the process of the plugin results in a 'reply hash' (some reply to channel or user), send it as reply to appropriate location

* Check if text has trigger word (skip if already known it is a command, and work only on "Public" chat) If yes:
* > Pick a random reply from array of possible replies, and respond back in the same channel.

# Conceptual specs for Packages #
### moobot.pl ###
- Reads Config file into a hash.
- Creates $bot = MooBot->new(); for the session hash
- Reads through available plugins, set commands from each plugin into COMMANDS hash
- Manipulates event calls.
- > Calls plugin-specific events for each call
- > sends result of plugin-call to MooBot::Helper::speak();
- calls $poe_kernel->run();

### MooBot Class ###
- accepts config hash to initiate irc sessions
- handles anything related to $irc object
- > yield (answer)
- > change nickname
- > change channels
- > etc

### MooBot::Plugin Class ##
* Sets up the basic functionality of a plugin
* Contains all methods of reading through plugins

### MooBot::Plugin::Core::Users ###
* CORE PLUGIN : in charge of handling users
* Commands:
* > adduser
* > deluser
* > edituser
* Methods calls:
* > On_Bot_Init - reads existing users from user.yml file

### MooBot::Plugin::Core::Triggers ##
* responsible for reading and outputting 'autotriggers'
* reads autotriggers.yml file on init
* Method calls:
* > On_Bot_Public - checks if there is a trigger, and outputs a random response from the list

### MooBot::Plugin::Channel ###
* CORE PLUGIN: in charge of basic channel operations
* Commands:
* > op
* > deop
* > voice
* > devoice
* > slap

### MooBot::Helper Functions ##
Contains the helper functions.
* save_yml
* read_yml
* pwd_encrypt
* pwd_compare

