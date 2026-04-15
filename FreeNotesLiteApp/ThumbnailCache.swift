import SwiftUI
import PDFKit

class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        cache.countLimit = 50
    }
    
    func thumbnail(for url: URL, pageIndex: Int, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let key = NSURL(fileURLWithPath: "\(url.absoluteString)-\(pageIndex)")

        if let cachedImage = cache.object(forKey: key) {
            completion(cachedImage)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let document = PDFDocument(url: url),
                  let page = document.page(at: pageIndex) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let thumbnailImage = page.thumbnail(of: size, for: .mediaBox)

            self.cache.setObject(thumbnailImage, forKey: key)

            DispatchQueue.main.async {
                completion(thumbnailImage)
            }
        }
    }
}

struct AsyncPDFThumbnail: View {
    let url: URL
    let pageIndex: Int
    let size: CGSize
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let loadedImage = image {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .onAppear {
            ThumbnailCache.shared.thumbnail(for: url, pageIndex: pageIndex, size: size) { img in
                self.image = img
            }
        }
    }
}
