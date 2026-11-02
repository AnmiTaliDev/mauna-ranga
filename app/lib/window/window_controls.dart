import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('mauna_ranga/window');

enum ResizeEdge {
  northWest,
  north,
  northEast,
  west,
  east,
  southWest,
  south,
  southEast,
}

abstract final class WindowControls {
  static bool get available => Platform.isLinux;

  static void startMove() => _call('startMove');

  static void startResize(ResizeEdge edge) => _call('startResize', edge.index);

  static void minimize() => _call('minimize');

  static void toggleMaximize() => _call('toggleMaximize');

  static void close() => _call('close');

  static void forceClose() => _call('forceClose');

  static void onCloseRequested(Future<void> Function() handler) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'closeRequested') {
        await handler();
      }
    });
  }

  static void stopListening() => _channel.setMethodCallHandler(null);

  static void setTitle(String title) => _call('setTitle', title);

  static void _call(String method, [Object? argument]) {
    unawaited(_invoke(method, argument));
  }

  static Future<void> _invoke(String method, Object? argument) async {
    try {
      await _channel.invokeMethod<void>(method, argument);
    } on MissingPluginException {
      return;
    }
  }
}
