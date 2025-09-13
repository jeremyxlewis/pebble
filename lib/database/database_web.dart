// ignore: deprecated_member_use
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    return WebDatabase('db');
  });
}
