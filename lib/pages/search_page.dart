import 'package:carpool_flutter/data/Models/ReservationModel.dart';
import 'package:carpool_flutter/data/Models/UserModel.dart';
import 'package:carpool_flutter/data/Repositories/ReservationRepository.dart';
import 'package:carpool_flutter/data/Repositories/TripRepository.dart';
import 'package:carpool_flutter/data/Repositories/UserRepository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Utilities/utils.dart';
import '../data/Models/TripModel.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  ReservationRepository reservationRepository = ReservationRepository();
  UserRepository userRepository = UserRepository();
  TripRepository tripRepository = TripRepository();
  String rideType = "toASU";

  List<Map<String, dynamic>> filteredTrips = [];

  void toggleRideType() {
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


  addToCart(Trip trip) async {
    if(rideType == "fromASU"){
      Utils.displaySnack("Trip Requested and Added to Cart, Confirm Payment before ${Utils.formatDate(trip.date)} 01:00PM", context);
    }
    else{
      Utils.displaySnack("Trip Requested and Added to Cart, Confirm Payment before ${Utils.formatDate(trip.date)} 10:00PM", context);
    }
    Reservation reservation = Reservation(
      userId: FirebaseAuth.instance.currentUser!.uid,
      tripId: trip.id,
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: '',
    );
    await reservationRepository.addReservation(reservation);
  }


  Future<List<Map<String, dynamic>>> getTripsData() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;

    List<Trip> trips = await tripRepository.searchTrips(userId!, rideType);
    List<Map<String, dynamic>> tripsData = [];
    for (Trip trip in trips) {
      Map<String,dynamic> data = {};
      data['trip'] = trip;
      Student? driver = await userRepository.getUser(trip.driverId);
      if(driver?.id == userId){
        continue;
      }
      data['driver'] = driver;
      data['addedToCart'] = false;

      tripsData.add(data);
    }
    return tripsData;
  }

  List<Map<String, dynamic>> filterTripsByDate(List<Map<String, dynamic>> tripsData, DateTime? tripDate){
    List<Map<String, dynamic>> filteredTrips = [];
    if(tripDate == null){
      return tripsData;
    }
    for(Map<String, dynamic> tripData in tripsData){
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
    Trip trip = snapshot['trip'];
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
                  const Icon(Icons.attach_money),
                  Text(
                    trip.price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.person),
                  Text(
                    trip.passengersCount.toString(),
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
                    onPressed: () async {
                      await addToCart(trip);
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
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 5,
                          spreadRadius: 0.5,
                          offset: Offset(0, 5),
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 35,
                      child: rideType=="fromASU"? const Image(
                        image: AssetImage("assets/images/logo.png"),
                      ):
                      const Icon(
                        Icons.home,
                        color: Colors.black,
                        size: 35,
                      )
                      ,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 40,
                  ),
                  Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 5,
                            spreadRadius: 0.5,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 35,
                        child: rideType=="toASU"? const Image(
                          image: AssetImage("assets/images/logo.png"),
                        ):
                        const Icon(
                          Icons.home,
                          color: Colors.black,
                          size: 35,
                        )
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 15),
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
              top: 22,
              right: 7,
              child: GestureDetector(
                onTap: toggleRideType,
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child:  Icon(
                    Icons.compare_arrows_rounded,
                    color: Colors.black,
                    size: 40,
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
