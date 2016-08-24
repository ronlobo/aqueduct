part of aqueduct;

abstract class SchemaGeneratorBackend {
  List<String> handleAddTableCommand(SchemaTable table, bool temporary);
  List<String> handleDeleteTableCommand(SchemaTable tableName);
  List<String> handleRenameTableCommand(SchemaTable existingTable, String newName);

  List<String> handleAddColumnCommand(SchemaTable table, SchemaColumn column, dynamic initialValue);
  List<String> handleDeleteColumnCommand(SchemaTable table, SchemaColumn column);
  List<String> handleRenameColumnCommand(SchemaTable table, SchemaColumn existingColumn, String newName);
  List<String> handleAlterColumnCommand(SchemaTable table, SchemaColumn existingColumn, SchemaColumn updatedColumn, dynamic initialValue);
  List<String> handleMoveColumnCommand(SchemaTable sourceTable, SchemaTable destinationTable, SchemaColumn column);

  List<String> handleAddIndexCommand(SchemaTable table, SchemaIndex index);
  List<String> handleRenameIndexCommand(SchemaTable table, SchemaIndex index, String newIndexName);
  List<String> handleDeleteIndexCommand(SchemaTable table, SchemaIndex index);
}

class SchemaGenerator {
  static List<String> generateCommandsForSchema(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false}) {
    return schema.dependencyOrderedTables
        .map((table) => backend.handleAddTableCommand(table, temporary))
        .expand((cmds) => cmds)
        .toList();
  }

  // Validate the ordered operations against a test database
  static void applyOperationsToSchema(Schema baseSchema, SchemaGeneratorBackend backend, List<Map<String, dynamic>> operations, {bool temporary: false, List<String> outCommands}) {
    operations
        .map((op) => new SchemaOperation.fromJSON(op))
        .forEach((SchemaOperation op) {
          op.validate(baseSchema);
          op.execute(baseSchema, backend, temporary: temporary, outCommands: outCommands);
        });
    return null;
  }
}

class SchemaGeneratorException implements Exception {
  SchemaGeneratorException(this.message);

  String message;
}

abstract class SchemaOperation {
  factory SchemaOperation.fromJSON(Map<String, dynamic> operation) {
    var opName = operation["op"];
    var typeMirror = reflectClass(SchemaOperation);
    LibraryMirror lib = reflect(SchemaOperation).type.owner;

    ClassMirror opMirror = lib.declarations.values
      .where((decl) => decl is ClassMirror)
      .where((ClassMirror m) => m.isSubclassOf(typeMirror))
      .firstWhere((ClassMirror decl) => decl.invoke(#key, []).reflectee == opName);


    SchemaOperation instance = opMirror.newInstance(new Symbol(""), []).reflectee;
    instance.readJSON(operation);

    return instance;
  }

  SchemaOperation();

  void validate(Schema schema);
  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null});

  void readJSON(Map<String, dynamic> operation) {
    operation.forEach((key, value) {
      if (key == "op") {
        return;
      }

      VariableMirror decl = reflect(this).type.declarations[#key];
      if (decl.type.isSubtypeOf(reflectType(SchemaTable))) {
        reflect(this).setField(new Symbol(key), new SchemaTable.fromJSON(value));
      } else if (decl.type.isSubtypeOf(reflectType(SchemaIndex))) {
        reflect(this).setField(new Symbol(key), new SchemaIndex.fromJSON(value));
      } else if (decl.type.isSubtypeOf(reflectType(SchemaColumn))) {
        reflect(this).setField(new Symbol(key), new SchemaColumn.fromJSON(value));
      } else {
        reflect(this).setField(new Symbol(key), value);
      }
    });

    return reflect(this).type.declarations.values
        .where((m) => m is VariableMirror)
        .fold({
          "op" : reflect(this).type.invoke(#key, []).reflectee
        }, (m, VariableMirror decl) {
          if (decl.type.isSubtypeOf(reflectType(SchemaElement))) {
            m[MirrorSystem.getName(decl.simpleName)] = reflect(this).getField(decl.simpleName).reflectee.asJSON();
          } else {
            m[MirrorSystem.getName(decl.simpleName)] = reflect(this).getField(decl.simpleName).reflectee;
          }

          return m;
        });
  }

  Map<String, dynamic> asJSON() {
    return reflect(this).type.declarations.values
        .where((m) => m is VariableMirror && !m.isStatic)
        .fold({
          "op" : reflect(this).type.invoke(#key, []).reflectee
        }, (m, VariableMirror decl) {
          if (decl.type.isSubtypeOf(reflectType(SchemaElement))) {
            m[MirrorSystem.getName(decl.simpleName)] = reflect(this).getField(decl.simpleName).reflectee.asJSON();
          } else {
            m[MirrorSystem.getName(decl.simpleName)] = reflect(this).getField(decl.simpleName).reflectee;
          }

          return m;
        });
  }
}

class AddTableOperation extends SchemaOperation {
  static String get key => "table.add";
  SchemaTable table;

  void validate(Schema schema) {
    if (schema.tableForName(table.name) != null) {
      throw new SchemaGeneratorException("Add Table failed: table named ${table.name} already exists.");
    }
  }

  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null}) {
    outCommands?.addAll(backend.handleAddTableCommand(table, temporary));

    schema.tables.add(table);
  }
}

class DeleteTableOperation extends SchemaOperation {
  static String get key => "table.delete";
  String tableName;

