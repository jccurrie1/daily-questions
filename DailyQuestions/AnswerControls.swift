import SwiftUI

struct AnswerButton: View {
    let value: Bool
    let question: DailyQuestion
    let saved: DailyAnswer?
    var size: CGFloat = 34
    var fontSize: CGFloat = 16
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(value ? "y" : "n").font(.system(size: fontSize, weight: .medium))
                .frame(width: size, height: size)
                .foregroundStyle(saved?.value == value ? Palette.onInk : Palette.ink)
                .background(saved?.value == value ? Palette.ink : Palette.selection, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(AnswerBubbleStyle())
        .disabled(saved != nil)
        .accessibilityLabel("\(value ? "Yes" : "No") — \(question.text)")
        .accessibilityValue(saved.map { "Saved \($0.value ? "Yes" : "No"). Cannot be changed." } ?? "Not answered")
        .help(saved == nil ? (value ? "Answer Yes" : "Answer No") : "Saved answers cannot be changed")
    }
}

struct SavedLock: View {
    let saved: Bool

    var body: some View {
        Image(systemName: "lock.fill")
            .font(.caption).foregroundStyle(.secondary)
            .opacity(saved ? 1 : 0)
            .accessibilityHidden(true)
    }
}

private struct AnswerBubbleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.75 : 1)
    }
}
