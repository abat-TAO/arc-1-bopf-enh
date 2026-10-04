import { z } from 'zod';
import type { PluginToolDefinition } from 'arc-1/public';
import { objectNamePattern, read } from '../service.js';

const objectName = z.string().regex(objectNamePattern);

const schema = z.object({
  what: z
    .enum(['businessObjects', 'enhancements', 'enhancement', 'names'])
    .describe(
      'businessObjects: extensible standard business objects. ' +
        'enhancements: enhancement objects of one business object (needs baseBo). ' +
        'enhancement: one enhancement object with its entities (needs name; see scope and node). ' +
        'names: the names SAP proposes for a planned create operation (needs operation and name, and the parameters ' +
        'the create call takes: enhancement, node, baseAction, action). Returns the objects BOPF will generate ' +
        '(class, constantsInterface, combinedStructure, combinedTableType, databaseTable) and the DDIC objects to ' +
        'create beforehand (dataStructure, transientStructure, parameterStructure), named like the ' +
        'Custom_BopfEnhWrite parameters. Nothing is created and the checks of the create do not run; hints report ' +
        'proposals that cannot work. No lookup for createQuery and createAlternativeKey.',
    ),
  baseBo: objectName.optional().describe('Standard business object, e.g. /SCMTMS/TOR'),
  name: objectName
    .optional()
    .describe('what=enhancement: enhancement object, e.g. ZENH_TOR. what=names: name of the new enhancement or entity'),
  operation: z
    .enum([
      'createEnhancement',
      'createNode',
      'createAction',
      'createActionEnhancement',
      'createDetermination',
      'createValidation',
      'createActionValidation',
      'createAssociation',
    ])
    .optional()
    .describe('what=names: planned Custom_BopfEnhWrite operation'),
  enhancement: objectName.optional().describe('what=names: enhancement object of the entity'),
  node: objectName
    .optional()
    .describe(
      'what=enhancement: limit the result to one node, e.g. ROOT; returns that node in full with its standard ' +
        'actions (the targets of createActionEnhancement and createActionValidation). ' +
        'what=names: node of the entity; for createNode the parent node',
    ),
  baseAction: objectName.optional().describe('what=names, createActionEnhancement: standard action to enhance'),
  action: objectName.optional().describe('what=names, createActionValidation: action to validate'),
  scope: z
    .enum(['own', 'all'])
    .optional()
    .describe(
      'For what=enhancement. own (default): entities of the enhancement in full plus the nodes of the base ' +
        'business object in short form (name, parent, type, isExtensible, dataStructure, extensionInclude). ' +
        'all: also the actions, determinations, validations, queries and associations of the base; this can be ' +
        'very large for big business objects such as /SCMTMS/TOR, so combine it with node.',
    ),
});

export const readTool: PluginToolDefinition = {
  name: 'Custom_BopfEnhRead',
  description:
    'Read classic BOPF enhancement objects (enhancements of SAP standard business objects): ' +
    'list extensible business objects, list the enhancements of a business object, ' +
    'or read one enhancement with its nodes, actions, determinations, validations, queries, associations and ' +
    'alternative keys. Entities carry isOwn (belongs to the enhancement) and isChangeable on the header; ' +
    'missing booleans are false. what=names gives SAP\'s name proposals before a create.',
  schema,
  policy: { scope: 'read', opType: 'R' },
  availableOn: 'onprem',
  async handler(args, ctx) {
    const { what, baseBo, name, scope, operation, enhancement, node, baseAction, action } = schema.parse(args);
    if (what === 'enhancements' && !baseBo) {
      return { content: [{ type: 'text', text: 'baseBo is required for what=enhancements' }], isError: true };
    }
    if (what === 'enhancement' && !name) {
      return { content: [{ type: 'text', text: 'name is required for what=enhancement' }], isError: true };
    }
    if (what === 'names') {
      if (!operation || !name) {
        return { content: [{ type: 'text', text: 'operation and name are required for what=names' }], isError: true };
      }
      return read(ctx, what, {
        operation,
        name: name.toUpperCase(),
        enhancement: enhancement?.toUpperCase(),
        node: node?.toUpperCase(),
        baseAction: baseAction?.toUpperCase(),
        action: action?.toUpperCase(),
      });
    }
    return read(ctx, what, {
      baseBo: baseBo?.toUpperCase(),
      name: name?.toUpperCase(),
      scope,
      node: node?.toUpperCase(),
    });
  },
};
