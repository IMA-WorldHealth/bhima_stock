import 'package:bhima_collect/models/inventory.dart';
import 'package:bhima_collect/models/inventory_lot.dart';
import 'package:bhima_collect/utilities/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:math' as math;
import 'package:bhima_collect/providers/entry_movement.dart';
import 'package:bhima_collect/models/stock_movement.dart';
import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/services/db.dart';

class StockEntryIntegration extends StatefulWidget {
  const StockEntryIntegration({super.key});

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
  // bool _savingSucceed = false;

  DateTime _selectedDate = DateTime.now();
  var formatter = DateFormat.yMMMMd('fr_FR');
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
    var pageViews = Column(
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Integration de stock'),
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
    Future<List<Inventory>> loadInventories(String pattern) async {
      List<Inventory> allIventory = await Inventory.inventories(database);
      return allIventory
          .where((element) =>
              element.label!.toLowerCase().contains(pattern.toLowerCase()) ==
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
        return loadInventories(pattern);
      },
      itemBuilder: (context, Inventory suggestion) {
        return Column(
          children: [
            ListTile(
              title: Text(suggestion.label ?? ''),
              subtitle: Text(suggestion.code ?? ''),
            ),
            const Divider(
              height: 2,
            )
          ],
        );
      },
      onSuggestionSelected: (Inventory suggestion) {
        typeAheadController.text = suggestion.label ?? '';
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'inventory_uuid', suggestion.uuid);
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'inventory_text', suggestion.label);
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'inventory_code', suggestion.code);
        Provider.of<EntryMovement>(context, listen: false)
            .setLot(index, 'unit_type', suggestion.type);
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
    String formattedSelectedDate = formatter.format(_selectedDate);

    Future selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate, // Refer step 1
          firstDate: DateTime(2000),
          lastDate: DateTime(2050),
          locale: const Locale('fr', 'FR'));
      if (picked != null && picked != _selectedDate) {
        _selectedDate = picked;
        formattedSelectedDate = formatter.format(_selectedDate);
        _txtDate.text = formattedSelectedDate;
        // ignore: use_build_context_synchronously
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
              await selectDate(context);
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
          lastDate: DateTime(2050),
          locale: const Locale('fr', 'FR'));
      if (picked != null && picked.compareTo(DateTime.now()) > 0) {
        // be sure the picked date is in the future
        expirationDate = picked;
        var hrFormattedExpirationDate = formatter.format(expirationDate);
        txtExpirationDate.text = hrFormattedExpirationDate;
        // ignore: use_build_context_synchronously
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [DecimalTextInputFormatter(decimalRange: 8)]),
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
      List<StockMovement> movements = [];
      List<Lot> batch = [];

      lots.forEach((element) {
        if (element != null && element['lot_uuid'] != null) {
          String uniCost = element['unit_cost'].toString();
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
            unit_cost: double.parse(
                uniCost.contains(',') ? uniCost.replaceAll(",", ".") : uniCost),
            quantity: int.parse(element['quantity']),
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
            unitCost: double.parse(
                uniCost.contains(',') ? uniCost.replaceAll(",", ".") : uniCost),
          );
          batch.add(lot);
          movements.add(movement);
        }
      });

      /* use the transaction, if you have a array of data to record,
      * for good performance
      */
      // insert lot
      await Lot.txInsertLot(database, batch);

      // insert the movement
      await StockMovement.txInsertMovement(database, movements);
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
        Navigator.pushNamed(context, '/home');

        return true;
      });
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 0),
            child: Text('Date: ${formatter.format(date)}'),
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

                dynamic rawExpirationDate;
                if (value['expiration_date'].runtimeType == String) {
                  rawExpirationDate = parseDate(value['expiration_date']);
                } else {
                  rawExpirationDate = value['expiration_date'];
                }

                dynamic expirationDate = rawExpirationDate != null
                    ? formatter.format(rawExpirationDate)
                    : '-';
                var unitCost = value['unit_cost'] ?? 0;
                return ListTile(
                  title: Text(value['inventory_text'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value['lot_label'] ?? ''),
                      Text('Expiration : $expirationDate'),
                      Text('Coût unitaire : $unitCost'),
                    ],
                  ),
                  trailing: Chip(label: Text(value['quantity'] ?? '0')),
                );
              } else {
                return const Row();
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

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({required this.decimalRange})
      // ignore: unnecessary_null_comparison
      : assert(decimalRange == null || decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;

    // ignore: unnecessary_null_comparison
    if (decimalRange != null) {
      String value = newValue.text;

      if (value.contains(".") &&
          value.substring(value.indexOf(".") + 1).length > decimalRange) {
        truncated = oldValue.text;
        newSelection = oldValue.selection;
      } else if (value == ".") {
        truncated = "0.";

        newSelection = newValue.selection.copyWith(
          baseOffset: math.min(truncated.length, truncated.length + 1),
          extentOffset: math.min(truncated.length, truncated.length + 1),
        );
      }

      return TextEditingValue(
        text: truncated,
        selection: newSelection,
        composing: TextRange.empty,
      );
    }
    return newValue;
  }
}
