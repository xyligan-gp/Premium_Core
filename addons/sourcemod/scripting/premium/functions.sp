stock void InitCore() {
    BuildPath(Path_SM, g_szLogsFile, sizeof g_szLogsFile, LOGS_PATH);

    API_CreateForward_OnReady();
}

stock void InitEngine() {
    g_hEngine = GetEngineVersion();

    if(g_hEngine != Engine_SourceSDK2006 && g_hEngine != Engine_CSS && g_hEngine != Engine_CSGO)
        SetFailState("Current plugin supports the following games: CS:S v34, CS:S OrangeBox and CS:GO!");
}

stock void InitConfig(bool bIsNotify = false, int iClient = 0) {
    BuildPath(Path_SM, g_szConfig, sizeof g_szConfig, CONFIG_PATH);

    if(g_hConfigs[CONFIG_MAIN] != INVALID_HANDLE)
        delete g_hConfigs[CONFIG_MAIN];
    
    g_hConfigs[CONFIG_MAIN] = CreateKeyValues("Premium");

    if(!FileToKeyValues(g_hConfigs[CONFIG_MAIN], g_szConfig))
        SetFailState("Failed to load the main configuration file of the plugin: %s", g_szConfig);
    
    char szFlags[16];
    KvGetString(g_hConfigs[CONFIG_MAIN], "AccessAdminFlags", szFlags, sizeof szFlags, "z");
    g_iAdminFlags = ReadFlagString(szFlags);

    KvGetString(g_hConfigs[CONFIG_MAIN], "DatabaseTableName", g_szTablePrefix, sizeof g_szTablePrefix, "premium");

    g_fCheckInterval = KvGetFloat(g_hConfigs[CONFIG_MAIN], "CheckPremiumAccessInterval", 0.1);

    g_bIsNotify[0] = view_as<bool>(KvGetNum(g_hConfigs[CONFIG_MAIN], "GiveAccessNotify", 1));
    g_bIsNotify[1] = view_as<bool>(KvGetNum(g_hConfigs[CONFIG_MAIN], "RemoveAccessNotify", 1));
    g_bIsNotify[2] = view_as<bool>(KvGetNum(g_hConfigs[CONFIG_MAIN], "ConnectAccessNotify", 1));

    if(bIsNotify) {
        char szBuffer[PLATFORM_MAX_PATH];
        FormatEx(szBuffer, sizeof szBuffer, "%T", "Messages_ReloadConfig", iClient);

        CORE_PrintToChat(iClient, szBuffer);
        
        char szAuth[MAX_AUTHID_LENGTH];
        GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof szAuth);

        char szName[MAX_NAME_LENGTH];
        GetClientName(iClient, szName, sizeof szName);

        StringMap hData = CreateTrie();

        SetTrieString(hData, "0", szName);
        SetTrieString(hData, "1", szAuth);

        PrintToLogs("PremiumLog_ReloadConfiguration", hData);
    }
}

stock void InitCommands() {
    char szConfigCommands[1024];
    KvGetString(g_hConfigs[CONFIG_MAIN], "PremiumMenuCommands", szConfigCommands, sizeof szConfigCommands, "sm_vip;sm_premium");

    char szCommands[16][32];
    int iLength = ExplodeString(szConfigCommands, ";", szCommands, sizeof szCommands, sizeof szCommands[]);

    for(int i; i < iLength; i++)
        RegConsoleCmd(szCommands[i], Call_PremiumMenu);
}

stock void InitComponents() {
    g_hGroups = CreateTrie();

    PrecacheSound(NO_ACCESS_SOUND, true);
}

stock void FetchPremiumUsers() {
    if(g_hTimer == INVALID_HANDLE)
        g_hTimer = CreateTimer(g_fCheckInterval, Timer_FetchPremiumUsers, _, TIMER_REPEAT);
}

public Action Timer_FetchPremiumUsers(Handle hTimer) {
    char szQuery[PLATFORM_MAX_PATH];

    FormatEx(szQuery, sizeof szQuery, "SELECT * FROM `%s_users` ORDER BY `id` DESC", g_szTablePrefix);
    g_hDatabase.Query(SQL_CallBack_FetchPremiumUsers, szQuery);

    return Plugin_Continue;
}

