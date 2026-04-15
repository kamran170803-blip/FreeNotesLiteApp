import SwiftUI
import UniformTypeIdentifiers

struct PageView: View {
    @EnvironmentObject var store: NotesStore
    let folderID: UUID
    let notebookID: UUID

    @State private var selectedPageID: UUID?
    @State private var selectedTool: AnnotationTool = .pen
    @State private var selectedColorHex: String = "111111"
    @State private var lineWidth: CGFloat = 4

    @State private var showingPDFImporter = false
    @State private var importErrorMessage = ""
    @State private var showImportError = false

    private let quickColors: [(name: String, hex: String)] = [
        ("Ink", "111111"),
        ("Blue", "2563EB"),
        ("Red", "DC2626"),
        ("Green", "15803D"),
        ("Purple", "7C3AED"),
        ("Orange", "EA580C")
    ]

    var body: some View {
        if let notebook = store.notebook(folderID: folderID, notebookID: notebookID) {
            VStack(spacing: 0) {
                premiumHero(notebook: notebook)
                toolStrip

                if notebook.pages.isEmpty {
                    ContentUnavailableView(
                        "No Pages Yet",
                        systemImage: "doc",
                        description: Text("Use the + button to add a blank page, ruled page, or PDF.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TabView(selection: $selectedPageID) {
                        ForEach(notebook.pages) { page in
                            PageContentView(
                                folderID: folderID,
                                notebookID: notebookID,
                                page: page,
                                selectedTool: selectedTool,
                                selectedColorHex: selectedColorHex,
                                lineWidth: lineWidth
                            )
                            .tag(Optional(page.id))
                            .padding()
                            .background(Color(hex: page.pageColorHex))
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .overlay(alignment: .bottomTrailing) {
                        if selectedPageID != nil {
                            Button {
                                clearCurrentPage()
                            } label: {
                                Label("Clear", systemImage: "trash")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(notebook.title)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Blank Page") { addPage(style: .blank) }
                        Button("Ruled Page") { addPage(style: .ruled) }
                        Button("Double Ruled Page") { addPage(style: .doubleRuled) }
                        Button("Grid Page") { addPage(style: .grid) }
                        Button {
                            exportPDF()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Button("Import PDF") { showingPDFImporter = true }
                    } label: {
                        Image(systemName: "plus")
                    }

                    NavigationLink {
                        CompareSplitView(folderID: folderID, notebookID: notebookID)
                    } label: {
                        Image(systemName: "square.split.2x1")
                    }
                }
            }
            .onAppear {
                if selectedPageID == nil {
                    selectedPageID = notebook.pages.first?.id
                }
            }
            .fileImporter(
                isPresented: $showingPDFImporter,
                allowedContentTypes: [.pdf]
            ) { result in
                switch result {
                case .success(let url):
                    if let fileName = DataManager.shared.importPDF(from: url) {
                        store.addPage(folderID: folderID, notebookID: notebookID, style: .blank, pdfFileName: fileName)
                        selectedPageID = store.notebook(folderID: folderID, notebookID: notebookID)?.pages.last?.id
                    } else {
                        importErrorMessage = "Could not import this PDF."
                        showImportError = true
                    }
                case .failure(let error):
                    importErrorMessage = error.localizedDescription
                    showImportError = true
                }
            }
            .alert("Import Error", isPresented: $showImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage)
            }
        } else {
            ContentUnavailableView("Notebook Not Found", systemImage: "book.closed")
        }
    }
    func exportPDF() {
        guard let pageID = selectedPageID,
              let page = store.page(folderID: folderID, notebookID: notebookID, pageID: pageID),
              let pdfName = page.pdfFileName else { return }

        let url = DataManager.shared.pdfURL(for: pdfName)

        if let outputURL = DataManager.shared.exportAnnotatedPDF(
            originalURL: url,
            drawingData: page.drawingData
        ) {
            sharePDF(url: outputURL)
        }
    }
    func sharePDF(url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }

    private var toolStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AnnotationTool.allCases) { tool in
                    Button {
                        selectedTool = tool
                    } label: {
                        Label(tool.title, systemImage: tool.systemImage)
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .foregroundStyle(selectedTool == tool ? .white : .primary)
                            .background(selectedTool == tool ? Color.blue : Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Menu {
                    Button("Thin") { lineWidth = 2 }
                    Button("Medium") { lineWidth = 4 }
                    Button("Bold") { lineWidth = 8 }
                } label: {
                    Label("Width \(Int(lineWidth))", systemImage: "lineweight")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }

                ForEach(quickColors, id: \.hex) { item in
                    Button {
                        selectedColorHex = item.hex
                    } label: {
                        Circle()
                            .fill(Color(hex: item.hex))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .stroke(selectedColorHex == item.hex ? Color.primary : Color.clear, lineWidth: 2)
                            )
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.name)
                }

                Button {
                    clearCurrentPage()
                } label: {
                    Label("Clear", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(selectedPageID == nil)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    private func premiumHero(notebook: Notebook) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.18),
                        Color.purple.opacity(0.12),
                        Color.orange.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 120)
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notebook")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(notebook.title)
                        .font(.title2.weight(.bold))
                    Text("\(notebook.pages.count) pages")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .padding([.horizontal, .top])
    }

    private func addPage(style: PageStyle) {
        store.addPage(folderID: folderID, notebookID: notebookID, style: style)
        selectedPageID = store.notebook(folderID: folderID, notebookID: notebookID)?.pages.last?.id
    }

    private func clearCurrentPage() {
        guard let pageID = selectedPageID else { return }
        store.setPageDrawing(folderID: folderID, notebookID: notebookID, pageID: pageID, data: nil)
    }
}
