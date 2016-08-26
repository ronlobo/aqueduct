import 'package:aqueduct/aqueduct.dart';
import 'package:test/test.dart';
import '../helpers.dart';

void main() {
  test("A single, simple model", () {
    var dataModel = new DataModel([SimpleModel]);
    var generator = new Schema(dataModel);
    var json = generator.tables.map((st) => st.asJSON()).toList();
    expect(json.length, 1);

    var tableJSON = json.first;
    expect(tableJSON["name"], "_SimpleModel");

    var tableColumns = tableJSON["columns"];
    expect(tableColumns.length, 1);
    expect(tableColumns.first, {
      "name" : "id",
      "type" : "bigInteger",
      "nullable" : false,
      "autoincrement" : true,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : true,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });
  });

  test("An extensive model", () {
    var dataModel = new DataModel([ExtensiveModel]);
    var generator = new Schema(dataModel);
    var json = generator.tables.map((st) => st.asJSON()).toList();
    expect(json.length, 1);

    var tableJSON = json.first;
    expect(tableJSON["name"], "_ExtensiveModel");

    var columns = tableJSON["columns"];
    expect(columns.length, 8);

    expect(columns.firstWhere((c) => c["name"] == "id"), {
      "name" : "id",
      "type" : "string",
      "nullable" : false,
      "autoincrement" : false,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : true,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });

    expect(columns.firstWhere((c) => c["name"] == "startDate"), {
      "name" : "startDate",
      "type" : "datetime",
      "nullable" : false,
      "autoincrement" : false,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : false,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });

    expect(columns.firstWhere((c) => c["name"] == "indexedValue"), {
      "name" : "indexedValue",
      "type" : "integer",
      "nullable" : false,
      "autoincrement" : false,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : false,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : true
    });

    expect(columns.firstWhere((c) => c["name"] == "autoincrementValue"), {
      "name" : "autoincrementValue",
      "type" : "integer",
      "nullable" : false,
      "autoincrement" : true,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : false,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });

    expect(columns.firstWhere((c) => c["name"] == "uniqueValue"), {
      "name" : "uniqueValue",
      "type" : "string",
      "nullable" : false,
      "autoincrement" : false,
      "unique" : true,
      "defaultValue" : null,
      "primaryKey" : false,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });

    expect(columns.firstWhere((c) => c["name"] == "defaultItem"), {
      "name" : "defaultItem",
      "type" : "string",
      "nullable" : false,
      "autoincrement" : false,
      "unique" : false,
      "defaultValue" : "'foo'",
      "primaryKey" : false,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });

    expect(columns.firstWhere((c) => c["name"] == "nullableValue"), {
      "name" : "nullableValue",
      "type" : "boolean",
      "nullable" : true,
      "autoincrement" : false,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : false,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });

    expect(columns.firstWhere((c) => c["name"] == "loadedValue"), {
      "name" : "loadedValue",
      "type" : "bigInteger",
      "nullable" : true,
      "autoincrement" : true,
      "unique" : true,
      "defaultValue" : "7",
      "primaryKey" : false,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : true
    });
  });

  test("A model graph", () {
    var dataModel = new DataModel([Container, DefaultItem, LoadedItem, LoadedSingleItem]);
    var generator = new Schema(dataModel);
    var json = generator.tables.map((st) => st.asJSON()).toList();

    expect(json.length, 4);

    var containerTable = json.firstWhere((t) => t["name"] == "_Container");
    expect(containerTable["name"], "_Container");
    var containerColumns = containerTable["columns"];
    expect(containerColumns.length, 1);
    expect(containerColumns.first, {
      "name" : "id",
      "type" : "bigInteger",
      "nullable" : false,
      "autoincrement" : true,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : true,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });

    var defaultItemTable = json.firstWhere((t) => t["name"] == "_DefaultItem");
    expect(defaultItemTable["name"], "_DefaultItem");
    var defaultItemColumns = defaultItemTable["columns"];
    expect(defaultItemColumns.length, 2);
    expect(defaultItemColumns.first, {
      "name" : "id",
      "type" : "bigInteger",
      "nullable" : false,
      "autoincrement" : true,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : true,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });
    expect(defaultItemColumns.last, {
      "name" : "container",
      "type" : "bigInteger",
      "nullable" : true,
      "autoincrement" : false,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : false,
      "relatedTableName" : "_Container",
      "relatedColumnName" : "id",
      "deleteRule" : "nullify",
      "indexed" : true
    });

    var loadedItemTable = json.firstWhere((t) => t["name"] == "_LoadedItem");
    expect(loadedItemTable ["name"], "_LoadedItem");
    var loadedColumns = loadedItemTable["columns"];
    expect(loadedColumns.length, 3);
    expect(loadedColumns[0], {
      "name" : "id",
      "type" : "bigInteger",
      "nullable" : false,
      "autoincrement" : true,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : true,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });
    expect(loadedColumns[1], {
      "name" : "someIndexedThing",
      "type" : "string",
      "nullable" : false,
      "autoincrement" : false,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : false,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : true
    });
    expect(loadedColumns[2], {
      "name" : "container",
      "type" : "bigInteger",
      "nullable" : true,
      "autoincrement" : false,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : false,
      "relatedTableName" : "_Container",
      "relatedColumnName" : "id",
      "deleteRule" : "restrict",
      "indexed" : true
    });

    var loadedSingleItemTable = json.firstWhere((t) => t["name"] == "_LoadedSingleItem");
    expect(loadedSingleItemTable ["name"], "_LoadedSingleItem");
    var loadedSingleColumns = loadedSingleItemTable["columns"];
    expect(loadedSingleColumns.length, 2);
    expect(loadedSingleColumns[0], {
      "name" : "id",
      "type" : "bigInteger",
      "nullable" : false,
      "autoincrement" : true,
      "unique" : false,
      "defaultValue" : null,
      "primaryKey" : true,
      "relatedTableName" : null,
      "relatedColumnName" : null,
      "deleteRule" : null,
      "indexed" : false
    });
    expect(loadedSingleColumns[1], {
      "name" : "container",
      "type" : "bigInteger",
      "nullable" : false,
      "autoincrement" : false,
      "unique" : true,
      "defaultValue" : null,
      "primaryKey" : false,
      "relatedTableName" : "_Container",
      "relatedColumnName" : "id",
      "deleteRule" : "cascade",
      "indexed" : true
    });
  });

  test("Tables get ordered correctly", () {
    var dataModel = new DataModel([SimpleModel, Container, DefaultItem, LoadedItem, LoadedSingleItem, ExtensiveModel]);
    var generator = new Schema(dataModel);
    var ordered = generator.dependencyOrderedTables.map((st) => st.name).toList();

    expect(ordered.indexOf("_Container"), lessThan(ordered.indexOf("_DefaultItem")));
    expect(ordered.indexOf("_Container"), lessThan(ordered.indexOf("_LoadedItem")));
    expect(ordered.indexOf("_Container"), lessThan(ordered.indexOf("_LoadedSingleItem")));

    dataModel = new DataModel([TreeLeaf, TreeRoot, TreeBranch]);
    generator = new Schema(dataModel);
    expect(generator.dependencyOrderedTables.map((st) => st.name).toList(), ["_TreeRoot", "_TreeBranch", "_TreeLeaf"]);
  });
}