stock void LoadPremiumGroups() {
    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof szPath, GROUPS_PATH);

    if(g_hConfigs[CONFIG_GROUPS] != INVALID_HANDLE)
        delete g_hConfigs[CONFIG_TIMES];
    
    g_hConfigs[CONFIG_GROUPS] = CreateKeyValues("Groups");

    if(!FileToKeyValues(g_hConfigs[CONFIG_GROUPS], szPath))
        SetFailState("Failed to load configuration file with groups: %s", szPath);
    
    KvRewind(g_hConfigs[CONFIG_GROUPS]);

    if(KvGotoFirstSubKey(g_hConfigs[CONFIG_GROUPS], false)) {
        char szGroup[MAX_GROUP_LENGTH];

        do {
            KvGetSectionName(g_hConfigs[CONFIG_GROUPS], szGroup, sizeof szGroup);

            LoadGroupFeatures(szGroup);
        }while(KvGotoNextKey(g_hConfigs[CONFIG_GROUPS]))
    }
}

stock void LoadGroupFeatures(const char[] szGroup) {
    if(KvGotoFirstSubKey(g_hConfigs[CONFIG_GROUPS], false)) {
        StringMap hFeatures = CreateTrie();

        do {
            char szFeature[MAX_FEATURE_LENGTH], szValue[PLATFORM_MAX_PATH];

            KvGetSectionName(g_hConfigs[CONFIG_GROUPS], szFeature, sizeof szFeature);
            KvGetString(g_hConfigs[CONFIG_GROUPS], NULL_STRING, szValue, sizeof szValue);

            StringToUpperCase(szFeature, 0, 1);

            SetTrieString(hFeatures, szFeature, szValue);
        }while(KvGotoNextKey(g_hConfigs[CONFIG_GROUPS], false))

        KvGoBack(g_hConfigs[CONFIG_GROUPS]);

        SetTrieValue(g_hGroups, szGroup, hFeatures);
    }
}

stock bool IsInteger(char[] szBuffer) {
    int iBufferSize = strlen(szBuffer);

    for(int i; i < iBufferSize; i++)
        if(szBuffer[i] != '.' && !IsCharNumeric(szBuffer[i])) return false;

    return true;
}

stock bool IsBoolean(char[] szBuffer) {
    if(StrEqual(szBuffer, "true") || StrEqual(szBuffer, "false")) return true;
    else return false;
}

stock void StringToUpperCase(char[] szText, int iStartLen = 0, int iEndLen = 0) {
    int iLen = strlen(szText) + 1;

    if(1 > iEndLen || iLen < iEndLen)
        iEndLen = iLen;

    for(int i = iStartLen; i != iEndLen; i++)
        szText[i] &= ~0x20;
}

stock void CreateClientData(int iClient) {
    g_hClientData[iClient] = CreateTrie();
}

stock void ClearClientData(int iClient) {
    if(g_hClientData[iClient] != INVALID_HANDLE)
        delete g_hClientData[iClient];
}

stock bool IsValidClientFeature(int iClient, const char[] szFeature) {
    char szAuth[MAX_AUTHID_LENGTH], szEscapedFeature[MAX_FEATURE_LENGTH], szQuery[PLATFORM_MAX_PATH];
    GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof szAuth);

    SQL_EscapeString(g_hDatabase, szFeature, szEscapedFeature, sizeof szEscapedFeature);
    FormatEx(szQuery, sizeof szQuery, "SELECT `feature_status` FROM `%s_settings` WHERE `feature_id` = '%s' AND `auth` = '%s'", g_szTablePrefix, szFeature, szAuth);
    
    SQL_LockDatabase(g_hDatabase);
    DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
    SQL_UnlockDatabase(g_hDatabase);

    bool IsValid = SQL_FetchRow(hResults);
    CloseHandle(hResults);

    return IsValid;
}

stock int SearchFeatureParent(const char[] szFeature, char[] szBuffer, int iMaxLength) {
    int iBufLength = -1;

    if(GetTrieSize(g_hFeatures)) {
        Handle hFeatures = CreateTrieSnapshot(g_hFeatures);
        int iFeaturesCount = TrieSnapshotLength(hFeatures);

        for(int i = 0; i < iFeaturesCount; i++) {
            char szGlobalFeature[MAX_FEATURE_LENGTH];
            GetTrieSnapshotKey(hFeatures, i, szGlobalFeature, sizeof szGlobalFeature);

            if(strlen(szGlobalFeature) == strlen(szFeature)) continue;
            if(StrEqual(szGlobalFeature, szFeature)) continue;

            if(strlen(szGlobalFeature) > strlen(szFeature)) {
                if(StrContains(szGlobalFeature, szFeature) != -1) {
                    iBufLength = strcopy(szBuffer, iMaxLength, szGlobalFeature);

                    break;
                }
            }else{
                if(StrContains(szFeature, szGlobalFeature) != -1) {
                    iBufLength = strcopy(szBuffer, iMaxLength, szGlobalFeature);

                    break;
                }
            }
        }

        CloseHandle(hFeatures);
    }

    return iBufLength;
}

