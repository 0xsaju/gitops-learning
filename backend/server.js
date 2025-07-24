require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const fs = require('fs');

const app = express();
app.use(cors({ origin: process.env.FRONTEND_URL, credentials: true }));
app.use(express.json());

const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 3306,
  ssl: {
    ca: fs.readFileSync('/DigiCertGlobalRootCA.crt.pem')
  }
};

let db;
async function connectDB() {
  db = await mysql.createConnection(dbConfig);
  await db.execute(`CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL
  )`);
}

async function connectDBWithRetry(retries = 10, delay = 3000) {
  for (let i = 0; i < retries; i++) {
    try {
      await connectDB();
      console.log('Connected to DB');
      return;
    } catch (err) {
      console.error(`DB connection failed (attempt ${i + 1}/${retries}):`, err.message);
      if (i < retries - 1) {
        await new Promise(res => setTimeout(res, delay));
      } else {
        throw err;
      }
    }
  }
}

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';

function generateToken(user) {
  return jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '1h' });
}

function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'No token' });
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Invalid token' });
    req.user = user;
    next();
  });
}

app.post('/api/register', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ message: 'Email and password required' });
  try {
    const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length > 0) return res.status(400).json({ message: 'User exists' });
    const hashed = await bcrypt.hash(password, 10);
    await db.execute('INSERT INTO users (email, password) VALUES (?, ?)', [email, hashed]);
    res.status(201).json({ message: 'User registered' });
  } catch (err) {
    console.error('Registration error:', err); // Log the error for debugging
    res.status(500).json({ message: 'Error registering user' });
  }
});

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ message: 'Email and password required' });
  try {
    const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) return res.status(400).json({ message: 'Invalid credentials' });
    const user = users[0];
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(400).json({ message: 'Invalid credentials' });
    const token = generateToken(user);
    res.json({ token });
  } catch (err) {
    res.status(500).json({ message: 'Error logging in' });
  }
});

app.get('/api/user', authMiddleware, async (req, res) => {
  try {
    const [users] = await db.execute('SELECT id, email FROM users WHERE id = ?', [req.user.id]);
    if (users.length === 0) return res.status(404).json({ message: 'User not found' });
    res.json(users[0]);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching user' });
  }
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

connectDBWithRetry().then(() => {
  app.listen(process.env.PORT || 4000, () => {
    console.log('Backend running on port', process.env.PORT || 4000);
  });
}); 