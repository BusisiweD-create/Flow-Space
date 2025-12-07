const { loggingService, LogLevel, LogCategory } = require('../services/loggingService');

/**
 * Logging middleware that logs all incoming requests
 */
const loggingMiddleware = (req, res, next) => {
  const start = Date.now();
  
  // Log the incoming request
  loggingService.log(
    LogLevel.INFO,
    LogCategory.API,
    `Incoming ${req.method} request to ${req.originalUrl}`,
    null,
    {
      method: req.method,
      url: req.originalUrl,
      ip: req.ip || req.connection.remoteAddress,
      userAgent: req.get('User-Agent'),
      query: req.query,
      params: req.params
    }
  );

  // Capture response details when the response is finished
  res.on('finish', () => {
    const duration = Date.now() - start;
    
    loggingService.log(
      LogLevel.INFO,
      LogCategory.API,
      `Response for ${req.method} ${req.originalUrl}`,
      duration,
      {
        method: req.method,
        url: req.originalUrl,
        statusCode: res.statusCode,
        durationMs: duration,
        contentLength: res.get('Content-Length') || 'unknown'
      }
    );
  });

  next();
};

/**
 * Error logging middleware
 */
const errorLoggingMiddleware = (error, req, res, next) => {
  loggingService.log(
    LogLevel.ERROR,
    LogCategory.API,
    'Unhandled error occurred',
    null,
    {
      error: error.message,
      stack: error.stack,
      method: req.method,
      url: req.originalUrl,
      ip: req.ip || req.connection.remoteAddress
    }
  );

  // Pass the error to the default error handler
  next(error);
};

module.exports = {
  loggingMiddleware,
  errorLoggingMiddleware
};