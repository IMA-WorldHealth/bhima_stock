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
  Future<List<dynamic>>? _depotFuture;
  List<Depot> _depots = [];
  List<Depot> _filterDepot = [];

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
      _filterDepot = _depots
          .where((element) => element.text.toLowerCase().contains(value))
          .toList();
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
    var d = await Depot.depots(database);
    setState(() {
      _depots = d;
      _filterDepot = d;
    });
    return Depot.depots(database);
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
        future: _depotFuture,
        builder: (context, snapshot) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            List values = _filterDepot;
            return Padding(
              padding: const EdgeInsets.all(0.0),
              child: Column(children: <Widget>[
                CardBhima(
                  width: screenWidth,
                  height: screenHeight / 13,
                  borderOnForeground: false,
                  elevation: 2,
                  clipBehavior: Clip.hardEdge,
                  child: SearchBhima(
                    onSearch: _onSeach,
                    searchController: _searchCtrller,
                  ),
                ),
                Expanded(
                    child: ListView.builder(
                        itemCount: _filterDepot.length,
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

          // Expanded(
          //         child: ListView(
          //           children: <Widget>[
          //             Padding(
          //                 padding: const EdgeInsets.all(10.0),
          //                 child: FormBuilder(
          //                   key: _formKey,
          //                   // enabled: false,
          //                   onChanged: () {
          //                     _formKey.currentState!.save();
          //                   },
          //                   autovalidateMode: AutovalidateMode.disabled,
          //                   skipDisabled: true,
          //                   child: Column(
          //                     children: <Widget>[
          //                       FormBuilderRadioGroup<dynamic>(
          //                         decoration: const InputDecoration(
          //                           labelText: 'Choisissez votre depot',
          //                           alignLabelWithHint: false,
          //                           border: InputBorder.none,
          //                         ),
          //                         orientation: OptionsOrientation.vertical,
          //                         initialValue: _selectedDepotUuid,
          //                         name: 'selected_depot_uuid',
          //                         onChanged: _onChanged,
          //                         validator: FormBuilderValidators.compose(
          //                             [FormBuilderValidators.required()]),
          //                         options: (snapshot.data ?? [])
          //                             .map((depot) => FormBuilderFieldOption(
          //                                   value: depot.uuid,
          //                                   child: Text(depot.text),
          //                                 ))
          //                             .toList(growable: true),
          //                         controlAffinity: ControlAffinity.trailing,
          //                       ),
          //                     ],
          //                   ),
          //                 ))
          //           ],
          //         ),
          //       ),