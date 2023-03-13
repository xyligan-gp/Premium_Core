stock void InitDownloads() {
    char szPath[PLATFORM_MAX_PATH], szDownloadPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof szPath, DOWNLOADS_PATH);

    File hFile = OpenFile(szPath, "r");

    if(hFile != null) {
        while(!IsEndOfFile(hFile) && ReadFileLine(hFile, szDownloadPath, sizeof szDownloadPath)) {
            TrimString(szDownloadPath);
            DownloadPath(szDownloadPath);
        }

        delete hFile;
    }
}

stock void DownloadPath(const char[] szPath) {
    switch(GetFileType(szPath)) {
        case FileType_File: DownloadFile(szPath);
        case FileType_Directory: DownloadDirectory(szPath);
    }
}

stock FileType GetFileType(const char[] szPath) {
    if(FileExists(szPath))
        return FileType_File;

    if(DirExists(szPath))
        return FileType_Directory;

    return FileType_Unknown;
}

stock void DownloadFile(const char[] szPath) {
    if(FileExists(szPath)) AddFileToDownloadsTable(szPath);
    else LogError("File path '%s' not found!", szPath);
}

stock void DownloadDirectory(const char[] szPath) {
    DirectoryListing hDirectory = OpenDirectory(szPath);

    if(hDirectory != null) {
        FileType hType;
        char szEntry[PLATFORM_MAX_PATH], szGeneratedPath[PLATFORM_MAX_PATH];

        while(hDirectory.GetNext(szEntry, sizeof szEntry, hType)) {
            if(hType == FileType_Directory && (!strcmp(szEntry, ".") || !strcmp(szEntry, "..")))
                continue;

            FormatEx(szGeneratedPath, sizeof szGeneratedPath, "%s/%s", szPath, szEntry);

            switch(hType) {
                case FileType_File: DownloadFile(szGeneratedPath);
                case FileType_Directory: DownloadDirectory(szGeneratedPath);
            }
        }

        delete hDirectory;
    }
}