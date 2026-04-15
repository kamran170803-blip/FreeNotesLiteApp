import SwiftUI
import UIKit

struct UIColorPickerSheet: UIViewControllerRepresentable {
    @Binding var selectedColor: UIColor
    let onSave: (UIColor) -> Void
    let dismiss: () -> Void

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = true
        picker.selectedColor = selectedColor
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIColorPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var parent: UIColorPickerSheet

        init(_ parent: UIColorPickerSheet) {
            self.parent = parent
        }

        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            parent.selectedColor = viewController.selectedColor
        }

        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            let color = viewController.selectedColor
            parent.selectedColor = color
            parent.onSave(color)
            parent.dismiss()
        }
    }
}
