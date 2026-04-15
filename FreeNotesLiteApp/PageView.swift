import SwiftUI
import UniformTypeIdentifiers
import PencilKit
import VisionKit
import AVFoundation
import PDFKit   // <-- ADD THIS

struct PageView: View {
    @EnvironmentObject var store: NotesStore
    let folderID: UUID
    let notebookID: UUID

    @State private var selectedPageID: UUID?
    @State private var currentPDFPageIndex: Int = 0
    @State private var pdfTotalPages: Int = 0
    @State private var pdfPageLabel: String = "1 / 1"
    @State private var showingPDFImporter = false
    @State private var showingPageSettings = false
    @State private var importErrorMessage = ""
    @State private var showImportError = false
    @State private var showingExportAlert = false
    @State private var exportAlertMessage = ""
    @State private var showingDocumentScanner = false
    @State private var showingVersionHistory = false
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?

    @State private var toolPicker: PKToolPicker?
    @State private var canvasViewForToolPicker: PKCanvasView?
    @State private var selectedTool: AnnotationTool = .pen
    @State private var selectedColor: UIColor = .black
    @State private var strokeWidth: CGFloat = 5
    
    private let toolPickerObserver = ToolPickerObserver()

    var body: some View {
        if let notebook = store.notebook(folderID: folderID, notebookID: notebookID) {
            ZStack {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {}) { Image(systemName: "arrow.uturn.backward") }
                            .disabled(true)
                        Button(action: {}) { Image(systemName: "arrow.uturn.forward") }
                            .disabled(true)

                        Spacer()

                        Button {
                            toggleRecording()
                        } label: {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle")
                                .font(.title2)
                                .foregroundColor(isRecording ? .red : .primary)
                        }

                        Menu {
                            Section("Page Actions") {
                                Button("Add Blank Page") { addPage(style: .blank) }
                                Button("Add Ruled Page") { addPage(style: .ruled) }
                                Button("Add Grid Page") { addPage(style: .grid) }
                                if let pageID = selectedPageID {
                                    Button("Duplicate Page") { duplicatePage(pageID: pageID) }
                                    Button("Delete Page", role: .destructive) { deletePage(pageID: pageID) }
                                }
                            }
                            Section("Import") {
                                Button("Import PDF") { showingPDFImporter = true }
                                Button("Scan Document") { showingDocumentScanner = true }
                            }
                            Section("Export") {
                                Button("Export as PDF") { exportPDF() }
                            }
                            Section("Settings") {
                                Button("Page Settings") { showingPageSettings = true }
                            }
                            Section("History") {
                                if let pageID = selectedPageID {
                                    Button("Save Current Version") { saveVersion(pageID: pageID) }
                                    Button("View Version History") { showingVersionHistory = true }
                                }
                            }
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
                                    toolPicker: toolPicker,
                                    onCanvasCreated: { canvas in
                                        DispatchQueue.main.async {
                                            activateToolPicker(for: canvas)
                                        }
                                    },
                                    currentPDFPageIndex: $currentPDFPageIndex
                                )
                                .tag(Optional(page.id))
                                .padding()
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .overlay(alignment: .bottom) {
                            bottomOverlay(notebook: notebook)
                        }
                        .onChange(of: selectedPageID) { oldID, newID in
                            if let newID,
                               let page = store.page(folderID: folderID, notebookID: notebookID, pageID: newID) {
                                if page.pdfFileName != nil {
                                    currentPDFPageIndex = 0
                                    updatePDFPageCount(for: page)
                                } else {
                                    pdfTotalPages = 0
                                }
                            }
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
                            Button("Scan Document") { showingDocumentScanner = true }
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
                if let page = notebook.pages.first(where: { $0.id == selectedPageID }) {
                    updatePDFPageCount(for: page)
                }
                setupToolPicker()
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
            .sheet(isPresented: $showingVersionHistory) {
                if let pageID = selectedPageID,
                   let page = store.page(folderID: folderID, notebookID: notebookID, pageID: pageID) {
                    VersionHistoryView(
                        page: page,
                        onRestore: { versionID in
                            store.restoreVersion(folderID: folderID, notebookID: notebookID, pageID: pageID, versionID: versionID)
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
                                updatePDFPageCount(for: lastPage)
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
            .sheet(isPresented: $showingDocumentScanner) {
                DocumentScannerView { scannedImages in
                    handleScannedImages(scannedImages)
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
    private func bottomOverlay(notebook: Notebook) -> some View {
        if let pageID = selectedPageID,
           let page = store.page(folderID: folderID, notebookID: notebookID, pageID: pageID),
           page.pdfFileName != nil {
            HStack {
                Button {
                    currentPDFPageIndex = max(0, currentPDFPageIndex - 1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(currentPDFPageIndex == 0)
                
                Text(pdfPageLabel)
                    .font(.caption)
                    .monospacedDigit()
                    .frame(minWidth: 60)
                
                Button {
                    currentPDFPageIndex = min(pdfTotalPages - 1, currentPDFPageIndex + 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(currentPDFPageIndex >= pdfTotalPages - 1)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.bottom, 8)
        } else {
            thumbnailStrip(notebook: notebook)
        }
    }

    private func setupToolPicker() {
        if toolPicker == nil {
            let picker = PKToolPicker()
            picker.addObserver(toolPickerObserver)
            picker.setVisible(true, forFirstResponder: canvasViewForToolPicker ?? UIView())
            toolPicker = picker
        }
    }

    private func activateToolPicker(for canvas: PKCanvasView) {
        DispatchQueue.main.async {
            canvasViewForToolPicker = canvas
            toolPicker?.setVisible(true, forFirstResponder: canvas)
            canvas.becomeFirstResponder()
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard let pageID = selectedPageID else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documents.appendingPathComponent("\(pageID.uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            store.setPageAudioURL(folderID: folderID, notebookID: notebookID, pageID: pageID, url: audioFilename)
            isRecording = true
        } catch {
            print("Recording failed: \(error)")
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }

    private func updatePDFPageCount(for page: NotePage) {
        guard let pdfName = page.pdfFileName else { return }
        let url = DataManager.shared.pdfURL(for: pdfName)
        DispatchQueue.global(qos: .userInitiated).async {
            if let doc = PDFDocument(url: url) {
                let count = doc.pageCount
                DispatchQueue.main.async {
                    pdfTotalPages = count
                    pdfPageLabel = "\(currentPDFPageIndex + 1) / \(count)"
                }
            }
        }
    }

    private func handleScannedImages(_ images: [UIImage]) {
        guard let pdfData = createPDF(from: images) else { return }
        if let fileName = DataManager.shared.saveScannedPDF(data: pdfData) {
            store.addPage(folderID: folderID, notebookID: notebookID, style: .blank, pdfFileName: fileName)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let notebook = store.notebook(folderID: folderID, notebookID: notebookID),
                   let lastPage = notebook.pages.last {
                    selectedPageID = lastPage.id
                    updatePDFPageCount(for: lastPage)
                }
            }
        }
    }

    private func createPDF(from images: [UIImage]) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = pdfRenderer.pdfData { context in
            for image in images {
                context.beginPage()
                let rect = CGRect(x: 0, y: 0, width: 612, height: 792)
                image.draw(in: rect)
            }
        }
        return data
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

    private func duplicatePage(pageID: UUID) {
        store.duplicatePage(folderID: folderID, notebookID: notebookID, pageID: pageID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let notebook = store.notebook(folderID: folderID, notebookID: notebookID),
               let lastPage = notebook.pages.last {
                selectedPageID = lastPage.id
            }
        }
    }

    private func deletePage(pageID: UUID) {
        store.deletePage(folderID: folderID, notebookID: notebookID, pageID: pageID)
        if let notebook = store.notebook(folderID: folderID, notebookID: notebookID) {
            selectedPageID = notebook.pages.first?.id
        }
    }

    private func saveVersion(pageID: UUID) {
        store.saveVersion(folderID: folderID, notebookID: notebookID, pageID: pageID)
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
        DispatchQueue.global(qos: .userInitiated).async {
            let outputURL = DataManager.shared.exportAnnotatedPDF(
                originalURL: url,
                drawingsPerPage: page.drawingPerPDFPage
            )
            DispatchQueue.main.async {
                if let outputURL = outputURL {
                    sharePDF(url: outputURL)
                } else {
                    exportAlertMessage = "Failed to create annotated PDF."
                    showingExportAlert = true
                }
            }
        }
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

    @ViewBuilder
    private func thumbnailStrip(notebook: Notebook) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(notebook.pages) { page in
                    thumbnailView(for: page)
                        .onTapGesture {
                            selectedPageID = page.id
                        }
                        .contextMenu {
                            Button("Duplicate") { duplicatePage(pageID: page.id) }
                            Button("Delete", role: .destructive) { deletePage(pageID: page.id) }
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

            if let pdfName = page.pdfFileName {
                AsyncPDFThumbnail(url: DataManager.shared.pdfURL(for: pdfName), pageIndex: 0, size: CGSize(width: 60, height: 80))
            } else {
                Image(systemName: page.style == .blank ? "doc" : "doc.text")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            if page.audioURL != nil {
                Image(systemName: "mic.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(4)
                    .background(Circle().fill(.white.opacity(0.8)))
                    .offset(x: 20, y: -25)
            }
        }
    }

    final class ToolPickerObserver: NSObject, PKToolPickerObserver {}
}
