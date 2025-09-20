const Koa = require("koa");
const Router = require("@koa/router");
const bodyParser = require("koa-bodyparser");
const cors = require("@koa/cors");
const { db, sqlite } = require("./db/connection");
const gamesRoutes = require("./routes/games");
const leaderboardRoutes = require("./routes/leaderboard");
const healthRoutes = require("./routes/health");

const app = new Koa();

app.use(
  bodyParser({
    enableTypes: ["json"],
    jsonLimit: "2mb"
  })
);

// Allow local dev across ports
app.use(
  cors({
    origin: "*"
  })
);

app.use(async (ctx, next) => {
  try {
    await next();
  } catch (err) {
    console.error("Unhandled error", err);
    ctx.status = err.status || 500;
    ctx.body = {
      message: err.expose ? err.message : "Internal Server Error"
    };
  }
});

const apiRouter = new Router({ prefix: "/api" });

apiRouter.use(healthRoutes.routes(), healthRoutes.allowedMethods());
apiRouter.use(gamesRoutes.routes(), gamesRoutes.allowedMethods());
apiRouter.use(leaderboardRoutes.routes(), leaderboardRoutes.allowedMethods());

app.use(apiRouter.routes()).use(apiRouter.allowedMethods());

const PORT = Number(process.env.BACKEND_PORT) || 4000;

const server = app.listen(PORT, () => {
  console.log(`Cashflow backend running at http://localhost:${PORT}`);
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
