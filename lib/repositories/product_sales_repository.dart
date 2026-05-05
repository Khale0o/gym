import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/gym_product.dart';
import 'package:gymsaas/models/product_sale.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class ProductSalesRepository {
  ProductSalesRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<List<ProductSale>> streamSalesForMonth(
    String gymId,
    DateTime monthDate,
  ) {
    return _paths.productSalesCollection(gymId).snapshots().map((snap) {
      final start = DateTime(monthDate.year, monthDate.month);
      final end = DateTime(monthDate.year, monthDate.month + 1);
      final rows = snap.docs
          .map(ProductSale.fromFirestore)
          .where((item) =>
              !item.saleDate.isBefore(start) && item.saleDate.isBefore(end))
          .toList()
        ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
      return rows;
    });
  }

  Future<void> createProductSale({
    required String gymId,
    required GymProduct product,
    required String? memberId,
    required String? memberName,
    required int quantity,
    required String paymentMethod,
    required String status,
    required DateTime saleDate,
    required String? notes,
    required String? createdBy,
  }) async {
    if (gymId.trim().isEmpty) throw StateError('Gym is required.');
    if (product.id.trim().isEmpty) throw StateError('Product is required.');
    if (quantity <= 0) throw StateError('Quantity must be greater than zero.');
    if (product.sellingPrice <= 0) {
      throw StateError('Product selling price must be greater than zero.');
    }
    if (paymentMethod.trim().isEmpty) {
      throw StateError('Payment method is required.');
    }
    if (![ProductSaleStatus.paid, ProductSaleStatus.pending].contains(status)) {
      throw StateError('Unsupported sale status.');
    }

    final db = _paths.gymDoc(gymId).firestore;
    final productRef = _paths.productDoc(gymId, product.id);
    final saleRef = _paths.productSalesCollection(gymId).doc();
    await db.runTransaction((transaction) async {
      final productSnap = await transaction.get(productRef);
      if (!productSnap.exists) throw StateError('Product no longer exists.');
      final freshProduct = GymProduct.fromFirestore(productSnap);
      if (freshProduct.status != GymProductStatus.active) {
        throw StateError('Product is not active.');
      }
      final tracksStock = freshProduct.stockQuantity != null;
      if (status == ProductSaleStatus.paid && tracksStock) {
        final currentStock = freshProduct.stockQuantity ?? 0;
        if (currentStock < quantity) {
          throw StateError('Not enough stock available.');
        }
        transaction.update(productRef, {
          'stockQuantity': currentStock - quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final unitSelling = freshProduct.sellingPrice;
      final unitCost = freshProduct.costPrice;
      final totalRevenue = unitSelling * quantity;
      final totalCost = unitCost * quantity;
      transaction.set(saleRef, {
        'gymId': gymId,
        'productId': freshProduct.id,
        'productName': freshProduct.name,
        'productCategory': freshProduct.category,
        'memberId': _optional(memberId),
        'memberName': _optional(memberName),
        'quantity': quantity,
        'unitSellingPrice': unitSelling,
        'unitCostPrice': unitCost,
        'totalRevenue': totalRevenue,
        'totalCost': totalCost,
        'grossProfit': totalRevenue - totalCost,
        'currency': freshProduct.currency,
        'paymentMethod': paymentMethod,
        'status': status,
        'saleDate': Timestamp.fromDate(saleDate),
        'notes': _optional(notes),
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'cancelledAt': null,
        'cancelledBy': null,
        'cancellationReason': null,
        'stockWasTracked': tracksStock,
      });
    });
  }

  Future<void> cancelProductSale({
    required String gymId,
    required String saleId,
    required String cancelledBy,
    required String reason,
  }) async {
    if (gymId.trim().isEmpty || saleId.trim().isEmpty) {
      throw StateError('Sale and gym are required.');
    }
    if (reason.trim().isEmpty) {
      throw StateError('Cancellation reason is required.');
    }

    final db = _paths.gymDoc(gymId).firestore;
    final saleRef = _paths.productSaleDoc(gymId, saleId);
    await db.runTransaction((transaction) async {
      final saleSnap = await transaction.get(saleRef);
      if (!saleSnap.exists) throw StateError('Product sale not found.');
      final sale = ProductSale.fromFirestore(saleSnap);
      if (sale.status == ProductSaleStatus.cancelled) {
        throw StateError('Product sale is already cancelled.');
      }

      if (sale.status == ProductSaleStatus.paid && sale.stockWasTracked) {
        final productRef = _paths.productDoc(gymId, sale.productId);
        final productSnap = await transaction.get(productRef);
        if (!productSnap.exists) {
          throw StateError(
            'Cannot cancel this sale because the product stock record is missing.',
          );
        }
        final product = GymProduct.fromFirestore(productSnap);
        final currentStock = product.stockQuantity ?? 0;
        transaction.update(productRef, {
          'stockQuantity': currentStock + sale.quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(saleRef, {
        'status': ProductSaleStatus.cancelled,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': cancelledBy,
        'cancellationReason': reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
