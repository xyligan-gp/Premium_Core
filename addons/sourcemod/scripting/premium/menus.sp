stock void InitPremiumMenu() {
    g_hMenu = CreateMenu(CallBack_PremiumMenu, MenuAction_Display | MenuAction_DisplayItem | MenuAction_DrawItem | MenuAction_Select | MenuAction_Start);
}

public Action Call_PremiumMenu(int iClient, int iArgs) {
    if(CORE_IsValidClient(iClient)) {
        if(CORE_IsClientHaveAccess(iClient))
            CORE_ShowMenu(iClient);
        else
            CORE_ShowMenu(iClient, NO_ACCESS, 10);
    }

    return Plugin_Handled;
}

public int CallBack_PremiumMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_DrawItem: {
            char szItem[PLATFORM_MAX_PATH];
            GetMenuItem(hMenu, iSlot, szItem, sizeof szItem);

            if(!StrEqual(szItem, "noFeatures")) {
                DataPack hPack;
                GetTrieValue(g_hFeatures, szItem, hPack);

                ResetPack(hPack);

                Handle hPlugin = view_as<Handle>(ReadPackCell(hPack));
                PremiumFeatureType iType = ReadPackCell(hPack);

                ReadPackFunction(hPack);
                ReadPackFunction(hPack);

                int iStyle = ITEMDRAW_DEFAULT;

                if(iType == SELECTABLE) {
                    char szParent[PLATFORM_MAX_PATH];
                    SearchFeatureParent(szItem, szParent, sizeof szParent);

                    if(strlen(szParent))
                        if(!CORE_IsAllowedFeature(szParent)) return ITEMDRAW_DISABLED;
                }else if(iType == STATUS && !CORE_IsAllowedFeature(szItem)) return ITEMDRAW_DISABLED;

                Function OnItemDraw = ReadPackFunction(hPack);

                if(OnItemDraw != INVALID_FUNCTION) {
                    Call_StartFunction(hPlugin, OnItemDraw);

                    Call_PushCell(iClient);
                    Call_PushString(szItem);

                    Call_Finish(iStyle);
                }

                return iStyle;
            }else return ITEMDRAW_DISABLED;
        }

        case MenuAction_DisplayItem: {
            char szItem[PLATFORM_MAX_PATH];
            GetMenuItem(hMenu, iSlot, szItem, sizeof szItem);

            if(!StrEqual(szItem, "noFeatures")) {
                DataPack hPack;
                GetTrieValue(g_hFeatures, szItem, hPack);

                ResetPack(hPack);

                char szDisplay[PLATFORM_MAX_PATH];

                Handle hPlugin = view_as<Handle>(ReadPackCell(hPack));
                PremiumFeatureType iType = ReadPackCell(hPack);

                switch(iType) {
                    case STATUS: {
                        if(!TranslationPhraseExists(szItem)) FormatEx(szDisplay, sizeof szDisplay, "%s [%s]", szItem, CORE_GetClientFeatureStatus(iClient, szItem) ? "+" : "-");
                        else FormatEx(szDisplay, sizeof szDisplay, "%T [%s]", szItem, iClient, CORE_GetClientFeatureStatus(iClient, szItem) ? "+" : "-");
                    }
                    
                    case SELECTABLE: {
                        if(!TranslationPhraseExists(szItem)) FormatEx(szDisplay, sizeof szDisplay, "%s", szItem);
                        else FormatEx(szDisplay, sizeof szDisplay, "%T", szItem, iClient);
                    }
                }

                ReadPackFunction(hPack);

                Function OnItemDisplay = ReadPackFunction(hPack);

                if(OnItemDisplay != INVALID_FUNCTION) {
                    Call_StartFunction(hPlugin, OnItemDisplay);

                    Call_PushCell(iClient);
                    Call_PushString(szItem);
                    Call_PushStringEx(szDisplay, sizeof szDisplay, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
                    Call_PushCell(sizeof szDisplay);

                    Call_Finish();
                }

                return RedrawMenuItem(szDisplay);
            }
        }

        case MenuAction_Select: {
            char szItem[PLATFORM_MAX_PATH];
            GetMenuItem(hMenu, iSlot, szItem, sizeof szItem);

            DataPack hPack;
            GetTrieValue(g_hFeatures, szItem, hPack);

            ResetPack(hPack);

            Handle hPlugin = view_as<Handle>(ReadPackCell(hPack));
            PremiumFeatureType iType = ReadPackCell(hPack);

            Function OnItemSelect = ReadPackFunction(hPack);

            if(OnItemSelect != INVALID_FUNCTION) {
                Call_StartFunction(hPlugin, OnItemSelect);

                Call_PushCell(iClient);
                Call_PushString(szItem);

                Call_Finish();
            }

            if(iType == STATUS)
                DisplayMenuAtItem(hMenu, iClient, hMenu.Selection, MENU_TIME_FOREVER);
        }
    }

    return 0;
}

