class WorkspaceInfo {
  const WorkspaceInfo({
    required this.folderId,
    required this.spreadsheetId,
  });

  final String folderId;
  final String spreadsheetId;

  String get spreadsheetUrl {
    return 'https://docs.google.com/spreadsheets/d/$spreadsheetId';
  }
}
