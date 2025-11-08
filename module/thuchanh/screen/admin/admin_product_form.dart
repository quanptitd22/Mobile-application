import 'package:flutter/material.dart';
import '../../models/product.dart';

class AdminProductForm extends StatefulWidget {
  final Product? editing;

  const AdminProductForm({super.key, this.editing});

  @override
  State<AdminProductForm> createState() => _AdminProductFormState();
}

class _AdminProductFormState extends State<AdminProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameController.text = widget.editing!.name;
      _priceController.text = widget.editing!.price.toString();
      _imageController.text = widget.editing!.imageUrl;
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: widget.editing?.id ?? DateTime.now().millisecondsSinceEpoch,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        imageUrl: _imageController.text.trim(),
      );
      Navigator.pop(context, newProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'URL ảnh'),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm mới'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
