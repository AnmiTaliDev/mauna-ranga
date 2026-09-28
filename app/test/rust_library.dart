import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:mauna_ranga/bridge/generated/frb_generated.dart';

const String rustLibraryPath = '../mauna-ranga/target/debug/libranga_ffi.so';

Future<void> initRustLibrary() {
  return RustLib.init(externalLibrary: ExternalLibrary.open(rustLibraryPath));
}