stock void UpdatePremiumClientInfo(int iClient) {
    char szAuth[MAX_AUTHID_LENGTH], szName[MAX_NAME_LENGTH], szQuery[PLATFORM_MAX_PATH];
    
    GetClientName(iClient, szName, sizeof szName);
    GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof szAuth);

    char szEscapedName[MAX_NAME_LENGTH];
    SQL_EscapeString(g_hDatabase, szName, szEscapedName, sizeof szEscapedName);

    FormatEx(szQuery, sizeof szQuery, "UPDATE `%s_users` SET `player_name` = '%s', `jointime` = '%i' WHERE `player_auth` = '%s'", g_szTablePrefix, szEscapedName, GetTime(), szAuth);
    g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);
}

stock int GetClientGroup(const char[] szAuth, char[] szBuffer, int iMaxLength) {
    char szQuery[PLATFORM_MAX_PATH];
    FormatEx(szQuery, sizeof szQuery, "SELECT `group` FROM `%s_users` WHERE `player_auth` = '%s'", g_szTablePrefix, szAuth);

    SQL_LockDatabase(g_hDatabase);
    DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
    SQL_UnlockDatabase(g_hDatabase);

    if(SQL_FetchRow(hResults)) SQL_FetchString(hResults, 0, szBuffer, iMaxLength);
    else strcopy(szBuffer, iMaxLength, "premium1");

    CloseHandle(hResults);

    return strlen(szBuffer);
}

stock void SetClientGroup(const char[] szAuth, const char[] szGroup) {
    int iTarget = CORE_GetClientByAuth(szAuth);

    if(!CORE_IsValidClient(iTarget)) {
        char szQuery[PLATFORM_MAX_PATH];
        
        FormatEx(szQuery, sizeof szQuery, "UPDATE `%s_users` SET `group` = '%s' WHERE `player_auth` = '%s'", g_szTablePrefix, szGroup, szAuth);
        g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);
    }else
        if(CORE_IsClientHaveAccess(iTarget))
            CORE_SetClientGroup(iTarget, szGroup);
}

stock void PrintToLogs(char[] szPhrase, StringMap hData) {
    if(hData != INVALID_HANDLE) {
        char szValue[2048];

        for(int i = 0; i < 10; i++) {
            char szKey[4];
            IntToString(i, szKey, sizeof szKey);

            char szInValue[PLATFORM_MAX_PATH];
            GetTrieString(hData, szKey, szInValue, sizeof szInValue);

            if(!StrEqual(szInValue, ""))
                if(StrEqual(szValue, ""))
                    FormatEx(szValue, sizeof szValue, "%s", szInValue);
                else
                    FormatEx(szValue, sizeof szValue, "%s|=|%s", szValue, szInValue);
        }

        char szBuffer[10][PLATFORM_MAX_PATH];
        ExplodeString(szValue, "|=|", szBuffer, sizeof szBuffer, sizeof szBuffer[]);

        SetGlobalTransTarget(LANG_SERVER);
        LogToFileEx(g_szLogsFile, "%t", szPhrase, szBuffer[0], szBuffer[1], szBuffer[2], szBuffer[3], szBuffer[4], szBuffer[5], szBuffer[6], szBuffer[7], szBuffer[8], szBuffer[9]);

        CloseHandle(hData);
    }
}

stock int GetPremiumClientName(char[] szAuth, char[] szBuffer, int iMaxLength) {
    char szQuery[PLATFORM_MAX_PATH];
    FormatEx(szQuery, sizeof szQuery, "SELECT `player_name` FROM `%s_users` WHERE `player_auth` = '%s'", g_szTablePrefix, szAuth);

    SQL_LockDatabase(g_hDatabase);
    DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
    SQL_UnlockDatabase(g_hDatabase);

    if(SQL_FetchRow(hResults)) SQL_FetchString(hResults, 0, szBuffer, iMaxLength);
    else strcopy(szBuffer, iMaxLength, "Unknown");

    CloseHandle(hResults);

    return strlen(szBuffer);
}

stock void CORE_PlaySound(int iClient, const char[] szSound) {
	ClientCommand(iClient, "playgamesound %s", szSound);
}

stock bool CORE_IsValidClient(int iClient) {
    if(iClient < 1 || iClient > MaxClients) return false;
    else if(!IsClientInGame(iClient)) return false;
    else if(IsFakeClient(iClient)) return false;

    return true;
}

