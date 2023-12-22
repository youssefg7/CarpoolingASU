import 'package:carpool_flutter/data/Models/ReservationModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import 'Models/TripModel.dart';

class MyDB {
  static Database? _database;
  static final MyDB _singleton = MyDB._internal();

  factory MyDB() {
    return _singleton;
  }

  MyDB._internal();

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await initDB();
    return _database;
  }

  initDB() async {
    return await openDatabase(
      'myDB.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
              CREATE TABLE trip(
                id TEXT PRIMARY KEY,
                start TEXT,
                startLat REAL,
                startLng REAL,
                destination TEXT,
                destinationLat REAL,
                destinationLng REAL,
                price TEXT,
                distance TEXT,
                duration TEXT,
                driverId TEXT,
                status TEXT,
                passengersCount INTEGER,
                date INTEGER,
                rideType TEXT,
                gate INTEGER
              )
            ''');
        await db.execute('''
              CREATE TABLE reservation(
                id TEXT PRIMARY KEY,
                tripId TEXT,
                userId TEXT,
                status TEXT,
                paymentMethod TEXT,
                paymentStatus TEXT
              )
            ''');
      },
    );
  }

  Future<void> addTrip(Trip trip) async {
    final db = await database;
    var t = trip.toJSON();
    t['date'] = t['date'].millisecondsSinceEpoch;
    await db!.insert('trip', t, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> addReservation(Reservation reservation) async {
    final db = await database;
    await db!.insert('reservation', reservation.toJSON(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await database;
    await db!.update('trip', trip.toJSON(), where: 'id = ?', whereArgs: [trip.id], conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateReservation(Reservation reservation) async {
    final db = await database;
    await db!.update('reservation', reservation.toJSON(), where: 'id = ?', whereArgs: [reservation.id], conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Reservation>> getReservations() async {
    final db = await database;
    var result = await db!.query('reservation');
    return result.map((e) => Reservation.fromJSON(e)).toList();
  }

  Future<List<Reservation>> getReservationsByPaymentStatus(String paymentStatus) async {
    final db = await database;
    var result = await db!.query('reservation', where: 'paymentStatus = ?', whereArgs: [paymentStatus]);
    return result.map((e) => Reservation.fromJSON(e)).toList();
  }

  Future<List<Trip>> getTripsByDateAndRideType(DateTime date, String rideType) async {
    final db = await database;
    var res = await db!.query('trip', where: 'date = ? AND rideType = ?', whereArgs: [date.millisecondsSinceEpoch, rideType]);
    for (var element in res) {
      element['date'] = Timestamp.fromMillisecondsSinceEpoch(element['date'] as int);
    }
    return res.map((e) => Trip.fromJSON(e)).toList();
  }

  Future<void> batchInsertTrips(List<Trip> trips) async {
    final db = await database;
    var batch = db!.batch();
    for (var trip in trips) {
      var t = trip.toJSON();
      t['date'] = t['date'].millisecondsSinceEpoch;
      print(t);
      batch.rawInsert(
          '''INSERT OR REPLACE INTO trip(id, start, startLat, startLng, destination, destinationLat, destinationLng, price, distance, duration, driverId, status, passengersCount, date, rideType, gate) VALUES (
            '${t['id']}',
            '${t['start']}',
            ${t['startLat']},
            ${t['startLng']},
            '${t['destination']}',
            ${t['destinationLat']},
            ${t['destinationLng']},
            '${t['price']}',
            '${t['distance']}',
            '${t['duration']}',
            '${t['driverId']}',
            '${t['status']}',
            ${t['passengersCount']},
            ${t['date']},
            '${t['rideType']}',
            ${t['gate']}
          )'''
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Trip>> getTripsByIdsAndStatus(List<String> ids, String status) async {
    final db = await database;
    var res = await db!.query('trip', where: 'id IN ? AND status = ?', whereArgs: [ids, status]);
    List<Map<String, dynamic>> modifiedRes = List.from(res);

    for (var element in modifiedRes) {
      element['date'] = Timestamp.fromMillisecondsSinceEpoch(element['date'] as int);
    }
    return res.map((e) => Trip.fromJSON(e)).toList();
  }

  Future<List<Trip>> getTripsByIds(List<String> ids) async {
    final db = await database;
    for(var id in ids){
      var x = await db?.query('trip');
      print(x);
    }

    var res = await db!.query('trip', where: 'id IN (${ids.map((_) => '?').join(', ')})', whereArgs: ids);
    if (res.isEmpty) {
      print('empty');

      return [];
    }
      // print(res);
    List<Map<String, dynamic>> modifiedRes = List.from(res);
    for (var element in modifiedRes) {
      element['date'] = Timestamp.fromMillisecondsSinceEpoch(element['date'] as int);
    }
    return res.map((e) => Trip.fromJSON(e)).toList();
  }

  Future<void> deleteReservation(Reservation reservation) async {
    final db = await database;
    await db!.delete('reservation', where: 'id = ?', whereArgs: [reservation.id]);
  }

}
