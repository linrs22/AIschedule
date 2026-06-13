import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var draftAPIKey: String
    @State private var statusText = ""

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        _draftAPIKey = State(initialValue: settingsStore.deepSeekAPIKey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置API")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("DeepSeek API Key")
                    .font(.headline)

                SecureField("输入 DeepSeek API Key", text: $draftAPIKey)
                    .textFieldStyle(.roundedBorder)

                Text("应用不内置 API Key。你填写的 Key 仅保存在本机系统钥匙串中。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if settingsStore.hasDeepSeekAPIKey {
                    Text("已保存 API Key")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            if !statusText.isEmpty {
                Text(statusText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()

                Button("取消") {
                    dismiss()
                }

                Button("保存") {
                    do {
                        try settingsStore.saveDeepSeekAPIKey(draftAPIKey)
                        statusText = settingsStore.hasDeepSeekAPIKey ? "已安全保存" : "API Key 已清空"
                        dismiss()
                    } catch {
                        statusText = error.localizedDescription
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
