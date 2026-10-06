# arc-1-bopf-enh

Classic BOPF enhancements, the customer extensions of SAP standard business objects such as the SAP TM freight
order `/SCMTMS/TOR`, are maintained in the BOPF designer (transaction BOBX). ADT has no API for them, so tools that
work through ADT cannot reach them either.

arc-1-bopf-enh closes that gap for [ARC-1](https://github.com/arc-mcp/arc-1), the MCP server for SAP: an ABAP
service on SAP's BOPF configuration API and an ARC-1 extension with four tools. AI agents connected to ARC-1 can
then read, create, change, check and delete enhancement objects and their nodes, actions, determinations,
validations, queries, associations and alternative keys.

> **Status: 0.1.0.** Verified live on SAP_BASIS 816 (S/4HANA 2025): the ABAP Platform trial with the EPM sales
> order, and an S/4HANA system with SAP TM and the freight order `/SCMTMS/TOR`, both on-premise. Private cloud and
> older releases such as S/4HANA 2023 should work as well but are not tested yet. Built against ARC-1 1.5.0, verified
> with ARC-1 1.4.0 and 1.5.0. ARC-1 still marks its plugin API (`apiVersion` 1) as experimental, so a later ARC-1
> release may need an update of this extension.

## Tools

| Tool | ARC-1 policy | Purpose |
|---|---|---|
| `Custom_BopfEnhRead` | `read` | Extensible business objects, their enhancements, one enhancement with its entities, and the names SAP proposes before a create |
| `Custom_BopfEnhWrite` | `write`, create | Create and change enhancements and their entities; every change runs as a dry run first |
| `Custom_BopfEnhDelete` | `write`, delete | Delete own entities or a whole enhancement: preview with token, then deletion |
| `Custom_BopfEnhMaintain` | `write`, update | BOPF consistency check; refresh after appends to standard nodes |

[docs/tools.md](docs/tools.md) describes parameters, results, errors and the typical flows.

## Quick start

This path runs ARC-1 locally, started by your MCP client. For Docker and SAP BTP, see [Deployment](#deployment).

**You need** an SAP system with classic BOPF, tested with S/4HANA 2025 (SAP_BASIS 816) on-premise (private cloud
and older releases should work but are not tested yet); [abapGit](https://abapgit.org) in that system; and an SAP
user with developer authorization (`S_DEVELOP`) for the packages of the enhancements. Building the extension
yourself also needs Node.js 22.19 or later on Linux, macOS or WSL (the build scripts use POSIX shell commands).

1. **Set up ARC-1 first.** Follow ARC-1's [quickstart](https://docs.arc-1-mcp.com/quickstart/) and check that your
   agent can read an ABAP object through it. The extension only adds tools to a working ARC-1.
2. **Import the ABAP objects.** In abapGit, create an online repository with
   `https://github.com/abat-TAO/arc-1-bopf-enh` in a package of your choice, for example the local package
   `$ZBE_BOPF_ENH`, and pull. Without access to GitHub from the SAP system, import
   `arc-1-bopf-enh-abap-<version>.zip` from the [latest release](https://github.com/abat-TAO/arc-1-bopf-enh/releases/latest)
   as an offline repository instead. abapGit creates and activates the ICF node `/sap/bc/zbe_bopf_enh/`.
3. **Get the extension.** Download `bopf-enh.mjs` from the
   [latest release](https://github.com/abat-TAO/arc-1-bopf-enh/releases/latest), with `THIRD-PARTY-NOTICES.md` next
   to it. Or build it yourself; the result is `arc1-extension/dist/bopf-enh.mjs`:
   ```bash
   git clone https://github.com/abat-TAO/arc-1-bopf-enh.git
   cd arc-1-bopf-enh/arc1-extension && npm ci --ignore-scripts && npm run build
   ```
4. **Add it to ARC-1.** Extend the `env` block of the ARC-1 server in your MCP client configuration and restart the
   client:
   ```json
   "ARC1_PLUGINS": "<absolute path>/bopf-enh.mjs",
   "SAP_ALLOW_WRITES": "true",
   "SAP_ALLOW_PLUGIN_RAW_WRITES": "true",
   "SAP_ALLOWED_PACKAGES": "$TMP,ZTM_EXT"
   ```
5. **Try it.** Ask your agent *"Which enhancements does /BOBF/EPM_SALES_ORDER have?"*. If you built the extension
   yourself, you can also call the tool from `arc1-extension` with ARC-1's command line client and the same `SAP_*`
   settings in your shell:
   ```bash
   ARC1_PLUGINS=$PWD/dist/bopf-enh.mjs npx arc1-cli call Custom_BopfEnhRead --json '{"what":"businessObjects"}'
   ```

**Other object names.** All objects carry the code `BE` (`ZCL_BE_*`, `ZBE_*`, `$ZBE_BOPF_ENH`, ICF node
`zbe_bopf_enh`). If these names are taken in your system, the release files do not fit: clone the repository and
rename it from its root before steps 2 and 3:

```bash
node tools/rename.mjs --code XY --dry-run   # preview
node tools/rename.mjs --code XY             # ZCL_BE_ → ZCL_XY_, ZBE_ → ZXY_; --letter Y also changes Z → Y
```

The script renames the abapGit files and their contents, the extension with its service path, the tests and the
documentation, recomputes the file name of the ICF node and checks SAP's name length limits. `--map renames.json`
renames single objects. In step 2, import the renamed objects: push your copy to your own Git repository and use its
URL, or zip it (with `.abapgit.xml` and `src/`) and import it as an offline repository. In step 3, build the
extension from your copy.

## Deployment

ARC-1 loads the extension as a file at startup, wherever ARC-1 runs:

| ARC-1 runs | Supported |
|---|---|
| Locally (`npx arc-1`) | Yes, verified |
| Docker | Yes, with an image based on ARC-1's image; not verified yet |
| SAP BTP Cloud Foundry, single target | Yes, for on-premise systems through the Cloud Connector; not verified yet |
| SAP BTP Cloud Foundry, multi-target routes | No: ARC-1 loads no extensions there |
| Any, with SAP BTP ABAP Environment or S/4HANA Public Cloud | No: classic BOPF enhancements do not exist there |

[docs/deployment.md](docs/deployment.md) has the settings and steps for each setup.

## Design

- **Own ICF service.** ARC-1 extensions call SAP over HTTP, and ARC-1 refuses extension writes to `/sap/bc/adt/`.
  The ABAP side is therefore its own ICF node, `/sap/bc/zbe_bopf_enh/`: reads are `GET`, changes are one `POST`.
- **SAP's API, not table writes.** The service works through `/BOBF/CL_CONF_MODEL_API`, the API behind the BOPF
  designer, and reads the BOPF meta model directly only where that API has gaps, such as alternative keys and the
  consistency check.
- **Thin extension.** The TypeScript side holds the parameter schemas, runs the dry run before every change and
  applies the package and transport settings of the ARC-1 server.
- **Source code stays with ARC-1.** Implementation classes are generated as stubs. Implementing them, and creating
  DDIC structures and appends, is done with ARC-1's own tools (`SAPWrite`, `SAPActivate`).

## Guardrails

Three layers check every change:

1. **ARC-1** allows reads (`GET`) always. Writes need `SAP_ALLOW_WRITES`, `SAP_ALLOW_PLUGIN_RAW_WRITES` and a caller
   with the `write` scope.
2. **The extension** runs each change as a dry run in SAP first and refuses it unless its package is in
   `SAP_ALLOWED_PACKAGES` (`$TMP` when empty) and its transport in `SAP_ALLOWED_TRANSPORTS` (any when empty). ARC-1
   itself applies these two settings only to its built-in tools. The extension accepts exact names, `*` and a
   trailing `*` such as `Z*`; unlike ARC-1, an entry `ROOT/**` allows only the package `ROOT`, so list its
   subpackages explicitly.
3. **The ABAP service** changes only enhancement objects in the customer namespace (`Z*`, `Y*` or a namespace the
   system is the producer of) and only their own entities, never the standard business object. It checks
   `S_DEVELOP`, extensibility, package, transport and language, and accepts only new, valid names, including the
   names of objects BOPF generates. Deleting needs a token from a preview and stops when the enhancement changed in
   between; database tables with data are not deleted.

## Example

The user asks: *"Add a subnode NOTES under ROOT of the enhancement ZENH_TOR."* The agent then makes the following
tool calls, shown here with their arguments; nobody types them by hand. New entity names start with the prefix of
the enhancement, here `ZENH`, so the node becomes `ZENH_NOTES`:

```jsonc
// 1. Which names will BOPF generate? (Custom_BopfEnhRead)
{ "what": "names", "operation": "createNode", "enhancement": "ZENH_TOR", "node": "ROOT", "name": "ZENH_NOTES" }
// → dataStructure to create first, combinedStructure, combinedTableType, databaseTable

// 2. Create the data structure with SAPWrite and SAPActivate, then check the node (Custom_BopfEnhWrite)
{ "operation": "createNode", "enhancement": "ZENH_TOR", "node": "ROOT", "name": "ZENH_NOTES",
  "dataStructure": "ZS_NOTES_D", "dryRun": true }

// 3. The same call without dryRun creates the node; then check the enhancement (Custom_BopfEnhMaintain)
{ "operation": "check", "enhancement": "ZENH_TOR" }
// → findings of the enhancement, and baseFindings that belong to the standard business object
```

## Known limitations

- Classic BOPF only. Business objects of the ABAP Programming Model for SAP Fiori (BOPF generated from CDS views)
  are not handled.
- New subnodes cannot be made extensible themselves, because the extension does not create extension includes.
- Entities cannot be renamed. Associations, alternative keys and determination patterns change by delete and
  create.
- `scope=all` returns every entity of the standard business object, which is very large for objects such as
  `/SCMTMS/TOR`; combine it with `node`.
- The consistency check assigns findings to the standard object by the element SAP reports them for. Findings
  without such an element count as findings of the enhancement.
- Tested only with S/4HANA 2025 (SAP_BASIS 816) on-premise. Private cloud and older releases such as S/4HANA 2023
  should work as well but are not tested yet.
- ARC-1 stops every HTTP request to SAP after 120 seconds. A write makes two requests: the dry run and the change.
- Not available on SAP BTP ABAP Environment and S/4HANA Public Cloud, on ARC-1's multi-target routes and in ARC-1's
  `hyperfocused` tool mode; see [docs/deployment.md](docs/deployment.md).

## Development

[docs/development.md](docs/development.md) covers the code layout, the HTTP contract, abaplint, the ABAP Unit tests
with their test enhancement on the EPM sales order, and the build and tests of the extension
(`npm test`).

## License

[MIT](LICENSE). ARC-1 is a separate project, also under the MIT license.
