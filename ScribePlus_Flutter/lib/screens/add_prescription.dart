import 'dart:io' as io;
import 'dart:core';
import 'dart:convert';
import 'dart:async';
import 'package:ScribePlus/screens/processing_prescription.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timer/flutter_timer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:audio_recorder/audio_recorder.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ScribePlus/url.dart';
import 'package:ScribePlus/backWidget.dart';

class UploadAudioPrescription extends StatefulWidget {
  final String patientAddress;
  final LocalFileSystem localFileSystem;
  UploadAudioPrescription({@required this.patientAddress, localFileSystem})
      : this.localFileSystem = localFileSystem ?? LocalFileSystem();
  @override
  _UploadAudioPrescriptionState createState() =>
      new _UploadAudioPrescriptionState(patientAddress);
}

class _UploadAudioPrescriptionState extends State<UploadAudioPrescription> {
  bool timerRunning = false;
  bool _isRecording = false;

  static const platform = const MethodChannel('scribeplus.sendstring');
  String receivedString = "";

  Future<void> callNativeFunction() async {
    String msg = "Hello from Flutter", data = "";
    try {
      final String temp =
          await platform.invokeMethod('callSendStringFun', {"arg": msg});
      data = temp;
    } on PlatformException catch (e) {
      data = "Failed";
    }
    setState(() {
      _audioFullPath = data;
    });
    print("finding $data");
  }

  Future<void> stopFuncOp() async {
    bool data = false;
    try {
      final bool temp = await platform.invokeMethod('stopRecord');
      data = temp;
    } on PlatformException catch (e) {
      data = false;
    }
    print("data is $data");
  }

  PermissionStatus _permissionStatus = PermissionStatus.undetermined;
  Permission _permission = Permission.speech;
  String _audioFullPath = "/storage/emulated/0/recordingxxx.mp3";
  TextEditingController _controller = new TextEditingController();
  String _uploadResponseStatus;
  String authToken;
  String patientAddress;
  DateTime currTime;
  bool completedRecording = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  _UploadAudioPrescriptionState(this.patientAddress);

