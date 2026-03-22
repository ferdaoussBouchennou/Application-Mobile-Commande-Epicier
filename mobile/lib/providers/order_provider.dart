import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/client_order.dart';
import '../data/services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<ClientOrder> _orders = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  String? _lastToken;

  List<ClientOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders(String? token, {bool silent = false}) async {
    if (token == null || token.isEmpty) {
      _orders = [];
      notifyListeners();
      return;
    }
    _lastToken = token;
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await _api.get('/commandes', token: token);
      List<ClientOrder> newOrders = [];
      if (response is List) {
        for (final e in response) {
          if (e is Map) {
            try {
              newOrders.add(ClientOrder.fromJson(Map<String, dynamic>.from(e as Map)));
            } catch (_) {}
          }
        }
      }

      // Check if something changed to avoid unnecessary UI rebuilds
      bool changed = _orders.length != newOrders.length;
      if (!changed) {
        for (int i = 0; i < _orders.length; i++) {
          if (_orders[i].statut != newOrders[i].statut) {
            changed = true;
            break;
          }
        }
      }

      if (changed) {
        _orders = newOrders;
        notifyListeners();
      }
    } catch (e) {
      if (!silent) {
        _error = e.toString().replaceFirst('Exception: ', '');
        notifyListeners();
      }
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void startPolling(String? token) {
    _pollingTimer?.cancel();
    _lastToken = token;
    fetchOrders(token); // Initial fetch
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_lastToken != null) {
        fetchOrders(_lastToken, silent: true);
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
