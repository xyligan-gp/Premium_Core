public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErrMax) {
    g_hGlobalForward[OnReady] = CreateGlobalForward("Premium_OnReady", ET_Ignore);
    g_hGlobalForward[OnAddAccess] = CreateGlobalForward("Premium_OnAddAccess", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell);
    g_hGlobalForward[OnRemoveAccess] = CreateGlobalForward("Premium_OnRemoveAccess", ET_Ignore, Param_Cell, Param_Cell, Param_String);
    g_hGlobalForward[OnClientJoin] = CreateGlobalForward("Premium_OnClientConnected", ET_Ignore, Param_Cell);
    g_hGlobalForward[OnClientLeave] = CreateGlobalForward("Premium_OnClientDisconnected", ET_Ignore, Param_Cell);
    g_hGlobalForward[OnClientSpawn] = CreateGlobalForward("Premium_OnPlayerSpawn", ET_Ignore, Param_Cell, Param_Cell);
    g_hGlobalForward[OnConfigsLoaded] = CreateGlobalForward("Premium_OnConfigsLoaded", ET_Ignore);
    g_hGlobalForward[OnFeatureRegistered] = CreateGlobalForward("Premium_OnFeatureRegistered", ET_Ignore, Param_String);
    g_hGlobalForward[OnFeatureUnregistered] = CreateGlobalForward("Premium_OnFeatureUnregistered", ET_Ignore, Param_String);

    CreateNative("Premium_IsReady", API_CreateNative_IsReady);
    CreateNative("Premium_IsValidClient", API_CreateNative_IsValidClient);
    CreateNative("Premium_IsClientHaveAccess", API_CreateNative_IsClientHaveAccess);
    CreateNative("Premium_IsValidGroup", API_CreateNative_IsValidGroup);
    CreateNative("Premium_IsValidFeature", API_CreateNative_IsValidFeature);
    CreateNative("Premium_IsRegisteredFeature", API_CreateNative_IsRegisteredFeature);
    CreateNative("Premium_IsAllowedFeature", API_CreateNative_IsAllowedFeature);
    CreateNative("Premium_IsAllowedFirstRound", API_CreateNative_IsAllowedFirstRound);

    CreateNative("Premium_GetConfig", API_CreateNative_GetConfig);
    CreateNative("Premium_GetGroups", API_CreateNative_GetGroups);
    CreateNative("Premium_GetFeatures", API_CreateNative_GetFeatures);
    CreateNative("Premium_GetFeatureValue", API_CreateNative_GetFeatureValue);

    CreateNative("Premium_GetDatabase", API_CreateNative_GetDatabase);
    CreateNative("Premium_GetDatabaseType", API_CreateNative_GetDatabaseType);
    CreateNative("Premium_GetDatabasePrefix", API_CreateNative_GetDatabasePrefix);

    CreateNative("Premium_GetClientByAuth", API_CreateNative_GetClientByAuth);
    CreateNative("Premium_GetClientGroup", API_CreateNative_GetClientGroup);
    CreateNative("Premium_GetClientExpires", API_CreateNative_GetClientExpires);

    CreateNative("Premium_GetClientFeatureStatus", API_CreateNative_GetClientFeatureStatus);
    CreateNative("Premium_SetClientFeatureStatus", API_CreateNative_SetClientFeatureStatus);

    CreateNative("Premium_GiveClientAccess", API_CreateNative_GiveAccess);
    CreateNative("Premium_SetClientGroup", API_CreateNative_SetClientGroup);
    CreateNative("Premium_RemoveClientAccess", API_CreateNative_RemoveAccess);

    CreateNative("Premium_PlaySound", API_CreateNative_PlaySound);
    CreateNative("Premium_ShowClientMenu", API_CreateNative_ShowMenu);

    CreateNative("Premium_RegisterFeature", API_CreateNative_RegisterFeature);
    CreateNative("Premium_UnregisterFeature", API_CreateNative_UnregisterFeature);

    CreateNative("Premium_PrintToChat", API_CreateNative_PrintToChat);
    CreateNative("Premium_PrintToChatAll", API_CreateNative_PrintToChatAll);

    CreateNative("Premium_Debug", API_CreateNative_Debug);
    CreateNative("Premium_FormatAccessTime", API_CreateNative_FormatAccessTime);

    RegPluginLibrary("premium");

    return APLRes_Success;
}

