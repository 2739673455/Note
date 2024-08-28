# 1.Spark概述
## 1.Spark简介
    Spark是一种基于内存的快速、通用、可扩展的大数据分析计算引擎
## 2.Spark内置模块
| 参数 | 描述 |
| --- | --- |
| Spark Core | 实现了Spark的基本功能，包含任务调度、内存管理、错误恢复、与存储系统交互等模块<br>Spark Core中还包含了对弹性分布式数据集(Resilient Distributed DataSet，简称RDD)的API定义
| Spark SQL | 是Spark用来操作结构化数据的程序包。通过Spark SQL，我们可以使用 SQL或者Apache Hive版本的HQL来查询数据<br>Spark SQL支持多种数据源，比如Hive表、Parquet以及JSON等
| Spark Streaming | 是Spark提供的对实时数据进行流式计算的组件。提供了用来操作数据流的API，并且与Spark Core中的 RDD API高度对应
| Spark MLlib | 提供常见的机器学习功能的程序库。包括分类、回归、聚类、协同过滤等，还提供了模型评估、数据导入等额外的支持功能
| Spark GraphX | 主要用于图形并行计算和图挖掘系统的组件
| 集群管理器 | Spark设计为可以高效地在一个计算节点到数千个计算节点之间伸缩计算<br>为了实现这样的要求，同时获得最大灵活性，Spark支持在各种集群管理器(Cluster Manager)上运行<br>包括Hadoop YARN、Apache Mesos，以及Spark自带的一个简易调度器，叫作独立调度器
## 3.Spark特点
    1. 快:
        与Hadoop的MapReduce相比，Spark基于内存的运算要快100倍以上，基于硬盘的运算也要快10倍以上
        Spark实现了高效的DAG执行引擎，可以通过基于内存来高效处理数据流。计算的中间结果是存在于内存中的
    2. 易用:
        Spark支持Java、Python和Scala的API，还支持超过80种高级算法，使用户可以快速构建不同的应用
        而且Spark支持交互式的Python和Scala的Shell，可以非常方便地在这些Shell中使用Spark集群来验证解决问题的方法
    3. 通用:
        Spark提供了统一的解决方案。Spark可以用于，交互式查询(Spark SQL)、实时流处理(Spark Streaming)、机器学习(Spark MLlib)和图计算(GraphX)
        这些不同类型的处理都可以在同一个应用中无缝使用。减少了开发和维护的人力成本和部署平台的物力成本
    4. 兼容性:
        Spark可以非常方便地与其他的开源产品进行融合
        比如，Spark可以使用Hadoop的YARN和Apache Mesos作为它的资源管理和调度器，并且可以处理所有Hadoop支持的数据，包括HDFS、HBase等
        这对于已经部署Hadoop集群的用户特别重要，因为不需要做任何数据迁移就可以使用Spark的强大处理能力
# 2.Spark运行模式
    部署Spark集群大体上分为两种模式:单机模式与集群模式
    大多数分布式框架都支持单机模式，方便开发者调试框架的运行环境。但是在生产环境中，并不会使用单机模式
    下面详细列举了Spark目前支持的部署模式:
        1. Local模式:在本地部署单个Spark服务
        2. Standalone模式:Spark自带的任务调度模式(国内不常用)
        3. YARN模式:Spark使用Hadoop的YARN组件进行资源与任务调度(国内最常用)
        4. Mesos模式:Spark使用Mesos平台进行资源与任务的调度(国内很少用)
## 1.Local模式
    1. 安装解压即可
    2. 官方求PI案例
    bin/spark-submit --class org.apache.spark.examples.SparkPi --master local[2] ./examples/jars/spark-examples_2.12-3.3.1.jar 10
        --class:表示要执行程序的主类
        --master local[2]
            1. local:没有指定线程数，则所有计算都运行在一个线程当中，没有任何并行计算
            2. local[K]:指定使用K个Core来运行计算，比如local[2]就是运行2个Core来执行
            3. local[*]:默认模式。自动帮你按照CPU最多核来设置线程数。比如CPU有8核，Spark帮你自动设置8个线程计算
        spark-examples_2.12-3.3.1.jar:要运行的程序
        10:要运行程序的输入参数(计算圆周率π的次数，计算次数越多，准确率越高)
## 2.Yarn模式
### 1.安装解压，重命名为spark-yarn
### 2.修改spark-env.sh
    添加YARN_CONF_DIR配置，保证后续运行任务的路径都变成集群路径
    cd /opt/module/spark-yarn/conf
    mv spark-env.sh.template spark-env.sh
    vim spark-env.sh
        YARN_CONF_DIR=/opt/module/hadoop-3.3.4/etc/hadoop
