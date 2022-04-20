public void OnConfigsExecuted() {
    InitialSounds();
    InitialCommands();
    InitialAdminMenu();
    InitialKeyValues();

    FetchExpiredPlayers();
    FetchPremiumDatabase();
}

public void OnLibraryRemoved(const char[] szName) {
    if(StrEqual(szName, "adminmenu")) g_hTopMenu = null;
}

stock void InitialCore() {
    g_bIsReady = true;
    g_hFeatures = CreateTrie();
    
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

    API_CreateForward_OnReady();
}

stock void InitialEngine() {
    g_GameEngine = GetEngineVersion();

    if(g_GameEngine != Engine_SourceSDK2006 && g_GameEngine != Engine_CSS && g_GameEngine != Engine_CSGO) SetFailState("[Premium] The current plugin supports the following games: CS:S v34, CS:S OB and CS:GO!");
}

stock void InitialTranslations() {
    LoadTranslations("premium.core.phrases");
    LoadTranslations("premium.modules.phrases");
}

stock void InitialKeyValues() {
    g_hKV_BlockedMaps = CreateKeyValues("Premium_BlockedMaps");
    g_hKV_FirstRounds = CreateKeyValues("Premium_FirstRounds");
    g_hKV_AccessTimes = CreateKeyValues("Premium_AccessTimes");
}

stock void InitialConfiguration() {
    g_hPluginTag = CreateConVar("sm_premium_tag", "[Premium]", "Префик плагина в серверном чате");
    g_hAdminMenuFlags = CreateConVar("sm_premium_flags", "z", "Флаги доступа в меню управления Premium");
    g_hCheckInterval = CreateConVar("sm_premium_check_interval", "0.1", "Интервал проверки игроков на наличие Premium-доступа (в секундах) [Рекомендуется изменять если сервер сильно нагружен и появляются фризы]");
    g_hLogPath = CreateConVar("sm_premium_log_path", "logs/premium.log", "Путь к лог-файлу плагина");
    g_hDebugPath = CreateConVar("sm_premium_debug_path", "logs/premium.debug.log", "Путь к файлу-отладке плагина");
    g_hPluginCommands = CreateConVar("sm_premium_commands", "sm_vip;sm_premium", "Команды плагина для вызова главного меню");
    g_hIsNotifyPlayer_Add = CreateConVar("sm_premium_notify_add", "1", "Уведомлять игрока о получении Premium-доступа выводом специального меню [0 - Выключить | 1 - Включить]");
    g_hIsNotifyPlayer_Connect = CreateConVar("sm_premium_notify_connect", "1", "Уведомлять игрока при входе на сервер о наличии Premium-доступа выводом специального меню [0 - Выключить | 1 - Включить]");
    g_hIsNotifyPlayer_Expired = CreateConVar("sm_premium_notify_expired", "1", "Уведомлять игрока об окончании срока действия Premium-доступа выводом специального меню [0 - Выключить | 1 - Включить]");

    AutoExecConfig(true, "core", "premium");
    FetchConfigValues();

    HookConVarChange(g_hPluginTag, OnConVarValueChanged);
    HookConVarChange(g_hAdminMenuFlags, OnConVarValueChanged);
    HookConVarChange(g_hCheckInterval, OnConVarValueChanged);
    HookConVarChange(g_hLogPath, OnConVarValueChanged);
    HookConVarChange(g_hDebugPath, OnConVarValueChanged);
    HookConVarChange(g_hPluginCommands, OnConVarValueChanged);
    HookConVarChange(g_hIsNotifyPlayer_Add, OnConVarValueChanged);
    HookConVarChange(g_hIsNotifyPlayer_Connect, OnConVarValueChanged);
    HookConVarChange(g_hIsNotifyPlayer_Expired, OnConVarValueChanged);
}

stock void InitialSounds() {
    PrecacheSound(NO_ACCESS_SOUND, true);
}

stock void InitialCommands() {
    char szBuffer[8][32];

    int iBuffer = ExplodeString(g_szPluginCommands, ";", szBuffer, sizeof szBuffer, sizeof szBuffer[]);

    for(int i; i < iBuffer; i++) RegConsoleCmd(szBuffer[i], Call_PremiumMenu);
}

