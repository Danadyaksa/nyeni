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

// KONEKSI DATABASE
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

// Helper: bangun path relatif untuk file yang diupload
// Simpan sebagai path relatif agar tidak terikat IP tertentu
// Flutter akan menggabungkan dengan serverHost terkini dari ApiConfig
function buildFileUrl(filename) {
  return `/uploads/${filename}`;
}

// AUTH: REGISTER
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

// AUTH: LOGIN (mengembalikan field 'role')
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

// AUTH: VERIFY PASSWORD (untuk enable biometric, tanpa update session)
app.post('/api/auth/verify-password', (req, res) => {
  const { email, password } = req.body;
  const sql = 'SELECT * FROM users WHERE email = ?';
  db.query(sql, [email], async (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0)
      return res.status(401).json({ error: 'Email tidak ditemukan!' });

    const user = results[0];
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ error: 'Password salah!' });

    // Hanya return success, tidak perlu token atau update session
    res.json({ message: 'Password benar!', verified: true });
  });
});

// USER: AMBIL PROFIL
app.get('/api/user/:id', (req, res) => {
  db.query('SELECT * FROM users WHERE id = ?', [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const user = results[0];
    if (user) delete user.password;
    res.json(user);
  });
});

// USER: UPDATE NAMA
app.post('/api/user/update-name', (req, res) => {
  const { id, full_name } = req.body;
  db.query('UPDATE users SET full_name = ? WHERE id = ?', [full_name, id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ status: 'success', message: 'Nama berhasil diubah!' });
  });
});

// USER: UPDATE EMAIL
app.post('/api/user/update-email', (req, res) => {
  const { id, email } = req.body;
  
  // Validasi format email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!email || !emailRegex.test(email)) {
    return res.status(400).json({ error: 'Format email tidak valid!' });
  }
  
  // Cek apakah email sudah digunakan user lain
  db.query('SELECT id FROM users WHERE email = ? AND id != ?', [email, id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length > 0) {
      return res.status(400).json({ error: 'Email sudah digunakan oleh user lain!' });
    }
    
    // Update email
    db.query('UPDATE users SET email = ? WHERE id = ?', [email, id], (err2) => {
      if (err2) return res.status(500).json({ error: err2.message });
      res.json({ status: 'success', message: 'Email berhasil diubah!' });
    });
  });
});

// USER: UPDATE PASSWORD
app.post('/api/user/update-password', async (req, res) => {
  const { id, password } = req.body;
  
  if (!password || password.length < 6) {
    return res.status(400).json({ error: 'Password minimal 6 karakter!' });
  }
  
  const hashedPassword = await bcrypt.hash(password, 10);
  db.query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ status: 'success', message: 'Password berhasil diubah!' });
  });
});

// USER: UPDATE PROGRESS GAME & XP
app.post('/api/user/update-progress', (req, res) => {
  const { id, total_xp, level, completed_levels_trivia, completed_levels_labirin } = req.body;
  const sql = `UPDATE users SET total_xp = ?, level = ?, completed_levels_trivia = ?, completed_levels_labirin = ? WHERE id = ?`;
  db.query(sql, [total_xp, level, completed_levels_trivia, completed_levels_labirin, id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ status: 'success', message: 'Progress berhasil disimpan!' });
  });
});

// MULTER: KONFIGURASI UPLOAD AVATAR
if (!fs.existsSync('./uploads')) fs.mkdirSync('./uploads');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) =>
    cb(null, 'avatar-' + Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// USER: UPLOAD AVATAR
app.post('/api/user/upload-avatar', upload.single('avatar'), (req, res) => {
  const userId = req.body.id;
  if (!req.file)
    return res.status(400).json({ error: 'Tidak ada file gambar yang dikirim!' });

  const avatarUrl = buildFileUrl(req.file.filename);
  db.query('UPDATE users SET avatar_url = ? WHERE id = ?', [avatarUrl, userId], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ status: 'success', message: 'Avatar berhasil diupdate!', avatar_url: avatarUrl });
  });
});

