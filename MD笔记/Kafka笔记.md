# 1.Kafka概述
## 1.传统消息队列的应用场景
### 1.缓冲/消峰
    有助于控制和优化数据流经过系统的速度，解决生产消息和消费消息的处理速度不一致的情况
### 2.解耦
    允许独立的扩展或修改两边的处理过程，只要确保它们遵守同样的接口约束
### 3.异步通信
    允许用户把一个消息放入队列，但并不立即处理它，然后在需要的时候再去处理它们
## 2.消息队列的两种模式
### 1.点对点模式
    消费者主动拉取数据，消息收到之后清除消息
### 2.发布/订阅模式
    可以有多个topic主题(浏览、点赞、收藏、评论等)
    消费者消费数据后，不删除数据
    每个消费者相互独立，都可以消费到数据
## 3.Kafka基础架构
| 参数 | 描述 |
| --- | --- |
| Producer | 			消息生产者，就是向Kafka broker发消息的客户端
| Consumer | 			消息消费者，从Kafka broker取消息的客户端
| Consumer Group(CG) | 			消费者组，由多个consumer组成，消费者组内每个消费者负责消费不同分区的数据，一个分区只能由一个组内消费者消费，消费者组之间互不影响，所有的消费者都属于某个消费者组，即消费者组是逻辑上的一个订阅者
| Broker | 			一台Kafka服务器就是一个broker，一个集群由多个broker组成，一个broker可以容纳多个topic
| Topic | 			可以理解为一个队列，生产者和消费者面向的都是一个topic
| Partition | 			为了实现扩展性，一个非常大的topic可以分布到多个broker(即服务器)上，一个topic可以分为多个partition，每个partition是一个有序的队列
| Replica | 			副本，一个topic的每个分区都有若干个副本，一个Leader和若干个Follower
| Leader | 			每个分区多个副本的“主”，生产者发送数据的对象，以及消费者消费数据的对象都是Leader
| Follower | 			每个分区多个副本中的“从”，实时从Leader中同步数据，保持和Leader数据的同步，Leader发生故障时，某个Follower会成为新的Leader
# 2.Kafka入门
## 1.安装部署
### 1.修改配置文件
    /opt/module/kafka_2.12-3.6.1/config/server.properties
| 参数 | 描述 |
| --- | --- |
| broker.id=0 | 				broker的全局唯一编号，不能重复，只能是数字
| log.dirs=/opt/module/kafka/datas | 				Kafka运行日志(数据)存放的路径，路径不需要提前创建，Kafka自动帮你创建，可以配置多个磁盘路径，路径与路径之间可以用","分隔
| zookeeper.connect=hadoop102:2181,hadoop103:2181,hadoop104:2181/kafka | 				配置连接Zookeeper集群地址(在zk根目录下创建/Kafka，方便管理)
### 2.启动与关闭
    1. 启动
        kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties
        先启动Zookeeper集群，然后启动Kafka
    2. 关闭
        kafka-server-stop.sh
        停止Kafka集群时，一定要等Kafka所有节点进程全部停止后再停止Zookeeper集群，因为Zookeeper集群当中记录着Kafka集群相关信息，Zookeeper集群一旦先停止，Kafka集群就没有办法再获取停止进程的信息，只能手动杀死Kafka进程了
