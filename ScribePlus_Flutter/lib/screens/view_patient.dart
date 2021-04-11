import 'dart:convert';

import 'package:ScribePlus/screens/add_prescription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:ScribePlus/url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pin_entry_text_field/pin_entry_text_field.dart';
import 'package:ScribePlus/backWidget.dart';

class Prescription {
  final String prescriptionID;
  final String date;
  final String doctorName;
  final String medicines;
  final String symptoms;
  final String diagnosis;
  final String advice;
  Prescription(
      {this.prescriptionID,
      this.date,
      this.doctorName,
      this.advice,
      this.symptoms,
      this.diagnosis,
      this.medicines});
}

class Patient {
  final String name;
  final String id;
  final String email;
  final String phone;
  final String doctorsVisitedCount;
  final List<Prescription> prescriptions;
  Patient(
      {this.name,
      this.id,
      this.email,
      this.phone,
      this.doctorsVisitedCount,
      this.prescriptions});

  factory Patient.fromJson(Map<String, dynamic> response) {
    List<Prescription> prescriptionsList = new List<Prescription>();
    for (var prescriptionItem in response['prescriptions']) {
      Prescription prescription = Prescription(
          prescriptionID: prescriptionItem['prescriptionID'],
          date: prescriptionItem['date'],
          doctorName: prescriptionItem['doctorName'],
          medicines: prescriptionItem['medicines'],
          symptoms: prescriptionItem['symptoms'],
          diagnosis: prescriptionItem['diagnosis'],
          advice: prescriptionItem['advice']);
      prescriptionsList.add(prescription);
    }
    print('Inside factory: $response');
    return Patient(
        name: response['name'],
        id: response['id'],
        email: response['email'],
        phone: response['phone'],
        doctorsVisitedCount: response['doctorsVisitedCount'],
        prescriptions: prescriptionsList);
  }
}

class ViewPatient extends StatefulWidget {
  final String patientQr;

  ViewPatient({Key key, @required this.patientQr}) : super(key: key);
  @override
  _ViewPatientState createState() => _ViewPatientState(patientQr);
}

