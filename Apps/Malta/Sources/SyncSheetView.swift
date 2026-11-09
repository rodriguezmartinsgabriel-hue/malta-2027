import SwiftUI
import MaltaKit
import UIKit

/// Sheet de configuracao de sync: Supabase (URL + anon key) + trip id + status.
/// Sem projeto configurado o app roda 100% local.
struct SyncSheetView: View {
    @Environment(MaltaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var url = ""
    @State private var key = ""
    @State private var trip = ""
    @State private var seeded = false
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                statusSection
                configSection
                actionSection
                helpSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .onAppear {
                guard !seeded else { return }
                seeded = true
                url = store.remoteURL
                key = store.remoteKey
                trip = store.tripID
            }
        }
    }

    private var statusSection: some View {
        Section("Estado") {
            HStack {
                Text("Modo")
                Spacer()
                Text(statusTitle)
                    .foregroundStyle(Theme.muted)
            }
            HStack {
                Text("Sync")
                Spacer()
                Text(store.syncStatus.label)
                    .font(.footnote)
                    .foregroundStyle(statusColor)
            }
            HStack {
                Text("Cotacao")
                Spacer()
                Text(Money.brNumber(store.fx) + (store.fxSourceIsLive ? " (ao vivo)" : " (manual)"))
                    .foregroundStyle(Theme.muted)
            }
        }
    }

    private var configSection: some View {
        Section("Supabase") {
            TextField("URL (https://xxxx.supabase.co)", text: $url)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.footnote)
            TextField("Anon key", text: $key)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.footnote)
            TextField("Trip id (ex.: nana-dani)", text: $trip)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }

    private var actionSection: some View {
        Section {
            Button("Salvar e conectar") {
                saveConfig()
            }
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
                }
            }
            .disabled(busy)
            Button(role: .destructive, action: resetConfig) {
                Text("Limpar")
            }
        }
    }

    private var helpSection: some View {
        Section {
            Text("1 - No Supabase (gratis): rodar research/supabase/schema.sql no SQL Editor.")
            Text("2 - Copiar Project URL e anon public key de Settings > API e colar acima.")
            Text("3 - O mesmo trip id nas duas: gastos, roteiro e checklist ficam iguais nos dois aparelhos.")
        } header: {
            Text("Como ativar")
        } footer: {
            Note("Sem configuracao o app funciona 100% local.")
        }
        .font(.footnote)
    }

    private var statusTitle: String {
        trip.isEmpty ? "Local (sem sync)" : trip
    }

    private var statusColor: Color {
        switch store.syncStatus {
        case .offline, .syncing: return Theme.muted
        case .synced: return Theme.olive
        case .failed: return Theme.wine
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
