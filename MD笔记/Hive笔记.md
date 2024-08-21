# 1.hive简介
## 1.hive本质
    hive是基于Hadoop的一个数据仓库工具，可以将结构化的数据文件映射为一张表，并提供类SQL查询功能
    hive是一个hadoop客户端，用于将HQL(hive SQL)转化成MapReduce程序
    1. hive中每张表的数据存储在HDFS
    2. hive分析数据底层的实现是MapReduce(也可配置为Spark或者Tez)
    3. 执行程序运行在Yarn上
## 2.hive架构
    1. 用户接口 Client
        CLI（command-line interface）、JDBC/ODBC
    2. 元数据 Metastore
        元数据包括:数据库(默认是default)、表名、表的拥有者、列/分区字段、表的类型(是否是外部表)、表的数据所在目录等
        默认存储在自带的derby数据库中，由于derby数据库只支持单客户端访问，生产环境中为了多人开发，推荐使用MySQL存储Metastore
    3. 驱动器 Driver
        1. 解析器(SQLParser):将SQL字符串转换成抽象语法树(AST)
        2. 语义分析(Semantic Analyzer):将AST进一步划分为QeuryBlock
        3. 逻辑计划生成器(Logical Plan Gen):将语法树生成逻辑计划
        4. 逻辑优化器(Logical Optimizer):对逻辑计划进行优化
        5. 物理计划生成器(Physical Plan Gen):根据优化后的逻辑计划生成物理计划
        6. 物理优化器(Physical Optimizer):对物理计划进行优化
        7. 执行器(Execution):执行该计划，得到查询结果并返回给客户端
    4. Hadoop
        使用HDFS进行存储，可以选择MapReduce/Tez/Spark进行计算
    5. 架构原理
        1. 用户创建table
        2. Metastore中记录对应表的路径
        3. 映射表关系
        4. 用户根据业务需求编写相应的HQL语句
        5. 经过Driver调用MapReduce进行计算，返回计算结果
## 3.hive安装
    1. 下载hive，解压
    2. 添加环境变量，source更新环境变量
    3. 初始化元数据库
        xxx/hive/bin/schematool -dbType derby -initSchema
    Hive默认使用的元数据库为derby。derby数据库的特点是同一时间只允许一个客户端访问。如果多个Hive客户端同时访问，就会报错
    由于在企业开发中，都是多人协作开发，需要多客户端同时访问Hive，可以将Hive的元数据改为用MySQL存储，MySQL支持多客户端同时访问
## 4.mysql安装
    1. 下载mysql安装包
    2. 卸载系统自带的mariadb
        sudo rpm -qa | grep mariadb | xargs sudo rpm -e --nodeps
    3. 安装mysql依赖
        sudo rpm -ivh mysql-community-common-5.7.28-1.el7.x86_64.rpm
        sudo rpm -ivh mysql-community-libs-5.7.28-1.el7.x86_64.rpm
        sudo rpm -ivh mysql-community-libs-compat-5.7.28-1.el7.x86_64.rpm
    4. 安装mysql-client
        sudo rpm -ivh mysql-community-client-5.7.28-1.el7.x86_64.rpm
    5. 安装mysql-server
        sudo rpm -ivh mysql-community-server-5.7.28-1.el7.x86_64.rpm
## 5.配置mysql
    1. 启动mysql
        sudo systemctl start mysqld
    2. 查看mysql密码
        sudo cat /var/log/mysqld.log | grep password
    3. 进入mysql
        mysql -uroot -p"password"
    4. 设置复杂密码(由于MySQL密码策略，此密码必须足够复杂)
        set password=password("password")
    5. 更改密码策略
        set global validate_password_policy=0
        set global validate_password_length=4
    6. 设置新密码
        set password=password('123456')
    7. 进入mysql库
        use mysql
    8. 查询user表
        select host,user from user
    9. 修改user表，把host内容修改为%
        update user set host='%' where user='root'
    10. 刷新
        flush privileges
    11. 退出
        quit
    12. 若因为安装失败或者其他原因，MySQL需要卸载重装
        1. 清空原有数据
            通过/etc/my.cnf查看MySQL数据的存储位置
                sudo cat /etc/my.cnf
            去往/var/lib/mysql路径需要root权限
                su - root
                cd /var/lib/mysql
                rm -rf *
        2. 卸载MySQL相关包
            查看安装过的MySQL相关包
                sudo rpm -qa | grep -i -E mysql
            一键卸载
                rpm -qa | grep -i -E mysql\|mariadb | xargs -n1 sudo rpm -e --nodeps
## 6.配置hive元数据到mysql
    1. 新建元数据
        mysql -uroot -p
        create database metastore;
        quit;
    2. 将mysql的JDBC驱动拷贝到hive的lib目录下
        cp /opt/software/mysql-connector-java-5.1.37.jar $HIVE_HOME/lib
    3. 在hive/conf目录下新建hive-site.xml文件
        vim $HIVE_HOME/conf/hive-site.xml
        添加如下内容:
        <?xml version="1.0"?>
        <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
        <configuration>
            <!-- jdbc连接的URL -->
            <property>
                <name>javax.jdo.option.ConnectionURL</name>
                <value>jdbc:mysql://hadoop102:3306/metastore?useSSL=false</value>
            </property>
            
            <!-- jdbc连接的Driver-->
            <property>
                <name>javax.jdo.option.ConnectionDriverName</name>
                <value>com.mysql.jdbc.Driver</value>
            </property>
            
            <!-- jdbc连接的username-->
            <property>
                <name>javax.jdo.option.ConnectionUserName</name>
                <value>root</value>
            </property>
            <!-- jdbc连接的password -->
            <property>
                <name>javax.jdo.option.ConnectionPassword</name>
                <value>123456</value>
            </property>
            <!-- hive默认在HDFS的工作目录 -->
            <property>
                <name>hive.metastore.warehouse.dir</name>
                <value>/user/hive/warehouse</value>
            </property>
        </configuration>
    4. 初始化hive元数据库(修改为采用MySQL存储元数据)
        schematool -dbType mysql -initSchema -verbose
    5. 查看mysql中的元数据信息
        use metastore;
        select * from DBS;  #查看元数据库中存储的库信息
        select * from TBLS;  #查看元数据库中存储的表信息
        select * from COLUMNS_V2;  #查看元数据库中存储的表中列相关信息
