# xlx-hud

> Claude Code 个性化状态栏 — 把 /usage 的信息搬到输入框下方，实时展示，一目了然。

基于 Claude Code 的 `statusLine` 功能，通过自定义 bash 脚本实现。支持 13 个可配置元素、`/hud` 交互式开关、每 4 个元素自动换行。

## 效果展示

**默认配置（4 个元素）：**
```
🤖 mimo-v2.5-pro[1M]   💭 ████░░░░░░ 35%   📁 CCWork1   🎯 98.79%
```

**开启 8 个元素（自动换行）：**
```
🤖 mimo-v2.5-pro[1M]   💭 ████░░░░░░ 35%   📁 CCWork1   🎯 98.79%
⚡ max   📥 250k   ⏱️ 1h24m   🧠 on
```

**全开 13 个元素：**
```
🤖 mimo-v2.5-pro[1M]   🌿 main +3/-1   💭 ████░░░░░░ 35%   📁 CCWork1
🎯 98.79%   📝 +887/-215   ⚡ max   📥 250k
⏱️ 1h24m   🧠 on   📂 11   📡 698   🔧 261
```

## 快速开始

```bash
# 克隆项目
git clone https://github.com/Dece7/xlx-hud.git
cd xlx-hud

# 一键安装
bash install.sh

# 重启 Claude Code，HUD 自动出现
```

## 功能清单

### 📍 核心信息

| 元素 | 图标 | 说明 | 默认 |
|------|------|------|------|
| model | 🤖 | 模型名称（始终开启） | ✅ |
| folder | 📁 | 当前工作区文件夹名（最后一层） | ✅ |

### 📊 会话数据

| 元素 | 图标 | 说明 | 默认 |
|------|------|------|------|
| context | 💭 | 上下文进度条 + 使用率百分比 | ✅ |
| cache | 🎯 | 会话级缓存命中率（从 JSONL 累计计算） | ✅ |
| tokens | 📥 | 累计输入 Token 数（自动格式化 k/M） | ❌ |
| duration | ⏱️ | 会话持续时间 | ❌ |
| files | 📂 | 本次会话编辑的文件数 | ❌ |
| requests | 📡 | API 请求次数 | ❌ |
| tools | 🔧 | 工具调用次数 | ❌ |

### 🔧 开发信息

| 元素 | 图标 | 说明 | 默认 |
|------|------|------|------|
| git | 🌿 | Git 分支名 + 增删行数统计 | ❌ |
| lines | 📝 | 会话累计代码变更行数 | ❌ |
| effort | ⚡ | 当前思考等级（max/xhigh/high/medium/low） | ❌ |
| thinking | 🧠 | 思考模式开关状态（on/off） | ❌ |

### 颜色说明

| 颜色 | 含义 |
|------|------|
| 🟢 绿色 | 状态良好（上下文 <50%、缓存 >80%） |
| 🟡 黄色 | 需要注意（上下文 50-80%、缓存 50-80%） |
| 🔴 红色 | 警告（上下文 >80%、缓存 <50%） |

## 配置方式

### 方式一：/hud 指令（推荐）

在 Claude Code 中输入 `/hud`，交互式切换各元素：

```
━━━ HUD 配置 ━━━

📍 核心信息
  [✅] model      模型名称（始终开启）
  [✅] folder     工作区文件夹

📊 会话数据
  [✅] context    上下文进度条
  [❌] tokens     累计输入 Token
  [✅] cache      缓存命中率
  [❌] duration   会话时长
  [❌] files      编辑文件数
  [❌] requests   API 请求次数
  [❌] tools      工具调用次数

🔧 开发信息
  [❌] git        Git 分支 + 增删统计
  [❌] lines      代码变更行数
  [❌] effort     思考等级
  [❌] thinking   思考模式状态
```

### 方式二：直接编辑配置文件

编辑 `~/.claude/hud-config.json`，将 `false` 改为 `true` 即可开启：

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

