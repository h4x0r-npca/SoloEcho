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
import 'profile_avatar.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    super.key,
    required this.account,
    required this.workspace,
    required this.writingMode,
    required this.themeMode,
    required this.fontScaleStep,
    required this.motionEffectsEnabled,
    required this.lockEnabled,
    required this.lastSync,
    required this.onWritingModeChanged,
    required this.onThemeModeChanged,
    required this.onFontScaleStepChanged,
    required this.onMotionEffectsChanged,
    required this.onEnableLock,
    required this.onDisableLock,
    required this.onChangeLockPassword,
    required this.onSignOut,
  });

  final SoloEchoAccount account;
  final WorkspaceInfo workspace;
  final WritingMode writingMode;
  final AppThemeMode themeMode;
  final FontScaleStep fontScaleStep;
  final bool motionEffectsEnabled;
  final bool lockEnabled;
  final DateTime? lastSync;
  final Future<void> Function(WritingMode mode) onWritingModeChanged;
  final Future<void> Function(AppThemeMode mode) onThemeModeChanged;
  final Future<void> Function(FontScaleStep step) onFontScaleStepChanged;
  final Future<void> Function(bool enabled) onMotionEffectsChanged;
  final Future<String?> Function(String password) onEnableLock;
  final Future<String?> Function(String currentPassword) onDisableLock;
  final Future<String?> Function({
    required String currentPassword,
    required String newPassword,
  }) onChangeLockPassword;
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
              leading: ProfileAvatar(account: account),
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
            _MotionEffectsControl(
              value: motionEffectsEnabled,
              onChanged: onMotionEffectsChanged,
            ),
            _LockModeControl(
              enabled: lockEnabled,
              onEnableLock: onEnableLock,
              onDisableLock: onDisableLock,
              onChangeLockPassword: onChangeLockPassword,
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

class _MotionEffectsControl extends StatelessWidget {
  const _MotionEffectsControl({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final Future<void> Function(bool enabled) onChanged;

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
            Icons.animation_outlined,
            size: 22,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              '동작',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '애니메이션',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (enabled) {
              unawaited(onChanged(enabled));
            },
          ),
        ],
      ),
    );
  }
}

class _LockModeControl extends StatelessWidget {
  const _LockModeControl({
    required this.enabled,
    required this.onEnableLock,
    required this.onDisableLock,
    required this.onChangeLockPassword,
  });

  final bool enabled;
  final Future<String?> Function(String password) onEnableLock;
  final Future<String?> Function(String currentPassword) onDisableLock;
  final Future<String?> Function({
    required String currentPassword,
    required String newPassword,
  }) onChangeLockPassword;

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
            enabled ? Icons.lock_outline : Icons.lock_open_outlined,
            size: 22,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '잠금',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Chip(
                  label: Text(enabled ? '켜짐' : '꺼짐'),
                  visualDensity: VisualDensity.compact,
                ),
                if (enabled) ...<Widget>[
                  OutlinedButton(
                    onPressed: () => _openChangePasswordDialog(context),
                    child: const Text('비밀번호 변경'),
                  ),
                  OutlinedButton(
                    onPressed: () => _openDisableDialog(context),
                    child: const Text('잠금 끄기'),
                  ),
                ] else
                  FilledButton(
                    onPressed: () => _openEnableDialog(context),
                    child: const Text('잠금 켜기'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEnableDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return _LockPasswordDialog(
          title: '잠금 켜기',
          primaryActionLabel: '완료',
          requireCurrentPassword: false,
          requireNewPassword: true,
          onSubmit: ({
            required currentPassword,
            required newPassword,
          }) {
            return onEnableLock(newPassword);
          },
        );
      },
    );
  }

  Future<void> _openDisableDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return _LockPasswordDialog(
          title: '잠금 끄기',
          primaryActionLabel: '끄기',
          requireCurrentPassword: true,
          requireNewPassword: false,
          onSubmit: ({
            required currentPassword,
            required newPassword,
          }) {
            return onDisableLock(currentPassword);
          },
        );
      },
    );
  }

  Future<void> _openChangePasswordDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return _LockPasswordDialog(
          title: '비밀번호 변경',
          primaryActionLabel: '변경',
          requireCurrentPassword: true,
          requireNewPassword: true,
          onSubmit: ({
            required currentPassword,
            required newPassword,
          }) {
            return onChangeLockPassword(
              currentPassword: currentPassword,
              newPassword: newPassword,
            );
          },
        );
      },
    );
  }
}

class _LockPasswordDialog extends StatefulWidget {
  const _LockPasswordDialog({
    required this.title,
    required this.primaryActionLabel,
    required this.requireCurrentPassword,
    required this.requireNewPassword,
    required this.onSubmit,
  });

  final String title;
  final String primaryActionLabel;
  final bool requireCurrentPassword;
  final bool requireNewPassword;
  final Future<String?> Function({
    required String currentPassword,
    required String newPassword,
  }) onSubmit;

  @override
  State<_LockPasswordDialog> createState() => _LockPasswordDialogState();
}

class _LockPasswordDialogState extends State<_LockPasswordDialog> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isBusy = false;
  bool _obscure = true;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.requireCurrentPassword) ...<Widget>[
              _buildPasswordField(
                controller: _currentController,
                label: '현재 비밀번호',
              ),
              const SizedBox(height: 10),
            ],
            if (widget.requireNewPassword) ...<Widget>[
              _buildPasswordField(
                controller: _newController,
                label: '새 비밀번호',
              ),
              const SizedBox(height: 10),
              _buildPasswordField(
                controller: _confirmController,
                label: '새 비밀번호 확인',
                textInputAction: TextInputAction.done,
              ),
            ],
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isBusy ? null : _submit,
          child: _isBusy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.primaryActionLabel),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      obscureText: _obscure,
      enabled: !_isBusy,
      textInputAction: textInputAction,
      onSubmitted: (_) {
        if (textInputAction == TextInputAction.done) {
          _submit();
        }
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          tooltip: _obscure ? '비밀번호 보기' : '비밀번호 숨기기',
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isBusy) {
      return;
    }
    final currentPassword = _currentController.text;
    final newPassword = _newController.text;
    final confirmPassword = _confirmController.text;

    if (widget.requireCurrentPassword && currentPassword.isEmpty) {
      setState(() {
        _errorMessage = '현재 비밀번호를 입력해 주세요';
      });
      return;
    }
    if (widget.requireNewPassword && newPassword.isEmpty) {
      setState(() {
        _errorMessage = '새 비밀번호를 입력해 주세요';
      });
      return;
    }
    if (widget.requireNewPassword && newPassword != confirmPassword) {
      setState(() {
        _errorMessage = '새 비밀번호가 서로 다릅니다';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    final message = await widget.onSubmit(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (!mounted) {
      return;
    }
    if (message != null) {
      setState(() {
        _isBusy = false;
        _errorMessage = message;
      });
      return;
    }
    Navigator.of(context).pop();
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