## 2.命令行操作
### 1.主题命令行操作
| 参数 | 描述 |
| --- | --- |
| kafka-topics.sh                   | 查看操作主题命令参数
| --bootstrap-server hadoop102:9092 | 连接的Kafka Broker主机名称和端口号
| --topic 主题名                     | 操作的topic名称
| --create                          | 创建主题
| --delete                          | 删除主题
| --alter                           | 修改主题
| --list                            | 查看所有主题
| --describe                        | 查看主题详细描述
| --partitions 分区数                | 设置分区数
| --replication-factor 副本数        | 设置分区副本
| --config <name=value>             | 更新系统默认的配置
### 2.生产者命令行操作
| 参数 | 描述 |
| --- | --- |
| kafka-console-producer.sh         | 查看操作生产者命令参数
| --bootstrap-server hadoop102:9092 | 连接的Kafka Broker主机名称和端口号
| --topic 主题名                     | 操作的topic名称
### 3.消费者命令行操作
| 参数 | 描述 |
| --- | --- |
| kafka-console-consumer.sh         | 查看操作消费者命令参数
| --bootstrap-server hadoop102:9092 | 连接的Kafka Broker主机名称和端口号
| --topic 主题名                     | 操作的topic名称
| --from-beginning                  | 从头开始消费
| --group 消费者组名称                | 指定消费者组名称
# 3.生产者
## 1.生产者消息发送流程
    在消息发送的过程中，涉及到了两个线程，main线程和Sender线程
    在main线程中创建双端队列RecordAccumulator，main线程将消息发送给RecordAccumulator
    Sender线程不断从RecordAccumulator中拉取消息发送到Kafka Broker
    1. 生产者生成消息后先经过拦截器Interceptors
    2. 经过序列化器Serializer，根据key和value的序列化配置对消息内容序列化
    3. 经过分区器Partitioner，根据分区进入相应RecordAccumulator队列(默认大小32m)
    4. 当到达batch.size大小(默认16k)，或到达linger.ms时间(默认0ms)，sender拉取数据打包成request请求
    5. 多少个broker有leader，则有多少组请求队列，每个请求队列最多缓存5个请求
    6. sender向各个broker发送数据
    7. broker根据acks进行应答
        acks=0:生产者发送来的数据，不需要等数据落盘就应答
        acks=1:生产者发送来的数据，leader收到数据后应答
        acks=-1(all):生产者发送来的数据，leader和isr队列中所有节点收齐数据后应答
    8. broker的应答返回selector，如果失败则重试，如果成功则清理发送过的数据
## 2.生产者重要参数
| 参数 | 描述 |
| --- | --- |
| bootstrap.servers | 			生产者连接集群所需的broker地址清单，例如hadoop102:9092,hadoop103:9092,hadoop104:9092，可以设置1个或者多个，中间用逗号隔开，注意这里并非需要所有的broker地址，因为生产者从给定的broker里查找到其他broker信息
| key.serializer和value.serializer | 			指定发送消息的key和value的序列化类型，一定要写全类名
| buffer.memory | 			RecordAccumulator缓冲区总大小，默认32m
| batch.size | 			缓冲区一批数据最大值，默认16k，适当增加该值，可以提高吞吐量，但是如果该值设置太大，会导致数据传输延迟增加
| linger.ms | 			如果数据迟迟未达到batch.size，sender等待linger.time之后就会发送数据，单位ms，默认值是0ms，表示没有延迟，生产环境建议该值大小为50-100ms之间
| acks | 			0:生产者发送过来的数据，不需要等数据落盘应答， 1:生产者发送过来的数据，Leader收到数据后应答， -1(all):生产者发送过来的数据，Leader+和isr队列里面的所有节点收齐数据后应答，默认值是-1，-1和all是等价的
| max.in.flight.requests.per.connection | 			允许最多没有返回ack的次数，默认为5，开启幂等性要保证该值是 1-5的数字
| retries | 			当消息发送出现错误的时候，系统会重发消息，retries表示重试次数，默认是int最大值，2147483647，如果设置了重试，还想保证消息的有序性，需要设置max.in.flight.requests.per.connection=1否则在重试此失败消息的时候，其他的消息可能发送成功了
| retry.backoff.ms | 			两次重试之间的时间间隔，默认是100ms
| enable.idempotence | 			是否开启幂等性，默认true，开启幂等性
| compression.type | 			生产者发送的所有数据的压缩方式，默认是none，也就是不压缩，支持压缩类型:none、gzip、snappy、lz4和zstd
## 3.生产者分区
### 1.分区的好处
    1. 便于合理使用存储资源:将海量数据按分区切割存储在多台broker上，实现负载均衡
    2. 提高并行度:生产者可以以分区为单位发送数据，消费者可以以分区为单位消费数据
