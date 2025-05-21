import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import https from "https";
import fs from "fs";
import path from "path";

import api from "./routes/api";
import { PORT, MONGO_URI, SSL_CERT, SSL_PRIVKEY } from "./env";

const app = express();
app.use(cors());
app.use(express.json());
app.use("/api", api);

// 🗝️ Path to SSL certs
const sslOptions = {
  key: fs.readFileSync(path.resolve(__dirname, SSL_PRIVKEY)),
  cert: fs.readFileSync(path.resolve(__dirname, SSL_CERT)),
};

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log("Mongo connected");
    https.createServer(sslOptions, app).listen(PORT, () => {
      console.log(`🚀 Server running securely on https://localhost:${PORT}`);
    });
  })
  .catch((err) => console.error(err));
