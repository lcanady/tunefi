import mongoose, { Schema, Document, Types } from 'mongoose';
import { IContract } from './Contract';

export interface ITransaction extends Document {
  contract: Types.ObjectId | IContract;
  hash: string;
  blockNumber: number;
  from: string;
  to: string;
  value?: string;
  gasUsed?: number;
  gasPrice?: string;
  input?: string;
  status?: boolean;
  timestamp?: number;
  createdAt: Date;
  updatedAt: Date;
}

const TransactionSchema = new Schema<ITransaction>({
  contract: {
    type: Schema.Types.ObjectId,
    ref: 'Contract',
    required: true,
    index: true
  },
  hash: {
    type: String,
    required: true,
    unique: true,
    validate: {
      validator: (v: string) => /^0x[a-fA-F0-9]{64}$/.test(v),
      message: 'Invalid transaction hash format'
    },
    index: true
  },
  blockNumber: {
    type: Number,
    required: true,
    validate: {
      validator: (v: number) => v > 0,
      message: 'Block number must be positive'
    },
    index: true
  },
  from: {
    type: String,
    required: true,
    lowercase: true,
    validate: {
      validator: (v: string) => /^0x[a-fA-F0-9]{40}$/.test(v),
      message: 'Invalid Ethereum address format'
    },
    index: true
  },
  to: {
    type: String,
    required: true,
    lowercase: true,
    validate: {
      validator: (v: string) => /^0x[a-fA-F0-9]{40}$/.test(v),
      message: 'Invalid Ethereum address format'
    },
    index: true
  },
  value: {
    type: String,
    validate: {
      validator: (v: string) => /^\d+$/.test(v),
      message: 'Value must be a valid number string'
    }
  },
  gasUsed: {
    type: Number,
    validate: {
      validator: (v: number) => v > 0,
      message: 'Gas used must be positive'
    }
  },
  gasPrice: {
    type: String,
    validate: {
      validator: (v: string) => /^\d+$/.test(v),
      message: 'Gas price must be a valid number string'
    }
  },
  input: {
    type: String,
    validate: {
      validator: (v: string) => /^0x([a-fA-F0-9]{2})*$/.test(v),
      message: 'Invalid input data format'
    }
  },
  status: {
    type: Boolean
  },
  timestamp: {
    type: Number,
    index: true
  }
}, {
  timestamps: true,
  versionKey: false
});

// Create compound index for efficient querying
TransactionSchema.index(
  { contract: 1, blockNumber: 1 }
);

// Pre-save hook to ensure hash, from, and to are lowercase
TransactionSchema.pre('save', function(next) {
  if (this.isModified('hash')) {
    this.hash = this.hash.toLowerCase();
  }
  if (this.isModified('from')) {
    this.from = this.from.toLowerCase();
  }
  if (this.isModified('to')) {
    this.to = this.to.toLowerCase();
  }
  next();
});

export const Transaction = mongoose.model<ITransaction>('Transaction', TransactionSchema); 