public void OnClientPostAdminCheck(int iClient) {
    CreateTimer(1.0, Timer_ClientConnected, GetClientUserId(iClient));
}

public Action Timer_ClientConnected(Handle hTimer, int iUserId) {
    int iClient = GetClientOfUserId(iUserId);

    if(CORE_IsValidClient(iClient) && CORE_IsClientHaveAccess(iClient)) {
        UpdatePremiumClientInfo(iClient);
        API_CreateForward_OnClientConnected(iClient);

        if(g_bIsNotify[2])
            CORE_ShowMenu(iClient, HAVE_ACCESS, 10);
    }

    return Plugin_Stop;
}

public void OnClientDisconnect(int iClient) {
    if(CORE_IsClientHaveAccess(iClient))
        API_CreateForward_OnClientDisconnected(iClient);
}

public void Event_PlayerSpawn(Handle hEvent, const char[] szName, bool bSilent) {
    int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

    if(CORE_IsValidClient(iClient) && CORE_IsClientHaveAccess(iClient))
        API_CreateForward_OnPlayerSpawn(iClient, GetClientTeam(iClient));
}

public void Event_RoundEnd(Handle hEvent, const char[] szName, bool bSilent) {
    if((GetTeamScore(2) + GetTeamScore(3))) g_bIsFirstRound = false;
}

public void Event_RoundStart(Handle hEvent, const char[] szName, bool bSilent) {
    if(!(GetTeamScore(2) + GetTeamScore(3))) g_bIsFirstRound = true;
}