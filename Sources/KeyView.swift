import SwiftUI

private let accent = Color(red: 1.0, green: 0.81, blue: 0.28)

struct KeyView: View {
    @ObservedObject var model: KeyModel

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 18) {
                hero
                modifiers
                historyList
            }
            .padding(20)
            .frame(minWidth: 440)

            if model.showLegend {
                Divider()
                legend
                    .frame(width: 230)
            }
        }
        .frame(minWidth: 440, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbar {
            ToolbarItemGroup {
                Button { model.clear() } label: { Label("清除紀錄", systemImage: "trash") }
                    .help("清除紀錄")
                Button { model.showLegend.toggle() } label: { Label("符號對照表", systemImage: "sidebar.right") }
                    .help("顯示 / 隱藏符號對照表")
            }
        }
    }

    // MARK: 目前按鍵

    private var hero: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [Color(white: 0.24), Color(white: 0.12)],
                                         startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 5)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(model.current?.info.special == true ? accent : Color.white.opacity(0.15),
                                  lineWidth: 2)
                Text(model.current?.combo ?? "⌨︎")
                    .font(.system(size: 72, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .padding(.horizontal, 20)
            }
            .frame(height: 150)
            .frame(maxWidth: 360)
            .id(model.current?.id)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
            .animation(.spring(duration: 0.18), value: model.current?.id)

            Text(model.current?.comboName ?? "請按任意鍵")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            HStack(spacing: 16) {
                infoItem("Key Code", model.current?.keyCode.map(String.init) ?? "—")
                infoItem("字元", model.current?.characters.isEmpty == false ? model.current!.characters : "—")
                infoItem("動作", model.current?.action ?? "—")
            }
        }
    }

    private func infoItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.body, design: .monospaced)).textSelection(.enabled)
        }
        .frame(minWidth: 90)
    }

    // MARK: 修飾鍵狀態

    private var modifiers: some View {
        HStack(spacing: 8) {
            chip("⌃", "Control", left: 59, right: 62)
            chip("⌥", "Option", left: 58, right: 61)
            chip("⇧", "Shift", left: 56, right: 60)
            chip("⌘", "Command", left: 55, right: 54)
            chip("fn", "Function", left: 63, right: nil)
            chip("⇪", "Caps Lock", on: model.flags.contains(.capsLock), side: "")
        }
    }

    private func chip(_ sym: String, _ name: String, left: UInt16, right: UInt16?) -> some View {
        let l = model.heldModifiers.contains(left)
        let r = right.map { model.heldModifiers.contains($0) } ?? false
        let side = right == nil ? "" : (l && r ? "左+右" : l ? "左" : r ? "右" : "")
        return chip(sym, name, on: l || r, side: side)
    }

    private func chip(_ sym: String, _ name: String, on: Bool, side: String) -> some View {
        VStack(spacing: 2) {
            Text(sym).font(.system(size: 20, weight: .semibold, design: .rounded))
            Text(name).font(.system(size: 10))
            Text(side.isEmpty ? " " : side).font(.system(size: 9)).opacity(0.8)
        }
        .frame(width: 66, height: 60)
        .foregroundStyle(on ? Color.black : Color.primary.opacity(0.7))
        .background(RoundedRectangle(cornerRadius: 10).fill(on ? accent : Color.primary.opacity(0.07)))
        .animation(.easeOut(duration: 0.1), value: on)
    }

    // MARK: 紀錄

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("紀錄").font(.headline)
            List(model.history) { r in
                HStack {
                    Text(r.combo)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .frame(width: 90, alignment: .leading)
                        .lineLimit(1)
                    Text(r.comboName).lineLimit(1)
                    Spacer()
                    Text(r.action).foregroundStyle(.secondary).font(.caption)
                    Text(r.keyCode.map { "#\($0)" } ?? "")
                        .foregroundStyle(.secondary).font(.caption.monospaced())
                        .frame(width: 40, alignment: .trailing)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    // MARK: 符號對照表

    private var legend: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mac 按鍵符號").font(.headline).padding(.bottom, 4)
            ForEach(KeyNames.legend, id: \.0) { sym, name in
                HStack(spacing: 10) {
                    Text(sym)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(width: 62, height: 22)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.08)))
                    Text(name).font(.system(size: 13))
                    Spacer()
                }
            }
            Text("⌘Q 結束；⌘Tab、⌘Space 等系統快捷鍵會先被 macOS 攔截，無法偵測。")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
        .padding(16)
        }
    }
}
