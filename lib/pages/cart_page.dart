import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {


  Future<List<Map<String, dynamic>>> getTripsData() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;
    QuerySnapshot pendingReservations = await FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .where('paymentStatus', isEqualTo: 'pending')
        .get();
    List<String> pendingReservationsIds = pendingReservations.docs.map((e) => e['tripId'].toString()).toList();
    QuerySnapshot querySnapshot;
    if(pendingReservationsIds.isNotEmpty) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('trips')
            .where('uid', whereIn: pendingReservationsIds)
            .where('status', isEqualTo: 'upcoming')
            .get();
        List<Map<String, dynamic>> trips = [];
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          Map<String, dynamic> reservationData = pendingReservations.docs
              .firstWhere((element) => element['tripId'] == data['id'])
              .data() as Map<String, dynamic>;
          data['paymentMethod'] = reservationData['paymentMethod'];
          data['paymentStatus'] = reservationData['paymentStatus'];
          data['requestStatus'] = reservationData['status'];
          data['reservationId'] = reservationData['uid'];
          print(reservationData['uid']);
          if(data['date'].toString().substring(0,10).compareTo(DateTime.now().toString().substring(0,10)) < 0){
            continue;
          }

          trips.add(data);
        }
        return trips;
    }else{
      return [];
    }
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
                    "Pay ${snapshot['price']} to Request Trip",
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
