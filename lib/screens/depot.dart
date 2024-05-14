// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:bhima_collect/components/card_bhima.dart';
import 'package:bhima_collect/components/search_bhima.dart';
import 'package:bhima_collect/models/depot.dart';
import 'package:bhima_collect/models/inventory_lot.dart';
import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/models/stock_movement.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:bhima_collect/services/connect.dart';
import 'package:bhima_collect/utilities/toast_bhima.dart';
import 'package:bhima_collect/utilities/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigureDepotPage extends StatefulWidget {
  const ConfigureDepotPage({super.key});

  @override
  State<ConfigureDepotPage> createState() => _ConfigureDepotPageState();
}

class _ConfigureDepotPageState extends State<ConfigureDepotPage> {
  var database = BhimaDatabase.open();
  var connexion = Connect();
  String _selectedDepotUuid = '';
  String _selectedDepotText = '';
  final TextEditingController _searchCtrller = TextEditingController();
  String _textDepot = '';
  Future<List<dynamic>>? _depotFuture;
  String _serverUrl = '';
  String _username = '';
  String _password = '';
  int projectId = 0;
  bool isLoading = false;
  int indexDepot = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedDepot();
    _depotFuture = _loadDepots();
  }

  @override
  void dispose() {
    _searchCtrller.dispose();
    super.dispose();
  }

  _onSeach(String value) {
    setState(() {
      _textDepot = value;
    });
  }

  //Loading saved selected depot
  Future<void> _loadSavedDepot() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = (prefs.getString('username') ?? '');
      _password = (prefs.getString('password') ?? '');
      _selectedDepotUuid = (prefs.getString('selected_depot_uuid') ?? '');
      _selectedDepotText = (prefs.getString('selected_depot_text') ?? '');
      _serverUrl = prefs.getString('server') ?? '';
      projectId = (prefs.getInt('projectId') ?? 0);
    });
  }

  void onToggleShow(bool show) {
    if (show) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Chargement des lots'),
            content: show
                ? const CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 5,
                  )
                : Icon(Icons.check_circle_outline_outlined,
                    size: 23, color: Colors.green[200]),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.maybePop(context);
                },
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
    }
  }

  // handle change on option choice
  Future<void> _onChanged(dynamic val) async {
    bool isInternetAvailable = await InternetConnectionChecker().hasConnection;

    if (!isInternetAvailable) {
      return alertWarning(context, 'Pas de connexion Internet');
    }

    try {
      setState(() {
        isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      List<Depot> userDepots = await _loadDepots();
      Depot userSelectedDepot = userDepots
          .where((element) => element.uuid == val.uuid.toString())
          .toList()[0];
      setState(() {
        _selectedDepotUuid = userSelectedDepot.uuid;
        _selectedDepotText = userSelectedDepot.text;
      });
      await Future.wait([
        prefs.setString('selected_depot_uuid', _selectedDepotUuid),
        prefs.setString('selected_depot_text', _selectedDepotText),
        fetchLots(userSelectedDepot.uuid)
      ]);
      alertSuccess(context, 'Chargement des lots reussi!');
    } catch (e) {
      alertError(
          context, 'Une erreur est survenue lors du chargement des lots');
    }
  }

  Future fetchLots(String depotUuid) async {
    try {
      setState(() {
        isLoading = true;
      });
      var token =
          await connexion.getToken(_serverUrl, _username, _password, projectId);
      // clean previous lots
      Lot.clean(database);
      StockMovement.clean(database);
      // collect the lots by deposit

      /**
       * Include empty lots for having lots which are sent by not yet received
       */
      String lotDataUrl =
          '/stock/lots/depots?includeEmptyLot=0&fullList=1&depot_uuid=$depotUuid';
      List lotsRaw = await connexion.api(lotDataUrl, token);

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
      await InventoryLot.import(database);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('ERROR_LOT: $e');
      }
      setState(() {
        isLoading = false;
      });
      throw Exception(e);
    }
  }

  Future<List<Depot>> _loadDepots() async {
    return Depot.depots(database);
  }

  Future<List<Depot>> _filterDepots(String text) async {
    return Depot.depotFilter(database, text);
  }

  void clearText() {
    setState(() {
      _textDepot = '';
    });
    _searchCtrller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depot'),
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
      body: FutureBuilder<List>(
        future: _searchCtrller.text.isEmpty
            ? _depotFuture
            : _filterDepots(_textDepot),
        builder: (context, snapshot) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            List values = (snapshot.data ?? []);
            return Padding(
              padding: const EdgeInsets.all(0.0),
              child: Column(children: <Widget>[
                CardBhima(
                  width: screenWidth,
                  height: screenHeight / 13.5,
                  borderOnForeground: false,
                  elevation: 2,
                  clipBehavior: Clip.hardEdge,
                  child: SearchBhima(
                    clear: clearText,
                    onSearch: _onSeach,
                    searchController: _searchCtrller,
                    hintText: 'Recherche un dépot ...',
                  ),
                ),
                Expanded(
                    child: ListView.builder(
                        itemCount: values.length,
                        itemBuilder: ((context, index) {
                          return Column(children: <Widget>[
                            Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        indexDepot = index;
                                      });
                                      _onChanged(values[index]);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      fixedSize: Size(
                                          screenWidth - 2, screenHeight / 17),
                                      side: BorderSide(
                                          color: values[index].uuid ==
                                                  _selectedDepotUuid
                                              ? Colors.blue
                                              : Colors.black),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Flexible(
                                            child: Text(
                                              '${values[index].text}',
                                              style: TextStyle(
                                                overflow: TextOverflow.visible,
                                                color: values[index].uuid ==
                                                        _selectedDepotUuid
                                                    ? Colors.blue
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                          generateLoadIcon(values[index], index)
                                        ])))
                          ]);
                        }))),
              ]),
            );
          }
        },
      ),
    );
  }

  Widget generateLoadIcon(dynamic values, int index) {
    if (!isLoading &&
        indexDepot != index &&
        values.uuid != _selectedDepotUuid) {
      return const Icon(Icons.circle_outlined, color: Colors.black);
    } else if (isLoading &&
        indexDepot == index &&
        values.uuid == _selectedDepotUuid) {
      return const CircularProgressIndicator(
        color: Colors.blue,
        strokeWidth: 1.8,
        strokeAlign: 0.4,
      );
    } else if (!isLoading && values.uuid == _selectedDepotUuid) {
      return const Icon(Icons.check_circle, color: Colors.blue);
    } else {
      return const Icon(Icons.circle_outlined, color: Colors.black);
    }
  }
}
