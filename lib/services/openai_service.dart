import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../constants/prompts.dart';
import '../models/cue_template.dart';
import '../models/cue_card.dart';
import 'template_matching_service.dart';
import 'vlog_data_service.dart'; // Plan도 export됨
import 'progress_notification_service.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-3.5-turbo';
  // Updated fine-tuned model (59 templates, trained on 2025-11-20)
  static const String _fineTunedModel = 'ft:gpt-4o-2024-08-06:ael-kaist:vlog-template-v1:CdoLdEtq';
  
  // Fine-tuned models 목록 조회 (최신 모델 확인용)
  static Future<List<Map<String, dynamic>>> listFineTunedModels() async {
    if (!ApiConfig.isApiKeySet) {
      throw Exception('OpenAI API 키가 설정되지 않았습니다.');
    }
    
    try {
      final response = await http.get(
        Uri.parse('https://api.openai.com/v1/fine_tuning/jobs'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobs = data['data'] as List<dynamic>;
        
        // 완료된 fine-tuning job만 필터링하고 정렬
        final completedJobs = jobs
            .where((job) => job['status'] == 'succeeded')
            .map((job) => {
                  'id': job['fine_tuned_model'],
                  'created_at': job['created_at'],
                  'finished_at': job['finished_at'],
                  'training_file': job['training_file'],
                  'hyperparameters': job['hyperparameters'],
                })
            .toList();
        
        // 최신순으로 정렬
        completedJobs.sort((a, b) {
          final aTime = a['finished_at'] ?? a['created_at'] ?? 0;
          final bTime = b['finished_at'] ?? b['created_at'] ?? 0;
          return bTime.compareTo(aTime);
        });
        
        return completedJobs.cast<Map<String, dynamic>>();
      } else {
        print('[OPENAI_API] Fine-tuned models 조회 실패: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('[OPENAI_API] Fine-tuned models 조회 오류: $e');
      return [];
    }
  }
  
  // 현재 사용 중인 모델이 최신인지 확인
  static Future<Map<String, dynamic>> checkCurrentModel() async {
    final models = await listFineTunedModels();
    
    if (models.isEmpty) {
      return {
        'current': _fineTunedModel,
        'isLatest': false,
        'latest': null,
        'message': 'Fine-tuned models를 조회할 수 없습니다.',
      };
    }
    
    final latestModel = models.first;
    final isLatest = latestModel['id'] == _fineTunedModel;
    
    return {
      'current': _fineTunedModel,
      'isLatest': isLatest,
      'latest': latestModel,
      'allModels': models,
      'message': isLatest
          ? '현재 사용 중인 모델이 최신입니다.'
          : '더 최신 모델이 있습니다: ${latestModel['id']}',
    };
  }
  
  static Future<String?> generateResponse(String prompt) async {
    if (!ApiConfig.isApiKeySet) {
      print('[OPENAI_API] API 키가 설정되지 않음');
      throw Exception('OpenAI API 키가 설정되지 않았습니다.');
    }
    
    print('[OPENAI_API] API 키 확인됨: ${ApiConfig.apiKey?.substring(0, 10)}...');
    
    try {
      print('[OPENAI_API] HTTP 요청 시작...');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that generates v-log cue cards for theme park beginners. Always respond in Korean for user-facing content.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 4000, // GPT-3.5 Turbo는 더 긴 응답 가능
        }),
      );
      
      print('[OPENAI_API] HTTP 응답 상태 코드: ${response.statusCode}');
      print('[OPENAI_API] HTTP 응답 바디 길이: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('[OPENAI_API] 응답 내용 길이: ${content.length}');
        return content;
      } else {
        print('[OPENAI_API] API 오류: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('[OPENAI_API] API 호출 중 오류: $e');
      return null;
    }
  }
  
  // ============================================
  // 아래 함수들은 Fine-tuned model 사용으로 더 이상 필요하지 않습니다.
  // 하위 호환성을 위해 주석 처리되어 있습니다.
  // ============================================

  // [DEPRECATED] 템플릿 생성 API 호출 - Fine-tuned model 사용으로 불필요
  // static Future<List<CueTemplate>> generateTemplates(List<String> urls) async { ... }

  // [DEPRECATED] 템플릿 정리 API 호출 - Fine-tuned model 사용으로 불필요
  // static Future<List<CueTemplate>> cleanTemplates(List<CueTemplate> templates) async { ... }

  // [DEPRECATED] 계획 생성 API 호출 - Fine-tuned model 사용으로 불필요
  // static Future<Plan?> generatePlan(Map<String, String> userInput) async { ... }

  // [DEPRECATED] 큐카드 생성 API 호출 - Fine-tuned model 사용으로 불필요
  // static Future<List<CueCard>> generateCueCards(List<CueTemplate> templates, Plan plan) async { ... }
  
  // JSON 응답 정리 (코드 펜스 제거, 제어 문자 제거 등)
  static String _cleanJsonResponse(String response) {
    // 코드 펜스 제거
    String cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();
    
    // JSON 문자열 값 내부의 제어 문자를 이스케이프
    // 따옴표로 둘러싸인 문자열 값 내부의 제어 문자를 찾아서 이스케이프
    final buffer = StringBuffer();
    bool inString = false;
    bool escaped = false;
    
    for (int i = 0; i < cleaned.length; i++) {
      final char = cleaned[i];
      final codeUnit = char.codeUnitAt(0);
      
      if (escaped) {
        // 이스케이프 시퀀스 처리 중
        buffer.write(char);
        escaped = false;
        continue;
      }
      
      if (char == '\\') {
        // 이스케이프 문자 시작
        buffer.write(char);
        escaped = true;
        continue;
      }
      
      if (char == '"' && (i == 0 || cleaned[i - 1] != '\\')) {
        // 문자열 시작/끝 (이스케이프되지 않은 따옴표)
        inString = !inString;
        buffer.write(char);
        continue;
      }
      
      if (inString) {
        // JSON 문자열 값 내부
        // 제어 문자를 이스케이프된 형태로 변환
        if (codeUnit == 0x0A) { // \n
          buffer.write('\\n');
        } else if (codeUnit == 0x0D) { // \r
          buffer.write('\\r');
        } else if (codeUnit == 0x09) { // \t
          buffer.write('\\t');
        } else if (codeUnit < 0x20) {
          // 다른 제어 문자는 공백으로 대체
          buffer.write(' ');
        } else {
          buffer.write(char);
        }
      } else {
        // JSON 구조 부분 (키, 구분자 등)
        // 구조 부분의 제어 문자는 제거
        if (codeUnit >= 0x20 || codeUnit == 0x09 || codeUnit == 0x0A || codeUnit == 0x0D) {
          buffer.write(char);
        } else {
          buffer.write(' ');
        }
      }
    }
    
    return buffer.toString();
  }
  
  // Fine-tuned model을 사용한 통합 스토리보드 생성
  // API 호출 헬퍼 함수 (JSON 파싱 및 정리 포함)
  static Future<Map<String, dynamic>?> _callApiWithPrompt(String prompt, String stepName) async {
    if (!ApiConfig.isApiKeySet) {
      print('[OPENAI_API] API 키가 설정되지 않음');
      throw Exception('OpenAI API 키가 설정되지 않았습니다.');
    }

    print('[OPENAI_API] $stepName API 호출 중...');

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.apiKey}',
      },
      body: jsonEncode({
        'model': _fineTunedModel,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert vlog storyboard creator that generates comprehensive vlog shooting plans in JSON format. Always respond with valid JSON only, no markdown or code fences.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 16384, // API 최대값
      }),
    );

    print('[OPENAI_API] $stepName 응답 상태: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      print('[OPENAI_API] $stepName 응답 길이: ${content.length}');

      // JSON 파싱 (제어 문자 제거 후)
      final cleanedResponse = _cleanJsonResponse(content);
      print('[OPENAI_API] $stepName 정리된 JSON 길이: ${cleanedResponse.length}');
      
      // JSON 파싱 시도
      Map<String, dynamic> result;
      try {
        result = jsonDecode(cleanedResponse) as Map<String, dynamic>;
      } catch (e) {
        print('[OPENAI_API] $stepName JSON 파싱 실패, 추가 정리 시도: $e');
        
        // 오류 위치 찾기
        if (e is FormatException) {
          final offset = e.offset;
          if (offset != null && offset < cleanedResponse.length) {
            final start = (offset - 200).clamp(0, cleanedResponse.length);
            final end = (offset + 200).clamp(0, cleanedResponse.length);
            print('[OPENAI_API] $stepName 오류 위치 주변 (offset: $offset):');
            print('[OPENAI_API] ${cleanedResponse.substring(start, end)}');
          }
        }
        
        // 추가 정리: 더 공격적인 정리 시도
        String furtherCleaned = cleanedResponse;
        
        // 잘린 문자열 복구 시도
        final openQuotes = furtherCleaned.split('"').length - 1;
        if (openQuotes % 2 != 0) {
          print('[OPENAI_API] $stepName ⚠️ 따옴표가 닫히지 않았습니다. 마지막 문자열 복구 시도...');
          int lastOpenQuote = -1;
          int quoteCount = 0;
          for (int i = furtherCleaned.length - 1; i >= 0; i--) {
            if (furtherCleaned[i] == '"' && (i == 0 || furtherCleaned[i - 1] != '\\')) {
              quoteCount++;
              if (quoteCount == 1) {
                lastOpenQuote = i;
                break;
              }
            }
          }
          
          if (lastOpenQuote != -1) {
            final afterQuote = furtherCleaned.substring(lastOpenQuote + 1);
            final nextComma = afterQuote.indexOf(',');
            final nextBrace = afterQuote.indexOf('}');
            final nextBracket = afterQuote.indexOf(']');
            final nextColon = afterQuote.indexOf(':');
            
            int cutPoint = afterQuote.length;
            if (nextComma != -1 && nextComma < cutPoint) cutPoint = nextComma;
            if (nextBrace != -1 && nextBrace < cutPoint) cutPoint = nextBrace;
            if (nextBracket != -1 && nextBracket < cutPoint) cutPoint = nextBracket;
            if (nextColon != -1 && nextColon < cutPoint) cutPoint = nextColon;
            
            if (cutPoint < afterQuote.length) {
              furtherCleaned = furtherCleaned.substring(0, lastOpenQuote + 1 + cutPoint);
            }
            if (!furtherCleaned.endsWith('"')) {
              furtherCleaned += '"';
            }
            print('[OPENAI_API] $stepName 잘린 문자열 복구 완료');
          }
        }
        
        // 닫히지 않은 객체/배열 닫기
        int openBraces = furtherCleaned.split('{').length - 1;
        int closeBraces = furtherCleaned.split('}').length - 1;
        int openBrackets = furtherCleaned.split('[').length - 1;
        int closeBrackets = furtherCleaned.split(']').length - 1;
        
        if (openBraces > closeBraces) {
          furtherCleaned += '}' * (openBraces - closeBraces);
          print('[OPENAI_API] $stepName 닫히지 않은 객체 ${openBraces - closeBraces}개 복구');
        }
        if (openBrackets > closeBrackets) {
          furtherCleaned += ']' * (openBrackets - closeBrackets);
          print('[OPENAI_API] $stepName 닫히지 않은 배열 ${openBrackets - closeBrackets}개 복구');
        }
        
        // 제어 문자 처리
        final regex = RegExp(r'"([^"\\]|\\.)*"');
        furtherCleaned = furtherCleaned.replaceAllMapped(regex, (match) {
          String value = match.group(0)!;
          String cleaned = value.replaceAllMapped(RegExp(r'(?<!\\)(\n|\r|\t)'), (m) {
            if (m.group(1) == '\n') return '\\n';
            if (m.group(1) == '\r') return '\\r';
            if (m.group(1) == '\t') return '\\t';
            return m.group(0)!;
          });
          return cleaned;
        });
        
        furtherCleaned = furtherCleaned.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ');
        
        try {
          result = jsonDecode(furtherCleaned) as Map<String, dynamic>;
        } catch (e2) {
          print('[OPENAI_API] $stepName 추가 정리 후에도 파싱 실패: $e2');
          final finalCleaned = furtherCleaned.replaceAll(RegExp(r'[\x00-\x1F]'), ' ');
          result = jsonDecode(finalCleaned) as Map<String, dynamic>;
        }
      }

      return result;
    } else {
      print('[OPENAI_API] $stepName API 오류: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> generateStoryboardWithFineTunedModel(
    Map<String, String> userInput,
  ) async {
    try {
      // 새로운 스토리보드 생성 시 템플릿 캐시 초기화
      clearTemplateCache();

      print('[OPENAI_API] Fine-tuned model로 스토리보드 생성 중 (2단계 분할)...');

      // 진행 상황 알림 시작
      ProgressNotificationService().show(progress: 0.05, task: '영상 계획을 세우는 중...');

      // 1단계: Plan 정보 + alternative_scenes 생성
      final planPrompt = Prompts.buildFineTunedPlanPrompt(userInput);
      ProgressNotificationService().update(progress: 0.1, task: '영상 계획을 세우는 중...');
      final planData = await _callApiWithPrompt(planPrompt, '1단계: Plan 정보');
      
      if (planData == null) {
        print('[OPENAI_API] 1단계 실패: Plan 정보 생성 실패');
        ProgressNotificationService().hide();
        return null;
      }
      
      print('[OPENAI_API] 1단계 완료: Plan 정보 생성 성공');
      print('[OPENAI_API]   - chapters 개수: ${(planData['chapters'] as List?)?.length ?? 0}');
      print('[OPENAI_API]   - alternative_scenes 개수: ${(planData['alternative_scenes'] as List?)?.length ?? 0}');

      // 2단계: Scenes 배열 생성
      ProgressNotificationService().update(progress: 0.2, task: '씬 목록을 만드는 중...');
      final scenesPrompt = Prompts.buildFineTunedScenesPrompt(userInput, planData);
      ProgressNotificationService().update(progress: 0.25, task: '씬 목록을 만드는 중...');
      final scenesData = await _callApiWithPrompt(scenesPrompt, '2단계: Scenes 배열');
      
      if (scenesData == null) {
        print('[OPENAI_API] 2단계 실패: Scenes 배열 생성 실패');
        ProgressNotificationService().hide();
        return null;
      }
      
      print('[OPENAI_API] 2단계 완료: Scenes 배열 생성 성공');
      print('[OPENAI_API]   - scenes 개수: ${(scenesData['scenes'] as List?)?.length ?? 0}');

      // 두 결과 합치기
      final storyboard = <String, dynamic>{
        ...planData,
        'scenes': scenesData['scenes'] ?? [],
      };

      print('[OPENAI_API] 스토리보드 생성 완료: scenes ${(storyboard['scenes'] as List).length}개');
      ProgressNotificationService().update(progress: 0.4, task: '스토리보드 정보를 정리하는 중...');
      return storyboard;
    } catch (e) {
      print('[OPENAI_API] Fine-tuned model 스토리보드 생성 오류: $e');
      ProgressNotificationService().hide();
      return null;
    }
  }

  // Fine-tuned model을 사용한 스토리보드 수정
  static Future<Map<String, dynamic>?> modifyStoryboardWithFineTunedModel({
    required Map<String, dynamic> currentStoryboard,
    required String modificationRequest,
  }) async {
    try {
      final prompt = Prompts.buildStoryboardModificationPrompt(
        currentStoryboard: currentStoryboard,
        modificationRequest: modificationRequest,
      );

      print('[OPENAI_API] Fine-tuned model로 스토리보드 수정 중...');

      if (!ApiConfig.isApiKeySet) {
        print('[OPENAI_API] API 키가 설정되지 않음');
        throw Exception('OpenAI API 키가 설정되지 않았습니다.');
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'model': _fineTunedModel,
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert vlog storyboard creator that generates comprehensive vlog shooting plans in JSON format. Always respond with valid JSON only, no markdown or code fences.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 16384, // API 최대값 (alternative_scenes 포함)
        }),
      );

      print('[OPENAI_API] Fine-tuned model 수정 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('[OPENAI_API] Fine-tuned model 수정 응답 길이: ${content.length}');

        // JSON 파싱 (제어 문자 제거 후)
        final cleanedResponse = _cleanJsonResponse(content);
        print('[OPENAI_API] 정리된 JSON 길이: ${cleanedResponse.length}');
        
        // JSON 파싱 시도
        Map<String, dynamic> storyboard;
        try {
          storyboard = jsonDecode(cleanedResponse) as Map<String, dynamic>;
        } catch (e) {
          print('[OPENAI_API] JSON 파싱 실패, 추가 정리 시도: $e');
          
          // 오류 위치 찾기
          if (e is FormatException) {
            final offset = e.offset;
            if (offset != null && offset < cleanedResponse.length) {
              final start = (offset - 200).clamp(0, cleanedResponse.length);
              final end = (offset + 200).clamp(0, cleanedResponse.length);
              print('[OPENAI_API] 오류 위치 주변 (offset: $offset):');
              print('[OPENAI_API] ${cleanedResponse.substring(start, end)}');
            }
          } else {
            print('[OPENAI_API] 오류 위치 주변: ${cleanedResponse.length > 1000 ? cleanedResponse.substring(0, 1000) : cleanedResponse}');
          }
          
          // 추가 정리: 더 공격적인 정리 시도
          String furtherCleaned = cleanedResponse;
          
          // 잘린 문자열 복구 시도: 마지막 따옴표가 닫히지 않은 경우
          final openQuotes = furtherCleaned.split('"').length - 1;
          if (openQuotes % 2 != 0) {
            // 따옴표가 홀수 개면 마지막 문자열이 닫히지 않았을 가능성
            print('[OPENAI_API] ⚠️ 따옴표가 닫히지 않았습니다. 마지막 문자열 복구 시도...');
            // 마지막 불완전한 문자열을 찾아서 닫기
            final lastQuoteIndex = furtherCleaned.lastIndexOf('"');
            if (lastQuoteIndex != -1) {
              // 마지막 따옴표 이후의 내용을 확인
              final afterLastQuote = furtherCleaned.substring(lastQuoteIndex + 1);
              // 줄바꿈이나 쉼표가 나오기 전까지의 내용을 문자열로 간주하고 닫기
              final nextComma = afterLastQuote.indexOf(',');
              final nextBrace = afterLastQuote.indexOf('}');
              final nextBracket = afterLastQuote.indexOf(']');
              int cutPoint = afterLastQuote.length;
              if (nextComma != -1) cutPoint = nextComma;
              if (nextBrace != -1 && nextBrace < cutPoint) cutPoint = nextBrace;
              if (nextBracket != -1 && nextBracket < cutPoint) cutPoint = nextBracket;
              
              if (cutPoint < afterLastQuote.length) {
                // 불완전한 문자열을 제거하고 닫기
                furtherCleaned = furtherCleaned.substring(0, lastQuoteIndex + 1 + cutPoint);
                if (!furtherCleaned.endsWith('"')) {
                  furtherCleaned += '"';
                }
                print('[OPENAI_API] 잘린 문자열 복구 완료');
              }
            }
          }
          
          // 1단계: JSON 문자열 값 내부의 이스케이프되지 않은 제어 문자 처리
          final regex = RegExp(r'"([^"\\]|\\.)*"');
          furtherCleaned = furtherCleaned.replaceAllMapped(regex, (match) {
            String value = match.group(0)!;
            String cleaned = value.replaceAllMapped(RegExp(r'(?<!\\)(\n|\r|\t)'), (m) {
              if (m.group(1) == '\n') return '\\n';
              if (m.group(1) == '\r') return '\\r';
              if (m.group(1) == '\t') return '\\t';
              return m.group(0)!;
            });
            return cleaned;
          });
          
          // 2단계: 구조 부분의 제어 문자 제거
          furtherCleaned = furtherCleaned.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ');
          
          try {
            storyboard = jsonDecode(furtherCleaned) as Map<String, dynamic>;
          } catch (e2) {
            print('[OPENAI_API] 추가 정리 후에도 파싱 실패: $e2');
            // 최종 시도: 모든 제어 문자를 공백으로 대체
            final finalCleaned = furtherCleaned.replaceAll(RegExp(r'[\x00-\x1F]'), ' ');
            storyboard = jsonDecode(finalCleaned) as Map<String, dynamic>;
          }
        }

        ProgressNotificationService().update(progress: 0.8, task: '스토리보드 수정이 완료되었습니다');
        return storyboard;
      } else {
        print('[OPENAI_API] Fine-tuned model 수정 API 오류: ${response.statusCode} - ${response.body}');
        ProgressNotificationService().hide();
        return null;
      }
    } catch (e) {
      print('[OPENAI_API] Fine-tuned model 스토리보드 수정 오류: $e');
      ProgressNotificationService().hide();
      return null;
    }
  }

  // Fine-tuned model 응답에서 Plan과 CueCards 파싱
  static Future<({Plan? plan, List<CueCard>? cueCards})?> parseStoryboard(
    Map<String, dynamic> storyboard,
  ) async {
    try {
      // Plan 생성 전에 데이터 정리 (안전한 파싱을 위해)
      final cleanedStoryboard = _cleanJsonForParsing(storyboard);
      
      // alternative_scenes 데이터 확인을 위한 디버그 로그
      print('[OPENAI_API] JSON 응답에서 alternative_scenes 확인:');
      if (cleanedStoryboard['alternative_scenes'] != null) {
        final altScenesJson = cleanedStoryboard['alternative_scenes'];
        print('[OPENAI_API]   - alternative_scenes 타입: ${altScenesJson.runtimeType}');
        if (altScenesJson is List) {
          print('[OPENAI_API]   - alternative_scenes 개수: ${altScenesJson.length}');
          for (var i = 0; i < altScenesJson.length; i++) {
            final altScene = altScenesJson[i];
            if (altScene is Map) {
              print('[OPENAI_API]     - 대체 씬 #${i + 1}: id=${altScene['id']}, title=${altScene['title']}');
            }
          }
        } else {
          print('[OPENAI_API]   - ⚠️ alternative_scenes가 List가 아닙니다: $altScenesJson');
        }
      } else {
        print('[OPENAI_API]   - ⚠️ alternative_scenes가 JSON 응답에 없습니다');
        print('[OPENAI_API]   - JSON 키 목록: ${cleanedStoryboard.keys.toList()}');
      }
      
      // rationale 데이터 확인을 위한 디버그 로그
      if (cleanedStoryboard['style_analysis'] != null) {
        final styleAnalysis = cleanedStoryboard['style_analysis'] as Map<String, dynamic>;
        if (styleAnalysis['rationale'] != null) {
          final rationale = styleAnalysis['rationale'] as Map<String, dynamic>;
          print('[OPENAI_API] rationale 데이터 발견:');
          print('[OPENAI_API] - movement: ${rationale['movement']}');
          print('[OPENAI_API] - location_diversity: ${rationale['location_diversity']}');
          print('[OPENAI_API] - excitement_surprise: ${rationale['excitement_surprise']}');
          print('[OPENAI_API] - speed_rhythm: ${rationale['speed_rhythm']}');
          print('[OPENAI_API] - emotional_expression: ${rationale['emotional_expression']}');
        } else {
          print('[OPENAI_API] ⚠️ rationale 데이터가 없습니다');
        }
      } else {
        print('[OPENAI_API] ⚠️ style_analysis 데이터가 없습니다');
      }
      
      final plan = Plan.fromJson(cleanedStoryboard);
      
      // 대체 씬 생성 여부 확인
      if (plan.alternativeScenes.isNotEmpty) {
        print('[OPENAI_API] ✅ 대체 씬 생성 완료: ${plan.alternativeScenes.length}개');
        for (var i = 0; i < plan.alternativeScenes.length; i++) {
          final altScene = plan.alternativeScenes[i];
          print('[OPENAI_API]   - 대체 씬 #${i + 1} (${altScene.alternativeSceneId ?? "id 없음"}): ${altScene.title}');
        }
      } else {
        print('[OPENAI_API] ⚠️ 대체 씬이 생성되지 않았습니다');
      }
      
      // 파싱 후 rationale 확인
      if (plan.styleAnalysis?.rationale != null) {
        final rationale = plan.styleAnalysis!.rationale!;
        print('[OPENAI_API] 파싱된 rationale:');
        print('[OPENAI_API] - movement: ${rationale.movement}');
        print('[OPENAI_API] - locationDiversity: ${rationale.locationDiversity}');
        print('[OPENAI_API] - excitementSurprise: ${rationale.excitementSurprise}');
        print('[OPENAI_API] - speedRhythm: ${rationale.speedRhythm}');
        print('[OPENAI_API] - emotionalExpression: ${rationale.emotionalExpression}');
      } else {
        print('[OPENAI_API] ⚠️ 파싱된 rationale이 null입니다');
      }

      // CueCards 생성
      final scenesJson = cleanedStoryboard['scenes'] as List<dynamic>?;
      if (scenesJson == null || scenesJson.isEmpty) {
        print('[OPENAI_API] scenes 데이터가 없습니다');
        return null;
      }

      final cueCards = <CueCard>[];
      int scenesWithAlternativeId = 0;
      int scenesWithoutAlternativeId = 0;
      final alternativeIdCounts = <String, int>{};
      
      for (var sceneJson in scenesJson) {
        // scene도 정리
        final scene = sceneJson is Map<String, dynamic> 
            ? _cleanJsonForParsing(sceneJson) 
            : (sceneJson as Map<String, dynamic>);

        // 대체 씬 ID 확인
        final alternativeSceneId = scene['alternative_scene_id'] != null ? _safeString(scene['alternative_scene_id']) : null;
        if (alternativeSceneId != null) {
          scenesWithAlternativeId++;
          alternativeIdCounts[alternativeSceneId] = (alternativeIdCounts[alternativeSceneId] ?? 0) + 1;
        } else {
          scenesWithoutAlternativeId++;
        }

        // CueCard 생성 (안전한 파싱 사용)
        final cueCard = CueCard(
          title: _safeString(scene['title']),
          allocatedSec: _safeInt(scene['allocated_sec']),
          trigger: _safeString(scene['trigger']),
          summary: scene['summary'] != null
              ? List<String>.from((scene['summary'] as List<dynamic>).map((e) => e.toString()))
              : [],
          steps: scene['steps'] != null
              ? List<String>.from((scene['steps'] as List<dynamic>).map((e) => e.toString()))
              : [],
          checklist: scene['checklist'] != null
              ? List<String>.from((scene['checklist'] as List<dynamic>).map((e) => e.toString()))
              : [],
          fallback: _safeString(scene['fallback']),
          startHint: _safeString(scene['start_hint']),
          stopHint: _safeString(scene['stop_hint']),
          completionCriteria: _safeString(scene['completion_criteria']),
          tone: _safeString(scene['tone']),
          styleVibe: _safeString(scene['style_vibe']),
          targetAudience: _safeString(scene['target_audience']),
          script: _safeString(scene['script']),
          // 새로운 필드들
          shotComposition: scene['shot_composition'] != null
              ? List<String>.from((scene['shot_composition'] as List<dynamic>).map((e) => e.toString()))
              : [],
          shootingInstructions: scene['shooting_instructions'] != null
              ? List<String>.from((scene['shooting_instructions'] as List<dynamic>).map((e) => e.toString()))
              : [],
          location: _safeString(scene['location']),
          cost: _safeInt(scene['cost']),
          peopleCount: _safeInt(scene['people_count'], defaultValue: 1),
          shootingTimeMin: _safeInt(scene['shooting_time_min'], defaultValue: 30),
          storyboardImageUrl: scene['storyboard_image_url'] != null ? _safeString(scene['storyboard_image_url']) : null,
          referenceVideoUrl: scene['reference_video_url'] != null ? _safeString(scene['reference_video_url']) : null,
          referenceVideoTimestamp: _safeInt(scene['reference_video_timestamp']),
          pro: scene['pro'] != null && scene['pro'] is Map<String, dynamic>
              ? _parsePro(scene['pro'] as Map<String, dynamic>)
              : null,
          rawMarkdown: '',
          // 대체 씬 ID 할당 (Plan 레벨의 alternative_scenes와 매칭)
          alternativeSceneId: alternativeSceneId,
        );

        cueCards.add(cueCard);
      }

      // 대체 씬 ID 할당 통계 로그
      print('[OPENAI_API] 대체 씬 ID 할당 통계:');
      print('[OPENAI_API]   - 대체 씬 ID가 있는 씬: ${scenesWithAlternativeId}개');
      if (scenesWithoutAlternativeId > 0) {
        print('[OPENAI_API]   - ⚠️ 대체 씬 ID가 없는 씬: ${scenesWithoutAlternativeId}개');
      }
      if (alternativeIdCounts.isNotEmpty) {
        print('[OPENAI_API]   - 대체 씬 ID별 할당 현황:');
        alternativeIdCounts.forEach((id, count) {
          print('[OPENAI_API]     • $id: ${count}개 씬');
        });
      }

      print('[OPENAI_API] Plan과 ${cueCards.length}개의 CueCard 파싱 완료');
      return (plan: plan, cueCards: cueCards);
    } catch (e) {
      print('[OPENAI_API] 스토리보드 파싱 오류: $e');
      return null;
    }
  }

  // JSON 데이터 정리 (List를 String으로 잘못 캐스팅하는 것을 방지)
  static Map<String, dynamic> _cleanJsonForParsing(Map<String, dynamic> json) {
    final cleaned = <String, dynamic>{};
    
    json.forEach((key, value) {
      if (value == null) {
        cleaned[key] = null;
      } else if (value is Map) {
        cleaned[key] = _cleanJsonForParsing(value as Map<String, dynamic>);
      } else if (value is List) {
        // List는 그대로 유지 (Plan.fromJson에서 처리)
        cleaned[key] = value;
      } else if (value is String || value is int || value is double || value is bool) {
        cleaned[key] = value;
      } else {
        // 예상치 못한 타입은 문자열로 변환
        cleaned[key] = value.toString();
      }
    });
    
    return cleaned;
  }

  // 대체 씬 파싱 헬퍼 함수
  static List<CueCard> _parseAlternativeScenes(List<dynamic> alternativeScenes, Map<String, dynamic> parentScene) {
    final altScenes = <CueCard>[];

    for (var altSceneJson in alternativeScenes) {
      if (altSceneJson is! Map<String, dynamic>) continue;

      final altScene = altSceneJson as Map<String, dynamic>;

      try {
        final altCueCard = CueCard(
          title: _safeString(altScene['title']),
          allocatedSec: _safeInt(altScene['allocated_sec']),
          trigger: _safeString(altScene['trigger']),
          summary: altScene['summary'] != null
              ? List<String>.from((altScene['summary'] as List<dynamic>).map((e) => e.toString()))
              : [],
          steps: altScene['steps'] != null
              ? List<String>.from((altScene['steps'] as List<dynamic>).map((e) => e.toString()))
              : [],
          checklist: altScene['checklist'] != null
              ? List<String>.from((altScene['checklist'] as List<dynamic>).map((e) => e.toString()))
              : [],
          fallback: _safeString(altScene['fallback']),
          startHint: _safeString(altScene['start_hint']),
          stopHint: _safeString(altScene['stop_hint']),
          completionCriteria: _safeString(altScene['completion_criteria']),
          tone: _safeString(altScene['tone']),
          styleVibe: _safeString(altScene['style_vibe']),
          targetAudience: _safeString(altScene['target_audience']),
          script: _safeString(altScene['script']),
          shotComposition: altScene['shot_composition'] != null
              ? List<String>.from((altScene['shot_composition'] as List<dynamic>).map((e) => e.toString()))
              : [],
          shootingInstructions: altScene['shooting_instructions'] != null
              ? List<String>.from((altScene['shooting_instructions'] as List<dynamic>).map((e) => e.toString()))
              : [],
          location: _safeString(altScene['location']),
          cost: _safeInt(altScene['cost']),
          peopleCount: _safeInt(altScene['people_count'], defaultValue: 1),
          shootingTimeMin: _safeInt(altScene['shooting_time_min'], defaultValue: 30),
          storyboardImageUrl: altScene['storyboard_image_url'] != null ? _safeString(altScene['storyboard_image_url']) : null,
          referenceVideoUrl: altScene['reference_video_url'] != null ? _safeString(altScene['reference_video_url']) : null,
          referenceVideoTimestamp: _safeInt(altScene['reference_video_timestamp']),
          pro: null, // 대체 씬은 pro 필드를 가지지 않음
          rawMarkdown: '',
          alternativeSceneId: null, // 대체 씬은 alternativeSceneId를 가지지 않음
        );

        altScenes.add(altCueCard);
      } catch (e) {
        print('[OPENAI_API] 대체 씬 파싱 오류: $e');
        // 파싱 실패 시 해당 대체 씬은 건너뛰고 계속 진행
        continue;
      }
    }

    return altScenes;
  }

  // 안전한 String 파싱 헬퍼 함수
  static String _safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is List && value.isNotEmpty) {
      // List인 경우 첫 번째 요소를 문자열로 변환
      return value[0].toString();
    }
    return value.toString();
  }

  // 안전한 int 파싱 헬퍼 함수
  static int _safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    if (value is double) {
      return value.toInt();
    }
    return defaultValue;
  }

  // Pro 정보 파싱
  static CueCardPro _parsePro(Map<String, dynamic> proJson) {
    return CueCardPro(
      framing: proJson['framing'] != null
          ? List<String>.from((proJson['framing'] as List<dynamic>).map((e) => e.toString()))
          : [],
      audio: proJson['audio'] != null
          ? List<String>.from((proJson['audio'] as List<dynamic>).map((e) => e.toString()))
          : [],
      dialogue: proJson['dialogue'] != null
          ? List<String>.from((proJson['dialogue'] as List<dynamic>).map((e) => e.toString()))
          : [],
      editHint: proJson['edit_hint'] != null
          ? List<String>.from((proJson['edit_hint'] as List<dynamic>).map((e) => e.toString()))
          : [],
      safety: proJson['safety'] != null
          ? List<String>.from((proJson['safety'] as List<dynamic>).map((e) => e.toString()))
          : [],
      broll: proJson['broll'] != null
          ? List<String>.from((proJson['broll'] as List<dynamic>).map((e) => e.toString()))
          : [],
    );
  }

  // ============================================
  // 추가 기능: Script, 요약, 장비 추천 등
  // ============================================

  // 1. 씬별 Script 생성 (Option 2: Few-shot + Transcript 스타일)
  static Future<String?> generateScriptForScene({
    required String sceneSummary,
    required String sceneLocation,
    required String tone,
    required String vibe,
    required int durationSec,
    Map<String, dynamic>? contextData, // 추가 컨텍스트 데이터
    int? sceneIndex, // 씬 인덱스 (0부터 시작)
    int? totalScenes, // 전체 씬 개수
  }) async {
    try {
      // Few-shot 예시 찾기
      final fewShotExample = await _findRelevantScriptExample(
        sceneSummary: sceneSummary,
        sceneLocation: sceneLocation,
        tone: tone,
      );

      final prompt = _buildScriptPrompt(
        sceneSummary: sceneSummary,
        sceneLocation: sceneLocation,
        tone: tone,
        vibe: vibe,
        durationSec: durationSec,
        contextData: contextData,
        fewShotExample: fewShotExample,
        sceneIndex: sceneIndex,
        totalScenes: totalScenes,
      );

      print('[OPENAI_API] Script 생성 중: $sceneLocation');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o',  // GPT-4o 사용 (script 생성에 최적)
          'messages': [
            {
              'role': 'system',
              'content': 'You are a vlog script writer who creates natural, conversational Korean dialogue based on real vlog transcripts and visual context.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.8,  // 창의성 높임
          'max_tokens': 4000, // 매우 긴 씬(120초+)에도 충분한 토큰 할당 (GPT-4o 최대: 16,384)
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final script = data['choices'][0]['message']['content'];
        print('[OPENAI_API] Script 생성 완료: ${script.length}자');
        return script.trim();
      } else {
        print('[OPENAI_API] Script 생성 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[OPENAI_API] Script 생성 예외: $e');
      // 네트워크 연결 중단 시 기본 스크립트 반환
      if (e.toString().contains('connection abort') || e.toString().contains('SocketException')) {
        print('[OPENAI_API] 네트워크 연결 중단, 기본 스크립트 반환');
        return _generateFallbackScript(sceneLocation, sceneSummary, durationSec);
      }
      return null;
    }
  }

  /// 네트워크 오류 시 기본 스크립트 생성
  static String _generateFallbackScript(String location, String summary, int durationSec) {
    return '''안녕하세요! 지금은 $location에 와 있어요.

$summary

정말 멋진 곳이네요! 

다음 장소로 이동해볼게요!''';
  }

  // 캐시: 템플릿 매칭 결과
  static String? _cachedMatchedTemplateDir;
  
  /// Few-shot 예시 찾기 (Template Matching Service 사용)
  static Future<String?> _findRelevantScriptExample({
    required String sceneSummary,
    required String sceneLocation,
    required String tone,
  }) async {
    try {
      // VlogDataService에서 현재 plan 가져오기
      final vlogService = VlogDataService();
      final plan = vlogService.plan;
      final userInput = vlogService.userInput;

      print('[OPENAI_API] VlogDataService에서 Plan 가져오기 시도: plan=${plan != null ? "존재" : "null"}');

      if (plan == null) {
        print('[OPENAI_API] Plan이 없어 예시를 찾을 수 없음');
        return null;
      }

      // 캐시된 템플릿이 있으면 재사용
      String? matchedTemplateDir = _cachedMatchedTemplateDir;
      
      if (matchedTemplateDir == null) {
        // 가장 유사한 템플릿 찾기 (한 번만 수행)
        final matchingService = TemplateMatchingService();
        matchedTemplateDir = await matchingService.findMostSimilarTemplate(
          userInput: userInput,
          plan: plan,
        );
        
        // 캐시에 저장
        _cachedMatchedTemplateDir = matchedTemplateDir;
      }

      if (matchedTemplateDir == null) {
        print('[OPENAI_API] 유사한 템플릿을 찾지 못함');
        return null;
      }

      // 씬 타입 추정
      final sceneType = _inferSceneType(sceneSummary, sceneLocation);

      // 해당 템플릿에서 대본 예시 가져오기
      final matchingService = TemplateMatchingService();
      final example = await matchingService.getScriptExample(matchedTemplateDir, sceneType);
      
      print('[OPENAI_API] Few-shot 예시 찾음: ${matchedTemplateDir.split('/').last}');
      return example;
    } catch (e) {
      print('[OPENAI_API] Few-shot 예시 찾기 오류: $e');
      return null;
    }
  }
  
  /// 캐시 초기화 (새로운 스토리보드 생성 시 호출)
  static void clearTemplateCache() {
    _cachedMatchedTemplateDir = null;
  }

  /// 씬 타입 추정
  static String _inferSceneType(String sceneSummary, String sceneLocation) {
    final summaryLower = sceneSummary.toLowerCase();
    final locationLower = sceneLocation.toLowerCase();

    if (summaryLower.contains('입장') || summaryLower.contains('오프닝') || 
        locationLower.contains('입구') || locationLower.contains('게이트')) {
      return 'opening';
    }
    
    if (summaryLower.contains('식사') || summaryLower.contains('먹') || 
        summaryLower.contains('음식') || summaryLower.contains('맛')) {
      return 'food';
    }
    
    if (summaryLower.contains('일') || summaryLower.contains('업무') || 
        summaryLower.contains('작업') || summaryLower.contains('오피스')) {
      return 'work';
    }
    
    if (summaryLower.contains('이동') || summaryLower.contains('걷') || 
        summaryLower.contains('가는')) {
      return 'moving';
    }
    
    if (summaryLower.contains('휴식') || summaryLower.contains('쉬')) {
      return 'rest';
    }
    
    if (summaryLower.contains('인사') || summaryLower.contains('마무리') || 
        summaryLower.contains('엔딩')) {
      return 'ending';
    }

    return 'default';
  }

  // Script 프롬프트 구성 (Few-shot 예시 포함)
  static String _buildScriptPrompt({
    required String sceneSummary,
    required String sceneLocation,
    required String tone,
    required String vibe,
    required int durationSec,
    Map<String, dynamic>? contextData, // 추가 컨텍스트 데이터
    String? fewShotExample, // Few-shot 예시
    int? sceneIndex, // 씬 인덱스 (0부터 시작)
    int? totalScenes, // 전체 씬 개수
  }) {
    // 시간에 따른 대사 줄 수 계산 (1줄 = 약 3-4초)
    final minLines = (durationSec / 4).floor();
    final maxLines = ((durationSec / 3) * 1.2).ceil(); // 약간 여유있게
    
    // 첫 번째 씬인지, 마지막 씬인지 판단
    final isFirstScene = sceneIndex != null && sceneIndex == 0;
    final isLastScene = sceneIndex != null && totalScenes != null && sceneIndex == totalScenes - 1;
    
    // 씬 타입에 따른 안내
    String sceneTypeGuide = '';
    if (isFirstScene) {
      sceneTypeGuide = '''

**[중요] 이것은 브이로그의 첫 번째 씬입니다**
- 브이로그 시작 인사와 오프닝을 포함하세요
- 예: "안녕하세요~", "오늘은...", "여러분 안녕~" 등
- 오늘 무엇을 할 것인지 간단히 소개하세요
''';
    } else if (isLastScene) {
      sceneTypeGuide = '''

**[중요] 이것은 브이로그의 마지막 씬입니다**
- 브이로그 마무리와 엔딩 멘트를 포함하세요
- 예: "오늘 영상 재밌게 보셨나요?", "구독과 좋아요 부탁드려요~", "다음에 또 만나요!" 등
- 전체 경험을 간단히 회고하고 마무리하세요
''';
    } else {
      sceneTypeGuide = '''

**[중요] 이것은 브이로그의 중간 씬입니다 (씬 ${(sceneIndex ?? 0) + 1}/${totalScenes ?? 1})**
- 오프닝이나 엔딩 멘트 없이, 바로 이 씬의 내용으로 시작하세요
- 이전 씬에서 자연스럽게 이어지는 느낌으로 작성하세요
- 예: "자 그럼~", "이제...", "다음으로는..." 등의 자연스러운 전환으로 시작
''';
    }

    // Few-shot 예시가 있으면 포함
    String fewShotSection = '';
    if (fewShotExample != null && fewShotExample.isNotEmpty) {
      fewShotSection = '''

================================================================================
[실제 브이로그 대본 예시 - Few-shot Learning]
================================================================================

다음은 유사한 스타일의 실제 브이로그에서 추출한 screenplay 형태의 대본입니다.
이 형태와 말투를 **정확히 따라서** 작성해주세요:

$fewShotExample

================================================================================
''';
    }

    return '''
당신은 영화 시나리오 형태의 브이로그 대본(screenplay)을 작성하는 전문가입니다.
실제 브이로거들의 자연스러운 말투를 학습하여, 생동감 있고 친근한 대본을 만들어주세요.
$fewShotSection$sceneTypeGuide

[생성할 씬 정보]
- 씬 제목: $sceneLocation
- 내용: $sceneSummary
- 톤: $tone
- 바이브: $vibe
- **필수 길이: 정확히 ${durationSec}초 분량**

**중요: 대본 길이 규칙 (반드시 준수)**
- 일반적으로 한 줄 대사 = 약 3-4초 소요
- 이 씬은 ${durationSec}초이므로, **최소 ${minLines}줄 ~ 최대 ${maxLines}줄**의 [VOICE] 대사를 작성해야 합니다
- 짧게 쓰지 말고, ${durationSec}초를 꽉 채울 수 있는 충분한 양의 대사를 생성하세요
- [VOICE] 태그를 여러 번 사용하여 대사를 나눠서 작성하세요

[출력 형식]
반드시 아래 screenplay 형태로 작성하세요:

---
SCENE TITLE: $sceneLocation
LOCATION: (구체적 장소)
TIME: 낮 또는 밤
MOOD: $tone

[ACTION / VISUAL DESCRIPTION]
(영상에 보이는 행동이나 장면 묘사를 2-3문장으로 작성)

[DIALOGUE]
[VOICE]
(첫 번째 대사: 실제 브이로거가 말하는 자연스러운 대사)
(말줄임표~, 느낌표!, 물음표? 등을 적절히 사용)
[VOICE]
(두 번째 대사: 계속해서 이어지는 대사)
[VOICE]
(세 번째 대사: ${durationSec}초를 채울 때까지 계속 작성)
... (최소 ${minLines}줄 ~ 최대 ${maxLines}줄까지 [VOICE] 대사를 작성)

[NARRATION / VOICE-OVER]
$tone 분위기가 흐른다.
$sceneSummary

---

**중요 지침**:
${fewShotSection.isNotEmpty ? '''
1. **[필수] 대본 길이: 최소 ${minLines}줄 ~ 최대 ${maxLines}줄의 [VOICE] 대사를 반드시 작성하세요**
2. 위 [실제 브이로그 대본 예시]의 형태를 **정확히** 따라야 합니다
3. 예시의 자연스러운 말투와 표현 방식을 학습하여 적용하세요
4. [VOICE] 태그 안의 대사는 실제 브이로거처럼 친근하고 자연스럽게
5. 예시와 같은 수준의 디테일과 생동감을 유지하세요
6. 짧게 쓰지 말고, ${durationSec}초를 완전히 채울 수 있는 충분한 분량으로 작성하세요''' : '''
1. **[필수] 대본 길이: 최소 ${minLines}줄 ~ 최대 ${maxLines}줄의 [VOICE] 대사를 반드시 작성하세요**
2. screenplay 형태를 정확히 지켜주세요
3. [VOICE] 태그 안의 대사는 실제 브이로거처럼 친근하고 자연스럽게
4. 말줄임표(~), 느낌표(!), 물음표(?)를 적절히 사용
5. "$tone" 톤과 "$vibe" 바이브를 잘 살려서 작성
6. 짧게 쓰지 말고, ${durationSec}초를 완전히 채울 수 있는 충분한 분량으로 작성하세요'''}
7. 다른 설명 없이 screenplay 형태의 대본만 출력하세요
''';
  }

  // 2. 시나리오 요약 생성 (씬 내용 기반)
  static Future<String?> generateScenarioSummary({
    required List<String> sceneSummaries,
    required String location,
    required String tone,
    required int durationMin,
  }) async {
    try {
      final sceneList = sceneSummaries
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value}')
          .join('\n');

      final prompt = '''
다음은 브이로그의 씬별 내용입니다.

[촬영 정보]
- 장소: $location
- 톤: $tone
- 목표 시간: $durationMin분

[씬 구성]
$sceneList

위 씬들의 흐름을 바탕으로, 이 브이로그의 전체 시나리오를 2-3문장으로 자연스럽게 요약해주세요.
단순 나열이 아니라 스토리의 흐름이 느껴지도록 작성해주세요.
''';

      print('[OPENAI_API] 시나리오 요약 생성 중...');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional vlog storyteller who creates compelling scenario summaries.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['choices'][0]['message']['content'];
        print('[OPENAI_API] 시나리오 요약 생성 완료');
        return summary.trim();
      } else {
        print('[OPENAI_API] 시나리오 요약 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[OPENAI_API] 시나리오 요약 예외: $e');
      return null;
    }
  }

  // 3. 촬영 장비 추천
  static Future<String?> recommendEquipment({
    required String location,
    required String tone,
    required String equipment,
    required String difficulty,
  }) async {
    try {
      final prompt = '''
다음 브이로그 촬영에 필요한 장비를 추천해주세요.

[촬영 정보]
- 장소: $location (실내/실외, 밝기 등 고려)
- 톤: $tone
- 기본 장비: $equipment
- 촬영 경험: $difficulty

추천 장비를 다음 형식으로 작성해주세요:

**필수 장비**
- [장비명]: [이유]

**권장 장비** (선택)
- [장비명]: [이유]

**팁**
- [촬영 팁 1-2줄]

간결하게 5-6줄로 작성해주세요.
''';

      print('[OPENAI_API] 장비 추천 생성 중...');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a vlog equipment specialist.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.6,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendation = data['choices'][0]['message']['content'];
        print('[OPENAI_API] 장비 추천 생성 완료');
        return recommendation.trim();
      } else {
        print('[OPENAI_API] 장비 추천 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[OPENAI_API] 장비 추천 예외: $e');
      return null;
    }
  }

  // 시뮬레이션용 메서드 (API 키가 없을 때 사용)
  static Future<String?> generateSimulatedResponse(String prompt) async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (prompt.contains('CueTemplate')) {
      return '''
[
  {
    "scene_type": "opening",
    "when": "입구 표지판 보일 때",
    "len_sec": [20, 40],
    "camera": ["와이드→미드"],
    "action": ["입구 촬영", "환기 나레이션"],
    "audio": ["나레이션 70%", "밝은 톤"],
    "checklist": ["노출 고정", "마이크 확인", "포커스 락"],
    "fallback": "사람 많으면 인서트 촬영",
    "placeholders": ["{동행자}", "{날씨}", "{장소}"],
    "style_tone": "밝고 경쾌",
    "style_vibe": "MZ"
  },
  {
    "scene_type": "main",
    "when": "메인 어트랙션 대기열",
    "len_sec": [30, 60],
    "camera": ["미드→클로즈업"],
    "action": ["대기 상황 촬영", "기대감 나레이션"],
    "audio": ["나레이션 50%", "현장음 50%"],
    "checklist": ["노출 고정", "마이크 확인", "포커스 락"],
    "fallback": "대기 시간 길면 컷어웨이",
    "placeholders": ["{동행자}", "{대기시간}", "{어트랙션}"],
    "style_tone": "밝고 경쾌",
    "style_vibe": "MZ"
  },
  {
    "scene_type": "main",
    "when": "어트랙션 탑승 시",
    "len_sec": [60, 120],
    "camera": ["POV", "와이드"],
    "action": ["탑승 과정 촬영", "감정 표현"],
    "audio": ["현장음 80%", "나레이션 20%"],
    "checklist": ["안전 고정", "마이크 확인", "포커스 락"],
    "fallback": "촬영 금지시 VO 녹음",
    "placeholders": ["{동행자}", "{어트랙션}", "{감정}"],
    "style_tone": "밝고 경쾌",
    "style_vibe": "MZ"
  },
  {
    "scene_type": "reaction",
    "when": "어트랙션 하차 후",
    "len_sec": [15, 30],
    "camera": ["클로즈업", "미드"],
    "action": ["감정 표현", "후기 나레이션"],
    "audio": ["나레이션 90%", "현장음 10%"],
    "checklist": ["노출 고정", "마이크 확인", "포커스 락"],
    "fallback": "민망하면 인서트 촬영",
    "placeholders": ["{동행자}", "{어트랙션}", "{감정}"],
    "style_tone": "밝고 경쾌",
    "style_vibe": "MZ"
  },
  {
    "scene_type": "food",
    "when": "간식 구매 후",
    "len_sec": [20, 40],
    "camera": ["클로즈업", "미드"],
    "action": ["간식 촬영", "맛 리뷰"],
    "audio": ["나레이션 80%", "현장음 20%"],
    "checklist": ["화이트밸런스", "마이크 확인", "포커스 락"],
    "fallback": "먹기 전에만 촬영",
    "placeholders": ["{동행자}", "{간식}", "{맛}"],
    "style_tone": "밝고 경쾌",
    "style_vibe": "MZ"
  },
  {
    "scene_type": "ending",
    "when": "출구 근처",
    "len_sec": [20, 40],
    "camera": ["와이드→미드"],
    "action": ["마무리 촬영", "감사 인사"],
    "audio": ["나레이션 90%", "현장음 10%"],
    "checklist": ["노출 고정", "마이크 확인", "포커스 락"],
    "fallback": "사람 많으면 인서트",
    "placeholders": ["{동행자}", "{장소}", "{감정}"],
    "style_tone": "밝고 경쾌",
    "style_vibe": "MZ"
  }
]
''';
    } else if (prompt.contains('Plan JSON')) {
      return '''
{
  "goal_duration_min": 8,
  "buffer_rate": 0.12,
  "chapters": [
    {"id":"opening_gate","alloc_sec":35,"alternatives":[]},
    {"id":"move_in","alloc_sec":30,"alternatives":["move_cutaway"]},
    {"id":"main_ride_queue","alloc_sec":45,"alternatives":["map_board_reaction"]},
    {"id":"main_ride_pov","alloc_sec":90,"alternatives":["main_ride_vo"]},
    {"id":"reaction_post_ride","alloc_sec":25,"alternatives":["reaction_text_overlay"]},
    {"id":"food_snack","alloc_sec":35,"alternatives":["food_insert_only"]},
    {"id":"photo_spot","alloc_sec":40,"alternatives":["alt_background"]},
    {"id":"rest_bench","alloc_sec":30,"alternatives":["standing_rest"]},
    {"id":"ending_exit","alloc_sec":35,"alternatives":["sign_static_vo"]}
  ]
}
''';
    } else {
      return '''
## 오월드 도착!  ⏱ 30s | 🏷 entrance

**요약**
- 오월드 도착! · 친구들과 함께!
- 게이트 앞에서 소개

**스텝 (3)**
1) 게이트 앞 서기
2) 소개 멘트 하기
3) 마이크 체크

**체크 (3)**
- 노출 고정
- 마이크 확인
- 포커스 락

**대안**
- 셀카로 짧게

**힌트**
- ▶ 시작: 표지판 앞 시작
- ⏹ 정지: 소개 끝
- 🎯 완료: 인사 완료·친구 2명 등장

**스타일**
- 톤: 밝고 경쾌 / 바이브: 캐주얼 / 타깃: 20대 친구

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 상1/3 구도
- 무브먼트: 고정3초
- 노출/포커스: AE/AF 고정

**오디오(Pro)**
- 입 30~40cm

**대화/나레이션**
- "오월드 왔다!"
- "오늘 코스는?"
- "함께한 친구는?"

**편집 힌트**
- 인서트→멘트

**안전/권한**
- 통행 방해 금지

**B-roll 제안**
- 입구 간판
- 티켓 손샷
- 손 인사
</details>

## 들어가면서 걷기  ⏱ 20s | 🏷 moving

**요약**
- 들어가며 걷기 · 풍경 즐기기
- 친구와 대화

**스텝 (3)**
1) 친구와 걷기
2) 경치 둘러보기
3) 가볍게 대화

**체크 (3)**
- 흔들림 방지
- 노출 확인
- OK

**대안**
- 풍경만 스케치

**힌트**
- ▶ 시작: 통과 직후 시작
- ⏹ 정지: 첫 어트 보일 때
- 🎯 완료: 10–20초 워킹·배경 전환

**스타일**
- 톤: 경쾌·활기찬 / 바이브: MZ / 타깃: 20대 친구

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: POV 중앙선
- 무브먼트: 부드럽게 워킹
- 노출/포커스: AE/AF 고정

**오디오(Pro)**
- 바람 가리고 말하기

**대화/나레이션**
- "첫인상 어때?"
- "가장 기대는?"
- "오늘 목표는?"

**편집 힌트**
- 워킹 5초 컷

**안전/권한**
- 보행자 우선

**B-roll 제안**
- 발걸음
- 표지판 스윕
- 좌우 풍경
</details>

## 줄 서며 대기  ⏱ 40s | 🏷 queue

**요약**
- 줄 서며 대기 · 친구와 대화
- 기대감 표현

**스텝 (3)**
1) 둘러보기
2) 친구와 대화
3) 카메라 멘트

**체크 (3)**
- 포커스 락
- 노출 고정
- 주변 동의

**대안**
- 음식/사물만 촬영

**힌트**
- ▶ 시작: 줄 시작 시
- ⏹ 정지: 안전요원 근접
- 🎯 완료: 3–4문장·줄 분위기

**스타일**
- 톤: 자연·편안 / 바이브: 일상 / 타깃: 20대 친구

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 허리~가슴샷
- 무브먼트: 고정+리액션
- 노출/포커스: AE/AF 고정

**오디오(Pro)**
- 소음 피해서 말해

**대화/나레이션**
- "대기 몇 분?"
- "기대 포인트?"
- "초보 팁은?"

**편집 힌트**
- 대화 키컷

**안전/권한**
- 줄 이탈 금지

**B-roll 제안**
- 안내 표지
- 기구 전경
- 대기줄 발
</details>

## 놀이기구 탑승  ⏱ 90s | 🏷 main_ride

**요약**
- 놀이기구 탑승 · 긴장감 즐기기
- 감정 표현

**스텝 (3)**
1) 긴장 멘트
2) 안전바 내리기
3) 요원 보며 웃기

**체크 (3)**
- 포커스 락
- 손떨림 방지
- OK

**대안**
- 외부 전경 컷

**힌트**
- ▶ 시작: 좌석 앉자마자
- ⏹ 정지: 작동 직전
- 🎯 완료: 전후 촬영·표정 클로즈업

**스타일**
- 톤: 기대감·긴장 / 바이브: 시네마틱 / 타깃: 20대 친구

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 얼굴+안전바
- 무브먼트: 고정 촬영
- 노출/포커스: AE/AF 고정

**오디오(Pro)**
- 레벨 확인 후 말해

**대화/나레이션**
- "시작 전 한마디"
- "지금 심정은?"
- "끝나면 뭐함?"

**편집 힌트**
- 스타트음에 컷

**안전/권한**
- 촬영 규정 준수

**B-roll 제안**
- 바퀴·레일
- 안전수칙 표
- 관중 환호
</details>

## 탑승 후 소감  ⏱ 30s | 🏷 post_ride

**요약**
- 탑승 후 소감 · 놀란 표정 포착
- 짧은 감상평

**스텝 (3)**
1) 숨 고르기
2) 놀란 표정
3) 소감 한마디

**체크 (3)**
- 흔들림 방지
- 소리 조절
- OK

**대안**
- 자막 코멘트

**힌트**
- ▶ 시작: 하차 직후
- ⏹ 정지: 소감 끝
- 🎯 완료: 표정 클로즈업·짧은 감상평

**스타일**
- 톤: 신나고 유쾌 / 바이브: MZ / 타깃: 20대 친구

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 페이스샷 근접
- 무브먼트: 짧게 핸드헬드
- 노출/포커스: 얼굴 우선

**오디오(Pro)**
- 숨 고르고 말해

**대화/나레이션**
- "점수는 몇 점?"
- "제일 무서웠던?"
- "다시 탈래?"

**편집 힌트**
- 리액션→컷

**안전/권한**
- 통행로 비켜

**B-roll 제안**
- 안전바 손
- 하이파이브
- 기구 멀리샷
</details>

## 간식 먹방  ⏱ 50s | 🏷 snack

**요약**
- 간식 먹방 · 맛 표현하기
- 한입 리액션

**스텝 (3)**
1) 음식 클로즈업
2) 한 입 먹기
3) 맛 한줄 평가

**체크 (3)**
- 음식 포커스
- 조명 확인
- OK

**대안**
- 음식 접사 대체

**힌트**
- ▶ 시작: 받자마자
- ⏹ 정지: 한입 끝
- 🎯 완료: 먹는 소리·짧은 맛 설명

**스타일**
- 톤: 맛있고 따뜻함 / 바이브: 일상 / 타깃: 20대 친구

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 음식 근접
- 무브먼트: 살짝 회전
- 노출/포커스: WB 확인

**오디오(Pro)**
- 씹는 소리 적당

**대화/나레이션**
- "첫맛은 어때?"
- "식감 어때?"
- "가성비 어때?"

**편집 힌트**
- 한입에 컷

**안전/권한**
- 매장 동선 배려

**B-roll 제안**
- 메뉴판
- 가격표
- 손 한입 샷
</details>

## 벤치에서 휴식  ⏱ 45s | 🏷 rest_area

**요약**
- 벤치에서 휴식 · 친구와 이야기
- 정리 대화

**스텝 (3)**
1) 음료 마시기
2) 정리 대화
3) 풍경 찍기

**체크 (3)**
- 고정 촬영
- 음량 확인
- OK

**대안**
- 풍경만 촬영

**힌트**
- ▶ 시작: 앉자마자
- ⏹ 정지: 이동 전
- 🎯 완료: 5–10문장·친구 2명

**스타일**
- 톤: 평화·차분 / 바이브: 시네마틱 / 타깃: 20대 친구

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 투샷 중앙
- 무브먼트: 고정 롱테이크
- 노출/포커스: AE/AF 고정

**오디오(Pro)**
- 주변 소음 최소

**대화/나레이션**
- "오늘 하이라이트?"
- "힘들었던 점?"
- "다음 계획은?"

**편집 힌트**
- 대화 호흡컷

**안전/권한**
- 주변 손님 배려

**B-roll 제안**
- 음료 컵샷
- 손 제스처
- 벤치 표식
</details>

## 포토존에서 사진  ⏱ 45s | 🏷 photo_spot

**요약**
- 포토존에서 사진 · 인생샷 남기기
- 다양한 포즈

**스텝 (3)**
1) 친구 2명 포즈
2) 카메라 보고 웃기
3) 다양한 구도

**체크 (3)**
- 노출 고정
- 손떨림 방지
- OK

**대안**
- 배경만 촬영

**힌트**
- ▶ 시작: 발견 즉시
- ⏹ 정지: 촬영 완료
- 🎯 완료: 다양한 포즈·장소 특색

**스타일**
- 톤: 신나고 유쾌 / 바이브: MZ / 타깃: 20대 친구

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 배경 정리
- 무브먼트: 포즈 전환
- 노출/포커스: 고정

**오디오(Pro)**
- 현장 소리 짧게

**대화/나레이션**
- "이 장소 포인트?"
- "포즈 컨셉은?"
- "한마디 외치기"

**편집 힌트**
- 베스트샷 2컷

**안전/권한**
- 길막 금지

**B-roll 제안**
- 장소 표식
- 포즈 실루엣
- 돌아보기 샷
</details>

## 마지막 인사  ⏱ 20s | 🏷 exit

**요약**
- 마지막 인사 · 오늘의 소감
- 다음 예고

**스텝 (3)**
1) 출구 앞 서기
2) 소감 말하기
3) 다음 예고

**체크 (3)**
- 마이크 확인
- 노출 고정
- OK

**대안**
- 간판 정지컷

**힌트**
- ▶ 시작: 출구 앞 시작
- ⏹ 정지: 인사 끝
- 🎯 완료: 감상평 완료·친구 2명

**스타일**
- 톤: 따뜻·감동적 / 바이브: 시네마틱 / 타깃: 20대 친구

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 중앙+출구
- 무브먼트: 고정3초
- 노출/포커스: AE/AF 고정

**오디오(Pro)**
- 바람 등지고 말해

**대화/나레이션**
- "오늘 어땠나?"
- "하이라이트는?"
- "다음은 어디?"

**편집 힌트**
- 자막 엔드

**안전/권한**
- 통행 방해 금지

**B-roll 제안**
- 출구 간판
- 하늘 스윕
- 퇴장 발샷
</details>

---

### 들어가면서 걷기  ⏱ 20s | 🏷 moving

**요약**: 들어가며 걷기 · 풍경 즐기기
**스텝**: 친구와 걷기 · 경치 둘러보기 · 가볍게 대화
**체크**: 흔들림 방지 · 노출 확인 · OK
**대안**: 풍경만 스케치
**힌트**: ▶ 통과 직후 시작 | ⏹ 첫 어트 보일 때 | 🎯 10–20초 워킹·배경 전환
**스타일**: 경쾌·활기찬 / MZ / 20대 친구
**Pro**: 프레임 POV 중앙선 · 무브 부드럽게 워킹 · 노출 AE/AF고정 | 오디오 바람 가리고 말하기 | 대화 첫인상 어때? / 가장 기대는? / 오늘 목표는? | 편집 워킹 5초 컷 | 안전 보행자 우선 | B-roll 발걸음 / 표지판 스윕 / 좌우 풍경

---

### 줄 서며 대기  ⏱ 40s | 🏷 queue

**요약**: 줄 서며 대기 · 친구와 대화
**스텝**: 둘러보기 · 친구와 대화 · 카메라 멘트
**체크**: 포커스 락 · 노출 고정 · 주변 동의
**대안**: 음식/사물만 촬영
**힌트**: ▶ 줄 시작 시 | ⏹ 안전요원 근접 | 🎯 3–4문장·줄 분위기
**스타일**: 자연·편안 / 일상 / 20대 친구
**Pro**: 프레임 허리~가슴샷 · 무브 고정+리액션 · 노출 AE/AF고정 | 오디오 소음 피해서 말해 | 대화 대기 몇 분? / 기대 포인트? / 초보 팁은? | 편집 대화 키컷 | 안전 줄 이탈 금지 | B-roll 안내 표지 / 기구 전경 / 대기줄 발

---

### 놀이기구 탑승  ⏱ 90s | 🏷 main_ride

**요약**: 놀이기구 탑승 · 긴장감 즐기기
**스텝**: 긴장 멘트 · 안전바 내리기 · 요원 보며 웃기
**체크**: 포커스 락 · 손떨림 방지 · OK
**대안**: 외부 전경 컷
**힌트**: ▶ 좌석 앉자마자 | ⏹ 작동 직전 | 🎯 전후 촬영·표정 클로즈업
**스타일**: 기대감·긴장 / 시네마틱 / 20대 친구
**Pro**: 프레임 얼굴+안전바 · 무브 고정 촬영 · 노출 AE/AF고정 | 오디오 레벨 확인 후 말해 | 대화 시작 전 한마디 / 지금 심정은? / 끝나면 뭐함? | 편집 스타트음에 컷 | 안전 촬영 규정 준수 | B-roll 바퀴·레일 / 안전수칙 표 / 관중 환호

---

### 탑승 후 소감  ⏱ 30s | 🏷 post_ride

**요약**: 탑승 후 소감 · 놀란 표정 포착
**스텝**: 숨 고르기 · 놀란 표정 · 소감 한마디
**체크**: 흔들림 방지 · 소리 조절 · OK
**대안**: 자막 코멘트
**힌트**: ▶ 하차 직후 | ⏹ 소감 끝 | 🎯 표정 클로즈업·짧은 감상평
**스타일**: 신나고 유쾌 / MZ / 20대 친구
**Pro**: 프레임 페이스샷 근접 · 무브 짧게 핸드헬드 · 노출 얼굴 우선 | 오디오 숨 고르고 말해 | 대화 점수는 몇 점? / 제일 무서웠던? / 다시 탈래? | 편집 리액션→컷 | 안전 통행로 비켜 | B-roll 안전바 손 / 하이파이브 / 기구 멀리샷

---

### 간식 먹방  ⏱ 50s | 🏷 snack

**요약**: 간식 먹방 · 맛 표현하기
**스텝**: 음식 클로즈업 · 한 입 먹기 · 맛 한줄 평가
**체크**: 음식 포커스 · 조명 확인 · OK
**대안**: 음식 접사 대체
**힌트**: ▶ 받자마자 | ⏹ 한입 끝 | 🎯 먹는 소리·짧은 맛 설명
**스타일**: 맛있고 따뜻함 / 일상 / 20대 친구
**Pro**: 프레임 음식 근접 · 무브 살짝 회전 · 노출 WB 확인 | 오디오 씹는 소리 적당 | 대화 첫맛은 어때? / 식감 어때? / 가성비 어때? | 편집 한입에 컷 | 안전 매장 동선 배려 | B-roll 메뉴판 / 가격표 / 손 한입 샷

---

### 벤치에서 휴식  ⏱ 45s | 🏷 rest_area

**요약**: 벤치에서 휴식 · 친구와 이야기
**스텝**: 음료 마시기 · 정리 대화 · 풍경 찍기
**체크**: 고정 촬영 · 음량 확인 · OK
**대안**: 풍경만 촬영
**힌트**: ▶ 앉자마자 | ⏹ 이동 전 | 🎯 5–10문장·친구 2명
**스타일**: 평화·차분 / 시네마틱 / 20대 친구
**Pro**: 프레임 투샷 중앙 · 무브 고정 롱테이크 · 노출 AE/AF고정 | 오디오 주변 소음 최소 | 대화 오늘 하이라이트? / 힘들었던 점? / 다음 계획은? | 편집 대화 호흡컷 | 안전 주변 손님 배려 | B-roll 음료 컵샷 / 손 제스처 / 벤치 표식

---

### 포토존에서 사진  ⏱ 45s | 🏷 photo_spot

**요약**: 포토존에서 사진 · 인생샷 남기기
**스텝**: 친구 2명 포즈 · 카메라 보고 웃기 · 다양한 구도
**체크**: 노출 고정 · 손떨림 방지 · OK
**대안**: 배경만 촬영
**힌트**: ▶ 발견 즉시 | ⏹ 촬영 완료 | 🎯 다양한 포즈·장소 특색
**스타일**: 신나고 유쾌 / MZ / 20대 친구
**Pro**: 프레임 배경 정리 · 무브 포즈 전환 · 노출 고정 | 오디오 현장 소리 짧게 | 대화 이 장소 포인트? / 포즈 컨셉은? / 한마디 외치기 | 편집 베스트샷 2컷 | 안전 길막 금지 | B-roll 장소 표식 / 포즈 실루엣 / 돌아보기 샷

---

### 두 번째 대기  ⏱ 40s | 🏷 queue

**요약**: 두 번째 대기 · 기대감 표현
**스텝**: 주변 둘러보기 · 웃는 대화 · 카메라 장난
**체크**: 포커스 락 · 노출 고정 · 주변 동의
**대안**: 음식/사물만 촬영
**힌트**: ▶ 2번째 줄 시작 | ⏹ 탑승 직전 | 🎯 줄 분위기·짧은 대화
**스타일**: 자연·편안 / 일상 / 20대 친구
**Pro**: 프레임 허리샷 투샷 · 무브 고정 리액션 · 노출 AE/AF고정 | 오디오 소음 피해서 말해 | 대화 이번 각오는? / 얼마나 남았나? / 팁 한줄 말해 | 편집 대화 하이라이트 | 안전 타인 동의 주의 | B-roll 시간 안내판 / 신발 리듬샷 / 표정 클로즈업

---

### 두 번째 놀이기구  ⏱ 70s | 🏷 main_ride

**요약**: 두 번째 놀이기구 · 짜릿한 순간 포착
**스텝**: 긴장 멘트 · 안전바 내리기 · 출발 신호 대기
**체크**: 포커스 락 · 손떨림 방지 · OK
**대안**: 외부 전경 컷
**힌트**: ▶ 2번째 좌석 착석 | ⏹ 작동 직전 | 🎯 탑승 직전 촬영·표정 변화
**스타일**: 기대감·긴장 / 시네마틱 / 20대 친구
**Pro**: 프레임 얼굴+안전바 · 무브 고정 촬영 · 노출 AE/AF고정 | 오디오 레벨 과다 주의 | 대화 두근두근! / 살짝 떨린다 / 끝나고 뭐함? | 편집 출발음에 컷 | 안전 촬영 규정 준수 | B-roll 트랙 전경 / 표정 클로즈업 / 안전수칙 표

---

### 마지막 인사  ⏱ 20s | 🏷 exit

**요약**: 마지막 인사 · 오늘의 소감
**스텝**: 출구 앞 서기 · 소감 말하기 · 다음 예고
**체크**: 마이크 확인 · 노출 고정 · OK
**대안**: 간판 정지컷
**힌트**: ▶ 출구 앞 시작 | ⏹ 인사 끝 | 🎯 감상평 완료·친구 2명
**스타일**: 따뜻·감동적 / 시네마틱 / 20대 친구
**Pro**: 프레임 중앙+출구 · 무브 고정3초 · 노출 AE/AF고정 | 오디오 바람 등지고 말해 | 대화 오늘 어땠나? / 하이라이트는? / 다음은 어디? | 편집 자막 엔드 | 안전 통행 방해 금지 | B-roll 출구 간판 / 하늘 스윕 / 퇴장 발샷
- 노출 고정
- 마이크 확인
- 포커스 락

**대안**
- 사람 많으면 인서트 촬영

**힌트**
- ▶ 시작: 표지판 보일 때
- ⏹ 정지: 나레이션 완료
- 🎯 완료: 표지판 + 나레이션

**스타일**
- 톤: 밝고 경쾌 / 바이브: MZ / 타깃: 20대

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 상1/3 구도
- 무브먼트: 워킹 최소
- 노출/포커스: AE/AF 고정

**오디오(Pro)**
- 입 30~40cm

**대화/나레이션**
- "드디어 도착했어요!"
- "오늘 날씨 완전 좋네요"
- "기대돼요!"

**편집 힌트**
- 인서트→점프컷

**안전/권한**
- 통행 방해 금지

**B-roll 제안**
- 표지판 클로즈업
- 하늘 촬영
- 발걸음
</details>

## 메인 어트랙션 대기
> ⏱ 45s | 🏷 Trigger: `queue`

**요약**
- 대기 상황 촬영
- 기대감 나레이션

**스텝 (3)**
1) 대기열 위치 확인
2) 미드→클로즈업 촬영
3) 기대감 표현

**체크 (3)**
- 노출 고정
- 마이크 확인
- 포커스 락

**대안**
- 대기 시간 길면 컷어웨이

**힌트**
- ▶ 시작: 대기열 도착
- ⏹ 정지: 탑승 직전
- 🎯 완료: 대기 + 기대감

**스타일**
- 톤: 밝고 경쾌 / 바이브: MZ / 타깃: 20대

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 중앙 구도
- 무브먼트: 정적 촬영
- 노출/포커스: AE/AF 고정

**오디오(Pro)**
- 입 20~30cm

**대화/나레이션**
- "대기 시간 얼마나 될까요?"
- "정말 기대돼요!"
- "사람들이 많네요"

**편집 힌트**
- 점프컷→슬로우모션

**안전/권한**
- 대기열 순서 준수

**B-roll 제안**
- 대기열 전체
- 시계 촬영
- 주변 풍경
</details>

## 어트랙션 탑승
> ⏱ 90s | 🏷 Trigger: `main_ride`

**요약**
- 탑승 과정 촬영
- 감정 표현

**스텝 (3)**
1) 안전장치 착용
2) POV 촬영 시작
3) 감정 표현

**체크 (3)**
- 안전 고정
- 마이크 확인
- 포커스 락

**대안**
- 촬영 금지시 VO 녹음

**힌트**
- ▶ 시작: 탑승 시
- ⏹ 정지: 하차 시
- 🎯 완료: 탑승 + 감정

**스타일**
- 톤: 밝고 경쾌 / 바이브: MZ / 타깃: 20대

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: POV 고정
- 무브먼트: 최소화
- 노출/포커스: AE/AF 고정

**오디오(Pro)**
- 마이크 음소거

**대화/나레이션**
- "와! 정말 재미있어요!"
- "어떻게 이렇게 빠를 수 있어요?"
- "다시 타고 싶어요!"

**편집 힌트**
- 액션→슬로우모션

**안전/권한**
- 안전장치 필수 착용

**B-roll 제안**
- 탑승 전 표정
- 하차 후 표정
- 어트랙션 전체
</details>
''';
    }
  }

  // ============================================================================
  // 재생성 기능 (Regeneration)
  // ============================================================================

  /// 개별 씬 재생성
  ///
  /// 기존 씬 데이터 + 사용자 수정사항을 기반으로 해당 씬만 다시 생성
  static Future<CueCard?> regenerateScene({
    required CueCard originalScene,
    required String userFeedback,
    required Plan plan,
  }) async {
    try {
      print('[OPENAI_API] 씬 재생성 시작: ${originalScene.title}');
      print('[OPENAI_API] 수정사항: $userFeedback');

      // 프롬프트 구성
      final prompt = '''
다음은 브이로그의 한 씬입니다. 사용자가 수정 요청을 했으니 이를 반영하여 씬을 재생성해주세요.

[기존 씬 정보]
- 제목: ${originalScene.title}
- 요약: ${originalScene.summary.join(' ')}
- 할당 시간: ${originalScene.allocatedSec}초
- 기존 script: ${originalScene.script ?? '없음'}

[브이로그 전체 컨텍스트]
- 제목: ${plan.vlogTitle}
- 톤: ${plan.styleAnalysis?.tone ?? '밝고 경쾌'}
- 바이브: ${plan.styleAnalysis?.vibe ?? 'MZ'}
- 총 길이: ${plan.goalDurationMin}분

[사용자 수정사항]
$userFeedback

위 수정사항을 반영하여 씬을 재생성해주세요. 반드시 다음 형식으로 출력하세요:

<scene>
<title>씬 제목</title>
<summary>
- 요약 1
- 요약 2
- 요약 3
</summary>
<allocated_sec>${originalScene.allocatedSec}</allocated_sec>
<script>
screenplay 형태의 대본 (기존 형태와 동일하게)
</script>
</scene>

**중요**:
- 할당 시간(${originalScene.allocatedSec}초)은 유지하세요
- script는 screenplay 형태로 작성하세요
- 사용자 수정사항을 최대한 반영하세요
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a vlog scene editor who regenerates scenes based on user feedback.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        print('[OPENAI_API] 씬 재생성 완료');

        // 파싱
        final titleMatch = RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(content);
        final summaryMatch = RegExp(r'<summary>(.*?)</summary>', dotAll: true).firstMatch(content);
        final scriptMatch = RegExp(r'<script>(.*?)</script>', dotAll: true).firstMatch(content);

        if (titleMatch == null || summaryMatch == null) {
          print('[OPENAI_API] 씬 파싱 실패');
          return null;
        }

        final title = titleMatch.group(1)!.trim();
        final summaryText = summaryMatch.group(1)!.trim();
        final script = scriptMatch?.group(1)?.trim();

        // summary 파싱 (- 로 시작하는 줄들)
        final summaryLines = summaryText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.startsWith('-'))
            .map((line) => line.substring(1).trim())
            .toList();

        // 새로운 CueCard 생성
        return CueCard(
          title: title,
          summary: summaryLines.isNotEmpty ? summaryLines : [summaryText],
          allocatedSec: originalScene.allocatedSec,
          trigger: originalScene.trigger,
          steps: [],
          checklist: originalScene.checklist,
          fallback: originalScene.fallback,
          startHint: originalScene.startHint,
          stopHint: originalScene.stopHint,
          completionCriteria: originalScene.completionCriteria,
          tone: originalScene.tone,
          styleVibe: originalScene.styleVibe,
          targetAudience: originalScene.targetAudience,
          script: script ?? '',
          pro: originalScene.pro,
          rawMarkdown: originalScene.rawMarkdown,
          thumbnailUrl: originalScene.thumbnailUrl, // 기존 이미지 유지
        );
      } else {
        print('[OPENAI_API] 씬 재생성 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[OPENAI_API] 씬 재생성 예외: $e');
      return null;
    }
  }

  /// 전체 스토리보드 재생성
  ///
  /// 기존 스토리보드 + 사용자 수정사항을 기반으로 전체를 다시 생성
  static Future<({Plan? plan, List<CueCard>? cueCards})?> regenerateStoryboard({
    required Plan originalPlan,
    required List<CueCard> originalCueCards,
    required String userFeedback,
    required Map<String, String> userInput,
  }) async {
    try {
      print('[OPENAI_API] 스토리보드 재생성 시작');
      print('[OPENAI_API] 수정사항: $userFeedback');

      // 기존 씬 정보를 문자열로 변환
      final existingScenes = originalCueCards
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value.title} (${e.value.allocatedSec}초): ${e.value.summary.join(' ')}')
          .join('\n');

      // 프롬프트 구성
      final prompt = '''
다음은 이미 생성된 브이로그 스토리보드입니다. 사용자가 수정을 요청했으니 이를 반영하여 스토리보드를 재생성해주세요.

[기존 스토리보드]
제목: ${originalPlan.vlogTitle}
키워드: ${originalPlan.keywords.join(', ')}
목표 시간: ${originalPlan.goalDurationMin}분
톤: ${originalPlan.styleAnalysis?.tone ?? '밝고 경쾌'}

[기존 씬 구성]
$existingScenes

[사용자 입력]
- 장소: ${userInput['location'] ?? ''}
- 방문 목적: ${userInput['visit_context'] ?? ''}
- 촬영 시간: ${userInput['time_weather'] ?? ''}
- 장비: ${userInput['equipment'] ?? 'smartphone'}

[사용자 수정사항]
$userFeedback

위 수정사항을 반영하여 스토리보드를 재생성해주세요.
**주의**: 수정사항에 따라 씬의 개수, 순서, 내용이 변경될 수 있습니다.

반드시 기존과 동일한 JSON 형식으로 출력하세요 (이전에 사용했던 fine-tuned model 출력 형식).
''';

      // Fine-tuned model로 재생성
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'model': _fineTunedModel,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a vlog storyboard generator that creates detailed shooting plans.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 4000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final storyboard = data['choices'][0]['message']['content'] as String;

        print('[OPENAI_API] 스토리보드 재생성 완료');

        // JSON 파싱하여 Map으로 변환
        final storyboardMap = jsonDecode(storyboard) as Map<String, dynamic>;
        
        // 기존 parseStoryboard 메서드를 사용하여 파싱
        final result = await parseStoryboard(storyboardMap);

        if (result == null || result.plan == null || result.cueCards == null) {
          print('[OPENAI_API] 스토리보드 파싱 실패');
          return null;
        }

        return result;
      } else {
        print('[OPENAI_API] 스토리보드 재생성 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[OPENAI_API] 스토리보드 재생성 예외: $e');
      return null;
    }
  }
}
