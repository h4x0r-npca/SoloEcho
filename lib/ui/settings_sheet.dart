import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_theme_mode.dart';
import '../models/font_scale_step.dart';
import '../models/solo_echo_account.dart';
import '../models/workspace_info.dart';
import '../models/writing_mode.dart';
import '../utils/timestamp_formatter.dart';
import 'app_theme.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    super.key,
    required this.account,
    required this.workspace,
    required this.writingMode,
    required this.themeMode,
    required this.fontScaleStep,
    required this.lastSync,
    required this.onWritingModeChanged,
    required this.onThemeModeChanged,
    required this.onFontScaleStepChanged,
    required this.onSignOut,
  });

  final SoloEchoAccount account;
  final WorkspaceInfo workspace;
  final WritingMode writingMode;
  final AppThemeMode themeMode;
  final FontScaleStep fontScaleStep;
  final DateTime? lastSync;
  final Future<void> Function(WritingMode mode) onWritingModeChanged;
  final Future<void> Function(AppThemeMode mode) onThemeModeChanged;
  final Future<void> Function(FontScaleStep step) onFontScaleStepChanged;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SoloEchoColors.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colors.point,
                foregroundColor: colors.pointText,
                child: Text(account.initials),
              ),
              title: Text(
                account.displayName ?? account.email,
                style: TextStyle(color: colors.textPrimary),
              ),
              subtitle: Text(
                account.email,
                style: TextStyle(color: colors.textSecondary),
              ),
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
            _ThemeModeControl(
              value: themeMode,
              onChanged: onThemeModeChanged,
            ),
            _FontScaleControl(
              value: fontScaleStep,
              onChanged: onFontScaleStepChanged,
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

class _FontScaleControl extends StatelessWidget {
  const _FontScaleControl({
    required this.value,
    required this.onChanged,
  });

  final FontScaleStep value;
  final Future<void> Function(FontScaleStep step) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SoloEchoColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.format_size,
            size: 22,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '글씨',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      value.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!value.isDefault)
                      TextButton(
                        onPressed: () {
                          unawaited(
                            onChanged(FontScaleStep.defaultValue),
                          );
                        },
                        child: const Text('기본크기'),
                      ),
                  ],
                ),
                Slider(
                  min: -3,
                  max: 3,
                  divisions: 6,
                  value: value.sliderValue,
                  label: value.label,
                  onChanged: (sliderValue) {
                    unawaited(
                      onChanged(FontScaleStep.fromSliderValue(sliderValue)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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
    final colors = SoloEchoColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.view_agenda_outlined,
            size: 22,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              '글쓰기',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
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

class _ThemeModeControl extends StatelessWidget {
  const _ThemeModeControl({
    required this.value,
    required this.onChanged,
  });

  final AppThemeMode value;
  final Future<void> Function(AppThemeMode mode) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SoloEchoColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.contrast_outlined,
            size: 22,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              '화면',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SegmentedButton<AppThemeMode>(
              showSelectedIcon: false,
              segments: AppThemeMode.values
                  .map(
                    (mode) => ButtonSegment<AppThemeMode>(
                      value: mode,
                      label: Text(mode.label),
                    ),
                  )
                  .toList(),
              selected: <AppThemeMode>{value},
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
    final colors = SoloEchoColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 22, color: colors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
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
