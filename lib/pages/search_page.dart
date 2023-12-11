import 'package:carpool_flutter/Utilities/global_var.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:intl/intl.dart';

import '../Utilities/utils.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController pickupTextEditingController = TextEditingController();
  TextEditingController dropoffTextEditingController = TextEditingController();
  TextEditingController searchTextEditingController = TextEditingController();
  String rideType = "toASU";
  FocusNode pickupFocus = FocusNode();
  FocusNode dropoffFocus = FocusNode();

  List<Map<String, dynamic>> filteredTrips = [];

  void toggleRideType() {
    String tempPickup = pickupTextEditingController.text;
    String tempDropoff = dropoffTextEditingController.text;

    if (rideType == "fromASU") {
      pickupTextEditingController.text = tempDropoff;
      dropoffTextEditingController.text = "Faculty of Engineering, ASU";
      FocusScope.of(context).requestFocus(pickupFocus);
    } else {
      pickupTextEditingController.text = "Faculty of Engineering, ASU";
      dropoffTextEditingController.text = tempPickup;
      FocusScope.of(context).requestFocus(dropoffFocus);
    }
    setState(() {
      rideType = rideType == "toASU" ? "fromASU" : "toASU";
    });
  }

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
    DateTime initialDay;
    if (rideType == "toASU") {
      if (DateTime.now().isAfter(DateTime(DateTime.now().year,
          DateTime.now().month, DateTime.now().day, 23, 30))) {
        initialDay = DateTime(now.year, now.month, now.day + 2);
      } else {
        initialDay = DateTime(now.year, now.month, now.day + 1);
      }
    } else {
      if (DateTime.now().isAfter(DateTime(DateTime.now().year,
          DateTime.now().month, DateTime.now().day, 16, 30))) {
        initialDay = DateTime(now.year, now.month, now.day + 1);
      } else {
        initialDay = now;
      }
    }
    return showDatePicker(
      context: context,
      initialDate: initialDay,
      firstDate: initialDay,
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );
  }


  addToCart(trip){
    if(rideType == "fromASU"){
      Utils.displaySnack("Trip Requested and Added to Cart, Confirm Payment before ${trip['date'].substring(0,10)} 01:00PM", context);
    }
    else{
      Utils.displaySnack("Trip Requested and Added to Cart, Confirm Payment before ${trip['date'].substring(0,10)} 10:00PM", context);
    }
    FirebaseFirestore.instance.collection('reservations').add(
      {
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'tripId': trip['id'],
        'status': 'pending',
        'paymentStatus': 'pending',
        'paymentMethod': '',
      }
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
          .where('uid', whereNotIn: pastTripsIds)
          // .where('driverId', isNotEqualTo: userId)
          .where('status', isEqualTo: 'upcoming')
          .where('rideType', isEqualTo: rideType)
          .get();
    }
    else{
      querySnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('driverId', isNotEqualTo: userId)
          .where('status', isEqualTo: 'upcoming')
          .where('rideType', isEqualTo: rideType)
          .get();
    }
    List<Map<String, dynamic>> trips = [];
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      Map<String, dynamic> driverData = await getDriverData(data['driverId']);
      data['driverName'] = driverData['username'];
      data['driverPhone'] = driverData['phone'];
      data['driverVehicleType'] = driverData['vehicleType'];
      data['driverVehicleColor'] = driverData['vehicleColor'];
      data['driverVehicleModel'] = driverData['vehicleModel'];
      data['driverVehiclePlates'] = driverData['vehiclePlates'];
      data['addedToCart'] = false;

      if(data['driverId'] == userId){
        continue;
      }
      trips.add(data);
    }
    return trips;
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
          "No Trips Match Your Date and Destination",
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
                  const Icon(Icons.attach_money),
                  Text(
                    snapshot['price'].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.person),
                  Text(
                    snapshot['passengersCount'].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  snapshot['addedToCart']?
                  const Icon(Icons.check_circle, color: Colors.green, size: 20,)
                      :ElevatedButton.icon(
                    onPressed: () {
                      addToCart(snapshot);
                      setState(() {
                        filteredTrips.remove(snapshot);
                      });
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text("Add to Cart"),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.green),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, "/home",arguments: {"tripToView": snapshot});
                      setState(() {});
                    },
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text("View Trip"),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rideType = (ModalRoute.of(context)!.settings.arguments as Map)['rideType'];
      FocusScope.of(context).requestFocus(rideType == "fromASU" ? dropoffFocus : pickupFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, "/home"),
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(
              Icons.access_time_filled_sharp,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(
              width: 10,
            ),
            const Text(
              "Trip Start Time: ",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontStyle: FontStyle.italic),
            ),
            Text(
              rideType == "toASU" ? "07:30 AM" : "05:30 PM",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Column(children: [
              // const SizedBox(height: 10),
              AbsorbPointer(
                absorbing: rideType == "fromASU" ? true : false,
                child: Opacity(
                  opacity: rideType == "fromASU" ? 0.5 : 1,
                  child: GooglePlaceAutoCompleteTextField(
                    focusNode: pickupFocus,
                    textEditingController: pickupTextEditingController,
                    googleAPIKey: googleMapApiKeyAndroid,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    inputDecoration: InputDecoration(
                      labelText: rideType == "fromASU"
                          ? "Faculty of Engineering, Ain Shams University"
                          : "Search Pickup Location",
                      labelStyle:
                          const TextStyle(fontSize: 20, color: Colors.white),
                      contentPadding: const EdgeInsets.fromLTRB(22, 12, 0, 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                        borderSide: const BorderSide(
                          width: 2,
                          color: Colors.purple,
                        ),
                      ),
                      suffixIcon: const Icon(Icons.location_pin),
                    ),
                    boxDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    debounceTime: 800,
                    countries: const ["eg"],
                    getPlaceDetailWithLatLng: (Prediction prediction) {
                      print("placeDetails${prediction.lng}");
                    },
                    itemClick: (Prediction prediction) {
                      pickupTextEditingController.text =
                          prediction.description!;
                      pickupTextEditingController.selection =
                          TextSelection.fromPosition(TextPosition(
                              offset: prediction.description!.length));
                    },
                    // if we want to make custom list background
                    // listBackgroundColor: Colors.black,
                    itemBuilder: (context, index, Prediction prediction) {
                      return Card(
                        color: Colors.white24,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on),
                              const SizedBox(
                                width: 7,
                              ),
                              Expanded(
                                  child: Text(prediction.description ?? "",
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.white))),
                            ],
                          ),
                        ),
                      );
                    },
                    seperatedBuilder: const Divider(
                      height: 1,
                    ),
                    isCrossBtnShown: rideType == "fromASU" ? false : true,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              AbsorbPointer(
                absorbing: rideType == "toASU" ? true : false,
                child: Opacity(
                  opacity: rideType == "toASU" ? 0.5 : 1,
                  child: GooglePlaceAutoCompleteTextField(
                    focusNode: dropoffFocus,
                    textEditingController: dropoffTextEditingController,
                    googleAPIKey: googleMapApiKeyAndroid,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    inputDecoration: InputDecoration(
                      labelText: rideType == "toASU"
                          ? "Faculty of Engineering, Ain Shams University"
                          : "Search Drop-off Location",
                      labelStyle:
                          const TextStyle(fontSize: 20, color: Colors.white),
                      contentPadding: const EdgeInsets.fromLTRB(22, 12, 0, 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                        borderSide: const BorderSide(
                          width: 2,
                          color: Colors.purple,
                        ),
                      ),
                      suffixIcon: const Icon(Icons.location_pin),
                    ),
                    boxDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    debounceTime: 800,
                    countries: const ["eg"],
                    getPlaceDetailWithLatLng: (Prediction prediction) {
                      print("placeDetails${prediction.lng}");
                    }, // this callback is called when isLatLngRequired is true
                    itemClick: (Prediction prediction) {
                      dropoffTextEditingController.text =
                          prediction.description!;
                      dropoffTextEditingController.selection =
                          TextSelection.fromPosition(TextPosition(
                              offset: prediction.description!.length));
                    },
                    // if we want to make custom list item builder
                    itemBuilder: (context, index, Prediction prediction) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on),
                            const SizedBox(
                              width: 7,
                            ),
                            Expanded(
                                child: Text(prediction.description ?? "",
                                    style: const TextStyle(
                                        fontSize: 18, color: Colors.white))),
                          ],
                        ),
                      );
                    },
                    seperatedBuilder: const Divider(
                      height: 1,
                    ),
                    isCrossBtnShown: rideType == "toASU" ? false : true,
                  ),
                ),
              ),
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
                          "No Trips Match Your Date and Destination",
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
            Positioned(
              top: 42,
              right: 7,
              child: GestureDetector(
                onTap: toggleRideType,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Transform.rotate(
                    angle: -1.5708,
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
