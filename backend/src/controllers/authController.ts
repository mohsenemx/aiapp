// src/controllers/authController.ts
import { RequestHandler } from "express";
import { User, IUserDocument } from "../models/User";

const OTP_CODE = "9999";
const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes

// POST /auth/send-otp
export const sendOtp: RequestHandler = async (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    res.status(400).json({ error: "phone required" });
    return;
  }

  const expiresAt = new Date(Date.now() + OTP_TTL_MS);
  await User.findOneAndUpdate(
    { phone },
    {
      $set: {
        otp: OTP_CODE,
        otpExpiresAt: expiresAt,
      },
      $setOnInsert: {
        stars: 250,
        uuids: [],
      },
    },
    { upsert: true, new: true }
  );

  console.log(`[DEV] OTP for ${phone} is ${OTP_CODE}`);
  res.json({ success: true, expiresIn: OTP_TTL_MS / 1000 });
  // no return of res.* value here
};

// POST /auth/verify-otp
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

  // Issue and persist a new UUID
  const newUuid = user.issueUuid();
  user.otp = undefined;
  user.otpExpiresAt = undefined;
  await user.save();

  res.json({ userId: newUuid });
  // no return of res.* value here
};
export const resendOtp: RequestHandler = async (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    res.status(400).json({ error: "phone required" });
    return;
  }

  const expiresAt = new Date(Date.now() + OTP_TTL_MS);
  await User.findOneAndUpdate(
    { phone },
    { otp: OTP_CODE, otpExpiresAt: expiresAt },
    { upsert: true, new: true }
  );

  console.log(`[DEV] New OTP for ${phone} is ${OTP_CODE}`);
  res.json({ success: true, expiresIn: OTP_TTL_MS / 1000 });
  // no return of res.* value here
};

export const getStars: RequestHandler = async (req, res) => {
  const { userId } = req.params;
  // find the user whose uuids array contains this client UUID
  const user = (await User.findOne({ uuids: userId })) as IUserDocument | null;
  if (!user) {
    res.status(404).json({ error: "User not found" });
  }
  res.json({ stars: user!.stars });
};
export const guest: RequestHandler = async (req, res) => {
  try {
    const { uuid } = req.body;
    if (!uuid) {
       res.status(400).json({ message: "UUID is required" });
    }

    // Find by guestUuid
    let user = await User.findOne({ guestUuid: uuid }) as IUserDocument | null;
    if (user) {
       res.json({ userId: user._id });
    }

    // Create new guest user
    user = new User({
      guestUuid: uuid,
      stars: 250,
      uuids: [],    // OTP logins go here later
    });
    await user.save();

     res.status(201).json({ userId: user._id });

  } catch (e) {
    console.error("guest signup error:", e);
     res.status(500).json({ message: "Server error" });
  }
};