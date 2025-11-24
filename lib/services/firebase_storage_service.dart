import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

/// Firebase Storage에 이미지를 업로드하는 서비스
class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// DALL-E 이미지 URL을 다운로드하여 Firebase Storage에 업로드
  ///
  /// [imageUrl] DALL-E에서 생성된 이미지 URL
  /// [path] Firebase Storage 경로 (예: "composition_images/scene_1/checklist_0.png")
  /// Returns: Firebase Storage 다운로드 URL
  Future<String?> uploadImageFromUrl({
    required String imageUrl,
    required String path,
  }) async {
    try {
      print('[FIREBASE_STORAGE] 이미지 다운로드 시작: $imageUrl');
      
      // 1. 이미지 다운로드
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        print('[FIREBASE_STORAGE] 이미지 다운로드 실패: ${response.statusCode}');
        return null;
      }

      print('[FIREBASE_STORAGE] 이미지 다운로드 완료 (${response.bodyBytes.length} bytes)');

      // 2. Firebase Storage에 업로드
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putData(
        response.bodyBytes,
        SettableMetadata(
          contentType: 'image/png',
          cacheControl: 'public, max-age=31536000', // 1년 캐시
        ),
      );

      print('[FIREBASE_STORAGE] Firebase Storage 업로드 시작...');
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('[FIREBASE_STORAGE] Firebase Storage 업로드 완료: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('[FIREBASE_STORAGE] 이미지 업로드 오류: $e');
      return null;
    }
  }

  /// 로컬 파일을 Firebase Storage에 업로드
  ///
  /// [file] 로컬 파일
  /// [path] Firebase Storage 경로
  /// Returns: Firebase Storage 다운로드 URL
  Future<String?> uploadFile({
    required File file,
    required String path,
  }) async {
    try {
      print('[FIREBASE_STORAGE] 파일 업로드 시작: ${file.path}');
      
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/png',
          cacheControl: 'public, max-age=31536000',
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('[FIREBASE_STORAGE] 파일 업로드 완료: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('[FIREBASE_STORAGE] 파일 업로드 오류: $e');
      return null;
    }
  }

  /// Firebase Storage에서 파일 삭제
  ///
  /// [path] Firebase Storage 경로
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
      print('[FIREBASE_STORAGE] 파일 삭제 완료: $path');
    } catch (e) {
      print('[FIREBASE_STORAGE] 파일 삭제 오류: $e');
    }
  }
}

