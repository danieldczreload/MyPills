import 'package:sqlite3/sqlite3.dart';

bool hasSqliteRuntime() {
  try {
    sqlite3.openInMemory().dispose();
    return true;
  } on Object {
    return false;
  }
}
