import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/models/stock_movement.dart';
import 'package:bhima_collect/providers/exit_movement.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:uuid/uuid.dart';
import 'package:darq/darq.dart';
import 'package:intl/intl.dart';

class StockLossPage extends StatefulWidget {
  const StockLossPage({super.key});

  @override
  State<StockLossPage> createState() => _StockLossPageState();
}

class _StockLossPageState extends State<StockLossPage> {
  var database = BhimaDatabase.open();
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  // ignore: non_constant_identifier_names
  final _STOCK_TO_LOSS = 11;
  final PageController _controller = PageController(
    initialPage: 0,
  );

  final TextEditingController _txtDate = TextEditingController();
  final TextEditingController _txtDescription = TextEditingController();
  final TextEditingController _txtQuantity = TextEditingController();

  var formatter = DateFormat.yMMMMd('fr_FR');
  String _selectedDepotUuid = '';
  String _selectedDepotText = '';
  int? _userId;
  // bool _savingSucceed = false;

  DateTime _selectedDate = DateTime.now();
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
    _txtDescription.dispose();
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
                  Provider.of<ExitMovement>(context, listen: false)
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
        title: const Text('Perte de stock'),
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
      child: stockExitStartPage(),
    ));

    // Lots pages
    num count = Provider.of<ExitMovement>(context, listen: false).totalItems;
    // clear previous lots array
    Provider.of<ExitMovement>(context, listen: false).clear();
    // create page view according totalItems expected
    for (var i = 0; i < count; i++) {
      Provider.of<ExitMovement>(context, listen: false).addLot({});
      pages.add(Padding(
        padding: const EdgeInsets.all(16.0),
        child: lotExitPage(i),
      ));
    }

    // Introduction page
    pages.add(Padding(
      padding: const EdgeInsets.all(16.0),
      child: submitPage(),
    ));

    return pages;
  }

  Widget inventoryTypeaheadField(int index) {
    final TextEditingController typeAheadController = TextEditingController();
    Future<List> loadInventories(String pattern) async {
      List currentInventories =
          await StockMovement.stockQuantityDepot(database, _selectedDepotUuid);
      return currentInventories
          .distinct((element) => element['inventory_uuid'])
          .where((element) =>
              element['text']!.toLowerCase().contains(pattern.toLowerCase()) ==
                  true ||
              element['code']!.toLowerCase().contains(pattern.toLowerCase()) ==
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
      itemBuilder: (context, dynamic suggestion) {
        return Column(
          children: [
            ListTile(
              title: Text(suggestion['text'] ?? ''),
              subtitle: Text(suggestion['code'] ?? ''),
            ),
            const Divider(
              height: 2,
            )
          ],
        );
      },
      onSuggestionSelected: (dynamic suggestion) {
        typeAheadController.text = suggestion['text'] ?? '';
        Provider.of<ExitMovement>(context, listen: false)
            .setLot(index, 'inventory_uuid', suggestion['inventory_uuid']);
        Provider.of<ExitMovement>(context, listen: false)
            .setLot(index, 'inventory_text', suggestion['text']);
      },
    );
  }

  Widget lotTypeaheadField(int index) {
    final TextEditingController lotTypeAheadController =
        TextEditingController();

    Future<List> loadInventoryLots(String pattern) async {
      var inventoryUuid = Provider.of<ExitMovement>(context, listen: false)
          .getLotValue(index, 'inventory_uuid');

      List currentLots =
          await StockMovement.stockQuantityDepot(database, _selectedDepotUuid);
      return currentLots
          .where((element) =>
              element['inventory_uuid'] == inventoryUuid &&
              element['quantity'] > 0)
          .where((element) =>
              element['label']!.toLowerCase().contains(pattern.toLowerCase()) ==
              true)
          .toList();
    }

    return TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        controller: lotTypeAheadController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Lot'),
      ),
      suggestionsCallback: (pattern) async {
        return await loadInventoryLots(pattern);
      },
      itemBuilder: (context, dynamic suggestion) {
        String exp = suggestion['expiration_date'] == null ||
                suggestion['expiration_date'] == 'null'
            ? ''
            : '/ Exp. ${suggestion['expiration_date'].toString()}';
        return Column(
          children: [
            ListTile(
              title: Text(suggestion['label'] ?? ''),
              subtitle: Text('Quantité: ${suggestion['quantity']} $exp'),
            ),
            const Divider(
              height: 2,
            )
          ],
        );
      },
      onSuggestionSelected: (dynamic suggestion) {
        lotTypeAheadController.text = suggestion['label'] ?? '';
        Provider.of<ExitMovement>(context, listen: false)
            .setLot(index, 'lot_uuid', suggestion['lot_uuid']);
        Provider.of<ExitMovement>(context, listen: false)
            .setLot(index, 'lot_label', suggestion['label']);
        Provider.of<ExitMovement>(context, listen: false)
            .setLot(index, 'unit_cost', suggestion['unit_cost']);
        Provider.of<ExitMovement>(context, listen: false)
            .setLot(index, 'max_quantity', suggestion['quantity']);
      },
    );
  }

  Widget stockExitStartPage() {
    String formattedSelectedDate = formatter.format(_selectedDate);

    Future selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate, // Refer step 1
        firstDate: DateTime(2000),
        lastDate: DateTime(2050),
      );
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
          formattedSelectedDate = formatter.format(_selectedDate);
        });
      }
    }

    return Column(
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: () => selectDate(context).then(
            (_) {
              Provider.of<ExitMovement>(context, listen: false).setDate =
                  _selectedDate;
            },
          ),
          icon: const Icon(Icons.date_range_sharp),
          label: Text(formattedSelectedDate),
        ),
        TextFormField(
          controller: _txtDescription,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Raison de la perte",
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Veuillez saisir la raison de la perte";
            }
            return null;
          },
        ),
        TextFormField(
          controller: _txtQuantity,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: "Nombre d'items",
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Veuillez saisir le nombre des items";
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

  Widget lotExitPage(int index) {
    var txtQuantity = TextEditingController();
    var totalItems =
        Provider.of<ExitMovement>(context, listen: false).totalItems;
    return Column(
      children: <Widget>[
        Text('Item ${index + 1} sur $totalItems'),
        inventoryTypeaheadField(index),
        lotTypeaheadField(index),
        TextFormField(
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Quantity',
          ),
          onChanged: (value) {
            Provider.of<ExitMovement>(context, listen: false)
                .setLot(index, 'quantity', value);
          },
          validator: (value) {
            var maxQuantity = Provider.of<ExitMovement>(context, listen: false)
                .getLotValue(index, 'max_quantity');
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir la quantité';
            }
            if (int.parse(value) > maxQuantity) {
              return 'Quantité maximum atteint ($maxQuantity)';
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
    var date = Provider.of<ExitMovement>(context, listen: false).date;
    var totalItems =
        Provider.of<ExitMovement>(context, listen: false).totalItems;
    var lots = Provider.of<ExitMovement>(context).lots;

    Future batchInsertMovements(var lots) async {
      var movementUuid = _uuid.v4();
      final allLots = await Lot.inventories(database, _selectedDepotUuid);
      List<StockMovement> movements = [];

      lots.forEach((element) async {
        if (element != null && element['lot_uuid'] != null) {
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
            fluxId: _STOCK_TO_LOSS,
            isExit: 1,
            date: date,
            description: 'PERTE DE STOCK\n ${_txtDescription.text}',
            quantity: int.parse(element['quantity'] ?? 0),
            unitCost: element['unit_cost'].toDouble(),
          );
          movements.add(movement);
          var quantity = (int.parse(lot.quantity.toString()) -
              int.parse(element['quantity'] ?? 0));
          lot.quantity = quantity;
          await Lot.updateLot(database, lot);
        }
      });

      await StockMovement.txInsertMovement(database, movements);
    }

    Future<dynamic> save() {
      return batchInsertMovements(lots).then((value) {
        var snackBar = const SnackBar(
          content: Text('Perte de stock réussie ✅'),
        );

        // Find the ScaffoldMessenger in the widget tree
        // and use it to show a SnackBar.
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        // reset the provider
        Provider.of<ExitMovement>(context, listen: false).reset();

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
                return ListTile(
                  title: Text(value['inventory_text'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value['lot_label'] ?? ''),
                    ],
                  ),
                  trailing: Chip(label: Text(value['quantity'] ?? '')),
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
