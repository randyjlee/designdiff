# App Store 심사 체크리스트

## ⚠️ 긴급 수정 필요

### 1. OpenAI API 키 보안 문제 (🔴 필수)
**문제**: `OpenAIService.swift`에 API 키가 하드코딩되어 있습니다.
```swift
private let apiKey = "sk-proj-JDFzW93bYyBRaLWPY..."
```

**해결 방법**:
- **옵션 A (권장)**: 서버 사이드 API 구축
  - 백엔드 서버를 만들어서 OpenAI API를 호출
  - 앱은 백엔드 API를 호출
  - API 키는 서버에서 안전하게 관리

- **옵션 B**: 사용자가 직접 API 키 입력
  - Settings에서 사용자가 자신의 OpenAI API 키 입력
  - 키는 Keychain에 안전하게 저장
  - 기존 SettingsView 복구 필요

**앱스토어 리젝 가능성**: 매우 높음 (보안 및 가이드라인 위반)

---

## 📋 필수 항목

### 2. 앱 아이콘 (🔴 필수)
- [ ] 1024x1024 앱 아이콘 제작
- [ ] 모든 사이즈 아이콘 추가 (16x16 ~ 512x512 @1x, @2x)
- 위치: `DesignDiff/Assets.xcassets/AppIcon.appiconset/`

### 3. Privacy Policy (🔴 필수)
- [ ] Privacy Policy 웹페이지 작성
- [ ] URL을 App Store Connect에 입력
- 포함 내용:
  - OpenAI API를 통한 이미지 전송
  - 데이터 처리 방식
  - 데이터 보관 정책

### 4. 네트워크 사용 설명 (🔴 필수)
Info.plist에 추가 필요:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

### 5. 앱 스크린샷 (🔴 필수)
App Store Connect에 업로드 필요:
- [ ] 1280x800 또는 2880x1800 스크린샷 최소 1장
- [ ] 권장: 3-5장 (업로드, 분석, 결과, 편집, 내보내기 화면)

---

## 📝 App Store Connect 정보

### 앱 정보
- **Bundle ID**: `com.designdiff.app`
- **Version**: 1.0
- **Build**: 1

### 작성 필요 항목
- [ ] 앱 이름
- [ ] 부제목 (선택)
- [ ] 앱 설명
- [ ] 키워드
- [ ] 지원 URL
- [ ] 마케팅 URL (선택)
- [ ] Privacy Policy URL
- [ ] 카테고리 (제안: Developer Tools, Graphics & Design)

### 앱 설명 예시
```
DesignDiff는 디자이너와 개발자 간의 원활한 협업을 위한 AI 기반 비주얼 디자인 비교 도구입니다.

주요 기능:
• AI 기반 변경사항 자동 감지 (GPT-4o)
• 대화형 주석 편집 (드래그, 추가, 삭제)
• Slack 및 Linear용 포맷 자동 생성
• 픽셀 단위 정확한 비교 이미지 생성
• 아름다운 네이티브 macOS 경험

사용 방법:
1. Before/After 이미지를 드래그 앤 드롭
2. "분석" 버튼 클릭으로 AI 분석 시작
3. 주석 위치 조정 및 설명 편집
4. Slack, Linear, PNG로 결과 공유

디자인 변경사항을 명확하게 전달하고, 팀 커뮤니케이션을 개선하세요.
```

---

## 🔧 빌드 및 제출

### Archive 생성
```bash
cd /Users/randy/project/design_diff_macapp/DesignDiff
xcodebuild archive \
  -project DesignDiff.xcodeproj \
  -scheme DesignDiff \
  -archivePath ./build/DesignDiff.xcarchive
```

### App Store 제출
1. Xcode에서 Product > Archive
2. Organizer에서 "Distribute App" 클릭
3. "App Store Connect" 선택
4. "Upload" 선택
5. 자동 서명 또는 수동 서명 선택
6. 제출

---

## ⚠️ 심사 거부 가능성 높은 항목

1. **API 키 하드코딩** (🔴 최우선 수정)
   - 리젝 사유: 보안 위반, 가이드라인 2.5.2
   
2. **개인정보 처리방침 누락**
   - 리젝 사유: 가이드라인 5.1.1

3. **네트워크 사용 설명 누락**
   - 리젝 사유: 가이드라인 5.1.2

4. **앱 아이콘 누락**
   - 리젝 사유: 기본 요구사항 미충족

---

## ✅ 완료된 항목

- [x] README.md 업데이트
- [x] 코드 정리 및 빌드 확인
- [x] Git commit & push
- [x] 버전 정보 설정 (1.0, Build 1)

---

## 📞 다음 단계

1. **즉시**: OpenAI API 키 보안 문제 해결
2. 앱 아이콘 제작 및 추가
3. Privacy Policy 작성
4. 스크린샷 준비
5. App Store Connect 계정 준비 및 앱 등록
6. Archive 생성 및 업로드
7. 심사 제출

---

## 💡 추가 권장사항

- [ ] 앱 버전 관리: 1.0 → 1.0.0 형식 고려
- [ ] 릴리즈 노트 준비
- [ ] 테스트플라이트 베타 테스트 고려
- [ ] 지역화(한국어/영어) 고려
- [ ] macOS 최소 버전 확인 (현재: 14.0)





