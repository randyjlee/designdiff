# DesignDiff 배포 가이드

이 가이드는 DesignDiff 앱을 DMG 파일로 빌드하고 GitHub Releases를 통해 배포하는 방법을 설명합니다.

## 1. Sparkle Framework 추가 (자동 업데이트)

### Xcode에서 Sparkle 추가하기

1. **Xcode에서 프로젝트 열기**
   ```bash
   open DesignDiff/DesignDiff.xcodeproj
   ```

2. **Swift Package 추가**
   - `File` → `Add Package Dependencies...` 선택
   - 검색창에 입력: `https://github.com/sparkle-project/Sparkle`
   - Version: `2.5.0` 이상 선택
   - `Add Package` 클릭
   - Target `DesignDiff`에 `Sparkle` 체크하고 `Add Package` 클릭

3. **Info.plist 연결**
   - Project Navigator에서 `DesignDiff` 프로젝트 선택
   - `DesignDiff` 타겟 선택
   - `Build Settings` 탭
   - 검색: `Info.plist`
   - `Info.plist File` 값을 `DesignDiff/Info.plist`로 설정

4. **서명 설정**
   - `Signing & Capabilities` 탭
   - `Automatically manage signing` 체크
   - Team 선택

## 2. 업데이트 키 생성

Sparkle는 업데이트의 보안을 위해 EdDSA 서명을 사용합니다.

```bash
# Sparkle의 generate_keys 도구 다운로드
cd scripts
curl -L -o generate_keys https://github.com/sparkle-project/Sparkle/releases/latest/download/generate_keys
chmod +x generate_keys

# 키 생성
./generate_keys
```

**중요:** 생성된 키를 안전하게 보관하세요!
- `공개키`를 `Info.plist`의 `SUPublicEDKey`에 입력
- `비밀키`는 GitHub Secrets에 저장 (절대 공개하지 마세요!)

## 3. Info.plist 설정 업데이트

`DesignDiff/DesignDiff/Info.plist` 파일 수정:

```xml
<key>SUFeedURL</key>
<string>https://github.com/YOUR_USERNAME/design_diff_macapp/releases/latest/download/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
```

- `YOUR_USERNAME`: GitHub 사용자명으로 변경
- `YOUR_PUBLIC_KEY_HERE`: 생성한 공개키로 변경

## 4. 버전 업데이트

릴리스 전 버전 번호를 업데이트하세요:

1. Xcode에서 프로젝트 선택
2. `DesignDiff` 타겟 선택
3. `General` 탭
4. `Version`: `1.0.0` (마케팅 버전)
5. `Build`: `1` (빌드 번호)

또는 `Info.plist`에서 직접 수정:
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

## 5. DMG 빌드

```bash
# 프로젝트 루트에서 실행
./scripts/create-dmg.sh
```

빌드가 완료되면 `build/DesignDiff-1.0.0.dmg` 파일이 생성됩니다.

## 6. GitHub Release 생성

### 수동 릴리스

1. **GitHub 저장소로 이동**
2. **Releases** 탭 클릭
3. **Draft a new release** 클릭
4. **Tag version**: `v1.0.0` 입력
5. **Release title**: `DesignDiff 1.0.0` 입력
6. **Release notes** 작성:

```markdown
## 🎉 DesignDiff 1.0.0

### 새로운 기능
- 🖼️ Before/After 이미지 비교
- 🤖 AI 기반 디자인 변경 분석
- 📝 드래그 가능한 주석 시스템
- 💾 PNG 내보내기 (주석 및 변경 사항 포함)
- 📋 Slack/Linear 포맷 지원
- 🔄 자동 업데이트

### 설치 방법
1. DMG 파일 다운로드
2. DMG 열기
3. DesignDiff.app을 Applications 폴더로 드래그
4. 실행!

### 시스템 요구사항
- macOS 13.0 이상
```

7. **DMG 파일 업로드**: `build/DesignDiff-1.0.0.dmg` 드래그 앤 드롭
8. **Appcast 파일 업로드** (있는 경우): `build/appcast.xml`
9. **Publish release** 클릭

### 자동 릴리스 (GitHub Actions)

`.github/workflows/release.yml` 생성:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build DMG
      run: ./scripts/create-dmg.sh
      
    - name: Create Release
      uses: softprops/action-gh-release@v1
      with:
        files: |
          build/*.dmg
          build/appcast.xml
        body_path: CHANGELOG.md
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 7. Appcast 생성

Sparkle의 `generate_appcast` 도구 사용:

```bash
# Sparkle 도구 다운로드
cd scripts
curl -L -o generate_appcast https://github.com/sparkle-project/Sparkle/releases/latest/download/generate_appcast
chmod +x generate_appcast

# Appcast 생성
./generate_appcast ../build
```

생성된 `appcast.xml`을 GitHub Release에 업로드하세요.

## 8. 테스트

1. **DMG 다운로드 및 설치**
   - GitHub Releases에서 DMG 다운로드
   - DMG 열고 Applications로 드래그
   - 앱 실행

2. **자동 업데이트 테스트**
   - 버전을 높여서 새 릴리스 생성
   - 앱 실행 → "Check for Updates..." 클릭
   - 업데이트가 감지되고 설치되는지 확인

## 9. 웹사이트 배포

웹사이트에 다운로드 링크 추가:

```html
<a href="https://github.com/YOUR_USERNAME/design_diff_macapp/releases/latest/download/DesignDiff-1.0.0.dmg">
  Download DesignDiff for Mac
</a>
```

또는 최신 버전 자동 링크:

```html
<a href="https://github.com/YOUR_USERNAME/design_diff_macapp/releases/latest">
  Download Latest Version
</a>
```

## 문제 해결

### "DesignDiff.app is damaged and can't be opened"
사용자에게 다음 명령어 실행 안내:
```bash
xattr -cr /Applications/DesignDiff.app
```

### Notarization (공증)
앱스토어 외부 배포 시 Apple 공증이 권장됩니다:

```bash
# 1. 아카이브 생성
xcodebuild archive -scheme DesignDiff -archivePath build/DesignDiff.xcarchive

# 2. 공증용 내보내기
xcodebuild -exportArchive -archivePath build/DesignDiff.xcarchive \
  -exportPath build -exportOptionsPlist scripts/ExportOptions.plist

# 3. 공증 제출
xcrun notarytool submit build/DesignDiff.zip \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID"

# 4. 스테이플링
xcrun stapler staple build/DesignDiff.app
```

## 버전 관리 전략

- **Patch (1.0.x)**: 버그 수정
- **Minor (1.x.0)**: 새로운 기능
- **Major (x.0.0)**: 큰 변경 사항

각 릴리스에는 태그를 생성하세요:
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

---

## 체크리스트

릴리스 전 확인사항:

- [ ] Sparkle Framework 추가됨
- [ ] Info.plist 설정 완료
- [ ] 업데이트 키 생성 및 설정
- [ ] 버전 번호 업데이트
- [ ] 앱 아이콘 설정
- [ ] DMG 빌드 성공
- [ ] 로컬에서 앱 테스트
- [ ] GitHub Release 생성
- [ ] Appcast 업로드
- [ ] 다운로드 링크 테스트
- [ ] 자동 업데이트 테스트

