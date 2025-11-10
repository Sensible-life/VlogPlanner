# API 키 설정 가이드

## 1. OpenAI API 키 발급받기

1. [OpenAI 플랫폼](https://platform.openai.com/)에 접속합니다
2. 로그인 후 [API Keys 페이지](https://platform.openai.com/api-keys)로 이동합니다
3. "Create new secret key" 버튼을 클릭합니다
4. 키 이름을 입력하고 생성합니다
5. 생성된 API 키를 복사합니다 (다시 볼 수 없으니 안전한 곳에 보관하세요!)

## 2. API 키 설정하기

### 방법 1: .env 파일 사용 (권장)

1. `assets/.env` 파일을 엽니다
2. `OPENAI_API_KEY=` 뒤에 발급받은 API 키를 붙여넣습니다

```env
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
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

## 3. API 키 확인하기

앱을 실행하고 사용자 입력을 완료한 후, 콘솔에서 다음 메시지를 확인하세요:

```
[OPENAI_API] API 키 확인됨: sk-proj-xx...
```

이 메시지가 보이면 API 키가 정상적으로 설정된 것입니다.

## 4. 문제 해결

### "API 키가 설정되지 않았습니다" 오류

- `.env` 파일이 `assets/` 폴더 안에 있는지 확인
- API 키가 `sk-`로 시작하는지 확인
- 앱을 완전히 종료하고 재시작

### API 호출 실패

- API 키가 유효한지 확인 (OpenAI 플랫폼에서 확인)
- OpenAI 계정에 크레딧이 있는지 확인
- 인터넷 연결 상태 확인

## 5. 비용 관리

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

## 6. 보안 주의사항

⚠️ **절대로 하지 말아야 할 것들:**
- API 키를 GitHub 등 공개 저장소에 커밋하지 마세요
- API 키를 다른 사람과 공유하지 마세요
- `.env` 파일은 `.gitignore`에 포함되어 있는지 확인하세요

✅ **권장사항:**
- API 키는 반드시 `.env` 파일에만 저장하세요
- 정기적으로 API 키를 재발급하세요
- 사용량 제한(Usage Limits)을 설정하세요

