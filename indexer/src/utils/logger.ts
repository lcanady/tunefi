export enum LogLevel {
  ERROR = 'error',
  WARN = 'warn',
  INFO = 'info',
  DEBUG = 'debug'
}

const LOG_LEVEL_PRIORITY = {
  [LogLevel.ERROR]: 0,
  [LogLevel.WARN]: 1,
  [LogLevel.INFO]: 2,
  [LogLevel.DEBUG]: 3
};

export class Logger {
  private level: LogLevel;

  constructor() {
    this.level = (process.env.LOG_LEVEL as LogLevel) || LogLevel.INFO;
  }

  private shouldLog(level: LogLevel): boolean {
    return LOG_LEVEL_PRIORITY[level] <= LOG_LEVEL_PRIORITY[this.level];
  }

  private formatMessage(level: LogLevel, message: string): string {
    const timestamp = new Date().toISOString();
    return `[${timestamp}] [${level.toUpperCase()}] ${message}`;
  }

  error(message: string, error?: Error, metadata?: Record<string, unknown>): void {
    if (this.shouldLog(LogLevel.ERROR)) {
      if (error && metadata) {
        console.error(this.formatMessage(LogLevel.ERROR, message), error, metadata);
      } else if (error) {
        console.error(this.formatMessage(LogLevel.ERROR, message), error);
      } else {
        console.error(this.formatMessage(LogLevel.ERROR, message), metadata);
      }
    }
  }

  warn(message: string, metadata?: Record<string, unknown>): void {
    if (this.shouldLog(LogLevel.WARN)) {
      console.warn(this.formatMessage(LogLevel.WARN, message), metadata);
    }
  }

  info(message: string, metadata?: Record<string, unknown>): void {
    if (this.shouldLog(LogLevel.INFO)) {
      console.info(this.formatMessage(LogLevel.INFO, message), metadata);
    }
  }

  debug(message: string, metadata?: Record<string, unknown>): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      console.debug(this.formatMessage(LogLevel.DEBUG, message), metadata);
    }
  }
}

export const logger = new Logger(); 