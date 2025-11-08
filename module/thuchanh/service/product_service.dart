import '../data/fake_products.dart';
import '../models/product.dart';

class ProductService {
  List<Product> getAllProducts() {
    return fakeProducts;
  }
}
