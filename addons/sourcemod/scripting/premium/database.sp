stock void InitialDB() {
    char szDriver[10], szError[PLATFORM_MAX_PATH];
    szError[0] = '\0';
    
    static const char szQueryMySQL[] = "CREATE TABLE IF NOT EXISTS `premium_users` ( \
        `id` INTEGER PRIMARY KEY AUTO_INCREMENT, \
        `adminName` TEXT, `adminSteam` TEXT, \
        `playerName` TEXT, `playerSteam` TEXT, \
        `lastjoin` INTEGER NOT NULL, \
        `timestamp` INTEGER NOT NULL, \
        `expires` INTEGER NOT NULL);";
    static const char szQuerySQLite[] = "CREATE TABLE IF NOT EXISTS `premium_users` ( \
        `id` INTEGER PRIMARY KEY AUTOINCREMENT, \
        `adminName` varchar(50), `adminSteam` varchar(32), \
        `playerName` varchar(50), `playerSteam` varchar(32), \
        `lastjoin` INTEGER NOT NULL, \
        `timestamp` INTEGER NOT NULL, \
        `expires` INTEGER NOT NULL);";

    static const char szSettingsQueryMySQL[] = "CREATE TABLE IF NOT EXISTS `premium_settings` ( \
        `id` INTEGER PRIMARY KEY AUTO_INCREMENT, \
        `feature` TEXT, \
        `player` TEXT, \
        `use` INTEGER NOT NULL DEFAULT '1');";
    static const char szSettingsQuerySQLite[] = "CREATE TABLE IF NOT EXISTS `premium_settings` ( \
        `id` INTEGER PRIMARY KEY AUTOINCREMENT, \
        `feature` varchar(32), \
        `player` varchar(32), \
        `use` INTEGER NOT NULL default 1)";

    if(SQL_CheckConfig("premium")) {
        g_hDatabase = SQL_Connect("premium", true, szError, sizeof szError);
    }else{
        g_hDatabase = SQLite_UseDatabase("Premium", szError, sizeof szError);
    }

    if(g_hDatabase == INVALID_HANDLE) SetFailState("[Premium] Failed connect to database!");

    g_hDatabase.Driver.GetIdentifier(szDriver, sizeof szDriver);

    if(StrEqual(szDriver, "mysql")) {
        if(!SQL_FastQuery(g_hDatabase, szQueryMySQL)) SetFailState("[Premium] An error occurred while executing a query to create a table!");
        if(!SQL_FastQuery(g_hDatabase, szSettingsQueryMySQL)) SetFailState("[Premium] An error occurred while executing a query to create a table!");
    }else{
        if(!SQL_FastQuery(g_hDatabase, szQuerySQLite)) SetFailState("[Premium] An error occurred while executing a query to create a table!");
        if(!SQL_FastQuery(g_hDatabase, szSettingsQuerySQLite)) SetFailState("[Premium] An error occurred while executing a query to create a table!");
    }

    SQL_SetCharset(g_hDatabase, "utf8");
}

stock void FetchPremiumDatabase() {
    CreateTimer(g_fCheckInterval, Timer_FetchPremiumDB, _, TIMER_REPEAT);
}

public Action Timer_FetchPremiumDB(Handle hTimer) {
    for(int iClient = 1; iClient <= MaxClients; iClient++) {
        if(PM_IsValidClient(iClient)) GetPremiumFromClient(iClient);
    }
}

stock void FetchExpiredPlayers() {
    CreateTimer(g_fCheckInterval, Timer_DeleteExpiredPlayers, _, TIMER_REPEAT);
}

public Action Timer_DeleteExpiredPlayers(Handle hTimer) {
    char szQuery[PLATFORM_MAX_PATH];

    FormatEx(szQuery, sizeof szQuery, "SELECT `expires`, `playerSteam` FROM `premium_users` ORDER BY `id` DESC");
    g_hDatabase.Query(SQL_CallBack_DeleteExpiredPlayers, szQuery);
}

public void SQL_CallBack_DeleteExpiredPlayers(Database hDB, DBResultSet hResults, const char[] szError, any data) {
    if(szError[0] && hResults == null) {
        DBG_SQL("[SQL_CallBack_DeleteExpiredPlayers]: %s", szError);

        return;
    }

    while(SQL_FetchRow(hResults)) {
        char szSteam[32];
        int iExpires = SQL_FetchInt(hResults, 0);
        SQL_FetchString(hResults, 1, szSteam, sizeof szSteam);

        if(iExpires != 0 && iExpires < GetTime()) PM_RemoveClientAccess(szSteam);
    }
}