### 3.配置历史服务
    针对Yarn模式，再次配置一下历史服务器
    1. 修改spark-default.conf.template名称
        mv spark-defaults.conf.template spark-defaults.conf
    2. 修改spark-default.conf文件，配置日志存储路径
        vim spark-defaults.conf
            spark.eventLog.enabled           true
            spark.eventLog.dir               hdfs://hadoop102:8020/directory
    3. 修改spark-env.sh文件，添加如下配置:
        vim spark-env.sh
            export SPARK_HISTORY_OPTS="
            -Dspark.history.ui.port=18080
            -Dspark.history.fs.logDirectory=hdfs://hadoop102:8020/directory
            -Dspark.history.retainedApplications=30"
            # 参数1:WEBUI访问的端口号为18080
            # 参数2:指定历史服务器日志存储路径(读)
            # 参数3:指定保存Application历史记录的个数，如果超过这个值，旧的应用程序信息将被删除，这个是内存中的应用数，而不是页面上显示的应用数
    4. 配置查看历史日志
        为了能从Yarn上关联到Spark历史服务器，需要配置spark历史服务器关联路径
        目的是点击yarn(8088)上spark任务的history按钮，进入的是spark历史服务器(18080)，而不再是yarn历史服务器(19888)
        1. 修改配置文件/opt/module/spark-yarn/conf/spark-defaults.conf，添加如下内容:
            spark.yarn.historyServer.address=hadoop102:18080
            spark.history.ui.port=18080
        2. 重启Spark历史服务
            sbin/stop-history-server.sh
            sbin/start-history-server.sh
### 4.运行流程
    Spark有yarn-client和yarn-cluster两种模式，主要区别在于:Driver程序的运行节点
    yarn-client:Driver程序运行在客户端，适用于交互、调试，希望立即看到app的输出
    yarn-cluster:Driver程序运行在由ResourceManager启动的APPMaster，适用于生产环境
    1. 客户端模式(默认)
        bin/spark-submit \
        --class org.apache.spark.examples.SparkPi \
        --master yarn \
        --deploy-mode client \
        ./examples/jars/spark-examples_2.12-3.3.1.jar \
        10
    2. 集群模式
        bin/spark-submit \
        --class org.apache.spark.examples.SparkPi \
        --master yarn \
        --deploy-mode cluster \
        ./examples/jars/spark-examples_2.12-3.3.1.jar \
        10
# 3.RDD
## 1.RDD概述
    1. RDD(Resilient Distributed Dataset)
        弹性分布式数据集，是Spark中最基本的数据抽象，Spark中最基本的数据处理模型(业务模型)
        代码中是一个抽象类，它代表一个弹性的、不可变、可分区、里面的元素可并行计算的集合
        RDD封装的就是分布式计算功能:数据传输、数据执行
        RDD会提供很多方法，并且每一个方法不会很复杂，可以组合多个RDD方法来实现复杂逻辑
    2. RDD五大特性
        1. 一组分区(Partition)，即是数据集的基本组成单位，标记数据是哪个分区的
        2. 一个计算每个分区的函数
        3. RDD之间的依赖关系
        4. 一个Partitioner，即RDD的分片函数，控制分区的数据流向(键值对)
        5. 一个列表，存储存取每个Partition的优先位置(preferred location)，如果节点和分区个数不对应优先把分区设置在哪个节点上。移动数据不如移动计算，除非资源不够
## 2.RDD的创建
    在Spark中创建RDD的创建方式可以分为三种:从集合中创建RDD、从外部存储创建RDD、从其他RDD创建
    在pom文件中添加spark-core的依赖:
        <dependencies>
            <dependency>
                <groupId>org.apache.spark</groupId>
                <artifactId>spark-core_2.12</artifactId>
                <version>3.3.1</version>
            </dependency>
        </dependencies>
### 1.从集合中创建RDD:parallelize
    public class Test01_List {
        public static void main(String[] args) {
            # 1.创建配置对象
            SparkConf conf = new SparkConf().setMaster("local[*]").setAppName("sparkCore");
            # 2.创建SparkContext
            JavaSparkContext jsc = new JavaSparkContext(conf);
            # 3.编写代码
            JavaRDD<String> rdd = jsc.parallelize(Arrays.asList("hello", "spark"));
            rdd.collect().forEach(System.out::println);
            rdd.saveAsTextFile("output");
            # 4.关闭jsc
            jsc.stop();
        }
    }
### 2.从外部存储系统的数据集创建:textFile
    由外部存储系统的数据集创建RDD包括:本地的文件系统，还有所有Hadoop支持的数据集，比如HDFS、HBase等
    JavaRDD<String> rdd = jsc.textFile("input");
## 3.分区规则
### 1.从集合创建RDD
    1. 默认分区数为核数
        conf.set("spark.default.parallelism", "6");
            # 手动设置默认核数
    2. 手动设置分区数
        JavaRDD<String> rdd = jsc.parallelize(names, 2);
            # 分区数设置为2
    3. 数据分配方法
        利用整数除机制，左闭右开
        0号分区: (0 * 总字节数 / 分区数) 到 (1 * 总字节数 / 分区数)
        1号分区: (1 * 总字节数 / 分区数) 到 (2 * 总字节数 / 分区数)
        例如:
        0: start 0*5/2  end 1*5/2 => (0,2)
        1: start 1*5/2  end 2*5/2 => (2,5)
