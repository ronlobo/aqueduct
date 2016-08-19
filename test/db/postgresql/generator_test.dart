import 'package:aqueduct/aqueduct.dart';
import 'package:test/test.dart';
import '../../helpers.dart';

void main() {
  test("Property tables generate appropriate postgresql commands", () {
    expect(commandsForModelTypes([GeneratorModel1]),
        "CREATE TABLE _GeneratorModel1 (id BIGSERIAL PRIMARY KEY,name TEXT NOT NULL,option BOOLEAN NOT NULL,points DOUBLE PRECISION NOT NULL UNIQUE,validDate TIMESTAMP NULL);");
  });

  test("Create temporary table", () {
    expect(commandsForModelTypes([GeneratorModel1], temporary: true),
        "CREATE TEMPORARY TABLE _GeneratorModel1 (id BIGSERIAL PRIMARY KEY,name TEXT NOT NULL,option BOOLEAN NOT NULL,points DOUBLE PRECISION NOT NULL UNIQUE,validDate TIMESTAMP NULL);");
  });

  test("Create table with indices", () {
    expect(commandsForModelTypes([GeneratorModel2]),
        "CREATE TABLE _GeneratorModel2 (id INT PRIMARY KEY);\nCREATE INDEX _GeneratorModel2_id_idx ON _GeneratorModel2 (id);");
  });

  test("Create multiple tables with trailing index", () {
    expect(commandsForModelTypes([GeneratorModel1, GeneratorModel2]),
        "CREATE TABLE _GeneratorModel1 (id BIGSERIAL PRIMARY KEY,name TEXT NOT NULL,option BOOLEAN NOT NULL,points DOUBLE PRECISION NOT NULL UNIQUE,validDate TIMESTAMP NULL);\nCREATE TABLE _GeneratorModel2 (id INT PRIMARY KEY);\nCREATE INDEX _GeneratorModel2_id_idx ON _GeneratorModel2 (id);");
  });

  test("Default values are properly serialized", () {
    expect(commandsForModelTypes([GeneratorModel3]),
        "CREATE TABLE _GeneratorModel3 (creationDate TIMESTAMP NOT NULL DEFAULT (now() at time zone 'utc'),id INT PRIMARY KEY,textValue TEXT NOT NULL DEFAULT \$\$dflt\$\$,option BOOLEAN NOT NULL DEFAULT true,otherTime TIMESTAMP NOT NULL DEFAULT '1900-01-01T00:00:00.000Z',value DOUBLE PRECISION NOT NULL DEFAULT 20.0);");
  });

  test("Table with tableName() overrides class name", () {
    expect(commandsForModelTypes([GenNamed]),
        "CREATE TABLE GenNamed (id INT PRIMARY KEY);");
  });

  test("One-to-one relationships are generated", () {
    var cmds = commandsForModelTypes([GenOwner, GenAuth]);

    expect(cmds.contains("CREATE TABLE _GenOwner (id BIGSERIAL PRIMARY KEY)"), true);
    expect(cmds.contains("CREATE TABLE _GenAuth (id INT PRIMARY KEY,owner_id BIGINT NULL UNIQUE)"), true);
    expect(cmds.contains("CREATE INDEX _GenAuth_owner_id_idx ON _GenAuth (owner_id)"), true);
    expect(cmds.contains("ALTER TABLE ONLY _GenAuth ADD FOREIGN KEY (owner_id) REFERENCES _GenOwner (id) ON DELETE CASCADE"), true);
    expect(cmds.split("\n").length, 4);
  });

  test("One-to-many relationships are generated", () {
    var cmds = commandsForModelTypes([GenUser, GenPost]);

    expect(cmds.contains("CREATE TABLE _GenUser (id INT PRIMARY KEY,name TEXT NOT NULL)"), true);
    expect(cmds.contains("CREATE TABLE _GenPost (id INT PRIMARY KEY,text TEXT NOT NULL,owner_id INT NULL)"), true);
    expect(cmds.contains("CREATE INDEX _GenPost_owner_id_idx ON _GenPost (owner_id)"), true);
    expect(cmds.contains("ALTER TABLE ONLY _GenPost ADD FOREIGN KEY (owner_id) REFERENCES _GenUser (id) ON DELETE RESTRICT"), true);
    expect(cmds.split("\n").length, 4);
  });

  test("Many-to-many relationships are generated", () {
    var cmds = commandsForModelTypes([GenLeft, GenRight, GenJoin]);

    expect(cmds.contains("CREATE TABLE _GenLeft (id INT PRIMARY KEY)"), true);
    expect(cmds.contains("CREATE TABLE _GenRight (id INT PRIMARY KEY)"), true);
    expect(cmds.contains("CREATE TABLE _GenJoin (id BIGSERIAL PRIMARY KEY,left_id INT NULL,right_id INT NULL)"), true);
    expect(cmds.contains("ALTER TABLE ONLY _GenJoin ADD FOREIGN KEY (left_id) REFERENCES _GenLeft (id) ON DELETE SET NULL"), true);
    expect(cmds.contains("ALTER TABLE ONLY _GenJoin ADD FOREIGN KEY (right_id) REFERENCES _GenRight (id) ON DELETE SET NULL"), true);
    expect(cmds.contains("CREATE INDEX _GenJoin_left_id_idx ON _GenJoin (left_id)"), true);
    expect(cmds.contains("CREATE INDEX _GenJoin_right_id_idx ON _GenJoin (right_id)"), true);
    expect(cmds.split("\n").length, 7);
  });

  test("Serial types in relationships are properly inversed", () {
    var cmds = commandsForModelTypes([GenOwner, GenAuth]);
    expect(cmds.contains("CREATE TABLE _GenAuth (id INT PRIMARY KEY,owner_id BIGINT NULL UNIQUE)"), true);
  });
}