## 7.hive服务部署
### 1.hiveserver2服务
    hive的hiveserver2服务的作用是提供jdbc/odbc接口，为用户提供远程访问hive数据的功能
    1. 用户说明
        在远程访问Hive数据时，客户端并未直接访问Hadoop集群，而是由Hivesever2代理访问
        具体使用什么身份访问，由Hiveserver2的hive.server2.enable.doAs参数决定，该参数的含义是是否启用Hiveserver2用户模拟的功能
        若启用，则Hiveserver2会模拟成客户端的登录用户去访问Hadoop集群的数据，不启用，则Hivesever2会直接使用启动用户访问Hadoop集群数据。默认是开启的
        生产环境，推荐开启用户模拟功能，因为开启后才能保证各用户之间的权限隔离
        hivesever2的模拟用户功能，依赖于Hadoop提供的proxy user（代理用户功能），只有Hadoop中的代理用户才能模拟其他用户的身份访问Hadoop集群。因此，需要将hiveserver2的启动用户设置为Hadoop的代理用户
    2. hadoop端配置  #修改core-site.xml，分发
        <!--配置所有节点的atguigu用户都可作为代理用户-->
        <property>
            <name>hadoop.proxyuser.atguigu.hosts</name>
            <value>*</value>
        </property>
        <!--配置atguigu用户能够代理的用户组为任意组-->
        <property>
            <name>hadoop.proxyuser.atguigu.groups</name>
            <value>*</value>
        </property>
        <!--配置atguigu用户能够代理的用户为任意用户-->
        <property>
            <name>hadoop.proxyuser.atguigu.users</name>
            <value>*</value>
        </property>
    3. hive端配置  #在hive-site.xml文件中添加如下配置信息
        <!-- 指定hiveserver2连接的host -->
        <property>
            <name>hive.server2.thrift.bind.host</name>
            <value>hadoop102</value>
        </property>
        <!-- 指定hiveserver2连接的端口号 -->
        <property>
            <name>hive.server2.thrift.port</name>
            <value>10000</value>
        </property>
    4. 测试
        1. 启动hiveserver2
            hive --service hiveserver2
        2. 使用命令行客户端beeline进行远程访问
            beeline -u jdbc:hive2://hadoop102:10000 -n atguigu
### 2.metastore服务
    为hive CLI或者hiveserver2提供元数据访问接口，有嵌入式模式和独立服务模式
    1. 嵌入式模式 
        每个hive CLI都需要直接连接元数据库，当hive CLI较多时，数据库压力会比较大
        每个客户端都需要用户元数据库的读写权限，元数据库的安全得不到很好的保证
        嵌入式模式下，只需保证hiveserver2和每个hive CLI的配置文件hive-site.xml中包含连接元数据库所需要的以下参数即可:
        <!-- jdbc连接的URL -->
        <property>
            <name>javax.jdo.option.ConnectionURL</name>
            <value>jdbc:mysql://hadoop102:3306/metastore?useSSL=false</value>
        </property>
        
        <!-- jdbc连接的Driver-->
        <property>
            <name>javax.jdo.option.ConnectionDriverName</name>
            <value>com.mysql.jdbc.Driver</value>
        </property>
        
        <!-- jdbc连接的username-->
        <property>
            <name>javax.jdo.option.ConnectionUserName</name>
            <value>root</value>
        </property>
        <!-- jdbc连接的password -->
        <property>
            <name>javax.jdo.option.ConnectionPassword</name>
            <value>123456</value>
        </property>
    2. 独立服务模式
        每个hive CLI都通过metastore服务连接元数据库
        1. 首先，保证metastore服务的配置文件hive-site.xml中包含连接元数据库所需的以下参数:
            <!-- jdbc连接的URL -->
            <property>
                <name>javax.jdo.option.ConnectionURL</name>
                <value>jdbc:mysql://hadoop102:3306/metastore?useSSL=false</value>
            </property>
            
            <!-- jdbc连接的Driver-->
            <property>
                <name>javax.jdo.option.ConnectionDriverName</name>
                <value>com.mysql.jdbc.Driver</value>
            </property>
            
            <!-- jdbc连接的username-->
            <property>
                <name>javax.jdo.option.ConnectionUserName</name>
                <value>root</value>
            </property>
            <!-- jdbc连接的password -->
            <property>
                <name>javax.jdo.option.ConnectionPassword</name>
                <value>123456</value>
            </property>
        2. 其次，保证hiveserver2和每个hive CLI的配置文件hive-site.xml中包含访问metastore服务所需的以下参数:
            <!-- 指定metastore服务的地址 -->
            <property>
                <name>hive.metastore.uris</name>
                <value>thrift://hadoop102:9083</value>
            </property>
            注意:主机名需要改为metastore服务所在节点，端口号无需修改，metastore服务的默认端口就是9083
        3. 测试
            hive --service metastore  #启动metastore
## 8.hive常用交互命令
    hive -e 'sql语句'  #不进入hive的交互窗口执行hql语句
    hive -f sql文件  #执行脚本中的hql语句
## 9.hive参数配置方式
    1. 在客户端中设置(当前窗口中当次有效)
        hive > set 参数名=参数值
    2. 在启动客户端时设置参数(当前窗口中当次有效)
        hive --hiveconf 参数名=参数值
    3. 在配置文件hive-site.xml中配置(永久有效)
        cd /opt/module/hive/conf
        vim hive-site.xml
        <property>
            <name>mapreduce.job.reduces</name>
            <value>9</value>
        </property>
## 10.常见属性配置
    1. hive客户端显示当前库和表头
        hive-site.xml
        <property>
            <name>hive.cli.print.header</name>
            <value>true</value>
        </property>
        <property>
            <name>hive.cli.print.current.db</name>
            <value>true</value>
        </property>
    2. hive运行日志路径配置
        hive的log默认存放在/tmp/atguigu/hive.log目录下(当前用户名下)
        修改Hive的log存放日志到/opt/module/hive/logs
        1. 修改$HIVE_HOME/conf/hive-log4j2.properties.template文件名称为hive-log4j2.properties
        2. 在hive-log4j2.properties文件中修改log存放位置
            property.hive.log.dir=/opt/module/hive/logs
    3. hive的JVM堆内存设置
        新版本的hive启动的时候，默认申请的JVM堆内存大小为256M，JVM堆内存申请的太小，导致后期开启本地模式，执行复杂的SQL时经常会报错:java.lang.OutOfMemoryError: Java heap space，因此最好提前调整一下HADOOP_HEAPSIZE这个参数
        1. 修改$HIVE_HOME/conf下的hive-env.sh.template为hive-env.sh
        2. 将hive-env.sh其中的参数 export HADOOP_HEAPSIZE 修改为2048，重启hive
    4. 关闭Hadoop虚拟内存检查
        yarn-site.xml添加如下配置
        <property>
            <name>yarn.nodemanager.vmem-check-enabled</name>
            <value>false</value>
        </property>
    5. 开启本地模式
        set hive.exec.mode.local.auto=true;
    6. 单个MR的中间结果进行压缩
        单个MR的中间结果是指Mapper输出的数据，对其进行压缩可降低shuffle阶段的网络IO，可通过以下参数进行配置:
        set mapreduce.map.output.compress=true;
            开启MapReduce中间数据压缩功能
        set mapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.SnappyCodec;
            设置MapReduce中间数据数据的压缩方式为Snappy
    7. 单条SQL语句的中间结果进行压缩
        单条SQL语句的中间结果是指，两个MR(一条SQL语句可能需要通过MR进行计算)之间的临时数据，可通过以下参数进行配置:
        set hive.exec.compress.intermediate=true;
            是否对两个MR之间的临时数据进行压缩
        set hive.intermediate.compression.codec= org.apache.hadoop.io.compress.SnappyCodec;
            设置压缩方式为Snappy
