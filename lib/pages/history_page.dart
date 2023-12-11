import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

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

  Future<Map<String, dynamic>> getDriverData(driverId) async{
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(driverId).get();
    return doc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getTripsData() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;
    QuerySnapshot pastReservations = await FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .get();
    List<String> pastTripsIds = pastReservations.docs.map((e) => e['tripId'].toString()).toList();
    print(pastTripsIds);
    QuerySnapshot querySnapshot;
    if(pastTripsIds.isNotEmpty) {
      querySnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('uid', whereIn: pastTripsIds)
          .get();
    List<Map<String, dynamic>> trips = [];
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      Map<String, dynamic> driverData = await getDriverData(data['driverId']);
      Map<String, dynamic> reservationData = pastReservations.docs.firstWhere((element) => element['tripId'] == data['id']).data() as Map<String, dynamic>;
      data['driverName'] = driverData['username'];
      data['driverPhone'] = driverData['phone'];
      data['driverVehicleType'] = driverData['vehicleType'];
      data['driverVehicleColor'] = driverData['vehicleColor'];
      data['driverVehicleModel'] = driverData['vehicleModel'];
      data['driverVehiclePlates'] = driverData['vehiclePlates'];
      data['addedToCart'] = false;
      data['paymentMethod'] = reservationData['paymentMethod'];
      data['paymentStatus'] = reservationData['paymentStatus'];
      data['requestStatus'] = reservationData['status'];

      if(data['requestStatus'] !='accepted'){
        continue;
      }

      trips.add(data);
      }
      return trips;
    }else{
      return [];
    }
  }

  List<Map<String, dynamic>> filterTripsByDate(List<Map<String, dynamic>> trips, DateTime? tripDate){
    List<Map<String, dynamic>> filteredTrips = [];
    if(tripDate == null){
      return trips;
    }
    for(Map<String, dynamic> trip in trips){
      if(trip['date'].toString().substring(0,10) == tripDate.toString().substring(0,10)){
        filteredTrips.add(trip);
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
                        snapshot['date']
                            .toString()
                            .substring(0, 10),
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
                        snapshot['rideType'] == 'toASU'
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
                      "From: ${snapshot['start']}",
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
                      "To: ${snapshot['destination']}",
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
                    snapshot['distance'].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.drive_eta),
                  Text(
                    snapshot['duration'].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.pending_outlined),
                  Text(
                    snapshot['status'].toString().toUpperCase(),
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
                    snapshot['price'].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 10),
                  snapshot['paymentMethod']=='cash'?Icon(Icons.payments_outlined)
                      :Icon(Icons.credit_card_outlined),
                  Text(
                    snapshot['paymentMethod'].toString().isEmpty?'Pending Payment'
                        :snapshot['paymentMethod'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: snapshot['paymentMethod'].toString().isEmpty?Colors.red:Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                      return buildTripsList(filteredTrips);
                    }
                  },
                ),
              ),
            ]),
    );
  }
}
