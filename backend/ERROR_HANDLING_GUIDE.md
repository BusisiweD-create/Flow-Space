# Backend Error Handling Standardization Guide

## 🎯 Current Issues Identified

1. **Inconsistent error logging** - Mix of `console.error`, `console.log`, and emoji usage
2. **Error handling inconsistency** - Different patterns across files
3. **Missing error context** - Some errors lack detailed information
4. **Unhandled promise rejections** - Potential crashes from uncaught errors

## 📋 Standardized Error Handling Pattern

### 1. Use Centralized Error Handler

**Import the error handler:**
```javascript
const ErrorHandler = require('./utils/errorHandler');
```

### 2. Error Logging Patterns

**Instead of:**
```javascript
console.error('❌ Database connection failed:', error.message);
```

**Use:**
```javascript
ErrorHandler.logError(error, 'Database connection failed');
```

**Instead of:**
```javascript
console.warn('⚠️ Warning: Email service not available');
```

**Use:**
```javascript
ErrorHandler.logWarning('Email service not available', 'Email Service');
```

### 3. HTTP Error Responses

**Instead of:**
```javascript
res.status(500).json({ error: 'Internal server error' });
```

**Use:**
```javascript
const errorResponse = ErrorHandler.createErrorResponse(error, 'User registration failed');
res.status(500).json(errorResponse);
```

### 4. Database Error Handling

**Instead of generic error handling:**
```javascript
} catch (error) {
  console.error('Database error:', error);
  res.status(500).json({ error: 'Database operation failed' });
}
```

**Use specific error handling:**
```javascript
} catch (error) {
  const errorResponse = ErrorHandler.handleDatabaseError(error, 'user query');
  res.status(500).json(errorResponse);
}
```

### 5. Email Service Error Handling

**Instead of:**
```javascript
} catch (emailError) {
  console.error('❌ Email sending error:', emailError.message);
}
```

**Use:**
```javascript
} catch (emailError) {
  ErrorHandler.handleEmailError(emailError, 'verification email');
}
```

## 🚀 Implementation Examples

### Before (Problematic):
```javascript
app.post('/api/register', async (req, res) => {
  try {
    // ... registration logic
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

### After (Standardized):
```javascript
app.post('/api/register', async (req, res) => {
  try {
    // ... registration logic
  } catch (error) {
    const errorResponse = ErrorHandler.handleDatabaseError(error, 'user registration');
    res.status(500).json(errorResponse);
  }
});
```

## 🔧 Error Handler Utility Features

The `ErrorHandler` class provides:

1. **Structured logging** with timestamps and error IDs
2. **Context-aware error messages**
3. **Database-specific error handling**
4. **Email service error handling**
5. **Consistent error response format**

## 📊 Error Response Format

All error responses follow this standardized format:

```json
{
  "success": false,
  "error": "Database connection failed",
  "errorId": "abc123def456",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## 🎯 Files That Need Updates

Based on code analysis, these files need error handling standardization:

1. `server-fixed.js` - ✅ Partially updated
2. `server.js` - Needs comprehensive update
3. `server-updated.js` - Needs comprehensive update  
4. `node-backend/src/app.js` - Error middleware needs update
5. Various route files (`signoff.js`, `sprints.js`, `deliverables.js`, etc.)

## ⚡ Quick Fix Script

Run this to identify all files needing error handling updates:

```bash
# Find all console.error usage
grep -r "console\.error" backend/ --include="*.js"

# Find all console.warn usage  
grep -r "console\.warn" backend/ --include="*.js"

# Find all error response patterns
grep -r "res\.status(5" backend/ --include="*.js"
```

## ✅ Completion Checklist

- [ ] All `console.error` calls replaced with `ErrorHandler.logError`
- [ ] All `console.warn` calls replaced with `ErrorHandler.logWarning`
- [ ] All generic error responses replaced with structured responses
- [ ] Database errors handled with `handleDatabaseError`
- [ ] Email errors handled with `handleEmailError`
- [ ] Error IDs included in all error responses
- [ ] Timestamps included in all error responses

## 📞 Support

For questions about error handling standardization, refer to this guide or check the `ErrorHandler` class implementation in `utils/errorHandler.js`.