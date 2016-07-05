part of aqueduct;

abstract class SchemaGeneratorBackend {
  SchemaGeneratorBackend(List<Map> operations, {bool temporary: false}) {
    isTemporary = temporary;
    operations.forEach((op) {
      _parseOperation(op);
    });
  }

  List<String> commands;
  bool isTemporary;

  String get commandList {
    return commands.join("\n");
  }

  void _parseOperation(Map<String, dynamic> operation) {
    switch(operation["op"]) {
      case "table.add" : handleAddTableCommand(new SchemaTable.fromJSON(operation["table"]));
    }

    return null;
  }

  void handleAddTableCommand(SchemaTable table);
  void handleDeleteTableCommand(SchemaTable table);
  void handleRenameTableCommand(SchemaTable existingTable, String newName);

  void handleAddColumnCommand(SchemaTable table, SchemaColumn column, dynamic initialValue);
  void handleDeleteColumnCommand(SchemaTable table, SchemaColumn column);
  void handleRenameColumnCommand(SchemaTable table, SchemaColumn existingColumn, String newName);
  void handleAlterColumnCommand(SchemaTable table, SchemaColumn existingColumn, SchemaColumn updatedColumn, dynamic initialValue);
  void handleMoveColumnCommand(SchemaTable sourceTable, SchemaTable destinationTable, SchemaColumn column);
}