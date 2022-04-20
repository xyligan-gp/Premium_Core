public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErrMax) {
    g_hGlobalForward_OnReady = CreateGlobalForward("Premium_OnReady", ET_Ignore);
    g_hGlobalForward_OnAddAccess = CreateGlobalForward("Premium_OnAddAccess", ET_Ignore, Param_Cell);
    g_hGlobalForward_OnPlayerSpawn = CreateGlobalForward("Premium_OnPlayerSpawn", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hGlobalForward_OnRemoveAccess = CreateGlobalForward("Premium_OnRemoveAccess", ET_Ignore, Param_Cell);
    g_hGlobalForward_OnAdminMenuReady = CreateGlobalForward("Premium_OnAdminMenuReady", ET_Ignore, Param_Cell, Param_Cell);
    g_hGlobalForward_OnClientConnected = CreateGlobalForward("Premium_OnClientConnected", ET_Ignore, Param_Cell);
    g_hGlobalForward_OnClientDisconnect = CreateGlobalForward("Premium_OnClientDisconnect", ET_Ignore, Param_Cell);
    g_hGlobalForward_OnMenuFeatureSelected = CreateGlobalForward("Premium_OnMenuFeatureSelected", ET_Ignore, Param_Cell, Param_String, Param_Cell);

    CreateNative("Premium_IsReady",             API_Native_IsReady);
    CreateNative("Premium_IsValidClient",       API_Native_IsValidClient);
    CreateNative("Premium_IsClientAccess",      API_Native_IsClientAccess);
    CreateNative("Premium_IsAllowedFeature",    API_Native_IsAllowedFeature);
    CreateNative("Premium_IsAllowedFirstRound", API_Native_IsAllowedFirstRound);

    CreateNative("Premium_GetDatabase",         API_Native_GetDatabase);
    CreateNative("Premium_GetFeaturesTrie",     API_Native_GetFeaturesTrie);
    CreateNative("Premium_RegisterFeature",     API_Native_RegisterFeature);
    CreateNative("Premium_UnRegisterFeature",   API_Native_UnRegisterFeature);
    CreateNative("Premium_GetFeatureStatus",    API_Native_GetFeatureStatus);
    CreateNative("Premium_SetFeatureStatus",    API_Native_SetFeatureStatus);
    CreateNative("Premium_SendClientMenu",      API_Native_SendClientMenu);

    CreateNative("Premium_PrintToChat",         API_Native_PrintToChat);
    CreateNative("Premium_PrintToChatAll",      API_Native_PrintToChatAll);

    CreateNative("Premium_GiveClientAccess",    API_Native_GiveClientAccess);
    CreateNative("Premium_RemoveClientAccess",  API_Native_RemoveClientAccess);

    CreateNative("Premium_Debug_SQL",           API_Native_DebugSQL);
    CreateNative("Premium_Debug_MODULE",        API_Native_DebugMODULE);

    RegPluginLibrary("premium");

    return APLRes_Success;
}

stock void API_CreateForward_OnReady() {
    Call_StartForward(g_hGlobalForward_OnReady);
    Call_Finish();
}

stock void API_CreateForward_OnAddAccess(int iClient) {
    DBG_API("[Premium_OnAddAccess]: Client: %N", iClient);

    Call_StartForward(g_hGlobalForward_OnAddAccess);
    Call_PushCell(iClient);
    Call_Finish();
}

stock void API_CreateForward_OnPlayerSpawn(int iClient, int iTeam, bool bIsPremium) {
    DBG_API("[Premium_OnPlayerSpawn]: Client: %N | Client team index: %i | Client is premium: %s", iClient, iTeam, bIsPremium ? "True":"False");

    Call_StartForward(g_hGlobalForward_OnPlayerSpawn);
    Call_PushCell(iClient);
    Call_PushCell(iTeam);
    Call_PushCell(bIsPremium);
    Call_Finish();
}

stock void API_CreateForward_OnRemoveAccess(int iClient) {
    DBG_API("[Premium_OnRemoveAccess]: Client: %N", iClient);

    Call_StartForward(g_hGlobalForward_OnRemoveAccess);
    Call_PushCell(iClient);
    Call_Finish();
}

public void API_CreateForward_OnAdminMenuReady(Handle hTopMenu, int iFlags) {
    DBG_API("[Premium_OnAdminMenuReady]: Admin menu flags index: %i", iFlags);

    Call_StartForward(g_hGlobalForward_OnAdminMenuReady);
    Call_PushCell(hTopMenu);
    Call_PushCell(iFlags);
    Call_Finish();
}

stock void API_CreateForward_OnClientConnected(int iClient) {
    DBG_API("[Premium_OnClientConnected]: Client: %N", iClient);

    Call_StartForward(g_hGlobalForward_OnClientConnected);
    Call_PushCell(iClient);
    Call_Finish();
}

stock void API_CreateForward_OnClientDisconnect(int iClient) {
    DBG_API("[Premium_OnCloientDisconnect]: Client: %N", iClient);

    Call_StartForward(g_hGlobalForward_OnClientDisconnect);
    Call_PushCell(iClient);
    Call_Finish();
}

stock void API_CreateForward_OnMenuFeatureSelected(int iClient, const char[] szFeature, bool bStatus) {
    DBG_API("[Premium_OnMenuFeatureSelected]: Client: %N | Feature unique name: %s | Feature state: %s", iClient, szFeature, bStatus ? "True":"False");

    Call_StartForward(g_hGlobalForward_OnMenuFeatureSelected);
    Call_PushCell(iClient);
    Call_PushString(szFeature);
    Call_PushCell(bStatus);
    Call_Finish();
}

public int API_Native_IsReady(Handle hPlugin, int iNumParams) {
    return g_bIsReady;
}

public int API_Native_IsValidClient(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    bool bIsValidClient = PM_IsValidClient(iClient);

    DBG_API("[Premium_IsValidClient]: Client: %N | Client valid: %s", iClient, bIsValidClient ? "True":"False");

    return bIsValidClient;
}

public int API_Native_IsClientAccess(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);

    DBG_API("[Premium_IsClientAccess]: Client: %N | Client access: %s", iClient, g_bIsPremiumClient[iClient] ? "True":"False");

    return g_bIsPremiumClient[iClient];
}