class _ViewPatientState extends State<ViewPatient> {
  String patientAddress;
  Future patientDetails;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  _ViewPatientState(this.patientAddress);
  String doctorAddress;
  String authToken;
  String otp;
  String enteredOtp;
  bool newPatient = false;
  final GlobalKey<ScaffoldState> _viewPatientScaffoldKey =
      new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getAuthTokenAndAddress().then((details) {
      setState(() {
        doctorAddress = details['doctorAddress'];
        authToken = details['authToken'];
        patientDetails =
            getPatientDetails(details['doctorAddress'], details['authToken']);
      });
    });
    // patientDetails=getPatientDetails();
  }

  @override
  Widget build(BuildContext context) {
    print(patientAddress);
    return new Scaffold(
      body: patientWidget(),
    );
  }

  Widget topBarStyled(Patient patient) {
    return Stack(children: <Widget>[
      Container(
          width: 375,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(100),
            ),
            color: Color.fromRGBO(24, 199, 99, 1),
          )),
      Positioned(
          right: 40,
          top: 70,
          left: 110,
          child: Text(
            'Patient Details',
            textAlign: TextAlign.left,
            style: TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.800000011920929),
                fontFamily: 'Montserrat',
                fontSize: 18,
                letterSpacing:
                    0 /*percentages not used in flutter. defaulting to zero*/,
                fontWeight: FontWeight.normal,
                height: 1),
          )),
      Positioned(
          top: 110,
          left: 100,
          child: Text(
            patient.name,
            textAlign: TextAlign.left,
            style: TextStyle(
                color: Color.fromRGBO(255, 255, 255, 1),
                fontFamily: 'Roboto',
                fontSize: 48,
                letterSpacing:
                    0 /*percentages not used in flutter. defaulting to zero*/,
                fontWeight: FontWeight.normal,
                height: 1),
          )),
    ]);
  }

  Widget prescriptionCard(Prescription prescription) {
    return Padding(
        padding: EdgeInsets.all(10),
        child: Card(
          elevation: 7,
          child: InkWell(
            splashColor: Colors.blue.withAlpha(30),
            onTap: () {
              print('Card tapped.');
            },
            child: Container(
                width: 400,
                height: 100,
                child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            prescription.diagnosis,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                fontFamily: 'Montserrat'),
                          ),
                          Text(
                            "Medication",
                            style: TextStyle(
                                fontSize: 20, fontFamily: 'Montserrat'),
                          ),
                          Text(
                            prescription.medicines,
                            style: TextStyle(
                                fontSize: 15, fontFamily: 'Montserrat'),
                          ),
                        ]))),
          ),
        ));
  }

  Widget patientWidget() {
    return FutureBuilder(
      future: patientDetails,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorWidget(snapshot.error.toString());
        } else if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData == false) {
          return errorWidget('No Data');
        } else if (snapshot.hasData) {
          print('Snapshot Data: ${snapshot.data}');
          if (snapshot.data is Patient)
            return Scaffold(
              backgroundColor: Colors.white,
              body: SingleChildScrollView(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  backButton(context),
                  topBarStyled(snapshot.data),
                  for (var prescription in snapshot.data.prescriptions)
                    prescriptionCard(prescription),
                ],
              )),
              floatingActionButton: FloatingActionButton(
                backgroundColor: Color(0xff18C763),
                child: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => new UploadAudioPrescription(
                              patientAddress: this.patientAddress)));
                  print("Go to add prescription");
                },
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            );
          else if (snapshot.data is String)
            return Scaffold(
              body: Column(
                children: <Widget>[
                  PinEntryTextField(
                    fields: 6,
                    showFieldAsBox: false,
                    onSubmit: (String pin) {
                      print('Pin: $pin');
                      if (pin == snapshot.data) {
                        allowPatientAccess().then((bool result) {
                          if (result == true) {
                            setState(() {
                              patientDetails = getPatientDetails(
                                  this.doctorAddress, this.authToken);
                            });
                          } else {
                            final SnackBar snackBar =
                                SnackBar(content: Text('Login Failed'));
                            _viewPatientScaffoldKey.currentState
                                .showSnackBar(snackBar);
                          }
                        });
                      }
                    },
                  )
                ],
              ),
            );
        }
        print(snapshot.connectionState);
        print(snapshot.hasData);
        return loadingWidget();
      },
    );
  }

  Widget errorWidget(String error) {
    return Scaffold(
        body: Center(
      child: Text(error),
    ));
  }

  Widget loadingWidget() {
    return Scaffold(
        body: Center(
      child: Text("Loading"),
    ));
  }

  /*Widget prescriptionCard(Prescription prescription) {
    return Card(
      borderOnForeground: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Text(prescription.date),
          Text('Diagnosis: ${prescription.diagnosis}'),
          Text('Treated by: ${prescription.doctorName}')
        ],
      ),
    );
  }*/

  Future getPatientDetails(String doctorAddress, String authToken) async {
    print('patient adrress  ${this.patientAddress}');
    final http.Response response = await http.post('$apiUrl/patient/details',
        headers: <String, String>{
          'Content-Type': 'application/json',
          'auth-token': authToken
        },
        body: jsonEncode(<String, String>{
          'patientQrCode': this.patientAddress,
          'address': doctorAddress
        }));
    print(response.reasonPhrase);
    print(response.body);
    if (response.statusCode == 200) {
      return Patient.fromJson(json.decode(response.body)['patient']);
    } else if (response.statusCode == 401) {
      return json.decode(response.body)['OTP'];
    } else {
      throw Exception('Failed to load patient details');
    }
  }

  Future<bool> allowPatientAccess() async {
    final http.Response response = await http.post(
        '$apiUrl/patient/prescription/access',
        headers: <String, String>{
          'Content-Type': 'application/json',
          'auth-token': authToken
        },
        body: jsonEncode(<String, String>{
          'patientQrCode': patientAddress.toString(),
          'address': doctorAddress
        }));
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<Map<String, String>> getAuthTokenAndAddress() async {
    final SharedPreferences prefs = await _prefs;
    return {
      'authToken': prefs.get("doctorToken"),
      'doctorAddress': prefs.get("doctorAddress")
    };
  }
}
