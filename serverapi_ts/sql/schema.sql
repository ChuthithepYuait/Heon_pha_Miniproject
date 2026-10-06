CREATE DATABASE IF NOT EXISTS heuan_pha_shop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE heuan_pha_shop;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  firstname VARCHAR(100) NOT NULL,
  lastname VARCHAR(100) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('customer','admin') NOT NULL DEFAULT 'customer',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  description TEXT NULL,
  image VARCHAR(255) NULL,
  barcode VARCHAR(100) NOT NULL UNIQUE,
  stock INT NOT NULL DEFAULT 0,
  price DECIMAL(10,2) NOT NULL,
  category_id INT NOT NULL,
  sizes VARCHAR(120) NULL,
  status_id TINYINT NOT NULL DEFAULT 1,
  created_by INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id),
  CONSTRAINT fk_products_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  status ENUM('confirmed','processing','shipped','completed','cancelled') NOT NULL DEFAULT 'confirmed',
  total_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS order_items (
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
);

INSERT IGNORE INTO categories (id, name) VALUES
(1,'เสื้อพื้นเมือง'),(2,'ชุดพื้นเมือง'),(3,'ผ้าซิ่นและผ้าถุง'),(4,'เครื่องประดับ');

INSERT IGNORE INTO products (name,description,barcode,stock,price,category_id,sizes,status_id) VALUES
('เสื้อพื้นเมืองคอกลม','เสื้อผ้าฝ้ายพื้นเมือง ใส่สบาย','FOLK-001',25,390,1,'S,M,L,XL',1),
('เสื้อพื้นเมืองแขนยาว','เสื้อพื้นเมืองลายทอ เหมาะกับทุกโอกาส','FOLK-002',15,590,1,'S,M,L,XL,XXL',1),
('ชุดพื้นเมืองผู้หญิง','ชุดพื้นเมืองพร้อมใส่','FOLK-003',10,890,2,'S,M,L,XL',1);

-- หลังสมัครสมาชิกแล้ว ให้เปลี่ยนสิทธิ์บัญชีที่ต้องการเป็น admin ด้วยคำสั่ง:
-- UPDATE users SET role='admin' WHERE email='your-admin-email@example.com';

-- การรองรับรูปสินค้าและ Size:
-- products.image เก็บชื่อไฟล์รูปที่อัปโหลดใน serverapi_ts/uploads/images
-- products.sizes เก็บ Size คั่นด้วย comma เช่น S,M,L,XL,XXL
-- หากใช้ฐานข้อมูลเดิม server.js จะเพิ่มคอลัมน์ sizes และ order_items.size ให้อัตโนมัติเมื่อ Backend เริ่มทำงาน
