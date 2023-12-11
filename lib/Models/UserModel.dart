class UserModel{
  String id;
  String username;
  String email;
  String phone;
  String? image;
  bool isDriver;
  String? vehicleType;
  String? vehicleModel;
  String? vehicleColor;
  String? vehiclePlates;



  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    this.image,
    required this.isDriver,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleColor,
    this.vehiclePlates
  });

  UserModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'],
        email = json['email'],
        phone = json['phone'],
        image = json['image'],
        isDriver = json['isDriver'],
        vehicleType = json['vehicleType'],
        vehicleModel = json['vehicleModel'],
        vehicleColor = json['vehicleColor'],
        vehiclePlates = json['vehiclePlates'];

  Map<String,dynamic> toJSON(){
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'image': image,
      'isDriver': isDriver,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'vehiclePlates': vehiclePlates,
    };
  }
}