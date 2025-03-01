import mongoose, { Schema, Document, Types } from 'mongoose';
import { IContract } from './Contract';

export enum MetadataCacheStatus {
  PENDING = 'pending',
  FETCHING = 'fetching',
  SUCCESS = 'success',
  FAILED = 'failed',
  INVALID = 'invalid'
}

export interface ITokenAttribute {
  trait_type: string;
  value: string | number;
  display_type?: string;
}

export interface ITokenMetadata {
  name?: string;
  description?: string;
  image?: string;
  external_url?: string;
  animation_url?: string;
  background_color?: string;
  attributes?: ITokenAttribute[];
  [key: string]: any; // Allow for additional metadata fields
}

export interface IMetadataCache extends Document {
  contract: Types.ObjectId | IContract;
  tokenId: string;
  uri: string;
  metadata?: ITokenMetadata;
  lastFetched?: number;
  status: MetadataCacheStatus;
  error?: string;
  retryCount: number;
  createdAt: Date;
  updatedAt: Date;
}

const MetadataCacheSchema = new Schema<IMetadataCache>({
  contract: {
    type: Schema.Types.ObjectId,
    ref: 'Contract',
    required: true,
    index: true
  },
  tokenId: {
    type: String,
    required: true,
    validate: {
      validator: (v: string) => /^\d+$/.test(v),
      message: 'Token ID must be a valid number string'
    }
  },
  uri: {
    type: String,
    required: true,
    validate: {
      validator: (v: string) => {
        try {
          new URL(v);
          return true;
        } catch (e) {
          return false;
        }
      },
      message: 'URI must be a valid URL'
    }
  },
  metadata: {
    type: Schema.Types.Mixed,
    default: null
  },
  lastFetched: {
    type: Number,
    index: true
  },
  status: {
    type: String,
    required: true,
    enum: Object.values(MetadataCacheStatus),
    default: MetadataCacheStatus.PENDING,
    index: true
  },
  error: {
    type: String
  },
  retryCount: {
    type: Number,
    default: 0,
    validate: {
      validator: (v: number) => v >= 0,
      message: 'Retry count must be non-negative'
    }
  }
}, {
  timestamps: true,
  versionKey: false
});

// Create compound index for uniqueness
MetadataCacheSchema.index(
  { contract: 1, tokenId: 1 },
  { unique: true }
);

// Create compound index for efficient querying
MetadataCacheSchema.index(
  { contract: 1, status: 1, lastFetched: 1 }
);

// Add validation for metadata structure
MetadataCacheSchema.pre('save', function(next) {
  if (this.metadata) {
    if (this.metadata.attributes) {
      if (!Array.isArray(this.metadata.attributes)) {
        next(new Error('Metadata attributes must be an array'));
        return;
      }

      for (const attr of this.metadata.attributes) {
        if (!attr.trait_type || !('value' in attr)) {
          next(new Error('Invalid attribute format'));
          return;
        }
      }
    }

    if (this.metadata.image && typeof this.metadata.image === 'string') {
      try {
        new URL(this.metadata.image);
      } catch (e) {
        next(new Error('Invalid image URL in metadata'));
        return;
      }
    }
  }
  next();
});

// Update lastFetched on metadata update
MetadataCacheSchema.pre('save', function(next) {
  if (this.isModified('metadata')) {
    this.lastFetched = Date.now();
  }
  next();
});

export const MetadataCache = mongoose.model<IMetadataCache>('MetadataCache', MetadataCacheSchema); 