stock DatabaseType CORE_GetDatabaseType() {
    char szDriver[10];

    g_hDatabase.Driver.GetIdentifier(szDriver, sizeof szDriver);

    return StrEqual(szDriver, "mysql") ? DB_TYPE_MYSQL : DB_TYPE_SQL;
}

stock int CORE_GetClientByAuth(const char[] szAuth) {
    for(int iClient = 1; iClient <= MaxClients; iClient++) {
        if(CORE_IsValidClient(iClient)) {
            char szClientAuth[MAX_AUTHID_LENGTH];
            GetClientAuthId(iClient, AuthId_Steam2, szClientAuth, sizeof szClientAuth);
            
            if(!strcmp(szClientAuth, szAuth)) return iClient;
        }
    }

    return -1;
}

stock void CORE_Debug(DebugType iType, const char[] szLog, any ...) {
    #if DEBUG_MODE == 1
        char szPath[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, szPath, sizeof szPath, DEBUG_PATH);

        char szBuffer[1024];
        VFormat(szBuffer, sizeof szBuffer, szLog, 3);

        if(iType == API) {
            #if defined DEBUG_API
                LogToFileEx(szPath, "API: %s", szBuffer);
            #endif
        }

        if(iType == QUERY) {
            #if defined DEBUG_SQL
                LogToFileEx(szPath, "SQL: %s", szBuffer);
            #endif
        }

        if(iType == MODULE) {
            #if defined DEBUG_MODULES
                LogToFileEx(szPath, "MODULE: %s", szBuffer);
            #endif
        }
    #endif
}

stock bool CORE_GiveClientAccess(int iTarget, const char[] szGroup, int iAdmin = 0, int iTime = 0) {
    ClearClientData(iTarget);
    
    char szName[2][MAX_NAME_LENGTH],
        szEscapedName[2][MAX_NAME_LENGTH],
        szAuth[2][32],
        szQuery[1024];

    if(CORE_IsValidClient(iAdmin)) {
        GetClientName(iAdmin, szName[0], sizeof szName[]);
        GetClientAuthId(iAdmin, AuthId_Steam2, szAuth[0], sizeof szAuth[]);
    }else{
        strcopy(szName[0], sizeof szName[], "SERVER");
        strcopy(szAuth[0], sizeof szAuth[], "SERVER_ID");
    }

    SQL_EscapeString(g_hDatabase, szName[0], szEscapedName[0], sizeof szEscapedName[]);

    if(CORE_IsValidClient(iTarget)) {
        GetClientName(iTarget, szName[1], sizeof szName[]);
        GetClientAuthId(iTarget, AuthId_Steam2, szAuth[1], sizeof szAuth[]);

        SQL_EscapeString(g_hDatabase, szName[1], szEscapedName[1], sizeof szEscapedName[]);
        FormatEx(szQuery, sizeof szQuery, "INSERT INTO `%s_users` (`group`, `player_name`, `player_auth`, `admin_name`, `admin_auth`, `timestamp`, `jointime`, `expires`) VALUES('%s', '%s', '%s', '%s', '%s', '%i', '%i', '%i')", g_szTablePrefix, szGroup, szEscapedName[1], szAuth[1], szEscapedName[0], szAuth[0], GetTime(), GetTime(), iTime == 0 ? iTime : GetTime() + iTime);

        SQL_LockDatabase(g_hDatabase);
        DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
        SQL_UnlockDatabase(g_hDatabase);
        CloseHandle(hResults);

        g_bIsHaveAccess[iTarget] = true;

        if(g_bIsNotify[0]) CORE_ShowMenu(iTarget, GIVE_ACCESS, 10);

        char szExpires[PLATFORM_MAX_PATH];
        CORE_FormatAccessTime(LANG_SERVER, iTime, szExpires, sizeof szExpires);

        StringMap hData = CreateTrie();

        SetTrieString(hData, "0", szName[0]);
        SetTrieString(hData, "1", szAuth[0]);
        SetTrieString(hData, "2", szName[1]);
        SetTrieString(hData, "3", szAuth[1]);
        SetTrieString(hData, "4", szGroup);
        SetTrieString(hData, "5", szExpires);

        PrintToLogs("PremiumLog_GiveAccess", hData);

        API_CreateForward_OnAddAccess(iTarget, iAdmin, szGroup, iTime);

        return true;
    }else LogError("Cannot find client with index '%i'!", iTarget);

    return false;
}

