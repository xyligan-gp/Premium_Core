stock void InitDatabase() {
    char szError[PLATFORM_MAX_PATH], szQuery[4][1024];

    FormatEx(szQuery[0], sizeof szQuery[], "CREATE TABLE IF NOT EXISTS `%s_users` ( \
        `id` INTEGER PRIMARY KEY AUTO_INCREMENT, \
        `group` TEXT, \
        `player_name` TEXT, `player_auth` TEXT, \
        `admin_name` TEXT, `admin_auth` TEXT, \
        `timestamp` INTEGER NOT NULL, \
        `jointime` INTEGER NOT NULL, \
        `expires` INTEGER NOT NULL);", g_szTablePrefix);
    
    FormatEx(szQuery[1], sizeof szQuery[], "CREATE TABLE IF NOT EXISTS `%s_users` ( \
        `id` INTEGER PRIMARY KEY AUTOINCREMENT, \
        `group` varchar(32), \
        `player_name` varchar(128), `player_auth` varchar(32), \
        `admin_name` varchar(128), `admin_auth` varchar(32), \
        `timestamp` INTEGER NOT NULL, \
        `jointime` INTEGER NOT NULL, \
        `expires` INTEGER NOT NULL);", g_szTablePrefix);
    
    FormatEx(szQuery[2], sizeof szQuery[], "CREATE TABLE IF NOT EXISTS `%s_settings` ( \
        `auth` TEXT, \
        `feature_id` TEXT, \
        `feature_status` INTEGER NOT NULL DEFAULT '1');", g_szTablePrefix);
    
    FormatEx(szQuery[3], sizeof szQuery[], "CREATE TABLE IF NOT EXISTS `%s_settings` ( \
        `auth` varchar(32), \
        `feature_id` varchar(32), \
        `feature_status` INTEGER NOT NULL default 1);", g_szTablePrefix);
    
    if(SQL_CheckConfig("premium"))
        g_hDatabase = SQL_Connect("premium", true, szError, sizeof szError);
    else
        g_hDatabase = SQLite_UseDatabase("Premium", szError, sizeof szError);
    
    g_hDatabase.Query(SQL_CallBack_CreateUsersTable, CORE_GetDatabaseType() ? szQuery[0] : szQuery[1]);
    g_hDatabase.Query(SQL_CallBack_CreateSettingsTable, CORE_GetDatabaseType() ? szQuery[2] : szQuery[3]);
}

public void SQL_CallBack_CreateUsersTable(Database hDatabase, DBResultSet hResults, const char[] szError, any data) {
    if(!hResults && strlen(szError)) {
        LogError("[Premium::InitDatabase] SQL_CallBack_CreateUsersTable - error while working with data (%s)", szError);
        CORE_Debug(QUERY, "SQL_CallBack_CreateUsersTable - An error occurred while executing the query - %s", szError);

        return;
    }

    if(CORE_GetDatabaseType()) {
        char szQuery[PLATFORM_MAX_PATH];

        FormatEx(szQuery, sizeof szQuery, "ALTER TABLE `%s_users` COLLATE %s;", g_szTablePrefix, CHARSET);
        g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);

        FormatEx(szQuery, sizeof szQuery, "ALTER TABLE `%s_users` MODIFY COLUMN `player_name` TEXT CHARACTER SET utf8mb4 COLLATE %s;", g_szTablePrefix, CHARSET);
        g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);

        FormatEx(szQuery, sizeof szQuery, "ALTER TABLE `%s_users` MODIFY COLUMN `player_auth` TEXT CHARACTER SET utf8mb4 COLLATE %s;", g_szTablePrefix, CHARSET);
        g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);

        FormatEx(szQuery, sizeof szQuery, "ALTER TABLE `%s_users` MODIFY COLUMN `admin_name` TEXT CHARACTER SET utf8mb4 COLLATE %s;", g_szTablePrefix, CHARSET);
        g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);

        FormatEx(szQuery, sizeof szQuery, "ALTER TABLE `%s_users` MODIFY COLUMN `admin_auth` TEXT CHARACTER SET utf8mb4 COLLATE %s;", g_szTablePrefix, CHARSET);
        g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);
    }
    
    SQL_SetCharset(g_hDatabase, "utf8");
}

public void SQL_CallBack_CreateSettingsTable(Database hDatabase, DBResultSet hResults, const char[] szError, any data) {
    if(!hResults && strlen(szError)) {
        LogError("[Premium::InitDatabase] SQL_CallBack_CreateSettingsTable - error while working with data (%s)", szError);
        CORE_Debug(QUERY, "SQL_CallBack_CreateSettingsTable - An error occurred while executing the query - %s", szError);

        return;
    }

    if(CORE_GetDatabaseType()) {
        char szQuery[PLATFORM_MAX_PATH];

        FormatEx(szQuery, sizeof szQuery, "ALTER TABLE `%s_settings` COLLATE %s;", g_szTablePrefix, CHARSET);
        g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);

        FormatEx(szQuery, sizeof szQuery, "ALTER TABLE `%s_settings` MODIFY COLUMN `auth` TEXT CHARACTER SET utf8mb4 COLLATE %s;", g_szTablePrefix, CHARSET);
        g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);

        FormatEx(szQuery, sizeof szQuery, "ALTER TABLE `%s_settings` MODIFY COLUMN `feature_id` TEXT CHARACTER SET utf8mb4 COLLATE %s;", g_szTablePrefix, CHARSET);
        g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);
    }
    
    SQL_SetCharset(g_hDatabase, "utf8");
}

