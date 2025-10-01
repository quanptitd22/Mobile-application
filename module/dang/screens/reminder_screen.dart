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
  final _dosageController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  String _selectedMedicineType = 'Viên nang';
  String _selectedFrequency = 'Hàng ngày';
  int _selectedQuantity = 1;

  final List<String> _medicineTypes = [
    'Viên nang',
    'Viên thuốc',
    'Thuốc nước',
    'Thuốc xịt',
    'Thuốc mỡ',
    'Thuốc tiêm'
  ];

  final List<String> _frequencies = [
    'Hàng ngày',
    'Mỗi 2 ngày',
    'Mỗi tuần',
    'Khi cần thiết'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      _titleController.text = widget.existingReminder!.title;
      _descriptionController.text = widget.existingReminder!.description ?? '';
      _selectedDateTime = widget.existingReminder!.time;
    } else {
      // Set default time to next hour
      _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _saveReminder() {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng nhập tên thuốc');
      return;
    }

    final reminder = Reminder(
      id: widget.existingReminder?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      time: _selectedDateTime,
      description: _buildDescription(),
    );

    Navigator.pop(context, reminder);
  }

  String _buildDescription() {
    List<String> parts = [];
    parts.add('Loại: $_selectedMedicineType');
    parts.add('Tần suất: $_selectedFrequency');
    parts.add('Số lượng: $_selectedQuantity');

    if (_dosageController.text.trim().isNotEmpty) {
      parts.add('Liều lượng: ${_dosageController.text.trim()}');
    }

    if (_descriptionController.text.trim().isNotEmpty) {
      parts.add('Ghi chú: ${_descriptionController.text.trim()}');
    }

    return parts.join('\n');
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
          widget.existingReminder != null ? 'Chỉnh sửa lịch trình' : 'Thêm lịch trình mới',
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
                _buildDropdown(
                  label: 'Loại thuốc',
                  value: _selectedMedicineType,
                  items: _medicineTypes,
                  icon: Icons.category,
                  onChanged: (value) => setState(() => _selectedMedicineType = value!),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _dosageController,
                  label: 'Liều lượng',
                  hint: 'VD: 500mg, 1 thìa...',
                  icon: Icons.straighten,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Schedule Card
            _buildCard(
              title: 'Lịch trình',
              icon: Icons.schedule,
              children: [
                _buildDropdown(
                  label: 'Tần suất',
                  value: _selectedFrequency,
                  items: _frequencies,
                  icon: Icons.repeat,
                  onChanged: (value) => setState(() => _selectedFrequency = value!),
                ),
                const SizedBox(height: 16),
                _buildQuantitySelector(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeButton(
                        label: 'Ngày',
                        value: '${_selectedDateTime.day.toString().padLeft(2, '0')}/${_selectedDateTime.month.toString().padLeft(2, '0')}/${_selectedDateTime.year}',
                        icon: Icons.calendar_today,
                        onTap: _selectDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateTimeButton(
                        label: 'Giờ',
                        value: '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                        icon: Icons.access_time,
                        onTap: _selectTime,
                      ),
                    ),
                  ],
                ),
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

            // Save Button (Alternative)
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
                  widget.existingReminder != null ? 'Cập nhật lịch trình' : 'Tạo lịch trình',
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
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
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
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
          'Số lượng',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(Icons.format_list_numbered, color: Colors.grey[400]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_selectedQuantity viên/lần',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: _selectedQuantity > 1
                    ? () => setState(() => _selectedQuantity--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: _selectedQuantity > 1 ? const Color(0xFF2196F3) : Colors.grey,
              ),
              Text(
                _selectedQuantity.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
              IconButton(
                onPressed: _selectedQuantity < 10
                    ? () => setState(() => _selectedQuantity++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: _selectedQuantity < 10 ? const Color(0xFF2196F3) : Colors.grey,
              ),
            ],
          ),
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