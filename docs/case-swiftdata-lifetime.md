# 사례: 같은 원인의 크래시를 세 번 — SwiftData 컨테이너 수명

## 첫 번째와 두 번째: 테스트
SwiftData 모델 테스트가 실패가 아니라 **크래시**로 끝났다. 테스트 실행기가 "예기치 않은 종료"로 재시작을 반복했다.

```swift
init() throws {
    let container = try ModelContainer(for: Routine.self, configurations: .init(isStoredInMemoryOnly: true))
    context = container.mainContext   // context만 보관
}                                     // ← 여기서 container가 해제된다
```

`ModelContext`만 붙잡고 `ModelContainer`는 지역 변수로 두었다. 초기화가 끝나면 컨테이너가 해제되고, 그 context로 할 일을 넣는 순간 크래시가 났다. 컨테이너를 테스트의 프로퍼티로 보관해서 해결했다.

얼마 뒤 데이터 이전 테스트를 쓰면서 **같은 실수를 또 했다.** `try container(at: url).mainContext`처럼 컨테이너를 만들자마자 버리고 context만 썼다.

## 세 번째: 실제 기기의 위젯
위젯을 홈 화면에 올리자 내용 대신 회색·주황색 네모만 보였다. iOS가 위젯 내용을 만들지 못했을 때 보여 주는 자리표시 화면이다.

- 원인을 찾으려고 기기의 크래시 로그를 가져왔다(`xcrun devicectl device copy from --domain-type systemCrashLogs`).
- 위젯 확장이 계속 죽고 있었고, 스택은 같은 지점을 가리켰다.

```
SwiftData  _assertionFailure
work1WidgetExtension  Routine.lastCompletedAt.getter
work1WidgetExtension  Routine.nextDueDate.getter
work1WidgetExtension  DueProvider.entries(for:)
```

위젯의 데이터 로딩 함수가 컨테이너를 지역 변수로 열고 `Routine` 객체 배열만 돌려줬다. 함수가 끝나 컨테이너가 해제된 뒤, 위젯 화면을 만들며 `lastCompletedAt`을 읽는 순간 크래시였다.

## 해결: 경계 밖으로는 값만 내보낸다
세 번째에서 규칙으로 정리했다.

> **컨테이너가 살아 있는 범위 밖으로 SwiftData 객체를 내보내지 않는다. 필요한 값만 복사해서 값 타입으로 내보낸다.**

```swift
/// 저장소에서 위젯에 필요한 값만 복사해 온다.
/// SwiftData 객체는 컨테이너가 해제된 뒤 속성을 읽으면 크래시가 난다.
@MainActor
private func loadSnapshots() -> [DueItem] {
    guard SharedStore.storeExists, let container = try? SharedStore.makeContainer() else { return [] }
    let routines = (try? container.mainContext.fetch(FetchDescriptor<Routine>())) ?? []
    return routines.compactMap(DueItem.init)   // 컨테이너가 살아 있을 때 값으로
}
```

이후 위젯 표시 순서 같은 로직도 값 타입(`DueItem`)을 기준으로 짜서, 앱 테스트에서 검증할 수 있게 됐다.

## 배운 점
- 같은 실수를 반복했다는 건 "주의하자"로는 부족하다는 뜻이다. 규칙을 문장으로 만들고, 코드 주석으로 이유를 남겨 다음에 그 코드를 보는 사람(나 포함)이 같은 길을 밟지 않게 했다.
- 위젯 같은 확장은 앱과 달리 디버거가 붙어 있지 않아 조용히 실패한다. 증상(자리표시 화면) → 기기 크래시 로그 → 스택이라는 경로를 익혀 두면 빨리 찾는다.