public void SQL_CallBack_FetchPremiumUsers(Database hDatabase, DBResultSet hResults, const char[] szError, any data) {
    if(!hResults && strlen(szError)) {
        LogError("[Premium] SQL_CallBack_FetchPremiumUsers - error while working with data (%s)", szError);
        CORE_Debug(QUERY, "SQL_CallBack_FetchPremiumUsers - An error occurred while executing the query - %s", szError);

        return;
    }

    while(SQL_FetchRow(hResults)) {
        char szAuth[32];

        int iExpires = SQL_FetchInt(hResults, 8);
        SQL_FetchString(hResults, 3, szAuth, sizeof szAuth);

        if(iExpires != 0 && iExpires < GetTime()) {
            CORE_RemoveClientAccess(szAuth);

            return;
        }else{
            int iClient = CORE_GetClientByAuth(szAuth);
        
            if(CORE_IsValidClient(iClient))
                g_bIsHaveAccess[iClient] = true;
        }
    }
}

public void SQL_CallBack_ShowPremiumClients(Database hDatabase, DBResultSet hResults, const char[] szError, int iUserId) {
    if(!hResults && strlen(szError)) {
        LogError("[Premium] SQL_CallBack_ShowPremiumClients - error while working with data (%s)", szError);
        CORE_Debug(QUERY, "SQL_CallBack_ShowPremiumClients - An error occurred while executing the query - %s", szError);

        return;
    }

    int iClient = GetClientOfUserId(iUserId);

    Menu hMenu = CreateMenu(CallBack_ShowPremiumClientsMenu);

    SetMenuTitle(hMenu, "%T\n ", "Titles_SelectClient", iClient);

    while(SQL_FetchRow(hResults)) {
        char szAuth[32];
        SQL_FetchString(hResults, 3, szAuth, sizeof szAuth);

        char szName[MAX_NAME_LENGTH];
        SQL_FetchString(hResults, 2, szName, sizeof szName);

        AddMenuItem(hMenu, szAuth, szName);
    }

    if(!GetMenuItemCount(hMenu)) {
        char szItem[PLATFORM_MAX_PATH];
        FormatEx(szItem, sizeof szItem, "%T", "NoClients", iClient);

        AddMenuItem(hMenu, NULL_STRING, szItem, ITEMDRAW_DISABLED);
    }

    SetMenuExitBackButton(hMenu, true);

    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void SQL_CallBack_ShowClientInfo(Database hDatabase, DBResultSet hResults, const char[] szError, int iUserId) {
    if(!hResults && strlen(szError)) {
        LogError("[Premium] SQL_CallBack_ShowClientInfo - error while working with data (%s)", szError);
        CORE_Debug(QUERY, "SQL_CallBack_ShowClientInfo - An error occurred while executing the query - %s", szError);

        return;
    }

    int iClient = GetClientOfUserId(iUserId);

    if(SQL_FetchRow(hResults)) {
        Menu hMenu = CreateMenu(CallBack_ShowClientInfo);

        char szGroup[32];
        SQL_FetchString(hResults, 1, szGroup, sizeof szGroup);

        char szName[MAX_NAME_LENGTH];
        SQL_FetchString(hResults, 2, szName, sizeof szName);

        char szAuth[32];
        SQL_FetchString(hResults, 3, szAuth, sizeof szAuth);

        char szTime[PLATFORM_MAX_PATH];
        int iExpires = SQL_FetchInt(hResults, 8);

        if(iExpires) FormatTime(szTime, sizeof szTime, "%d.%m.%Y - %H:%M:%S", iExpires);
        else FormatEx(szTime, sizeof szTime, "%T", "Forever", iClient);

        char szStatus[PLATFORM_MAX_PATH];
        FormatEx(szStatus, sizeof szStatus, "%T", CORE_IsValidClient(CORE_GetClientByAuth(szAuth)) ? "Status_Online" : "Status_Offline", iClient);

        SetMenuTitle(hMenu, "%T\n ", "Titles_ClientInfo", iClient, szName, szStatus, szGroup, szTime);

        char szItem[PLATFORM_MAX_PATH];

        ClearClientData(iClient);
        CreateClientData(iClient);
        
        SetTrieString(g_hClientData[iClient], "Target", szAuth);

        FormatEx(szItem, sizeof szItem, "%T", "Items_RemoveAccess", iClient);
        AddMenuItem(hMenu, "removeAccess", szItem);

        FormatEx(szItem, sizeof szItem, "%T", "Items_ChangeGroup", iClient);
        AddMenuItem(hMenu, "changeGroup", szItem);
        
        FormatEx(szItem, sizeof szItem, "%T", "Items_ChangeExpires", iClient);
        AddMenuItem(hMenu, "changeExpires", szItem);

        SetMenuExitBackButton(hMenu, true);

        DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
    }else{
        char szBuffer[PLATFORM_MAX_PATH];

        FormatEx(szBuffer, sizeof szBuffer, "%T", "Messages_ErrorGetClientInfo", iClient, iClient);
    }
}

public void SQL_CallBack_ErrorHandle(Database hDatabase, DBResultSet hResults, const char[] szError, any data) {
    if(!hResults && strlen(szError)) {
        LogError("[Premium] SQL_CallBack_ErrorHandle - error while working with data (%s)", szError);
        CORE_Debug(QUERY, "SQL_CallBack_ErrorHandle - An error occurred while executing the query - %s", szError);
    }
}