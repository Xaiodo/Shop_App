import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/http_exception.dart';
import 'product.dart';

class Products with ChangeNotifier {
  List<Product>? _items = [];

  final _showFavoriteOnly = false;

  final String? authToken;
  final String? userId;

  Products(this._items, {this.authToken, this.userId});

  List<Product> get items {
    if (_showFavoriteOnly) {
      return _items!.where((element) => element.isFavorite).toList();
    }
    return [..._items!];
  }

  Product findById(String id) {
    return _items!.firstWhere((product) => product.id == id);
  }

  List<Product> get favoriteItems {
    return _items!.where((element) => element.isFavorite).toList();
  }

  Future<void> addProduct(Product product) async {
    final url = Uri.parse(
        'https://shopapp-dart-default-rtdb.firebaseio.com/products.json?auth=$authToken');
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'userId': userId,
        }),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items!.add(newProduct);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="userId"&equalTo="$userId"' : '';
    final url = Uri.parse(
        'https://shopapp-dart-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filterString');
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final favoriteResponse = await http.get(
        Uri.parse(
          'https://shopapp-dart-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken',
        ),
      );

      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
          imageUrl: prodData['imageUrl'],
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items!.indexWhere((element) => element.id == id);
    if (prodIndex >= 0) {
      final url = Uri.parse(
          'https://shopapp-dart-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken');
      http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'price': newProduct.price,
            'imageUrl': newProduct.imageUrl,
          }));
      _items![prodIndex] = newProduct;
      notifyListeners();
    } else {}
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.parse(
        'https://shopapp-dart-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken');
    final existingProductIndex =
        _items!.indexWhere((element) => element.id == id);
    Product? existingProduct = _items![existingProductIndex];
    _items!.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items!.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete a product');
    }
    existingProduct = null;
  }
}