public void SQL_CallBack_GiveClientAccess(Database hDB, DBResultSet hResults, const char[] szError, int iUserID) {
    if(szError[0] && hResults == null) {
        DBG_SQL("[SQL_CallBack_GiveClientAccess]: %s", szError);

        return;
    }

    int iClient = GetClientOfUserId(iUserID);

    if(g_bIsNotifyPlayer_Add) ShowGiveAccessMenu(iClient);
    if(PM_IsValidClient(iClient)) API_CreateForward_OnAddAccess(iClient);
    
    DBG_SQL("[SQL_CallBack_GiveClientAccess]: Data saved!");
}

public void SQL_CallBack_RemoveClientAccess(Database hDB, DBResultSet hResults, const char[] szError, int iClient) {
    if(szError[0] && hResults == null) {
        DBG_SQL("[SQL_CallBack_RemoveClientAccess]: %s", szError);

        return;
    }

    if(PM_IsValidClient(iClient)) {
        if(g_bIsNotifyPlayer_Expired) ShowExpiredAccessMenu(iClient);

        API_CreateForward_OnRemoveAccess(iClient);
    }
    
    DBG_SQL("[SQL_CallBack_RemoveClientAccess]: Data saved!");
}

public void SQL_CallBack_UpdateJoinTime(Database hDB, DBResultSet hResults, const char[] szError, any data) {
    if(szError[0] && hResults == null) {
        DBG_SQL("[SQL_CallBack_UpdateJoinTime]: %s", szError);

        return;
    }

    DBG_SQL("[SQL_CallBack_UpdateJoinTime]: Data saved!");
}

public void SQL_CallBack_GetPremiumFromClient(Database hDB, DBResultSet hResults, const char[] szError, int iUserID) {
    if(szError[0] && hResults == null) {
        DBG_SQL("[SQL_CallBack_GetPremiumFromClient]: %s", szError);
        
        return;
    }

    int iClient = GetClientOfUserId(iUserID);

    if(iClient) {
        if(hResults.FetchRow()) g_bIsPremiumClient[iClient] = true;
        else g_bIsPremiumClient[iClient] = false;

        DBG_SQL("[SQL_CallBack_GetPremiumFromClient]: %N | Premium Access: %s", iClient, g_bIsPremiumClient[iClient] ? "True" : "False");
    }
}

public void SQL_CallBack_PremiumClientsMenu(Database hDB, DBResultSet hResults, const char[] szError, int iUserID) {
    if(szError[0] && hResults == null) {
        DBG_SQL("[SQL_CallBack_PremiumClientsMenu]: %s", szError);
        
        return;
    }

    int iClient = GetClientOfUserId(iUserID);

    if(iClient) {
        Menu hMenu = CreateMenu(CallBack_PremiumClientsMenu);

        SetMenuTitle(hMenu, "%T\n ", "ClientsMenu_Title", iClient);

        char szNoPlayers[128];
        FormatEx(szNoPlayers, sizeof szNoPlayers, "%T", "PlayersNotFound", iClient);

        while(hResults.FetchRow()) {
            char szName[MAX_NAME_LENGTH], szSteam[32];

            hResults.FetchString(3, szName, sizeof szName);
            hResults.FetchString(4, szSteam, sizeof szSteam);

            AddMenuItem(hMenu, szSteam, szName);
        }

        if(!GetMenuItemCount(hMenu)) AddMenuItem(hMenu, NULL_STRING, szNoPlayers, ITEMDRAW_DISABLED);

        SetMenuExitBackButton(hMenu, true);

        DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
    }
}

public void SQL_CallBack_PremiumPlayersMenu(Database hDB, DBResultSet hResults, const char[] szError, int iUserID) {
    if(szError[0] && hResults == null) {
        DBG_SQL("[SQL_CallBack_PremiumPlayersMenu]: %s", szError);
        
        return;
    }

    int iClient = GetClientOfUserId(iUserID);

    if(iClient) {
        Menu hMenu = CreateMenu(CallBack_PremiumPlayersMenu);

        SetMenuTitle(hMenu, "%T\n ", "PremiumPlayersMenu_Title", iClient);

        char szNoPlayers[128];
        FormatEx(szNoPlayers, sizeof szNoPlayers, "%T", "PlayersNotFound", iClient);

        while(hResults.FetchRow()) {
            char szName[MAX_NAME_LENGTH], szSteam[64];

            hResults.FetchString(3, szName, sizeof szName);
            hResults.FetchString(4, szSteam, sizeof szSteam);

            AddMenuItem(hMenu, szSteam, szName);
        }

        if(!GetMenuItemCount(hMenu)) AddMenuItem(hMenu, NULL_STRING, szNoPlayers, ITEMDRAW_DISABLED);

        SetMenuExitBackButton(hMenu, true);

        DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
    }
}

