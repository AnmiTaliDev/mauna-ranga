import 'package:flutter/foundation.dart';

class FocusModeController extends ChangeNotifier {
  bool _focusMode = false;
  bool _sidebarOpen = true;
  bool _writing = false;

  bool get focusMode => _focusMode;

  bool get sidebarOpen => _sidebarOpen;

  bool get sidebarCollapsed => _focusMode || !_sidebarOpen;

  bool get writing => _writing;

  void toggleFocusMode() {
    _focusMode = !_focusMode;
    notifyListeners();
  }

  void exitFocusMode() {
    if (_focusMode) {
      toggleFocusMode();
    }
  }

  void toggleSidebar() {
    _sidebarOpen = !_sidebarOpen;
    notifyListeners();
  }

  void startWriting() {
    if (!_writing) {
      _writing = true;
      notifyListeners();
    }
  }

  void stopWriting() {
    if (_writing) {
      _writing = false;
      notifyListeners();
    }
  }
}
