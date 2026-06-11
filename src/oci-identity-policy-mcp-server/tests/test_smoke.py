"""Smoke tests for metadata-only OCI Identity Policy MCP wrapper."""


def test_upstream_entrypoint_importable() -> None:
    """Ensure upstream MCP server entrypoint is importable from dependency package."""
    from oci_policy_analysis import mcp_server

    assert hasattr(mcp_server, "main")
