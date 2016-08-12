part of aqueduct;

abstract class SchemaGeneratorBackend {
  List<String> get commands;

  void handleAddTableCommand(SchemaTable table, bool temporary);
  void handleDeleteTableCommand(SchemaTable tableName);
  void handleRenameTableCommand(SchemaTable existingTable, String newName);

  void handleAddColumnCommand(SchemaTable table, SchemaColumn column, dynamic initialValue);
  void handleDeleteColumnCommand(SchemaTable table, SchemaColumn column);
  void handleRenameColumnCommand(SchemaTable table, SchemaColumn existingColumn, String newName);
  void handleAlterColumnCommand(SchemaTable table, SchemaColumn existingColumn, SchemaColumn updatedColumn, dynamic initialValue);
  void handleMoveColumnCommand(SchemaTable sourceTable, SchemaTable destinationTable, SchemaColumn column);

  void handleAddIndexCommand(SchemaTable table, SchemaIndex index);
  void handleDeleteIndexCommand(SchemaTable table, SchemaIndex index);
}

class SchemaGenerator {
  static const String OperationTableAdd = "table.add";
  static const String OperationTableDelete = "table.delete";
  static const String OperationTableRename = "table.rename";

  static List<String> generateCommandsForSchema(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false}) {
    schema.tables.forEach((table) {
      backend.handleAddTableCommand(table, temporary);
    });

    return backend.commands;
  }

  static Schema generateSchemaFromOperations(List<Map<String, dynamic>> operations) {
    return null;
  }

  SchemaGenerator.fromSchema(this.schema, {bool temporary: false}) {
    isTemporary = temporary;
  }

  SchemaGenerator.fromSchemaFiles(List<String> filenames) {
    schemaFiles = filenames
        .map((filename) => new File(filename).readAsStringSync())
        .map((contents) => JSON.decode(contents))
        .toList();
  }

  Schema schema;
  List<List<Map<String, dynamic>>> schemaFiles;
  bool isTemporary;

  void _applyOperationToSchema(Map<String, dynamic> operation, Schema schema) {
    var op = operation["op"];
    switch(op) {
      case OperationTableAdd: {
        var table = new SchemaTable.fromJSON(operation["table"]);
        if (schema.tableForName(table.name) != null) {
          throw new SchemaGeneratorException("Attempted operation $operation failed, table already exists.");
        }
        schema.tables.add(table);
      } break;
    }
  }

  void _parseOperation(Map<String, dynamic> operation, Schema schema) {
    var op = operation["op"];
    switch(op) {
      case OperationTableAdd: {
        var table = new SchemaTable.fromJSON(operation["table"]);
        schema.tables.add(table);
        handleAddTableCommand(table);
      } break;
      case OperationTableDelete: {
        var table = schema.tableForName(operation["name"]);
        if (table == null) {
          throw new SchemaGeneratorException("Attempted operation $operation failed, table does not exist.");
        }
        schema.tables.remove(table);
        handleDeleteTableCommand(table);
      } break;
      case OperationTableRename: {
        var table = schema.tableForName(operation["sourceName"]);
        if (table == null) {
          throw new SchemaGeneratorException("Attempted operation $operation failed, table does not exist.");
        }

        var newName = operation["destinationName"];
        if (schema.tableForName(newName) != null) {
          throw new SchemaGeneratorException("Attempted operation $operation failed, new table name already exists.");
        }

        table.name = newName;
        handleRenameTableCommand(table, newName);
      } break;
    }
  }
}

class SchemaGeneratorException implements Exception {
  SchemaGeneratorException(this.message);

  String message;
}