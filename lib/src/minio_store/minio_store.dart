// ignore_for_file: deprecated_member_use

import 'dart:cli';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:minio_new/minio.dart';
import 'package:path/path.dart' as path;
import 'package:unpub/unpub.dart';

part 'minio_credentials.dart';
part 'minio_file_store.dart';

PackageStore minioPackageStore() {
  final env = Platform.environment;
  final host = env['UNPUBDEV_HOST'] ?? '0.0.0.0';
  final storage = env['UNPUBDEV_STORAGE'] ?? 'folder';
  if (storage == 'minio') {
    return MinioStore(
      env['MINIO_BUCKET_NAME'] ?? 'unpubdev',
      region: env['MINIO_DEFAULT_REGION'] ?? 'us-east-1',
      endpoint: host,
      getObjectPath: (String name, String version) =>
          '$name/$name-$version.tar.gz',
      credentials: MinioCredentials(
        accessKey: env['MINIO_ROOT_USER'] ?? 'minioadmin',
        secretKey: env['MINIO_ROOT_PASSWORD'] ?? 'minioadmin',
      ),
    );
  }

  var baseDir = path.absolute(env['UNPUBDEV_FOLDER'] ?? 'unpubdev-packages');
  return FileStore(baseDir);
}
