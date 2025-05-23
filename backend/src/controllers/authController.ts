// src/controllers/authController.ts
import { RequestHandler } from "express";
import { User, IUserDocument } from "../models/User";
import mongoose from "mongoose";
import axios from "axios";
import { API_IR_API_KEY } from "../env";

const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes

const generateOtp = (): string => {
  return Math.floor(10000 + Math.random() * 90000).toString(); // 5-digit code
};

const sendOtpSms = async (phone: string, code: string) => {
  try {
    await axios.post(
      "https://s.api.ir/api/sw1/SmsOTP",
      { code, mobile: phone },
      {
        headers: {
          Authorization: `Bearer ${API_IR_API_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (error: any) {
    console.error("SMS sending failed:", error.response?.data || error.message);
    throw new Error("Failed to send OTP");
  }
};
// POST /auth/send-otp
export const sendOtp: RequestHandler = async (req, res) => {
  const { phone } = req.body;
  if (!phone) res.status(400).json({ error: "phone required" });

  const code = generateOtp();
  const expiresAt = new Date(Date.now() + OTP_TTL_MS);

  await User.findOneAndUpdate(
    { phone },
    {
      $set: { otp: code, otpExpiresAt: expiresAt },
      $setOnInsert: { stars: 1000, uuids: [], guestUuid: undefined },
    },
    { upsert: true, new: true }
  );

  try {
    await sendOtpSms(phone, code);
    res.json({ success: true, expiresIn: OTP_TTL_MS / 1000 });
  } catch (err) {
    res.status(500).json({ error: "SMS failed" });
  }
};

// POST /auth/verify-otp
export const verifyOtp: RequestHandler = async (req, res) => {
  const { phone, otp } = req.body;
  if (!phone || !otp) res.status(400).json({ error: "phone and otp required" });

  const user = (await User.findOne({ phone })) as IUserDocument | null;

  if (
    !user ||
    user.otp !== otp ||
    !user.otpExpiresAt ||
    user.otpExpiresAt < new Date()
  ) {
    res.status(400).json({ error: "invalid or expired otp" });
  }

  // Issue new UUID
  const newUuid = user!.issueUuid();
  user!.otp = undefined;
  user!.otpExpiresAt = undefined;
  await user!.save();

  res.json({ userId: newUuid });
};
export const resendOtp: RequestHandler = async (req, res) => {
  const { phone } = req.body;
  if (!phone) res.status(400).json({ error: "phone required" });

  const code = generateOtp();
  const expiresAt = new Date(Date.now() + OTP_TTL_MS);

  await User.findOneAndUpdate(
    { phone },
    { otp: code, otpExpiresAt: expiresAt },
    { upsert: false, new: true }
  );

  try {
    await sendOtpSms(phone, code);
    res.json({ success: true, expiresIn: OTP_TTL_MS / 1000 });
  } catch (err) {
    res.status(500).json({ error: "SMS failed" });
  }
};

export const getStars: RequestHandler = async (req, res) => {
  const { userId } = req.params;
  let user: IUserDocument | null = null;

  // 1) Try by MongoDB _id
  if (mongoose.isValidObjectId(userId)) {
    user = (await User.findById(userId)) as IUserDocument | null;
  }

  // 2) Fallback to guestUuid
  if (!user) {
    user = (await User.findOne({ guestUuid: userId })) as IUserDocument | null;
  }

  // 3) Fallback to OTP‐issued UUIDs
  if (!user) {
    user = (await User.findOne({ uuids: userId })) as IUserDocument | null;
  }

  // If still not found, bail out
  if (!user) {
    res.status(404).json({ error: "User not found" });
  }

  // Success
  res.json({ stars: user!.stars });
};
export const guest: RequestHandler = async (req, res) => {
  try {
    const { uuid } = req.body;
    if (!uuid) {
      res.status(400).json({ message: "UUID is required" });
    }

    // Find by guestUuid
    let user = (await User.findOne({
      guestUuid: uuid,
    })) as IUserDocument | null;
    if (user) {
      res.json({ userId: user._id });
    }

    // Create new guest user
    user = new User({
      guestUuid: uuid,
      stars: 1000,
      uuids: [], // OTP logins go here later
    });
    await user.save();

    res.status(201).json({ userId: user._id });
  } catch (e) {
    console.error("guest signup error:", e);
    res.status(500).json({ message: "Server error" });
  }
};
