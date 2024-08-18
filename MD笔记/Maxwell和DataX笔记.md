# 1.Maxwell简介
## 1.概述
    Maxwell会实时监控MySQL数据库的数据变更区别(包括insert,update,delete)，并将变更数据以JSON格式发送给Kafka等流数据处理平台
## 2.Maxwell输出数据格式
| 参数 | 描述 |
| --- | --- |
| database | 变更数据所属的数据库 |
| table | 表更数据所属的表 |
| type | 数据变更类型 |
| ts | 数据变更发生的时间 |
| xid | 事务id |
| commit | 事务提交标志，可用于重新组装事务 |
| data | 对于insert类型，表示插入的数据；对于update类型，标识修改之后的数据；对于delete类型，表示删除的数据 |
| old | 对于update类型，表示修改之前的数据，只包含变更字段 |
    1. 插入
        maxwell输出:
        {
            "database": "gmall",
            "table": "student",
            "type": "insert",
            "ts": 1634004537,
            "xid": 1530970,
            "commit": true,
            "data": {
                "id": 1,
                "name": "zhangsan"
            }
        }
    2. 更新
        maxwell输出:
        {
            "database": "gmall",
            "table": "student",
            "type": "update",
            "ts": 1634004653,
            "xid": 1531916,
            "commit": true,
            "data": {
                "id": 1,
                "name": "lisi"
            },
            "old": {
                "name": "zhangsan"
            }
        }
    3. 删除
        maxwell输出:
        {
            "database": "gmall",
            "table": "student",
            "type": "delete",
            "ts": 1634004751,
            "xid": 1532725,
            "commit": true,
            "data": {
                "id": 1,
                "name": "lisi"
            }
        }
# 2.Maxwell原理
## 1.MySQL二进制日志
    二进制日志(Binlog)是MySQL服务端非常重要的一种日志，它会保存MySQL数据库的所有数据变更记录，Binlog的主要作用包括主从复制和数据恢复，Maxwell的工作原理和主从复制密切相关
## 2.MySQL主从复制
    MySQL的主从复制，就是用来建立一个和主数据库完全一样的数据库环境，这个数据库称为从数据库
    1. 主从复制的应用场景如下:
        1. 做数据库的热备:主数据库服务器故障后，可切换到从数据库继续工作
        2. 读写分离:主数据库只负责业务数据的写入操作，而多个从数据库只负责业务数据的查询工作，在读多写少场景下，可以提高数据库工作效率
    2. 主从复制的工作原理如下:
        1. Master主库将数据变更记录，写到二进制日志(binary log)中
        2. Slave从库向MySQL Master发送dump协议，将Master主库的binary log events拷贝到它的中继日志(relay log)
        3. Slave从库读取并回放中继日志中的事件，将改变的数据同步到自己的数据库
    3. Maxwell原理
        Maxwell的工作原理是将自己伪装成Slave，并遵循MySQL主从复制的协议，实时读取MySQL数据库的二进制日志(Binlog)，从中获取变更数据，再将变更数据以JSON格式发送至Kafka等流处理平台
# 3.Maxwell部署
## 1.启用MySQL Binlog
    MySQL服务器的Binlog默认是未开启的，如需进行同步，需要先进行开启
    修改MySQL配置文件/etc/my.cnf，增加如下配置:
        server-id = 1
            #数据库id
        log-bin=mysql-bin
            #启动binlog，该参数的值会作为binlog的文件名
        binlog_format=row
            #binlog类型，maxwell要求为row类型
        binlog-do-db=gmall
            #启用binlog的数据库，需根据实际情况作出修改
    重启MySQL服务
    MySQL Binlog模式：
    Statement-based
        基于语句，Binlog会记录所有写操作的SQL语句，包括insert、update、delete等
        优点：节省空间
        缺点：有可能造成数据不一致，例如insert语句中包含now()函数
    Row-based
        基于行，Binlog会记录每次写操作后被操作行记录的变化
        优点：保持数据的绝对一致性
        缺点：占用较大空间
    mixed
        混合模式，默认是Statement-based，如果SQL语句可能导致数据不一致，就自动切换到Row-based
    Maxwell要求Binlog采用Row-based模式
## 2.创建Maxwell所需数据库和用户
    Maxwell需要在MySQL中存储其运行过程中的所需的一些数据，包括binlog同步的断点位置(Maxwell支持断点续传)等，故需要在MySQL为Maxwell创建数据库及用户
    1. 创建数据库
        create database maxwell;
    2. 创建Maxwell用户并赋予其必要权限
        create user 'maxwell'@'%' identified by 'maxwell';
        grant all on maxwell.* to 'maxwell'@'%';
        grant select, replication client, replication slave on *.* to 'maxwell'@'%';
