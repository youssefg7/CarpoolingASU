import 'dart:async';
import 'dart:convert';
import 'package:carpool_flutter/Utilities/global_var.dart';
import 'package:carpool_flutter/data/Models/ReservationModel.dart';
import 'package:carpool_flutter/data/Models/UserModel.dart';
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

import '../data/Models/TripModel.dart';
import '../data/Repositories/ReservationRepository.dart';
import '../data/Repositories/UserRepository.dart';

class ViewRoutePage extends StatefulWidget {
  final Trip trip;
  const ViewRoutePage({super.key, required this.trip});

  @override
  State<ViewRoutePage> createState() => _ViewRoutePageState();
}

class _ViewRoutePageState extends State<ViewRoutePage> {
  ReservationRepository reservationRepository = ReservationRepository();
  UserRepository userRepository = UserRepository();
  final Completer<GoogleMapController> googleMapControllerCompleter =
      Completer<GoogleMapController>();
  late GoogleMapController googleMapController;
  Set<Marker> markers = {};
  PolylinePoints polylinePoints = PolylinePoints();
  final List<Polyline> polylines = [];
  late LatLng pickupLatLng;
  late LatLng dropoffLatLng;
  late Trip tripDetails = widget.trip;
  bool addedToCart = false;
  PanelController panelController = PanelController();
  Position? currentUserPosition;
  LatLng? currentUserLatLng;
  bool alreadyAdded = false;
  Student driver = Student(
    id: '',
    username: '',
    email: '',
    phone: '',
    isDriver: false,
  );

  getDriverInfo() async {
    driver = (await userRepository.getUser(tripDetails.driverId))!;
    setState(() {
      driver = driver;
    });
  }

  @override
  void dispose() {
    googleMapController.dispose();
    super.dispose();
  }

  addToCart() async {
    if(tripDetails.rideType == "fromASU"){
      Utils.displaySnack("Trip Requested and Added to Cart, Confirm Payment before ${Utils.formatDate(tripDetails.date)} 01:00PM", context);
    }
    else{
      Utils.displaySnack("Trip Requested and Added to Cart, Confirm Payment before ${Utils.formatDate(tripDetails.date)} 10:00PM", context);
    }

    Reservation reservation = Reservation(
      id: '',
      tripId: tripDetails.id,
      userId: FirebaseAuth.instance.currentUser!.uid,
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: '',
    );
    reservationRepository.addReservation(reservation);

    setState(() {
      addedToCart = true;
    });
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

  Future<void> addTripRoute(Trip trip) async {
    FocusManager.instance.primaryFocus?.unfocus();
    String rideType = trip.rideType;
    if (rideType == "fromASU") {
      pickupLatLng = defaultLocation;
      dropoffLatLng = LatLng(trip.destinationLat, trip.destinationLng);
    }
    else {
      pickupLatLng = LatLng(trip.startLat, trip.startLng);
      dropoffLatLng = defaultLocation;
    }
    clearMap();
    LocationServices.getDirections(pickupLatLng, dropoffLatLng)
        .then((value) async {
      addPolyLine(value["points"]);
      await googleMapController.animateCamera(CameraUpdate.newLatLngBounds(value['bounds'], 30));
        Marker origin = Marker(
          markerId: const MarkerId("origin"),
          infoWindow: const InfoWindow(title: "Trip Start"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          position: pickupLatLng,
        );
      Marker destination = Marker(
          markerId: const MarkerId("destination"),
          infoWindow: const InfoWindow(title: "Trip End"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: dropoffLatLng,
        );
      setState(() {
        markers.add(origin);
        markers.add(destination);
        addPolyLine(value["points"]);
        panelController.open();
      });
    });
  }

  getCurrentLocation() async {
    currentUserPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentUserLatLng =
        LatLng(currentUserPosition!.latitude, currentUserPosition!.longitude);
    CameraPosition cameraPosition =
    CameraPosition(target: currentUserLatLng!, zoom: 14.4746);
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }




  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addTripRoute(tripDetails);
      getDriverInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(children: [
                  const Icon(Icons.date_range_sharp,
                      color: Colors.black),
                  const SizedBox(width: 5),
                  Text(
                      Utils.formatDate(tripDetails.date),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ]),
                Row(
                  children: [
                    const Icon(Icons.watch_later_outlined,
                        color: Colors.black),
                    const SizedBox(width: 5),
                    Text(
                        tripDetails.rideType ==
                            'toASU'
                            ? '07:30 AM'
                            : '05:30 PM',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                )
              ]),
          centerTitle: true,
          leading:
          IconButton(
              onPressed: (){
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black))
        ),
        body: SlidingUpPanel(
          controller: panelController,
          color: Colors.black,
          backdropEnabled: false,
          backdropOpacity: 0.4,
          backdropTapClosesPanel: true,
          minHeight: 0.2 * MediaQuery.of(context).size.height,
          maxHeight: 0.32 * MediaQuery.of(context).size.height,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          body: GoogleMap(
            padding: EdgeInsets.only(bottom: (0.4 * MediaQuery.of(context).size.height)),
            myLocationEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            markers: markers,
            onMapCreated: (GoogleMapController controller) {
              setState(() {
                googleMapController = controller;
              });
              googleMapControllerCompleter.complete(controller);
            },
            polylines: Set.from(polylines),
          ),
          panel: Card(
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
                          child: Text("From: ${tripDetails.start}",
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.black)),
                        ),
                        tripDetails.rideType == 'fromASU'? const Icon(Icons.door_sliding_outlined, color: Colors.black,):const SizedBox(),
                        Text(
                          tripDetails.rideType == 'fromASU'
                              ? tripDetails.gate.toString()
                              : '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      ]),
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.location_pin, color: Colors.black),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text("To: ${tripDetails.destination}",
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.black)),
                        ),
                        tripDetails.rideType == 'toASU'? const Icon(Icons.door_sliding_outlined, color: Colors.black,):const SizedBox(),
                        Text(
                          tripDetails.rideType == 'toASU'
                              ? tripDetails.gate.toString()
                              : '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      ]),
                      const SizedBox(height: 10),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.route, color: Colors.black),
                            Text(
                                tripDetails.distance,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            const SizedBox(width: 10),
                            const Icon(Icons.drive_eta, color: Colors.black),
                            Text(
                                tripDetails.duration,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            const SizedBox(width: 10),
                            const Icon(Icons.attach_money, color: Colors.black),
                            Text(tripDetails.price,
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
                                  await Utils.makePhoneCall(driver.phone);
                                }),
                            const Icon(Icons.person, color: Colors.black),
                            const SizedBox(width: 10),
                            Text(driver.username, style: const TextStyle(fontSize: 18, color: Colors.black)),
                          ]
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(driver.vehicleType=='Car'?Icons.directions_car:Icons.motorcycle_outlined, color: Colors.red),
                          const SizedBox(width: 10),
                          Text("${driver.vehicleColor} ${driver.vehicleModel}", style: const TextStyle(fontSize: 18, color: Colors.black)),
                          const Text(" - ", style: TextStyle(fontSize: 18, color: Colors.black)),
                          Text("(${driver.vehiclePlates})", style: const TextStyle(fontSize: 18, color: Colors.black)),
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
                        onPressed: addedToCart?null:addToCart,
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
              )),
        ));
  }
}
