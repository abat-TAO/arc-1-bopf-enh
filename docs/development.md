# Development

## Layout

### ABAP (`src/`, abapGit format)

| Object | Purpose |
|---|---|
| `ZCL_BE_HTTP_HANDLER` | ICF handler of `/sap/bc/zbe_bopf_enh/`: routing, CSRF protection of writes, `{"result": …}` and `{"messages": […]}` answers with HTTP status |
| `ZCL_BE_JSON` | JSON conversion of the HTTP contract: camelCase names, initial values left out |
| `ZCL_BE_READER` | Read access to business objects, enhancements and their entities |
| `ZCL_BE_WRITER` | Create and update operations and the names lookup, through `/BOBF/CL_CONF_MODEL_API`: every request is checked, written and read back |
| `ZCL_BE_DELETER` | Two-step deletion: preview in execution order, token, delete |
| `ZCL_BE_MAINTAINER` | Consistency check and refresh |
| `ZCL_BE_META_MODEL` | Direct access to the BOPF meta model for what the configuration API lacks: alternative keys, deleting actions, the consistency check |
| `ZCL_BE_CHANGE_CONTEXT` | Checks required for every change: enhancement, customer namespace, authorization, package, transport request, language |
| `ZCL_BE_SESSION` | Dialog-free session for the configuration API, the only place that sets the switches of `/BOBF/CL_CONF_TOOLBOX` |
| `ZCX_BE_ERROR` | Exception with a message of `ZBE_BOPF_ENH` and an HTTP status |
| `ZCL_BE_TEST_FIXTURE` | Console application that creates the test enhancement `ZBE_TEST_SO` |
| `ZBE_BOPF_ENH` | Message class |
| `ZBE_S_TEST_*`, `ZBE_T_TEST_PRIORITY`, `ZBE_TEST_PRIORITY` | DDIC objects of the test enhancement |

### Extension (`arc1-extension/`)

| File | Purpose |
|---|---|
| `src/index.ts` | Plugin definition with the four tools |
| `src/tools/*.ts` | One file per tool: schema, description, handler |
| `src/service.ts` | HTTP calls to the ABAP service and error handling |
| `src/policy.ts` | Deployment policy from `SAP_ALLOWED_PACKAGES` and `SAP_ALLOWED_TRANSPORTS` |
| `tests/` | Tests of the tools against a fake ARC-1 context |

The ABAP service enforces the rules of BOPF enhancements on its own (customer namespace, own entities only,
extensibility, authorization); the extension adds the deployment policy of the ARC-1 server on top.

## HTTP contract

All resources are under `/sap/bc/zbe_bopf_enh/`. Reads are `GET` with query parameters, changes are `POST /write`
with a JSON body: ARC-1 treats every `POST` of an extension as a write, which needs the write settings.

| Request | Purpose |
|---|---|
| `GET businessobjects` | Extensible standard business objects |
| `GET enhancements?baseBo=` | Enhancement objects of a business object |
| `GET enhancement?name=&scope=&node=` | One enhancement |
| `GET names?operation=&name=&enhancement=&node=&baseAction=&action=` | Name proposals for a planned create |
| `GET deletepreview?enhancement=&entityType=&name=&transport=` | Delete preview with token |
| `GET check?enhancement=` | Consistency check |
| `POST write` | Body `{"operation": …}`: every create and update operation, `delete` (with token) and `refresh`; `dryRun: true` checks only |

`POST` needs a CSRF token, which ARC-1 fetches on its own.

## Code style

abaplint checks the ABAP code against `abaplint.jsonc` (Clean ABAP: no prefixes, descriptive English names, one
place per message):

```bash
npx @abaplint/cli abaplint.jsonc
```

SAP standard objects come from [abaplint/deps](https://github.com/abaplint/deps); clone it into `./deps` to work
offline. abaplint treats SAP objects it does not know as void, so a clean run does not prove that the code compiles:
check the syntax in the SAP system before an import.

## ABAP Unit

Most tests need the test enhancement `ZBE_TEST_SO` of the EPM demo business object `/BOBF/EPM_SALES_ORDER`:

1. Run `ZCL_BE_TEST_FIXTURE` as a console application (F9 in ADT). It creates the enhancement in `$TMP` with nodes,
   actions, action enhancements, determinations, validations, a query, an association and an alternative key, and
   prints one line per step. Existing entities are left as they are, so it can run again.
2. Run the ABAP Unit tests of the package. Without the test enhancement, the tests that need it are skipped.

The tests only read the test enhancement and use dry runs; they do not change it. The test classes are
`RISK LEVEL HARMLESS`; the writer tests take longer than a minute on slower systems and are `DURATION MEDIUM`.

## Extension

```bash
cd arc1-extension
npm ci --ignore-scripts   # ARC-1's native modules are not needed for building and testing
npm run build    # type check and bundle to dist/bopf-enh.mjs
npm test         # tests of the tools
npm run tools    # lists the tools as ARC-1 loads them
```

The scripts use POSIX shell commands (`chmod`, `$PWD`), so build on Linux, macOS or WSL. The bundle is one
self-contained ES module: ARC-1 loads it through `ARC1_PLUGINS` without a `node_modules` folder.
Most of its size is zod, the schema library of the tool parameters. `dist/` is not part of the repository.

## Continuous integration

`.github/workflows/pr.yml` runs on every pull request against `main`:

- abaplint, reporting only the findings the pull request adds;
- build, tests and tool listing of the extension.

## Third-party components

| Component | License | Use |
|---|---|---|
| [ARC-1](https://github.com/arc-mcp/arc-1) | MIT | Plugin host; type definitions at build time |
| [zod](https://github.com/colinhacks/zod) | MIT | Tool parameter schemas; bundled into `dist/bopf-enh.mjs` |
| [esbuild](https://github.com/evanw/esbuild), [TypeScript](https://github.com/microsoft/TypeScript) | MIT, Apache-2.0 | Build |
| [abaplint](https://github.com/abaplint/abaplint), [abaplint/deps](https://github.com/abaplint/deps) | MIT | ABAP code checks |
| [abapGit](https://github.com/abapGit/abapGit) | MIT | Import into the SAP system |

A distributed copy of the bundle contains zod and therefore has to carry zod's license text; releases ship it as
`THIRD-PARTY-NOTICES.md`.

## Releases

A release is a tag `v<version>` on `main` with four files built from exactly that tag:

| File | How |
|---|---|
| `bopf-enh.mjs` | `npm ci --ignore-scripts && npm run build` in a clean checkout of the tag (`git worktree add --detach <dir> v<version>`); the build is reproducible |
| `arc-1-bopf-enh-abap-v<version>.zip` | `git archive --format=zip -o <file> v<version> .abapgit.xml src`, for abapGit offline imports |
| `THIRD-PARTY-NOTICES.md` | Name, version and license text of zod from `arc1-extension/node_modules/zod` |
| `SHA256SUMS` | `sha256sum` of the three files above |

Set the plugin version in `arc1-extension/src/index.ts` and `arc1-extension/package.json` to the release version
before tagging. Publish with `gh release create v<version> --latest` and the four files.
