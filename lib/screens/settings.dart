import 'dart:async';

import 'package:bhima_collect/models/depot.dart';
import 'package:bhima_collect/models/inventory.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:bhima_collect/services/connect.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhima_collect/utilities/toast_bhima.dart';

@immutable
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  var connexion = Connect();
  var txtServerUrl = TextEditingController();
  var txtUsername = TextEditingController();
  var txtPassword = TextEditingController();
  var database = BhimaDatabase.open();

  bool _isButtonDisabled = false;
  bool isDeviceConnected = false;
  String _serverUrl = '';
  String _username = '';
  String _password = '';
  String _token = '';
  double _progressValue = 0.0;
  List<Depot> depotList = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future fetchInventory() async {
    try {
      setState(() {
        _progressValue += 0.1;
      });

      const inventoryUrl = '/inventory/metadata';
      List inventoryRaw = await connexion.api(inventoryUrl, _token);

      List<Inventory> inventories = inventoryRaw.map((inventory) {
        return Inventory(
            uuid: inventory['uuid'],
            code: inventory['code'],
            group_name: inventory['groupName'],
            is_asset: inventory['is_asset'],
            label: inventory['label'],
            manufacturer_brand: inventory['manufacturer_brand'],
            manufacturer_model: inventory['manufacturer_model'],
            type: inventory['type'],
            unit: inventory['unit']);
      }).toList();

      await Inventory.clean(database);
      await Inventory.txInsertInventory(database, inventories);
      setState(() {
        _progressValue += 0.1;
      });
    } catch (e) {
      throw Exception(e);
    }
  }

  Future syncDepots() async {
    try {
      setState(() {
        _progressValue += 0.1;
      });
      // get only depots of the given user
      List userDepots = await connexion.api(
          '/users/${connexion.user['id']}/depots?details=1', _token);

      List<Depot> userDepotList = userDepots.map((depot) {
        return Depot(uuid: depot['depot_uuid'], text: depot['text']);
      }).toList();

      setState(() {
        depotList = userDepotList;
      });

      // open the database
      var database = BhimaDatabase.open();
      // clean previous data
      Depot.clean(database);
      // write new fresh depots entries
      // insert new with transaction
      await Depot.txInsertDepots(database, userDepotList);
      setState(() {
        _progressValue += 0.1;
      });
    } catch (e) {
      if (kDebugMode) {
        print('ERROR SYNC Depot :  $e');
      }
      throw Exception(e);
    }
  }

  Future submit() async {
    bool isInternetAvailable = await InternetConnectionChecker().hasConnection;

    if (!isInternetAvailable) {
      // ignore: use_build_context_synchronously
      return alertWarning(context, 'Pas de connexion Internet');
    }

    if (_formKey.currentState!.validate()) {
      try {
        // init connexion by getting the user token
        setState(() {
          _isButtonDisabled = true;
          _progressValue += 0.1;
        });
        var token = await connexion.getToken(_serverUrl, _username, _password);
        setState(() {
          _token = token;
          _progressValue += 0.1;
        });
      } catch (e) {
        setState(() {
          _isButtonDisabled = false;
          _progressValue = 0.0;
          _token = '';
        });
        // ignore: use_build_context_synchronously
        return alertError(context, "Echec d'authentification");
      }

      try {
        setState(() {
          _isButtonDisabled = true;
          _progressValue += 0.1;
        });

        await Future.wait([
          // sync the users depots
          syncDepots(),
          // fetch inventory
          fetchInventory(),
          // save settings as preferences
          _saveSettings(),
        ]);

        setState(() {
          _isButtonDisabled = false;
          _progressValue = 0.1;
        });

        // ignore: use_build_context_synchronously
        alertSuccess(context, 'Connexion réussie');

        setState(() {
          _progressValue = 0.0;
        });
      } catch (e) {
        setState(() {
          _isButtonDisabled = false;
          _progressValue = 0.0;
          _token = '';
        });
        // ignore: use_build_context_synchronously
        return alertError(context, 'Echec de synchronisation');
      }
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
    await prefs.setString('token', _token);
    await prefs.remove('selected_depot_text');
    await prefs.remove('selected_depot_uuid');
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
      body: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: "Entrez l'adresse du serveur",
                    icon: Icon(Icons.public),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _serverUrl = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Veuillez saisir l'URL";
                    }
                    return null;
                  },
                  controller: txtServerUrl,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: "Entrez votre nom d'utilisateur",
                    icon: Icon(Icons.person),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _username = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Veuillez saisir l'utilisateur";
                    }
                    return null;
                  },
                  controller: txtUsername,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Entrez le mot de passe',
                    icon: Icon(Icons.lock_outline),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _password = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Veuillez saisir le mot de passe";
                    }
                    return null;
                  },
                  controller: txtPassword,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton(
                  onPressed: _isButtonDisabled
                      ? null
                      : () async {
                          await submit();
                        },
                  child: _isButtonDisabled
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text('En cours de traitement...'),
                            SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.blue,
                                  strokeWidth: 4.0,
                                  strokeCap: StrokeCap.round,
                                )),
                          ],
                        )
                      : const Text('Soumettre'),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20.0),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: !_isButtonDisabled
                        ? null
                        : GFProgressBar(
                            percentage: _progressValue,
                            lineHeight: 20,
                            alignment: MainAxisAlignment.spaceBetween,
                            backgroundColor: Colors.black26,
                            progressBarColor: GFColors.INFO,
                            child: Text(
                              'Chargement... ${(_progressValue * 100).round()}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                          )),
              )
            ],
          )),
    );
  }
}