stock void FetchConfigValues() {
    GetConVarString(g_hPluginTag, g_szPluginTag, sizeof g_szPluginTag);
    g_fCheckInterval = GetConVarFloat(g_hCheckInterval);
    
    char szBuffer[PLATFORM_MAX_PATH];
    g_hAdminMenuFlags.GetString(szBuffer, sizeof szBuffer);
    g_iAdminMenuFlags = ReadFlagString(szBuffer);

    g_hLogPath.GetString(szBuffer, sizeof szBuffer);
    BuildPath(Path_SM, g_szLogPath, sizeof g_szLogPath, szBuffer);

    g_hDebugPath.GetString(szBuffer, sizeof szBuffer);
    BuildPath(Path_SM, g_szDebugPath, sizeof g_szDebugPath, szBuffer);

    g_bIsNotifyPlayer_Add = GetConVarBool(g_hIsNotifyPlayer_Add);
    g_bIsNotifyPlayer_Connect = GetConVarBool(g_hIsNotifyPlayer_Connect);
    g_bIsNotifyPlayer_Expired = GetConVarBool(g_hIsNotifyPlayer_Expired);

    GetConVarString(g_hPluginCommands, g_szPluginCommands, sizeof g_szPluginCommands);
}

public void OnConVarValueChanged(Handle hCvar, const char[] szOldValue, const char[] szNewValue) {
    if(hCvar == g_hPluginTag) strcopy(g_szPluginTag, sizeof g_szPluginTag, szNewValue);
    if(hCvar == g_hAdminMenuFlags) g_iAdminMenuFlags = ReadFlagString(szNewValue);
    if(hCvar == g_hCheckInterval) g_fCheckInterval = StringToFloat(szNewValue);
    if(hCvar == g_hLogPath) BuildPath(Path_SM, g_szLogPath, sizeof g_szLogPath, szNewValue);
    if(hCvar == g_hDebugPath) BuildPath(Path_SM, g_szDebugPath, sizeof g_szDebugPath, szNewValue);
    if(hCvar == g_hPluginCommands) strcopy(g_szPluginCommands, sizeof g_szPluginCommands, szNewValue);
    if(hCvar == g_hIsNotifyPlayer_Add) g_bIsNotifyPlayer_Add = GetConVarBool(hCvar);
    if(hCvar == g_hIsNotifyPlayer_Connect) g_bIsNotifyPlayer_Connect = GetConVarBool(hCvar);
    if(hCvar == g_hIsNotifyPlayer_Expired) g_bIsNotifyPlayer_Expired = GetConVarBool(hCvar);
}

stock bool PM_IsValidClient(int iClient) {
    if(!iClient || iClient > MaxClients) return false;
    else if(!IsClientInGame(iClient)) return false;
    else if(IsFakeClient(iClient)) return false;

    return true;
}

stock int GetClientBySteamID(const char[] szSteamID) {
    for(int iClient = 1; iClient <= MaxClients; iClient++) {
        GetClientAuthId(iClient, AuthId_Steam2, g_szSteamID[iClient], sizeof g_szSteamID[]);
        
        if(!strcmp(szSteamID, g_szSteamID[iClient])) return iClient;
    }

    return -1;
}

stock int GetPremiumTime(int iClient, int iTime, char[] szBuffer, int iMaxLength) {
    char szPath[PLATFORM_MAX_PATH], szTimeBuffer[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, szPath, sizeof szPath, "data/premium/cfg/times.ini");

	if(!g_hKV_AccessTimes.ImportFromFile(szPath)) SetFailState("[Premium] Times config is missing: %s", szPath);

	if(g_hKV_AccessTimes.GotoFirstSubKey()) {
		char szBufferTime[PLATFORM_MAX_PATH], szTime[32], szClientLang[4], szServerLang[4];

		GetLanguageInfo(GetClientLanguage(iClient), szClientLang, sizeof szClientLang);
		GetLanguageInfo(GetServerLanguage(), szServerLang, sizeof szServerLang);

		do {
			KvGetSectionName(g_hKV_AccessTimes, szTime, sizeof szTime);
			KvGetString(g_hKV_AccessTimes, szClientLang, szBufferTime, sizeof szBufferTime, "LangError");

			if(!szBufferTime[0]) KvGetString(g_hKV_AccessTimes, szServerLang, szBufferTime, sizeof szBufferTime, "LangError");

            if(StringToInt(szTime) == iTime) strcopy(szTimeBuffer, sizeof szTimeBuffer, szBufferTime);
		} while(g_hKV_AccessTimes.GotoNextKey(false));
	}

    return strcopy(szBuffer, iMaxLength, szTimeBuffer);
}

