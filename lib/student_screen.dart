import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'student_ble_connector.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final List<ScanResult> discoveredDevices = [];
  late final StreamSubscription<List<ScanResult>> _scanSubscription;

  bool isScanning = false;
  bool isConnecting = false;
  bool isConnected = false;
  String statusText = 'Tap Rescan to search for nearby BLE devices';
  BluetoothDevice? selectedTeacherDevice;

  @override
  void initState() {
    super.initState();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        discoveredDevices
          ..clear()
          ..addAll(results);
      });
    });
    startScan();
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> startScan() async {
    try {
      await StudentBleConnector.requestPermissions();

      if (!await StudentBleConnector.ensureBluetoothEnabled()) {
        if (!mounted) return;
        setState(() {
          isScanning = false;
          statusText = 'Bluetooth is OFF. Please turn it ON first.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        isScanning = true;
        discoveredDevices.clear();
        statusText = 'Scanning for nearby BLE advertisers...';
      });

      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      if (!mounted) return;
      setState(() {
        isScanning = false;
        statusText = discoveredDevices.isEmpty
            ? 'No BLE devices found nearby.'
            : 'Scan complete. Select a teacher device to connect.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isScanning = false;
        statusText = 'Scan failed: $e';
      });
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (!mounted) return;
    setState(() {
      isScanning = false;
      statusText = 'Scan stopped.';
    });
  }

  Future<void> connectToTeacher(BluetoothDevice? device) async {
    if (device == null) {
      return;
    }

    setState(() {
      isConnecting = true;
      selectedTeacherDevice = device;
      statusText = 'Connecting to teacher BLE session...';
    });

    try {
      final characteristic = await StudentBleConnector.connectToDevice(device);

      if (!mounted) return;

      if (characteristic == null) {
        setState(() {
          isConnecting = false;
          isConnected = false;
          statusText =
              'Teacher not found. Start attendance on the teacher phone.';
        });
        return;
      }

      setState(() {
        isConnecting = false;
        isConnected = true;
        statusText = 'Connected to teacher BLE session.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isConnecting = false;
        isConnected = false;
        statusText = 'Connection failed: $e';
      });
    }
  }

  bool isTeacherDevice(ScanResult result) {
    return StudentBleConnector.matchesTeacherDevice(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.bluetooth_searching, size: 60),
            const SizedBox(height: 12),
            const Text(
              'Nearby BLE Advertisers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isConnected ? Colors.green : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isScanning ? null : startScan,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rescan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isScanning ? stopScan : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: discoveredDevices.isEmpty
                  ? const Center(
                      child: Text('No BLE devices found yet. Press Rescan.'),
                    )
                  : ListView.builder(
                      itemCount: discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final result = discoveredDevices[index];
                        final name = result.device.platformName.isNotEmpty
                            ? result.device.platformName
                            : (result.advertisementData.advName.isNotEmpty
                                  ? result.advertisementData.advName
                                  : 'Unknown Device');
                        final isTeacher = isTeacherDevice(result);

                        return Card(
                          child: ListTile(
                            onTap: () => connectToTeacher(result.device),
                            leading: Icon(
                              isTeacher ? Icons.school : Icons.bluetooth,
                              color: isTeacher ? Colors.green : Colors.blue,
                            ),
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('RSSI: ${result.rssi} dBm'),
                                if (result
                                    .advertisementData
                                    .serviceUuids
                                    .isNotEmpty)
                                  Text(
                                    'UUIDs: ${result.advertisementData.serviceUuids.join(', ')}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (isTeacher)
                                  const Text(
                                    'Teacher session detected',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.link),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