### 2.分区策略
    1. 指明partition
    2. 没指明partition但有key，将key的hash值与topic的partition数取余得到partition值
    3. 既没指明partition又没有key，使用Sticky Partition(黏性分区器)随机选择一个分区，并尽可能一直使用该分区，待该分区的batch已满或者已完成，在随机一个和前一次不同的分区
    4. 自定义分区器，实现Partition接口，重写partition()方法
## 4.生产经验
### 1.提高吞吐量
    1. batch.size增加批次大小
    2. linger.ms延长等待时间
    3. compression.type压缩文件
    4. RecordAccumulator增加缓冲区大小
### 2.数据可靠性
    1. 数据完全可靠条件:ack级别设置为-1，分区副本数>=2，isr里应答的最小副本数量>=2
### 3.数据去重
    1. 幂等性:具有<PID,Partition,SeqNumber>相同的主键消息提交时，broker只会持久化一条
        PID是Kafka每次重启就会分配一个新的
        Partition表示分区号
        Sequence Number是单调自增的
        所以幂等性只能保证在单分区单会话内不重复
        enable.idempotence  #默认为true，开启幂等性
    2. 生产者事务
        注意:提前开启幂等性
        Kafka0.11版本引入了事务的特性，为了实现跨分区跨会话的事务，需要引入一个全局唯一的Transaction ID，并将Producer获得的PID和Transaction ID绑定，这样当Producer重启后就可以通过正在进行的Transaction ID获得原来的PID
        为了管理Transaction，Kafka引入了一个新的组件Transaction Coordinator，Producer就是通过和Transaction Coordinator交互获得Transaction ID对应的任务状态，Transaction Coordinator还负责将事务所有写入Kafka的一个内部Topic，这样即使整个服务重启，由于事务状态得到保存，进行中的事务状态可以得到恢复，从而继续进行
### 4.数据有序
    1. Kafka最多只保证单分区内的消息是有序的，所以如果要保证业务全局严格有序，就要设置topic为单分区
    2. 如何保证单分区内数据有序
        1. 禁止重试，设置retries=0，会导致丢失数据
        2. 启用幂等性，设置以下参数
            enable.idempotence=true
            max.in.flight.requests.per.connection<=5
            retries>0
            acks=-1
            当此批次的SeqNumber比最新的SeqNumber大2，证明乱序，拒绝写入，回应Producer，对RecorderAccumulator中的分区的batch重新排序
# 4.Broker
## 1.Broker工作流程
### 1.Zookeeper中存储的Kafka信息
    admin
    brokers
        ids  #[0,1,2] 记录有哪些服务器
        topics
            first  #主题名
                partitions  #分区
                    0  #分区号
                        state  #{"leader":1,"isr":[1,0,2]} 记录谁是leader，有哪些服务器可用
        seqid
    cluster
        id
    consumers  #0.9版本之前保存offset信息，0.9之后offset存储在Kafka主题中
    controller
    config
### 2.leader选举流程
    1. broker启动后在zookeeper中注册
    2. broker中的controller先在zookeeper中的controller节点注册的进行leader选举决策
    3. controller监听zookeeper中brokers节点变化
    4. controller在ar中按顺序轮询，如果在isr中存活，则选为leader
    5. controller将选举结果写入zookeeper的/brokers/topic/主题名/partitions/0/state中
    6. 其他controller从zookeeper中读取选举结果
    7. 如果leader挂了，zookeeper会反向通知controller
    8. controller获取isr，重新选举leader，并在zookeeper节点中更新leader和isr
