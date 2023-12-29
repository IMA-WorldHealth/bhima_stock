import 'dart:async';

import 'package:bhima_collect/models/depot.dart';
import 'package:bhima_collect/models/inventory.dart';
import 'package:bhima_collect/models/inventory_lot.dart';
import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/services/connect.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:bhima_collect/utilities/util.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  List<Depot> depotList = [];
  @override
  void initState() {
    super.initState();
    _loadSettings();
    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      if (kDebugMode) print('Couldn\'t check connectivity status $e');
      return;
    }
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  Future checkServerConnection() async {
    if (_connectionStatus == ConnectivityResult.mobile ||
        _connectionStatus == ConnectivityResult.wifi) {
      try {
        // init connexion by getting the user token
        var token = await connexion.getToken(_serverUrl, _username, _password);
        setState(() {
          _token = token;
        });
      } catch (e) {
        throw Exception(e);
      }
    } else {
      throw ("Vous n'etes connecté à un réseau");
    }
  }

  Future fetchLots() async {
    try {
      setState(() {
        _progressValue += 0.1;
      });
      // clean previous lots
      Lot.clean(database);
      // collect the lots by deposit
      for (var dp in depotList) {
        String depotUuid = dp.uuid;
        /**
       * Include empty lots for having lots which are sent by not yet received
       */
        String lotDataUrl =
            '/stock/lots/depots?includeEmptyLot=0&fullList=1&depot_uuid=$depotUuid';
        List lotsRaw = await connexion.api(lotDataUrl, _token);

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
        // write new entries
        await Lot.txInsertLot(database, lots);
      }
      await InventoryLot.import(database);
      setState(() {
        _progressValue += 0.1;
      });
    } catch (e) {
      if (kDebugMode) {
        print('ERROR_LOT: $e');
      }
      throw Exception(e);
    }
  }

  Future fetchInventory() async {
    try {
      setState(() {
        _progressValue += 0.1;
      });
      const inventoryUrl = '/inventory/metadata?is_asset=0';

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
      // get all depots
      setState(() {
        _progressValue += 0.1;
      });
      List depots = await connexion.api('/depots', _token);
      // get only depots of the given user
      List userDepots =
          await connexion.api('/users/${connexion.user['id']}/depots', _token);

      List<Depot> userDepotList = depots.where((depot) {
        return userDepots.contains(depot['uuid']);
      }).map((depot) {
        return Depot(uuid: depot['uuid'], text: depot['text']);
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
      await Depot.txInsertLot(database, userDepotList);
      setState(() {
        _progressValue += 0.1;
      });
    } catch (e) {
      if (kDebugMode) {
        print('ERROR SYNC DEpot :  $e');
      }
      throw Exception(e);
    }
  }

  Future submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isButtonDisabled = true;
          _progressValue += 0.1;
        });

        await checkServerConnection();
        // sync the users depots
        await syncDepots();

        await Future.wait([
          // fetch lots
          fetchLots(),
          // fetch inventory
          fetchInventory(),
          // save settings as preferences
          _saveSettings(),
        ]);

        setState(() {
          _isButtonDisabled = false;
          // _progressValue = 0.0;
        });

        // ignore: use_build_context_synchronously
        alertSuccess(context, 'Synchronisation des données réussie');
      } catch (e) {
        setState(() {
          _isButtonDisabled = false;
          _progressValue = 0.0;
          _token = '';
        });
        // ignore: use_build_context_synchronously
        alertError(context, 'Echec de synchronisation \n ${e.toString()}');
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
                            leading: const Icon(Icons.sentiment_dissatisfied,
                                color: GFColors.DANGER),
                            trailing: const Icon(Icons.sentiment_satisfied,
                                color: GFColors.SUCCESS),
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