## 11.hive启停脚本
    #!/bin/bash
    HIVE_LOG_DIR=$HIVE_HOME/logs
    if [ ! -d $HIVE_LOG_DIR ]
    then
        mkdir -p $HIVE_LOG_DIR
    fi
    #检查进程是否运行正常，参数1为进程名，参数2为进程端口
    function check_process(){
        pid=$(ps -ef 2>/dev/null | grep -v grep | grep -i $1 | awk '{print $2}')
        ppid=$(netstat -nltp 2>/dev/null | grep $2 | awk '{print $7}' | cut -d '/' -f 1)
        echo $pid
        [[ "$pid" =~ "$ppid" ]] && [ "$ppid" ] && return 0 || return 1
    }
    function hive_start(){
        metapid=$(check_process HiveMetastore 9083)
        cmd="nohup hive --service metastore >$HIVE_LOG_DIR/metastore.log 2>&1 &"
        [ -z "$metapid" ] && eval $cmd || echo "Metastroe服务已启动"
        server2pid=$(check_process HiveServer2 10000)
        cmd="nohup hive --service hiveserver2 >$HIVE_LOG_DIR/hiveServer2.log 2>&1 &"
        [ -z "$server2pid" ] && eval $cmd || echo "HiveServer2服务已启动"
    }
    function hive_stop(){
        metapid=$(check_process HiveMetastore 9083)
        [ "$metapid" ] && kill $metapid || echo "Metastore服务未启动"
        server2pid=$(check_process HiveServer2 10000)
        [ "$server2pid" ] && kill $server2pid || echo "HiveServer2服务未启动"
    }
    case $1 in
    "start")hive_start;;
    "stop")hive_stop;;
    "restart")
        hive_stop
        sleep 2
        hive_start
        ;;
    "status")
        check_process HiveMetastore 9083 >/dev/null && echo "Metastore服务运行正常" || echo "Metastore服务运行异常"
        check_process HiveServer2 10000 >/dev/null && echo "HiveServer2服务运行正常" || echo "HiveServer2服务运行异常"
        ;;
    *)
        echo Invalid Args!
        echo 'Usage: '$(basename $0)' start|stop|restart|status'
        ;;
    esac
# 2.库操作
## 1.建库语句格式
    create database [if not exists] 库名
    [comment 注释]
    [location hdfs对应路径]  #默认路径为/user/hive/warehouse
    [with dbproperties('属性名'='属性值',...)]  #给库设置属性
## 2.案例
    create database d1
    comment 'this is d1'
    location '/demo/d1'
    with dbproperties('ver'='1.0');
    #注意:库名和HDFS上对应的目录名可以不一致(对应关系元数据记录了)
    create database d2
    comment 'this is d1'
    location '/demo/d2222'
    with dbproperties('ver'='1.0');
## 3.库操作
    1. 查看库的信息
        desc database [extended] 库名  #[extended]加上后可以查看库的属性
    2. 查询数据库
        show databases [like '匹配规则']  #like 模糊查询 只能用 *、| 匹配
    3. 删除数据库
        drop database [if exists] 库名 [restrict|cascade]
        #默认为restrict只能删除空库，cascade用来删除非空的库
    4. 切换库
        use 库名
    5. 修改库
        1. 修改库的属性
            alter database 库名 set dbproperties('属性名'='属性值',...)
        2. 修改location
            alter database 库名 set location hdfs绝对路径('hdfs://hadoop102:8020/user...')
        3. 修改owner user
            alter database 库名 set owner user 用户名
# 3.表操作
## 1.建表语句格式
    create [temporary] [external] table [if not exists] [库名.]表名
    [(
        字段名 字段类型 [comment 字段描述信息，注释],...
    )]
    [comment 表的描述信息，注释]
    [partitioned by (字段名 字段类型 [comment 字段描述信息，注释],...)]  #创建分区表
    [clustered by (分桶字段名1,分桶字段名2,...)]  #创建分桶表
    [row format row_format]  #用来对数据和元数据的匹配进行说明
    [stored as file_format]  #数据的存储格式，默认是textfile
    [location 路径]  #创建库和表在hdfs上对应的路径
    [tblproperties ('属性名'='属性值',...)]
## 2.关键字说明
### 1.temporary 临时表
    该表只在当前会话可见，会话结束，表会被删除
### 2.external 外部表
    外部表，与之相对应的是内部表(管理表)
    管理表意味着Hive会完全接管该表，包括元数据和HDFS中的数据。而外部表则意味着Hive只接管元数据，而不完全接管HDFS中的数据
    删除管理表时会将元数据和HDFS上的数据全部删除掉
    删除外部表时只会删除元数据
    truncate table时只能清空管理表，清空外部表时会报错
    外部表和管理表的转换:
        desc formatted 表名  #查看表信息
        alter table 表名 set tblproperties('EXTERNAL'='TRUE/FALSE')  #通过修改表的属性修改表的类型
### 3.数据类型
| 参数 | 描述 |
| --- | --- |
| tinyint   | 1byte，有符号整数
| smallint  | 2byte，有符号整数
| int       | 4byte，有符号整数
| bigint    | 8byte，有符号整数
| boolean   | 布尔类型，true或者false
| float     | 单精度浮点数
| double    | 双精度浮点数
| decimal   | 十进制精准数字类型，decimal(16,2)
| varchar   | 字符序列，需指定最大长度，最大长度的范围是[1,65535]，varchar(32)
| string    | 字符串，无需指定最大长度
| timestamp | 时间类型
| binary    | 二进制数据
| array     | 数组是一组相同类型的值的集合，array<string>，arr[0]
| map       | map是一组相同类型的键-值对集合，map<string,int>，map['key']
| struct    | 结构体由多个属性组成，每个属性都有自己的属性名和数据类型，struct\<id:int,name:string>，struct.id
    数据类型转换:
    1. 隐式类型转换
        任何整数类型都可以隐式地转换为一个范围更广的类型，如tinyint可以转换成int，int可以转换成bigint
        所有整数类型、float和string类型都可以隐式地转换成double
        tinyint、smallint、int都可以转换为float
        boolean类型不可以转换为任何其它的类型
    2. 显式类型转换
        cast('1' as int)