stock bool CORE_RemoveClientAccess(char[] szAuth, int iAdmin = 0, const char[] szReason = "Time has expired.") {
    char szQuery[PLATFORM_MAX_PATH];
    FormatEx(szQuery, sizeof szQuery, "DELETE FROM `%s_users` WHERE `player_auth` = '%s'", g_szTablePrefix, szAuth);

    SQL_LockDatabase(g_hDatabase);
    DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
    SQL_UnlockDatabase(g_hDatabase);
    
    char szAdminAuth[MAX_AUTHID_LENGTH], szName[2][MAX_NAME_LENGTH];

    int iTarget = CORE_GetClientByAuth(szAuth);

    if(CORE_IsValidClient(iTarget)) {
        g_bIsHaveAccess[iTarget] = false;

        GetClientName(iTarget, szName[0], sizeof szName[]);

        if(g_bIsNotify[1]) CORE_ShowMenu(iTarget, REMOVE_ACCESS, 10);
    }else GetPremiumClientName(szAuth, szName[0], sizeof szName[]);

    if(CORE_IsValidClient(iAdmin)) {
        GetClientName(iAdmin, szName[1], sizeof szName[]);
        GetClientAuthId(iAdmin, AuthId_Steam2, szAdminAuth, sizeof szAdminAuth);
    }else{
        FormatEx(szName[1], sizeof szName[], "SERVER");
        FormatEx(szAdminAuth, sizeof szAdminAuth, "SERVER_ID");
    }

    StringMap hData = CreateTrie();

    SetTrieString(hData, "0", szName[1]);
    SetTrieString(hData, "1", szAdminAuth);
    SetTrieString(hData, "2", szName[0]);
    SetTrieString(hData, "3", szAuth);

    PrintToLogs("PremiumLog_RemoveAccess", hData);

    CloseHandle(hResults);

    API_CreateForward_OnRemoveAccess(iTarget, iAdmin, szReason);

    return true;
}

stock bool CORE_IsClientHaveAccess(int iClient) {
    return g_bIsHaveAccess[iClient];
}

stock int CORE_FormatAccessTime(int iClient, int iTime, char[] szBuffer, int iMaxLength) {
    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof szPath, TIMES_PATH);

    if(g_hConfigs[CONFIG_TIMES] != INVALID_HANDLE)
        delete g_hConfigs[CONFIG_TIMES];
    
    g_hConfigs[CONFIG_TIMES] = CreateKeyValues("Times");

    if(!FileToKeyValues(g_hConfigs[CONFIG_TIMES], szPath))
        SetFailState("Failed to load configuration file with times: %s", szPath);

    KvRewind(g_hConfigs[CONFIG_TIMES]);

    if(KvGotoFirstSubKey(g_hConfigs[CONFIG_TIMES])) {
        char szValue[PLATFORM_MAX_PATH], szSection[32], szLang[2][10];

        GetLanguageInfo(GetServerLanguage(), szLang[0], sizeof szLang[]);
        
        if(iClient != 0) GetLanguageInfo(GetClientLanguage(iClient), szLang[1], sizeof szLang[]);
        else GetLanguageInfo(GetServerLanguage(), szLang[1], sizeof szLang[]);

        do {
            KvGetSectionName(g_hConfigs[CONFIG_TIMES], szSection, sizeof szSection);
            KvGetString(g_hConfigs[CONFIG_TIMES], szLang[1], szValue, sizeof szValue, "LangError");

            if(!strlen(szValue))
                KvGetString(g_hConfigs[CONFIG_TIMES], szLang[0], szValue, sizeof szValue, "LangError");

            if(StringToInt(szSection) == iTime)
                strcopy(szBuffer, iMaxLength, szValue);
        }while(KvGotoNextKey(g_hConfigs[CONFIG_TIMES], false));
    }

    return strlen(szBuffer);
}

