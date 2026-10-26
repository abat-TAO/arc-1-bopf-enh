import { z } from 'zod';
import type { PluginToolDefinition } from 'arc-1/public';
import { findPolicyViolation, type PlannedChange } from '../policy.js';
import { objectNamePattern, read, textResult, write } from '../service.js';

const schema = z.object({
  enhancement: z.string().regex(objectNamePattern).describe('Enhancement object, e.g. ZENH_TOR'),
  operation: z
    .enum(['check', 'refresh', 'correct'])
    .describe(
      'check: BOPF consistency check of the enhancement. findings are the enhancement\'s own, with entityType ' +
        'and entityName when SAP locates them at an entity (no entity: the enhancement as a whole). baseFindings ' +
        'are located at the standard business object and usually SAP\'s own; act on them only if your change ' +
        'caused them. ' +
        'refresh: regenerate the constants interface of the enhancement, run Check & Correct and invalidate the ' +
        'runtime buffer, needed after appends to standard nodes and after changes of the data structure of own subnodes. ' +
        'correct: Check & Correct of the BOPF designer; removes configuration entries the check reports as lost ' +
        'elements and regenerates the constants interface. Changes through these tools end with it anyway; use it ' +
        'for enhancements changed elsewhere, when the check says "Run Check & Correct", or after correctionFailed.',
    ),
  transport: z.string().regex(/^[A-Za-z0-9]{10}$/).optional().describe(
    'refresh, correct: workbench request or task for the constants interface, unless it is already in a request',
  ),
  dryRun: z.boolean().optional().describe('refresh, correct: only check authorization, package and transport'),
});

export const maintainTool: PluginToolDefinition = {
  name: 'Custom_BopfEnhMaintain',
  description:
    'Maintain a classic BOPF enhancement object: run the BOPF consistency check, refresh it after fields were ' +
    'appended to a standard node (constants interface and runtime buffer), or run Check & Correct as the BOPF ' +
    'designer does. The check changes nothing.',
  schema,
  policy: { scope: 'write', opType: 'U' },
  availableOn: 'onprem',
  async handler(args, ctx) {
    const request = schema.parse(args);
    const enhancement = request.enhancement.toUpperCase();
    if (request.operation === 'check') {
      return read(ctx, 'check', { enhancement });
    }

    const change = { operation: request.operation, enhancement, transport: request.transport?.toUpperCase() };
    const check = await write(ctx, { ...change, dryRun: true });
    if (!check.ok) {
      return check.result;
    }
    const violation = findPolicyViolation((JSON.parse(check.body) as { result?: PlannedChange }).result ?? {});
    if (violation) {
      return textResult(violation, true);
    }
    if (request.dryRun) {
      return textResult(check.body);
    }
    const answer = await write(ctx, change);
    return answer.ok ? textResult(answer.body) : answer.result;
  },
};