### 2.从文件创建RDD
    1. 默认分区数为 核数和2的最小值
    2. 手动设置最小分区数
        JavaRDD<String> rdd = jsc.textFile("data/word.txt", 3)
            # 最小分区数设置为3
    3. 分区流程
        1. 根据文件的总长度(回车，换行符也计算在内)totalSize 和 切片数numSplits 计算出 平均长度goalSize
            goalSize = totalSize / numSplits
        2. 获取块大小 blockSize = 128M
        3. 计算切分大小 splitSize = Math.max(minSize, Math.min(goalSize, blockSize));
            goalSize 和 blockSize 比较，谁小拿谁进行切分
        4. 使用splitSize按照1.1倍原则切分整个文件，如果最后剩余数据大小大于 0.1*splitSize，再加一个分区
        例如:
        totalSize = 10，numSplits = 3
        goalSize = 10 / 3 = 3(byte) 表示每个分区存储3字节的数据
        分区数 = totalSize/ goalSize = 10 /3 => 3,3,4
        4byte大于3byte的1.1倍,符合Hadoop切片1.1倍的策略,因此会多创建一个分区,即一共有4个分区
    4. 数据分配方法
        Spark采用Hadoop的方式读取，所以按行读取
        读取数据时会依靠换行符进行读取，读取到回车符会忽略
        如果切分的位置位于一行的中间，会在当前分区读完一整行数据
        数据读取位置计算是以偏移量为单位来进行计算的，从0开始
        例如:
        0: [0,3](如果没读满3个，最多会读到偏移量3的位置，若偏移量3不在行尾，读完此行)
        1: [3,6]
        2: [6,9]
        3: [9,10]
## 4.Transformation 转换算子
    装饰者设计模式
    转换算子只是用于组合功能，不会马上执行
    转换算子返回类型为RDD
    1. RDD方法在调用时，默认分区数量和前面RDD的分区数量相同
    2. RDD方法在调用时，默认情况下，数据处理完后，所在分区不变
    3. RDD方法在调用时，分区内有序，分区间无序
    4. 元组
        Tuple2<> tuple = new Tuple2<>(,)
        tuple._1
        tuple._2
### 1.单值类型
| 参数 | 描述 |
| --- | --- |
| map() 映射 | rdd.map(num -> num + 1)<br>rdd.mapToPair(num -> new Tuple2(num, 1))
| flatMap() 扁平化 | rdd.flatMap(list -> list.iterator())<br>将所有集合中元素取出放入一个大的集合中<br>需返回可迭代对象
| filter() 过滤 | rdd.filter(num -> num > 0)
| groupBy() 分组 | rdd.groupBy(num -> num % 2)<br>对数据添加分组标记，按标记分组，将同一组的数据放入一个迭代器<br>shuffle:<br>	将不同的分区数据进行打乱重组的过程，称之为shuffle<br>	分组落盘<br>	同组数据放入同一分区<br>shuffle存在的问题:<br>	分区数量可能不合理(分组数量与分区数量不匹配)<br>	不允许出现环状功能调用<br>	shuffle操作会影响Spark的计算性能<br>shuffle操作一般都会提供改变分区的功能<br>底层调用groupByKey()
| distinct() 全局去重 | rdd.distinct()<br>底层存在shuffle操作<br>底层使用了reduceByKey()
| sortBy() 排序 | rdd.sortBy(num -> num, true, 2)<br>参数1: 排序的规则<br>	给每一个数据增加排序标记，根据标记大小对数据排序<br>参数2: 升序或降序，true为升序<br>参数3: 设定分区数量<br>底层调用sortByKey()
| coalesce() 合并分区 | rdd.coalesce(2, false)<br>默认false，没有shuffle操作，数据不会打乱重组<br>可能存在数据倾斜，若倾斜可以使用shuffle操作
| repartition() 重新分区 | rdd.repartition(3)<br>底层调用coalesce()，存在shuffle操作
### 2.键值类型
| 参数 | 描述 |
| --- | --- |
| mapValues() 对value操作 | rdd.mapValues(val -> val * 2)
| groupByKey() 按key对value分组 | rdd.groupByKey()
| reduceByKey() 按key对value两两聚合 | rdd.reduceByKey((val1, val2) -> val1 + val2)<br>reduceByKey会进行两次计算:分区内计算+分区间计算<br>reduceByKey会在shuffle之前进行预聚合
| sortByKey() 按key排序 | rdd.sortByKey()
## 5.Action 行动算子
    行动算子调用后就会执行功能
    行动算子返回类型为集合
    行动算子执行时就会产生一个Job
    代码执行位置:
        RDD的转换算子在调用时，逻辑并不会执行，会在逻辑发送到Executor端才执行
            RDD算子的内部代码在Executor端执行
            RDD算子的外部代码在Driver端执行
            当算子的内部代码使用了外部代码的数据或对象，那么就需要从Driver端将对象或数据拉取到Executor端
| 参数 | 描述 |
| --- | --- |
| collect() | rdd.collect()<br>会将结果从EXecutor按照分区顺序依次拉取回Driver<br>可能存在Driver中资源不够的问题，故生产环境中不推荐使用
| first() 首个 | rdd.first()
| take() 前几个 | rdd.take(3)
| takeOrdered() | rdd.takeOrdered(3)<br>先排序，再取前几个
| count() 计数 | rdd.count()
| countByKey() 对key计数 | rdd.countByKey()
| countByValue() 对单值计数 | rdd.countByValue()
| save() | rdd.saveAsTextFile("output")<br>rdd.saveAsObjectFile("output")
| foreach() 遍历所有元素 | rdd.foreach()<br>分布式循环遍历，以分区为单位循环，可能导致结果无序
| foreachPartition() 遍历所有分区 | rdd.foreachPartition()
## 6.Kryo序列化框架
    当RDD在Shuffle数据的时候，简单数据类型、数组和字符串类型已经在Spark内部使用Kryo来序列化
    使用Kryo序列化:
        // 创建配置对象
        SparkConf conf = new SparkConf().setMaster("local[*]").setAppName("sparkCore")
        // 替换默认的序列化机制
        .set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
        // 注册需要使用kryo序列化的自定义类
        .registerKryoClasses(new Class[]{Class.forName("com.atguigu.bean.User")});
