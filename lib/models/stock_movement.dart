import 'package:bhima_collect/models/inventory_lot.dart';
import 'package:bhima_collect/utilities/util.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class StockMovement {
  String? uuid;
  String? movementUuid;
  String? depotUuid;
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
  double unitCost = 0;
  int? isSync = 0;

  StockMovement({
    required this.uuid,
    required this.movementUuid,
    required this.depotUuid,
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
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'movementUuid': movementUuid,
      'depotUuid': depotUuid,
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
    };
  }

  @override
  String toString() {
    return 'StockMovement{uuid: $uuid, depotUuid: $depotUuid, lotUuid: $lotUuid, reference: $reference, entityUuid: $entityUuid, periodId: $periodId, fluxId: $fluxId, isExit: $isExit, date: $date, description: $description, quantity: $quantity, unitCost: $unitCost}';
  }

  String? get getUuid {
    return uuid;
  }

  String? get getDepotUuid {
    return depotUuid;
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
    lotUuid = json['lotUuid'];
    periodId = json['periodId'];
    fluxId = json['fluxId'];
    userId = json['userId'];
    description = json['description'];
    unitCost = json['unitCost'];
    quantity = json['quantity'];
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
        lotUuid: maps[i]['lotUuid'],
        periodId: maps[i]['periodId'],
        fluxId: maps[i]['fluxId'],
        userId: maps[i]['userId'],
        description: maps[i]['description'],
        unitCost: maps[i]['unitCost'],
        quantity: maps[i]['quantity'],
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
      SELECT z.depot_uuid, z.inventory_text AS text, z.lot_label AS label,
      SUM(z.quantity) quantity,
      z.code, z.unit_type, z.isExit
      FROM (
        SELECT
          i.uuid AS inventory_uuid, l.uuid AS lot_uuid,
          m.depotUuid AS depot_uuid, i.label AS inventory_text, l.label AS lot_label,
          SUM(IIF(m.isExit = 0, 1 * m.quantity, -1 * m.quantity)) quantity,
          m.isExit, i.code, i.unit AS unit_type
        FROM stock_movement m
        JOIN inventory_lot l ON l.uuid = m.lotUuid
        JOIN inventory i ON i.uuid = l.inventory_uuid
        WHERE m.isSync IS null OR m.isSync = 0
        GROUP BY m.depotUuid, l.inventory_uuid, l.uuid
        UNION ALL
        SELECT
          lot.inventory_uuid AS inventory_uuid, lot.uuid AS lot_uuid,
          lot.depot_uuid AS depot_uuid, lot.text AS inventory_text, lot.label AS lot_label, lot.quantity,
          0 AS isExit, lot.code, lot.unit_type AS unit_type
        FROM lot
        GROUP BY lot.depot_uuid, lot.inventory_uuid, lot.uuid
      ) z 
      GROUP BY z.depot_uuid, z.inventory_uuid, z.lot_uuid;
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

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

    // Update the given StockMovement.
    Map<String, dynamic> row = {'isSync': 1};
    return db.update(
      'stock_movement',
      row,
      // Ensure that the StockMovement has a matching id.
      where: 'movementUuid = ? AND lotUuid IN (?)',
      // Pass the StockMovement's id as a whereArg to prevent SQL injection.
      whereArgs: [movementUuid, uuids],
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
}
