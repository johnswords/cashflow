const cors = require('@koa/cors');
const config = require('../config');

/**
 * Creates a CORS middleware with dynamic origin validation
 * This prevents unauthorized domains from accessing the API
 */
function createCorsMiddleware() {
  const allowedOrigins = new Set(config.cors.allowedOrigins);

  // Add middleware to set Vary header for proper CDN caching
  const corsMiddleware = cors({
    origin: (ctx) => {
      const requestOrigin = ctx.headers.origin;

      // No origin header (same-origin requests, Postman, etc.)
      if (!requestOrigin) {
        return config.nodeEnv === 'development' ? '*' : false;
      }

      // Check if origin is allowed
      if (allowedOrigins.has(requestOrigin)) {
        return requestOrigin;
      }

      // In development, log rejected origins for debugging
      if (config.nodeEnv === 'development') {
        console.log(`CORS: Rejected origin ${requestOrigin}. Allowed origins:`, config.cors.allowedOrigins);
      }

      return false;
    },

    // Allow credentials only for allowed origins
    credentials: config.cors.credentials,

    // Cache preflight requests
    maxAge: config.cors.maxAge,

    // Allowed headers
    allowHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],

    // Allowed methods
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],

    // Expose headers to the client
    exposeHeaders: ['X-RateLimit-Remaining', 'X-RateLimit-Reset', 'X-RateLimit-Total']
  });

  // Return a composed middleware that sets Vary header
  return async (ctx, next) => {
    // Set Vary: Origin header for proper CDN caching
    ctx.vary('Origin');
    await corsMiddleware(ctx, next);
  };
}

module.exports = createCorsMiddleware;