stock void CORE_ShowMenu(int iClient, MenuType iType = DEFAULT, int iTime = MENU_TIME_FOREVER) {
    Panel hPanel;
    bool bIsPanel = false;

    if(GetMenuItemCount(g_hMenu))
        RemoveAllMenuItems(g_hMenu);
    
    switch(iType) {
        case DEFAULT: {
            int iExpires = CORE_GetClientExpires(iClient);

            char szGroup[MAX_GROUP_LENGTH], szClientGroup[MAX_GROUP_LENGTH];
            char szTime[PLATFORM_MAX_PATH], szExpires[PLATFORM_MAX_PATH];

            CORE_GetClientGroup(iClient, szGroup, sizeof szGroup);
            FormatEx(szClientGroup, sizeof szClientGroup, "%T", "ClientGroup", iClient, szGroup);

            if(iExpires) FormatTime(szTime, sizeof szTime, "%d.%m.%Y - %H:%M:%S", iExpires);
            else FormatEx(szTime, sizeof szTime, "%T", "Forever", iClient);

            FormatEx(szExpires, sizeof szExpires, "%T", "AccessExpires", iClient, szTime);

            SetMenuTitle(g_hMenu, "%T\n \n%s\n%s\n ", "Titles_Premium", iClient, szClientGroup, szExpires);

            StringMap hGroupFeatures;
            GetTrieValue(g_hGroups, szGroup, hGroupFeatures);

            Handle hFeatures;
            int iFeaturesCount = 0;

            if(hGroupFeatures != INVALID_HANDLE) {
                hFeatures = CreateTrieSnapshot(hGroupFeatures);
                iFeaturesCount = TrieSnapshotLength(hFeatures);
            }

            for(int i = 0; i < iFeaturesCount; i++) {
                char szGroupFeature[MAX_FEATURE_LENGTH];
                GetTrieSnapshotKey(hFeatures, i, szGroupFeature, sizeof szGroupFeature);
                
                if(!CORE_IsRegisteredFeature(szGroupFeature) || !CORE_GetFeatureStatus(szGroupFeature, szGroup)) continue;

                DataPack hPack;
                GetTrieValue(g_hFeatures, szGroupFeature, hPack);

                ResetPack(hPack);
                ReadPackCell(hPack);

                char szItem[PLATFORM_MAX_PATH];
                PremiumFeatureType iFType = ReadPackCell(hPack);

                switch(iFType) {
                    case STATUS: {
                        if(TranslationPhraseExists(szGroupFeature)) FormatEx(szItem, sizeof szItem, "%T [%s]", szGroupFeature, iClient, CORE_GetClientFeatureStatus(iClient, szGroupFeature) ? "+" : "-");
                        else FormatEx(szItem, sizeof szItem, "%s [%s]", szGroupFeature, CORE_GetClientFeatureStatus(iClient, szGroupFeature) ? "+" : "-");

                        AddMenuItem(g_hMenu, szGroupFeature, szItem);

                        char szParent[PLATFORM_MAX_PATH];
                        SearchFeatureParent(szGroupFeature, szParent, sizeof szParent);

                        if(strlen(szParent)) {
                            FormatEx(szItem, sizeof szItem, TranslationPhraseExists(szParent) ? "%T" : "%s", szParent, iClient);
                            AddMenuItem(g_hMenu, szParent, szItem);
                        }
                    }

                    case SELECTABLE: {
                        FormatEx(szItem, sizeof szItem, "%T", szGroupFeature, iClient);
                        AddMenuItem(g_hMenu, szGroupFeature, szItem);
                    }
                }
            }

            CloseHandle(hFeatures);

            if(!iFeaturesCount || !GetMenuItemCount(g_hMenu)) {
                char szItem[PLATFORM_MAX_PATH];
                FormatEx(szItem, sizeof szItem, "%T", "NoFeatures", iClient);

                AddMenuItem(g_hMenu, "noFeatures", szItem);
            }
        }

        case NO_ACCESS: {
            bIsPanel = true;

            hPanel = CreatePanel();

            char szContent[PLATFORM_MAX_PATH], szExit[64];
            FormatEx(szExit, sizeof szExit, "%T", "Buttons_Exit", iClient);
            FormatEx(szContent, sizeof szContent, "%T", "Panels_NoAccess", iClient);

            SetPanelTitle(hPanel, szContent);
            SetPanelCurrentKey(hPanel, 1);
            DrawPanelText(hPanel, "\n ");
            SetPanelCurrentKey(hPanel, 10);
            DrawPanelItem(hPanel, szExit);

            CORE_PlaySound(iClient, NO_ACCESS_SOUND);
        }

        case HAVE_ACCESS: {
            bIsPanel = true;

            hPanel = CreatePanel();

            char szContent[PLATFORM_MAX_PATH], szExit[64];
            FormatEx(szExit, sizeof szExit, "%T", "Buttons_Exit", iClient);
            FormatEx(szContent, sizeof szContent, "%T", "Panels_HaveAccess", iClient);

            SetPanelTitle(hPanel, szContent);
            SetPanelCurrentKey(hPanel, 1);
            DrawPanelText(hPanel, "\n ");
            SetPanelCurrentKey(hPanel, 10);
            DrawPanelItem(hPanel, szExit);
        }

        case GIVE_ACCESS: {
            bIsPanel = true;

            hPanel = CreatePanel();

            char szContent[PLATFORM_MAX_PATH], szExit[64];
            FormatEx(szExit, sizeof szExit, "%T", "Buttons_Exit", iClient);
            FormatEx(szContent, sizeof szContent, "%T", "Panels_GiveAccess", iClient);

            SetPanelTitle(hPanel, szContent);
            SetPanelCurrentKey(hPanel, 1);
            DrawPanelText(hPanel, "\n ");
            SetPanelCurrentKey(hPanel, 10);
            DrawPanelItem(hPanel, szExit);
        }

        case REMOVE_ACCESS: {
            bIsPanel = true;

            hPanel = CreatePanel();

            char szContent[PLATFORM_MAX_PATH], szExit[64];
            FormatEx(szExit, sizeof szExit, "%T", "Buttons_Exit", iClient);
            FormatEx(szContent, sizeof szContent, "%T", "Panels_RemoveAccess", iClient);

            SetPanelTitle(hPanel, szContent);
            SetPanelCurrentKey(hPanel, 1);
            DrawPanelText(hPanel, "\n ");
            SetPanelCurrentKey(hPanel, 10);
            DrawPanelItem(hPanel, szExit);
        }
    }

    bIsPanel ? SendPanelToClient(hPanel, iClient, CallBack_ShowPanel, iTime) : DisplayMenu(g_hMenu, iClient, iTime);
}

