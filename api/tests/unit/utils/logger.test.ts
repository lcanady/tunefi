import { logger, Logger, LogLevel } from '../../../src/utils/logger';

describe('Logger', () => {
  let consoleLogSpy: jest.SpyInstance;
  let consoleErrorSpy: jest.SpyInstance;
  let consoleWarnSpy: jest.SpyInstance;
  let consoleInfoSpy: jest.SpyInstance;
  let consoleDebugSpy: jest.SpyInstance;
  let testLogger: Logger;

  beforeEach(() => {
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
    consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation();
    consoleInfoSpy = jest.spyOn(console, 'info').mockImplementation();
    consoleDebugSpy = jest.spyOn(console, 'debug').mockImplementation();
    process.env.LOG_LEVEL = LogLevel.DEBUG;
    testLogger = new Logger();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should log messages with different levels', () => {
    const message = 'Test message';
    const error = new Error('Test error');
    const metadata = { key: 'value' };

    testLogger.error(message, error, metadata);
    testLogger.warn(message, metadata);
    testLogger.info(message, metadata);
    testLogger.debug(message, metadata);

    expect(consoleErrorSpy).toHaveBeenCalledWith(
      expect.stringContaining('[ERROR]'),
      error,
      metadata
    );
    expect(consoleWarnSpy).toHaveBeenCalledWith(
      expect.stringContaining('[WARN]'),
      metadata
    );
    expect(consoleInfoSpy).toHaveBeenCalledWith(
      expect.stringContaining('[INFO]'),
      metadata
    );
    expect(consoleDebugSpy).toHaveBeenCalledWith(
      expect.stringContaining('[DEBUG]'),
      metadata
    );
  });

  it('should respect log level configuration', () => {
    process.env.LOG_LEVEL = LogLevel.WARN;
    const warnLogger = new Logger();

    const message = 'Test message';
    warnLogger.error(message);
    warnLogger.warn(message);
    warnLogger.info(message);
    warnLogger.debug(message);

    expect(consoleErrorSpy).toHaveBeenCalled();
    expect(consoleWarnSpy).toHaveBeenCalled();
    expect(consoleInfoSpy).not.toHaveBeenCalled();
    expect(consoleDebugSpy).not.toHaveBeenCalled();
  });

  it('should include timestamp in log messages', () => {
    const message = 'Test message';
    testLogger.info(message);

    expect(consoleInfoSpy).toHaveBeenCalledWith(
      expect.stringMatching(/\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\] \[INFO\] Test message/),
      undefined
    );
  });

  it('should handle objects and arrays in metadata', () => {
    const message = 'Test message';
    const metadata = {
      array: [1, 2, 3],
      object: { nested: { value: 'test' } }
    };

    testLogger.info(message, metadata);

    expect(consoleInfoSpy).toHaveBeenCalledWith(
      expect.stringContaining('[INFO]'),
      metadata
    );
  });

  it('should format error stacks in error logs', () => {
    const message = 'Test error message';
    const error = new Error('Test error');
    
    testLogger.error(message, error);

    expect(consoleErrorSpy).toHaveBeenCalledWith(
      expect.stringContaining('[ERROR]'),
      error
    );
  });
}); 