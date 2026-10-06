const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('../db');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();
const uploadDir = path.join(__dirname, '../../uploads/images');
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    cb(
      null,
      `${Date.now()}-${Math.round(Math.random() * 1e9)}${path.extname(file.originalname).toLowerCase()}`,
    );
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (/^image\/(jpeg|png|webp|gif)$/.test(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('รองรับไฟล์รูป JPG, PNG, WEBP หรือ GIF เท่านั้น'));
    }
  },
});

const productFields = `
  p.id,
  p.name,
  p.description,
  p.image,
  p.barcode,
  p.stock,
  CAST(p.price AS UNSIGNED) AS price,
  p.category_id,
  p.status_id,
  COALESCE(NULLIF(p.sizes, ''), 'S,M,L,XL') AS sizes
`;

function normalizeSizes(value) {
  if (value === undefined || value === null) return '';
  return String(value)
    .split(',')
    .map((size) => size.trim())
    .filter(Boolean)
    .filter((size, index, array) => array.indexOf(size) === index)
    .join(',');
}

function sizeList(value) {
  return normalizeSizes(value)
    .split(',')
    .map((size) => size.trim())
    .filter(Boolean);
}

router.get('/', async (_req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT ${productFields} FROM products p WHERE p.status_id=1 ORDER BY p.id DESC`,
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT ${productFields} FROM products p WHERE p.id=? AND p.status_id=1`,
      [req.params.id],
    );
    if (!rows.length) return res.status(404).json({ message: 'ไม่พบสินค้า' });
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

router.post(
  '/',
  authenticateToken,
  requireAdmin,
  upload.single('photo'),
  async (req, res, next) => {
    try {
      const {
        name,
        description = '',
        barcode,
        stock,
        price,
        category_id,
        sizes,
      } = req.body;
      const normalizedSizes = normalizeSizes(sizes);

      if (
        !name ||
        !barcode ||
        stock === undefined ||
        price === undefined ||
        !category_id ||
        !normalizedSizes
      ) {
        return res.status(400).json({ message: 'กรุณากรอกข้อมูลสินค้าและ Size ให้ครบ' });
      }

      const [result] = await db.query(
        `INSERT INTO products
          (name,description,image,barcode,stock,price,category_id,status_id,created_by,sizes)
         VALUES (?,?,?,?,?,?,?,1,?,?)`,
        [
          name,
          description,
          req.file?.filename || null,
          barcode,
          Number(stock),
          Number(price),
          Number(category_id),
          req.user.id,
          normalizedSizes,
        ],
      );

      const [rows] = await db.query(
        `SELECT ${productFields} FROM products p WHERE p.id=?`,
        [result.insertId],
      );
      res.status(201).json({ message: 'เพิ่มสินค้าสำเร็จ', product: rows[0] });
    } catch (e) {
      next(e);
    }
  },
);

router.put(
  '/:id',
  authenticateToken,
  requireAdmin,
  upload.single('photo'),
  async (req, res, next) => {
    try {
      const allowed = [
        'name',
        'description',
        'barcode',
        'stock',
        'price',
        'category_id',
        'sizes',
      ];
      const sets = [];
      const values = [];

      for (const key of allowed) {
        if (req.body[key] !== undefined) {
          sets.push(`${key}=?`);
          if (['stock', 'price', 'category_id'].includes(key)) {
            values.push(Number(req.body[key]));
          } else if (key === 'sizes') {
            const normalized = normalizeSizes(req.body[key]);
            if (!normalized) {
              return res.status(400).json({ message: 'กรุณาเลือกอย่างน้อย 1 Size' });
            }
            values.push(normalized);
          } else {
            values.push(req.body[key]);
          }
        }
      }

      if (req.file) {
        sets.push('image=?');
        values.push(req.file.filename);
      }

      if (!sets.length) {
        return res.status(400).json({ message: 'ไม่มีข้อมูลที่ต้องการแก้ไข' });
      }

      values.push(req.params.id);
      const [result] = await db.query(
        `UPDATE products SET ${sets.join(',')} WHERE id=?`,
        values,
      );

      if (!result.affectedRows) {
        return res.status(404).json({ message: 'ไม่พบสินค้า' });
      }

      const [rows] = await db.query(
        `SELECT ${productFields} FROM products p WHERE p.id=?`,
        [req.params.id],
      );
      res.json({ message: 'แก้ไขสินค้าสำเร็จ', product: rows[0] });
    } catch (e) {
      next(e);
    }
  },
);

router.delete('/:id', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const [result] = await db.query('DELETE FROM products WHERE id=?', [req.params.id]);
    if (!result.affectedRows) return res.status(404).json({ message: 'ไม่พบสินค้า' });
    res.json({ message: 'ลบสินค้าสำเร็จ' });
  } catch (e) {
    if (e.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(409).json({ message: 'สินค้านี้มีประวัติคำสั่งซื้อ จึงลบไม่ได้' });
    }
    next(e);
  }
});

module.exports = router;
