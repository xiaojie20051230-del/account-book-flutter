import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class PasscodeProvider extends ChangeNotifier {
  Box? _settingsBox;
  String? _storedHash;
  bool _isLocked = false;
  int _pinLength = 4;

  bool get hasPasscode => _storedHash != null;
  bool get isLocked => _isLocked;
  bool get shouldLock => hasPasscode;
  int get pinLength => _pinLength;

  void init(Box settingsBox) {
    _settingsBox = settingsBox;
    _storedHash = _settingsBox!.get('passcode_hash');
    _pinLength = _settingsBox!.get('passcode_length', defaultValue: 4) as int;
  }

  /// 设置密码
  bool setPasscode(String passcode) {
    if (passcode.length < 4 || passcode.length > 6) return false;
    if (!RegExp(r'^\d+$').hasMatch(passcode)) return false;

    _pinLength = passcode.length;
    final hash = _hash(passcode);
    _storedHash = hash;
    _settingsBox?.put('passcode_hash', hash);
    _settingsBox?.put('passcode_length', _pinLength);
    notifyListeners();
    return true;
  }

  /// 验证密码
  bool verify(String passcode) {
    if (_storedHash == null) return true;
    return _hash(passcode) == _storedHash;
  }

  /// 移除密码（需先验证）
  bool remove(String passcode) {
    if (!verify(passcode)) return false;
    _storedHash = null;
    _pinLength = 4;
    _settingsBox?.delete('passcode_hash');
    _settingsBox?.delete('passcode_length');
    _isLocked = false;
    notifyListeners();
    return true;
  }

  void lock() {
    if (shouldLock) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlock() {
    _isLocked = false;
    notifyListeners();
  }

  String _hash(String passcode) {
    final bytes = utf8.encode(passcode);
    return sha256.convert(bytes).toString();
  }
}