  @override
  void initState() {
    super.initState();
    requestPermission(_permission);
    getAuthToken().then((authToken) {
      this.authToken = authToken;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        body: new Center(
          child: new Padding(
            padding: new EdgeInsets.all(8.0),
            child: completedRecording
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "Do you want to transcribe this conversation?",
                            style: TextStyle(
                                color: Color.fromRGBO(0, 0, 0, 1),
                                fontFamily: 'Montserrat',
                                fontSize: 30,
                                letterSpacing:
                                    0 /*percentages not used in flutter. defaulting to zero*/,
                                fontWeight: FontWeight.normal,
                                height: 1),
                          )),
                      uploadWidget(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text("No, I want to retake",
                              style: TextStyle(
                                  color: Color.fromRGBO(0, 0, 0, 1),
                                  fontFamily: 'Montserrat',
                                  fontSize: 20,
                                  letterSpacing:
                                      0 /*percentages not used in flutter. defaulting to zero*/,
                                  fontWeight: FontWeight.normal,
                                  height: 1)),
                          new IconButton(
                            icon:
                                Icon(Icons.replay, size: 56, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                completedRecording = false;
                                _audioFullPath = '';
                                currTime = new DateTime.now();
                              });
                            },
                          )
                        ],
                      ),
                    ],
                  )
                : new Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                        // backButton(_scaffoldKey.currentContext),
                        micDisplay(),
                        TikTikTimer(
                          initialDate: currTime,
                          running: timerRunning,
                          height: MediaQuery.of(context).size.height * 0.2,
                          width: MediaQuery.of(context).size.width * 0.8,
                          backgroundColor: Colors.transparent,
                          timerTextStyle: TextStyle(
                              color: Color.fromRGBO(0, 0, 0, 1),
                              fontFamily: 'Montserrat',
                              fontSize: 36,
                              letterSpacing:
                                  0 /*percentages not used in flutter. defaulting to zero*/,
                              fontWeight: FontWeight.normal,
                              height: 1),
                          borderRadius: 0,
                          isRaised: false,
                          tracetime: (time) {
                            // print(time.getCurrentSecond);
                          },
                        ),
                        // stopRecording(),
                        Container(
                            child: Center(
                                child: _isRecording
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.stop,
                                          size: 56,
                                          color: Colors.red,
                                        ),
                                        onPressed: _isRecording ? _stop : null,
                                      )
                                    : IconButton(
                                        icon: Icon(Icons.play_arrow,
                                            size: 56, color: Colors.green),
                                        onPressed: _isRecording ? null : _start,
                                      )))
                      ]),
          ),
        ));
  }

  Widget micDisplay() {
    return Container(
        width: MediaQuery.of(context).size.width * 0.6,
        // height: MediaQuery.of(context).size.width * 0.4,
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/mic1.png',
                color: _isRecording ? Colors.red : Colors.green,
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height * 0.4,
                semanticLabel: 'mic1',
              ),
            ),
          ],
        ));
  }

  // Widget micDisplay() {
  //   return Container(
  //       width: MediaQuery.of(context).size.width * 0.8,
  //       child: Align(
  //           alignment: Alignment.center,
  //           child: Icon(Icons.mic_none,
  //               color: _isRecording ? Colors.red : Colors.green,
  //               size: MediaQuery.of(context).size.width * 0.7)));
  // }
  Widget uploadWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text("Yes, upload",
            style: TextStyle(
                color: Color.fromRGBO(0, 0, 0, 1),
                fontFamily: 'Montserrat',
                fontSize: 20,
                letterSpacing:
                    0 /*percentages not used in flutter. defaulting to zero*/,
                fontWeight: FontWeight.normal,
                height: 1)),
        IconButton(
          icon: Icon(Icons.file_upload),
          iconSize: 60,
          color: Colors.grey,
          onPressed: () {
            uploadAudio().then((socketEvent) {
              if (socketEvent != '')
                Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => FollowUp(
                            patientAddress: this.patientAddress,
                            socketEvent: socketEvent)));
              else {
                final SnackBar snackBar =
                    SnackBar(content: Text('Could not process audio'));
                _scaffoldKey.currentState.showSnackBar(snackBar);
              }
            });
          },
        )
      ],
    );
  }

  Future<void> requestPermission(Permission permission) async {
    final status = await permission.request();
    setState(() {
      _permissionStatus = status;
      print(_permissionStatus);
    });
  } //Request permissions for Audio

  Future<String> uploadAudio() async {
    final SharedPreferences prefs = await _prefs;
    var request =
        http.MultipartRequest('POST', Uri.parse('$apiUrl/doctor/upload/audio'));
    request.headers.addAll({'auth-token': this.authToken});
    print("Path" + _audioFullPath);
    request.files
        .add(await http.MultipartFile.fromPath('file', _audioFullPath));
    var streamedResponse = await request.send();
    var response = await streamedResponse.stream.bytesToString();
    var parsedJson = json.decode(response);
    print(parsedJson);
    print(parsedJson['socketId']);
    prefs.setString("Socket-ID", parsedJson['socketID']);
    // return parsedJson['socketID'];
    return parsedJson['socketId'];
  }

  _start() async {
    try {
      await callNativeFunction();
      setState(() {
        _isRecording = true;
        timerRunning = true;
        currTime = new DateTime.now();
      });
    } catch (e) {
      print(e);
    }
//    try {
//      if (_permissionStatus == PermissionStatus.granted) {
//        io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
//        String filename =
//            new DateTime.now().millisecondsSinceEpoch.toString() + '.mp4';
//        String path = appDocDirectory.path + '/' + filename;
//        await AudioRecorder.start(
//            path: path, audioOutputFormat: AudioOutputFormat.AAC);
//        bool isRecording = await AudioRecorder.isRecording;
//        setState(() {
//          currTime = new DateTime.now();
//          timerRunning = true;
//          _audioFullPath = path;
//          _recording = new Recording(duration: new Duration(), path: "");
//          _isRecording = isRecording;
//        });
//      } else {
//        Scaffold.of(context).showSnackBar(
//            new SnackBar(content: new Text("You must accept permissions")));
//      }
//    } catch (e) {
//      print(e);
//    }
  }

  _stop() async {
    try {
      await stopFuncOp();
      setState(() {
        _isRecording = false;
        completedRecording = true;
        timerRunning = false;
      });
    } catch (e) {
      print(e);
    }
//    var recording = await AudioRecorder.stop();
//    print("Stop recording: ${recording.path}");
//    bool isRecording = await AudioRecorder.isRecording;
//    File file = widget.localFileSystem.file(recording.path);
//    print(" File length: ${await file.length()}");
//    setState(() {
//      completedRecording = true;
//      timerRunning = false;
//      _recording = recording;
//      _isRecording = isRecording;
//    });
//    _controller.text = recording.path;
  }

  Future<String> getAuthToken() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.get("doctorToken");
  }
}
