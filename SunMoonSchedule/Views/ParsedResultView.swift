import SwiftUI

struct ParsedResultView: View {
    @Binding var items: [ParsedItem]
    let onAddToCalendar: (ParsedItem) -> Void
    let onAddToReminder: (ParsedItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("解析结果")
                .font(.headline)

            if items.isEmpty {
                Text("解析结果会显示在这里。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach($items) { $item in
                        ParsedItemCard(
                            item: $item,
                            onAddToCalendar: onAddToCalendar,
                            onAddToReminder: onAddToReminder
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct ParsedItemCard: View {
    @Binding var item: ParsedItem
    let onAddToCalendar: (ParsedItem) -> Void
    let onAddToReminder: (ParsedItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("类型", selection: $item.type) {
                ForEach(ParsedItemType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if item.confidence < 0.7 {
                WarningBanner(
                    systemImage: "exclamationmark.triangle.fill",
                    title: "识别置信度较低，请检查"
                )
            }

            if !item.missingFields.isEmpty {
                WarningBanner(
                    systemImage: "questionmark.circle.fill",
                    title: "需要确认的信息：\(item.missingFields.joined(separator: ", "))"
                )
            }

            TextField("标题", text: $item.title)
                .textFieldStyle(.roundedBorder)

            if item.type == .calendarEvent {
                EditableDateRow(title: "开始时间", date: $item.startDate)
                EditableDateRow(title: "结束时间", date: $item.endDate)
                TextField("地点", text: $item.location)
                    .textFieldStyle(.roundedBorder)
                TextField("备注", text: $item.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...5)
            } else {
                EditableDateRow(title: "截止时间", date: $item.dueDate)
                Picker("优先级", selection: $item.priority) {
                    ForEach(ParsedItemPriority.allCases) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
                .pickerStyle(.menu)
                TextField("地点（可选）", text: $item.location)
                    .textFieldStyle(.roundedBorder)
                TextField("备注", text: $item.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...5)
            }

            HStack {
                Text("置信度 \(item.confidence.formatted(.percent.precision(.fractionLength(0))))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    onAddToCalendar(item)
                } label: {
                    Label("添加到日历", systemImage: "calendar.badge.plus")
                }

                Button {
                    onAddToReminder(item)
                } label: {
                    Label("添加到提醒事项", systemImage: "checklist")
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct EditableDateRow: View {
    let title: String
    @Binding var date: Date?

    private var isEnabled: Binding<Bool> {
        Binding(
            get: { date != nil },
            set: { isEnabled in
                date = isEnabled ? Date() : nil
            }
        )
    }

    private var concreteDate: Binding<Date> {
        Binding(
            get: { date ?? Date() },
            set: { date = $0 }
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: isEnabled)
                .labelsHidden()

            Text(title)
                .frame(width: 72, alignment: .leading)

            DatePicker("", selection: concreteDate)
                .labelsHidden()
                .disabled(date == nil)

            Spacer()
        }
    }
}

private struct WarningBanner: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.orange)

            Text(title)
                .font(.callout)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(10)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