public int CallBack_ShowPanel(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_End: CloseHandle(hMenu);
    }

    return 0;
}

stock void ShowAllClientsMenu(int iClient) {
    Menu hMenu = CreateMenu(CallBack_ShowAllClientsMenu);

    SetMenuTitle(hMenu, "%T\n ", "Titles_SelectClient", iClient);

    for(int iTarget = 1; iTarget <= MaxClients; iTarget++) {
        if(!CORE_IsValidClient(iTarget) || CORE_IsClientHaveAccess(iTarget)) continue;

        char szUserId[10], szName[MAX_NAME_LENGTH];
        GetClientName(iTarget, szName, sizeof szName);
        IntToString(GetClientUserId(iTarget), szUserId, sizeof szUserId);

        AddMenuItem(hMenu, szUserId, szName);
    }

    if(!GetMenuItemCount(hMenu)) {
        char szItem[PLATFORM_MAX_PATH];
        FormatEx(szItem, sizeof szItem, "%T", "NoClients", iClient);

        AddMenuItem(hMenu, NULL_STRING, szItem, ITEMDRAW_DISABLED);
    }

    SetMenuExitBackButton(hMenu, true);

    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int CallBack_ShowAllClientsMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szUserId[10];
            GetMenuItem(hMenu, iSlot, szUserId, sizeof szUserId);

            ClearClientData(iClient);
            CreateClientData(iClient);

            SetTrieValue(g_hClientData[iClient], "Action", ACTION_ADD_CLIENT);
            SetTrieValue(g_hClientData[iClient], "Target", StringToInt(szUserId));

            ShowTimesMenu(iClient);
        }

        case MenuAction_Cancel: {
            if(iSlot == MenuCancel_ExitBack)
                DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
        }

        case MenuAction_End: CloseHandle(hMenu);
    }

    return 0;
}

