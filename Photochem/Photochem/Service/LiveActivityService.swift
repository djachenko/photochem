import ActivityKit

@MainActor
protocol LiveActivityService: AnyObject {
    func start(processName: String, totalStages: Int, state: DevelopmentActivityAttributes.ContentState) async
    func update(state: DevelopmentActivityAttributes.ContentState) async
    func stop() async
}

@MainActor
final class LiveActivityServiceImpl: LiveActivityService {
    private var activityID: String?

    func start(
        processName: String,
        totalStages: Int,
        state: DevelopmentActivityAttributes.ContentState
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activityID == nil else {
            return
        }
        let activity = try? Activity.request(
            attributes: DevelopmentActivityAttributes(processName: processName, totalStages: totalStages),
            content: ActivityContent(state: state, staleDate: nil)
        )
        activityID = activity?.id
    }

    func update(state: DevelopmentActivityAttributes.ContentState) async {
        guard let activityID else {
            return
        }
        await Self.update(activityID: activityID, state: state)
    }

    func stop() async {
        guard let activityID else {
            return
        }
        self.activityID = nil
        await Self.end(activityID: activityID)
    }

    private nonisolated static func update(
        activityID: String,
        state: DevelopmentActivityAttributes.ContentState
    ) async {
        guard let activity = activity(id: activityID) else {
            return
        }
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    private nonisolated static func end(activityID: String) async {
        guard let activity = activity(id: activityID) else {
            return
        }
        await activity.end(nil, dismissalPolicy: .immediate)
    }

    private nonisolated static func activity(id: String) -> Activity<DevelopmentActivityAttributes>? {
        Activity<DevelopmentActivityAttributes>.activities.first { $0.id == id }
    }
}