public int API_Native_IsAllowedFeature(Handle hPlugin, int iNumParams) {
    char szFeature[PLATFORM_MAX_PATH];
    GetNativeString(1, szFeature, sizeof szFeature);
    bool bIsAllowed = PM_IsAllowedFeature(szFeature);

    DBG_API("[Premium_IsAllowedFeature]: Feature: %s | Feature allowed: %s", bIsAllowed ? "True":"False");

    return bIsAllowed;
}

public int API_Native_IsAllowedFirstRound(Handle hPlugin, int iNumParams) {
    char szFeature[PLATFORM_MAX_PATH];
    GetNativeString(1, szFeature, sizeof szFeature);
    bool bIsAllowed = PM_IsAllowedFirstRound(szFeature);

    DBG_API("[Premium_IsAllowedFirstRound]: Feature: %s | Feature allowed: %s", szFeature, bIsAllowed ? "True":"False");

    return bIsAllowed;
}

public any API_Native_GetDatabase(Handle hPlugin, int iNumParams) {
    return g_hDatabase;
}

public any API_Native_GetFeaturesTrie(Handle hPlugin, int iNumParams) {
    return g_hFeatures;
}

public int API_Native_PremiumTimeToString(Handle hPlugin, int iNumParams) {
    char szBuffer[PLATFORM_MAX_PATH];

    int iClient = GetNativeCell(1);
    int iTime = GetNativeCell(2);
    int iMaxLength = GetNativeCell(4);
    GetNativeString(3, szBuffer, sizeof szBuffer);

    return GetPremiumTime(iClient, iTime, szBuffer, iMaxLength);
}