### 4.partitioned by 分区表(分目录)
    1. 查看分区
        show partitions 表名
    2. 添加分区
        alter table 表名 add partition(分区字段名='分区值') partition(分区字段名='分区值')...
        alter table dept_partition add partition(day='20221010')
        alter table dept_partition add partition(day='20221011') partition(day='20221012')
    3. 删除分区
        alter table 表名 drop partition(分区字段名='分区值'),partition(分区字段名='分区值')...
        alter table dept_partition drop partition(day='20221011'),partition(day='20221012')
    4. 导数据
        load data [local] inpath '数据的地址' [overwrite] into table 表名 partition(分区字段名='分区值')
        load data local inpath '/opt/module/hive/datas/20221010.txt' into table dept_partition partition(day='20221010')
        #如果导数据时没有对应的分区那么会自动创建
    5. 同步hdfs与元数据分区信息
        1. 增加hdfs路径存在但元数据缺失的分区信息(有目录但是没有对应的元数据)
            msck repair table 表名 add partitions
        2. 删除hdfs路径已经删除但元数据仍然存在的分区信息(有元数据但是没有对应的目录)
            msck repair table 表名 drop partitions
        3. 该命令会同步hdfs路径和元数据分区信息，相当于同时执行上述的两个命令
            msck repair table 表名 sync partitions
    6. 分区表-二级分区
        1. 创建表
            create table dept_partition2
            (
                deptno  int,
                dname   string,
                loc     string
            )
            partitioned by (day string, hour string)
            row format delimited fields terminated by '\t';
        2. 添加分区
            alter table 表名 add partition(分区字段名1='值',分区字段名2=‘值’) partition(分区字段名1='值',分区字段名2=‘值’)...
        3. 导数据
            load data [local] inpath '数据的地址' [overwrite] into table 表名 partition(分区字段名1='值',分区字段名2=‘值’)
            load data local inpath '/opt/module/hive/datas/20221010.txt' into table dept_partition2 partition(day='20221010',hour='01')
    7. 动态分区
        将非分区表变成分区表，本身表不能改
        1. 创建分区表
            create table dept_partition_dynamic
            (
                id int,
                name string
            )
            partitioned by (loc int)
            row format delimited fields terminated by '\t';
        2. 设置成非严格模式
            set hive.exec.dynamic.partition.mode=nonstrict;
        3. 将查询的结果插入到分区表中
            insert into table dept_partition_dynamic
            partition(loc)  #指定分区字段
            select
                deptno,
                dname,
                loc
            from dept;
### 5.clustered by ... sorted by ... into ... buckets 分桶表(分文件)
    1. 创建分桶表
        create table stu_buck_sort
        (
            id int,
            name string
        )
        clustered by(id)  #指定分桶字段(会对该字段的值的 hashCode值 % 桶的数量 进行分桶)
        sorted by (id)  #分桶时对数据进行排序,按照id升序
        into 4 buckets  #桶的数量(分几个文件)
        row format delimited fields terminated by '\t';
    2. 向分桶表中导入数据
        insert / load
        #向分桶表中导入的数据(load data方式)必须放在HDFS上
        load data inpath '/demo/datas2/student2.txt' into table stu_buck;
### 6.row format 数据匹配
    指定serde，serde是Serializer and Deserializer的简写。hive使用serde序列化和反序列化每行数据
    1. delimited
        表示对文件中的每个字段按照特定分割符进行分割，其会使用默认的serde对每行数据进行序列化和反序列化
        row format delimited
        [fields terminated by 分隔字符]  #每个字段用什么分隔
        [collection items terminated by 分隔字符]  #复杂数据类型中的元素之间用什么分隔
        [map keys terminated by 分隔字符]  #map中的元素的key和value用什么分隔
        [lines terminated by 分隔字符]  #每条数据之间用什么分隔
        [null defined as 字符]  #表中的null值在HDFS上的文件中用什么字符表示，默认\N
        案例:
        create table stu
        (
        name string,
        friends array<string>,
        students map<string,int>,
        address struct<street:string,city:string,postal_code:int>
        )
        row format delimited
        fields terminated by ','
        collection items terminated by '-'
        map keys terminated by ':';
    2. serde
        指定其他内置的serde或者用户自定义的serde。例如JSON serde，可用于处理JSON字符串
        row format serde SERDE名 [with serdeproperties (property_name=property_value,property_name=property_value,...)]
        案例:
        create table stu2
        (
        name string,
        friends array<string>,
        students map<string,int>,
        address struct<street:string,city:string,postal_code:int>
        )
        row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe';
