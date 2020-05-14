import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volume_mixer/volume_mixer.dart';

String globalIPAddress;
String baseURL;
Future<List<Text>> futureInfo;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volume Mixer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColorBrightness: Brightness.dark,
        accentColorBrightness: Brightness.dark,
        primaryColor: Colors.green,
        accentColor: Colors.purple,
        // sliderTheme: SliderThemeData(thumbColor: Colors.orange),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Home(),
    );
  }
}

//Stateless because as soon as input is received, we navigate away from this page
class Home extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    icon: IconButton(
                      icon: Icon(Icons.camera_alt),
                      tooltip: "Capture QR Code",
                      onPressed: () => scanQRCode(context),
                    ),
                    labelText: "Enter Computer IP Address",
                    hintText: "123.123.123.123",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    WhitelistingTextInputFormatter(RegExp("[0-9.\n]")),
                  ],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (value) => _formKey.currentState.validate(),
                  validator: (value) => validateIPAddress(value),
                ),
                RaisedButton(
                  child: Text("Connect"),
                  onPressed: () {
                    final state = _formKey.currentState;
                    if (state.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VolumeMixer(),
                        ),
                      );
                    }
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future scanQRCode(BuildContext context) async {
    try {
      var options = ScanOptions(
        strings: {
          "cancel": "Cancel",
          "flash_on": "Flash On",
          "flash_off": "Flash Off"
        },
        restrictFormat: [
          BarcodeFormat.qr
        ], //Only recognize QR codes and no other types of barcode
        autoEnableFlash: false,
        android: AndroidOptions(useAutoFocus: true),
      );
      ScanResult result = await BarcodeScanner.scan(options: options);
      if (result.type == ResultType.Barcode) {
        String ipAddress = result.rawContent;
        String validMessage = validateIPAddress(ipAddress);
        if (validMessage == null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VolumeMixer(),
            ),
          );
        } else {
          showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) {
                return AlertDialog(
                  title: Text("Error"),
                  content: Text(validMessage),
                  actions: <Widget>[
                    FlatButton(
                        child: Text("OK"),
                        onPressed: () => Navigator.of(context).pop())
                  ],
                );
              });
        }
      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return AlertDialog(
                title: Text("Error"),
                content: Text(
                    "App needs Camera permissions for this functionality."),
                actions: <Widget>[
                  FlatButton(
                      child: Text("OK"),
                      onPressed: () => Navigator.of(context).pop())
                ],
              );
            });
      } else {
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return AlertDialog(
                title: Text("Error"),
                content: Text("Unknown error: $e"),
                actions: <Widget>[
                  FlatButton(
                      child: Text("OK"),
                      onPressed: () => Navigator.of(context).pop())
                ],
              );
            });
      }
    }
  }

  String validateIPAddress(String value) {
    var regEx = RegExp(r'^\d{1,3}[.]\d{1,3}[.]\d{1,3}[.]\d{1,3}$');
    if (value.isEmpty)
      return "IP Address is required";
    else if (!regEx.hasMatch(value))
      return "Incorrectly formatted IP Address";
    else {
      globalIPAddress = value;
      baseURL = "http://" + value + ":8080/volume/";
      return null;
    }
  }
}