## 3.配置Maxwell
    1. 修改Maxwell配置文件名称
        cd /opt/module/maxwell
        cp config.properties.example config.properties
    2. 修改Maxwell配置文件
        producer=kafka
            #Maxwell数据发送目的地，可选配置有stdout|file|kafka|kinesis|pubsub|sqs|rabbitmq|redis
        kafka.bootstrap.servers=hadoop102:9092,hadoop103:9092,hadoop104:9092
            # 目标Kafka集群地址
        kafka_topic=topic_db
            #目标Kafka topic，可静态配置，例如:maxwell，也可动态配置，例如：%{database}_%{table}
        # MySQL相关配置
        host=hadoop102
        user=maxwell
        password=maxwell
        jdbc_options=useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
        filter=exclude:gmall.z_log
            # 过滤gmall中的z_log表数据，该表是日志数据的备份，无须采集
        producer_partition_by=primary_key
            # 指定数据按照主键分组进入Kafka不同分区，避免数据倾斜
# 4.Maxwell使用
## 1.Maxwell启停 
    若Maxwell发送数据的目的地为Kafka集群，则需要先确保Kafka集群为启动状态
    1. 启动Maxwell
        /opt/module/maxwell/bin/maxwell --config /opt/module/maxwell/config.properties --daemon
    2. 停止Maxwell
        ps -ef | grep com.zendesk.maxwell.Maxwell | grep -v grep | awk '{print $2}' | xargs kill -9
    3. Maxwell启停脚本
        #!/bin/bash
        MAXWELL_HOME=/opt/module/maxwell-1.29.2
        status_maxwell(){
            result=`ps -ef | grep com.zendesk.maxwell.Maxwell | grep -v grep | wc -l`
            return $result
        }
        start_maxwell(){
            status_maxwell
            if [[ $? -lt 1 ]];then
                echo "启动Maxwell"
                $MAXWELL_HOME/bin/maxwell --config $MAXWELL_HOME/config.properties --daemon
            else
                echo "Maxwell正在运行"
            fi
        }
        stop_maxwell(){
            status_maxwell
            if [[ $? -gt 0 ]];then
                echo "停止Maxwell"
                ps -ef | grep com.zendesk.maxwell.Maxwell | grep -v grep | awk '{print $2}' | xargs kill -9
            else
                echo "Maxwell未在运行"
            fi
        }
        case $1 in
            start )start_maxwell;;
            stop )stop_maxwell;;
            restart )
                stop_maxwell
                start_maxwell
            ;;
        esac
## 2.历史数据全量同步
    有时可能需要使用到MySQL数据库中从历史至今的一个完整的数据集。这就需要我们在进行增量同步之前，先进行一次历史数据的全量同步
    1. Maxwell-bootstrap
        Maxwell提供了bootstrap功能来进行历史数据的全量同步，命令如下:
        /opt/module/maxwell/bin/maxwell-bootstrap --database gmall --table user_info --config /opt/module/maxwell/config.properties
    2. boostrap数据格式
        采用bootstrap方式同步的输出数据格式如下:
        {
            "database": "fooDB",
            "table": "barTable",
            "type": "bootstrap-start",
            "ts": 1450557744,
            "data": {}
        }
        {
            "database": "fooDB",
            "table": "barTable",
            "type": "bootstrap-insert",
            "ts": 1450557744,
            "data": {
                "txt": "hello"
            }
        }
        {
            "database": "fooDB",
            "table": "barTable",
            "type": "bootstrap-insert",
            "ts": 1450557744,
            "data": {
                "txt": "bootstrap!"
            }
        }
        {
            "database": "fooDB",
            "table": "barTable",
            "type": "bootstrap-complete",
            "ts": 1450557744,
            "data": {}
        }
        注意事项:
        1. 第一条type为bootstrap-start和最后一条type为bootstrap-complete的数据，是bootstrap开始和结束的标志，不包含数据，中间的type为bootstrap-insert的数据才包含数据
        2. 一次bootstrap输出的所有记录的ts都相同，为bootstrap开始的时间
# 5.DataX简介
    DataX是阿里巴巴开源的一个异构数据源离线同步工具，致力于实现包括关系型数据库(MySQL、Oracle等)、HDFS、Hive、ODPS、HBase、FTP等各种异构数据源之间稳定高效的数据同步功能
# 6.DataX架构原理
## 1.DataX设计理念
    为了解决异构数据源同步问题，DataX将复杂的网状的同步链路变成了星型数据链路，DataX作为中间传输载体负责连接各种数据源
    当需要接入一个新的数据源的时候，只需要将此数据源对接到DataX，便能跟已有的数据源做到无缝数据同步
