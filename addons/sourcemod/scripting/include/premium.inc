#if defined _premium_core_included
 #endinput
#endif
#define _premium_core_included

#define API_VERSION "1.0.0"
#define PREMIUM_MAINMENU "Premium_MainAdminMenu"

enum PremiumFeatureType {
    DEFAULT = 0,
    SELECTABLE = 1
}

enum PremiumMenuType {
    DEFAULT_MENU = 0,
    NO_ACCESS_MENU = 1,
    GIVE_ACCESS_MENU = 2,
    HAVE_ACCESS_MENU = 3,
    EXPIRED_ACCESS_MENU = 4,
}

enum PremiumHookMenuType {
    HOOK_DB_MANAGE_MENU = 0
}

/********************************************************** FORWARDS **********************************************************/

/**
 * Premium Core Start Event
*/
forward void Premium_OnReady();

/**
 * Event of getting Premium access by a server player
 * 
 * @param iClient     Client index
*/
forward void Premium_OnAddAccess(int iClient);

/**
 * The event of the completion of Premium access by a server player
 * 
 * @param iClient     Client index
*/
forward void Premium_OnRemoveAccess(int iClient);

/**
 * Event connecting to the server of a player with Premium access
 * 
 * @param iClient     Client index
*/
forward void Premium_OnClientConnected(int iClient);

/**
 * Event disconnected from the server of a player with Premium access
 * 
 * @param iClient     Client index
*/
forward void Premium_OnClientDisconnect(int iClient);

/**
 * Server respawn event
 * 
 * @param iClient        Client index
 * @param iTeam          Client team index
 * @param bIsPremium     Does the player have Premium access
*/
forward void Premium_OnPlayerSpawn(int iClient, int iTeam, bool bIsPremium);

/**
 * Admin menu readiness event for adding items
 * 
 * @param hMenu       Admin Menu Handle
 * @param hObject     Admin Menu Category
 * @param iFlags      Admin Access Flags
*/
forward void Premium_OnAdminMenuReady(Handle hTopMenu, int iFlags);

/**
 * Event of the player selecting a feature in the Premium menu
 * 
 * @param iClient       Client index
 * @param szFeature     Unique feature name
 * @param bStatus       feature status
*/
forward void Premium_OnMenuFeatureSelected(int iClient, const char[] szFeature, bool bStatus);

/********************************************************** NATIVES **********************************************************/

/**
 * Native to getting Premium core status
 * 
 * @return     Premium core status
*/
native bool Premium_IsReady();

/**
 * Native player validation check
 * 
 * @param iClient     Client index
 *
 * @return            State whether the player is valid
*/
native bool Premium_IsValidClient(int iClient);

/**
 * Native player check for Premium access
 * 
 * @param iClient     Client index
 *
 * @return            State whether the player has Premium access
*/
native bool Premium_IsClientAccess(int iClient);

/**
 * Native to check if the function can work at the moment
 * 
 * @param szFeature     Unique feature name
 *
 * @return              State, whether the feature can work at a given time
*/
native bool Premium_IsAllowedFeature(const char[] szFeature);

/**
 * Native to check if a feature can work in the first round of the game
 * 
 * @param szFeature     Unique feature name
 *
 * @return              State whether the feature can work in the first round of the game
 */
native bool Premium_IsAllowedFirstRound(const char[] szFeature);

/**
 * Native to get a pointer to the core database to work with it
 * 
 * @return     Core database pointer
*/
native Database Premium_GetDatabase();

/**
 * Native to list all available Premium features
 * 
 * @return     List all available Premium features
*/
native StringMap Premium_GetFeaturesTrie();

/**
 * Native to register a new unique feature in Premium
 * 
 * @param szFeature          Feature unique name
 * @param iType              Feature type
 * @param szFeatureSetup     Unique key for the feature setting item
 *
 * @return                   State of registering a new unique feature in Premium
*/
native bool Premium_RegisterFeature(const char[] szFeature, PremiumFeatureType iType, const char[] szFeatureSetup = "");

/**
 * Native to remove unique feature from Premium
 * 
 * @param szFeature     Feature unique name
 *
 * @return              State of removing a unique feature from Premium
*/
native bool Premium_UnRegisterFeature(const char[] szFeature);

/**
 * Native to get the state of a feature from a specific server player
 * 
 * @param iClient       Client index
 * @param szFeature     Feature unique name
 *
 * @return              Feature state of a specific player on the server
*/
native bool Premium_GetFeatureStatus(int iClient, const char[] szFeature);

/**
 * Native to set the feature state of a specific player on the server
 * 
 * @param iClient        Client index
 * @param szFeature      feature unique name
 * @param bIsEnabled     Feature state
 *
 * @return               Feature state setting state for a specific player on the server
*/
native bool Premium_SetFeatureStatus(int iClient, const char[] szFeature, bool bIsEnabled);

/**
 * Native to send menu to server player
 * 
 * @param iClient       Client index
 * @param iMenuType     Menu type
*/
native void Premium_SendClientMenu(int iClient, PremiumMenuType iMenuType = DEFAULT_MENU);

/**
 * Native for issuing Premium access to a player
 * 
 * @param iClient     Client index
 * @param iAdmin      Admin Client index
 * @param iTime       Premium expire time
*/
native void Premium_GiveClientAccess(int iClient, int iAdmin = 0, int iTime = 0);

/**
 * Native to remove Premium access from a player
 * 
 * @param szSteam     Player SteamID
*/
native void Premium_RemoveClientAccess(const char[] szSteam);

/**
 * Native to send a chat message to a specific player
 * 
 * @param iClient       Client index
 * @param szMessage     Message content
 * @param ...           Formatting Options
*/
native void Premium_PrintToChat(int iClient, const char[] szMessage, any...);

/**
 * Native to send a chat message to all players on the server
 * 
 * @param szMessage     Message content
 * @param ...           Formatting Options
*/
native void Premium_PrintToChatAll(const char[] szMessage, any...);

/**
 * Native for debugging SQL actions Premium core
 * 
 * @param szMessage     Log content
 * @param ...           Formatting Options
*/
native void Premium_Debug_SQL(const char[] szMessage, any...);

/**
 * Native for debugging Premium module actions
 * 
 * @param szMessage     Log content
 * @param ...           Formatting Options
*/
native void Premium_Debug_MODULE(const char[] szMessage, any...);