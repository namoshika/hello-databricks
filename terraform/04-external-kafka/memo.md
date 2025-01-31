# コマンド
Kafka 動作確認用のコマンドを以下に記載

```bash

# BootstrapServerString へ入れる値を取得
aws kafka get-bootstrap-brokers --cluster-arn ClusterARN

# 以下に続くコマンドのカレントディレクトリを指定
cd '/home/ec2-user/kafka_2.13-3.6.0/bin'

# Create Topic
./kafka-topics.sh --create \
    --bootstrap-server BootstrapServerString \
    --command-config client.properties \
    --replication-factor 2 \
    --partitions 1 \
    --topic SampleTopic01

# List Topic
./kafka-topics.sh --list \
    --bootstrap-server 'BootstrapServerString' \
    --command-config client.properties

# Produce Message
./kafka-console-producer.sh \
    --broker-list BootstrapServerString \
    --producer.config client.properties \
    --topic SampleTopic01

# Consume Message
./kafka-console-consumer.sh \
    --bootstrap-server BootstrapServerString \
    --consumer.config client.properties \
    --topic SampleTopic01 \
    --from-beginning

```

# 参考
https://docs.aws.amazon.com/msk/latest/developerguide/create-topic.html