  void validate(Schema schema) {
    if (schema.tableForName(tableName) == null) {
      throw new SchemaGeneratorException("Delete Table failed: table named ${tableName} does not exist.");
    }
  }

  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null}) {
    var table = schema.tableForName(tableName);
    outCommands?.addAll(backend.handleDeleteTableCommand(table));

    schema.tables.remove(table);
  }
}

class RenameTableOperation extends SchemaOperation {
  static String get key => "table.rename";
  String tableName;
  String newTableName;

  void validate(Schema schema) {
    if (schema.tableForName(tableName) == null) {
      throw new SchemaGeneratorException("Rename Table failed: table named ${tableName} does not exist.");
    }

    if (schema.tableForName(newTableName) != null) {
      throw new SchemaGeneratorException("Rename Table failed: table named ${newTableName} already exists.");
    }
  }

  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null}) {
    var table = schema.tableForName(tableName);
    outCommands?.addAll(backend.handleRenameTableCommand(table, newTableName));

    table.name = newTableName;
  }
}

class AddColumnOperation extends SchemaOperation {
  static String get key => "column.add";
  String tableName;
  SchemaColumn column;
  dynamic initialValue;

  void validate(Schema schema) {
    var table = schema.tableForName(tableName);
    if (table == null) {
      throw new SchemaGeneratorException("Add Column failed: table named ${tableName} does not exist.");
    }

    if (table.columns.any((col) => col.name == column.name)) {
      throw new SchemaGeneratorException("Add Column failed: column named ${column.name} already exists for ${tableName}.");
    }
  }

  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null}) {
    var table = schema.tableForName(tableName);
    outCommands?.addAll(backend.handleAddColumnCommand(table, column, initialValue));

    table.columns.add(column);
  }
}

class DeleteColumnOperation extends SchemaOperation {
  static String get key => "column.delete";
  String tableName;
  String columnName;

  void validate(Schema schema) {
    var table = schema.tableForName(tableName);
    if (table == null) {
      throw new SchemaGeneratorException("Delete Column failed: table named ${tableName} does not exist.");
    }

    var column = table.columnForName(columnName);
    if (column == null) {
      throw new SchemaGeneratorException("Delete Column failed: column named ${columnName} does not exist for ${tableName}.");
    }
  }

  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null}) {
    var table = schema.tableForName(tableName);
    var column = table.columnForName(columnName);

    outCommands?.addAll(backend.handleDeleteColumnCommand(table, column));

    table.columns.remove(column);
  }
}

class RenameColumnOperation extends SchemaOperation {
  static String get key => "column.rename";
  String tableName;
  String columnName;
  String newColumnName;

