import SwiftData
import SwiftUI

struct SessionRecoveryModifier: ViewModifier {
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<DevelopmentSession> { $0.statusRaw == "inProgress" }, sort: \DevelopmentSession.startedAt)
    private var unfinishedSessions: [DevelopmentSession]

    func body(content: Content) -> some View {
        content
            .alert(String(localized: .recoveryTitle), isPresented: .constant(!unfinishedSessions.isEmpty)) {
                Button(String(localized: .recoveryCompleted)) {
                    finish(status: .completed)
                }
                Button(String(localized: .recoveryAborted)) {
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
        return String(localized: .recoveryMessage(kitName, session.films.count, session.startedAt.formatted(.dateAndTime)))
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
