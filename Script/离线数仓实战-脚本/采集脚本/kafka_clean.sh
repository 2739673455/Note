#!/bin/bash
# 清理kafka中topic_log和topic_db主题
ssh hadoop103 "kafka-topics.sh --bootstrap-server hadoop103:9092 --delete --topic topic_log"
ssh hadoop103 "kafka-topics.sh --bootstrap-server hadoop103:9092 --delete --topic topic_db"
ssh hadoop103 "kafka-topics.sh --bootstrap-server hadoop103:9092 --list"