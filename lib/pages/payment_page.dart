import 'package:carpool_flutter/data/Repositories/CreditCardRepository.dart';
import 'package:carpool_flutter/data/Repositories/ReservationRepository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../Utilities/utils.dart';
import '../data/Models/CreditCardModel.dart';
import '../data/Models/ReservationModel.dart';
import '../data/Models/TripModel.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Trip trip ;
  late Reservation reservation;
  bool saveCard = false;
  List<CreditCard> savedCards = [];
  CreditCard? selectedCreditCard;
  ReservationRepository reservationRepository = ReservationRepository();
  CreditCardRepository creditCardRepository = CreditCardRepository();

  Future<List<CreditCard>> getStoredCards() async {
    return await creditCardRepository.getCreditCards();
  }

  late Map<String, dynamic> tripDetails;
  String paymentMethod = 'cash';
  bool _submitted = false;
  final _formKey = GlobalKey<FormState>();
  TextEditingController cardNumberController = TextEditingController();
  TextEditingController cardHolderNameController = TextEditingController();
  TextEditingController expiryMonthController = TextEditingController();
  TextEditingController expiryYearController = TextEditingController();
  TextEditingController cvvController = TextEditingController();

  pay(){
    setState(() {
      _submitted = true;
    });
    if(paymentMethod == 'cash'){
      reservation.paymentStatus = 'paid';
      reservation.paymentMethod = 'cash';
      reservationRepository.updateReservation(reservation);

      Navigator.pop(context);
      Utils.displayToast("Request Sent, Wait for Driver Confirmation!", context, toastLength: Toast.LENGTH_LONG);
      return;
    }else{
      if (selectedCreditCard == null){
        if(_formKey.currentState!.validate()){
          reservation.paymentStatus = 'paid';
          reservation.paymentMethod = 'creditCard';
          reservationRepository.updateReservation(reservation);
          if(saveCard){
            CreditCard creditCard = CreditCard(
              id: '',
              userId: FirebaseAuth.instance.currentUser!.uid,
              cardNumber: cardNumberController.text,
              cardHolderName: cardHolderNameController.text,
              expiryMonth: int.parse(expiryMonthController.text),
              expiryYear: int.parse(expiryYearController.text),
              cvv: cvvController.text,
            );
            creditCardRepository.addCreditCard(creditCard);
          }
          Navigator.pop(context);
          Utils.displayToast("Request Sent, Wait for Driver Confirmation!", context, toastLength: Toast.LENGTH_LONG);
          return;
        }
      }
      else{
        reservation.paymentStatus = 'paid';
        reservation.paymentMethod = 'creditCard';
        reservationRepository.updateReservation(reservation);
        Navigator.pop(context);
        Utils.displayToast("Request Sent, Wait for Driver Confirmation!", context, toastLength: Toast.LENGTH_LONG);
        return;
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    tripDetails = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    trip = tripDetails['trip'];
    reservation = tripDetails['reservation'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Page'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      // body: const Center(
      //   child: Text('Payment Page'),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            const SizedBox(
              height: 10,
            ),
            Card(
              elevation: 10,
              shadowColor: Colors.black,
              color: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white24, width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Card(
                elevation: 10,
                shadowColor: Colors.black,
                color: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.white24, width: 3),
                ),
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(children: <Widget>[
                      ListTile(
                        title: const Text('Cash'),
                        leading: Radio<String>(
                          value: 'cash',
                          groupValue: paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              paymentMethod = value!;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('Credit Card'),
                        leading: Radio<String>(
                          value: 'creditCard',
                          groupValue: paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              paymentMethod = value!;
                            });
                          },
                        ),
                      ),
                    ]))),
            paymentMethod == 'creditCard'
            ?
            FutureBuilder(
                future: getStoredCards(),
                builder:
                    (BuildContext context, AsyncSnapshot<List<CreditCard>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error'),
                    );
                  }
                  else {
                    if(snapshot.data!.isEmpty){
                      return const SizedBox();
                    }

                    savedCards = snapshot.data!;
                    return DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: "Choose from Saved Credit Cards",
                        labelStyle: const TextStyle(fontSize: 16),
                        prefixIcon: const Icon(Icons.credit_card),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: const BorderSide(
                            width: 2,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      items: savedCards.map((e) =>
                          DropdownMenuItem(
                              value: e,
                              child: Text(
                                  "**** **** **** ${e.cardNumber.substring(
                                      12, 15)}"))).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCreditCard = value;
                        });
                      },);
                  }
                }
            )
            : const SizedBox(),
            paymentMethod == 'creditCard'
                ? Card(
                    elevation: 10,
                    shadowColor: Colors.black,
                    color: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.white24, width: 3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Credit Card Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextFormField(
                              controller: cardNumberController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(16),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Card Number',
                              ),
                              autovalidateMode: _submitted
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter card number';
                                }else if(value.length != 16){
                                  return 'Please enter a valid card number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: cardHolderNameController,
                              decoration: const InputDecoration(
                                labelText: 'Card Holder Name',
                              ),
                              autovalidateMode: _submitted
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter card holder name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: expiryMonthController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(2),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Expiry Month',
                                    ),
                                    autovalidateMode: _submitted
                                        ? AutovalidateMode.onUserInteraction
                                        : AutovalidateMode.disabled,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter expiry month';
                                      }else if(int.parse(value)>12 || int.parse(value)<1){
                                        return 'Please enter a valid expiry month';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: expiryYearController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Expiry Year',
                                    ),
                                    autovalidateMode: _submitted
                                        ? AutovalidateMode.onUserInteraction
                                        : AutovalidateMode.disabled,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter expiry year';
                                      } else if(int.parse(value)<DateTime.now().year || int.parse(value)>DateTime.now().year+10){
                                        return 'Please enter a valid expiry year';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: cvvController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                              ),
                              autovalidateMode: _submitted
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter CVV';
                                } else if(int.parse(value)<100 || int.parse(value)>999){
                                  return 'Please enter a valid CVV';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Checkbox(
                                  value: saveCard,
                                  onChanged: (value) {
                                    setState(() {
                                      saveCard = value!;
                                    });
                                  },
                                ),
                                const Text('Save Card for future payments'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
            ElevatedButton(
              onPressed: pay,
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
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              ),
              child: const Text(
                'Confirm Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