stock void ShowTimesMenu(int iClient) {
    Menu hMenu = CreateMenu(CallBack_ShowTimesMenu);

    SetMenuTitle(hMenu, "%T\n ", "Titles_SelectTime", iClient);

    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof szPath, TIMES_PATH);

    if(g_hConfigs[CONFIG_TIMES] != INVALID_HANDLE)
        delete g_hConfigs[CONFIG_TIMES];
    
    g_hConfigs[CONFIG_TIMES] = CreateKeyValues("Times");

    if(!FileToKeyValues(g_hConfigs[CONFIG_TIMES], szPath))
        SetFailState("Failed to load configuration file with times: %s", szPath);
    
    KvRewind(g_hConfigs[CONFIG_TIMES]);

    ActionType iAction;
    GetTrieValue(g_hClientData[iClient], "Action", iAction);

    if(KvGotoFirstSubKey(g_hConfigs[CONFIG_TIMES])) {
        char szLang[2][8], szSection[32], szItem[PLATFORM_MAX_PATH];

        GetLanguageInfo(GetServerLanguage(), szLang[0], sizeof szLang[]);
        GetLanguageInfo(GetClientLanguage(iClient), szLang[1], sizeof szLang[]);

        do {
            KvGetSectionName(g_hConfigs[CONFIG_TIMES], szSection, sizeof szSection);
            KvGetString(g_hConfigs[CONFIG_TIMES], szLang[1], szItem, sizeof szItem, "LangError");

            if(!strlen(szItem))
                KvGetString(g_hConfigs[CONFIG_TIMES], szLang[0], szItem, sizeof szItem, "LangError");

            if(iAction == ACTION_UPDATE_EXPIRES) {
                ExpiresAction iExpAction;
                GetTrieValue(g_hClientData[iClient], "UpdateType", iExpAction);
                
                if(iExpAction != EXP_ACTION_SET) {
                    if(StringToInt(szSection) != 0)
                        AddMenuItem(hMenu, szSection, szItem);
                }else AddMenuItem(hMenu, szSection, szItem);
            }else AddMenuItem(hMenu, szSection, szItem);
        }while(KvGotoNextKey(g_hConfigs[CONFIG_TIMES], false))
    }

    if(!GetMenuItemCount(hMenu)) {
        char szItem[PLATFORM_MAX_PATH];
        FormatEx(szItem, sizeof szItem, "%T", "NoItems", iClient);

        AddMenuItem(hMenu, NULL_STRING, szItem, ITEMDRAW_DISABLED);
    }

    SetMenuExitBackButton(hMenu, true);

    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int CallBack_ShowTimesMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szTime[32];
            GetMenuItem(hMenu, iSlot, szTime, sizeof szTime);
            
            ActionType iAction;
            GetTrieValue(g_hClientData[iClient], "Action", iAction);

            if(iAction == ACTION_ADD_CLIENT) {
                SetTrieValue(g_hClientData[iClient], "Expire", StringToInt(szTime));

                ShowGroupsMenu(iClient);
            }

            if(iAction == ACTION_UPDATE_EXPIRES) {
                ExpiresAction iExpAction;
                GetTrieValue(g_hClientData[iClient], "UpdateType", iExpAction);
                
                char szAuth[MAX_AUTHID_LENGTH];
                GetTrieString(g_hClientData[iClient], "Target", szAuth, sizeof szAuth);
                
                char szQuery[PLATFORM_MAX_PATH];
                FormatEx(szQuery, sizeof szQuery, "SELECT `expires` FROM `%s_users` WHERE `player_auth` = '%s'", g_szTablePrefix, szAuth);

                SQL_LockDatabase(g_hDatabase);
                DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
                SQL_UnlockDatabase(g_hDatabase);

                int iExpires;

                if(SQL_FetchRow(hResults)) iExpires = SQL_FetchInt(hResults, 0);
                else iExpires = GetTime();

                int iExpValue = StringToInt(szTime);

                char szAdminAuth[MAX_AUTHID_LENGTH], szName[2][MAX_NAME_LENGTH];

                GetClientName(iClient, szName[0], sizeof szName[]);
                GetClientAuthId(iClient, AuthId_Steam2, szAdminAuth, sizeof szAdminAuth);
                GetPremiumClientName(szAuth, szName[1], sizeof szName[]);

                char szTimeValue[PLATFORM_MAX_PATH];
                CORE_FormatAccessTime(LANG_SERVER, iExpValue, szTimeValue, sizeof szTimeValue);

                StringMap hData = CreateTrie();
                char szPhrase[PLATFORM_MAX_PATH];

                SetTrieString(hData, "0", szName[0]);
                SetTrieString(hData, "1", szAdminAuth);
                SetTrieString(hData, "2", szName[1]);
                SetTrieString(hData, "3", szAuth);
                SetTrieString(hData, "4", szTimeValue);

                if(iExpAction == EXP_ACTION_SET) {
                    iExpires = iExpValue == 0 ? iExpValue : iExpires == 0 ? GetTime() + iExpValue : iExpires + iExpValue;

                    FormatEx(szPhrase, sizeof szPhrase, "PremiumLog_SetPremiumExpires");
                }

                if(iExpAction == EXP_ACTION_ADD) {
                    iExpires = iExpires == 0 ? GetTime() + iExpValue : iExpires + iExpValue;
                    
                    char szValue[PLATFORM_MAX_PATH];
                    FormatTime(szValue, sizeof szValue, "%d.%m.%Y - %H:%M:%S", iExpires);

                    SetTrieString(hData, "5", szValue);

                    FormatEx(szPhrase, sizeof szPhrase, "PremiumLog_AddPremiumExpires");
                }

                if(iExpAction == EXP_ACTION_TAKE) {
                    iExpires = iExpires - iExpValue;

                    char szValue[PLATFORM_MAX_PATH];
                    FormatTime(szValue, sizeof szValue, "%d.%m.%Y - %H:%M:%S", iExpires);

                    SetTrieString(hData, "5", szValue);

                    FormatEx(szPhrase, sizeof szPhrase, "PremiumLog_TakePremiumExpires");
                }

                PrintToLogs(szPhrase, hData);
                
                FormatEx(szQuery, sizeof szQuery, "UPDATE `%s_users` SET `expires` = '%i' WHERE `player_auth` = '%s'", g_szTablePrefix, iExpires, szAuth);
                g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);
            }
        }

        case MenuAction_Cancel: {
            if(iSlot == MenuCancel_ExitBack) {
                ActionType iAction;
                GetTrieValue(g_hClientData[iClient], "Action", iAction);

                if(iAction == ACTION_ADD_CLIENT)
                    ShowAllClientsMenu(iClient);
                
                if(iAction == ACTION_UPDATE_EXPIRES)
                    ShowUpdateExpires(iClient);
            }
        }

        case MenuAction_End: CloseHandle(hMenu);
    }

    return 0;
}

