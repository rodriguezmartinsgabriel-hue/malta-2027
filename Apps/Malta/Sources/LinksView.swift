import SwiftUI
import MaltaKit
import UIKit

/// Aba Links: nos de emergencia e links uteis, em linhas nativas.
struct LinksView: View {
    var body: some View {
        NavigationStack {
            List {
                usefulSection
                emergencySection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Links")
        }
    }

    private var usefulSection: some View {
        Section("Uteis") {
            ForEach(usefulLinks) { link in
                Button {
                    if let url = URL(string: link.url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(link.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Text(link.subtitle)
                                .font(.caption2)
                                .foregroundStyle(Theme.muted)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Theme.wine)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .listRowBackground(Theme.paper)
    }

    private var emergencySection: some View {
        Section {
            Button {
                if let url = URL(string: "tel://112") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text("112")
                        .font(Fonts.display(28))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("Numero unico de emergencia na UE")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.trailing)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Emergencia")
        } footer: {
            Note("Consulado do Itamaraty acreditado em Malta fica em Roma - confirmar antes da viagem. Guarde copia digital dos passaportes.")
        }
        .listRowBackground(Theme.paper)
    }
}
