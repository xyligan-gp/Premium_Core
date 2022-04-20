public Action Event_PlayerSpawn(Handle hEvent, const char[] szName, bool bDontBroadcast) {
    int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

    if(PM_IsValidClient(iClient)) {
        int iTeam = GetClientTeam(iClient);

        API_CreateForward_OnPlayerSpawn(iClient, iTeam, g_bIsPremiumClient[iClient]);
    }
}

public Action Event_RoundStart(Handle hEvent, const char[] szName, bool bDontBroadcast) {
    if(!(GetTeamScore(2) + GetTeamScore(3))) g_bIsFirstRound = true;
}

public Action Event_RoundEnd(Handle hEvent, const char[] szName, bool bDontBroadcast) {
    if((GetTeamScore(2) + GetTeamScore(3))) g_bIsFirstRound = false;
}

public void OnClientPostAdminCheck(int iClient) {
    CreateTimer(0.5, Timer_ClientConnected, GetClientUserId(iClient));
}

public void OnClientDisconnect(int iClient) {
    if(g_bIsPremiumClient[iClient]) API_CreateForward_OnClientDisconnect(iClient);
}

public Action Timer_ClientConnected(Handle hTimer, int iUserID) {
    int iClient = GetClientOfUserId(iUserID);

    if(!PM_IsValidClient(iClient) || !g_bIsPremiumClient[iClient]) return Plugin_Stop;
    if(g_bIsNotifyPlayer_Connect) ShowHaveAccessMenu(iClient);

    UpdateJoinTime(iClient);
    API_CreateForward_OnClientConnected(iClient);

    return Plugin_Stop;
}