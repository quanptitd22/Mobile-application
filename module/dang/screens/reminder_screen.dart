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
  String _selectedUnit = 'viên';

  // 🆕 Tần suất
  String _selectedFrequency = 'Hằng ngày';
  final List<String> _frequencies = ['Hằng ngày', 'Cách ngày', 'Một lần', 'Theo số ngày'];
  int _intervalDays = 2;   // cho "cách ngày"
  int _durationDays = 7;   // cho "theo số ngày"

  final List<String> _units = ['viên', 'ml', 'lọ', 'gói', 'liều'];

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      _titleController.text = widget.existingReminder!.title;
      _descriptionController.text = widget.existingReminder!.description ?? '';

      // Giờ chỉ còn 1 time, cho vào list để tái sử dụng logic cũ
      _times = [widget.existingReminder!.time];

      // Liều lượng (dosage) là số nguyên, không còn đơn vị riêng
      _selectedQuantity = widget.existingReminder!.dosage;
      _selectedUnit = "viên"; // Hoặc mặc định "ml", tuỳ bạn muốn

      // Tần suất
      _selectedFrequency = widget.existingReminder!.frequency ?? 'Hằng ngày';
      _intervalDays = widget.existingReminder!.intervalDays ?? 2;

      // Tính số ngày từ endDate (nếu có), mặc định 7 ngày
      _durationDays = widget.existingReminder!.endDate != null
          ? widget.existingReminder!.endDate!
          .difference(DateTime.now())
          .inDays
          : 7;
    } else {
      _times = [DateTime.now().add(const Duration(hours: 1))];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_times[index]),
    );

    if (time != null) {
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
    setState(() {
      _times.removeAt(index);
    });
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

    // 🔹 Chuyển danh sách _times thành danh sách chuỗi "HH:mm"
    final timesPerDay = _times
        .map((t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();

    // 🔹 Tính intervalDays & endDate theo loại tần suất
    int interval = 1;
    DateTime? endDate;

    switch (_selectedFrequency) {
      case 'Hằng ngày':
        interval = 1;
        endDate = DateTime.now().add(Duration(days: _durationDays));
        break;
      case 'Cách ngày':
        interval = _intervalDays;
        endDate = DateTime.now().add(Duration(days: _durationDays));
        break;
      case 'Theo số ngày':
        interval = 1;
        endDate = DateTime.now().add(Duration(days: _durationDays));
        break;
      case 'Một lần':
        interval = 9999; // coi như chỉ một lần duy nhất
        endDate = DateTime.now();
        break;
    }

    final reminder = Reminder(
      id: widget.existingReminder?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dosage: _selectedQuantity,
      time: _times.first,
      frequency: _selectedFrequency,
      intervalDays: interval,
      endDate: endDate,
      timesPerDay: timesPerDay,
    );

    Navigator.pop(context, reminder);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.existingReminder != null
              ? 'Chỉnh sửa lịch trình'
              : 'Thêm lịch trình mới',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saveReminder,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Info Card
            _buildCard(
              title: 'Thông tin thuốc',
              icon: Icons.medication,
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Tên thuốc',
                  hint: 'VD: Paracetamol, Ibuprofen...',
                  icon: Icons.medical_services,
                ),
                const SizedBox(height: 16),
                _buildQuantitySelector(),
              ],
            ),

            const SizedBox(height: 20),

            // 🆕 Frequency Card
            _buildCard(
              title: 'Tần suất uống',
              icon: Icons.repeat,
              children: [
                DropdownButton<String>(
                  value: _selectedFrequency,
                  isExpanded: true,
                  items: _frequencies
                      .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFrequency = value);
                    }
                  },
                ),
                if (_selectedFrequency == 'Cách ngày') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Mỗi'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed > 0) {
                              _intervalDays = parsed;
                            }
                          },
                          controller: TextEditingController(text: _intervalDays.toString()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('ngày'),
                    ],
                  ),
                ],
                if (_selectedFrequency == 'Theo số ngày') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Trong'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed > 0) {
                              _durationDays = parsed;
                            }
                          },
                          controller: TextEditingController(text: _durationDays.toString()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('ngày'),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Schedule Card
            _buildCard(
              title: 'Thời gian uống thuốc',
              icon: Icons.schedule,
              children: [
                Column(
                  children: List.generate(_times.length, (index) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeButton(
                            label: 'Giờ uống ${index + 1}',
                            value:
                            '${_times[index].hour.toString().padLeft(2, '0')}:${_times[index].minute.toString().padLeft(2, '0')}',
                            icon: Icons.access_time,
                            onTap: () => _selectTime(index),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeTime(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        )
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm mốc giờ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            // Additional Notes Card
            _buildCard(
              title: 'Ghi chú thêm',
              icon: Icons.note_add,
              children: [
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Ghi chú',
                  hint: 'Uống sau khi ăn, không uống với sữa...',
                  icon: Icons.edit_note,
                  maxLines: 3,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  widget.existingReminder != null
                      ? 'Cập nhật lịch trình'
                      : 'Tạo lịch trình',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Các widget phụ (card, textfield, quantity...)
  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Liều lượng',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _selectedQuantity > 1
                          ? () => setState(() => _selectedQuantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: _selectedQuantity > 1
                          ? const Color(0xFF2196F3)
                          : Colors.grey,
                    ),
                    Expanded(
                      child: Text(
                        '$_selectedQuantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _selectedQuantity < 10
                          ? () => setState(() => _selectedQuantity++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: _selectedQuantity < 10
                          ? const Color(0xFF2196F3)
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String>(
                  value: _selectedUnit,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _units
                      .map((unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedUnit = value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeButton({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
