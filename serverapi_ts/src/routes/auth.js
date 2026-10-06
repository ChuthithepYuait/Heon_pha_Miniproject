const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const router = express.Router();
const publicUser = (u) => ({ id: u.id, firstname: u.firstname, lastname: u.lastname, email: u.email, role: u.role });
function makeToken(user) {
  return jwt.sign({ id: user.id, email: user.email, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });
}
router.post('/register', async (req, res, next) => {
  try {
    const firstname = String(req.body.firstname || '').trim();
    const lastname = String(req.body.lastname || '').trim();
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');
    if (!firstname || !lastname || !email || !password) return res.status(400).json({status:'error',message:'กรุณากรอกชื่อ นามสกุล อีเมล และรหัสผ่านให้ครบ'});
    if (!/^\S+@\S+\.\S+$/.test(email)) return res.status(400).json({status:'error',message:'รูปแบบอีเมลไม่ถูกต้อง'});
    if (password.length < 6) return res.status(400).json({status:'error',message:'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'});
    const [exists] = await db.query('SELECT id FROM users WHERE email=?', [email]);
    if (exists.length) return res.status(409).json({status:'error',message:'อีเมลนี้ถูกใช้งานแล้ว'});
    const hash = await bcrypt.hash(password, 12);
    const [result] = await db.query('INSERT INTO users(firstname,lastname,email,password_hash) VALUES(?,?,?,?)', [firstname,lastname,email,hash]);
    const user = { id: result.insertId, firstname, lastname, email, role:'customer' };
    return res.status(201).json({status:'success',message:'สมัครสมาชิกสำเร็จ',token:makeToken(user),user});
  } catch (e) { next(e); }
});
router.post('/login', async (req, res, next) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');
    if (!email || !password) return res.status(400).json({status:'error',message:'กรุณากรอกอีเมลและรหัสผ่าน'});
    const [rows] = await db.query('SELECT id,firstname,lastname,email,password_hash,role FROM users WHERE email=? LIMIT 1', [email]);
    if (!rows.length || !(await bcrypt.compare(password, rows[0].password_hash))) return res.status(401).json({status:'error',message:'อีเมลหรือรหัสผ่านไม่ถูกต้อง'});
    const user = publicUser(rows[0]);
    return res.json({status:'success',message:'เข้าสู่ระบบสำเร็จ',token:makeToken(user),user});
  } catch (e) { next(e); }
});
router.get('/me', require('../middleware/auth').authenticateToken, async (req,res,next) => {
  try { const [rows] = await db.query('SELECT id,firstname,lastname,email,role FROM users WHERE id=?',[req.user.id]); if(!rows.length) return res.status(404).json({status:'error',message:'ไม่พบบัญชีผู้ใช้'}); res.json({user:rows[0]}); } catch(e){next(e);}
});
module.exports = router;
