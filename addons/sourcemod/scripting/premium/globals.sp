#define DEBUG_MODE 0
#define DEBUG_SQL            // Отладка SQL запросов
#define DEBUG_API            // Отладка API запросов
#define DEBUG_MODULES        // Отладка работы модулей

#define MAX_CONFIG_MAPS 32

#define PLUGIN_NAME "[Premium] Core"
#define PLUGIN_AUTHOR "xyligan"
#define PLUGIN_DESCRIPTION "Ядро для выдачи привилегированного доступа игрокам"
#define PLUGIN_VERSION "1.1.3-dev.1679254600"
#define PLUGIN_URL "https://csdevs.net"

#define LOGS_PATH "logs/premium.log"
#define DEBUG_PATH "logs/premium.debug.log"

#define DOWNLOADS_PATH "configs/premium/core/downloads.txt"
#define CONFIG_PATH "configs/premium/core/settings.cfg"
#define GROUPS_PATH "configs/premium/core/groups.cfg"
#define TIMES_PATH "configs/premium/core/times.cfg"

#define MAX_MAP_LENGTH 128
#define CHARSET "utf8mb4_general_ci"
#define NO_ACCESS_SOUND "buttons/button11.wav"

enum ConfigType {
    CONFIG_MAIN = 0,
    CONFIG_TIMES,
    CONFIG_GROUPS
}

enum Forwards {
    OnReady = 0,
    OnAddAccess,
    OnRemoveAccess,
    OnClientJoin,
    OnClientLeave,
    OnClientSpawn,
    OnConfigsLoaded,
    OnFeatureRegistered,
    OnFeatureUnregistered
}

enum ActionType {
    ACTION_ADD_CLIENT = 0,
    ACTION_UPDATE_GROUP,
    ACTION_UPDATE_EXPIRES
}

enum ExpiresAction {
    EXP_ACTION_SET = 0,
    EXP_ACTION_ADD,
    EXP_ACTION_TAKE
}

Menu g_hMenu;
int g_iAdminFlags;
Database g_hDatabase;
TopMenu g_hAdminMenu;
float g_fCheckInterval;
EngineVersion g_hEngine;
KeyValues g_hConfigs[ConfigType];

Handle g_hTimer,
    g_hGlobalForward[Forwards];

char g_szTablePrefix[32],
    g_szConfig[PLATFORM_MAX_PATH],
    g_szLogsFile[PLATFORM_MAX_PATH];

StringMap g_hGroups,
    g_hFeatures,
    g_hClientData[MAXPLAYERS + 1];

bool g_bIsReady,
    g_bIsNotify[3],
    g_bIsFirstRound,
    g_bIsHaveAccess[MAXPLAYERS + 1];