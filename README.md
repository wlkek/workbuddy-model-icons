# WorkBuddy 模型图标

给 WorkBuddy 的**自定义模型**自动配上官方品牌图标。新加一个模型，只要名字里带 `kimi`、`deepseek` 这类词，模型菜单里就会显示对应品牌的 logo——不用挑图、不用配置。

> [!IMPORTANT]
> **2026-11-14：v3.0.0 复活，换了一套注入通道。**
>
> 5.9.2 起客户端把 renderer 打进 `app.asar` 并加了 SHA256 完整性校验，老的
> 「往 `app.asar.unpacked/renderer/index.html` 插 loader」彻底没有落点。
>
> v3 改成 **运行时注入**：用 Electron 的 `NODE_OPTIONS` fuse（当前 5.9.3 里是开着的）
> 在主进程启动时加载一个 hook，等主界面 `dom-ready` 后把 mod 脚本注入页面。
> **不再修改客户端任何文件**，卸载就是删快捷方式。

> **非官方项目**。与 WorkBuddy / 腾讯无任何关系。它通过运行时注入改动界面，
> 可能违反其服务条款，请自行判断是否使用。

> ⚡ **Vibe Coding 产物**：人类开发者提出架构与业务意图，AI 助手端到端完成逆向分析、
> DOM 结构测绘、注入方案设计与界面代码编写。

![效果](docs/screenshot.png)

## 它做了什么

在模型列表、自定义模型子菜单、输入框右下角的模型胶囊里，把官方默认的灰色立方体换成品牌图标。

匹配**不依赖固定前缀**：`cr-`、`wb-` 或以后换成别的，只要类名 token 以 `-model-selector__item` / `__item-name` / `__item-icon` 结尾就能认出。

认不出来的模型保持官方默认图标，不会乱贴。找不到结构就完全不动 DOM，界面照常。

## 支持的品牌

| 关键词（不区分大小写） | 图标 |
|---|---|
| `kimi` / `moonshot` | Kimi |
| `deepseek` | DeepSeek |
| `glm` / `chatglm` / `zhipu` | 智谱 GLM |
| `minimax` / `abab` | MiniMax |
| `hunyuan` / `hy` | 腾讯混元 |
| `claude` / `anthropic` | Claude |
| `gemini` | Gemini |
| `gpt` / `openai` | OpenAI |

## 安装（5.9.2 及以上）

1. 下载 Release 里的 zip，解压到任意目录
2. 双击 `install.cmd`
3. **托盘右键，完全退出 WorkBuddy**
4. 用桌面上的 **「WorkBuddy (mods)」** 快捷方式启动
5. 打开任意模型菜单即可看到图标

安装器做四件事：

```
复制 loader 与 mod 到 %LOCALAPPDATA%\WbMods
生成 launch.vbs（设置 NODE_OPTIONS 后拉起 WorkBuddy.exe）
在桌面 / 开始菜单建快捷方式
读 exe 里的 Electron fuse，确认 NODE_OPTIONS 通道可用
```

`install.cmd -Status` 看状态，`uninstall.cmd` 一键还原。

> [!WARNING]
> **必须用新快捷方式启动。** Windows 快捷方式不能带环境变量，所以 mod 靠 `launch.vbs`
> 注入。点原来的图标、或任务栏上固定的那个，启动的是没有 mod 的原版。
> 想要任务栏固定，就固定新快捷方式。

## 工作原理

```
WorkBuddy.exe
  └─ NODE_OPTIONS=--require "...\WbMods\hook.js"
       └─ main 进程启动，监听 web-contents-created
            └─ 主界面 dom-ready → executeJavaScript(mod.js)
                 └─ MutationObserver 盯着模型列表，命中关键词就换图标
```

`hook.js` 的三条硬约束：

1. 只处理 `process.type === 'browser'`，不碰渲染进程
2. 启动后立刻把 `--require` 从 `NODE_OPTIONS` 里摘掉，避免被 agent 的 node 子进程继承
3. 只在 `app.asar/renderer/index.html` 这个页面上注入，guest 页面一律跳过

## 兼容性

| 版本 | 状态 | 说明 |
|---|---|---|
| ≤ 5.8.3 | 用 v2.x | 老的 index.html 加载器方案，见 Release 里的 2.8.0 |
| 5.9.0 – 5.9.1 | 未验证 | 打包方式切换期 |
| 5.9.2 – 5.9.3 | **v3 目标版本** | 已确认：入口已 packed + integrity、fuse `10111101`（NODE_OPTIONS 开启）、模型菜单类名仍在 |
| 以后 | 看 fuse | 官方一旦把 `EnableNodeOptionsEnvironmentVariable` 关掉，v3 就失效；安装器会读 fuse 并明确提示 |

**失效时的表现**：脚本找不到结构就完全不动 DOM——界面照常，只是没有品牌图标。不会白屏、不会报错、不会把菜单弄坏。

## 排查

注入日志：`%LOCALAPPDATA%\WbMods\loader.log`

```
[..] loader start | pid=1234 | mods=model-icons@3.0.0
[..] injected model-icons@3.0.0
```

有 `loader start` 没有 `injected` → fuse 或启动方式不对；两行都没有 → 没用新快捷方式启动。

## 安全边界

- **不联网**、不读对话内容、不采集数据
- **不修改客户端任何文件**，只往 `%LOCALAPPDATA%\WbMods` 写自己的东西 + 建一个快捷方式
- **fail-open**：脚本出错时列表照常显示，只是没图标
- 但注入本身有风险：`NODE_OPTIONS=--require` 是常见注入手法，部分杀软会拦；介意就别用

## 和「思考强度滑条」共存

两个 mod 共用同一个 loader、同一个快捷方式，各自在 `mods/<id>/` 下独立安装。
先装哪个都行，卸载任意一个不影响另一个。

## License

MIT