  void validate(Schema schema) {
    var table = schema.tableForName(tableName);
    if (table == null) {
      throw new SchemaGeneratorException("Rename Column failed: table named ${tableName} does not exist.");
    }

    var column = table.columnForName(columnName);
    if (column == null) {
      throw new SchemaGeneratorException("Rename Column failed: column named ${columnName} does not exist for ${tableName}.");
    }

    column = table.columnForName(newColumnName);
    if (column != null) {
      throw new SchemaGeneratorException("Rename Column failed: column named ${newColumnName} already exists for ${tableName}.");
    }
  }

  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null}) {
    var table = schema.tableForName(tableName);
    var column = table.columnForName(columnName);

    outCommands?.addAll(backend.handleRenameColumnCommand(table, column, newColumnName));

    column.name = newColumnName;
  }
}

class AlterColumnOperation extends SchemaOperation {
  static String get key => "column.alter";
  String tableName;
  String columnName;
  SchemaColumn column;
  dynamic initialValue;

  void validate(Schema schema) {
    if (column != columnName) {
      throw new SchemaGeneratorException("Alter Column failed: column name must be renamed explicitly (referenced ${columnName}, but column object name was ${column.name}).");
    }

    var table = schema.tableForName(tableName);
    if (table == null) {
      throw new SchemaGeneratorException("Alter Column failed: table named ${tableName} does not exist.");
    }

    var existingColumn = table.columnForName(columnName);
    if (existingColumn == null) {
      throw new SchemaGeneratorException("Alter Column failed: column named ${columnName} does not exist for ${tableName}.");
    }
  }

  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null}) {
    var table = schema.tableForName(tableName);
    var existingColumn = table.columnForName(columnName);

    outCommands?.addAll(backend.handleAlterColumnCommand(table, existingColumn, column, initialValue));
    table.columns.remove(existingColumn);
    table.columns.add(column);
  }
}

class AddIndexOperation extends SchemaOperation {
  static String get key => "index.add";
  String tableName;
  SchemaIndex index;

  void validate(Schema schema) {
    var table = schema.tableForName(tableName);
    if (table == null) {
      throw new SchemaGeneratorException("Add Index failed: table named ${tableName} does not exist.");
    }

    var existingIndex = table.indexForName(index.name);
    if (existingIndex != null) {
      throw new SchemaGeneratorException("Add Index failed: index named ${index.name} already exists on table $tableName");
    }
  }

  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null}) {
    var table = schema.tableForName(tableName);

    outCommands?.addAll(backend.handleAddIndexCommand(table, index));
    table.indexes.add(index);
  }
}

class RenameIndexOperation extends SchemaOperation {
  static String get key => "index.rename";
  String tableName;
  String indexName;
  String newIndexName;

  void validate(Schema schema) {
    var table = schema.tableForName(tableName);
    if (table == null) {
      throw new SchemaGeneratorException("Rename Index failed: table named ${tableName} does not exist.");
    }

    var existingIndex = table.indexForName(indexName);
    if (existingIndex != null) {
      throw new SchemaGeneratorException("Rename Index failed: index named ${indexName} does not exist on table $tableName");
    }

    existingIndex = table.indexForName(newIndexName);
    if (existingIndex != null) {
      throw new SchemaGeneratorException("Rename Index failed: index named ${newIndexName} already exists on table $tableName");
    }
  }

  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null}) {
    var table = schema.tableForName(tableName);
    var index = table.indexForName(indexName);

    outCommands?.addAll(backend.handleRenameIndexCommand(table, index, newIndexName));
    index.name = newIndexName;
  }
}

class DeleteIndexOperation extends SchemaOperation {
  static String get key => "index.delete";
  String tableName;
  String indexName;

  void validate(Schema schema) {
    var table = schema.tableForName(tableName);
    if (table == null) {
      throw new SchemaGeneratorException("Delete Index failed: table named ${tableName} does not exist.");
    }

    var existingIndex = table.indexForName(indexName);
    if (existingIndex != null) {
      throw new SchemaGeneratorException("Delete Index failed: index named ${indexName} does not exist on table $tableName");
    }
  }

  void execute(Schema schema, SchemaGeneratorBackend backend, {bool temporary: false, List<String> outCommands: null}) {
    var table = schema.tableForName(tableName);
    var index = table.indexForName(indexName);

    outCommands?.addAll(backend.handleDeleteIndexCommand(table, index));
    table.indexes.remove(index);
  }
}