stock void ShowGroupsMenu(int iClient) {
    Menu hMenu = CreateMenu(CallBack_ShowGroupsMenu);

    SetMenuTitle(hMenu, "%T\n ", "Titles_SelectGroup", iClient);

    char szGroup[MAX_GROUP_LENGTH];
    Handle hGroups = CreateTrieSnapshot(g_hGroups);
    int iLength = TrieSnapshotLength(hGroups);

    for(int i = 0; i < iLength; i++) {
        GetTrieSnapshotKey(hGroups, i, szGroup, sizeof szGroup);
        
        ActionType iAction;

        if(GetTrieValue(g_hClientData[iClient], "Action", iAction)) {
            if(iAction == ACTION_UPDATE_GROUP) {
                char szAuth[MAX_AUTHID_LENGTH], szClientGroup[MAX_GROUP_LENGTH];

                GetTrieString(g_hClientData[iClient], "Target", szAuth, sizeof szAuth);
                GetClientGroup(szAuth, szClientGroup, sizeof szClientGroup);

                if(!StrEqual(szClientGroup, szGroup))
                    AddMenuItem(hMenu, szGroup, szGroup);
                else
                    AddMenuItem(hMenu, szGroup, szGroup, ITEMDRAW_DISABLED);
            }else AddMenuItem(hMenu, szGroup, szGroup);
        }else AddMenuItem(hMenu, szGroup, szGroup);
    }

    CloseHandle(hGroups);

    if(!GetMenuItemCount(hMenu)) {
        char szItem[PLATFORM_MAX_PATH];
        FormatEx(szItem, sizeof szItem, "%T", "NoGroups", iClient);

        AddMenuItem(hMenu, NULL_STRING, szItem, ITEMDRAW_DISABLED);
    }

    SetMenuExitBackButton(hMenu, true);

    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int CallBack_ShowGroupsMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szGroup[MAX_GROUP_LENGTH];
            GetMenuItem(hMenu, iSlot, szGroup, sizeof szGroup);
            
            ActionType iType;
            GetTrieValue(g_hClientData[iClient], "Action", iType);

            if(iType == ACTION_ADD_CLIENT) {
                int iExpires;
                GetTrieValue(g_hClientData[iClient], "Expire", iExpires);
                
                int iUserId;
                GetTrieValue(g_hClientData[iClient], "Target", iUserId);

                char szTime[2][PLATFORM_MAX_PATH];
                int iTarget = GetClientOfUserId(iUserId);

                CORE_FormatAccessTime(iClient, iExpires, szTime[0], sizeof szTime[]);
                CORE_FormatAccessTime(iTarget, iExpires, szTime[1], sizeof szTime[]);

                CORE_GiveClientAccess(iTarget, szGroup, iClient, iExpires);

                char szBuffer[PLATFORM_MAX_PATH];

                FormatEx(szBuffer, sizeof szBuffer, "%T", "Messages_GiveAccess", iTarget, iTarget, iClient, szGroup, szTime[1]);
                CORE_PrintToChat(iTarget, szBuffer);

                FormatEx(szBuffer, sizeof szBuffer, "%T", "Messages_GiveAccessAdmin", iClient, iClient, szGroup, iTarget, szTime[0]);
                CORE_PrintToChat(iClient, szBuffer);
            }

            if(iType == ACTION_UPDATE_GROUP) {
                char szAuth[MAX_AUTHID_LENGTH];
                GetTrieString(g_hClientData[iClient], "Target", szAuth, sizeof szAuth);

                SetClientGroup(szAuth, szGroup);

                char szBuffer[PLATFORM_MAX_PATH];
                int iTarget = CORE_GetClientByAuth(szAuth);

                if(CORE_IsValidClient(iTarget)) {
                    FormatEx(szBuffer, sizeof szBuffer, "%T", "Messages_ChangeClientGroup", iTarget, iClient, szGroup);
                    CORE_PrintToChat(iTarget, szBuffer);
                }

                char szTargetName[MAX_NAME_LENGTH];
                GetPremiumClientName(szAuth, szTargetName, sizeof szTargetName);

                FormatEx(szBuffer, sizeof szBuffer, "%T", "Messages_ChangeClientGroupAdmin", iClient, iClient, szTargetName, szGroup);
                CORE_PrintToChat(iClient, szBuffer);
                
                StringMap hData = CreateTrie();

                char szAdminAuth[MAX_AUTHID_LENGTH], szName[2][MAX_NAME_LENGTH];

                GetPremiumClientName(szAuth, szName[1], sizeof szName[]);
                GetClientName(iClient, szName[0], sizeof szName[]);
                GetClientAuthId(iClient, AuthId_Steam2, szAdminAuth, sizeof szAdminAuth);

                SetTrieString(hData, "0", szName[0]);
                SetTrieString(hData, "1", szAdminAuth);
                SetTrieString(hData, "2", szName[1]);
                SetTrieString(hData, "3", szAuth);
                SetTrieString(hData, "4", szGroup);

                PrintToLogs("PremiumLog_ChangeClientGroup", hData);
            }
        }
        
        case MenuAction_Cancel: {
            if(iSlot == MenuCancel_ExitBack) {
                ActionType iType;
                GetTrieValue(g_hClientData[iClient], "Action", iType);

                if(iType == ACTION_ADD_CLIENT) {
                    SetTrieValue(g_hClientData[iClient], "Expire", -1);
                
                    ShowTimesMenu(iClient);
                }

                if(iType == ACTION_UPDATE_GROUP) {
                    char szAuth[MAX_AUTHID_LENGTH];
                    GetTrieString(g_hClientData[iClient], "Target", szAuth, sizeof szAuth);
                    
                    ShowClientInfo(iClient, szAuth);
                    ClearClientData(iClient);
                }
            }
        }

        case MenuAction_End: CloseHandle(hMenu);
    }

    return 0;
}

