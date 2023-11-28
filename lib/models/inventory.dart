// ignore_for_file: non_constant_identifier_names
import 'package:sqflite/sqlite_api.dart';

class Inventory {
  String? uuid;
  String? label;
  String? code;
  String? unit;
  String? type;
  String? group_name;
  num? is_asset;
  String? manufacturer_brand;
  String? manufacturer_model;

  Inventory({
    required this.uuid,
    required this.code,
    required this.label,
    required this.unit,
    required this.type,
    required this.group_name,
    required this.is_asset,
    required this.manufacturer_brand,
    required this.manufacturer_model,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'label': label,
      'code': code,
      'unit': unit,
      'type': type,
      'group_name': group_name,
      'is_asset': is_asset,
      'manufacturer_brand': manufacturer_brand,
      'manufacturer_model': manufacturer_model,
    };
  }

  @override
  String toString() {
    return 'Depot{uuid: $uuid, code: $code, label: $label}';
  }

  // A method that retrieves all inventories from the inventory table.
  static Future<List<Inventory>> inventories(dynamic database) async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The lot.
    final List<Map<String, dynamic>> maps = await db.query('inventory');

    // Convert the List<Map<String, dynamic> into a List<Inventory>.
    List<Inventory> collection = List.generate(maps.length, (i) {
      return Inventory(
        uuid: maps[i]['uuid'],
        label: maps[i]['label'],
        code: maps[i]['code'],
        unit: maps[i]['unit'],
        type: maps[i]['type'],
        group_name: maps[i]['group_name'],
        is_asset: maps[i]['is_asset'],
        manufacturer_brand: maps[i]['manufacturer_brand'],
        manufacturer_model: maps[i]['manufacturer_model'],
      );
    });

    return collection;
  }

  // Define a function that inserts lot into the database
  static Future<void> insertInventory(dynamic database, Inventory lot) async {
    final db = await database;
    await db.insert(
      'inventory',
      lot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> updateInventory(dynamic database, Inventory lot) async {
    // Get a reference to the database.
    final db = await database;
    await db.update(
      'inventory',
      lot.toMap(),
      where: 'uuid = ?',
      whereArgs: [lot.uuid],
    );
  }

  static Future<void> deleteInventory(dynamic database, String uuid) async {
    // Get a reference to the database.
    final db = await database;
    await db.delete(
      'inventory',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  static Future<void> clean(dynamic database) async {
    // Get a reference to the database.
    final db = await database;
    await db.delete(
      'inventory',
      where: 'uuid IS NOT NULL',
    );
  }
}
