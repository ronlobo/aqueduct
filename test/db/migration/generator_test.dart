import 'package:aqueduct/aqueduct.dart';
import 'package:test/test.dart';
import '../../helpers.dart';

void main() {
  group("Adding tables", () {
    test("Add simple table", () {
      var dm = new DataModel([SimpleModel]);
      var schema = new Schema(dm);
      var op = {"op" : "table.add", "table" : schema.tableForName("_SimpleModel").asJSON()};

      var emptySchema = new Schema.empty();
      SchemaGenerator.applyOperationsToSchema([op], emptySchema);

      var t = emptySchema.tableForName("_SimpleModel");
      expect(t.asJSON(), equals(op["table"]));
    });

    test("Add related tables", () {
      var dm = new DataModel([TreeBranch, TreeRoot, TreeLeaf]);
      var schema = new Schema(dm);
      var ops = [
        {"op" : "table.add", "table" : schema.tableForName("_TreeRoot").asJSON()},
        {"op" : "table.add", "table" : schema.tableForName("_TreeBranch").asJSON()},
        {"op" : "table.add", "table" : schema.tableForName("_TreeLeaf").asJSON()}
      ];

      var emptySchema = new Schema.empty();
      SchemaGenerator.applyOperationsToSchema(ops, emptySchema);

      expect(emptySchema.tableForName("_TreeRoot").asJSON(), equals(ops[0]["table"]));
      expect(emptySchema.tableForName("_TreeBranch").asJSON(), equals(ops[1]["table"]));
      expect(emptySchema.tableForName("_TreeLeaf").asJSON(), equals(ops[2]["table"]));
    });

    test("Duplicate tables", () {
      var dm = new DataModel([TreeBranch, TreeRoot, TreeLeaf]);
      var schema = new Schema(dm);

      // With same case
      var ops = [
        {"op" : "table.add", "table" : schema.tableForName("_TreeRoot").asJSON()},
        {"op" : "table.add", "table" : (schema.tableForName("_TreeBranch")..name = "_TreeRoot").asJSON()}
      ];

      var emptySchema = new Schema.empty();
      try {
        SchemaGenerator.applyOperationsToSchema(ops, emptySchema);
        expect(true, false);
      } on SchemaGeneratorException {}

      // Without same case
      schema = new Schema(dm);
      ops = [
        {"op" : "table.add", "table" : schema.tableForName("_TreeRoot").asJSON()},
        {"op" : "table.add", "table" : (schema.tableForName("_TreeBranch")..name = "_treeroot").asJSON()}
      ];

      emptySchema = new Schema.empty();
      try {
        SchemaGenerator.applyOperationsToSchema(ops, emptySchema);
        expect(true, false);
      } on SchemaGeneratorException {}
    });
  });

  group("Renaming tables", () {
    test("Rename simple table", () {
      var dm = new DataModel([SimpleModel]);
      var schema = new Schema(dm);

      var op = {"op" : "table.rename", "tableName" : "_SimpleModel", "newTableName" : "_foobar"};

      SchemaGenerator.applyOperationsToSchema([op], schema);

      var t = schema.tableForName("_foobar");
      expect(t.name, "_foobar");
      expect(t.columns.length, 1);
      expect(t.columns.first.name, "id");
    });

    test("Rename table with a foreign key", () {
      var dm = new DataModel([TreeLeaf, TreeRoot, TreeBranch]);
      var schema = new Schema(dm);

      var op = {"op" : "table.rename", "tableName" : "_TreeBranch", "newTableName" : "_foobar"};
      SchemaGenerator.applyOperationsToSchema([op], schema);

      var leafTable = schema.tableForName("_TreeLeaf");
      expect(leafTable.columns.firstWhere((c) => c.name == "branch").relatedTableName, "_foobar");
      expect(leafTable.columns.firstWhere((c) => c.name == "branch").relatedColumnName, "id");
    });

    test("Rename unknown table fails", () {
      var dm = new DataModel([TreeLeaf, TreeRoot, TreeBranch]);
      var schema = new Schema(dm);

      var op = {"op" : "table.rename", "tableName" : "_TreeBark", "newTableName" : "_foobar"};
      try {
        SchemaGenerator.applyOperationsToSchema([op], schema);
        expect(true, false);
      } on SchemaGeneratorException {}
    });

    test("Rename table to already existing table fails", () {
      var dm = new DataModel([TreeLeaf, TreeRoot, TreeBranch]);
      var schema = new Schema(dm);

      var op = {"op" : "table.rename", "tableName" : "_TreeBranch", "newTableName" : "_TreeRoot"};
      try {
        SchemaGenerator.applyOperationsToSchema([op], schema);
        expect(true, false);
      } on SchemaGeneratorException {}
    });
  });

  group("Deleting tables", () {
    test("Delete simple table", () {
      var dm = new DataModel([SimpleModel]);
      var schema = new Schema(dm);

      var op = {"op" : "table.delete", "tableName" : "_SimpleModel"};

      SchemaGenerator.applyOperationsToSchema([op], schema);

      var t = schema.tableForName("_foobar");
      expect(t, isNull);
    });

    test("Delete referenced table fails while still referenced", () {
      var dm = new DataModel([TreeLeaf, TreeRoot, TreeBranch]);
      var schema = new Schema(dm);

      var op = {"op" : "table.delete", "tableName" : "_TreeBranch"};
      try {
        SchemaGenerator.applyOperationsToSchema([op], schema);
        expect(true, false);
      } on SchemaGeneratorException {}
    });

    test("Delete previously referenced table succeeds", () {

    });


    test("Delete unknown table", () {
      var dm = new DataModel([SimpleModel]);
      var schema = new Schema(dm);

      var op = {"op" : "table.delete", "tableName" : "_foobar"};

      try {
        SchemaGenerator.applyOperationsToSchema([op], schema);
        expect(true, false);
      } on SchemaGeneratorException {}
    });
  });

  group("Adding columns", () {

  });
}