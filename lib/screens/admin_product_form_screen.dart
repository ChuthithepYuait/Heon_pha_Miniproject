import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/categories.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Product? product;

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  static const _sizeOptions = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
    'Free Size',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _stockController;
  late final TextEditingController _priceController;
  late int _categoryId;
  late List<String> _selectedSizes;
  late final TextEditingController _customSizeController;

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController =
        TextEditingController(text: product?.description ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _stockController = TextEditingController(text: product?.stock.toString() ?? '');
    _priceController = TextEditingController(text: product?.price.toString() ?? '');
    _categoryId = product?.categoryId ?? ProductCategory.names.keys.first;
    _selectedSizes = product != null && product.sizes.isNotEmpty
        ? [...product.sizes]
        : ['S', 'M', 'L', 'XL'];
    _customSizeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    _customSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() {
      _pickedImage = picked;
      _pickedImageBytes = bytes;
    });
  }

  void _addCustomSize() {
    final size = _customSizeController.text.trim();
    if (size.isEmpty) return;

    if (_selectedSizes.contains(size)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Size นี้ถูกเลือกไว้แล้ว')),
      );
      return;
    }

    setState(() {
      _selectedSizes.add(size);
      _customSizeController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอย่างน้อย 1 Size')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<ProductProvider>();
    final token = auth.token;
    if (token == null) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final barcode = _barcodeController.text.trim();
    final stock = int.parse(_stockController.text.trim());
    final price = int.parse(_priceController.text.trim());

    final bool success;
    if (_isEditing) {
      success = await provider.updateProduct(
        token: token,
        id: widget.product!.id,
        name: name,
        description: description,
        barcode: barcode.isEmpty ? null : barcode,
        stock: stock,
        price: price,
        categoryId: _categoryId,
        sizes: _selectedSizes,
        imageFile: _pickedImage,
      );
    } else {
      success = await provider.createProduct(
        token: token,
        name: name,
        description: description,
        barcode: barcode,
        stock: stock,
        price: price,
        categoryId: _categoryId,
        sizes: _selectedSizes,
        imageFile: _pickedImage,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.adminErrorMessage ?? 'บันทึกไม่สำเร็จ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<ProductProvider>().isSaving;
    final existingImageUrl = ApiConfig.imageUrl(widget.product?.image);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขสินค้า' : 'เพิ่มสินค้า'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildImagePreview(existingImageUrl),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _pickedImage == null
                      ? 'เลือกรูปสินค้า'
                      : 'เปลี่ยนรูปสินค้า',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสินค้า',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'กรุณากรอกชื่อสินค้า'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดสินค้า',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  border: const OutlineInputBorder(),
                  hintText: _isEditing
                      ? 'เว้นว่างได้ เพื่อใช้ค่าเดิม'
                      : 'เช่น FOLK-004',
                ),
                validator: (value) {
                  if (_isEditing) return null;
                  return (value == null || value.trim().isEmpty)
                      ? 'กรุณากรอก Barcode'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Size ที่มีจำหน่าย',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'เลือกได้หลายขนาด เช่น S, M, L, XL หรือ Free Size',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sizeOptions.map((size) {
                  final selected = _selectedSizes.contains(size);
                  return FilterChip(
                    label: Text(size),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          if (!_selectedSizes.contains(size)) {
                            _selectedSizes.add(size);
                          }
                        } else {
                          _selectedSizes.remove(size);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customSizeController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'เพิ่ม Size เอง',
                        hintText: 'เช่น 42, 44, 3XL',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addCustomSize(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: _addCustomSize,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่ม'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_selectedSizes.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedSizes.map((size) {
                    return InputChip(
                      label: Text(size),
                      onDeleted: () {
                        setState(() => _selectedSizes.remove(size));
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 6),
              Text(
                _selectedSizes.isEmpty
                    ? 'ยังไม่ได้เลือก Size'
                    : 'Size ที่เลือก: ${_selectedSizes.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'จำนวนสต็อก',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateNonNegativeInt,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ราคา (บาท)',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateNonNegativeInt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final entry in ProductCategory.names.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _categoryId = value);
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: isSaving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'บันทึกการแก้ไข' : 'เพิ่มสินค้า'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateNonNegativeInt(String? value) {
    if (value == null || value.trim().isEmpty) return 'กรุณากรอกข้อมูล';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'กรุณากรอกตัวเลขที่ถูกต้อง';
    return null;
  }

  Widget _buildImagePreview(String existingImageUrl) {
    if (_pickedImageBytes != null) {
      return Image.memory(_pickedImageBytes!, fit: BoxFit.cover);
    }
    if (existingImageUrl.isNotEmpty) {
      return Image.network(
        existingImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        const Text('แตะเพื่อเลือกรูปสินค้า'),
      ],
    );
  }
}
