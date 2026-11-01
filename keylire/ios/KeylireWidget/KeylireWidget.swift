// KeylireWidget — WidgetKit target (iOS 17+). Add via Xcode: File > New >
// Target > Widget Extension, name "KeylireWidget", enable App Groups
// "group.com.keylire.app" on both app and extension.
//
// Interactive buttons (AppIntent) work in-widget for Bed / Up / chips /
// ghosts: they write the intent into the shared UserDefaults and the app
// processes it on next launch OR, if you add a small SQLite writer here,
// immediately. Text / voice / camera cannot be captured inside an iOS
// widget; they deep-link into the app with that door already open
// (keylire://open/text, keylire://open/mic, keylire://open/camera).

import AppIntents
import SwiftUI
import WidgetKit

private let group = "group.com.keylire.app"

struct Ink {
    static let paper = Color(light: 0xF1F1EE, dark: 0x111214)
    static let elevated = Color(light: 0xE9E9E5, dark: 0x212226)
    static let ink = Color(light: 0x1C1C1E, dark: 0xE9E9E4)
    static let soft = Color(light: 0x5C5C60, dark: 0x9C9C98)
    static let line = Color(light: 0xDCDCD7, dark: 0x2A2B30)
    static let night = Color(light: 0x4B5B85, dark: 0x7C8BB5)
    static let dawn = Color(light: 0xB98A2E, dark: 0xD4A64A)
}

extension Color {
    init(light: UInt, dark: UInt) {
        self.init(UIColor { t in
            let h = t.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255, alpha: 1)
        })
    }
}

struct Chip: Codable, Identifiable {
    var id: Int? ; var name: String; var ghostId: Int?; var at: String?
    var key: String { "\(id ?? 0)-\(ghostId ?? 0)-\(name)" }
}

struct Entry: TimelineEntry {
    let date: Date
    let count: Int
    let lastLine: String
    let lastTime: String
    let chips: [Chip]
}

struct Provider: TimelineProvider {
    func placeholder(in: Context) -> Entry { Entry(date: .now, count: 0, lastLine: "", lastTime: "", chips: []) }
    func getSnapshot(in: Context, completion: @escaping (Entry) -> Void) { completion(read()) }
    func getTimeline(in: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [read()], policy: .after(.now.addingTimeInterval(1800))))
    }
    func read() -> Entry {
        let d = UserDefaults(suiteName: group)
        let chips = (try? JSONDecoder().decode([Chip].self, from: Data((d?.string(forKey: "kv_chips") ?? "[]").utf8))) ?? []
        return Entry(date: .now, count: d?.integer(forKey: "kv_count") ?? 0,
                     lastLine: d?.string(forKey: "kv_last_line") ?? "",
                     lastTime: d?.string(forKey: "kv_last_time") ?? "", chips: chips)
    }
}

/// In-widget action. Writes a queue entry the app drains on launch
/// (HomeWidget.initiallyLaunchedFromHomeWidget / widgetClicked won't fire
/// for AppIntents, so poll `kv_pending` in main.dart). Replace with a
/// direct SQLite write to the shared DB for instant behaviour.
struct LogKeyIntent: AppIntent {
    static var title: LocalizedStringResource = "Log"
    @Parameter(title: "uri") var uri: String
    init() {}
    init(uri: String) { self.uri = uri }
    func perform() async throws -> some IntentResult {
        let d = UserDefaults(suiteName: group)
        var q = d?.stringArray(forKey: "kv_pending") ?? []
        q.append(uri)
        d?.set(q, forKey: "kv_pending")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct KeylireWidgetView: View {
    let e: Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.count == 0 ? "Today" : "Today · \(e.count) \(e.count == 1 ? "entry" : "entries")")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Ink.soft)
                    Text(e.lastLine.isEmpty ? "Nothing yet — tap Up" : "\(e.lastTime)  \(e.lastLine)")
                        .font(.system(size: 15)).foregroundStyle(Ink.ink).lineLimit(1)
                }
                Spacer()
                Text(e.date, style: .time).font(.system(size: 12, design: .monospaced)).foregroundStyle(Ink.soft)
            }
            HStack(spacing: 6) {
                pill("Bed", dot: Ink.night, uri: "keylire://widget/bed")
                pill("Up", dot: Ink.dawn, uri: "keylire://widget/up")
                Rectangle().fill(Ink.line).frame(width: 1, height: 16)
                ForEach(e.chips.prefix(3), id: \.key) { c in
                    if let g = c.ghostId {
                        pill("○ \(c.name) \(c.at ?? "")", dot: nil, uri: "keylire://widget/ghost?id=\(g)", ghost: true)
                    } else {
                        pill(c.name, dot: nil, uri: "keylire://widget/chip?id=\(c.id ?? 0)&name=\(c.name)")
                    }
                }
            }
            HStack(spacing: 4) {
                Link(destination: URL(string: "keylire://open/camera")!) { Image(systemName: "camera").padding(8) }
                Link(destination: URL(string: "keylire://open/mic")!) { Image(systemName: "mic").padding(8) }
                Link(destination: URL(string: "keylire://open/text")!) {
                    Text("Log one line…").font(.system(size: 15)).foregroundStyle(Ink.soft)
                    Spacer()
                }
            }
            .foregroundStyle(Ink.soft)
            .frame(height: 40)
            .background(RoundedRectangle(cornerRadius: 12).stroke(Ink.line))
        }
        .padding(14)
        .containerBackground(Ink.paper, for: .widget)
    }

    func pill(_ t: String, dot: Color?, uri: String, ghost: Bool = false) -> some View {
        Button(intent: LogKeyIntent(uri: uri)) {
            HStack(spacing: 6) {
                if let d = dot { Circle().fill(d).frame(width: 7, height: 7) }
                Text(t).font(.system(size: 13, weight: .medium)).foregroundStyle(Ink.ink).lineLimit(1)
            }
            .padding(.horizontal, 11).frame(height: 30)
            .background(ghost ? AnyView(Capsule().stroke(Ink.soft, style: StrokeStyle(lineWidth: 1, dash: [3, 2])))
                              : AnyView(Capsule().fill(Ink.elevated)))
        }
        .buttonStyle(.plain)
    }
}

@main
struct KeylireWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "KeylireWidget", provider: Provider()) { KeylireWidgetView(e: $0) }
            .configurationDisplayName("Keylire")
            .description("One line, a photo, or a voice note.")
            .supportedFamilies([.systemMedium])
            .contentMarginsDisabled()
    }
}
