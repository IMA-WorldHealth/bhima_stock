import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Connect {
  String token = '';
  String _server = '';
  String _username = '';
  String _password = '';
  var user = {};

  //Write settings values after submission
  Future<void> _saveUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  Future<String> getToken(
      String server, String username, String password, int projectId) async {
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
          'project': projectId,
        }));

    if (response.statusCode == 200) {
      var body = jsonDecode(response.body) as Map<String, dynamic>;
      token = body['token'];
      user = body['user'];
      // save the user id
      _saveUser(user['id']);
    } else if (response.statusCode == 401) {
      throw 'Bad username or password';
    } else {
      throw 'Unable to get token';
    }

    return token;
  }

  // url string must start with /
  Future<dynamic> api(String url, String token) async {
    String endPoint = '$_server$url';

    var response = await http.get(
      Uri.parse(endPoint),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate',
        'x-access-token': token,
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    if (response.statusCode == 431) {
      throw 'Request field too large with status ${response.statusCode}';
    }
    throw 'Request failed with status : ${response.statusCode}';
  }

  // post data
  Future post(String url, String token, dynamic params) async {
    String endPoint = '$_server$url';
    var response = await http.post(Uri.parse(endPoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-access-token': token,
        },
        body: jsonEncode(params));

    return jsonDecode(response.body);
  }

  Future<dynamic> getProject(String url) async {
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    if (response.statusCode == 431) {
      throw 'Request field too large with status ${response.statusCode}';
    }
    throw 'Request failed with status : ${response.statusCode}';
  }
}
