import mongoose, { Schema, Document } from 'mongoose';

export const ContractType = {
  ERC721: 'ERC721',
  ERC1155: 'ERC1155'
} as const;

export type ContractType = typeof ContractType[keyof typeof ContractType];

export interface IContract extends Document {
  address: string;
  network: string;
  type: ContractType;
  name?: string;
  symbol?: string;
  isVerified: boolean;
  deployedAt?: number;
  lastIndexedBlock?: number;
  metadata?: {
    description?: string;
    image?: string;
    externalLink?: string;
  };
  createdAt: Date;
  updatedAt: Date;
}

const contractSchema = new Schema<IContract>(
  {
    address: {
      type: String,
      required: true,
      unique: true,
      index: true,
      lowercase: true
    },
    network: {
      type: String,
      required: true,
      index: true
    },
    type: {
      type: String,
      required: true,
      enum: Object.values(ContractType),
      index: true
    },
    name: String,
    symbol: String,
    isVerified: {
      type: Boolean,
      default: false,
      index: true
    },
    deployedAt: {
      type: Number,
      index: true
    },
    lastIndexedBlock: {
      type: Number,
      index: true
    },
    metadata: {
      description: String,
      image: String,
      externalLink: String
    }
  },
  {
    timestamps: true,
    versionKey: false
  }
);

// Pre-save hook to ensure address is lowercase
contractSchema.pre('save', function(next) {
  if (this.isModified('address')) {
    this.address = this.address.toLowerCase();
  }
  next();
});

// Remove explicit index creation since we're using schema-level indexing
export const Contract = mongoose.model<IContract>('Contract', contractSchema); 