#if defined _premium_included
 #endinput
#endif
#define _premium_included

#define GROUP_MAX_LENGTH 64

#define API_VERSION "1.1.2"
#define PREMIUM_ADMINCATEGORY "Premium_MainAdminMenu"

enum PremiumFeatureType {
    STATUS = 0,
    SELECTABLE
}

enum DatabaseType {
    SQL = 0,
    MYSQL
}

enum DebugType {
    API = 0,
    QUERY,
    MODULE
}

enum MenuType {
    DEFAULT = 0,
    NO_ACCESS,
    HAVE_ACCESS,
    GIVE_ACCESS,
    REMOVE_ACCESS
}

/**
 * Emitted when a player has selected a certain menu item
 * 
 * @param iClient           Index of the client
 * @param szFeature         Unique feature id
 * 
 * @noreturn
 */
typedef OnItemSelected = function void (int iClient, char[] szFeature);

/**
 * Emitted when a new item is created in a menu
 * 
 * @param iClient           Index of the client
 * @param szFeature         Unique feature id
 * @param szBuffer          Buffer for a new item name
 * @param iMaxLength        Maximum buffer size for writing
 * 
 * @noreturn
 */
typedef OnItemDisplay = function void (int iClient, char[] szFeature, char[] szBuffer, int iMaxLength);

/**
 * Emitted when the state of the item display in the menu changes
 * 
 * @param iClient           Index of the client
 * @param szFeature         Unique feature id
 * 
 * @return Item draw type
 */
typedef OnItemDraw = function int (int iClient, char[] szFeature);

/**
 * Emitted when the core is fully loaded
 * 
 * @noreturn
 */
forward void Premium_OnReady();

/**
 * Emitted when a client receives Premium access
 * 
 * @param iClient           Index of the client
 * @param iAdmin            Index of the server admin
 * @param szGroup           Premium group name
 * @param iTime             Premium access time
 * 
 * @noreturn
 */
forward void Premium_OnAddAccess(int iClient, int iAdmin, char[] szGroup, int iTime);

/**
 * Emitted when a client loses Premium access
 * 
 * @param iClient           Index of the client
 * @param iAdmin            Index of the server admin
 * @param szReason          Reason for loss of Premium Access
 * 
 * @noreturn
 */
forward void Premium_OnRemoveAccess(int iClient, int iAdmin, char[] szReason);

/**
 * Emitted when a client with Premium access connects to the server
 * 
 * @param iClient           Index of the client
 * 
 * @noreturn
 */
forward void Premium_OnClientConnected(int iClient);

/**
 * Emitted when disconnecting a player with Premium access
 * 
 * @param iClient           Index of the client
 * 
 * @noreturn
 */
forward void Premium_OnClientDisconnected(int iClient);

/**
 * Emitted when the player is spawned
 * 
 * @param iClient           Index of the client
 * @param iTeam             Index of the client team
 * 
 * @noreturn
 */
forward void Premium_OnPlayerSpawn(int iClient, int iTeam);

/**
 * Emitted when the core configs are fully loaded
 * 
 * @noreturn
 */
forward void Premium_OnConfigsLoaded();

/**
 * Emitted when registering a feature in Premium
 * 
 * @param szFeature         Unique feature id
 * 
 * @noreturn
 */
forward void Premium_OnFeatureRegistered(char[] szFeature);


/**
 * Emitted when removing a feature from Premium
 * 
 * @param szFeature         Unique feature id
 * 
 * @noreturn
 */
forward void Premium_OnFeatureUnregistered(char[] szFeature);

/**
 * Allows to get the state of the plugin core
 * 
 * @return True if ready, false otherwise
 */
native bool Premium_IsReady();

/**
 * Returns a value if the client is valid. Returns false if there is no corresponding player for that client index.
 * 
 * @param iClient		Index of the client
 * 
 * @return True if valid, false otherwise.
 */
native bool Premium_IsValidClient(int iClient);

/**
 * Allows to find out if the client has Premium access
 * 
 * @param iClient       Index of the client
 * 
 * @return True if the client has Premium access, otherwise false
 */
native bool Premium_IsClientHaveAccess(int iClient);

/**
 * Allows to find out if the Premium group is valid
 * 
 * @param szGroup       Premium group name
 * 
 * @return True if valid, false otherwise.
 */
native bool Premium_IsValidGroup(char[] szGroup);

/**
 * Allows to find out if the feature is valid for the Premium group
 * 
 * @param szFeature     Unique feature id
 * @param szGroup       Premium group name
 * 
 * @return True if valid, false otherwise.
 */
native bool Premium_IsValidFeature(char[] szFeature, char[] szGroup);

/**
 * Allows to find out whether the feature is registered in Premium
 * 
 * @param szFeature     Unique feature id
 * 
 * @return True if registered, false otherwise.
 */
