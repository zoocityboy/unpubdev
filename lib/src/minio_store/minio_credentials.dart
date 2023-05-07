// ignore_for_file: deprecated_member_use
part of 'package_store.dart';

class MinioCredentials {
  String? accessKey;
  String? secretKey;
  String? awsSessionToken;
  Map<String, String>? environment;
  Map<String, String>? containerCredentials;

  MinioCredentials(
      {this.accessKey,
      this.secretKey,
      this.awsSessionToken,
      this.environment,
      this.containerCredentials}) {
    final env = environment ?? Platform.environment;
    environment ??= Platform.environment;
    accessKey = accessKey ?? env['MINIO_ROOT_USER'];
    secretKey = secretKey ?? env['MINIO_ROOT_PASSWORD'];

    var isInContainer = env['MINIO_CONTAINER_CREDENTIALS_RELATIVE_URI'];

    if ((isInContainer != null || containerCredentials != null) &&
        (accessKey == null && secretKey == null)) {
      var data = containerCredentials ?? waitFor(getContainerCredentials(env));
      if (data != null) {
        accessKey = data['AccessKeyId'];
        secretKey = data['SecretAccessKey'];
        awsSessionToken = data['Token'];
      }
    }

    if (accessKey == null || secretKey == null) {
      throw ArgumentError(
          'You must provide a valid Access Key and Secret for AWS.');
    }
  }

  Future<Map<String, String>?> getContainerCredentials(
      Map<String, String> environment) async {
    try {
      var relativeUri =
          environment['MINIO_CONTAINER_CREDENTIALS_RELATIVE_URI'] ?? '';
      var url = Uri.parse('http://127.0.0$relativeUri');
      var response = await http.read(url);
      return json.decode(response);
    } catch (e) {
      print('failed to get container credentials.');
    }
    return null;
  }
}
