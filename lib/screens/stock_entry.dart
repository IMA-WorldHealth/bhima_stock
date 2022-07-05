import 'package:bhima_collect/providers/entry_movement.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockEntryPage extends StatefulWidget {
  StockEntryPage({Key? key}) : super(key: key);

  @override
  State<StockEntryPage> createState() => _StockEntryPageState();
}

class _StockEntryPageState extends State<StockEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _controller = PageController(
    initialPage: 0,
  );
  String _selectedDepotUuid = '';
  String _selectedDepotText = '';
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
    super.dispose();
  }

  //Loading saved selected depot
  Future<void> _loadSavedDepot() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDepotUuid = (prefs.getString('selected_depot_uuid') ?? '');
      _selectedDepotText = (prefs.getString('selected_depot_text') ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> getPages() {
      List<Widget> pages = [];

      // Introduction page
      pages.add(Padding(
        padding: const EdgeInsets.all(16.0),
        child: stockEntryStartPage(),
      ));

      // Lots pages
      Provider.of<EntryMovement>(context).createLots();
      for (var i = 0; i < Provider.of<EntryMovement>(context).totalItems; i++) {
        pages.add(Padding(
          padding: const EdgeInsets.all(16.0),
          child: lotEntryPage(i),
        ));
      }

      return pages;
    }

    var pageBody = Column(
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

    var globalForm = Form(
      key: _formKey,
      child: pageBody,
    );

    Widget pageBottom() => Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _controller.previousPage(
                      duration: _kDuration, curve: _kCurve);
                },
                label: const Text('Retour'),
                icon: const Icon(Icons.arrow_left_outlined),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _controller.nextPage(duration: _kDuration, curve: _kCurve);
                },
                label: const Text('Suivant'),
                icon: const Icon(Icons.arrow_right_outlined),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrée de stock'),
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
      body: globalForm,
      bottomNavigationBar: pageBottom(),
    );
  }

  Widget stockEntryStartPage() {
    DateTime selectedDate = DateTime.now();
    TextEditingController txtDate = TextEditingController();
    var customDateFormat = [dd, ' ', MM, ' ', yyyy];

    txtDate.text = formatDate(selectedDate, customDateFormat);

    Future _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate, // Refer step 1
        firstDate: DateTime(2000),
        lastDate: DateTime(2025),
      );
      if (picked != null && picked != selectedDate) {
        selectedDate = picked;
        txtDate.text = formatDate(selectedDate, customDateFormat);
      }
    }

    return Column(
      children: <Widget>[
        TextFormField(
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Ref. Bon de sortie',
          ),
          onChanged: (value) {
            Provider.of<EntryMovement>(context, listen: false)
                .setDocumentReference = value;
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir la reference du bon de sortie';
            }
            return null;
          },
          // controller: txtDocumentLabel,
        ),
        TextFormField(
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Date',
          ),
          controller: txtDate,
          enabled: false,
        ),
        ElevatedButton.icon(
          onPressed: () => _selectDate(context),
          icon: const Icon(Icons.date_range_sharp),
          label: const Text('Choisissez la date'),
        ),
        TextFormField(
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: "Nombre d'items",
          ),
          onChanged: (value) {
            if (int.parse(value).runtimeType == int) {
              Provider.of<EntryMovement>(context, listen: false).setTotalItems =
                  int.parse(value);
            }
          },
        ),
        ElevatedButton(
            onPressed: () {
              // Validate returns true if the form is valid, or false otherwise.
              if (_formKey.currentState!.validate()) {
                // If the form is valid, display a snackbar. In the real world,
                // you'd often call a server or save the information in a database.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Saisie de ${Provider.of<EntryMovement>(context).totalItems} items')),
                );
              }
            },
            child: const Text('Valider'))
      ],
    );
  }

  Widget lotEntryPage(int index) {
    var txtInventory = TextEditingController();
    var txtLot = TextEditingController();
    var txtQuantity = TextEditingController();
    var lotIndex = index;
    return Column(
      children: <Widget>[
        TextFormField(
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Inventory',
          ),
          onChanged: (value) {
            Provider.of<EntryMovement>(context, listen: false)
                .setLot(lotIndex, 'inventory_uuid', value);
          },
          controller: txtInventory,
        ),
        TextFormField(
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Lot',
          ),
          onChanged: (value) {
            Provider.of<EntryMovement>(context, listen: false)
                .setLot(lotIndex, 'lot_uuid', value);
          },
          controller: txtLot,
        ),
        TextFormField(
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Quantity',
          ),
          onChanged: (value) {
            Provider.of<EntryMovement>(context, listen: false)
                .setLot(lotIndex, 'quantity', value);
          },
          controller: txtQuantity,
        ),
      ],
    );
  }
}
