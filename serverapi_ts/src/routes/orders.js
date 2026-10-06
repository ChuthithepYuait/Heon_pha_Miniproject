const express = require('express');
const db = require('../db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
router.use(authenticateToken);

function normalizeSize(value) {
  return String(value || '').trim();
}

function parseSizes(value) {
  return String(value || '')
    .split(',')
    .map((size) => size.trim())
    .filter(Boolean);
}

router.post('/', async (req, res, next) => {
  const items = req.body.items;
  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ message: 'ไม่มีสินค้าในคำสั่งซื้อ' });
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();
    let total = 0;
    const snapshots = [];

    for (const item of items) {
      const pid = Number(item.product_id);
      const qty = Number(item.quantity);
      const size = normalizeSize(item.size);

      if (!Number.isInteger(pid) || !Number.isInteger(qty) || qty < 1) {
        throw Object.assign(new Error('รายการสินค้าไม่ถูกต้อง'), { status: 400 });
      }

      const [rows] = await conn.query(
        'SELECT id,name,price,stock,sizes FROM products WHERE id=? AND status_id=1 FOR UPDATE',
        [pid],
      );
      if (!rows.length) {
        throw Object.assign(new Error('ไม่พบสินค้าในระบบ'), { status: 404 });
      }

      const p = rows[0];
      const allowedSizes = parseSizes(p.sizes);

      if (allowedSizes.length > 0 && !allowedSizes.includes(size)) {
        throw Object.assign(new Error(`กรุณาเลือก Size ที่ถูกต้องสำหรับ ${p.name}`), {
          status: 400,
        });
      }

      if (p.stock < qty) {
        throw Object.assign(new Error(`สินค้า ${p.name} มีไม่เพียงพอ`), {
          status: 409,
        });
      }

      const unit = Number(p.price);
      const subtotal = unit * qty;
      total += subtotal;
      snapshots.push({
        product_id: p.id,
        product_name: p.name,
        size,
        unit_price: unit,
        quantity: qty,
        subtotal,
      });
    }

    const [orderResult] = await conn.query(
      'INSERT INTO orders(user_id,status,total_price) VALUES(?,?,?)',
      [req.user.id, 'confirmed', total],
    );
    const orderId = orderResult.insertId;

    for (const item of snapshots) {
      await conn.query(
        `INSERT INTO order_items
          (order_id,product_id,product_name,size,unit_price,quantity,subtotal)
         VALUES(?,?,?,?,?,?,?)`,
        [
          orderId,
          item.product_id,
          item.product_name,
          item.size,
          item.unit_price,
          item.quantity,
          item.subtotal,
        ],
      );

      await conn.query(
        'UPDATE products SET stock=stock-? WHERE id=?',
        [item.quantity, item.product_id],
      );
    }

    await conn.commit();
    res.status(201).json({
      message: 'สั่งซื้อสำเร็จ',
      order: {
        id: orderId,
        status: 'confirmed',
        total_price: total,
        created_at: new Date().toISOString(),
        items: snapshots,
      },
    });
  } catch (e) {
    await conn.rollback();
    next(e);
  } finally {
    conn.release();
  }
});

router.get('/', async (req, res, next) => {
  try {
    const [rows] = await db.query(
      'SELECT id,status,CAST(total_price AS UNSIGNED) total_price,created_at FROM orders WHERE user_id=? ORDER BY id DESC',
      [req.user.id],
    );
    res.json({ orders: rows });
  } catch (e) {
    next(e);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const [orders] = await db.query(
      'SELECT id,status,CAST(total_price AS UNSIGNED) total_price,created_at FROM orders WHERE id=? AND user_id=?',
      [req.params.id, req.user.id],
    );
    if (!orders.length) return res.status(404).json({ message: 'ไม่พบคำสั่งซื้อ' });

    const [items] = await db.query(
      `SELECT product_id,product_name,size,
        CAST(unit_price AS UNSIGNED) unit_price,
        quantity,
        CAST(subtotal AS UNSIGNED) subtotal
       FROM order_items WHERE order_id=?`,
      [req.params.id],
    );

    res.json({ order: { ...orders[0], items } });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
