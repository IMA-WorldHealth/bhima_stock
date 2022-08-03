// ignore_for_file: non_constant_identifier_names
import 'package:bhima_collect/utilities/util.dart';
import 'package:sqflite/sqlite_api.dart';

class InventoryLot {
  String? uuid;
  String? code;
  String? label;
  String? inventory_uuid;
  String? text;
  String? unit_type;
  String? group_name;
  num? unit_cost;
  DateTime? expiration_date;
  DateTime? entry_date;

  InventoryLot({
    required this.uuid,
    required this.code,
    required this.label,
    required this.inventory_uuid,
    required this.text,
    required this.unit_type,
    required this.group_name,
    required this.unit_cost,
    required this.expiration_date,
    required this.entry_date,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'label': label,
      'code': code,
      'inventory_uuid': inventory_uuid,
      'text': text,
      'unit_type': unit_type,
      'group_name': group_name,
      'unit_cost': unit_cost,
      'expiration_date': expiration_date.toString(),
      'entry_date': entry_date.toString(),
    };
  }

  @override
  String toString() {
    return 'Depot{uuid: $uuid, text: $text, label: $label}';
  }

  // A method that retrieves all lots from the lot table.
  static Future<List<InventoryLot>> lots(dynamic database) async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The lot.
    final List<Map<String, dynamic>> maps = await db.query('lot');

    // Convert the List<Map<String, dynamic> into a List<InventoryLot>.
    List<InventoryLot> collection = List.generate(maps.length, (i) {
      return InventoryLot(
        uuid: maps[i]['uuid'],
        label: maps[i]['label'],
        code: maps[i]['code'],
        inventory_uuid: maps[i]['inventory_uuid'],
        text: maps[i]['text'],
        unit_type: maps[i]['unit_type'],
        group_name: maps[i]['group_name'],
        unit_cost: maps[i]['unit_cost'],
        expiration_date: parseDate(maps[i]['expiration_date']),
        entry_date: parseDate(maps[i]['entry_date']),
      );
    });

    return collection;
  }

  // List of unique inventories
  static Future<List<InventoryLot>> inventories(
      dynamic database, String depot_uuid) async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The lot.
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM lot WHERE lot.depot_uuid = ? GROUP BY lot.inventory_uuid;',
        [depot_uuid]);

    // Convert the List<Map<String, dynamic> into a List<InventoryLot>.
    List<InventoryLot> collection = List.generate(maps.length, (i) {
      return InventoryLot(
        uuid: maps[i]['uuid'],
        label: maps[i]['label'],
        code: maps[i]['code'],
        inventory_uuid: maps[i]['inventory_uuid'],
        text: maps[i]['text'],
        unit_type: maps[i]['unit_type'],
        group_name: maps[i]['group_name'],
        unit_cost: maps[i]['unit_cost'],
        expiration_date: parseDate(maps[i]['expiration_date']),
        entry_date: parseDate(maps[i]['entry_date']),
      );
    });

    return collection;
  }

  // List of unique inventories
  static Future<List<InventoryLot>> inventoryLots(
      dynamic database, String depot_uuid, String inventoryUuid) async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The lot.
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM lot WHERE depot_uuid = ? AND inventory_uuid = ? GROUP BY uuid;',
        [depot_uuid, inventoryUuid]);

    // Convert the List<Map<String, dynamic> into a List<InventoryLot>.
    List<InventoryLot> collection = List.generate(maps.length, (i) {
      return InventoryLot(
        uuid: maps[i]['uuid'],
        label: maps[i]['label'],
        code: maps[i]['code'],
        inventory_uuid: maps[i]['inventory_uuid'],
        text: maps[i]['text'],
        unit_type: maps[i]['unit_type'],
        group_name: maps[i]['group_name'],
        unit_cost: maps[i]['unit_cost'],
        expiration_date: parseDate(maps[i]['expiration_date']),
        entry_date: parseDate(maps[i]['entry_date']),
      );
    });

    return collection;
  }

  // import from lot : inventory_lot and inventory
  static Future<void> import(dynamic database) async {
    final db = await database;

    // insert into inventory_lot
    String queryInsertInventoryLot = '''
      INSERT INTO inventory_lot (uuid, label, code, inventory_uuid, text, unit_type, group_name, unit_cost, expiration_date, entry_date)
        SELECT uuid, label, code, inventory_uuid, text, unit_type, group_name, unit_cost, expiration_date, entry_date 
        FROM lot GROUP BY inventory_uuid, uuid
    ''';
    await db.rawQuery(queryInsertInventoryLot);

    // insert into inventory_lot
    String queryInsertInventory = '''
      INSERT INTO inventory (uuid, label, code, unit, group_name, is_asset, manufacturer_brand, manufacturer_brand)
        SELECT inventory_uuid, text, code, unit_type, group_name, is_asset, manufacturer_brand, manufacturer_brand
        FROM lot GROUP BY inventory_uuid
    ''';
    await db.rawQuery(queryInsertInventory);
  }

  // Define a function that inserts lot into the database
  static Future<void> insertLot(dynamic database, InventoryLot lot) async {
    final db = await database;
    await db.insert(
      'lot',
      lot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> updateLot(dynamic database, InventoryLot lot) async {
    // Get a reference to the database.
    final db = await database;
    await db.update(
      'lot',
      lot.toMap(),
      where: 'uuid = ?',
      whereArgs: [lot.uuid],
    );
  }

  static Future<void> deleteLot(dynamic database, String uuid) async {
    // Get a reference to the database.
    final db = await database;
    await db.delete(
      'lot',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  static Future<void> clean(dynamic database) async {
    // Get a reference to the database.
    final db = await database;
    await db.delete(
      'lot',
      where: 'uuid IS NOT NULL',
    );
  }
}
