import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:zaanassh/services/calculate_service.dart';
import 'package:zaanassh/screens/drawe.dart';
import 'package:zaanassh/screens/save_activity.dart';
import 'package:zaanassh/services/geo_locator_service.dart';
import 'package:http/http.dart' as http;

import 'package:zaanassh/services/distance_calculator.dart';

class RecordScreen extends StatefulWidget {
  final Position initialPosition;
  final String time;
  final String speed;
  final String distance;
  final bool showMap;
  RecordScreen(
      {this.time,
      this.speed,
      this.distance,
      @required this.initialPosition,
      @required this.showMap});
  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool isStarted = true;
  bool isReset = true;
  bool isStopped = true;
  Position initPosition;
  String stopTimetoDisplay;
  var swatch = Stopwatch();
  final dur = const Duration(seconds: 1);
  Position sPosition;

  GeolocatorService geolocatorService = GeolocatorService();
  Geolocator geolocator = Geolocator();
  double time = 1.000000;

  List<Position> points = [];
  double _distance = 0.0;
  double _avgSpeed = 0.0;
//calculate distance

  void startTimer() {
    Timer(
      dur,
      keepRunning,
    );
  }

  void keepRunning() {
    if (swatch.isRunning) {
      startTimer();
      setState(() {
        stopTimetoDisplay = swatch.elapsed.inHours.toString().padLeft(2, "0") +
            ":" +
            (swatch.elapsed.inMinutes % 60).toString().padLeft(2, "0") +
            ":" +
            (swatch.elapsed.inSeconds % 60).toString().padLeft(2, "0");
        time++;
      });
    }
  }

  void startsStopWatch() {
    setState(() {
      // isStopped = false;
      isStarted = false;
    });
    swatch.start();
    startTimer();
  }

  void stopsStopWatch() {
    setState(() {
      isStopped = false;
      isStarted = true;
      isReset = true;
    });
    swatch.stop();
  }

  void resetsStopWatch() {
    setState(() {
      isStarted = true;
      isReset = false;
      isStopped = true;
      stopTimetoDisplay = "00:00:00";
      time = 1;
      // distance = 0.0;
      // speed = 0.0;
    });
    swatch.reset();
  }

  @override
  void dispose() {
    swatch.elapsed;

    super.dispose();
  }

  @override
  void initState() {
    _getCurrentLocation();
    super.initState();

    setState(() {
      stopTimetoDisplay = (widget.time == null) ? "00:00:00" : widget.time;
    });
  }

