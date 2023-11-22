// ignore_for_file: unnecessary_new

import 'package:sqflite/sqflite.dart';

class Depot {
  final String uuid;
  final String text;

  const Depot({
    required this.uuid,
    required this.text,
  });

  // GETTERS
  String get getUuid {
    return uuid;
  }

  String get getText {
    return text;
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'text': text,
    };
  }

  @override
  String toString() {
    return 'Depot{uuid: $uuid, text: $text}';
  }

  // A method that retrieves all the Depots from the Depots table.
  static Future<List<Depot>> depots(dynamic database) async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The Depots.
    final List<Map<String, dynamic>> maps = await db.query('depot');

    // Convert the List<Map<String, dynamic> into a List<Depot>.
    return List.generate(maps.length, (i) {
      return Depot(
        uuid: maps[i]['uuid'],
        text: maps[i]['text'],
      );
    });
  }

  // A method to the filter depot list
  static Future<List<Depot>> depotFilter(dynamic database, String text) async {
    final db = await database;

    //Query
    final List<Map<String, dynamic>> maps =
        await db.query('depot', where: 'text LIKE ?', whereArgs: ['%$text%']);

    // Convert the List<Map<String, dynamic> into a List<Depot>.
    return List.generate(maps.length, (i) {
      return Depot(
        uuid: maps[i]['uuid'],
        text: maps[i]['text'],
      );
    });
  }

  // Define a function that inserts depots into the database
  static Future<void> insertDepot(dynamic database, Depot depot) async {
    // Get a reference to the database.
    final db = await database;

    // Insert the Depot into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same Depot is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'depot',
      depot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Define a function that insert the array depots into database with transaction
  static Future<void> txInsertLot(dynamic database, List<Depot> depots) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var depot in depots) {
        batch.insert('depot', depot.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<void> updateDepot(dynamic database, Depot depot) async {
    // Get a reference to the database.
    final db = await database;

    // Update the given Depot.
    await db.update(
      'depot',
      depot.toMap(),
      // Ensure that the Depot has a matching id.
      where: 'uuid = ?',
      // Pass the Depot's id as a whereArg to prevent SQL injection.
      whereArgs: [depot.uuid],
    );
  }

  static Future<void> deleteDepot(dynamic database, String uuid) async {
    // Get a reference to the database.
    final db = await database;

    // Remove the Depot from the database.
    await db.delete(
      'depot',
      // Use a `where` clause to delete a specific depot.
      where: 'uuid = ?',
      // Pass the Depot's id as a whereArg to prevent SQL injection.
      whereArgs: [uuid],
    );
  }

  static Future<void> clean(dynamic database) async {
    // Get a reference to the database.
    final db = await database;

    // Remove the Depot from the database.
    await db.delete(
      'depot',
      // Use a `where` clause to delete a specific depot.
      where: 'uuid IS NOT NULL',
    );
  }
}
