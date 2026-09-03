# ============================================================================
# MCP SERVERS - Model Context Protocol Configuration
# ============================================================================
#
# WHAT IS MCP?
# The Model Context Protocol (MCP) is a standard for connecting AI applications
# to external data sources and tools ("servers").
#
# This config writes ~/.config/mcp/mcp.json declaratively via Nix, so the same
# servers are always available regardless of which MCP client is used.
#
# SERVER TYPES:
#   stdio  — runs as a local process (e.g., filesystem server)
#   http/sse — connects to a remote HTTP/SSE endpoint (e.g. a local llama.cpp server)
#
# ============================================================================

{ ... }:

{
  home.file.".config/mcp/mcp.json".text = builtins.toJSON {
    mcpServers = {
      # ==========================================================================
      # OBSIDIAN VAULT
      # ==========================================================================
      # Reads from your PARA Obsidian vault (Areas section).
      # Lets AI agents search, read, and write notes in your knowledge base.
      obsidian-vault = {
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "~/PARA/Areas/Notes"
        ];
      };
    };
  };
}
