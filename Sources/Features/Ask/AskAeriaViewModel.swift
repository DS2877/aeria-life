import Foundation

@MainActor
final class AskAeriaViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published private(set) var response: AeriaResponse?
    @Published private(set) var isThinking = false

    func ask(environment: AppEnvironment, context: AeriaContextBundle) async {
        let question = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        isThinking = true
        response = nil
        defer { isThinking = false }
        response = await environment.intelligenceProvider.respond(to: question, context: context)
    }

    func clear() {
        inputText = ""
        response = nil
    }
}