## 2.DataX框架设计
    DataX本身作为离线数据同步框架，采用Framework + plugin架构构建。将数据源读取和写入抽象成为Reader/Writer插件，纳入到整个同步框架中
    Reader:数据采集模块，负责采集数据源的数据，将数据发送给Framework
    Writer:数据写入模块，负责不断从Framework取数据，并将数据写入到目的端
    Framework:用于连接Reader和Writer，作为两者的数据传输通道，并处理缓冲，控流，并发，数据转换等核心技术问题
## 3.DataX运行流程
    Job:单个数据同步的作业，称为一个Job，一个Job启动一个进程
    Task:根据不同的数据源的切分策略，一个Job会切分为多个Task，Task是DataX作业的最小单元，每个Task负责一部分数据的同步工作
    TaskGroup:Scheduler调度模块会对Task进行分组，每个Task组称为一个TaskGroup，每个TaskGroup负责以一定的并发度运行其所分得的Task，单个Task的并发度为5
    Reader->Channel->Writer:每个Task启动后，都会固定启动Reader->Channel->Writer的线程来完成同步工作
## 4.DataX调度决策思路
    举例来说，用户提交了一个DataX作业，并且配置了总的并发度为20，目的是对一个有100张分表的mysql数据源进行同步。DataX的调度决策思路是:
    1. DataX Job根据分库分表切分策略，将同步工作分成100个Task
    2. 根据配置的总的并发度20，以及每个Task Group的并发度5，DataX计算共需要分配4个TaskGroup
    3. 4个TaskGroup平分100个Task，每一个TaskGroup负责运行25个Task
# 7.DataX部署
    1. 下载解压
    2. 自检
        python /opt/module/datax/bin/datax.py /opt/module/datax/job/job.json
        出现如下内容，表示安装成功:
        2022-10-12 21:51:12.335 [job-0] INFO  JobContainer - 
        任务启动时刻                    : 2022-10-12 21:51:02
        任务结束时刻                    : 2022-10-12 21:51:12
        任务总计耗时                    :                 10s
        任务平均流量                    :          253.91KB/s
        记录写入速度                    :          10000rec/s
        读出记录总数                    :              100000
        读写失败总数                    :                   0
# 8.DataX使用
## 1.DataX任务提交命令
    只需根据自己同步数据的数据源和目的地选择相应的Reader和Writer，并将Reader和Writer的信息配置在一个json文件中，然后执行如下命令提交数据同步任务即可:
    python bin/datax.py xxx/job.json
## 2.DataX配置文件格式
    可以使用如下命名查看DataX配置文件模板:
        python /opt/module/datax/bin/datax.py -r mysqlreader -w hdfswriter
    json最外层是一个job，job包含setting和content两部分，其中setting用于对整个job进行配置，content用户配置数据源和目的地
    {
        "job": {
            "content": [
                {
                    "reader": {
                        "name": "mysqlreader", 
                        "parameter": {
                            "column": [], 
                            "connection": [
                                {
                                    "jdbcUrl": [], 
                                    "table": []
                                }
                            ], 
                            "password": "", 
                            "username": "", 
                            "where": ""
                        }
                    }, 
                    "writer": {
                        "name": "hdfswriter", 
                        "parameter": {
                            "column": [], 
                            "compress": "", 
                            "defaultFS": "", 
                            "fieldDelimiter": "", 
                            "fileName": "", 
                            "fileType": "", 
                            "path": "", 
                            "writeMode": ""
                        }
                    }
                }
            ], 
            "setting": {
                "speed": {
                    "channel": ""
                }
            }
        }
    }
