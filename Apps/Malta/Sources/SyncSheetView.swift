import SwiftUI
import MaltaKit
import UIKit

/// Sheet de sync em vidro: estado, Supabase (URL + anon key), acoes e ajuda.
struct SyncSheetView: View {
    @Environment(MaltaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var url = ""
    @State private var key = ""
    @State private var trip = ""
    @State private var seeded = false
    @State private var busy = false

    var body: some View {
        ZStack {
            ScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    statusCard
                    configCard
                    actionCard
                    helpCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            guard !seeded else { return }
            seeded = true
            url = store.remoteURL
            key = store.remoteKey
            trip = store.tripID
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Sync")
                .font(Fonts.display(36))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .padding(10)
                    .background(Circle().fill(Theme.softStrong))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar")
        }
    }

    private var statusCard: some View {
        VStack(spacing: 10) {
            statusRow(label: "Modo", value: {
                let t = trip.trimmingCharacters(in: .whitespaces)
                return t.isEmpty ? "Local (sem sync)" : t
            }(), accent: false)
            statusRow(label: "Sync", value: store.syncStatus.label,
                      accent: isSynced(store.syncStatus))
            statusRow(label: "Cotacao",
                      value: Money.brNumber(store.fx) +
                          (store.fxSourceIsLive ? " (ao vivo)" : " (manual)"),
                      accent: store.fxSourceIsLive)
        }
        .padding(16)
        .glass()
    }

    private var configCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScreenLabel(text: "Supabase").padding(.top, 0)
            glassField("URL (https://xxxx.supabase.co)", text: $url)
            glassField("Anon key", text: $key, secure: true)
            glassField("Trip id (ex.: nana-dani)", text: $trip)
        }
        .padding(16)
        .glass()
    }

    private var actionCard: some View {
        VStack(spacing: 10) {
            Button {
                saveConfig()
            } label: {
                Text("Salvar e conectar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Theme.wineFill))
                    .shadow(color: Theme.wine.opacity(0.45), radius: 10, y: 4)
            }
            .buttonStyle(.plain)

            Button {
                guard !busy else { return }
                busy = true
                Task {
                    if trip.isEmpty { store.tripID = "nana-dani" }
                    await store.syncNow()
                    await store.pushAll()
                    busy = false
                }
            } label: {
                HStack {
                    if busy { ProgressView().padding(.trailing, 6) }
                    Text(busy ? "Sincronizando..." : "Sincronizar agora")
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Capsule().fill(Theme.soft))
            }
            .buttonStyle(.plain)
            .disabled(busy)

            Button(role: .destructive, action: resetConfig) {
                Text("Limpar")
                    .font(.subheadline)
                    .foregroundStyle(Theme.wineBright)
            }
            .buttonStyle(.plain)
        }
    }

    private var helpCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenLabel(text: "Como ativar").padding(.top, 0)
            helpRow("1", "No Supabase (gratis), rode research/supabase/schema.sql no SQL Editor.")
            helpRow("2", "Copiar Project URL e anon public key de Settings > API e colar acima.")
            helpRow("3", "O mesmo trip id nas duas: gastos, roteiro e checklist ficam iguais nos dois aparelhos.")
            Text("Sem configuracao o app funciona 100% local.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .padding(.leading, 2)
        }
        .padding(16)
        .glass()
    }

    // MARK: - Pieces

    private func isSynced(_ s: MaltaStore.SyncStatus) -> Bool {
        if case .synced = s { return true }
        return false
    }

    private func statusRow(label: String, value: String, accent: Bool) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.muted)
            Spacer()
            Text(value)
                .font(Fonts.mono(13))
                .foregroundStyle(accent ? Theme.oliveBright : Theme.muted)
        }
    }

    private func glassField(_ placeholder: String, text: Binding<String>, secure: Bool = false) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .font(.footnote)
        .foregroundStyle(Theme.ink)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .keyboardType(.URL)
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.soft)
        }
    }

    private func helpRow(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Theme.oliveBright)
                .padding(.top, 2)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func saveConfig() -> Void {
        let t = trip.trimmingCharacters(in: .whitespaces)
        store.saveSyncConfig(
            url: url.trimmingCharacters(in: .whitespaces),
            key: key.trimmingCharacters(in: .whitespaces),
            trip: t.isEmpty ? "nana-dani" : t)
        Task { await store.pushAll() }
        dismiss()
    }

    private func resetConfig() {
        url = ""
        key = ""
        trip = ""
        store.saveSyncConfig(url: "", key: "", trip: "")
    }
}
