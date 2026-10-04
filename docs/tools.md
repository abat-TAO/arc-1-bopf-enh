# Tools

The extension adds four tools to ARC-1. Every tool calls the ABAP service `/sap/bc/zbe_bopf_enh/`, which does the
actual work with SAP's BOPF configuration API. This page describes what the tools do and how they work together;
each parameter is also described in the tool schema that agents see.

## Conventions

- **Names** of business objects, enhancements and entities are case-insensitive in requests and upper case in
  results. Namespaces are written with slashes: `/SCMTMS/TOR`.
- **Own and base.** An enhancement contains the entities of its standard business object (the *base*) and its own.
  Results mark own entities with `isOwn: true`; only own entities can be changed or deleted.
- **Results** are JSON in `{"result": …}`. Initial values are left out, so a missing boolean is `false`.
- **Errors of the ABAP service** come with an HTTP status and a `messages` array:

  ```json
  { "messages": [{ "severity": "E", "id": "ZBE_BOPF_ENH", "number": "010", "text": "Node ZNOTE does not exist in ZENH_TOR" }] }
  ```

  | Status | Meaning |
  |---|---|
  | 400 | Missing or invalid parameter, request body without an operation (for example not valid JSON), transport request required or not modifiable |
  | 403 | No authorization for the package, or CSRF token missing |
  | 404 | Business object, enhancement, node, action or entity does not exist |
  | 405 | HTTP method not supported for the resource |
  | 409 | Conflict with the current state: delete token outdated, object locked, name already used by another enhancement, action already enhanced, database table contains data |
  | 422 | A rule is violated (standard object, base entity, not extensible, invalid or existing name), or BOPF did not save or delete |
  | 500 | Unexpected error |

  The messages come from message class `ZBE_BOPF_ENH`; the first one is the cause, the following ones are the
  messages of SAP behind it. Errors the extension finds itself, such as a missing parameter or a package outside
  the deployment policy, come back as plain text tool errors.
- **Deployment policy.** Before a change, the extension asks the service for the package and transport the change
  would use and refuses it unless they are allowed by `SAP_ALLOWED_PACKAGES` and `SAP_ALLOWED_TRANSPORTS` of the
  ARC-1 server.

## Custom_BopfEnhRead

Reads only.

| `what` | Parameters | Returns |
|---|---|---|
| `businessObjects` | | Extensible classic standard business objects, with the number of their enhancements |
| `enhancements` | `baseBo` | Enhancement objects of one business object: package, constants interface, `isChangeable` |
| `enhancement` | `name`, optional `scope`, `node` | One enhancement with its header and entities |
| `names` | `operation`, `name` and the context of that create operation (see below) | The names SAP proposes for a planned create |

**Reading an enhancement.** Standard business objects can be large: `/SCMTMS/TOR` has more than 130 nodes and more
than 500 actions. The read therefore works in two levels:

- default (`scope=own`): the own entities in full, and the nodes of the base in short form (name, parent, type,
  `isExtensible`, `dataStructure`, `extensionInclude`), which is enough to place new nodes and appends;
- `node=<node>`: only that node, in full, with its entities, including the standard actions of the base that action
  enhancements and action validations refer to;
- `scope=all`: also the actions, determinations, validations, queries and associations of the base. Without `node`
  this is everything of the standard object.

**Names lookup.** Some names cannot be changed once BOPF has generated the objects: implementation classes, the
constants interface, the combined structure and table type and the database table of a node. `what=names` returns
the names SAP would use for a planned create. It creates nothing; it resolves the enhancement, node or action of the
request, but does not run the checks of the create itself.

| `operation` | Context |
|---|---|
| `createEnhancement` | none, only `name` |
| `createNode`, `createAction`, `createDetermination`, `createValidation`, `createAssociation` | `enhancement`, `node` |
| `createActionEnhancement` | `enhancement`, `baseAction` |
| `createActionValidation` | `enhancement`, `action` |

Queries and alternative keys have no names lookup. New entity names start with the prefix of the enhancement, for
example `ZENH` for `ZENH_TOR`:

```json
{ "what": "names", "operation": "createNode", "enhancement": "ZENH_TOR", "node": "ROOT", "name": "ZENH_NOTES" }
```

The result names the objects BOPF will generate (`class`, `constantsInterface`, `combinedStructure`,
`combinedTableType`, `databaseTable`) and the DDIC objects to create beforehand (`dataStructure`,
`transientStructure`, `parameterStructure`), with the same names as the parameters of `Custom_BopfEnhWrite`.
`hints` reports proposals that cannot work, for example a database table name SAP truncates.

## Custom_BopfEnhWrite

One call is one change, saved immediately. Before saving, the tool runs the same request as a dry run in SAP and
applies the deployment policy; with `dryRun: true` it stops there.

