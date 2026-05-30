#!/usr/bin/env bash
set -euo pipefail

# xlx-hud uninstaller

CLAUDE_DIR="$HOME/.claude"

echo "━━━ xlx-hud 卸载 ━━━"
echo ""

# Remove files
echo "移除文件..."
for f in statusline-command.sh hud-config.json; do
  if [ -f "$CLAUDE_DIR/$f" ]; then
    rm "$CLAUDE_DIR/$f"
    echo "  ✅ 已删除: $f"
  fi
done

if [ -f "$CLAUDE_DIR/commands/hud.md" ]; then
  rm "$CLAUDE_DIR/commands/hud.md"
  echo "  ✅ 已删除: commands/hud.md"
fi
echo ""

# Remove statusLine from settings.json
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ] && jq -e '.statusLine' "$SETTINGS" &>/dev/null; then
  jq 'del(.statusLine)' "$SETTINGS" > "$SETTINGS.tmp"
  mv "$SETTINGS.tmp" "$SETTINGS"
  echo "  ✅ 已从 settings.json 移除 statusLine"
fi
echo ""

echo "━━━ 卸载完成 ━━━"
echo ""
echo "请重启 Claude Code 使更改生效。"
echo "备份文件（如有）保留在 ~/.claude/*.bak.* 中，可手动删除。"
echo ""