## 3.同步MySQL数据到HDFS案例
    同步gmall数据库中base_province表数据到HDFS的/base_province目录
    要实现该功能，需选用MySQLReader和HDFSWriter
    MySQLReader具有两种模式分别是TableMode和QuerySQLMode
    TableMode使用table，column，where等属性声明需要同步的数据
    QuerySQLMode使用一条SQL查询语句声明需要同步的数据
    1. 编写配置文件
        vim /opt/module/datax/job/base_province.json
        {
            "job": {
                "content": [
                    {
                        "reader": {
                            "name": "mysqlreader",
                            "parameter": {
                                "column": [
                                    "id",
                                    "name",
                                    "region_id",
                                    "area_code",
                                    "iso_code",
                                    "iso_3166_2",
                                    "create_time",
                                    "operate_time"
                                ],
                                "where": "id>=3",
                                "connection": [
                                    {
                                        "jdbcUrl": [
                                            "jdbc:mysql://hadoop102:3306/gmall?useUnicode=true&allowPublicKeyRetrieval=true&characterEncoding=utf-8"
                                        ],
                                        "table": [
                                            "base_province"
                                        ]
                                    }
                                ],
                                "password": "000000",
                                "splitPk": "",
                                "username": "root"
                            }
                        },
                        "writer": {
                            "name": "hdfswriter",
                            "parameter": {
                                "column": [
                                    {
                                        "name": "id",
                                        "type": "bigint"
                                    },
                                    {
                                        "name": "name",
                                        "type": "string"
                                    },
                                    {
                                        "name": "region_id",
                                        "type": "string"
                                    },
                                    {
                                        "name": "area_code",
                                        "type": "string"
                                    },
                                    {
                                        "name": "iso_code",
                                        "type": "string"
                                    },
                                    {
                                        "name": "iso_3166_2",
                                        "type": "string"
                                    },
                                    {
                                        "name": "create_time",
                                        "type": "string"
                                    },
                                    {
                                        "name": "operate_time",
                                        "type": "string"
                                    }
                                ],
                                "compress": "gzip",
                                "defaultFS": "hdfs://hadoop102:8020",
                                "fieldDelimiter": "\t",
                                "fileName": "base_province",
                                "fileType": "text",
                                "path": "/base_province",
                                "writeMode": "append"
                            }
                        }
                    }
                ],
                "setting": {
                    "speed": {
                        "channel": 1
                    }
                }
            }
        }
        注意事项:
        HFDS Writer并未提供nullFormat参数：也就是用户并不能自定义null值写到HFDS文件中的存储格式
        默认情况下，HFDS Writer会将null值存储为空字符串('')，而Hive默认的null值存储格式为\N，所以后期将DataX同步的文件导入Hive表就会出现问题
        解决该问题的方案有两个：
        1. 修改DataX HDFS Writer的源码，增加自定义null值存储格式的逻辑，可参考https://blog.csdn.net/u010834071/article/details/105506580
        2. 是在Hive中建表时指定null值存储格式为空字符串（''），例如 NULL DEFINED AS ''
    2. 提交任务
        1. 在HDFS创建/base_province目录
            使用DataX向HDFS同步数据时，需确保目标路径已存在
                hadoop fs -mkdir /base_province
        2. 执行命令
            python /opt/module/datax/bin/datax.py /opt/module/datax/job/base_province.json
## 4.DataX传参
    通常情况下，离线数据同步任务需要每日定时重复执行，故HDFS上的目标路径通常会包含一层日期，以对每日同步的数据加以区分
    也就是说每日同步数据的目标路径不是固定不变的，因此DataX配置文件中HDFS Writer的path参数的值应该是动态的
    为实现这一效果，就需要使用DataX传参的功能
    DataX传参的用法如下，在JSON配置文件中使用${param}引用参数，在提交任务时使用-p"-Dparam=value"传入参数值，具体示例如下:
    1. 编写配置文件
        vim /opt/module/datax/job/base_province.json
        {
            "job": {
                "content": [
                    {
                        "reader": {
                            "name": "mysqlreader",
                            "parameter": {
                                "connection": [
                                    {
                                        "jdbcUrl": [
                                            "jdbc:mysql://hadoop102:3306/gmall?useUnicode=true&allowPublicKeyRetrieval=true&characterEncoding=utf-8"
                                        ],
                                        "querySql": [
                                            "select id,name,region_id,area_code,iso_code,iso_3166_2,create_time,operate_time from base_province where id>=3"
                                        ]
                                    }
                                ],
                                "password": "000000",
                                "username": "root"
                            }
                        },
                        "writer": {
                            "name": "hdfswriter",
                            "parameter": {
                                "column": [
                                    {
                                        "name": "id",
                                        "type": "bigint"
                                    },
                                    {
                                        "name": "name",
                                        "type": "string"
                                    },
                                    {
                                        "name": "region_id",
                                        "type": "string"
                                    },
                                    {
                                        "name": "area_code",
                                        "type": "string"
                                    },
                                    {
                                        "name": "iso_code",
                                        "type": "string"
                                    },
                                    {
                                        "name": "iso_3166_2",
                                        "type": "string"
                                    },
                                    {
                                        "name": "create_time",
                                        "type": "string"
                                    },
                                    {
                                        "name": "operate_time",
                                        "type": "string"
                                    }
                                ],
                                "compress": "gzip",
                                "defaultFS": "hdfs://hadoop102:8020",
                                "fieldDelimiter": "\t",
                                "fileName": "base_province",
                                "fileType": "text",
                                "path": "/base_province/${dt}",
                                "writeMode": "append"
                            }
                        }
                    }
                ],
                "setting": {
                    "speed": {
                        "channel": 1
                    }
                }
            }
        }
    2. 提交任务
        1. 创建目标路径
            hadoop fs -mkdir /base_province/2022-06-08
        2. 执行命令
            python /opt/module/datax/bin/datax.py -p"-Ddt=2022-06-08" /opt/module/datax/job/base_province.json
