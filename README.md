# WorkBuddy 模型图标

给 WorkBuddy 的自定义模型自动配上品牌图标。模型名里包含 `kimi`、`deepseek` 这类关键词时，
菜单里就会显示对应的 logo，不需要手动挑图。

**非官方项目**，与 WorkBuddy、腾讯没有关系。它通过运行时注入修改界面，
可能违反客户端的服务条款，使用前请自行评估。

![效果](docs/screenshot.png)

## 版本说明

v3 起改用运行时注入，不再修改客户端的任何文件。

原因是 5.9.2 开始，客户端把 renderer 打包进 `app.asar` 并加了 SHA256 完整性校验，
原先「往 `app.asar.unpacked/renderer/index.html` 插入加载器」的做法已经没有入口。

现在的流程是：快捷方式调用客户端自带的 `node.exe` 运行注入器，
注入器带 `--inspect` 启动客户端，连上主进程后把 mod 脚本注入页面，随后关闭调试端口。

已在 Windows 版 WorkBuddy 5.9.3 上验证。

## 功能

在模型列表、自定义模型子菜单、输入框右下角的模型胶囊里，把默认的灰色立方体换成品牌图标。

匹配不依赖固定的类名前缀：`cr-`、`wb-` 或以后换成别的都可以，
只要类名以 `-model-selector__item`、`__item-name`、`__item-icon` 结尾就能识别。

没有匹配到的模型保持官方默认图标，找不到结构时不改动 DOM。

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

## 安装

需要 WorkBuddy 5.9.2 或更新版本。

1. 下载 Release 中的 zip，解压到任意目录
2. 双击 `install.cmd`
3. 在托盘右键完全退出 WorkBuddy
4. 用原来的图标启动，桌面、开始菜单、任务栏均可

安装完成后打开模型菜单即可看到图标。

### 关于快捷方式

安装器会接管桌面、开始菜单、任务栏固定项里的 `WorkBuddy.lnk`：把目标改成注入器，
原文件备份为 `WorkBuddy.lnk.wbmods.bak`，图标和名称保持不变。

如果不想让官方图标被接管，使用 `install.cmd -KeepOfficialIcon`，
此时只能通过新创建的「WorkBuddy (mods)」快捷方式启动。

启动时可能出现一个最小化窗口，那是注入器，注入完成后会自动退出。

### 安装目录识别

安装目录可以是任意盘符、任意路径，含中文或空格也可以，不要求目录名是 `WorkBuddy`。

安装器按以下顺序查找，只要目录里存在 `resources\app.asar` 就认定为客户端：

1. 上次安装时记录的路径
2. 正在运行的客户端进程
3. 注册表卸载项（`DisplayIcon`、`InstallLocation`、`UninstallString`）
4. App Paths（HKLM / HKCU，含 WOW6432Node）
5. 桌面、公共桌面、开始菜单、任务栏固定项的快捷方式
6. 默认安装位置

其中快捷方式不看文件名，只看目标或图标是否指向 `WorkBuddy.exe`。
注册表部分需要注意：不少安装器只填 `DisplayIcon`，`InstallLocation` 是空的，
所以只读后者会漏掉。

如果都找不到，安装器会报错，可以用 `install.cmd -AppRoot "D:\你的路径\WorkBuddy"` 手动指定。

### 客户端升级或被移动之后

- 快捷方式指向 `%LOCALAPPDATA%\WbMods\node.exe`，这是客户端自带 node 的硬链接，
  不额外占用空间。客户端升级后即使换掉了 `versions\<版本号>\` 目录，图标也不会失效。
- `config.json` 里保存了安装时探测到的全部候选路径，
  注入器在主路径失效时会按候选逐个尝试。

## 卸载

双击 `uninstall.cmd`。会删除自己这份 mod，并还原被接管过的快捷方式。

`install.cmd -Status` 可以查看当前状态。

## 工作原理

```
快捷方式 → node.exe injector.js
             ├─ 带 --inspect=<随机端口> 启动 WorkBuddy
             ├─ 连上主进程 inspector，注入一段 bootstrap
             ├─ bootstrap 挂 web-contents-created，页面 dom-ready 后执行 mod
             └─ 注入完成 1.2 秒后关闭 inspector，不留下调试端口
```

只注入 `app.asar/renderer/index.html`，guest 页面跳过。启动客户端时会清掉
`ELECTRON_RUN_AS_NODE`，避免它被当成 node 进程运行。

没有采用 `NODE_OPTIONS --require`，是因为 Electron 对打包应用只放行 NODE_OPTIONS
的一个白名单，`--require` 不在其中。

## 兼容性

- Windows 10 / 11 x64，使用 PowerShell 5.1，不需要额外安装组件
- 客户端 5.9.2 / 5.9.3 已验证；5.8.3 及更早版本请使用 v2.x
- 装在 Program Files 也可以，不需要管理员权限；公共桌面的快捷方式在没有权限时会跳过
- 绿色解压版、包管理器安装的版本可能没有注册表项，也没有自带的 node 运行时，
  自动识别会失败，此时用 `-AppRoot` 指定一次即可
- 注入失败时客户端照常启动，只是没有图标

## 排查

日志在 `%LOCALAPPDATA%\WbMods\loader.log`。正常一次启动的记录如下：

```
injector spawn app with --inspect=1999
main bootstrap ok, mods=2
injector evaluate => OK:2
main injected model-icons@3.0.0
main inspector closed
```

| 现象 | 处理方式 |
|---|---|
| 日志没有新增 | 快捷方式没有被接管，重跑一次 `install.cmd` |
| 有 `spawn app` 没有 `bootstrap ok` | 客户端已经在运行，先完全退出 |
| 有 `bootstrap ok` 没有 `injected` | 页面 URL 不匹配，客户端改版了 |
| 出现 `app exe not found` | 客户端被移动过，候选路径也失效了，重跑 `install.cmd` |

如果想确认注入器能否找到客户端、能否读到 mod，可以不启动客户端，直接做 dry-run：

```powershell
$env:WB_DRY_RUN=1
& "$env:LOCALAPPDATA\WbMods\node.exe" "$env:LOCALAPPDATA\WbMods\injector.js"
```

日志里会多一行 `dry-run app=<实际用到的路径> mods=[...]`。
如果安装后连这行都没有，问题出在快捷方式，不在注入。

任务栏固定项点了还是原版时，右键取消固定，再从开始菜单重新固定即可。
Windows 有时会缓存旧的固定项。

## 安全边界

- 不联网、不读对话内容、不采集数据，只操作模型菜单的 DOM
- 不修改客户端任何文件，所有内容都位于 `%LOCALAPPDATA%\WbMods`
- 会改写快捷方式，但有备份，卸载时会还原
- 调试端口只在启动后存在约 1 秒，注入完成即关闭

## 与「思考强度滑条」共存

两个 mod 共用同一个注入器和快捷方式，各自安装在 `mods/<id>/` 下。
安装顺序随意，卸载任意一个不影响另一个。

## License

MIT
