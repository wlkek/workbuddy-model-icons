# 变更记录

## v3.0.0 — 复活（2026-11-14）

5.9.2 起客户端把 renderer 打进 asar 并加了 SHA256 完整性校验，旧的 index.html 加载器方案
没有落点。这一版换成运行时注入，**不再改客户端任何文件**。

- **新通道**：`NODE_OPTIONS=--require hook.js`（Electron 的 `EnableNodeOptionsEnvironmentVariable` fuse，
  5.9.3 实测为开）→ main 进程监听 `web-contents-created` → 主界面 `dom-ready` 后
  `executeJavaScript(mod.js)`。
- **hook 的三条约束**：只认 `process.type === 'browser'`；启动后立刻把 `--require` 从
  `NODE_OPTIONS` 摘掉，避免被 agent 的 node 子进程继承；只注入
  `app.asar/renderer/index.html`，guest 页面跳过。
- **安装器重写**：不再碰安装目录，改为复制到 `%LOCALAPPDATA%\WbMods`、生成 `launch.vbs`、
  建桌面/开始菜单快捷方式；安装前读 exe 的 fuse 串，通道不可用时明确提示。
- **mod 脚本本身没改**（v1.4.0 的 DOM 逻辑在 5.9.3 上仍然成立：`model-selector__item*`
  类名都还在），只补了注入时机的兼容——脚本本来就判断 `document.readyState`，晚注入也能启动。
- **已知代价**：必须用新快捷方式启动；`NODE_OPTIONS` 注入可能被杀软拦。

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
