import 'dart:convert';
import 'dart:io';

import 'package:ScribePlus/backWidget.dart';
import 'package:ScribePlus/screens/view_patient.dart';
import 'package:beauty_textfield/beauty_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:ScribePlus/url.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Medicine {
  final String dosage;
  final String duration;
  final String foodtime;
  final String form;
  final String freq;
  final String medicine;
  final String route;
  final String strength;
  final String onone;
  Medicine(
      {this.dosage,
      this.duration,
      this.foodtime,
      this.form,
      this.freq,
      this.medicine,
      this.route,
      this.strength,
      this.onone});
}

class EditPrescription extends StatefulWidget {
  final List prescription;
  final String patientAddress;
  final String patientName;
  final String patientAge;
  final String patientPhone;
  final String patientGender;
  final String patientEmail;
  EditPrescription(
      {Key key,
      @required this.patientAddress,
      @required this.prescription,
      @required this.patientName,
      @required this.patientEmail,
      @required this.patientGender,
      @required this.patientAge,
      @required this.patientPhone})
      : super(key: key);
  @override
  _EditPrescriptionState createState() => _EditPrescriptionState(
      this.patientAddress,
      this.prescription,
      this.patientName,
      this.patientEmail,
      this.patientGender,
      this.patientAge,
      this.patientPhone);
}

class _EditPrescriptionState extends State<EditPrescription> {
  List prescription;
  String patientAddress;
  String doctorAddress;
  String doctorAuthToken;
  String patientName;
  String patientAge;
  String patientEmail;
  String patientGender;
  String patientPhone;
  final GlobalKey<ScaffoldState> _editPrescriptionScaffoldKey =
      new GlobalKey<ScaffoldState>();

  TextEditingController diagnosisController;
  TextEditingController medicinesController;
  TextEditingController symptomsController;
  TextEditingController adviceController;

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  _EditPrescriptionState(
      this.patientAddress,
      this.prescription,
      this.patientName,
      this.patientEmail,
      this.patientGender,
      this.patientAge,
      this.patientPhone);

  @override
  void initState() {
    print('Prescription: $prescription');
    print('Patient address: $patientAddress');

    // diagnosisController =
    //     new TextEditingController(text: prescription['Disease']);
    // medicinesController =
    //     new TextEditingController(text: prescription['Drugs']);
    // symptomsController =
    //     new TextEditingController(text: prescription['Symptoms']);
    adviceController = new TextEditingController();

    //Create Patient

    getDoctorCredentialsfromSharedPrefs().then((docCredentials) {
      setState(() {
        doctorAddress = docCredentials['doctorAddress'];
        doctorAuthToken = docCredentials['doctorAuth'];
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // double width=MediaQuery.of(context).size.width;
    // double height=MediaQuery.of(context).size.height;
    return Scaffold(
        key: _editPrescriptionScaffoldKey,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            backButton(_editPrescriptionScaffoldKey.currentContext),
            topBarStyled(),
            Expanded(
              child: displayPrescription(),
            ),
            postButton()
          ],
        ));
  }

  Widget topBarStyled() {
    return Stack(children: <Widget>[
      Container(
          width: MediaQuery.of(context).size.width,
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
            'Edit Prescription',
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
    ]);
  }

  Widget prescriptionRowWidget(
      String textKey, TextEditingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text(textKey),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: TextField(
            controller: controller,
          ),
        )
      ],
    );
  }

  Widget fullDetailsWidget() {
    return Column(
      children: <Widget>[
        prescriptionRowWidget('Diagnosis', diagnosisController),
        prescriptionRowWidget('Medicines', medicinesController),
        prescriptionRowWidget('Symptoms', symptomsController),
        prescriptionRowWidget('Advice', adviceController),
      ],
    );
  }

  Widget halfDetailsWidget() {
    return Column(
      children: <Widget>[
        prescriptionRowWidget('Diagnosis', diagnosisController),
        prescriptionRowWidget('Medicines', medicinesController),
        prescriptionRowWidget('Symptoms', symptomsController),
        prescriptionRowWidget('Advice', adviceController),
      ],
    );
  }

