import 'package:firebase_database/firebase_database.dart';

class FirebaseIotService {
  final DatabaseReference _ref =
  FirebaseDatabase.instance.ref().child('medicineBox');

  // Stream theo dõi trạng thái 3 ngăn thuốc
  Stream<Map<String, dynamic>> getMedicineBoxStatus() {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return {};
      return data.map((key, value) => MapEntry(key, value.toString()));
    });
  }

  // Gửi lệnh điều khiển mở/đóng ngăn thuốc
  Future<void> setCompartmentState(String compartment, String state) async {
    await _ref.child(compartment).set(state);
  }
}
