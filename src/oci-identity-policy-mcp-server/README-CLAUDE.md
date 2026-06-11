# Claude Desktop Setup

This page extends the generic MCP setup in [README.md](README.md) with Claude
Desktop-specific `stdio` examples.

Claude Desktop starts MCP servers as local commands. For this server, that means
Claude should use either:

- a Python executable that can import `oci_policy_analysis`
- a Docker executable that can run the built image

Claude Desktop should use `stdio` for this server. Do not configure Streamable
HTTP for Claude Desktop unless Claude adds explicit support for that flow.

## Example Index

| Example | Runtime | Data mode |
|---|---|---|
| [Local Python cached stdio](#local-python-cached-stdio) | Python | cache |
| [Local Python live profile stdio](#local-python-live-profile-stdio) | Python | live OCI profile |
| [Docker cached stdio](#docker-cached-stdio) | Docker | cache |
| [Docker live profile stdio](#docker-live-profile-stdio) | Docker | live OCI profile |

Use the generic parameter table and cache workflow in [README.md](README.md)
before choosing one of these Claude examples.

## Claude Rules

- Use command-line arguments for local Python.
- Use Docker environment variables for container runs.
- Use absolute executable paths for Python and Docker.
- Replace `<HOME>` with an absolute home directory path.
- Replace `<CACHE_NAME>` with a cache entry listed by the CLI workflow in
  [README.md](README.md#create-and-use-a-cache).
- For Docker stdio, use `-i` and do not use `-t`, `--tty`, or `--it`.
- Avoid appending server arguments after the Docker image when using `MCP_*`
  environment variables.
- Restart Claude Desktop after editing `claude_desktop_config.json`.

Claude Desktop logs MCP server output under:

```text
$HOME/Library/Logs/Claude
```

On macOS, Claude Desktop config is usually:

```text
$HOME/Library/Application Support/Claude/claude_desktop_config.json
```

## Executable Paths

Claude starts the configured `command` directly. It does not activate your shell
profile or virtual environment first.

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

If Docker is provided by Rancher Desktop, it may not be on Claude Desktop's
inherited `PATH`. Rancher Desktop commonly provides Docker at:

```text
$HOME/.rd/bin/docker
```

Confirm it is available:

```sh
$HOME/.rd/bin/docker --version
```

Use the absolute path, for example `/Users/<you>/.rd/bin/docker`, as
`<DOCKER_EXECUTABLE>`.

## Local Python Cached Stdio

```json
{
  "mcpServers": {
    "oci-policy-python-cache": {
      "command": "<PYTHON_EXECUTABLE>",
      "args": [
        "-m",
        "oci_policy_analysis.mcp_server",
        "--use-cache",
        "<CACHE_NAME>",
        "--transport",
        "stdio",
        "--log-level",
        "ERROR"
      ],
      "env": {
        "MCP_STDIO_MODE": "1",
        "PYTHONUNBUFFERED": "1",
        "PYTHONWARNINGS": "ignore"
      }
    }
  }
}
```

## Local Python Live Profile Stdio

```json
{
  "mcpServers": {
    "oci-policy-python-live": {
      "command": "<PYTHON_EXECUTABLE>",
      "args": [
        "-m",
        "oci_policy_analysis.mcp_server",
        "--profile",
        "DEFAULT",
        "--transport",
        "stdio",
        "--compartment-domain-search-depth",
        "2",
        "--log-level",
        "WARNING"
      ],
      "env": {
        "MCP_STDIO_MODE": "1",
        "PYTHONUNBUFFERED": "1",
        "PYTHONWARNINGS": "ignore"
      }
    }
  }
}
```

Add `"--dont-save-cache-after-load"` to the `args` list if the live run should
not write a new cache file after loading OCI data.

## Docker Cached Stdio

Docker arguments are array entries. Keep `-e` and each `KEY=value` as separate
strings.

```json
{
  "mcpServers": {
    "oci-policy-docker-cache": {
      "command": "<DOCKER_EXECUTABLE>",
      "args": [
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
        "oracle.oci-identity-policy-mcp-server:latest"
      ],
      "env": {}
    }
  }
}
```

## Docker Live Profile Stdio

The mounted `<HOME>/.oci` directory must include the OCI config file and private
key files referenced by `OCI_PROFILE`.

```json
{
  "mcpServers": {
    "oci-policy-docker-live": {
      "command": "<DOCKER_EXECUTABLE>",
      "args": [
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
        "oracle.oci-identity-policy-mcp-server:latest"
      ],
      "env": {}
    }
  }
}
```

Use a read-write cache mount for live runs if you want the server to write the
fresh cache after loading OCI data.

## Troubleshooting

If the container starts and exits immediately, check the Claude MCP log for the
server name.

Common causes:

- `--it`, `--tty`, or `-t` was used instead of `-i`.
- `command` is `python` or `docker` but Claude cannot find it.
- The Python executable does not have `oci-policy-analysis[mcp]` installed.
- Server CLI arguments were appended after the Docker image while relying on
  `MCP_*` environment defaults.
- The cache directory was not mounted, or `MCP_CACHE_NAME` does not match an
  available cache entry.
- The OCI profile name does not exist inside the mounted `/app/.oci/config`.
