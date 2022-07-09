import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/widgets.dart';

class BhimaDatabase {
  static dynamic open() async {
    // Avoid errors caused by flutter upgrade.
    // Importing 'package:flutter/widgets.dart' is required.
    WidgetsFlutterBinding.ensureInitialized();
    // Open the database and store the reference.
    final database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'bhima.db'),
      // When the database is first created, create a table to store depots.
      onCreate: (db, version) async {
        join(await getDatabasesPath(), 'bhima.db');
        // Run the CREATE TABLE statement on the database.
        await db.execute(
          'CREATE TABLE depot(uuid TEXT PRIMARY KEY, "text" TEXT)',
        );
        // The lot TABLE
        await db.execute(
          '''
          CREATE TABLE lot(
            "uuid" TEXT,
            "label" TEXT,
            "lot_description" TEXT,
            "code" TEXT,
            "inventory_uuid" TEXT,
            "text" TEXT,
            "unit_type" TEXT,
            "group_name" TEXT,
            "depot_text" TEXT,
            "depot_uuid" TEXT,
            "is_asset" NUMERIC,
            "barcode" TEXT,
            "serial_number" TEXT,
            "reference_number" TEXT,
            "manufacturer_brand" TEXT,
            "manufacturer_model" TEXT,
            "unit_cost" NUMERIC,
            "quantity" NUMERIC,
            "avg_consumption" NUMERIC,
            "exhausted" NUMERIC,
            "expired" NUMERIC,
            "near_expiration" NUMERIC,
            "expiration_date" TEXT,
            "entry_date" TEXT,
            PRIMARY KEY ("uuid", "depot_uuid")
          )
          ''',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    return database;
  }
}
