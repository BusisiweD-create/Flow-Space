// Centralized error handling utility
class ErrorHandler {
  static logError(error, context = '') {
    const timestamp = new Date().toISOString();
    const errorId = Math.random().toString(36).substring(2, 15);
    
    console.error(`❌ [${timestamp}] [${errorId}] ${context}`);
    console.error(`   Message: ${error.message}`);
    
    if (error.stack) {
      console.error(`   Stack: ${error.stack.split('\n')[0]}`);
    }
    
    if (error.code) {
      console.error(`   Code: ${error.code}`);
    }
    
    return errorId;
  }
  
  static logWarning(message, context = '') {
    const timestamp = new Date().toISOString();
    console.warn(`⚠️ [${timestamp}] ${context}: ${message}`);
  }
  
  static logInfo(message, context = '') {
    const timestamp = new Date().toISOString();
    console.log(`ℹ️ [${timestamp}] ${context}: ${message}`);
  }
  
  static createErrorResponse(error, context = 'Internal server error') {
    const errorId = this.logError(error, context);
    
    return {
      success: false,
      error: context,
      errorId: errorId,
      timestamp: new Date().toISOString()
    };
  }
  
  static handleDatabaseError(error, operation = 'database operation') {
    if (error.code === 'ECONNREFUSED') {
      return this.createErrorResponse(error, 'Database connection failed');
    } else if (error.code === '42P01') {
      return this.createErrorResponse(error, 'Database table does not exist');
    } else if (error.code === '23505') {
      return this.createErrorResponse(error, 'Duplicate entry');
    }
    
    return this.createErrorResponse(error, `Database ${operation} failed`);
  }
  
  static handleEmailError(error, operation = 'email operation') {
    if (error.code === 'EAUTH') {
      return this.createErrorResponse(error, 'Email authentication failed');
    } else if (error.code === 'ECONNECTION') {
      return this.createErrorResponse(error, 'Email service connection failed');
    }
    
    return this.createErrorResponse(error, `Email ${operation} failed`);
  }
}

module.exports = ErrorHandler;