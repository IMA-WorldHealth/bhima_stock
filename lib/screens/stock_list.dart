import 'package:bhima_collect/models/lot.dart';
import 'package:bhima_collect/services/db.dart';
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

  Future<List<Lot>> _loadLots() async {
    List<Lot> allLots = await Lot.lots(database);
    return allLots
        .where((element) => element.depot_uuid == _selectedDepotUuid)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder for list of lots
    var futureBuilder = FutureBuilder<List<Lot>>(
      future: _loadLots(),
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
              return createListView(context, snapshot);
            } else {
              return const Center(child: CircularProgressIndicator());
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
      body: futureBuilder,
    );
  }

  Widget createListView(
      BuildContext context, AsyncSnapshot<List<Lot>> snapshot) {
    List<Lot> values = snapshot.data ?? [];
    return ListView.builder(
      itemCount: values.length,
      itemBuilder: ((context2, index) {
        return Column(
          children: <Widget>[
            Card(
              elevation: 1,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Column(
                children: [
                  ListTile(
                    title: Text('${values[index].text}'),
                    subtitle: Text('Code: ${values[index].code}'),
                  ),
                  createLotChip(values[index]),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    child: Row(
                      children: [
                        Chip(
                          backgroundColor: Colors.green[200],
                          label: Text(
                              'Qty: ${values[index].quantity} ${values[index].unit_type}'),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        );
      }),
    );
  }

  Widget createLotChip(value) {
    String expirationDate = value.expiration_date != null
        ? formatDate(value.expiration_date, [MM, '-', yyyy])
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: [
          Chip(
            label: Text('Lot: ${value.label}'),
          ),
          if (value.expiration_date != null)
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
