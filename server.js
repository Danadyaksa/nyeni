require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const path = require('path');
const multer = require('multer');
const fs = require('fs');

const app = express();
app.use(express.json());
app.use(cors());

// Folder uploads bisa diakses publik
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const JWT_SECRET = process.env.JWT_SECRET;

// ==========================================
// KONEKSI DATABASE
// ==========================================
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME,
});

db.connect((err) => {
  if (err) throw err;
  console.log('✅ Berhasil konek ke MySQL Nyeni!');
  // Set timezone ke WIB (+07:00) supaya created_at tersimpan dan terbaca dengan benar
  db.query("SET time_zone = '+07:00'", (tzErr) => {
    if (tzErr) console.warn('⚠️ Gagal set timezone:', tzErr.message);
    else console.log('🕐 Timezone diset ke WIB (+07:00)');
  });
});

// ==========================================
// AUTH: REGISTER
// ==========================================
app.post('/api/auth/register', async (req, res) => {
  const { email, password, full_name } = req.body;
  const hashedPassword = await bcrypt.hash(password, 10);
  const userId = crypto.randomUUID();
  const sql = 'INSERT INTO users (id, email, password, full_name) VALUES (?, ?, ?, ?)';
  db.query(sql, [userId, email, hashedPassword, full_name], (err) => {
    if (err) {
      if (err.code === 'ER_DUP_ENTRY')
        return res.status(400).json({ error: 'Email sudah terdaftar!' });
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Registrasi berhasil!', user_id: userId });
  });
});

// ==========================================
// AUTH: LOGIN (mengembalikan field 'role')
// ==========================================
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  const sql = 'SELECT * FROM users WHERE email = ?';
  db.query(sql, [email], async (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0)
      return res.status(401).json({ error: 'Email tidak ditemukan!' });

    const user = results[0];
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ error: 'Password salah!' });

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, {
      expiresIn: '7d',
    });
    delete user.password;
    // 'role' ikut terkirim ke Flutter untuk redirect admin/user
    res.json({ message: 'Login berhasil!', token, user });
  });
});

// ==========================================
// USER: AMBIL PROFIL
// ==========================================
app.get('/api/user/:id', (req, res) => {
  db.query('SELECT * FROM users WHERE id = ?', [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const user = results[0];
    if (user) delete user.password;
    res.json(user);
  });
});

// ==========================================
// USER: UPDATE NAMA
// ==========================================
app.post('/api/user/update-name', (req, res) => {
  const { id, full_name } = req.body;
  db.query('UPDATE users SET full_name = ? WHERE id = ?', [full_name, id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ status: 'success', message: 'Nama berhasil diubah!' });
  });
});

// ==========================================
// USER: UPDATE PROGRESS GAME & XP
// ==========================================
app.post('/api/user/update-progress', (req, res) => {
  const { id, total_xp, level, completed_levels_trivia, completed_levels_labirin } = req.body;
  const sql = `UPDATE users SET total_xp = ?, level = ?, completed_levels_trivia = ?, completed_levels_labirin = ? WHERE id = ?`;
  db.query(sql, [total_xp, level, completed_levels_trivia, completed_levels_labirin, id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ status: 'success', message: 'Progress berhasil disimpan!' });
  });
});

// ==========================================
// MULTER: KONFIGURASI UPLOAD AVATAR
// ==========================================
if (!fs.existsSync('./uploads')) fs.mkdirSync('./uploads');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) =>
    cb(null, 'avatar-' + Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// ==========================================
// USER: UPLOAD AVATAR
// ==========================================
app.post('/api/user/upload-avatar', upload.single('avatar'), (req, res) => {
  const userId = req.body.id;
  if (!req.file)
    return res.status(400).json({ error: 'Tidak ada file gambar yang dikirim!' });

  const PORT = process.env.PORT || 3000;
  const avatarUrl = `http://localhost:${PORT}/uploads/${req.file.filename}`;
  db.query('UPDATE users SET avatar_url = ? WHERE id = ?', [avatarUrl, userId], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ status: 'success', message: 'Avatar berhasil diupdate!', avatar_url: avatarUrl });
  });
});

