import mongoose, { Document, Model } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';

export interface IUser {
  phone?: string;        // now optional
  uuids: string[];       // OTP logins
  guestUuid?: string;    // for anonymous guests
  otp?: string;
  otpExpiresAt?: Date;
  stars: number;
}

export interface IUserDocument extends IUser, Document {
  issueUuid(): string;
}

const userSchema = new mongoose.Schema<IUserDocument>({
  phone:        { type: String, unique: true, sparse: true },
  uuids:        { type: [String], default: [] },
  guestUuid:    { type: String, unique: true, sparse: true },
  otp:          { type: String },
  otpExpiresAt: { type: Date },
  stars:        { type: Number, default: 250 },
});

// instance method to issue a new client UUID (for OTP logins)
userSchema.methods.issueUuid = function (): string {
  const newUuid = uuidv4();
  this.uuids.push(newUuid);
  return newUuid;
};

export const User: Model<IUserDocument> =
  mongoose.model<IUserDocument>('User', userSchema);
