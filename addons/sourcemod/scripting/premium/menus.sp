stock void ShowClientsMenu(int iClient) {
    Menu hMenu = CreateMenu(CallBack_ClientsMenu);
    
    SetMenuTitle(hMenu, "%T\n ", "ClientsMenu_Title", iClient);

    char szNoPlayers[PLATFORM_MAX_PATH], szPlayerName[MAX_NAME_LENGTH], szUserID[10];
    FormatEx(szNoPlayers, sizeof szNoPlayers, "%T", "PlayersNotFound", iClient);

    for(int iTarget = 1; iTarget <= MaxClients; iTarget++) {
        if(!PM_IsValidClient(iTarget) || g_bIsPremiumClient[iTarget]) continue;

        GetClientName(iTarget, szPlayerName, sizeof szPlayerName);
        IntToString(GetClientUserId(iTarget), szUserID, sizeof szUserID);

        AddMenuItem(hMenu, szUserID, szPlayerName);
    }

    if(!GetMenuItemCount(hMenu)) AddMenuItem(hMenu, NULL_STRING, szNoPlayers, ITEMDRAW_DISABLED);

    SetMenuExitBackButton(hMenu, true);

    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int CallBack_ClientsMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szUserID[10];
            GetMenuItem(hMenu, iSlot, szUserID, sizeof szUserID);

            int iTarget = GetClientOfUserId(StringToInt(szUserID));
            if(!iTarget) {
                PM_PrintToChat(iClient, "%T", "LeavedPlayer", iClient, iTarget);

                return;
            }

            g_iTarget[iClient] = iTarget;

            ShowSelectTimeMenu(iClient);
        }

        case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) DisplayTopMenu(g_hTopMenu, iClient, TopMenuPosition_LastCategory);
        case MenuAction_End: CloseHandle(hMenu);
    }
}

stock void ShowSelectTimeMenu(int iClient) {
    char szPath[PLATFORM_MAX_PATH];
	Menu hMenu = CreateMenu(CallBack_SelectTimeMenu);

	SetMenuTitle(hMenu, "%T\n ", "SelectTimeMenu_Title", iClient);

	KeyValues hKV = CreateKeyValues("PremiumTimes");
	BuildPath(Path_SM, szPath, sizeof szPath, "data/premium/cfg/times.ini");

	if(!hKV.ImportFromFile(szPath)) SetFailState("[Premium] Times config is missing: %s", szPath);

	if(hKV.GotoFirstSubKey()) {
		char szBuffer[PLATFORM_MAX_PATH], szTime[32], szClientLang[4], szServerLang[4];

		GetLanguageInfo(GetClientLanguage(iClient), szClientLang, sizeof szClientLang);
		GetLanguageInfo(GetServerLanguage(), szServerLang, sizeof szServerLang);

		do {
			KvGetSectionName(hKV, szTime, sizeof szTime);
			KvGetString(hKV, szClientLang, szBuffer, sizeof szBuffer, "LangError");

			if(!szBuffer[0]) {
				KvGetString(hKV, szServerLang, szBuffer, sizeof szBuffer, "LangError");
			}

			AddMenuItem(hMenu, szTime, szBuffer);
		} while(hKV.GotoNextKey(false));
	}

	delete hKV;

	SetMenuExitBackButton(hMenu, true);

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int CallBack_SelectTimeMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szExpires[64], szTime[64], szPlayer[PLATFORM_MAX_PATH], szAdmin[PLATFORM_MAX_PATH];
			GetMenuItem(hMenu, iSlot, szExpires, sizeof szExpires);

            int iTime = StringToInt(szExpires), iExpires;
            GetPremiumTime(iClient, iTime, szTime, sizeof szTime);

            if(!iTime) iExpires = 0;
			else iExpires = GetTime() + iTime;

            PM_GiveClientAccess(g_iTarget[iClient], iClient, iExpires);

            FormatEx(szAdmin, sizeof szAdmin, "%T", "AccessAdded_Admin", iClient, g_iTarget[iClient], szTime);
            FormatEx(szPlayer, sizeof szPlayer, "%T", "AccessAdded_Player", g_iTarget[iClient], g_iTarget[iClient], szTime);

            PM_PrintToChat(iClient, szAdmin);
            PM_PrintToChat(g_iTarget[iClient], szPlayer);
        }

        case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) ShowClientsMenu(iClient);
        case MenuAction_End: CloseHandle(hMenu);
    }
}

