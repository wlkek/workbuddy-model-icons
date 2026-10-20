# WorkBuddy 模型图标

给 WorkBuddy 的**自定义模型**自动配上官方品牌图标。

新加一个模型，只要名字里带 `kimi`、`deepseek` 这类词，菜单里就会显示对应品牌的 logo——不用挑图、不用配置。

> **非官方项目**。与 WorkBuddy / 腾讯无关。它通过修改客户端的一个入口文件注入脚本，
> 可能违反其服务条款，请自行判断。

![效果](docs/screenshot.png)

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

认不出来的保持官方默认图标（灰色立方体），不会乱贴。

## 安装

1. 下载 Release 里的 zip，解压到任意目录
2. 双击 `install.cmd`
3. **完全退出 WorkBuddy 再打开**（托盘图标右键退出，只关窗口不够）
4. 点开模型菜单

`install.cmd -Status` 看状态，`install.cmd -Uninstall` 卸载。

## 它改了什么

```
resources/app.asar.unpacked/renderer/index.html    ← 插一段 200 字节的加载器
resources/wb-model-icons/wb-model-icons.js         ← 新增的脚本
```

脚本运行时只做一件事：找到模型列表里的图标位，把官方默认的灰色立方体换成品牌 SVG。

**图标不是自己画的**——是从客户端自带的 bundle 里提取的官方 SVG 路径，所以和官方图标是同一套，视觉上分不出来。

## 安全边界

说清楚：

- **不联网**、不读对话内容、不采集数据
- 不改 `app.asar` 本体，只改一个 HTML 入口 + 新增一个 js 文件
- **fail-open**：脚本出错时列表照常显示，只是没有图标，不会把菜单弄坏
- 但修改客户端文件本身有风险，客户端更新会覆盖入口，需要重装一次

## 和「思考强度滑条」共存

两个插件互不干扰：

- 滑条改的是思考强度面板，这个改的是模型图标
- 都用同一个加载器机制，但各自插自己的一段、各自删自己的一段
- 卸载任意一个，另一个照常工作

## 工作原理

```
index.html 插加载器 → 加载 wb-model-icons.js
  → MutationObserver 监听 DOM
  → 每个模型条目按名字匹配关键词
  → 命中就把 .cr-model-selector__item-icon 里的内容换成对应的 SVG
```

覆盖三个位置：主列表条目、自定义模型子菜单、输入框右下角的当前模型胶囊。

> 踩过的坑：类名带 `cr-` 前缀，`closest('[class*=...]')` 还会先命中自己的子元素。
> 必须用精确类名或 token 匹配，否则拿到的是空集合——代码不报错，只是什么都不发生。

## License

MIT
