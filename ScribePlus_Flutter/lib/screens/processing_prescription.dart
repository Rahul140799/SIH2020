import 'dart:convert';

import 'package:ScribePlus/backWidget.dart';
import 'package:ScribePlus/screens/view_patient.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ScribePlus/screens/edit_prescription.dart';
import 'package:ScribePlus/url.dart';
import 'package:beauty_textfield/beauty_textfield.dart';

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

class FollowUp extends StatefulWidget {
  final String socketEvent;
  final String patientAddress;
  FollowUp({@required this.patientAddress, @required this.socketEvent});

  @override
  _FollowUpState createState() => _FollowUpState(patientAddress, socketEvent);
}

class _FollowUpState extends State<FollowUp> {
  SocketIO socketIO;
  var response;
  var prescription;
  bool _prescriptionReady;
  List<bool> isSelected;
  String questionPicked;
  DateTime chosenDate;
  TextEditingController _followDayController = new TextEditingController();
  bool _skipFollowUp;
  String socketEvent;
  String patientAddress;
  List prescriptionResponse= new List();
  // String disease;
  // String symptoms;

  //Create Patient
  TextEditingController patientNameController;
  TextEditingController patientAgeController;
  TextEditingController patientPhoneController;
  TextEditingController patientGenderController;
  TextEditingController patientEmailController;
  _FollowUpState(this.patientAddress, this.socketEvent);
  bool isExpanded;

