import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showDrawing = false
    @State private var draft: Note
    let onSave: (Note) -> Void

    init(note: Note?, onSave: @escaping (Note) -> Void) {
        _draft = State(initialValue: note ?? Note())
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.indigo.opacity(0.18),
                        Color.purple.opacity(0.12),
                        Color.blue.opacity(0.10),
                        Color.white.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                

                ScrollView {
                    VStack(spacing: 16) {
                        Button {
                            showDrawing = true
                        } label: {
                            Label("Draw", systemImage: "pencil.tip")
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        card {
                            TextField("Title", text: $draft.title)
                                .font(.title2.weight(.semibold))
                                .textInputAutocapitalization(.sentences)
                                .disableAutocorrection(true)
                        }

                        card {
                            TextEditor(text: $draft.content)
                                .frame(minHeight: 280)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                        }

                        card {
                            Toggle("Pinned", isOn: $draft.isPinned)
                                .font(.body.weight(.medium))
                        }

                        card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Color")
                                    .font(.headline)

                                HStack(spacing: 12) {
                                    ForEach(0..<NoteTheme.colors.count, id: \.self) { index in
                                        Button {
                                            draft.colorIndex = index
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(NoteTheme.colors[index])
                                                    .frame(width: 34, height: 34)

                                                if draft.colorIndex == index {
                                                    Image(systemName: "checkmark")
                                                        .font(.caption.bold())
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .sheet(isPresented: $showDrawing) {
                    DrawingView(
                        drawingData: Binding<Data>(
                            get: { draft.drawingData },
                            set: { newValue in
                                draft.drawingData = newValue
                            }
                        )
                    )
                }
            }
            
            .navigationTitle(draft.title.isBlank && draft.content.isBlank ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(draft.title.isBlank && draft.content.isBlank)
                }
            }
        }
    }

    private func saveNote() {
        draft.title = draft.title.trimmedText
        draft.content = draft.content.trimmedText
        draft.updatedAt = Date()

        onSave(draft)
        dismiss()
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

enum NoteTheme {
    static let colors: [Color] = [
        Color.blue.opacity(0.22),
        Color.purple.opacity(0.22),
        Color.green.opacity(0.22),
        Color.orange.opacity(0.22),
        Color.pink.opacity(0.22),
        Color.gray.opacity(0.22)
    ]

    static func color(for index: Int) -> Color {
        guard colors.indices.contains(index) else { return colors[0] }
        return colors[index]
    }
}
    

