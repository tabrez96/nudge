import Foundation

/// One alert in the S01 "Test the alerts" run, shown `delay` seconds after the click.
public struct TestAlertStep: Equatable {
    public let delay: TimeInterval
    public let alert: ScheduledAlert

    public init(delay: TimeInterval, alert: ScheduledAlert) {
        self.delay = delay
        self.alert = alert
    }
}

/// The fake meeting behind S01 "Test the alerts": S03 now, S02 a few seconds later.
/// The shell presents these directly and never passes them to `AlertTicker`, so real fired keys are untouched.
public enum TestAlerts {
    public static let meetingID = "nudge-test-alert"
    public static let title = "Test meeting"
    public static let fullScreenDelay: TimeInterval = 5
    public static let meetingLength: TimeInterval = 30 * 60

    /// Banner at `now` for a meeting 5 minutes out; full-screen warning `fullScreenDelay` later for a
    /// meeting starting one minute after that, so its countdown opens at 1:00.
    public static func steps(now: Date) -> [TestAlertStep] {
        let bannerStart = now.addingTimeInterval(AlertEngine.fiveMinuteLead)
        let warningStart = now.addingTimeInterval(fullScreenDelay + AlertEngine.oneMinuteLead)
        return [
            TestAlertStep(delay: 0, alert: ScheduledAlert(meeting: meeting(start: bannerStart), kind: .fiveMinute)),
            TestAlertStep(delay: fullScreenDelay,
                          alert: ScheduledAlert(meeting: meeting(start: warningStart), kind: .oneMinute)),
        ]
    }

    static func meeting(start: Date) -> Meeting {
        Meeting(id: meetingID, title: title, start: start, end: start.addingTimeInterval(meetingLength))
    }
}