stock void ShowPremiumClientsMenu(int iClient) {
    char szQuery[PLATFORM_MAX_PATH];

    FormatEx(szQuery, sizeof szQuery, "SELECT * FROM `premium_users` ORDER BY `id` DESC");
    g_hDatabase.Query(SQL_CallBack_PremiumClientsMenu, szQuery, GetClientUserId(iClient));
}

public int CallBack_PremiumClientsMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szSteam[64], szAdmin[PLATFORM_MAX_PATH];
            GetMenuItem(hMenu, iSlot, szSteam, sizeof szSteam);
            
            PM_RemoveClientAccess(szSteam);

            FormatEx(szAdmin, sizeof szAdmin, "%T", "AccessRemoved_Admin", iClient, iClient);
            PM_PrintToChat(iClient, szAdmin);
        }

        case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) DisplayTopMenu(g_hTopMenu, iClient, TopMenuPosition_LastCategory);
        case MenuAction_End: CloseHandle(hMenu);
    }
}

stock void ShowPremiumPlayersMenu(int iClient) {
    char szQuery[PLATFORM_MAX_PATH];

    FormatEx(szQuery, sizeof szQuery, "SELECT * FROM `premium_users` ORDER BY `id` DESC");
    g_hDatabase.Query(SQL_CallBack_PremiumPlayersMenu, szQuery, GetClientUserId(iClient));
}

public int CallBack_PremiumPlayersMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szQuery[PLATFORM_MAX_PATH], szSteam[64];
            GetMenuItem(hMenu, iSlot, szSteam, sizeof szSteam);

            FormatEx(szQuery, sizeof szQuery, "SELECT * FROM `premium_users` WHERE `playerSteam` = '%s'", szSteam);
            g_hDatabase.Query(SQL_CallBack_ShowPlayerInfo, szQuery, GetClientUserId(iClient));
        }

        case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) DisplayTopMenu(g_hTopMenu, iClient, TopMenuPosition_LastCategory);
        case MenuAction_End: CloseHandle(hMenu);
    }
}

public int CallBack_PlayerInfoMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) ShowPremiumPlayersMenu(iClient);
        case MenuAction_End: CloseHandle(hMenu);
    }
}

public Action Call_PremiumMenu(int iClient, int iArgs) {
    if(PM_IsValidClient(iClient) && !g_bIsPremiumClient[iClient]) ShowNoAccessMenu(iClient);
    if(PM_IsValidClient(iClient) && g_bIsPremiumClient[iClient]) ShowPremiumMenu(iClient);

    return Plugin_Handled;
}

stock void ShowNoAccessMenu(int iClient) {
    PlaySound(iClient, NO_ACCESS_SOUND);

    char szContent[PLATFORM_MAX_PATH], szExit[64];
    FormatEx(szExit, sizeof szExit, "%T", "Exit", iClient);
    FormatEx(szContent, sizeof szContent, "%T", "NoAccess_Content", iClient);

    Panel hPanel = CreatePanel();

    SetPanelTitle(hPanel, szContent);
    SetPanelCurrentKey(hPanel, 1);
    DrawPanelText(hPanel, "\n ");
    SetPanelCurrentKey(hPanel, 10);
    DrawPanelItem(hPanel, szExit);
    
    SendPanelToClient(hPanel, iClient, CallBack_NoAccessMenu, 15);
}

public int CallBack_NoAccessMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_End: CloseHandle(hMenu);
    }
}

stock void ShowExpiredAccessMenu(int iClient) {
    char szContent[PLATFORM_MAX_PATH], szExit[64];
    FormatEx(szExit, sizeof szExit, "%T", "Exit", iClient);
    FormatEx(szContent, sizeof szContent, "%T", "ExpiredAccess_Content", iClient);

    Panel hPanel = CreatePanel();

    SetPanelTitle(hPanel, szContent);
    SetPanelCurrentKey(hPanel, 1);
    DrawPanelText(hPanel, "\n ");
    SetPanelCurrentKey(hPanel, 10);
    DrawPanelItem(hPanel, szExit);
    
    SendPanelToClient(hPanel, iClient, CallBack_ExpiredAccessMenu, 15);
}