stock void API_CreateForward_OnReady() {
    g_bIsReady = true;

    CORE_Debug(API, "Forward: OnReady");

    Call_StartForward(g_hGlobalForward[OnReady]);
    Call_Finish();
}

stock void API_CreateForward_OnAddAccess(int iClient, int iAdmin, const char[] szGroup, int iTime) {
    CORE_Debug(API,
        "Forward: OnAddAccess | Client: (Index: %i - Username: %N) => Admin: (Index: %i - Username: %N) => Group: %s => Time: %i",
    iClient, iClient, iAdmin, iAdmin, szGroup, iTime);
    
    Call_StartForward(g_hGlobalForward[OnAddAccess]);

    Call_PushCell(iClient);
    Call_PushCell(iAdmin);
    Call_PushString(szGroup);
    Call_PushCell(iTime);

    Call_Finish();
}

stock void API_CreateForward_OnRemoveAccess(int iClient, int iAdmin, const char[] szReason) {
    CORE_Debug(API,
        "Forward: OnRemoveAccess | Client: (Index: %i - Username: %N) => Admin: (Index: %i - Username: %N) => Reason: %s",
    iClient, iClient, iAdmin, iAdmin, szReason);

    Call_StartForward(g_hGlobalForward[OnRemoveAccess]);

    Call_PushCell(iClient);
    Call_PushCell(iAdmin);
    Call_PushString(szReason);

    Call_Finish();
}

stock void API_CreateForward_OnClientConnected(int iClient) {
    CORE_Debug(API,
        "Forward: OnClientJoin | Client: (Index: %i - Username: %N)",
    iClient, iClient);

    Call_StartForward(g_hGlobalForward[OnClientJoin]);

    Call_PushCell(iClient);

    Call_Finish();
}

stock void API_CreateForward_OnClientDisconnected(int iClient) {
    CORE_Debug(API,
        "Forward: OnClientLeave | Client: (Index: %i - Username: %N)",
    iClient, iClient);

    Call_StartForward(g_hGlobalForward[OnClientLeave]);

    Call_PushCell(iClient);

    Call_Finish();
}

stock void API_CreateForward_OnPlayerSpawn(int iClient, int iTeam) {
    CORE_Debug(API,
        "Forward: OnPlayerSpawn | Client: (Index: %i - Username: %N) => Team: (Index: %i)",
    iClient, iClient, iTeam);

    Call_StartForward(g_hGlobalForward[OnClientSpawn]);

    Call_PushCell(iClient);
    Call_PushCell(iTeam);

    Call_Finish();
}

stock void API_CreateForward_OnConfigsLoaded() {
    CORE_Debug(API, "Forward: OnConfigsLoaded");

    Call_StartForward(g_hGlobalForward[OnConfigsLoaded]);
    Call_Finish();
}

stock void API_CreateForward_OnFeatureRegistered(const char[] szFeature) {
    CORE_Debug(API,
        "Forward: OnFeatureRegistered | Feature: %s",
    szFeature);

    Call_StartForward(g_hGlobalForward[OnFeatureRegistered]);

    Call_PushString(szFeature);

    Call_Finish();
}

stock void API_CreateForward_OnFeatureUnregistered(const char[] szFeature) {
    CORE_Debug(API,
        "Forward: OnFeatureUnregistered | Feature: %s",
    szFeature);

    Call_StartForward(g_hGlobalForward[OnFeatureUnregistered]);

    Call_PushString(szFeature);

    Call_Finish();
}

public int API_CreateNative_IsReady(Handle hPlugin, int iNumParams) {
    CORE_Debug(API,
        "Native: IsReady | Core status: %s",
    g_bIsReady ? "Active" : "Disabled");

    return g_bIsReady;
}

public int API_CreateNative_IsValidClient(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);

    bool bIsValid = CORE_IsValidClient(iClient);

    CORE_Debug(API,
        "Native: IsValidClient | Client: (Index: %i - Status: %s)",
    iClient, bIsValid ? "Valid" : "Invalid");

    return bIsValid;
}

public int API_CreateNative_IsClientHaveAccess(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);

    bool bIsHave = CORE_IsClientHaveAccess(iClient);

    CORE_Debug(API,
        "Native: IsClientHaveAccess | Client: (Index: %i - Status: %s)",
    iClient, bIsHave ? "True" : "False");

    return bIsHave;
}

