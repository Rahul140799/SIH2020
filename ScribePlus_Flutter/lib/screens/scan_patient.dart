import 'package:ScribePlus/screens/view_patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qrscan/qrscan.dart' as scanner;

class ScanPatient extends StatefulWidget {
  @override
  _ScanPatientState createState() => _ScanPatientState();
}

class _ScanPatientState extends State<ScanPatient> {
  String patientAddress;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    text: 'Welcome Back,',
                    style: TextStyle(
                        color: Color.fromRGBO(24, 115, 158, 1),
                        fontFamily: 'Roboto',
                        fontSize: 32,
                        letterSpacing:
                            0 /*percentages not used in flutter. defaulting to zero*/,
                        fontWeight: FontWeight.normal,
                        height: 1)),
              ]),
            ),
            padding: EdgeInsets.only(top: 0, bottom: 10),
          ),
          Padding(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: 'Doctor!',
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
            padding: EdgeInsets.only(top: 50),
          ),
          Padding(
              padding: EdgeInsets.only(top: 100, bottom: 50),
              child: Text(
                'Scan to view your Patient',
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: Color.fromRGBO(0, 0, 0, 1),
                    fontFamily: 'Roboto',
                    fontSize: 28,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1),
              )),
          scanButton(),
        ]))));
  }

  Widget scanButton() {
    return Padding(
        padding: EdgeInsets.only(top: 70),
        child: InkWell(
          onTap: () {
            _scan().then((String scannedString) {
              setState(() {
                this.patientAddress = scannedString;
              });
              print('SS');
              print(scannedString);
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (context) =>
                          new ViewPatient(patientQr: this.patientAddress)));
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

  Future<String> _scan() async {
    String scannedString = await scanner.scan();
    return scannedString;
  }
}
