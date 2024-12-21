import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var popover: NSPopover?
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarIcon()
    }

    private func setupStatusBarIcon() {
        // 创建状态栏项
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        NSApp.delegate = self
        // 设置图标
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Serial Communication")
            //button.imageScaling = .scaleAxesIndependently
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // NSApp.delegate = self
        
        // 设置 Popover
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: ContentView())
        popover?.behavior = .transient  // popover 关闭时自动销毁
    }

    @objc private func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                if let button = statusBarItem?.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }
}
