# API 키 설정 가이드

이 문서는 앱에서 사용하는 외부 API 서비스들의 키를 설정하는 방법을 안내합니다.

---

## 📋 목차

1. [OpenAI API (필수)](#1-openai-api-필수)
2. [Google Custom Search API (이미지)](#2-google-custom-search-api-이미지)
3. [Unsplash API (이미지 대체)](#3-unsplash-api-이미지-대체)
4. [Pexels API (이미지 대체)](#4-pexels-api-이미지-대체)
5. [OpenWeather API (날씨)](#5-openweather-api-날씨)
6. [Naver Local API (예산, 선택)](#6-naver-local-api-예산-선택)

---

## 1. OpenAI API (필수)

### 가입 및 키 발급

1. [OpenAI Platform](https://platform.openai.com/) 접속
2. 계정 생성 또는 로그인
3. [API Keys](https://platform.openai.com/api-keys) 페이지 이동
4. "Create new secret key" 클릭
5. 생성된 키 복사 (다시 볼 수 없으니 안전하게 보관!)

### 앱에 적용

`assets/.env` 파일에 추가:
```
OPENAI_API_KEY=sk-proj-...your-key-here...
```

### 비용

- GPT-4o: $2.50 / 1M input tokens, $10 / 1M output tokens
- Fine-tuned model: 약간 더 비쌈
- **스토리보드 1회 생성**: 약 $0.10 - $0.15

---

## 2. Google Custom Search API (이미지)

### 가입 및 키 발급

**Step 1: Google Cloud Console에서 API 키 발급**

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 생성 또는 기존 프로젝트 선택
3. "API 및 서비스" → "라이브러리" 이동
4. "Custom Search API" 검색 후 활성화
5. "API 및 서비스" → "사용자 인증 정보" 이동
6. "사용자 인증 정보 만들기" → "API 키" 클릭
7. 생성된 API 키 복사

**Step 2: Programmable Search Engine 생성**

1. [Programmable Search Engine](https://programmablesearchengine.google.com/) 접속
2. "시작하기" 또는 "새 검색 엔진 추가" 클릭
3. 검색 설정:
   - **검색할 사이트**: "전체 웹 검색" 선택
   - **이미지 검색**: "이미지 검색 사용" 활성화
   - **검색 엔진 이름**: 원하는 이름 입력 (예: "Vlog Image Search")
4. "만들기" 클릭
5. 생성된 검색 엔진 클릭 → "기본 사항"에서 **검색 엔진 ID** 복사

### 앱에 적용

`assets/.env` 파일에 추가:
```
GOOGLE_CUSTOM_SEARCH_API_KEY=your-api-key-here
GOOGLE_CUSTOM_SEARCH_ENGINE_ID=your-search-engine-id-here
```

### 무료 플랜 제한

- **100 검색 쿼리 / 일** (무료)
- 추가 사용: $5 / 1,000 쿼리
- 스토리보드 1회 생성: 최대 10-12 쿼리 사용
- **권장**: 무료 할당량 내에서 하루 최대 8-10개 스토리보드 생성 가능

### 장점

- ✅ 실제 장소 이미지 검색 (예: "사그라다 파밀리아", "에펠탑")
- ✅ GPT-4 기반 최적화된 검색 키워드 생성
- ✅ Unsplash/Pexels보다 정확한 이미지 매칭
- ✅ 자동 Fallback (API 미설정 시 Unsplash/Pexels 사용)

---

## 3. Unsplash API (이미지 대체)

### 가입 및 키 발급

1. [Unsplash Developers](https://unsplash.com/developers) 접속
2. 계정 생성 또는 로그인
3. "Your apps" → "New Application" 클릭
4. 약관 동의 후 앱 이름 입력
5. Access Key 복사

### 앱에 적용

`lib/services/image_service.dart` 파일 수정:
```dart
static const String _unsplashAccessKey = 'YOUR_KEY_HERE';  // ← 여기에 붙여넣기
```

### 무료 플랜 제한

- 50 requests / hour
- 충분히 사용 가능 (스토리보드 1회 = 최대 10-12 requests)

---

## 4. Pexels API (이미지 대체)

Unsplash가 실패할 경우 자동으로 사용됩니다 (Fallback).

### 가입 및 키 발급

1. [Pexels API](https://www.pexels.com/api/) 접속
2. 계정 생성 또는 로그인
3. API Key 복사

### 앱에 적용

`lib/services/image_service.dart` 파일 수정:
```dart
static const String _pexelsApiKey = 'YOUR_KEY_HERE';  // ← 여기에 붙여넣기
```

### 무료 플랜 제한

- 200 requests / hour
- 무제한 사용 가능

---

## 5. OpenWeather API (날씨)

### 가입 및 키 발급

1. [OpenWeatherMap](https://openweathermap.org/api) 접속
2. 계정 생성 또는 로그인
3. [API Keys](https://home.openweathermap.org/api_keys) 페이지 이동
4. "Create Key" 클릭 (또는 기본 키 사용)
5. API Key 복사

**중요**: 새로 생성한 키는 활성화까지 최대 2시간 소요될 수 있습니다.

### 앱에 적용

`lib/services/weather_service.dart` 파일 수정:
```dart
static const String _apiKey = 'YOUR_KEY_HERE';  // ← 여기에 붙여넣기
```

### 무료 플랜 제한

- 60 calls / minute
- 1,000,000 calls / month
- 충분히 사용 가능 (스토리보드 1회 = 1 call)

---

## 6. Naver Local API (예산, 선택)

현재 구현은 **Mock 데이터**를 사용하므로 선택 사항입니다.
실제 가격 정보가 필요하면 설정하세요.

### 가입 및 키 발급

1. [Naver Developers](https://developers.naver.com/main/) 접속
2. 계정 생성 또는 로그인
3. "Application" → "애플리케이션 등록" 클릭
4. 앱 정보 입력 (이름, 사용 API 등)
5. "검색" API 선택
6. Client ID 및 Client Secret 복사

### 앱에 적용

`lib/services/budget_service.dart` 파일 수정:
```dart
static const String _naverClientId = 'YOUR_CLIENT_ID';  // ← 여기에 붙여넣기
static const String _naverClientSecret = 'YOUR_CLIENT_SECRET';  // ← 여기에 붙여넣기
```

### 무료 플랜 제한

- 25,000 calls / day
- 충분히 사용 가능

---

## ⚙️ 설정 확인

API 키를 설정한 후, 다음 순서로 확인하세요:

1. **OpenAI API** (필수)
   - 스토리보드 생성이 작동하는지 확인

2. **Google Custom Search API** (권장)
   - 실제 장소 이미지가 로드되는지 확인
   - 실패 시 Unsplash/Pexels로 자동 전환

3. **Unsplash API** (권장)
   - 이미지가 로드되는지 확인
   - Google Custom Search 미설정 시 사용

4. **Pexels API** (선택)
   - Unsplash 실패 시 자동 전환

5. **OpenWeather API** (선택)
   - 날씨 정보가 표시되는지 확인
   - 없으면 Mock 데이터 사용

6. **Naver Local API** (선택)
   - 예산 정보가 정확한지 확인
   - 없으면 추정값 사용

---

## 🔒 보안 주의사항

1. **.env 파일을 절대 Git에 커밋하지 마세요!**
   - `.gitignore`에 이미 추가되어 있습니다

2. **API 키를 공개 저장소에 올리지 마세요!**

3. **API 키가 노출되면 즉시 재발급하세요!**

---

## 💰 예상 비용 (월간)

스토리보드 100회 생성 기준:

| API | 월간 비용 | 무료 플랜 |
|-----|-----------|-----------|
| OpenAI | $10 - $15 | ❌ 유료 |
| Google Custom Search | $0 (무료 100쿼리/일 이내) | ✅ 무료* |
| Unsplash | $0 | ✅ 무료 |
| Pexels | $0 | ✅ 무료 |
| OpenWeather | $0 | ✅ 무료 |
| Naver Local | $0 | ✅ 무료 |
| **총계** | **$10 - $15** | |

\* Google Custom Search: 무료 할당량(100쿼리/일) 초과 시 추가 비용 발생

---

## ❓ 문제 해결

### "API key not set" 오류
→ `.env` 파일 또는 서비스 파일에 키가 제대로 입력되었는지 확인

### "401 Unauthorized" 오류
→ API 키가 잘못되었거나 만료됨. 재발급 필요

### "429 Too Many Requests" 오류
→ Rate limit 초과. 잠시 후 재시도

### Google Custom Search 이미지가 안 나옴
→ API 키와 Search Engine ID가 정확한지 확인
→ Custom Search API가 Google Cloud Console에서 활성화되었는지 확인
→ 무료 할당량(100쿼리/일) 초과 여부 확인
→ 자동으로 Unsplash/Pexels로 Fallback 됨

### Unsplash 이미지가 안 나옴
→ Pexels로 자동 전환됨. 또는 플레이스홀더 이미지 사용

### OpenWeather 키가 작동 안 함
→ 새 키는 활성화까지 최대 2시간 소요

---

## 📞 지원

API 관련 문제는 각 서비스의 공식 문서를 참조하세요:

- [OpenAI Docs](https://platform.openai.com/docs)
- [Google Custom Search API Docs](https://developers.google.com/custom-search/v1/overview)
- [Programmable Search Engine Guide](https://programmablesearchengine.google.com/about/)
- [Unsplash API Docs](https://unsplash.com/documentation)
- [Pexels API Docs](https://www.pexels.com/api/documentation/)
- [OpenWeather API Docs](https://openweathermap.org/api)
- [Naver API Docs](https://developers.naver.com/docs/common/openapiguide/)
