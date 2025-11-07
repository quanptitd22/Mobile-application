import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/reminder_storage.dart';

class ReminderScreen extends StatefulWidget {
  final Reminder? existingReminder;

  const ReminderScreen({super.key, this.existingReminder});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<DateTime> _times = [];
  int _selectedQuantity = 1;
  int _selectedDrawer = 1;
  String _selectedUnit = 'viên';

  String _selectedFrequency = 'Hằng ngày';
  final List<String> _frequencies = [
    'Hằng ngày',
    'Cách ngày',
    'Một lần',
    'Theo số ngày',
  ];
  int _intervalDays = 2;
  DateTime _startDate = DateTime.now();
  int _durationDays = 30;
  int _customIntervalDays = 1;
  final _customDaysController = TextEditingController();

  final List<String> _units = ['viên', 'ml', 'lọ', 'gói', 'liều'];

  @override
  void initState() {
    super.initState();
    _customDaysController.text = _customIntervalDays.toString();
    if (widget.existingReminder != null) {
      _titleController.text = widget.existingReminder!.title;
      _descriptionController.text = widget.existingReminder!.description ?? '';
      _times = [widget.existingReminder!.time];
      _selectedQuantity = widget.existingReminder!.dosage;
      _selectedUnit = "viên";
      _selectedFrequency = widget.existingReminder!.frequency ?? 'Hằng ngày';
      _intervalDays = widget.existingReminder!.intervalDays ?? 2;
      _durationDays = widget.existingReminder!.endDate != null
          ? widget.existingReminder!.endDate!.difference(DateTime.now()).inDays
          : 7;
      _startDate = widget.existingReminder!.time;
      _selectedDrawer = widget.existingReminder!.drawer ?? 1;
    } else {
      _times = [DateTime.now().add(const Duration(hours: 1))];
      _startDate = DateTime.now();
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.purple.shade600),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      final now = DateTime.now();

      // Kiểm tra ngày được chọn không nằm trong quá khứ
      if (picked.isBefore(DateTime(now.year, now.month, now.day))) {
        _showErrorSnackBar('Không thể chọn ngày trong quá khứ');
        return;
      }

      setState(() {
        _startDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _startDate.hour,
          _startDate.minute,
        );

        // Update time list to use new date and validate times
        _times = _times.map((t) {
          final newDateTime = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            t.hour,
            t.minute,
          );

          // Nếu thời gian mới nằm trong quá khứ, tự động điều chỉnh sang giờ tiếp theo
          if (newDateTime.isBefore(now)) {
            return DateTime(
              _startDate.year,
              _startDate.month,
              _startDate.day,
              now.hour + 1,
              0,
            );
          }
          return newDateTime;
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  // Đặt hàm này bên trong class _ReminderScreenState
  Future<void> _showCustomDaysDialog() async {
    _customDaysController.text = _customIntervalDays.toString();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Người dùng phải nhấn nút để đóng
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nhập số ngày'),
          content: TextField(
            controller: _customDaysController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly, // Chỉ cho phép nhập số
            ],
            decoration: const InputDecoration(hintText: "Nhập số ngày ở đây"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  _customIntervalDays =
                      int.tryParse(_customDaysController.text) ?? 1;
                  // Cập nhật lại lựa chọn tần suất
                  _selectedFrequency = 'Theo số ngày';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_times[index]),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue.shade600),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        time.hour,
        time.minute,
      );

      if (selectedDateTime.isBefore(now)) {
        _showErrorSnackBar('Thời gian uống thuốc không hợp lệ');
        return;
      }

      setState(() {
        _times[index] = DateTime(
          _times[index].year,
          _times[index].month,
          _times[index].day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _addTime() {
    setState(() {
      _times.add(DateTime.now().add(const Duration(hours: 1)));
    });
  }

  void _removeTime(int index) {
    if (_times.length > 1) {
      setState(() {
        _times.removeAt(index);
      });
    }
  }

  void _saveReminder() {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng nhập tên thuốc');
      return;
    }

    if (_times.isEmpty) {
      _showErrorSnackBar('Vui lòng chọn ít nhất 1 mốc giờ');
      return;
    }

    // Kiểm tra ngày bắt đầu không nằm trong quá khứ
    final now = DateTime.now();
    if (_startDate.isBefore(DateTime(now.year, now.month, now.day))) {
      _showErrorSnackBar('Ngày bắt đầu không thể nằm trong quá khứ');
      return;
    }

    // Kiểm tra tất cả các mốc thời gian
    List<String> invalidTimes = [];
    for (var time in _times) {
      // Tạo DateTime đầy đủ với ngày và giờ để so sánh
      var fullDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        time.hour,
        time.minute,
      );

      if (fullDateTime.isBefore(now)) {
        invalidTimes.add(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        );
      }
    }

    if (invalidTimes.isNotEmpty) {
      if (invalidTimes.length == 1) {
        _showErrorSnackBar(
          'Giờ ${invalidTimes[0]} không hợp lệ vì nằm trong quá khứ. Vui lòng chọn lại thời gian.',
        );
      } else {
        _showErrorSnackBar(
          'Các giờ ${invalidTimes.join(", ")} không hợp lệ vì nằm trong quá khứ. Vui lòng chọn lại thời gian.',
        );
      }
      return;
    }

    final timesPerDay = _times
        .map(
          (t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        )
        .toList();

    int interval = 1;
    DateTime? endDate;

    switch (_selectedFrequency) {
      case 'Hằng ngày':
        interval = 1;
        endDate = _startDate.add(Duration(days: _durationDays));
        break;
      case 'Cách ngày':
        interval = 2;
        endDate = _startDate.add(Duration(days: _durationDays));
        break;
      case 'Một lần':
        interval = 1;
        // For one-time reminders, endDate == startDate so generateSchedule yields only that day
        endDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
        break;
      case 'Theo số ngày':
        interval = _customIntervalDays;
        endDate = _startDate.add(Duration(days: _durationDays));
        break;
    }

    // Update times to use selected start date
    final updatedTimes = timesPerDay.map((timeStr) {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          hour,
          minute,
        );
      }
      return _startDate;
    }).toList();

    final reminder = Reminder(
      id:
          widget.existingReminder?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dosage: _selectedQuantity,
      time: updatedTimes.first, // Use updated time with selected date
      frequency: _selectedFrequency,
      intervalDays: interval,
      endDate: endDate,
      timesPerDay: timesPerDay,
      drawer: _selectedDrawer,
    );

    Navigator.pop(context, reminder);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildMedicineInfoCard(),
                      const SizedBox(height: 20),
                      _buildDateCard(),
                      const SizedBox(height: 20),
                      _buildFrequencyCard(),
                      const SizedBox(height: 20),
                      _buildDrawerCard(),
                      const SizedBox(height: 20),
                      _buildTimeCard(),
                      const SizedBox(height: 20),
                      _buildNotesCard(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.purple.shade600],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          Text(
            widget.existingReminder != null
                ? 'Chỉnh sửa lịch trình'
                : 'Thêm lịch trình mới',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: _saveReminder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade600,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Lưu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.medication,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thông tin thuốc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStyledTextField(
            controller: _titleController,
            label: 'Tên thuốc',
            hint: 'VD: Paracetamol, Ibuprofen...',
            icon: Icons.edit,
          ),
          const SizedBox(height: 20),
          _buildDosageSelector(),
        ],
      ),
    );
  }

