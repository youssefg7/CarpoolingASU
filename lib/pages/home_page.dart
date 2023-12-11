import 'dart:async';
import 'dart:convert';
import 'package:carpool_flutter/Utilities/global_var.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../Utilities/location_serives.dart';
import '../Utilities/utils.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapControllerCompleter =
      Completer<GoogleMapController>();
  late GoogleMapController googleMapController;
  Position? currentUserPosition;
  LatLng? currentUserLatLng;
  Set<Marker> markers = {};
  Marker? origin;
  Marker? destination;
  PolylinePoints polylinePoints = PolylinePoints();
  final List<Polyline> polylines = [];
  List<LatLng> routeCoords = [];
  GlobalKey<ScaffoldState> sandwichKey = GlobalKey<ScaffoldState>();
  GlobalKey<ScaffoldState> cartKey = GlobalKey<ScaffoldState>();
  bool serviceEnabled = false;
  Map<String, dynamic> userInfo = {};
  int price = 0;
  String duration = "0 mins";
  String distance = "0 kms";
  late Prediction currentPrediction;
  late LatLng pickupLatLng;
  late LatLng dropoffLatLng;
  PanelController panelController = PanelController();

  FocusNode pickupFocus = FocusNode();
  FocusNode dropoffFocus = FocusNode();
  bool floatingButtonVisibility = true;
  bool isTripView = false;
  late Map<String, dynamic> tripDetails;
  bool addedToCart = false;

  @override
  void dispose() {
    googleMapController.dispose();
    super.dispose();
  }

  addToCart(){
    setState(() {
      addedToCart = true;
    });
    if(tripDetails['rideType'] == "fromASU"){
      Utils.displayToast("Trip Requested and Added to Cart, Confirm Payment before ${tripDetails['date'].substring(0,10)} 01:00PM", context);
    }
    else{
      Utils.displayToast("Trip Requested and Added to Cart, Confirm Payment before ${tripDetails['date'].substring(0,10)} 10:00PM", context);
    }
  }

  updateMapStyle(
      GoogleMapController googleMapController, String mapStyleName) async {
    ByteData byteData =
        await rootBundle.load('lib/map_styles/${mapStyleName}_style.json');
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    var decodedList = utf8.decode(list);
    googleMapController.setMapStyle(decodedList);
  }

  getCurrentLocation() async {
    currentUserPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentUserLatLng =
        LatLng(currentUserPosition!.latitude, currentUserPosition!.longitude);
    // CameraPosition cameraPosition =
    //     CameraPosition(target: currentUserLatLng!, zoom: 15);
    // googleMapController
    //     .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  getUserInfo() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
        setState(() {
          userInfo = data;
        });
      } else {
        FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // Handle any potential errors
      Utils.displayToast('Error fetching user data: $e',context);
    }
  }


  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 4,
    );
    setState(() {
      polylines.add(polyline);
    });
  }

  void clearMap() {
    setState(() {
      markers.clear();
      polylines.clear();
    });
  }

  Future<void> addTripRoute(Map<String, dynamic> snapshot) async {
    FocusManager.instance.primaryFocus?.unfocus();
    String rideType = snapshot['rideType'];
    if (rideType == "fromASU") {
      pickupLatLng = defaultLocation;
      dropoffLatLng = LatLng(
          double.parse(snapshot['destinationLat']),
          double.parse(snapshot['destinationLng']));
    }
    else {
      pickupLatLng = LatLng(
          double.parse(snapshot['startLat']),
          double.parse(snapshot['startLng']));
      dropoffLatLng = defaultLocation;
    }
    clearMap();
    LocationServices.getDirections(pickupLatLng, dropoffLatLng)
        .then((value) async {
      addPolyLine(value["points"]);
      await googleMapController.animateCamera(CameraUpdate.newLatLngBounds(value['bounds'], 30));
      setState(() {
        origin = Marker(
          markerId: const MarkerId("origin"),
          infoWindow: const InfoWindow(title: "Trip Start"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          position: pickupLatLng,
        );
        destination = Marker(
          markerId: const MarkerId("destination"),
          infoWindow: const InfoWindow(title: "Trip End"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: dropoffLatLng,
        );
        markers.add(origin!);
        markers.add(destination!);
        addPolyLine(value["points"]);
      });
      setState(() {
        isTripView = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    getUserInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)!.settings.arguments != null) {
        var args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        var trip = args['tripToView'] as Map<String, dynamic>;
        addTripRoute(trip);
        setState(() {
          tripDetails = trip;
          isTripView = true;
          panelController.open();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: isTripView?Colors.white:Colors.black,
          title: isTripView? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(children: [
                  const Icon(Icons.date_range_sharp,
                      color: Colors.black),
                  const SizedBox(width: 10),
                  Text(
                      tripDetails["date"].substring(0, 10),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ]),
                Row(
                  children: [
                    const Icon(Icons.watch_later_outlined,
                        color: Colors.black),
                    const SizedBox(width: 10),
                    Text(
                        tripDetails["rideType"] ==
                            'toASU'
                            ? '07:30 AM'
                            : '05:30 PM',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                )
              ])
              :const Text(
            "ASUFE CARPOOL",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: isTripView?
          IconButton(
              onPressed: (){
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.black))
              :null,
        ),
        key: sandwichKey,
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
                  Navigator.pushReplacementNamed(context, '/profile',
                      arguments: {"user": userInfo});
                },
                leading: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 40,
                ),
                title: Text(
                  userInfo["username"] ?? "username",
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
              ListTile(
                onTap: (){
                  Navigator.pushReplacementNamed(context, '/wallet');
                },
                leading: const Icon(
                  Icons.monetization_on_outlined,
                  color: Colors.white,
                  size: 34,
                ),
                title: const Text(
                  "Wallet",
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
        body: SlidingUpPanel(
          controller: panelController,
          color: Colors.black,
          backdropEnabled: false,
          backdropOpacity: 0.4,
          backdropTapClosesPanel: true,
          minHeight: 0,
          maxHeight: 0.4 * MediaQuery.of(context).size.height,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          onPanelClosed: () {
            setState(() {
              floatingButtonVisibility = true;
            });
          },
          onPanelOpened: () {
            setState(() {
              floatingButtonVisibility = false;
            });
          },
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Stack(children: [
              GoogleMap(
                padding: floatingButtonVisibility?const EdgeInsets.only(bottom: 80):EdgeInsets.only(bottom: (0.5 * MediaQuery.of(context).size.height)),
                mapType: MapType.normal,
                myLocationEnabled: true,
                initialCameraPosition: googlePlexInitialPosition,
                onCameraMove: (camera){},
                markers: markers,
                onMapCreated: (GoogleMapController controller) {
                  setState(() {
                    googleMapController = controller;
                  });
                  updateMapStyle(controller, 'normal');
                  googleMapControllerCompleter.complete(controller);
                },
                polylines: Set.from(polylines),
              ),
              Positioned(
                bottom: 100,
                  child: floatingButtonVisibility?
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 80,
                    child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, "/cartPage");
                      },
                      child: Container(
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
                          child: const CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: 35,
                            child: Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 35,
                            ),
                          )),
                    ),
                    GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, "/search",
                              arguments: {"rideType": "toASU"});
                        },
                        child: Container(
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
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 35,
                            child: Image(
                              image: AssetImage("assets/images/logo.png"),
                            ),
                          ),
                        )),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, "/search",
                            arguments: {"rideType": "fromASU"});
                      },
                      child: Container(
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
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 35,
                            child: Icon(
                              Icons.home,
                              color: Colors.black,
                              size: 35,
                            ),
                          )),
                    ),
                ],
              ),
                  ):const SizedBox(),
              )
            ]),
          ),
          panel: (isTripView)
              ? Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white24, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: ListView(
                    children: [
                      const Center(
                        child: Text(
                          "View Trip",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(children: [
                        const Icon(Icons.location_pin, color: Colors.black),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text("From: ${tripDetails["start"]}",
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.black)),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.location_pin, color: Colors.black),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text("To: ${tripDetails["destination"]}",
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.black)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.route, color: Colors.black),
                            Text(
                                tripDetails['distance'],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            const SizedBox(width: 10),
                            const Icon(Icons.drive_eta, color: Colors.black),
                            Text(
                                tripDetails['duration'],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            const SizedBox(width: 10),
                            const Icon(Icons.attach_money, color: Colors.black),
                            Text(tripDetails['price'],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ]),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(icon: const Icon(Icons.phone), color: Colors.green,
                                onPressed: () async{
                                  await Utils.makePhoneCall(tripDetails['driverPhone']!);
                                }),
                            const Icon(Icons.person, color: Colors.black),
                            const SizedBox(width: 10),
                            Text(tripDetails['driverName']!, style: const TextStyle(fontSize: 18, color: Colors.black)),
                          ]
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(tripDetails['driverVehicleType']=='Car'?Icons.directions_car:Icons.motorcycle_outlined, color: Colors.red),
                          const SizedBox(width: 10),
                          Text("${tripDetails['driverVehicleColor']!} ${tripDetails['driverVehicleModel']!}", style: const TextStyle(fontSize: 18, color: Colors.black)),
                          const Text(" - ", style: TextStyle(fontSize: 18, color: Colors.black)),
                          Text("(${tripDetails['driverVehiclePlates']!})", style: const TextStyle(fontSize: 18, color: Colors.black)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      addedToCart?
                      ElevatedButton.icon(
                        onPressed: (){

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shadowColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 2,
                              color: Colors.green,
                            ),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          padding:
                          const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        ),
                        icon: const Icon(
                          Icons.check,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Added to Cart",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ):
                      ElevatedButton.icon(
                        onPressed: addToCart,
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
                          const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        ),
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Add to Cart",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ))
              : const SizedBox(),
        ));
  }
}
