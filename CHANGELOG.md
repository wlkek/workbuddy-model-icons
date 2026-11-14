# 变更记录

## v3.0.2 — 跨机器 / 跨目录自动识别（2026-11-14）

之前能装能用，但只在「客户端正在运行」时可靠——注册表里的 `InstallLocation`
是空的，只读它会在冷启动安装时找不到目录。

- **路径探测重写为六条独立线索**：上次记录 → 运行进程 → 注册表
  `DisplayIcon` / `InstallLocation` / `UninstallString` → App Paths →
  快捷方式（按目标或图标指向 `WorkBuddy.exe` 判定，不靠文件名）→ 默认路径。
  判定标准统一为 `resources\app.asar` 存在，所以装到任何盘、任何目录名都能认。
- **快捷方式改指固定入口** `%LOCALAPPDATA%\WbMods\node.exe`（客户端自带 node 的硬链接）。
  之前直接指向 `versions\<版本号>\node.exe`，客户端升级清掉旧版本目录后，
  图标会连客户端都打不开。实测硬链接在源文件删除后仍可执行。
- **config.json 增加 candidates**：注入器在 `app` 失效时逐个回退。
  实测把 `app` 改成不存在的盘符，仍能从候选找回客户端。
- **修复**：配置里残留失效路径（移走的盘符）会让 `Join-Path` 抛错、整个安装中断。
  现在候选入表前先 `Test-Path`。
- **修复**：`-Status` 里 mod 版本号显示为空。PS 5.1 默认按 GBK 读无 BOM 的 UTF-8，
  中文描述被吃掉一个引号导致 JSON 解析失败——所有 `Get-Content` 补 `-Encoding UTF8`。
- `install.cmd` 先对解压目录 `Unblock-File`，避免 zip 带 Mark-of-the-Web 时被拦。
- 新增 `WB_DRY_RUN=1`：只打印解析到的客户端路径与 mod 列表，不启动客户端。

## v3.0.1 — 接管官方快捷方式（2026-11-14）

- 安装器会把桌面 / 开始菜单 / 任务栏固定项里的 `WorkBuddy.lnk` 改成走注入器，
  名字与图标不变，原文件备份成 `WorkBuddy.lnk.wbmods.bak`。
  点平时那个图标就能带 mod，不用记新图标。
- 新增 `-KeepOfficialIcon`：不想被接管时用，退回「只从 WorkBuddy (mods) 启动」。
- `uninstall.cmd` 在没有其它 mod 时会还原这些快捷方式。
- 已知：任务栏固定项偶尔被 Windows 缓存，取消固定再从开始菜单固定回来即可。

## v3.0.0 — 复活（2026-11-14）

5.9.2 起客户端把 renderer 打进 asar 并加了 SHA256 完整性校验，旧的 index.html 加载器方案
没有落点。这一版换成运行时注入，**不改客户端任何文件**。

- **通道**：快捷方式 → 客户端自带的 `node.exe` 跑 `injector.js` → 带 `--inspect=<随机端口>`
  启动客户端 → 连上主进程 inspector → `Runtime.evaluate` 注入 bootstrap →
  挂 `web-contents-created`，主界面 `dom-ready` 后 `executeJavaScript(mod.js)`。
  注入完成 1.2 秒后从主进程 `inspector.close()`，不留下调试端口。
- **试错记录**：先试过 `NODE_OPTIONS=--require`。fuse 是开着的，但 Electron 对打包应用
  只放行 NODE_OPTIONS 的一个白名单（内存/证书/警告类），`--require` 被过滤——
  二进制里那句 "Most NODE_OPTIONs are not supported in packaged apps" 就是这道闸。
  之后还踩过 `.vbs` 用 LF 换行、脚本宿主整行解析失败；最后干脆绕开脚本宿主，
  让快捷方式直接指向 node.exe。
- **安装器**：不碰安装目录，写 `%LOCALAPPDATA%\WbMods` + `config.json`，建快捷方式；
  安装前读 exe 的 Electron fuse，确认 `NodeCliInspect` 可用。
- **mod 脚本没改**，只补了注入时机的兼容（脚本自带 readyState 判断，晚注入也能启动）。
- **已知代价**：必须用「WorkBuddy (mods)」启动；启动时可能闪过一个最小化窗口。

## v1.4.0

修复一个会把界面弄崩的写法。

- **问题**：替换图标时用的是 `iconEl.innerHTML = svg`。图标容器是 React 管的节点，
  `innerHTML` 赋值会把它原本的子节点整个销毁。之后 React 再更新那一块，
  要去删它记住的节点却找不到，就抛 `Failed to execute 'removeChild' on 'Node'`，
  表现为输入框上方出现「输入框遇到错误」的红条。不常复现——要等 React 恰好重渲染那个图标位。
- **修复**：新增 `paint()`，不再删除或替换任何 React 节点，只做两件事——
  把原有子节点设为 `display:none`，再追加一个自己的 `<span class="wb-brand-icon">` 放图标。
  后续只改这个 span。

这条适用于所有「往 React 管的 DOM 里塞东西」的场景：
**可以加兄弟节点，可以改样式，但不要动它的孩子。**

## v1.3.0
- 修正输入框右下角"当前模型"胶囊的选择器：类名带 `cr-` 前缀，之前写成
  `.model-selector__trigger` 匹配不到，代码在跑但什么都不发生。改成 token 正则匹配，
  `--compact` / `--open` 修饰符也能命中。

## v1.2.0
- 新增对 `.cr-model-selector__trigger`（输入框里的模型胶囊）的处理。

## v1.1.0
- 修复自定义模型子菜单不生效：那里的条目挂的是 `data-testid="model-group-option-<id>"`，
  不是 `.cr-model-selector__item`。同时加了兜底——找不到图标容器就找第一个 16×16 的元素。

## v1.0.0
- 第一版：按模型名关键词替换图标，覆盖主列表与子菜单。