## 7.RDD依赖关系
### 1.什么是依赖
    2个相邻RDD之间存在依赖关系，新的(下游)RDD依赖于旧的(上游)RDD
    连续的依赖关系称之为血缘关系
    rdd.toDebugString()  #查看依赖关系
### 2.依赖的2个分类
    1. 窄依赖: OneToOneDependency(继承NarrowDependency)
        上游RDD的一个分区的数据被下游RDD的一个分区所独享(一对一，多对一)
    2. 宽依赖: ShuffleDependency(继承Dependency)
        上游RDD的一个分区的数据被下游RDD的多个分区所共享(一对多)
        底层存在shuffle操作
        具有宽依赖的transformations包括:sort、reduceByKey、groupByKey、join和调用repartition函数的任何操作
### 3.Spark中的数量
    1. Application
        代码中Spark环境对象的数量，其实就是应用程序的数量
        一般情况下，一个Java程序就是一个Application
    2. Job
        代码中，执行行动算子的时候，调用一次就会产生一个Job(new Action)
    3. Stage
        Spark中，shuffle操作会将完整的计算流程分成两个阶段，前一个阶段不执行完，后一个阶段不允许执行
        阶段的数量 = shuffle依赖的数量 + 1
    4. Task
        一个阶段中任务的数量 = 阶段中最后一个RDD的分区数量
        总任务的数量 = 总分区的数量，一般推荐设定为CPU核数的2~3倍
## 8.持久化
### 1.Cache 缓存
    1. 使用方法
        rdd.cache()                          #将RDD中数据放入内存
        rdd.persist(StorageLevel.DISK_ONLY)  #将RDD中数据放入磁盘
    2. 存储位置
        Cache缓存的数据通常存储在磁盘、内存等地方，可靠性低
    3. 执行时机
        并不是这两个方法被调用时立即缓存，而是触发后面的Action算子时，该RDD将会被缓存在计算节点的内存中，供后面重用
    4. 血缘关系
        缓存操作会在RDD的血缘关系中增加依赖
    5. 自动缓存
        shuffle算子不需要手动cache，会自动缓存
    6. 释放缓存
        如果使用完了缓存，可以通过unpersist()方法释放缓存
### 2.CheckPoint 检查点
    cache和persist方法只对当前应用有效，一旦应用程序执行完毕，缓存和持久化的数据全部删除
    如果要跨应用使用计算的中间数据，可以采用检查点的操作
    1. 使用方法
        jsc.setCheckPointDir("path")  #设置检查点存储路径
        rdd.checkpoint()              #检查点操作
    2. 存储位置
        检查点的数据通常是存储在HDFS等容错、高可用的文件系统
        如果检查点数据存储到HDFS集群，要注意配置访问集群的用户名。否则会报访问权限异常:
            // 修改用户名称
            System.setProperty("HADOOP_USER_NAME","atguigu");
            // 需要设置路径.需要提前在HDFS集群上创建/checkpoint路径
            jsc.setCheckpointDir("hdfs://hadoop102:8020/checkpoint");
    3. 执行时机
        检查点操作并不会马上被执行，必须执行Action操作才能触发。但是检查点为了数据安全，会从血缘关系的最开始执行一遍
    4. 血缘关系
        检查点操作会切断RDD的血缘关系，重新创建新的血缘
    5. 加快读取
        检查点操作一般为了提高效率，会和Cache操作联合使用
## 9.分区器
    Spark目前支持Hash分区(默认)、Range分区和用户自定义分区
    单值类型数据没有分区器
    键值类型数据才有分区器，数据的key决定数据所在分区
### 1.HashPartitioner
    key.hashCode() % numPartitions
    可能出现数据倾斜
### 2.RangePartitioner
    将一定范围内的数映射到某一个分区内，尽量保证每个分区中数据量均匀，而且分区与分区之间是有序的
    一个分区中的元素肯定都是比另一个分区内的元素小或者大，但是分区内的元素是不能保证顺序的
    简单的说就是将一定范围内的数映射到某一个分区内
    1. 从整个RDD中抽取样本数据并排序，根据分区数将数据划分出相应段数，计算出每个分区的最大key值，形成一个Array[key]类型的数组变量rangeBounds
    2. 根据每个key在rangeBounds中所处的范围，给出该key的分区号
    3. 该分区器要求RDD中的key类型必须是可以排序的
### 3.自定义分区器
    class MyPartitioner extends Partitioner {
        @Override
        public int numPartitions() {
            return 2;
        }
        @Override
        public int getPartition(Object key) {
            if ((Integer) key % 2 == 0) return 0;
            else return 1;
        }
    }
