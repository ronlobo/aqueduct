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
}