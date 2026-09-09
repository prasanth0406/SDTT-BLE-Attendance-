import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class StudentBleConnector {
  static const String teacherServiceId = '12345678-1234-1234-1234-123456789abc';
  static const String teacherCharacteristicId =
      'abcdefab-cdef-abcd-efab-cdefabcdefab';
  static const List<String> teacherLocalNames = [
    'SDTT',
    'SDTT_CLASS',
    'prasanth',
  ];

  static Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;

    final permissions = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    for (final permission in permissions) {
      if (await permission.isDenied) {
        await permission.request();
      }
    }
  }

  static Future<bool> ensureBluetoothEnabled() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  static bool matchesTeacherDevice(ScanResult result) {
    final serviceUuids = result.advertisementData.serviceUuids;
    final hasTeacherService = serviceUuids.any(
      (uuid) => uuid.toString().toUpperCase() == teacherServiceId.toUpperCase(),
    );

    final name = result.advertisementData.advName.isNotEmpty
        ? result.advertisementData.advName
        : result.device.platformName;
    final hasTeacherName = teacherLocalNames.any(
      (localName) => name.toUpperCase() == localName.toUpperCase(),
    );

    return hasTeacherService || hasTeacherName;
  }

  static Future<BluetoothDevice?> findTeacher() async {
    await requestPermissions();

    if (!await ensureBluetoothEnabled()) {
      return null;
    }

    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(
      withServices: [Guid(teacherServiceId)],
      withNames: teacherLocalNames,
      timeout: const Duration(seconds: 10),
    );

    final results = await FlutterBluePlus.scanResults.firstWhere(
      (items) => items.any(matchesTeacherDevice),
      orElse: () => const <ScanResult>[],
    );

    final teacher = results.firstWhere(
      matchesTeacherDevice,
      orElse: () => throw StateError('Teacher device not found'),
    );

    return teacher.device;
  }

  static Future<String> getStudentDeviceName() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final model = info.model.trim();
      if (model.isNotEmpty) {
        return model;
      }
    }

    return 'Android Device';
  }

  static Future<BluetoothCharacteristic?> connectToDevice(
    BluetoothDevice device,
  ) async {
    await device.connect(
      license: License.nonprofit,
      timeout: const Duration(seconds: 10),
    );

    final services = await device.discoverServices();
    final targetService = services.firstWhere(
      (service) =>
          service.uuid.toString().toUpperCase() ==
          teacherServiceId.toUpperCase(),
      orElse: () => throw StateError('Teacher service not found'),
    );

    final characteristic = targetService.characteristics.firstWhere(
      (item) =>
          item.uuid.toString().toUpperCase() ==
          teacherCharacteristicId.toUpperCase(),
      orElse: () => throw StateError('Teacher characteristic not found'),
    );

    final studentName = await getStudentDeviceName();
    final payload = utf8.encode(studentName);
    await characteristic.write(payload, withoutResponse: true);
    await characteristic.setNotifyValue(true);
    return characteristic;
  }

  static Future<BluetoothCharacteristic?> connectToTeacher() async {
    final teacherDevice = await findTeacher();
    if (teacherDevice == null) {
      return null;
    }

    return connectToDevice(teacherDevice);
  }

  static Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
    await FlutterBluePlus.stopScan();
  }
}