public int API_CreateNative_IsValidGroup(Handle hPlugin, int iNumParams) {
    char szGroup[MAX_GROUP_LENGTH];
    GetNativeString(1, szGroup, sizeof szGroup);

    bool IsValid = CORE_IsValidGroup(szGroup);

    CORE_Debug(API,
        "Native: IsValidGroup | Group: %s - Valid: %s",
    szGroup, IsValid ? "True" : "False");

    return IsValid;
}

public int API_CreateNative_IsValidFeature(Handle hPlugin, int iNumParams) {
    char szFeature[MAX_FEATURE_LENGTH];
    GetNativeString(1, szFeature, sizeof szFeature);

    char szGroup[MAX_GROUP_LENGTH];
    GetNativeString(2, szGroup, sizeof szGroup);

    bool bIsValid = CORE_IsValidFeature(szFeature, szGroup);

    CORE_Debug(API,
        "Native: IsValidFeature | Group: %s => Feature: %s => Status: %s",
    szGroup, szFeature, bIsValid ? "Valid" : "Invalid");

    return bIsValid;
}

public int API_CreateNative_IsRegisteredFeature(Handle hPlugin, int iNumParams) {
    char szFeature[PLATFORM_MAX_PATH];
    GetNativeString(1, szFeature, sizeof szFeature);

    bool bIsRegistered = CORE_IsRegisteredFeature(szFeature);

    CORE_Debug(API,
        "Native: IsRegisteredFeature | Feature: %s => Status: %s",
    szFeature, bIsRegistered ? "Registered" : "Unregistered");

    return bIsRegistered;
}

public int API_CreateNative_IsAllowedFeature(Handle hPlugin, int iNumParams) {
    char szFeature[MAX_FEATURE_LENGTH];
    GetNativeString(1, szFeature, sizeof szFeature);

    bool bIsAllowed = CORE_IsAllowedFeature(szFeature);

    CORE_Debug(API,
        "Native: IsAllowedFeature | Feature: %s => Status: %s",
    szFeature, bIsAllowed ? "Allowed" : "Not Allowed");

    return bIsAllowed;
}

public int API_CreateNative_IsAllowedFirstRound(Handle hPlugin, int iNumParams) {
    char szFeature[MAX_FEATURE_LENGTH];
    GetNativeString(1, szFeature, sizeof szFeature);

    bool bIsAllowed = CORE_IsAllowedFirstRound(szFeature);

    CORE_Debug(API,
        "Native: IsAllowedFirstRound | Feature: %s => Status: %s",
    szFeature, bIsAllowed ? "Allowed" : "Not Allowed");

    return bIsAllowed;
}

public int API_CreateNative_GetConfig(Handle hPlugin, int iNumParams) {
    KvRewind(g_hConfigs[CONFIG_MAIN]);

    CORE_Debug(API, "Native: GetConfig");

    return view_as<int>(g_hConfigs[CONFIG_MAIN]);
}

public int API_CreateNative_GetGroups(Handle hPlugin, int iNumParams) {
    CORE_Debug(API,
        "Native: GetGroups | Groups count: %i",
    GetTrieSize(g_hGroups));

    return view_as<int>(g_hGroups);
}

public int API_CreateNative_GetFeatures(Handle hPlugin, int iNumParams) {
    CORE_Debug(API,
        "Native: GetFeatures | Features count: %i",
    GetTrieSize(g_hFeatures));

    return view_as<int>(g_hFeatures);
}

public int API_CreateNative_GetFeatureValue(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    int iBufLength = GetNativeCell(4);

    char szFeature[MAX_FEATURE_LENGTH];
    GetNativeString(2, szFeature, sizeof szFeature);

    char szValue[PLATFORM_MAX_PATH];
    CORE_GetFeatureValue(iClient, szFeature, szValue, sizeof szValue);

    CORE_Debug(API,
        "Native: GetFeatureValue | Client Index: %i | Feature ID: %s | feature Value: %s",
    iClient, szFeature, szValue);

    return SetNativeString(3, szValue, iBufLength);
}

public int API_CreateNative_GetDatabase(Handle hPlugin, int iNumParams) {
    CORE_Debug(API, "Native: GetDatabase");

    return view_as<int>(g_hDatabase);
}

