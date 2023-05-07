import 'dart:io';

import 'package:args/args.dart';
import 'package:eit_unpubdev/unpubdev.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub/unpub.dart' as unpub;

main(List<String> args) async {
  final env = Platform.environment;
  final dbName = env['MONGO_DB'] ?? 'unpubdev';

  var parser = ArgParser();
  parser.addOption('host', abbr: 'h', defaultsTo: '0.0.0.0');
  parser.addOption('port', abbr: 'p', defaultsTo: '4000');
  parser.addOption('database',
      abbr: 'd', defaultsTo: 'mongodb://127.0.0.1:27017/$dbName');
  parser.addOption('proxy-origin', abbr: 'o', defaultsTo: '');

  var results = parser.parse(args);

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
  try {
    await db.open(); // make sure the MongoDB connection opened
  } catch (e) {
    print(Error.safeToString(e));
    rethrow;
  }

  final app = unpub.App(
    proxy_origin: proxyOrigin.trim().isEmpty ? null : Uri.parse(proxyOrigin),
    metaStore: unpub.MongoStore(db),
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
