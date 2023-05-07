import 'dart:io';

import 'package:eit_unpubdev/unpubdev.dart';
import 'package:unpub/unpub.dart';

PackageStore getPackageStore(String host) {
  final env = Platform.environment;
  final storage = env['UNPUBDEV_STORAGE'] ?? 'folder';
  if (storage == 'minio') {
    return minioPackageStore(host);
  }

  return folderPackageStore();
}
