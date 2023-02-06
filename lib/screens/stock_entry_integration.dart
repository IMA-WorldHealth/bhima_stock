import 'package:bhima_collect/models/inventory_lot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:bhima_collect/providers/entry_movement.dart';
import 'package:bhima_collect/models/stock_movement.dart';
import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/services/db.dart';

import '../components/card_bhima.dart';

class StockEntryIntegration extends StatefulWidget {
  const StockEntryIntegration({Key? key}) : super(key: key);

  @override
  State<StockEntryIntegration> createState() => _StockEntryIntegrationState();
}

class _StockEntryIntegrationState extends State<StockEntryIntegration> {
  var database = BhimaDatabase.open();
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  final _stockFromIntegration = 13;
  final PageController _controller = PageController(
    initialPage: 0,
  );

  final TextEditingController _txtDate = TextEditingController();
  final TextEditingController _txtQuantity = TextEditingController();

  String _selectedDepotUuid = '';
  String _selectedDepotText = '';
  int? _userId;
  bool _savingSucceed = false;

  DateTime _selectedDate = DateTime.now();
  final _customDateFormat = [dd, ' ', MM, ' ', yyyy];
  static const _kDuration = Duration(milliseconds: 300);
  static const _kCurve = Curves.ease;

  @override
  void initState() {
    super.initState();
    _loadSavedDepot();
  }

