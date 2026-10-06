import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() => runApp(const FolkWearApp());

const red = Color(0xFFB71C1C);
const paleRed = Color(0xFFFFEEEE);

const productIcons = <IconData>[
  Icons.checkroom, Icons.style, Icons.auto_awesome, Icons.shopping_bag,
  Icons.dry_cleaning, Icons.local_mall, Icons.woman, Icons.man,
];

class ShopProduct {
  final int id;
  String name;
  String category;
  double price;
  String description;
  int stock;
  int iconIndex;
  String imageBase64;
  List<String> sizes;

  ShopProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.stock = 10,
    this.iconIndex = 0,
    this.imageBase64 = '',
    List<String>? sizes,
  }) : sizes = List<String>.from(sizes ?? const ['S', 'M', 'L', 'XL']);

  IconData get icon => productIcons[iconIndex.clamp(0, productIcons.length - 1)];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'stock': stock,
        'iconIndex': iconIndex,
        'imageBase64': imageBase64,
        'sizes': sizes,
      };

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    final rawSizes = json['sizes'];
    final parsedSizes = rawSizes is List
        ? rawSizes.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : rawSizes is String
            ? rawSizes
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];

    return ShopProduct(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      description: (json['description'] ?? '') as String,
      stock: (json['stock'] ?? 10) as int,
      iconIndex: (json['iconIndex'] ?? 0) as int,
      imageBase64: (json['imageBase64'] ?? '') as String,
      sizes: parsedSizes.isEmpty ? const ['S', 'M', 'L', 'XL'] : parsedSizes,
    );
  }
}

List<ShopProduct> defaultProducts() => [
  ShopProduct(id: 1, name: 'เสื้อพื้นเมืองคอกลม', category: 'เสื้อผู้ชาย', price: 390, iconIndex: 0, description: 'เสื้อผ้าฝ้ายสวมใส่สบาย เหมาะกับทุกโอกาส มีหลายขนาด'),
  ShopProduct(id: 2, name: 'เสื้อผ้าฝ้ายปักลาย', category: 'เสื้อผู้หญิง', price: 590, iconIndex: 1, description: 'เสื้อผ้าฝ้ายทอลายพื้นเมือง ดีไซน์เรียบหรู'),
  ShopProduct(id: 3, name: 'ชุดพื้นเมืองล้านนา', category: 'ชุดพื้นเมือง', price: 890, iconIndex: 2, description: 'ชุดพื้นเมืองสไตล์ล้านนา เหมาะสำหรับงานประเพณี'),
  ShopProduct(id: 4, name: 'ผ้าซิ่นลายดอก', category: 'ผ้าซิ่น', price: 650, iconIndex: 0, description: 'ผ้าซิ่นลายดอกสีสวย เนื้อผ้านุ่มและทิ้งตัวดี'),
  ShopProduct(id: 5, name: 'เสื้อม่อฮ่อม', category: 'เสื้อผู้ชาย', price: 450, iconIndex: 3, description: 'เสื้อม่อฮ่อมสีน้ำเงิน สไตล์พื้นเมืองคลาสสิก'),
  ShopProduct(id: 6, name: 'ผ้าคลุมไหล่ทอมือ', category: 'เครื่องประดับ', price: 320, iconIndex: 4, description: 'ผ้าคลุมไหล่ทอมือ ใช้ได้หลายโอกาส'),
];