class GeneratorModel1 extends Model<_GeneratorModel1> implements _GeneratorModel1 {}

class _GeneratorModel1 {
  @primaryKey
  int id;

  String name;

  bool option;

  @Attributes(unique: true)
  double points;

  @Attributes(nullable: true)
  DateTime validDate;
}

class GeneratorModel2 extends Model<_GeneratorModel2> implements _GeneratorModel2 {}
class _GeneratorModel2 {
  @Attributes(primaryKey: true, indexed: true)
  int id;
}

class GeneratorModel3 extends Model<_GeneratorModel3> implements _GeneratorModel3 {}
class _GeneratorModel3 {
  @Attributes(defaultValue: "(now() at time zone 'utc')")
  DateTime creationDate;

  @Attributes(primaryKey: true, defaultValue: "18")
  int id;

  @Attributes(defaultValue: "\$\$dflt\$\$")
  String textValue;

  @Attributes(defaultValue: "true")
  bool option;

  @Attributes(defaultValue: "'1900-01-01T00:00:00.000Z'")
  DateTime otherTime;

  @Attributes(defaultValue: "20.0")
  double value;
}

class GenUser extends Model<_GenUser> implements _GenUser {}

class _GenUser {
  @Attributes(primaryKey: true)
  int id;

  String name;

  @Relationship(RelationshipType.hasMany, "owner")
  List<GenPost> posts;
}

class GenPost extends Model<_GenPost> implements _GenPost {}
class _GenPost {
  @Attributes(primaryKey: true)
  int id;

  String text;

  @Relationship(RelationshipType.belongsTo, "posts", required: false, deleteRule: RelationshipDeleteRule.restrict)
  GenUser owner;
}

class GenNamed extends Model<_GenNamed> implements _GenNamed {}

class _GenNamed {
  @Attributes(primaryKey: true)
  int id;

  static String tableName() {
    return "GenNamed";
  }
}

class GenOwner extends Model<_GenOwner> implements _GenOwner {}
class _GenOwner {
  @primaryKey
  int id;

  @Relationship(RelationshipType.hasOne, "owner")
  GenAuth auth;
}

class GenAuth extends Model<_GenAuth> implements _GenAuth {}
class _GenAuth {
  @Attributes(primaryKey: true)
  int id;

  @Relationship(RelationshipType.belongsTo, "auth", required: false, deleteRule: RelationshipDeleteRule.cascade)
  GenOwner owner;
}

class GenLeft extends Model<_GenLeft> implements _GenLeft {}

class _GenLeft {
  @Attributes(primaryKey: true)
  int id;

  @Relationship(RelationshipType.hasMany, "left")
  List<GenJoin> join;
}

class GenRight extends Model<_GenRight> implements _GenRight {}

class _GenRight {
  @Attributes(primaryKey: true)
  int id;

  @Relationship(RelationshipType.hasMany, "right")
  List<GenJoin> join;
}

class GenJoin extends Model<_GenJoin> implements _GenJoin {}
class _GenJoin {
  @primaryKey
  int id;

  @Relationship(RelationshipType.belongsTo, "join")
  GenLeft left;

  @Relationship(RelationshipType.belongsTo, "join")
  GenRight right;
}

class GenObj extends Model<_GenObj> implements _GenObj {}
class _GenObj {
  @primaryKey
  int id;

  @Relationship(RelationshipType.hasOne, "ref")
  GenNotNullable gen;
}

class GenNotNullable extends Model<_GenNotNullable> implements _GenNotNullable {}
class _GenNotNullable {
  @primaryKey
  int id;

  @Relationship(RelationshipType.belongsTo, "gen", deleteRule: RelationshipDeleteRule.nullify, required: false)
  GenObj ref;
}
