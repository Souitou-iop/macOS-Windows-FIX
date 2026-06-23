<p align="center">
  <img src="../macOS-Windows-FIX%20Exports/macOS-Windows-FIX.icon/Assets/icon%E5%BE%85%E5%AE%9A.png" width="160" alt="MacFocusFix 图标">
</p>

<h1 align="center">MacFocusFix</h1>

<p align="center">
  一个轻量 macOS 菜单栏工具，用来修复远程点击后键盘焦点仍留在旧 App 的问题。
</p>

<p align="center">
  <a href="../README.md">English</a> | <strong>简体中文</strong>
</p>

<p align="center">
  <a href="https://github.com/Souitou-iop/macOS-Windows-FIX/releases">下载</a> ·
  <a href="https://github.com/Souitou-iop/macOS-Windows-FIX/actions/workflows/release.yml">构建</a> ·
  <a href="https://github.com/Souitou-iop/macOS-Windows-FIX/issues">反馈</a>
</p>

## 为什么写这个软件

升级到 macOS 27 之后，我在使用 UU 远程这类远程控制工具时遇到了一个很奇怪的焦点问题：远程鼠标点击确实能到达目标窗口，按钮会响应，输入框也像是被点到了；但 macOS 没有把这个窗口所属的 App 变成真正的前台 App。Apple 菜单右侧显示的 App 名称仍然停在旧 App，后续键盘输入也继续进入旧 App。

当时最稳定的手动 workaround 是先点目标窗口的标题栏。标题栏点击能触发真正的窗口激活，但这会打断正常远控体验：每次想在另一个 App 里打字，都要先记得点窗口边框，而不是直接点内容区域。

前期排查后，这个问题不像普通应用设置能解决。辅助功能权限、重启 UI 组件、远控设置都值得检查，但症状更像是系统层的输入路由变化：鼠标事件到了，WindowServer / Accessibility 负责切换真正前台 App 的那一步没有发生。Apple 自家的远控链路也在新系统上围绕输入和辅助功能做过适配，这进一步说明第三方远控可能需要跟进新的事件注入行为。

MacFocusFix 就是这次排查后做出来的一个小型本机补偿器。它不替代远控软件，而是运行在被控制的 Mac 上，监听鼠标点击，找到指针下方窗口所属的 App，并显式激活它，让键盘焦点重新跟随鼠标点击。

## 功能

- 只驻留菜单栏，不显示 Dock 图标。
- 可以从菜单栏开启或关闭焦点修复。
- 提供“激活后二次点击”兜底模式。
- 会忽略 macOS 顶部菜单栏和已知系统 UI 进程，因此不会干扰控制中心、Wi-Fi、输入法等系统控件。
- App 图标来自 Icon Composer 导出资源，菜单栏图标使用单独的模板风格图标。

## 安装

1. 到 [Releases](https://github.com/Souitou-iop/macOS-Windows-FIX/releases) 下载最新 zip。
2. 解压。
3. 把 `MacFocusFix.app` 拖到 `/Applications`。
4. 启动应用。
5. 如果 macOS 提示权限，在系统设置里允许“辅助功能”。

如果 macOS 因为未 notarize 而阻止打开，请在 Finder 里按住 Control 点按应用，选择“打开”，然后确认。当前构建使用 ad hoc 签名，不是 Developer ID notarization。

## 菜单栏

- 状态：显示已开启、已关闭或等待辅助功能授权。
- 开启 / 关闭焦点修复：安装或移除鼠标事件监听。
- 激活后二次点击：给“已激活但仍不能输入”的 App 做兜底。
- 打开辅助功能设置
- 退出 MacFocusFix

## 本地构建

```zsh
./script/build_app.sh
./script/build_and_run.sh
```

`build_app.sh` 会生成 `dist/MacFocusFix.app`，并使用 ad hoc 签名。
`build_and_run.sh` 会构建并打开应用。

## 发布

GitHub Actions 会在 macOS runner 上构建发布产物。推送 `v0.1.0` 这类标签时，会生成 zip 格式的 `.app` 包并发布到 GitHub Release。

## 卸载

退出 MacFocusFix，然后把 `MacFocusFix.app` 移到废纸篓。如果之前授予过辅助功能权限，也可以在系统设置里移除它。

## 兼容性

MacFocusFix 使用 SwiftPM 构建，目标系统为 macOS 14 或更新版本。
