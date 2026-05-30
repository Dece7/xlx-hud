HUD 配置管理工具。

读取 `~/.claude/hud-config.json`，展示当前 HUD 各元素的显示状态，然后让用户选择要切换的元素。

**执行步骤**：

1. 用 Read 工具读取 `~/.claude/hud-config.json`
2. 按以下分组格式展示当前状态（用代码块格式，清晰分层）：

```
━━━ HUD 配置 ━━━

📍 核心信息
  [✅] model     模型名称
  [✅] folder    工作区文件夹

📊 会话数据
  [✅] context   上下文进度条
  [❌] tokens    累计输入 Token
  [✅] cache     缓存命中率

🔧 开发信息
  [❌] git       Git 分支 + 增删统计
  [❌] lines     代码变更行数
  [❌] effort    思考等级
```

3. 用 AskUserQuestion 让用户选择要切换的元素，选项格式为：
   - `git → 开启` 或 `git → 关闭`（根据当前状态显示切换方向）
   - 每个选项的 description 写明当前状态和切换后状态
   - 支持多选
   - 列出所有可切换的元素（排除不可切换的如 model）

4. 用 Edit 工具修改 `~/.claude/hud-config.json` 中对应元素的 true/false
5. 展示修改后的配置摘要，告知用户下次状态栏刷新自动生效

**注意**：
- 不要修改 statusline-command.sh，只修改 hud-config.json
- 配置文件路径：`~/.claude/hud-config.json`
- model 始终开启，不需要切换选项
- 修改后立即生效，无需重启 CC
