import 'dart:convert';
import 'package:ScribePlus/screens/scan_patient.dart';
import 'package:ScribePlus/screens/view_patient.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

import 'package:ScribePlus/url.dart';
import 'package:intl/intl.dart';

class Patient {
  final String name;
  final String phNo;
  final String patientId;
  final String email;

  Patient({this.name, this.phNo, this.patientId, this.email});

  factory Patient.fromJson(Map<String, dynamic> responsePatient) {
    return Patient(
        name: responsePatient['name'],
        phNo: responsePatient['phone'],
        email: responsePatient['email']);
  }
}

class Appointment {
  final int appointmentNo;
  final String time;
  // final String date;
  final Patient patientDetails;
  final bool isNewPatient;
  final String patientQrCode;
  final String date;
  // final DateTime timeChosen;
  Appointment(
      {this.appointmentNo,
      this.time,
      this.patientDetails,
      this.isNewPatient,
      this.patientQrCode,
      this.date});

  factory Appointment.fromJson(Map<String, dynamic> response) {
    return Appointment(
      appointmentNo: response['appointment']['appointmentNumber'],
      time: response['appointment']['time'],
      patientDetails: Patient.fromJson(response['patientDetails']),
      isNewPatient: response['isNewPatient'],
      patientQrCode: response['appointment']['patientQrCode'],
      date: response['appointment']['date'],
      // timeChosen: DateTime.parse(response['appointmentTime'])
    );
  }
}

double toDouble(TimeOfDay myTime) => myTime.hour + myTime.minute / 60.0;

List<Appointment> initAppointments(var response) {
  List<Appointment> appointmentsList = new List();
  for (var appointment in response) {
    appointmentsList.add(Appointment.fromJson(appointment));
  }
  // appointmentsList.sort((a,b){
  //   // print(DateTime.now());
  //   // print(DateTime.parse(a.date.substring(0,10)+'T'+ a.time));
  //   // print(DateTime.parse(b.date.substring(0,10)+'T'+ b.time));
  //   // print(DateTime.parse(b.date.substring(0,10)+'T'+ b.time) is DateTime);
  //   // final DateFormat formatter = DateFormat('HOUR24_MINUTE_SECOND');
  //   // DateFormat.Hms().format(DateTime.parse(a.date+' '+ a.time));
  //   // String formattedA = DateFormat.Hms().format(DateTime.parse(a.date.substring(0,10)+'T'+ a.time+'.000Z'));
  //   // String formattedB = DateFormat.Hms().format(DateTime.parse(b.date.substring(0,10)+'T'+ b.time+'.000Z'));
  //   print(a.timeChosen);
  //   print(b.timeChosen);
  //   double timeA=toDouble(TimeOfDay.fromDateTime(a.timeChosen));
  //   double timeB=toDouble(TimeOfDay.fromDateTime(b.timeChosen));
  //   return timeA.compareTo(timeB);
  // });
  return appointmentsList;
}

class ViewAppointments extends StatefulWidget {
  @override
  _ViewAppointmentsState createState() => _ViewAppointmentsState();
}

