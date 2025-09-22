// Rate Limiting Configuration
const rateLimitConfig = {
  enabled: process.env.RATE_LIMIT_ENABLED !== 'false',
  window: Number(process.env.RATE_LIMIT_WINDOW) || 60000, // 1 minute
  max: Number(process.env.RATE_LIMIT_MAX) || 100, // requests per window

  // Endpoint-specific limits
  endpoints: {
    '/api/games': {
      max: 50,
      window: 60000
    },
    '/api/games/:id/players/:playerId': {
      max: 200, // Higher for game updates
      window: 60000
    },
    '/api/leaderboard': {
      max: 30,
      window: 60000
    }
  }
};

module.exports = rateLimitConfig;