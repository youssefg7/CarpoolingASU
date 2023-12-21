import 'package:carpool_flutter/Utilities/utils.dart';
import '../data/Models/TripModel.dart';
import 'package:carpool_flutter/data/Models/ReservationModel.dart';
import 'package:carpool_flutter/data/Repositories/TripRepository.dart';
import '../data/Repositories/ReservationRepository.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  ReservationRepository reservationRepository = ReservationRepository();
  TripRepository tripRepository = TripRepository();

  Future<List<Map<String, dynamic>>> getTripsData() async {
    List<Map<String, dynamic>> tripsData = [];
    List<Reservation> pendingReservations = await reservationRepository.getReservationsByPaymentStatus('pending');
    List<String> pendingReservationsIds = pendingReservations.map((e) => e.tripId).toList();
    if(pendingReservationsIds.isEmpty){
      return tripsData;
    }
    List<Trip> trips = await tripRepository.getTripsByIdsAndStatus(pendingReservationsIds, 'upcoming');
    for (Reservation reservation in pendingReservations) {
      Trip trip = trips.firstWhere((element) => element.id == reservation.tripId);

      if(trip.date.isBefore(DateTime.now())){
        trip.status = 'completed';
        tripRepository.updateTrip(trip);
        reservation.status = 'expired';
        reservationRepository.updateReservation(reservation);
        continue;
      }
      if(trip.rideType == 'toASU' && trip.date == DateTime.now().add(const Duration(days: 1)) && DateTime.now().hour > 22){
        reservation.status = 'expired';
        reservationRepository.updateReservation(reservation);
        continue;
      }
      if(trip.rideType == 'fromASU' && trip.date == DateTime.now() && DateTime.now().hour > 13){
        reservation.status = 'expired';
        reservationRepository.updateReservation(reservation);
        continue;
      }
      Map<String, dynamic> data = {
        'trip': trip,
        'reservation': reservation,
      };
      tripsData.add(data);
    }
    return tripsData;
  }


  Widget buildTripsList(List<Map<String, dynamic>> trips) {
    if(trips.isEmpty){
      return const Center(
        child: Text(
          "Your Cart is Empty",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: trips.length,
      itemBuilder: (context, index) {
        var tripData = trips[index];
        return buildTripCard(tripData, context);
      },
    );
  }

  Widget buildTripCard(Map<String, dynamic> snapshot, BuildContext context) {
    Trip trip = snapshot['trip'];
    Reservation reservation = snapshot['reservation'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Card(
        elevation: 10,
        shadowColor: Colors.black,
        color: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range_sharp),
                      const SizedBox(width: 10),
                      Text(
                        Utils.formatDate(trip.date),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.watch_later_outlined),
                      const SizedBox(width: 10),
                      Text(
                        trip.rideType == 'toASU'
                            ? '07:30 AM'
                            : '05:30 PM',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_pin),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "From: ${trip.start}",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_pin),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "To: ${trip.destination}",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [ElevatedButton.icon(
                  onPressed: (){
                    Navigator.pushNamed(context, '/payment', arguments: snapshot).then((value) => setState(() {}));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shadowColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 2,
                        color: Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    padding:
                    const EdgeInsets.all(10),
                  ),
                  icon: const Icon(
                    Icons.payments_outlined,
                    color: Colors.white,
                  ),
                  label: Text(
                    "Pay ${trip.price} to Request Trip",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),]
              ),
          ],
        ),
      ),),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
        title: const Text("Reservations Cart"),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Column(children: [
        SizedBox(
          height: 10
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: getTripsData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "Your Cart is Empty",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              } else {
                return buildTripsList(snapshot.data!);
              }
            },
          ),
        ),
      ]),
    );
  }
}
