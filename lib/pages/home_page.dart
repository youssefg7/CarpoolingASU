import 'package:carpool_flutter/data/Models/ReservationModel.dart';
import 'package:carpool_flutter/data/Models/UserModel.dart';
import 'package:carpool_flutter/data/Repositories/ReservationRepository.dart';
import 'package:carpool_flutter/data/Repositories/TripRepository.dart';
import 'package:carpool_flutter/data/Repositories/UserRepository.dart';
import 'package:carpool_flutter/pages/view_route_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Utilities/utils.dart';
import '../data/Models/TripModel.dart';
import 'package:badges/badges.dart' as badge;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ReservationRepository reservationRepository = ReservationRepository();
  UserRepository userRepository = UserRepository();
  TripRepository tripRepository = TripRepository();
  String rideType = "toASU";
  List<Map<String, dynamic>> filteredTrips = [];

  Student user = Student(
    id: '',
    username: '',
    email: '',
    phone: '',
    isDriver: false,
  );

  getUserInfo() async {
    user = await userRepository.getCurrentUser();
    setState(() {
      user = user;
    });
  }

  Future<List<Map<String, dynamic>>> getFullData(List<Trip>? trips) async{
    Map<String, dynamic> data = {};
    List<Map<String, dynamic>> fullData = [];
    for(Trip trip in trips!){
      data['trip'] = trip;
      data['driver'] = await userRepository.getUser(trip.driverId);
      data['addedToCart'] = false;
      fullData.add(data);
    }
    return fullData;
  }

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
          DateTime.now().month, DateTime.now().day, 22, 00))) {
        initialDay = DateTime(now.year, now.month, now.day + 2);
      } else {
        initialDay = DateTime(now.year, now.month, now.day + 1);
      }
    } else {
      if (DateTime.now().isAfter(DateTime(DateTime.now().year,
          DateTime.now().month, DateTime.now().day, 13, 00))) {
        initialDay = DateTime(now.year, now.month, now.day + 1);
      } else {
        initialDay = now;
      }
    }

    return showDatePicker(
      context: context,
      initialDate: initialDay,
      firstDate: initialDay,
      lastDate: DateTime.now().add(const Duration(days: 365)),
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


  List<Map<String, dynamic>> filterTripsByDate(List<Map<String, dynamic>> tripsData, DateTime? tripDate){
    List<Map<String, dynamic>> filteredTrips = [];
    if(tripDate == null){
      return tripsData;
    }
    for(Map<String, dynamic> tripData in tripsData){
      if(tripData['trip'].date.isBefore(DateTime.now())){
        Trip t = tripData['trip'];
        t.status = 'completed';
        tripRepository.updateTrip(t);
        continue;
      }
      else if(tripData['trip'].rideType == 'fromASU' && tripData['trip'].date == DateTime.now() && DateTime.now().hour > 13){
        continue;
      }else if(tripData['trip'].rideType == 'toASU' && tripData['trip'].date == DateTime.now() && DateTime.now().hour > 22){
        continue;
      }
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
          "No Trips Match Date and Destination",
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
      padding: const EdgeInsets.all(3),
      child: Card(
        elevation: 10,
        shadowColor: Colors.black,
        color: Colors.black,
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
                  trip.rideType == 'fromASU'? const Icon(Icons.door_sliding_outlined,):const SizedBox(),
                  Text(
                    trip.rideType == 'fromASU'
                        ? trip.gate.toString()
                        : '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
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
                  trip.rideType == 'toASU'? const Icon(Icons.door_sliding_outlined,):const SizedBox(),
                  Text(
                    trip.rideType == 'toASU'
                        ? trip.gate.toString()
                        : '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
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
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context,
                      MaterialPageRoute(
                          builder: (context) => ViewRoutePage(trip: trip)))
                      .then((value) {
                        setState(() {});
                      });
                    },
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text("View Trip Route"),
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
    getUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: () async{
          if(!(await Utils.checkInternetConnection(context))) {
            return;}
          Navigator.pushNamed(context, "/cart");
        },
        child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: const [
                BoxShadow(
                  color: Colors.blueAccent,
                  blurRadius: 5,
                  spreadRadius: 0.1,
                )
              ],
            ),
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 35,
              child: Icon(
                Icons.shopping_cart,
                color: Colors.black,
                size: 35,
              ),
            )),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      drawer: Container(
        width: 255,
        color: Colors.black,
        child: Drawer(
          backgroundColor: Colors.white10,
          child: ListView(padding: EdgeInsets.zero, children: [
            const SizedBox(
              height: 50,
            ),
            ListTile(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/profile');
              },
              leading: const Icon(
                Icons.person,
                color: Colors.white,
                size: 40,
              ),
              title: Text(
                user.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ListTile(
              onTap: (){
                Navigator.pushNamed(context, '/history');
              },
              leading: const Icon(
                Icons.receipt_outlined,
                color: Colors.white,
                size: 34,
              ),
              title: const Text(
                "Trips History",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Divider(
              height: 1,
              color: Colors.white,
              thickness: 1,
            ),
            const SizedBox(
              height: 10,
            ),
            ListTile(
              onTap: () {
                FirebaseAuth.instance.signOut();
                userRepository.deleteCurrentUser();
                Navigator.pushReplacementNamed(context, '/login');
              },
              leading: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.logout,
                  color: Colors.grey,
                ),
              ),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
            ),
          ]),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Card(
                elevation: 10,
                shadowColor: Colors.black,
                color: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.white24, width: 3),
                ),
                child: Padding(
                    padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ASUFE CARPOOL COMMUNITY",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Text(
                            "Hello, ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user.username.split(" ")[0],
                            style: TextStyle(
                              color: Colors.lightBlue.shade300,
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(" !",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                    ])
              ),
              ),
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
            "Request your next trip now:",
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
            ),
          ),
              ),
          badge.Badge(
            position: badge.BadgePosition.topEnd(),
            badgeStyle: const badge.BadgeStyle(
              badgeColor: Colors.white,
              shape: badge.BadgeShape.circle,
            ),
            badgeContent: GestureDetector(
              onTap: toggleRideType,
              child: const Icon(
                Icons.compare_arrows_rounded,
                color: Colors.black,
                size: 40,
              ),
            ),
            child: Card(
              elevation: 10,
              shadowColor: Colors.black,
              color: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white24, width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
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
              ),
            ),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: callDatePicker,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.date_range,
                    color: Colors.white70,
                    size: 22,
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
                        fontSize: 20,
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.white, width: 3),
                ),
                color: Colors.black26,
                child: FutureBuilder<List<Reservation>>(
                  future: reservationRepository.getReservations(),
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Error Loading Available Trips',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Trips Match Date and Destination",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else {
                      List<String> ids = snapshot.data!.map((e) => e.tripId).toList();
                      print("ids length: ${ids.length}");
                      return StreamBuilder<List<Trip>>(
                          stream: tripRepository.getTripsByIdsAndStatusStream(ids, 'upcoming', rideType),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return const Center(
                                child: Text(
                                  'Error Loading Available Trips',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No Trips Match Date and Destination",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            } else {
                              List<Map<String, dynamic>> full = [];
                              // exclude trips that user is driver
                              List<Trip> trips = snapshot.data!.where((element) => element.driverId != user.id).toList();
                              tripRepository.orderTripsByDate(trips, true);
                              for(Trip trip in trips){
                                Map<String, dynamic> data = {};
                                data['trip'] = trip;
                                data['addedToCart'] = false;
                                full.add(data);
                              }

                              filteredTrips = filterTripsByDate(full, tripDate);
                              return buildTripsList(filteredTrips);
                            }
                          },
                      );
                    }
                  },

    )



                // FutureBuilder<List<Map<String, dynamic>>>(
                //   future: getTripsData(),
                //   builder: (context, snapshot) {
                //     if (snapshot.connectionState == ConnectionState.waiting) {
                //       return const Center(child: CircularProgressIndicator());
                //     } else if (snapshot.hasError) {
                //       return const Center(
                //         child: Text(
                //           'Error Loading Available Trips',
                //           style: TextStyle(color: Colors.red),
                //         ),
                //       );
                //     } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                //       return const Center(
                //         child: Text(
                //           "No Trips Match Date and Destination",
                //           style: TextStyle(
                //             fontSize: 20,
                //             color: Colors.white,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //       );
                //     } else {
                //       filteredTrips = filterTripsByDate(snapshot.data!, tripDate);
                //       return buildTripsList(filteredTrips);
                //     }
                //   },
                // ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
