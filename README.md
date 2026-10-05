# Check Again

**마지막으로 한 때부터 다시 세서 알려 주는 할 일 앱 (iOS)**

> **English summary** — Check Again is an iOS to-do app that counts the next reminder from *when you last did it*, not from a fixed calendar time. Due items surface on the Home and Lock Screen widgets only when it's time, so you can stop keeping them in your head. Built with SwiftUI, SwiftData, WidgetKit and App Intents. This repository is a case study; the app's source is private, and the reminder scheduling engine is published under `ReminderEngine/`.

<!-- 대표 스크린샷: 목록 · 위젯 · 잠금 화면 · 다크 모드 (작성 예정) -->

---

## 왜 만들었나

고양이 물 갈기와 화장실 청소는 "매일 오전 9시"가 아니라 **"마지막으로 한 때부터 24시간"**이 기준입니다. 그런데 아이폰 미리 알림의 반복은 달력 기준이라, 밤 11시에 늦게 하면 다음 알림이 10시간 뒤에 옵니다.

Check Again은 **체크한 순간부터 다음 주기를 셉니다.** 정수기 필터(6개월), 칫솔(3개월)처럼 간격이 길어서 잊기 쉬운 일일수록 효과가 큽니다.

## 주요 기능

- **완료 기준 반복**: 체크한 때부터 시간·일·주·월·년 단위로 다음 알림 (월·년은 달력 기준)
- **때가 되면 눈앞에**: 해야 할 일만 홈·잠금 화면 위젯에 나타나고, 다 하면 사라짐
- **다시 알림과 방해 금지 시간**: 체크하지 않으면 주기의 1/24 간격으로 최대 2번, 밤에는 아침으로 미룸
- **캘린더 기록**: 완료하면 캘린더에 자동 기록 (쓰기 전용 권한)
- **미리 알림 수준의 사용감**: 여러 목록, 한 번 할 일, 메모, 하위 항목, 검색, 끌어서 정렬

## 기술 스택과 구조

SwiftUI · SwiftData · WidgetKit · App Intents · UserNotifications · EventKit · App Group · Swift Testing

> 자세한 구조: [docs/architecture.md](docs/architecture.md) (작성 예정)

## 설계 결정

> [docs/decisions.md](docs/decisions.md) (작성 예정)

## 문제 해결 사례

- [시작 속도: 가설을 버리고 측정으로 찾은 진짜 원인](docs/case-launch-time.md) (작성 예정)
- [iOS 예약 알림 64개 한도와 스케줄러](docs/case-notification-limit.md) (작성 예정)

## 공개 코드: ReminderEngine

앱의 알림 일정 계산 엔진(완료 기준 반복, 다시 알림, 방해 금지 시간, 64개 한도)을 테스트와 함께 공개합니다. 화면·위젯·저장소 코드는 포함하지 않습니다.

> [ReminderEngine/](ReminderEngine/) (작성 예정)

## AI와 함께 일한 방식

> [docs/working-with-ai.md](docs/working-with-ai.md) (작성 예정)

## 다음 계획

- TestFlight 베타, App Store 출시
- iCloud 동기화와 백업

---

© 2026 skyun-ui. All rights reserved. 이 저장소는 사례 소개를 위해 공개하며, 코드의 사용 권한을 부여하지 않습니다.
