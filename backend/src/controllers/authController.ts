// src/controllers/authController.ts
import { RequestHandler } from 'express';
import { User, IUserDocument } from '../models/User';

const OTP_CODE = '9999';
const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes

// POST /auth/send-otp
export const sendOtp: RequestHandler = async (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    res.status(400).json({ error: 'phone required' });
    return;
  }

  const expiresAt = new Date(Date.now() + OTP_TTL_MS);
  await User.findOneAndUpdate(
    { phone },
    { otp: OTP_CODE, otpExpiresAt: expiresAt },
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
    res.status(400).json({ error: 'phone and otp required' });
    return;
  }

  const user = await User.findOne({ phone }) as IUserDocument | null;
  if (
    !user ||
    user.otp !== otp ||
    !user.otpExpiresAt ||
    user.otpExpiresAt < new Date()
  ) {
    res.status(400).json({ error: 'invalid or expired otp' });
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
    res.status(400).json({ error: 'phone required' });
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