# xlx-hud

Claude Code 个性化状态栏 — 在输入框下方实时展示模型、Git、上下文、缓存命中率等信息。

基于 Claude Code 的 `statusLine` 功能，通过自定义 bash 脚本实现。

## 效果

```
🤖 mimo-v2.5-pro[1M]   💭 ████░░░░░░ 35%   📁 CCWork1   🎯 98.65%   📂 11   📡 698   🔧 261
```

## 功能

| 元素 | 图标 | 说明 | 默认 |
|------|------|------|------|
| model | 🤖 | 模型名称 | 开启 |
| git | 🌿 | Git 分支 + 增删统计 | 关闭 |
| context | 💭 | 上下文进度条 + 使用率 | 开启 |
| folder | 📁 | 工作区文件夹名 | 开启 |
| cache | 🎯 | 会话级缓存命中率 | 开启 |
| lines | 📝 | 代码变更行数 | 关闭 |
| effort | ⚡ | 思考等级 | 关闭 |
| tokens | 📥 | 累计输入 Token | 关闭 |
| duration | ⏱️ | 会话持续时间 | 关闭 |
| thinking | 🧠 | 思考模式状态（on/off） | 关闭 |
| files | 📂 | 本次会话编辑的文件数 | 关闭 |
| requests | 📡 | API 请求次数 | 关闭 |
| tools | 🔧 | 工具调用次数 | 关闭 |

所有元素可通过 `/hud` 指令交互式开关。

## 安装

```bash
git clone https://github.com/Dece7/xlx-hud.git
cd xlx-hud
bash install.sh
```

重启 Claude Code 即可生效。

## 卸载

```bash
bash uninstall.sh
```

## 配置

在 Claude Code 中输入 `/hud`，交互式切换各元素的显示状态。

或直接编辑 `~/.claude/hud-config.json`：

```json
{
  "model": true,
  "git": false,
  "context": true,
  "folder": true,
  "cache": true,
  "lines": false,
  "effort": false,
  "tokens": false,
  "duration": false,
  "thinking": false,
  "files": false,
  "requests": false,
  "tools": false
}
```

修改后立即生效，无需重启。

## 依赖

- `jq` — JSON 解析
- `git` — Git 信息获取
- `cygpath` — Windows Git Bash 路径转换（Linux/macOS 不需要）

## 工作原理

Claude Code 每次刷新状态栏时，将当前会话状态打包为 JSON 通过 stdin 传给脚本，脚本解析后输出格式化文本。

数据来源：
- **statusLine JSON**：模型、上下文、费用、思考等级等
- **session JSONL**：缓存命中率、API 请求次数、工具调用次数
- **file-history**：编辑文件数
- **git 命令**：分支、增删统计

缓存命中率公式（从 JSONL 累计计算）：
```
缓存命中率 = cache_read / (input + cache_read) × 100
```

## 文件结构

```
~/.claude/
├── statusline-command.sh    # HUD 主脚本
├── hud-config.json          # 显隐开关配置
├── commands/
│   └── hud.md               # /hud 指令
└── settings.json            # CC 配置（自动注入 statusLine）
```

## 许可证

MIT
