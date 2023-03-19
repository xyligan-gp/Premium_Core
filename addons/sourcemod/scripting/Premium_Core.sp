#pragma newdecls required

// Загрузка inc
#include <premium>

// Загрузка библиотек
#include <sourcemod>
#include <adminmenu>
#include <morecolors>
#include <csgo_colors>
#include <sdktools_functions>
#include <sdktools_stringtables>

// Загрузка файлов плагина
#include "premium/globals.sp"
#include "premium/downloads.sp"
#include "premium/database.sp"
#include "premium/adminmenu.sp"
#include "premium/menus.sp"
#include "premium/events.sp"
#include "premium/functions.sp"

// Загрузка API плагина
#include "premium/API.sp"

public Plugin myinfo = {
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

public void OnPluginStart() {
    InitEngine();
    InitConfig();
    InitCommands();
    InitDatabase();
    InitPremiumMenu();

    InitComponents();
    FetchPremiumUsers();

    g_hFeatures = CreateTrie();

    HookEvent("round_end", Event_RoundEnd);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("player_spawn", Event_PlayerSpawn);
	
    LoadTranslations("premium.core.phrases");
    LoadTranslations("premium.logs.phrases");
    LoadTranslations("premium.modules.phrases");

    InitCore();
}

public void OnPluginEnd() {
    delete g_hMenu;
    delete g_hTimer;
    delete g_hAdminMenu;

    ClearFeatures();
    
    g_bIsReady = false;
}

public void OnMapStart() {
    InitConfig();
    InitDownloads();
    InitComponents();
    LoadPremiumGroups();

    API_CreateForward_OnConfigsLoaded();
}

public void OnMapEnd() {
    ClearGroups();
}

public void OnLibraryRemoved(const char[] szName) {
    if(StrEqual(szName, "adminmenu")) delete g_hAdminMenu;
}