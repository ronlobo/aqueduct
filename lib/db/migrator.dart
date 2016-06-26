part of aqueduct;

abstract class Migrator {
  Future up();
  Future down();

  Future upData();
  Future downData();

  void addTable(SchemaTable table) {

  }

  void deleteTable(String tableName) {

  }

  void renameTable(String existingTableName, String newName) {

  }

  void renameColumn(String tableName, String existingColumnName, String newColumnName) {

  }

  void addColumn(String tableName, SchemaColumn column, dynamic initialValue) {

  }

  void deleteColumn(String tableName, String columnName) {

  }

  void alterColumn(String tableName, SchemaColumn column, dynamic initialValue) {

  }

  void addIndex(String tableName, SchemaIndex index) {

  }

  void renameIndex(String tableName, String existingIndexName, String newIndexName) {

  }

  void deleteIndex(String tableName, String indexName) {

  }
}