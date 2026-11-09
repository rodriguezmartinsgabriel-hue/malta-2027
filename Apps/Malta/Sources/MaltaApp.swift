import SwiftUI
import MaltaKit

@main
struct MaltaApp: App {
    @State private var store = MaltaStore()

    init() {
        Fonts.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(Theme.wineBright)
        }
    }
}

/// The six destinations of the app.
enum TripTab: String, CaseIterable, Identifiable {
    case inicio, dinheiro, orcamento, roteiro, checklist, links

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inicio: return "Inicio"
        case .dinheiro: return "Dinheiro"
        case .orcamento: return "Orcamento"
        case .roteiro: return "Roteiro"
        case .checklist: return "Checklist"
        case .links: return "Links"
        }
    }

    var icon: String {
        switch self {
        case .inicio: return "house"
        case .dinheiro: return "eurosign"
        case .orcamento: return "banknote"
        case .roteiro: return "map"
        case .checklist: return "checklist"
        case .links: return "link"
        }
    }
}

/// Root: one stack per destination kept alive (drafts + scroll survive tab
/// switches), a single liquid backdrop behind everything and a floating
/// glass dock replacing the system bar (UIKit collapses > 5 items).
struct RootView: View {
    @Environment(MaltaStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: TripTab = .inicio

    var body: some View {
        ZStack {
            ScreenBackdrop()
            pane(.inicio) { HomeView() }
            pane(.dinheiro) { MoneyView() }
            pane(.orcamento) { BudgetView() }
            pane(.roteiro) { ItineraryView() }
            pane(.checklist) { ChecklistView() }
            pane(.links) { LinksView() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MaltaDock(tab: $tab)
        }
        .sensoryFeedback(.selection, trigger: tab)
        .onAppear {
            if let raw = ProcessInfo.processInfo.environment["MALTA_TAB"],
               let forced = TripTab(rawValue: raw) {
                tab = forced
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                if store.isSyncConfigured { await store.syncNow() }
                await store.refreshLiveFX()
            }
        }
        .task {
            if store.isSyncConfigured { await store.syncNow() }
            await store.refreshLiveFX()
        }
    }

    @ViewBuilder
    private func pane(_ t: TripTab, @ViewBuilder content: () -> some View) -> some View {
        content()
            .opacity(tab == t ? 1 : 0)
            .allowsHitTesting(tab == t)
    }
}

/// Floating glass dock, iOS 26 style: capsule island, glow pill on the
/// active destination.
struct MaltaDock: View {
    @Binding var tab: TripTab

    var body: some View {
        HStack(spacing: 2) {
            ForEach(TripTab.allCases) { t in
                dockButton(t)
            }
        }
        .padding(6)
        .glass(corner: 30)
        .padding(.horizontal, 14)
        .padding(.bottom, 2)
    }

    private func dockButton(_ t: TripTab) -> some View {
        let active = tab == t
        return Button {
            guard tab != t else { return }
            withAnimation(.snappy(duration: 0.28)) { tab = t }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: t.icon)
                    .font(.system(size: 18, weight: active ? .semibold : .medium))
                    .scaleEffect(active ? 1.08 : 1)
                Text(t.title)
                    .font(.system(size: 9.5, weight: active ? .semibold : .regular))
            }
            .foregroundStyle(active ? Theme.ink : Theme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background {
                if active {
                    Capsule()
                        .fill(Theme.wineFill)
                        .overlay {
                            Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1)
                        }
                        .shadow(color: Theme.wine.opacity(0.55), radius: 8, y: 3)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