public int CallBack_ExpiredAccessMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_End: CloseHandle(hMenu);
    }
}

stock void ShowGiveAccessMenu(int iClient) {
    char szContent[PLATFORM_MAX_PATH], szExit[64];
    FormatEx(szExit, sizeof szExit, "%T", "Exit", iClient);
    FormatEx(szContent, sizeof szContent, "%T", "GiveAccess_Content", iClient);

    Panel hPanel = CreatePanel();

    SetPanelTitle(hPanel, szContent);
    SetPanelCurrentKey(hPanel, 1);
    DrawPanelText(hPanel, "\n ");
    SetPanelCurrentKey(hPanel, 10);
    DrawPanelItem(hPanel, szExit);
    
    SendPanelToClient(hPanel, iClient, CallBack_GiveAccessMenu, 15);
}

public int CallBack_GiveAccessMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_End: CloseHandle(hMenu);
    }
}

stock void ShowHaveAccessMenu(int iClient) {
    int iExpires = PM_GetClientExpires(iClient);
    char szContent[PLATFORM_MAX_PATH], szExit[64], szExpiresTime[128];

    if(iExpires) FormatTime(szExpiresTime, sizeof szExpiresTime, "%d.%m.%Y - %H:%M:%S", iExpires);
    else FormatEx(szExpiresTime, sizeof szExpiresTime, "%T", "Forever", iClient);

    FormatEx(szExit, sizeof szExit, "%T", "Exit", iClient);
    FormatEx(szContent, sizeof szContent, "%T", "HaveAccess_Content", iClient, iClient, szExpiresTime);

    Panel hPanel = CreatePanel();

    SetPanelTitle(hPanel, szContent);
    SetPanelCurrentKey(hPanel, 1);
    DrawPanelText(hPanel, "\n ");
    SetPanelCurrentKey(hPanel, 10);
    DrawPanelItem(hPanel, szExit);
    
    SendPanelToClient(hPanel, iClient, CallBack_HaveAccessMenu, 15);
}

public int CallBack_HaveAccessMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_End: CloseHandle(hMenu);
    }
}

