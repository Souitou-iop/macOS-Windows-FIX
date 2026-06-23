import AppKit
import ApplicationServices
import Foundation
import os

private let bundleID = "win.ebato.MacFocusFix"
private let logger = Logger(subsystem: bundleID, category: "focus")

private struct Options {
    var requireUURemote = true
    var reclickAfterActivation = false
    var activationDelay: TimeInterval = 0.06
}

private enum FocusState {
    case disabled
    case waitingForPermission
    case active

    var title: String {
        switch self {
        case .disabled:
            return "已关闭"
        case .waitingForPermission:
            return "等待辅助功能授权"
        case .active:
            return "已开启"
        }
    }
}

private final class FocusController {
    private var options: Options
    private let systemElement = AXUIElementCreateSystemWide()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?
    private var lastActivation = Date.distantPast
    private var suppressedUntil = Date.distantPast
    private let minimumActivationInterval: TimeInterval = 0.08
    private(set) var state = FocusState.disabled
    var onStateChanged: (() -> Void)?

    init(options: Options) {
        self.options = options
    }

    var isEnabled: Bool {
        state != .disabled
    }

    var isReclickEnabled: Bool {
        options.reclickAfterActivation
    }

    func start(prompt: Bool = true) {
        if installEventTapWhenTrusted(prompt: prompt) {
            printStatus()
            return
        }

        setState(.waitingForPermission)
        schedulePermissionTimer()
        printPermissionStatus()
    }

    func stop() {
        permissionTimer?.invalidate()
        permissionTimer = nil

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        setState(.disabled)
        logger.info("MacFocusFix event tap is disabled")
    }

    func setReclickEnabled(_ enabled: Bool) {
        options.reclickAfterActivation = enabled
        onStateChanged?()
    }

    func suppressBriefly(for interval: TimeInterval = 0.35) {
        suppressedUntil = Date().addingTimeInterval(interval)
    }

