import express from "express";
import mongoose from "mongoose";
import dotenv from "dotenv";
import cors from "cors";
import api from "./routes/api";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());
app.use("/api", api);

mongoose
  .connect(process.env.MONGO_URI!)
  .then(() => {
    console.log("Mongo connected");
    app.listen(process.env.PORT, () =>
      console.log(`Server running on http://localhost:${process.env.PORT}`)
    );
  })
  .catch((err) => console.error(err));
