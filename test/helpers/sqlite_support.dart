// ignore: depend_on_referenced_packages, reason: sqlite3 is transitive via drift/native in tests
import 'package:sqlite3/sqlite3.dart';

bool hasSqliteRuntime() {
  try {
    sqlite3.openInMemory().dispose();
    return true;
  } on Object {
    return false;
  }
}
