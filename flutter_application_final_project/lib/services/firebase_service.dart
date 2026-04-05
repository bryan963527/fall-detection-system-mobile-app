import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

/// Centralized Firebase Service
/// 
/// Provides unified access to Firebase Realtime Database with:
/// * Correct regional database URL (asia-southeast1)
/// * Consistent DatabaseReference creation
/// * Timeout protection
/// * Debug logging
class FirebaseService {
  static const String _databaseUrl =
      "https://app-dev-safestefs-default-rtdb.asia-southeast1.firebasedatabase.app";

  /// Get the Firebase Database instance for the correct region
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _databaseUrl,
  );

  /// Get a DatabaseReference for a specific path
  static DatabaseReference ref(String path) {
    print("🔗 [FirebaseService] Creating ref for path: $path");
    return _database.ref(path);
  }

  /// Safe database read with timeout
  /// Returns the data as Map<String, dynamic>? or null if path doesn't exist
  static Future<Map<String, dynamic>?> getWithTimeout(
    String path, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      print("📖 [FirebaseService] Fetching path: $path");
      
      final snapshot = await ref(path)
          .get()
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Database read timed out after ${timeout.inSeconds} seconds for path: $path',
              );
            },
          );

      if (!snapshot.exists) {
        print("📖 [FirebaseService] Path does not exist: $path");
        return null;
      }

      final data = snapshot.value as Map<String, dynamic>?;
      print("✅ [FirebaseService] Data received. Path exists: ${snapshot.exists}");
      return data;
    } catch (e) {
      print("❌ [FirebaseService] Error fetching $path: $e");
      rethrow;
    }
  }

  /// Get the database stream for real-time updates
  static Stream<DatabaseEvent> getStream(String path) {
    print("📡 [FirebaseService] Creating stream for path: $path");
    return ref(path).onValue;
  }

  /// Write data to database with timeout
  static Future<void> writeWithTimeout(
    String path,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      print("✏️  [FirebaseService] Writing to path: $path");
      print("📝 [FirebaseService] Data: $data");
      
      await ref(path)
          .set(data)
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Database write timed out after ${timeout.inSeconds} seconds for path: $path',
              );
            },
          );

      print("✅ [FirebaseService] Data written successfully");
    } catch (e) {
      print("❌ [FirebaseService] Error writing to $path: $e");
      rethrow;
    }
  }

  /// Update data in database with timeout
  static Future<void> updateWithTimeout(
    String path,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      print("✏️  [FirebaseService] Updating path: $path");
      
      await ref(path)
          .update(data)
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Database update timed out after ${timeout.inSeconds} seconds for path: $path',
              );
            },
          );

      print("✅ [FirebaseService] Data updated successfully");
    } catch (e) {
      print("❌ [FirebaseService] Error updating $path: $e");
      rethrow;
    }
  }

  /// Delete data from database with timeout
  static Future<void> deleteWithTimeout(
    String path, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      print("🗑️  [FirebaseService] Deleting path: $path");
      
      await ref(path)
          .remove()
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Database delete timed out after ${timeout.inSeconds} seconds for path: $path',
              );
            },
          );

      print("✅ [FirebaseService] Data deleted successfully");
    } catch (e) {
      print("❌ [FirebaseService] Error deleting $path: $e");
      rethrow;
    }
  }
}
