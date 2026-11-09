import SwiftUI
import MaltaKit
import UIKit

/// Aba Links: uteis em cartoes de vidro + emergencia com numero 112 grande.
struct LinksView: View {
    var body: some View {
        NavigationStack {
            MaltaScreen(title: "Links") {
                usefulCard
                emergencyCard
                footerNote
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var usefulCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenLabel(text: "Uteis")
            VStack(spacing: 0) {
                ForEach(usefulLinks) { link in
                    Button {
                        if let url = URL(string: link.url) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 12) {
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
                                .foregroundStyle(Theme.wineBright)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    if link.id != usefulLinks.last?.id {
                        Rectangle().fill(.white.opacity(0.08)).frame(height: 0.5)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glass()
        }
    }

    private var emergencyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenLabel(text: "Emergencia")
            Button {
                if let url = URL(string: "tel://112") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(alignment: .center) {
                    Text("112")
                        .font(Fonts.display(44))
                        .foregroundStyle(Theme.cream)
                        .shadow(color: Theme.wine.opacity(0.5), radius: 12, y: 2)
                    Spacer()
                    Text("Numero unico de emergencia na UE")
                        .font(.footnote)
                        .foregroundStyle(Theme.cream.opacity(0.8))
                        .multilineTextAlignment(.trailing)
                }
                .padding(18)
                .background {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Theme.wineFill)
                        .overlay {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                        }
                        .shadow(color: Theme.wine.opacity(0.55), radius: 24, y: 12)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var footerNote: some View {
        Text("Consulado do Itamaraty acreditado em Malta fica em Roma - confirmar antes da viagem. Guarde copia digital dos passaportes.")
            .font(.footnote)
            .foregroundStyle(Theme.muted)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 6)
    }
}
