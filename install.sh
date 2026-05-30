#!/usr/bin/env bash
set -euo pipefail

# xlx-hud installer
# Installs HUD script, config, and /hud command into ~/.claude/

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "━━━ xlx-hud 安装 ━━━"
echo ""

# Check dependencies
echo "检查依赖..."
for cmd in jq git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ 缺少依赖: $cmd"
    echo "   请先安装 $cmd 后重试"
    exit 1
  fi
done

# cygpath (Git Bash on Windows)
if command -v cygpath &>/dev/null; then
  echo "✅ jq  ✅ git  ✅ cygpath"
else
  echo "✅ jq  ✅ git  ⚠️ cygpath 未找到（非 Git Bash 环境可能需要调整路径）"
fi
echo ""

# Backup existing files
echo "备份已有文件..."
for f in statusline-command.sh hud-config.json; do
  if [ -f "$CLAUDE_DIR/$f" ]; then
    cp "$CLAUDE_DIR/$f" "$CLAUDE_DIR/$f.bak.$(date +%s)"
    echo "  已备份: $f"
  fi
done
echo ""

# Copy files
echo "安装文件..."
cp "$SCRIPT_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
cp "$SCRIPT_DIR/hud-config.json" "$CLAUDE_DIR/hud-config.json"
mkdir -p "$CLAUDE_DIR/commands"
cp "$SCRIPT_DIR/commands/hud.md" "$CLAUDE_DIR/commands/hud.md"
chmod +x "$CLAUDE_DIR/statusline-command.sh"
echo "  ✅ statusline-command.sh"
echo "  ✅ hud-config.json"
echo "  ✅ commands/hud.md"
echo ""

# Inject statusLine into settings.json
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ]; then
  # Check if statusLine already exists
  if jq -e '.statusLine' "$SETTINGS" &>/dev/null; then
    echo "⚠️  settings.json 已有 statusLine 配置，跳过注入"
  else
    # Add statusLine while preserving existing config
    jq '. + {"statusLine": {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}}' "$SETTINGS" > "$SETTINGS.tmp"
    mv "$SETTINGS.tmp" "$SETTINGS"
    echo "  ✅ 已注入 statusLine 到 settings.json"
  fi
else
  cat > "$SETTINGS" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
EOF
  echo "  ✅ 已创建 settings.json"
fi
echo ""

echo "━━━ 安装完成 ━━━"
echo ""
echo "请重启 Claude Code 使 HUD 生效。"
echo "输入 /hud 可配置 HUD 显示元素。"
echo ""
