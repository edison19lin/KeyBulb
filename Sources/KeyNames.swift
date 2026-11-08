import AppKit

/// 一個按鍵的顯示資訊：符號 + 英文名稱
struct KeyInfo {
    let symbol: String
    let name: String
    /// 是否為 Mac 特殊鍵（修飾鍵、功能鍵、方向鍵…）
    let special: Bool
}

enum KeyNames {
    /// Mac 特殊鍵：以 keyCode 對照（左右修飾鍵分開）
    static let special: [UInt16: KeyInfo] = {
        var m: [UInt16: KeyInfo] = [:]
        func add(_ code: UInt16, _ symbol: String, _ name: String) {
            m[code] = KeyInfo(symbol: symbol, name: name, special: true)
        }
        // 修飾鍵
        add(55, "⌘", "Left Command")
        add(54, "⌘", "Right Command")
        add(56, "⇧", "Left Shift")
        add(60, "⇧", "Right Shift")
        add(58, "⌥", "Left Option")
        add(61, "⌥", "Right Option")
        add(59, "⌃", "Left Control")
        add(62, "⌃", "Right Control")
        add(57, "⇪", "Caps Lock")
        add(63, "fn", "Function (fn / 🌐 Globe)")
        // 編輯 / 導覽
        add(36, "↩", "Return")
        add(76, "⌤", "Enter (Keypad)")
        add(48, "⇥", "Tab")
        add(49, "␣", "Space")
        add(51, "⌫", "Delete (Backspace)")
        add(117, "⌦", "Forward Delete")
        add(53, "⎋", "Escape")
        add(71, "⌧", "Clear (Keypad)")
        add(114, "?⃝", "Help / Insert")
        add(115, "↖", "Home")
        add(119, "↘", "End")
        add(116, "⇞", "Page Up")
        add(121, "⇟", "Page Down")
        add(123, "←", "Left Arrow")
        add(124, "→", "Right Arrow")
        add(125, "↓", "Down Arrow")
        add(126, "↑", "Up Arrow")
        // 日文鍵盤
        add(102, "英数", "Eisu (JIS)")
        add(104, "かな", "Kana (JIS)")
        // F1–F20
        let fkeys: [(UInt16, Int)] = [
            (122, 1), (120, 2), (99, 3), (118, 4), (96, 5), (97, 6), (98, 7), (100, 8),
            (101, 9), (109, 10), (103, 11), (111, 12), (105, 13), (107, 14), (113, 15),
            (106, 16), (64, 17), (79, 18), (80, 19), (90, 20),
        ]
        for (code, n) in fkeys { add(code, "F\(n)", "Function Key F\(n)") }
        return m
    }()

    /// 數字鍵盤（Keypad）
    static let keypad: [UInt16: String] = [
        65: ".", 67: "*", 69: "+", 75: "/", 78: "-", 81: "=",
        82: "0", 83: "1", 84: "2", 85: "3", 86: "4", 87: "5", 88: "6", 89: "7", 91: "8", 92: "9",
    ]

    /// 一般按鍵的英文名稱
    static let punctuation: [String: String] = [
        "`": "Grave Accent", "-": "Minus", "=": "Equals", "[": "Left Bracket", "]": "Right Bracket",
        "\\": "Backslash", ";": "Semicolon", "'": "Quote", ",": "Comma", ".": "Period", "/": "Slash",
        "§": "Section",
    ]

    static func info(keyCode: UInt16, charactersIgnoringModifiers chars: String?) -> KeyInfo {
        if let s = special[keyCode] { return s }
        if let k = keypad[keyCode] { return KeyInfo(symbol: k, name: "Keypad \(k)", special: false) }
        let c = chars ?? ""
        if let p = punctuation[c] { return KeyInfo(symbol: c, name: p, special: false) }
        if c.count == 1, let ch = c.first {
            if ch.isLetter { return KeyInfo(symbol: c.uppercased(), name: "Letter \(c.uppercased())", special: false) }
            if ch.isNumber { return KeyInfo(symbol: c, name: "Digit \(c)", special: false) }
            return KeyInfo(symbol: c, name: "Character \(c)", special: false)
        }
        return KeyInfo(symbol: "?", name: "Key Code \(keyCode)", special: false)
    }

    /// 修飾鍵在組合鍵字串中的順序（Apple 慣例：⌃⌥⇧⌘）
    static let modifierOrder: [(NSEvent.ModifierFlags, String, String)] = [
        (.function, "fn", "Function"),
        (.control, "⌃", "Control"),
        (.option, "⌥", "Option"),
        (.shift, "⇧", "Shift"),
        (.command, "⌘", "Command"),
        (.capsLock, "⇪", "Caps Lock"),
    ]

    /// 修飾鍵本身的 keyCode 對應到哪個 flag
    static let modifierFlag: [UInt16: NSEvent.ModifierFlags] = [
        55: .command, 54: .command, 56: .shift, 60: .shift, 58: .option, 61: .option,
        59: .control, 62: .control, 57: .capsLock, 63: .function,
    ]

    /// 符號對照表（顯示在畫面上）
    static let legend: [(String, String)] = [
        ("⌘", "Command"), ("⌥", "Option"), ("⌃", "Control"), ("⇧", "Shift"),
        ("⇪", "Caps Lock"), ("fn", "Function / 🌐"), ("↩", "Return"), ("⌤", "Enter"),
        ("⇥", "Tab"), ("⌫", "Delete"), ("⌦", "Fwd Delete"), ("⎋", "Escape"),
        ("␣", "Space"), ("↖", "Home"), ("↘", "End"), ("⇞", "Page Up"),
        ("⇟", "Page Down"), ("←→↑↓", "Arrows"), ("⌧", "Clear"), ("F1–F20", "Function Keys"),
    ]
}
