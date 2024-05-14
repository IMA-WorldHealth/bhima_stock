import 'package:bhima_collect/utilities/util.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class StockMovement {
  String? uuid;
  String? movementUuid;
  String? depotUuid;
  String? inventoryUuid;
  String? lotUuid;
  String? reference;
  String? entityUuid;
  int? periodId;
  int? userId;
  int? fluxId;
  int? isExit;
  DateTime? date;
  String? description;
  int quantity = 0;
  int? oldQuantity;
  double unitCost = 0;
  int? isSync = 0;

  StockMovement(
      {required this.uuid,
      required this.movementUuid,
      required this.depotUuid,
      required this.inventoryUuid,
      required this.lotUuid,
      required this.reference,
      required this.entityUuid,
      required this.periodId,
      required this.userId,
      required this.fluxId,
      required this.isExit,
      required this.date,
      required this.description,
      required this.quantity,
      required this.unitCost,
      this.isSync,
      this.oldQuantity});

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'movementUuid': movementUuid,
      'depotUuid': depotUuid,
      'inventoryUuid': inventoryUuid,
      'lotUuid': lotUuid,
      'reference': reference,
      'entityUuid': entityUuid,
      'periodId': periodId,
      'userId': userId,
      'fluxId': fluxId,
      'isExit': isExit,
      'date': date.toString(),
      'description': description,
      'quantity': quantity,
      'unitCost': unitCost,
      'isSync': isSync,
      'oldQuantity': oldQuantity,
    };
  }

  @override
  String toString() {
    return 'StockMovement{uuid: $uuid, depotUuid: $depotUuid, lotUuid: $lotUuid, reference: $reference, entityUuid: $entityUuid, periodId: $periodId, fluxId: $fluxId, isExit: $isExit, date: $date, description: $description, quantity: $quantity, oldQuantity: $oldQuantity, unitCost: $unitCost}';
  }

  String? get getUuid {
    return uuid;
  }

  String? get getDepotUuid {
    return depotUuid;
  }

  String? get getInventoryUuid {
    return inventoryUuid;
  }

  String? get getLotUuid {
    return lotUuid;
  }

  String? get getReference {
    return reference;
  }

  String? get getEntityUuid {
    return entityUuid;
  }

  int? get getPeriodId {
    return periodId;
  }

  int? get getUserId {
    return userId;
  }

  int? get getFluxId {
    return fluxId;
  }

  int? get getIsExit {
    return isExit;
  }

  DateTime? get getDate {
    return date;
  }

  String? get getDescription {
    return description;
  }

  int? get getQuantity {
    return quantity;
  }

  int? get getOldQuantity {
    return oldQuantity;
  }

  double? get getUnitCost {
    return unitCost;
  }

  // Setters
  void setUuid(String uuid) {
    uuid = uuid;
  }

  // json handlers
  StockMovement.fromJson(Map<String, dynamic> json) {
    uuid = json['uuid'];
    movementUuid = json['movementUuid'];
    reference = json['reference'];
    depotUuid = json['depotUuid'];
    entityUuid = json['entityUuid'];
    inventoryUuid = json['inventoryUuid'];
    lotUuid = json['lotUuid'];
    periodId = json['periodId'];
    fluxId = json['fluxId'];
    userId = json['userId'];
    description = json['description'];
    unitCost = json['unitCost'];
    quantity = json['quantity'];
    oldQuantity = json['oldQuantity'];
    date = parseDate(json['date']);
    isExit = json['isExit'];
    isSync = json['isSync'];
  }

  // json export
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'movementUuid': movementUuid,
      'depotUuid': depotUuid,
      'inventoryUuid': inventoryUuid,
      'lotUuid': lotUuid,
      'reference': reference,
      'entityUuid': entityUuid,
      'periodId': periodId,
      'userId': userId,
      'fluxId': fluxId,
      'isExit': isExit,
      'date': date.toString(),
      'description': description,
      'quantity': quantity,
      'oldQuantity': oldQuantity,
      'unitCost': unitCost,
      'isSync': isSync,
    };
  }

  // A method that retrieves all the StockMovement from the stock_movement table.
  static Future<List<StockMovement>> stockMovements(dynamic database) async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The StockMovement.
    final List<Map<String, dynamic>> maps = await db.query('stock_movement');

    // Convert the List<Map<String, dynamic> into a List<StockMovement>.
    return List.generate(maps.length, (i) {
      return StockMovement(
        uuid: maps[i]['uuid'],
        movementUuid: maps[i]['movementUuid'],
        reference: maps[i]['reference'],
        depotUuid: maps[i]['depotUuid'],
        entityUuid: maps[i]['entityUuid'],
        inventoryUuid: maps[i]['inventoryUuid'],
        lotUuid: maps[i]['lotUuid'],
        periodId: maps[i]['periodId'],
        fluxId: maps[i]['fluxId'],
        userId: maps[i]['userId'],
        description: maps[i]['description'],
        unitCost: maps[i]['unitCost'].toDouble(),
        quantity: maps[i]['quantity'],
        oldQuantity: maps[i]['oldQuantity'],
        date: parseDate(maps[i]['date']),
        isExit: maps[i]['isExit'],
        isSync: maps[i]['isSync'],
      );
    });
  }

  // get stock quantities
  static Future<List> stockQuantity(dynamic database) async {
    // Get a reference to the database.
    final db = await database;

    // Get data from local movements and latest online data received
    String query = '''
      SELECT l.depot_uuid, i.label AS text, l.label AS label,
      l.quantity,
      l.code, l.unit_type, m.isExit, l.inventory_uuid, l.uuid AS lot_uuid,
      l.expiration_date, l.unit_cost
      FROM lot l
      JOIN inventory i ON i.uuid = l.inventory_uuid
      LEFT JOIN stock_movement m ON m.lotUuid = l.uuid
      WHERE m.isSync IS null OR m.isSync = 0
      GROUP BY l.depot_uuid, l.inventory_uuid, l.uuid
      ORDER BY i.label, l.label;
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

    // Convert the List<Map<String, dynamic> into a List<StockMovement>.
    return maps;
  }

  static Future<List> stockQuantityDepot(
      dynamic database, String depotUuid) async {
    // Get a reference to the database.
    final db = await database;

    // Get data from local movements and latest online data received
    String query = '''
      SELECT l.depot_uuid, i.label AS text, l.label AS label,
      l.quantity,
      l.code, l.unit_type, m.isExit, l.inventory_uuid, l.uuid AS lot_uuid,
      l.expiration_date, l.unit_cost
      FROM lot l
      JOIN inventory i ON i.uuid = l.inventory_uuid
      LEFT JOIN stock_movement m ON m.lotUuid = l.uuid
      WHERE m.isSync IS null OR m.isSync = 0 AND l.depot_uuid = ?
      GROUP BY l.depot_uuid, l.inventory_uuid, l.uuid
      ORDER BY i.label, l.label;
    ''';
    final List<Map<String, dynamic>> maps =
        await db.rawQuery(query, [depotUuid]);

    // Convert the List<Map<String, dynamic> into a List<StockMovement>.
    return maps;
  }

  // Filter the stock of a given depot by lot and inventory
  static Future<List> stockQuantityDepotFilter(
      dynamic database, String depotUuid, String text) async {
    // Get a reference to the database.
    final db = await database;

    // Get data from local movements and latest online data received
    String query = '''
      SELECT l.depot_uuid, i.label AS text, l.label AS label,
      l.quantity,
      l.code, l.unit_type, m.isExit, l.inventory_uuid, l.uuid AS lot_uuid,
      l.expiration_date, l.unit_cost
      FROM lot l
      LEFT JOIN inventory i ON i.uuid = l.inventory_uuid
      LEFT JOIN stock_movement m ON m.lotUuid = l.uuid
      WHERE m.isSync IS null OR m.isSync = 0 AND 
      l.depot_uuid = ? OR l.label LIKE ? OR i.label LIKE ?
      GROUP BY l.depot_uuid, l.inventory_uuid, l.uuid
      ORDER BY i.label, l.label;
    ''';
    final List<Map<String, dynamic>> maps =
        await db.rawQuery(query, [depotUuid, '%$text%', '%$text%']);

    // Convert the List<Map<String, dynamic> into a List<StockMovement>.
    return maps;
  }

  // Define a function that inserts stock_movements into the database
  static Future<void> insertMovement(
    dynamic database,
    StockMovement movement,
  ) async {
    // Get a reference to the database.
    final db = await database;

    if (movement.uuid == null) {
      const uuid = Uuid();
      movement.setUuid(uuid.v4());
    }

    // Insert the StockMovement into the database
    await db.insert(
      'stock_movement',
      movement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Define a function that insert the array movement into database with transaction
  static Future<dynamic> txInsertMovement(
      dynamic database, List<StockMovement> movements) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var movement in movements) {
        batch.insert('stock_movement', movement.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<void> updateMovement(
    dynamic database,
    StockMovement movement,
  ) async {
    // Get a reference to the database.
    final db = await database;

    // Update the given StockMovement.
    await db.update(
      'stock_movement',
      movement.toMap(),
      // Ensure that the StockMovement has a matching id.
      where: 'uuid = ?',
      // Pass the StockMovement's id as a whereArg to prevent SQL injection.
      whereArgs: [movement.uuid],
    );
  }

  static Future<dynamic> updateSyncStatus(
    dynamic database,
    String movementUuid,
    String uuids,
  ) async {
    // Get a reference to the database.
    final db = await database;
    var lotUuids = uuids.split(',');
    var lotUuidsMarks = lotUuids.map((e) => '?').join(',');

    // Update the given StockMovement.
    Map<String, dynamic> row = {'isSync': 1};
    return db.update(
      'stock_movement',
      row,
      // Ensure that the StockMovement has a matching id.
      where: 'movementUuid = ? AND lotUuid IN ($lotUuidsMarks)',
      // Pass the StockMovement's id as a whereArg to prevent SQL injection.
      whereArgs: [movementUuid, ...lotUuids],
    );
  }

  static Future<void> deleteMovement(dynamic database, String uuid) async {
    // Get a reference to the database.
    final db = await database;

    // Remove the StockMovement from the database.
    await db.delete(
      'stock_movement',
      // Use a `where` clause to delete a specific depot.
      where: 'uuid = ?',
      // Pass the StockMovement's id as a whereArg to prevent SQL injection.
      whereArgs: [uuid],
    );
  }

  static Future<void> clean(dynamic database) async {
    // Get a reference to the database.
    final db = await database;

    // Remove the StockMovement from the database.
    await db.delete(
      'stock_movement',
      // Use a `where` clause to delete a specific depot.
      where: 'uuid IS NOT NULL',
    );
  }

  // get lots from local integrations
  static Future<List> getLocalLots(dynamic database) async {
    // Get a reference to the database.
    final db = await database;

    // Get data from local movements and latest online data received
    String query = '''
      SELECT
        l.uuid,
        l.label,
        l.quantity,
        l.unit_cost,
        l.expiration_date,
        l.inventory_uuid,
        m.isSync,
        m.movementUuid
      FROM stock_movement m
      JOIN lot l ON l.uuid = m.lotUuid
      WHERE m.fluxId = 13 AND m.isExit = 0 AND (m.isSync IS NULL OR m.isSync = 0);
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

    // Convert the List<Map<String, dynamic> into a List<StockMovement>.
    return maps;
  }
}