stock int CORE_FormatTime(int iTimeStamp, int iClient = LANG_SERVER, char[] szBuffer, int iMaxLength) {
	if(iTimeStamp > 31536000) {
		int iYears = iTimeStamp / 31536000, i = iTimeStamp - iYears * 31536000;
		
        if(i > 2592000) FormatEx(szBuffer, iMaxLength, "%T", "TimeLeft_YearMonths", iClient, iYears, i / 2592000);
		else FormatEx(szBuffer, iMaxLength, "%T", "TimeLeft_Years", iClient, iYears);

		return strlen(szBuffer);
	}

	if(iTimeStamp > 2592000) {
		int iMonths = iTimeStamp / 2592000, i = iTimeStamp - iMonths * 2592000;
		
        if(i > 86400) FormatEx(szBuffer, iMaxLength, "%T", "TimeLeft_MonthDays", iClient, iMonths, i / 86400);
		else FormatEx(szBuffer, iMaxLength, "%T", "TimeLeft_Months", iClient, iMonths);

		return strlen(szBuffer);
	}

	if(iTimeStamp > 86400) {
		int iDays = iTimeStamp / 86400 % 365, iHours = iTimeStamp / 3600 % 24;
		
        if(iHours > 0) FormatEx(szBuffer, iMaxLength, "%T", "TimeLeft_DayHours", iClient, iDays, iHours);
		else FormatEx(szBuffer, iMaxLength, "%T", "TimeLeft_Days", iClient, iDays);

		return strlen(szBuffer);
	}

	int iHours = iTimeStamp / 3600, iMins = iTimeStamp / 60 % 60, iSecs = iTimeStamp % 60;
	
    if(iHours > 0) FormatEx(szBuffer, iMaxLength, "%T", "TimeLeft_Default", iClient, iHours, iMins, iSecs);
	else FormatEx(szBuffer, iMaxLength, "%T", "TimeLeft_MinSecs", iClient, iMins, iSecs);

	return strlen(szBuffer);
}

stock bool CORE_IsValidFeature(const char[] szFeature, const char[] szGroup) {
    StringMap hFeatures;

    if(GetTrieValue(g_hGroups, szGroup, hFeatures)) {
        char szValue[PLATFORM_MAX_PATH];
        if(GetTrieString(hFeatures, szFeature, szValue, sizeof szValue)) return true;

        return false;
    }

    return false;
}

stock bool CORE_GetFeatureStatus(const char[] szFeature, const char[] szGroup) {
    StringMap hFeatures;
    bool bIsEnabled = false;

    if(GetTrieValue(g_hGroups, szGroup, hFeatures)) {
        char szValue[PLATFORM_MAX_PATH];
        
        if(GetTrieString(hFeatures, szFeature, szValue, sizeof szValue)) {
            if(IsInteger(szValue)) bIsEnabled = view_as<bool>(StringToInt(szValue));
            else if(IsBoolean(szValue)) bIsEnabled = StrEqual(szValue, "true");
            else if(strlen(szValue)) bIsEnabled = true;
            else bIsEnabled = false;
        }
    }

    return bIsEnabled;
}

stock bool CORE_GetClientFeatureStatus(int iClient, const char[] szFeature) {
    bool bIsEnabled = false;
    char szAuth[MAX_AUTHID_LENGTH], szEscapedFeature[MAX_FEATURE_LENGTH], szQuery[PLATFORM_MAX_PATH];
    GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof szAuth);

    SQL_EscapeString(g_hDatabase, szFeature, szEscapedFeature, sizeof szEscapedFeature);
    FormatEx(szQuery, sizeof szQuery, "SELECT `feature_status` FROM `%s_settings` WHERE `feature_id` = '%s' AND `auth` = '%s'", g_szTablePrefix, szEscapedFeature, szAuth);
    
    SQL_LockDatabase(g_hDatabase);
    DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
    SQL_UnlockDatabase(g_hDatabase);
    
    if(SQL_FetchRow(hResults)) bIsEnabled = SQL_FetchInt(hResults, 0) ? true : false;
    else bIsEnabled = true;

    CloseHandle(hResults);
    
    return bIsEnabled;
}

stock void CORE_SetClientFeatureStatus(int iClient, const char[] szFeature, bool bIsEnabled) {
    char szAuth[MAX_AUTHID_LENGTH], szEscapedFeature[MAX_FEATURE_LENGTH], szQuery[PLATFORM_MAX_PATH];
    GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof szAuth);

    SQL_EscapeString(g_hDatabase, szFeature, szEscapedFeature, sizeof szEscapedFeature);

    if(IsValidClientFeature(iClient, szFeature)) FormatEx(szQuery, sizeof szQuery, "UPDATE `%s_settings` SET `feature_status` = '%i' WHERE `feature_id` = '%s' AND `auth` = '%s'", g_szTablePrefix, view_as<int>(bIsEnabled), szFeature, szAuth);
    else FormatEx(szQuery, sizeof szQuery, "INSERT INTO `%s_settings` (`auth`, `feature_id`, `feature_status`) VALUES ('%s', '%s', '%i')", g_szTablePrefix, szAuth, szFeature, view_as<int>(bIsEnabled));
    
    g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);
}

stock int CORE_GetClientExpires(int iClient) {
    char szAuth[MAX_AUTHID_LENGTH], szQuery[PLATFORM_MAX_PATH];

    GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof szAuth);
    FormatEx(szQuery, sizeof szQuery, "SELECT `expires` FROM `%s_users` WHERE `player_auth` = '%s'", g_szTablePrefix, szAuth);

    SQL_LockDatabase(g_hDatabase);
    DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
    SQL_UnlockDatabase(g_hDatabase);

    int iExpires;

    if(SQL_FetchRow(hResults)) iExpires = SQL_FetchInt(hResults, 0);
    else iExpires = -1;

    CloseHandle(hResults);

    return iExpires;
}

