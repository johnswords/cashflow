const rateLimit = require('koa-ratelimit');
const rateLimitConfig = require('../config/rateLimit');

// In-memory store for rate limiting
// In production, consider using Redis for distributed systems
const rateLimitStore = new Map();

/**
 * Creates rate limiting middleware
 * Prevents DoS attacks and API abuse
 */
function createRateLimitMiddleware() {
  if (!rateLimitConfig.enabled) {
    console.warn('⚠️  Rate limiting is disabled');
    return async (ctx, next) => next();
  }

  return rateLimit({
    driver: 'memory',
    db: rateLimitStore,
    duration: rateLimitConfig.window,
    errorMessage: {
      error: 'Too many requests, please try again later.',
      status: 429
    },
    id: (ctx) => ctx.ip,
    headers: {
      remaining: 'X-RateLimit-Remaining',
      reset: 'X-RateLimit-Reset',
      total: 'X-RateLimit-Total'
    },
    max: rateLimitConfig.max,
    disableHeader: false,

    // Skip rate limiting for health checks
    skip: (ctx) => ctx.path === '/api/health',

    // Custom handler for rate limit exceeded
    throw: false,
    handler: async (ctx) => {
      ctx.status = 429;
      ctx.body = {
        error: 'Too many requests, please try again later.',
        status: 429,
        retryAfter: ctx.response.headers['x-ratelimit-reset']
      };
    }
  });
}

// Clean up old entries periodically to prevent memory bloat
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of rateLimitStore.entries()) {
    if (value.reset < now) {
      rateLimitStore.delete(key);
    }
  }
}, 60000); // Clean every minute

module.exports = createRateLimitMiddleware;