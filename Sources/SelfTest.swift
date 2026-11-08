import AppKit

/// 自我測試：設定環境變數 KEYBULB_SELFTEST=輸出資料夾 時，
/// 送出模擬按鍵 → 把視窗截圖存成 PNG → 結束 App。
enum SelfTest {
    static func runIfRequested(model: KeyModel) {
        guard let dir = ProcessInfo.processInfo.environment["KEYBULB_SELFTEST"] else { return }
        let steps: [(NSEvent.EventType, UInt16, String, NSEvent.ModifierFlags)] = [
            (.flagsChanged, 55, "", [.command, NSEvent.ModifierFlags(rawValue: 0x08)]),
            (.flagsChanged, 56, "", [.command, .shift, NSEvent.ModifierFlags(rawValue: 0x0A)]),
            (.keyDown, 0, "a", [.command, .shift]),
            (.flagsChanged, 56, "", [.command, NSEvent.ModifierFlags(rawValue: 0x08)]),
            (.flagsChanged, 55, "", []),
            (.keyDown, 126, "\u{F700}", [.function, .numericPad]),
            (.keyDown, 53, "\u{1B}", []),
            (.keyDown, 122, "\u{F704}", [.function]),
            (.flagsChanged, 58, "", [.option, NSEvent.ModifierFlags(rawValue: 0x20)]),
            (.keyDown, 51, "\u{7F}", [.option]),
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard let win = NSApp.windows.first(where: { $0.isVisible }) else { exit(2) }
            for (type, code, chars, flags) in steps {
                let e = NSEvent.keyEvent(with: type, location: .zero, modifierFlags: flags,
                                         timestamp: ProcessInfo.processInfo.systemUptime,
                                         windowNumber: win.windowNumber, context: nil,
                                         characters: chars, charactersIgnoringModifiers: chars,
                                         isARepeat: false, keyCode: code)!
                NSApp.postEvent(e, atStart: false)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let lines = model.history.reversed().map { "\($0.combo)\t\($0.comboName)\t\($0.action)" }
                try? lines.joined(separator: "\n").write(toFile: dir + "/history.txt", atomically: true, encoding: .utf8)
                if let view = win.contentView?.superview ?? win.contentView,
                   let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                    view.cacheDisplay(in: view.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?
                        .write(to: URL(fileURLWithPath: dir + "/window.png"))
                }
                NSApp.terminate(nil)
            }
        }
    }
}
