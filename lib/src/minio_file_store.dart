// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:cli';
import 'dart:io';
import 'dart:typed_data';

import 'package:minio_new/minio.dart';
import 'package:unpub/unpub.dart';

import 'minio_credentials.dart';

/// Use an AWS S3 Bucket as a package store
class MinioStore extends PackageStore {
  String Function(String name, String version)? getObjectPath;

  String bucketName;
  String? region;
  String? endpoint;
  MinioCredentials? credentials;
  Minio? minio;
  Map<String, String>? environment;

  MinioStore(this.bucketName,
      {this.region,
      this.getObjectPath,
      this.endpoint,
      this.credentials,
      this.minio,
      this.environment}) {
    final env = environment ?? Platform.environment;

    // Check for env vars or container credentials if none were provided.
    credentials ??= MinioCredentials(environment: env);

    // Use a supplied minio instance or create a default
    minio ??= Minio(
      endPoint: endpoint ?? env['MINIO_ENDPOINT'] ?? 'play.min.io',
      region: region ?? env['MINIO_DEFAULT_REGION'],
      accessKey: credentials!.accessKey ?? '',
      secretKey: credentials!.secretKey ?? '',
    );

    // Check for a region or default region which is required
    if (region == null &&
        (env['MINIO_DEFAULT_REGION'] == null ||
            env['MINIO_DEFAULT_REGION']!.isEmpty)) {
      throw ArgumentError('Could not determine a default region for aws.');
    }
  }

  String _getObjectKey(String name, String version) {
    return getObjectPath?.call(name, version) ?? '$name/$name-$version.tar.gz';
  }

  @override
  Future<void> upload(String name, String version, List<int> content) async {
    await minio!.putObject(bucketName, _getObjectKey(name, version),
        Stream.value(Uint8List.fromList(content)));
  }

  @override
  Stream<List<int>> download(String name, String version) {
    return waitFor(minio!.getObject(bucketName, _getObjectKey(name, version)));
  }
}
