import { z } from 'zod';
import type { PluginToolDefinition } from 'arc-1/public';
import { findPolicyViolation, isPackageAllowed, type PlannedChange } from '../policy.js';
import { objectNamePattern, textResult, write } from '../service.js';

const objectName = z.string().regex(objectNamePattern);

const schema = z.object({
  operation: z
    .enum([
      'createEnhancement',
      'updateEnhancement',
      'createAction',
      'createActionEnhancement',
      'createDetermination',
      'createValidation',
      'createActionValidation',
      'createNode',
      'createQuery',
      'createAssociation',
      'createAlternativeKey',
      'updateAction',
      'updateDetermination',
      'updateValidation',
      'updateNode',
      'updateQuery',
    ])
    .describe(
      'createEnhancement: new enhancement object (name, baseBusinessObject, package). ' +
        'updateEnhancement: new description. createAction: action on node. ' +
        'createActionEnhancement: pre or post enhancement (timing) of an extensible standard action (baseAction). ' +
        'createDetermination: on node, pattern afterModify or beforeSave. createValidation: consistency validation on node. ' +
        'createActionValidation: validation of action. createNode: subnode under node, persistent data structure must exist. ' +
        'createQuery: select-by-elements query on node. createAssociation: from node to targetBusinessObject/targetNode. ' +
        'createAlternativeKey: key on node over fields (dataType and tableType must exist). ' +
        'update*: change an own entity (name); only the given fields change, the same values again return unchanged. ' +
        'updateAction: description, class, parameterStructure, cardinality (the last two not for pre/post enhancements). ' +
        'updateDetermination: description, class, triggers, writeNodes. updateValidation: description, class, impact, triggers ' +
        '(action validations: description, class). updateNode: description. updateQuery: description, dataStructure. ' +
        'Renaming is not possible; associations, alternative keys and determination patterns change by delete and create.',
    ),
  enhancement: objectName.optional().describe('Enhancement object to change; not used for createEnhancement'),
  name: objectName.optional().describe('Name of the new or changed enhancement or entity; new names start with the enhancement prefix'),
  description: z.string().max(40).optional(),
  baseBusinessObject: objectName.optional().describe('createEnhancement: standard business object, e.g. /SCMTMS/TOR'),
  node: objectName.optional().describe('Node the entity belongs to; for createNode the parent node'),
  baseAction: objectName.optional().describe('createActionEnhancement: standard action to enhance'),
  timing: z.enum(['pre', 'post']).optional().describe('createActionEnhancement'),
  action: objectName.optional().describe('createActionValidation: action to validate'),
  class: objectName.optional().describe('Implementation class; default is the class name SAP proposes, generated as stub'),
  constantsInterface: objectName.optional().describe(
    'createEnhancement: constants interface to generate; default is the name SAP proposes. Must not exist yet',
  ),
  parameterStructure: objectName.optional().describe('createAction, createAssociation, updateAction: existing DDIC structure'),
  cardinality: z.enum(['many', 'one', 'static', 'zeroToOne', 'oneToMany']).optional().describe(
    'Actions: many (default), one, static. createAssociation: many (default), one, zeroToOne, oneToMany',
  ),
  pattern: z.enum(['afterModify', 'beforeSave']).optional().describe('createDetermination, default afterModify'),
  impact: z.enum(['messages', 'preventSave']).optional().describe('createValidation, updateValidation; default messages'),
  triggers: z
    .array(
      z.object({
        node: objectName.optional().describe('Node whose changes trigger; default: the node of the entity'),
        association: objectName
          .optional()
          .describe('Association from the trigger node to the node of the entity; default TO_PARENT, composition or TO_ROOT'),
        onCreate: z.boolean().optional(),
        onUpdate: z.boolean().optional(),
        onDelete: z.boolean().optional(),
      }),
    )
    .optional()
    .describe('Determination/validation triggers; on create default: create and update of the node'),
  writeNodes: z
    .array(
      z.object({
        node: objectName.describe('Further node the determination changes; its own node is always included'),
        association: objectName.optional().describe('Association from that node to the node of the determination'),
      }),
    )
    .optional()
    .describe('createDetermination, updateDetermination'),
  dataStructure: objectName.optional().describe('createNode: persistent data structure (must exist and be active); updateQuery'),
  transientStructure: objectName.optional().describe('createNode: transient data structure'),
  databaseTable: z.string().regex(/^[A-Za-z0-9_/]{1,16}$/).optional().describe(
    'createNode: database table, at most 16 characters, must not exist; default: SAP proposal, which fails for long node names',
  ),
  combinedStructure: objectName.optional().describe(
    'createNode: combined structure to generate; default is the name SAP proposes. Must not exist yet and must ' +
      'differ from combinedTableType and databaseTable',
  ),
  combinedTableType: objectName.optional().describe(
    'createNode: combined table type to generate; default is the name SAP proposes. Must not exist yet and must ' +
      'differ from combinedStructure and databaseTable',
  ),
  isTransient: z.boolean().optional().describe('createNode: transient node without database table'),
  isExtensible: z.boolean().optional().describe('createEnhancement: enhancement can be enhanced further'),
  targetBusinessObject: objectName.optional().describe(
    'createAssociation. The base business object of the enhancement references other instances of it ' +
      '(like ASSIGNED_FUS of /SCMTMS/TOR)',
  ),
  targetNode: objectName.optional().describe('createAssociation, default ROOT'),
  fields: z.array(z.string().regex(/^[A-Za-z0-9_]{1,30}$/)).optional().describe('createAlternativeKey: key fields'),
  dataType: objectName.optional().describe('createAlternativeKey: data element (one field) or structure'),
  tableType: objectName.optional().describe('createAlternativeKey: table type of dataType'),
  uniqueness: z.enum(['notUnique', 'unique', 'uniqueIfNotInitial']).optional().describe('createAlternativeKey, default notUnique'),
  uniquenessCheck: z.enum(['beforeSave', 'afterModify', 'none']).optional().describe(
    'createAlternativeKey with unique keys, default beforeSave; afterModify adds the uniqueness validation of the node',
  ),
  package: z.string().regex(/^\$?[A-Za-z0-9_/]{1,30}$/).optional().describe('createEnhancement: package'),
  transport: z.string().regex(/^[A-Za-z0-9]{10}$/).optional().describe(
    'Workbench request or task; needed for packages that record changes unless the object is already in a request',
  ),
  language: z.string().regex(/^[A-Za-z]{1,2}$/).optional().describe(
    'Language of texts (E, D, EN, DE); default: original language of the enhancement',
  ),
  dryRun: z.boolean().optional().describe('Only check: names, extensibility, authorization, package, transport'),
});