// ==========================================
// EVENTS: AMBIL SEMUA (aktif saja, untuk user)
// ==========================================
app.get('/api/events', (req, res) => {
  db.query('SELECT * FROM events WHERE is_active = 1 ORDER BY id DESC', (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ==========================================
// EVENTS: DETAIL + OPSI TIKET
// ==========================================
app.get('/api/events/:id', (req, res) => {
  db.query('SELECT * FROM events WHERE id = ?', [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0)
      return res.status(404).json({ message: 'Acara tidak ditemukan' });

    let event = results[0];
    const now = new Date();
    const deadline = event.early_bird_deadline
      ? new Date(event.early_bird_deadline)
      : new Date(0);
    const normalPrice = event.price;
    const earlyPrice = normalPrice * 0.7;
    const isEarlyActive = now <= deadline;

    event.ticket_options = [
      {
        type: 'Early Bird',
        price: earlyPrice,
        status: isEarlyActive ? 'AVAILABLE' : 'SOLD OUT',
        desc: 'Diskon 30% (Sisa waktu terbatas)',
      },
      {
        type: 'Normal',
        price: normalPrice,
        status: isEarlyActive ? 'LOCKED' : 'AVAILABLE',
        desc: 'Harga normal acara',
      },
    ];

    const eventDate = new Date(event.event_date);
    if (now > eventDate) {
      event.ticket_options.forEach((opt) => (opt.status = 'EXPIRED'));
    }

    res.json(event);
  });
});

// ==========================================
// TICKETS: CHECKOUT BULK (N tiket sekaligus, masing-masing QR unik)
// Biaya layanan flat per transaksi, bukan per tiket
// ==========================================
app.post('/api/tickets/checkout-bulk', async (req, res) => {
  const { user_id, event_name, event_date, count, unique_code, service_fee, ticket_price, total_amount } = req.body;
  const qty = parseInt(count) || 1;

  // Semua tiket dalam 1 pembelian share transaction_id yang sama
  const transactionId = crypto.randomUUID();

  const values = [];
  const ticketIds = [];

  for (let i = 0; i < qty; i++) {
    const ticketId = crypto.randomUUID();
    ticketIds.push(ticketId);
    values.push([
      ticketId,
      transactionId,
      user_id,
      event_name,
      event_date,
      'PENDING',
      unique_code || 0,
      i === 0 ? (service_fee || 2500) : 0,  // service_fee hanya di tiket pertama
      ticket_price || 0,                     // ticket_price SEMUA tiket diisi
      i === 0 ? (total_amount || 0) : 0,     // total_amount hanya di tiket pertama
    ]);
  }

  const sql = `
    INSERT INTO tickets (id, transaction_id, user_id, event_name, event_date, status, unique_code, service_fee, ticket_price, total_amount)
    VALUES ?
  `;

  db.query(sql, [values], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({
      success: true,
      message: `${qty} tiket berhasil dibuat, menunggu verifikasi admin!`,
      transaction_id: transactionId,
      ticket_ids: ticketIds,
      count: qty,
    });
  });
});

// ==========================================
// TICKETS: CHECKOUT SINGLE (tetap ada untuk kompatibilitas)
// ==========================================
app.post('/api/tickets/checkout', (req, res) => {
  const { user_id, event_name, event_date, unique_code, service_fee, ticket_price, total_amount } = req.body;
  const ticketId = crypto.randomUUID();
  const sql = `
    INSERT INTO tickets (id, user_id, event_name, event_date, status, unique_code, service_fee, ticket_price, total_amount)
    VALUES (?, ?, ?, ?, 'PENDING', ?, ?, ?, ?)
  `;
  db.query(sql, [ticketId, user_id, event_name, event_date, unique_code || 0, service_fee || 2500, ticket_price || 0, total_amount || 0], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Pesanan masuk bos, nunggu di-acc admin dlu!', ticket_id: ticketId });
  });
});

// ==========================================
// TICKETS: RIWAYAT USER (JOIN image_url dari events)
// ==========================================
app.get('/api/tickets/my-tickets/:user_id', (req, res) => {
  const sql = `
    SELECT tickets.*, events.image_url
    FROM tickets
    LEFT JOIN events ON tickets.event_name LIKE CONCAT(events.title, '%')
    WHERE tickets.user_id = ?
    ORDER BY tickets.created_at DESC
  `;
  db.query(sql, [req.params.user_id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ==========================================
// TICKETS: SCAN (endpoint lama untuk user/gate)
// ==========================================
app.post('/api/tickets/scan', (req, res) => {
  const { ticket_id } = req.body;
  db.query('SELECT * FROM tickets WHERE id = ?', [ticket_id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0)
      return res.status(404).json({ error: 'Tiket bodong kaga nemu bos!' });

    const ticket = results[0];
    if (ticket.status === 'PENDING')
      return res.status(400).json({
        error: 'Tiket belom lunas atau belom di-acc admin bos, kaga bisa masuk!',
        event_info: ticket.event_name,
      });
    if (ticket.status === 'USED')
      return res.status(400).json({
        error: 'Waduh, tiket udah pernah di-scan!',
        event_info: ticket.event_name,
      });

    db.query("UPDATE tickets SET status = 'USED' WHERE id = ?", [ticket_id], (err2) => {
      if (err2) return res.status(500).json({ error: err2.message });
      res.json({
        status: 'success',
        message: 'Scan berhasil, silakan masuk!',
        event_info: { name: ticket.event_name, date: ticket.event_date },
      });
    });
  });
});

// ==========================================
// GAME: SIMPAN REKOR
// ==========================================
app.post('/api/game/save-score', (req, res) => {
  const { user_id, username, game_name, level, best_time } = req.body;
  const sqlCheck =
    'SELECT * FROM game_scores WHERE user_id = ? AND game_name = ? AND level = ?';
  db.query(sqlCheck, [user_id, game_name, level], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0) {
      const sqlInsert =
        'INSERT INTO game_scores (user_id, username, game_name, level, best_time) VALUES (?, ?, ?, ?, ?)';
      db.query(sqlInsert, [user_id, username, game_name, level, best_time], (err2) => {
        if (err2) return res.status(500).json({ error: err2.message });
        res.json({ message: 'Rekor pertama disimpan!' });
      });
    } else {
      if (best_time < results[0].best_time) {
        db.query(
          'UPDATE game_scores SET best_time = ? WHERE id = ?',
          [best_time, results[0].id],
          (err2) => {
            if (err2) return res.status(500).json({ error: err2.message });
            res.json({ message: 'Rekor lama terpecahkan!' });
          }
        );
      } else {
        res.json({ message: 'Waktu tidak memecahkan rekor.' });
      }
    }
  });
});

// ==========================================
// FEEDBACK: AMBIL SEMUA
// ==========================================
app.get('/api/feedbacks', (req, res) => {
  db.query('SELECT * FROM tpm_feedbacks ORDER BY created_at DESC', (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ==========================================
// FEEDBACK: KIRIM BARU
// ==========================================
app.post('/api/feedbacks', (req, res) => {
  const { user_id, username, feedback, rating } = req.body;
  if (!feedback || feedback.trim() === '')
    return res.status(400).json({ error: 'Feedback tidak boleh kosong!' });

  const sql =
    'INSERT INTO tpm_feedbacks (user_id, username, feedback, rating) VALUES (?, ?, ?, ?)';
  db.query(sql, [user_id, username, feedback, rating || 5.0], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ status: 'success', message: 'Kritik & Saran berhasil dikirim!' });
  });
});

// ============================================================
// ==================== ADMIN ROUTES ==========================
// ============================================================

// ==========================================
// ADMIN: SEMUA TIKET — digroup per transaksi
// ==========================================
app.get('/api/admin/tickets', (req, res) => {
  // Ambil 1 row per transaksi (tiket pertama sebagai representasi)
  // Sertakan jumlah tiket dalam transaksi tersebut
  const sql = `
    SELECT
      t.transaction_id,
      t.id AS first_ticket_id,
      t.user_id,
      u.full_name AS user_name,
      t.event_name,
      t.event_date,
      t.status,
      t.unique_code,
      t.service_fee,
      t.ticket_price,
      t.total_amount,
      t.created_at,
      COUNT(t2.id) AS ticket_count
    FROM tickets t
    LEFT JOIN users u ON t.user_id = u.id
    LEFT JOIN tickets t2 ON (
      t2.transaction_id = t.transaction_id
      AND t2.transaction_id IS NOT NULL
    )
    WHERE t.service_fee > 0 OR t.transaction_id IS NULL
    GROUP BY
      COALESCE(t.transaction_id, t.id),
      t.id, t.user_id, u.full_name, t.event_name, t.event_date,
      t.status, t.unique_code, t.service_fee, t.ticket_price,
      t.total_amount, t.created_at
    ORDER BY t.created_at DESC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ==========================================
// ADMIN: TIKET PENDING — digroup per transaksi
// ==========================================
app.get('/api/admin/tickets/pending', (req, res) => {
  const sql = `
    SELECT
      t.transaction_id,
      t.id AS first_ticket_id,
      t.user_id,
      u.full_name AS user_name,
      t.event_name,
      t.event_date,
      t.status,
      t.unique_code,
      t.service_fee,
      t.ticket_price,
      t.total_amount,
      t.created_at,
      COUNT(t2.id) AS ticket_count
    FROM tickets t
    LEFT JOIN users u ON t.user_id = u.id
    LEFT JOIN tickets t2 ON (
      t2.transaction_id = t.transaction_id
      AND t2.transaction_id IS NOT NULL
    )
    WHERE t.status = 'PENDING'
      AND (t.service_fee > 0 OR t.transaction_id IS NULL)
    GROUP BY
      COALESCE(t.transaction_id, t.id),
      t.id, t.user_id, u.full_name, t.event_name, t.event_date,
      t.status, t.unique_code, t.service_fee, t.ticket_price,
      t.total_amount, t.created_at
    ORDER BY t.created_at ASC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ==========================================
// ADMIN: ACCEPT TRANSAKSI → semua tiket dalam transaksi jadi ACTIVE
// ==========================================
app.put('/api/admin/tickets/:id/accept', (req, res) => {
  db.query('SELECT transaction_id FROM tickets WHERE id = ?', [req.params.id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    if (rows.length === 0) return res.status(404).json({ error: 'Tiket tidak ditemukan' });

    const txId = rows[0].transaction_id;
    const sql = txId
      ? "UPDATE tickets SET status = 'ACTIVE' WHERE transaction_id = ? AND status = 'PENDING'"
      : "UPDATE tickets SET status = 'ACTIVE' WHERE id = ? AND status = 'PENDING'";
    const param = txId || req.params.id;

    db.query(sql, [param], (err2, result) => {
      if (err2) return res.status(500).json({ error: err2.message });
      if (result.affectedRows === 0)
        return res.status(404).json({ error: 'Tiket tidak ditemukan atau sudah diproses' });
      res.json({ message: `${result.affectedRows} tiket berhasil diaktifkan!`, affected: result.affectedRows });
    });
  });
});

// ==========================================
// ADMIN: DECLINE TRANSAKSI → semua tiket dalam transaksi jadi DECLINED
// ==========================================
app.put('/api/admin/tickets/:id/decline', (req, res) => {
  db.query('SELECT transaction_id FROM tickets WHERE id = ?', [req.params.id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    if (rows.length === 0) return res.status(404).json({ error: 'Tiket tidak ditemukan' });

    const txId = rows[0].transaction_id;
    const sql = txId
      ? "UPDATE tickets SET status = 'DECLINED' WHERE transaction_id = ? AND status = 'PENDING'"
      : "UPDATE tickets SET status = 'DECLINED' WHERE id = ? AND status = 'PENDING'";
    const param = txId || req.params.id;

    db.query(sql, [param], (err2, result) => {
      if (err2) return res.status(500).json({ error: err2.message });
      if (result.affectedRows === 0)
        return res.status(404).json({ error: 'Tiket tidak ditemukan atau sudah diproses' });
      res.json({ message: `${result.affectedRows} tiket berhasil ditolak`, affected: result.affectedRows });
    });
  });
});

// ==========================================
// ADMIN: SCAN QR → EXPIRED
// ==========================================
app.put('/api/admin/tickets/:id/scan', (req, res) => {
  db.query('SELECT * FROM tickets WHERE id = ?', [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0)
      return res.status(404).json({ error: 'Tiket tidak ditemukan, QR tidak valid!' });

    const ticket = results[0];
    if (ticket.status === 'PENDING')
      return res.status(400).json({
        error: 'Tiket belum diverifikasi admin, tidak bisa masuk!',
        event_info: ticket.event_name,
      });
    if (ticket.status === 'DECLINED')
      return res.status(400).json({
        error: 'Tiket ini sudah ditolak admin!',
        event_info: ticket.event_name,
      });
    if (ticket.status === 'EXPIRED')
      return res.status(400).json({
        error: 'Tiket sudah kadaluwarsa, sudah pernah digunakan!',
        event_info: ticket.event_name,
      });
    if (ticket.status !== 'ACTIVE')
      return res.status(400).json({
        error: `Status tiket tidak valid: ${ticket.status}`,
        event_info: ticket.event_name,
      });

    db.query("UPDATE tickets SET status = 'EXPIRED' WHERE id = ?", [req.params.id], (err2) => {
      if (err2) return res.status(500).json({ error: err2.message });
      res.json({
        status: 'success',
        message: 'Scan berhasil! Tiket telah digunakan.',
        event_info: { name: ticket.event_name, date: ticket.event_date },
      });
    });
  });
});

// ==========================================
// ADMIN: SEMUA EVENT (termasuk nonaktif)
// ==========================================
app.get('/api/admin/events', (req, res) => {
  db.query('SELECT * FROM events ORDER BY id DESC', (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ==========================================
// ADMIN: UPLOAD GAMBAR EVENT
// ==========================================
app.post('/api/admin/events/upload-image', upload.single('image'), (req, res) => {
  if (!req.file)
    return res.status(400).json({ error: 'Tidak ada file gambar yang dikirim!' });
  const PORT = process.env.PORT || 3000;
  const imageUrl = `http://localhost:${PORT}/uploads/${req.file.filename}`;
  res.json({ image_url: imageUrl });
});

// ==========================================
// ADMIN: TAMBAH EVENT
// ==========================================
app.post('/api/admin/events', (req, res) => {
  const {
    title, category, event_date, event_start_date, event_end_date,
    location, latitude, longitude,
    price, regular_start, regular_end,
    early_bird_price, early_bird_start, early_bird_end,
    image_url, description, is_active,
  } = req.body;

  if (!title || !category || !event_date || !location)
    return res.status(400).json({ error: 'Field title, category, event_date, location wajib diisi!' });

  const sql = `
    INSERT INTO events
      (title, category, event_date, event_start_date, event_end_date,
       location, latitude, longitude,
       price, regular_start, regular_end,
       early_bird_price, early_bird_start, early_bird_end,
       image_url, description, is_active)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;
  db.query(sql, [
    title, category, event_date, event_start_date || null, event_end_date || null,
    location, latitude || null, longitude || null,
    price || 0, regular_start || null, regular_end || null,
    early_bird_price || null, early_bird_start || null, early_bird_end || null,
    image_url || '', description || '', is_active ?? 1,
  ], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Event berhasil ditambahkan!', id: result.insertId });
  });
});

// ==========================================
// ADMIN: UPDATE EVENT
// ==========================================
app.put('/api/admin/events/:id', (req, res) => {
  const {
    title, category, event_date, event_start_date, event_end_date,
    location, latitude, longitude,
    price, regular_start, regular_end,
    early_bird_price, early_bird_start, early_bird_end,
    image_url, description, is_active,
  } = req.body;

  const sql = `
    UPDATE events SET
      title = ?, category = ?, event_date = ?, event_start_date = ?, event_end_date = ?,
      location = ?, latitude = ?, longitude = ?,
      price = ?, regular_start = ?, regular_end = ?,
      early_bird_price = ?, early_bird_start = ?, early_bird_end = ?,
      image_url = ?, description = ?, is_active = ?
    WHERE id = ?
  `;
  db.query(sql, [
    title, category, event_date, event_start_date || null, event_end_date || null,
    location, latitude || null, longitude || null,
    price || 0, regular_start || null, regular_end || null,
    early_bird_price || null, early_bird_start || null, early_bird_end || null,
    image_url || '', description || '', is_active ?? 1,
    req.params.id,
  ], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    if (result.affectedRows === 0)
      return res.status(404).json({ error: 'Event tidak ditemukan' });
    res.json({ message: 'Event berhasil diupdate!' });
  });
});

// ==========================================
// ADMIN: HAPUS EVENT
// ==========================================
app.delete('/api/admin/events/:id', (req, res) => {
  db.query('DELETE FROM events WHERE id = ?', [req.params.id], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    if (result.affectedRows === 0)
      return res.status(404).json({ error: 'Event tidak ditemukan' });
    res.json({ message: 'Event berhasil dihapus!' });
  });
});

// ==========================================
// ADMIN: REVENUE SUMMARY
// ==========================================
app.get('/api/admin/revenue', (req, res) => {
  // Revenue = total service_fee dari tiket ACTIVE + EXPIRED
  const sqlTotal = `
    SELECT
      COALESCE(SUM(CASE WHEN t.status IN ('ACTIVE','EXPIRED') THEN t.service_fee ELSE 0 END), 0) AS total_revenue,
      COUNT(CASE WHEN t.status IN ('ACTIVE','EXPIRED') THEN 1 END) AS total_sold,
      COUNT(CASE WHEN t.status = 'PENDING'  THEN 1 END) AS pending_count,
      COUNT(CASE WHEN t.status = 'ACTIVE'   THEN 1 END) AS active_count,
      COUNT(CASE WHEN t.status = 'EXPIRED'  THEN 1 END) AS expired_count,
      COUNT(CASE WHEN t.status = 'DECLINED' THEN 1 END) AS declined_count
    FROM tickets t
  `;
  const sqlPerEvent = `
    SELECT
      t.event_name,
      COUNT(*) AS ticket_count,
      COALESCE(SUM(t.service_fee), 0) AS revenue
    FROM tickets t
    WHERE t.status IN ('ACTIVE','EXPIRED')
    GROUP BY t.event_name
    ORDER BY revenue DESC
  `;
  const sqlRecent = `
    SELECT t.*, u.full_name AS user_name
    FROM tickets t
    LEFT JOIN users u ON t.user_id = u.id
    WHERE t.status IN ('ACTIVE','EXPIRED')
    ORDER BY t.created_at DESC
    LIMIT 20
  `;

  db.query(sqlTotal, (err, totalResult) => {
    if (err) return res.status(500).json({ error: err.message });
    db.query(sqlPerEvent, (err2, perEventResult) => {
      if (err2) return res.status(500).json({ error: err2.message });
      db.query(sqlRecent, (err3, recentResult) => {
        if (err3) return res.status(500).json({ error: err3.message });
        const s = totalResult[0];
        res.json({
          total_revenue: parseInt(s.total_revenue) || 0,
          total_sold: parseInt(s.total_sold) || 0,
          pending_count: parseInt(s.pending_count) || 0,
          active_count: parseInt(s.active_count) || 0,
          expired_count: parseInt(s.expired_count) || 0,
          declined_count: parseInt(s.declined_count) || 0,
          per_event: perEventResult,
          recent_transactions: recentResult,
        });
      });
    });
  });
});

// ==========================================
// JALANKAN SERVER
// ==========================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server berjalan di http://localhost:${PORT}`);
});