    private func schedulePermissionTimer() {
        guard permissionTimer == nil else { return }

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.installEventTapWhenTrusted(prompt: false) {
                self.printStatus()
            }
        }
    }

    private func installEventTapWhenTrusted(prompt: Bool) -> Bool {
        guard requestAccessibilityTrust(prompt: prompt) else { return false }
        guard eventTap == nil else {
            setState(.active)
            return true
        }

        let mask =
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let controller = Unmanaged<FocusController>.fromOpaque(refcon).takeUnretainedValue()
            controller.handleMouseDown(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap else {
            print("Could not create the mouse event tap. Recheck Accessibility/Input Monitoring permission for MacFocusFix.")
            return false
        }

        permissionTimer?.invalidate()
        permissionTimer = nil
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        setState(.active)
        return true
    }

    private func printStatus() {
        print("MacFocusFix is running. Press Ctrl-C to stop.")
        print("Mode: \(options.requireUURemote ? "only while UURemote is running" : "always on")\(options.reclickAfterActivation ? ", reclick enabled" : "")")
        logger.info("MacFocusFix event tap is active")
    }

    private func printPermissionStatus() {
        print("MacFocusFix is waiting for Accessibility permission.")
        print("Grant it in System Settings > Privacy & Security > Accessibility. It will start automatically after permission is granted.")
    }

    private func setState(_ newState: FocusState) {
        guard state != newState else { return }
        state = newState
        onStateChanged?()
    }

    private func requestAccessibilityTrust(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func handleMouseDown(type: CGEventType, event: CGEvent) {
        guard Date() >= suppressedUntil else { return }
        guard Date().timeIntervalSince(lastActivation) >= minimumActivationInterval else { return }
        guard !options.requireUURemote || UURemoteDetector.isRunning() else { return }

        let location = event.location
        guard !isMenuBarLocation(location) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + options.activationDelay) { [weak self] in
            self?.activateElement(at: location)
        }
    }

    private func isMenuBarLocation(_ location: CGPoint) -> Bool {
        let menuBarHeight = max(NSStatusBar.system.thickness, 24) + 8
        var displayCount: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else {
            return location.y <= menuBarHeight
        }

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        guard CGGetActiveDisplayList(displayCount, &displays, &displayCount) == .success else {
            return location.y <= menuBarHeight
        }

        return displays.prefix(Int(displayCount)).contains { display in
            let bounds = CGDisplayBounds(display)
            return location.x >= bounds.minX &&
                location.x <= bounds.maxX &&
                location.y >= bounds.minY &&
                location.y <= bounds.minY + menuBarHeight
        }
    }

    private func activateElement(at location: CGPoint) {
        guard Date() >= suppressedUntil else { return }
        guard !isMenuBarLocation(location) else { return }

        var rawElement: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(
            systemElement,
            Float(location.x),
            Float(location.y),
            &rawElement
        )

        guard result == .success, let element = rawElement else { return }

        var pid = pid_t(0)
        guard AXUIElementGetPid(element, &pid) == .success, pid > 0, pid != getpid() else { return }
        guard !isSystemUIProcess(pid: pid) else { return }

        let appElement = AXUIElementCreateApplication(pid)
        let window = focusedWindowCandidate(from: element)

        if let window {
            AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
            AXUIElementSetAttributeValue(window, kAXFocusedAttribute as CFString, kCFBooleanTrue)
            AXUIElementSetAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, window)
        }

        guard let app = NSRunningApplication(processIdentifier: pid) else { return }
        app.activate()
        lastActivation = Date()
        logger.info("Activated pid \(pid, privacy: .public) at x=\(location.x, privacy: .public) y=\(location.y, privacy: .public)")

        if options.reclickAfterActivation {
            reclick(at: location)
        }
    }

    private func focusedWindowCandidate(from element: AXUIElement) -> AXUIElement? {
        if role(of: element) == kAXWindowRole {
            return element
        }

        var rawWindow: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXWindowAttribute as CFString, &rawWindow) == .success,
           CFGetTypeID(rawWindow) == AXUIElementGetTypeID() {
            return (rawWindow as! AXUIElement)
        }

        var current: AXUIElement? = element
        for _ in 0..<8 {
            guard let item = current else { break }

            var rawParent: CFTypeRef?
            guard AXUIElementCopyAttributeValue(item, kAXParentAttribute as CFString, &rawParent) == .success,
                  CFGetTypeID(rawParent) == AXUIElementGetTypeID() else {
                break
            }

            let parent = rawParent as! AXUIElement
            if role(of: parent) == kAXWindowRole {
                return parent
            }
            current = parent
        }

        return nil
    }

    private func role(of element: AXUIElement) -> String? {
        var rawRole: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &rawRole) == .success else {
            return nil
        }
        return rawRole as? String
    }

    private func isSystemUIProcess(pid: pid_t) -> Bool {
        guard let app = NSRunningApplication(processIdentifier: pid),
              let bundleIdentifier = app.bundleIdentifier else {
            return false
        }

        return bundleIdentifier == "com.apple.systemuiserver" ||
            bundleIdentifier == "com.apple.controlcenter" ||
            bundleIdentifier == "com.apple.TextInputMenuAgent"
    }

    private func reclick(at location: CGPoint) {
        guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: location, mouseButton: .left),
              let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: location, mouseButton: .left) else {
            return
        }

        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}

private enum UURemoteDetector {
    static func isRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            guard let bundleIdentifier = app.bundleIdentifier else { return false }
            return bundleIdentifier.hasPrefix("com.netease.uuremote")
        }
    }
}

private final class MenuBarController: NSObject, NSMenuDelegate {
    private let focusController: FocusController
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem()
    private let toggleMenuItem = NSMenuItem()
    private let reclickMenuItem = NSMenuItem()

