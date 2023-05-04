import 'package:eit_unpubdev/src/aws_credentials.dart';
import 'package:eit_unpubdev/src/s3_file_store.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub/unpub.dart' as unpub;

main(List<String> args) async {
  final db = Db('mongodb://localhost:27017/dart_pub');
  await db.open(); // make sure the MongoDB connection opened

  final app = unpub.App(
    metaStore: unpub.MongoStore(db),
    packageStore: S3Store(
      'pubdev',

      // We attempt to find region from AWS_DEFAULT_REGION. If one is not
      // available or provided an Argument error will be thrown.
      region: 'us-east-1',

      // Provide a different S3 compatible endpoint.
      endpoint: '127.0.0.1',

      // By default packages are sorted into folders in s3 like this.
      // Pass in an alternative if needed.
      getObjectPath: (String name, String version) =>
          '$name/$name-$version.tar.gz',

      // You can provide credentials manually but...
      // don't be bad at security populate env vars instead...
      //
      // AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxxxxx
      // AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
      credentials: AwsCredentials(
        awsAccessKeyId: 'BIfYL9y0auX4KqPw',
        awsSecretAccessKey: 'bElQc7YtZFqI5YOYXVdRtFO8DBxsFsE8',
      ),
    ),
    uploadValidator: (pubspec, uploaderEmail) {
      var prefix = 'eit_';
      var name = pubspec['name'] as String;
      if (!name.startsWith(prefix)) {
        throw 'Package name should starts with $prefix';
      }

      // Also, you can check if uploader email is valid

      if (!['@embedit.com', '@homecredit.eu']
          .any((element) => uploaderEmail.endsWith(element))) {
        throw 'Uploader email invalid';
      }
      return Future.value();
    },
  );

  final server = await app.serve('0.0.0.0', 4000);
  print('Serving at http://${server.address.host}:${server.port}');
}
