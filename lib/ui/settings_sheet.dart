import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/solo_echo_account.dart';
import '../models/workspace_info.dart';
import '../utils/timestamp_formatter.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    super.key,
    required this.account,
    required this.workspace,
    required this.lastSync,
    required this.onSignOut,
  });

  final SoloEchoAccount account;
  final WorkspaceInfo workspace;
  final DateTime? lastSync;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(account.initials)),
              title: Text(account.displayName ?? account.email),
              subtitle: Text(account.email),
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.table_chart_outlined,
              label: '시트',
              value: workspace.spreadsheetUrl,
              link: Uri.parse(workspace.spreadsheetUrl),
            ),
            _InfoRow(
              icon: Icons.sync_outlined,
              label: '동기화',
              value: lastSync == null
                  ? '없음'
                  : TimestampFormatter.format(lastSync!.toLocal()),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onSignOut,
              icon: Icon(Icons.logout, color: theme.colorScheme.error),
              label: Text(
                '로그아웃',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.link,
  });

  final IconData icon;
  final String label;
  final String value;
  final Uri? link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (link != null)
            IconButton(
              tooltip: '열기',
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                await launchUrl(link!, mode: LaunchMode.externalApplication);
              },
            ),
        ],
      ),
    );
  }
}
