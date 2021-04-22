import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:zaanassh/screens/daily_record_screen.dart';

class WeeklySummariesScreen extends StatefulWidget {
  @override
  _WeeklySummariesScreenState createState() => _WeeklySummariesScreenState();
}

class _WeeklySummariesScreenState extends State<WeeklySummariesScreen> {
  @override
  void initState() {
    super.initState();
  }

  timeMethod() {
    DateTime now = DateTime.now();
    //DateTime after = now.subtract(Duration(days: 7));
    var a = now.difference(DateTime.utc(DateTime.now().year));
    int inDays = a.inDays;
    var b = now.add(Duration(days: 28)).day;

    double week = inDays / 7;
    print("week is ${week.toString().split(".")[0]} $b");
    if (DateTime.now().day == 1) {
      var weekOneEndDay = now.add(Duration(days: 7));
    }
  }

  String getMonth(String month) {
    String monthname = "";
    switch (month) {
      case "01":
        monthname = "January";
        break;
      case "02":
        monthname = "February";
        break;
      case "03":
        monthname = "March";
        break;
      case "04":
        monthname = "April";
        break;
      case "05":
        monthname = "May";
        break;
      case "06":
        monthname = "June";
        break;
      case "07":
        monthname = "July";
        break;
      case "08":
        monthname = "August";
        break;
      case "09":
        monthname = "September";
        break;
      case "10":
        monthname = "October";
        break;
      case "11":
        monthname = "November";

        break;
      case "12":
        monthname = "December";
        break;

      default:
        monthname = "";
    }
    return monthname;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(35, 36, 70, 1),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(35, 36, 70, 1),
        centerTitle: true,
        title: Text(
          "Weekly Summaries",
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.amber[700],
              borderRadius: BorderRadius.circular(18.0),
            ),
            child: Text(
              "${DateTime.now().year}",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width / 22.0),
            ),
            margin: EdgeInsets.all(15.0),
            padding: EdgeInsets.symmetric(vertical: 7.0, horizontal: 15.0),
          ),
          Container(
            /*child: MaterialButton(
            onPressed: () {
              timeMethod();
              // Get.to(() => DailyRecordScreen());
            },
            child: Text("Click me"),*/
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("weekly_steps_summaries")
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                return (!snapshot.hasData || snapshot.isBlank)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              alignment: Alignment.center,
                              child: Image.asset("assets/no_data.png")),
                          Text(
                            "No data",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              letterSpacing: 1.5,
                              fontSize: MediaQuery.of(context).size.width / 22,
                            ),
                          )
                        ],
                      )
                    : SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 1.3,
                        child: ListView(
                          children: snapshot.data.docs.map((doc) {
                            if (!doc.exists) {
                              return Center(
                                child: SpinKitChasingDots(
                                  color: Colors.amber[600],
                                ),
                              );
                            }
                            print(doc.id);
                            return (doc.id.split(" ")[2] ==
                                    FirebaseAuth.instance.currentUser.email)
                                ? Container(
                                    width: MediaQuery.of(context).size.width,
                                    color: Colors.white.withOpacity(0.01),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18.0),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            onTap: () {
                                              Get.to(
                                                () => DailyRecordScreen(
                                                  docId: doc.id,
                                                  month: doc.data()["month"],
                                                  year: doc.data()["year"],
                                                ),
                                              );
                                              print(doc.id);
                                            },
                                            title: RichText(
                                              text: TextSpan(children: [
                                                TextSpan(
                                                  text:
                                                      "W${doc.id.toUpperCase().split(" ")[1]} ",
                                                  style: TextStyle(
                                                    color: Colors.amber[500],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            22.0,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      "${DateFormat("dd").format(DateTime.now())}-${DateFormat("dd").format(DateTime.now().add(Duration(days: 7)))} ${DateFormat.MMM().format(DateTime.now())}",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            25.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ]),
                                            ),
                                            trailing: Icon(
                                                FontAwesomeIcons.arrowRight,
                                                color: Colors.amber),
                                          ),
                                          Container(
                                            color: Colors.grey[600],
                                            child: SizedBox(
                                              height: 0.54,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : SizedBox(width: 0.0);
                          }).toList(),
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
