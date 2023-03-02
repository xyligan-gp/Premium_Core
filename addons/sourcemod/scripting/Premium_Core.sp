#pragma newdecls required

#include <sourcemod>
#include <adminmenu>

// Загрузка inc
#include <premium>

#include "premium/globals.sp"
#include "premium/downloads.sp"
#include "premium/database.sp"
#include "premium/adminmenu.sp"
#include "premium/menus.sp"
#include "premium/events.sp"
#include "premium/functions.sp"

// Загрузка API
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
    delete g_hAdminMenu;
    
    g_bIsReady = false;
}

public void OnMapStart() {
    InitConfig();
    InitDownloads();
    InitComponents();

    LoadPremiumGroups();
}

public void OnMapEnd() {
    delete g_hGroups;
}

public void OnLibraryRemoved(const char[] szName) {
    if(StrEqual(szName, "adminmenu")) delete g_hAdminMenu;
}