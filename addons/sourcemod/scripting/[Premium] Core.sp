#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <adminmenu>
#include <sourcemod>
#include <morecolors>
#include <csgo_colors>

#include <premium>

#include "premium/globals.sp"
#include "premium/database.sp"
#include "premium/menus.sp"
#include "premium/adminmenu.sp"
#include "premium/functions.sp"
#include "premium/clients.sp"
#include "premium/debug.sp"
#include "premium/API.sp"

public Plugin myinfo = {
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

public void OnPluginStart() {
    InitialDB();
    InitialEngine();
    InitialTranslations();
    InitialConfiguration();

    InitialCore();
}