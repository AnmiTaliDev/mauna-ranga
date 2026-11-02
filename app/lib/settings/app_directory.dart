import 'dart:io';

String appDataDirectory() {
  final Map<String, String> env = Platform.environment;
  final String base;
  if (Platform.isWindows) {
    base = env['APPDATA'] ?? '.';
  } else if (Platform.isMacOS) {
    base = '${env['HOME']}/Library/Application Support';
  } else {
    base = env['XDG_CONFIG_HOME'] ?? '${env['HOME']}/.config';
  }
  return '$base/mauna-ranga';
}
