import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import api from "./routes/api";
import { PORT, MONGO_URI } from './env';
const app = express();
app.use(cors());
app.use(express.json());
app.use("/api", api);

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log("Mongo connected");
    app.listen(PORT, () =>
      console.log(`Server running on http://localhost:${PORT}`)
    );
  })
  .catch((err) => console.error(err));
