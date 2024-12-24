import mongoose from 'mongoose';

export interface IContract {
  address: string;
  name: string;
  type: string;
  network: string;
  createdAt: Date;
  updatedAt: Date;
  lastIndexedBlock?: number;
  isActive: boolean;
}

const contractSchema = new mongoose.Schema<IContract>(
  {
    address: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      required: true,
      enum: ['ERC721', 'ERC1155', 'Custom'],
      index: true,
    },
    network: {
      type: String,
      required: true,
      index: true,
    },
    lastIndexedBlock: {
      type: Number,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

export const Contract = mongoose.model<IContract>('Contract', contractSchema);
export default Contract; 