## 10.广播变量
    1. 定义
        广播变量: 分布式共享只读变量
    2. 为什么使用广播变量
        多个Task无法共享对象
        多个Task并行操作中使用同一个变量，但是Spark会为每个Task任务分别发送，可能出现同一数据传输多次，出现冗余
    3. 广播变量的优点
        广播变量用来高效分发较大的对象
        广播变量向所有工作节点(Executor)发送一个较大的只读值，以供一个或多个Task操作使用
    4. 使用方法
        // 创建广播变量
        Broadcast<> broadcast = jsc.broadcast(var);
        // 使用广播变量
        broadcast.value()
        例:
            JavaRDD<Integer> rdd = jsc.parallelize(Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 0), 10);
            List<Integer> okIds = new ArrayList<>();
            okIds.add(4);
            okIds.add(6);
            okIds.add(8);
            okIds.add(12);
            okIds.add(25);
            Broadcast<List<Integer>> broadcast = jsc.broadcast(okIds);
            JavaRDD<Integer> filterRDD = rdd.filter(
                    num -> broadcast.value().contains(num)
            );
            filterRDD.collect().forEach(System.out::println);
# 4.SparkSQL
## 1.常用方式
### 1.方法调用
    1. 导入依赖
        <dependencies>
            <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-sql_2.12</artifactId>
            <version>3.3.1</version>
            </dependency>
        </dependencies>
    2. 代码实现
        SparkConf conf = new SparkConf().setAppName("sparksql").setMaster("local[*]");
        SparkSession spark = SparkSession.builder().config(conf).getOrCreate();
        // 按行读取
        Dataset<Row> lineDS = spark.read().json("input/user.json");
        // 转换
        1. 转换为类和对象
            Dataset<User> userDS = lineDS.as(Encoders.bean(User.class));
            userDS.show();
        2. 使用函数式的方法转换为类和对象
            Dataset<User> userDataset = json.map(
                (MapFunction<Row, User>) value -> new User(value.getAs("name"), value.getAs("age")),
                Encoders.bean(User.class)
            );
            userDataset.show();
        3. 转换为RDD
            JavaRDD<User> userJavaRDD = lineDS.javaRDD();
        // 常规方法
        1. 排序
            Dataset<User> sortDS = userDataset.sort(new Column("age"));
            sortDS.show();
        2. 分组计数
            RelationalGroupedDataset groupByDS = userDataset.groupBy("name");
            Dataset<Row> count = groupByDS.count();
            count.show();
        // 函数式方法
            KeyValueGroupedDataset<String, User> groupedDataset = userDataset.groupByKey(
                (MapFunction<User, String>) value -> value.getName(),
                Encoders.STRING()
            );
            Dataset<Tuple2<String, User>> result = groupedDataset.reduceGroups(
                (ReduceFunction<User>) (v1, v2) -> new User(v1.getName(), Math.max(v1.getAge(), v2.getAge()))
            );
            result.show();
        spark.close();
### 2.SQL使用方式
    SparkConf conf = new SparkConf().setAppName("sparksql").setMaster("local[*]");
    SparkSession spark = SparkSession.builder().config(conf).getOrCreate();
    Dataset<Row> lineDS = spark.read().json("input/user.json");
    // 创建视图 => 转换为表格，填写表名
    // 临时视图的生命周期和当前的sparkSession绑定
    // createOrReplaceTempView表示覆盖之前相同名称的视图
    lineDS.createOrReplaceTempView("t1");
    Dataset<Row> result = spark.sql("select * from t1 where age > 18");
    result.show();
    spark.stop();
### 3.DSL特殊语法
    SparkConf conf = new SparkConf().setAppName("sparksql").setMaster("local[*]");
    SparkSession spark = SparkSession.builder().config(conf).getOrCreate();
    Dataset<Row> lineRDD = spark.read().json("input/user.json");
    Dataset<Row> result = lineRDD.select(col("name").as("newName"),col("age").plus(1).as("newAge"))
            .filter(col("age").gt(18));
    result.show();
    spark.close();
## 2.SQL语法的用户自定义函数
### 1.UDF 一行进，一行出
    1. 注册自定义函数
        sparkSession.udf().register("prefix", name -> "name: " + name, DataTypes.StringType);
        # 参数依次为函数名，函数逻辑，返回值类型
    2. 使用自定义函数
        sparkSession.sql("select prefix(age) from user").show();
### 2.UDAF 多行进，一行出
    1. 自定义聚合对象，创建公共类
        # 继承org.apache.spark.sql.expressions.Aggregator
        # 定义泛型
        #  IN:   函数的输入数据的类型
        #  BUFF: 函数的缓冲区数据的类型
        #        KV键值对只能访问不能修改
        #  OUT:  函数的输出数据的类型
        public class AUDAF extends Aggregator<Long, Tuple2<Long, Long>, Long> {
            // 初始化
            @Override
            public Tuple2<Long, Long> zero() {
                return new Tuple2<>(0L, 0L);
            }
            // 聚合
            @Override
            public Tuple2<Long, Long> reduce(Tuple2<Long, Long> b, Long a) {
                return new Tuple2<>(b._1 + a, b._2 + 1);
            }
            // 合并
            @Override
            public Tuple2<Long, Long> merge(Tuple2<Long, Long> b1, Tuple2<Long, Long> b2) {
                return new Tuple2<>(b1._1 + b2._1, b1._2 + b2._2);
            }
            // 结果
            @Override
            public Long finish(Tuple2<Long, Long> reduction) {
                return reduction._1 / reduction._2;
            }
            // 缓冲区数据类型
            @Override
            public Encoder<Tuple2<Long, Long>> bufferEncoder() {
                return Encoders.tuple(Encoders.LONG(), Encoders.LONG());
            }
            // 输出数据类型
            @Override
            public Encoder<Long> outputEncoder() {
                return Encoders.LONG();
            }
        }
    2. 使用自定义函数
        sparkSession.udf().register("func", functions.udaf(new AUDAF(), Encoders.LONG()));
        sparkSession.sql("select func(age) from text").show();
        # 使用LONG而非INT