  Widget _buildDrawerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade500, Colors.teal.shade600],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Chọn ngăn thuốc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final drawerNumber = index + 1;
              final isSelected = _selectedDrawer == drawerNumber;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                  ), // Thêm khoảng cách nhỏ
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDrawer = drawerNumber;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  Colors.teal.shade500,
                                  Colors.teal.shade600,
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.shade200),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Ngăn $drawerNumber',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade500, Colors.indigo.shade600],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ngày uống thuốc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _selectStartDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.white],
                ),
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: Colors.indigo.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade500, Colors.purple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tần suất uống',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Column(
            children: _frequencies.map((freq) {
              final isSelected = _selectedFrequency == freq;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    // ---- BẮT ĐẦU THAY ĐỔI LOGIC Ở ĐÂY ----
                    if (freq == 'Theo số ngày') {
                      _showCustomDaysDialog();
                    } else {
                      setState(() => _selectedFrequency = freq);
                    }
                    // ---- KẾT THÚC THAY ĐỔI ----
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                Colors.purple.shade500,
                                Colors.purple.shade600,
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        freq == 'Theo số ngày'
                            ? 'Trong $_customIntervalDays ngày'
                            : freq,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade500, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thời gian uống thuốc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: List.generate(_times.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(index),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey.shade50, Colors.white],
                            ),
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_times[index].hour.toString().padLeft(2, '0')}:${_times[index].minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                'Giờ uống ${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_times.length > 1) ...[
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconButton(
                          onPressed: () => _removeTime(index),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _addTime,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Thêm mốc giờ',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildNotesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade500, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ghi chú thêm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Uống sau khi ăn, không uống với sữa...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.orange.shade500, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _saveReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Lưu lịch trình',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDosageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Liều lượng',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                onPressed: _selectedQuantity > 1
                    ? () => setState(() => _selectedQuantity--)
                    : null,
                icon: const Icon(Icons.remove, size: 24),
                color: _selectedQuantity > 1
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final newValue = await showDialog<int>(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController(
                            text: '$_selectedQuantity',
                          );
                          return AlertDialog(
                            title: const Text('Nhập số lượng'),
                            content: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Nhập số lượng...',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () {
                                  final value = int.tryParse(controller.text);
                                  if (value != null && value > 0) {
                                    Navigator.pop(context, value);
                                  }
                                },
                                child: const Text('Xác nhận'),
                              ),
                            ],
                          );
                        },
                      );
                      if (newValue != null) {
                        setState(() {
                          _selectedQuantity = newValue;
                        });
                      }
                    },
                    child: Text(
                      '$_selectedQuantity',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    _selectedUnit,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                onPressed: () => setState(() => _selectedQuantity++),
                icon: const Icon(Icons.add, size: 24, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
