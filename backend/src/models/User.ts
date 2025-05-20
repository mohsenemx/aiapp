import mongoose, { Document, Model } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';

export interface IUser {
  phone: string;
  uuids: string[];
  otp?: string;
  otpExpiresAt?: Date;
}

// Extend mongoose.Document to include IUser fields + your method
export interface IUserDocument extends IUser, Document {
  issueUuid(): string;
}

// Now type the schema & model properly
const userSchema = new mongoose.Schema<IUserDocument>({
  phone:        { type: String, required: true, unique: true, index: true },
  uuids:        { type: [String], default: [] },
  otp:          { type: String },
  otpExpiresAt: { type: Date },
});

// Attach the instance method
userSchema.methods.issueUuid = function (): string {
  const newUuid = uuidv4();
  this.uuids.push(newUuid);
  return newUuid;
};

// Make sure to parameterize the model with IUserDocument
export const User: Model<IUserDocument> =
  mongoose.model<IUserDocument>('User', userSchema);
