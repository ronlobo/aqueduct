import 'package:wildfire/wildfire.dart';
import 'package:scribe/scribe.dart';
import 'dart:async';

class TestApplication {
  TestApplication() {
    configuration = new WildfireConfiguration("config.yaml.src");
    configuration.database.isTemporary = true;
  }

  Application<WildfirePipeline> application;
  WildfirePipeline get pipeline => application.server.pipeline;
  LoggingServer logger = new LoggingServer([]);
  TestClient client;
  WildfireConfiguration configuration;

  Future start() async {
    await logger.start();

    application = new Application<WildfirePipeline>();
    application.configuration.pipelineOptions = {
      WildfirePipeline.ConfigurationKey: configuration,
      WildfirePipeline.LoggingTargetKey : logger.getNewTarget()
    };

    await application.start(runOnMainIsolate: true);

    ModelContext.defaultContext = pipeline.context;

    await createDatabaseSchema(pipeline.context, pipeline.logger);
    await addClientRecord();

    client = new TestClient(application.configuration.port)
      ..clientID = "com.aqueduct.test"
      ..clientSecret = "kilimanjaro";
  }

  Future stop() async {
    await pipeline.context.persistentStore?.close();
    await logger?.stop();
    await application?.stop();
  }

  static Future addClientRecord({String clientID: "com.aqueduct.test", String clientSecret: "kilimanjaro"}) async {
    var salt = AuthenticationServer.generateRandomSalt();
    var hashedPassword = AuthenticationServer.generatePasswordHash(clientSecret, salt);
    var testClientRecord = new ClientRecord();
    testClientRecord.id = clientID;
    testClientRecord.salt = salt;
    testClientRecord.hashedPassword = hashedPassword;

    var clientQ = new Query<ClientRecord>()
      ..values.id = clientID
      ..values.salt = salt
      ..values.hashedPassword = hashedPassword;
    await clientQ.insert();
  }

  static Future createDatabaseSchema(ModelContext context, Logger logger) async {
    var generator = new SchemaGenerator(context.dataModel);
    var json = generator.serialized;
    var pGenerator = new PostgreSQLSchemaGenerator(json, temporary: true);

    for (var cmd in pGenerator.commandList.split(";\n")) {
      logger?.info("$cmd");
      await context.persistentStore.execute(cmd);
    }
  }
}