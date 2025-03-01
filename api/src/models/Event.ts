import mongoose, { Schema, Document, Types } from 'mongoose';
import { IContract } from './Contract';

export interface IEvent extends Document {
  contract: Types.ObjectId | IContract;
  name: string;
  signature: string;
  blockNumber: number;
  transactionHash: string;
  logIndex: number;
  args?: Record<string, any>;
  timestamp?: number;
  createdAt: Date;
  updatedAt: Date;
}

const EventSchema = new Schema<IEvent>({
  contract: {
    type: Schema.Types.ObjectId,
    ref: 'Contract',
    required: true,
    index: true
  },
  name: {
    type: String,
    required: true,
    index: true
  },
  signature: {
    type: String,
    required: true
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
  transactionHash: {
    type: String,
    required: true,
    validate: {
      validator: (v: string) => /^0x[a-fA-F0-9]{64}$/.test(v),
      message: 'Invalid transaction hash format'
    },
    index: true
  },
  logIndex: {
    type: Number,
    required: true,
    validate: {
      validator: (v: number) => v >= 0,
      message: 'Log index must be non-negative'
    }
  },
  args: {
    type: Schema.Types.Mixed,
    default: {}
  },
  timestamp: {
    type: Number,
    index: true
  }
}, {
  timestamps: true,
  versionKey: false
});

// Create compound index for uniqueness
EventSchema.index(
  { transactionHash: 1, logIndex: 1 },
  { unique: true }
);

// Create compound index for efficient querying
EventSchema.index(
  { contract: 1, blockNumber: 1, name: 1 }
);

// Add pre-save hook to check for duplicates
EventSchema.pre('save', async function(next) {
  const doc = this;
  const exists = await mongoose.model('Event').findOne({
    transactionHash: doc.transactionHash,
    logIndex: doc.logIndex
  });
  
  if (exists) {
    next(new Error('Event with this transaction hash and log index already exists'));
  }
  next();
});

export const Event = mongoose.model<IEvent>('Event', EventSchema); 