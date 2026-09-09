import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class sdtt extends StatefulWidget {
  const sdtt({super.key});

  @override
  State<sdtt> createState() => _sdttState();
}

class _sdttState extends State<sdtt> {
  List<ScanResult> devicesList = [];
  bool isScanning = false;
  bool yess = false;

  final auth = LocalAuthentication();

  Future<void> auther() async {
    final prasanth = await auth.authenticate(
      localizedReason: "PLEASE AUTHENTICATE TO CONTINUE",
    );

    if (prasanth) {
      setState(() {
        yess = true;
      });

      scanBLE();
    } else {
      debugPrint("hello error");
    }
  }

  Future<void> scanBLE() async {
    try {
      final bluetoothState = await FlutterBluePlus.adapterState.first;

      if (bluetoothState != BluetoothAdapterState.on) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please turn on Bluetooth to scan for devices."),
          ),
        );

        return;
      }

      setState(() {
        devicesList.clear();
        isScanning = true;
      });

      FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            devicesList = results;
          });
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    } catch (e) {
      debugPrint("Error scanning for BLE devices: $e");

      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    auther();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,

            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  const Text(
                    "WELCOME TO SDTT ATTENDANCE",
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  Text("Devices found: ${devicesList.length}"),

                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView.builder(
                      itemCount: devicesList.length,

                      itemBuilder: (context, index) {
                        final result = devicesList[index];

                        return ListTile(
                          leading: const Icon(Icons.bluetooth),

                          title: Text(
                            result.device.platformName.isNotEmpty
                                ? result.device.platformName
                                : "Unknown Device",
                          ),

                          subtitle: Text("RSSI: ${result.rssi}"),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
