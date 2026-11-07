import SwiftUI

struct MobileQuestionsView: View {
    let store: DailyStore
    let sync: SyncCoordinator
    @State private var showArchived = false
    @State private var selectedID: UUID?
    @State private var creating = false
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Question status", selection: $showArchived) {
                        Image(systemName: "tray.full").tag(false).accessibilityLabel("Active")
                        Image(systemName: "archivebox").tag(true).accessibilityLabel("Archived")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                    .frame(width: 112, alignment: .leading)

                    let questions = store.questions.filter { ($0.archivedDay != nil) == showArchived }
                    if questions.isEmpty {
                        Text(showArchived ? "No archived questions" : "No active questions")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                                let expanded = question.id == selectedID
                                VStack(alignment: .leading, spacing: 0) {
                                    Button {
                                        withAnimation(.snappy) { selectedID = expanded ? nil : question.id }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: expanded ? "chevron.down" : "chevron.right")
                                                .font(.footnote.weight(.semibold))
                                                .foregroundStyle(expanded ? Palette.ink : .secondary)
                                                .frame(width: 14)
                                                .accessibilityHidden(true)
                                            Text(question.text)
                                                .fontWeight(expanded ? .semibold : .regular)
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding(16)
                                        .frame(minHeight: 56)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(question.text)
                                    .accessibilityValue(expanded ? "Expanded" : "Collapsed")
                                    .accessibilityHint(expanded ? "Collapse question" : "Expand question")

                                    if expanded {
                                        MobileQuestionEditor(question: question, store: store) {
                                            path.append(question.id)
                                        } onArchive: {
                                            selectedID = nil
                                        }
                                        .id(question.id)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 16)
                                    }
                                }
                                .background(expanded ? Palette.selection.opacity(0.5) : .clear)
                                if index < questions.count - 1 {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .clipShape(MobileLayout.cardShape)
                        .mobileCard()

                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Palette.background)
            .navigationTitle("Questions")
            .settingsToolbar(sync)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { creating = true } label: {
                        Label("New", systemImage: "plus")
                    }
                    .accessibilityLabel("New question")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let question = store.questions.first(where: { $0.id == id }) {
                    MobileReportView(question: question, store: store)
                }
            }
            .sheet(isPresented: $creating) {
                MobileNewQuestionSheet(store: store) { question in
                    showArchived = false
                    selectedID = question.id
                }
            }
            .onChange(of: showArchived) {
                if let question = store.questions.first(where: { $0.id == selectedID }),
                   (question.archivedDay != nil) != showArchived {
                    selectedID = nil
                }
            }
        }
    }
}

private struct MobileQuestionEditor: View {
    let question: DailyQuestion
    let store: DailyStore
    let onPerformance: () -> Void
    let onArchive: () -> Void
    @State private var text: String
    @State private var error: String?

    init(question: DailyQuestion, store: DailyStore, onPerformance: @escaping () -> Void, onArchive: @escaping () -> Void) {
        self.question = question
        self.store = store
        self.onPerformance = onPerformance
        self.onArchive = onArchive
        _text = State(initialValue: question.text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if question.archivedDay == nil {
                Text("Question").font(.footnote).foregroundStyle(.secondary)
                TextField("Question", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("questionText")
                Text("\(created) Editing wording updates every report. Saved answers do not change.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(created) Archived \(dayText(question.archivedDay)). Answers are kept.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let error { Text(error).font(.callout).foregroundStyle(.red) }
            if question.archivedDay == nil {
                HStack(spacing: 8) {
                    Button("Save Changes") {
                        do { try store.updateQuestion(question, text: text); text = question.text; error = nil }
                        catch { self.error = error.localizedDescription }
                    }
                    .inkProminentButton()
                    .disabled(text == question.text)
                    Button("Cancel") { text = question.text; error = nil }
                        .buttonStyle(.bordered)
                        .disabled(text == question.text && error == nil)
                }
                .frame(maxWidth: .infinity)
            }
            HStack(spacing: 8) {
                Button(action: onPerformance) {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }
                .buttonStyle(.bordered)
                if question.archivedDay == nil {
                    Button {
                        do { try store.archiveQuestion(question); onArchive() }
                        catch { self.error = error.localizedDescription }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
    }

    private var created: String {
        "Created \(dayText(question.createdDay))."
    }

    private func dayText(_ key: String?) -> String {
        guard let key, let date = MobileLayout.date(fromKey: key) else { return key ?? "" }
        return date.formatted(MobileLayout.dateFormat.weekday(.abbreviated).month(.abbreviated).day().year())
    }
}

private struct MobileNewQuestionSheet: View {
    let store: DailyStore
    let onCreate: (DailyQuestion) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Question", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(create)
                    .accessibilityIdentifier("newQuestionText")
                Text("Asked Monday through Friday from today on.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let error { Text(error).font(.callout).foregroundStyle(.red) }
                Spacer()
            }
            .padding(20)
            .background(Palette.background)
            .navigationTitle("New Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .tint(Palette.ink)
        .onAppear { focused = true }
    }

    private func create() {
        do {
            let question = try store.createQuestion(text)
            onCreate(question)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
