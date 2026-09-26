import SwiftUI

struct DesktopView: View {
    let store: DailyStore
    @State private var section = "Questions"
    @State private var selectedID: UUID?
    @State private var showArchived = false
    @State private var creating = false
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all

    private var selectedQuestion: DailyQuestion? {
        store.questions.first { $0.id == selectedID }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    Image("AppLogo")
                        .resizable().scaledToFit()
                        .frame(width: 76, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .accessibilityHidden(true)
                    Text("Daily Questions").font(.title2.bold())
                }
                .padding(.horizontal, 24).padding(.top, 24)
                List(selection: $section) {
                    Label("Questions", systemImage: "list.bullet").tag("Questions")
                    Label("Analytics", systemImage: "chart.bar.xaxis").tag("Analytics")
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 260)
        } detail: {
            Group {
                if section == "Analytics", let question = selectedQuestion {
                    QuestionPerformanceView(question: question, store: store) {
                        section = "Questions"
                    }
                } else {
                    questionBrowser
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.background)
        }
        .navigationTitle("")
        .frame(minWidth: 950, minHeight: 610)
        .foregroundStyle(Palette.ink)
        .background {
            Button("") {
                withAnimation {
                    sidebarVisibility = sidebarVisibility == .detailOnly ? .all : .detailOnly
                }
            }
            .keyboardShortcut("b", modifiers: .command)
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)
        }
        .sheet(isPresented: $creating) {
            NewQuestionSheet(store: store) { question in
                showArchived = false
                selectedID = question.id
                section = "Questions"
            }
        }
    }

    private var questionBrowser: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack {
                Text(section).font(.system(size: 30, weight: .bold))
                Spacer()
                if section == "Questions" {
                    Button { creating = true } label: {
                        Label("New Question", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
            Picker("Question status", selection: $showArchived) {
                Text("Active").tag(false)
                Text("Archived").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 210, alignment: .leading)

            let questions = store.questions.filter { ($0.archivedDay != nil) == showArchived }
            if questions.isEmpty {
                Text(showArchived ? "No archived questions" : "No active questions")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(questions) { question in
                            let expanded = question.id == selectedID
                            VStack(alignment: .leading, spacing: 0) {
                                Button {
                                    selectedID = expanded ? nil : question.id
                                } label: {
                                    HStack(alignment: .firstTextBaseline, spacing: 20) {
                                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                                            .font(.body.weight(.medium))
                                            .frame(width: 16)
                                            .accessibilityHidden(true)
                                        Text(question.text)
                                            .font(.system(size: 18, weight: expanded ? .semibold : .regular))
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(18)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(question.text)
                                .accessibilityValue(expanded ? "Expanded" : "Collapsed")
                                .accessibilityHint(expanded ? "Collapse question" : "Expand question")

                                if expanded {
                                    QuestionEditor(question: question, store: store) {
                                        section = "Analytics"
                                    } onArchive: {
                                        selectedID = nil
                                    }
                                    .id(question.id)
                                    .padding(.leading, 54)
                                    .padding(.trailing, 18)
                                    .padding(.bottom, 18)
                                }
                            }
                            .background(expanded ? Palette.surface : .clear)
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(28)
        .onChange(of: showArchived) {
            if let question = selectedQuestion, (question.archivedDay != nil) != showArchived {
                selectedID = nil
            }
        }
    }
}

private struct QuestionEditor: View {
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
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Question").font(.callout).foregroundStyle(.secondary)
                if question.archivedDay == nil {
                    TextField("Question", text: $text, axis: .vertical)
                        .lineLimit(1...4).textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("questionText")
                } else {
                    Text(question.text).textSelection(.enabled)
                }
            }
            Button("View performance", action: onPerformance)
                .controlSize(.large)
            if let error { Text(error).foregroundStyle(.red).font(.callout) }
            if question.archivedDay == nil {
                Divider()
                HStack {
                    Button("Save Changes") {
                        do { try store.updateQuestion(question, text: text); text = question.text; error = nil }
                        catch { self.error = error.localizedDescription }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(text == question.text)
                    Spacer(minLength: 8)
                    Button("Cancel") { text = question.text; error = nil }
                        .disabled(text == question.text && error == nil)
                    Button("Archive") {
                        do { try store.archiveQuestion(question); onArchive() }
                        catch { self.error = error.localizedDescription }
                    }
                }
                .controlSize(.large)
            }
        }
    }
}

private struct NewQuestionSheet: View {
    let store: DailyStore
    let onCreate: (DailyQuestion) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Question").font(.title2.bold())
            TextField("Question", text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .accessibilityIdentifier("newQuestionText")
            if let error { Text(error).foregroundStyle(.red).font(.callout) }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Create") {
                    do {
                        let question = try store.createQuestion(text)
                        onCreate(question)
                        dismiss()
                    } catch { self.error = error.localizedDescription }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28).frame(width: 420)
        .tint(Palette.ink).preferredColorScheme(.light)
        .onAppear { focused = true }
    }
}
