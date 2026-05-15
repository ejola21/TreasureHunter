Xcode 프로젝트는 `project.pbxproj`라는 "숨은 상태"가 너무 많아서 텍스트 편집 위주의 Claude Code와 궁합이 별로입니다. 그래서 핵심 전략은 **"pbxproj를 사람도 AI도 건드리지 않게 만드는 것"** 입니다. 우선순위대로 정리해드릴게요.

## 1순위: 프로젝트 파일을 선언적으로 관리 (XcodeGen 또는 Tuist)

이것 하나가 게임 체인저입니다. `project.pbxproj`를 직접 다루는 대신 YAML(XcodeGen) 또는 Swift DSL(Tuist)로 정의하고, `xcodegen generate` 한 번이면 `.xcodeproj`가 재생성됩니다.

**XcodeGen 예시 (`project.yml`):**
```yaml
name: MyApp
targets:
  MyApp:
    type: application
    platform: iOS
    deploymentTarget: "16.0"
    sources:
      - path: Sources
      - path: Resources
        type: folder   # 폴더 통째로 → 새 파일 자동 포함
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.myapp
```

Claude Code는 파일 추가/삭제만 하면 끝, `xcodegen generate`로 프로젝트 재빌드. `.xcodeproj`는 `.gitignore`에 넣어버립니다. 이전 메시지의 이미지 문제도 자동 해결됩니다.

규모가 커지면 Tuist로 가는 게 좋습니다(모듈 그래프, 캐싱, 워크스페이스 관리).

## 2순위: SPM 로컬 패키지로 모듈화

기능별로 로컬 Swift Package(`Packages/Feature/...`)로 쪼개면, 각 패키지는 `Package.swift` 텍스트 파일 하나로 완전히 기술됩니다. Claude Code가 이 안에서 작업하면 pbxproj 자체를 건드릴 일이 없습니다.

```
MyApp/
  App/                  # 얇은 앱 진입점만
  Packages/
    Networking/Package.swift
    AuthFeature/Package.swift
    DesignSystem/Package.swift   # 이미지/색상 리소스도 여기
```

리소스는 `.process("Resources")`로 패키지 안에 넣고 `Bundle.module`로 접근. 이미지 로딩 문제가 구조적으로 사라집니다.

## 3순위: XcodeBuildMCP 서버 연결

Claude Code가 직접 빌드/실행/로그 확인을 할 수 있게 해주는 MCP 서버입니다. 이게 없으면 Claude Code는 "수정했어요" 하고 끝내는데, 있으면 빌드 에러 보고 자기가 고칩니다.

```bash
npm install -g xcodebuildmcp
```

`.mcp.json`에 등록하면 `build`, `test`, `run on simulator`, `screenshot`, `get logs` 같은 도구를 Claude Code가 알아서 호출합니다. 검증 루프가 닫혀서 디버깅 시간이 극적으로 줄어듭니다.

## 4순위: CLAUDE.md에 빌드/검증 규칙 박아두기

```markdown
# Build & Verify
- 코드 수정 후 항상 다음을 실행하고 결과를 보고:
  `xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' build`
- 이미지/리소스는 반드시 Assets.xcassets 또는 SPM 패키지의 Resources에만 추가
- 파일 추가/삭제 후 반드시 `xcodegen generate` 실행
- UI 변경 후 시뮬레이터 스크린샷 캡처:
  `xcrun simctl io booted screenshot /tmp/shot.png`
- print 문 추가 금지. os_log 또는 Logger 사용

# Project Conventions
- SwiftUI 우선, UIKit은 필요시에만
- 의존성 주입은 생성자 주입
- 비동기는 async/await, Combine 신규 사용 금지
```

CLAUDE.md는 Claude Code의 시스템 프롬프트처럼 작동해서 매 세션마다 일관성이 유지됩니다.

## 5순위: 시뮬레이터 자동화로 검증 루프 닫기

Claude Code가 UI를 만들면 결과를 확인할 방법이 필요합니다.

```bash
# 시뮬레이터 부팅 → 빌드 → 설치 → 실행 → 스크린샷
xcrun simctl boot "iPhone 15"
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' \
  -derivedDataPath ./build build
xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/MyApp.app
xcrun simctl launch booted com.example.myapp
sleep 2
xcrun simctl io booted screenshot /tmp/shot.png
```

이걸 `scripts/verify.sh`로 만들어두면 Claude Code가 호출하고, MCP가 연결돼 있으면 스크린샷까지 직접 봅니다.

## 6순위: 정적 분석 & 포맷팅 자동화

- **SwiftLint** + **SwiftFormat**을 pre-commit이나 빌드 페이즈에 박아두면 Claude Code 출력 품질이 평탄해집니다.
- **Periphery**로 unused code 검출 — Claude Code가 가끔 죽은 코드 남깁니다.

## 실전 워크플로우 추천 조합

20년 경력에 솔로 개발이시니까 너무 무겁지 않게 가는 게 좋겠습니다:

1. **XcodeGen** (Tuist는 솔로엔 오버킬)
2. **로컬 SPM 패키지**로 feature 분리
3. **XcodeBuildMCP** 연결
4. **CLAUDE.md** + `scripts/verify.sh`
5. **SwiftLint** 가볍게

