import 'dart:convert';
import 'package:http/http.dart' as http;

class Connect {
  String token = '';
  String _server = '';
  String _username = '';
  String _password = '';
  var user = {};

  Future<String> getToken(
    String server,
    String username,
    String password,
  ) async {
    _server = server;
    _username = username;
    _password = password;
    String endPoint = '$_server/auth/login';
    var response = await http.post(Uri.parse(endPoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'username': _username,
          'password': _password,
          'project': 1,
        }));

    if (response.statusCode == 200) {
      var body = jsonDecode(response.body) as Map<String, dynamic>;
      token = body['token'];
      user = body['user'];
    } else {
      throw 'Unable to get token';
    }

    return token;
  }

  // url string must start with /
  Future<dynamic> api(String url) async {
    String endPoint = '$_server$url';
    String token = await getToken(_server, _username, _password);

    var response = await http.get(
      Uri.parse(endPoint),
      headers: <String, String>{
        'x-access-token': token,
      },
    );
    return jsonDecode(response.body);
  }
}
