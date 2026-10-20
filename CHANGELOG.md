# 变更记录

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
