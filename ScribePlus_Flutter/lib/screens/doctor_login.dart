import 'package:ScribePlus/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:ScribePlus/url.dart';

class DoctorLogin extends StatefulWidget {
  DoctorLogin({Key key}) : super(key: key);

  _DoctorLoginState createState() => _DoctorLoginState();
}

class _DoctorLoginState extends State<DoctorLogin> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _doctorAddress;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController passwordController = new TextEditingController();
  @override
  void initState() {
    _doctorAddress = '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
        key: _scaffoldKey,
        body: Center(
          child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                Padding(
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: 'Welcome to Scribe+',
                          style: TextStyle(
                              color: Color.fromRGBO(0, 0, 0, 1),
                              fontFamily: 'Montserrat',
                              fontSize: 32,
                              letterSpacing:
                                  0 /*percentages not used in flutter. defaulting to zero*/,
                              fontWeight: FontWeight.normal,
                              height: 1)),
                    ]),
                  ),
                  padding: EdgeInsets.only(top: 75, bottom: 10),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 30),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/scribe1.jpg',
                      height: 0.3 * height,
                      width: 0.6 * width,
                      semanticLabel: 'Scribe Intro',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 30),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: 'Scan QR Code to get started',
                          style: TextStyle(
                              color: Color.fromRGBO(0, 0, 0, 1),
                              fontFamily: 'Montserrat',
                              fontSize: 23,
                              letterSpacing:
                                  0 /*percentages not used in flutter. defaulting to zero*/,
                              fontWeight: FontWeight.normal,
                              height: 1)),
                    ]),
                  ),
                ),
                loginButtons(),
                nextButton(),
              ])),
        ));
  }

  Widget loginButtons() {
    return Column(
      children: <Widget>[scanButton(), password()],
    );
  }

  Widget password() {
    return Container(
      width: 350,
      height: 60,
      //color: Colors.lightGreenAccent[200],
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
      ),
      child: Row(
        children: <Widget>[
          Padding(
              padding: EdgeInsets.only(left: 32),
              child: Icon(
                Icons.lock,
                color: Colors.white,
                size: 50,
              )),
          Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                  width: 230,
                  child: TextField(
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Montserrat',
                        fontSize: 23,
                        letterSpacing:
                            0 /*percentages not used in flutter. defaulting to zero*/,
                        fontWeight: FontWeight.normal,
                        height: 1),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          fontFamily: 'Montserrat',
                          fontSize: 23,
                          letterSpacing:
                              0 /*percentages not used in flutter. defaulting to zero*/,
                          fontWeight: FontWeight.normal,
                          height: 1),
                      hintText: "PASSWORD",
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    controller: passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                  )))
        ],
      ),
    );
  }

  Widget scanButton() {
    return Padding(
        padding: EdgeInsets.all(5),
        child: InkWell(
          onTap: () {
            _scan().then((String scannedString) {
              setState(() {
                _doctorAddress = scannedString;
              });
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
                    top: 16,
                    left: 160,
                    child: Text(
                      'SCAN',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          fontFamily: 'Montserrat',
                          fontSize: 23,
                          letterSpacing:
                              0 /*percentages not used in flutter. defaulting to zero*/,
                          fontWeight: FontWeight.normal,
                          height: 1),
                    )),
                Positioned(
                  top: 10,
                  left: 38,
                  child: SvgPicture.asset('assets/images/vector.svg',
                      semanticsLabel: 'vector'),
                ),
              ])),
        ));
  }

  Widget nextButton() {
    return InkWell(
        onTap: () {
          if (this._doctorAddress == '') {
            final SnackBar snackBar = SnackBar(content: Text('Scan QR again!'));
            _scaffoldKey.currentState.showSnackBar(snackBar);
          } else if (passwordController.text == '') {
            final SnackBar snackBar =
                SnackBar(content: Text('Password Not Entered!'));
            _scaffoldKey.currentState.showSnackBar(snackBar);
          } else {
            _postLoginRequest(_doctorAddress, passwordController.text)
                .then((bool result) {
                  print(result);
              if (result == false) {
                setState(() {
                  _doctorAddress = '';
                });
                final SnackBar snackBar =
                    SnackBar(content: Text('Login Failed!'));
                _scaffoldKey.currentState.showSnackBar(snackBar);
              } else
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => new Home(),
                    ));
            });
          }
        },
        child: SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
                width: 71,
                height: 30,
                child: Stack(children: <Widget>[
                  Positioned(
                      top: 30,
                      left: 71,
                      child: Transform.rotate(
                        angle: 180 * (3.14 / 180),
                        child: SvgPicture.asset('assets/images/vector.svg',
                            semanticsLabel: 'vector'),
                      )),
                  Positioned(
                      top: 20,
                      left: 300,
                      child: Transform.rotate(
                        angle: -3.0617613445625937e-22 * (3.14 / 180),
                        child: Text(
                          'next',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: Color.fromRGBO(24, 199, 99, 1),
                              fontFamily: 'Montserrat',
                              fontSize: 18,
                              letterSpacing:
                                  0 /*percentages not used in flutter. defaulting to zero*/,
                              fontWeight: FontWeight.normal,
                              height: 1),
                        ),
                      )),
                ]))));
  }

  Future<bool> _postLoginRequest(String userAddress, String password) async {
    String loginURL = "$apiUrl/doctor/login";
    final SharedPreferences prefs = await _prefs;
    print({'address': userAddress, 'password': password});
    var response = await http
        .post(loginURL, body: {'address': userAddress, 'password': password});
    if (response.statusCode == 200) {
      prefs.setString("doctorToken", response.headers['auth-token']);
      prefs.setString("doctorAddress", userAddress);
      return true;
    } else
      return false;
  }

  Future<String> _scan() async {
    String scannedString = await scanner.scan();
    return scannedString;
  }
}
