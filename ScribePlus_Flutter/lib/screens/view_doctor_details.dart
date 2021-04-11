import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:ScribePlus/url.dart';

class Doctor {
  final String name;
  final String address;
  final String phone;
  final String email;

  Doctor({this.name, this.address, this.phone, this.email});

  factory Doctor.fromJson(Map<String, dynamic> responseDoctor) {
    return Doctor(
        name: responseDoctor['name'],
        phone: responseDoctor['phno'],
        address: responseDoctor['address'],
        email: responseDoctor['email']);
  }
}

class DoctorDetails extends StatefulWidget {
  @override
  _DoctorDetailsState createState() => _DoctorDetailsState();
}

class _DoctorDetailsState extends State<DoctorDetails> {
  String doctorAddress;
  String doctorAuthToken;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Future doctorDetailsApi;
  Future balanceEth;

  @override
  void initState() {
    getDoctorCredentialsfromSharedPrefs().then((docCredentials) {
      setState(() {
        this.doctorAddress = docCredentials['doctorAddress'];
        this.doctorAuthToken = docCredentials['doctorAuth'];
        this.doctorDetailsApi =
            fetchDoctorDetails(this.doctorAddress, this.doctorAuthToken);
        this.balanceEth =
            fetchBalance(this.doctorAddress, this.doctorAuthToken);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              details(),
              balance(),
            ],
          ),
        ),
      ),
    );
  }

  Widget details() {
    return FutureBuilder(
      future: doctorDetailsApi,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorWidget(snapshot.error.toString());
        } else if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData == false) {
          return errorWidget('No Data');
        } else if (snapshot.hasData) {
          if (snapshot.data is Doctor)
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Hello !',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: Color.fromRGBO(24, 115, 158, 1),
                      fontFamily: 'Roboto',
                      fontSize: 22,
                      letterSpacing:
                          0 /*percentages not used in flutter. defaulting to zero*/,
                      fontWeight: FontWeight.normal,
                      height: 1),
                ),
                Text(
                  'Dr. ${snapshot.data.name}',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: Color.fromRGBO(35, 60, 101, 1),
                      fontFamily: 'Montserrat',
                      fontSize: 48,
                      letterSpacing:
                          0 /*percentages not used in flutter. defaulting to zero*/,
                      fontWeight: FontWeight.normal,
                      height: 1),
                ),
                Column(
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.call,
                                size: 24,
                                color: Colors.green,
                              ),
                            ),
                            Text(snapshot.data.phone,
                                style: TextStyle(
                                    color: Color.fromRGBO(0, 0, 0, 1),
                                    fontFamily: 'Montserrat',
                                    fontSize: 20,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1))
                          ],
                        )),
                    Padding(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                           Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.mail_outline,
                                size: 24,
                                color: Colors.green,
                              ),
                            ),
                            Text(snapshot.data.email,
                                style: TextStyle(
                                    color: Color.fromRGBO(0, 0, 0, 1),
                                    fontFamily: 'Montserrat',
                                    fontSize: 20,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1))
                          ],
                        )),
                  ],
                ),
                doctorCard(snapshot.data.name),
              ],
            );
          errorWidget(snapshot.data.toString());
        }
        return loadingWidget();
      },
    );
  }

  Widget doctorCard(String name) {
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/card_background.png',
            // color: _isRecording ? Colors.red : Colors.green,
            fit: BoxFit.fitWidth,
            height: MediaQuery.of(context).size.height * 0.4,
            semanticLabel: 'card',
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          child: Container(
              padding: EdgeInsets.all(10),
              // margin: EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width * 0.85,
              child: Text(this.doctorAddress,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      letterSpacing:
                          0 /*percentages not used in flutter. defaulting to zero*/,
                      fontWeight: FontWeight.normal,
                      height: 1))),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.26,
          // left: 20,
          child: Container(
            width: MediaQuery.of(context).size.width / 2,
            padding: EdgeInsets.only(left: 20),
            child: Text(name,
                style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1)),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.26,
          right: 20,
          child: Padding(
            padding: EdgeInsets.only(right: 50),
            child: Text('Doctor',
                style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1)),
          ),
        )
      ],
    );
  }

  Widget balance() {
    return FutureBuilder(
      future: balanceEth,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorWidget(snapshot.error.toString());
        } else if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData == false) {
          return errorWidget('No Data');
        } else if (snapshot.hasData) {
          if (snapshot.data is String)
            return Container(
                constraints:
                    BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ethIcon(),

                        // SizedBox(
                        //   width: MediaQuery.of(context).size.width * 0.6,
                        //   child: AutoSizeText.rich(
                        //     TextSpan(
                        //       text: snapshot.data,
                        //       style: TextStyle(fontSize: 35),
                        //     ),
                        //     minFontSize: 12,
                        //     stepGranularity: 0.1,
                        //   ),
                        // ),
                        Expanded(
                            child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          child: Column(
                            children: <Widget>[
                              AutoSizeText(
                                snapshot.data,
                                maxFontSize: 35,
                                maxLines: 2,
                                style: TextStyle(
                                    color: Color.fromRGBO(0, 0, 0, 1),
                                    fontFamily: 'Roboto',
                                    fontSize: 35,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1),
                              ),
                              Text('Available Balance',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      color: Color.fromRGBO(124, 108, 108, 1),
                                      fontFamily: 'Montserrat',
                                      fontSize: 18,
                                      letterSpacing:
                                          0 /*percentages not used in flutter. defaulting to zero*/,
                                      fontWeight: FontWeight.normal,
                                      height: 1)),
                            ],
                          ),
                        ))
                      ],
                    )));
          errorWidget(snapshot.data.toString());
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

  Widget ethIcon() {
    return Container(
        width: MediaQuery.of(context).size.width * 0.2,
        height: MediaQuery.of(context).size.width * 0.2,
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/eth.png'), fit: BoxFit.fitWidth),
          borderRadius: BorderRadius.all(Radius.elliptical(53, 49)),
        ));
  }

  Future fetchDoctorDetails(
      String doctorAddress, String doctorAuthToken) async {
    print('Doctor address $doctorAddress');
    print('Doctor Auth $doctorAuthToken');
    final http.Response response = await http.post('$apiUrl/doctor/details',
        headers: <String, String>{
          'Content-Type': 'application/json',
          'auth-token': doctorAuthToken
        },
        body: jsonEncode(<String, String>{'address': doctorAddress}));
    print(response.body);
    if (response.statusCode == 200) {
      return Doctor.fromJson(json.decode(response.body)['doctor']);
    } else if (response.statusCode == 401) return "Error";
    return Exception('Failed to load');
  }

  Future fetchBalance(String doctorAddress, String doctorAuthToken) async {
    print('Inside bal: $doctorAddress');
    final http.Response response = await http.post(
        '$apiUrl/doctor/wallet/balance',
        headers: <String, String>{
          'Content-Type': 'application/json',
          'auth-token': doctorAuthToken
        },
        body: jsonEncode(<String, String>{'doctorAddress': doctorAddress}));
    print(response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body)['balance'];
    } else if (response.statusCode == 401) return "Error";
    return Exception('Failed to load');
  }

  Future getDoctorCredentialsfromSharedPrefs() async {
    final SharedPreferences prefs = await _prefs;
    return {
      'doctorAddress': prefs.get('doctorAddress'),
      'doctorAuth': prefs.get('doctorToken')
    };
  }
}
