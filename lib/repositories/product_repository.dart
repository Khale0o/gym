import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/gym_product.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class ProductRepository {
  ProductRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<GymProduct>> streamProducts(String gymId) {
    return _paths.productsCollection(gymId).snapshots().map((snap) {
      final rows = snap.docs.map(GymProduct.fromFirestore).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return rows;
    });
  }

  Stream<List<GymProduct>> streamActiveProducts(String gymId) {
    return streamProducts(gymId).map(
      (rows) => rows.where((p) => p.status == GymProductStatus.active).toList(),
    );
  }

  Future<void> createProduct({
    required String gymId,
    required String name,
    required String category,
    required String? description,
    required double sellingPrice,
    required double costPrice,
    required String currency,
    required int? stockQuantity,
    required String status,
    required String? createdBy,
  }) {
    _validate(
      gymId: gymId,
      name: name,
      category: category,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      currency: currency,
      stockQuantity: stockQuantity,
      status: status,
    );
    final now = FieldValue.serverTimestamp();
    return _paths.productsCollection(gymId).add({
      'gymId': gymId,
      'name': name.trim(),
      'category': category,
      'description': _optional(description),
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'currency': currency.trim().toUpperCase(),
      if (stockQuantity != null) 'stockQuantity': stockQuantity,
      'status': status,
      'createdBy': createdBy,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateProduct({
    required String gymId,
    required String productId,
    required Map<String, dynamic> data,
  }) {
    if (gymId.trim().isEmpty || productId.trim().isEmpty) {
      throw StateError('Product and gym are required.');
    }
    return _paths.productDoc(gymId, productId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deactivateProduct({
    required String gymId,
    required String productId,
  }) {
    return updateProduct(
      gymId: gymId,
      productId: productId,
      data: {'status': GymProductStatus.inactive},
    );
  }

  void _validate({
    required String gymId,
    required String name,
    required String category,
    required double sellingPrice,
    required double costPrice,
    required String currency,
    required int? stockQuantity,
    required String status,
  }) {
    if (gymId.trim().isEmpty) throw StateError('Gym is required.');
    if (name.trim().isEmpty) throw StateError('Product name is required.');
    if (!GymProductCategory.all.contains(category)) {
      throw StateError('Product category is required.');
    }
    if (!sellingPrice.isFinite || sellingPrice <= 0) {
      throw StateError('Selling price must be greater than zero.');
    }
    if (!costPrice.isFinite || costPrice < 0) {
      throw StateError('Cost price must be zero or greater.');
    }
    if (currency.trim().isEmpty) throw StateError('Currency is required.');
    if (stockQuantity != null && stockQuantity < 0) {
      throw StateError('Stock quantity cannot be negative.');
    }
    if (![
      GymProductStatus.active,
      GymProductStatus.inactive,
    ].contains(status)) {
      throw StateError('Unsupported product status.');
    }
  }
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
