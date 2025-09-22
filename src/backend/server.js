const Koa = require("koa");
const Router = require("@koa/router");
const bodyParser = require("koa-bodyparser");
const { db, sqlite } = require("./db/connection");
const config = require("./config");
const createCorsMiddleware = require("./middleware/cors");
const gamesRoutes = require("./routes/games");
const leaderboardRoutes = require("./routes/leaderboard");
const healthRoutes = require("./routes/health");

const app = new Koa();

app.use(
  bodyParser({
    enableTypes: ["json"],
    jsonLimit: config.security.jsonLimit
  })
);

// Use secure CORS configuration
app.use(createCorsMiddleware());

app.use(async (ctx, next) => {
  try {
    await next();
  } catch (err) {
    ctx.status = err.status || 500;

    // In production, don't expose internal error details
    if (config.security.enableDetailedErrors) {
      console.error("Request error:", err);
      ctx.body = {
        error: err.message,
        status: ctx.status,
        ...(config.nodeEnv === 'development' && { stack: err.stack })
      };
    } else {
      // Production: log internally with context, return generic message
      console.error('Request error:', {
        status: ctx.status,
        method: ctx.method,
        path: ctx.path,
        origin: ctx.headers.origin || 'no-origin',
        userAgent: ctx.headers['user-agent'],
        ip: ctx.ip,
        error: err.message
      });
      ctx.body = {
        error: ctx.status === 500 ? 'Internal Server Error' : err.message,
        status: ctx.status
      };
    }
  }
});

const apiRouter = new Router({ prefix: "/api" });

apiRouter.use(healthRoutes.routes(), healthRoutes.allowedMethods());
apiRouter.use(gamesRoutes.routes(), gamesRoutes.allowedMethods());
apiRouter.use(leaderboardRoutes.routes(), leaderboardRoutes.allowedMethods());

app.use(apiRouter.routes()).use(apiRouter.allowedMethods());

const server = app.listen(config.port, () => {
  console.log(`Cashflow backend running at http://localhost:${config.port}`);
  console.log(`Environment: ${config.nodeEnv}`);
  console.log(`CORS origins: ${config.cors.allowedOrigins.join(', ')}`);
});

const gracefulShutdown = () => {
  console.log("Shutting down backend...");
  server.close(() => {
    db.destroy().finally(() => {
      sqlite.close();
      process.exit(0);
    });
  });
};

process.on("SIGTERM", gracefulShutdown);
process.on("SIGINT", gracefulShutdown);
