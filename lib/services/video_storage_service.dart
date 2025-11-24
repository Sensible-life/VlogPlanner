import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 비디오 파일 저장 및 관리 서비스
/// 파일명 형식: scene_{씬번호}_take_{테이크번호}_{timestamp}.mp4
class VideoStorageService {
  /// 표준화된 파일명 생성
  /// 예: scene_03_take_02_20250117_143022.mp4
  static String generateFileName({
    required int sceneNumber,
    required int takeNumber,
  }) {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final sceneStr = sceneNumber.toString().padLeft(2, '0');
    final takeStr = takeNumber.toString().padLeft(2, '0');
    
    return 'scene_${sceneStr}_take_${takeStr}_$timestamp.mp4';
  }

  /// 비디오 파일을 앱 디렉토리에 저장
  static Future<String> saveVideo({
    required String sourcePath,
    required int sceneNumber,
    required int takeNumber,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${directory.path}/videos');
      
      // 비디오 디렉토리가 없으면 생성
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }
      
      // 표준화된 파일명 생성
      final fileName = generateFileName(
        sceneNumber: sceneNumber,
        takeNumber: takeNumber,
      );
      
      final destinationPath = '${videosDir.path}/$fileName';
      
      // 파일 복사
      final sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);
      
      return destinationPath;
    } catch (e) {
      print('비디오 저장 오류: $e');
      rethrow;
    }
  }

  /// 특정 씬의 모든 Take 비디오 검색
  /// 파일명 패턴 매칭으로 같은 씬 번호를 가진 비디오들을 찾아 최신순으로 정렬
  static Future<List<File>> getPreviousTakes({
    required int sceneNumber,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${directory.path}/videos');
      
      if (!await videosDir.exists()) {
        return [];
      }
      
      // 씬 번호 패턴 (예: scene_03)
      final sceneStr = sceneNumber.toString().padLeft(2, '0');
      final pattern = RegExp(r'^scene_' + sceneStr + r'_take_\d+_\d+_\d+\.mp4$');
      
      // 해당 씬의 모든 비디오 파일 찾기
      final videoFiles = <File>[];
      await for (final entity in videosDir.list()) {
        if (entity is File && pattern.hasMatch(entity.path.split('/').last)) {
          videoFiles.add(entity);
        }
      }
      
      // 파일명으로 정렬 (최신순)
      videoFiles.sort((a, b) {
        final aName = a.path.split('/').last;
        final bName = b.path.split('/').last;
        return bName.compareTo(aName); // 역순 정렬 (최신이 먼저)
      });
      
      return videoFiles;
    } catch (e) {
      print('이전 Take 검색 오류: $e');
      return [];
    }
  }

  /// 특정 씬의 다음 Take 번호 계산
  static Future<int> getNextTakeNumber({
    required int sceneNumber,
  }) async {
    final previousTakes = await getPreviousTakes(sceneNumber: sceneNumber);
    
    if (previousTakes.isEmpty) {
      return 1;
    }
    
    // 가장 최신 Take 파일명에서 번호 추출
    final latestFileName = previousTakes.first.path.split('/').last;
    final takeMatch = RegExp(r'take_(\d+)').firstMatch(latestFileName);
    
    if (takeMatch != null) {
      final currentTake = int.tryParse(takeMatch.group(1) ?? '0') ?? 0;
      return currentTake + 1;
    }
    
    return 1;
  }

  /// 파일명에서 씬 번호 추출
  static int? extractSceneNumber(String fileName) {
    final match = RegExp(r'scene_(\d+)').firstMatch(fileName);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// 파일명에서 Take 번호 추출
  static int? extractTakeNumber(String fileName) {
    final match = RegExp(r'take_(\d+)').firstMatch(fileName);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// 특정 비디오 파일 삭제
  static Future<void> deleteVideo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('비디오 삭제 오류: $e');
      rethrow;
    }
  }

  /// 모든 비디오 파일 목록 가져오기
  static Future<List<File>> getAllVideos() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${directory.path}/videos');
      
      if (!await videosDir.exists()) {
        return [];
      }
      
      final videoFiles = <File>[];
      await for (final entity in videosDir.list()) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          videoFiles.add(entity);
        }
      }
      
      // 최신순 정렬
      videoFiles.sort((a, b) {
        final aName = a.path.split('/').last;
        final bName = b.path.split('/').last;
        return bName.compareTo(aName);
      });
      
      return videoFiles;
    } catch (e) {
      print('비디오 목록 가져오기 오류: $e');
      return [];
    }
  }
}