  Widget displayPrescription() {
    return ListView.builder(
        itemCount: prescription.length,
        itemBuilder: (context, index) {
          final item = prescription[index];
          TextEditingController formC = new TextEditingController();
          TextEditingController medC = new TextEditingController();
          TextEditingController dosageC = new TextEditingController();
          TextEditingController freqC = new TextEditingController();
          formC.text = item['form'];
          medC.text = item['medicine'];
          dosageC.text = item['dosage'];
          freqC.text = item['frequency'];
          return Dismissible(
            // Specify the direction to swipe and delete
            direction: DismissDirection.endToStart,
            key: Key(item['medicine']),
            onDismissed: (direction) {
              // Removes that item the list on swipwe
              setState(() {
                prescription.removeAt(index);
              });
              // Shows the information on Snackbar
              Scaffold.of(context)
                  .showSnackBar(SnackBar(content: Text("Prescription dismissed")));
            },
            background: Container(color: Colors.red),
            child: Padding(
                padding: EdgeInsets.all(10),
                child: Container(
                    color: Colors.green[50],
                    width: MediaQuery.of(
                            _editPrescriptionScaffoldKey.currentContext)
                        .size
                        .width,
                    height: MediaQuery.of(context).size.height * 0.2,
                    child: Column(
                      children: <Widget>[
                        Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.3,
                                      child: CupertinoTextField(
                                        controller: formC,
                                        onSubmitted: (param){
                                      item['form']=param;
                                    }
                                      ),
                                    )),
                                Expanded(
                                  child: CupertinoTextField(
                                    controller: medC,
                                    onSubmitted: (param){
                                      item['medicine']=param;
                                    },
                                  ),
                                ),
                                // Text(item['form']),
                              ],
                            )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: CupertinoTextField(
                                padding: EdgeInsets.all(10),
                                controller: dosageC,
                                onSubmitted: (param){
                                      item['dosage']=param;
                                    }
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: CupertinoTextField(
                                padding: EdgeInsets.all(10),
                                controller: freqC,
                                onSubmitted: (param){
                                      item['frequency']=param;
                                    }
                              ),
                            ),
                            // Expanded(
                            //   child: CupertinoTextField(
                            //     controller: medC,
                            //   ),
                            // ),
                            // Text(item['form']),
                          ],
                        )
                      ],
                    ))),
            // ListTile(title: Text('${item['medicine']}')),
          );
        });
  }

  Widget postButton() {
    return Padding(
        padding: EdgeInsets.only(top: 70),
        child: InkWell(
          onTap: () {
            var reqbody={
              'name': patientName,
              'phno': patientPhone,
              'email': patientEmail,
              'dob': patientAge,
              'gender': patientGender,
              'address':'Chennai',
              'date':'03-08-2020',
              'out':{
                    'result':{
                      'medicines': prescription
                    }
              }
            };
            createPDF(reqbody).then((onValue){
              print(onValue);
            });


          },      
          child: Container(
              width: 350,
              height: 60,
              child: Stack(children: <Widget>[
                Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                        width: 350,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.25),
                                offset: Offset(0, 4),
                                blurRadius: 4)
                          ],
                          color: Color.fromRGBO(24, 199, 99, 1),
                        ))),
                Positioned(
                    child: Center(
                      child: Text(
                      'Generate PDF',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          fontFamily: 'Montserrat',
                          fontSize: 23,
                          letterSpacing:
                              0 /*percentages not used in flutter. defaulting to zero*/,
                          fontWeight: FontWeight.normal,
                          height: 1),
                    ))),

              ])),
        ));
  }

  Future getDoctorCredentialsfromSharedPrefs() async {
    final SharedPreferences prefs = await _prefs;
    return {
      'doctorAddress': prefs.get('doctorAddress'),
      'doctorAuth': prefs.get('doctorToken')
    };
  }

  Future<String> createPatient(var requestBody) {
    String createPatientUrl = '$apiUrl/patient/create';
    return http
        .post(createPatientUrl,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'auth-token': this.doctorAuthToken,
            },
            body: jsonEncode(<String, String>{
              'name': patientName,
              'phno': patientPhone,
              'email': patientEmail,
              'dob': patientAge,
              'gender': patientGender,
            }))
        .then((value) {
      print("op");
      print(value.body);
      print(value.statusCode);
      if (value.statusCode == 200) {
        print("if" + value.body);
        return json.decode(value.body)['result']['account'];
      } else {
        print("else" + value.body);
        return null;
      }
    });
  }

  Future<bool> createPDF(var requestBody){
    String createPatientUrl = '$apiUrl/patient/prescription/create/pdf';
    return http
        .post(createPatientUrl,
            headers: <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': patientName,
              'phno': patientPhone,
              'email': patientEmail,
              'dob': patientAge,
              'gender': patientGender,
              'address':'Chennai',
              'date':'03-08-2020',
              'out':{
                    'result':{
                      'medicines': prescription
                    }
              }
            }))
        .then((value) {
      print("op");
      print(value.body);
      print(value.statusCode);
      if (value.statusCode == 200) {
        print("if" + value.body);
        return true;
      } else {
        print("else" + value.body);
        return false;
      }
    });
  }

  Future<String> getAccess(var requestBody) {
    String uploadUrl = '$apiUrl/patient/prescription/access';
    return http
        .post(uploadUrl,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'auth-token': this.doctorAuthToken,
            },
            body: jsonEncode(<String, String>{
              "patientQrCode": requestBody['patientQrCode'],
              "address": requestBody['address']
            }))
        .then((value) {
      if (value.statusCode == 200) {
        return json.decode(value.body)['access'];
      } else {
        return null;
      }
    });
  }

  Future<bool> createPrescription(var requestBody) {
    String uploadUrl = '$apiUrl/patient/prescription/create/pdf"';
    // final http.Response response = await
    return http
        .post(uploadUrl,
            headers: <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              // "medicines": "Dolo",
              // "symptoms": "Cough",
              // "diagnosis": "Cold",
              // "advice": "Take Rest",
              // "patientQrCode": requestBody['patientQrCode'],
              // "doctorAddress": requestBody['doctorAddress']
              'medicines': requestBody['medicines'],
              'symptoms': requestBody['symptoms'],
              'diagnosis': requestBody['diagnosis'],
              'advice': requestBody['advice'],
              'patientQrCode': requestBody['patientQrCode'],
              'doctorAddress': requestBody['doctorAddress'],
            }))
        .then((value) {
      print('res: $value');
      if (value.statusCode == 200) {
        print('Success');
        return true;
      } else {
        print('Failed');
        return false;
      }
    });
  }
}