| Operation | Required parameters |
|---|---|
| `createEnhancement` | `name`, `baseBusinessObject`, `package` |
| `updateEnhancement` | `enhancement`, `description` |
| `createNode` | `enhancement`, `node` (parent), `name`, `dataStructure` (not for transient nodes, `isTransient: true`) |
| `createAction` | `enhancement`, `node`, `name` |
| `createActionEnhancement` | `enhancement`, `baseAction`, `timing` (`pre` or `post`), `name` |
| `createDetermination` | `enhancement`, `node`, `name`; `pattern` `afterModify` (default) or `beforeSave` |
| `createValidation` | `enhancement`, `node`, `name` |
| `createActionValidation` | `enhancement`, `action`, `name` |
| `createQuery` | `enhancement`, `node`, `name` |
| `createAssociation` | `enhancement`, `node`, `name`, `targetBusinessObject`; `targetNode` defaults to `ROOT` |
| `createAlternativeKey` | `enhancement`, `node`, `name`, `fields`, `dataType`, `tableType` |
| `updateAction`, `updateDetermination`, `updateValidation`, `updateNode`, `updateQuery` | `enhancement`, `name` and the fields to change |

Further parameters (descriptions, classes, cardinalities, triggers, write nodes, uniqueness, transport, language)
are described in the tool schema.

**Result.** `operation`, `enhancement`, `entityType`, `entity`, `class`, `package`, `transport`, `language`, and:

- `class`: the implementation class; for `createEnhancement` the constants interface, for `createNode` the combined
  structure;
- `generated`: every object BOPF generates, also in a dry run, each with its type and name;
- `alreadyExisted`: an entity with this name exists, and the create changed nothing. Its definition is not compared
  with the request; read it to compare;
- `unchanged`: an update of an entity got the values it already has. `updateEnhancement` does not report it.

**Names.** Without explicit names, SAP's proposals are used. New names must not exist yet and must be valid customer
names. Implementation classes are generated as stubs, or reused when the class already exists.

**Triggers and write nodes.** Determinations and validations run when their trigger nodes change: by default on
create and update of their own node. A trigger on another node needs an association from that node to the node of
the entity; the service picks the parent, composition or root association when none is given.

### Typical flows

**New enhancement or entity with names the user chooses.**

1. `Custom_BopfEnhRead what=names` (or a dry run) shows the names SAP would generate.
2. The user confirms them or chooses others (`class`, `constantsInterface`, `combinedStructure`, …).
3. The create operation saves the entity.

**New subnode.** Create and activate its data structure with ARC-1's DDIC tools, then `createNode` with
`dataStructure`. The node gets a combined structure, a combined table type and a database table (at most 16
characters; pass `databaseTable` when SAP's proposal is too long).

**Fields on a standard node.** Append the fields to the node's `extensionInclude` (or, without one, to its
`dataStructure`) with ARC-1's `SAPWrite` (type `TABL/DS` for an append) and activate it. Then run
`Custom_BopfEnhMaintain` `refresh`, so the constants interface and the runtime buffer know the new fields. The same
applies after changing the data structure of an own subnode.

**Enhancing a standard action.** `Custom_BopfEnhRead what=enhancement node=ROOT` lists the actions of `ROOT`; then
`createActionEnhancement` with `baseAction` and `timing`. A standard action can have one `pre` and one `post`
enhancement per enhancement object, and only when the action is extensible.

**Implementing.** The generated classes are stubs. Agents implement their methods with ARC-1's source tools
(`SAPWrite`, `SAPActivate`).

## Custom_BopfEnhDelete

Deletes own entities, or a whole enhancement object, in two calls. Both take `enhancement`, `entityType` and
`name`; to delete the whole enhancement, use `entityType: "enhancement"` and its name in both `enhancement` and
`name`.

1. **Preview** (without `token`): everything that would be deleted, in deletion order, including dependent
   entities (subnodes, entities on deleted nodes, validations of deleted actions, generated DDIC objects); what stays
   (implementation classes, DDIC objects created by the developer); and a `token`.
2. **Delete** (the same parameters plus that `token`): deletes exactly what the preview showed.

The token is invalid as soon as the enhancement changes; the preview has to be read again (status 409). A node whose
database table contains data is not deleted. `entityType` is one of `enhancement`, `node`, `action`,
`actionEnhancement`, `determination`, `validation`, `query`, `association` and `alternativeKey`; `enhancement` deletes
the enhancement object with all its entities and its constants interface.

## Custom_BopfEnhMaintain

**`check`** runs the BOPF consistency check of the enhancement, as the BOPF designer does, and changes nothing.

- `findings` are the enhancement's own, with `entityType` and `entityName` when SAP reports them for an element.
  Findings without an element concern the enhancement as a whole.
- `baseFindings` are reported for elements of the standard business object. They are usually SAP's own and exist in
  the standard object as well; they matter only when a change of the enhancement caused them.

Example contents of `result`:

```json
{
  "enhancement": "ZENH_TOR",
  "findings": [{ "severity": "E", "text": "Lost elements that are obsolete exist in the configuration" }],
  "baseFindings": [
    {
      "severity": "W",
      "text": "Determination DET_ROOT_FILL_OVERVIEW is never executed because requesting nodes are not defined",
      "entityType": "determination",
      "entityName": "DET_ROOT_FILL_OVERVIEW"
    }
  ]
}
```

**`refresh`** regenerates the constants interface of the enhancement and invalidates the runtime buffer of the
enhancement and its standard object. It is needed after appends to standard nodes and after changes of the data
structure of own subnodes. Like a write, it runs as a dry run first; `dryRun: true` checks only authorization,
package and transport.
