// ignore_for_file: deprecated_member_use

import 'dart:cli';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AwsCredentials {
  String? awsAccessKeyId;
  String? awsSecretAccessKey;
  String? awsSessionToken;
  Map<String, String>? environment;
  Map<String, String>? containerCredentials;

  AwsCredentials(
      {this.awsAccessKeyId,
      this.awsSecretAccessKey,
      this.awsSessionToken,
      this.environment,
      this.containerCredentials}) {
    final env = environment ?? Platform.environment;
    environment ??= Platform.environment;
    awsAccessKeyId = awsAccessKeyId ?? env['AWS_ACCESS_KEY_ID'];
    awsSecretAccessKey = awsSecretAccessKey ?? env['AWS_SECRET_ACCESS_KEY'];

    var isInContainer = env['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'];

    if ((isInContainer != null || containerCredentials != null) &&
        (awsAccessKeyId == null && awsSecretAccessKey == null)) {
      var data = containerCredentials ?? waitFor(getContainerCredentials(env));
      if (data != null) {
        awsAccessKeyId = data['AccessKeyId'];
        awsSecretAccessKey = data['SecretAccessKey'];
        awsSessionToken = data['Token'];
      }
    }

    if (awsAccessKeyId == null || awsSecretAccessKey == null) {
      throw ArgumentError(
          'You must provide a valid Access Key and Secret for AWS.');
    }
  }

  Future<Map<String, String>?> getContainerCredentials(
      Map<String, String> environment) async {
    try {
      var relativeUri =
          environment['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'] ?? '';
      var url = Uri.parse('http://127.0.0$relativeUri');
      var response = await http.read(url);
      return json.decode(response);
    } catch (e) {
      print('failed to get container credentials.');
    }
    return null;
  }
}
