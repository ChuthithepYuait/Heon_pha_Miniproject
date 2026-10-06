require('dotenv').config();
const express=require('express');const cors=require('cors');const path=require('path');const db=require('./db');
const app=express();app.use(cors());app.use(express.json({limit:'2mb'}));app.use(express.urlencoded({extended:true}));app.use('/uploads',express.static(path.join(__dirname,'../uploads')));
app.get('/',(_req,res)=>res.json({name:'Heuan Pha Folk Shop API',status:'running'}));
app.get('/api/health',async(_req,res)=>{try{await db.query('SELECT 1');res.json({status:'ok',database:'connected'});}catch(_){res.status(500).json({status:'error',database:'disconnected'});}});
app.use('/api/auth',require('./routes/auth'));app.use('/api/products',require('./routes/products'));app.use('/api/orders',require('./routes/orders'));
app.use((err,_req,res,_next)=>{console.error(err);if(err.code==='ER_DUP_ENTRY')return res.status(409).json({status:'error',message:'อีเมลหรือรหัสสินค้าใช้งานแล้ว'});if(err.code==='ER_NO_REFERENCED_ROW_2')return res.status(400).json({status:'error',message:'หมวดหมู่สินค้าไม่ถูกต้อง'});res.status(err.status||500).json({status:'error',message:err.message||'เกิดข้อผิดพลาดในเซิร์ฟเวอร์'});});
const port=Number(process.env.PORT||3000);
async function ensureDatabaseStructure(){
  // Ensure orders table exists first because order_items references it.
  const [ordersTable] = await db.query("SHOW TABLES LIKE 'orders'");
  if (!ordersTable.length) {
    await db.query(`CREATE TABLE orders (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      status ENUM('confirmed','processing','shipped','completed','cancelled') NOT NULL DEFAULT 'confirmed',
      total_price DECIMAL(10,2) NOT NULL DEFAULT 0,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
    console.log('Migration: created orders table');
  }

  // Existing projects may already have products, but without the newer image/sizes columns.
  const [imageCols] = await db.query("SHOW COLUMNS FROM products LIKE 'image'");
  if (!imageCols.length) {
    await db.query("ALTER TABLE products ADD COLUMN image VARCHAR(255) NULL AFTER description");
    console.log('Migration: added products.image');
  }

  const [sizeCols] = await db.query("SHOW COLUMNS FROM products LIKE 'sizes'");
  if (!sizeCols.length) {
    await db.query('ALTER TABLE products ADD COLUMN sizes VARCHAR(120) NULL AFTER category_id');
    console.log('Migration: added products.sizes');
  }

  // The previous database used by this project may not have order_items at all.
  const [itemsTable] = await db.query("SHOW TABLES LIKE 'order_items'");
  if (!itemsTable.length) {
    await db.query(`CREATE TABLE order_items (
      id INT AUTO_INCREMENT PRIMARY KEY,
      order_id INT NOT NULL,
      product_id INT NOT NULL,
      product_name VARCHAR(200) NOT NULL,
      size VARCHAR(20) NOT NULL DEFAULT '',
      unit_price DECIMAL(10,2) NOT NULL,
      quantity INT NOT NULL,
      subtotal DECIMAL(10,2) NOT NULL,
      CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
      CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products(id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
    console.log('Migration: created order_items table');
  } else {
    const [itemSizeCols] = await db.query("SHOW COLUMNS FROM order_items LIKE 'size'");
    if (!itemSizeCols.length) {
      await db.query("ALTER TABLE order_items ADD COLUMN size VARCHAR(20) NOT NULL DEFAULT '' AFTER product_name");
      console.log('Migration: added order_items.size');
    }
  }
}

(async()=>{try{await db.query('SELECT 1');await ensureDatabaseStructure();console.log('MySQL connected');app.listen(port,'0.0.0.0',()=>console.log(`API listening on http://localhost:${port}`));}catch(e){console.error('Cannot connect to MySQL. Check .env and import sql/schema.sql',e.message);process.exit(1);}})();