public int API_CreateNative_GetDatabaseType(Handle hPlugin, int iNumParams) {
    DatabaseType iType = CORE_GetDatabaseType();

    CORE_Debug(API,
        "Native: GetDatabaseType | Type: %s",
    view_as<int>(iType) ? "SQL" : "MySQL");

    return view_as<int>(iType);
}

public int API_CreateNative_GetDatabasePrefix(Handle hPlugin, int iNumParams) {
    int iMaxLength = GetNativeCell(2);

    CORE_Debug(API,
        "Native: GetDatabasePrefix | Prefix: %s => Buffer size: %i",
    g_szTablePrefix, iMaxLength);
    
    return SetNativeString(1, g_szTablePrefix, iMaxLength);
}

public int API_CreateNative_GetClientByAuth(Handle hPlugin, int iNumParams) {
    char szAuth[MAX_AUTHID_LENGTH];
    GetNativeString(1, szAuth, sizeof szAuth);

    int iClient = CORE_GetClientByAuth(szAuth);

    CORE_Debug(API,
        "Native: GetClientByAuth | Auth: %s => Client: (Index: %i - Status: %s)",
    szAuth, iClient, CORE_IsValidClient(iClient) ? "Valid" : "Invalid");

    return iClient;
}

public int API_CreateNative_GetClientGroup(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);

    char szGroup[MAX_GROUP_LENGTH];
    CORE_GetClientGroup(iClient, szGroup, sizeof szGroup);
    
    int iMaxLength = GetNativeCell(3);

    CORE_Debug(API,
        "Native: GetClientGroup | Client: (Index: %i - Username: %N) => Group: %s => Buffer size: %i",
    iClient, iClient, szGroup, iMaxLength);

    return SetNativeString(2, szGroup, iMaxLength);
}

public int API_CreateNative_GetClientExpires(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    int iExpires = CORE_GetClientExpires(iClient);

    CORE_Debug(API,
        "Native: GetClientExpires | Client: (Index: %i - Username: %N) => Expires: %i",
    iClient, iClient, iExpires);

    return iExpires;
}

public int API_CreateNative_GetClientFeatureStatus(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);

    char szFeature[MAX_FEATURE_LENGTH];
    GetNativeString(2, szFeature, sizeof szFeature);

    bool bStatus = CORE_GetClientFeatureStatus(iClient, szFeature);

    CORE_Debug(API,
        "Native: GetClientFeatureStatus | Client: (Index: %i - Username: %N) => Feature: %s => Status: %s",
    iClient, iClient, szFeature, bStatus ? "Enabled" : "Disabled");

    return bStatus;
}

public int API_CreateNative_SetClientFeatureStatus(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);

    char szFeature[MAX_FEATURE_LENGTH];
    GetNativeString(2, szFeature, sizeof szFeature);
    
    bool bIsEnabled = GetNativeCell(3);

    CORE_Debug(API,
        "Native: SetClientFeatureStatus | Client: (Index: %i - Username: %N) => Feature: %s => Status: %s",
    iClient, iClient, szFeature, bIsEnabled ? "Enabled" : "Disabled");

    CORE_SetClientFeatureStatus(iClient, szFeature, bIsEnabled);

    return 1;
}

public int API_CreateNative_GiveAccess(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);

    char szGroup[MAX_GROUP_LENGTH]
    GetNativeString(2, szGroup, sizeof szGroup);

    int iAdmin = GetNativeCell(3);
    int iExpire = GetNativeCell(4);

    CORE_Debug(API,
        "Native: GiveAccess | Client: (Index: %i - Username: %N) => Admin: (Index: %i) => Group: %s => Expires: %i",
    iClient, iClient, iAdmin, szGroup, iExpire);

    return CORE_GiveClientAccess(iClient, szGroup, iAdmin, iExpire);
}

public int API_CreateNative_SetClientGroup(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);

    char szGroup[MAX_GROUP_LENGTH];
    GetNativeString(2, szGroup, sizeof szGroup);

    int iStatus = -1;

    if(CORE_IsValidClient(iClient)) {
        iStatus = 1;
        
        CORE_SetClientGroup(iClient, szGroup);
    }
    
    CORE_Debug(API,
        "Native: SetClientGroup | Client: (Index: %i - Group: %s)",
    iClient, szGroup);

    return view_as<bool>(iStatus);
}

