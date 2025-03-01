import mongoose, { Schema, Document } from 'mongoose';

export interface IBlock extends Document {
  number: number;
  hash: string;
  parentHash: string;
  timestamp: number;
  gasUsed?: number;
  gasLimit?: number;
  baseFeePerGas?: string;
  difficulty?: string;
  totalDifficulty?: string;
  size?: number;
  nonce?: string;
  miner?: string;
  extraData?: string;
  transactionCount?: number;
  createdAt: Date;
  updatedAt: Date;
}

const BlockSchema = new Schema<IBlock>({
  number: {
    type: Number,
    required: true,
    unique: true,
    index: true
  },
  hash: {
    type: String,
    required: true,
    unique: true,
    validate: {
      validator: (v: string) => /^0x[a-fA-F0-9]{64}$/.test(v),
      message: 'Invalid block hash format'
    },
    index: true
  },
  parentHash: {
    type: String,
    required: true,
    validate: {
      validator: (v: string) => /^0x[a-fA-F0-9]{64}$/.test(v),
      message: 'Invalid parent hash format'
    },
    index: true
  },
  timestamp: {
    type: Number,
    required: true,
    index: true
  },
  gasUsed: {
    type: Number,
    validate: {
      validator: (v: number) => v > 0,
      message: 'Gas used must be positive'
    }
  },
  gasLimit: {
    type: Number,
    validate: {
      validator: (v: number) => v > 0,
      message: 'Gas limit must be positive'
    }
  },
  baseFeePerGas: {
    type: String,
    validate: {
      validator: (v: string) => /^\d+$/.test(v),
      message: 'Base fee per gas must be a valid number string'
    }
  },
  difficulty: {
    type: String,
    validate: {
      validator: (v: string) => /^\d+$/.test(v),
      message: 'Difficulty must be a valid number string'
    }
  },
  totalDifficulty: {
    type: String,
    validate: {
      validator: (v: string) => /^\d+$/.test(v),
      message: 'Total difficulty must be a valid number string'
    }
  },
  size: {
    type: Number,
    validate: {
      validator: (v: number) => v > 0,
      message: 'Block size must be positive'
    }
  },
  nonce: {
    type: String,
    validate: {
      validator: (v: string) => /^0x[a-fA-F0-9]+$/.test(v),
      message: 'Invalid nonce format'
    }
  },
  miner: {
    type: String,
    lowercase: true,
    validate: {
      validator: (v: string) => /^0x[a-fA-F0-9]{40}$/.test(v),
      message: 'Invalid miner address format'
    }
  },
  extraData: {
    type: String,
    validate: {
      validator: (v: string) => /^0x([a-fA-F0-9]{2})*$/.test(v),
      message: 'Invalid extra data format'
    }
  },
  transactionCount: {
    type: Number,
    validate: {
      validator: (v: number) => v >= 0,
      message: 'Transaction count must be non-negative'
    }
  }
}, {
  timestamps: true,
  versionKey: false
});

// Create compound index for efficient querying
BlockSchema.index(
  { number: -1, timestamp: -1 }
);

// Add pre-save hook to check for duplicates
BlockSchema.pre('save', async function(next) {
  const doc = this;
  const exists = await mongoose.model('Block').findOne({
    $or: [
      { hash: doc.hash },
      { number: doc.number }
    ]
  });
  
  if (exists) {
    next(new Error('Block with this hash or number already exists'));
  }
  next();
});

export const Block = mongoose.model<IBlock>('Block', BlockSchema); 