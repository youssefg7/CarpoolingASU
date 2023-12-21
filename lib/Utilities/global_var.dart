import 'package:google_maps_flutter/google_maps_flutter.dart';

const String googleMapApiKeyAndroid = "AIzaSyAPhZVDY0YJjn1wiBjISM-oJqpToPMBatk";
const String googleMapApiKeyIos = "AIzaSyA5yBMwjGB5eyJdX1I90G4kLvZduxqEAVc";
const String googleMapApiKeyBrowser = "AIzaSyBTqNN8VFu5aUbvSE2_M6SHBo5mJTrw-1k";

const LatLng defaultLocation = LatLng(30.064554, 31.2788107);


const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: defaultLocation,
  zoom: 14.4746,
);