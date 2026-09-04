import UserNotifications

protocol NotificationService: AnyObject {
    func requestAuthorization() async -> Bool
    func scheduleStageAlerts(sessionID: UUID, stageIndex: Int, stageName: String, preAlertAt: Date?, endAt: Date)
    func cancelStageAlerts(sessionID: UUID, stageIndex: Int)
    func cancelAll(sessionID: UUID, stageCount: Int)
}

final class NotificationServiceImpl: NotificationService {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func scheduleStageAlerts(
        sessionID: UUID,
        stageIndex: Int,
        stageName: String,
        preAlertAt: Date?,
        endAt: Date
    ) {
        if let preAlertAt {
            add(
                identifier: Self.preAlertID(sessionID: sessionID, stageIndex: stageIndex),
                body: "Скоро конец: \(stageName)",
                soundName: "sound_pre.caf",
                date: preAlertAt
            )
        }
        add(
            identifier: Self.stageEndID(sessionID: sessionID, stageIndex: stageIndex),
            body: "Этап \(stageName) закончился — сливай",
            soundName: "sound_end.caf",
            date: endAt
        )
    }

    func cancelStageAlerts(sessionID: UUID, stageIndex: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.preAlertID(sessionID: sessionID, stageIndex: stageIndex),
            Self.stageEndID(sessionID: sessionID, stageIndex: stageIndex)
        ])
    }

    func cancelAll(sessionID: UUID, stageCount: Int) {
        let identifiers = (0..<stageCount).flatMap { stageIndex in
            [
                Self.preAlertID(sessionID: sessionID, stageIndex: stageIndex),
                Self.stageEndID(sessionID: sessionID, stageIndex: stageIndex)
            ]
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func add(identifier: String, body: String, soundName: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.body = body
        content.interruptionLevel = .timeSensitive
        content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        center.add(request)
    }

    private static func preAlertID(sessionID: UUID, stageIndex: Int) -> String {
        "pre-\(sessionID)-\(stageIndex)"
    }

    private static func stageEndID(sessionID: UUID, stageIndex: Int) -> String {
        "end-\(sessionID)-\(stageIndex)"
    }
}