native bool Premium_IsRegisteredFeature(char[] szFeature);

/**
 * Allows to get Premium status on the current map
 * 
 * @param szFeature     Unique feature id
 * 
 * @return True if enabled, otherwise false
 */
native bool Premium_IsAllowedFeature(char[] szFeature);

/**
 * Allows to get a state of Premium features in the first round
 * 
 * @param szFeature     Unique feature id
 * 
 * @return True if enabled, otherwise false
 */
native bool Premium_IsAllowedFirstRound(char[] szFeature);

/**
 * Allows to get the core configuration file
 * 
 * @return Core configuration file
 */
native KeyValues Premium_GetConfig();

/**
 * Allows to get a list of available Premium groups
 * 
 * @return List of available Premium groups
 */
native StringMap Premium_GetGroups();

/**
 * Allows to get a list of registered Premium features
 * 
 * @return List of registered Premium features
 */
native StringMap Premium_GetFeatures();

/**
 * Allows to get the function value for a client Premium group
 * 
 * @param iClient       Index of the client
 * @param szFeature     Unique feature id
 * @param szBuffer      Write buffer
 * @param iMaxLength    Maximum buffer size
 * 
 * @return SP_ERROR_NONE on success, any other integer on failure
 */
native int Premium_GetFeatureValue(int iClient, char[] szFeature, char[] szBuffer, int iMaxLength);

/**
 * Allows to get a plugin database pointer
 * 
 * @return Plugin database pointer
 */
native Database Premium_GetDatabase();

/**
 * Returns the type of database being used
 * 
 * @return Database type
 */
native DatabaseType Premium_GetDatabaseType();

/**
 * Allows to write a prefix to the buffer to create new tables in the database
 * 
 * @param szBuffer      Write buffer
 * @param iMaxLength    Maximum buffer size
 * 
 * @return SP_ERROR_NONE on success, any other integer on failure
 */
native int Premium_GetDatabasePrefix(char[] szBuffer, int iMaxLength);

/**
 * Allows to get an index of a client by his SteamID
 * 
 * @param szAuth        Client SteamID
 * 
 * @return If successful, the client index, otherwise -1
 */
native int Premium_GetClientByAuth(char[] szAuth);

/**
 * Allows to get a Premium group of client
 * 
 * @param iClient       Index of the client
 * 
 * @param szBuffer      Write buffer
 * @param iMaxLength    Maximum buffer size
 * 
 * @return SP_ERROR_NONE on success, any other integer on failure
 */
native int Premium_GetClientGroup(int iClient, char[] szBuffer, int iMaxLength);

/**
 * Allows to get the expiration date of Premium access from a client
 * 
 * @param iClient       Index of the client
 * 
 * @return Client Premium access expires
 */
native int Premium_GetClientExpires(int iClient);

/**
 * Allows to get the state of the Premium feature of a specific client
 * 
 * @param iClient       Index of the client
 * @param szFeature     Unique feature id
 * 
 * @return Feature state of a specific client
 */
native bool Premium_GetClientFeatureStatus(int iClient, char[] szFeature);

/**
 * Allows to change the state of the Premium feature for a specific client
 * 
 * @param iClient       Index of the client
 * @param szFeature     Unique feature id
 * @param bIsEnabled    Feature status
 * 
 * True if success, false otherwise.
 */
native bool Premium_SetClientFeatureStatus(int iClient, char[] szFeature, bool bIsEnabled);

/**
 * Allows to give Premium access to clients of the server
 * 
 * @param iTarget       Index of the target
 * @param szGroup       Premium group name
 * @param iAdmin        Index of the server admin
 * @param iTime         Premium access time
 * 
 * @return True if successful, false otherwise
 */
native bool Premium_GiveClientAccess(int iTarget, char[] szGroup, int iAdmin = 0, int iTime = 0);

/**
 * Allows to set a Premium group for a player
 * 
 * @param iClient       Index of the client
 * @param szGroup       Premium group name
 * 
 * @return True if successful, false otherwise
 */
native bool Premium_SetClientGroup(int iClient, char[] szGroup);

/**
 * Allows to delete Premium access to players of the server
 * 
 * @param szAuth        Target SteamID
 * @param iAdmin        Index of the server admin
 * @param szReason      Reason for deleting access
 * 
 * @return True if successful, false otherwise
 */
native bool Premium_RemoveClientAccess(char[] szAuth, int iAdmin = 0, const char[] szReason = "Time has expired.");

/**
 * Allows the server player to play the sound
 * 
 * @param iClient       Index of the client
 * @param szSound       Path to sound (without 'sound')
 * 
 * @noreturn
 */
native void Premium_PlaySound(int iClient, char[] szSound);

