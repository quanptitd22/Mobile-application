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
  Map<int, String> drawerControl = {
    1: "close",
    2: "close",
    3: "close",
  };

  @override
  void initState() {
    super.initState();
    _listenToDrawerData();
    _listenToControlStatus();
  }

  // 🟦 Lấy thông tin thuốc trong từng ngăn
  void _listenToDrawerData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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

  // 🟩 Lấy trạng thái open/close của từng ngăn
  void _listenToControlStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userUid = user.uid;

    _dbRef.child('users/$userUid/control').onValue.listen((event) {
      if (event.snapshot.value == null) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        drawerControl[1] = data["drawer1"] ?? "close";
        drawerControl[2] = data["drawer2"] ?? "close";
        drawerControl[3] = data["drawer3"] ?? "close";
      });
    });
  }

  // 🟧 Toggle mở/đóng
  Future<void> _toggleDrawer(int drawerNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userUid = user.uid;

    String currentState = drawerControl[drawerNumber] ?? "close";
    String newState = currentState == "close" ? "open" : "close";

    try {
      await _dbRef.child('users/$userUid/control/drawer$drawerNumber')
          .set(newState);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chuyển ngăn $drawerNumber → $newState')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi lệnh: $e')),
      );
    }
  }

  // 🟦 Format thời gian từ "2025-11-18T14:57:00.000"
  String _formatTime(String raw) {
    try {
      DateTime dt = DateTime.parse(raw);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return raw;
    }
  }

  // 🟦 CHUYỂN timesPerDay thành List chuẩn
  List<String> _extractTimes(dynamic rawTimes) {
    if (rawTimes == null) return [];

    if (rawTimes is List) {
      return rawTimes.map((e) => e.toString()).toList();
    }
    if (rawTimes is Map) {
      return rawTimes.values.map((e) => e.toString()).toList();
    }
    if (rawTimes is String) {
      return [rawTimes];
    }
    return [];
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
        itemCount: 3,
        itemBuilder: (context, index) {
          int drawerNum = index + 1;
          var data = drawerStatus[drawerNum];
          bool hasPill = data != null;

          // 🟦 SỬ DỤNG TIMESPERDAY
          List<String> times =
          _extractTimes(data != null ? data['timesPerDay'] : null);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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
                    backgroundColor: Colors.blue.withOpacity(0.12),
                    child: Icon(
                      hasPill
                          ? Icons.medication_rounded
                          : Icons.inventory_2_outlined,
                      size: 28,
                      color: const Color(0xFF4f7cff),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // ===== Thông tin thuốc =====
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
                          Text("Tên thuốc: ${data!['title']}"),
                          Text("Liều lượng: ${data['dosage']} viên"),
                          Text("Tần suất: ${data['frequency']}"),

                          const SizedBox(height: 4),
                          const Text(
                            "Thời gian uống:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // 🟦 HIỂN THỊ CHIP THỜI GIAN
                          times.isNotEmpty
                              ? Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: times.map((t) {
                              return Chip(
                                label: Text(
                                  t,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                avatar: const Icon(
                                  Icons.access_time,
                                  size: 18,
                                ),
                                backgroundColor:
                                const Color(0xFF4f7cff)
                                    .withOpacity(0.12),
                              );
                            }).toList(),
                          )
                              : const Text(
                            "Không có thời gian uống",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ] else
                          const Text(
                            "Trống",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 🔵 Nút Mở / Đóng ngăn
                  ElevatedButton(
                    onPressed: () => _toggleDrawer(drawerNum),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      drawerControl[drawerNum] == "open"
                          ? Colors.redAccent
                          : const Color(0xFF4f7cff),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      drawerControl[drawerNum] == "open"
                          ? "Đóng"
                          : "Mở",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
