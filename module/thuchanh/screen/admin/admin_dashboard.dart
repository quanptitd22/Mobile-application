import 'package:flutter/material.dart';
import '../../data/fake_products.dart';
import '../../models/product.dart';
import 'admin_product_form.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Product> products = List.from(fakeProducts);

  void _addOrEditProduct({Product? editing}) async {
    final Product? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductForm(editing: editing),
      ),
    );

    if (result != null) {
      setState(() {
        if (editing == null) {
          products.add(result);
        } else {
          int index = products.indexOf(editing);
          products[index] = result;
        }
      });
    }
  }

  void _deleteProduct(Product p) {
    setState(() {
      products.remove(p);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addOrEditProduct(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Image.network(p.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              title: Text(p.name),
              subtitle: Text('${p.price.toStringAsFixed(0)} VNĐ'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _addOrEditProduct(editing: p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteProduct(p),
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
