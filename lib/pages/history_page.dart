import 'package:carpool_flutter/data/Models/UserModel.dart';
import 'package:carpool_flutter/data/Repositories/ReservationRepository.dart';
import 'package:carpool_flutter/data/Repositories/TripRepository.dart';
import 'package:carpool_flutter/data/Repositories/UserRepository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Utilities/utils.dart';
import '../data/Models/ReservationModel.dart';
import '../data/Models/TripModel.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  ReservationRepository reservationRepository = ReservationRepository();
  TripRepository tripRepository = TripRepository();
  UserRepository userRepository = UserRepository();

  List<Map<String, dynamic>> filteredTrips = [];
  
  DateTime? tripDate;
  void callDatePicker() async {
    DateTime? date = await getDate();
    if(date == null){
      return;
    }
    setState(() {
      tripDate = date;
    });
  }

  Future<DateTime?> getDate() {
    DateTime now = DateTime.now();
    DateTime initialDay = now;
    DateTime firstDay = DateTime(2023);
    return showDatePicker(
      context: context,
      initialDate: initialDay,
      firstDate: firstDay,
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTripsData() async {
    List<Map<String, dynamic>> tripsData = [];
    List<Reservation> pendingReservations = await reservationRepository.getReservations();
    List<String> pendingReservationsIds = pendingReservations.map((e) => e.tripId).toList();
    print(pendingReservationsIds);
    if(pendingReservationsIds.isEmpty){
      return tripsData;
    }
    List<Trip> trips = await tripRepository.getTripsByIds(pendingReservationsIds);
      print("her1e");
    print(trips.length);
    for (Reservation reservation in pendingReservations) {
      Trip trip = trips.firstWhere((element) => element.id == reservation.tripId);
      Student? driver = await userRepository.getUser(trip.driverId);
      if(trip.date.isBefore(DateTime.now())){
        trip.status = 'completed';
        tripRepository.updateTrip(trip);
        reservation.status = 'expired';
        reservationRepository.updateReservation(reservation);
      }
      if(trip.rideType == 'toASU' && trip.date == DateTime.now().add(const Duration(days: 1)) && DateTime.now().hour > 22){
        reservation.status = 'expired';
        reservationRepository.updateReservation(reservation);
      }
      if(trip.rideType == 'fromASU' && trip.date == DateTime.now() && DateTime.now().hour > 13){
        reservation.status = 'expired';
        reservationRepository.updateReservation(reservation);
      }
      Map<String, dynamic> data = {
        'trip': trip,
        'reservation': reservation,
        'driver': driver,
      };
      tripsData.add(data);
    }
    return tripsData;
  }

  List<Map<String, dynamic>> filterTripsByDate(List<Map<String, dynamic>> trips, DateTime? tripDate){
    List<Map<String, dynamic>> filteredTrips = [];
    if(tripDate == null){
      return trips;
    }
    for(Map<String, dynamic> tripData in trips){
      if(tripData['trip'].date == tripDate){
        filteredTrips.add(tripData);
      }
    }
    return filteredTrips;
  }

  Widget buildTripsList(List<Map<String, dynamic>> trips) {
    if(trips.isEmpty){
      return const Center(
        child: Text(
          "No Trips Match The Filter Date",
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
    Student driver = snapshot['driver'];
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.route),
                  Text(
                    trip.distance,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.drive_eta),
                  Text(
                    trip.duration,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.pending_outlined),
                  Text(
                    trip.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.attach_money),
                  Text(
                    trip.price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 10),
                  reservation.paymentStatus != 'paid'?SizedBox():
                  reservation.paymentMethod=='cash'?const Icon(Icons.payments_outlined)
                      :const Icon(Icons.credit_card_outlined),
                  reservation.paymentStatus == 'paid'?
                  Text(reservation.paymentMethod.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                  :ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shadowColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 2,
                          color: Colors.blue,
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),),
                      onPressed: (){
                        Navigator.pushNamed(context, '/payment', arguments: snapshot).then((value) => setState(() {}));
                      },
                      icon: const Icon(Icons.payment_outlined),
                      label: const Text('Pay Now', style: TextStyle(fontSize: 18),),)
                ],
              ),

              const SizedBox(height: 10),
              reservation.paymentStatus == 'paid' && trip.status == 'upcoming'
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions_outlined),
                  const Text(
                    'Request Status:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    reservation.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: (reservation.status == 'declined')
                          ? Colors.red
                          : (reservation.status == 'accepted')
                          ? Colors.green
                          : Colors.white,
                    ),
                  ),
                ],
              ):const SizedBox(),

              const SizedBox(height: 10),
              reservation.paymentStatus == 'paid' && reservation.status == 'accepted' && trip.status == 'upcoming'
                  ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.phone), color: Colors.green,
                        onPressed: () async{
                          await Utils.makePhoneCall(driver.phone);
                        }),
                    const Icon(Icons.person),
                    const SizedBox(width: 10),
                    Text("${driver.username} - ${driver.email.toUpperCase()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                  ]
              ):const SizedBox(),
            ],
          ),
        ),
      ),
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
        title: const Text("Your Trips History"),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Column(children: [
              GestureDetector(
                onTap: callDatePicker,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.date_range,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        tripDate == null
                            ? "Filter by Date"
                            : DateFormat("E, dd MMM yyyy").format(tripDate!),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      tripDate==null?const SizedBox()
                          :IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20,),
                        onPressed: (){
                          setState(() {
                            tripDate = null;
                          });
                        },
                      )
                    ]),
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
                          "No Trips Yet",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else {
                      filteredTrips = filterTripsByDate(snapshot.data!, tripDate);
                      print(filteredTrips.length);
                      return buildTripsList(filteredTrips);
                    }
                  },
                ),
              ),
            ]),
    );
  }
}
