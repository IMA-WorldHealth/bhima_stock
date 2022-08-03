import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/models/stock_movement.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:bhima_collect/utilities/util.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_format/date_format.dart';

class StockListPage extends StatefulWidget {
  StockListPage({Key? key}) : super(key: key);

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  var database = BhimaDatabase.open();
  String _selectedDepotUuid = '';
  String _selectedDepotText = '';

  @override
  void initState() {
    super.initState();
    _loadSavedDepot();
  }

  //Loading saved selected depot
  Future<void> _loadSavedDepot() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDepotUuid = (prefs.getString('selected_depot_uuid') ?? '');
      _selectedDepotText = (prefs.getString('selected_depot_text') ?? '');
    });
  }

  // Stream<List<Lot>> _loadLots(String currentDepot) async* {
  //   List<Lot> allLots = await Lot.lots(database);
  //   yield allLots
  //       .where((element) =>
  //           element.depot_uuid == currentDepot && element.quantity! > 0)
  //       .toList();
  // }

  Stream<List> _loadLots(String currentDepot) async* {
    List allLots = await StockMovement.stockQuantity(database);
    yield allLots
        .where((element) =>
            element['depot_uuid'] == currentDepot && element['quantity']! > 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder for list of lots
    // var futureBuilder = FutureBuilder<List<Lot>>(
    //   future: _loadLots(),
    //   builder: ((context, snapshot) {
    //     switch (snapshot.connectionState) {
    //       case ConnectionState.none:
    //         return const Center(child: Text('Aucune connexion'));
    //       case ConnectionState.waiting:
    //         return const Center(child: CircularProgressIndicator());
    //       default:
    //         if (snapshot.hasError) {
    //           return Center(child: Text('${snapshot.error}'));
    //         } else if (snapshot.hasData) {
    //           return Column(
    //             children: <Widget>[
    //               Padding(
    //                 padding: const EdgeInsets.all(5),
    //                 child: Center(
    //                   child: Text(
    //                     _selectedDepotText,
    //                     style: TextStyle(
    //                       fontSize: 20,
    //                       color: Colors.blue[700],
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //               Expanded(
    //                 child: createListView(context, snapshot),
    //               )
    //             ],
    //           );
    //           // return createListView(context, snapshot);
    //         } else {
    //           return const Center(
    //             child: Text('Aucune données trouvées'),
    //           );
    //         }
    //     }
    //   }),
    // );

    var streamBuilder = StreamBuilder<List>(
      stream: _loadLots(_selectedDepotUuid),
      builder: ((context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return const Center(child: Text('Aucune connexion'));
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          default:
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            } else if (snapshot.hasData) {
              return Column(
                children: <Widget>[
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
                  Expanded(
                    child: createListView(context, snapshot),
                  )
                ],
              );
              // return createListView(context, snapshot);
            } else {
              return const Center(
                child: Text('Aucune données trouvées'),
              );
            }
        }
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
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
      body: streamBuilder,
    );
  }

  Widget createListView(BuildContext context, AsyncSnapshot<List> snapshot) {
    List values = snapshot.data ?? [];
    return ListView.builder(
      itemCount: values.length,
      itemBuilder: ((context, index) {
        return Column(
          children: <Widget>[
            Card(
              elevation: 0.5,
              child: Column(
                children: [
                  ListTile(
                    title: Text('${values[index]['text']}'),
                    subtitle: Text('Code: ${values[index]['code']}'),
                    trailing: Chip(
                      backgroundColor: Colors.green[200],
                      label: Text(
                          'Qty: ${values[index]['quantity']} ${values[index]['unit_type']}'),
                    ),
                  ),
                  createAssetTile(values[index]),
                  createLotChip(values[index]),
                ],
              ),
            )
          ],
        );
      }),
    );
  }

  Widget createAssetTile(dynamic value) {
    if (value['is_asset'] == 1) {
      String barcode = value['barcode'] ?? '';
      String serialNumber = stringNotNull(value['serial_number'])
          ? '${value['serial_number']}'
          : '';
      String manufacturerBrand = value['manufacturer_brand'] ?? '';
      String manufacturerModel = stringNotNull(value['manufacturer_model'])
          ? ' - ${value['manufacturer_model']}'
          : '';
      return ListTile(
        title: Text('Brand: $manufacturerBrand $manufacturerModel'),
        subtitle: Text('Serial: $serialNumber'),
        trailing: Text(barcode),
      );
    } else {
      // Empty Widget
      return Row();
    }
  }

  Widget createLotChip(value) {
    String expirationDate = value['expiration_date'] != null
        ? formatDate(value['expiration_date'], [MM, '-', yyyy])
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: [
          Chip(
            label: Text('Lot: ${value['label']}'),
          ),
          if (value['expiration_date'] != null)
            Chip(
              avatar: const Icon(Icons.timelapse_rounded),
              backgroundColor: Colors.orange[200],
              label: Text(expirationDate),
            ),
        ],
      ),
    );
  }
}
