# Deployment

The extension is one JavaScript file, `bopf-enh.mjs`, that ARC-1 loads at startup. Download it from the
[latest release](https://github.com/abat-TAO/arc-1-bopf-enh/releases/latest), or build it as described in the
README. How the file gets to ARC-1 depends on how ARC-1 runs. Set up ARC-1 first with its own
[deployment documentation](https://docs.arc-1-mcp.com/deployment/) and make sure a plain read works; then add the
extension as described here.

The extension is tested only with S/4HANA 2025 (SAP_BASIS 816) on-premise. Private cloud and older releases such as
S/4HANA 2023 should work as well but are not tested yet.

## Supported setups

| ARC-1 runs | SAP system | Status |
|---|---|---|
| Locally, started by the MCP client (`npx arc-1`) | On-premise | Supported, verified with S/4HANA 2025 |
| Locally, started by the MCP client (`npx arc-1`) | Private cloud | Supported, not verified yet |
| Docker on a VM or container host | On-premise or private cloud | Supported, not verified yet |
| SAP BTP Cloud Foundry, single target (`/mcp`) | On-premise or private cloud through the Cloud Connector | Supported, not verified yet |
| SAP BTP Cloud Foundry, multi-target routes (`/<SYSTEM>/<CLIENT>/mcp`, `/multi/mcp`) | On-premise | Not possible: ARC-1 loads no extensions on these routes |
| Any | SAP BTP ABAP Environment | Not possible, see below |
| Any | SAP S/4HANA Public Cloud | Not possible, see below |

"Not verified yet" means the steps follow ARC-1's documentation for extensions but have not been run end to end with
this extension. Reports are welcome.

## What every setup needs

- The ABAP objects imported into the SAP system, with the ICF node `/sap/bc/zbe_bopf_enh/` active (abapGit activates
  it on every pull).
- These settings in the environment of the ARC-1 server:

  | Setting | Value |
  |---|---|
  | `ARC1_PLUGINS` | Absolute path of `bopf-enh.mjs`, written out in full: ARC-1 does not expand `$HOME` or other variables |
  | `SAP_ALLOW_WRITES` | `true` |
  | `SAP_ALLOW_PLUGIN_RAW_WRITES` | `true`, so that extensions may call non-ADT services with `POST` |
  | `SAP_ALLOWED_PACKAGES` | Packages of the enhancements to change; `$TMP` when empty. Exact names, `*` and a trailing `*` such as `Z*` work; unlike ARC-1, `ROOT/**` allows only `ROOT` itself, so list subpackages explicitly |
  | `SAP_ALLOWED_TRANSPORTS` | Optional: transport requests the extension may use; any when empty |

- On Linux and macOS, ARC-1 loads the file only if it belongs to the user ARC-1 runs as and is not writable for
  everybody. `npm run build` creates it with mode `644`.
- ARC-1 reads the file once at startup: restart ARC-1 after every new build.
- ARC-1 runs in its standard tool mode. In the `hyperfocused` mode (`ARC1_TOOL_MODE`), which offers a single `sap`
  tool, ARC-1 lists no extension tools.
- The SAP user ARC-1 calls SAP with needs developer authorization (`S_DEVELOP`) for the enhancement packages. With
  principal propagation, this applies to every user who changes enhancements.
- Whatever route ARC-1 takes to the SAP system (direct, proxy, Cloud Connector) has to allow
  `/sap/bc/zbe_bopf_enh/` in addition to `/sap/bc/adt/`.

## Locally

ARC-1 runs as a subprocess of the MCP client. Add the settings to the `env` block of the ARC-1 server in the client
configuration, next to the SAP connection settings, and restart the client:

```json
"env": {
  "SAP_URL": "https://your-sap-host:44300",
  "SAP_USER": "YOUR_USER",
  "SAP_PASSWORD": "YOUR_PASSWORD",
  "SAP_CLIENT": "100",
  "ARC1_PLUGINS": "/home/you/arc-1-bopf-enh/arc1-extension/dist/bopf-enh.mjs",
  "SAP_ALLOW_WRITES": "true",
  "SAP_ALLOW_PLUGIN_RAW_WRITES": "true",
  "SAP_ALLOWED_PACKAGES": "$TMP,ZTM_EXT"
}
```

## Docker

Build an image on top of ARC-1's image that contains the extension. Put `bopf-enh.mjs` and `THIRD-PARTY-NOTICES.md`
from the release next to the Dockerfile and copy them with `--chown`: ARC-1 runs as the user `arc1`, and a file
copied as `root` is refused.

```dockerfile
FROM ghcr.io/arc-mcp/arc-1:1.5.0
COPY --chown=arc1:arc1 bopf-enh.mjs THIRD-PARTY-NOTICES.md /home/arc1/plugins/bopf-enh/
ENV ARC1_PLUGINS=/home/arc1/plugins/bopf-enh/bopf-enh.mjs \
    SAP_ALLOW_WRITES=true \
    SAP_ALLOW_PLUGIN_RAW_WRITES=true
```

Run it like ARC-1's own image ([Docker guide](https://docs.arc-1-mcp.com/docker/)) and pass `SAP_ALLOWED_PACKAGES`
and the connection settings at runtime. Mounting the file into the stock image instead works only if its owner on
the host has the user ID of `arc1` in the container.

The bundle contains the library zod, whose license text is in `THIRD-PARTY-NOTICES.md`; keep that file next to the
bundle, also in the application files on SAP BTP. If you build the bundle yourself, use
`arc1-extension/node_modules/zod/LICENSE` instead.

## SAP BTP Cloud Foundry

Follow ARC-1's [Cloud Foundry deployment](https://docs.arc-1-mcp.com/btp-cloud-foundry-deployment/) for a single
target (`/mcp`), then:

1. **Bring the file into the app.** Either push the Docker image from above
   (`cf push <app> --docker-image <registry>/<image>:<tag>`), or put `bopf-enh.mjs` into the application files of
   the buildpack deployment, for example under `plugins/bopf-enh/`, and set
   `ARC1_PLUGINS=/home/vcap/app/plugins/bopf-enh/bopf-enh.mjs`. Files pushed with the buildpack already belong to the
   app user.
2. **Allow writes.** ARC-1's example profiles start read-only. Set `SAP_ALLOW_WRITES`, `SAP_ALLOW_PLUGIN_RAW_WRITES`
   and `SAP_ALLOWED_PACKAGES` in your landscape extension.
3. **Open the path in the Cloud Connector.** The mapping of the SAP system usually exposes only `/sap/bc/adt` with its
   sub-paths. Add `/sap/bc/zbe_bopf_enh` with its sub-paths.
4. **Roles.** XSUAA needs no change: the tools use ARC-1's built-in scopes. Reading needs `read`; writing, deleting
   and the check need `write`.

The multi-target routes of ARC-1 are read-only by design and load no extensions. To work on several systems, run one
single-target ARC-1 per system.

## Not supported

- **SAP BTP ABAP Environment and SAP S/4HANA Public Cloud.** Both allow only ABAP Cloud development. Classic BOPF
  enhancements and the BOPF configuration API are not available there, and the classic ABAP objects of this
  repository cannot be imported. The tools are marked for on-premise systems, so ARC-1 does not offer them for these
  targets.
- **ARC-1 multi-target routes**, see above.
- **ARC-1 in `hyperfocused` tool mode**, see above.
