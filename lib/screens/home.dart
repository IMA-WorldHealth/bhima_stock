import 'package:bhima_collect/models/inventory_lot.dart';
import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/models/stock_movement.dart';
import 'package:bhima_collect/providers/entry_movement.dart';
import 'package:bhima_collect/providers/exit_movement.dart';
import 'package:bhima_collect/screens/depot.dart';
import 'package:bhima_collect/screens/settings.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:bhima_collect/utilities/toast_bhima.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhima_collect/services/connect.dart';
import 'package:bhima_collect/utilities/util.dart';
import "package:collection/collection.dart";
import "package:yaml/yaml.dart";
import "package:bhima_collect/components/card_bhima.dart";

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
  num _progress = 0;
  int _countSynced = 0;
  int _maxToSync = 0;
  final scaffoldKey = GlobalKey<ScaffoldState>();

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
      _isRecentSync = (prefs.getInt('last_sync') ?? 0) == 0 ? false : true;
    });
  }

  //Write settings values after submission
  Future<void> _saveSyncInfo(
      String lastSyncDate, int itemsSynced, int totalItemsToSync) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_date', lastSyncDate);
    await prefs.setInt('items_synced', itemsSynced);
    await prefs.setInt('total_items_to_sync', totalItemsToSync);
    await prefs.setInt('last_sync', 1);
  }

  Future serverConnection() async {
    try {
      // init connexion by getting the user token
      await connexion.getToken(_serverUrl, _username, _password);
    } catch (e) {
      handleError(e.toString());
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
      // clean previous depots
      Lot.clean(database);
      // write new entries
      lots.forEach((lot) async {
        await Lot.insertLot(database, lot);
      });

      // import into inventory_lot and inventory table
      await InventoryLot.import(database);

      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      handleError(e.toString());
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

      var groupedByIsExit = lots.groupListsBy((element) => element.isExit);

      List<StockMovement> exitMovement = [];
      List<StockMovement> entryMovement = [];

      groupedByIsExit.forEach((key, value) {
        if (key == 1) {
          exitMovement = value;
        } else {
          entryMovement = value;
        }
      });

      var entryGrouped =
          entryMovement.groupListsBy((element) => element.movementUuid);

      var exitGrouped =
          exitMovement.groupListsBy((element) => element.movementUuid);

      _maxToSync = entryGrouped.length + exitGrouped.length;
      _countSynced = 0;
      _progress = _maxToSync != 0 ? 0 : 100;

      // NOTE: Sync entries first before exits

      entryGrouped.forEach((key, value) async {
        var result =
            await connexion.post(url, {'lots': value, 'sync_mobile': 1});

        if (key != null && result != null && result['uuids'] != null) {
          // update the sync status for valid lots of the movements
          await StockMovement.updateSyncStatus(database, key, result['uuids']);
          setState(() {
            _countSynced++;
            _progress = ((_countSynced / _maxToSync) * 100).round();
          });
        }
      });

      // fetch fresh data from the server after entries
      await fetchLots();

      exitGrouped.forEach((key, value) async {
        var result =
            await connexion.post(url, {'lots': value, 'sync_mobile': 1});

        if (key != null && result != null && result['uuids'] != null) {
          // update the sync status for valid lots of the movements
          await StockMovement.updateSyncStatus(database, key, result['uuids']);
          setState(() {
            _countSynced++;
            _progress = ((_countSynced / _maxToSync) * 100).round();
          });
        }
      });

      // fetch fresh data from the server after exits
      await fetchLots();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      handleError(e.toString());
    }
  }

  // sync local lots from integration
  Future syncLots() async {
    try {
      const url = '/stock/lots/create';
      List lots = await StockMovement.getLocalLots(database);
      var grouped = lots.groupListsBy((element) => element['movementUuid']);
      grouped.forEach((key, value) async {
        await connexion.post(url, {'lots': value});
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      handleError(e.toString());
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

        // send local lots
        await syncLots();

        // send local stock movements (not synced)
        await syncStockMovements();

        setState(() {
          lastUpdate = DateTime.now();
          _formattedLastUpdate = formatDate(
              lastUpdate, [dd, '/', mm, '/', yyyy, '  ', HH, ':', nn]);
          _isSyncing = false;
          _isRecentSync = true;
        });

        await _saveSyncInfo(_formattedLastUpdate, _countSynced, _maxToSync);
      } catch (e) {
        setState(() {
          _isSyncing = false;
        });
        if (kDebugMode) {
          print(e);
        }
        handleError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // final ButtonStyle btnStyle = ElevatedButton.styleFrom(
    //   textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    //   backgroundColor: Colors.green[700],
    //   padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
    // );
    // final ButtonStyle btnRedStyle = ElevatedButton.styleFrom(
    //   textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    //   backgroundColor: Colors.red[700],
    //   padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
    // );

    var drawerContent = Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 183, 193, 203)),
            // ignore: unnecessary_const
            child: Center(
              child: Column(
                children: [
                  const Padding(
                      padding: EdgeInsets.all(2),
                      child: Image(
                        image: AssetImage('assets/icon.png'),
                        height: 60,
                        width: 130,
                        fit: BoxFit.contain,
                      )),
                  const Padding(
                    padding: EdgeInsets.all(5),
                    child: Text(
                      'Bhima collect',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: FutureBuilder(
                        future: rootBundle.loadString("pubspec.yaml"),
                        builder: (context, snapshot) {
                          String version = 'Unknown';
                          if (snapshot.hasData) {
                            var yaml = loadYaml(snapshot.data as String);
                            version = yaml["version"];
                          }
                          return Text(
                            'Version $version',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic),
                          );
                        }),
                  )
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_max),
            title: const Text(
              'Choisir Dépôt',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ConfigureDepotPage()),
              ).then((value) => {
                    value ? _loadSavedPreferences() : null,
                    Navigator.pop(context)
                  });
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text(
              'Paramètres',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ).then((value) => {
                    value ? _loadSavedPreferences() : null,
                    Navigator.pop(context)
                  });
            },
          ),
        ],
      ),
    );

    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          toolbarOpacity: 0.8,
          leading: Builder(builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu_sharp, size: 30, color: Colors.black),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
              },
            );
          }),
          backgroundColor: const Color.fromARGB(255, 183, 193, 203),
          title: const Text(
            'Acceuil',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        drawer: drawerContent,
        body: _selectedDepotText != ''
            ? Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ListView(
                    children: <Widget>[
                      CardBhima(
                        color: Colors.lime[600],
                        height: screenHeight / 8,
                        elevation: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(5),
                              child: Text('Votre dépôt en cours est :',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: Center(
                                child: Text(
                                  _selectedDepotText,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        // padding: const EdgeInsets.all(10.0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 3, horizontal: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CardBhima(
                              onTap: () {
                                Navigator.pushNamed(context, '/stock_entry')
                                    .then((value) => Provider.of<EntryMovement>(
                                            context,
                                            listen: false)
                                        .reset());
                              },
                              color: Colors.orange[300],
                              width: screenWidth / 2.3,
                              height: 95,
                              elevation: 2,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.add,
                                      size: 26, color: Colors.white),
                                  Text('Réception',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              // ),
                            ),
                            CardBhima(
                              color: Colors.blue[300],
                              width: screenWidth / 2.3,
                              elevation: 2,
                              height: 95,
                              onTap: () {
                                Navigator.pushNamed(
                                        context, '/stock_integration')
                                    .then((value) => Provider.of<EntryMovement>(
                                            context,
                                            listen: false)
                                        .reset());
                              },
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.add,
                                      size: 26, color: Colors.white),
                                  Text(
                                    'Integration de stock',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            // ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 3, horizontal: 5),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CardBhima(
                                color: const Color.fromARGB(255, 100, 105, 246),
                                width: screenWidth / 2.3,
                                height: 95,
                                elevation: 2,
                                onTap: () {
                                  Navigator.pushNamed(context, '/stock');
                                },
                                // style: btnStyle,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.inventory_sharp,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                    Text('Stock',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              CardBhima(
                                color: const Color.fromARGB(255, 149, 81, 127),
                                width: screenWidth / 2.3,
                                elevation: 2,
                                height: 95,
                                onTap: () {
                                  Navigator.pushNamed(context, '/stock_exit')
                                      .then((value) =>
                                          Provider.of<ExitMovement>(context,
                                                  listen: false)
                                              .reset());
                                },
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.people_alt_rounded,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('Consommation',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 3, horizontal: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CardBhima(
                              color: Colors.green[900],
                              width: screenWidth / 2.3,
                              elevation: 2,
                              height: 95,
                              onTap: syncBtnClicked,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  _isSyncing
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                          semanticsLabel: 'Chargement...',
                                        )
                                      : const Text(
                                          'Synchroniser',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ],
                              ),
                            ),
                            CardBhima(
                              color: Colors.red[900],
                              width: screenWidth / 2.3,
                              elevation: 2,
                              height: 95,
                              onTap: () {
                                Navigator.pushNamed(context, '/stock_loss')
                                    .then((value) => Provider.of<EntryMovement>(
                                            context,
                                            listen: false)
                                        .reset());
                              },
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.delete_outline,
                                    size: 26,
                                    color: Colors.white,
                                  ),
                                  Text('Perte de stock',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _progress > 0
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
                                      'Données synchronisées : $_countSynced / $_maxToSync'),
                                ],
                              )
                            : Row(),
                      )
                    ],
                  ),
                ),
              )
            : Center(
                child: CardBhima(
                  width: screenWidth / 1.5,
                  height: 80,
                  elevation: 2,
                  clipBehavior: Clip.hardEdge,
                  color: const Color.fromARGB(255, 183, 193, 203),
                  onTap: () {
                    scaffoldKey.currentState?.openDrawer();
                  },
                  child: const Center(
                    child: Text(
                      'Veuillez choisir un dépôt',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ));
  }
}
