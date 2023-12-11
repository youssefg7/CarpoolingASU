import 'dart:async';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'global_var.dart';
import 'dart:convert' as convert;

class LocationServices extends GetxController{

  static Future<String> getPlaceId(String input) async{
    final String url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$googleMapApiKeyAndroid';
    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var placeId = json['candidates'][0]['place_id'];
    print(placeId);
    return placeId;
  }

  static Future<Map<String,dynamic>> getPlace(String input) async{
    final placeId = await getPlaceId(input);
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleMapApiKeyAndroid';
    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var results = json['result'] as Map<String,dynamic>;
    return results;
  }


  static Future<Map<String,dynamic>> getRoute(LatLng start, LatLng end) async{
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$googleMapApiKeyAndroid';
    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var results = json['routes'][0]['legs'][0] as Map<String,dynamic>;
    return results;
  }

  static Future<Map<String, dynamic>> getDirections(LatLng origin, LatLng destination) async {
    Map<String, dynamic> data = {};
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleMapApiKeyAndroid';
    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    List<dynamic> list = json['routes'];
    var points = list[0]['overview_polyline']['points'];

    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(points);
    for (PointLatLng point in result) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }
    data['points'] = polylineCoordinates;
    data['bounds'] = LatLngBounds(
      northeast: LatLng(json['routes'][0]['bounds']['northeast']['lat'], json['routes'][0]['bounds']['northeast']['lng']),
      southwest: LatLng(json['routes'][0]['bounds']['southwest']['lat'], json['routes'][0]['bounds']['southwest']['lng']),
    );
    return data;
  }


}
