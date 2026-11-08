import AppKit
import SwiftUI

struct KeyRecord: Identifiable {
    let id = UUID()
    let info: KeyInfo
    /// 組合鍵符號，例如 ⌘⇧A
    let combo: String
    /// 組合鍵英文，例如 Command + Shift + A
    let comboName: String
    let keyCode: Int?
    let characters: String
    let action: String
    let time = Date()
}

final class KeyModel: ObservableObject {
    @Published var current: KeyRecord?
    @Published var flags: NSEvent.ModifierFlags = []
    /// 左右修飾鍵各自是否按住（依 keyCode）
    @Published var heldModifiers: Set<UInt16> = []
    @Published var history: [KeyRecord] = []
    @Published var showLegend = true

    private var monitors: [Any] = []

    // 左右修飾鍵的 device-dependent 位元（IOKit NX_DEVICE*KEYMASK）
    private static let sideMask: [UInt16: UInt] = [
        59: 0x0001, 62: 0x2000,     // Control L/R
        56: 0x0002, 60: 0x0004,     // Shift L/R
        55: 0x0008, 54: 0x0010,     // Command L/R
        58: 0x0020, 61: 0x0040,     // Option L/R
    ]

    func start() {
        guard monitors.isEmpty else { return }
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] e in
            guard let self else { return e }
            // ⌘Q 仍可結束 App，其他按鍵都吃掉，避免觸發選單或發出提示音
            if e.type == .keyDown,
               e.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
               e.charactersIgnoringModifiers == "q" {
                return e
            }
            if e.type == .keyDown { self.keyDown(e) }
            return nil
        } as Any)
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] e in
            self?.flagsChanged(e)
            return e
        } as Any)
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { [weak self] e in
            self?.systemDefined(e)
            return e
        } as Any)
    }

    private func push(_ r: KeyRecord) {
        current = r
        history.insert(r, at: 0)
        if history.count > 50 { history.removeLast(history.count - 50) }
    }

    func clear() {
        current = nil
        history.removeAll()
    }

    private func keyDown(_ e: NSEvent) {
        let info = KeyNames.info(keyCode: e.keyCode, charactersIgnoringModifiers: e.charactersIgnoringModifiers)
        let f = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var symbols: [String] = []
        var names: [String] = []
        for (flag, sym, name) in KeyNames.modifierOrder {
            guard f.contains(flag), flag != .capsLock else { continue }
            // 方向鍵、F 鍵等系統會自動帶 fn 旗標，不算使用者按的 fn
            if flag == .function && info.special && !heldModifiers.contains(63) { continue }
            symbols.append(sym)
            names.append(name)
        }
        let keyName = info.special ? info.name : info.symbol
        let combo = (symbols + [info.symbol]).joined()
        let comboName = (names + [keyName]).joined(separator: " + ")
        push(KeyRecord(info: info, combo: combo, comboName: comboName, keyCode: Int(e.keyCode),
                       characters: visible(e.characters ?? ""),
                       action: e.isARepeat ? "按住重複" : "按下"))
    }

    private func flagsChanged(_ e: NSEvent) {
        flags = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let code = e.keyCode
        guard let flag = KeyNames.modifierFlag[code] else { return }
        let info = KeyNames.info(keyCode: code, charactersIgnoringModifiers: nil)
        let down: Bool
        if let mask = Self.sideMask[code] {
            down = e.modifierFlags.rawValue & mask != 0
        } else {
            down = flags.contains(flag)
        }
        if code == 57 {
            // Caps Lock 是切換鍵：按一次開、再按一次關
            push(KeyRecord(info: info, combo: info.symbol, comboName: info.name, keyCode: Int(code),
                           characters: "", action: down ? "開啟" : "關閉"))
            return
        }
        if down { heldModifiers.insert(code) } else { heldModifiers.remove(code) }
        if down {
            push(KeyRecord(info: info, combo: info.symbol, comboName: info.name, keyCode: Int(code),
                           characters: "", action: "按下"))
        }
    }

    /// 媒體鍵（音量、亮度、播放…）
    private func systemDefined(_ e: NSEvent) {
        guard e.subtype.rawValue == 8 else { return }
        let code = (e.data1 & 0xFFFF0000) >> 16
        let down = ((e.data1 & 0xFF00) >> 8) == 0x0A
        guard down else { return }
        let table: [Int: (String, String)] = [
            0: ("🔊", "Volume Up"), 1: ("🔉", "Volume Down"), 7: ("🔇", "Mute"),
            2: ("🔆", "Brightness Up"), 3: ("🔅", "Brightness Down"),
            16: ("⏯", "Play / Pause"), 17: ("⏭", "Next Track"), 18: ("⏮", "Previous Track"),
            19: ("⏩", "Fast Forward"), 20: ("⏪", "Rewind"),
            21: ("💡", "Keyboard Light Up"), 22: ("💡", "Keyboard Light Down"),
            14: ("⏏", "Eject"),
        ]
        let (sym, name) = table[code] ?? ("◆", "Media Key \(code)")
        let info = KeyInfo(symbol: sym, name: name, special: true)
        push(KeyRecord(info: info, combo: sym, comboName: name, keyCode: nil, characters: "", action: "按下"))
    }

    private func visible(_ s: String) -> String {
        s.unicodeScalars.map { u in
            if u.value < 0x20 || u.value == 0x7F || (0xF700...0xF8FF).contains(u.value) {
                return String(format: "U+%04X", u.value)
            }
            return String(u)
        }.joined(separator: " ")
    }
}