### 7.stored as 数据的存储格式
    默认是textfile，还有sequence file，orc file、parquet file等
    1. textfile
        1. 创建表
            create table textfile_table
            (
                id int,
                name string
            )
            row format delimited fields terminated by '\t'
            stored as textfile;  #指定存储格式
            [set hive.exec.compress.output=true;  #SQL语句的最终输出结果是否压缩
            set mapreduce.output.fileoutputformat.compress.codec =org.apache.hadoop.io.compress.SnappyCodec;  #输出结果的压缩格式]
        2. 导入数据
            load data local inpath '/opt/module/hive/datas/student2.txt' into table textfile_table;
    2. orc(列存储)
        1. 创建表
            create table orc_table
            (
                id int,
                name string
            )
            row format delimited fields terminated by '\t'
            stored as orc  #指定存储格式
            tblproperties ("orc.compress"="none");  #不开启压缩
            / tblproperties ("orc.compress"="snappy");  #开启压缩
        2. 导入数据，只能通过insert
            insert into table orc_table select * from textfile_table;
    3. parquet(列存储)
        1. 创建表
            create table parquet_table
            (
                id int,
                name string
            )
            row format delimited fields terminated by '\t'
            stored as parquet;  #指定存储格式
            [tblproperties ("parquet.compression"="snappy");  #开启压缩]
        2. 导入数据，只能通过insert
            insert into table parquet_table select * from textfile_table;
### 8.location 数据的存储路径
    创建库和表在hdfs上对应的路径，若不指定路径，其默认值为${hive.metastore.warehouse.dir}/db_name.db/table_name
### 9.tblproperties 表的键值对参数
## 2.特殊建表
### 1.将查询的结果创建成一张表
    create table 表名
    as
    select .....
### 2.基于现有的表创建一张新表(没有数据只有表结构)
    create table 新表的表名 like 存在的表的表名;
## 3.表操作
### 1.查看表
    show tables [in 库名] like ['匹配规则'](可使用 *、|)
### 2.查看表信息
    desc(describe) [ectended | formatted] [库名.]表名
    #desc 表名  #查看字段信息
    #desc formatted 表名  #查看表的详细信息
    #desc ectended 表名  #查看表的详细信息但是显示的内容没有格式化
### 3.修改表名
    alter table 原表名 rename to 新表名
### 4.列操作
    1. 添加列
        alter table 表名 add columns (字段名 字段类型 [comment 注释],...)
    2. 更新列-更新列的名字
        alter table 表名 change [column] 原字段名 新字段名 字段类型 [comment 注释]
    3. 更新列-更新列的类型
        alter table 表名 change [column] 字段名 字段名 字段新类型 [commnet 注释]
        #注意字段的类型是否可以转。比如int可以转string，但string不能转int
    4. 更新列-调字段的位置
        alter table 表名 change [column] 字段名 字段名 字段新类型 [comment 注释] [first | after 字段名]
        1. 在交换位置时只能交换元数据，数据不会交换
        2. 注意数据类型
    5. 替换列
        alter table 表名 replace columns (字段名 字段类型 [comment 注释],...)
        1. 替换是依次替换
        2. 替换时一定要注意字段的类型
        3. 如果替换的字段的数量少于原数量，直接缺少该字段
### 5.删除表
    drop table 表名
### 6.清空表
    truncate table 表名  #不能清空外部表
### 7.导入导出数据
    1. load从文件中导入数据
        load data [local] inpath '文件路径' [overwrite] into table 表名
        [partiton (partcol1=val1,partcol2=val2,...)];
        #local 从本地拷贝数据，没有该字段则从hdfs上剪切数据
        #overwrite 覆盖表中原本数据，没有该字段则追加
    2. insert导入数据
        1. 从其他表导入
            insert into/overwrite table 表名[(字段1,字段2,...)]
            [partition (partcol1=val1,partcol2=val2,...)]
            select 查询语句;
            #into追加  表名后不指定字段则表示插入全字段，查询的字段和被插入的字段的个数和类型要保持一致
            #overwrite覆盖  表名后不能写字段名，要求必须全字段，表的字段和查询字段类型要一致
        2. 插入新数据
            insert into table 表名(字段名1,字段名2,...)
            [partition (partcol1=val1,partcol2=val2,...)]
            values(值1,值2),...;
    3. insert导出数据
        insert overwrite [local] directory 路径
        [row format row_format]
        [stored as 文件格式]
        select 查询语句;
    4. export导出数据到hdfs
        export table 表名 to 'hdfs路径'
    5. import从hdfs导入数据
        import [external] table 新表名 from 'hdfs路径' [location 'hdfs绝对路径'('hdfs://hadoop102:8020/...')]
        #只能导入到不存在的表，只能创建新表
        #导入的数据只能是通过export导出的数据，因为这个数据中才有元数据
# 4.表查询
## 1.基本查询
    select [all | distinct]
        *,
        字段名1 [as `别名`],
        字段名2 [`别名`],...
    from 表名
    [where 过滤条件]
    [group by 字段名]
    [having 过滤条件]
    [order by 字段名1 asc/desc,字段名2 asc/desc]  #排序，默认asc升序，desc降序
    [cluster by col_list
        [distribute by col_list] [sort by col_list]
    ]
    [limit num1,num2]  #从第num1行开始，向下抓取num2行
    #null与任何类型数据计算结果都为null
## 2.where及having关系运算符
    1. =
    2. <>，!  #不等于
    3. <=>  #都为null或都不为null，则返回true，如果只有一边为null，返回false
    4. in(值1,值2)
    5. [not] between 值1 and 值2
    6. is null / is not null
    7. and / or / not
    8. like '要匹配的字符串'
        1. %  #代表任意长度的字符串
        2. _  #代表1个字符
        3. \  #代表转义字符
        4. like 字符串 escape 字符  #使用指定字符代替转义字符
    9. A rlike B, A regexp B  #B是基于java的正则表达式，如果A与其匹配，则返回true；反之返回false
## 3.分组聚合函数
    count(*)  #表示统计所有行数，包含null值
    count(某列)  #表示该列一共有多少行，不包含null值
    max()  #求最大值，不包含null，除非所有值都是null
    min()  #求最小值，不包含null，除非所有值都是null
    sum()  #求和，不包含null
    avg()  #求平均值，不包含null
## 4.join,union拼接
    Hive支持通常的sql join语句，但是只支持等值连接，不支持非等值连接
    1. join 内连接
        只有进行连接的两个表中都存在与连接条件相匹配的数据才会被保留下来
    2. left join 左外连接
        join操作符左边表中符合where子句的所有记录将会被返回
    3. right join 右外连接
        join操作符右边表中符合where子句的所有记录将会被返回
    4. full join 满外连接
        将会返回所有表中符合where语句条件的所有记录。如果任一表的指定字段没有符合条件的值的话，那么就使用null值替代
    5. 笛卡尔积
        笛卡尔积会在下面条件下产生：
        1. 省略连接条件
        2. 连接条件无效
        3. 所有表中的所有行互相连接
    6. union 联合
        上下拼接，去重
        union all  #上下拼接，不去重
        两个sql的结果，列的个数必须相同
        两个sql的结果，上下所对应列的类型必须一致
## 5.单行函数
    show functions  #查看系统内置函数
    desc function 函数名  #查看内置函数用法
    desc function extended 函数名  #查看内置函数详细信息
### 1.数值函数
    round  #四舍五入
    ceil  #向上取整
    floor  #向下取整
### 2.字符串函数
    1. substring 截取字符串
        substring(string A, int start, [int len])
            #返回字符串A从start位置开始，长度为len的字符串，没有len则截取到结尾
    2. replace 替换
        replace(string A, string B, string C)
            #将字符串A中的子字符串B替换为C
    3. regexp_replace 正则替换
        regexp_replace(string A, string B, string C)
            #将字符串A中的符合java正则表达式B的部分替换为C。注意，在有些情况下要使用转义字符
    4. regexp 正则匹配
        select A regexp B
            #若字符串符A合正则表达式B，则返回true，否则返回false
    5. repeat 重复字符串
        repeat(string A, int n)
            #将字符串A重复n遍
    6. split 字符串切割
        split(string str, string pat) 
            #按照正则表达式pat匹配到的内容分割str，分割后的字符串，以数组的形式返回
    7. nvl 替换null
        nvl(A, B)
    8. concat 拼接字符串
        concat(string A, string B, string C) 
            #将A,B,C等字符拼接为一个字符串
    9. concat_ws 以指定分隔符拼接字符串或者字符串数组
        concat_ws(string A, string B,...| array(string))
            #使用分隔符A拼接多个字符串，或者一个数组的所有元素
    10. get_json_object 解析json字符串
        get_json_object(string json_string, string path)
            #解析json的字符串json_string，返回path指定的内容。如果输入的json字符串无效，那么返回NULL
        get_json_object('[{"name":"A","age":"25"},{"name":"B","age":"47"}]','$.[0].name');
### 2.日期函数
    1. unix_timestamp 返回当前或指定时间的时间戳
        select unix_timestamp('2022/08/08 08-08-08','yyyy/MM/dd HH-mm-ss');
    2. from_unixtime 转化UNIX时间戳（从 1970-01-01 00:00:00 UTC 到指定时间的秒数）到当前时区的时间格式
        select from_unixtime(1659946088);
    3. current_date 当前日期
    4. current_timestamp 当前的日期加时间，并且精确到毫秒
    5. month 获取日期中的月
        select month('2022-08-08 08:08:08');
    6. day 获取日期中的日
        select day('2022-08-08 08:08:08');
    7. hour 获取日期中的小时
        select hour('2022-08-08 08:08:08');
    8. datediff 两个日期相差的天数(左减右)
        select datediff('2021-08-08','2022-10-09');
    9. date_add 日期增加指定天数
        select date_add('2022-08-08',2);
    10. date_sub 日期减去指定天数
        select date_sub('2022-08-08',2);
    11. date_format 将标准日期解析成指定格式字符串
        select date_format('2022-08-08','yyyy年-MM月-dd日');
    12. date 获取年月日
### 3.流程控制函数
    1. case when 条件判断函数
        1. case
            when 表达式1 then 返回值1
            when 表达式2 then 返回值2
            when 表达式3 then 返回值3
            else 返回值4
        end;
        2. case 字段名
            when 值1 then 返回值1
            when 值2 then 返回值2
            when 值3 then 返回值3
            else 返回值4
        end;
    2. if函数
        if(boolean testCondition, T valueTrue, T valueFalseOrNull)
        select if(10 > 5,true,false);
### 4.集合函数
    1. array  #array(val1, val2,...) 
        select array('1','2','3','4');
    2. array_contains  #判断array中是否包含某个元素
        select array_contains(array('a','b','c','d'),'a');
    3. sort_array  #将array中的元素排序
        select sort_array(array('a','d','c'));
    4. size  #集合中元素的个数
        select size(friends) from test;  #每一行数据中的friends集合里的个数
    5. map  #map (key1, value1, key2, value2,...)
        select map('jia',1,'yi',2);
    6. map_keys  #返回map中的key
        select map_keys(map('jia',1,'yi',2));
    7. map_values  #返回map中的value
        select map_values(map('jia',1,'yi',2));
    8. struct  #声明struct中的各属性  struct(val1, val2, val3,...) 
        select struct('name','age','weight');
        输出:{"col1":"name","col2":"age","col3":"weight"}
    9. named_struct  #声明struct的属性和值
        select named_struct('name','jia','age',18,'weight',80);
        输出:{"name":"jia","age":18,"weight":80}
### 5.高级聚合函数
    1. collect_list  #收集并形成list
    2. collect_set  #收集并形成set，去重
## 6.高级函数
### 1.炸裂函数
    1. 格式
        select 表1字段名,字段名2
        from 表1
        lateral view explode(xx) 表2 as 字段名2
    2. 案例
        select name,explode_friends
        from employee
        lateral view explode(friends) lv as explode_friends
### 2.窗口函数
    1. over窗口
        over(分区(分组)  排序  范围)
        # rows between () and ()   #按行确定范围
        # range between () and ()  #按值确定范围 按order后的值取
        # unbounded preceding      #上无边界
        # unbounded following      #下无边界
        # n preceding              #上n行
        # n following              #下n行
        # current row              #当前行
        1. select user_name,count(*) over()  #对窗口中的数据进行count
            from order_info；
        2. select *,
                sum(order_amount) over(partition by user_name order by order_date rows between unbounded preceding and current row )
            from order_info;
    2. 取上1行与下1行
        lag(字段名,n,默认值)  #当前行的前n行的字段值 如果没有用默认值
        lead(字段名,n,默认值)  #当前行的后n行的字段值 如果没有用默认值
        注意:不支持自定义窗口范围，只可以写上无边界到下无边界
        1. select *,
                lag(order_amount, 1, 0) over (partition by user_name order by order_date),
                lead(order_amount, 1, 0) over (partition by user_name order by order_date)
            from order_info
    3. 取第1个与最后1个
        first_value(字段名,true/false)  #获取窗口中的第一条数据
            #true/false  #如果第一条数据为null是否获取null值
        last_value(字段名,true/false)  #获取窗口中的最后一条数据
            #true/false  #如果最后一条数据为null是否获取null值
        1. select *,
                first_value(order_date,false) over(partition by user_name order by order_date
                    rows between unbounded preceding and unbounded following),
                last_value(order_date,false) over(partition by user_name order by order_date
                    rows between unbounded preceding and unbounded following)
            from order_info;
    4. 排名
        rank()  #排名不一定连续
        dense_rank()  #排名连续
        row_number()  #行号
        注意:不支持自定义窗口
        1. select *,
                rank() over (order by order_amount desc),
                dense_rank() over (order by order_amount desc),
                row_number() over (order by order_amount desc)
            from order_info;
# 5.hive调优
## 1.Explain查看执行计划
    1. Explain执行计划概述
        Explain呈现的执行计划，由一系列Stage组成，这一系列Stage具有依赖关系，每个Stage对应一个MapReduce Job，或者一个文件系统操作等。若某个Stage对应的一个MapReduce Job，其Map端和Reduce端的计算逻辑分别由Map Operator Tree和Reduce Operator Tree进行描述，Operator Tree由一系列的Operator组成，一个Operator代表在Map或Reduce阶段的一个单一的逻辑操作，例如TableScan Operator，Select Operator，Join Operator等
        常见的Operator及其作用如下:
| 参数 | 描述 |
| --- | --- |
| TableScan              | 表扫描操作，通常map端第一个操作肯定是表扫描操作
| Select Operator        | 选取操作
| Group By Operator      | 分组聚合操作
| Reduce Output Operator | 输出到 reduce 操作
| Filter Operator        | 过滤操作
| Join Operator          | join 操作
| File Output Operator   | 文件输出操作
| Fetch Operator         | 客户端获取数据操作
    2. Explain基本语法
        explain [ formatted | extended | dependency ]
        sql语句;
        formatted:将执行计划以JSON字符串的形式输出
        extended:输出执行计划中的额外信息，通常是读写的文件名等信息
        dependency:输出执行计划读取的表及分区
## 2.分组聚合优化
    hive对分组聚合的优化主要围绕着减少Shuffle数据量进行，具体做法是Map-Side聚合
    所谓Map-Side聚合，就是在map端维护一个hash table，利用其完成部分的聚合，然后将部分聚合的结果，按照分组字段分区，发送至reduce端，完成最终的聚合
    Map-Side聚合能有效减少shuffle的数据量，提高分组聚合运算的效率
    1. set hive.map.aggr=true;
        启用Map-Side聚合
    2. set hive.map.aggr.hash.min.reduction=0.5;
        用于检测源表数据是否适合进行Map-Side聚合。检测的方法是:先对若干条数据进行Map-Side聚合，若聚合后的条数和聚合前的条数比值小于该值，则认为该表适合进行Map-Side聚合；否则，认为该表数据不适合进行Map-Side聚合，后续数据便不再进行Map-Side聚合
    3. set hive.groupby.mapaggr.checkinterval=100000;
        用于检测源表是否适合Map-Side聚合的条数
    4. set hive.map.aggr.hash.force.flush.memory.threshold=0.9;
        Map-Side聚合所用的hash table，占用map task堆内存的最大比例，若超出该值，则会对hash table进行一次flush
## 3.Join优化
### 1.Common Join
    是Hive中最稳定的join算法，其通过一个MapReduce Job完成一个join操作
    Map端负责读取join操作所需表的数据，并按照关联字段进行分区，通过Shuffle，将其发送到Reduce端，相同key的数据在Reduce端完成最终的Join操作
    sql语句中的join操作和执行计划中的Common Join任务并非一对一的关系，一个sql语句中的相邻的且关联字段相同的多个join操作可以合并为一个Common Join任务
### 2.Map Join
    可以通过两个只有map阶段的Job完成一个join操作。其适用场景为大表join小表
    若某join操作满足要求，则第一个Job会读取小表数据，将其制作为hash table，并上传至Hadoop分布式缓存(本质上是上传至HDFS)
    第二个Job会先从分布式缓存中读取小表数据，并缓存在Map Task的内存中，然后扫描大表数据，这样在map端即可完成关联操作
    Map Join设置:
    1. set hive.auto.convert.join=true;
        启动Map Join自动转换
    2. set hive.mapjoin.smalltable.filesize=250000;
        一个Common Join operator转为Map Join operator的判断条件
        若该Common Join相关的表中,存在n-1张表的已知大小总和<=该值,则生成一个Map Join计划
        此时可能存在多种n-1张表的组合均满足该条件,则hive会为每种满足条件的组合均生成一个Map Join计划,同时还会保留原有的Common Join计划作为后备(back up)计划
        实际运行时,优先执行Map Join计划，若不能执行成功，则启动Common Join后备计划
    3. set hive.auto.convert.join.noconditionaltask=true;
        开启无条件转Map Join
    4. set hive.auto.convert.join.noconditionaltask.size=10000000;
        无条件转Map Join时的小表之和阈值
        若一个Common Join operator相关的表中，存在n-1张表的大小总和<=该值,此时hive便不会再为每种n-1张表的组合均生成Map Join计划,同时也不会保留Common Join作为后备计划。而是只生成一个最优的Map Join计划
### 3.Bucket Map Join
    是对Map Join算法的改进，其打破了Map Join只适用于大表join小表的限制，可用于大表join大表的场景
    Bucket Map Join的核心思想是:
    若能保证参与join的表均为分桶表
    且关联字段为分桶字段
    且其中一张表的分桶数量是另外一张表分桶数量的整数倍
    就能保证参与join的两张表的分桶之间具有明确的关联关系，所以就可以在两表的分桶间进行Map Join操作了
    这样一来，第二个Job的Map端就无需再缓存小表的全表数据了，而只需缓存其所需的分桶即可
    Bucket Map Join设置
    1. Hint提示
        select /*+ mapjoin(ta) */
            ta.id,
            tb.id
        from table_a ta
        join table_b tb on ta.id=tb.id;
    2. set hive.cbo.enable=false;
        关闭cbo优化，cbo会导致hint信息被忽略
    3. set hive.ignore.mapjoin.hint=false;
        map join hint默认会被忽略(因为已经过时)，需将如下参数设置为false
    4. set hive.optimize.bucketmapjoin = true;
        启用bucket map join优化功能
### 4.Sort Merge Bucket Map Join
    基于Bucket Map Join，SMB Map Join要求:
    参与join的表均为分桶表
    且需保证分桶内的数据是有序的
    且分桶字段、排序字段和关联字段为相同字段
    且其中一张表的分桶数量是另外一张表分桶数量的整数倍
    SMB Map Join同Bucket Join一样，同样是利用两表各分桶之间的关联关系，在分桶之间进行join操作
    不同的是分桶之间的join操作的实现原理:
    Bucket Map Join，两个分桶之间的join实现原理为Hash Join算法
    而SMB Map Join，两个分桶之间的join实现原理为Sort Merge Join算法
    Hash Join和Sort Merge Join均为关系型数据库中常见的Join实现算法
    Hash Join的原理相对简单，就是对参与join的一张表构建hash table，然后扫描另外一张表，然后进行逐行匹配
    Sort Merge Join需要在两张按照关联字段排好序的表中进行
    SMB Map Join与Bucket Map Join相比，在进行Join操作时，Map端是无需对整个Bucket构建hash table，也无需在Map端缓存整个Bucket数据的，每个Mapper只需按顺序逐个key读取两个分桶的数据进行join即可
    Sort Merge Bucket Map Join设置:
    1. set hive.optimize.bucketmapjoin.sortedmerge=true;
        启动Sort Merge Bucket Map Join优化
    2. set hive.auto.convert.sortmerge.join=true;
        使用自动转换SMB Join
## 4.数据倾斜
    数据倾斜问题，通常是指参与计算的数据分布不均，即某个key或者某些key的数据量远超其他key，导致在shuffle阶段，大量相同key的数据被发往同一个Reduce，进而导致该Reduce所需的时间远超其他Reduce，成为整个任务的瓶颈
    hive中的数据倾斜常出现在分组聚合和join操作的场景中
### 1.分组聚合导致的数据倾斜
#### 1.Map-Side聚合
    开启Map-Side聚合后，数据会先在Map端完成部分聚合工作
    这样一来即便原始数据是倾斜的，经过Map端的初步聚合后，发往Reduce的数据也就不再倾斜了
    最佳状态下，Map端聚合能完全屏蔽数据倾斜问题
    1. set hive.map.aggr=true;
        启用Map-Side聚合
    2. set hive.map.aggr.hash.min.reduction=0.5;
        用于检测源表数据是否适合进行Map-Side聚合
        检测的方法是:先对若干条数据进行Map-Side聚合，若聚合后的条数和聚合前的条数比值小于该值，则认为该表适合进行Map-Side聚合；否则，认为该表数据不适合进行Map-Side聚合，后续数据便不再进行Map-Side聚合
    3. set hive.groupby.mapaggr.checkinterval=100000;
        用于检测源表是否适合Map-Side聚合的条数
    4. set hive.map.aggr.hash.force.flush.memory.threshold=0.9;
        Map-Side聚合所用的hash table，占用map task堆内存的最大比例，若超出该值，则会对hash table进行一次flush
#### 2.Skew-GroupBy优化
    Skew-GroupBy的原理是启动两个MR任务
    第一个MR按照随机数分区，将数据分散发送到Reduce，完成部分聚合
    第二个MR按照分组字段分区，完成最终聚合
    1. set hive.groupby.skewindata=true;
        启用Skew-GroupBy
    2. set hive.map.aggr=false;
        关闭Map Side聚合
### 2.Join导致的数据倾斜
#### 1.Map Join
    使用Map Join算法，join操作仅在map端就能完成，没有shuffle操作，没有reduce阶段，自然不会产生reduce端的数据倾斜
    该方案适用于大表join小表时发生数据倾斜的场景
    1. set hive.auto.convert.join=true;
        启动Map Join自动转换
    2. set hive.mapjoin.smalltable.filesize=250000;
        一个Common Join operator转为Map Join operator的判断条件
        若该Common Join相关的表中,存在n-1张表的大小总和<=该值,则生成一个Map Join计划
        此时可能存在多种n-1张表的组合均满足该条件,则hive会为每种满足条件的组合均生成一个Map Join计划,同时还会保留原有的Common Join计划作为后备(back up)计划,实际运行时,优先执行Map Join计划，若不能执行成功，则启动Common Join后备计划
    3. set hive.auto.convert.join.noconditionaltask=true;
        开启无条件转Map Join
    4. set hive.auto.convert.join.noconditionaltask.size=10000000;
        无条件转Map Join时的小表之和阈值
        若一个Common Join operator相关的表中，存在n-1张表的大小总和<=该值
        此时hive便不会再为每种n-1张表的组合均生成Map Join计划,同时也不会保留Common Join作为后备计划。而是只生成一个最优的Map Join计划
#### 2.Skew Join
    Skew join的原理是，为倾斜的大key单独启动一个Map Join任务进行计算，其余key进行正常的Common Join
    1. set hive.optimize.skewjoin=true;
        启用skew join优化
    2. set hive.skewjoin.key=100000;
        触发skew join的阈值，若某个key的行数超过该参数值，则触发
#### 3.调整SQL语句
    若参与join的两表均为大表，其中一张表的数据是倾斜的，此时也可对SQL语句进行相应的调整
    select *
    from(
        select  #打散操作
            concat(id,'_',cast(rand()*2 as int)) id,
            value
        from A) ta
    join(
        select  #扩容操作
            concat(id,'_',0) id,
            value
        from B
        union all
        select
            concat(id,'_',1) id,
            value
        from B) tb
    on ta.id=tb.id;
## 5.任务并行度
### 1.Map端并行度
    Map端的并行度，也就是Map的个数。是由输入文件的切片数决定的。一般情况下，Map端的并行度无需手动调整
    以下特殊情况可考虑调整Map端并行度:
    1. 查询的表中存在大量小文件
        按照Hadoop默认的切片策略，一个小文件会单独启动一个Map Task负责计算
        若查询的表中存在大量小文件，则会启动大量Map Task，造成计算资源的浪费
        这种情况下，可以使用Hive提供的CombineHiveInputFormat，多个小文件合并为一个切片，从而控制Map Task个数
        set hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
            #使用Hive提供的CombineHiveInputFormat
    2. Map端有复杂的查询逻辑
        若SQL语句中有正则替换、json解析等复杂耗时的查询逻辑时，Map端的计算会相对慢一些
        若想加快计算速度，在计算资源充足的情况下，可考虑增大Map端的并行度，令Map Task多一些，每个Map Task计算的数据少一些
        set mapreduce.input.fileinputformat.split.maxsize=256000000
            #一个切片的最大值
### 2.Reduce端并行度
    Reduce端的并行度，也就是Reduce个数。相对来说更需要关注
    Reduce端的并行度，可由用户自己指定，也可由Hive自行根据该MR Job输入的文件大小进行估算
    Hive自行估算Reduce并行度时，是以整个MR Job输入的文件大小作为依据的。因此，在某些情况下其估计的并行度很可能并不准确，此时就需要用户根据实际情况来指定Reduce并行度
    Reduce端的并行度的相关参数如下:
    1. set mapreduce.job.reduces
        指定Reduce端并行度，默认值为-1，表示用户未指定
    2. set hive.exec.reducers.max
        Reduce端并行度最大值
    3. set hive.exec.reducers.bytes.per.reducer
        单个Reduce Task计算的数据量，用于估算Reduce并行度
## 6.小文件合并
### 1.Map端输入文件合并
    合并Map端输入的小文件，是指将多个小文件划分到一个切片中，进而由一个Map Task去处理
    目的是防止为单个小文件启动一个Map Task，浪费计算资源
    相关参数为:
    1. set hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat
        可将多个小文件切片，合并为一个切片，进而由一个map任务处理
### 2.Reduce输出文件合并
    合并Reduce端输出的小文件，是指将多个小文件合并成大文件
    目的是减少HDFS小文件数量。其原理是根据计算任务输出文件的平均大小进行判断，若符合条件，则单独启动一个额外的任务进行合并
    相关参数为:
    1. set hive.merge.mapfiles=true
        开启合并map only任务输出的小文件
    2. set hive.merge.mapredfiles=true
        开启合并map reduce任务输出的小文件
    3. set hive.merge.size.per.task=256000000
        合并后的文件大小
    4. set hive.merge.smallfiles.avgsize=16000000
        触发小文件合并任务的阈值，若某计算任务输出的文件平均大小低于该值，则触发合并
## 7.其他
### 1.CBO优化
    CBO是指Cost based Optimizer，即基于计算成本的优化
    目前CBO在hive的MR引擎下主要用于join的优化，例如多表join的join顺序
    set hive.cbo.enable=true
### 2.谓词下推
    谓词下推(predicate pushdown)是指，尽量将过滤操作前移，以减少后续计算步骤的数据量
    set hive.optimize.ppd = true
### 3.矢量化查询
    set hive.vectorized.execution.enabled=true
### 4.Fetch抓取
    Fetch抓取是指，Hive中对某些情况的查询可以不必使用MapReduce计算
    例如:select * from emp;在这种情况下，Hive可以简单地读取emp对应的存储目录下的文件，然后输出查询结果到控制台
    set hive.fetch.task.conversion=more
    # 是否在特定场景转换为fetch 任务
    # none 表示不转换
    # minimal 表示支持select *，分区字段过滤，Limit等
    # more 表示支持select 任意字段,包括函数，过滤，和limit等
### 5.本地模式
    有时Hive的输入数据量是非常小的。在这种情况下，为查询触发执行任务消耗的时间可能会比实际job的执行时间要多的多
    对于大多数这种情况，Hive可以通过本地模式在单台机器上处理所有的任务。对于小数据集，执行时间可以明显被缩短
    1. set hive.exec.mode.local.auto=true
        开启自动转换为本地模式
    2. set hive.exec.mode.local.auto.inputbytes.max=50000000
        设置local MapReduce的最大输入数据量，当输入数据量小于这个值时采用local  MapReduce的方式，默认为134217728，即128M
    3. set hive.exec.mode.local.auto.input.files.max=10
        设置local MapReduce的最大输入文件个数，当输入文件个数小于这个值时采用local MapReduce的方式，默认为4
### 6.并行执行
    Hive会将一个SQL语句转化成一个或者多个Stage，每个Stage对应一个MR Job
    默认情况下，Hive同时只会执行一个Stage。但是某SQL语句可能会包含多个Stage，但这多个Stage可能并非完全互相依赖，也就是说有些Stage是可以并行执行的
    1. set hive.exec.parallel=true
        启用并行执行优化
    2. set hive.exec.parallel.thread.number=8
        同一个sql允许最大并行度，默认为8
### 7.严格模式
    1. 分区表不使用分区过滤
        将hive.strict.checks.no.partition.filter设置为true时，对于分区表，除非where语句中含有分区字段过滤条件来限制范围，否则不允许执行。换句话说，就是用户不允许扫描所有分区。进行这个限制的原因是，通常分区表都拥有非常大的数据集，而且数据增加迅速。没有进行分区限制的查询可能会消耗令人不可接受的巨大资源来处理这个表
    2. 使用order by没有limit过滤
        将hive.strict.checks.orderby.no.limit设置为true时，对于使用了order by语句的查询，要求必须使用limit语句。因为order by为了执行排序过程会将所有的结果数据分发到同一个Reduce中进行处理，强制要求用户增加这个limit语句可以防止Reduce额外执行很长一段时间(开启了limit可以在数据进入到Reduce之前就减少一部分数据)
    3. 笛卡尔积
        将hive.strict.checks.cartesian.product设置为true时，会限制笛卡尔积的查询。对关系型数据库非常了解的用户可能期望在执行JOIN查询的时候不使用ON语句而是使用where语句，这样关系数据库的执行优化器就可以高效地将WHERE语句转化成那个ON语句。不幸的是，Hive并不会执行这种优化，因此，如果表足够大，那么这个查询就会出现不可控的情况