stock void ShowPremiumClientsMenu(int iClient) {
    char szQuery[PLATFORM_MAX_PATH];

    FormatEx(szQuery, sizeof szQuery, "SELECT * FROM `%s_users` ORDER BY `id` DESC", g_szTablePrefix);
    g_hDatabase.Query(SQL_CallBack_ShowPremiumClients, szQuery, GetClientUserId(iClient));
}

public int CallBack_ShowPremiumClientsMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szAuth[MAX_AUTHID_LENGTH];
            GetMenuItem(hMenu, iSlot, szAuth, sizeof szAuth);

            ShowClientInfo(iClient, szAuth);
        }

        case MenuAction_Cancel: {
            if(iSlot == MenuCancel_ExitBack)
                DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
        }

        case MenuAction_End: CloseHandle(hMenu);
    }

    return 0;
}

stock void ShowClientInfo(int iClient, const char[] szAuth) {
    char szQuery[PLATFORM_MAX_PATH];
    
    FormatEx(szQuery, sizeof szQuery, "SELECT * FROM `%s_users` WHERE `player_auth` = '%s'", g_szTablePrefix, szAuth);
    g_hDatabase.Query(SQL_CallBack_ShowClientInfo, szQuery, GetClientUserId(iClient));
}

public int CallBack_ShowClientInfo(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szAction[64];
            GetMenuItem(hMenu, iSlot, szAction, sizeof szAction);

            char szAuth[MAX_AUTHID_LENGTH];
            GetTrieString(g_hClientData[iClient], "Target", szAuth, sizeof szAuth);

            if(StrEqual(szAction, "removeAccess")) {
                CORE_RemoveClientAccess(szAuth, iClient, "The administrator has taken away access.");

                char szName[MAX_NAME_LENGTH], szBuffer[PLATFORM_MAX_PATH];

                int iTarget = CORE_GetClientByAuth(szAuth);

                if(CORE_IsValidClient(iTarget)) {
                    FormatEx(szBuffer, sizeof szBuffer, "%T", "Messages_RemoveAccess", iTarget, iTarget, iClient);
                    CORE_PrintToChat(iTarget, szBuffer);
                    
                    GetClientName(iTarget, szName, sizeof szName);
                }

                FormatEx(szBuffer, sizeof szBuffer, "%T", "Messages_RemoveAccessAdmin", iClient, iClient, strlen(szName) ? szName : szAuth);
                CORE_PrintToChat(iClient, szBuffer);
            }

            if(StrEqual(szAction, "changeGroup")) {
                SetTrieValue(g_hClientData[iClient], "Action", ACTION_UPDATE_GROUP);

                ShowGroupsMenu(iClient);
            }

            if(StrEqual(szAction, "changeExpires")) {
                SetTrieValue(g_hClientData[iClient], "Action", ACTION_UPDATE_EXPIRES);

                ShowUpdateExpires(iClient);
            }
        }

        case MenuAction_Cancel: {
            if(iSlot == MenuCancel_ExitBack)
                ShowPremiumClientsMenu(iClient);
        }

        case MenuAction_End: CloseHandle(hMenu);
    }

    return 0;
}

