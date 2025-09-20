const { z } = require("zod");
const { auditEntrySchema, colorEnum } = require("./common");

const playerSeedSchema = z.object({
  name: z.string().trim().min(1).max(80),
  color: colorEnum,
  sheetState: z.unknown().optional()
});

const createGameSchema = z
  .object({
    title: z.string().trim().min(1).max(120).optional(),
    players: z.array(playerSeedSchema).min(2).max(6)
  })
  .superRefine((value, ctx) => {
    const colors = value.players.map(player => player.color);
    const uniqueColors = new Set(colors);
    if (uniqueColors.size !== colors.length) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: "Player colors must be unique." });
    }
    const names = value.players.map(player => player.name.toLowerCase());
    const uniqueNames = new Set(names);
    if (uniqueNames.size !== names.length) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: "Player names must be unique within a game." });
    }
  });

const updatePlayerSchema = z.object({
  sheetState: z.unknown(),
  audit: auditEntrySchema
});

const appendAuditSchema = auditEntrySchema.extend({
  playerId: z.string().trim().min(1)
});

const endGameSchema = z.object({
  winnerPlayerId: z.string().trim().min(1),
  winnerComment: z.string().trim().max(280).optional()
});

module.exports = {
  createGameSchema,
  updatePlayerSchema,
  appendAuditSchema,
  endGameSchema
};
