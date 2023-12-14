import 'package:bhima_collect/components/card_bhima.dart';
import 'package:bhima_collect/components/search_bhima.dart';
import 'package:bhima_collect/models/stock_movement.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:bhima_collect/utilities/util.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_format/date_format.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  var database = BhimaDatabase.open();
  String _selectedDepotUuid = '';
  String _selectedDepotText = '';
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedDepot();
  }

  onSearch(String value) {
    setState(() {
      _searchText = value;
    });
  }

  //Loading saved selected depot
  Future<void> _loadSavedDepot() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDepotUuid = (prefs.getString('selected_depot_uuid') ?? '');
      _selectedDepotText = (prefs.getString('selected_depot_text') ?? '');
    });
  }

  Stream<List> _loadLots() async* {
    List allLots =
        await StockMovement.stockQuantityDepot(database, _selectedDepotUuid);
    yield allLots.where((element) => element['quantity']! > 0).toList();
  }

  Stream<List> _filterLot(String text) async* {
    List allLots = await StockMovement.stockQuantityDepotFilter(
        database, _selectedDepotUuid, text);
    yield allLots.where((element) => element['quantity']! > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    var streamBuilder = StreamBuilder<List>(
      stream: _searchController.text.isEmpty
          ? _loadLots()
          : _filterLot(_searchText),
      builder: ((context, snapshot) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        } else if (snapshot.hasData) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(0.0),
                child: CardBhima(
                    width: screenWidth,
                    height: screenHeight / 6.1,
                    borderOnForeground: false,
                    elevation: 2,
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              _selectedDepotText,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.blue[700],
                                  overflow: TextOverflow.visible),
                            )),
                        SearchBhima(
                          onSearch: onSearch,
                          searchController: _searchController,
                          hintText: 'Recherche par lot, ou  nom inventaire ...',
                        ),
                      ],
                    )),
                // child: Center(
                //   child:
                //   ),
                // ),
              ),
              Expanded(
                child: createListView(context, snapshot),
              )
            ],
          );
          // return createListView(context, snapshot);
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
      return const Row();
    }
  }

  Widget createLotChip(value) {
    dynamic rawExpirationDate;
    if (value['expiration_date'].runtimeType == String) {
      rawExpirationDate = parseDate(value['expiration_date']);
    } else {
      rawExpirationDate = value['expiration_date'];
    }
    dynamic expirationDate = rawExpirationDate != null
        ? formatDate(rawExpirationDate, [MM, '-', yyyy])
        : null;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.spaceBetween,
            spacing: 3.0,
            children: [
              Chip(
                label: Text(
                  'Lot: ${value['label']}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              expirationDate != null
                  ? Chip(
                      avatar: const Icon(Icons.timelapse_rounded),
                      backgroundColor: Colors.orange[200],
                      label: Text(expirationDate),
                    )
                  : Chip(
                      avatar: const Icon(Icons.no_backpack_rounded,
                          color: Colors.white),
                      backgroundColor: Colors.red[300],
                      label: const Text(
                        'Invalid date',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ],
          ),
        ));
  }
}
