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
      .firstWhere((ClassMirror decl) => decl.invoke(new Symbol("key"), []).reflectee == opName);


    SchemaOperation instance = opMirror.newInstance(new Symbol(""), []).reflectee;
    instance.readJSON(operation);

    return instance;
  }

  SchemaOperation();

  void readJSON(Map<String, dynamic> operation) {
    operation.forEach((key, value) {
      if (key == "op") {
        return;
      }

      VariableMirror decl = reflect(this).type.declarations[new Symbol(key)];
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
          "op" : reflect(this).type.invoke(new Symbol("key"), []).reflectee
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
          "op" : reflect(this).type.invoke(new Symbol("key"), []).reflectee
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
}

class DeleteTableOperation extends SchemaOperation {
  static String get key => "table.delete";
  String tableName;
}

class RenameTableOperation extends SchemaOperation {
  static String get key => "table.rename";
  String tableName;
  String newTableName;
}

class AddColumnOperation extends SchemaOperation {
  static String get key => "column.add";
  String tableName;
  SchemaColumn column;
  dynamic initialValue;
}

class DeleteColumnOperation extends SchemaOperation {
  static String get key => "column.delete";
  String tableName;
  String columnName;
}

class RenameColumnOperation extends SchemaOperation {
  static String get key => "column.rename";
  String columnName;
  String newColumnName;
}

class AlterColumnOperation extends SchemaOperation {
  static String get key => "column.alter";
  String columnName;
  SchemaColumn column;
  dynamic initialValue;
}

class AddIndexOperation extends SchemaOperation {
  static String get key => "index.add";
  String tableName;
  SchemaIndex index;
}

class DeleteIndexOperation extends SchemaOperation {
  static String get key => "index.delete";
  String tableName;
  String indexName;
}