### 3.重要参数
| 参数 | 描述 |
| --- | --- |
| replica.lag.time.max.ms | 				默认30s，follower长时间未向leader发送通信请求或同步数据，则该follwer将被踢出isr
| auto.leader.rebalance.enable | 				默认true，自动leader partition平衡
| leader.imbalance.per.broker.percentage | 				默认10%，每个broker允许的不平衡的leader比率，如果每个broker超过该值，控制器会触发leader的平衡
| leader.imbalance.check.interval.seconds | 				默认300s，检查leader负载是否平衡的间隔时间
| log.segment.bytes | 				默认1G，Kafka中log日志分块存储，指定log日志划分成块的大小
| log.index.interval.bytes | 				默认4kb，Kafka里面每当写入4kb大小的日志，就往index文件里记录一个索引
| log.retention.hours | 				默认7天，Kafka中数据保存的时间
| log.retention.minutes | 				默认关闭，Kafka中数据保存的时间，分钟级别
| log.retention.ms | 				默认关闭，Kafka中数据保存的时间，毫秒级别
| log.retention.check.interval.ms | 				默认5分钟，检查数据是否保存超时的间隔
| log.retention.bytes | 				默认-1，表示无穷大，若超过设置的所有日志总大小，删除最早的segment
| log.cleanup.policy | 				默认delete，表示所有数据启用删除策略，如果设置值为compact，表示所有数据启用压缩策略
| num.io.threads | 				默认8，负责写磁盘的线程数，整个参数值要占总核数的50%
| num.replica.fetchers | 				副本拉取线程数，这个参数占总核数的50%的1/3
| num.network.threads | 				默认3，数据传输线程数，这个参数占总核数的50%的2/3
| log.flush.interval.messages | 				默认long的最大值，9223372036854775807，强制页缓存刷写到磁盘的条数，一般不建议修改，交给系统自己管理
| log.flush.interval.ms | 				默认null，每隔多久，刷数据到磁盘，一般不建议修改，交给系统自己管理
## 2.副本
### 1.副本基本信息
    1. 副本作用:提高数据可靠性
    2. 默认副本:生产环境一般配置2个，保证数据可靠性，太多副本会增加磁盘存储空间，增加网络上数据传输，降低效率
    3. Kafka中副本分为leader和follower，Kafka生产者只会把数据发往leader，然后follower找leader同步数据
    4. Kafka分区中的所有副本统称为AR(Assigned Repllicas)，AR=ISR+OSR
        ISR，表示和leader保持同步的follower集合
        OSR，表示follower与leader副本同步时，延迟过多的副本
### 2.Follower故障处理细节
    LEO(log end offset):每个副本的最后一个offset，LEO其实就是最新的offset+1
    HW(high watermark):所有副本中最小的LEO
    1. follower发生故障后会被临时踢出isr
    2. 这期间leader和follower继续接受数据
    3. 待故障的follower恢复后，读取本地磁盘记录的上次的HW，将log文件高于HW的部分截取掉，从HW开始向leader进行同步
    4. 等待该follower的LEO>=该Partition的HW，即follower追上leader之后，就可以重新加入isr
### 3.Leader故障处理细节
    1. leader发生故障后，会从isr中选出新的leader
    2. 为保证多个副本之间的数据一致性，其余的follower会先将各自的log文件高于HW的部分截掉，然后从新的leader同步数据
    注意:这只能保证副本之间的数据一致性，并不能保证数据不丢失或者不重复
## 3.文件存储
### 1.文件存储机制
#### 1.topic数据的存储机制
    1. 每个partition对应与一个log文件，该log文件中存储的就是Producer生产的数据
    2. Producer生产的数据会不断被追加到该log文件末端，为防止log文件过大导致数据定位效率低下，Kafka采取分片和索引机制，将每个partition分为多个segment
    3. 每个segment包括.index文件、.log文件、.timeindex文件等，这些文件位于一个文件夹下，该文件夹的命名规则为:topic名-分区序号，如:first-0
#### 2.查看数据
    kafka-run-class.sh kafka.tools.DumpLogSegments --files 文件名
    kafka-run-class.sh kafka.tools.DumpLogSegments --print-data-log --files 文件名
#### 3.index和log文件详解
    如何在log文件中定位到指定offset的Record:
    1. 根据目标offset定位Segment文件
    2. 找到<=目标offset的最大offset对应的索引项
    3. 定位到log文件
    4. 向下遍历找到目标Record
    注意:
    1. index为稀疏索引，大约每向log文件中写入4kb数据，就会向index文件写入一条索引
    2. index文件中保存的offset为相对值，以确保offset的值所占空间不会太大
