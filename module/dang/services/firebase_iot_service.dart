import 'package:firebase_database/firebase_database.dart';

class FirebaseIoTService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('devices');

  /// Gửi lệnh đến thiết bị (ví dụ bật đèn hoặc mở ngăn thuốc)
  Future<void> sendCommand(String deviceId, Map<String, dynamic> command) async {
    try {
      await _db.child(deviceId).child('command').set(command);
      print("📡 Gửi lệnh đến IoT: $command");
    } catch (e) {
      print("❌ Lỗi khi gửi lệnh IoT: $e");
    }
  }

  /// Cập nhật trạng thái (ví dụ user đã uống thuốc)
  Future<void> updateStatus(String deviceId, String status) async {
    await _db.child(deviceId).child('status').set(status);
  }

  /// Lắng nghe dữ liệu cảm biến từ thiết bị
  Stream<Map<String, dynamic>> listenSensorData(String deviceId) {
    return _db.child(deviceId).child('sensor_data').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      return data != null ? Map<String, dynamic>.from(data) : {};
    });
  }
}
