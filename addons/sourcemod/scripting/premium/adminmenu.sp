public void OnAdminMenuReady(Handle hMenu) {
    if(hMenu != g_hAdminMenu) {
        g_hAdminMenu = view_as<TopMenu>(hMenu);

        TopMenuObject hPremiumCategory = FindTopMenuCategory(g_hAdminMenu, PREMIUM_ADMINCATEGORY);

        if(hPremiumCategory == INVALID_TOPMENUOBJECT)
            hPremiumCategory = AddToTopMenu(g_hAdminMenu, PREMIUM_ADMINCATEGORY, TopMenuObject_Category, CallBack_PremiumAdminCategory, INVALID_TOPMENUOBJECT, NULL_STRING, g_iAdminFlags, NULL_STRING);
        
        AddToTopMenu(g_hAdminMenu, "premium_give_access", TopMenuObject_Item, CallBack_GiveAccess, hPremiumCategory, NULL_STRING, g_iAdminFlags, NULL_STRING);
        AddToTopMenu(g_hAdminMenu, "premium_all_clients", TopMenuObject_Item, CallBack_PremiumClients, hPremiumCategory, NULL_STRING, g_iAdminFlags, NULL_STRING);
        AddToTopMenu(g_hAdminMenu, "premium_restart_configuration", TopMenuObject_Item, CallBack_RestartConfiguration, hPremiumCategory, NULL_STRING, g_iAdminFlags, NULL_STRING);
        AddToTopMenu(g_hAdminMenu, "premium_database_management", TopMenuObject_Item, CallBack_DatabaseManagement, hPremiumCategory, NULL_STRING, g_iAdminFlags, NULL_STRING);
    }
}

public void CallBack_PremiumAdminCategory(TopMenu hMenu, TopMenuAction mAction, TopMenuObject hObject, int iClient, char[] szBuffer, int iMaxLength) {
    switch(mAction) {
        case TopMenuAction_DisplayOption: FormatEx(szBuffer, iMaxLength, "%T", "Items_Admin_Premium", iClient);
        case TopMenuAction_DisplayTitle: FormatEx(szBuffer, iMaxLength, "%T\n ", "Titles_Admin_Premium", iClient);
    }
}

public void CallBack_GiveAccess(TopMenu hMenu, TopMenuAction mAction, TopMenuObject hObject, int iClient, char[] szBuffer, int iMaxLength) {
    switch(mAction) {
        case TopMenuAction_DisplayOption: FormatEx(szBuffer, iMaxLength, "%T", "Items_GiveAccess", iClient);
        case TopMenuAction_SelectOption: ShowAllClientsMenu(iClient);
    }
}

public void CallBack_PremiumClients(TopMenu hMenu, TopMenuAction mAction, TopMenuObject hObject, int iClient, char[] szBuffer, int iMaxLength) {
    switch(mAction) {
        case TopMenuAction_DisplayOption: FormatEx(szBuffer, iMaxLength, "%T", "Items_ShowClients", iClient);
        case TopMenuAction_SelectOption: ShowPremiumClientsMenu(iClient);
    }
}

public void CallBack_RestartConfiguration(TopMenu hMenu, TopMenuAction mAction, TopMenuObject hObject, int iClient, char[] szBuffer, int iMaxLength) {
    switch(mAction) {
        case TopMenuAction_DisplayOption: FormatEx(szBuffer, iMaxLength, "%T", "Items_RestartConfig", iClient);
        case TopMenuAction_SelectOption: InitConfig(true, iClient);
    }
}

public void CallBack_DatabaseManagement(TopMenu hMenu, TopMenuAction mAction, TopMenuObject hObject, int iClient, char[] szBuffer, int iMaxLength) {
    switch(mAction) {
        case TopMenuAction_DisplayOption: FormatEx(szBuffer, iMaxLength, "%T", "Items_ManageDatabase", iClient);
        case TopMenuAction_SelectOption: ShowDatabaseManagementMenu(iClient);
    }
}