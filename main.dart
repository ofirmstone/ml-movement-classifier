import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arduino BLE Movement Classifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ScanScreen(),
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  bool isScanning = false;
  bool deviceFound = false;
  String currentGesture = "Unknown";


  // BluetoothCharacteristic? targetCharacteristic;

  final String serviceUUID = "19B10000-E8F2-537E-4F6C-D104768A1214";
  final String characteristicUUID = "19B10001-E8F2-537E-4F6C-D104768A1215";
  // final String confidenceCharacteristicUuid = "19B10001-E8F2-537E-4F6C-D104768A1216";
  final String targetDeviceName = "IMUClassifier";

  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<List<int>>? characteristicSubscription;
  BluetoothDevice? targetDevice;

  @override
  void initState() {
    super.initState();
    flutterBlue.state.listen((state) {
      if (state != BluetoothState.on) {
        setState(() {
          deviceFound = false;
          currentGesture = "Bluetooth is off";
        });
      }
    });
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    characteristicSubscription?.cancel();
    // if (targetDevice != null) {
    //   targetDevice!.disconnect();
    // }
    super.dispose();
  }

  /// Scans for the target BLE device.
  void scanForDevice() async {
    if (isScanning) return;

    BluetoothState bluetoothState = await flutterBlue.state.first;
    if (bluetoothState != BluetoothState.on) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please turn on Bluetooth')),
      );
      return;
    }

    setState(() {
      isScanning = true;
      deviceFound = false;
      currentGesture = "Scanning...";
    });

    flutterBlue.startScan(timeout: const Duration(seconds: 10));
    
    scanSubscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        String scanName = result.device.name;
        if (scanName.contains('Arduino') || scanName.contains('IMUClassifier') ||
            result.advertisementData.serviceUuids.contains(Guid(serviceUUID))) {
          connectToDevice(result.device);
          break;
        }
      }
    }, onDone: () {
      setState(() {
        isScanning = false;
        if (!deviceFound) {
          currentGesture = "No device found";
        }
      });
    });

    Future.delayed(const Duration(seconds: 10), () {
      flutterBlue.stopScan();
    });

    // flutterBlue.scan(timeout: Duration(seconds: 4)).listen((scanResult) {
    //   if (scanResult.device.name == targetDeviceName || scanResult.device.name == "Arduino") {
    //     flutterBlue.stopScan();
    //     targetDevice = scanResult.device;
    //     connectToDevice();
    //   }
    // });
  }

  /// Connects to the target device.
  Future<void> connectToDevice(BluetoothDevice device) async {
    flutterBlue.stopScan();
    scanSubscription?.cancel();

    setState(() {
      targetDevice = device;
      currentGesture = "Connecting...";
    });

    try {
      await device.connect();

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUUID) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == characteristicUUID) {
              await characteristic.setNotifyValue(true);
              characteristicSubscription = characteristic.value.listen((value) {
                if (value.isNotEmpty) {
                  setState(() {
                    currentGesture = utf8.decode(value).trim();
                    deviceFound = true;
                  });
                }
              });

              setState(() {
                deviceFound = true;
                isScanning = false;
              });

              return;
            }
          }
        }
      }

      setState(() {
        currentGesture = "Gesture characteristic not found";
        isScanning = false;
      });
    } catch (e) {
      setState(() {
        currentGesture = "Connection failed: ${e.toString()}";
        isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arduino BLE Movement Classifier'),
        actions: [
          if (deviceFound)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: () async {
                characteristicSubscription?.cancel();
                await targetDevice?.disconnect();
                setState(() {
                  deviceFound = false;
                  currentGesture = "Disconnected";
                });
              }
            ),
        ],
      ),

      body: Center(
        child: deviceFound
            ? Text(
              currentGesture, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )
            : ElevatedButton(
              onPressed: isScanning ? null : scanForDevice,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)
              ),
              child: isScanning
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text("Scanning..."),
                    ],
                  )
                : const Text(
                    "Scan",
                    style: TextStyle(fontSize: 20),
                  ),
            ),
      ),
    );
  }
}