### 2.文件清理策略
    1. 日志默认保存7天，可通过参数修改保存时间
        log.retention.hours  #默认7天，Kafka中数据保存的时间
        log.retention.minutes  #默认关闭，Kafka中数据保存的时间，分钟级别
        log.retention.ms  #默认关闭，Kafka中数据保存的时间，毫秒级别
    2. delete日志删除:将过期数据删除
        log.cleanup.policy = delete  #所有数据启用删除策略
    3. compact日志压缩:对于相同key的不同value值，只保存最后一个版本，压缩后的offset可能是不连续的
        log.cleanup.policy=compact  #数据启用压缩
## 4.高效读写
    1. Kafka是分布式集群，使用分区技术，并行度高
    2. 读数据采用稀疏索引，可快速定位要消费的数据
    3. 顺序写磁盘，写的过程为追加，省去了大量磁头寻址时间
    4. 页缓存+零拷贝技术
        PageCache页缓存:Kafka重度依赖底层操作系统提供的PageCache功能，当上层有写操作时，操作系统只是将数据写入PageCache。当读操作发生时，先从PageCache中查找，如果找不到再去磁盘中读取。实际上PageCache是把尽可能多的空闲内存当作磁盘缓存使用
        零拷贝:Kafka的数据加工处理操作交由Kafka生产者和Kafka消费者处理，Kafka broker应用层不关心存储的数据，所以不用走应用层，传输效率高
        log.flush.interval.messages  #默认是long的最大值，强制页缓存刷写到磁盘的条数，一般不建议修改，交给系统自己管理
        log.flush.interval.ms  #默认是null，每隔多久，刷数据到磁盘，一般不建议修改，交给系统自己管理
# 5.消费者
## 1.消费方式:pull
    consumer从broker中主动拉取数据
    如果Kafka没有数据，消费者可能陷入循环，一直返回空数据
## 2.工作流程
### 1.消费者组原理
    1. 消费者组内每个消费者负责消费不同分区的数据，一个分区只能由一个组内消费者消费
    2. 消费者组之间互不影响，所有消费者都属于某个消费者组
    3. 消费者组是逻辑上的一个订阅者
    4. 如果消费者组中消费者的数量超过主题分区数量，则有一部分消费者会闲置
### 2.消费者组初始化流程
    1. coordinator:辅助实现消费者组的初始化和分区的分配
        coordinator节点选择=groupid的hashcode值 % 50(__consumer_offsets的分区数量)
        例如:groupid的hashcode值=1，1%50=1，那么__consumer_offsets主题的1号分区在哪个broker上，就选择此节点的coordinator作为该消费者组的老大，消费者组下的所有消费者提交offset的时候就往这个分区去提交offset
    2. 每个consumer都向coordinator发送JoinGroup请求
    3. coordinator随机选出一个consumer作为leader
    4. coordinator把要消费的topic情况发送给leader消费者
    5. leader制定消费方案并发给coordinator
    6. coordinator把消费方案下发给各个consumer
    7. 每个消费者都会和coordinator保持心跳(默认3s)，一旦超时(session.timeout.ms=45s)，该消费者会被移除，并触发再平衡。或者消费者处理消息的时间过长(max.poll.interval.ms=5分钟)，也会触发再平衡
### 3.消费者组详细消费流程
    1. consumer发送消费请求
    2. broker处理
    3. FetchedRecords从队列中抓取数据
    4. ParseRecord反序列化
    5. Interceptors拦截器
    6. 处理数据
    fetch.max.wait.ms  #默认500ms，一批数据最小值未达到的超时时间
    fetch.max.bytes  #默认50m，每批次最大抓取大小
    fetch.min.bytes  #默认1字节，每批次最小抓取大小
    max.poll.records  #默认500条，一次拉取数据返回消息的最大条数，每条数据都要走一遍处理逻辑