// EVENTS: AMBIL SEMUA (aktif saja, untuk user)
app.get('/api/events', (req, res) => {
  // Hanya tampilkan event yang:
  // 1. is_active = 1
  // 2. Belum expired (cek event_start_date dan event_end_date jika ada)
  // 3. Jika event_start_date dan event_end_date NULL, tetap tampilkan (event baru)
  const sql = `
    SELECT * FROM events 
    WHERE is_active = 1 
      AND (
        -- Jika ada event_start_date, cek apakah belum lewat
        (event_start_date IS NOT NULL AND event_start_date >= CURDATE())
        OR 
        -- Jika ada event_end_date, cek apakah belum lewat
        (event_end_date IS NOT NULL AND event_end_date >= CURDATE())
        OR
        -- Jika kedua field NULL, tetap tampilkan (event baru yang belum set tanggal)
        (event_start_date IS NULL AND event_end_date IS NULL)
      )
    ORDER BY id DESC
  `;
  
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// EVENTS: DETAIL + OPSI TIKET
app.get('/api/events/:id', (req, res) => {
  db.query('SELECT * FROM events WHERE id = ?', [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0)
      return res.status(404).json({ message: 'Acara tidak ditemukan' });

    let event = results[0];
    const now = new Date();
    
    // Cek apakah event sudah lewat (gunakan event_start_date dan event_end_date)
    const eventStartDate = event.event_start_date ? new Date(event.event_start_date) : null;
    const eventEndDate = event.event_end_date ? new Date(event.event_end_date) : eventStartDate;
    
    let isEventPassed = false;
    if (eventEndDate) {
      isEventPassed = now > eventEndDate;
    } else if (eventStartDate) {
      isEventPassed = now > eventStartDate;
    }
    
    // Jika event sudah lewat, return error untuk user (kecuali admin)
    if (isEventPassed && event.is_active === 1) {
      return res.status(410).json({ 
        message: 'Event sudah berakhir',
        event_name: event.title,
        event_date: event.event_date 
      });
    }
    
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
        type: 'Reguler',
        price: normalPrice,
        status: isEarlyActive ? 'LOCKED' : 'AVAILABLE',
        desc: 'Harga reguler acara',
      },
    ];

    if (isEventPassed) {
      event.ticket_options.forEach((opt) => (opt.status = 'EXPIRED'));
    }

    res.json(event);
  });
});

// TICKETS: CHECKOUT BULK (N tiket sekaligus, masing-masing QR unik)
// Biaya layanan flat per transaksi, bukan per tiket
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

// TICKETS: CHECKOUT SINGLE (tetap ada untuk kompatibilitas)
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

// TICKETS: RIWAYAT USER (JOIN image_url dari events)
app.get('/api/tickets/my-tickets/:user_id', (req, res) => {
  const sql = `
    SELECT tickets.*, events.image_url, events.event_date
    FROM tickets
    LEFT JOIN events ON (
      SUBSTRING_INDEX(tickets.event_name, ' - ', 1) = events.title
    )
    WHERE tickets.user_id = ?
    ORDER BY tickets.created_at DESC
  `;
  db.query(sql, [req.params.user_id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    
    // Auto-expire tiket yang event-nya sudah lewat
    const now = new Date();
    const ticketsToExpire = [];
    
    results.forEach(ticket => {
      // Hanya expire tiket yang statusnya ACTIVE dan event sudah lewat
      if (ticket.status === 'ACTIVE' && ticket.event_date) {
        const eventDate = new Date(ticket.event_date);
        if (now > eventDate) {
          ticketsToExpire.push(ticket.id);
          ticket.status = 'EXPIRED'; // Update di response
        }
      }
    });
    
    // Update database untuk tiket yang expired
    if (ticketsToExpire.length > 0) {
      const updateSql = `UPDATE tickets SET status = 'EXPIRED' WHERE id IN (?)`;
      db.query(updateSql, [ticketsToExpire], (updateErr) => {
        if (updateErr) console.error('Error auto-expiring tickets:', updateErr);
      });
    }
    
    res.json(results);
  });
});

// TICKETS: SCAN (endpoint lama untuk user/gate)
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

