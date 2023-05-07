import 'dart:io';

import 'package:eit_unpubdev/unpubdev.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub/unpub.dart' as unpub;

main(List<String> args) async {
  final env = Platform.environment;

  final host = env['UNPUBDEV_HOST'] ?? '0.0.0.0';
  final port = int.parse(env['UNPUBDEV_PORT'] ?? '4000');
  final proxyOrigin = env['UNPUBDEV_PROXY_ORIGIN'] ?? '';
  final db = env['UNPUBDEV_MONGO_STRING'] ?? '';
  if (db.isEmpty) {
    print('Missing env[\'UNPUBDEV_MONGO_STRING\']');
    exit(1);
  }
  final database = Db(db);
  try {
    await database.open(); // make sure the MongoDB connection opened
  } catch (e) {
    print(Error.safeToString(e));
    rethrow;
  }

  final app = unpub.App(
    proxy_origin: proxyOrigin.trim().isEmpty ? null : Uri.parse(proxyOrigin),
    metaStore: unpub.MongoStore(database),
    packageStore: getPackageStore(host),
    uploadValidator: (pubspec, uploaderEmail) {
      final prefix = (env['UNPUBDEV_PACKAGE_PREFIX'] ?? '').trim();
      if (prefix.isNotEmpty) {
        var envPrefix = env['UNPUBDEV_PACKAGE_PREFIX'] ?? '';
        final prefixes = envPrefix.split(',').map((e) => e.trim()).toList();
        var packageName = pubspec['name'] as String;
        if (!prefixes.any((element) => packageName.startsWith(element))) {
          throw 'Package name should starts with $prefix';
        }
      }
      final domains = (env['UNPUBDEV_EMAIL_DOMAIN'] ?? '').trim();
      if (domains.isNotEmpty) {
        final envEmails = env['UNPUBDEV_EMAIL_DOMAIN'] ?? 'gmail.com';
        final emails = envEmails.split(',').map((e) => e.trim()).toList();
        if (!emails.any((element) => uploaderEmail.endsWith(element))) {
          throw 'Uploader email $uploaderEmail invalid';
        }
      }

      return Future<void>.value();
    },
  );

  var server = await app.serve(host, port);
  print('Environment');
  print("--------------------------");
  for (var element in env.entries) {
    print('${element.key}: ${element.value}');
  }
  print("--------------------------");
  print('Serving at http://${server.address.host}:${server.port}');
}
