#!/bin/bash
# 07-mini-agent-loop.sh
#
# Demonstrates: Pi's while loop pattern
# A simplified agent that processes commands interactively
#
# Usage: ./07-mini-agent-loop.sh

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Mini Agent Loop Demo${NC}"
echo -e "${BLUE}   (Simplified Pi architecture)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "This agent has 4 tools:"
echo "  • read <file>    - Read file contents"
echo "  • write <file>   - Write to file"
echo "  • list           - List files"
echo "  • bash <command> - Run any bash command"
echo ""
echo "Type 'help' for examples, 'quit' to exit"
echo ""

# Agent memory (context)
CONTEXT_FILE=$(mktemp)
echo "# Agent Session $(date)" > "$CONTEXT_FILE"

# Agent loop
while true; do
  echo -e "${YELLOW}Agent:${NC} Ready for command..."
  echo -n "You: "
  read -r user_input
  
  # Parse command
  cmd=$(echo "$user_input" | awk '{print $1}')
  args=$(echo "$user_input" | cut -d' ' -f2-)
  
  case "$cmd" in
    "quit"|"exit"|"done")
      echo -e "${GREEN}Agent:${NC} Session ended. Goodbye!"
      rm "$CONTEXT_FILE"
      break
      ;;
      
    "help")
      echo -e "${GREEN}Agent:${NC} Available commands:"
      echo "  read <file>      - Read file contents"
      echo "  write <file>     - Write to file (interactive)"
      echo "  list             - List files in current directory"
      echo "  bash <command>   - Execute any bash command"
      echo ""
      echo "Examples:"
      echo "  read README.md"
      echo "  write test.txt"
      echo "  list"
      echo "  bash ls -la"
      echo "  bash cat *.md | grep 'bash'"
      ;;
      
    "read")
      if [ -f "$args" ]; then
        echo -e "${GREEN}Agent:${NC} Reading $args..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$args"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        # Add to context
        echo "[Read $args]" >> "$CONTEXT_FILE"
      else
        echo -e "${GREEN}Agent:${NC} Error: File '$args' not found"
      fi
      ;;
      
    "write")
      echo -e "${GREEN}Agent:${NC} Creating $args..."
      echo "Enter content (Ctrl+D when done):"
      cat > "$args"
      echo -e "${GREEN}Agent:${NC} Wrote to $args"
      # Add to context
      echo "[Wrote to $args]" >> "$CONTEXT_FILE"
      ;;
      
    "list")
      echo -e "${GREEN}Agent:${NC} Listing files..."
      ls -lh
      # Add to context
      echo "[Listed files]" >> "$CONTEXT_FILE"
      ;;
      
    "bash")
      echo -e "${GREEN}Agent:${NC} Executing: $args"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      eval "$args"
      exit_code=$?
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo -e "${GREEN}Agent:${NC} Command completed (exit code: $exit_code)"
      # Add to context
      echo "[Ran: $args]" >> "$CONTEXT_FILE"
      ;;
      
    "context"|"history")
      echo -e "${GREEN}Agent:${NC} Session history:"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      cat "$CONTEXT_FILE"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      ;;
      
    *)
      echo -e "${GREEN}Agent:${NC} Unknown command: $cmd"
      echo "Type 'help' for available commands"
      ;;
  esac
  
  echo ""
done