stock int PM_GetClientExpires(int iClient) {
    int iExpires;
    char szQuery[PLATFORM_MAX_PATH];
    GetClientAuthId(iClient, AuthId_Steam2, g_szSteamID[iClient], sizeof g_szSteamID[]);

    FormatEx(szQuery, sizeof szQuery, "SELECT `expires` FROM `premium_users` WHERE `playerSteam` = '%s'", g_szSteamID[iClient]);

    SQL_LockDatabase(g_hDatabase);
    DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
    SQL_UnlockDatabase(g_hDatabase);

    if(SQL_FetchRow(hResults)) iExpires = hResults.FetchInt(0);
    else iExpires = -1;

    CloseHandle(hResults);

    return iExpires;
}

stock bool PM_RegisterFeature(const char[] szFeature, PremiumFeatureType iType, char[] szFeatureSetup = "") {
    bool bStatus;
    
    if(!GetTrieValue(g_hFeatures, szFeature, bStatus)) {
        char szKey[PLATFORM_MAX_PATH];

        if(iType == DEFAULT) FormatEx(szKey, sizeof szKey, "Feature->%s->Default", szFeature);

        if(iType == SELECTABLE) {
            if(!strlen(szFeatureSetup)) FormatEx(szFeatureSetup, PLATFORM_MAX_PATH, "%s_Setup", szFeature);
            FormatEx(szKey, sizeof szKey, "Feature->%s->Selectable->%s", szFeature, szFeatureSetup);
        }
        
        SetTrieString(g_hFeatures, szKey, szFeature);

        return true;
    }

    return false;
}

stock bool PM_UnRegisterFeature(const char[] szFeature) {
    bool bStatus;

    if(GetTrieValue(g_hFeatures, szFeature, bStatus)) {
        RemoveFromTrie(g_hFeatures, szFeature);

        return true;
    }

    return false;
}

stock bool PM_IsAllowedFeature(const char[] szFeature) {
    bool bAllowed = true;
    char szPath[PLATFORM_MAX_PATH], szMap[128], szFeatureNotAllowedMaps[PLATFORM_MAX_PATH], szBuffer[8][32];

    GetCurrentMap(szMap, sizeof szMap);
    BuildPath(Path_SM, szPath, sizeof szPath, "data/premium/cfg/blockedmaps.ini");

    if(!FileToKeyValues(g_hKV_BlockedMaps, szPath)) return true;

    KvGetString(g_hKV_BlockedMaps, szFeature, szFeatureNotAllowedMaps, sizeof szFeatureNotAllowedMaps);

    if(StrEqual(szFeatureNotAllowedMaps, "")) return true;

    int iBuffer = ExplodeString(szFeatureNotAllowedMaps, ";", szBuffer, sizeof szBuffer, sizeof szBuffer[]);

    for(int i; i < iBuffer; i++) {
        if(StrEqual(szBuffer[i], szMap)) {
            bAllowed = false;

            break;
        }
    }

    return bAllowed;
}

stock bool PM_IsAllowedFirstRound(const char[] szFeature) {
    bool bAllowed = true;
    char szPath[PLATFORM_MAX_PATH], szMap[128], szFeatureNotAllowedMaps[PLATFORM_MAX_PATH], szBuffer[8][32];

    GetCurrentMap(szMap, sizeof szMap);
    BuildPath(Path_SM, szPath, sizeof szPath, "data/premium/cfg/firstrounds.ini");

    if(!FileToKeyValues(g_hKV_FirstRounds, szPath)) return true;

    KvGetString(g_hKV_FirstRounds, szFeature, szFeatureNotAllowedMaps, sizeof szFeatureNotAllowedMaps);

    if(StrEqual(szFeatureNotAllowedMaps, "")) return true;

    int iBuffer = ExplodeString(szFeatureNotAllowedMaps, ";", szBuffer, sizeof szBuffer, sizeof szBuffer[]);

    for(int i; i < iBuffer; i++) {
        if(StrEqual(szBuffer[i], szMap) && g_bIsFirstRound) {
            bAllowed = false;

            break;
        }
    }

    return bAllowed;
}

