# 变更记录

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
