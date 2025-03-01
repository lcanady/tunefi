import mongoose, { Schema, Document } from 'mongoose';
import { ContractType } from './Contract';

export interface ITransaction extends Document {
  hash: string;
  blockNumber: number;
  blockHash: string;
  from: string;
  to: string;
  value: string;
  gasUsed: number;
  gasPrice: string;
  input: string;
  status: boolean;
  timestamp: Date;
  network: string;
  contractType?: ContractType;
  createdAt: Date;
  updatedAt: Date;
}

const transactionSchema = new Schema<ITransaction>(
  {
    hash: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
    },
    blockNumber: {
      type: Number,
      required: true,
    },
    blockHash: {
      type: String,
      required: true,
      lowercase: true,
    },
    from: {
      type: String,
      required: true,
      lowercase: true,
    },
    to: {
      type: String,
      required: true,
      lowercase: true,
    },
    value: {
      type: String,
      required: true,
    },
    gasUsed: {
      type: Number,
      required: true,
    },
    gasPrice: {
      type: String,
      required: true,
    },
    input: {
      type: String,
      required: true,
    },
    status: {
      type: Boolean,
      required: true,
    },
    timestamp: {
      type: Date,
      required: true,
    },
    network: {
      type: String,
      required: true,
    },
    contractType: {
      type: String,
      enum: Object.values(ContractType),
    },
  },
  {
    timestamps: true,
  }
);

// Create compound index for hash and network
transactionSchema.index({ hash: 1, network: 1 }, { unique: true });

// Pre-save hook to convert addresses to lowercase
transactionSchema.pre('save', function (next) {
  if (this.from) this.from = this.from.toLowerCase();
  if (this.to) this.to = this.to.toLowerCase();
  if (this.hash) this.hash = this.hash.toLowerCase();
  if (this.blockHash) this.blockHash = this.blockHash.toLowerCase();
  next();
});

export const Transaction = mongoose.model<ITransaction>('Transaction', transactionSchema); 