## 3.SparkSQL数据的加载与保存
### 1.读取和保存文件
#### 1.CSV文件
    # CSV文件以逗号分隔
    # SparkSQL中csv方法解析的文件数据格式不仅仅支持逗号分隔，亦支持其他分隔方式
    Dataset<Row> csvDS = sparkSession.read()
        .option("header", "true")  # 以首行为表头
        .option("sep", ",")        # 以","为分隔符
        .csv("input/user.csv");
    csvDS.show();
    csvDS.write()
        .mode("append")  # append 追加
                         # Overwrite 覆盖
                         # Ignore 如果目标路径已经存在数据，则跳过此次写操作，不会报错也不会覆盖已有数据
                         # ErrorIfExists 如果目标路径已经存在数据，则报错
        .option("header","true")
        .option("compression","gzip")  #压缩格式
        .option("sep", ",")
        .csv("output");
#### 2.JSON文件
    # SparkSQL读取JSON文件的要求: 每一行符合JSON格式，而不是整个文件符合JSON格式
    Dataset<User> userDS = json.as(Encoders.bean(User.class));
    # json数据可以读取数据的数据类型
    userDS.show();
    # 读取其他类型的数据也能写出为json
    DataFrameWriter<User> writer = userDS.write();
    writer.json("output1");
#### 3.Parquet文件
    Dataset<Row> json = spark.read().json("input/user.json");
    # 写出默认使用snappy压缩
    json.write().parquet("output");
    # 读取parquet自带解析，能够识别列名
    Dataset<Row> parquet = spark.read().parquet("output");
    parquet.printSchema();
    parquet.show();
### 2.与MySQL交互
    1. 导入依赖
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>8.0.18</version>
        </dependency>
    2. 代码实现
        SparkConf conf = new SparkConf().setAppName("sparksql").setMaster("local[*]");
        SparkSession spark = SparkSession.builder().config(conf).getOrCreate();
        Dataset<Row> json = spark.read().json("input/user.json");
        // 添加参数
        Properties properties = new Properties();
        properties.setProperty("user","root");
        properties.setProperty("password","000000");
        // 写模式，对表格追加
        json.write()
            .mode(SaveMode.Append)
            .jdbc("jdbc:mysql://hadoop102:3306","gmall.testInfo",properties);
        // 指定从gmall库中的test_info表中读取数据并显示
        Dataset<Row> jdbc = spark.read().jdbc("jdbc:mysql://hadoop102:3306/gmall?useSSL=false&useUnicode=true&characterEncoding=UTF-8&allowPublicKeyRetrieval=true", "test_info", properties);
        jdbc.show();
        spark.close();
### 3.与Hive交互
    1. 添加依赖
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-hive_2.12</artifactId>
            <version>3.3.1</version>
        </dependency>
    2. 拷贝hive-site.xml到resources目录
        如果需要操作Hadoop，也需要拷贝hdfs-site.xml、core-site.xml、yarn-site.xml
    3. 代码实现
        System.setProperty("HADOOP_USER_NAME","atguigu");
        SparkConf conf = new SparkConf().setAppName("sparksql").setMaster("local[*]");
        SparkSession spark = SparkSession.builder()
            .enableHiveSupport() // 添加hive支持
            .config(conf).getOrCreate();
        spark.sql("show tables").show();
        spark.sql("create table user_info(name String,age bigint)");
        spark.sql("insert into table user_info values('zhangsan',10)");
        spark.sql("select * from user_info").show();
        spark.close();
# 5.SparkStreaming
## 1.SparkStreaming概述
### 1.什么是Spark Streaming
    数据流:
        有界数据流: 有开始，有结束的数据流，如内存集合，磁盘文件
        无界数据流: 有开始，没有结束的数据流，如socket，Kafka，计算时需要切分为有界数据流
    数据处理延迟:
        离线:   延迟时间以小时、天为单位
        准实时: 延迟时间以秒、分钟单位
        实时:   延迟时间以毫秒为单位
    数据处理方式:
        批量:   一批一批数据的处理
        微批量: 一小批一小批数据的处理
        流式:   一条一条数据的处理
    Spark只能处理有界数据流，是批量、离线数据处理框架
    SparkStreaming: 微批量、准实时数据处理框架
### 2.Spark Streaming架构原理
    Spark Core数据模型:       RDD
    Spark SQL数据模型:        Dataset
    Spark Streaming数据模型:  DStream(离散化流)
        DStream是随时间推移而收到的数据的序列
        在DStream内部，每个时间区间收到的数据都作为RDD存在，而DStream是由这些RDD所组成的序列
        DStream就是对RDD在实时数据处理场景的一种封装