// FEEDBACK: AMBIL SEMUA
app.get('/api/feedbacks', (req, res) => {
  db.query('SELECT * FROM tpm_feedbacks ORDER BY created_at DESC', (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// FEEDBACK: KIRIM BARU
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

// Admin: Semua tiket (digroup per transaksi)
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

// ADMIN: TIKET PENDING — digroup per transaksi
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

// ADMIN: ACCEPT TRANSAKSI → semua tiket dalam transaksi jadi ACTIVE
// ADMIN: ACCEPT TRANSAKSI → semua tiket dalam transaksi jadi ACTIVE + KASIH XP KE USER
app.put('/api/admin/tickets/:id/accept', (req, res) => {
  // Step 1: Ambil info tiket & transaction_id
  db.query('SELECT transaction_id, user_id FROM tickets WHERE id = ?', [req.params.id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    if (rows.length === 0) return res.status(404).json({ error: 'Tiket tidak ditemukan' });

    const txId = rows[0].transaction_id;
    const userId = rows[0].user_id;
    const sql = txId
      ? "UPDATE tickets SET status = 'ACTIVE' WHERE transaction_id = ? AND status = 'PENDING'"
      : "UPDATE tickets SET status = 'ACTIVE' WHERE id = ? AND status = 'PENDING'";
    const param = txId || req.params.id;

    // Step 2: Update status tiket jadi ACTIVE
    db.query(sql, [param], (err2, result) => {
      if (err2) return res.status(500).json({ error: err2.message });
      if (result.affectedRows === 0)
        return res.status(404).json({ error: 'Tiket tidak ditemukan atau sudah diproses' });
      
      const ticketCount = result.affectedRows;

      // Step 3: Kasih XP ke user (150 XP per tiket)
      const xpReward = ticketCount * 150;
      
      db.query('SELECT total_xp, level, completed_levels_trivia, completed_levels_labirin FROM users WHERE id = ?', [userId], (err3, userRows) => {
        if (err3 || userRows.length === 0) {
          // Kalau gagal ambil user data, tetap return success (tiket sudah aktif)
          return res.json({ 
            message: `${ticketCount} tiket berhasil diaktifkan!`, 
            affected: ticketCount,
            xp_given: 0,
            note: 'XP tidak bisa diberikan (user tidak ditemukan)'
          });
        }

        const user = userRows[0];
        const currentXp = user.total_xp || 0;
        const newXp = currentXp + xpReward;

        // Hitung level baru berdasarkan XP
        let newLevel = 1;
        if (newXp >= 2700) newLevel = 10;
        else if (newXp >= 2200) newLevel = 9;
        else if (newXp >= 1750) newLevel = 8;
        else if (newXp >= 1350) newLevel = 7;
        else if (newXp >= 1000) newLevel = 6;
        else if (newXp >= 700) newLevel = 5;
        else if (newXp >= 450) newLevel = 4;
        else if (newXp >= 250) newLevel = 3;
        else if (newXp >= 100) newLevel = 2;

        // Update XP & level user
        db.query(
          'UPDATE users SET total_xp = ?, level = ? WHERE id = ?',
          [newXp, newLevel, userId],
          (err4) => {
            if (err4) {
              console.error('Error updating XP:', err4);
              return res.json({ 
                message: `${ticketCount} tiket berhasil diaktifkan!`, 
                affected: ticketCount,
                xp_given: 0,
                note: 'XP tidak bisa diberikan (error update)'
              });
            }

            res.json({ 
              message: `${ticketCount} tiket berhasil diaktifkan! User dapat +${xpReward} XP 🎉`, 
              affected: ticketCount,
              xp_given: xpReward,
              new_xp: newXp,
              new_level: newLevel
            });
          }
        );
      });
    });
  });
});

// ADMIN: DECLINE TRANSAKSI → semua tiket dalam transaksi jadi DECLINED
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

// ADMIN: SCAN QR → EXPIRED
app.put('/api/admin/tickets/:id/scan', (req, res) => {
  // Join dengan events untuk mendapatkan event_date
  const sql = `
    SELECT tickets.*, events.event_date
    FROM tickets
    LEFT JOIN events ON (
      SUBSTRING_INDEX(tickets.event_name, ' - ', 1) = events.title
    )
    WHERE tickets.id = ?
  `;
  
  db.query(sql, [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0)
      return res.status(404).json({ error: 'Tiket tidak ditemukan, QR tidak valid!' });

    const ticket = results[0];
    
    // Cek apakah event sudah lewat
    if (ticket.event_date) {
      const now = new Date();
      const eventDate = new Date(ticket.event_date);
      if (now > eventDate) {
        // Auto-expire tiket jika event sudah lewat
        db.query("UPDATE tickets SET status = 'EXPIRED' WHERE id = ?", [req.params.id], () => {});
        return res.status(400).json({
          error: 'Tiket sudah kadaluwarsa, event sudah lewat!',
          event_info: ticket.event_name,
          event_date: ticket.event_date,
        });
      }
    }
    
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

// ADMIN: SEMUA EVENT (termasuk nonaktif)
app.get('/api/admin/events', (req, res) => {
  db.query('SELECT * FROM events ORDER BY id DESC', (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    
    // Tambahkan flag is_expired untuk setiap event
    const now = new Date();
    results.forEach(event => {
      const eventStartDate = event.event_start_date ? new Date(event.event_start_date) : null;
      const eventEndDate = event.event_end_date ? new Date(event.event_end_date) : eventStartDate;
      
      if (eventEndDate) {
        event.is_expired = now > eventEndDate;
      } else if (eventStartDate) {
        event.is_expired = now > eventStartDate;
      } else {
        event.is_expired = false;
      }
    });
    
    res.json(results);
  });
});

// ADMIN: UPLOAD GAMBAR EVENT
app.post('/api/admin/events/upload-image', upload.single('image'), (req, res) => {
  if (!req.file)
    return res.status(400).json({ error: 'Tidak ada file gambar yang dikirim!' });
  const imageUrl = buildFileUrl(req.file.filename);
  res.json({ image_url: imageUrl });
});

// ADMIN: TAMBAH EVENT
app.post('/api/admin/events', (req, res) => {
  const {
    title, category, event_date, event_start_date, event_end_date,
    open_time, close_time,
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
       open_time, close_time,
       location, latitude, longitude,
       price, regular_start, regular_end,
       early_bird_price, early_bird_start, early_bird_end,
       image_url, description, is_active)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;
  db.query(sql, [
    title, category, event_date, event_start_date || null, event_end_date || null,
    open_time || null, close_time || null,
    location, latitude || null, longitude || null,
    price || 0, regular_start || null, regular_end || null,
    early_bird_price || null, early_bird_start || null, early_bird_end || null,
    image_url || '', description || '', is_active ?? 1,
  ], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Event berhasil ditambahkan!', id: result.insertId });
  });
});

// ADMIN: UPDATE EVENT
app.put('/api/admin/events/:id', (req, res) => {
  const {
    title, category, event_date, event_start_date, event_end_date,
    open_time, close_time,
    location, latitude, longitude,
    price, regular_start, regular_end,
    early_bird_price, early_bird_start, early_bird_end,
    image_url, description, is_active,
  } = req.body;

  const sql = `
    UPDATE events SET
      title = ?, category = ?, event_date = ?, event_start_date = ?, event_end_date = ?,
      open_time = ?, close_time = ?,
      location = ?, latitude = ?, longitude = ?,
      price = ?, regular_start = ?, regular_end = ?,
      early_bird_price = ?, early_bird_start = ?, early_bird_end = ?,
      image_url = ?, description = ?, is_active = ?
    WHERE id = ?
  `;
  db.query(sql, [
    title, category, event_date, event_start_date || null, event_end_date || null,
    open_time || null, close_time || null,
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

// ADMIN: HAPUS EVENT
app.delete('/api/admin/events/:id', (req, res) => {
  // Step 1: Ambil data event untuk cek tanggal
  db.query('SELECT * FROM events WHERE id = ?', [req.params.id], (err, eventResult) => {
    if (err) return res.status(500).json({ error: err.message });
    if (eventResult.length === 0) return res.status(404).json({ error: 'Event tidak ditemukan' });
    
    const event = eventResult[0];
    const now = new Date();
    
    // Cek apakah event sudah lewat
    const eventStartDate = event.event_start_date ? new Date(event.event_start_date) : null;
    const eventEndDate = event.event_end_date ? new Date(event.event_end_date) : eventStartDate;
    
    let isEventPassed = false;
    if (eventEndDate) {
      isEventPassed = now > eventEndDate;
    } else if (eventStartDate) {
      isEventPassed = now > eventStartDate;
    }
    
    // Step 2: Cek apakah ada tiket ACTIVE/PENDING untuk event ini
    db.query(
      `SELECT COUNT(*) as ticket_count 
       FROM tickets 
       WHERE SUBSTRING_INDEX(event_name, ' - ', 1) = ?
         AND status IN ('ACTIVE', 'PENDING')`,
      [event.title],
      (err2, countResult) => {
        if (err2) return res.status(500).json({ error: err2.message });
        
        const ticketCount = countResult[0]?.ticket_count || 0;
        
        // Step 3: Jika ada tiket aktif DAN event belum lewat, tolak delete
        if (ticketCount > 0 && !isEventPassed) {
          return res.status(400).json({ 
            error: `Tidak bisa menghapus event! Masih ada ${ticketCount} tiket aktif/pending dan event belum berakhir.`,
            suggestion: 'Tunggu sampai event selesai atau gunakan fitur nonaktifkan event (is_active = 0).'
          });
        }
        
        // Step 4: Jika event sudah lewat ATAU tidak ada tiket aktif, boleh hapus
        db.query('DELETE FROM events WHERE id = ?', [req.params.id], (err3, result) => {
          if (err3) return res.status(500).json({ error: err3.message });
          if (result.affectedRows === 0)
            return res.status(404).json({ error: 'Event tidak ditemukan' });
          
          let message = 'Event berhasil dihapus!';
          if (ticketCount > 0 && isEventPassed) {
            message += ` (Event sudah berakhir, ${ticketCount} tiket akan tetap tersimpan di riwayat user)`;
          }
          
          res.json({ message });
        });
      }
    );
  });
});

// ADMIN: REVENUE SUMMARY
// ADMIN: REVENUE SUMMARY
app.get('/api/admin/revenue', (req, res) => {

  const sqlTotal = `
    SELECT
      COUNT(CASE WHEN t.status IN ('ACTIVE','EXPIRED','USED') THEN 1 END) AS total_sold,
      COUNT(CASE WHEN t.status = 'PENDING'  THEN 1 END) AS pending_count,
      COUNT(CASE WHEN t.status = 'ACTIVE'   THEN 1 END) AS active_count,
      COUNT(CASE WHEN t.status = 'EXPIRED'  THEN 1 END) AS expired_count,
      COUNT(CASE WHEN t.status = 'DECLINED' THEN 1 END) AS declined_count,
      (
        SELECT COALESCE(SUM(tx_fee), 0) FROM (
          SELECT MAX(service_fee) AS tx_fee
          FROM tickets
          WHERE status IN ('ACTIVE','EXPIRED','USED')
            AND service_fee > 0
          GROUP BY COALESCE(transaction_id, id)
        ) AS fees
      ) AS total_revenue
    FROM tickets t
  `;

  // Revenue per event — 1 baris per event, hitung transaksi unik & tiket
  const sqlPerEvent = `
    SELECT
      sub.event_name,
      COUNT(*) AS transaction_count,
      SUM(sub.ticket_count) AS ticket_count,
      SUM(sub.tx_fee) AS revenue
    FROM (
      SELECT
        t.event_name,
        COALESCE(t.transaction_id, t.id) AS tx_id,
        COUNT(*) AS ticket_count,
        MAX(t.service_fee) AS tx_fee
      FROM tickets t
      WHERE t.status IN ('ACTIVE','EXPIRED','USED')
        AND t.service_fee > 0
      GROUP BY COALESCE(t.transaction_id, t.id), t.event_name
    ) AS sub
    GROUP BY sub.event_name
    ORDER BY revenue DESC
  `;

  // Riwayat transaksi — 1 baris per transaction_id
  // Pakai subquery: ambil tiket "utama" (service_fee > 0 atau yang pertama)
  const sqlRecent = `
    SELECT
      tx.tx_id,
      tx.event_name,
      tx.user_name,
      tx.service_fee,
      tx.total_amount,
      tx.unique_code,
      tx.ticket_price,
      tx.created_at,
      tx.ticket_count
    FROM (
      SELECT
        COALESCE(t.transaction_id, t.id) AS tx_id,
        t.event_name,
        u.full_name AS user_name,
        MAX(t.service_fee) AS service_fee,
        MAX(t.total_amount) AS total_amount,
        MAX(t.unique_code) AS unique_code,
        MAX(t.ticket_price) AS ticket_price,
        MIN(t.created_at) AS created_at,
        COUNT(*) AS ticket_count
      FROM tickets t
      LEFT JOIN users u ON t.user_id = u.id
      WHERE t.status IN ('ACTIVE','EXPIRED','USED')
      GROUP BY COALESCE(t.transaction_id, t.id), t.event_name, u.full_name
    ) AS tx
    ORDER BY tx.created_at DESC
    LIMIT 30
  `;

  // Revenue per bulan — hitung fee per transaksi (bukan per tiket)
  const sqlMonthly = `
    SELECT
      DATE_FORMAT(created_at, '%Y-%m') AS month,
      DATE_FORMAT(created_at, '%b %Y') AS month_label,
      COUNT(*) AS transaction_count,
      SUM(ticket_count) AS ticket_count,
      SUM(tx_fee) AS revenue
    FROM (
      SELECT
        COALESCE(t.transaction_id, t.id) AS tx_id,
        MIN(t.created_at) AS created_at,
        COUNT(*) AS ticket_count,
        CASE WHEN t.transaction_id IS NOT NULL THEN MAX(t.service_fee) ELSE 2500 END AS tx_fee
      FROM tickets t
      WHERE t.status IN ('ACTIVE','EXPIRED','USED')
        AND t.created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
      GROUP BY COALESCE(t.transaction_id, t.id)
    ) AS per_tx
    GROUP BY DATE_FORMAT(created_at, '%Y-%m'), DATE_FORMAT(created_at, '%b %Y')
    ORDER BY month ASC
  `;

  db.query(sqlTotal, (err, totalResult) => {
    if (err) return res.status(500).json({ error: err.message });
    db.query(sqlPerEvent, (err2, perEventResult) => {
      if (err2) return res.status(500).json({ error: err2.message });
      db.query(sqlRecent, (err3, recentResult) => {
        if (err3) return res.status(500).json({ error: err3.message });
        db.query(sqlMonthly, (err4, monthlyResult) => {
          if (err4) return res.status(500).json({ error: err4.message });
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
            monthly: monthlyResult,
          });
        });
      });
    });
  });
});

// AI RECOMMENDATION SYSTEM
app.get('/api/recommendations/:userId', (req, res) => {
  const userId = req.params.userId;
  console.log(`📊 Fetching recommendations for user ${userId}`);

  // Step 1: Analisis kategori favorit dari riwayat pembelian
  // Karena tickets tidak punya event_id, kita extract base event name
  const categoryQuery = `
    SELECT e.category, COUNT(*) as count
    FROM tickets t
    JOIN events e ON (
      t.event_name LIKE CONCAT(e.title, '%')
      OR e.title LIKE CONCAT(SUBSTRING_INDEX(t.event_name, ' - ', 1), '%')
    )
    WHERE t.user_id = ? AND t.status IN ('ACTIVE', 'USED')
    GROUP BY e.category
    ORDER BY count DESC
    LIMIT 1
  `;

  db.query(categoryQuery, [userId], (err, categoryResults) => {
    if (err) {
      console.error('❌ Category query error:', err.message);
      return res.status(500).json({ error: err.message });
    }

    console.log('📈 Category results:', categoryResults);

    // Step 2: Cek apakah user punya riwayat
    if (categoryResults.length > 0 && categoryResults[0].category) {
      const favoriteCategory = categoryResults[0].category;
      console.log(`✅ Favorite category: ${favoriteCategory}`);

      // Get 5 events dari kategori favorit
      const recommendQuery = `
        SELECT * FROM events
        WHERE category = ? AND is_active = 1
        ORDER BY created_at DESC
        LIMIT 5
      `;

      db.query(recommendQuery, [favoriteCategory], (err, events) => {
        if (err) {
          console.error('❌ Recommend query error:', err.message);
          return res.status(500).json({ error: err.message });
        }

        console.log(`✅ Found ${events.length} events for category ${favoriteCategory}`);

        return res.json({
          hasHistory: true,
          category: favoriteCategory,
          message: `Berdasarkan riwayat pembelian kamu, BAGAS merekomendasikan event kategori ${favoriteCategory}`,
          events: events,
        });
      });
    } else {
      // User belum punya riwayat - fallback ke event terbaru
      console.log('ℹ️ No purchase history, using fallback');
      getFallbackRecommendations(res);
    }
  });
});

// Helper function for fallback recommendations
function getFallbackRecommendations(res) {
  const fallbackQuery = `
    SELECT * FROM events
    WHERE is_active = 1
    ORDER BY created_at DESC
    LIMIT 5
  `;

  db.query(fallbackQuery, (err, events) => {
    if (err) {
      console.error('❌ Fallback query error:', err.message);
      return res.status(500).json({ error: err.message });
    }

    console.log(`✅ Fallback: Found ${events.length} latest events`);

    return res.json({
      hasHistory: false,
      category: null,
      message: 'BAGAS merekomendasikan event terbaru minggu ini:',
      events: events,
    });
  });
}

// JALANKAN SERVER
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server berjalan di http://localhost:${PORT}`);
});