## 5.同步HDFS数据到MySQL案例
    同步HDFS上的/base_province目录下的数据到MySQL gmall数据库下的test_province表
    1. 编写配置文件
        {
            "job": {
                "content": [
                    {
                        "reader": {
                            "name": "hdfsreader",
                            "parameter": {
                                "defaultFS": "hdfs://hadoop102:8020",
                                "path": "/base_province",
                                "column": [
                                    "*"
                                ],
                                "fileType": "text",
                                "compress": "gzip",
                                "encoding": "UTF-8",
                                "nullFormat": "\\N",
                                "fieldDelimiter": "\t",
                            }
                        },
                        "writer": {
                            "name": "mysqlwriter",
                            "parameter": {
                                "username": "root",
                                "password": "000000",
                                "connection": [
                                    {
                                        "table": [
                                            "test_province"
                                        ],
                                        "jdbcUrl": "jdbc:mysql://hadoop102:3306/gmall?useUnicode=true&allowPublicKeyRetrieval=true&characterEncoding=utf-8"
                                    }
                                ],
                                "column": [
                                    "id",
                                    "name",
                                    "region_id",
                                    "area_code",
                                    "iso_code",
                                    "iso_3166_2",
                                    "create_time",
                                    "operate_time"
                                ],
                                "writeMode": "replace"
                            }
                        }
                    }
                ],
                "setting": {
                    "speed": {
                        "channel": 1
                    }
                }
            }
        }
    2. 提交任务
        1. 在MySQL中创建gmall.test_province表
            DROP TABLE IF EXISTS `test_province`;
            CREATE TABLE `test_province`  (
            `id` bigint(20) NOT NULL,
            `name` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
            `region_id` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
            `area_code` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
            `iso_code` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
            `iso_3166_2` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
            `create_time` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
            `operate_time` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
            PRIMARY KEY (`id`)
            ) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;
        2. 执行命令
            python /opt/module/datax/bin/datax.py /opt/module/datax/job/test_province.json
# 9.DataX优化
## 1.速度控制
    DataX3.0提供了包括通道(并发)、记录流、字节流三种流控模式，可以随意控制你的作业速度，让你的作业在数据库可以承受的范围内达到最佳的同步速度
    关键优化参数如下:
| 参数 | 描述 |
| --- | --- |
| job.setting.speed.channel | 并发数 |
| job.setting.speed.record | 总record限速 |
| job.setting.speed.byte | 总byte限速 |
| core.transport.channel.speed.record | 单个channel的record限速，默认值为10000(10000条/s) |
| core.transport.channel.speed.byte | 单个channel的byte限速，默认值1024*1024(1M/s) |
    注意事项:
    1. 若配置了总record限速，则必须配置单个channel的record限速
    2. 若配置了总byte限速，则必须配置单个channel的byte限速
    3. 若配置了总record限速和总byte限速，channel并发数参数就会失效。因为配置了总record限速和总byte限速之后，实际channel并发数是通过计算得到的
        计算公式为:
            min(总byte限速/单个channel的byte限速，总record限速/单个channel的record限速)
        配置示例：
            {
                "core": {
                    "transport": {
                        "channel": {
                            "speed": {
                                "byte": 1048576 //单个channel byte限速1M/s
                            }
                        }
                    }
                },
                "job": {
                    "setting": {
                        "speed": {
                            "byte" : 5242880 //总byte限速5M/s
                        }
                    },
####### ...
    }
}
## 2.内存调整
    当提升DataX Job内Channel并发数时，内存的占用会显著增加，因为DataX作为数据交换通道，在内存中会缓存较多的数据
    例如Channel中会有一个Buffer，作为临时的数据交换的缓冲区，而在部分Reader和Writer的中，也会存在一些Buffer，为了防止OOM等错误，需调大JVM的堆内存
    建议将内存设置为4G或者8G，这个也可以根据实际情况来调整
    调整JVM xms xmx参数的两种方式:
    1. 直接更改datax.py脚本
    2. 在启动的时候，加上对应的参数，如下:
        python datax/bin/datax.py --jvm="-Xms8G -Xmx8G" xxx/job.json