stock void ShowUpdateExpires(int iClient) {
    Menu hMenu = CreateMenu(CallBack_UpdateExpires);

    SetMenuTitle(hMenu, "%T\n ", "Titles_SelectAction", iClient);

    char szItem[PLATFORM_MAX_PATH];

    FormatEx(szItem, sizeof szItem, "%T\n ", "Items_SetExpireTime", iClient);
    AddMenuItem(hMenu, "setExpire", szItem);

    FormatEx(szItem, sizeof szItem, "%T", "Items_AddExpireTime", iClient);
    AddMenuItem(hMenu, "addExpire", szItem);

    FormatEx(szItem, sizeof szItem, "%T", "Items_TakeExpireTime", iClient);
    AddMenuItem(hMenu, "takeExpire", szItem);

    SetMenuExitBackButton(hMenu, true);

    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int CallBack_UpdateExpires(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szAction[64];
            GetMenuItem(hMenu, iSlot, szAction, sizeof szAction);

            if(StrEqual(szAction, "setExpire"))
                SetTrieValue(g_hClientData[iClient], "UpdateType", EXP_ACTION_SET);
            
            if(StrEqual(szAction, "addExpire"))
                SetTrieValue(g_hClientData[iClient], "UpdateType", EXP_ACTION_ADD);
            
            if(StrEqual(szAction, "takeExpire"))
                SetTrieValue(g_hClientData[iClient], "UpdateType", EXP_ACTION_TAKE);
            
            ShowTimesMenu(iClient);
        }

        case MenuAction_Cancel: {
            if(iSlot == MenuCancel_ExitBack) {
                char szAuth[MAX_AUTHID_LENGTH];
                GetTrieString(g_hClientData[iClient], "Target", szAuth, sizeof szAuth);

                ShowClientInfo(iClient, szAuth);
                ClearClientData(iClient);
            }
        }

        case MenuAction_End: CloseHandle(hMenu);
    }

    return 0;
}

