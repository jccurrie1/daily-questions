import SwiftUI

@main
struct DailyQuestionsiOSApp: App {
    @State private var store: DailyStore?
    @State private var startupError: String?

    init() {
        do { _store = State(initialValue: try DailyStore()) }
        catch { _startupError = State(initialValue: error.localizedDescription) }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let store {
                    MobileRootView(store: store)
                } else {
                    ContentUnavailableView {
                        Label("Cannot open local data", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(startupError ?? "The local store could not be opened.")
                    } actions: {
                        Button("Retry") {
                            do { store = try DailyStore(); startupError = nil }
                            catch { startupError = error.localizedDescription }
                        }
                    }
                    .foregroundStyle(.red)
                }
            }
            .tint(Palette.ink)
        }
    }
}

struct MobileRootView: View {
    let store: DailyStore
    @State private var section: MobileSection = .today

    var body: some View {
        TabView(selection: $section) {
            Tab(value: MobileSection.today) {
                TodayView(store: store)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: MobileSection.questions) {
                MobileQuestionsView(store: store)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: MobileSection.analytics) {
                MobileAnalyticsView(store: store)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MobileDock(section: $section)
        }
    }
}

enum MobileSection: CaseIterable {
    case today, questions, analytics

    var title: String {
        switch self {
        case .today: "Today"
        case .questions: "Questions"
        case .analytics: "Analytics"
        }
    }

    var symbol: String {
        switch self {
        case .today: "calendar"
        case .questions: "list.bullet"
        case .analytics: "chart.bar.xaxis"
        }
    }
}

struct MobileDock: View {
    @Binding var section: MobileSection
    @Namespace private var selection

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MobileSection.allCases, id: \.self) { item in
                Button {
                    withAnimation(.snappy(duration: 0.25)) { section = item }
                } label: {
                    Image(systemName: item.symbol)
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(item == section ? Palette.onInk : Palette.ink.opacity(0.6))
                        .background {
                            if item == section {
                                Circle().fill(Palette.ink)
                                    .matchedGeometryEffect(id: "selected", in: selection)
                            }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(item == section ? [.isSelected] : [])
            }
        }
        .padding(6)
        .glassEffect(.regular, in: .capsule)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sections")
    }
}

enum MobileLayout {
    static let cardShape = RoundedRectangle(cornerRadius: 14)
    static let dateFormat = Date.FormatStyle(calendar: LocalDay.calendar(), timeZone: .current)

    static func date(fromKey key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return LocalDay.calendar().date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }
}

extension View {
    func mobileCard() -> some View {
        background(Palette.surface, in: MobileLayout.cardShape)
            .overlay(MobileLayout.cardShape.stroke(Palette.border.opacity(0.7), lineWidth: 1))
    }
}