stock void PM_GiveClientAccess(int iTarget, int iAdmin = 0, int iTime = 0) {
    char
        szQuery[1024],
        szAdminName[MAX_NAME_LENGTH],
        szPlayerName[MAX_NAME_LENGTH],
        szEscapedAdminName[MAX_NAME_LENGTH],
        szEscapedPlayerName[MAX_NAME_LENGTH];

    if(PM_IsValidClient(iAdmin)) {
        GetClientName(iAdmin, szAdminName, sizeof szAdminName);
        GetClientAuthId(iAdmin, AuthId_Steam2, g_szSteamID[iAdmin], sizeof g_szSteamID[]);

        g_hDatabase.Escape(szAdminName, szEscapedAdminName, sizeof szEscapedAdminName);
    }else{
        strcopy(szAdminName, sizeof szAdminName, "SERVER");
        strcopy(g_szSteamID[iAdmin], sizeof g_szSteamID[], "SERVER_ID");
    }
    
    if(PM_IsValidClient(iTarget)) {
        GetClientName(iTarget, szPlayerName, sizeof szPlayerName);
        GetClientAuthId(iTarget, AuthId_Steam2, g_szSteamID[iTarget], sizeof g_szSteamID[]);

        g_hDatabase.Escape(szPlayerName, szEscapedPlayerName, sizeof szEscapedPlayerName);
    }

    if(strlen(szPlayerName) > 0 && strlen(g_szSteamID[iTarget]) > 0) {
        FormatEx(szQuery, sizeof szQuery, "INSERT INTO `premium_users` (`adminName`, `adminSteam`, `playerName`, `playerSteam`, `lastjoin`, `timestamp`, `expires`) VALUES('%s', '%s', '%s', '%s', '%i', '%i', '%i')", szEscapedAdminName, g_szSteamID[iAdmin], szEscapedPlayerName, g_szSteamID[iTarget], GetTime(), GetTime(), iTime);
        g_hDatabase.Query(SQL_CallBack_GiveClientAccess, szQuery, GetClientUserId(iTarget));
    }else SetFailState("[Premium] Client index %i is invalid!", iTarget);
}

stock void PM_RemoveClientAccess(const char[] szSteam) {
    char szQuery[PLATFORM_MAX_PATH];

    FormatEx(szQuery, sizeof szQuery, "DELETE FROM `premium_users` WHERE `playerSteam` = '%s'", szSteam);
    g_hDatabase.Query(SQL_CallBack_RemoveClientAccess, szQuery, GetClientBySteamID(szSteam));
}

stock bool PM_GetClientFeatureStatus(int iClient, const char[] szFeature) {
    bool bFeatureStatus;
    char szQuery[PLATFORM_MAX_PATH], szEscapedFeature[128];
    GetClientAuthId(iClient, AuthId_Steam2, g_szSteamID[iClient], sizeof g_szSteamID[]);

    g_hDatabase.Escape(szFeature, szEscapedFeature, sizeof szEscapedFeature);
    FormatEx(szQuery, sizeof szQuery, "SELECT `use` FROM `premium_settings` WHERE `feature` = '%s' AND `player` = '%s'", szEscapedFeature, g_szSteamID[iClient]);
    
    SQL_LockDatabase(g_hDatabase);
    DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
    SQL_UnlockDatabase(g_hDatabase);
    
    if(SQL_FetchRow(hResults)) bFeatureStatus = SQL_FetchInt(hResults, 0) ? true : false;
    else bFeatureStatus = true;

    CloseHandle(hResults);
    
    return bFeatureStatus;
}

