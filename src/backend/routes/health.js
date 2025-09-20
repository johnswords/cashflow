const Router = require("@koa/router");

const router = new Router({ prefix: "/health" });

router.get("/", ctx => {
  ctx.body = { ok: true };
});

module.exports = router;
