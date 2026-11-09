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
                .tint(Theme.wine)
                .background(Theme.bg)
        }
    }
}

/// The six destinations of the app. Tab order mirrors the PWA.
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

/// Root: one NavigationStack per destination, kept alive so drafts and scroll
/// state survive tab switches. A system-styled translucent bar hosts the six
/// destinations (UIKit collapses > 5 items into a "More" menu, so the bar is
/// hand built to look exactly like the system one).
struct RootView: View {
    @Environment(MaltaStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: TripTab = .inicio

    var body: some View {
        ZStack {
            pane(.inicio) { HomeView() }
            pane(.dinheiro) { MoneyView() }
            pane(.orcamento) { BudgetView() }
            pane(.roteiro) { ItineraryView() }
            pane(.checklist) { ChecklistView() }
            pane(.links) { LinksView() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MaltaTabBar(tab: $tab)
        }
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

/// Bottom bar styled like the system one: translucent material, hairline top,
/// filled glyph when selected. Glass sits here and only here, like iOS.
struct MaltaTabBar: View {
    @Binding var tab: TripTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TripTab.allCases) { t in
                Button {
                    guard tab != t else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { tab = t }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.icon)
                            .font(.system(size: 17, weight: tab == t ? .semibold : .regular))
                        Text(t.title).font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(tab == t ? Theme.wine : Theme.muted)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.line.opacity(0.6)).frame(height: 0.5)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
