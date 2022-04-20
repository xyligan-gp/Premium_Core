stock void DBG_API(const char[] szMessage, any ...) {
    #if DEBUG_MODE 1
        #if defined DEBUG_API
            char szBuffer[1024];

            VFormat(szBuffer, sizeof szBuffer, szMessage, 2);
            LogToFileEx(g_szDebugPath, "API: %s", szBuffer);
        #endif
    #endif
}

stock void DBG_MODULE(const char[] szMessage, any ...) {
    #if DEBUG_MODE 1
        #if defined DEBUG_MODULES
            char szBuffer[1024];
            
            VFormat(szBuffer, sizeof szBuffer, szMessage, 2);
            LogToFileEx(g_szDebugPath, "MODULE: %s", szBuffer);
        #endif
    #endif
}

stock void DBG_SQL(const char[] szMessage, any...) {
    #if DEBUG_MODE 1
        #if defined DEBUG_SQL
            char szBuffer[1024];
            
            VFormat(szBuffer, sizeof szBuffer, szMessage, 2);
            LogToFileEx(g_szDebugPath, "SQL: %s", szBuffer);
        #endif
    #endif
}