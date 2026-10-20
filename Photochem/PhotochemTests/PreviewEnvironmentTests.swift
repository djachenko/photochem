import Testing
@testable import Photochem

/// Засев превью-хранилища не должен ходить в `resolver`, пока тот ещё собирается:
/// рекурсивный `dispatch_once` роняет каждое превью.
@MainActor
struct PreviewEnvironmentTests {
    @Test("P1: засев превью не входит в resolver повторно")
    func seededStoreIsReachable() {
        #expect(PreviewEnvironment.session.kit == PreviewEnvironment.kit)
    }
}