stock bool PM_SetClientFeatureStatus(int iClient, const char[] szFeature, bool bIsEnabled) {
    char szQuery[PLATFORM_MAX_PATH], szEscapedFeature[128];
    GetClientAuthId(iClient, AuthId_Steam2, g_szSteamID[iClient], sizeof g_szSteamID[]);

    g_hDatabase.Escape(szFeature, szEscapedFeature, sizeof szEscapedFeature);

    if(PM_IsValidClientFeature(iClient, szFeature)) FormatEx(szQuery, sizeof szQuery, "UPDATE `premium_settings` SET `use` = '%i' WHERE `feature` = '%s' AND `player` = '%s'", bIsEnabled ? 1 : 0, szFeature, g_szSteamID[iClient]);
    else FormatEx(szQuery, sizeof szQuery, "INSERT INTO `premium_settings` (`feature`, `player`, `use`) VALUES ('%s', '%s', '%i')", szFeature, g_szSteamID[iClient], bIsEnabled ? 1 : 0);
    
    return SQL_FastQuery(g_hDatabase, szQuery);
}

stock bool PM_IsValidClientFeature(int iClient, const char[] szFeature) {
    char szQuery[PLATFORM_MAX_PATH], szEscapedFeature[128];
    GetClientAuthId(iClient, AuthId_Steam2, g_szSteamID[iClient], sizeof g_szSteamID[]);

    g_hDatabase.Escape(szFeature, szEscapedFeature, sizeof szEscapedFeature);
    FormatEx(szQuery, sizeof szQuery, "SELECT `use` FROM `premium_settings` WHERE `feature` = '%s' AND `player` = '%s'", szFeature, g_szSteamID[iClient]);
    
    SQL_LockDatabase(g_hDatabase);
    DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
    SQL_UnlockDatabase(g_hDatabase);

    bool bIsValid = SQL_FetchRow(hResults);
    CloseHandle(hResults);

    return bIsValid;
}

stock void GetPremiumFromClient(int iClient) {
    char szQuery[PLATFORM_MAX_PATH];
    GetClientAuthId(iClient, AuthId_Steam2, g_szSteamID[iClient], sizeof g_szSteamID[]);

    FormatEx(szQuery, sizeof szQuery, "SELECT * FROM `premium_users` WHERE `playerSteam` = '%s'", g_szSteamID[iClient]);
    g_hDatabase.Query(SQL_CallBack_GetPremiumFromClient, szQuery, GetClientUserId(iClient));
}

stock void UpdateJoinTime(int iClient) {
    char szQuery[PLATFORM_MAX_PATH];
    GetClientAuthId(iClient, AuthId_Steam2, g_szSteamID[iClient], sizeof g_szSteamID[]);

    FormatEx(szQuery, sizeof szQuery, "UPDATE `premium_users` SET `lastjoin` = '%i' WHERE `playerSteam` = '%s'", GetTime(), g_szSteamID[iClient]);
    g_hDatabase.Query(SQL_CallBack_UpdateJoinTime, szQuery);
}

stock void PlaySound(int iClient, const char[] szSound) {
	ClientCommand(iClient, "playgamesound %s", szSound);
}

stock void PM_PrintToChat(int iClient, char[] szMessage, any...) {
    if(PM_IsValidClient(iClient)) {
        switch(g_GameEngine) {
            case Engine_SourceSDK2006: CPrintToChat(iClient, "%s %s", g_szPluginTag, szMessage);
            case Engine_CSS: CPrintToChat(iClient, "%s %s", g_szPluginTag, szMessage);
            case Engine_CSGO: CGOPrintToChat(iClient, "%s %s", g_szPluginTag, szMessage);
        }
    }
}

stock void PM_PrintToChatAll(char[] szMessage, any...) {
    for(int iClient = 1; iClient < MaxClients; iClient++) {
        if(PM_IsValidClient(iClient)) {
            switch(g_GameEngine) {
                case Engine_SourceSDK2006: CPrintToChat(iClient, "%s %s", g_szPluginTag, szMessage);
                case Engine_CSS: CPrintToChat(iClient, "%s %s", g_szPluginTag, szMessage);
                case Engine_CSGO: CGOPrintToChat(iClient, "%s %s", g_szPluginTag, szMessage);
            }
        }
    }
}