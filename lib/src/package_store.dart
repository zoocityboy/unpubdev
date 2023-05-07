import 'dart:io';

import 'package:unpub/unpub.dart';

import 'folder_store/folder_store.dart';
import 'minio_store/minio_store.dart';

PackageStore getPackageStore(String host) {
  final env = Platform.environment;
  final storage = env['UNPUBDEV_STORAGE'] ?? 'folder';
  if (storage == 'minio') {
    return minioPackageStore(host);
  }

  return folderPackageStore();
}
