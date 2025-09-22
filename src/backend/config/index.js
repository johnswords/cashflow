const config = {
  // Server Configuration
  port: Number(process.env.BACKEND_PORT) || 4000,
  nodeEnv: process.env.NODE_ENV || 'development',

  // CORS Configuration
  cors: {
    // In production, set ALLOWED_ORIGINS environment variable
    // Example: ALLOWED_ORIGINS=https://example.com,https://app.example.com
    allowedOrigins: process.env.ALLOWED_ORIGINS
      ? process.env.ALLOWED_ORIGINS.split(',').map(origin => {
          const trimmed = origin.trim();
          // Validate URL format
          try {
            new URL(trimmed);
            return trimmed;
          } catch (e) {
            console.error(`Invalid origin URL: ${trimmed}`);
            return null;
          }
        }).filter(Boolean)
      : process.env.NODE_ENV === 'production'
        ? ['http://localhost:8080'] // Default for production - update this!
        : ['http://localhost:8080', 'http://localhost:3000', 'http://127.0.0.1:8080'], // Development origins

    credentials: true,
    maxAge: 604800, // 7 days for stable API
  },

  // Security Configuration
  security: {
    jsonLimit: process.env.JSON_LIMIT || '2mb',
    enableDetailedErrors: process.env.NODE_ENV !== 'production',
  }
};

// Validate critical production settings
if (config.nodeEnv === 'production') {
  if (config.cors.allowedOrigins.includes('http://localhost:8080')) {
    console.warn('⚠️  WARNING: Using default localhost origin in production. Set ALLOWED_ORIGINS environment variable!');
  }
}

module.exports = config;