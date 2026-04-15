import SwiftUI

struct NotebookCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onConfirm: (String, NotebookCover, PageStyle) -> Void

    @State private var title = ""
    @State private var selectedCover: NotebookCover = .none
    @State private var selectedTemplate: PageStyle = .blank
    @State private var paperColorHex = "FFFDF7"
    @State private var lineColorHex = "000000"

    private let quickColors: [(String, String)] = [
        ("White", "FFFDF7"), ("Cream", "FFF8E7"), ("Gray", "F0F0F0"),
        ("Blue", "E6F0FF"), ("Green", "E6FFE6"), ("Pink", "FFE6F0")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Notebook Title") {
                    TextField("Title", text: $title)
                }

                Section("Cover") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(NotebookCover.allCases) { cover in
                                VStack {
                                    Image(systemName: cover.imageName)
                                        .font(.largeTitle)
                                        .frame(width: 60, height: 80)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.15))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedCover == cover ? Color.blue : Color.clear, lineWidth: 3)
                                        )
                                    Text(cover.displayName)
                                        .font(.caption)
                                }
                                .onTapGesture {
                                    selectedCover = cover
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Paper Template") {
                    Picker("Template", selection: $selectedTemplate) {
                        ForEach(PageStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Paper Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(quickColors, id: \.1) { name, hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(paperColorHex == hex ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                )
                                .onTapGesture {
                                    paperColorHex = hex
                                }
                        }
                    }
                }
            }
            .navigationTitle("New Notebook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onConfirm(trimmed, selectedCover, selectedTemplate)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