## 2.SparkStreaming使用
### 1.使用socket接收数据
    # 需要提前监听9999端口并将数据转发给socketTextStream
    SparkConf conf = new SparkConf().setMaster("local[*]").setAppName("SparkStreaming");
    JavaStreamingContext jsc = new JavaStreamingContext(conf, new Duration(3000));
    JavaReceiverInputDStream<String> dstream = jsc.socketTextStream("127.0.0.1", 9999);
    dstream.print();
    jsc.start();
    jsc.awaitTermination();
### 2.读取kafka主题中的数据
    1. 添加依赖
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-streaming-kafka-0-10_2.12</artifactId>
            <version>3.3.1</version>
        </dependency>
    2. 编写代码
        SparkConf conf = new SparkConf().setMaster("local[*]").setAppName("HelloWorld");
        JavaStreamingContext jsc = new JavaStreamingContext(conf, new Duration(3000));
        // 创建配置参数
        HashMap<String, Object> conf = new HashMap<>();
        conf.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "hadoop102:9092,hadoop103:9092,hadoop104:9092");
        conf.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");
        conf.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");
        conf.put(ConsumerConfig.GROUP_ID_CONFIG, "group1");
        conf.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");
        // 需要消费的主题
        ArrayList<String> topics = new ArrayList<>();
        topics.add("test");
        JavaInputDStream<ConsumerRecord<String, String>> directStream = KafkaUtils.createDirectStream(
                jsc,
                LocationStrategies.PreferBrokers(),
                ConsumerStrategies.Subscribe(topics, conf)
        );
        directStream.map(v1 -> v1.value()).print(100);
        jsc.start();
        jsc.awaitTermination();
## 3.DStream转换
### 1.无状态转化操作
    无状态转化操作: 就是把RDD转化操作应用到DStream每个批次上，每个批次相互独立
    离散化流DStream的方法称之为原语
    transform原语用于将数据模型进行转换，转成RDD
    JavaDStream<String> transformDS = dstream.transform(
            rdd -> {
                // 此处代码运行在Driver上(每个采集周期运行一次)
                return rdd.sortBy(s -> {
                    // 此处代码运行在Executor上(Task)
                    return s;
                }, true, 2);
            }
    );
### 2.窗口操作
    1. 代码实现
        JavaDStream<String> windowDS = dstream.window(new Duration(6000), new Duration(3000));
        JavaPairDStream<String, Integer> wordCountDS = windowDS.reduceByKey(Integer::sum);
        wordCountDS.print();
    2. window需要两个参数:
        窗口范围:       计算内容的时间范围
        窗口移动时间间隔: 隔多久触发一次计算
        都必须为采集时间的整数倍
    3. 窗口数据处理的类型:
        1. 窗口范围(6s)大于窗口移动幅度(3s): 重复数据
        2. 窗口范围(3s)等于窗口移动幅度(3s)
        3. 窗口范围(3s)小于窗口移动幅度(6s): 丢失数据
    4. reduceByKeyAndWindow
        reduceByKeyAndWindow(func, windowLength, slideInterval, [numTasks])
        当在一个(K,V)对的DStream上调用此函数，会返回一个新(K,V)对的DStream，此处通过对滑动窗口中批次数据使用reduce函数来整合每个key的value值
## 4.DStream输出
    DStream与RDD中的惰性求值类似，如果一个DStream及其派生出的DStream都没有被执行输出操作，那么这些DStream就都不会被求值
    如果StreamingContext中没有设定输出操作，整个Context就都不会启动
    输出操作API如下:
    1. saveAsTextFiles(prefix, [suffix])
        以text文件形式存储这个DStream的内容。每一批次的存储文件名基于参数中的prefix和suffix
        如: prefix-Time_IN_MS[.suffix]
        注意: 以上操作都是每一批次写出一次，会产生大量小文件，在生产环境，很少使用
    2. print()
        在运行流程序的驱动结点上打印DStream中每一批次数据的最开始10个元素，用于开发和调试
    3. foreachRDD(func)
        最通用的输出操作，将函数func用于产生DStream的每一个RDD
        在企业开发中通常采用foreachRDD()，它用来对DStream中的RDD进行任意计算，这和transform()有些类似，都可以让我们访问任意RDD
        在foreachRDD()中，可以重用我们在Spark中实现的所有行动操作(action算子)，比如把数据写入MySQL
        例:
        wordCountDS.foreachRDD(
            rdd -> {
                System.out.println("-------------------------------------------");
                System.out.println("Time: " + System.currentTimeMillis());
                System.out.println("-------------------------------------------");
            }
        );
## 5.优雅关闭
    SparkStreaming采集器计算功能一般不会关闭，除非:
        1. 业务升级，数据规则发生变化
        2. 技术升级
    javaStreamingContext.stop(true, true)
    一般不会在main()主线程中进行关闭，一般会在子线程中监听某一状态值来确定何时关闭
# 6.Spark内核
## 1.Spark提交流程(YarnCluster)
    1. 脚本启动执行
        解析参数
        创建客户端
        封装提交参数和命令
        向ResourceManager提交任务信息submitApplication
        向HDFS提交资源数据
    2. RM启动ApplicationMaster
    3. AM根据参数启动Driver线程并初始化SparkContext
    4. Driver在NodeManager上启动Executor(ExecutorBackend)
    5. Driver将Task添加进TaskPool，并通过RPC发送给Executor
    6. Executor创建ThreadPool运行Task
