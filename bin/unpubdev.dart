import 'dart:io';

import 'package:args/args.dart';
import 'package:eit_unpubdev/src/minio_credentials.dart';
import 'package:eit_unpubdev/src/minio_file_store.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub/unpub.dart' as unpub;

main(List<String> args) async {
  var parser = ArgParser();
  parser.addOption('host', abbr: 'h', defaultsTo: '0.0.0.0');
  parser.addOption('port', abbr: 'p', defaultsTo: '4000');
  parser.addOption('database',
      abbr: 'd', defaultsTo: 'mongodb://localhost:27017/dart_pub');
  parser.addOption('proxy-origin', abbr: 'o', defaultsTo: '');

  var results = parser.parse(args);

  final env = Platform.environment;

  var host = env['UNPUBDEV_HOST'] ?? results['host'] as String;
  var port = int.parse(env['UNPUBDEV_PORT'] ?? results['port'] as String);
  var dbUri = results['database'] as String;
  var proxyOrigin = results['proxy-origin'] as String;

  if (results.rest.isNotEmpty) {
    print('Got unexpected arguments: "${results.rest.join(' ')}".\n\nUsage:\n');
    print(parser.usage);
    exit(1);
  }

  final db = Db(dbUri);
  await db.open(); // make sure the MongoDB connection opened

  final app = unpub.App(
    proxy_origin: proxyOrigin.trim().isEmpty ? null : Uri.parse(proxyOrigin),
    metaStore: unpub.MongoStore(db),
    packageStore: MinioStore(
      env['MINIO_BUCKET_NAME'] ?? 'unpubdev',
      region: env['MINIO_DEFAULT_REGION'] ?? 'us-east-1',
      endpoint: host,
      getObjectPath: (String name, String version) =>
          '$name/$name-$version.tar.gz',
      credentials: MinioCredentials(
        accessKey: env['MINIO_ROOT_USER'] ?? 'minioadmin',
        secretKey: env['MINIO_ROOT_PASSWORD'] ?? 'minioadmin',
      ),
    ),
    uploadValidator: (pubspec, uploaderEmail) {
      if (env['UNPUBDEV_PACKAGE_PREFIX'] != null) {
        var prefix = env['UNPUBDEV_PACKAGE_PREFIX'] ?? 'company_';
        var name = pubspec['name'] as String;
        if (!name.startsWith(prefix)) {
          throw 'Package name should starts with $prefix';
        }
      }
      if (env['UNPUBDEV_EMAIL_DOMAIN'] != null) {
        final envEmails = env['UNPUBDEV_EMAIL_DOMAIN'] ?? 'gmail.com';
        final emails = envEmails.split(',').map((e) => e.trim()).toList();
        if (!emails.any((element) => uploaderEmail.endsWith(element))) {
          throw 'Uploader email invalid';
        }
      }

      return Future.value();
    },
  );

  var server = await app.serve(host, port);
  print('Serving at http://${server.address.host}:${server.port}');
}
