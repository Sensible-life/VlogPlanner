# API 키 설정 가이드

## 1. 필수 API 키

### OpenAI API 키 (필수)

1. [OpenAI 플랫폼](https://platform.openai.com/)에 접속합니다
2. 로그인 후 [API Keys 페이지](https://platform.openai.com/api-keys)로 이동합니다
3. "Create new secret key" 버튼을 클릭합니다
4. 키 이름을 입력하고 생성합니다
5. 생성된 API 키를 복사합니다 (다시 볼 수 없으니 안전한 곳에 보관하세요!)

## 2. 선택적 API 키

### YouTube Data API v3 키 (선택사항)

**용도**: 각 씬의 레퍼런스 영상을 YouTube에서 자동으로 검색

1. [Google Cloud Console](https://console.cloud.google.com/)에 접속합니다
2. 새 프로젝트를 만들거나 기존 프로젝트를 선택합니다
3. [API 라이브러리](https://console.cloud.google.com/apis/library)로 이동합니다
4. "YouTube Data API v3"를 검색하고 활성화합니다
5. [API 및 서비스 > 사용자 인증 정보](https://console.cloud.google.com/apis/credentials)로 이동합니다
6. "사용자 인증 정보 만들기" > "API 키"를 선택합니다
7. 생성된 API 키를 복사합니다

**참고**: YouTube API 키가 없으면 레퍼런스 영상 검색이 건너뛰어지며, 앱의 다른 기능은 정상 작동합니다.

## 3. API 키 설정하기

### 방법 1: .env 파일 사용 (권장)

1. `assets/.env` 파일을 엽니다
2. 발급받은 API 키들을 입력합니다

```env
# 필수
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 선택사항 (있으면 추가)
YOUTUBE_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

3. 앱을 재시작합니다

### 방법 2: 코드에서 직접 설정 (테스트용)

`lib/main.dart` 파일에서 다음과 같이 설정할 수 있습니다:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // API 키 직접 설정 (테스트용)
  ApiConfig.setApiKey('sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
  
  runApp(const MyApp());
}
```

⚠️ **주의**: 방법 2는 테스트용으로만 사용하고, 실제 배포 시에는 .env 파일을 사용하세요!

## 4. API 키 확인하기

앱을 실행하고 사용자 입력을 완료한 후, 콘솔에서 다음 메시지들을 확인하세요:

**OpenAI API:**
```
[OPENAI_API] API 키 확인됨: sk-proj-xx...
```

**YouTube API (선택사항):**
```
[YOUTUBE_API] 검색 쿼리: 워밍업 스트레칭 브이로그
[YOUTUBE_API] ✅ 레퍼런스 영상 찾음: 10분 전신 스트레칭...
```

YouTube API 키가 없으면:
```
[YOUTUBE_API] ⚠️ YouTube API 키가 설정되지 않았습니다.
[YOUTUBE_API] API 키가 없어 검색을 건너뜁니다.
```

## 5. 문제 해결

### "API 키가 설정되지 않았습니다" 오류

- `.env` 파일이 `assets/` 폴더 안에 있는지 확인
- API 키가 `sk-`로 시작하는지 확인
- 앱을 완전히 종료하고 재시작

### API 호출 실패

- API 키가 유효한지 확인 (OpenAI 플랫폼에서 확인)
- OpenAI 계정에 크레딧이 있는지 확인
- 인터넷 연결 상태 확인

## 6. 비용 관리

OpenAI API는 사용량에 따라 비용이 발생합니다:

### 현재 사용 모델: GPT-3.5 Turbo
- **입력**: $0.0005 / 1K tokens
- **출력**: $0.0015 / 1K tokens
- **한 번의 브이로그 계획 생성**: 약 $0.01~$0.05 예상

### 비용 비교
| 모델 | 입력 | 출력 | 예상 비용/회 |
|------|------|------|-------------|
| GPT-3.5 Turbo | $0.0005 | $0.0015 | $0.01~$0.05 |
| GPT-4 | $0.03 | $0.06 | $0.5~$1.0 |

💡 **GPT-3.5 Turbo를 사용하여 약 20배 저렴**합니다!

[OpenAI 사용량 대시보드](https://platform.openai.com/usage)에서 사용량을 확인할 수 있습니다.

### YouTube Data API 비용

YouTube Data API v3는 **할당량 기반**입니다:
- **일일 무료 할당량**: 10,000 units
- **검색 1회**: 100 units
- **약 100회 검색/일 무료**

한 번의 스토리보드 생성(10개 씬)에 약 1,000 units (10회 검색) 사용하므로, **하루에 약 10개의 스토리보드**를 무료로 생성할 수 있습니다.

## 7. 보안 주의사항

⚠️ **절대로 하지 말아야 할 것들:**
- API 키를 GitHub 등 공개 저장소에 커밋하지 마세요
- API 키를 다른 사람과 공유하지 마세요
- `.env` 파일은 `.gitignore`에 포함되어 있는지 확인하세요

✅ **권장사항:**
- API 키는 반드시 `.env` 파일에만 저장하세요
- 정기적으로 API 키를 재발급하세요
- 사용량 제한(Usage Limits)을 설정하세요

