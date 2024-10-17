# 1.Flink概述
    1. Flink是什么
        Flink是一个框架和分布式处理引擎，用于对无界和有界数据流进行有状态计算
    2. Flink特点
        高吞吐，低延迟: 每秒处理数百万个时间，毫秒级延迟
        结果的准确性: Flink提供了事件时间和处理时间语义，对于乱序事件流，事件时间语义仍能提供一致且准确的结果
        精确一次: 状态一致性保证
        可以连接常用的存储系统: Kafka,Hive,JDBC,HDFS,Redis等
        高可用: 本身高可用，或与Yarn,K8S集成
    3. Flink应用场景
        电商和市场营销: 实时数据报表，广告投放，实时推荐
        物联网: 传感器实时数据采集与显示，实时报警，交通运输业
        物流配送和服务业: 订单状态实时更新，通知信息推送
        银行和金融业: 实时结算和通知推送，实时检测异常行为
    4. Flink分层API
        有状态流处理(底层API): 通过底层API，对最原始数据加工处理
        DataStream(核心API): 封装底层处理函数，提供通用模块
        Table API(声明式领域专用语言): 以表为中心的声明式编程
        SQL(最高层语言): 以SQL查询表达式的形式表现程序
# 2.Flink快速上手
## 1.添加依赖
    <properties>
        <flink.version>1.17.0</flink.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-streaming-java</artifactId>
            <version>${flink.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-clients</artifactId>
            <version>${flink.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-log4j12</artifactId>
            <version>1.7.25</version>
            <scope>provided</scope>
        </dependency>
    </dependencies>
    添加log4j.properties文件
        log4j.rootLogger=error, stdout
        log4j.appender.stdout=org.apache.log4j.ConsoleAppender
        log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
        log4j.appender.stdout.layout.ConversionPattern=%-4r [%t] %-5p %c %x - %m%n
## 2.批处理
    /*
    * 批处理 - DataSet
    * 1. 准备执行环境
    * 2. 读取数据(source)
    * 3. 对数据转换处理(transformation)
    * 4. 输出结果(sink)
    * */
    public class Flink01_BatchWordCount {
        public static void main(String[] args) throws Exception {
            //1. 准备执行环境
            ExecutionEnvironment env = ExecutionEnvironment.getExecutionEnvironment();
            //2. 读取数据
            DataSource<String> dataSource = env.readTextFile("D:\\Code\\JavaProject\\20240522java\\BigData0522\\Flink\\input\\word.txt");
            //3. 对数据转换处理
            FlatMapOperator<String, Tuple2<String, Long>> flatMapDS = dataSource.flatMap(
                    new FlatMapFunction<String, Tuple2<String, Long>>() {
                        @Override
                        public void flatMap(String s, Collector<Tuple2<String, Long>> collector) {
                            Arrays.stream(s.split(" ")).forEach(word -> collector.collect(Tuple2.of(word, 1L)));
                        }
                    }
            );
            //groupBy(int)    如果当前数据类型是Tuple，指定使用Tuple中的第几个元素作为分组的key
            //groupBy(String) 如果当前数据类型是POJO(简单理解为JavaBean)，指定使用POJO中的哪个属性作为分组的key
            UnsortedGrouping<Tuple2<String, Long>> groupByDS = flatMapDS.groupBy(0);
            AggregateOperator<Tuple2<String, Long>> sum = groupByDS.sum(1);
            sum.print();
        }
    }
## 3.有界流与无界流
    /*
    * 有界流处理 / 无界流处理 - DataStream
    * 1. 准备执行环境
    * 2. 读取数据(source)
    * 3. 对数据转换处理(transformation)
    * 4. 输出结果(sink)
    * 5. 启动执行
    * */
    public class Flink02_StreamWordCount {
        public static void main(String[] args) throws Exception {
            StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
            boundedStream(env);
            ParameterTool parameterTool = ParameterTool.fromArgs(args);
            String host = parameterTool.get("host");
            int port = parameterTool.getInt("port");
            unboundedStream(env, host, port);
            env.execute();
        }
        private static void boundedStream(StreamExecutionEnvironment env) {
            //有界数据流
            DataStreamSource<String> streamSource = env.readTextFile("D:\\Code\\JavaProject\\20240522java\\BigData0522\\Flink\\input\\word.txt");
            SingleOutputStreamOperator<Tuple2<String, Long>> flatMapDS = streamSource.flatMap(
                    new FlatMapFunction<String, Tuple2<String, Long>>() {
                        @Override
                        public void flatMap(String s, Collector<Tuple2<String, Long>> collector) {
                            Arrays.stream(s.split(" ")).forEach(word -> collector.collect(Tuple2.of(word, 1L)));
                        }
                    }
            );
            KeyedStream<Tuple2<String, Long>, Object> keyByDS = flatMapDS.keyBy(o -> o.f0);
            SingleOutputStreamOperator<Tuple2<String, Long>> sum = keyByDS.sum(1);
            sum.print();
        }
        private static void unboundedStream(StreamExecutionEnvironment env, String host, int port) {
            //无界数据流
            DataStreamSource<String> unboundedStreamSource = env.socketTextStream(host, port);
            unboundedStreamSource
                    .flatMap(
                            new FlatMapFunction<String, Tuple2<String, Long>>() {
                                @Override
                                public void flatMap(String s, Collector<Tuple2<String, Long>> collector) {
                                    Arrays.stream(s.split(" ")).forEach(word -> collector.collect(Tuple2.of(word, 1L)));
                                }
                            }
                    )
                    .keyBy(o -> o.f0)
                    .sum(1)
                    .print();
        }
    }
## 4.流批一体
    public class Flink03_BatchAndStreamWordCount {
        public static void main(String[] args) throws Exception {
            StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
            env.setParallelism(1);
            env.setRuntimeMode(RuntimeExecutionMode.AUTOMATIC);
            //有界流
            DataStreamSource<String> streamSource = env.readTextFile("D:\\Code\\JavaProject\\20240522java\\BigData0522\\Flink\\input\\word.txt");
            //无界流
            //DataStreamSource<String> streamSource = env.socketTextStream("localhost", 9999);
            streamSource.
                    flatMap(
                            new FlatMapFunction<String, Tuple2<String, Long>>() {
                                @Override
                                public void flatMap(String line, Collector<Tuple2<String, Long>> collector) {
                                    Arrays.stream(line.split(" ")).forEach(word -> collector.collect(Tuple2.of(word, 1L)));
                                }
                            }
                    )
                    .keyBy(o -> o.f0)
                    .sum(1)
                    .print();
            env.execute();
        }
    }
## 5.POJO对象
    public class Flink04_POJOWordCount {
        public static void main(String[] args) throws Exception {
            StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
            DataStreamSource<String> streamSource = env.socketTextStream("localhost", 9999);
            streamSource
                    .flatMap((String line, Collector<WordCount> collector) -> Arrays.stream(line.split(" ")).forEach(word -> collector.collect(new WordCount(word, 1L))))
                    .returns(Types.POJO(WordCount.class))
                    .keyBy(WordCount::getWord)
                    .sum("count")
                    .print();
            env.execute();
        }
        // Flink对POJO要求
        // 1. 类必须是public
        // 2. 类中必须提供无参构造器
        // 3. 类中的属性必须能被访问
        //	3.1 属性直接使用public修饰
        //	3.2 属性使用private修饰，但要提供public修饰的get/set方法
        // 4. 类中属性必须可序列化
        @Data
        @AllArgsConstructor
        @NoArgsConstructor
        public static class WordCount {
            private String word;
            private Long count;
            @Override
            public String toString() {
                return word + " : " + count;
            }
        }
    }
## 6.WebUI
    public class Flink05_WebUIWordCount {
        public static void main(String[] args) throws Exception {
            //创建配置对象
            Configuration configuration = new Configuration();
            //指定webui的地址和端口
            configuration.setString("rest.address", "127.0.0.1");
            configuration.setInteger("rest.port", 8008);
            StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment(configuration);
            DataStreamSource<String> streamSource = env.socketTextStream("localhost", 9999);
            streamSource
                    .flatMap((String line, Collector<WordCount> collector) -> Arrays.stream(line.split(" ")).forEach(word -> collector.collect(new WordCount(word, 1L))))
                    .returns(Types.POJO(WordCount.class))
                    .keyBy(WordCount::getWord)
                    .sum("count")
                    .print();
            env.execute();
        }
    }
# 3.Flink部署
## 1.集群角色
    客户端: 代码由客户端获取并转换，之后提交给JobManager
    JobManager: 对作业进行中央调度管理，获取到要执行的作业后，会进一步处理转换，之后分发给TaskManager
    TaskManager: 进行数据处理操作
## 2.Flink集群搭建
    1. 下载解压
    2. 修改配置文件
        1. vim /conf/flink-conf.yaml
            # JobManager节点地址
            jobmanager.rpc.address: hadoop102
            jobmanager.bind-host: 0.0.0.0
            # TaskManager节点地址
            taskmanager.bind-host: 0.0.0.0
            taskmanager.host: hadoop102
            # Rest & web frontend
            rest.address: hadoop102
            rest.bind-address: 0.0.0.0
        2. vim /conf/workers
            hadoop102
            hadoop103
            hadoop104
        3. vim /conf/masters
            hadoop102:8081
        4. 另外，在flink-conf.yaml文件中还可以对集群中的JobManager和TaskManager组件进行优化配置，主要配置项如下:
            # 对JobManager进程可使用到的全部内存进行配置，包括JVM元空间和其他开销，默认为1600M，可以根据集群规模进行适当调整
            jobmanager.memory.process.size
            # 对TaskManager进程可使用到的全部内存进行配置，包括JVM元空间和其他开销，默认为1728M，可以根据集群规模进行适当调整
            taskmanager.memory.process.size
            # 对每个TaskManager能够分配的Slot数量进行配置，默认为1，可根据TaskManager所在的机器能够提供给Flink的CPU数量决定。Slot就是TaskManager中具体运行一个任务所分配的计算资源
            taskmanager.numberOfTaskSlots
            # Flink任务执行的并行度，默认为1。优先级低于代码中进行的并行度配置和任务提交时使用参数指定的并行度数量
            parallelism.default
    3. 分发安装目录，修改其他服务器 flink-conf.yaml 中 taskmanager.host 为本机
    4. 启动Flink集群
        start-cluster.sh
    5. 访问WebUI
        启动成功后，可以访问 http://hadoop102:8081 对flink集群和任务进行监控管理
## 3.向集群提交作业
    1. pol.xml文件中添加打包插件的配置
        <build>
            <plugins>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-shade-plugin</artifactId>
                    <version>3.2.4</version>
                    <executions>
                        <execution>
                            <phase>package</phase>
                            <goals>
                                <goal>shade</goal>
                            </goals>
                            <configuration>
                                <artifactSet>
                                    <excludes>
                                        <exclude>com.google.code.findbugs:jsr305</exclude>
                                        <exclude>org.slf4j:*</exclude>
                                        <exclude>log4j:*</exclude>
                                    </excludes>
                                </artifactSet>
                                <filters>
                                    <filter>
                                        <!-- Do not copy the signatures in the META-INF folder.
                                        Otherwise, this might cause SecurityExceptions when using the JAR. -->
                                        <artifact>*:*</artifact>
                                        <excludes>
                                            <exclude>META-INF/*.SF</exclude>
                                            <exclude>META-INF/*.DSA</exclude>
                                            <exclude>META-INF/*.RSA</exclude>
                                        </excludes>
                                    </filter>
                                </filters>
                                <transformers combine.children="append">
                                    <transformer
                                            implementation="org.apache.maven.plugins.shade.resource.ServicesResourceTransformer">
                                    </transformer>
                                </transformers>
                            </configuration>
                        </execution>
                    </executions>
                </plugin>
            </plugins>
        </build>
    2. 可在Web中提交作业，或使用命令行提交作业
        flink run -m hadoop102:8081 -c com.atguigu.flink.wordcount.Flink02_StreamWordCount ./FlinkTutorial-1.0-SNAPSHOT.jar
## 4.部署模式
    1. 会话模式(Session Mode)
        先启动一个集群，保持会话，在会话中通过客户端提交作业
        集群启动时所有资源都已确定，所以所有提交的作业都会竞争集群中的资源
        会话模式适合于单个规模小、执行时间短的大量作业
    2. 单作业模式(Per-Job Mode)
        为每个作业启动一个集群，作业完成后，集群就会关闭
        Flink本身无法以单作业模式运行，需要借助一些资源管理框架来启动集群
    3. 应用模式(Application Mode)
        前两个模式，应用代码都是在客户端上执行，再由客户端提交给JobManager。这种方式客户端需要占用大量网络带宽，加重客户端所在节点的资源消耗
        因此，直接将应用提交到JobManager上运行。为每一个提交的应用单独启动一个JobManager，也就是创建一个集群。该JobManager只为执行这一个应用而存在，执行结束后JobManager也就关闭
        应用模式和单作业模式都是提交作业后才创建群组。但单作业模式通过客户端提交，客户端解析出的每一个作业对应一个集群，而应用模式下，直接由JobManager执行应用程序
## 5.Standalone运行模式
    1. 会话模式部署
        1. 启动Flink集群
            start-cluster.sh
        2. 提交作业
            flink run -m hadoop102:8081 -c com.atguigu.flink.wordcount.Flink02_StreamWordCount ./FlinkTutorial-1.0-SNAPSHOT.jar
    2. 单作业模式部署
        Flink的Standalone集群并不支持单作业模式部署。因为单作业模式需要借助一些资源管理平台
    3. 应用模式部署
        1. 提前将应用程序的jar包放到lib目录下
        2. 启动JobManager
            standalone-job.sh start --job-classname com.atguigu.flink.wordcount.Flink02_StreamWordCount
            直接指定作业入口类，脚本会到lib目录扫描所有的jar包
        3. 启动TaskManager
            taskmanager.sh start
        4. 关闭集群
            taskmanager.sh stop
            standalone-job.sh stop
## 6.Yarn运行模式
    Yarn上部署的过程:
        客户端把Flink应用提交给Yarn的ResourceManager
        Yarn的ResourceManager会向Yarn的NodeManager申请容器
        在这些容器上，Flink会部署JobManager和TaskManager的实例，从而启动集群
        Flink会根据运行在JobManger上的作业所需要的Slot数量动态分配TaskManager资源
### 1.相关配置
    1. 配置服务器环境变量
        HADOOP_HOME=/opt/module/hadoop-3.1.3
        export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
        export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
        export HADOOP_CLASSPATH=`hadoop classpath`
    2. 启动Hadoop集群
### 2.会话模式部署
    1. 开启一个Yarn会话，启动Flink集群
        yarn-session.sh -nm test
        可用参数解读:
        -d: 分离模式，如果你不想让Flink Yarn客户端一直前台运行，可以使用这个参数，即使关掉当前对话窗口，Yarn session也可以后台运行
        -jm(--jobManagerMemory): 配置JobManager所需内存，默认单位MB
        -nm(--name): 配置在Yarn UI界面上显示的任务名
        -qu(--queue): 指定Yarn队列名
        -tm(--taskManager): 配置每个TaskManager所使用内存
        注意: Flink1.11.0版本不再使用-n参数和-s参数分别指定TaskManager数量和slot数量，YARN会按照需求动态分配TaskManager和slot。所以从这个意义上讲，YARN的会话模式也不会把集群资源固定，同样是动态分配的
        Yarn Session启动之后会给出一个WebUI地址以及一个Yarn application ID
    2. 通过Web或命令行提交作业
        flink run -c com.atguigu.flink.wordcount.Flink02_StreamWordCount FlinkTutorial-1.0-SNAPSHOT.jar
        客户端可以自行确定JobManager的地址，也可以通过-m或者-jobmanager参数指定JobManager的地址，JobManager的地址在Yarn Session的启动页面中可以找到
### 3.单作业模式部署
    1. 命令行提交作业
        flink run -d -t yarn-per-job -c com.atguigu.flink.wordcount.Flink02_StreamWordCount FlinkTutorial-1.0-SNAPSHOT.jar
    2. 命令行查看或取消作业
        flink list -t yarn-per-job -Dyarn.application.id=application_XXXX_YY
        flink cancel -t yarn-per-job -Dyarn.application.id=application_XXXX_YY <jobId>
        如果取消作业，整个Flink集群也会停掉
### 4.应用模式部署
    1. 命令行提交作业
        flink run-application -t yarn-application -c com.atguigu.flink.wordcount.Flink02_StreamWordCount FlinkTutorial-1.0-SNAPSHOT.jar
    2. 命令行查看或取消作业
        flink list -t yarn-application -Dyarn.application.id=application_XXXX_YY
        flink cancel -t yarn-application -Dyarn.application.id=application_XXXX_YY <jobId>
    3. 也可以通过yarn.provided.lib.dirs配置选项指定位置，将Flink运行所依赖的jar环境上传到远程
            1. 在HDFS上创建目录
                hadoop fs -mkdir /flink-jar
            2. 将Flink安装目录下的 lib 和 plugins 目录及内容上传到HDFS
                hadoop fs -put ./lib/ /flink-jar
                hadoop fs -put ./plugins/ /flink-jar
            3. 提交作业
                flink run-application -t yarn-application -c com.atguigu.flink.wordcount.Flink02_StreamWordCount -Dyarn.provided.lib.dirs="hdfs://hadoop102:8020/flink-jar" FlinkTutorial-1.0-SNAPSHOT.jar
            这种方式下jar可以预先上传到HDFS，而不需要单独发送到集群，这就使得作业提交更加轻量了
### 5.历史服务器
    1. 创建存储目录
        hadoop fs -mkdir -p /flink-logs
    2. 在 flink-config.yaml 中添加如下配置
        jobmanager.archive.fs.dir: hdfs://hadoop102:8020/flink-logs
        historyserver.web.address: hadoop102
        historyserver.web.port: 8082
        historyserver.archive.fs.dir: hdfs://hadoop102:8020/flink-logs
        historyserver.archive.fs.refresh-interval: 5000
    3. 启动历史服务器
        historyserver.sh start
    4. 停止历史服务器
        historyserver.sh  stop
    5. 在浏览器地址栏输入 http://hadoop102:8082 查看已经停止的job的信息
# 4.Flink运行时架构
## 1.系统架构
    1. 作业管理器(JobManager)
        JobManager是一个Flink集群中任务管理和调度的核心，是控制应用执行的主进程。也就是说，每个应用都应该被唯一的JobManager所控制执行
        JobManger又包含3个不同的组件
        1. JobMaster
            JobMaster是JobManager中最核心的组件，负责处理单独的作业(Job)
            JobMaster和具体的Job是一一对应的，多个Job可以同时运行在一个Flink集群中, 每个Job都有一个自己的JobMaster
            需要注意在早期版本的Flink中，没有JobMaster的概念；而JobManager的概念范围较小，实际指的就是现在所说的JobMaster
            在作业提交时，JobMaster会先接收到要执行的应用。JobMaster会把JobGraph转换成一个物理层面的数据流图，这个图被叫作“执行图”(ExecutionGraph)，它包含了所有可以并发执行的任务。JobMaster会向资源管理器(ResourceManager)发出请求，申请执行任务必要的资源。一旦它获取到了足够的资源，就会将执行图分发到真正运行它们的TaskManager上
            而在运行过程中，JobMaster会负责所有需要中央协调的操作，比如说检查点(checkpoints)的协调
        2. 资源管理器(ResourceManager)
            ResourceManager主要负责资源的分配和管理，在Flink集群中只有一个
            所谓"资源"，主要是指TaskManager的任务槽(task slots)。任务槽就是Flink集群中的资源调配单元，包含了机器用来执行计算的一组CPU和内存资源。每一个任务(Task)都需要分配到一个slot上执行
            这里注意要把Flink内置的ResourceManager和其他资源管理平台(比如Yarn)的ResourceManager区分开
        3. 分发器(Dispatcher)
            Dispatcher主要负责提供一个REST接口，用来提交应用，并且负责为每一个新提交的作业启动一个新的JobMaster组件
            Dispatcher也会启动一个WebUI，用来方便地展示和监控作业执行的信息。Dispatcher在架构中并不是必需的，在不同的部署模式下可能会被忽略掉
    2. 任务管理器(TaskManager)
        TaskManager是Flink中的工作进程，数据流的具体计算就是它来做的,Flink集群中必须至少有一个TaskManager
        每一个TaskManager都包含了一定数量的任务槽(task slots)。slot是资源调度的最小单位，slot的数量限制了TaskManager能够并行处理的任务数量
        启动之后，TaskManager会向资源管理器注册它的slots；收到资源管理器的指令后，TaskManager就会将一个或者多个槽位提供给JobMaster调用，JobMaster就可以分配任务来执行了
        在执行过程中，TaskManager可以缓冲数据，还可以跟其他运行同一应用的TaskManager交换数据
## 2.核心概念
### 1.并行度(Parallelism)
    算子并行度: 每个算子执行时并行的task个数
    作业并行度: 当前作业中所有算子中最大的并行度
    设置并行度:
    1. idea中，若不明确指定并行度，使用当前处理器个数作为并行度
    2. env.setParallelism(n)
    3. 算子().setParallelism(n)
    4. 集群配置文件中 parallelism.default: 1 来指定集群默认并行度
    5. 提交作业时指定并行度 bin/flink run -p n ...
### 2.算子链(Operator Chain)
#### 1.Flink的数据分发规则(分区规则):
    ChannelSelector
        StreamPartitioner
            KeyGroupStreamPartitioner : keyBy()
                按照指定的key求hash值，对下游算子并行度取余，决定数据发往哪个并行实例
            RebalancePartitioner : rebalance()
                轮询发往下一个并行实例
                若上下游并行度不一样，且未指定数据分发规则，默认为rebalance()
            RescalePartitioner : rescale()
                按轮询，将数据均衡的发往组内的下游的并行实例
                0->0
                0->1
                ----
                1->2
                1->3
            ShufflePartitioner : shuffle()
                随机
            BroadcastPartitioner : broadcast()
                广播
            GlobalPartitioner : global()
                强制并行度为1
            ForwardPartitioner : forward()
                直连，上游与下游并行度保持一致
                若上下游并行度一样，且未指定数据分发规则，默认为forward()
#### 2.算子链:
    将上下游算子的并行实例合并在一起，形成一个算子链
    合并算子链的条件:
        1. 上下游算子的并行度一致
        2. 数据分发规则必须为forward()
    合并算子链的好处: 减少线程间切换、缓冲的开销，并在减少延迟的同时增加整体吞吐量
    禁用算子链:
        1. 全局禁用算子链合并: env.disableOperatorChaining()
        2. 从当前算子开始开启新链(和下游算子链合并): startNewChain()
        3. 禁用当前算子链合并(不和上下游算子合并): disableChaining()
### 3.任务槽(Task Slots)
    1. 什么是任务槽
        Flink中每一个TaskManager都是一个JVM进程，它可以启动多个独立的线程，来并行执行多个子任务(subtask)，在TaskManager上对每个任务运行所占用的资源做出明确的划分，这就是所谓的任务槽(task slots)，每个任务槽(task slot)其实表示了TaskManager拥有计算资源的一个固定大小的子集。这些资源就是用来独立执行一个子任务的
    2. slot共享: Flink允许同一个作业中，上下游算子的并行实例共享同一个slot
    3. 为什么要slot共享:
        1. 一个slot可以持有整个作业管道，即使某个TaskManager出现故障宕机，其他节点也可以完全不受影响，作业的任务可以继续执行
        2. Flink集群所需的taskslot和作业中使用的最大并行度恰好一样，无需计算程序总共包含多少个task
        3. 更好的资源利用。如果没有slot共享，非密集subtask(source/map())将阻塞和密集型subtask(window)一样多的资源
        4. 确保繁重的subtask在TaskManager之间公平分配
    4. 任务槽数量的设置
        在Flink的 conf/flink-conf.yaml 配置文件中，可以设置TaskManager的slot数量，默认是1个slot
            taskmanager.numberOfTaskSlots: 8
        注意: slot目前仅仅用来隔离内存，不会涉及CPU的隔离。在具体应用时，可以将slot数量配置为机器的CPU核心数，尽量避免不同任务之间对CPU的竞争。这也是开发环境默认并行度设为机器CPU数量的原因
    5. 可通过设置共享组来不共享slot
        slotSharingGroup("group1")
        从source算子开始，默认将算子放到默认的default共享组；后续的算子如果不明确指定共享组，默认从上游算子继承共享组
## 3.作业提交流程
### 1.Standalone会话模式作业提交流程
    1. 提交job到客户端，脚本启动执行
    2. 客户端解析参数，生成逻辑流图、作业流图，封装提交参数，提交/取消/更新任务到JobManager
    3. 分发器启动JobMaster并提交应用，JobMaster形成执行图
    4. JobMaster向资源管理器请求slots，资源管理器向TaskManager请求slots，TaskManager为JobMaster提供slots
    5. JobMaster向TaskManager分发任务，TaskManager根据物理图对传递来的数据进行处理计算。TaskManager相互之间存在数据流
### 2.逻辑流图/作业图/执行图/物理流图
    1. 逻辑流图(StreamGraph)
        这是根据用户通过DataStream API编写的代码生成的最初的DAG图，用来表示程序的拓扑结构，这一步一般在客户端完成
    2. 作业图(JobGraph)
        StreamGraph经过优化后生成的就是作业图(JobGraph)，这是提交给JobManager的数据结构，确定了当前作业中所有任务的划分
        主要的优化为: 将多个符合条件的节点链接在一起合并成一个任务节点，形成算子链，这样可以减少数据交换的消耗
        JobGraph一般也是在客户端生成的，在作业提交时传递给JobMaster
        我们提交作业之后，打开Flink自带的Web UI，点击作业就能看到对应的作业图
    3. 执行图(ExecutionGraph)
        JobMaster收到JobGraph后，会根据它来生成执行图(ExecutionGraph)
        ExecutionGraph是JobGraph的并行化版本，是调度层最核心的数据结构。与JobGraph最大的区别就是按照并行度对并行子任务进行了拆分，并明确了任务间数据传输的方式
    4. 物理流图
        JobMaster生成执行图后，会将它分发给TaskManager；各个TaskManager会根据执行图部署任务，最终的物理执行过程也会形成一张“图”，一般就叫作物理图(Physical Graph)
        这只是具体执行层面的图，并不是一个具体的数据结构
        物理图主要就是在执行图的基础上，进一步确定数据存放的位置和收发的具体方式。有了物理图，TaskManager就可以对传递来的数据进行处理计算了
### 3.Yarn应用模式作业提交流程
    1. Yarn的ResourceManager启动ApplicationMaster
    2. AM启动分发器，分发器启动JobMaster
    3. JobMaster生成逻辑流图、作业流图、执行流图，向资源管理器注册并请求slot
    4. 资源管理器向Yarn的ResourceManager申请资源
    5. Yarn的ResourceManager启动TaskManager，TaskManager向资源管理器注册slot，资源管理器为TaskManager提供slot，TaskManager向JobMaster提供slot
    6. JobMaster向TaskManager分发任务，TaskManager根据物理图对传递来的数据进行处理计算。TaskManager相互之间存在数据流
# 5.DataStream API
## 1.执行环境
    1. 根据上下文创建执行环境
        StreamExecutionEnvironment.getExecutionEnvironment()
        这个方法会根据当前运行的上下文直接得到正确的结果: 如果程序是独立运行的，就返回一个本地执行环境；如果是创建了jar包，然后从命令行调用它并提交到集群执行，那么就返回集群的执行环境。也就是说，这个方法会根据当前运行的方式，自行决定该返回什么样的运行环境
    2. 本地执行环境
        StreamExecutionEnvironment.createLocalEnvironment()
        这个方法返回一个本地执行环境。可以在调用时传入一个参数，指定默认的并行度；如果不传入，则默认并行度就是本地的CPU核心数
    3. 远程执行环境
        StreamExecutionEnvironment.createRemoteEnvironment("hadoop103", 40758, "jar/1.jar")
        这个方法返回集群执行环境。需要在调用时指定JobManager的主机名和端口号，并指定要在集群中运行的Jar包
## 2.执行模式
    流执行模式、批执行模式、自动模式
    1. 流执行模式(Streaming)
        这是DataStream API最经典的模式，一般用于需要持续实时处理的无界数据流。默认情况下，程序使用的就是Streaming执行模式
    2. 批执行模式(Batch)
        专门用于批处理的执行模式
    3. 自动模式(AutoMatic)
        在这种模式下，将由程序根据输入数据源是否有界，来自动选择执行模式
    通过命令行配置
        flink run -Dexecution.runtime-mode=BATCH ...
## 3.源算子
### 1.从集合中读取数据
    1. 方式一
        List<Event> eventList = Arrays.asList(
            new Event("zhangsan", "/home", 1000L),
            new Event("lisi", "/home", 2000L),
            new Event("wangwu", "/home", 3000L),
            new Event("zhangliu", "/home", 4000L)
        );
        env.fromCollection(eventList).print("from collection ");
    2. 方式二
        env.fromElements(
            new Event("zhangsan", "/home", 1000L),
            new Event("lisi", "/home", 2000L),
            new Event("wangwu", "/home", 3000L),
            new Event("zhangliu", "/home", 4000L)
        ).print("from elements ");
### 2.从端口读取数据
    env.socketTextStream("localhost", 9999)
        .print("from socket ");
### 3.从文件读取数据
    1. 方式一
        env.readTextFile("input/word.txt")
            .print("from file ");
    2. 方式二
        添加依赖:
            <dependency>
                <groupId>org.apache.flink</groupId>
                <artifactId>flink-connector-files</artifactId>
                <version>${flink.version}</version>
                <scope>provided</scope>
            </dependency>
        Source类型:
            SourceFunction(旧的) : addSource()
            Source : fromSource()
        FileSource<String> fileSource = FileSource.forRecordStreamFormat(
            new TextLineInputFormat(),
            new Path("D:\\Code\\JavaProject\\20240522java\\BigData0522\\Flink\\input\\word.txt")
        ).build();
        DataStreamSource<String> streamSource = env.fromSource(fileSource, WatermarkStrategy.noWatermarks(), "fileSource");
        streamSource.print();
        env.execute();
### 4.从Kafka读取数据
    添加依赖:
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-kafka</artifactId>
            <version>${flink.version}</version>
            <scope>compile</scope>
        </dependency>
    // 指定某分区从offset开始消费
    HashMap<TopicPartition, Long> offsets = new HashMap<>();
    offsets.put(new TopicPartition("topicA", 0), 28020L);
    KafkaSource<String> kafkaSource = KafkaSource.<String>builder()
        .setBootstrapServers("hadoop102:9092,hadoop103:9092,hadoop104:9092")
        .setGroupId("flink")
        .setTopics("topicA")
        .setValueOnlyDeserializer(new SimpleStringSchema())
        // 基于提交的offset重新消费，若需要重置offset，重置到尾部
        .setStartingOffsets(OffsetsInitializer.committedOffsets(OffsetResetStrategy.LATEST))
        // 指定某分区从offset开始消费
        //.setStartingOffsets(OffsetsInitializer.offsets(offsets))
        // 其他配置使用通用方法
        .setProperty("isolation.level", "read_committed")
        .build();
    DataStreamSource<String> streamSource = env.fromSource(kafkaSource, WatermarkStrategy.noWatermarks(), "kafkaSource");
    streamSource.print();
### 5.从数据生成器读取数据
    添加依赖:
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-datagen</artifactId>
            <version>${flink.version}</version>
        </dependency>
    DataGeneratorSource<String> dataGenSource = new DataGeneratorSource<>(
        new GeneratorFunction<Long, String>() {
            @Override
            public String map(Long aLong) {
                return UUID.randomUUID().toString(); // 生成数据内容
            }
        },
        Integer.MAX_VALUE, // 生成数据量
        RateLimiterStrategy.perSecond(10), // 每秒生成条数
        Types.STRING
    );
    DataStreamSource<String> streamSource = env.fromSource(dataGenSource, WatermarkStrategy.noWatermarks(), "datagen");
    streamSource.print();
### 6.自定义数据源
    public class Flink06_UserDefineSource {
        public static void main(String[] args) throws Exception {
            StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
            env.setParallelism(1);
            DataStreamSource<Event> ds = env.addSource(new EventSource());
            ds.print();
            env.execute();
        }
        public static class EventSource implements SourceFunction<Event> {
            @Override
            public void run(SourceContext<Event> sourceContext) throws InterruptedException {
                String[] users = {"zhangsan", "lisi", "wangwu", "tom", "jerry", "alice"};
                String[] urls = {"/home", "/list", "/cart", "/order", "/pay"};
                while (true) {
                    String user = users[RandomUtils.nextInt(0, users.length)];
                    String url = urls[RandomUtils.nextInt(0, urls.length)];
                    Long timestamp = System.currentTimeMillis();
                    Event event = new Event(user, url, timestamp);
                    sourceContext.collect(event);
                    Thread.sleep(300);
                }
            }
            @Override
            public void cancel() {
            }
        }
    }
## 4.转换算子
### 1.基本转换算子
    map: 映射，将输入的数据经过映射，输出一个数据
    filter: 过滤，将输入的数据经过过滤，满足条件才输出
    flatMap: 扁平映射，将输入的数据经过扁平映射，输出多个数据
### 2.聚合算子(Aggregation)
    1. 按键分区
        要聚合，先keyBu；Flink希望通过keyBy的方式将数据拆分，再通过并行的方式处理数据
        kyeBy()在内部，是通过计算key的哈希值(hash code)，对分区数进行取模运算来实现的。所以这里key如果是POJO的话，必须要重写hashCode()方法
        keyBy()方法需要传入一个参数，这个参数指定了一个或一组key。有很多不同的方法来指定key: 比如对于Tuple数据类型，可以指定字段的位置或者多个位置的组合；对于POJO类型，可以指定字段的名称(String)；另外，还可以传入Lambda表达式或者实现一个键选择器(KeySelector)，用于说明从数据中提取key的逻辑
    2. 简单聚合
        max/min
        maxBy/minBy  # min()只计算指定字段的最小值，其他字段会保留最初第一个数据的值；而minBy()则会返回包含字段最小值的整条数据
        sum
        这些聚合方法调用时，需要传入聚合指定的字段。指定字段的方式有两种: 指定位置，和指定名称。对于元组类型的数据，可以使用这两种方式来指定字段。需要注意的是，元组中字段的名称，是以f0、f1、f2、…来命名的。如果数据流的类型是POJO类，则只能通过字段名称来指定
    3. 归约聚合
        reduce(): 归约算子，两两聚合，每次使用上次归约的结果和本次新到的数据进行归约，第一条数据不进行归约处理
        reduce()方法需传入两个参数，第一个参数为归约结果，第二个参数为本次输入的数据
        env.fromSource(SourceUtil.getDataGeneratorSource(3), WatermarkStrategy.noWatermarks(), "ds")
            .map(o -> new Tuple2<>(o.getUrl(), 1L))
            .returns(Types.TUPLE(Types.STRING, Types.LONG))
            .keyBy(o -> o.f0)
            .reduce((ReduceFunction<Tuple2<String, Long>>) (result, in) -> new Tuple2<>(result.f0, result.f1 + in.f1))
            .print();
### 3.自定义函数(UDF)
    1. 普通函数类: 只定义了函数的具体功能
        MapFunction
        FilterFunction
        FlatMapFunction
        ReduceFunction
        ...
    2. 富函数类:
        RichFunction 富函数接口
            AbstractRichFunction 抽象富函数父类
                RichMapFunction
                RichFilterFunction
                RichFlatMapFunction
                RichReduceFunction
                ...
        富函数类的功能:
            1. 对数据处理的功能
            2. 生命周期方法，算子每一个并行实例的生命周期
                void open(Configuration parameters) throws Exception
                    算子的实例对象在创建的时候会调用一次open方法(在数据处理之前，做一些前置工作)
                void close() throws Exception
                    算子的实例对象在销毁的时候会调用一次close方法(在数据处理之后，做一些后置工作)
            3. 获取运行时上下文对象 RuntimeContext
                1. 获取一些和当前作业相关的信息
                2. 做状态编程
                    getState()
                    getListState()
                    getReduceState()
                    getAggregatingState()
                    getMapState()
### 4.物理分区算子(Physical Partitioning)
| 参数 | 描述 |
| --- | --- |
| keyBy() | 按照指定的key求hash值，对下游算子并行度取余，决定数据发往哪个并行实例
| rebalance() | 轮询发往下一个并行实例<br>若上下游并行度不一样，且未指定数据分发规则，默认为rebalance()
| rescale() | 按轮询，将数据均衡的发往组内的下游的并行实例<br>0->0<br>0->1<br>----<br>1->2<br>1->3
| shuffle() | 随机
| broadcast() | 广播
| global() | 强制并行度为1
| forward() | 直连，上游与下游并行度保持一致<br>若上下游并行度一样，且未指定数据分发规则，默认为forward()
    自定义分区:
        ds.partitionCustom(
            new Partitioner<String>() {
                @Override
                public int partition(String s, int i) {
                    return Math.abs(s.hashCode() % 5);
                }
            },
            Event::getUser
        ).print();
### 5.分流
    1. 简单实现: 通过filter算子，从原始流中将满足条件的数据挑选出来放到新流中
        ds.filter(o -> "zhangsan".equals(o.getUser()))
            .print("zhangsan => ");
        ds.filter(o -> "lisi".equals(o.getUser()))
            .print("lisi => ");
        ds.filter(o -> !"zhangsan".equals(o.getUser()) && !"lisi".equals(o.getUser()))
            .print("other => ");
    2. 使用侧输出流:
        OutputTag<Event> zhangsanTag = new OutputTag<>("zhangsan->", Types.POJO(Event.class));
        OutputTag<Event> lisiTag = new OutputTag<>("lisi->", Types.POJO(Event.class));
        DataStreamSource<Event> ds = env.fromSource(SourceUtil.getDataGeneratorSource(3), WatermarkStrategy.noWatermarks(), "ds");
        SingleOutputStreamOperator<Event> mainDS = ds.process(
            new ProcessFunction<Event, Event>() {
                @Override
                public void processElement(Event event, ProcessFunction<Event, Event>.Context context, Collector<Event> out) throws Exception {
                    if ("zhangsan".equals(event.getUser()))
                        context.output(zhangsanTag, event);
                    else if ("lisi".equals(event.getUser()))
                        context.output(lisiTag, event);
                    else
                        out.collect(event);
                }
            }
        );
        mainDS.print("main ");
        mainDS.getSideOutput(zhangsanTag).print("zhangsan ");
        mainDS.getSideOutput(lisiTag).print("lisi ");
### 6.合流
    1. union合流: 合并多条流，要求被合并的流中数据类型一致
        OutputTag<Event> zhangsanTag = new OutputTag<>("zhangsan->", Types.POJO(Event.class));
        OutputTag<Event> lisiTag = new OutputTag<>("lisi->", Types.POJO(Event.class));
        DataStreamSource<Event> ds = env.fromSource(SourceUtil.getDataGeneratorSource(3), WatermarkStrategy.noWatermarks(), "ds");
        SingleOutputStreamOperator<Event> mainDS = ds.process(
            new ProcessFunction<Event, Event>() {
                @Override
                public void processElement(Event event, ProcessFunction<Event, Event>.Context context, Collector<Event> out) throws Exception {
                    if ("zhangsan".equals(event.getUser()))
                        context.output(zhangsanTag, event);
                    else if ("lisi".equals(event.getUser()))
                        context.output(lisiTag, event);
                    else
                        out.collect(event);
                }
            }
        );
        SideOutputDataStream<Event> zhangsanStream = mainDS.getSideOutput(zhangsanTag);
        SideOutputDataStream<Event> lisiStream = mainDS.getSideOutput(lisiTag);
        DataStream<Event> unionDS = mainDS.union(zhangsanStream, lisiStream);
        unionDS.print();
    2. connect合流: 将不同数据类型的两条流合并
        1. CoMapFunction()
            DataStreamSource<Event> ds = env.fromSource(SourceUtil.getDataGeneratorSource(3), WatermarkStrategy.noWatermarks(), "ds");
            DataStreamSource<Integer> intStream = env.fromElements(1, 2, 3, 4, 5);
            ConnectedStreams<Event, Integer> connectStream = ds.connect(intStream);
            SingleOutputStreamOperator<String> connectDS = connectStream.map(
                new CoMapFunction<Event, Integer, String>() {
                    @Override
                    public String map1(Event event) {
                        return event.getTimestamp().toString();
                    }
                    @Override
                    public String map2(Integer integer) {
                        return integer.toString();
                    }
                }
            );
            connectDS.print();
        2. keyBy()
            ConnectedStreams也可以直接调用.keyBy()进行按键分区的操作，得到的还是一个ConnectedStreams：
                connectedStreams.keyBy(keySelector1, keySelector2);
            这里传入两个参数keySelector1和keySelector2，是两条流中各自的键选择器；当然也可以直接传入键的位置值(keyPosition)，或者键的字段名(field)，这与普通的keyBy用法完全一致。ConnectedStreams进行keyBy操作，其实就是把两条流中key相同的数据放到了一起，然后针对来源的流再做各自处理，这在一些场景下非常有用
        3. CoProcessFunction()
            CoProcessFunction()需要实现processElement1()、processElement2()两个方法，在每个数据到来时，会根据来源的流调用其中的一个方法进行处理
            CoProcessFunction同样可以通过上下文ctx来访问timestamp、水位线，并通过TimerService注册定时器；另外也提供了.onTimer()方法，用于定义定时触发的处理操作
            SingleOutputStreamOperator<String> connectDS = connectStream.process(
                new CoProcessFunction<Event, Integer, String>() {
                    @Override
                    public void processElement1(Event o, CoProcessFunction.Context context, Collector collector) throws Exception {
                        collector.collect(o.toString());
                    }
                    @Override
                    public void processElement2(Integer o, CoProcessFunction.Context context, Collector collector) throws Exception {
                        collector.collect(o.toString());
                    }
                }
            );
## 5.输出算子
### 1.输出到文件
    FileSink支持行编码(Row-encoded)和批量编码(Bulk-encoded)格式。这两种不同的方式都有各自的构建器(builder)，可以直接调用FileSink的静态方法:
        行编码: FileSink.forRowFormat(basePath，rowEncoder)
        批量编码: FileSink.forBulkFormat(basePath，bulkWriterFactory)
    // 开启检查点
    env.enableCheckpointing(5000L);
    DataStreamSource<Event> ds = env.fromSource(SourceUtil.getDataGeneratorSource(30), WatermarkStrategy.noWatermarks(), "ds");
    SingleOutputStreamOperator<String> stringDS = ds.map(Objects::toString);
    FileSink<String> fileSink = FileSink.<String>forRowFormat(
            new Path("D:\\Code\\JavaProject\\20240522java\\BigData0522\\Flink\\output"),
            new SimpleStringEncoder<>()
        )
        .withRollingPolicy(
                DefaultRollingPolicy.builder()
                        .withMaxPartSize(MemorySize.parse("3m")) //文件多大滚动
                        .withRolloverInterval(Duration.ofSeconds(10L)) // 滚动间隔
                        .withInactivityInterval(Duration.ofSeconds(5L)) // 文件非活跃滚动间隔
                        .build()
        ) // 文件滚动策略
        .withBucketAssigner(
                new DateTimeBucketAssigner<>("yyyy-MM-dd hh-mm")
        ) // 目录滚动策略
        .withOutputFileConfig(
                OutputFileConfig.builder()
                        .withPartPrefix("event") // 文件名前缀
                        .withPartSuffix(".log") // 文件名后缀
                        .build()
        ) // 文件名策略
        .withBucketCheckInterval(1000L) // 检查间隔
        .build();
    stringDS.sinkTo(fileSink);
### 2.输出到Kafka
    1. 使用KafkaSink,DeliveryGuarantee.EXACTLY_ONCE 一致性级别 注意事项:
        1. The transaction timeout is larger than the maximum value allowed by the broker (as configured by transaction.max.timeout.ms)
            Kafka Broker 级别的超时时间:
                transaction.max.timeout.ms: 900000(15 minutes)
            Kafka Producer 级别的超时时间:
                transaction.timeout.ms: 60000(1 minutes)
            Flink KafkaSink 默认的事务超时时间:
                DEFAULT_KAFKA_TRANSACTION_TIMEOUT(transaction.timeout.ms) = Duration.ofHours(1); // 1 hour
        2. 设置事务id前缀
    2. 只有value写入
        // 开启检查点
        env.enableCheckpointing(2000L);
        DataStreamSource<Event> ds = env.fromSource(SourceUtil.getDataGeneratorSource(1), WatermarkStrategy.noWatermarks(), "ds");
        KafkaSink<Event> kafkaSink = KafkaSink.<Event>builder()
            .setBootstrapServers("hadoop102:9092,hadoop103:9092,hadoop104:9092")
            .setRecordSerializer(
                KafkaRecordSerializationSchema.<Event>builder()
                    .setTopic("topicA")
                    .setValueSerializationSchema(
                        new SerializationSchema<Event>() {
                            @Override
                            public byte[] serialize(Event event) {
                                return event.toString().getBytes();
                            }
                        }
                    )
                    .build()
            )
            .setDeliveryGuarantee(DeliveryGuarantee.EXACTLY_ONCE) // 设置精准一次
            .setProperty("transaction.timeout.ms", "600000") // 设置Producer事务超时时间
            .setTransactionalIdPrefix("flink-" + System.currentTimeMillis()) // 设置事务id前缀
            .build();
        ds.sinkTo(kafkaSink);
    3. 带key写入
        DataStreamSource<Event> ds = env.fromSource(SourceUtil.getDataGeneratorSource(1), WatermarkStrategy.noWatermarks(), "ds");
        KafkaSink<Event> kafkaSink = KafkaSink.<Event>builder()
            .setBootstrapServers("hadoop102:9092,hadoop103:9092,hadoop104:9092")
            .setRecordSerializer(
                new KafkaRecordSerializationSchema<Event>() {
                    @Nullable
                    @Override
                    public ProducerRecord<byte[], byte[]> serialize(Event event, KafkaSinkContext kafkaSinkContext, Long aLong) {
                        String key = event.getUser();
                        String value = JSON.toJSONString(event);
                        return new ProducerRecord<>("topicA", key.getBytes(), value.getBytes());
                    }
                }
            )
            .build();
        ds.sinkTo(kafkaSink);
### 3.输出到MySQL
    JDBCConnector: 支持将数据写入外部数据库
    添加依赖:
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-jdbc</artifactId>
            <version>3.1.0-1.17</version>
            <scope>compile</scope>
        </dependency>
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <version>8.0.32</version>
            <scope>compile</scope>
        </dependency>
    // 开启检查点
    env.enableCheckpointing(2000L);
    DataStreamSource<Event> ds = env.fromSource(SourceUtil.getDataGeneratorSource(2), WatermarkStrategy.noWatermarks(), "ds");
    SinkFunction<Event> jdbcSink = JdbcSink.sink(
        "insert into event_table1 (user,url,ts) values(?,?,?)",
        //"replace into event_table1 (user,url,ts) values(?,?,?)", // 覆盖该条数据
        //"insert into event_table1 (user,url,ts) values(?,?,?) on duplicate key update url=values(url)", // 覆盖该条数据指定字段
        new JdbcStatementBuilder<Event>() {
            @Override
            public void accept(PreparedStatement preparedStatement, Event event) throws SQLException {
                // 给sql中的占位符赋值
                preparedStatement.setString(1, event.getUser());
                preparedStatement.setString(2, event.getUrl());
                preparedStatement.setLong(3, event.getTimestamp());
            }
        },
        // 按批写入
        JdbcExecutionOptions.builder()
            .withBatchSize(5)
            .withBatchIntervalMs(5000L)
            .withMaxRetries(3)
            .build(),
        new JdbcConnectionOptions.JdbcConnectionOptionsBuilder()
            .withDriverName("com.mysql.cj.jdbc.Driver")
            .withUrl("jdbc:mysql://localhost:3306/db1")
            .withUsername("root")
            .withPassword("123321")
            .build()
    );
    ds.addSink(jdbcSink);
### 4.自定义Sink输出
    public class Flink05_UserDefineSink {
        public static void main(String[] args) throws Exception {
            StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
            env.setParallelism(1);
            DataStreamSource<Event> ds = env.fromSource(SourceUtil.getDataGeneratorSource(3), WatermarkStrategy.noWatermarks(), "ds");
            ds.addSink(new MySink());
            env.execute();
        }
        public static class MySink implements SinkFunction<Event> {
            @Override
            public void invoke(Event value, Context context) {
                System.out.println(value);
            }
        }
    }