## 2.任务切分与调度
    1. DAGScheduler
        根据宽依赖做Stage划分
        根据分区数做Task划分
    2. TaskScheduler
        TaskScheduler通过TaskSet获取job的所有Task,然后序列化发往Executor
    3. SchedulableBuilder(FIFO/Fair)
    4. SchedulerBackend(通信后台)
        负责与ExecutorBackend通信
## 3.Spark通信原理
    Spark底层通信采用的是netty通信框架(AIO, NIO(EPOCH))
    通信方式类似于生活中发邮件
| 参数 | 描述 |
| --- | --- |
| RpcEndpoint | 			RPC通信终端，Spark针对每个节点(Client/Master/Worker)都称之为一个RPC终端，且都实现RpcEndpoint接口
| RpcEnv | 			RPC上下文环境，每个RPC终端运行时依赖的上下文环境称为RpcEnv，在当前Spark版本中使用的NettyRpcEnv
| RpcEndpointRef | 			RpcEndpointRef是对远程RpcEndpoint的一个引用，当我们需要向一个具体的RpcEndpoint发送消息时，一般我们需要获取到该RpcEndpoint的引用，然后通过该应用发送消息
| RpcAddress | 			表示远程的RpcEndpointRef的地址，Host + Port
| Dispatcher | 			消息调度(分发)器，针对于RPC终端需要发送远程消息或者从远程RPC接收到的消息，分发至对应的指令收件箱(发件箱)，如果指令接收方是自己则存入收件箱，如果指令接收方不是自己，则放入发件箱
| Inbox | 指令消息收件箱，一个本地RpcEndpoint对应一个收件箱，Dispatcher在每次向Inbox存入消息时，都将对应EndpointData加入内部ReceiverQueue中<br>另外Dispatcher创建时会启动一个单独线程进行轮询ReceiverQueue，进行收件箱消息消费
| OutBox | 指令消息发件箱，对于当前RpcEndpoint来说，一个目标RpcEndpoint对应一个发件箱，如果向多个目标RpcEndpoint发送信息，则有多个OutBox<br>当消息放入Outbox后，紧接着通过TransportClient将消息发送出去，消息放入发件箱以及发送过程是在同一个线程中进行
| TransportClient | 			Netty通信客户端，一个OutBox对应一个TransportClient，TransportClient不断轮询OutBox，根据OutBox消息的receiver信息，请求对应的远程TransportServer
| TransportServer | 			Netty通信服务端，一个RpcEndpoint对应一个TransportServer，接受远程消息后调用Dispatcher分发消息至对应收发件箱
## 4.Shuffle原理
    SortShuffle:
    在溢写磁盘前，先根据key进行排序，再分批默认以每批一万条通过缓冲区溢写的方式写入磁盘文件
    每次溢写都会产生一个磁盘文件，也就是说一个Task过程会产生多个临时文件
    最后在每个Task中，将所有的临时文件合并，一次写入到最终文件
    每个文件会产生一个index文件，用于记录之后的每个Task所要读取的数据的索引
## 5.Spark内存
### 1.三种内存
    1. 堆外内存: 直接向操作系统申请的内存，不受JVM控制
        减少了垃圾回收的工作，但难以控制，如果内存泄漏，那么很难排查
        堆外内存本身是序列化的，但相对来说，不适合存储很复杂的对象
        堆外内存大小设置: spark.memory.offHeap.enabled 参数启用，并由 spark.memory.offHeap.size 参数设定堆外空间的大小
    2. 堆内内存: 程序在运行时动态地申请的内存空间
        堆内内存大小设置: -executor-memory 或 spark.executor.memory
    3. 非堆内存: 方法区、栈等
### 2.堆内内存空间分配
    1. Java内存管理: 分代管理
        新生代: 会有minor gc
            EDNE(伊甸):  新出生的
            S1(幸存区1): EDNE中从minor gc中幸存下来的
            S2(幸存区2): S1中从minor gc中幸存下来的
        老年代: 会有major gc
            经历过一定轮数minor gc的会进入老年代
    2. Spark内存管理: 分层管理
        动态内存管理，Storage和Execution所占用内存不固定
        Storage(存储内存)30%:   cache、广播变量
        Execution(执行内存)30%: shuffle
        Other(其他内存)40%:     Spark的内部对象
### 3.存储内存管理
    RDD的持久化机制:
        在对RDD持久化时，Spark规定了MEMORY_ONLY、MEMORY_AND_DISK 等7种不同的存储级别
        存储级别从三个维度定义了RDD的 Partition(同时也就是Block)的存储方式
            存储位置: 磁盘／堆内内存／堆外内存
                如MEMORY_AND_DISK是同时在磁盘和堆内内存上存储，实现了冗余备份
                OFF_HEAP 则是只在堆外内存存储，目前选择堆外内存时不能同时存储到其他位置
            存储形式: Block 缓存到存储内存后，是否为非序列化的形式
                如 MEMORY_ONLY是非序列化方式存储
                OFF_HEAP 是序列化方式存储
            副本数量: 大于1时需要远程冗余备份到其他节点
                如DISK_ONLY_2需要远程备份1个副本