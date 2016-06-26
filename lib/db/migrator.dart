part of aqueduct;

abstract class Migrator {

  DataModel targetDataModel;

  Future up();
  Future down();

  Future upData();
  Future downData();

  List<Map<String, dynamic>> operations = [];

  void addTable(SchemaTable table) {
    operations.add({
      "op" : "table.add",
      "table" : table.asSerializable()
    });
  }

  void deleteTable(String tableName) {
    operations.add({
      "op" : "table.delete",
      "name" : tableName
    });
  }

  void renameTable(String existingTableName, String newName) {

  }

  void renameColumn(String tableName, String existingColumnName, String newColumnName) {

  }

  void addColumn(String tableName, SchemaColumn column, dynamic initialValue) {
    operations.add({
      "op" : "column.add",
      "tableName" : tableName,
      "column" : column.asSerializable(),
      "initialValue" : initialValue
    });
  }

  void deleteColumn(String tableName, String columnName) {
    operations.add({
      "op" : "column.delete",
      "tableName" : tableName,
      "name" : columnName
    });
  }

  void alterColumn(String tableName, SchemaColumn column, dynamic initialValue) {

  }

  void addIndex(String tableName, SchemaIndex index) {
    operations.add({
      "op" : "index.add",
      "index" : index.asSerializable()
    });
  }

  void renameIndex(String tableName, String existingIndexName, String newIndexName) {
    operations.add({
      "op" : "index.rename",
      "sourceName" : existingIndexName,
      "destinationName" : newIndexName
    });
  }

  void deleteIndex(String tableName, String indexName) {
    operations.add({
      "op" : "index.delete",
      "name" : indexName
    });
  }
}