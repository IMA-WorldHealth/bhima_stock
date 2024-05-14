// ignore_for_file: unused_local_variable

import 'package:bhima_collect/models/stock_movement.dart';
import 'package:bhima_collect/providers/exit_movement.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:bhima_collect/utilities/util.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';
import 'package:uuid/uuid.dart';
import 'package:bhima_collect/models/lot.dart';

class StockAdjustmentPage extends StatefulWidget {
  const StockAdjustmentPage({super.key});

  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPage();
}

class _StockAdjustmentPage extends State<StockAdjustmentPage> {
  var database = BhimaDatabase.open();
  String _selectedDepotUuid = '';
  String _selectedDepotText = '';
  bool isShowBottomSheet = false;
  dynamic _selectLot;
  Stream<List<dynamic>>? _streamLots;
  final INVENTORY_ADJUSTMENT = 15;
  final TextEditingController _txtQuantity = TextEditingController();
  var formatter = DateFormat.yMMMM('fr_FR');
  final _uuid = const Uuid();
  int? _userId;
  @override
  void initState() {
    super.initState();
    _loadSavedDepot();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _streamLots = _loadExitMovement();
      });
    });
  }

  //Loading saved selected depot
  Future<void> _loadSavedDepot() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDepotUuid = (prefs.getString('selected_depot_uuid') ?? '');
      _selectedDepotText = (prefs.getString('selected_depot_text') ?? '');
      _userId = prefs.getInt('user_id');
    });
  }

  Stream<List> _loadLots() async* {
    List allLots =
        await StockMovement.stockQuantityDepot(database, _selectedDepotUuid);
    yield allLots.where((element) => element['quantity']! > 0).toList();
  }

  Future<List<dynamic>> _loadData() async {
    final allLots = _loadLots();
    List allData = [await for (final item in allLots) ...item];

    allData.forEach((element) {
      var lot = {
        'lot_uuid': element['lot_uuid'],
        'lot_label': element['label'],
        'description': element['lot_description'],
        'oldQuantity': element['quantity'],
        'quantity': 0,
        'difference': 0,
        'inventory_uuid': element['inventory_uuid'],
        'inventory_text': element['text'],
        'unit_cost': element['unit_cost'],
        'expiration_date': element['expiration_date'],
        'code': element['code'],
        'depot_uuid': element['depot_uuid'],
        'depot_text': _selectedDepotText,
      };
      Provider.of<ExitMovement>(context, listen: false).addLot(lot);
    });
    return Provider.of<ExitMovement>(context, listen: false).lots;
  }

  Stream<List> _loadExitMovement() async* {
    List allLots = await _loadData();
    yield allLots;
  }

  modalBottomSheet() {
    showModalBottomSheet<void>(
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 400,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    child: _selectLot != null
                        ? ListTile(
                            title: Text(
                                '${_selectLot['inventory_text'] ?? 'Not selected'}'),
                            subtitle: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Lot: ${_selectLot['lot_label'] ?? 'Not selected'}'),
                                Text(
                                    'Quantité Ancienne: ${_selectLot['oldQuantity'] ?? 'Not selected'}')
                              ],
                            ),
                          )
                        : null,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Quantité',
                      ),
                      onChanged: (value) {
                        var qty = int.parse(value ?? '0');
                        Provider.of<ExitMovement>(context, listen: false)
                            .setLot(_selectLot['index'], 'quantity', qty);
                        Provider.of<ExitMovement>(context, listen: false)
                            .setLot(_selectLot['index'], 'difference',
                                qty - _selectLot['oldQuantity']);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir la quantité';
                        }
                        if (int.parse(value) < 0) {
                          return 'Veuillez saisir un nombre positive';
                        }
                        return null;
                      },
                      controller: _txtQuantity,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    child: FilledButton(
                      onPressed: _txtQuantity.text == ''
                          ? null
                          : () {
                              _onClose();
                              Navigator.pop(context);
                            },
                      style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.blueAccent)),
                      child: const Text('Soumettre'),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  _onEditLot(dynamic value, int i) {
    setState(() {
      _selectLot = {'index': i, ...value};
      isShowBottomSheet = true;
    });
    _txtQuantity.text = (value['quantity'] ?? 0).toString();
    modalBottomSheet();
  }

  void _onClose() {
    setState(() {
      _selectLot = {};
      isShowBottomSheet = false;
    });
    _txtQuantity.text = '0';
  }

  Future batchInsertMovements(var lots) async {
    var date = DateTime.now();
    var movementUuid = _uuid.v4();
    final allLots = await Lot.inventories(database, _selectedDepotUuid);
    List<StockMovement> movements = [];
    lots.forEach((element) async {
      if (element != null &&
          element['lot_uuid'] != null &&
          element['quantity'] > 0) {
        var lot = allLots.where((lt) => lt.uuid == element['lot_uuid']).first;
        var movement = StockMovement(
          uuid: _uuid.v4(),
          movementUuid: movementUuid,
          depotUuid: _selectedDepotUuid,
          inventoryUuid: element['inventory_uuid'],
          lotUuid: element['lot_uuid'],
          reference: '',
          entityUuid: _selectedDepotUuid,
          periodId: int.parse(formatDate(date, [yyyy, mm])),
          userId: _userId,
          fluxId: INVENTORY_ADJUSTMENT,
          isExit: 1,
          date: date,
          description:
              'Ajustement de stock ${element['inventory_text']} - ${element['lot_label']}',
          quantity: element['quantity'],
          oldQuantity: element['oldQuantity'] ?? 0,
          unitCost: element['unit_cost'].toDouble(),
        );
        movements.add(movement);
        lot.quantity = element['quantity'];

        await Lot.updateLot(database, lot);
      }
    });
    await StockMovement.txInsertMovement(database, movements);
  }

  onSubmit() {
    var lots = Provider.of<ExitMovement>(context, listen: false).lots;
    batchInsertMovements(lots).then((value) {
      var snackBar = const SnackBar(
        content: Text('Ajustement de stock réussie ✅'),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      // reset the provider
      Provider.of<ExitMovement>(context, listen: false).reset();

      // back to home
      Navigator.pushNamed(context, '/home');
      // ignore: body_might_complete_normally_catch_error
    });
  }

  @override
  Widget build(BuildContext context) {
    var streamBuilder = StreamBuilder<List>(
      stream: _streamLots,
      builder: ((context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        } else if (snapshot.hasData) {
          return Column(
            children: <Widget>[
              Expanded(
                child: createListView(context, snapshot),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton(
                  onPressed: () {
                    onSubmit();
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Soumettre'),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustement des stocks'),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    List values = snapshot.data ?? [];
    return ListView.builder(
      itemCount: values.length,
      itemBuilder: ((context, index) {
        return Column(
          children: <Widget>[
            Card(
              // width: screenWidth,
              // height: screenHeight / 4,
              elevation: 0.5,
              child: Column(
                children: [
                  ListTile(
                      title: Text('${values[index]['inventory_text']}'),
                      subtitle: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lot: ${values[index]['lot_label']}'),
                        ],
                      ),
                      trailing: FilledButton(
                        onPressed: () {
                          _onEditLot(values[index], index);
                        },
                        child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.spaceBetween,
                            runSpacing: 4.6,
                            children: [
                              Text('Qty: ${values[index]['quantity']}'),
                              Icon(Icons.edit_square),
                            ]),
                      )),
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
        ? toBeginningOfSentenceCase(formatter.format(rawExpirationDate))
        : null;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.spaceBetween,
            spacing: 3.0,
            children: [
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
              Chip(
                label: Text(
                  'Qty(Ancien): ${value['oldQuantity']}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Chip(
                label: Text('Diff: ${value['difference']}'),
              ),
            ],
          ),
        ));
  }
}
