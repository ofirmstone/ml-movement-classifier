import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arduino BLE & CSV Logger',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // BLE-related variables
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? targetCharacteristic;
  String currentState = "Unknown";

  // CSV Logging variables
  File? logFile;
  final String csvFilename = "running.csv";


  final String serviceUUID = "19B10010-E8F2-537E-4F6C-D104768A1214";
  final String characteristicUUID = "19B10011-E8F2-537E-4F6C-D104768A1214";
  final String targetDeviceName = "Arduino Nano BLE 33";

  @override
  void initState() {
    super.initState();
    initCSVFile();
    scanForDevice();
  }

  /// Initializes the CSV log file in the device's documents directory.
  Future<void> initCSVFile() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path;
    logFile = File('$path/$csvFilename');
    if (!await logFile!.exists()) {
      await logFile!.create(recursive: true);
      // Optionally, write a header row
      await logFile!.writeAsString("timestamp,state,raw_data\n", mode: FileMode.write);
    }
  }

  /// Scans for the target BLE device.
  void scanForDevice() {
    flutterBlue.scan(timeout: Duration(seconds: 4)).listen((scanResult) {
      if (scanResult.device.name == targetDeviceName) {
        flutterBlue.stopScan();
        targetDevice = scanResult.device;
        connectToDevice();
      }
    });
  }

  /// Connects to the target device.
  Future<void> connectToDevice() async {
    if (targetDevice == null) return;
    await targetDevice!.connect();
    discoverServices();
  }

  /// Discovers services and characteristics.
  Future<void> discoverServices() async {
    if (targetDevice == null) return;
    List<BluetoothService> services = await targetDevice!.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString() == serviceUUID) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristicUUID) {
            targetCharacteristic = characteristic;
            subscribeToCharacteristic();
            return;
          }
        }
      }
    }
  }

  /// Subscribes to the characteristic to receive data and logs each packet.
  void subscribeToCharacteristic() async {
    if (targetCharacteristic == null) return;
    await targetCharacteristic!.setNotifyValue(true);
    targetCharacteristic!.value.listen((value) {
      if (value.isNotEmpty) {
        // Decode the incoming BLE data into a string.
        String csvRow = utf8.decode(value).trim();
        List<String> parts = csvRow.split(',');
        int stateCode = -1;
        if (parts.isNotEmpty) {
          stateCode = int.tryParse(parts[0]) ?? -1;
        }
        // Update UI based on state code.
        setState(() {
          switch (stateCode) {
            case 0:
              currentState = "Idle";
              break;
            case 1:
              currentState = "Walking";
              break;
            case 2:
              currentState = "Running";
              break;
            default:
              currentState = "Unknown";
          }
        });

        // Prepare and append a CSV log entry with a timestamp.
        String timestamp = DateTime.now().toIso8601String();
        String logEntry = "$timestamp,$csvRow\n";
        if (logFile != null) {
          logFile!.writeAsString(logEntry, mode: FileMode.append).catchError((error) {
            print("Error writing to CSV: $error");
          });
        }
      }
    });
  }

  @override
  void dispose() {
    if (targetDevice != null) {
      targetDevice!.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arduino BLE & CSV Logger'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Current State:', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text(
              currentState,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            // Display the CSV log file path.
            FutureBuilder<String>(
              future: getCSVFilePath(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return Text('CSV Log File:\n${snapshot.data}', textAlign: TextAlign.center);
                }
                return CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> getCSVFilePath() async {
    Directory directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$csvFilename';
  }
}

