import 'package:bhima_collect/models/inventory_lot.dart';
import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/models/stock_movement.dart';
import 'package:bhima_collect/providers/entry_movement.dart';
import 'package:bhima_collect/providers/exit_movement.dart';
import 'package:bhima_collect/screens/depot.dart';
import 'package:bhima_collect/screens/settings.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhima_collect/services/connect.dart';
import 'package:bhima_collect/utilities/util.dart';
import "package:collection/collection.dart";

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var connexion = Connect();
  var database = BhimaDatabase.open();
  DateTime lastUpdate = DateTime.now();
  String _formattedLastUpdate = '';
  String _selectedDepotText = '';
  bool _isRecentSync = false;
  bool _isSyncing = false;
  String _serverUrl = '';
  String _username = '';
  String _password = '';
  int _importedRecords = 0;
  num _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  //Loading settings values on start
  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrl = (prefs.getString('server') ?? '');
      _username = (prefs.getString('username') ?? '');
      _password = (prefs.getString('password') ?? '');
      _selectedDepotText = (prefs.getString('selected_depot_text') ?? '');
      _formattedLastUpdate = (prefs.getString('last_sync_date') ?? '');
      _importedRecords = (prefs.getInt('last_sync_items') ?? 0);
      _isRecentSync = (prefs.getInt('last_sync') ?? 0) == 0 ? false : true;
    });
  }

  //Write settings values after submission
  Future<void> _saveSyncInfo(String lastSyncDate, int lastSyncItems) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_date', lastSyncDate);
    await prefs.setInt('last_sync_items', lastSyncItems);
    await prefs.setInt('last_sync', 1);
  }

  Future serverConnection() async {
    try {
      // init connexion by getting the user token
      await connexion.getToken(_serverUrl, _username, _password);
    } catch (e) {}
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
      // clean previous depots
      Lot.clean(database);
      // write new entries
      lots.forEach((lot) async {
        await Lot.insertLot(database, lot);
      });

      // import into inventory_lot and inventory table
      await InventoryLot.import(database);

      setState(() {
        _importedRecords = lots.length;
      });
    } catch (e) {
      print(
          'Error during fetch of lots : $e, $_serverUrl, $_username, $_password');
    }
  }

  Future syncStockMovements() async {
    try {
      const url = '/stock/lots/movements';
      List<StockMovement> movements =
          await StockMovement.stockMovements(database);

      var lots = movements
          .where((element) => element.isSync == 0 || element.isSync == null)
          .toList();

      var grouped = lots.groupListsBy((element) => element.movementUuid);

      var max = grouped.length;
      var i = 0;
      var countSynced = 0;
      _progress = max != 0 ? 0 : 100;
      grouped.forEach((key, value) async {
        var result =
            await connexion.post(url, {'lots': value, 'sync_mobile': 1});

        if (key != null && result != null) {
          // update the sync status for valid lots of the movements
          await StockMovement.updateSyncStatus(database, key, result['uuids']);
          countSynced++;
        }

        setState(() {
          i++;
          _progress =
              (((i / max) * 100 + (countSynced / max) * 100) / 2).round();
        });
      });
    } catch (e) {
      print(e);
    }
  }

  Future syncBtnClicked() async {
    if (_isSyncing) {
      return null;
    } else {
      // sync data
      try {
        setState(() {
          _isSyncing = true;
        });

        // set the connection to the server
        await serverConnection();

        // send local stock movements (not synced)
        await syncStockMovements();

        // fetch fresh data from the server
        await fetchLots();

        setState(() {
          lastUpdate = DateTime.now();
          _formattedLastUpdate = formatDate(
              lastUpdate, [dd, '/', mm, '/', yyyy, '  ', HH, ':', nn]);
          _isSyncing = false;
          _isRecentSync = true;
        });

        await _saveSyncInfo(_formattedLastUpdate, _importedRecords);
      } catch (e) {
        setState(() {
          _isSyncing = false;
        });
        print(e);
      }
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
                  ).then((value) => value ? _loadSavedPreferences() : null);
                  break;
                case 'Paramètres':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  ).then((value) => value ? _loadSavedPreferences() : null);
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
                          Navigator.pushNamed(context, '/stock_entry').then(
                              (value) => Provider.of<EntryMovement>(context,
                                      listen: false)
                                  .reset());
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
                          Navigator.pushNamed(context, '/stock_exit').then(
                              (value) => Provider.of<ExitMovement>(context,
                                      listen: false)
                                  .reset());
                        },
                        style: btnStyle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            Icon(Icons.people_alt_rounded),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Consommation'),
                            ),
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
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    semanticsLabel: 'Chargement...',
                                  )
                                : const Text('Synchroniser'),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _isSyncing
                          ? Column(
                              children: <Widget>[
                                LinearProgressIndicator(
                                  value: _progress.toDouble(),
                                  semanticsLabel: '$_progress %',
                                ),
                                Text('$_progress %')
                              ],
                            )
                          : Row(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _isRecentSync
                          ? Column(
                              children: <Widget>[
                                const Text('Dernière synchronisation'),
                                Text(_formattedLastUpdate),
                                Text(
                                    'Nombre des lots importés : $_importedRecords'),
                              ],
                            )
                          : Row(),
                    )
                  ],
                ),
              ),
            )
          : const Center(child: Text('Veuillez choisir un dépôt')),
    );
  }
}