    init(focusController: FocusController) {
        self.focusController = focusController
        super.init()
        configureStatusItem()
        configureMenu()
        focusController.onStateChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.updateMenu()
            }
        }
        updateMenu()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.image = statusImage(active: true, appearance: button.effectiveAppearance)
        button.imagePosition = .imageOnly
        button.title = button.image == nil ? "FF" : ""

        button.toolTip = "MacFocusFix 焦点修复"
    }

    private func configureMenu() {
        menu.delegate = self

        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        toggleMenuItem.target = self
        toggleMenuItem.action = #selector(toggleFocusFix)
        menu.addItem(toggleMenuItem)

        reclickMenuItem.title = "备用模式：激活后二次点击"
        reclickMenuItem.target = self
        reclickMenuItem.action = #selector(toggleReclick)
        menu.addItem(reclickMenuItem)

        menu.addItem(.separator())

        let accessibilityItem = NSMenuItem(title: "打开辅助功能设置", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        accessibilityItem.target = self
        menu.addItem(accessibilityItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出 MacFocusFix", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        focusController.suppressBriefly()
        updateMenu()
    }

    func menuDidClose(_ menu: NSMenu) {
        focusController.suppressBriefly()
    }

    private func updateMenu() {
        statusMenuItem.title = "状态：\(focusController.state.title)"
        toggleMenuItem.title = focusController.isEnabled ? "关闭焦点修复" : "开启焦点修复"
        reclickMenuItem.state = focusController.isReclickEnabled ? .on : .off

        guard let button = statusItem.button else { return }
        button.image = statusImage(active: focusController.state == .active, appearance: button.effectiveAppearance)
        button.title = button.image == nil ? "FF" : ""
        button.contentTintColor = nil
        button.needsDisplay = true
    }

    private func statusImage(active: Bool, appearance: NSAppearance) -> NSImage? {
        guard let baseImage = statusIconImage() else { return nil }

        let mode = appearance.bestMatch(from: [.darkAqua, .aqua])
        let color: NSColor
        if active {
            color = mode == .darkAqua ? .white : .black
        } else {
            color = mode == .darkAqua
                ? NSColor(calibratedWhite: 0.45, alpha: 1.0)
                : NSColor(calibratedWhite: 0.66, alpha: 1.0)
        }
        let size = NSSize(width: 18, height: 18)
        let rect = NSRect(origin: .zero, size: size)
        let image = NSImage(size: size)

        image.lockFocus()
        baseImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        color.setFill()
        rect.fill(using: .sourceAtop)
        image.unlockFocus()

        image.isTemplate = false
        return image
    }

    private func statusIconImage() -> NSImage? {
        guard let url = Bundle.module.url(forResource: "MenuBarIcon", withExtension: "svg") else {
            return nil
        }

        return NSImage(contentsOf: url)
    }

    @objc private func toggleFocusFix() {
        if focusController.isEnabled {
            focusController.stop()
        } else {
            focusController.start(prompt: true)
        }
    }

    @objc private func toggleReclick() {
        focusController.setReclickEnabled(!focusController.isReclickEnabled)
    }

    @objc private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let focusController: FocusController
    private var menuBarController: MenuBarController?

    init(options: Options) {
        focusController = FocusController(options: options)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController(focusController: focusController)
        focusController.start(prompt: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        focusController.stop()
    }
}

private func parseOptions() -> Options {
    var options = Options()

    for argument in CommandLine.arguments.dropFirst() {
        switch argument {
        case "--always":
            options.requireUURemote = false
        case "--reclick":
            options.reclickAfterActivation = true
        case "--help", "-h":
            print("""
            usage: MacFocusFix [--always] [--reclick]

              --always   Run even when UURemote is not running.
              --reclick  After activating the target app, send one local left click at the same point.
                         This is a fallback for text fields that still do not accept typing.
            """)
            exit(0)
        default:
            print("Unknown argument: \(argument)")
            exit(2)
        }
    }

    return options
}

private let options = parseOptions()
private let app = NSApplication.shared
app.setActivationPolicy(.accessory)

private let appDelegate = AppDelegate(options: options)
app.delegate = appDelegate
app.run()
