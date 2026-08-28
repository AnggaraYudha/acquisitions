import { rateLimit } from 'express-rate-limit';
import logger from '#config/logger.js';

const securityMiddleware = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  limit: (req) => {
    const role = req.user?.role || 'guest';
    switch (role) {
      case 'admin':
        return 20; // 20 requests per minute for admin
      case 'user':
        return 10; // 10 requests per minute for user
      default:
        return 5; // 5 requests per minute for guest
    }
  },
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn('Rate limit exceeded', {
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      path: req.path,
      role: req.user?.role || 'guest'
    });

    res.status(429).json({
      error: 'Too many requests',
      message: 'Rate limit exceeded. Slow down!'
    });
  }
});

export default securityMiddleware;