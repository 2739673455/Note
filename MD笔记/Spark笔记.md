# 1.Spark概述
## 1.Spark简介
    Spark是一种基于内存的快速、通用、可扩展的大数据分析计算引擎
## 2.Spark内置模块
| 参数 | 描述 |
| --- | --- |
| Spark Core | 实现了Spark的基本功能，包含任务调度、内存管理、错误恢复、与存储系统交互等模块<br>Spark Core中还包含了对弹性分布式数据集(Resilient Distributed DataSet，简称RDD)的API定义
| Spark SQL | 是Spark用来操作结构化数据的程序包。通过Spark SQL，我们可以使用 SQL或者Apache Hive版本的HQL来查询数据<br>Spark SQL支持多种数据源，比如Hive表、Parquet以及JSON等
| Spark Streaming | 是Spark提供的对实时数据进行流式计算的组件。提供了用来操作数据流的API，并且与Spark Core中的 RDD API高度对应
| Spark MLlib | 提供常见的机器学习功能的程序库。包括分类、回归、聚类、协同过滤等，还提供了模型评估、数据 导入等额外的支持功能
| Spark GraphX | 主要用于图形并行计算和图挖掘系统的组件
| 集群管理器 | Spark设计为可以高效地在一个计算节点到数千个计算节点之间伸缩计算。为了实现这样的要求，同时获得最大灵活性，Spark支持在各种集群管理器(Cluster Manager)上运行，包括Hadoop YARN、Apache Mesos，以及Spark自带的一个简易调度器，叫作独立调度器
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
            #参数1:WEBUI访问的端口号为18080
            #参数2:指定历史服务器日志存储路径(读)
            #参数3:指定保存Application历史记录的个数，如果超过这个值，旧的应用程序信息将被删除，这个是内存中的应用数，而不是页面上显示的应用数
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