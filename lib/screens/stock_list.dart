// import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/models/stock_movement.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:bhima_collect/utilities/util.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_format/date_format.dart';
import 'package:bhima_collect/components/card_bhima.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({Key? key}) : super(key: key);

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
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

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
                      child: CardBhima(
                        width: screenWidth - 2,
                        height: screenHeight / 12,
                        color: Colors.blue[400],
                        child: Center(
                          child: Text(
                            _selectedDepotText,
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
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
        backgroundColor: const Color.fromARGB(255, 183, 193, 203),
        title: const Text(
          'Stock',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ListView.builder(
      itemCount: values.length,
      itemBuilder: ((context, index) {
        return Column(
          children: <Widget>[
            CardBhima(
              width: screenWidth - 15,
              height: screenHeight / 6.5,
              elevation: 2,
              clipBehavior: Clip.hardEdge,
              color: Colors.blueGrey[100],
              child: Column(
                children: [
                  ListTile(
                    title: Text('${values[index]['text']}'),
                    subtitle: Text('Code: ${values[index]['code']}'),
                    trailing: Chip(
                      backgroundColor: Colors.green[200],
                      label: Text('Qty: ${values[index]['quantity']}'),
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
    dynamic rawExpirationDate;
    if (value['expiration_date'].runtimeType == String) {
      rawExpirationDate = parseDate(value['expiration_date']);
    } else {
      rawExpirationDate = value['expiration_date'];
    }
    String expirationDate = rawExpirationDate != null
        ? formatDate(rawExpirationDate, [MM, '-', yyyy])
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
