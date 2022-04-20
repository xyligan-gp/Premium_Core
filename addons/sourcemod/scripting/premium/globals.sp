#define DEBUG_MODE 0
// #define DEBUG_SQL            // Отладка SQL запросов
// #define DEBUG_API            // Отладка API запросов
// #define DEBUG_MODULES        // Отладка работы модулей

#define PLUGIN_NAME "[Premium] Core"
#define PLUGIN_AUTHOR "xyligan"
#define PLUGIN_DESCRIPTION "Ядро для выдачи привилегированного доступа игрокам"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "https://dynodev.ru"

stock const char NO_ACCESS_SOUND[] = "buttons/button11.wav";

TopMenu g_hTopMenu;
Database g_hDatabase;
StringMap g_hFeatures;
float g_fCheckInterval;
EngineVersion g_GameEngine;

KeyValues
    g_hKV_BlockedMaps,
    g_hKV_FirstRounds,
    g_hKV_AccessTimes;

int
    g_iAdminMenuFlags,
    g_iTarget[MAXPLAYERS + 1];

bool
    g_bIsReady,
    g_bIsFirstRound,
    g_bIsNotifyPlayer_Add,
    g_bIsNotifyPlayer_Connect,
    g_bIsNotifyPlayer_Expired,
    g_bIsPremiumClient[MAXPLAYERS + 1];

char
    g_szLogPath[PLATFORM_MAX_PATH],
    g_szSteamID[MAXPLAYERS + 1][32],
    g_szPluginTag[PLATFORM_MAX_PATH],
    g_szDebugPath[PLATFORM_MAX_PATH],
    g_szPluginCommands[PLATFORM_MAX_PATH];

ConVar
    g_hLogPath,
    g_hDebugPath,
    g_hPluginTag,
    g_hCheckInterval,
    g_hPluginCommands,
    g_hAdminMenuFlags,
    g_hIsNotifyPlayer_Add,
    g_hIsNotifyPlayer_Connect,
    g_hIsNotifyPlayer_Expired;

Handle
    g_hGlobalForward_OnReady,
    g_hGlobalForward_OnAddAccess,
    g_hGlobalForward_OnPlayerSpawn,
    g_hGlobalForward_OnRemoveAccess,
    g_hGlobalForward_OnAdminMenuReady,
    g_hGlobalForward_OnClientConnected,
    g_hGlobalForward_OnClientDisconnect,
    g_hGlobalForward_OnMenuFeatureSelected;