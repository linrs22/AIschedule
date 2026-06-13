import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @StateObject private var settingsStore = SettingsStore.shared
    @State private var isSettingsPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("AIschedule")
                        .font(.largeTitle.weight(.semibold))

                    Spacer()

                    Button {
                        isSettingsPresented = true
                    } label: {
                        Label("设置", systemImage: "gearshape")
                    }
                }

                HStack(alignment: .top, spacing: 20) {
                    InputPanelView(viewModel: viewModel)
                        .frame(minWidth: 360, idealWidth: 440, maxWidth: 520)

                    ParsedResultView(
                        items: $viewModel.parsedItems,
                        onAddToCalendar: { item in
                            Task {
                                await viewModel.addToCalendar(item)
                            }
                        },
                        onAddToReminder: { item in
                            Task {
                                await viewModel.addToReminder(item)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                StatusBarView(statusText: viewModel.statusText)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 820, minHeight: 520)
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(settingsStore: settingsStore)
        }
    }
}

private struct StatusBarView: View {
    let statusText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)

            Text(statusText)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.top, 4)
    }
}
