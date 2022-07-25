import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class StockMovement {
  String? uuid;
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
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
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
    return 'Depot{uuid: $uuid, depotUuid: $depotUuid, lotUuid: $lotUuid, reference: $reference, entityUuid: $entityUuid, periodId: $periodId, fluxId: $fluxId, isExit: $isExit, date: $date, description: $description, quantity: $quantity, unitCost: $unitCost}';
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

  // A method that retrieves all the StockMovement from the stock_movement table.
  static Future<List<StockMovement>> stockMovements(dynamic database) async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The StockMovement.
    final List<Map<String, dynamic>> maps = await db.query('stock_movement');

    // Convert the List<Map<String, dynamic> into a List<Depot>.
    return List.generate(maps.length, (i) {
      return StockMovement(
        uuid: maps[i]['uuid'],
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
        date: maps[i]['date'],
        isExit: maps[i]['isExit'],
      );
    });
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

  static Future<void> deleteMovement(dynamic database, String uuid) async {
    // Get a reference to the database.
    final db = await database;

    // Remove the StockMovement from the database.
    await db.delete(
      'stock_movement',
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
      'stock_movement',
      // Use a `where` clause to delete a specific depot.
      where: 'uuid IS NOT NULL',
    );
  }
}
