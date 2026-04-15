import SwiftUI
import UniformTypeIdentifiers

struct PageView: View {
    @EnvironmentObject var store: NotesStore   // ✅ THIS WAS MISSING
    let folderID: UUID
    let notebookID: UUID

    @State private var selectedPageID: UUID?
    @State private var selectedTool: AnnotationTool = .pen
    @State private var selectedColorHex: String = "111111"
    @State private var lineWidth: CGFloat = 4
    @State private var currentPDFPageIndex: Int = 0
    @State private var showingPDFImporter = false
    @State private var showingPageSettings = false
    @State private var importErrorMessage = ""
    @State private var showImportError = false
    @State private var showingExportAlert = false
    @State private var exportAlertMessage = ""

    private let quickColors: [(String, String)] = [
        ("Black", "111111"), ("Blue", "2563EB"), ("Red", "DC2626"),
        ("Green", "15803D"), ("Purple", "7C3AED"), ("Orange", "EA580C")
    ]

    var body: some View {
        if let notebook = store.notebook(folderID: folderID, notebookID: notebookID) {
            ZStack {
                VStack(spacing: 0) {
                    // Top Toolbar
                    HStack {
                        Button(action: {}) { Image(systemName: "arrow.uturn.backward") }
                            .disabled(true)
                        Button(action: {}) { Image(systemName: "arrow.uturn.forward") }
                            .disabled(true)

                        Divider().frame(height: 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AnnotationTool.allCases) { tool in
                                    Button {
                                        selectedTool = tool
                                    } label: {
                                        Image(systemName: tool.systemImage)
                                            .padding(8)
                                            .background(selectedTool == tool ? Color.blue : Color.clear)
                                            .foregroundColor(selectedTool == tool ? .white : .primary)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }

                        Divider().frame(height: 20)

                        HStack(spacing: 4) {
                            ForEach(quickColors, id: \.1) { _, hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColorHex == hex ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture { selectedColorHex = hex }
                            }
                        }

                        Spacer()

                        Menu {
                            Button("Add Blank Page") { addPage(style: .blank) }
                            Button("Add Ruled Page") { addPage(style: .ruled) }
                            Button("Add Grid Page") { addPage(style: .grid) }
                            Divider()
                            Button("Import PDF") { showingPDFImporter = true }
                            Button("Export PDF") { exportPDF() }
                            Divider()
                            Button("Page Settings") { showingPageSettings = true }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))

                    if notebook.pages.isEmpty {
                        ContentUnavailableView("No Pages", systemImage: "doc")
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
                                    lineWidth: lineWidth,
                                    pdfPageIndex: currentPDFPageIndex
                                )
                                .tag(Optional(page.id))
                                .padding()
                                .background(Color(hex: page.pageColorHex))
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .overlay(alignment: .bottom) {
                            thumbnailStrip(notebook: notebook)
                        }
                    }
                }

                if notebook.pages.isEmpty {
                    VStack {
                        Spacer()
                        Menu {
                            Button("Blank Page") { addPage(style: .blank) }
                            Button("Ruled Page") { addPage(style: .ruled) }
                            Button("Grid Page") { addPage(style: .grid) }
                            Button("Import PDF") { showingPDFImporter = true }
                        } label: {
                            Label("Add Page", systemImage: "plus")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .shadow(radius: 5)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(notebook.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
            .sheet(isPresented: $showingPageSettings) {
                if let pageID = selectedPageID,
                   let page = store.page(folderID: folderID, notebookID: notebookID, pageID: pageID) {
                    PageSettingsSheet(
                        page: page,
                        onUpdateStyle: { style in
                            store.setPageStyle(folderID: folderID, notebookID: notebookID, pageID: pageID, style: style)
                        },
                        onUpdateColor: { hex in
                            store.setPageColor(folderID: folderID, notebookID: notebookID, pageID: pageID, hex: hex)
                        }
                    )
                }
            }
            .fileImporter(isPresented: $showingPDFImporter, allowedContentTypes: [.pdf]) { result in
                switch result {
                case .success(let url):
                    if let fileName = DataManager.shared.importPDF(from: url) {
                        store.addPage(folderID: folderID, notebookID: notebookID, style: .blank, pdfFileName: fileName)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let notebook = store.notebook(folderID: folderID, notebookID: notebookID),
                               let lastPage = notebook.pages.last {
                                selectedPageID = lastPage.id
                            }
                        }
                    } else {
                        importErrorMessage = "Could not import PDF."
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
            .alert("Export", isPresented: $showingExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportAlertMessage)
            }
        } else {
            ContentUnavailableView("Notebook Not Found", systemImage: "book.closed")
        }
    }

    @ViewBuilder
    private func thumbnailStrip(notebook: Notebook) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(notebook.pages) { page in
                    thumbnailView(for: page)
                        .onTapGesture {
                            selectedPageID = page.id
                        }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func thumbnailView(for page: NotePage) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: page.pageColorHex))
                .frame(width: 60, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectedPageID == page.id ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                )

            if page.pdfFileName != nil {
                Image(systemName: "doc.richtext")
                    .font(.title2)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: page.style == .blank ? "doc" : "doc.text")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func addPage(style: PageStyle) {
        store.addPage(folderID: folderID, notebookID: notebookID, style: style)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let notebook = store.notebook(folderID: folderID, notebookID: notebookID),
               let lastPage = notebook.pages.last {
                selectedPageID = lastPage.id
            }
        }
    }

    private func clearCurrentPage() {
        guard let pageID = selectedPageID else { return }
        store.setPageDrawing(folderID: folderID, notebookID: notebookID, pageID: pageID, data: nil)
    }

    func exportPDF() {
        guard let pageID = selectedPageID,
              let page = store.page(folderID: folderID, notebookID: notebookID, pageID: pageID) else {
            exportAlertMessage = "No page selected."
            showingExportAlert = true
            return
        }

        guard let pdfName = page.pdfFileName else {
            exportAlertMessage = "This page is not a PDF. Only imported PDFs can be exported with annotations."
            showingExportAlert = true
            return
        }

        let url = DataManager.shared.pdfURL(for: pdfName)
        guard let outputURL = DataManager.shared.exportAnnotatedPDF(
            originalURL: url,
            drawingsPerPage: page.drawingPerPDFPage
        ) else {
            exportAlertMessage = "Failed to create annotated PDF."
            showingExportAlert = true
            return
        }

        sharePDF(url: outputURL)
    }

    func sharePDF(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = root.view
                popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            root.present(activityVC, animated: true)
        }
    }
}