## 3.重要参数
| 参数 | 描述 |
| --- | --- |
| bootstrap.servers | 			向Kafka集群建立初始链接用到的host/port列表
| key.deserializer和value.deserializer | 			指定接收消息的key和value的反序列化类型，一定要写全类名
| group.id | 			标记消费者所属的消费者组
| enable.auto.commit | 			默认true，消费者会自动周期性地向服务器提交偏移量
| auto.commit.interval.ms | 			默认5s，如果设置了enable.auto.commit的值为true， 则该值定义了消费者偏移量向Kafka提交的频率
| auto.offset.reset | 			当Kafka中没有初始偏移量或当前偏移量在服务器中不存在(如，数据被删除了)时如何处理，earliest:自动重置偏移量到最早的偏移量， latest:默认，自动重置偏移量为最新的偏移量， none:如果消费组原来的(previous)偏移量不存在，则向消费者抛异常， anything:向消费者抛异常
| offsets.topic.num.partitions | 			默认50，__consumer_offsets的分区数
| heartbeat.interval.ms | 			默认3s，Kafka消费者和coordinator之间的心跳时间，该条目的值必须小于session.timeout.ms，也不应该高于session.timeout.ms 的1/3
| session.timeout.ms | 			默认45s，Kafka消费者和coordinator之间连接超时时间，超过该值，该消费者被移除，消费者组执行再平衡
| max.poll.interval.ms | 			默认是5分钟，消费者处理消息的最大时长，超过该值，该消费者被移除，消费者组执行再平衡
| fetch.min.bytes | 			默认1个字节，消费者获取服务器端一批消息最小的字节数
| fetch.max.wait.ms | 			默认500ms，如果没有从服务器端获取到一批数据的最小字节数。该时间到，仍然会返回数据
| fetch.max.bytes | 			默认Default:52428800(50m)，消费者获取服务器端一批消息最大的字节数。如果服务器端一批次的数据大于该值(50m)仍然可以拉取回来这批数据，因此，这不是一个绝对最大值。一批次的大小受message.max.bytes(broker config)或max.message.bytes(topic config)影响
| max.poll.records | 			默认500条，一次poll拉取数据返回消息的最大条数
## 4.offset位移
### 1.offset的默认维护位置
    __consumer_offsets
    __consumer_offsets主题里面采用key和value的方式存储数据。key是group.id+topic+分区号，value就是当前offset的值。每隔一段时间，Kafka内部会对这个topic进行compact，也就是每个group.id+topic+分区号只保留最新数据
### 2.自动提交offset
    enable.auto.commit  #默认true，是否开启自动提交offset功能
    auto.commit.interval.ms  #默认5s，自动提交offset的时间间隔
### 3.手动提交offset
    由于自动提交offset基于时间提交，开发人员难以把握offset提交的时机，因此Kafka提供手动提交offset的API
    手动提交offset方式有commitSync(同步提交)和commitAsync(异步提交)两种，两者都会将本次提交的一批数据最高的偏移量提交
    同步提交阻塞当前线程，失败自动重试，直到提交成功。必须等待offset提交完毕再消费下一批数据
    异步提交没有失败重试机制，有可能提交失败。发送完offset提交请求后就开始消费下一批数据
### 4.offset消费的不同模式
    auto.offset.reset = earliest | latest | none  #默认是latest
    当Kafka中没有初始偏移量(消费者组第一次消费)或服务器上不再存在当前偏移量时(例如该数据已被删除)如何处理:
    earliest:自动将偏移量重置为最早的偏移量，--from-beginning
    latest(默认值):自动将偏移量重置为最新偏移量
    none:如果未找到消费者组的先前偏移量，则向消费者抛出异常
### 5.重复消费与漏消费
    1. 重复消费:已经消费了数据，但是offset没提交
        offset提交后，comsumer又向后处理了数据但是还未提交offset，此时comsumer挂了，再次重启comsumer，从上次提交的offset处继续消费，导致重复消费
    2. 漏消费:先提交offset后消费，有可能会造成数据的漏消费
        offset被提交时，数据还在内存中未落盘，此时消费者线程被kill掉，offset已提交，但是数据未处理，导致这部分内存中的数据丢失
## 5.生产经验
### 1.分区的分配及再平衡
    Kafka有四种主流分配策略:Range，RoundRobin，Sticky，CooperactiveSticky
    partition.assignment.strategy  #消费者分区分配策略，默认策略是Range+CooperativeSticky，可同时使用多个分区分配策略
    某个消费者挂掉后，消费者组需要等待45s来判断它是否退出，判断它真的退出就会把任务分配给其他consumer执行，故障消费者被踢出消费者组后重新分配消费分区
