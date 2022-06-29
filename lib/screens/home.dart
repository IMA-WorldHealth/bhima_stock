import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/screens/depot.dart';
import 'package:bhima_collect/screens/settings.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhima_collect/services/connect.dart';
import 'package:bhima_collect/utilities/util.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var connexion = Connect();
  DateTime? lastUpdate;
  String _selectedDepotText = '';
  bool _isSyncing = false;
  bool _isConnectionSucceed = false;
  String _serverUrl = '';
  String _username = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    _loadSavedDepot();
    _loadSettings();
  }

  // //Loading saved selected depot
  Future<void> _loadSavedDepot() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDepotText = (prefs.getString('selected_depot_text') ?? '');
    });
  }

  //Loading settings values on start
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrl = (prefs.getString('server') ?? '');
      _username = (prefs.getString('username') ?? '');
      _password = (prefs.getString('password') ?? '');
    });
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
      const lotDataUrl = '/stock/lots/depots?displayValues=&includeEmptyLot=1';
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
          unit_cost: lot['unit_cost'],
          quantity: lot['quantity'],
          avg_consumption: lot['avg_consumption'],
          lifetime: lot['lifetime'],
          lifetime_lot: lot['lifetime_lot'],
          exhausted: parseBool(lot['exhausted']),
          expired: parseBool(lot['expired']),
          near_expiration: parseBool(lot['near_expiration']),
          expiration_date: parseDate(lot['expiration_date']),
        );
      }).toList();

      // open the database
      var database = BhimaDatabase.open();
      // clean previous depots
      Lot.clean(database);
      // write new entries
      lots.forEach((lot) async {
        await Lot.insertLot(database, lot);
      });
    } catch (e) {
      print('Error during fetch of lots : $e');
    }
  }

  Future syncBtnClicked() async {
    try {
      setState(() {
        _isSyncing = true;
      });

      await checkServerConnection();

      await fetchLots();

      setState(() {
        lastUpdate = DateTime.now();
        _isSyncing = false;
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle btnStyle = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      primary: Colors.green[700],
    );

    return Scaffold(
      appBar: AppBar(
        leading: Image.asset(
          'assets/icon.png',
        ),
        title: const Text('BHIMA'),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'Choisir Dépôt':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ConfigureDepotPage()),
                  ).then((value) => value ? _loadSavedDepot() : null);
                  break;
                case 'Paramètres':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  ).then((value) => value ? _loadSavedDepot() : null);
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Choisir Dépôt', 'Paramètres'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _selectedDepotText != ''
          ? Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                width: double.infinity,
                child: ListView(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.all(5),
                      child: Center(child: Text('Votre depot en cours est')),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Center(
                        child: Text(
                          _selectedDepotText,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          print('Click on Entree de stock');
                        },
                        style: btnStyle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            Icon(Icons.add),
                            Text('Entrée de stock'),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/stock');
                        },
                        style: btnStyle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            Text('Stock'),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          print('Click on Entree de stock');
                        },
                        style: btnStyle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            Icon(Icons.remove),
                            Text('Sortie de stock'),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: syncBtnClicked,
                        style: btnStyle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _isSyncing
                                ? const Text('En cours...')
                                : const Text('Synchroniser'),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: <Widget>[
                          const Text('Dernière synchronisation'),
                          Text(lastUpdate != null ? lastUpdate.toString() : ''),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          : const Center(child: Text('Veuillez choisir un dépôt')),
    );
  }
}
