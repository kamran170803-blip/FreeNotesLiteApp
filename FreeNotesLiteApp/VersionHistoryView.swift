import SwiftUI

struct VersionHistoryView: View {
    let page: NotePage
    let onRestore: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if page.versionHistory.isEmpty {
                    ContentUnavailableView("No Versions", systemImage: "clock.arrow.circlepath")
                } else {
                    ForEach(page.versionHistory.sorted(by: { $0.timestamp > $1.timestamp })) { version in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(version.timestamp, style: .date)
                                Text(version.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Restore") {
                                onRestore(version.id)
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("Version History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
