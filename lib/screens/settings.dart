import 'package:bhima_collect/models/depot.dart';
import 'package:bhima_collect/models/inventory_lot.dart';
import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/services/connect.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:bhima_collect/utilities/util.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  var connexion = Connect();
  var txtServerUrl = TextEditingController();
  var txtUsername = TextEditingController();
  var txtPassword = TextEditingController();

  bool _isButtonDisabled = false;
  bool _isConnectionSucceed = false;
  bool _isSyncFailed = false;
  bool _isDepotSynced = false;
  bool _isLotsImported = false;
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

  Future fetchLots() async {
    try {
      /**
       * Include empty lots for having lots which are sent by not yet received
       */
      const lotDataUrl = '/stock/lots/depots?includeEmptyLot=1';

      List lotsRaw = await connexion.api(lotDataUrl);

      List<Lot> lots = lotsRaw.map((lot) {
        return Lot(
          uuid: lot['uuid'],
          label: lot['label'],
          lot_description: lot['lot_description'],
          code: lot['code'],
          inventory_uuid: lot['inventory_uuid'],
          text: lot['text'],
          unit_type: lot['unit_type'],
          group_name: lot['group_name'],
          depot_text: lot['depot_text'],
          depot_uuid: lot['depot_uuid'],
          is_asset: lot['is_asset'],
          barcode: lot['barcode'],
          serial_number: lot['serial_number'],
          reference_number: lot['reference_number'],
          manufacturer_brand: lot['manufacturer_brand'],
          manufacturer_model: lot['manufacturer_model'],
          unit_cost: lot['unit_cost'],
          quantity: lot['quantity'],
          avg_consumption: lot['avg_consumption'],
          exhausted: parseBool(lot['exhausted']),
          expired: parseBool(lot['expired']),
          near_expiration: parseBool(lot['near_expiration']),
          expiration_date: parseDate(lot['expiration_date']),
          entry_date: parseDate(lot['entry_date']),
        );
      }).toList();

      // open the database
      var database = BhimaDatabase.open();
      // clean previous lots
      Lot.clean(database);
      // write new entries
      lots.forEach((lot) async {
        await Lot.insertLot(database, lot);
      });

      // import into inventory_lot and inventory table
      await InventoryLot.import(database);

      setState(() {
        _isLotsImported = true;
      });
    } catch (e) {
      print(
          'Error during fetch of lots : $e, $_serverUrl, $_username, $_password');
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
      // clean previous data
      Depot.clean(database);
      // write new fresh depots entries
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
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isButtonDisabled = true;
        });

        // check the connection to the server
        await checkServerConnection();

        // sync the users depots
        await syncDepots();

        // fetch lots
        await fetchLots();

        // save settings as preferences
        await _saveSettings();

        setState(() {
          _isButtonDisabled = false;
        });
      } catch (e) {
        setState(() {
          _isSyncFailed = true;
        });
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
                child: ElevatedButton(
                  onPressed: _isButtonDisabled
                      ? null
                      : () async {
                          await submit();
                        },
                  child: _isButtonDisabled
                      ? const Text('En cours de traitement...')
                      : const Text('Soumettre'),
                ),
              ),
              Center(
                child: _isDepotSynced && _isLotsImported
                    ? const Text(
                        'Synchronisation des données réussie',
                        style: TextStyle(color: Colors.green),
                      )
                    : _isSyncFailed
                        ? const Text(
                            'Echec de synchronisation',
                            style: TextStyle(color: Colors.red),
                          )
                        : null,
              )
            ],
          )),
    );
  }
}
