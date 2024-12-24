import mongoose from 'mongoose';

const DEFAULT_DB_URI = 'mongodb://localhost:27017/tunefi';

export const connectDatabase = async () => {
  try {
    const uri = process.env.MONGODB_URI || DEFAULT_DB_URI;
    await mongoose.connect(uri);
    console.log('Successfully connected to MongoDB.');
    return mongoose;
  } catch (error) {
    console.error('Error connecting to MongoDB:', error);
    throw error;
  }
};

export const closeDatabase = async () => {
  try {
    await mongoose.disconnect();
    console.log('Successfully disconnected from MongoDB.');
  } catch (error) {
    console.error('Error disconnecting from MongoDB:', error);
    throw error;
  }
};

// Export the mongoose instance for use in other parts of the application
export default mongoose; 