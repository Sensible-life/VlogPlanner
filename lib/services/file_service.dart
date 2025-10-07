import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileService {
  static Future<String?> saveResponseToFile({
    required String fileName,
    required String content,
    String? subDirectory,
  }) async {
    try {
      // 플랫폼에 따라 저장 위치 결정
      Directory directory;
      if (Platform.isAndroid) {
        // Android에서는 외부 저장소 사용
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            print('[FILE_SERVICE] 저장소 권한이 거부되었습니다. 앱 문서 디렉토리 사용');
            directory = await getApplicationDocumentsDirectory();
          } else {
            // 권한 승인 시 Download 폴더 사용
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              directory = await getApplicationDocumentsDirectory();
            }
          }
        } else {
          // 권한이 이미 있는 경우 Download 폴더 사용
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getApplicationDocumentsDirectory();
          }
        }
        print('[FILE_SERVICE] Android 저장 디렉토리: ${directory.path}');
      } else {
        // 데스크탑에서는 현재 작업 디렉토리 사용
        directory = Directory.current;
        print('[FILE_SERVICE] 데스크탑 현재 디렉토리: ${directory.path}');
      }

      // 서브 디렉토리 생성
      if (subDirectory != null) {
        directory = Directory('${directory.path}/$subDirectory');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }

      // 파일 생성
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);
      
      print('[FILE_SERVICE] 파일 저장 완료: ${file.path}');
      return file.path;
    } catch (e) {
      print('[FILE_SERVICE] 파일 저장 중 오류: $e');
      return null;
    }
  }

  static Future<String?> saveCueCardResponse({
    required String templateResponse,
    required String planResponse,
    required String cueCardResponse,
    required List<Map<String, dynamic>> cueCards,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cue_card_response_$timestamp.md';
      
      String content = '''# 큐카드 생성 결과

## 생성 시간
${DateTime.now().toString()}

## 1. 템플릿 응답
\`\`\`
$templateResponse
\`\`\`

## 2. 계획 응답
\`\`\`
$planResponse
\`\`\`

## 3. 최종 큐카드 응답
\`\`\`
$cueCardResponse
\`\`\`

## 4. 파싱된 큐카드 데이터
\`\`\`json
${cueCards.map((card) => card.toString()).join('\n')}
\`\`\`

## 5. 큐카드 요약
총 ${cueCards.length}개의 큐카드가 생성되었습니다.

''';

      return await saveResponseToFile(
        fileName: fileName,
        content: content,
        subDirectory: 'responses',
      );
    } catch (e) {
      print('[FILE_SERVICE] 큐카드 응답 저장 중 오류: $e');
      return null;
    }
  }

  static Future<String?> saveRawResponse({
    required String response,
    required String type,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${type}_response_$timestamp.txt';
      
      return await saveResponseToFile(
        fileName: fileName,
        content: response,
        subDirectory: 'responses',
      );
    } catch (e) {
      print('[FILE_SERVICE] 원본 응답 저장 중 오류: $e');
      return null;
    }
  }
}