  Widget stopWatch() {
    return Container(
      child: Column(
        children: [
          Container(
            child: Text(
              stopTimetoDisplay,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width / 6.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //get currentLocation
  _getCurrentLocation() async {
    var initPos = await geolocator.getCurrentPosition();
    setState(() {
      initPosition = initPos;
      points.add(initPosition);
    });
  }

  Position lastPosition;
  String unit = "m";
  int count = 0;
  String avgSpeed = "0";
  Stream<double> getDistance() async* {
    double distance = 0.0;
    if (initPosition != null) {
      Position currentPosition = await Geolocator().getCurrentPosition();
      points.add(currentPosition);
    }
    if (points.length > 1) {
      for (int i = 0; i < points.length; i++) {
        print("point - ${points[i]}");
        distance += coordinateDistance(
              points[i].latitude,
              points[i].longitude,
              points[i + 1].latitude,
              points[i + 1].longitude,
            ) *
            1000;
      }
      print("Distance - $distance");
      yield distance;
    } else {
      yield distance;
    }
  }

  Stream<double> getAvgSpeed() async* {
    double avgSpeed;
    getDistance().listen((double distance) {
      avgSpeed = distance / time;
    });
    yield avgSpeed;
  }

  final firebase = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  double calories = 0.0;
  int age = 0;
  double weight = 0;
  Future<double> calculateCalories(int time) async {
    if (isStarted) {
      DocumentReference ageReference = firebase
          .collection("users")
          .doc(auth.currentUser.email)
          .collection("user_data")
          .doc("age");

      DocumentReference weightReference = firebase
          .collection("users")
          .doc(auth.currentUser.email)
          .collection("weight")
          .doc("weight");
      firebase.runTransaction((transaction) async {
        DocumentSnapshot ageSnapshot = await transaction.get(ageReference);
        DocumentSnapshot weightSnapshot =
            await transaction.get(weightReference);

        setState(() {
          age = DateTime.now().year -
              int.parse(ageSnapshot.data()["age"].toString().split("-")[0]);
          // print("Age is $age");
          weight = weightSnapshot.data()["weight"];
          // print("weight is $weight ");
          calories = (age * 0.074) -
              (weight * 0.05741) +
              (78 * 0.4472 - 20.4022) * time / 4.184;
        });
      });
    }
    print("Calories is $calories");
    return calories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerClass().drawer(context),
      backgroundColor: Color.fromRGBO(19, 20, 41, 1),
      appBar: AppBar(
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "ZANN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width / 22,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: "ASH",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: MediaQuery.of(context).size.width / 22,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              )
            ],
          ),
        ),
        backgroundColor: Color.fromRGBO(19, 20, 41, 1),
        //shadowColor: Colors.white.withOpacity(0.1),
        actions: [
          TextButton(
            onPressed: () async {
              Get.to(() => SaveActivityScreen(
                    speed: (_distance ~/ time).toString(),
                    time: stopTimetoDisplay,
                    distance: _distance.toString(),
                    initialPosition: widget.initialPosition,
                    cTime: time,
                    showMap: widget.showMap,
                    currentPosition: sPosition,
                  ));
            },
            child: Text(
              "Save Activity",
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width / 36,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "TIME",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amber[600],
                    letterSpacing: 1.5,
                    fontSize: MediaQuery.of(context).size.width / 25,
                  ),
                ),
              ],
            ),
            stopWatch(),
            Container(
              color: Colors.grey[500],
              child: SizedBox(
                height: 0.5,
                width: MediaQuery.of(context).size.width / 1.1,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "AVG SPEED (s)",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amber[600],
                    letterSpacing: 1.5,
                    fontSize: MediaQuery.of(context).size.width / 25,
                  ),
                ),
              ],
            ),
            Container(
              child: StreamBuilder(
                stream: getAvgSpeed(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _avgSpeed = snapshot.data;
                    return Text(
                      "${(snapshot.data).toStringAsFixed(2)} ps",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width / 6.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  } else {
                    return Text(
                      "0.0",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width / 6.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }
                },
              ),
            ),
            Container(
              color: Colors.grey[500],
              child: SizedBox(
                height: 0.5,
                width: MediaQuery.of(context).size.width / 1.1,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "DISTANCE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amber[600],
                    letterSpacing: 1.5,
                    fontSize: MediaQuery.of(context).size.width / 25,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20.0,
            ),
            StreamBuilder(
              stream: getDistance(),
              builder: (context, snapshot) {
                print("snapshot - ${snapshot.data}");
                if (snapshot.hasData) {
                  _distance = snapshot.data;
                  return Container(
                    child: Text(
                      "${(snapshot.data).toStringAsFixed(2)} $unit",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width / 6.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  );
                } else {
                  return Container(
                    child: Text(
                      "0.0 $unit",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width / 6.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  );
                }
              },
            ),
            Container(
              color: Colors.grey[500],
              child: SizedBox(
                height: 0.5,
                width: MediaQuery.of(context).size.width / 1.1,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "CALORIES",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amber[600],
                    letterSpacing: 1.5,
                    fontSize: MediaQuery.of(context).size.width / 25,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20.0,
            ),
            FutureBuilder(
              future: calculateCalories(time.toInt()),
              builder: (context, AsyncSnapshot<double> snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                    child: SpinKitChasingDots(
                      color: Colors.amber[700],
                    ),
                  );
                }
                print("${snapshot.data} is s timr is $time");
                return Text(
                    (snapshot.data > 0)
                        ? "${snapshot.data.floorToDouble()}"
                        : "0.0",
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 6.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ));
              },
            ),
            Container(
              color: Colors.grey[500],
              child: SizedBox(
                height: 0.5,
                width: MediaQuery.of(context).size.width / 1.1,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MaterialButton(
                  onPressed: isStarted ? startsStopWatch : stopsStopWatch,
                  child: Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width / 6,
                    height: MediaQuery.of(context).size.width / 6,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        //borderRadius: BorderRadius.circular(15.0),
                        color: Colors.amber[600]),
                    child: Icon(
                      (isStarted) ? Icons.play_arrow_sharp : Icons.stop,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width / 8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 12.0,
                ),
                MaterialButton(
                  onPressed: isReset ? resetsStopWatch : null,
                  child: Container(
                    width: MediaQuery.of(context).size.width / 8,
                    height: MediaQuery.of(context).size.width / 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restore_outlined,
                      color: Colors.amber[600],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
