part of aqueduct;

class PostgreSQLSchemaGenerator extends SchemaGeneratorBackend {
  List<String> handleAddTableCommand(SchemaTable table, bool temporary) {
    var columnString = table.columns.map((sc) => _columnStringForColumn(sc)).join(",");
    List<SchemaColumn> constraints = table.columns
        .where((col) => col.relatedColumnName != null)
        .toList();

    var commands = [];
    commands.add("CREATE${temporary ? " TEMPORARY " : " "}TABLE ${table.name} (${columnString});");
    commands.addAll(table.indexes.map((i) => _indexStringForTableIndex(table, i)).toList());
    commands.addAll(constraints.map((c) => _foreignKeyConstraintForTableConstraint(table, c)).toList());
    return commands;
  }

  List<String> handleDeleteTableCommand(SchemaTable table) {
    return ["DROP TABLE ${table.name};"];
  }

  List<String> handleRenameTableCommand(SchemaTable table, String newName) {
    // Must also rename any referencing columns or indices/constraints that contain table name.
    return ["ALTER TABLE ${table.name} RENAME TO ${newName};"];
  }

  List<String> handleAddColumnCommand(SchemaTable table, SchemaColumn column, dynamic initialValue) {
    var commands = [];
    commands.add("ALTER TABLE ${table.name} ADD COLUMN ${_columnStringForColumn(column)};");

    if (column.relatedColumnName != null) {
      commands.add(_foreignKeyConstraintForTableConstraint(table, column));
    }
    return commands;
  }

  List<String> handleDeleteColumnCommand(SchemaTable table, SchemaColumn column) {
    return ["ALTER TABLE ${table.name} DROP COLUMN ${_columnNameForColumn(column)} ${column.relatedColumnName != null ? "CASCADE" : "RESTRICT"};"];
  }

  List<String> handleRenameColumnCommand(SchemaTable table, SchemaColumn existingColumn, String newName) {
    // Must also rename any referencing indices/constraints
    return ["ALTER TABLE ${table.name} RENAME COLUMN ${_columnNameForColumn(existingColumn)} TO ${newName};"];
  }

  List<String> handleAlterColumnCommand(SchemaTable table, SchemaColumn existingColumn, SchemaColumn updatedColumn, dynamic initialValue) {
    var commands = [];
    if (updatedColumn.isNullable != existingColumn.isNullable) {
      if (updatedColumn.isNullable) {
        commands.add("ALTER TABLE ${table.name} ALTER COLUMN ${_columnNameForColumn(existingColumn)} DROP NOT NULL;");
      } else if (initialValue != null) {
        commands.add("UPDATE ${table.name} SET ${_columnNameForColumn(existingColumn)}=${initialValue} WHERE ${_columnNameForColumn(existingColumn)} IS NULL;");
        commands.add("ALTER TABLE ${table.name} ALTER COLUMN ${_columnNameForColumn(existingColumn)} SET NOT NULL;");
      } else {
        throw 'Initial value must be supplied for setting a column to not null';
      }
    }

    if (updatedColumn.type != existingColumn.type) {
      commands.add("ALTER TABLE ${table.name} ALTER COLUMN ${_columnNameForColumn(existingColumn)} SET DATA TYPE ${updatedColumn.type};");
    }

    if (updatedColumn.defaultValue != existingColumn.defaultValue) {
      if (updatedColumn.defaultValue != null) {
        commands.add("ALTER TABLE ${table.name} ALTER COLUMN ${_columnNameForColumn(existingColumn)} SET DEFAULT ${updatedColumn.defaultValue};");
      } else {
        commands.add("ALTER TABLE ${table.name} ALTER COLUMN ${_columnNameForColumn(existingColumn)} DROP DEFAULT;");
      }
    }

    // TODO: unique
    if (updatedColumn.isUnique != existingColumn.isUnique) {
      throw 'UnsupportedOperation';
//      if (updatedColumn.isUnique) {
////        indexCommands.add("CREATE UNIQUE INDEX IF NOT EXISTS ${table.name}_${_columnNameForColumn(existingColumn)}_idx ON ${table.name} (${_columnNameForColumn(existingColumn)});");
//        constraintCommands.add("ALTER TABLE ${table.name} ADD UNIQUE (${_columnNameForColumn(existingColumn)});");
//      } else {
//        constraintCommands.add("ALTER TABLE ${table.name} DROP CONSTRAINT ${table.name}_${_columnNameForColumn(existingColumn)}_key CASCADE;");
//      }
    }

    return commands;
  }

