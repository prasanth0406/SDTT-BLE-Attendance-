import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ble_peripheral_plus/ble_peripheral_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class Teacher extends StatefulWidget {
  const Teacher({super.key});

  @override
  State<Teacher> createState() => _TeacherState();
}

class _TeacherState extends State<Teacher> {
  bool isAttendanceStarted = false;
  bool isSupported = false;
  final Map<String, String> connectedPhones = {};

  // Our attendance BLE service
  static const String serviceId = '12345678-1234-1234-1234-123456789abc';

  // Characteristic inside the service
  static const String characteristicId = 'abcdefab-cdef-abcd-efab-cdefabcdefab';

  Future<void> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) return;

    final permissions = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        debugPrint('Bluetooth permission denied: ${permission.toString()}');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    requestBluetoothPermissions();
    initializeBLE();
  }

  Future<void> initializeBLE() async {
    try {
      await BlePeripheral.initialize();

      BlePeripheral.setConnectionStateChangeCallback((deviceId, connected) {
        debugPrint('BLE connection update: $deviceId connected=$connected');

        if (!mounted) return;

        setState(() {
          if (connected) {
            connectedPhones.putIfAbsent(deviceId, () => 'Connecting...');
          } else {
            connectedPhones.remove(deviceId);
          }
        });
      });

      BlePeripheral.setWriteRequestCallback((
        deviceId,
        receivedCharacteristicId,
        offset,
        value,
      ) {
        final payload = value ?? Uint8List(0);

        if (receivedCharacteristicId == characteristicId) {
          final incomingName = utf8
              .decode(payload, allowMalformed: true)
              .trim();
          if (incomingName.isNotEmpty && mounted) {
            setState(() {
              connectedPhones[deviceId] = _displayNameFor(
                deviceId,
                incomingName,
              );
            });
          }
        }

        return WriteRequestResult(status: 0);
      });

      final supported = await BlePeripheral.isSupported();

      if (mounted) {
        setState(() {
          isSupported = supported;
        });
      }

      debugPrint("BLE Peripheral supported: $supported");
    } catch (e) {
      debugPrint("BLE initialization error: $e");
    }
  }

  String _displayNameFor(String deviceId, [String? incomingName]) {
    final cleanedName = incomingName?.trim();
    if (cleanedName != null && cleanedName.isNotEmpty) {
      return cleanedName;
    }

    if (deviceId.isEmpty) {
      return 'Unknown student';
    }

    final shortId = deviceId.length > 12 ? deviceId.substring(0, 12) : deviceId;
    return 'Student $shortId';
  }

  Future<void> startAttendance() async {
    try {
      await requestBluetoothPermissions();

      if (!isSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This phone does not support BLE advertising"),
          ),
        );
        return;
      }

      await BlePeripheral.clearServices();

      await BlePeripheral.addService(
        BleService(
          uuid: serviceId,
          primary: true,
          characteristics: [
            BleCharacteristic(
              uuid: characteristicId,
              properties: [
                CharacteristicProperties.read.index,
                CharacteristicProperties.writeWithoutResponse.index,
                CharacteristicProperties.write.index,
                CharacteristicProperties.notify.index,
              ],
              permissions: [
                AttributePermissions.readable.index,
                AttributePermissions.writeable.index,
              ],
              descriptors: null,
              value: Uint8List.fromList([1]),
            ),
          ],
        ),
      );

      BlePeripheral.setAdvertisingStatusUpdateCallback((advertising, error) {
        debugPrint("Advertising: $advertising Error: $error");

        if (mounted) {
          setState(() {
            isAttendanceStarted = advertising;
          });

          if (advertising) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Attendance BLE session started")),
            );
          }
        }
      });

      await BlePeripheral.startAdvertising(
        services: [serviceId],
        localName: 'ppasteam',
        requireBonding: false,
      );

      if (mounted) {
        setState(() {
          isAttendanceStarted = true;
        });
      }
    } catch (e) {
      debugPrint("BLE advertising error: $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("BLE advertising failed: $e")));
      }
    }
  }

  Future<void> stopAttendance() async {
    try {
      await BlePeripheral.stopAdvertising();

      if (mounted) {
        setState(() {
          isAttendanceStarted = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance BLE session stopped")),
        );
      }
    } catch (e) {
      debugPrint("BLE stop error: $e");
    }
  }

  @override
  void dispose() {
    if (isAttendanceStarted) {
      BlePeripheral.stopAdvertising();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Attendance")),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "TEACHER ATTENDANCE",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              const Text("Class: CSE-A", style: TextStyle(fontSize: 18)),

              const SizedBox(height: 20),

              Text(
                isSupported
                    ? "BLE Peripheral Supported"
                    : "Checking BLE support...",
              ),

              const SizedBox(height: 20),

              Text(
                isAttendanceStarted ? "BLE: ON 🟢" : "BLE: OFF 🔴",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: isAttendanceStarted ? null : startAttendance,

                child: const Text("START ATTENDANCE"),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: isAttendanceStarted ? stopAttendance : null,

                child: const Text("STOP ATTENDANCE"),
              ),

              const SizedBox(height: 20),

              const Text(
                "Connected phones",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              if (connectedPhones.isEmpty)
                const Text("No student phone connected yet")
              else
                SizedBox(
                  height: 160,
                  width: 260,
                  child: ListView.builder(
                    itemCount: connectedPhones.length,
                    itemBuilder: (context, index) {
                      final entry = connectedPhones.entries.toList()[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.phone_android),
                          title: Text(entry.value),
                          subtitle: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
