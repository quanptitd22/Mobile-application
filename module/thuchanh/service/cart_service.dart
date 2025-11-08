import '../models/product.dart';

class CartService {
  final List<Product> _cartItems = [];

  List<Product> getCartItems() => _cartItems;

  void addToCart(Product product) {
    _cartItems.add(product);
  }

  void removeFromCart(Product product) {
    _cartItems.remove(product);
  }

  double getTotalPrice() {
    return _cartItems.fold(0, (sum, item) => sum + item.price);
  }
}
