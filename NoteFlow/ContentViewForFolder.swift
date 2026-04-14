import SwiftUI

struct ContentViewForFolder: View {
    @ObservedObject var vm: NotesViewModel
    let folder: Folder

    @State private var showingEditor = false
    @State private var editingNote: Note?

    private var notes: [Note] {
        vm.notes.filter { $0.folderID == folder.id }
    }

    // ✅ FIXED GRID
    let columns = [
        GridItem(.adaptive(minimum: 160))
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.gray.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    if notes.isEmpty {
                        emptyView
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {

                            // Create card
                            createCard

                            // Notes
                            ForEach(notes) { note in
                                noteCard(note)
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                }

                // Floating button (optional, you can keep or remove)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            editingNote = nil
                            showingEditor = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 64, height: 64)
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(folder.name)
            .sheet(isPresented: $showingEditor) {
                NoteEditorView(note: editingNote) { note in
                    var updatedNote = note
                    updatedNote.folderID = folder.id
                    vm.addOrUpdate(updatedNote)
                }
            }
        }
    }

    // MARK: - Create Card

    private var createCard: some View {
        Button {
            editingNote = nil
            showingEditor = true
        } label: {
            VStack {
                Spacer()

                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .clipShape(Circle())

                Text("Create")
                    .foregroundStyle(.white)
                    .padding(.top, 6)

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.3))
            )
        }
    }

    // MARK: - Note Card

    private func noteCard(_ note: Note) -> some View {
        Button {
            withAnimation {
                editingNote = note
                showingEditor = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Text(note.displayTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.white)
                    }
                }

                Text(note.previewText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(3)

                Spacer()

                Text(note.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2))
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                vm.togglePin(note)
            } label: {
                Label("Pin", systemImage: "pin")
            }

            Button(role: .destructive) {
                vm.delete(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 14) {
            Image(systemName: "note.text")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.white.opacity(0.6))

            Text("No notes yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text("Tap + to create your first note")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 100)
    }
}