class FolkWearApp extends StatelessWidget {
  const FolkWearApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'เฮือนผ้าพื้นเมือง',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: red, primary: red),
      scaffoldBackgroundColor: const Color(0xFFFFF8F8),
      appBarTheme: const AppBarTheme(backgroundColor: red, foregroundColor: Colors.white),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: red, foregroundColor: Colors.white))),
    home: const AuthGate(),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _tokenKey = 'api_auth_token';
  static const _userKey = 'api_auth_user';
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _loading = true;
  String? _error;
  String? _token;
  Map<String, dynamic>? _user;

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  @override
  void initState() { super.initState(); _restore(); }

  @override
  void dispose() { _first.dispose(); _last.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      try {
        final response = await http.get(Uri.parse('$_baseUrl/api/auth/me'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          _token = token;
          _user = Map<String, dynamic>.from(data['user'] as Map);
        } else { await prefs.remove(_tokenKey); await prefs.remove(_userKey); }
      } catch (_) {
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final body = <String, dynamic>{'email': _email.text.trim(), 'password': _password.text};
      if (_register) { body['firstname'] = _first.text.trim(); body['lastname'] = _last.text.trim(); }
      final endpoint = _register ? 'register' : 'login';
      final response = await http.post(Uri.parse('$_baseUrl/api/auth/$endpoint'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(data['message']?.toString() ?? 'เข้าสู่ระบบไม่สำเร็จ');
      final token = data['token']?.toString();
      final user = Map<String, dynamic>.from(data['user'] as Map);
      if (token == null || token.isEmpty) throw Exception('เซิร์ฟเวอร์ไม่ได้ส่ง Token กลับมา');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user));
      if (!mounted) return;
      setState(() { _token = token; _user = user; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey); await prefs.remove(_userKey);
    if (mounted) setState(() { _token = null; _user = null; _password.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _token == null && _error == null) return const Scaffold(body: Center(child: CircularProgressIndicator(color: red)));
    if (_token != null && _user != null) return ShopHome(user: _user!, onLogout: _logout);
    return Scaffold(
      body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.checkroom, size: 78, color: red), const SizedBox(height: 10),
        const Text('เฮือนผ้าพื้นเมือง', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: red)),
        const SizedBox(height: 6), Text(_register ? 'สร้างบัญชีเพื่อเริ่มเลือกซื้อสินค้า' : 'เข้าสู่ระบบเพื่อเลือกซื้อผ้าพื้นเมือง', textAlign: TextAlign.center), const SizedBox(height: 28),
        if (_register) ...[
          TextFormField(controller: _first, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'ชื่อ', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null), const SizedBox(height: 14),
          TextFormField(controller: _last, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'นามสกุล', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกนามสกุล' : null), const SizedBox(height: 14),
        ],
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'อีเมล', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()), validator: (v) { final value = v?.trim() ?? ''; return value.contains('@') && value.contains('.') ? null : 'กรุณากรอกอีเมลให้ถูกต้อง'; }), const SizedBox(height: 14),
        TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'รหัสผ่าน', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()), validator: (v) => v == null || v.length < 6 ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร' : null), const SizedBox(height: 18),
        if (_error != null) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: Text(_error!, style: const TextStyle(color: red), textAlign: TextAlign.center)),
        FilledButton(onPressed: _loading ? null : _submit, child: Padding(padding: const EdgeInsets.all(12), child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_register ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ'))),
        TextButton(onPressed: _loading ? null : () => setState(() { _register = !_register; _error = null; }), child: Text(_register ? 'มีบัญชีแล้ว? เข้าสู่ระบบ' : 'ยังไม่มีบัญชี? สมัครสมาชิก')),
      ])))))),
    );
  }
}

class ShopHome extends StatefulWidget {
  final Map<String, dynamic> user;
  final Future<void> Function() onLogout;
  const ShopHome({super.key, required this.user, required this.onLogout});
  @override
  State<ShopHome> createState() => _ShopHomeState();
}

class _ShopHomeState extends State<ShopHome> {
  int tab = 0;
  String category = 'ทั้งหมด', search = '', customer = '';
  final Map<int, int> cart = {};
  final Set<int> favorites = {};
  final List<String> orders = [];
  List<ShopProduct> products = defaultProducts();
  bool ready = false;

