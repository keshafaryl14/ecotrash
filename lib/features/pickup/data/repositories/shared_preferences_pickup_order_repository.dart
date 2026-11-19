import 'dart:convert';

import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/domain/repositories/pickup_order_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesPickupOrderRepository implements PickupOrderRepository {
  static const _ordersKey = 'pickup_orders';

  @override
  Future<List<PickupOrder>> loadOrders() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_ordersKey);
      if (encoded == null || encoded.isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        throw const FormatException('Daftar pesanan tidak valid.');
      }
      return decoded.map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Data pesanan tidak valid.');
        }
        return PickupOrder.fromJson(entry);
      }).toList();
    } on PickupOrderException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        const PickupOrderException('Daftar pesanan tidak dapat dimuat.'),
        stackTrace,
      );
    }
  }

  @override
  Future<void> saveOrder(PickupOrder order) async {
    final orders = List<PickupOrder>.of(await loadOrders());
    if (orders.any((existing) => existing.id == order.id)) {
      throw const PickupOrderException('Nomor pesanan sudah digunakan.');
    }
    orders.insert(0, order);
    await _persist(orders, 'Pesanan baru tidak dapat disimpan.');
  }

  @override
  Future<void> updateOrder(PickupOrder order) async {
    final orders = List<PickupOrder>.of(await loadOrders());
    final index = orders.indexWhere((existing) => existing.id == order.id);
    if (index < 0) {
      throw const PickupOrderException('Pesanan tidak ditemukan.');
    }
    orders[index] = order;
    await _persist(orders, 'Perubahan pesanan tidak dapat disimpan.');
  }

  Future<void> _persist(List<PickupOrder> orders, String message) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _ordersKey,
        jsonEncode(orders.map((order) => order.toJson()).toList()),
      );
      if (!saved) {
        throw PickupOrderException(message);
      }
    } on PickupOrderException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(PickupOrderException(message), stackTrace);
    }
  }
}
