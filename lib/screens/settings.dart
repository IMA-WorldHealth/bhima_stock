import 'package:bhima_collect/models/depot.dart';
import 'package:bhima_collect/services/connect.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var connexion = Connect();
  var txtServerUrl = TextEditingController();
  var txtUsername = TextEditingController();
  var txtPassword = TextEditingController();

  bool _isButtonDisabled = false;
  bool _isConnectionSucceed = false;
  bool _isDepotSynced = false;
  String _serverUrl = '';
  String _username = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future checkServerConnection() async {
    _isConnectionSucceed = false;
    try {
      // init connexion by getting the user token
      await connexion.getToken(_serverUrl, _username, _password);
      // update the connection status message
      setState(() {
        _isConnectionSucceed = true;
      });
    } catch (e) {
      _isConnectionSucceed = false;
    }
  }

  Future syncDepots() async {
    _isDepotSynced = false;
    try {
      // get all depots
      List depots = await connexion.api('/depots');

      // get only depots of the given user
      List userDepots =
          await connexion.api('/users/${connexion.user['id']}/depots');

      // update the connection status message
      List<Depot> userDepotList = depots.where((depot) {
        return userDepots.contains(depot['uuid']);
      }).map((depot) {
        return Depot(uuid: depot['uuid'], text: depot['text']);
      }).toList();

      // open the database
      var database = BhimaDatabase.open();
      // clean previous depots
      Depot.clean(database);
      // write new entries
      userDepotList.forEach((depot) async {
        await Depot.insertDepot(database, depot);
      });

      setState(() {
        _isDepotSynced = true;
      });
    } catch (e) {
      setState(() {
        _isDepotSynced = false;
      });
    }
  }

  Future submit() async {
    try {
      setState(() {
        _isButtonDisabled = true;
      });

      // check the connection to the server
      await checkServerConnection();

      // sync the users depots
      await syncDepots();

      // save settings as preferences
      await _saveSettings();

      setState(() {
        _isButtonDisabled = false;
      });
    } catch (e) {
      print(e);
    }
  }

  //Loading settings values on start
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrl = (prefs.getString('server') ?? '');
      txtServerUrl.text = _serverUrl;
      _username = (prefs.getString('username') ?? '');
      txtUsername.text = _username;
      _password = (prefs.getString('password') ?? '');
      txtPassword.text = _password;
    });
  }

  //Write settings values after submission
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server', _serverUrl);
    await prefs.setString('username', _username);
    await prefs.setString('password', _password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametres'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, true);
              },
            );
          },
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextFormField(
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Enter the server URL',
                icon: Icon(Icons.public),
              ),
              onChanged: (value) {
                setState(() {
                  _serverUrl = value;
                });
              },
              controller: txtServerUrl,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextFormField(
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Enter the Username',
                icon: Icon(Icons.person),
              ),
              onChanged: (value) {
                setState(() {
                  _username = value;
                });
              },
              controller: txtUsername,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextFormField(
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Enter the password',
                icon: Icon(Icons.lock_outline),
              ),
              onChanged: (value) {
                setState(() {
                  _password = value;
                });
              },
              controller: txtPassword,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                await submit();
              },
              child: _isButtonDisabled
                  ? const Text('En cours de traitement...')
                  : const Text('Soumettre'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: _isConnectionSucceed && _isDepotSynced
                ? const Text('Synchronisation depot OK')
                : null,
          )
        ],
      ),
    );
  }
}
