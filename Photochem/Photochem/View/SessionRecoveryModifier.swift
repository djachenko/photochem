import SwiftData
import SwiftUI

struct SessionRecoveryModifier: ViewModifier {
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<DevelopmentSession> { $0.statusRaw == "inProgress" }, sort: \DevelopmentSession.startedAt)
    private var unfinishedSessions: [DevelopmentSession]

    func body(content: Content) -> some View {
        content
            .alert("Найдена незавершённая проявка", isPresented: .constant(!unfinishedSessions.isEmpty)) {
                Button("Завершилась нормально") {
                    finish(status: .completed)
                }
                Button("Была прервана") {
                    finish(status: .aborted)
                }
            } message: {
                if let session = unfinishedSessions.first {
                    Text(description(of: session))
                }
            }
    }

    private func description(of session: DevelopmentSession) -> String {
        let kitName = session.kit?.processName ?? ""
        return "\(kitName), \(session.films.count) плёнок, \(session.startedAt.formatted(.dateAndTime)). Чем закончилась?"
    }

    private func finish(status: SessionStatus) {
        guard let session = unfinishedSessions.first else {
            return
        }
        session.status = status
        session.finishedAt = .now
        try? modelContext.save()
    }
}

extension View {
    func sessionRecoveryDialog() -> some View {
        modifier(SessionRecoveryModifier())
    }
}
