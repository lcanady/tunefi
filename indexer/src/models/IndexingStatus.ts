import mongoose, { Schema, Document, Types } from 'mongoose';
import { IContract } from './Contract';

export enum IndexingStatusType {
  PENDING = 'pending',
  RUNNING = 'running',
  PAUSED = 'paused',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

export interface IIndexingStatus extends Document {
  contract: Types.ObjectId | IContract;
  lastIndexedBlock: number;
  lastIndexedAt: number;
  isIndexing: boolean;
  status: IndexingStatusType;
  error?: string;
  progress?: number;
  startBlock?: number;
  endBlock?: number;
  currentBlock?: number;
  createdAt: Date;
  updatedAt: Date;
}

const IndexingStatusSchema = new Schema<IIndexingStatus>({
  contract: {
    type: Schema.Types.ObjectId,
    ref: 'Contract',
    required: true,
    unique: true
  },
  lastIndexedBlock: {
    type: Number,
    required: true,
    validate: {
      validator: (v: number) => v >= 0,
      message: 'Last indexed block must be non-negative'
    }
  },
  lastIndexedAt: {
    type: Number,
    required: true
  },
  isIndexing: {
    type: Boolean,
    required: true,
    default: false
  },
  status: {
    type: String,
    required: true,
    enum: Object.values(IndexingStatusType),
    default: IndexingStatusType.PENDING
  },
  error: {
    type: String
  },
  progress: {
    type: Number,
    validate: {
      validator: (v: number) => v >= 0 && v <= 100,
      message: 'Progress must be between 0 and 100'
    }
  },
  startBlock: {
    type: Number,
    validate: {
      validator: (v: number) => v >= 0,
      message: 'Start block must be non-negative'
    }
  },
  endBlock: {
    type: Number,
    validate: {
      validator: (v: number) => v >= 0,
      message: 'End block must be non-negative'
    }
  },
  currentBlock: {
    type: Number,
    validate: {
      validator: (v: number) => v >= 0,
      message: 'Current block must be non-negative'
    }
  }
}, {
  timestamps: true,
  versionKey: false
});

// Create indexes for efficient querying
IndexingStatusSchema.index({ status: 1 });
IndexingStatusSchema.index({ lastIndexedAt: -1 });
IndexingStatusSchema.index({ isIndexing: 1 });

// Add validation for block ranges
IndexingStatusSchema.pre('save', function(next) {
  if (this.startBlock != null && this.endBlock != null) {
    if (this.startBlock > this.endBlock) {
      next(new Error('Start block must be less than or equal to end block'));
    }
    if (this.currentBlock != null) {
      if (this.currentBlock < this.startBlock || this.currentBlock > this.endBlock) {
        next(new Error('Current block must be within start and end block range'));
      }
    }
  }
  next();
});

// Update lastIndexedAt on save
IndexingStatusSchema.pre('save', function(next) {
  if (this.isModified('lastIndexedBlock')) {
    this.lastIndexedAt = Date.now();
  }
  next();
});

export const IndexingStatus = mongoose.model<IIndexingStatus>('IndexingStatus', IndexingStatusSchema); 