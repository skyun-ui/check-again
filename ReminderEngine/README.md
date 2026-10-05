# ReminderEngine

Check Again의 **알림 일정 계산 엔진**입니다. 화면·위젯·저장소와 무관한 순수 Swift 로직이라 macOS에서 `swift test`로 바로 검증할 수 있습니다.

```bash
cd ReminderEngine
swift test
```

## 구성

| 타입 | 하는 일 |
|---|---|
| `IntervalValue` | 시간·일·주·월·년 주기. 월·년은 달력 기준(3/15 → 4/15, 1/31 → 2/28 → 3/31) |
| `ReminderPolicy` | 할 일 하나의 알림 일정. **마지막으로 완료한 시각부터** 다음 주기를 세고, 체크하지 않으면 주기의 1/24 간격(최소 10분)으로 최대 2번 더 알림 |
| `ReminderScheduler` | 여러 할 일의 알림을 시간순으로 합쳐 iOS 예약 알림 한도(앱당 64개) 안에서 가장 가까운 것만 예약 |
| `QuietHours` | 방해 금지 시간. 그 시간의 알림은 끝나는 시각으로 미루고, 같은 할 일의 알림이 겹치면 하나만 |

## 예시

```swift
import ReminderEngine

// 고양이 물 갈기: 매일, 마지막으로 한 때부터
let policy = ReminderPolicy(step: IntervalValue(amount: 1, unit: .day))
let item = ReminderScheduler.Item(routineID: UUID(), anchor: lastDoneAt, policy: policy)

// 앞으로 예약할 알림 (밤 11시 ~ 아침 8시는 아침 8시로)
let requests = ReminderScheduler.plan([item], now: .now, quietHours: QuietHours())
```

## 설계 메모

- **시간 계산을 데이터 모델과 분리**: 날짜를 넣으면 날짜가 나오는 순수 함수라, 경계 조건(오래 밀린 할 일, 월말, 자정을 넘는 방해 금지 시간)을 테스트로 정확히 고정할 수 있습니다.
- **다시 예약해도 중복 없음**: 알림 식별자를 "할 일 ID + 시각"으로 만들어, 데이터가 바뀔 때마다 전체를 다시 계산해도 같은 알림이 두 번 생기지 않습니다.
- **월·년 주기의 날짜 밀림 방지**: 매번 직전 알림이 아니라 기준 시각에서 N번째 주기를 계산합니다.