stock void ShowDatabaseManagementMenu(int iClient) {
    Menu hMenu = CreateMenu(CallBack_ShowDatabaseManagementMenu);

    SetMenuTitle(hMenu, "%T\n ", "Titles_SelectAction", iClient);

    char szItem[PLATFORM_MAX_PATH];

    FormatEx(szItem, sizeof szItem, "%T", "Items_CleanUsers", iClient);
    AddMenuItem(hMenu, "cleanUsers", szItem);

    FormatEx(szItem, sizeof szItem, "%T", "Items_CleanSettings", iClient);
    AddMenuItem(hMenu, "cleanSettings", szItem);

    SetMenuExitBackButton(hMenu, true);

    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int CallBack_ShowDatabaseManagementMenu(Menu hMenu, MenuAction mAction, int iClient, int iSlot) {
    switch(mAction) {
        case MenuAction_Select: {
            char szAction[64];
            GetMenuItem(hMenu, iSlot, szAction, sizeof szAction);

            char szAuth[MAX_AUTHID_LENGTH], szName[MAX_NAME_LENGTH], szQuery[PLATFORM_MAX_PATH];

            GetClientName(iClient, szName, sizeof szName);
            GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof szAuth);

            StringMap hData = CreateTrie();

            SetTrieString(hData, "0", szName);
            SetTrieString(hData, "1", szAuth);

            if(StrEqual(szAction, "cleanUsers")) {
                for(int iTarget = 1; iTarget <= MaxClients; iTarget++)
                    if(CORE_IsValidClient(iTarget))
                        g_bIsHaveAccess[iTarget] = false;
                
                PrintToLogs("PremiumLog_ClearPremiumUsers", hData);

                FormatEx(szQuery, sizeof szQuery, "DELETE FROM `%s_users`", g_szTablePrefix);
            }
            
            if(StrEqual(szAction, "cleanSettings")) {
                PrintToLogs("PremiumLog_ClearPremiumUsersPreferences", hData);

                FormatEx(szQuery, sizeof szQuery, "DELETE FROM `%s_settings`", g_szTablePrefix);
            }
            
            g_hDatabase.Query(SQL_CallBack_ErrorHandle, szQuery);
            
            char szBuffer[PLATFORM_MAX_PATH];
            FormatEx(szBuffer, sizeof szBuffer, "%T", "Messages_DatabaseActionExecuted", iClient);

            CORE_PrintToChat(iClient, szBuffer);
            ShowDatabaseManagementMenu(iClient);
        }

        case MenuAction_Cancel:
            if(iSlot == MenuCancel_ExitBack)
                DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
        
        case MenuAction_End: CloseHandle(hMenu);
    }

    return 0;
}