stock int CORE_GetClientGroup(int iClient, char[] szBuffer, int iMaxLength) {
    char szAuth[MAX_AUTHID_LENGTH], szQuery[PLATFORM_MAX_PATH];

    GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof szAuth);
    FormatEx(szQuery, sizeof szQuery, "SELECT `group` FROM `%s_users` WHERE `player_auth` = '%s'", g_szTablePrefix, szAuth);

    SQL_LockDatabase(g_hDatabase);
    DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
    SQL_UnlockDatabase(g_hDatabase);

    if(SQL_FetchRow(hResults)) SQL_FetchString(hResults, 0, szBuffer, iMaxLength);
    else strcopy(szBuffer, iMaxLength, "premium1");

    CloseHandle(hResults);

    return strlen(szBuffer);
}

stock void CORE_SetClientGroup(int iClient, const char[] szGroup) {
    char szAuth[MAX_AUTHID_LENGTH], szQuery[PLATFORM_MAX_PATH];

    GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof szAuth);
    FormatEx(szQuery, sizeof szQuery, "UPDATE `%s_users` SET `group` = '%s' WHERE `player_auth` = '%s'", g_szTablePrefix, szGroup, szAuth);

    g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);
}

stock void CORE_PrintToChat(int iClient, const char[] szMessage) {
	if(CORE_IsValidClient(iClient)) {
		SetGlobalTransTarget(iClient);
		
		switch(g_hEngine) {
            case Engine_SourceSDK2006: CPrintToChat(iClient, "%t %s", "ChatPrefix", szMessage);
            case Engine_CSS: CPrintToChat(iClient, "%t %s", "ChatPrefix", szMessage);
            case Engine_CSGO: CGOPrintToChat(iClient, "%t %s", "ChatPrefix", szMessage);
        }
	}
}

stock void CORE_PrintToChatAll(const char[] szMessage) {
	for (int iTarget = 1; iTarget <= MaxClients; iTarget++) {
		if (CORE_IsValidClient(iTarget)) CORE_PrintToChat(iTarget, szMessage);
	}
}

stock int CORE_RegisterFeature(
    Handle hPlugin, PremiumFeatureType iType = STATUS,
    const char[] szFeature, Function OnItemSelect,
    Function OnItemDisplay = INVALID_FUNCTION,
    Function OnItemDraw = INVALID_FUNCTION
) {
    DataPack hPack;
    
    if(!GetTrieValue(g_hFeatures, szFeature, hPack)) {
        hPack = CreateDataPack();

        WritePackCell(hPack, hPlugin);
        WritePackCell(hPack, iType);
        WritePackFunction(hPack, OnItemSelect);
        WritePackFunction(hPack, OnItemDisplay);
        WritePackFunction(hPack, OnItemDraw);

        SetTrieValue(g_hFeatures, szFeature, hPack);

        API_CreateForward_OnFeatureRegistered(szFeature);

        return GetTrieSize(g_hFeatures);
    }

    return -1;
}

stock bool CORE_IsRegisteredFeature(const char[] szFeature) {
    DataPack hPack;

    return GetTrieValue(g_hFeatures, szFeature, hPack);
}

stock int CORE_UnregisterFeature(const char[] szFeature) {
    DataPack hPack;

    if(GetTrieValue(g_hFeatures, szFeature, hPack)) {
        RemoveFromTrie(g_hFeatures, szFeature);

        if(hPack != INVALID_HANDLE)
            delete hPack;
        
        API_CreateForward_OnFeatureUnregistered(szFeature);

        return GetTrieSize(g_hFeatures);
    }

    return -1;
}

