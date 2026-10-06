import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'order_detail_screen.dart';

// feature.md A2 (ปิด G2) — ประวัติการสั่งซื้อ (GET /api/orders)
//
// โครงเดียวกับ HomeScreen ทุกประการ: Loading / Error / Empty / Data ครบสี่สถานะ
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  void _loadOrders() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<OrderProvider>().fetchOrders(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: () async {
          final token = context.read<AuthProvider>().token;
          if (token != null) {
            await context.read<OrderProvider>().fetchOrders(token);
          }
        },
        child: _buildBody(orderProvider),
      ),
    );
  }

  Widget _buildBody(OrderProvider orderProvider) {
    if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderProvider.errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Text(
                  orderProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loadOrders,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (orderProvider.orders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('You have no orders yet')),
        ],
      );
    }

    return ListView.separated(
      itemCount: orderProvider.orders.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _OrderTile(
        order: orderProvider.orders[index],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final createdAt = order.createdAt;

    return ListTile(
      leading: const Icon(Icons.receipt_long),
      title: Text('Order #${order.id}'),
      subtitle: Text(
        createdAt == null
            ? order.status
            : '${order.status} · ${createdAt.toLocal().toString().split('.').first}',
      ),
      trailing: Text(
        '฿${order.totalPrice}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      // GET /api/orders คืนแบบสรุปไม่มี items — รายละเอียดต้องไปโหลดอีกหน้า
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderId: order.id),
        ),
      ),
    );
  }
}