  @override
  void initState() { super.initState(); _loadSaved(); }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProducts = prefs.getString('folk_products');
    final rawOrders = prefs.getStringList('folk_orders');
    if (!mounted) return;
    setState(() {
      if (rawProducts != null) {
        try { products = (jsonDecode(rawProducts) as List).map((e) => ShopProduct.fromJson(Map<String, dynamic>.from(e))).toList(); } catch (_) { products = defaultProducts(); }
      }
      orders.addAll(rawOrders ?? []);
      customer = prefs.getString('folk_customer') ?? '';
      ready = true;
    });
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('folk_products', jsonEncode(products.map((p) => p.toJson()).toList()));
  }
  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('folk_orders', orders);
  }

  List<ShopProduct> get shown => products.where((p) => (category == 'ทั้งหมด' || p.category == category) && p.name.toLowerCase().contains(search.toLowerCase())).toList();
  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  double get total => cart.entries.fold(0, (sum, e) { final matches = products.where((p) => p.id == e.key); return sum + (matches.isEmpty ? 0 : matches.first.price * e.value); });

  @override
  Widget build(BuildContext context) {
    if (!ready) return const Scaffold(body: Center(child: CircularProgressIndicator(color: red)));
    final pages = [buildShop(), buildCart(), buildFavorites(), buildProfile()];
    return Scaffold(
      appBar: AppBar(title: const Text('เฮือนผ้าพื้นเมือง', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(onPressed: () => setState(() => tab = 1), icon: Badge(label: Text('$cartCount'), child: const Icon(Icons.shopping_cart_outlined)))]),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), indicatorColor: red.withValues(alpha: .12), destinations: const [
        NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'หน้าร้าน'),
        NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'ตะกร้า'),
        NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'รายการโปรด'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'บัญชี'),
      ]),
    );
  }

  Widget buildShop() => Column(children: [
    Container(width: double.infinity, margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(18)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('เสน่ห์ผ้าพื้นเมือง', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 5), Text('สวมใส่ความเป็นไทย ในแบบของคุณ', style: TextStyle(color: Colors.white))])),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: TextField(decoration: InputDecoration(hintText: 'ค้นหาสินค้า...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)), onChanged: (v) => setState(() => search = v))),
    SizedBox(height: 56, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(10), children: [for (final c in ['ทั้งหมด', ...products.map((p) => p.category).toSet()]) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(c), selected: category == c, selectedColor: red.withValues(alpha: .15), onSelected: (_) => setState(() => category = c)))])),
    Expanded(child: shown.isEmpty ? const Center(child: Text('ไม่พบสินค้า')) : GridView.builder(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .68, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: shown.length, itemBuilder: (_, i) => productCard(shown[i])))
  ]);

  Widget productCard(ShopProduct p) => Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => productDetails(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: paleRed,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: p.imageBase64.isNotEmpty
                            ? Image.memory(
                                base64Decode(p.imageBase64),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Icon(p.icon, size: 76, color: red.withValues(alpha: .75)),
                                ),
                              )
                            : Center(child: Icon(p.icon, size: 76, color: red.withValues(alpha: .75))),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton(
                          onPressed: () => setState(() => favorites.contains(p.id)
                              ? favorites.remove(p.id)
                              : favorites.add(p.id)),
                          icon: Icon(
                            favorites.contains(p.id) ? Icons.favorite : Icons.favorite_border,
                            color: red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  '฿${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(color: red, fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'ไซซ์: ${p.sizes.join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'คงเหลือ ${p.stock} ชิ้น',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: p.stock <= 0
                        ? null
                        : () => setState(() => cart.update(p.id, (v) => v + 1, ifAbsent: () => 1)),
                    child: const Text('เพิ่มลงตะกร้า'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  void productDetails(ShopProduct p) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 180,
                      height: 180,
                      color: paleRed,
                      child: p.imageBase64.isNotEmpty
                          ? Image.memory(
                              base64Decode(p.imageBase64),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(p.icon, size: 100, color: red),
                            )
                          : Icon(p.icon, size: 100, color: red),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('หมวดหมู่: ${p.category} • คงเหลือ ${p.stock} ชิ้น'),
                const SizedBox(height: 8),
                Text(p.description),
                const SizedBox(height: 12),
                const Text('ไซซ์ที่มี', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: p.sizes.map((size) => Chip(label: Text(size))).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  '฿${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 24, color: red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: p.stock <= 0
                        ? null
                        : () {
                            setState(() => cart.update(p.id, (v) => v + 1, ifAbsent: () => 1));
                            Navigator.pop(context);
                          },
                    child: const Text('เพิ่มลงตะกร้า'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget buildCart() => cart.isEmpty ? const Center(child: Text('ยังไม่มีสินค้าในตะกร้า')) : Column(children: [Expanded(child: ListView(children: cart.entries.map((e) { final matches = products.where((x) => x.id == e.key); if (matches.isEmpty) return const SizedBox.shrink(); final p = matches.first; return ListTile(leading: CircleAvatar(backgroundColor: paleRed, child: Icon(p.icon, color: red)), title: Text(p.name), subtitle: Text('฿${p.price.toStringAsFixed(0)} × ${e.value}'), trailing: Wrap(children: [IconButton(onPressed: () => setState(() { if (e.value > 1) { cart[e.key] = e.value - 1; } else { cart.remove(e.key); } }), icon: const Icon(Icons.remove_circle_outline)), IconButton(onPressed: () => setState(() { if (e.value < p.stock) cart.update(e.key, (v) => v + 1); }), icon: const Icon(Icons.add_circle_outline))])); }).toList())), Container(color: Colors.white, padding: const EdgeInsets.all(18), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('ยอดรวม', style: TextStyle(fontSize: 18)), Text('฿${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, color: red, fontWeight: FontWeight.bold))]), const SizedBox(height: 10), SizedBox(width: double.infinity, child: FilledButton(onPressed: checkout, child: const Text('ยืนยันคำสั่งซื้อ')))]))]);

  void checkout() async {
    if (customer.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อในหน้าโปรไฟล์ก่อนสั่งซื้อ'))); return; }
    if (cart.isEmpty) return;
    for (final entry in cart.entries) {
      final matches = products.where((p) => p.id == entry.key).toList();
      final product = matches.isEmpty ? null : matches.first;
      if (product == null || entry.value > product.stock) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สินค้าในตะกร้ามีจำนวนเกินสต็อก'))); return; }
    }
    setState(() {
      for (final entry in cart.entries) { final p = products.firstWhere((p) => p.id == entry.key); p.stock -= entry.value; }
      orders.insert(0, 'คำสั่งซื้อ ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} • ฿${total.toStringAsFixed(0)} • $customer');
      cart.clear();
    });
    await _saveProducts(); await _saveOrders();
    if (!mounted) return;
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('สั่งซื้อสำเร็จ'), content: const Text('บันทึกคำสั่งซื้อเรียบร้อยแล้ว'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ตกลง'))]));
  }

  
  Widget buildFavorites() {
    final items = products
        .where((p) => favorites.contains(p.id))
        .toList();

    if (items.isEmpty) {
      return const Center(
        child: Text('ยังไม่มีรายการโปรด'),
      );
    }

    return ListView(
      children: items.map<Widget>((p) {
        return ListTile(
          leading: const Icon(
            Icons.favorite,
            color: Colors.red,
          ),
          title: Text(p.name),
          subtitle: Text(
            '฿${p.price.toStringAsFixed(0)}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: p.stock <= 0
                ? null
                : () {
                    setState(() {
                      cart.update(
                        p.id,
                        (v) => v + 1,
                        ifAbsent: () => 1,
                      );
                    });
                  },
          ),
        );
      }).toList(),
    );
  }

  bool get _isAdmin => (widget.user['role']?.toString().toLowerCase() ?? '') == 'admin';

  Widget buildProfile() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const CircleAvatar(
        radius: 42,
        backgroundColor: paleRed,
        child: Icon(Icons.person, size: 48, color: red),
      ),
      const SizedBox(height: 12),
      Text(
        '${widget.user['firstname'] ?? ''} ${widget.user['lastname'] ?? ''}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      Text(
        '${widget.user['email'] ?? ''}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 18),
      TextFormField(
        initialValue: customer,
        decoration: const InputDecoration(
          labelText: 'ชื่อผู้สั่งซื้อ',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
        onChanged: (v) {
          customer = v;
          SharedPreferences.getInstance().then(
            (p) => p.setString('folk_customer', v),
          );
        },
      ),
      const SizedBox(height: 20),
      const Text(
        'ประวัติคำสั่งซื้อ',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      if (orders.isEmpty)
        const Padding(
          padding: EdgeInsets.all(18),
          child: Text('ยังไม่มีคำสั่งซื้อ'),
        )
      else
        ...orders.map(
          (o) => Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: red),
              title: Text(o),
              subtitle: const Text('สถานะ: รับคำสั่งซื้อแล้ว'),
            ),
          ),
        ),
      const SizedBox(height: 24),
      if (_isAdmin) ...[
        const Divider(),
        const Text(
          'สำหรับผู้ดูแลร้าน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: openAdmin,
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text('จัดการสินค้า'),
        ),
        const SizedBox(height: 12),
      ],
      OutlinedButton.icon(
        onPressed: () async {
          await widget.onLogout();
        },
        icon: const Icon(Icons.logout),
        label: const Text('ออกจากระบบ'),
      ),
    ],
  );

  Future<void> openAdmin() async {
    if (!_isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เฉพาะผู้ดูแลระบบเท่านั้นที่สามารถจัดการสินค้าได้'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductsScreen(
          products: products,
          onChanged: _saveProducts,
          onAdd: _addProduct,
          onUpdate: _updateProduct,
          onDelete: _deleteProduct,
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _addProduct(ShopProduct p) async {
    setState(() {
      final nextId = products.isEmpty
          ? 1
          : products.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
      p = ShopProduct(
        id: nextId,
        name: p.name,
        category: p.category,
        price: p.price,
        description: p.description,
        stock: p.stock,
        iconIndex: p.iconIndex,
        imageBase64: p.imageBase64,
        sizes: List<String>.from(p.sizes),
      );
      products.insert(0, p);
    });
    await _saveProducts();
  }
  Future<void> _updateProduct(ShopProduct updated) async { setState(() { final i = products.indexWhere((p) => p.id == updated.id); if (i >= 0) products[i] = updated; }); await _saveProducts(); }
  Future<void> _deleteProduct(int id) async { setState(() { products.removeWhere((p) => p.id == id); cart.remove(id); favorites.remove(id); }); await _saveProducts(); }
}

class AdminProductsScreen extends StatefulWidget {
  final List<ShopProduct> products;
  final Future<void> Function() onChanged;
  final Future<void> Function(ShopProduct) onAdd;
  final Future<void> Function(ShopProduct) onUpdate;
  final Future<void> Function(int) onDelete;
  const AdminProductsScreen({super.key, required this.products, required this.onChanged, required this.onAdd, required this.onUpdate, required this.onDelete});
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}


class ProductFormDialog extends StatefulWidget {
  final ShopProduct? product;

  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _description;
  late final TextEditingController _customSize;
  final ImagePicker _picker = ImagePicker();

  late int _iconIndex;
  late List<String> _sizes;
  String _imageBase64 = '';
  final bool _saving = false;

  static const presetSizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    'Free Size',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _category = TextEditingController(text: p?.category ?? 'เสื้อพื้นเมือง');
    _price = TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(0));
    _stock = TextEditingController(text: p == null ? '10' : '${p.stock}');
    _description = TextEditingController(text: p?.description ?? '');
    _customSize = TextEditingController();
    _iconIndex = p?.iconIndex ?? 0;
    _sizes = List<String>.from(p?.sizes ?? const ['S', 'M', 'L', 'XL']);
    _imageBase64 = p?.imageBase64 ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _stock.dispose();
    _description.dispose();
    _customSize.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBase64 = base64Encode(bytes);
    });
  }

  void _toggleSize(String size) {
    setState(() {
      if (_sizes.contains(size)) {
        _sizes.remove(size);
      } else {
        _sizes.add(size);
      }
    });
  }

  void _addCustomSize() {
    final size = _customSize.text.trim();
    if (size.isEmpty) return;
    if (!_sizes.contains(size)) {
      setState(() => _sizes.add(size));
    }
    _customSize.clear();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอย่างน้อย 1 Size')),
      );
      return;
    }

    final price = double.tryParse(_price.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    if (price == null || stock == null) return;

    final product = ShopProduct(
      id: widget.product?.id ?? 0,
      name: _name.text.trim(),
      category: _category.text.trim(),
      price: price,
      stock: stock,
      description: _description.text.trim(),
      iconIndex: _iconIndex,
      imageBase64: _imageBase64,
      sizes: List<String>.from(_sizes),
    );

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;

    return AlertDialog(
      title: Text(editing ? 'แก้ไขสินค้า' : 'เพิ่มสินค้าใหม่'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: paleRed,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: red.withValues(alpha: .25)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imageBase64.isNotEmpty
                          ? Image.memory(
                              base64Decode(_imageBase64),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.broken_image_outlined, size: 48, color: red),
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 44, color: red),
                                  SizedBox(height: 8),
                                  Text('กดเพื่อเลือกรูปสินค้า'),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'ชื่อสินค้า', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'หมวดหมู่', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกหมวดหมู่' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'ราคา (บาท)', border: OutlineInputBorder()),
                  validator: (v) {
                    final value = double.tryParse(v?.trim() ?? '');
                    return value == null || value <= 0 ? 'กรุณากรอกราคาที่ถูกต้อง' : null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'จำนวนสินค้าในสต็อก', border: OutlineInputBorder()),
                  validator: (v) {
                    final value = int.tryParse(v?.trim() ?? '');
                    return value == null || value < 0 ? 'กรุณากรอกสต็อกเป็นจำนวนเต็ม 0 ขึ้นไป' : null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'รายละเอียดสินค้า', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Size สินค้า', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final size in presetSizes)
                      FilterChip(
                        label: Text(size),
                        selected: _sizes.contains(size),
                        selectedColor: red.withValues(alpha: .15),
                        checkmarkColor: red,
                        onSelected: (_) => _toggleSize(size),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customSize,
                        decoration: const InputDecoration(
                          labelText: 'เพิ่ม Size เอง',
                          hintText: 'เช่น 4XL, 42, 44',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addCustomSize(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addCustomSize,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_sizes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final size in _sizes)
                        Chip(
                          label: Text(size),
                          onDeleted: () => setState(() => _sizes.remove(size)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ไอคอนสินค้า'),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  initialValue: _iconIndex,
                  items: [
                    for (var i = 0; i < productIcons.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Row(
                          children: [
                            Icon(productIcons[i], color: red),
                            const SizedBox(width: 8),
                            Text('รูปแบบ ${i + 1}'),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _iconIndex = v ?? 0),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(editing ? 'บันทึกการแก้ไข' : 'เพิ่มสินค้า'),
        ),
      ],
    );
  }
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('จัดการสินค้า')), floatingActionButton: FloatingActionButton.extended(backgroundColor: red, foregroundColor: Colors.white, onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('เพิ่มสินค้า')), body: widget.products.isEmpty ? const Center(child: Text('ยังไม่มีสินค้า')) : ListView.separated(padding: const EdgeInsets.only(bottom: 90), itemCount: widget.products.length, separatorBuilder: (_, _) => const Divider(height: 1), itemBuilder: (_, i) { final p = widget.products[i]; return ListTile(leading: CircleAvatar(backgroundColor: paleRed, child: Icon(p.icon, color: red)), title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${p.category} • ฿${p.price.toStringAsFixed(0)} • คงเหลือ ${p.stock} • ไซซ์ ${p.sizes.join(', ')}'), trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') _openForm(product: p); if (v == 'delete') _confirmDelete(p); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('แก้ไข'))), PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: red), title: Text('ลบสินค้า')))])); }));

  Future<void> _openForm({ShopProduct? product}) async {
    final result = await showDialog<ShopProduct>(
      context: context,
      builder: (_) => ProductFormDialog(product: product),
    );

    if (result == null) return;

    if (product == null) {
      await widget.onAdd(result);
    } else {
      await widget.onUpdate(result);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmDelete(ShopProduct p) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text(
          'ต้องการลบสินค้า "${p.name}" หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('ลบสินค้า'),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await widget.onDelete(p.id);

    if (mounted) {
      setState(() {});
    }
  }
}
}