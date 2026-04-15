import SwiftUI

struct PageSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let page: NotePage?
    let onUpdateStyle: (PageStyle) -> Void
    let onUpdateColor: (String) -> Void

    @State private var selectedStyle: PageStyle
    @State private var selectedColorHex: String

    private let paperColors: [(String, String)] = [
        ("White", "FFFFFF"), ("Cream", "FFF8E7"), ("Gray", "F0F0F0"),
        ("Blue", "E6F0FF"), ("Green", "E6FFE6"), ("Pink", "FFE6F0"),
        ("Yellow", "FFFFCC"), ("Lavender", "F0E6FF")
    ]

    init(page: NotePage?, onUpdateStyle: @escaping (PageStyle) -> Void, onUpdateColor: @escaping (String) -> Void) {
        self.page = page
        self.onUpdateStyle = onUpdateStyle
        self.onUpdateColor = onUpdateColor
        _selectedStyle = State(initialValue: page?.style ?? .blank)
        _selectedColorHex = State(initialValue: page?.pageColorHex ?? "FFFFFF")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Page Style") {
                    Picker("Style", selection: $selectedStyle) {
                        ForEach(PageStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Paper Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                        ForEach(paperColors, id: \.1) { name, hex in
                            VStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: hex))
                                    .frame(height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedColorHex == hex ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                                Text(name)
                                    .font(.caption2)
                            }
                            .onTapGesture {
                                selectedColorHex = hex
                            }
                        }
                    }
                }
            }
            .navigationTitle("Page Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onUpdateStyle(selectedStyle)
                        onUpdateColor(selectedColorHex)
                        dismiss()
                    }
                }
            }
        }
    }
}
