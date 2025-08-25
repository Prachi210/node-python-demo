const express = require('express');
const axios = require('axios');
const app = express();
const PORT = process.env.PORT || 8080;

// Python backend URL (change to service name in Kubernetes)
const PYTHON_API = process.env.PYTHON_API || "http://localhost:5000/api/hello";

app.get('/', async (req, res) => {
  try {
    const response = await axios.get(PYTHON_API);
    res.send(`<h1>Node.js Frontend</h1><p>${response.data.message}</p>`);
  } catch (error) {
    res.send(`<h1>Node.js Frontend</h1><p>Could not reach Python API</p>`);
  }
});

app.listen(PORT, () => console.log(`Node app running on port ${PORT}`));
