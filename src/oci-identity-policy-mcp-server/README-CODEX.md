# Codex Setup

This page extends the generic MCP setup in [README.md](README.md) with Codex
CLI and Codex IDE extension examples.

Codex supports MCP servers over both `stdio` and Streamable HTTP. Use `stdio`
when Codex should own the server process lifecycle. Use Streamable HTTP when the
server should be started, inspected, restarted, or hosted independently from
Codex.

Codex MCP configuration lives in `~/.codex/config.toml`, or in a project-scoped
`.codex/config.toml` for trusted projects.

## Example Index

| Example | Runtime | Transport | Data mode |
|---|---|---|---|
| [Codex CLI add: local Python cached stdio](#codex-cli-add-local-python-cached-stdio) | Python | `stdio` | cache |
| [config.toml: local Python cached stdio](#configtoml-local-python-cached-stdio) | Python | `stdio` | cache |
| [config.toml: Docker cached stdio](#configtoml-docker-cached-stdio) | Docker | `stdio` | cache |
| [Local Python cached Streamable HTTP](#local-python-cached-streamable-http) | Python | `streamable-http` | cache |
| [Docker cached Streamable HTTP](#docker-cached-streamable-http) | Docker | `streamable-http` | cache |
| [config.toml: local Python live stdio](#configtoml-local-python-live-stdio) | Python | `stdio` | live OCI profile |
| [config.toml: Docker live stdio](#configtoml-docker-live-stdio) | Docker | `stdio` | live OCI profile |
| [Live Streamable HTTP starts](#live-streamable-http-starts) | Python or Docker | `streamable-http` | live OCI profile |

Use the generic parameter table and cache workflow in [README.md](README.md)
before choosing one of these Codex examples.

## Codex Rules

- Use absolute executable paths for `stdio` Python and Docker commands.
- Replace `<HOME>` with an absolute home directory path.
- Replace `<CACHE_NAME>` with a cache entry listed by the CLI workflow in
  [README.md](README.md#create-and-use-a-cache).
- For Docker stdio, use `-i` and do not use `-t`, `--tty`, or `--it`.
- Docker and TOML arrays do not expand `$HOME`.
- For Streamable HTTP, start the server outside Codex and configure Codex with
  the endpoint URL.

Streamable HTTP endpoint:

```text
http://127.0.0.1:8765/mcp
```

## Executable Paths

Codex starts configured `stdio` MCP commands directly. It does not activate your
shell profile or virtual environment first.

Find the Python executable:

```sh
python -c "import sys; print(sys.executable)"
```

From a project virtual environment without activating it:

```sh
./.venv/bin/python -c "import sys; print(sys.executable)"
```

Use the printed path as `<PYTHON_EXECUTABLE>`.

Find Docker:

```sh
command -v docker
```

If Docker is provided by Rancher Desktop, it may be outside Codex's inherited
`PATH`. Rancher Desktop commonly provides Docker at:

```text
$HOME/.rd/bin/docker
```

Confirm it is available:

```sh
$HOME/.rd/bin/docker --version
```

Use the absolute path, for example `/Users/<you>/.rd/bin/docker`, as
`<DOCKER_EXECUTABLE>`.

## Codex CLI Add: Local Python Cached Stdio

```sh
codex mcp add oci-policy-python-cache \
  --env MCP_STDIO_MODE=1 \
  --env PYTHONUNBUFFERED=1 \
  --env PYTHONWARNINGS=ignore \
  -- "<PYTHON_EXECUTABLE>" -m oci_policy_analysis.mcp_server \
    --use-cache <CACHE_NAME> \
    --transport stdio \
    --log-level ERROR
```

Use `codex mcp --help` to inspect the currently installed Codex CLI's exact
options.

## config.toml: Local Python Cached Stdio

```toml
[mcp_servers.oci_policy_python_cache]
command = "<PYTHON_EXECUTABLE>"
args = [
  "-m",
  "oci_policy_analysis.mcp_server",
  "--use-cache",
  "<CACHE_NAME>",
  "--transport",
  "stdio",
  "--log-level",
  "ERROR",
]
startup_timeout_sec = 60
tool_timeout_sec = 120

[mcp_servers.oci_policy_python_cache.env]
MCP_STDIO_MODE = "1"
PYTHONUNBUFFERED = "1"
PYTHONWARNINGS = "ignore"
```

## config.toml: Docker Cached Stdio

```toml
[mcp_servers.oci_policy_docker_cache]
command = "<DOCKER_EXECUTABLE>"
args = [
  "run",
  "--rm",
  "-i",
  "-v",
  "<HOME>/.oci-policy-analysis/cache:/app/.oci-policy-analysis/cache:ro",
  "-e",
  "MCP_AUTH_MODE=cache",
  "-e",
  "MCP_CACHE_NAME=<CACHE_NAME>",
  "-e",
  "MCP_TRANSPORT=stdio",
  "-e",
  "MCP_LOG_LEVEL=ERROR",
  "-e",
  "MCP_STDIO_MODE=1",
  "-e",
  "MCP_SAVE_CACHE_AFTER_LOAD=false",
  "-e",
  "PYTHONUNBUFFERED=1",
  "-e",
  "PYTHONWARNINGS=ignore",
  "oracle.oci-identity-policy-mcp-server:latest",
]
startup_timeout_sec = 60
tool_timeout_sec = 120
```

## Local Python Cached Streamable HTTP

Start the server outside Codex:

```sh
python -m oci_policy_analysis.mcp_server \
  --use-cache <CACHE_NAME> \
  --transport streamable-http \
  --host 127.0.0.1 \
  --port 8765 \
  --log-level INFO
```

Configure Codex:

```toml
[mcp_servers.oci_policy_http]
url = "http://127.0.0.1:8765/mcp"
startup_timeout_sec = 10
tool_timeout_sec = 120
```

## Docker Cached Streamable HTTP

Start the container outside Codex:

```sh
docker run --rm -p 127.0.0.1:8765:8765 \
  -v "$HOME/.oci-policy-analysis/cache:/app/.oci-policy-analysis/cache:ro" \
  -e MCP_AUTH_MODE=cache \
  -e MCP_CACHE_NAME=<CACHE_NAME> \
  -e MCP_TRANSPORT=streamable-http \
  -e MCP_HOST=0.0.0.0 \
  -e MCP_PORT=8765 \
  -e MCP_LOG_LEVEL=INFO \
  -e MCP_SAVE_CACHE_AFTER_LOAD=false \
  oracle.oci-identity-policy-mcp-server:latest
```

Configure Codex with the same HTTP block:

```toml
[mcp_servers.oci_policy_http]
url = "http://127.0.0.1:8765/mcp"
startup_timeout_sec = 10
tool_timeout_sec = 120
```

## config.toml: Local Python Live Stdio

```toml
[mcp_servers.oci_policy_python_live]
command = "<PYTHON_EXECUTABLE>"
args = [
  "-m",
  "oci_policy_analysis.mcp_server",
  "--profile",
  "DEFAULT",
  "--transport",
  "stdio",
  "--compartment-domain-search-depth",
  "2",
  "--log-level",
  "WARNING",
]
startup_timeout_sec = 120
tool_timeout_sec = 120

[mcp_servers.oci_policy_python_live.env]
MCP_STDIO_MODE = "1"
PYTHONUNBUFFERED = "1"
PYTHONWARNINGS = "ignore"
```

## config.toml: Docker Live Stdio

```toml
[mcp_servers.oci_policy_docker_live]
command = "<DOCKER_EXECUTABLE>"
args = [
  "run",
  "--rm",
  "-i",
  "-v",
  "<HOME>/.oci:/app/.oci:ro",
  "-v",
  "<HOME>/.oci-policy-analysis/cache:/app/.oci-policy-analysis/cache",
  "-e",
  "MCP_AUTH_MODE=profile",
  "-e",
  "OCI_PROFILE=DEFAULT",
  "-e",
  "MCP_TRANSPORT=stdio",
  "-e",
  "MCP_LOG_LEVEL=WARNING",
  "-e",
  "MCP_COMPARTMENT_DOMAIN_SEARCH_DEPTH=2",
  "-e",
  "MCP_STDIO_MODE=1",
  "-e",
  "PYTHONUNBUFFERED=1",
  "-e",
  "PYTHONWARNINGS=ignore",
  "oracle.oci-identity-policy-mcp-server:latest",
]
startup_timeout_sec = 120
tool_timeout_sec = 120
```

## Live Streamable HTTP Starts

Start local Python outside Codex:

```sh
python -m oci_policy_analysis.mcp_server \
  --profile DEFAULT \
  --transport streamable-http \
  --host 127.0.0.1 \
  --port 8765 \
  --log-level INFO \
  --compartment-domain-search-depth 2
```

Or start Docker outside Codex:

```sh
docker run --rm -p 127.0.0.1:8765:8765 \
  -v "$HOME/.oci:/app/.oci:ro" \
  -v "$HOME/.oci-policy-analysis/cache:/app/.oci-policy-analysis/cache" \
  -e MCP_AUTH_MODE=profile \
  -e OCI_PROFILE=DEFAULT \
  -e MCP_TRANSPORT=streamable-http \
  -e MCP_HOST=0.0.0.0 \
  -e MCP_PORT=8765 \
  -e MCP_LOG_LEVEL=INFO \
  -e MCP_COMPARTMENT_DOMAIN_SEARCH_DEPTH=2 \
  oracle.oci-identity-policy-mcp-server:latest
```

Configure Codex with the HTTP block:

```toml
[mcp_servers.oci_policy_http]
url = "http://127.0.0.1:8765/mcp"
startup_timeout_sec = 10
tool_timeout_sec = 120
```

## Notes

- Cached mode is the fastest first test for Codex integration.
- Live mode can take longer because the MCP server loads data from OCI before it
  is ready.
- Streamable HTTP is useful when you want to start and inspect the server
  independently from Codex.
- For Docker, prefer environment variables and do not append `--use-cache` or
  other server arguments after the image unless you also provide every required
  Python server argument explicitly.
