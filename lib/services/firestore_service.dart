import 'package:cloud_firestore/cloud_firestore.dart';
import 'vlog_data_service.dart';

/// Firestore와 상호작용하는 서비스 클래스
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 컬렉션 이름
  static const String _storyboardsCollection = 'storyboards';

  /// 스토리보드를 Firestore에 저장
  ///
  /// [storyboard] 저장할 스토리보드
  /// Returns: 저장된 문서 ID
  Future<String> saveStoryboard(SavedStoryboard storyboard) async {
    try {
      final docRef = await _firestore
          .collection(_storyboardsCollection)
          .add(storyboard.toJson());

      return docRef.id;
    } catch (e) {
      throw Exception('스토리보드 저장 실패: $e');
    }
  }

  /// Firestore에서 모든 스토리보드 목록 가져오기
  ///
  /// 생성일 기준 내림차순으로 정렬
  /// Returns: 스토리보드 목록
  Future<List<SavedStoryboard>> getAllStoryboards() async {
    try {
      final querySnapshot = await _firestore
          .collection(_storyboardsCollection)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Firestore 문서 ID를 id로 사용
        return SavedStoryboard.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('스토리보드 목록 불러오기 실패: $e');
    }
  }

  /// Firestore에서 스토리보드 목록을 실시간으로 스트림
  ///
  /// 생성일 기준 내림차순으로 정렬
  /// Returns: 스토리보드 목록 스트림
  Stream<List<SavedStoryboard>> getStoryboardsStream() {
    try {
      return _firestore
          .collection(_storyboardsCollection)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Firestore 문서 ID를 id로 사용
          return SavedStoryboard.fromJson(data);
        }).toList();
      });
    } catch (e) {
      throw Exception('스토리보드 스트림 생성 실패: $e');
    }
  }

  /// Firestore에서 특정 스토리보드 가져오기
  ///
  /// [id] 스토리보드 문서 ID
  /// Returns: 스토리보드 또는 null
  Future<SavedStoryboard?> getStoryboard(String id) async {
    try {
      final doc = await _firestore
          .collection(_storyboardsCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      return SavedStoryboard.fromJson(data);
    } catch (e) {
      throw Exception('스토리보드 불러오기 실패: $e');
    }
  }

  /// Firestore의 스토리보드 업데이트
  ///
  /// [storyboard] 업데이트할 스토리보드
  Future<void> updateStoryboard(SavedStoryboard storyboard) async {
    try {
      await _firestore
          .collection(_storyboardsCollection)
          .doc(storyboard.id)
          .update(storyboard.toJson());
    } catch (e) {
      throw Exception('스토리보드 업데이트 실패: $e');
    }
  }

  /// Firestore에서 스토리보드 삭제
  ///
  /// [id] 삭제할 스토리보드 문서 ID
  Future<void> deleteStoryboard(String id) async {
    try {
      await _firestore
          .collection(_storyboardsCollection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('스토리보드 삭제 실패: $e');
    }
  }

  /// 특정 스토리보드가 존재하는지 확인
  ///
  /// [id] 확인할 스토리보드 문서 ID
  /// Returns: 존재 여부
  Future<bool> storyboardExists(String id) async {
    try {
      final doc = await _firestore
          .collection(_storyboardsCollection)
          .doc(id)
          .get();

      return doc.exists;
    } catch (e) {
      throw Exception('스토리보드 확인 실패: $e');
    }
  }
}
