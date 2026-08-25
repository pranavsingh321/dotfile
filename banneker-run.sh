#!/bin/bash
set -euo pipefail

# Banneker CLI wrapper - runs Banneker commands via opencode
# Usage: ./banneker-run.sh [command]
# Commands: document, roadmap, appendix, feed, all (default: all)

COMMAND="${1:-all}"

echo "==> Running Banneker: $COMMAND"

case "$COMMAND" in
  document)
    opencode -c "Run /banneker:document to analyze this codebase"
    ;;
  roadmap)
    opencode -c "Run /banneker:roadmap to generate architecture diagrams"
    ;;
  appendix)
    opencode -c "Run /banneker:appendix to compile HTML reference"
    ;;
  feed)
    opencode -c "Run /banneker:feed to export planning artifacts"
    ;;
  all)
    opencode -c "
      Run /banneker:document to analyze the codebase.
      Then run /banneker:roadmap to generate architecture diagrams.
      Then run /banneker:appendix to compile HTML reference.
      Show me the results.
    "
    ;;
  *)
    echo "Unknown command: $COMMAND"
    echo "Usage: $0 [document|roadmap|appendix|feed|all]"
    exit 1
    ;;
esac

echo "==> Done!"
