import mongoose, { Document, Model } from "mongoose";
import { v4 as uuidv4 } from "uuid";

export interface IUser {
  phone?: string; // now optional
  uuid: string; // single UUID for both guest and logged in users
  otp?: string;
  otpExpiresAt?: Date;
  stars: number;
}

export interface IUserDocument extends IUser, Document {
  issueUuid(): string;
}

const userSchema = new mongoose.Schema<IUserDocument>({
  phone: { type: String, unique: true, sparse: true },
  uuid: { type: String, unique: true, required: true },
  otp: { type: String },
  otpExpiresAt: { type: Date },
  stars: { type: Number, default: 1000 },
});

// instance method to issue a new client UUID
userSchema.methods.issueUuid = function (): string {
  const newUuid = uuidv4();
  this.uuid = newUuid;
  return newUuid;
};

export const User: Model<IUserDocument> = mongoose.model<IUserDocument>(
  "User",
  userSchema
);