stock bool CORE_IsAllowedFirstRound(const char[] szFeature) {
    bool bIsAllowed = true;
    
    char szMap[MAX_MAP_LENGTH];
    GetCurrentMap(szMap, sizeof szMap);

    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof szPath, CONFIG_PATH);

    if(g_hConfigs[CONFIG_MAIN] != INVALID_HANDLE)
        delete g_hConfigs[CONFIG_MAIN];
    
    g_hConfigs[CONFIG_MAIN] = CreateKeyValues("Premium");

    if(!FileToKeyValues(g_hConfigs[CONFIG_MAIN], szPath))
        SetFailState("Failed to load the main configuration file of the plugin: %s", szPath);
    
    KvRewind(g_hConfigs[CONFIG_MAIN]);

    if(KvJumpToKey(g_hConfigs[CONFIG_MAIN], "FirstRounds")) {
        char szMapsList[1024];
        KvGetString(g_hConfigs[CONFIG_MAIN], szFeature, szMapsList, sizeof szMapsList);

        if(!strlen(szMapsList))
            return true;
        
        char szMaps[MAX_CONFIG_MAPS][MAX_MAP_LENGTH];
        int iMapsCount = ExplodeString(szMapsList, ";", szMaps, sizeof szMaps, sizeof szMaps[]);

        for(int i = 0; i < iMapsCount; i++) {
            if(StrEqual(szMaps[i], szMap) && g_bIsFirstRound) {
                bIsAllowed = false;

                break;
            }
        }
    }

    return bIsAllowed;
}

stock bool CORE_IsAllowedFeature(const char[] szFeature) {
    bool bIsAllowed = true;
    
    char szMap[MAX_MAP_LENGTH];
    GetCurrentMap(szMap, sizeof szMap);

    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof szPath, CONFIG_PATH);

    if(g_hConfigs[CONFIG_MAIN] != INVALID_HANDLE)
        delete g_hConfigs[CONFIG_MAIN];
    
    g_hConfigs[CONFIG_MAIN] = CreateKeyValues("Premium");

    if(!FileToKeyValues(g_hConfigs[CONFIG_MAIN], szPath))
        SetFailState("Failed to load the main configuration file of the plugin: %s", szPath);
    
    KvRewind(g_hConfigs[CONFIG_MAIN]);

    if(KvJumpToKey(g_hConfigs[CONFIG_MAIN], "Blockedmaps")) {
        char szMapsList[1024];
        KvGetString(g_hConfigs[CONFIG_MAIN], szFeature, szMapsList, sizeof szMapsList);

        if(!strlen(szMapsList))
            return true;
        
        char szMaps[MAX_CONFIG_MAPS][MAX_MAP_LENGTH];
        int iMapsCount = ExplodeString(szMapsList, ";", szMaps, sizeof szMaps, sizeof szMaps[]);

        for(int i = 0; i < iMapsCount; i++) {
            if(StrEqual(szMaps[i], szMap) /* && g_bIsFirstRound */ ) {
                bIsAllowed = false;

                break;
            }
        }
    }

    return bIsAllowed;
}

stock bool CORE_IsValidGroup(const char[] szGroup) {
    StringMap hGroupFeatures;
    GetTrieValue(g_hGroups, szGroup, hGroupFeatures);

    return hGroupFeatures != INVALID_HANDLE;
}

stock int CORE_GetFeatureValue(int iClient, char[] szFeature, char[] szBuffer, int iMaxLength) {
    int iBufLength = -1;
    
    if(CORE_IsValidClient(iClient)) {
        char szGroup[MAX_GROUP_LENGTH];
        CORE_GetClientGroup(iClient, szGroup, sizeof szGroup);

        StringMap hFeatures;
        GetTrieValue(g_hGroups, szGroup, hFeatures);

        if(hFeatures != INVALID_HANDLE) {
            GetTrieString(hFeatures, szFeature, szBuffer, iMaxLength);
            iBufLength = strlen(szBuffer);
        }
    }

    return iBufLength;
}

stock void ClearGroups() {
    char szGroup[MAX_GROUP_LENGTH];
    Handle hGroups = CreateTrieSnapshot(g_hGroups);
    int iGroupsCount = TrieSnapshotLength(hGroups);

    for(int i = 0; i < iGroupsCount; i++) {
        GetTrieSnapshotKey(hGroups, i, szGroup, sizeof szGroup);

        StringMap hFeatures;
        GetTrieValue(g_hGroups, szGroup, hFeatures);

        if(hFeatures != INVALID_HANDLE)
            delete hFeatures;
    }

    delete hGroups;
    delete g_hGroups;
}

stock void ClearFeatures() {
    char szFeature[MAX_FEATURE_LENGTH];
    Handle hFeatures = CreateTrieSnapshot(g_hFeatures);
    int iFeaturesCount = TrieSnapshotLength(hFeatures);

    for(int i = 0; i < iFeaturesCount; i++) {
        GetTrieSnapshotKey(hFeatures, i, szFeature, sizeof szFeature);

        DataPack hPack;
        GetTrieValue(g_hFeatures, szFeature, hPack);

        if(hPack != INVALID_HANDLE)
            delete hPack;
    }

    delete hFeatures;
    delete g_hFeatures;
}