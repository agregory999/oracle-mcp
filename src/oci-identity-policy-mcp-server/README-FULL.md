# OCI Identity Policy MCP Server: Full Guide

This module is a thin, pip-only wrapper around the released
[`oci-policy-analysis`](https://github.com/agregory999/oci-policy-analysis)
package. It exposes that package's MCP entry point without duplicating its
implementation.

The wrapper requires Python 3.13 or later and `oci-policy-analysis` 6.5.1 or
later. It does not provide a container image or OCI Container Instance
deployment path.

## What it provides

The implementation comes from `oci-policy-analysis[mcp]`. Its MCP tools
search OCI IAM policies, users, groups, dynamic groups, identity domains,
compartments, cached snapshots, and cross-tenancy policy statements.

| Tool | Use it for |
| --- | --- |
| `policy_search` | One policy question, such as who can manage a resource. |
| `identity_search` | Finding a user, group, dynamic group, domain, or membership. |
| `data_operations` | Checking readiness, loading a cache, or reloading OCI data. |
| `policy_history_search` | Comparing policy results across cached snapshots. |

## Prerequisites and IAM access

Install Python 3.13 or later and the OCI CLI. The examples use the OCI CLI
`DEFAULT` profile, normally configured in `~/.oci/config`.

The principal that loads live tenancy data needs read-only identity and policy
permissions. Create or use a narrowly scoped group, then grant:

```text
allow group PolicyAnalysisUsers to {POLICY_READ, COMPARTMENT_INSPECT, DOMAIN_INSPECT, DYNAMIC_GROUP_INSPECT, GROUP_INSPECT, USER_INSPECT, LIMITS_VIEW_INSPECT} in tenancy
```

Verify the profile before starting the server:

```sh
oci iam region list --profile DEFAULT
```

## Install with pip

Create an isolated virtual environment, upgrade pip, and install the released
package. The `mcp` extra installs the MCP server dependencies; the released
base package also provides the cache-management command.

```sh
python3.13 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install --upgrade "oci-policy-analysis[mcp]>=6.5.1"
```

When developing this wrapper from a clone, install the wrapper itself into the
same environment:

```sh
.venv/bin/python -m pip install -e src/oci-identity-policy-mcp-server
```

Verify both upstream entry points and the wrapper console script:

```sh
python -m oci_policy_analysis.cli --help
python -m oci_policy_analysis.mcp_server --help
oracle.oci-identity-policy-mcp-server --help
```

## Run the server

For a desktop MCP client, use standard input/output and your `DEFAULT` OCI
profile:

```sh
python -m oci_policy_analysis.mcp_server --profile DEFAULT --transport stdio
```

For a local MCP client that supports Streamable HTTP:

```sh
python -m oci_policy_analysis.mcp_server \
  --profile DEFAULT \
  --transport streamable-http \
  --host 127.0.0.1 \
  --port 8765 \
  --log-level INFO
```

The MCP endpoint is `http://127.0.0.1:8765/mcp`; the health endpoint is
`http://127.0.0.1:8765/health`. Keep an HTTP server bound to localhost unless
you have an authenticated, trusted network boundary.

## MCP client configuration

Use the absolute path to the virtual environment's Python executable, not a
shell-dependent `python` alias.

### Claude Desktop

Add an entry to Claude Desktop's MCP configuration, replacing
`<PYTHON_EXECUTABLE>` with the absolute path to `.venv/bin/python`:

```json
{
  "mcpServers": {
    "oci-policy": {
      "command": "<PYTHON_EXECUTABLE>",
      "args": ["-m", "oci_policy_analysis.mcp_server", "--profile", "DEFAULT", "--transport", "stdio"]
    }
  }
}
```

### Codex

Add this to Codex `config.toml`, replacing `<PYTHON_EXECUTABLE>` with an
absolute path:

```toml
[mcp_servers.oci_policy]
command = "<PYTHON_EXECUTABLE>"
args = ["-m", "oci_policy_analysis.mcp_server", "--profile", "DEFAULT", "--transport", "stdio"]
```

For a server already running locally over HTTP:

```toml
[mcp_servers.oci_policy]
url = "http://127.0.0.1:8765/mcp"
```

## Caches and authentication

Live profile loading is the simplest first validation. If the data is large or
you want predictable startup, use the upstream CLI to create and list caches,
then start the MCP server with `--use-cache <CACHE_NAME>`.

```sh
python -m oci_policy_analysis.cli --help
python -m oci_policy_analysis.mcp_server --use-cache <CACHE_NAME> --transport stdio
```

The released package also supports the authentication modes documented by its
command help, including instance principal, resource principal, and
session-token based workflows. Pass those arguments directly to
`oci_policy_analysis.mcp_server`; this wrapper does not translate environment
variables or manage credentials.

## Troubleshooting

- If the module cannot be imported, activate the virtual environment and rerun
  the pip install command.
- If the OCI profile is unavailable, run `oci iam region list --profile DEFAULT`
  and inspect `~/.oci/config` and the selected profile name.
- If live loading returns authorization errors, verify the policy permissions
  above and that they are attached to the same principal used by the profile.
- If a desktop client cannot start the server, use the absolute venv Python path
  in its configuration and run the same command in a terminal first.
- For option details and supported authentication modes, run
  `python -m oci_policy_analysis.mcp_server --help` from the installed
  environment.

## License

Copyright (c) 2025 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.
