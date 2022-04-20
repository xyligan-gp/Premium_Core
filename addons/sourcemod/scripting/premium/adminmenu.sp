public void InitialAdminMenu() {
    Handle hTopMenu;

    if(LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE)) OnAdminMenuReady(hTopMenu);
}

stock void OnAdminMenuReady(Handle hTopMenu) {
    if(hTopMenu == g_hTopMenu) return;
	
	g_hTopMenu = view_as<TopMenu>(hTopMenu);

	TopMenuObject hTopMenuObject = g_hTopMenu.FindCategory(PREMIUM_MAINMENU);

    if(hTopMenuObject == INVALID_TOPMENUOBJECT)
		hTopMenuObject = g_hTopMenu.AddCategory(PREMIUM_MAINMENU, CallBack_Premium_MainMenu, "premium_admin", g_iAdminMenuFlags);

    g_hTopMenu.AddItem("premium_give_access", CallBack_SelectPlayer_GiveAccess, hTopMenuObject, "premium_give_access", g_iAdminMenuFlags);
    g_hTopMenu.AddItem("premium_players", CallBack_PremiumPlayers, hTopMenuObject, "premium_players", g_iAdminMenuFlags);
    g_hTopMenu.AddItem("premium_remove_access", CallBack_SelectPlayer_RemoveAccess, hTopMenuObject, "premium_remove_access", g_iAdminMenuFlags);
	g_hTopMenu.AddItem("premium_database_manage", CallBack_Database_Manage, hTopMenuObject, "premium_database_manage", g_iAdminMenuFlags);

    API_CreateForward_OnAdminMenuReady(hTopMenu, g_iAdminMenuFlags);
}

public void CallBack_Premium_MainMenu(TopMenu hMenu, TopMenuAction mAction, TopMenuObject object_id, int iClient, char[] szBuffer, int iMaxLength) {
    switch(mAction) {
		case TopMenuAction_DisplayOption: FormatEx(szBuffer, iMaxLength, "%T", "AdminMenu_ItemName", iClient);
		case TopMenuAction_DisplayTitle: FormatEx(szBuffer, iMaxLength, "%T\n ", "AdminMenu_Title", iClient);
	}
}

public void CallBack_SelectPlayer_GiveAccess(TopMenu hMenu, TopMenuAction mAction, TopMenuObject object_id, int iClient, char[] szBuffer, int iMaxLength) {
	switch(mAction) {
		case TopMenuAction_DisplayOption: FormatEx(szBuffer, iMaxLength, "%T", "AdminMenu_GiveAccess", iClient);
		case TopMenuAction_SelectOption: ShowClientsMenu(iClient);
	}
}

public void CallBack_PremiumPlayers(TopMenu hMenu, TopMenuAction mAction, TopMenuObject object_id, int iClient, char[] szBuffer, int iMaxLength) {
	switch(mAction) {
		case TopMenuAction_DisplayOption: FormatEx(szBuffer, iMaxLength, "%T", "AdminMenu_PlayersList", iClient);
		case TopMenuAction_SelectOption: ShowPremiumPlayersMenu(iClient);
	}
}

public void CallBack_SelectPlayer_RemoveAccess(TopMenu hMenu, TopMenuAction mAction, TopMenuObject object_id, int iClient, char[] szBuffer, int iMaxLength) {
    switch(mAction) {
        case TopMenuAction_DisplayOption: FormatEx(szBuffer, iMaxLength, "%T", "AdminMenu_RemoveAccess", iClient);
        case TopMenuAction_SelectOption: ShowPremiumClientsMenu(iClient);
    }
}

public void CallBack_Database_Manage(TopMenu hMenu, TopMenuAction mAction, TopMenuObject object_id, int iClient, char[] szBuffer, int iMaxLength) {
    switch(mAction) {
        case TopMenuAction_DisplayOption: FormatEx(szBuffer, iMaxLength, "%T", "AdminMenu_DBManage", iClient);
        case TopMenuAction_SelectOption: ShowDBManageMenu(iClient);
    }
}