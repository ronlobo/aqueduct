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
  });

  group("Deleting tables", () {

  });

  group("Adding columns", () {

  });
}