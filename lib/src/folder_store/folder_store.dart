import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unpub/unpub.dart';
import 'package:unpub/unpub.dart' as unpub;

PackageStore folderPackageStore() {
  final env = Platform.environment;
  var baseDir = path.absolute(env['UNPUBDEV_FOLDER'] ?? 'unpubdev-packages');
  return unpub.FileStore(baseDir);
}
