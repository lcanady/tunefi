import mongoose, { Schema, Document } from 'mongoose';

export const ContractType = {
  ERC721: 'ERC721',
  ERC1155: 'ERC1155'
} as const;

export type ContractType = typeof ContractType[keyof typeof ContractType];

export interface IContract {
  address: string;
  type: ContractType;
  network: string;
  name?: string;
  symbol?: string;
  startBlock?: number;
  deployedAt: Date;
  lastIndexedBlock: number;
  isVerified: boolean;
  metadata?: {
    description?: string;
    imageUrl?: string;
    externalUrl?: string;
  };
}

export interface ContractDocument extends Document {
  address: string;
  type: ContractType;
  network: string;
  name?: string;
  symbol?: string;
  startBlock?: number;
  deployedAt: Date;
  lastIndexedBlock: number;
  isVerified: boolean;
  metadata?: {
    description?: string;
    imageUrl?: string;
    externalUrl?: string;
  };
  createdAt: Date;
  updatedAt: Date;
}

const schema = {
  address: {
    type: String,
    required: true,
    lowercase: true,
  },
  type: {
    type: String,
    required: true,
    enum: Object.values(ContractType),
  },
  network: {
    type: String,
    required: true,
  },
  name: String,
  symbol: String,
  startBlock: Number,
  deployedAt: Date,
  lastIndexedBlock: Number,
  isVerified: {
    type: Boolean,
    default: false
  },
  metadata: {
    description: String,
    imageUrl: String,
    externalUrl: String
  }
};

const contractSchema = new Schema(schema, { timestamps: true });

contractSchema.index({ address: 1, network: 1 }, { unique: true });

contractSchema.pre('save', function(next) {
  if (this.address) {
    this.address = this.address.toLowerCase();
  }
  next();
});

export const Contract = mongoose.model<ContractDocument>('Contract', contractSchema); 