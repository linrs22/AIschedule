import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct InputPanelView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isImageTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("输入内容")
                .font(.headline)

            TextEditor(text: $viewModel.inputText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor))
                }
                .frame(minHeight: 220)

            ImageInputView(
                image: viewModel.inputImage,
                isTargeted: isImageTargeted,
                onPasteImage: pasteImageFromPasteboard,
                onClearImage: viewModel.clearInputImage
            )
            .onDrop(
                of: [UTType.image],
                isTargeted: $isImageTargeted,
                perform: handleImageDrop
            )

            if !viewModel.ocrText.isEmpty {
                DisclosureGroup("图片 OCR 文字", isExpanded: $viewModel.isOCRTextVisible) {
                    Text(viewModel.ocrText)
                        .font(.callout)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            HStack {
                Button {
                    Task {
                        await viewModel.parseInput()
                    }
                } label: {
                    Label(viewModel.isParsing ? "解析中" : "解析", systemImage: "wand.and.sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canParse)

                Button {
                    viewModel.clear()
                } label: {
                    Label("清空", systemImage: "xmark.circle")
                }

                Spacer()
            }
        }
    }

    private func handleImageDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) else {
            return false
        }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
            guard let data,
                  let image = NSImage(data: data) else {
                return
            }

            Task { @MainActor in
                viewModel.setInputImage(image)
            }
        }

        return true
    }

    private func pasteImageFromPasteboard() {
        if let image = NSImage(pasteboard: .general) {
            viewModel.setInputImage(image)
        } else {
            viewModel.statusText = "剪贴板中没有可用图片"
        }
    }
}

private struct ImageInputView: View {
    let image: NSImage?
    let isTargeted: Bool
    let onPasteImage: () -> Void
    let onClearImage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("图片输入")
                .font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                                style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [6, 4])
                            )
                    }

                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        Text("拖入图片，或从剪贴板粘贴")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 150)

            HStack {
                Button {
                    onPasteImage()
                } label: {
                    Label("粘贴图片", systemImage: "doc.on.clipboard")
                }

                if image != nil {
                    Button {
                        onClearImage()
                    } label: {
                        Label("移除图片", systemImage: "xmark.circle")
                    }
                }

                Spacer()
            }
        }
    }
}