class _ViewAppointmentsState extends State<ViewAppointments> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Future appointments;
  String doctorAddress;
  String authToken;
  DateTime selectedDate = DateTime.now();
  var newFormat = DateFormat("yyyy-MM-dd");

  final GlobalKey<ScaffoldState> _viewAppointmentsScaffoldKey =
      new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getAuthTokenAndAddress().then((details) {
      setState(() {
        doctorAddress = details['doctorAddress'];
        authToken = details['authToken'];
        appointments = getAppointments(this.doctorAddress, this.authToken,
            newFormat.format(this.selectedDate));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _viewAppointmentsScaffoldKey,
      body: getAppointmentsWidget(),
    );
  }

  Widget getAppointmentsWidget() {
    return FutureBuilder(
      future: appointments,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorWidget(snapshot.error.toString());
        } else if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData == false) {
          return errorWidget('No Data');
        } else if (snapshot.hasData) {
          if (snapshot.data is List<Appointment>) {
            print(snapshot.data);
            return ListView(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      size: 38,
                    ),
                    onPressed: () {
                      pickDate();
                    },
                  ),
                ),
                Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Column(children: <Widget>[
                      Text(
                        'Your Appointments for:',
                        style: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 1),
                            fontFamily: 'Montserrat',
                            fontSize: 20,
                            letterSpacing:
                                0 /*percentages not used in flutter. defaulting to zero*/,
                            fontWeight: FontWeight.normal,
                            height: 1),
                      ),
                      Text(
                        ' ${DateFormat("yMMMMEEEEd").format(selectedDate)}',
                        style: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 1),
                            fontFamily: 'Montserrat',
                            fontSize: 25,
                            letterSpacing:
                                0 /*percentages not used in flutter. defaulting to zero*/,
                            fontWeight: FontWeight.bold,
                            height: 1),
                      )
                    ])),
                firstAppointment(snapshot.data[0]),
                // firstAppointmentWidget(snapshot.data[0]),
                Center(
                    child: Text('Next Appointments',
                        style: TextStyle(
                            color: Color.fromRGBO(88, 83, 83, 1),
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            letterSpacing:
                                0 /*percentages not used in flutter. defaulting to zero*/,
                            fontWeight: FontWeight.w400,
                            height: 1))),
                for (Appointment appointment in snapshot.data.sublist(1))
                  nextAppointmentWidget(appointment),
              ],
            );
          }
          return ListView(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    Icons.calendar_today,
                    size: 38,
                  ),
                  onPressed: () {
                    pickDate();
                  },
                ),
              ),
              Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(children: <Widget>[
                    Text(
                      'Your Appointments for:',
                      style: TextStyle(
                          color: Color.fromRGBO(0, 0, 0, 1),
                          fontFamily: 'Montserrat',
                          fontSize: 20,
                          letterSpacing:
                              0 /*percentages not used in flutter. defaulting to zero*/,
                          fontWeight: FontWeight.normal,
                          height: 1),
                    ),
                    Text(
                      ' ${DateFormat("yMMMMEEEEd").format(selectedDate)}',
                      style: TextStyle(
                          color: Color.fromRGBO(0, 0, 0, 1),
                          fontFamily: 'Montserrat',
                          fontSize: 25,
                          letterSpacing:
                              0 /*percentages not used in flutter. defaulting to zero*/,
                          fontWeight: FontWeight.bold,
                          height: 1),
                    )
                  ])),
            ],
          );
        }
        return loadingWidget();
      },
    );
  }

  Widget errorWidget(String error) {
    return Center(
      child: Text(error),
    );
  }

  Widget loadingWidget() {
    return Center(
      child: Text("Loading"),
    );
  }

  Widget firstAppointment(Appointment appointment) {
    Widget common = Column(
      children: <Widget>[
        Container(
            constraints: BoxConstraints.expand(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.12),
            margin: EdgeInsets.only(top: 20.0, right: 20.0, left: 20.0),
            decoration: BoxDecoration(
                color: Color(0xFF18C763),
                shape: BoxShape.rectangle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 2.0,
                    spreadRadius: 0.0,
                    offset: Offset(2.0, 2.0), // shadow direction: bottom right
                  )
                ],
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0))),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text('Current Appointment',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          letterSpacing:
                              0 /*percentages not used in flutter. defaulting to zero*/,
                          fontWeight: FontWeight.normal,
                          height: 1)),
                  Text(appointment.time,
                      style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          fontFamily: 'Montserrat',
                          fontSize: 20,
                          letterSpacing:
                              0 /*percentages not used in flutter. defaulting to zero*/,
                          fontWeight: FontWeight.bold,
                          height: 1)),
                ],
              ),
            )),
        Container(
            margin: EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    appointment.patientDetails.name,
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        letterSpacing:
                            0 /*percentages not used in flutter. defaulting to zero*/,
                        fontWeight: FontWeight.normal,
                        height: 1),
                  ),
                  if (!appointment.isNewPatient)
                    viewPatientHistory(appointment),
                  attendWidget(appointment)
                ],
              ),
            ),
            constraints: BoxConstraints.expand(
                width: MediaQuery.of(context).size.width * 0.90,
                height: MediaQuery.of(context).size.height * 0.15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 4.0,
                  spreadRadius: 0.0,
                  offset: Offset(2.0, 2.0), // shadow direction: bottom right
                )
              ],
            ))
      ],
    );
    if (appointment.isNewPatient)
      return Container(
          child: Banner(
              message: "New Patient",
              color: Colors.red,
              location: BannerLocation.topStart,
              child: common));
    else
      return Container(
        child: common,
      );
  }

  Widget nextAppointmentWidget(Appointment appointment) {
    print('Appointment: $appointment');
    print('time: ${appointment.time}');
    print('name: ${appointment.patientDetails.name}');
    print('phone: ${appointment.patientDetails.phNo}');
    return Card(
      margin: EdgeInsets.all(20.0),
      shape: RoundedRectangleBorder(
        // side: BorderSide(color: Colors.green, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        title: Text(appointment.patientDetails.name,
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'Montserrat',
                fontSize: 18,
                letterSpacing:
                    0 /*percentages not used in flutter. defaulting to zero*/,
                fontWeight: FontWeight.bold,
                height: 1)),
        subtitle: Text(appointment.time,
            style: TextStyle(
                color: Color.fromRGBO(159, 154, 154, 1),
                fontFamily: 'Montserrat',
                fontSize: 15,
                letterSpacing:
                    0 /*percentages not used in flutter. defaulting to zero*/,
                fontWeight: FontWeight.normal,
                height: 1)),
        children: <Widget>[
          appointment.isNewPatient
              ? Text('New Patient')
              : viewPatientHistory(appointment),
          attendWidget(appointment)
        ],
      ),
    );
  }

  // Widget viewPatientHistory(Appointment appointment) {
  //   return InkWell(
  //     child: Container(
  //         width: 150,
  //         height: 29,
  //         child: Stack(children: <Widget>[
  //           Positioned(
  //               top: 0,
  //               left: 0,
  //               child: Container(
  //                   width: 150,
  //                   height: 29,
  //                   decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.only(
  //                       topLeft: Radius.circular(30),
  //                       topRight: Radius.circular(30),
  //                       bottomLeft: Radius.circular(30),
  //                       bottomRight: Radius.circular(30),
  //                     ),
  //                     color: Color.fromRGBO(56, 59, 69, 1),
  //                   ))),
  //           Positioned(
  //             top: 6,
  //             left: 55,
  //             child: Text(
  //               'View Patient History',
  //               style: TextStyle(
  //                   color: Color.fromRGBO(255, 255, 255, 1),
  //                   fontFamily: 'Montserrat',
  //                   fontSize: 15,
  //                   letterSpacing:
  //                       0 /*percentages not used in flutter. defaulting to zero*/,
  //                   fontWeight: FontWeight.normal,
  //                   height: 1),
  //             ),
  //           ),
  //         ])),
  //     onTap: () {
  //       Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //               builder: (context) => new ViewPatient(
  //                     patientQr: appointment.patientQrCode,
  //                   )));
  //     },
  //   );
  // }

  Widget viewPatientHistory(Appointment appointment) {
    return InkWell(
      child: Container(
          width: 250,
          height: 29,
          child: Stack(children: <Widget>[
            Positioned(
                top: 0,
                left: 0,
                child: Container(
                    width: 250,
                    height: 29,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      color: Color.fromRGBO(56, 59, 69, 1),
                    ))),
            Positioned(
              top: 6,
              left: 55,
              child: Text(
                'View Patient History',
                style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1),
              ),
            ),
          ])),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => new ViewPatient(
                      patientQr: appointment.patientQrCode,
                    )));
      },
    );
  }

  Widget attendWidget(Appointment appointment) {
    return InkWell(
      child: Container(
          width: 150,
          height: 29,
          child: Stack(children: <Widget>[
            Positioned(
                top: 0,
                left: 0,
                child: Container(
                    width: 150,
                    height: 29,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      color: Color.fromRGBO(56, 59, 69, 1),
                    ))),
            Positioned(
              top: 6,
              left: 55,
              child: Text(
                'Attend',
                style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1),
              ),
            ),
          ])),
      onTap: () {
        attendAppointment(appointment.appointmentNo).then((bool result) {
          if (result == true)
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => new ScanPatient()));
          else {
            final SnackBar snackBar =
                SnackBar(content: Text('Could not process! Try again later.'));
            _viewAppointmentsScaffoldKey.currentState.showSnackBar(snackBar);
          }
        });
      },
    );
  }

  Future getAppointments(
      String doctorAddress, String authToken, String date) async {
    print(authToken);
    final http.Response response = await http.post(
        '$apiUrl/doctor/appointment/date',
        headers: <String, String>{
          'Content-Type': 'application/json',
          'auth-token': authToken
        },
        body: jsonEncode(
            <String, String>{'doctorAddress': doctorAddress, 'date': date}));
    if (response.statusCode == 200) {
      print('Inside call: ${response.body}');
      if (response.body.toString() != '[]')
        return initAppointments(json.decode(response.body));
      return "No appointments";
    }
  }

  Future<bool> attendAppointment(int appointmentNo) async {
    final http.Response response = await http.put(
        '$apiUrl/doctor/appointment/visited',
        headers: <String, String>{
          'Content-Type': 'application/json',
          'auth-token': authToken
        },
        body: jsonEncode(<String, int>{'appointmentNumber': appointmentNo}));
    if (response.statusCode == 200)
      return true;
    else
      return false;
  }

  Future<void> pickDate() async {
    final DateTime picked = await showDatePicker(
        context: _viewAppointmentsScaffoldKey.currentContext,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
        appointments = getAppointments(this.doctorAddress, this.authToken,
            newFormat.format(this.selectedDate));
      });
  }

  Future<Map<String, String>> getAuthTokenAndAddress() async {
    final SharedPreferences prefs = await _prefs;
    return {
      'authToken': prefs.get("doctorToken"),
      'doctorAddress': prefs.get("doctorAddress")
    };
  }
}
