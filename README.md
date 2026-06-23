# MacFocusFix

A lightweight macOS menu bar app that keeps remote-control clicks from leaving keyboard focus behind.
It is built for the case where a click lands on the right window, but typing still goes to the old app.

## English

### What it does

MacFocusFix listens for mouse clicks and promotes the clicked app to the front so keyboard input follows the pointer.
It is designed for remote-control workflows such as UU Remote.

### Download

Get the latest release from [Releases](https://github.com/Souitou-iop/macOS-Windows-FIX/releases).

### Install

1. Download the release zip.
2. Unzip it and move `MacFocusFix.app` to `/Applications`.
3. Launch the app.
4. Grant Accessibility permission in System Settings if macOS asks for it.

### Menu bar actions

- Status: shows whether the helper is on, off, or waiting for permission.
- Enable / Disable: turns the focus fix on or off.
- Reclick after activation: fallback mode for apps that still do not accept typing after activation.
- Open Accessibility Settings
- Quit

### Build locally

```zsh
./script/build_app.sh
./script/build_and_run.sh
```

`build_app.sh` creates `dist/MacFocusFix.app` and signs it ad hoc for local use.
`build_and_run.sh` builds the app and opens it.

### Release notes

Release builds are produced by GitHub Actions as a zipped `.app` bundle.
The project currently uses ad hoc signing for local and CI builds and is not notarized.

### Uninstall

Quit the app, then move `MacFocusFix.app` to the Trash.

### Limitations

MacFocusFix ignores clicks in the screen menu bar area and skips known system UI processes so it does not interfere with Control Center, Wi-Fi, or input method controls.

## 中文

### 它做什么

MacFocusFix 是一个 macOS 菜单栏工具，用来修复远程控制时“点击已经到了正确窗口，但键盘输入还留在旧 App 里”的问题。
它适合 UU Remote 这类远程点击场景。

### 下载

到 [Releases](https://github.com/Souitou-iop/macOS-Windows-FIX/releases) 下载最新版本。

### 安装

1. 下载 release 压缩包。
2. 解压后把 `MacFocusFix.app` 拖到 `/Applications`。
3. 启动应用。
4. 如果 macOS 提示权限，去系统设置里开启“辅助功能”。

### 菜单栏功能

- 状态：显示已开启、已关闭或等待授权。
- 开启 / 关闭：控制焦点修复是否生效。
- 激活后二次点击：给“激活后仍不能输入”的应用做兜底。
- 打开辅助功能设置
- 退出

### 本地构建

```zsh
./script/build_app.sh
./script/build_and_run.sh
```

`build_app.sh` 会生成 `dist/MacFocusFix.app`，并使用 ad hoc 签名，适合本地和 CI。
`build_and_run.sh` 会构建并打开应用。

### 发布说明

GitHub Actions 会把 release 构建打成 zip 格式的 `.app` 包。
当前项目的本地和 CI 构建都使用 ad hoc 签名，暂未做 notarization。

### 卸载

退出应用后，直接把 `MacFocusFix.app` 移到废纸篓即可。

### 已知边界

MacFocusFix 会忽略屏幕顶部菜单栏区域的点击，并跳过已知系统 UI 进程，因此不会干扰控制中心、Wi-Fi 和输入法控件。