修改后立即生效，无需重启 Claude Code。

## 工作原理

```
Claude Code 进程
│
├── 每次刷新时构造 JSON（模型/上下文/费用/会话信息）
│
├── pipe 到 statusline-command.sh（stdin）
│
├── 脚本解析：
│   ├── jq 解析 statusLine JSON
│   ├── grep/awk 读取 session JSONL（缓存/请求/工具）
│   ├── ls 统计 file-history（编辑文件数）
│   └── git 获取分支/差异信息
│
└── 输出格式化文本（stdout）→ 渲染到输入框下方
```

### 数据来源

| 来源 | 路径 | 提供的数据 |
|------|------|-----------|
| statusLine JSON | stdin（CC 自动传入） | 模型、上下文、费用、思考等级等 |
| session JSONL | `~/.claude/projects/<project>/<session-id>.jsonl` | 缓存命中率、API 请求次数、工具调用次数 |
| file-history | `~/.claude/file-history/<session-id>/` | 编辑文件数 |
| git 命令 | 工作区目录 | 分支名、增删行数 |

### 缓存命中率公式

从 session JSONL 中累计所有请求的数据计算：

```
缓存命中率 = cache_read_input_tokens / (input_tokens + cache_read_input_tokens) × 100
```

> 注意：使用第三方代理（如 MiMo、DeepSeek）时，`cache_creation_input_tokens` 可能始终为 0（代理层未透传）。此公式避开该字段，用 `input + cache_read` 作为分母，提供近似命中率。

## 卸载

```bash
bash uninstall.sh
```

卸载脚本会：
- 删除 `~/.claude/statusline-command.sh`
- 删除 `~/.claude/hud-config.json`
- 删除 `~/.claude/commands/hud.md`
- 从 `settings.json` 中移除 `statusLine` 配置

## 依赖

| 依赖 | 用途 | 安装方式 |
|------|------|---------|
| `jq` | JSON 解析 | `brew install jq` / `apt install jq` / `winget install jqlang.jq` |
| `git` | Git 信息获取 | 通常已预装 |
| `cygpath` | Windows 路径转换 | Git Bash 自带（Linux/macOS 不需要） |

## 文件结构

```
xlx-hud/                          # 项目仓库
├── README.md                     # 本文档
├── install.sh                    # 一键安装脚本
├── uninstall.sh                  # 一键卸载脚本
├── statusline-command.sh         # HUD 主脚本
├── hud-config.json               # 默认配置
├── commands/
│   └── hud.md                    # /hud 指令定义
└── .gitignore

~/.claude/                        # 安装后的文件分布
├── statusline-command.sh         # HUD 主脚本
├── hud-config.json               # 显隐开关配置
├── commands/
│   └── hud.md                    # /hud 指令
└── settings.json                 # CC 配置（自动注入 statusLine）
```

## 常见问题

**Q: HUD 没有显示？**
A: 确认已重启 Claude Code。检查 `~/.claude/settings.json` 中是否有 `statusLine` 配置。

**Q: 缓存命中率一直是 100%？**
A: 使用第三方代理时，`cache_creation_input_tokens` 可能为 0。这是代理层的问题，不是 HUD 的问题。详见 [相关讨论](https://github.com/anthropics/claude-code/issues/58953)。

**Q: Token 数量和模型官网不一致？**
A: HUD 显示的 Token 数由 Anthropic 分词器计算，与模型官网（使用各自分词器）的计数不同，属于正常现象。

**Q: Windows 以外的系统能用吗？**
A: 脚本依赖 `cygpath`（Git Bash 自带）。Linux/macOS 用户需要将脚本中的 `cygpath -f -` 替换为 `cat` 或直接使用路径。

**Q: /hud 指令消耗 Token 吗？**
A: 是的，每次调用约消耗 500-1000 Token。频繁切换建议直接编辑 `~/.claude/hud-config.json`。

## 许可证

[MIT](https://opensource.org/licenses/MIT)