#### 1.Range及再分配
    Range是对每个topic而言的
    1. 首先对同一个topic里面的分区按照序号进行排序，并对消费者按照字母顺序进行排序
        例如，现在有7个分区，3个消费者，排序后的分区将会是0,1,2,3,4,5,6。消费者排序完之后将会是C0,C1,C2
    2. 通过 partitions数/consumer数 来决定每个消费者应该消费几个分区。如果除不尽，那么前面几个消费者将会多消费1个分区
        例如，7/3=2余1，消费者C0便会多消费1个分区
    注意:如果只是针对1个topic而言，C0消费者多消费1个分区影响不是很大。但是如果有N个topic，那么针对每个topic，消费者C0都将多消费1个分区，容易产生数据倾斜
#### 2.RoundRobin(轮询)及再平衡
    RoundRobin是对集群中所有topic而言
    RoundRobin轮询分区策略，是把所有的partition和所有的consumer都列出来，然后按照hashcode进行排序，最后通过轮询算法来分配partition给到各个消费者
#### 3.Sticky及再平衡
    可理解为分配结果带有“粘性”。首先会尽量均衡的放置分区到消费者上，在出现同一消费者组内消费者出现问题的时候，会尽量保持原有分配的分区不变化，可以节省大量的开销
### 2.消费者事务
    如果想完成Consumer端的精准一次性消费，那么需要Kafka消费端将消费过程和提交offset过程做原子绑定，此时我们需要将Kafka的offset保存到支持事务的自定义介质(比如MySQL)，并指定消费者的offset
### 3.数据积压(消费者如何提高吞吐量)
    1. 如果是Kafka消费能力不足，可以考虑增加topic的分区数，并且同时提升消费组的消费者数量，消费者数=分区数(两者缺一不可)
    2. 如果是下游的数据处理不及时，提高每批次拉取的数量。批次拉取数据过少(拉取数据/处理时间<生产速度)，使处理的数据小于生产的数据，也会造成数据积压
    fetch.max.bytes  #默认Default:52428800(50m)，消费者获取服务器端一批消息最大的字节数
    max.poll.records  #默认500条，一次poll拉取数据返回消息的最大条数
# 6.Kafka Kraft模式
## 1.Kraft架构
    Kraft模式架构:不再依赖zookeeper集群，而是用三台controller节点代替zookeeper，元数据保存在controller中，由controller直接进行Kafka集群管理
    优点:
    1. Kafka不再依赖外部框架，而是能够独立运行
    2. controller管理集群时，不再需要从zookeeper中先读取数据，集群性能上升
    3. 由于不依赖zookeeper，集群扩展时不再受到zookeeper读写能力限制
    4. controller不再动态选举，而是由配置文件规定。这样我们可以有针对性的加强controller节点的配置，而不是像以前一样对随机controller节点的高负载束手无策
## 2.Kafka-Kraft集群部署
    1. 修改/opt/module/kafka-kraft/config/kraft/server.properties配置文件
        process.roles=broker, controller
            #kafka的角色(controller相当于主机、broker节点相当于从机，主机类似zk功能)
        node.id=2
            #节点ID
        controller.quorum.voters=2@hadoop102:9093,3@hadoop103:9093,4@hadoop104:9093
            #全Controller列表
        advertised.Listeners=PLAINTEXT://hadoop102:9092
            #broker对外暴露的地址
        log.dirs=/opt/module/kafka-kraft/datas
            #kafka数据存储目录
        分发配置文件
    2. 初始化集群数据目录
        1. 首先生成存储目录唯一ID。
            bin/kafka-storage.sh random-uuid
                J7s9e8PPTKOO47PxzI39VA
        2. 用该ID格式化kafka存储目录(三台节点)
            bin/kafka-storage.sh format -t J7s9e8PPTKOO47PxzI39VA -c /opt/module/kafka2/config/kraft/server.properties × 3
        3. 启动kafka集群
            bin/kafka-server-start.sh -daemon config/kraft/server.properties × 3