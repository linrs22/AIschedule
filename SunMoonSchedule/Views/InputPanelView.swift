import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct InputPanelView: View {
    private enum InputFocus {
        case text
        case image
    }

    @ObservedObject var viewModel: MainViewModel
    @State private var isImageTargeted = false
    @FocusState private var focusedInput: InputFocus?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label("输入内容", systemImage: "square.and.pencil")
                    .font(.headline)

                Text("输入文字，也可以附加一张图片")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if viewModel.hasMixedInput {
                    Label("文字和图片将一起解析", systemImage: "arrow.triangle.merge")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }

            TextEditor(text: $viewModel.inputText)
                .focused($focusedInput, equals: .text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.8))
                }
                .frame(minHeight: 190)

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
            .focusable()
            .focused($focusedInput, equals: .image)
            .onTapGesture {
                focusedInput = .image
            }
            .onPasteCommand(of: [.image]) { providers in
                _ = handleImageDrop(providers)
            }

            if !viewModel.ocrText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isOCRTextVisible.toggle()
                        }
                    } label: {
                        HStack {
                            Label("图片 OCR 文字", systemImage: "text.viewfinder")
                                .font(.callout.weight(.medium))

                            Spacer()

                            Text(viewModel.isOCRTextVisible ? "收起" : "展开")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .rotationEffect(.degrees(viewModel.isOCRTextVisible ? 180 : 0))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Text(viewModel.ocrText)
                        .font(.callout)
                        .lineLimit(viewModel.isOCRTextVisible ? nil : 3)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            Divider()

            HStack(spacing: 10) {
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
                    Image(systemName: "trash")
                }
                .help("清空输入内容")

                Spacer()
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blue.opacity(0.14))
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
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.65))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
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

                VStack {
                    HStack {
                        Spacer()

                        Button {
                            onClearImage()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption.weight(.semibold))
                                .padding(6)
                                .background(.regularMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help("移除图片")
                    }

                    Spacer()
                }
                .padding(8)
            } else {
                Button {
                    onPasteImage()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)

                        Text("拖入或粘贴图片")
                            .font(.callout)

                        Text("可选")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .frame(height: image == nil ? 92 : 150)
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}
