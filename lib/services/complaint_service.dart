import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';

/// Complaint CRUD on Firestore.
class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'complaints';

  Future<String> submitComplaint({
    required String userId,
    required String userEmail,
    required String userName,
    required ComplaintCategory category,
    required String subject,
    required String description,
  }) async {
    final ref = _firestore.collection(_collection).doc();
    final complaint = Complaint(
      id: ref.id,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      category: category,
      subject: subject,
      description: description,
      status: ComplaintStatus.submitted,
      createdAt: DateTime.now(),
    );
    await ref.set(complaint.toMap());
    return ref.id;
  }

  Stream<List<Complaint>> streamComplaintsByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Complaint.fromMap(d.data())).toList());
  }

  Stream<List<Complaint>> streamAllComplaints({ComplaintCategory? category, ComplaintStatus? status}) {
    Query<Map<String, dynamic>> q = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true);
    if (category != null) q = q.where('category', isEqualTo: category.name);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((snap) => snap.docs.map((d) => Complaint.fromMap(d.data())).toList());
  }

  Future<Complaint?> getComplaint(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists && doc.data() != null) return Complaint.fromMap(doc.data()!);
    return null;
  }

  Future<void> updateStatus(String id, ComplaintStatus status, {String? adminFeedback}) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (adminFeedback != null) data['adminFeedback'] = adminFeedback;
    await _firestore.collection(_collection).doc(id).update(data);
  }

  Future<void> assignComplaint(String id, String assignedTo) async {
    await _firestore.collection(_collection).doc(id).update({
      'assignedTo': assignedTo,
      'status': ComplaintStatus.inProgress.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
