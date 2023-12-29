import 'package:bhima_collect/components/card_bhima.dart';
import 'package:bhima_collect/components/search_bhima.dart';
import 'package:bhima_collect/models/depot.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigureDepotPage extends StatefulWidget {
  const ConfigureDepotPage({super.key});

  @override
  State<ConfigureDepotPage> createState() => _ConfigureDepotPageState();
}

class _ConfigureDepotPageState extends State<ConfigureDepotPage> {
  var database = BhimaDatabase.open();
  String _selectedDepotUuid = '';
  String _selectedDepotText = '';
  final TextEditingController _searchCtrller = TextEditingController();
  String _textDepot = '';
  Future<List<dynamic>>? _depotFuture;

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
      _selectedDepotUuid = (prefs.getString('selected_depot_uuid') ?? '');
      _selectedDepotText = (prefs.getString('selected_depot_text') ?? '');
    });
  }

  // handle change on option choice
  Future<void> _onChanged(dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    List<Depot> userDepots = await _loadDepots();
    Depot userSelectedDepot = userDepots
        .where((element) => element.uuid == val.uuid.toString())
        .toList()[0];
    setState(() {
      _selectedDepotUuid = userSelectedDepot.uuid;
      _selectedDepotText = userSelectedDepot.text;
    });
    await prefs.setString('selected_depot_uuid', _selectedDepotUuid);
    await prefs.setString('selected_depot_text', _selectedDepotText);
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
                                          Icon(
                                              values[index].uuid ==
                                                      _selectedDepotUuid
                                                  ? Icons.check_circle
                                                  : Icons.circle_outlined,
                                              color: values[index].uuid ==
                                                      _selectedDepotUuid
                                                  ? Colors.blue
                                                  : Colors.black)
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
}