  List<String> handleMoveColumnCommand(SchemaTable sourceTable, SchemaTable destinationTable, SchemaColumn column) {
    throw 'UnsupportedOperation';
  }


  List<String> handleAddIndexCommand(SchemaTable table, SchemaIndex index) {
    return [_indexStringForTableIndex(table, index)];
  }

  List<String> handleRenameIndexCommand(SchemaTable table, SchemaIndex index, String newIndexName) {
    return [];
  }

  List<String> handleDeleteIndexCommand(SchemaTable table, SchemaIndex index) {
    var actualColumn = table.columns.firstWhere((col) => col.name == index.name);
    return ["DROP INDEX ${table.name}_${_columnNameForColumn(actualColumn)}_idx ${actualColumn.relatedColumnName != null ? "CASCADE" : "RESTRICT"}"];
  }

  String _foreignKeyConstraintForTableConstraint(SchemaTable sourceTable, SchemaColumn column) =>
      "ALTER TABLE ONLY ${sourceTable.name} ADD FOREIGN KEY (${_columnNameForColumn(column)}) "
          "REFERENCES ${column.relatedTableName} (${column.relatedColumnName}) "
          "ON DELETE ${_deleteRuleStringForDeleteRule(column.deleteRule)};";

  String _indexStringForTableIndex(SchemaTable table, SchemaIndex i) {
    var actualColumn = table.columns.firstWhere((col) => col.name == i.name);
    return "CREATE INDEX ${table.name}_${_columnNameForColumn(actualColumn)}_idx ON ${table.name} (${_columnNameForColumn(actualColumn)});";
  }

  String _columnStringForColumn(SchemaColumn col) {
    var elements = [_columnNameForColumn(col), _postgreSQLTypeForColumn(col)];
    if (col.isPrimaryKey) {
      elements.add("PRIMARY KEY");
    } else {
      elements.add(col.isNullable ? "NULL" : "NOT NULL");
      if (col.defaultValue != null) {
        elements.add("DEFAULT ${col.defaultValue}");
      }
      if (col.isUnique) {
        elements.add("UNIQUE");
      }
    }

    return elements.join(" ");
  }

  String _columnNameForColumn(SchemaColumn column) {
    if (column.relatedColumnName != null) {
      return "${column.name}_${column.relatedColumnName}";
    }

    return column.name;
  }

  String _deleteRuleStringForDeleteRule(String deleteRule) {
    switch (deleteRule) {
      case "cascade":
        return "CASCADE";
      case "restrict":
        return "RESTRICT";
      case "default":
        return "SET DEFAULT";
      case "nullify":
        return "SET NULL";
    }

    return null;
  }

  String _postgreSQLTypeForColumn(SchemaColumn t) {
    switch (t.type) {
      case "integer": {
        if (t.autoincrement) {
          return "SERIAL";
        }
        return "INT";
      } break;
      case "bigInteger": {
        if (t.autoincrement) {
          return "BIGSERIAL";
        }
        return "BIGINT";
      } break;
      case "string":
        return "TEXT";
      case "datetime":
        return "TIMESTAMP";
      case "boolean":
        return "BOOLEAN";
      case "double":
        return "DOUBLE PRECISION";
    }

    return null;
  }
}