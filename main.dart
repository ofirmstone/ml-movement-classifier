import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Arduino IMU Movement Classifier',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const ScanScreen(title: 'Arduino IMU Movement Classifier'),
  );
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.title});

  final String title;

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String currentGesture = "Unknown";
  final serviceUUID = Guid("19B10000-E8F2-537E-4F6C-D104768A1214");
  final characteristicUUID = Guid("19B10001-E8F2-537E-4F6C-D104768A1215");
  final List<String> targetDeviceName = ["IMUClassifier", "Arduino"];

  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? gestureCharacteristic;

  @override
  void initState() {
    super.initState();

    setState(() {
      currentGesture = "Scanning...";
    });

    scanForDevice();
  }

  void scanForDevice() async {
    if (await FlutterBluePlus.isSupported == false) {
      // output log to show that bluetooth is not supported
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      // log bluetooth is off and for user to turn it on
      if (!Platform.isAndroid) {
        return;
      }
      await FlutterBluePlus.turnOn(); // request the user to turn on Bluetooth
    }

    FlutterBluePlus.startScan(
      withServices: [serviceUUID],
      withNames: targetDeviceName,
    );

    FlutterBluePlus.scanResults.listen((results) {
      if (results.isNotEmpty) {
        for (ScanResult result in results) {
          connectToDevice(result.device);
        }
      }
    });


  }

  void connectToDevice(BluetoothDevice device) async {
    FlutterBluePlus.stopScan();

    setState(() {
      currentGesture = "Connecting...";
    });

    try {
      await device.connect(autoConnect: true);

      discoverServices(device);

    } catch (e) {
      setState(() {
        currentGesture = "Connection failed: ${e.toString()}";
      });
    }

  }

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    for (BluetoothService service in services) {
      if (service.uuid == serviceUUID) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid == characteristicUUID) {
            setState(() {
              currentGesture = "Connected. Waiting for gesture.";
            });

            await characteristic.setNotifyValue(true);

            characteristic.onValueReceived.listen((value) {
              setState(() {
                currentGesture = utf8.decode(value).trim();
              });
            });
          }
        }
      }
    }

    setState(() {
      currentGesture = "Gesture characteristic not found (failed)";
    });
  }


  @override
  void dispose() {
    // clear connections
    super.dispose();
  }




  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currentGesture,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: currentGesture == "Scanning..."
                  ? Colors.blue
                  : currentGesture == "Connecting..."
                  ? Colors.orange
                  : currentGesture.contains("failed")
                  ? Colors.red
                  : Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          if (currentGesture.contains("failed"))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () => scanForDevice(),
                child: Text('Retry Scan'),
              ),
            ),
        ],
      ),
    ),
  );
}
