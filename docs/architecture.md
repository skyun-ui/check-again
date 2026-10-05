# 구조

## 한눈에 보기

```mermaid
flowchart LR
    subgraph App["앱 (work1)"]
        UI["SwiftUI 화면<br/>목록 모음 · 목록 · 세부사항 · 설정"]
        RN["ReminderNotifications<br/>권한 · 알림 응답"]
        CR["CalendarRecorder<br/>캘린더 기록"]
    end

    subgraph Widget["위젯 확장"]
        TL["DueProvider<br/>위젯 화면 미리 계산"]
        IN["CompleteRoutineIntent<br/>위젯에서 체크"]
    end

    subgraph Shared["Shared (앱·위젯 공통 코드)"]
        M["SwiftData 모델<br/>TaskList · Routine · Completion · Subtask"]
        NP["NotificationPlanner<br/>알림 재예약"]
        RE["알림 일정 계산<br/>(ReminderEngine)"]
    end

    Store[("App Group 저장소<br/>work1.store")]
    UN["iOS 알림"]
    EK["캘린더 (EventKit)"]

    UI --> M
    IN --> M
    TL --> M
    M --- Store
    NP --> RE
    RN --> NP
    IN --> NP
    NP --> UN
    CR --> EK
```

- **타깃 3개**: 앱, 위젯 확장, 단위 테스트
- **Shared 폴더**는 앱과 위젯 확장 양쪽에 함께 컴파일된다. 모델, 알림 재예약, 일정 계산처럼 두 프로세스가 똑같이 동작해야 하는 코드만 둔다.
- **저장소는 App Group 공유 폴더**에 있다. 위젯은 앱과 다른 프로세스라서 앱 전용 폴더를 읽을 수 없기 때문이다.

## 데이터 모델

```mermaid
erDiagram
    TaskList ||--o{ Routine : "목록 삭제 시 함께 삭제"
    Routine ||--o{ Completion : "할 일 삭제해도 기록은 남김"
    Routine ||--o{ Subtask : "할 일 삭제 시 함께 삭제"

    Routine {
        string title
        string notes
        double interval "대략적인 초"
        int intervalAmount
        string intervalUnitRaw "시간·일·주·월·년"
        date lastCompletedAt "다음 주기의 기준"
        bool isOneTime
        date dueAt "한 번짜리의 시각"
        double manualOrder
    }
    Completion {
        date completedAt
        string title "완료 당시 제목 사본"
        string calendarEventID "비어 있으면 캘린더에 아직 안 옮김"
    }
```

## 주요 흐름

### 앱에서 체크했을 때

```mermaid
sequenceDiagram
    participant U as 사용자
    participant V as 목록 화면
    participant S as 저장소
    participant N as NotificationPlanner
    participant W as 위젯

    U->>V: 동그라미 누름
    V->>V: 0.7초 채워진 동그라미 표시(그 사이 다시 누르면 취소)
    V->>S: complete() 후 즉시 저장
    S-->>N: 저장 알림(ModelContext.didSave), 0.3초 모아서 한 번만
    N->>N: 전체 알림 다시 계산(가장 가까운 64개, 방해 금지 시간 반영)
    N->>N: 이미 한 일의 받은 알림은 알림 센터에서 정리
    N->>W: 위젯 다시 그리기
```

### 위젯에서 체크했을 때
1. 위젯 확장의 `CompleteRoutineIntent`가 공유 저장소를 열어 완료 처리하고 저장한다.
2. 같은 `NotificationPlanner`로 알림을 다시 예약한다. 이미 한 일에 알림이 울리지 않는다.
3. "앱 밖에서 바뀜" 시각을 공유 설정에 남긴다. 앱이 다음에 활성화되면 이를 보고 저장소를 다시 열어 화면을 맞춘다.
4. 캘린더 기록은 앱에만 권한이 있으므로, 앱이 열릴 때 기록되지 않은 완료를 찾아 옮긴다.

### 위젯 화면
- 위젯은 실시간으로 갱신되지 않는다. 그래서 "할 일이 새로 나타나는 시각"마다 위젯 화면을 미리 만들어 둔다(최대 30장).
- 위젯은 SwiftData 객체가 아닌 값(`DueItem`)만 들고 그린다. 저장소를 닫은 뒤 객체 속성을 읽으면 크래시가 나기 때문이다. → [사례](case-swiftdata-lifetime.md)

## 테스트
- 앱: Swift Testing 52개. 일정 계산, 목록 구역·정렬, 위젯 표시 순서, 데이터 이전(실제 SQLite 파일 복사), 캘린더 기록 대상 선정 등.
- 공개 엔진: 19개, GitHub Actions에서 자동 실행.
- 저장 구조를 바꿀 때마다 **실기기 데이터 사본**을 시뮬레이터에서 새 버전으로 열어, 기존 할 일이 그대로 열리는지 확인했다.