stock void ShowPremiumMenu(int iClient) {
    int iExpires = PM_GetClientExpires(iClient);
    char szExpiresTime[128], szExpiresTimeItem[PLATFORM_MAX_PATH];
    
    if(iExpires) FormatTime(szExpiresTime, sizeof szExpiresTime, "%d.%m.%Y - %H:%M:%S", iExpires);
    else FormatEx(szExpiresTime, sizeof szExpiresTime, "%T", "Forever", iClient);
    
    FormatEx(szExpiresTimeItem, sizeof szExpiresTimeItem, "%T", "AccessExpires", iClient, szExpiresTime);

    Menu hMenu = CreateMenu(CallBack_PremiumMenu);

    SetMenuTitle(hMenu, "%T\n \n%s\n ", "PremiumMenu_Title", iClient, szExpiresTimeItem);

    StringMapSnapshot hFeatures = g_hFeatures.Snapshot();
    int iLength = hFeatures.Length;
    
    char szKey[128], szPhrase[128], szItem[128], szNoFeatures[128];
    FormatEx(szNoFeatures, sizeof szNoFeatures, "%T", "NoFeatures", iClient);

    for(int i = 0; i < iLength; i++) {
        char szBuffer[8][64];
        hFeatures.GetKey(i, szKey, sizeof szKey);
        ExplodeString(szKey, "->", szBuffer, sizeof szBuffer, sizeof szBuffer[]);
        
        FormatEx(szPhrase, sizeof szPhrase, "Premium_%s", szBuffer[1]);
        FormatEx(szItem, sizeof szItem, "%T [%s]", szPhrase, iClient, PM_GetClientFeatureStatus(iClient, szBuffer[1]) ? "+" : "-");
        
        if(StrEqual(szBuffer[2], "Default")) {
            if(PM_IsAllowedFeature(szBuffer[1])) AddMenuItem(hMenu, szBuffer[1], szItem);
            else AddMenuItem(hMenu, szBuffer[1], szItem, ITEMDRAW_DISABLED);
        }

        if(StrEqual(szBuffer[2], "Selectable")) {
            if(PM_IsAllowedFeature(szBuffer[1])) AddMenuItem(hMenu, szBuffer[1], szItem);
            else AddMenuItem(hMenu, szBuffer[1], szItem, ITEMDRAW_DISABLED);

            char szSetupPhrase[PLATFORM_MAX_PATH], szSetupItem[PLATFORM_MAX_PATH];
            FormatEx(szSetupPhrase, sizeof szSetupPhrase, "Premium_%s", szBuffer[3]);
            FormatEx(szSetupItem, sizeof szSetupItem, "%T", szSetupPhrase, iClient);
            
            if(PM_GetClientFeatureStatus(iClient, szBuffer[1]) && PM_IsAllowedFeature(szBuffer[1])) AddMenuItem(hMenu, szBuffer[3], szSetupItem);
            else AddMenuItem(hMenu, szBuffer[3], szSetupItem, ITEMDRAW_DISABLED);
        }
    }

    if(!GetMenuItemCount(hMenu)) AddMenuItem(hMenu, NULL_STRING, szNoFeatures, ITEMDRAW_DISABLED);

    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int CallBack_PremiumMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szFeature[128];
            GetMenuItem(hMenu, iSlot, szFeature, sizeof szFeature);

            API_CreateForward_OnMenuFeatureSelected(iClient, szFeature, PM_GetClientFeatureStatus(iClient, szFeature));
        }

        case MenuAction_End: CloseHandle(hMenu);
    }
}

stock void ShowDBManageMenu(int iClient) {
    Menu hMenu = CreateMenu(CallBack_DBManageMenu);

    SetMenuTitle(hMenu, "%T\n ", "DBManageMenu_Title", iClient);

    char szItem_ClearPremiumPlayers[PLATFORM_MAX_PATH], szItem_ClearPremiumSettings[PLATFORM_MAX_PATH];
    FormatEx(szItem_ClearPremiumPlayers, sizeof szItem_ClearPremiumPlayers, "%T", "DBManageMenu_ClearPlayers", iClient);
    FormatEx(szItem_ClearPremiumSettings, sizeof szItem_ClearPremiumSettings, "%T", "DBManageMenu_ClearSettings", iClient);

    AddMenuItem(hMenu, "clear_players", szItem_ClearPremiumPlayers);
    AddMenuItem(hMenu, "clear_settings", szItem_ClearPremiumSettings);

    SetMenuExitBackButton(hMenu, true);

    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int CallBack_DBManageMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szInfo[64];
            GetMenuItem(hMenu, iSlot, szInfo, sizeof szInfo);

            if(StrEqual(szInfo, "clear_players")) {
                char szQuery[PLATFORM_MAX_PATH], szMessage[PLATFORM_MAX_PATH];
                FormatEx(szQuery, sizeof szQuery, "DELETE FROM `premium_users`");
                FormatEx(szMessage, sizeof szMessage, "%T", "PlayersCleared", iClient);

                SQL_FastQuery(g_hDatabase, szQuery);
                PM_PrintToChat(iClient, szMessage);
            }

            if(StrEqual(szInfo, "clear_settings")) {
                char szQuery[PLATFORM_MAX_PATH], szMessage[PLATFORM_MAX_PATH];
                FormatEx(szQuery, sizeof szQuery, "DELETE FROM `premium_settings`");
                FormatEx(szMessage, sizeof szMessage, "%T", "SettingsCleared", iClient);

                SQL_FastQuery(g_hDatabase, szQuery);
                PM_PrintToChat(iClient, szMessage);
            }
        }

        case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) DisplayTopMenu(g_hTopMenu, iClient, TopMenuPosition_LastCategory);
        case MenuAction_End: CloseHandle(hMenu);
    }
}