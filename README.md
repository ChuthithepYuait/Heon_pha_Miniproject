# เฮือนผ้าพื้นเมือง — Flutter + Node.js + MySQL

Mini Project ร้านเสื้อผ้าพื้นเมือง ใช้ Flutter (แดง/ขาว), Express REST API, MySQL และ JWT Authentication. โฟลเดอร์ `serverapi_ts` เป็น Backend สำหรับทดสอบด้วย Thunder Client.

## A. เตรียมฐานข้อมูล MySQL
1. เปิด MySQL Server ที่พอร์ต `3306` (เช่น XAMPP, MySQL Workbench หรือ Laragon)
2. เปิด Workbench/phpMyAdmin แล้ว Import/Run `serverapi_ts/sql/schema.sql`
3. ไฟล์นี้สร้างฐานข้อมูล `heuan_pha_shop`, ตาราง users/categories/products/orders/order_items และข้อมูลสินค้าเริ่มต้น

## B. ตั้งค่าและรัน Backend
เปิด Terminal ในโฟลเดอร์ `serverapi_ts`:

```bash
npm install
```

คัดลอก `.env.example` เป็น `.env` แล้วกรอกค่าของ MySQL จริง โดยเฉพาะ `DB_PASSWORD` และตั้ง `JWT_SECRET` เป็นข้อความสุ่มยาวอย่างน้อย 32 ตัวอักษร

Windows PowerShell:
```powershell
Copy-Item .env.example .env
notepad .env
npm run dev
```

หรือใช้ `npm start`. เมื่อสำเร็จจะแสดง `MySQL connected` และ `API listening on http://localhost:3000`.

ทดสอบใน Browser/Thunder Client: `GET http://localhost:3000/api/health` ต้องตอบ `database: connected`.

## C. ทดสอบ Login/Register ด้วย Thunder Client
ดูคู่มือเต็มที่ `serverapi_ts/THUNDER_CLIENT.md` มี Register, Login, /me, Products, Orders และตัวอย่าง multipart สำหรับเพิ่มสินค้า

API หลัก:
- `POST /api/auth/register` — สมัครสมาชิก; body firstname, lastname, email, password
- `POST /api/auth/login` — Login; body email, password
- `GET /api/auth/me` — ต้องมี Bearer token
- `GET /api/products` — รายการสินค้า
- `POST /api/products` / `PUT /api/products/:id` / `DELETE /api/products/:id` — Admin เท่านั้น
- `POST /api/orders`, `GET /api/orders`, `GET /api/orders/:id` — ต้อง Login

รหัสผ่านเก็บเป็น bcrypt hash ไม่เก็บ plaintext. JWT ใช้ตรวจสิทธิ์บน Backend.

## D. กำหนดบัญชี Admin
1. สมัครบัญชีด้วย Register หรือจากหน้า Register ใน Flutter.
2. ใน MySQL รันคำสั่ง (เปลี่ยนอีเมลให้ตรงบัญชีที่สมัคร):
```sql
USE heuan_pha_shop;
UPDATE users SET role='admin' WHERE email='your-admin-email@example.com';
```
3. Logout แล้ว Login ใหม่เพื่อรับ JWT ที่มี role `admin`. ห้ามใช้ role ที่ส่งมาจาก client เป็นตัวกำหนดสิทธิ์.

## E. รัน Flutter Android Emulator
1. เปิดโปรเจกต์หลัก (โฟลเดอร์ที่มี `pubspec.yaml`) ใน Android Studio.
2. เปิด Emulator และตรวจด้วย `flutter devices`.
3. ใน Terminal โปรเจกต์ Flutter:
```bash
flutter pub get
flutter run -d <android-device-id>
```

Flutter ใช้ `http://10.0.2.2:3000` สำหรับ Android Emulator ซึ่งชี้กลับมายังเครื่องพัฒนา. ต้องเปิด Backend ค้างไว้ระหว่างใช้แอป. หากใช้มือถือจริง ให้แก้ `lib/config/api_config.dart` เป็น IP LAN ของเครื่องที่รัน Backend และให้ทั้งสองเครื่องอยู่ Wi-Fi เดียวกัน.

## หมายเหตุ
- Backend ใช้ MySQL local; Thunder Client trên máyพัฒนาใช้ `localhost:3000` ส่วน Android Emulator ใช้ `10.0.2.2:3000`.
- การอัปโหลดรูปสินค้ารองรับ JPG/PNG/WEBP/GIF ขนาดไม่เกิน 5 MB และเก็บไว้ใน `serverapi_ts/uploads/images`.
- นี่เป็นชุดสำหรับการเรียน/ทดสอบในเครื่อง ไม่ใช่การตั้งค่า production. ก่อนเผยแพร่จริงต้องใช้ HTTPS, secret ที่ปลอดภัย, validation/rate limiting และระบบจัดการรูป/backup ที่เหมาะสม.
