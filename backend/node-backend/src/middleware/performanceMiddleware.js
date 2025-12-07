const { loggingService, LogLevel, LogCategory } = require('../services/loggingService');

/**
 * Performance monitoring middleware
 * Measures response time and logs slow requests
 */
const performanceMiddleware = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    
    // Log slow requests (over 500ms)
    if (duration > 500) {
      loggingService.log(
        LogLevel.WARNING,
        LogCategory.PERFORMANCE,
        `Slow request detected: ${req.method} ${req.originalUrl} took ${duration}ms`,
        duration,
        {
          method: req.method,
          url: req.originalUrl,
          duration: duration,
          statusCode: res.statusCode
        }
      );
    }
    
    // Log all requests for performance monitoring
    loggingService.log(
      LogLevel.DEBUG,
      LogCategory.PERFORMANCE,
      `Request completed: ${req.method} ${req.originalUrl} in ${duration}ms`,
      duration,
      {
        method: req.method,
        url: req.originalUrl,
        duration: duration,
        statusCode: res.statusCode
      }
    );
  });

  next();
};

/**
 * Memory usage monitoring middleware
 */
const memoryUsageMiddleware = (req, res, next) => {
  const memoryUsage = process.memoryUsage();
  
  // Log memory usage periodically (every 100 requests)
  if (Math.random() < 0.01) { // 1% chance to log memory usage
    loggingService.log(
      LogLevel.DEBUG,
      LogCategory.PERFORMANCE,
      'Memory usage snapshot',
      null,
      {
        rss: `${(memoryUsage.rss / 1024 / 1024).toFixed(2)}MB`,
        heapTotal: `${(memoryUsage.heapTotal / 1024 / 1024).toFixed(2)}MB`,
        heapUsed: `${(memoryUsage.heapUsed / 1024 / 1024).toFixed(2)}MB`,
        external: `${(memoryUsage.external / 1024 / 1024).toFixed(2)}MB`,
        arrayBuffers: `${(memoryUsage.arrayBuffers / 1024 / 1024).toFixed(2)}MB`
      }
    );
  }

  next();
};

module.exports = {
  performanceMiddleware,
  memoryUsageMiddleware
};