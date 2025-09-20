const { z } = require("zod");

const colorEnum = z.enum(["blue", "purple", "orange", "red", "green", "yellow"]);

const auditEntrySchema = z.object({
  entryType: z.enum(["turn", "correction"]),
  fieldPaths: z.array(z.string().min(1)).min(1),
  beforeSnapshot: z.unknown(),
  afterSnapshot: z.unknown(),
  notes: z.string().trim().max(280).optional(),
  originEntryId: z.string().trim().min(1).optional(),
  timestamp: z.string().datetime().optional()
});

module.exports = {
  colorEnum,
  auditEntrySchema
};