public int API_Native_RegisterFeature(Handle hPlugin, int iNumParams) {
    char szFeature[128], szFeatureSetup[128];
    GetNativeString(1, szFeature, sizeof szFeature);
    PremiumFeatureType iType = GetNativeCell(2);
    GetNativeString(3, szFeatureSetup, sizeof szFeatureSetup);

    if(!strlen(szFeatureSetup)) strcopy(szFeatureSetup, sizeof szFeatureSetup, "");

    return PM_RegisterFeature(szFeature, iType, szFeatureSetup);
}

public int API_Native_UnRegisterFeature(Handle hPlugin, int iNumParams) {
    char szFeature[128];
    GetNativeString(1, szFeature, sizeof szFeature);

    return PM_UnRegisterFeature(szFeature);
}

public int API_Native_GetFeatureStatus(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    char szFeature[PLATFORM_MAX_PATH];
    GetNativeString(2, szFeature, sizeof szFeature);

    return PM_GetClientFeatureStatus(iClient, szFeature);
}

public int API_Native_SetFeatureStatus(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    char szFeature[PLATFORM_MAX_PATH];
    GetNativeString(2, szFeature, sizeof szFeature);
    bool bIsEnabled = GetNativeCell(3);

    return PM_SetClientFeatureStatus(iClient, szFeature, bIsEnabled);
}

public int API_Native_SendClientMenu(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    PremiumMenuType iType = GetNativeCell(2);

    switch(iType) {
        case DEFAULT_MENU: ShowPremiumMenu(iClient);
        case NO_ACCESS_MENU: ShowNoAccessMenu(iClient);
        case GIVE_ACCESS_MENU: ShowGiveAccessMenu(iClient);
        case HAVE_ACCESS_MENU: ShowHaveAccessMenu(iClient);
        case EXPIRED_ACCESS_MENU: ShowExpiredAccessMenu(iClient);
    }
}

public int API_Native_GiveClientAccess(Handle hPlugin, int iNumParams) {
    int iTarget = GetNativeCell(1);
    int iAdmin = GetNativeCell(2);
    int iTime = GetNativeCell(3);

    PM_GiveClientAccess(iTarget, iAdmin, iTime);
}

public int API_Native_RemoveClientAccess(Handle hPlugin, int iNumParams) {
    char szSteam[128];
    GetNativeString(1, szSteam, sizeof szSteam);

    PM_RemoveClientAccess(szSteam);
}

public int API_Native_PrintToChat(Handle hPlugin, int iNumParams) {
    int iClient = GetNativeCell(1);
    char szMessage[PLATFORM_MAX_PATH];

    SetGlobalTransTarget(iClient);
    FormatNativeString(0, 2, 3, sizeof szMessage, _, szMessage);

    DBG_API("[Premium_PrintToChat] Client - %i | Message - %s", iClient, szMessage);

    if(PM_IsValidClient(iClient)) PM_PrintToChat(iClient, szMessage);
}

public int API_Native_PrintToChatAll(Handle hPlugin, int iNumParams) {
    char szMessage[PLATFORM_MAX_PATH];
    FormatNativeString(0, 1, 2, sizeof szMessage, _, szMessage);

    DBG_API("[Premium_PrintToChatAll] Message - %s", szMessage);

    PM_PrintToChatAll(szMessage);
}

public int API_Native_DebugSQL(Handle hPlugin, int iNumParams) {
    char szMessage[1024];
    FormatNativeString(0, 1, 2, sizeof szMessage, _, szMessage);
    
    DBG_SQL(szMessage);
}

public int API_Native_DebugMODULE(Handle hPlugin, int iNumParams) {
    char szMessage[1024];
    FormatNativeString(0, 1, 2, sizeof szMessage, _, szMessage);
    
    DBG_MODULE(szMessage);
}