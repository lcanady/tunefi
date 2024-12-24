declare global {
  namespace NodeJS {
    interface Global {
      __MONGO_URI__: string;
      __MONGO_DB_NAME__: string;
    }
  }
}

declare const __MONGO_URI__: string;
declare const __MONGO_DB_NAME__: string;

export {}; 