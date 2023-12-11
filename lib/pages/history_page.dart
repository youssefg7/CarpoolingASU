import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Future getRidesHistory() async {
    return FirebaseDatabase.instance.ref().child("users");
  }

  @override
  Widget build(BuildContext context) {

    var Users=["Yous", "No", "Zoo"];
    return Scaffold(
      body: Column(
        children: [FutureBuilder<void>(
        future: getRidesHistory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('${snapshot.error}');
          } else {
            return ListView.builder(
              itemCount: Users.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  onTap: (){},
                  title: const Text("title"),
                  subtitle: const Text("subtitle"),
                );
              },
            );
          }
        }),

        ]
      ),
    );
  }
}
