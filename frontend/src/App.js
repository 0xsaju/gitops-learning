import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import Alert from '@mui/material/Alert';

const apiUrl = window.REACT_APP_API_URL || process.env.REACT_APP_API_URL || 'http://localhost:4000';
const api = axios.create({
  baseURL: apiUrl,
});

function App() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [token, setToken] = useState(localStorage.getItem('token') || '');
  const [user, setUser] = useState(null);
  const [message, setMessage] = useState('');
  const [messageType, setMessageType] = useState('error');

  useEffect(() => {
    if (token) fetchUser(token);
  }, [token]);

  const fetchUser = async (jwt) => {
    try {
      const res = await api.get('/api/user', {
        headers: { Authorization: `Bearer ${jwt}` },
      });
      setUser(res.data);
    } catch (err) {
      setUser(null);
    }
  };

  const handleRegister = async () => {
    try {
      await api.post('/api/register', { email, password });
      setMessage('Registration successful. Please log in.');
      setMessageType('success');
    } catch (err) {
      setMessage(err.response?.data?.message || 'Registration failed');
      setMessageType('error');
    }
  };

  const handleLogin = async () => {
    try {
      const res = await api.post('/api/login', { email, password });
      setToken(res.data.token);
      localStorage.setItem('token', res.data.token);
      setMessage('Login successful');
      setMessageType('success');
    } catch (err) {
      setMessage(err.response?.data?.message || 'Login failed');
      setMessageType('error');
    }
  };

  const handleLogout = () => {
    setToken('');
    setUser(null);
    localStorage.removeItem('token');
    setMessage('Logged out');
    setMessageType('info');
  };

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f5f6fa', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Card sx={{ minWidth: 350, maxWidth: 400, p: 2, boxShadow: 3 }}>
        <CardContent>
          <Typography variant="h4" component="h1" align="center" gutterBottom fontWeight={700} color="primary">
            Login System
          </Typography>
          {user ? (
            <Box textAlign="center">
              <Typography variant="h6" gutterBottom>Welcome, {user.email}!</Typography>
              <Button variant="contained" color="secondary" onClick={handleLogout} sx={{ mt: 2 }}>
                Logout
              </Button>
            </Box>
          ) : (
            <Box component="form" autoComplete="off" sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <TextField
                label="Email"
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                fullWidth
                required
              />
              <TextField
                label="Password"
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                fullWidth
                required
              />
              <Box sx={{ display: 'flex', gap: 2, mt: 1 }}>
                <Button variant="contained" color="primary" onClick={handleLogin} fullWidth>
                  Login
                </Button>
                <Button variant="outlined" color="primary" onClick={handleRegister} fullWidth>
                  Register
                </Button>
              </Box>
            </Box>
          )}
          {message && (
            <Alert severity={messageType} sx={{ mt: 3 }}>{message}</Alert>
          )}
        </CardContent>
      </Card>
    </Box>
  );
}

export default App; 