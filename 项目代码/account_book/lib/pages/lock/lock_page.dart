import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/passcode_provider.dart';

class LockPage extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const LockPage({super.key, this.onUnlocked});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  String _input = '';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passcode = context.watch<PasscodeProvider>();
    final pinLen = passcode.pinLength;

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            Text('请输入密码', style: theme.textTheme.titleLarge),
            const SizedBox(height: 32),

            // PIN dots - dynamic count from passcode length
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pinLen, (i) {
                final filled = i < _input.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: filled ? null : Center(
                    child: Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.onSurfaceVariant.withAlpha(80)),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text('请输入密码', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),

            const SizedBox(height: 32),

            // Number pad
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: List.generate(3, (col) {
                  final n = row * 3 + col + 1;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _NumberButton(
                        label: '$n',
                        onTap: () => _onDigit(n.toString()),
                      ),
                    ),
                  );
                }),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _NumberButton(
                      label: '0',
                      onTap: () => _onDigit('0'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _NumberButton(
                      label: '⌫',
                      onTap: () => setState(() {
                        if (_input.isNotEmpty) {
                          _input = _input.substring(0, _input.length - 1);
                          _error = null;
                        }
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDigit(String digit) {
    final pinLen = context.read<PasscodeProvider>().pinLength;
    if (_input.length >= pinLen) return;
    setState(() {
      _input += digit;
      _error = null;
    });

    if (_input.length >= pinLen) {
      _checkPasscode();
    }
  }

  void _checkPasscode() {
    final provider = context.read<PasscodeProvider>();
    if (provider.verify(_input)) {
      provider.unlock();
      widget.onUnlocked?.call();
    } else {
      setState(() {
        _error = '密码错误';
        _input = '';
      });
    }
  }
}

class _NumberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NumberButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
