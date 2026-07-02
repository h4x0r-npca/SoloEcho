import 'dart:async';

import 'package:flutter/material.dart';

import 'models/app_theme_mode.dart';
import 'models/font_scale_step.dart';
import 'models/solo_echo_account.dart';
import 'models/timeline_entry.dart';
import 'models/workspace_info.dart';
import 'models/writing_mode.dart';
import 'services/auth_service.dart';
import 'services/solo_echo_repository.dart';
import 'services/timeline_sheet_service.dart';
import 'services/user_settings_service.dart';
import 'ui/app_theme.dart';
import 'ui/home_scaffold.dart';
import 'ui/login_screen.dart';
import 'ui/lock_screen.dart';
import 'utils/friendly_error.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SoloEchoApp());
}

class SoloEchoApp extends StatefulWidget {
  const SoloEchoApp({super.key});

  @override
  State<SoloEchoApp> createState() => _SoloEchoAppState();
}

class _SoloEchoAppState extends State<SoloEchoApp> with WidgetsBindingObserver {
  static const _autoRefreshInterval = Duration(seconds: 20);
  static const _homeTransitionDuration = Duration(milliseconds: 700);

  final AuthService _authService = AuthService();
  final UserSettingsService _settingsService = UserSettingsService();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  SoloEchoAccount? _account;
  WorkspaceInfo? _workspace;
  TimelineSheetService? _timelineService;
  List<TimelineEntry> _entries = <TimelineEntry>[];
  WritingMode _writingMode = WritingMode.chat;
  AppThemeMode _themeMode = AppThemeMode.dark;
  FontScaleStep _fontScaleStep = FontScaleStep.defaultValue;
  bool _motionEffectsEnabled = true;
  DateTime? _lastSync;
  String? _errorMessage;
  bool _isLockEnabled = false;
  bool _isLocked = false;
  bool _isBootstrapping = true;
  bool _isSigningIn = false;
  bool _isLoadingTimeline = false;
  bool _isSaving = false;
  bool _isAutoRefreshing = false;
  bool _isAppInForeground = true;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoRefreshTimer();
    _authService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasInForeground = _isAppInForeground;
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (!wasInForeground && _isAppInForeground) {
      if (_isLockEnabled && _account != null) {
        _lockApp();
        return;
      }
      _startAutoRefreshTimer();
      unawaited(_refreshTimelineSilently());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoloEcho',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: SoloEchoTheme.lightTheme,
      darkTheme: SoloEchoTheme.darkTheme,
      themeMode: switch (_themeMode) {
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.light => ThemeMode.light,
      },
      builder: (context, child) {
        final colors = SoloEchoColors.of(context);
        return ColoredBox(
          color: colors.background,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AnimatedSwitcher(
        duration:
            _motionEffectsEnabled ? _homeTransitionDuration : Duration.zero,
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<String>(_homeStateKey),
          child: _buildHome(),
        ),
      ),
    );
  }

  String get _homeStateKey {
    if (_isBootstrapping) {
      return 'bootstrapping';
    }
    if (_account != null && _isLocked) {
      return 'locked';
    }
    if (_account == null || _workspace == null) {
      return 'login';
    }
    return 'home';
  }