  final GlobalKey<ScaffoldState> _processPrescriptionScaffoldKey =
      new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    isExpanded = false;
    patientNameController = new TextEditingController();
    patientPhoneController = new TextEditingController();
    patientEmailController = new TextEditingController();
    patientAgeController = new TextEditingController();
    patientGenderController = new TextEditingController();
    _prescriptionReady = false;
    _skipFollowUp = false;
    questionPicked = 'Question';
    isSelected = [false, false, false];
    socketIO = SocketIOManager().createSocketIO(socketUrl, '/');
    socketIO.init();
    print('socketEvent: $socketEvent');
    getPrescription();
    socketIO.connect();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _processPrescriptionScaffoldKey,
      body: Center(
          child: SingleChildScrollView(
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      backButton(_processPrescriptionScaffoldKey.currentContext),
                      this._prescriptionReady == false
                          ? gettingReadyNotificationWidget()
                          : readyNotificationWidget(),
                      // readyNotificationWidget(),
                      Center(
                          child: Text("Enter Patient Details while processing",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  // color: Color.fromRGBO(255, 255, 255, 1),
                                  fontFamily: 'Montserrat',
                                  fontSize: 18,
                                  letterSpacing:
                                      0 /*percentages not used in flutter. defaulting to zero*/,
                                  fontWeight: FontWeight.normal,
                                  height: 1))),
                      Padding(
                        padding: EdgeInsets.all(0),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(60),
                              topRight: Radius.circular(60),
                              bottomLeft: Radius.circular(0),
                              bottomRight: Radius.circular(0),
                            ),
                            color: Color.fromRGBO(24, 199, 99, 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              createPatientWidget(
                                  'Patient Name', patientNameController),
                              createPatientWidget(
                                  'Patient Phone', patientPhoneController),
                              createPatientWidget(
                                  'Patient Email', patientEmailController),
                              createPatientWidget(
                                  'Patient Age', patientAgeController),
                              createPatientWidget(
                                  'Patient Gender', patientGenderController),
                            ],
                          ),
                        ),
                      )
                    ],
                  )))),
    );
  }

  Widget createPatientWidget(String textKey, TextEditingController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        BeautyTextfield(
          width: isExpanded == true
              ? MediaQuery.of(context).size.width * 0.85
              : MediaQuery.of(context).size.width * 0.75,
          height: 60,
          backgroundColor: Colors.white,
          duration: Duration(milliseconds: 300),
          inputType: TextInputType.text,
          prefixIcon: Icon(
            Icons.keyboard,
          ),
          placeholder: textKey,
          onTap: () {
            setState(() {
              isExpanded = true;
            });
          },
          onSubmitted: (d) {
            switch (textKey) {
              case 'Patient Name':
                setState(() {
                  patientNameController.text = d;
                });
                break;
              case 'Patient Phone':
                setState(() {
                  patientPhoneController.text = d;
                });
                break;
              case 'Patient Email':
                setState(() {
                  patientEmailController.text = d;
                });
                break;
              case 'Patient Age':
                setState(() {
                  patientAgeController.text = d;
                });
                break;
              case 'Patient Gender':
                setState(() {
                  patientGenderController.text = d;
                });
                break;
            }
          },
        ),
      ],
    );
  }

  Widget gettingReadyNotificationWidget() {
    return Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Prescription is getting processed...',
                style: TextStyle(
                    // color: Color.fromRGBO(255, 255, 255, 1),
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1)),
            Padding(
                padding: EdgeInsets.all(10),
                child: SpinKitPouringHourglass(
                    // color: Colors.white,
                    size: 200.0,
                    color: Color(0xff18C763)
                    // controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)),
                    )),
          ],
        ));
  }

  Widget readyNotificationWidget() {
    return Container(
        padding: EdgeInsets.all(20),
        // height: MediaQuery.of(context).size.height * 0.15,
        width: MediaQuery.of(context).size.width,
        // color: Color(0xff18C763),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 120,
              height: 120,
              child: Image.asset('assets/images/el_ok-circle.png',
                  semanticLabel: 'vector'),
            ),
            FlatButton(
              child: Text("Click to view report",
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      letterSpacing:
                          0 /*percentages not used in flutter. defaulting to zero*/,
                      fontWeight: FontWeight.normal,
                      height: 1)),
              onPressed: () {
                socketIO.disconnect();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => new EditPrescription(
                              prescription: this.prescriptionResponse,
                              patientAddress: this.patientAddress,
                              patientAge: this.patientAgeController.text,
                              patientEmail: this.patientEmailController.text,
                              patientGender: this.patientGenderController.text,
                              patientName: this.patientNameController.text,
                              patientPhone: this.patientPhoneController.text,
                            )));
                print(prescription);
              },
            )
          ],
        ));
  }

  Widget followBodyWidget() {
    return Column(
      children: <Widget>[
        _skipFollowUp == false
            ? RaisedButton.icon(
                icon: Icon(Icons.skip_next),
                label: Text("Skip Follow Up"),
                onPressed: () {
                  setState(() {
                    _skipFollowUp = true;
                  });
                },
              )
            : Column(
                children: <Widget>[
                  RaisedButton(
                    child: Text("Set Follow Up"),
                    onPressed: () {
                      setState(() {
                        _skipFollowUp = false;
                      });
                    },
                  ),
                  SpinKitHourGlass(
                      // color: Colors.white,
                      size: 50.0,
                      color: Colors.white
                      // controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)),
                      )
                ],
              ),
        Container(
            width: 339,
            height: 50,
            child: Stack(children: <Widget>[
              Positioned(
                  top: 12,
                  left: 0,
                  child: Text(
                    'Follow Up :   ',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 1),
                        fontFamily: 'Montserrat',
                        fontSize: 26,
                        letterSpacing:
                            0 /*percentages not used in flutter. defaulting to zero*/,
                        fontWeight: FontWeight.normal,
                        height: 1),
                  )),
              Positioned(
                  top: 0,
                  left: 189,
                  child: Container(
                      width: 150,
                      height: 50,
                      child: Stack(children: <Widget>[
                        Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                                width: 150,
                                height: 50,
                                child: Stack(children: <Widget>[
                                  Positioned(
                                      top: 40.625,
                                      left: 0,
                                      child: Transform.rotate(
                                        angle: 1.6434499492364262e-16 *
                                            (3.14 / 180),
                                        child: Divider(
                                            color: Color.fromRGBO(0, 0, 0, 1),
                                            thickness: 1),
                                      )),
                                  Positioned(
                                      top: 2.2737367544323206e-13,
                                      left: 124.2855453491211,
                                      child: null),
                                  Positioned(top: 50, left: 150, child: null),
                                ]))),
                        Positioned(
                            top: 2,
                            left: 80,
                            child: Text(
                              '5',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: Color.fromRGBO(0, 0, 0, 1),
                                  fontFamily: 'Roboto',
                                  fontSize: 32,
                                  letterSpacing:
                                      0 /*percentages not used in flutter. defaulting to zero*/,
                                  fontWeight: FontWeight.normal,
                                  height: 1),
                            )),
                      ]))),
            ])),
        Container(
            width: 348,
            height: 40,
            child: Stack(children: <Widget>[
              Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                      width: 348,
                      height: 40,
                      child: Stack(children: <Widget>[
                        Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                                width: 105,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(24, 199, 99, 1),
                                ))),
                        Positioned(
                            top: 0,
                            left: 243,
                            child: Container(
                                width: 105,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(
                                      196, 196, 196, 0.800000011920929),
                                ))),
                        Positioned(
                            top: 0,
                            left: 124,
                            child: Container(
                                width: 105,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(
                                      196, 196, 196, 0.800000011920929),
                                ))),
                      ]))),
              Positioned(
                  top: 3,
                  left: 16,
                  child: Text(
                    'Days',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 1),
                        fontFamily: 'Montserrat',
                        fontSize: 26,
                        letterSpacing:
                            0 /*percentages not used in flutter. defaulting to zero*/,
                        fontWeight: FontWeight.normal,
                        height: 1),
                  )),
              Positioned(
                  top: 3,
                  left: 132,
                  child: Text(
                    'Month',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 1),
                        fontFamily: 'Montserrat',
                        fontSize: 26,
                        letterSpacing:
                            0 /*percentages not used in flutter. defaulting to zero*/,
                        fontWeight: FontWeight.normal,
                        height: 1),
                  )),
              Positioned(
                  top: 3,
                  left: 256,
                  child: Text(
                    'Week',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 1),
                        fontFamily: 'Montserrat',
                        fontSize: 26,
                        letterSpacing:
                            0 /*percentages not used in flutter. defaulting to zero*/,
                        fontWeight: FontWeight.normal,
                        height: 1),
                  )),
            ])),
        Container(
            width: 327,
            height: 32,
            child: Stack(children: <Widget>[
              Positioned(
                  top: 0,
                  left: 0,
                  child: Text(
                    'Date Chosen :',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 1),
                        fontFamily: 'Montserrat',
                        fontSize: 26,
                        letterSpacing:
                            0 /*percentages not used in flutter. defaulting to zero*/,
                        fontWeight: FontWeight.normal,
                        height: 1),
                  )),
              Positioned(
                  top: 0,
                  left: 222,
                  child: Text(
                    '13/07/20',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 1),
                        fontFamily: 'Montserrat',
                        fontSize: 26,
                        letterSpacing:
                            0 /*percentages not used in flutter. defaulting to zero*/,
                        fontWeight: FontWeight.normal,
                        height: 1),
                  )),
            ])),
      ],
    );
  }

  Widget questionsWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("Pick a Question to be asked"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Radio(
                groupValue: questionPicked,
                value: "Are you feeling better now?",
                onChanged: (T) {
                  print(T);
                  setState(() {
                    this.questionPicked = T;
                  });
                }),
            Text("Are you feeling better now?")
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Radio(
                groupValue: questionPicked,
                value: "Are the symptoms still present?",
                onChanged: (T) {
                  print(T);
                  setState(() {
                    this.questionPicked = T;
                  });
                }),
            Text("Are the symptoms still present?")
          ],
        ),
        Text("Enter a Custom Question"),
        Padding(
          padding: EdgeInsets.all(20.0),
          child: TextField(
            autofocus: false,
            onChanged: (String value) {
              setState(() {
                this.questionPicked = value;
              });
            },
          ),
        )
      ],
    );
  }

  Widget numberIncrementDecrementWidget(
      TextEditingController _followDayController) {
    return
        // Text("data");
        Container(
            child: Flexible(
      flex: 2,
      fit: FlexFit.loose,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 30.0,
            child: TextFormField(
              controller: _followDayController,
              maxLength: 3,
              keyboardType:
                  TextInputType.numberWithOptions(signed: true, decimal: false),
              validator: (String value) {
                if ((int.parse(value) < 0) | (int.parse(value) > 366)) {
                  _followDayController.text = '0';
                }
                return '';
              },
            ),
          ),
          SizedBox(
            height: 100.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_drop_up),
                  iconSize: 34,
                  onPressed: () {
                    _followDayController.text =
                        '${int.parse(_followDayController.text) + 1}';
                    print("Increment");
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 34,
                  onPressed: () {
                    _followDayController.text =
                        '${int.parse(_followDayController.text) - 1}';
                    print("Decrement");
                  },
                )
              ],
            ),
          )
        ],
      ),
    ));
  }

  Future getPrescription() async {
    // print(this.socketEvent);

    await socketIO.subscribe(this.socketEvent, (jsonResponse) {
      print("Inside Subscribe");
      response = json.decode(jsonResponse);
      print(response);
      setState((){
        this._prescriptionReady= true;
        // this._disease=response['disease'];
        // this._symptoms=response['symptoms'];
        response['medicines'].forEach((pres) async=>(this.prescriptionResponse.add({
            'medicine': pres['medicine'],
            'dosage': pres['dosage'],
            'strength': pres['strength'],
            'form': pres['form'],
            'route': pres['route'],
            'frequency': pres['frequency'],
            'duration': pres['duration'],
            'onone': pres['onone'],
            'foodtime': pres['foodtime']
          })));          
      });
    });
    print('SUBS${this._prescriptionReady}');
  }
}
