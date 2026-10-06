import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrder());
  }

  void _loadOrder() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<OrderProvider>().fetchOrderById(token, widget.orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.orderId}')),
      body: _buildBody(orderProvider),
    );
  }

  Widget _buildBody(OrderProvider orderProvider) {
    if (orderProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                orderProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadOrder,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final order = orderProvider.selectedOrder;
    if (order == null) {
      return const Center(child: Text('Order not found'));
    }

    return ListView(
      children: [
        _OrderSummary(order: order),
        const Divider(height: 1),
        for (final item in order.items)
          ListTile(
            title: Text(item.productName),
            subtitle: Text([
              if (item.size.isNotEmpty) 'Size: ${item.size}',
              '฿${item.unitPrice} × ${item.quantity}',
            ].join(' • ')),
            trailing: Text(
              '฿${item.subtotal}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        const Divider(height: 1),
        ListTile(
          title: const Text(
            'Total',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            '฿${order.totalPrice}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final Order order;

  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final createdAt = order.createdAt;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${order.status}'),
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Placed: ${createdAt.toLocal().toString().split('.').first}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${order.totalItems} item(s)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}