  Widget _buildHome() {
    if (_isBootstrapping) {
      final colors = SoloEchoColors.of(context);
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final account = _account;
    final workspace = _workspace;
    if (account != null && _isLocked) {
      return LockScreen(
        onUnlock: _unlockWithPassword,
        onUnlockComplete: _finishUnlockTransition,
        onResetLock: _resetLockFromLockScreen,
      );
    }

    if (account == null || workspace == null) {
      return LoginScreen(
        isBusy: _isSigningIn,
        errorMessage: _errorMessage,
        onSignIn: _signIn,
      );
    }

    return HomeScaffold(
      account: account,
      workspace: workspace,
      entries: _entries,
      writingMode: _writingMode,
      themeMode: _themeMode,
      fontScaleStep: _fontScaleStep,
      motionEffectsEnabled: _motionEffectsEnabled,
      lockEnabled: _isLockEnabled,
      isLoadingTimeline: _isLoadingTimeline,
      isSaving: _isSaving,
      lastSync: _lastSync,
      onRefresh: _refreshTimeline,
      onSave: _saveEntry,
      onWritingModeChanged: _changeWritingMode,
      onThemeModeChanged: _changeThemeMode,
      onFontScaleStepChanged: _changeFontScaleStep,
      onMotionEffectsChanged: _changeMotionEffects,
      onEnableLock: _enableLock,
      onDisableLock: _disableLock,
      onChangeLockPassword: _changeLockPassword,
      onSignOut: _signOut,
    );
  }

  Future<void> _bootstrap() async {
    try {
      final writingMode = await _settingsService.readWritingMode();
      final themeMode = await _settingsService.readThemeMode();
      final fontScaleStep = await _settingsService.readFontScaleStep();
      final motionEffectsEnabled =
          await _settingsService.readMotionEffectsEnabled();
      final lockSettings = await _settingsService.readLockSettings();
      if (mounted) {
        setState(() {
          _writingMode = writingMode;
          _themeMode = themeMode;
          _fontScaleStep = fontScaleStep;
          _motionEffectsEnabled = motionEffectsEnabled;
          _isLockEnabled = lockSettings.isEnabled;
        });
      }
      final account = await _authService.restoreSession();
      if (account == null) {
        setState(() {
          _isBootstrapping = false;
        });
        return;
      }
      if (lockSettings.isEnabled) {
        setState(() {
          _account = account;
          _isLocked = true;
        });
        return;
      }
      await _openWorkspace(account);
    } catch (error) {
      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrapping = false;
        });
      }
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });
    try {
      final account = await _authService.signIn();
      await _openWorkspace(account);
    } on AuthCancelledException {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
      _showSnackBar('로그인이 취소되었습니다');
    } catch (error) {
      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _openWorkspace(SoloEchoAccount account) async {
    setState(() {
      _account = account;
      _isLoadingTimeline = true;
    });
    final repository =
        SoloEchoRepository(client: _authService.authorizedClient);
    final workspace = await repository.ensureWorkspace();
    final timelineService = TimelineSheetService(
      client: _authService.authorizedClient,
      spreadsheetId: workspace.spreadsheetId,
    );
    final entries = await timelineService.readEntriesNewestFirst();
    setState(() {
      _workspace = workspace;
      _timelineService = timelineService;
      _entries = entries;
      _lastSync = DateTime.now();
      _isLoadingTimeline = false;
      _errorMessage = null;
    });
    if (!_isLocked) {
      _startAutoRefreshTimer();
    }
  }

  Future<void> _refreshTimeline() async {
    final timelineService = _timelineService;
    if (timelineService == null) {
      return;
    }
    setState(() {
      _isLoadingTimeline = true;
      _errorMessage = null;
    });
    try {
      final entries = await _runWithAuthRecovery(() {
        final currentTimelineService = _timelineService;
        if (currentTimelineService == null) {
          throw StateError('Timeline is not ready.');
        }
        return currentTimelineService.readEntriesNewestFirst();
      });
      setState(() {
        _entries = entries;
        _lastSync = DateTime.now();
      });
    } on AuthExpiredException {
      // _expireSession already reset state and informed the user.
    } catch (error) {
      setState(() {
        _errorMessage = _friendlyError(error);
      });
      _showSnackBar(_errorMessage!);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTimeline = false;
        });
      }
    }
  }

  Future<void> _changeWritingMode(WritingMode mode) async {
    if (mode == _writingMode) {
      return;
    }
    final previous = _writingMode;
    setState(() {
      _writingMode = mode;
    });
    try {
      await _settingsService.writeWritingMode(mode);
    } catch (error) {
      final message = _friendlyError(error);
      if (mounted) {
        setState(() {
          _writingMode = previous;
          _errorMessage = message;
        });
      }
      _showSnackBar(message);
    }
  }

  Future<void> _changeThemeMode(AppThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    final previous = _themeMode;
    setState(() {
      _themeMode = mode;
    });
    try {
      await _settingsService.writeThemeMode(mode);
    } catch (error) {
      final message = _friendlyError(error);
      if (mounted) {
        setState(() {
          _themeMode = previous;
          _errorMessage = message;
        });
      }
      _showSnackBar(message);
    }
  }

  Future<void> _changeFontScaleStep(FontScaleStep step) async {
    if (step == _fontScaleStep) {
      return;
    }
    final previous = _fontScaleStep;
    setState(() {
      _fontScaleStep = step;
    });
    try {
      await _settingsService.writeFontScaleStep(step);
    } catch (error) {
      final message = _friendlyError(error);
      if (mounted) {
        setState(() {
          _fontScaleStep = previous;
          _errorMessage = message;
        });
      }
      _showSnackBar(message);
    }
  }

  Future<void> _changeMotionEffects(bool enabled) async {
    if (enabled == _motionEffectsEnabled) {
      return;
    }
    final previous = _motionEffectsEnabled;
    setState(() {
      _motionEffectsEnabled = enabled;
    });
    try {
      await _settingsService.writeMotionEffectsEnabled(enabled);
    } catch (error) {
      final message = _friendlyError(error);
      if (mounted) {
        setState(() {
          _motionEffectsEnabled = previous;
          _errorMessage = message;
        });
      }
      _showSnackBar(message);
    }
  }

  Future<String?> _enableLock(String password) async {
    try {
      await _settingsService.writeLockPassword(password);
      if (mounted) {
        setState(() {
          _isLockEnabled = true;
        });
      }
      return null;
    } catch (error) {
      return _friendlyError(error);
    }
  }

  Future<String?> _disableLock(String currentPassword) async {
    if (!await _settingsService.verifyLockPassword(currentPassword)) {
      return '현재 비밀번호가 맞지 않습니다';
    }
    try {
      await _settingsService.clearLock();
      if (mounted) {
        setState(() {
          _isLockEnabled = false;
          _isLocked = false;
        });
      }
      return null;
    } catch (error) {
      return _friendlyError(error);
    }
  }

  Future<String?> _changeLockPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!await _settingsService.verifyLockPassword(currentPassword)) {
      return '현재 비밀번호가 맞지 않습니다';
    }
    try {
      await _settingsService.writeLockPassword(newPassword);
      if (mounted) {
        setState(() {
          _isLockEnabled = true;
        });
      }
      return null;
    } catch (error) {
      return _friendlyError(error);
    }
  }

  Future<void> _saveEntry(String content, DateTime timestamp) async {
    final timelineService = _timelineService;
    if (timelineService == null || content.trim().isEmpty) {
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final entry = await _runWithAuthRecovery(() {
        final currentTimelineService = _timelineService;
        if (currentTimelineService == null) {
          throw StateError('Timeline is not ready.');
        }
        return currentTimelineService.appendEntry(
          content,
          timestamp: timestamp,
        );
      });
      setState(() {
        _entries = <TimelineEntry>[entry, ..._entries];
        _lastSync = DateTime.now();
      });
      _showSnackBar('저장되었습니다');
    } on AuthExpiredException {
      rethrow;
    } catch (error) {
      setState(() {
        _errorMessage = _friendlyError(error);
      });
      _showSnackBar(_errorMessage!);
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    _stopAutoRefreshTimer();
    final repository =
        SoloEchoRepository(client: _authService.authorizedClient);
    await repository.clear();
    await _authService.signOut();
    setState(() {
      _account = null;
      _workspace = null;
      _timelineService = null;
      _entries = <TimelineEntry>[];
      _lastSync = null;
      _errorMessage = null;
      _isLocked = false;
    });
  }

  Future<String?> _unlockWithPassword(String password) async {
    final verified = await _settingsService.verifyLockPassword(password);
    if (!verified) {
      return '비밀번호가 맞지 않습니다';
    }

    final account = _account ?? _authService.account;
    if (account == null) {
      return null;
    }

    if (_workspace != null && _timelineService != null) {
      return null;
    }

    try {
      await _openWorkspace(account);
      return null;
    } catch (error) {
      final message = _friendlyError(error);
      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
      return message;
    }
  }

  void _finishUnlockTransition() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLocked = false;
    });
    if (_workspace != null && _timelineService != null) {
      _startAutoRefreshTimer();
      unawaited(_refreshTimelineSilently());
    }
  }

  Future<void> _resetLockFromLockScreen() async {
    _stopAutoRefreshTimer();
    await _settingsService.clearLock();
    try {
      await _authService.signOut();
    } catch (_) {
      // The reset flow should still return the user to Google sign-in.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _account = null;
      _workspace = null;
      _timelineService = null;
      _entries = <TimelineEntry>[];
      _lastSync = null;
      _errorMessage = null;
      _isLockEnabled = false;
      _isLocked = false;
      _isLoadingTimeline = false;
      _isSaving = false;
    });
    _showSnackBar('잠금 설정이 재설정되었습니다. 다시 로그인해 주세요');
  }

  void _lockApp() {
    if (!_isLockEnabled || _account == null || _isLocked) {
      return;
    }
    _stopAutoRefreshTimer();
    setState(() {
      _isLocked = true;
      _isLoadingTimeline = false;
    });
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    if (_timelineService == null) {
      return;
    }
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      unawaited(_refreshTimelineSilently());
    });
  }

  void _stopAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _isAutoRefreshing = false;
  }

  Future<void> _refreshTimelineSilently() async {
    final spreadsheetId = _workspace?.spreadsheetId;
    if (!_isAppInForeground ||
        _isLocked ||
        spreadsheetId == null ||
        _timelineService == null ||
        _isLoadingTimeline ||
        _isSaving ||
        _isAutoRefreshing) {
      return;
    }

    _isAutoRefreshing = true;
    try {
      final entries = await _runWithAuthRecovery(() {
        final currentTimelineService = _timelineService;
        if (currentTimelineService == null) {
          throw StateError('Timeline is not ready.');
        }
        return currentTimelineService.readEntriesNewestFirst();
      });
      if (!mounted || _workspace?.spreadsheetId != spreadsheetId) {
        return;
      }
      setState(() {
        _entries = entries;
        _lastSync = DateTime.now();
      });
    } on AuthExpiredException {
      // _expireSession already reset state and informed the user.
    } catch (_) {
      // Automatic refresh should stay quiet for transient network/API errors.
    } finally {
      _isAutoRefreshing = false;
    }
  }

  void _showSnackBar(String message) {
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<T> _runWithAuthRecovery<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (error) {
      if (!AuthService.isRecoverableAuthError(error)) {
        rethrow;
      }
      final recovered = await _refreshAuthorization();
      if (!recovered) {
        await _expireSession();
        throw const AuthExpiredException();
      }
    }

    try {
      return await request();
    } catch (error) {
      if (AuthService.isRecoverableAuthError(error)) {
        await _expireSession();
        throw const AuthExpiredException();
      }
      rethrow;
    }
  }

  Future<bool> _refreshAuthorization() async {
    final workspace = _workspace;
    if (workspace == null) {
      return false;
    }

    final refreshed = await _authService.refreshAuthorization();
    if (!refreshed || !mounted) {
      return false;
    }

    setState(() {
      _account = _authService.account ?? _account;
      _timelineService = TimelineSheetService(
        client: _authService.authorizedClient,
        spreadsheetId: workspace.spreadsheetId,
      );
    });
    return true;
  }

  Future<void> _expireSession() async {
    _stopAutoRefreshTimer();
    try {
      await _authService.signOut();
    } catch (_) {
      // The session is already unusable; local state still needs to reset.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _account = null;
      _workspace = null;
      _timelineService = null;
      _entries = <TimelineEntry>[];
      _lastSync = null;
      _errorMessage = null;
      _isLoadingTimeline = false;
      _isSaving = false;
      _isLocked = false;
    });
    _showSnackBar('세션이 만료되었습니다. 다시 로그인해 주세요');
  }

  String _friendlyError(Object error) {
    return friendlyErrorMessage(error);
  }
}
