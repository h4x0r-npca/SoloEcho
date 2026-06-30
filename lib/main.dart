import 'dart:async';

import 'package:flutter/material.dart';

import 'models/solo_echo_account.dart';
import 'models/timeline_entry.dart';
import 'models/workspace_info.dart';
import 'models/writing_mode.dart';
import 'services/auth_service.dart';
import 'services/solo_echo_repository.dart';
import 'services/timeline_sheet_service.dart';
import 'services/user_settings_service.dart';
import 'ui/home_scaffold.dart';
import 'ui/login_screen.dart';

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

  final AuthService _authService = AuthService();
  final UserSettingsService _settingsService = UserSettingsService();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  SoloEchoAccount? _account;
  WorkspaceInfo? _workspace;
  TimelineSheetService? _timelineService;
  List<TimelineEntry> _entries = <TimelineEntry>[];
  WritingMode _writingMode = WritingMode.chat;
  DateTime? _lastSync;
  String? _errorMessage;
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
      theme: _buildTheme(),
      home: _buildHome(),
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6ED6A0),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Pretendard',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF101112),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF101112),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF161819),
        indicatorColor: colorScheme.primaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildHome() {
    if (_isBootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final account = _account;
    final workspace = _workspace;
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
      isLoadingTimeline: _isLoadingTimeline,
      isSaving: _isSaving,
      lastSync: _lastSync,
      onRefresh: _refreshTimeline,
      onSave: _saveEntry,
      onWritingModeChanged: _changeWritingMode,
      onSignOut: _signOut,
    );
  }

  Future<void> _bootstrap() async {
    try {
      final writingMode = await _settingsService.readWritingMode();
      if (mounted) {
        setState(() {
          _writingMode = writingMode;
        });
      }
      final account = await _authService.restoreSession();
      if (account == null) {
        setState(() {
          _isBootstrapping = false;
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
    _startAutoRefreshTimer();
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
    });
    _showSnackBar('세션이 만료되었습니다. 다시 로그인해 주세요');
  }

  String _friendlyError(Object error) {
    if (error is AuthCancelledException) {
      return '로그인이 취소되었습니다';
    }
    if (error is AuthExpiredException ||
        AuthService.isRecoverableAuthError(error)) {
      return '세션이 만료되었습니다. 다시 로그인해 주세요';
    }

    final text = error.toString();
    if (text.contains('Google sign-in was cancelled')) {
      return '로그인이 취소되었습니다';
    }
    if (text.contains('Google API authorization is required')) {
      return 'Google Drive 접근 권한이 필요합니다. 다시 로그인해 주세요';
    }
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Network is unreachable')) {
      return '네트워크 연결을 확인해 주세요';
    }
    if (text.contains('timed out')) {
      return '로그인 시간이 초과되었습니다';
    }
    return text
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '');
  }
}
