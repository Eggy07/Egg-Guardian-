const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// --- MySQL Connection ---
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'egg_guardian'
});

db.connect((err) => {
  if (err) {
    console.error('❌ Database connection failed:', err.message);
  } else {
    console.log('✅ Connected to MySQL database.');
  }
});

// --- Multer Setup (must be BEFORE routes using it) ---
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = './uploads';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir);
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    cb(null, `user_${req.params.id || Date.now()}${ext}`);
  },
});
const upload = multer({ storage });

// --- Test Route ---
app.get('/test', (req, res) => {
  res.json({ success: true, message: 'Server connection successful!' });
});

// --- Register ---
app.post('/register', async (req, res) => {
  const { username, email, password } = req.body;
  const hash = await bcrypt.hash(password, 10);

  db.query(
    'INSERT INTO user (username, email, password, role) VALUES (?, ?, ?, ?)',
    [username, email, hash, 'user'],
    (err, result) => {
      if (err) return res.status(400).json({ error: err.sqlMessage });
      res.json({ success: true, insertedId: result.insertId });
    }
  );
});

// --- Login ---
app.post('/login', (req, res) => {
  const { email, password } = req.body;

  db.query('SELECT * FROM user WHERE email = ?', [email], async (err, results) => {
    if (err || results.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = results[0];
    const match = await bcrypt.compare(password, user.password);

    if (!match) return res.status(401).json({ error: 'Invalid credentials' });

    res.json({
      success: true,
      user_id: user.user_id,
      username: user.username,
      email: user.email,
      role: user.role
    });
  });
});

// --- Get Single User ---
app.get('/user/:id', (req, res) => {
  const userId = req.params.id;
  db.query('SELECT user_id, username, email, role, profile_image FROM user WHERE user_id = ?', [userId], (err, results) => {
    if (err) return res.status(500).json({ error: err.sqlMessage });
    if (results.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json(results[0]);
  });
});

// --- Get All Users ---
app.get('/user', (req, res) => {
  db.query('SELECT user_id, username, email, role, profile_image FROM user', (err, results) => {
    if (err) return res.status(500).json({ error: err.sqlMessage });
    res.json(results);
  });
});

// --- Update User (username, email, role, profile_image) ---
app.put('/user/:id', upload.single('profile_image'), async (req, res) => {
  try {
    const userId = req.params.id;
    const { username, email, role } = req.body;

    if (!username || !email) {
      return res.status(400).json({ success: false, error: 'Username and email are required' });
    }

    let profileImagePath = null;
    if (req.file) profileImagePath = req.file.path;

    const query = `
      UPDATE user 
      SET username = ?, email = ?, role = ?, profile_image = COALESCE(?, profile_image)
      WHERE user_id = ?
    `;

    db.query(query, [username, email, role, profileImagePath, userId], (err, result) => {
      if (err) return res.status(500).json({ success: false, error: err.sqlMessage });
      res.json({ success: true, message: 'User updated successfully', updatedId: userId });
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// --- Delete User ---
app.delete('/user/:id', (req, res) => {
  db.query('DELETE FROM user WHERE user_id = ?', [req.params.id], (err, result) => {
    if (err) return res.status(400).json({ error: err.sqlMessage });
    res.json({ success: true });
  });
});

// --- Messaging System ---
// Add message (user sends)
app.post('/messages', (req, res) => {
  const { user_id, subject, message } = req.body;
  if (!user_id || !subject || !message) {
    return res.status(400).json({ success: false, error: 'Missing fields' });
  }

  db.query('INSERT INTO concern_messages (user_id, subject, message) VALUES (?, ?, ?)', [user_id, subject, message], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err });
    res.json({ success: true, message_id: result.insertId });
  });
});

// Get all messages (admin)
app.get('/messages', (req, res) => {
  const sql = `
    SELECT m.message_id, m.user_id, u.username, m.subject, m.message, m.admin_response
    FROM concern_messages m
    JOIN user u ON m.user_id = u.user_id
    ORDER BY m.message_id DESC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.sqlMessage });
    res.json(results);
  });
});

// Fetch messages for a user
app.get('/messages/:userId', (req, res) => {
  const { userId } = req.params;
  db.query(
    'SELECT m.message_id, m.user_id, u.username, m.subject, m.message, m.admin_response ' +
    'FROM concern_messages m ' +
    'JOIN user u ON m.user_id = u.user_id ' +
    'WHERE m.user_id = ? ' +
    'ORDER BY m.message_id DESC',
    [userId],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.sqlMessage });
      res.json(results);
    }
  );
});

// Admin responds to message
app.put('/messages/respond/:id', (req, res) => {
  const { id } = req.params;
  const { adminResponse } = req.body;

  db.query(
    'UPDATE concern_messages SET admin_response = ? WHERE message_id = ?',
    [adminResponse, id],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.sqlMessage });
      if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Message not found' });
      res.json({ success: true });
    }
  );
});

// --- Detection Data ---
app.post('/detection', (req, res) => {
  const { total_eggs, fertile, infertile, timestamp } = req.body;
  db.query('INSERT INTO detection (total_eggs, fertile, infertile, timestamp) VALUES (?, ?, ?, ?)',
    [total_eggs, fertile, infertile, timestamp],
    (err) => {
      if (err) return res.status(500).json({ error: err.sqlMessage });
      res.json({ success: true });
    }
  );
});

// --- Latest Detection ---
app.get('/detection/latest', (req, res) => {
  db.query('SELECT * FROM detection ORDER BY timestamp DESC LIMIT 1', (err, results) => {
    if (err) return res.status(500).json({ error: err.sqlMessage });
    if (results.length === 0) return res.json({ total_eggs: 0, fertile: 0, infertile: 0, timestamp: null });
    res.json(results[0]);
  });
});

// --- Egg History ---
app.post('/history', (req, res) => {
  const { batch, status, image, timestamp } = req.body;
  db.query(
    'INSERT INTO egg_history (batch, status, image, timestamp) VALUES (?, ?, ?, ?)',
    [batch, status, image || 'assets/placeholder.png', timestamp],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.sqlMessage });
      res.json({ success: true, insertedId: result.insertId });
    }
  );
});

// --- Start Server ---
app.listen(3000, '0.0.0.0', () => {
  console.log('API running on http://0.0.0.0:3000');
});