  @override
  void dispose() {
    _controller.dispose();
    _txtDate.dispose();
    _txtQuantity.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    var pageViews = Column(
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
          child: PageView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            children: getPages(),
          ),
        ),
      ],
    );

    var pageBody = Form(
      key: _formKey,
      child: pageViews,
    );

    var pageBottom = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              _controller.previousPage(duration: _kDuration, curve: _kCurve);
            },
            label: const Text('Retour'),
            icon: const Icon(Icons.arrow_left_outlined),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Validate returns true if the form is valid, or false otherwise.
              if (_formKey.currentState!.validate()) {
                if (_controller.page == 0) {
                  Provider.of<EntryMovement>(context, listen: false)
                      .setTotalItems = int.parse(_txtQuantity.text);
                }
                _controller.nextPage(duration: _kDuration, curve: _kCurve);
              }
            },
            label: const Text('Suivant'),
            icon: const Icon(Icons.arrow_right_outlined),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 183, 193, 203),
        title: const Text(
          'Integration de stock',
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
      body: pageBody,
      bottomNavigationBar: pageBottom,
    );
  }

  List<Widget> getPages() {
    List<Widget> pages = [];

    // Introduction page
    pages.add(Padding(
      padding: const EdgeInsets.all(16.0),
      child: stockEntryStartPage(),
    ));

    // Lots pages
    num count = Provider.of<EntryMovement>(context, listen: false).totalItems;
    // clear previous lots array
    Provider.of<EntryMovement>(context, listen: false).clear();
    // create page view according totalItems expected
    for (var i = 0; i < count; i++) {
      Provider.of<EntryMovement>(context, listen: false).addLot({});
      pages.add(Padding(
        padding: const EdgeInsets.all(16.0),
        child: lotEntryPage(i),
      ));
    }

    // Summary page
    pages.add(Padding(
      padding: const EdgeInsets.all(16.0),
      child: submitPage(),
    ));

    return pages;
  }

  Widget inventoryTypeaheadField(int index) {
    final TextEditingController typeAheadController = TextEditingController();
    Future<List<Lot>> _loadInventories(String pattern) async {
      List<Lot> allLots = await Lot.inventories(database, _selectedDepotUuid);
      return allLots
          .where((element) =>
              element.text!.toLowerCase().contains(pattern.toLowerCase()) ==
              true)
          .toList();
    }

    return TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        controller: typeAheadController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Inventaire'),
      ),
      suggestionsCallback: (pattern) async {
        return _loadInventories(pattern);
      },
      itemBuilder: (context, Lot suggestion) {
        return Column(
          children: [
            ListTile(
              title: Text(suggestion.text ?? ''),
              subtitle: Text(suggestion.code ?? ''),
            ),
            const Divider(
              height: 2,
            )
          ],
        );
      },
      onSuggestionSelected: (Lot suggestion) {
        typeAheadController.text = suggestion.text ?? '';
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'inventory_uuid', suggestion.inventory_uuid);
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'inventory_text', suggestion.text);
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'inventory_code', suggestion.code);
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'unit_type', suggestion.unit_type);
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'group_name', suggestion.group_name);
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'manufacturer_brand', suggestion.manufacturer_brand);
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'manufacturer_model', suggestion.manufacturer_model);
      },
    );
  }

  Widget stockEntryStartPage() {
    String formattedSelectedDate = formatDate(_selectedDate, _customDateFormat);

    Future _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate, // Refer step 1
        firstDate: DateTime(2000),
        lastDate: DateTime(2030),
      );
      if (picked != null && picked != _selectedDate) {
        _selectedDate = picked;
        formattedSelectedDate = formatDate(_selectedDate, _customDateFormat);
        _txtDate.text = formattedSelectedDate;
        Provider.of<EntryMovement>(context, listen: false).setDate =
            _selectedDate;
      }
    }

    return Column(
      children: <Widget>[
        TextField(
            controller: _txtDate, //editing controller of this TextField
            decoration: const InputDecoration(
                labelText: "Date de l'integration" //label text of field
                ),
            readOnly: true, // when true user cannot edit text
            onTap: () async {
              //when click we have to show the datepicker
              await _selectDate(context);
            }),
        TextFormField(
          controller: _txtQuantity,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: "Nombre d'items",
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Veuillez saisir le nombre des lots";
            }
            return null;
          },
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly
          ],
        ),
      ],
    );
  }

  Widget lotEntryPage(int index) {
    var txtQuantity = TextEditingController();
    var txtLabel = TextEditingController();
    var txtExpirationDate = TextEditingController();
    var txtUnitCost = TextEditingController();
    var totalItems =
        Provider.of<EntryMovement>(context, listen: false).totalItems;

    DateTime expirationDate = DateTime.now();

    Future selectExpirationDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2030),
      );
      if (picked != null && picked.compareTo(DateTime.now()) > 0) {
        // be sure the picked date is in the future
        expirationDate = picked;
        var hrFormattedExpirationDate =
            formatDate(expirationDate, _customDateFormat);
        txtExpirationDate.text = hrFormattedExpirationDate;
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'expiration_date', expirationDate);
      }
    }

    return Column(
      children: <Widget>[
        Text('Item ${index + 1} sur $totalItems'),
        inventoryTypeaheadField(index),
        TextFormField(
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Libellé du lot',
          ),
          onChanged: (value) {
            Provider.of<EntryMovement>(context, listen: false)
                .setLot(index, 'lot_label', value);
            Provider.of<EntryMovement>(context, listen: false).setLot(index,
                'lot_uuid', _uuid.v4().replaceAll('-', '').toUpperCase());
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir le numero du lot';
            }
            return null;
          },
          controller: txtLabel,
        ),
        TextField(
            controller:
                txtExpirationDate, //editing controller of this TextField
            decoration: const InputDecoration(
                labelText: "Date d'expiration" //label text of field
                ),
            readOnly: true, // when true user cannot edit text
            onTap: () async {
              //when click we have to show the datepicker
              await selectExpirationDate(context);
            }),
        TextFormField(
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Coût unitaire',
          ),
          onChanged: (value) {
            Provider.of<EntryMovement>(context, listen: false)
                .setLot(index, 'unit_cost', value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir le cout unitaire';
            }
            return null;
          },
          controller: txtUnitCost,
          keyboardType: TextInputType.number,
        ),
        TextFormField(
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Quantity',
          ),
          onChanged: (value) {
            Provider.of<EntryMovement>(context, listen: false)
                .setLot(index, 'quantity', value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir la quantité';
            }
            return null;
          },
          controller: txtQuantity,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly
          ],
        ),
      ],
    );
  }

  Widget submitPage() {
    var documentReference =
        Provider.of<EntryMovement>(context, listen: false).documentReference;
    var date = Provider.of<EntryMovement>(context, listen: false).date;
    var totalItems =
        Provider.of<EntryMovement>(context, listen: false).totalItems;
    var lots = Provider.of<EntryMovement>(context).lots;

    Future batchInsertMovements(var lots) async {
      var movementUuid = _uuid.v4();
      return lots.forEach((element) async {
        if (element != null && element['lot_uuid'] != null) {
          var lot = Lot(
            uuid: element['lot_uuid'],
            label: element['lot_label'],
            lot_description: element['lot_label'],
            code: element['inventory_code'],
            inventory_uuid: element['inventory_uuid'],
            text: element['inventory_text'],
            unit_type: element['unit_type'],
            group_name: element['group_name'],
            depot_text: _selectedDepotText,
            depot_uuid: _selectedDepotUuid,
            is_asset: 0,
            barcode: '',
            serial_number: '',
            reference_number: '',
            manufacturer_brand: element['manufacturer_brand'],
            manufacturer_model: element['manufacturer_model'],
            unit_cost: double.parse(element['unit_cost']),
            quantity: 0, // previous quantity set to zero
            avg_consumption: 0,
            exhausted: false,
            expired: false,
            near_expiration: false,
            expiration_date: element['expiration_date'],
            entry_date: date,
          );
          var movement = StockMovement(
            uuid: _uuid.v4(),
            movementUuid: movementUuid,
            depotUuid: _selectedDepotUuid,
            inventoryUuid: element['inventory_uuid'],
            lotUuid: element['lot_uuid'],
            reference: documentReference,
            entityUuid: '',
            periodId: int.parse(formatDate(date, [yyyy, mm])),
            userId: _userId,
            fluxId: _stockFromIntegration,
            isExit: 0,
            date: date,
            description: 'INTEGRATION',
            quantity: int.parse(element['quantity']),
            unitCost: double.parse(element['unit_cost']),
          );
          // insert lot
          await Lot.insertLot(database, lot);
          // insert movement
          await StockMovement.insertMovement(database, movement);
        }
      });
    }

    Future<dynamic> save() {
      return batchInsertMovements(lots).then((value) async {
        // import into inventory_lot and inventory table
        return InventoryLot.import(database);
      }).then((value) {
        var snackBar = const SnackBar(
          content: Text('Integration de stock réussie ✅'),
        );

        // Find the ScaffoldMessenger in the widget tree
        // and use it to show a SnackBar.
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        // reset the provider
        Provider.of<EntryMovement>(context, listen: false).reset();

        // back to home
        Navigator.pushNamed(context, '/');

        setState(() {
          _savingSucceed = true;
        });

        return true;
      });
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 0),
            child: Text('Date: ${formatDate(date, _customDateFormat)}'),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Nombre des items: $totalItems'),
          ),
          Expanded(
              child: ListView.builder(
            itemCount: lots.length,
            itemBuilder: (context, index) {
              if (lots.isNotEmpty && lots[index] != null) {
                var value = lots[index];
                return ListTile(
                  title: Text(value['inventory_text']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value['lot_label']),
                      Text(
                          'Expiration : ${formatDate(value['expiration_date'], _customDateFormat)}'),
                      Text('Coût unitaire : ${value['unit_cost']}'),
                    ],
                  ),
                  trailing: Chip(label: Text(value['quantity'])),
                );
              } else {
                return Row();
              }
            },
          )),
          ElevatedButton.icon(
            onPressed: () => save(),
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
