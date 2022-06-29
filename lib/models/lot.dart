// ignore_for_file: non_constant_identifier_names
import 'package:bhima_collect/utilities/util.dart';
import 'package:sqflite/sqlite_api.dart';

class Lot {
  String? uuid;
  String? label;
  String? lot_description;
  String? code;
  String? inventory_uuid;
  String? text;
  String? unit_type;
  String? group_name;
  String? depot_text;
  String? depot_uuid;
  num? unit_cost;
  num? quantity;
  num? avg_consumption;
  num? lifetime;
  num? lifetime_lot;
  bool? exhausted;
  bool? expired;
  bool? near_expiration;
  DateTime? expiration_date;

  Lot({
    required this.uuid,
    required this.label,
    required this.lot_description,
    required this.code,
    required this.inventory_uuid,
    required this.text,
    required this.unit_type,
    required this.group_name,
    required this.depot_text,
    required this.depot_uuid,
    required this.unit_cost,
    required this.quantity,
    required this.avg_consumption,
    required this.lifetime,
    required this.lifetime_lot,
    required this.exhausted,
    required this.expired,
    required this.near_expiration,
    required this.expiration_date,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'label': label,
      'lot_description': lot_description,
      'code': code,
      'inventory_uuid': inventory_uuid,
      'text': text,
      'unit_type': unit_type,
      'group_name': group_name,
      'depot_text': depot_text,
      'depot_uuid': depot_uuid,
      'unit_cost': unit_cost,
      'quantity': quantity,
      'avg_consumption': avg_consumption,
      'lifetime': lifetime,
      'lifetime_lot': lifetime_lot,
      'exhausted': exhausted == true ? 1 : 0,
      'expired': expired == true ? 1 : 0,
      'near_expiration': near_expiration == true ? 1 : 0,
      'expiration_date': expiration_date.toString(),
    };
  }

  @override
  String toString() {
    return 'Depot{uuid: $uuid, text: $text, label: $label, quantity: $quantity, depot_text: $depot_text}';
  }

  // A method that retrieves all lots from the lot table.
  static Future<List<Lot>> lots(dynamic database) async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The Depots.
    final List<Map<String, dynamic>> maps = await db.query('lot');

    // Convert the List<Map<String, dynamic> into a List<Lot>.
    List<Lot> collection = List.generate(maps.length, (i) {
      return Lot(
        uuid: maps[i]['uuid'],
        label: maps[i]['label'],
        lot_description: maps[i]['lot_description'],
        code: maps[i]['code'],
        inventory_uuid: maps[i]['inventory_uuid'],
        text: maps[i]['text'],
        unit_type: maps[i]['unit_type'],
        group_name: maps[i]['group_name'],
        depot_text: maps[i]['depot_text'],
        depot_uuid: maps[i]['depot_uuid'],
        unit_cost: maps[i]['unit_cost'],
        quantity: maps[i]['quantity'],
        avg_consumption: maps[i]['avg_consumption'],
        lifetime: maps[i]['lifetime'],
        lifetime_lot: maps[i]['lifetime_lot'],
        exhausted: parseBool(maps[i]['exhausted']),
        expired: parseBool(maps[i]['expired']),
        near_expiration: parseBool(maps[i]['near_expiration']),
        expiration_date: parseDate(maps[i]['expiration_date']),
      );
    });

    return collection;
  }

  // Define a function that inserts lot into the database
  static Future<void> insertLot(dynamic database, Lot lot) async {
    final db = await database;
    await db.insert(
      'lot',
      lot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateLot(dynamic database, Lot lot) async {
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