public void SQL_CallBack_ShowPlayerInfo(Database hDB, DBResultSet hResults, const char[] szError, int iUserID) {
    if(szError[0] && hResults == null) {
        DBG_SQL("[SQL_CallBack_ShowPlayerInfo]: %s", szError);
        
        return;
    }

    int iClient = GetClientOfUserId(iUserID);

    if(iClient) {
        Menu hMenu = CreateMenu(CallBack_PlayerInfoMenu);

        SetMenuTitle(hMenu, "%T\n ", "PlayerInfoMenu_Title", iClient);

        char szNotData[PLATFORM_MAX_PATH];
        FormatEx(szNotData, sizeof szNotData, "%T", "NoData", iClient);

        if(hResults.FetchRow()) {
            char
                szAdminName[MAX_NAME_LENGTH], szAdminSteam[64],
                szPlayerName[MAX_NAME_LENGTH], szPlayerSteam[64],
                szLastJoin[PLATFORM_MAX_PATH], szExpiresTime[PLATFORM_MAX_PATH],
                szLastLoginItem[PLATFORM_MAX_PATH], szExpiresItem[PLATFORM_MAX_PATH],
                szPremiumAdded[PLATFORM_MAX_PATH], szAddedTimeItem[PLATFORM_MAX_PATH],
                szAdminNameItem[PLATFORM_MAX_PATH], szAdminSteamItem[PLATFORM_MAX_PATH],
                szPlayerNameItem[PLATFORM_MAX_PATH], szPlayerSteamItem[PLATFORM_MAX_PATH];
            
            hResults.FetchString(1, szAdminName, sizeof szAdminName);
            hResults.FetchString(2, szAdminSteam, sizeof szAdminSteam);

            hResults.FetchString(3, szPlayerName, sizeof szPlayerName);
            hResults.FetchString(4, szPlayerSteam, sizeof szPlayerSteam);

            FormatTime(szLastJoin, sizeof szLastJoin, "%d.%m.%Y - %H:%M:%S", hResults.FetchInt(5));
            FormatTime(szPremiumAdded, sizeof szPremiumAdded, "%d.%m.%Y - %H:%M:%S", hResults.FetchInt(6));
            
            if(hResults.FetchInt(7)) FormatTime(szExpiresTime, sizeof szExpiresTime, "%d.%m.%Y - %H:%M:%S", hResults.FetchInt(7));
            else FormatEx(szExpiresTime, sizeof szExpiresTime, "%T", "Forever", iClient);

            FormatEx(szPlayerNameItem, sizeof szPlayerNameItem, "%T", "PlayerInfo_Name", iClient, szPlayerName);
            FormatEx(szPlayerSteamItem, sizeof szPlayerSteamItem, "%T", "PlayerInfo_Steam", iClient, szPlayerSteam);

            FormatEx(szAdminNameItem, sizeof szAdminNameItem, "%T", "PlayerInfo_AdminName", iClient, szAdminName);
            FormatEx(szAdminSteamItem, sizeof szAdminSteamItem, "%T", "PlayerInfo_AdminSteam", iClient, szAdminSteam);

            FormatEx(szLastLoginItem, sizeof szLastLoginItem, "%T", "PlayerInfo_LastJoin", iClient, szLastJoin);
            FormatEx(szAddedTimeItem, sizeof szAddedTimeItem, "%T", "PlayerInfo_Added", iClient, szPremiumAdded);
            FormatEx(szExpiresItem, sizeof szExpiresItem, "%T", "PlayerInfo_Expires", iClient, szExpiresTime);

            AddMenuItem(hMenu, NULL_STRING, szPlayerNameItem, ITEMDRAW_DISABLED);
            AddMenuItem(hMenu, NULL_STRING, szPlayerSteamItem, ITEMDRAW_DISABLED);
            AddMenuItem(hMenu, NULL_STRING, szAdminNameItem, ITEMDRAW_DISABLED);
            AddMenuItem(hMenu, NULL_STRING, szAdminSteamItem, ITEMDRAW_DISABLED);
            AddMenuItem(hMenu, NULL_STRING, szAddedTimeItem, ITEMDRAW_DISABLED);
            AddMenuItem(hMenu, NULL_STRING, szExpiresItem, ITEMDRAW_DISABLED);
            AddMenuItem(hMenu, NULL_STRING, szLastLoginItem, ITEMDRAW_DISABLED);
        }else AddMenuItem(hMenu, NULL_STRING, szNotData, ITEMDRAW_DISABLED);

        SetMenuExitBackButton(hMenu, true);

        DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
    }
}