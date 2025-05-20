import mongoose, { Document, Model } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';

export interface IUser {
  phone: string;
  uuids: string[];
  otp?: string;
  otpExpiresAt?: Date;
  stars: number;
}

export interface IUserDocument extends IUser, Document {
  issueUuid(): string;
}

const userSchema = new mongoose.Schema<IUserDocument>({
  phone:        { type: String, required: true, unique: true, index: true },
  uuids:        { type: [String], default: [] },
  otp:          { type: String },
  otpExpiresAt: { type: Date },
  stars:        { type: Number, default: 250 },
});

// instance method to issue a new client UUID
userSchema.methods.issueUuid = function (): string {
  const newUuid = uuidv4();
  this.uuids.push(newUuid);
  return newUuid;
};

export const User: Model<IUserDocument> =
  mongoose.model<IUserDocument>('User', userSchema);