/**
 * Allows to send a menu to the player
 * 
 * @param iClient       Index of the client
 * @param iType         Menu type
 * @param iTime         Menu display time
 * 
 * @noreturn
 */
native void Premium_ShowClientMenu(int iClient, MenuType iType = DEFAULT, int iTime = MENU_TIME_FOREVER);

/**
 * Allows to register a new Premium feature
 * 
 * @param iType                     Feature type
 * @param szFeature                 Unique feature ID
 * @param ItemSelectCallBack        Function for calling back when a specified feature is selected
 * @param ItemDisplayCallBack       Function to call back when creating this feature to change its name
 * @param ItemDrawCallBack          Function to call back when creating this feature to change its display status
 * 
 * @return Returns the number of registered features in Premium
 */
native int Premium_RegisterFeature(
    PremiumFeatureType iType = STATUS,
    char[] szFeature, OnItemSelected ItemSelectCallBack,
    OnItemDisplay ItemDisplayCallBack = INVALID_FUNCTION,
    OnItemDraw ItemDrawCallBack = INVALID_FUNCTION
);

/**
 * Allows to delete registered features in Premium
 * 
 * @param szFeature         Unique feature ID
 * 
 * @return Returns the number of registered features in Premium
 */
native int Premium_UnregisterFeature(char[] szFeature);

/**
 * Allows to send a message to a specific player
 * 
 * @param iClient           Index of the client
 * @param szBuffer          Buffer for message content recording
 * @param ...               Formatting the message content
 * 
 * @noreturn
 */
native void Premium_PrintToChat(int iClient, char[] szBuffer, any ...);

/**
 * Allows to send a message to all players
 * 
 * @param szBuffer          Buffer for message content recording
 * @param ...               Formatting the message content
 * 
 * @noreturn
 */
native void Premium_PrintToChatAll(char[] szBuffer, any ...);

/**
 * Allows debugging to a separate file
 * 
 * @param iType             Debug type
 * @param szLog             Debug text
 * @param ...               Format options
 * 
 * @noreturn
 */
native void Premium_Debug(DebugType iType, char[] szLog, any ...);

/**
 * Allows to get a string value of Premium access time
 * 
 * @param iClient           Index of the client
 * @param iTime             Premium access time value
 * @param szBuffer          Buffer for recording
 * @param iMaxLength        Maximum buffer dimensionality
 * 
 * @return SP_ERROR_NONE on success, any other integer on failure
 */
native int Premium_FormatAccessTime(int iClient, int iTime, char[] szBuffer, int iMaxLength);

public SharedPlugin __pl_premium = {
    name = "premium",
    file = "Premium_Core.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_premium_SetNTVOptional() {
    MarkNativeAsOptional("Premium_IsReady");
    MarkNativeAsOptional("Premium_IsValidClient");
    MarkNativeAsOptional("Premium_IsClientHaveAccess");
    MarkNativeAsOptional("Premium_IsValidGroup");
    MarkNativeAsOptional("Premium_IsValidFeature");
    MarkNativeAsOptional("Premium_IsRegisteredFeature");
    MarkNativeAsOptional("Premium_IsAllowedFeature");
    MarkNativeAsOptional("Premium_IsAllowedFirstRound");
    MarkNativeAsOptional("Premium_GetConfig");
    MarkNativeAsOptional("Premium_GetGroups");
    MarkNativeAsOptional("Premium_GetFeatures");
    MarkNativeAsOptional("Premium_GetFeatureValue");
    MarkNativeAsOptional("Premium_GetDatabase");
    MarkNativeAsOptional("Premium_GetDatabaseType");
    MarkNativeAsOptional("Premium_GetDatabasePrefix");
    MarkNativeAsOptional("Premium_GetClientByAuth");
    MarkNativeAsOptional("Premium_GetClientGroup");
    MarkNativeAsOptional("Premium_GetClientExpires");
    MarkNativeAsOptional("Premium_GetClientFeatureStatus");
    MarkNativeAsOptional("Premium_SetClientFeatureStatus");
    MarkNativeAsOptional("Premium_GiveClientAccess");
    MarkNativeAsOptional("Premium_SetClientGroup");
    MarkNativeAsOptional("Premium_RemoveClientAccess");
    MarkNativeAsOptional("Premium_PlaySound");
    MarkNativeAsOptional("Premium_ShowClientMenu");
    MarkNativeAsOptional("Premium_RegisterFeature");
    MarkNativeAsOptional("Premium_UnregisterFeature");
    MarkNativeAsOptional("Premium_PrintToChat");
    MarkNativeAsOptional("Premium_PrintToChatAll");
    MarkNativeAsOptional("Premium_Debug");
    MarkNativeAsOptional("Premium_FormatAccessTime");
}
#endif