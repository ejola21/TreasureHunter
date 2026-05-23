화면을 보니 iOS의 **UIPickerView with multiple components** (다중 컬럼 휠 피커) 패턴이네요. "DatePicker"가 아니라 정확한 용어는 **multi-column wheel picker** 또는 **cascade picker**입니다. 이 용어로 검색하면 훨씬 정확한 라이브러리들이 나옵니다.

## iOS

- **UIPickerView** (UIKit) — 정확히 화면 속 컨트롤. `numberOfComponents`로 컬럼 수, `numberOfRowsInComponent`로 각 컬럼의 행 지정. 컬럼 간 연동(첫 번째 선택에 따라 두 번째 옵션 바뀌게)도 직접 구현 가능.
- **SwiftUI** — 다중 컬럼 휠 전용 컴포넌트가 없어서 `HStack` 안에 `Picker(...).pickerStyle(.wheel)`을 여러 개 배치하는 방식이 표준 패턴. 복잡한 cascade가 필요하면 그냥 UIPickerView를 `UIViewRepresentable`로 감싸는 게 깔끔.

## Android

네이티브에 다중 컬럼 휠은 없어서 라이브러리가 사실상 정답입니다.

- **Android-PickerView** (Bigkoo/jeasonlzy 계열) — 중국권 사실상 표준. 1·2·3단 연동(linked options) 지원, iOS 룩과 가장 비슷. View 시스템용.
- **WheelPicker** (AigeStudio) — 단일 컬럼 휠, 여러 개를 가로로 배치해서 다중 컬럼 구성.
- **Jetpack Compose** — `wheel-picker-compose` (commandiron) 라이브러리가 다중 컬럼 지원. Compose 프로젝트면 이게 가장 깔끔.
- 옵션 데이터가 단순하면 `NumberPicker`를 가로로 3개 두는 것도 가능하지만 룩앤필이 화면과 다릅니다.

## 웹

Vue 2.7 쓰시니까 Vue 친화 옵션 위주로 정리합니다.

- **Vant 2.x Picker** ([youzan/vant](https://vant-contrib.gitee.io/vant/v2/#/en-US/picker)) — Vue 2 호환, 다중 컬럼·cascade 모두 지원, iOS 휠 룩에 가장 가깝고 문서도 잘 정리됨. **첫 번째 추천**.
- **NutUI Picker** — 비슷한 카테고리, JD 만든 모바일 컴포넌트
- **Mint UI Picker** — 과거에 많이 썼지만 유지보수 거의 멈춤, 신규는 비추
- **rmc-picker / react-mobile-picker** — React라면 이쪽
- **Framework7 Picker** — 다중 컬럼·연동 모두 풍부하게 지원, iOS 룩 완성도 최고
- **Ionic `ion-picker`** — `ion-datetime`과 다른 컴포넌트로, 컬럼 N개 지원하는 범용 휠 피커
- **Mobiscroll Scroller** — 상용이지만 cascade/3단 연동·접근성·반응형 모두 가장 매끄러움

연동 로직(예: Item에서 Quiz 선택하면 Display 옵션이 바뀌어야 하는 케이스)이 들어가면 Vant나 Mobiscroll처럼 `cascade` 옵션을 공식 지원하는 라이브러리가 손이 훨씬 덜 갑니다. 수동으로 짜야 하는 라이브러리는 watch 걸어서 컬럼 데이터 갈아끼우는 보일러플레이트가 꽤 생깁니다.

화면 캡처처럼 정확히 3분할이고 데이터가 정적이라면, Vue 2.7 + Vant Picker가 가장 빠른 길입니다. 안드로이드 네이티브와 통일감을 맞추려면 Android-PickerView를 같이 쓰시면 됩니다.




쓸 수 있습니다. SwiftUI는 UIKit과 완전히 호환되도록 `UIViewRepresentable` / `UIViewControllerRepresentable` 프로토콜을 제공해서, UIKit 컴포넌트를 SwiftUI View처럼 감싸서 쓸 수 있습니다.

UIPickerView 같은 경우는 `UIViewRepresentable`로 감싸는 게 표준 패턴입니다.

```swift
import SwiftUI
import UIKit

struct MultiColumnPicker: UIViewRepresentable {
    let columns: [[String]]              // 컬럼별 옵션 데이터
    @Binding var selections: [Int]       // 컬럼별 선택 인덱스

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        for (component, row) in selections.enumerated() {
            uiView.selectRow(row, inComponent: component, animated: false)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: MultiColumnPicker
        init(_ parent: MultiColumnPicker) { self.parent = parent }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            parent.columns.count
        }
        func pickerView(_ pickerView: UIPickerView,
                        numberOfRowsInComponent component: Int) -> Int {
            parent.columns[component].count
        }
        func pickerView(_ pickerView: UIPickerView,
                        titleForRow row: Int,
                        forComponent component: Int) -> String? {
            parent.columns[component][row]
        }
        func pickerView(_ pickerView: UIPickerView,
                        didSelectRow row: Int,
                        inComponent component: Int) {
            parent.selections[component] = row
        }
    }
}

// 사용
struct ContentView: View {
    @State private var selections = [0, 0, 0]
    let columns = [
        ["Hint", "Quiz", "Solution", "Gambling"],
        ["Normal", "Stealth", "hide map"],
        ["30", "40", "50"]
    ]

    var body: some View {
        MultiColumnPicker(columns: columns, selections: $selections)
            .frame(height: 200)
    }
}
```

## SwiftUI 네이티브 방식과 비교

SwiftUI만 쓸 때는 보통 `HStack`에 `Picker(...).pickerStyle(.wheel)`을 여러 개 늘어놓습니다.

```swift
HStack(spacing: 0) {
    Picker("", selection: $sel1) {
        ForEach(items.indices, id: \.self) { Text(items[$0]).tag($0) }
    }.pickerStyle(.wheel)

    Picker("", selection: $sel2) { ... }.pickerStyle(.wheel)
    Picker("", selection: $sel3) { ... }.pickerStyle(.wheel)
}
```

## 어떤 걸 선택할까

| 상황 | 추천 |
|---|---|
| 단순 다중 컬럼, 컬럼 간 연동 없음 | SwiftUI `HStack` + `Picker(.wheel)` |
| Cascade(컬럼 간 연동), 컬럼별 폭 다르게, 선택 행 하이라이트 커스텀 등 정교한 제어 필요 | `UIViewRepresentable`로 UIPickerView 래핑 |
| iOS 13 이전도 지원해야 함 | UIPickerView (SwiftUI wheel은 한동안 버그 많았음) |

실무에선 UIPickerView 래핑 방식이 디테일 제어가 훨씬 자유로워서, 화면 캡처처럼 컬럼 폭/폰트/구분선이 명확히 설계된 UI는 UIPickerView 쪽이 더 빠르게 원하는 모양을 잡습니다. 반대로 데이터만 보여주면 되는 간단한 케이스는 SwiftUI 순정이 코드가 훨씬 짧고요.


