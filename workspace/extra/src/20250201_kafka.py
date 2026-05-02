# Databricks notebook source
df = (spark.read
    .format("kafka")
    .option("kafka.bootstrap.servers", "b-2.dbxkafkacluster.egq2ai.c3.kafka.ap-northeast-1.amazonaws.com:9098")
    .option("kafka.sasl.mechanism", "AWS_MSK_IAM")
    .option("kafka.sasl.jaas.config", "shadedmskiam.software.amazon.msk.auth.iam.IAMLoginModule required;")
    .option("kafka.security.protocol", "SASL_SSL")
    .option("kafka.sasl.client.callback.handler.class", "shadedmskiam.software.amazon.msk.auth.iam.IAMClientCallbackHandler")
    .option("subscribe", "SampleTopic01")
    .option("startingOffsets", "earliest")
    .option("endingOffsets", "latest")
    .load()
)
df.show(10)

# COMMAND ----------

df = (spark.readStream
    .format("kafka")
    .option("kafka.bootstrap.servers", "b-2.dbxkafkacluster.egq2ai.c3.kafka.ap-northeast-1.amazonaws.com:9098")
    .option("kafka.sasl.mechanism", "AWS_MSK_IAM")
    .option("kafka.sasl.jaas.config", "shadedmskiam.software.amazon.msk.auth.iam.IAMLoginModule required;")
    .option("kafka.security.protocol", "SASL_SSL")
    .option("kafka.sasl.client.callback.handler.class", "shadedmskiam.software.amazon.msk.auth.iam.IAMClientCallbackHandler")
    .option("subscribe", "SampleTopic01")
    .option("startingOffsets", "earliest")
    # .option("endingOffsets", "latest")
    .load()
)
df.display()