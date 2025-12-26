# Design Diff OAuth Server Setup

## 1. Figma App 등록

1. [Figma Developers](https://www.figma.com/developers/apps) 접속
2. **"Create new app"** 클릭
3. 앱 정보 입력:
   - **App name**: Design Diff
   - **Website URL**: https://your-vercel-app.vercel.app
   - **Callback URL**: https://your-vercel-app.vercel.app/api/callback
4. **Client ID**와 **Client Secret** 복사

## 2. Vercel 배포

```bash
cd oauth-server

# Vercel CLI 설치 (없으면)
npm i -g vercel

# 로그인
vercel login

# 배포
vercel

# 환경변수 설정
vercel env add FIGMA_CLIENT_ID
vercel env add FIGMA_CLIENT_SECRET

# 프로덕션 배포
vercel --prod
```

## 3. Figma App Callback URL 업데이트

배포된 URL로 Figma App의 Callback URL 업데이트:
```
https://your-app-name.vercel.app/api/callback
```

## 4. 사용

1. 브라우저에서 `https://your-app-name.vercel.app` 접속
2. Figma 계정으로 로그인 & 승인
3. 발급된 토큰을 Design Diff 플러그인에 입력

## 환경변수

| 변수명 | 설명 |
|--------|------|
| `FIGMA_CLIENT_ID` | Figma App Client ID |
| `FIGMA_CLIENT_SECRET` | Figma App Client Secret |
| `REDIRECT_URI` | (선택) 콜백 URL, 기본값: 자동 감지 |