public int API_CreateNative_RemoveAccess(Handle hPlugin, int iNumParams) {
    char szAuth[MAX_AUTHID_LENGTH];
    GetNativeString(1, szAuth, sizeof szAuth);

    int iAdmin = GetNativeCell(2);

    char szReason[PLATFORM_MAX_PATH];
    GetNativeString(3, szReason, sizeof szReason);

    CORE_Debug(API,
        "Native: RemoveAccess | Client: (Index: %i - Auth: %s) => Admin: (Index: %i) => Reason: %s",
    CORE_GetClientByAuth(szAuth), szAuth, iAdmin, szReason);

    return CORE_RemoveClientAccess(szAuth, iAdmin, szReason);
}

public int API_CreateNative_PlaySound(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);

    char szSound[PLATFORM_MAX_PATH];
    GetNativeString(2, szSound, sizeof szSound);

    CORE_Debug(API,
        "Native: PlaySound | Client: (Index: %i - Username: %N) => Path: %s",
    iClient, iClient, szSound);

    return view_as<int>(CORE_PlaySound(iClient, szSound));
}

public int API_CreateNative_ShowMenu(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    MenuType iType = GetNativeCell(2);
    int iShowMenuTime = GetNativeCell(3);

    CORE_Debug(API,
        "Native: ShowMenu | Client: (Index: %i - Username: %N) => Type: %i => Time: %i",
    iClient, iClient, view_as<int>(iType), iShowMenuTime);
    
    return view_as<int>(CORE_ShowMenu(iClient, iType, iShowMenuTime));
}

public int API_CreateNative_RegisterFeature(Handle hPlugin, int iNumParams) {
    PremiumFeatureType iType = GetNativeCell(1);

    char szFeature[MAX_FEATURE_LENGTH];
    GetNativeString(2, szFeature, sizeof szFeature);

    CORE_Debug(API,
        "Native: RegisterFeature | Type: %s => Feature: %s",
    iType == STATUS ? "Status" : "Selectable", szFeature);

    return CORE_RegisterFeature(hPlugin, iType, szFeature, GetNativeFunction(3), GetNativeFunction(4), GetNativeFunction(5));
}

public int API_CreateNative_UnregisterFeature(Handle hPlugin, int iNumParams) {
    char szFeature[MAX_FEATURE_LENGTH];
    GetNativeString(1, szFeature, sizeof szFeature);

    CORE_Debug(API,
        "Native: UnregisterFeature | Feature: %s",
    szFeature);

    return CORE_UnregisterFeature(szFeature);
}

public int API_CreateNative_PrintToChat(Handle hPlugin, int iNumParams) {
	int iClient = GetNativeCell(1);
	
	char szBuffer[PLATFORM_MAX_PATH];
	FormatNativeString(0, 2, 3, sizeof szBuffer, _, szBuffer);

    CORE_Debug(API,
        "Native: PrintToChat | Client: (Index: %i - Username: %N) => Buffer: %s",
    iClient, iClient, szBuffer);
	
	return view_as<int>(CORE_PrintToChat(iClient, szBuffer));
}

public int API_CreateNative_PrintToChatAll(Handle hPlugin, int iNumParams) {
	char szBuffer[PLATFORM_MAX_PATH];
	FormatNativeString(0, 1, 2, sizeof szBuffer, _, szBuffer);

    CORE_Debug(API,
        "Native: PrintToChatAll | Buffer: %s",
    szBuffer);
	
	return view_as<int>(CORE_PrintToChatAll(szBuffer));
}

public int API_CreateNative_Debug(Handle hPlugin, int iNumParams) {
    DebugType iType = GetNativeCell(1);

    char szLog[1024];
    FormatNativeString(0, 2, 3, sizeof szLog, _, szLog);

    CORE_Debug(iType, szLog);

    return -1;
}

public int API_CreateNative_FormatAccessTime(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    int iFormTime = GetNativeCell(2);
    int iMaxLength = GetNativeCell(4);

    char szBuffer[PLATFORM_MAX_PATH];
    CORE_FormatAccessTime(iClient, iFormTime, szBuffer, sizeof szBuffer);

    CORE_Debug(API,
        "Native: FormatAccessTime | Client: (Index: %i) => Timestamp: %i => Buffer: %s => Buffer size: %i",
    iClient, iFormTime, szBuffer, iMaxLength);

    return SetNativeString(3, szBuffer, iMaxLength);
}