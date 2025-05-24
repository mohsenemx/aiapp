// src/controllers/authController.ts
import { RequestHandler } from "express";
import { User, IUserDocument } from "../models/User";
import { v4 as uuidv4 } from "uuid";
import axios from "axios";
import { API_IR_API_KEY } from "../env";

const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes

const generateOtp = (): string =>
  Math.floor(10000 + Math.random() * 90000).toString();

const sendOtpSms = async (phone: string, code: string) => {
  await axios.post(
    "https://s.api.ir/api/sw1/SmsOTP",
    { code, mobile: phone },
    { headers: { Authorization: `Bearer ${API_IR_API_KEY}` } }
  );
};

// ── SEND OTP ─────────────────────────────────────────────
export const sendOtp: RequestHandler = async (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    res.status(400).json({ error: "phone required" });
    return;
  }

  const code = generateOtp();
  const expiresAt = new Date(Date.now() + OTP_TTL_MS);
  const newUuid = uuidv4();

  // Upsert user by phone, assign a uuid on first insert
  const user = (await User.findOneAndUpdate(
    { phone },
    {
      $set: { otp: code, otpExpiresAt: expiresAt },
      $setOnInsert: { stars: 1000, uuid: newUuid },
    },
    { upsert: true, new: true }
  )) as IUserDocument;

  try {
    await sendOtpSms(phone, code);
    res.json({ success: true, expiresIn: OTP_TTL_MS / 1000 });
    return;
  } catch (err: any) {
    console.error("SMS failed:", err.response?.data || err.message);
    res.status(500).json({ error: "SMS failed" });
    return;
  }
};

// ── VERIFY OTP ───────────────────────────────────────────
export const verifyOtp: RequestHandler = async (req, res) => {
  const { phone, otp } = req.body;
  if (!phone || !otp) {
    res.status(400).json({ error: "phone and otp required" });
    return;
  }

  const user = (await User.findOne({ phone })) as IUserDocument | null;
  if (
    !user ||
    user.otp !== otp ||
    !user.otpExpiresAt ||
    user.otpExpiresAt < new Date()
  ) {
    res.status(400).json({ error: "invalid or expired otp" });
    return;
  }

  // Issue a fresh UUID
  const newUuid = uuidv4();
  user.uuid = newUuid;
  user.otp = undefined;
  user.otpExpiresAt = undefined;
  await user.save();

  res.json({ userId: newUuid });
  return;
};

// ── RESEND OTP ───────────────────────────────────────────
export const resendOtp: RequestHandler = async (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    res.status(400).json({ error: "phone required" });
    return;
  }

  const code = generateOtp();
  const expiresAt = new Date(Date.now() + OTP_TTL_MS);

  await User.findOneAndUpdate(
    { phone },
    { otp: code, otpExpiresAt: expiresAt },
    { new: true }
  );

  try {
    await sendOtpSms(phone, code);
    res.json({ success: true, expiresIn: OTP_TTL_MS / 1000 });
    return;
  } catch (err: any) {
    console.error("SMS failed:", err.response?.data || err.message);
    res.status(500).json({ error: "SMS failed" });
    return;
  }
};

// ── GET STARS ────────────────────────────────────────────
export const getStars: RequestHandler = async (req, res) => {
  const { userId } = req.params;
  const user = (await User.findOne({ uuid: userId })) as IUserDocument | null;
  if (!user) {
    res.status(404).json({ error: "User not found" });
    return;
  }

  res.json({ stars: user.stars });
  return;
};

// ── GUEST (UUID-only signup) ────────────────────────────
export const guest: RequestHandler = async (req, res) => {
  const { uuid } = req.body;
  if (!uuid) {
    res.status(400).json({ error: "uuid required" });
    return;
  }

  let user = (await User.findOne({ uuid })) as IUserDocument | null;
  if (user) {
    res.json({ userId: user.uuid });
    return;
  }

  // Create brand-new guest user
  user = new User({
    uuid,
    stars: 1000,
  });
  await user.save();

  res.status(201).json({ userId: user.uuid });
  return;
};
