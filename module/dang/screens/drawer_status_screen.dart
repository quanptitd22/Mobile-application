import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DrawerStatusScreen extends StatefulWidget {
  const DrawerStatusScreen({super.key});

  @override
  State<DrawerStatusScreen> createState() => _DrawerStatusScreenState();
}

class _DrawerStatusScreenState extends State<DrawerStatusScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Map<int, Map<String, dynamic>> drawerStatus = {};

  @override
  void initState() {
    super.initState();
    _listenToDrawerData();
  }

  void _listenToDrawerData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("⚠️ Chưa có user đăng nhập");
      return;
    }

    final userUid = user.uid;
    _dbRef.child('users/$userUid/reminders').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        setState(() => drawerStatus.clear());
        return;
      }

      final Map<int, Map<String, dynamic>> updated = {};
      data.forEach((key, value) {
        final reminder = Map<String, dynamic>.from(value);
        int drawer = reminder['drawer'];
        updated[drawer] = reminder;
      });

      setState(() {
        drawerStatus = updated;
      });
    });
  }

  Future<void> _openDrawer(int drawerNumber) async {
    try {
      await _dbRef.child('control/drawer$drawerNumber').set('open');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Đã gửi lệnh mở ngăn $drawerNumber')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi khi gửi lệnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Trạng thái hộp thuốc',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4f7cff), Color(0xFFa55eea)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: drawerStatus.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // ✅ 3 ngăn thuốc
        itemBuilder: (context, index) {
          int drawerNum = index + 1;
          var data = drawerStatus[drawerNum];
          bool hasPill = data != null;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: hasPill ? Colors.white : Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: hasPill
                      ? Colors.blueAccent.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: hasPill
                        ? const Color(0xFF4f7cff).withOpacity(0.15)
                        : Colors.grey[300],
                    child: Icon(
                      hasPill
                          ? Icons.medication_rounded
                          : Icons.inventory_2_outlined,
                      size: 28,
                      color: hasPill
                          ? const Color(0xFF4f7cff)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ngăn $drawerNum",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (hasPill) ...[
                          Text("Tên thuốc: ${data!['title']}",
                              style: const TextStyle(fontSize: 15)),
                          Text("Liều lượng: ${data['dosage']} viên",
                              style: const TextStyle(fontSize: 15)),
                          Text("Tần suất: ${data['frequency']}",
                              style: const TextStyle(fontSize: 15)),
                          Text("Thời gian: ${data['time']}",
                              style: const TextStyle(fontSize: 14)),
                        ] else
                          const Text("Trống",
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  hasPill
                      ? ElevatedButton(
                    onPressed: () => _openDrawer(drawerNum),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4f7cff),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Mở ngăn',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                      : const Text(
                    'Trống',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
