import 'package:flutter/material.dart';

import 'login_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.onUnlock,
    required this.onUnlockComplete,
    required this.onResetLock,
  });

  final Future<String?> Function(String password) onUnlock;
  final VoidCallback onUnlockComplete;
  final Future<void> Function() onResetLock;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _isBusy = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      children: <Widget>[
        TextField(
          controller: _controller,
          autofocus: true,
          obscureText: _obscurePassword,
          enabled: !_isBusy,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            hintText: '비밀번호 입력',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isBusy ? null : _submit,
          icon: _isBusy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_open_outlined),
          label: Text(_isBusy ? '확인 중' : '잠금 해제'),
        ),
        TextButton(
          onPressed: _isBusy ? null : _confirmResetLock,
          child: const Text('비밀번호 재설정'),
        ),
        if (_errorMessage != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _submit() async {
    if (_isBusy) {
      return;
    }
    final password = _controller.text;
    if (password.isEmpty) {
      setState(() {
        _errorMessage = '비밀번호를 입력해 주세요';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    final message = await widget.onUnlock(password);
    if (!mounted) {
      return;
    }
    if (message == null) {
      widget.onUnlockComplete();
      return;
    }
    setState(() {
      _isBusy = false;
      _errorMessage = message;
    });
  }

  Future<void> _confirmResetLock() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 재설정'),
          content: const Text(
            '현재 Google 세션에서 로그아웃하고 이 기기의 잠금 설정을 삭제합니다. Google Drive 기록은 삭제되지 않습니다.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('재설정'),
            ),
          ],
        );
      },
    );
    if (shouldReset != true) {
      return;
    }
    await widget.onResetLock();
  }
}
