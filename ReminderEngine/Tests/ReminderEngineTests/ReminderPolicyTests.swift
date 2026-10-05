import Foundation
import Testing
import ReminderEngine

private let hour: TimeInterval = 60 * 60
private let day: TimeInterval = 24 * hour
private let anchor = Date(timeIntervalSince1970: 1_000_000)

private func at(_ offset: TimeInterval) -> Date {
    anchor.addingTimeInterval(offset)
}

struct ReminderPolicyTests {
    @Test("다시 알림 간격은 기본으로 주기의 1/24")
    func followUpIntervalDefaultsToOneTwentyFourth() {
        #expect(ReminderPolicy(interval: day).followUpInterval == hour)
        #expect(ReminderPolicy(interval: 30 * day).followUpInterval == 30 * hour)
    }

    @Test("짧은 주기여도 다시 알림 간격은 최소 10분")
    func followUpIntervalHasMinimum() {
        #expect(ReminderPolicy(interval: hour).followUpInterval == ReminderPolicy.minimumFollowUpInterval)
    }

    @Test("24시간 주기: 완료 24시간 뒤 알림, 1시간 간격으로 다시 알림 2회, 다음 주기 반복")
    func dailyRoutineFires() {
        let fires = ReminderPolicy(interval: day).upcomingFires(anchor: anchor, now: anchor, limit: 4)
        #expect(fires == [
            ReminderFire(date: at(day), kind: .due),
            ReminderFire(date: at(day + hour), kind: .followUp(1)),
            ReminderFire(date: at(day + 2 * hour), kind: .followUp(2)),
            ReminderFire(date: at(2 * day), kind: .due),
        ])
    }

    @Test("다시 알림을 끄면 주기마다 알림만 울린다")
    func followUpDisabled() {
        let policy = ReminderPolicy(interval: day, followUpEnabled: false)
        let fires = policy.upcomingFires(anchor: anchor, now: anchor, limit: 2)
        #expect(fires.map(\.date) == [at(day), at(2 * day)])
    }

    @Test("다음 주기를 넘어가는 다시 알림은 보내지 않는다")
    func followUpNeverPassesNextDue() {
        let policy = ReminderPolicy(interval: day, customFollowUpInterval: 13 * hour)
        let fires = policy.upcomingFires(anchor: anchor, now: anchor, limit: 3)
        #expect(fires.map(\.kind) == [.due, .followUp(1), .due])
    }

    @Test("오래 밀린 할 일은 지금 이후 알림부터 이어서 만든다")
    func overdueRoutineResumesFromNow() {
        let now = at(10 * day + 30 * 60)
        let fires = ReminderPolicy(interval: day).upcomingFires(anchor: anchor, now: now, limit: 3)
        #expect(fires == [
            ReminderFire(date: at(10 * day + hour), kind: .followUp(1)),
            ReminderFire(date: at(10 * day + 2 * hour), kind: .followUp(2)),
            ReminderFire(date: at(11 * day), kind: .due),
        ])
    }
}

struct CalendarIntervalTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 9))!
    }

    @Test("한 달 주기는 달력 기준: 3월 15일 체크 → 4월 15일 알림")
    func monthlyUsesSameDayNextMonth() {
        let policy = ReminderPolicy(step: IntervalValue(amount: 1, unit: .month), calendar: calendar)
        #expect(policy.dueDate(after: date(2026, 3, 15)) == date(2026, 4, 15))
    }

    @Test("없는 날짜는 그달 마지막 날, 다음 주기에는 원래 날짜로 돌아온다")
    func monthlyClampsWithoutDrift() {
        let policy = ReminderPolicy(step: IntervalValue(amount: 1, unit: .month), followUpEnabled: false, calendar: calendar)
        let fires = policy.upcomingFires(anchor: date(2026, 1, 31), now: date(2026, 1, 31), limit: 3)
        #expect(fires.map(\.date) == [date(2026, 2, 28), date(2026, 3, 31), date(2026, 4, 30)])
    }

    @Test("1년 주기는 다음 해 같은 날짜")
    func yearly() {
        let policy = ReminderPolicy(step: IntervalValue(amount: 1, unit: .year), calendar: calendar)
        #expect(policy.dueDate(after: date(2026, 10, 3)) == date(2027, 10, 3))
    }

    @Test("오래 밀린 월 단위 할 일도 지금 이후 알림부터 만든다")
    func overdueMonthlyResumes() {
        let policy = ReminderPolicy(step: IntervalValue(amount: 1, unit: .month), followUpEnabled: false, calendar: calendar)
        let fires = policy.upcomingFires(anchor: date(2025, 1, 10), now: date(2026, 3, 1), limit: 2)
        #expect(fires.map(\.date) == [date(2026, 3, 10), date(2026, 4, 10)])
    }
}

struct ReminderSchedulerTests {
    @Test("여러 할 일의 알림을 시간순으로 합쳐 개수 제한만큼만 예약한다")
    func mergesAndLimits() {
        let daily = ReminderScheduler.Item(routineID: UUID(), anchor: anchor, policy: ReminderPolicy(interval: day))
        let twoHourly = ReminderScheduler.Item(
            routineID: UUID(), anchor: anchor, policy: ReminderPolicy(interval: 2 * hour, followUpEnabled: false)
        )

        let plan = ReminderScheduler.plan([daily, twoHourly], now: anchor, limit: 5)

        #expect(plan.count == 5)
        #expect(plan.map(\.fire.date) == plan.map(\.fire.date).sorted())
        #expect(plan.allSatisfy { $0.routineID == twoHourly.routineID })
    }

    @Test("기본 제한은 iOS 예약 알림 한도인 64개")
    func defaultLimitIsSystemLimit() {
        let item = ReminderScheduler.Item(routineID: UUID(), anchor: anchor, policy: ReminderPolicy(interval: hour))
        #expect(ReminderScheduler.plan([item], now: anchor).count == 64)
    }
}

struct QuietHoursTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    private var quiet: QuietHours {
        QuietHours(isEnabled: true, start: 23 * 60, end: 8 * 60, calendar: calendar)
    }

    @Test("밤 11시 ~ 아침 8시 사이 알림은 아침 8시로, 그 밖은 그대로")
    func adjustsIntoMorning() {
        #expect(quiet.adjusted(date(5, 2)) == date(5, 8))
        #expect(quiet.adjusted(date(5, 23, 30)) == date(6, 8))
        #expect(quiet.adjusted(date(5, 8)) == date(5, 8))
        #expect(quiet.adjusted(date(5, 22, 59)) == date(5, 22, 59))
    }

    @Test("꺼져 있거나 시작과 끝이 같으면 미루지 않는다")
    func disabled() {
        var off = quiet
        off.isEnabled = false
        #expect(off.adjusted(date(5, 2)) == date(5, 2))
        let same = QuietHours(isEnabled: true, start: 60, end: 60, calendar: calendar)
        #expect(same.adjusted(date(5, 1)) == date(5, 1))
    }

    @Test("새벽 2시 체크 → 다음 날 새벽 알림과 다시 알림이 아침 8시 하나로 모인다")
    func plannerCollapsesQuietFires() {
        let policy = ReminderPolicy(step: IntervalValue(amount: 1, unit: .day), calendar: calendar)
        let item = ReminderScheduler.Item(routineID: UUID(), anchor: date(5, 2), policy: policy)

        let plan = ReminderScheduler.plan([item], now: date(5, 2), limit: 6, quietHours: quiet)

        #expect(plan.map(\.fire.date) == [date(6, 8), date(7, 8)])
    }
}
