import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/solo_echo_account.dart';
import '../models/workspace_info.dart';
import '../models/writing_mode.dart';
import '../utils/timestamp_formatter.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    super.key,
    required this.account,
    required this.workspace,
    required this.writingMode,
    required this.lastSync,
    required this.onWritingModeChanged,
    required this.onSignOut,
  });

  final SoloEchoAccount account;
  final WorkspaceInfo workspace;
  final WritingMode writingMode;
  final DateTime? lastSync;
  final Future<void> Function(WritingMode mode) onWritingModeChanged;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
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
            const SizedBox(height: 10),
            _WritingModeControl(
              value: writingMode,
              onChanged: onWritingModeChanged,
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

class _WritingModeControl extends StatelessWidget {
  const _WritingModeControl({
    required this.value,
    required this.onChanged,
  });

  final WritingMode value;
  final Future<void> Function(WritingMode mode) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.view_agenda_outlined,
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              '글쓰기',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SegmentedButton<WritingMode>(
              showSelectedIcon: false,
              segments: WritingMode.values
                  .map(
                    (mode) => ButtonSegment<WritingMode>(
                      value: mode,
                      label: Text(mode.label),
                    ),
                  )
                  .toList(),
              selected: <WritingMode>{value},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  return;
                }
                unawaited(onChanged(selection.single));
              },
            ),
          ),
        ],
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