type WriteArgs = z.infer<typeof schema>;

function policyViolation(args: WriteArgs, answer: string): string | undefined {
  const planned = (JSON.parse(answer) as { result?: PlannedChange }).result ?? {};
  if (args.operation === 'createEnhancement' && args.package && !isPackageAllowed(args.package)) {
    return `Package ${args.package} is not in SAP_ALLOWED_PACKAGES of this ARC-1 server`;
  }
  return findPolicyViolation(planned);
}

export const writeTool: PluginToolDefinition = {
  name: 'Custom_BopfEnhWrite',
  description:
    'Create or change classic BOPF enhancement objects (enhancements of SAP standard business objects, e.g. SAP TM). ' +
    'One call is one change and is saved immediately; creating an existing name returns alreadyExisted. ' +
    'Implementation classes are generated as stubs (result.class): implement their methods afterwards with SAPWrite. ' +
    'result.generated lists every object BOPF generates (also in a dry run). Generated names cannot be changed later: ' +
    'when the user did not name the objects, get the proposals with Custom_BopfEnhRead what=names or a dryRun, ' +
    'show them to the user and create afterwards. ' +
    'Fields on standard nodes: append to the node extensionInclude (Custom_BopfEnhRead; without one, to its dataStructure) ' +
    'with SAPWrite and SAPActivate. Fields on own subnodes: change their dataStructure with SAPWrite and SAPActivate. ' +
    'In both cases run Custom_BopfEnhMaintain refresh afterwards. Use dryRun first when unsure. ' +
    'Read the enhancement with Custom_BopfEnhRead to find node names; node=<node> lists the standard actions of a ' +
    'node. Delete with Custom_BopfEnhDelete.',
  schema,
  policy: { scope: 'write', opType: 'C' },
  availableOn: 'onprem',
  async handler(args, ctx) {
    const request = schema.parse(args);

    // The dry run tells which package and transport the service would use
    const check = await write(ctx, { ...request, dryRun: true });
    if (!check.ok) {
      return check.result;
    }
    const violation = policyViolation(request, check.body);
    if (violation) {
      return textResult(violation, true);
    }
    if (request.dryRun) {
      return textResult(check.body);
    }

    const answer = await write(ctx, request);
    return answer.ok ? textResult(answer.body) : answer.result;
  },
};
