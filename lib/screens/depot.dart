import 'package:bhima_collect/models/depot.dart';
import 'package:bhima_collect/services/db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigureDepotPage extends StatefulWidget {
  const ConfigureDepotPage({Key? key}) : super(key: key);

  @override
  State<ConfigureDepotPage> createState() => _ConfigureDepotPageState();
}

class _ConfigureDepotPageState extends State<ConfigureDepotPage> {
  var database = BhimaDatabase.open();
  final _formKey = GlobalKey<FormBuilderState>();
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

  // handle change on option choice
  Future<void> _onChanged(dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    List<Depot> userDepots = await _loadDepots();
    Depot userSelectedDepot = userDepots
        .where((element) => element.uuid == val.toString())
        .toList()[0];
    _selectedDepotUuid = userSelectedDepot.uuid;
    _selectedDepotText = userSelectedDepot.text;
    await prefs.setString('selected_depot_uuid', _selectedDepotUuid);
    await prefs.setString('selected_depot_text', _selectedDepotText);
  }

  Future<List<Depot>> _loadDepots() async {
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
        future: _loadDepots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView(
                children: <Widget>[
                  FormBuilder(
                    key: _formKey,
                    // enabled: false,
                    onChanged: () {
                      _formKey.currentState!.save();
                    },
                    autovalidateMode: AutovalidateMode.disabled,
                    skipDisabled: true,
                    child: Column(
                      children: <Widget>[
                        FormBuilderRadioGroup<dynamic>(
                          decoration: const InputDecoration(
                            labelText: 'Choisissez votre depot',
                            alignLabelWithHint: false,
                            border: InputBorder.none,
                          ),
                          orientation: OptionsOrientation.vertical,
                          initialValue: _selectedDepotUuid,
                          name: 'selected_depot_uuid',
                          onChanged: _onChanged,
                          validator: FormBuilderValidators.compose(
                              [FormBuilderValidators.required()]),
                          options: (snapshot.data ?? [])
                              .map((depot) => FormBuilderFieldOption(
                                    value: depot.uuid,
                                    child: Text(depot.text),
                                  ))
                              .toList(growable: true),
                          controlAffinity: ControlAffinity.trailing,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
