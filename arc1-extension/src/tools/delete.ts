import { z } from 'zod';
import type { PluginToolDefinition } from 'arc-1/public';
import { findPolicyViolation, type PlannedChange } from '../policy.js';
import { get, objectNamePattern, textResult, write } from '../service.js';

const objectName = z.string().regex(objectNamePattern);

const schema = z.object({
  enhancement: objectName.describe('Enhancement object, e.g. ZENH_TOR'),
  entityType: z
    .enum([
      'enhancement',
      'node',
      'action',
      'actionEnhancement',
      'determination',
      'validation',
      'query',
      'association',
      'alternativeKey',
    ])
    .describe('enhancement deletes the whole enhancement object with all its entities and its constants interface'),
  name: objectName.describe('Entity to delete; for entityType enhancement the enhancement itself'),
  token: z
    .string()
    .regex(/^[0-9a-f]{64}$/)
    .optional()
    .describe('Token of the preview; without it the tool only returns the preview'),
  transport: z.string().regex(/^[A-Za-z0-9]{10}$/).optional().describe(
    'Workbench request or task; needed for packages that record changes unless the object is already in a request',
  ),
});

export const deleteTool: PluginToolDefinition = {
  name: 'Custom_BopfEnhDelete',
  description:
    'Delete own entities of a classic BOPF enhancement object, or the whole enhancement, in two steps. ' +
    'Without token: preview with everything that is deleted, in deletion order and including dependent entities ' +
    '(subnodes, entities on deleted nodes, validations of deleted actions, generated DDIC objects), what stays ' +
    '(implementation classes, DDIC objects created by the developer) and a token. ' +
    'Show the preview to the user, then call again with that token to delete exactly that. ' +
    'The token becomes invalid as soon as the enhancement changes. A node whose database table contains data is not deleted.',
  schema,
  policy: { scope: 'write', opType: 'D' },
  availableOn: 'onprem',
  async handler(args, ctx) {
    const request = schema.parse(args);
    const target = {
      enhancement: request.enhancement.toUpperCase(),
      entityType: request.entityType,
      name: request.name.toUpperCase(),
      transport: request.transport?.toUpperCase(),
    };

    // The preview also tells which package and transport the deletion would use
    const preview = await get(ctx, 'deletePreview', target);
    if (!preview.ok) {
      return preview.result;
    }
    const violation = findPolicyViolation((JSON.parse(preview.body) as { result?: PlannedChange }).result ?? {});
    if (violation) {
      return textResult(violation, true);
    }
    if (!request.token) {
      return textResult(preview.body);
    }

    const answer = await write(ctx, { operation: 'delete', ...target, token: request.token });
    return answer.ok ? textResult(answer.body) : answer.result;
  },
};
