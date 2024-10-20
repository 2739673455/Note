# 1.Redis简介
## 1.Redis是什么
    1. Redis是一个开源的key-value存储系统
    2. 它支持存储的value类型相对更多，包括string、list链表、set集合、zset(sorted set)和hash
    3. Redis会周期性的把更新的数据写入磁盘或者把修改操作写入追加的记录文件
    4. 支持高可用和集群模式
## 2.Redis的应用场景
    1. 配合关系型数据库做高速缓存
        高频次，热门访问的数据，降低数据库IO
        经典的Cache Aside Pattern(旁路缓存模式)
    2. 大数据场景
        1. 缓存数据
            需要高频次访问
            持久化数据访问较慢
        2. 临时数据
            高频次
            读写时效性高
            总数据量不大
            临时性
            用key查询
        3. 计算结果
            高频次写入
            高频次查询
            总数据量不大
    3. 利用其多样的数据结构存储特定的数据
        1. 最新N个数据                 通过List实现按自然事件排序的数据
        2. 排行榜，TopN                利用zset(有序集合)
        3. 时效性的数据，比如手机验证码   Expire过期
        4. 计数器，秒杀                原子性，自增方法INCR、DECR
        5. 去除大量数据中的重复数据      利用set集合
        6. 构建队列                   利用list集合
        7. 发布订阅消息系统             pub/sub模式
# 2.Redis安装
## 1.安装
    1. 安装gcc编译器
        sudo yum -y install gcc-c++
    2. 上传安装包，解压
    3. 进入安装包的src目录，编辑Makefile文件，修改软件安装路径如下:
        vim Makefile
            PREFIX?=/home/atguigu
    4. 在Redis的解压路径下执行编译和安装命令
        make && make install
## 2.查看安装目录
| 参数 | 描述 |
| --- | --- |
| redis-benchmark  |  性能测试工具
| redis-check-aof  |  修复有问题的AOF文件
| redis-check-dump |  修复有问题的RDB文件
| redis-sentinel   |  启动Redis哨兵服务
| redis-server     |  Redis服务器启动命令
| redis-cli        |  客户端，操作入口
## 3.Redis的启动
    1. 拷贝一份redis.conf配置文件到工作目录
        mkdir myredis
        cd myredis
        cp /opt/module/redis-6.2.1/redis.conf /opt/module/redis-6.2.1/myredis
    2. 绑定主机IP，修改bind属性
        vim redis.conf
            bind 0.0.0.0
    3. 指定配置文件进行启动
        redis-server /opt/module/redis-6.2.1/myredis/redis.conf
## 4.客户端访问
    1. 使用redis-cli 命令访问启动好的Redis，默认端口为6379
        redis-cli
    2. 如果有多个Redis同时启动，或者端口做了修改,则需指定端口号访问
        redis-cli -p 6379
    3. 如果访问非本机redis，需要指定host来访问
        redis-cli -h 127.0.0.1 -p 6379
    4. 通过 ping 命令测试验证
        127 .0.0.1:6379> ping
        PONG
## 5.关闭Redis服务
    如果还未通过客户端访问，可直接: redis-cli shutdown
    如果已经进入客户端,直接 shutdown
# 3.Redis五大数据类型
## 1.redis键(key)
| 参数 | 描述 |
| --- | --- |
| keys *                |  查看当前库的所有键
| exists <key>          |  判断某个键是否存在
| type <key>            |  查看键对应的value的类型
| del <key>             |  删除某个键
| expire <key> <second> |  设置过期时间
| ttl <key>             |  查看过期时间，-1表示永不过期，-2表示已过期
| dbsize                |  查看当前库中key的数量
| flushdb               |  清空当前库
| flushall              |  清空所有库
## 2.string
### 1.特点
    String是Redis最基本的类型，适合保存单值类型，即一个key对应一个value
    String类型是二进制安全的。意味着Redis的string可以包含任何数据。比如jpg图片或者序列化的对象
    一个Redis中字符串value最多可以是512M
### 2.常用操作
| 参数 | 描述 |
| --- | --- |
| set <key> <value>              |  添加键值对
| get <key>                      |  获取键的值
| append <key> <value>           |  将给定的<value>追加到原值的末尾
| strlen <key>                   |  获取值的长度
| setnx <key> <value>            |  当key不存在时设置key的值
| incr <key>                     |  将key中存储的数字值增1
| decr <key>                     |  将key中存储的数字值减1
| incrby <key> <step>            |  将key中存储的数字值按照指定步长增
| decrby <key> <step>            |  将key中存储的数字值按照指定步长减
| mset <k1> <v1> <k2> <v2>       |  同时添加一个或者多个key
| mget <k1> <k2> <k3>            |  同时获取一个或者多个key的值
| msetnx <k1> <v1> <k2> <v2>     |  同时添加一个或者多个key，当且仅当所有给定的key都不存在
| getrange <key> <start> <end>   |  获取值的子串
| setrange <key> <start> <value> |  从指定的开始位置覆盖旧值
| setex <key> <seconds> <value>  |  同时设置值和过期时间
| getset <key> <value>           |  设置新值的同时获取旧值
## 3.list
### 1.特点
    单键多值
    Redis List是简单的字符串列表，按照插入顺序排序。可以添加一个元素到列表的头部(左边)或者尾部(右边)
    它的底层实际是个双向链表，对两端的操作性能很高，通过索引下标的操作中间的节点性能会较差
### 2.常用操作
| 参数 | 描述 |
| --- | --- |
| lpush <key> <element…>                       |  从左边插入一个或多个值
| rpush <key> <element…>                       |  从右边插入一个或多个值
| lpop <key>                                   |  从左边删除一个值(值在键在，值光键亡)
| rpop <key>                                   |  从右边删除一个值(值在键在，值光键亡)
| rpoplpush <key1> <key2>                      |  从key1列表右边删除一个值，插入到key2列表左边
| lrange <key> <start> <stop>                  |  按照索引下标范围获取元素(从左到右)
| lindex <key> <index>                         |  按照索引下标获取元素(从左到右)
| llen <key>                                   |  获取列表长度
| linsert <key> before|after <pivot> <element> |  在指定<value>的前面或者后面插入<newvalue>
| lrem <key> <count> <element>                 |  从左边删除count个指定的value
## 4.set
### 1.特点
    set中的元素是无序不重复的，提供了判断某个成员是否在一个set集合内的重要接口
    Redis的Set是string类型的无序集合。它底层其实是一个value为null的hash表,所以添加，删除，查找的复杂度都是O(1)
### 2.常用操作
| 参数 | 描述 |
| --- | --- |
| sadd <key> <member…>      |  将一个或者多个member元素加入到集合中，已经存在的member将被忽略
| smemebers <key>           |  取出集合的所有值
| sismember <key> <member>  |  判断集合<key>是否包含指定的member，包含返回1，不包含返回0
| scard <key>               |  返回集合的元素个数
| srem <key> <member…>      |  从集合中删除指定的元素
| spop <key>                |  随机从集合中删除一个值
| srandmember <key> <count> |  随机从集合中取出n个值，不会从集合中删除
| sinter <key…>             |  返回多个集合的交集元素
| sunion <key…>             |  返回多个集合的并集元素
| sdiff <key…>              |  返回多个集合的差集元素
## 5.zset
### 1.特点
    Redis有序集合zset与普通集合set非常相似，是一个没有重复元素的字符串集合。不同之处是有序集合的每个成员都关联了一个评分(score)，这个评分(score)被用来按照从最低分到最高分的方式排序集合中的成员。集合的成员唯一，但评分可重复
    因为元素是有序的, 所以可以根据评分(score)或者次序(position)来获取一个范围的元素。访问有序集合的中间元素也是非常快的,因此能够使用有序集合作为一个没有重复成员的智能列表
### 2.常用操作
| 参数 | 描述 |
| --- | --- |
| zadd <key> [<score> <member> …]                |  往集合中添加指定的member及score
| zrange <key> <start> <stop> [withscores]        |  从集合中取出指定下标范围的数据，正序取
| zrevrange <key> <start> <stop> [withscores]     |  从集合中取出指定下标范围的数据，倒序取
| zrangebyscore <key> <min> <max> [withscores]    |  从集合中取出指定score范围的数据，默认从小到大
| zrevrangebyscore <key> <max> <min> [withscores] |  从集合中取出指定score范围的数据，从大到小
| zincrby <key> <increment> <member>              |  给集合中指定member的score增加increment
| zrem <key> <member…>                            |  删除集合中指定的member
| zcount <key> <min> <max>                        |  统计指定score范围的元素个数
| zrank <key> <member>                            |  返回集合中指定member的排名，排名从0开始
## 6.hash
### 1.特点
    Redis hash是一个键值对集合
    Redis hash的值是由多个field和value组成的映射表
    类似Java里面的Map<String,Object>
### 2.常用操作
| 参数 | 描述 |
| --- | --- |
| hset <key> [<field> <value> …]    |  给集合中添加指定的 <field> | <value>
| hsetnx <key> <field> <value>      |  给集合中添加指定的 <field> | <value>，当指定的field不存在时
| hget <key> <field>                |  取出集合中指定field的value
| hexists <key> <field>             |  判断集合中是否存在指定的field
| hkeys <key>                       |  列出集合中所有的field
| hvals <key>                       |  列出集合中所有的value
| hincrby <key> <field> <increment> |  给集合中指定filed的value值增加increment
# 4.Redis的相关配置
    1. 计量单位说明,大小写不敏感
        1k  => 1000 bytes
        1kb => 1024 bytes
        1m  => 1000000 bytes
        1mb => 1024*1024 bytes
        1g  => 1000000000 bytes
        1gb => 1024*1024*1024 bytes
    2. bind
        默认情况bind=127.0.0.1只能接受本机的访问请求
        不写的情况下，无限制接受任何ip地址的访问。如果开启了protected-mode，那么在没有设定bind ip且没有设密码的情况下，Redis只允许接受本机的请求
        protected-mode no
    3. port 服务端口号
        port 6379
    4. daemonize 是否为后台进程
        daemonize yes
    5. pidfile 存放pid文件的位置
        每个实例会产生一个不同的pid文件
        pidfile /var/run/redis_6379.pid
    6. log file 日志文件存储位置
        logfile ""
    7. database 设定库的数量，默认16
        databases 16
    8. requirepass 设置密码
        requirepass 123456
            127 .0.0.1:6379> set k1 v1
            (error) NOAUTH Authentication required.
            127 .0.0.1:6379> auth "123456"
            OK
            127 .0.0.1:6379> set k1 v1
            OK
    9. maxmemory 可以使用的内存量
        一旦到达内存使用上限，Redis将会试图移除内部数据，移除规则可以通过maxmemory-policy来指定
        如果Redis无法根据移除规则来移除内存中的数据，或者设置了“不允许移除”，那么Redis则会针对那些需要申请内存的指令返回错误信息，比如SET、LPUSH等
        maxmemory <bytes>
    10. maxmemory-policy 移除策略
        maxmemory-policy noeviction
        volatile-lru     # 使用LRU算法移除key，只对设置了过期时间的键
        allkeys-lru      # 使用LRU算法移除key
        volatile-lfu     # 使用LFU策略移除key,只对设置了过期时间的键
        allkeys-lfu      # 使用LFU策略移除key
        volatile-random  # 在过期集合中移除随机的key，只对设置了过期时间的键
        allkeys-random   # 移除随机的key
        volatile-ttl     # 移除那些TTL值最小的key，即那些最近要过期的key
        noeviction       # 不进行移除。针对写操作，只是返回错误信息
    11. maxmemory-samples 设置样本数量
        LRU算法和最小TTL算法都并非是精确的算法，而是估算值，所以你可以设置样本的大小。一般设置3到7的数字，数值越小样本越不准确，但是性能消耗也越小
        maxmemory-samples 5
# 5.Jedis
    Jedis是Redis的Java客户端，可以通过Java代码的方式操作Redis
    1. 环境准备 添加依赖
        <dependency>
            <groupId>redis.clients</groupId>
            <artifactId>jedis</artifactId>
            <version>3.3.0</version>
        </dependency>
    2. 基本测试
        1. 测试连通
            public class JedisTest {
                public static void main(String[] args) {
                    Jedis jedis = new Jedis("hadoop102",6379);
                    String ping = jedis.ping();
                    System.out.println(ping);
                }
            }
        2. 连接池
            连接池主要用来节省每次连接redis服务带来的连接消耗，将连接好的实例反复利用
            public static JedisPool pool =  null;
            public static Jedis getJedis(){
                if(pool == null ){
                    //主要配置
                    JedisPoolConfig jedisPoolConfig =new JedisPoolConfig();
                    jedisPoolConfig.setMaxTotal(10); //最大可用连接数
                    jedisPoolConfig.setMaxIdle(5); //最大闲置连接数
                    jedisPoolConfig.setMinIdle(5); //最小闲置连接数
                    jedisPoolConfig.setBlockWhenExhausted(true); //连接耗尽是否等待
                    jedisPoolConfig.setMaxWaitMillis(2000); //等待时间
                    jedisPoolConfig.setTestOnBorrow(true); //取连接的时候进行一下测试 ping pong
                    pool = new JedisPool(jedisPoolConfig,"hadoop102",6379);
                }
                return pool.getResource();
            }
            public static void main(String[] args) {
                Jedis jedis = getJedis();
                String ping = jedis.ping();
                System.out.println(ping);
            }
# 6.Redis持久化
## 1.两种方式
    Redis提供了2个不同形式的持久化方式: RDB 和 AOF
    RDB为快照备份，会在备份时将内存中的所有数据持久化到磁盘的一个文件中
    AOF为日志备份，会将所有写操作命令记录在一个日志文件中
## 2.RDB(Redis Database)
    1. 是什么
        在指定的时间间隔内将内存中的数据集快照写入磁盘，也就是行话讲的Snapshot快照，它恢复时是将快照文件直接读到内存里
    2. 如何执行持久化
        Redis会单独创建(fork)一个子进程来进行持久化，会先将数据写入到一个临时文件中，待持久化过程都结束了，再用这个临时文件替换上次持久化好的文件
        整个过程中，主进程是不进行任何IO操作的，这就确保了极高的性能
        如果需要进行大规模数据的恢复，且对于数据恢复的完整性不是非常敏感，那RDB方式要比AOF方式更加的高效
        RDB的缺点是最后一次持久化后的数据可能丢失
    3. RDB文件
        1. RDB保存的文件
            在redis.conf中配置文件名称，默认为dump.rdb
            dbfilename dump.rdb
        2. RDB文件的保存路径
            默认为Redis启动时命令行所在的目录下,也可以修改
            dir ./
    4. RDB保存策略
        # save <seconds> <changes>
        # Unless specified otherwise, by default Redis will save the DB:
        #   * After 3600 seconds (an hour) if at least 1 key changed
        #   * After 300 seconds (5 minutes) if at least 100 keys changed
        #   * After 60 seconds if at least 10000 keys changed
        #
        # You can set these explicitly by uncommenting the three following lines.
        #
        # save 3600 1
        # save 300 100
        # save 60 10000
    5. 手动保存
        save      # 只管保存，其它不管，全部阻塞
        bgsave    # 按照保存策略自动保存
        shutdown  # 服务会立刻执行备份后再关闭
        flushall  # 会将清空后的数据备份
    6. RDB备份恢复
        将dump.rdb文件拷贝到要备份的位置
        关闭Redis，把备份的文件拷贝到工作目录下,启动redis,备份数据会直接加载
    7. RDB其他配置
        1. 进行rdb保存时，将文件压缩
            rdbcompression yes
        2. 文件校验
            在存储快照后，还可以让Redis使用CRC64算法来进行数据校验，但是这样做会增加大约10%的性能消耗，如果希望获取到最大的性能提升，可以关闭此功能
            rdbchecksum yes
    8. RDB优缺点
        1. 优点
            节省磁盘空间,恢复速度快
        2. 缺点
            虽然Redis在fork时使用了写时拷贝技术,但是如果数据庞大时还是比较消耗性能
            在备份周期在一定间隔时间做一次备份，所以如果Redis意外down掉的话，就会丢失最后一次快照后的所有修改
## 3.AOF(Append Only File)
    1. 是什么
        以日志的形式来记录每个写操作，将Redis执行过的所有写指令记录下来(读操作不记录)，只许追加文件但不可以改写文件
        Redis启动之初会读取该文件重新构建数据，换言之，Redis重启的话就根据日志文件的内容将写指令从前到后执行一次以完成数据的恢复工作
    2. 开启AOF
        1. 先进入redis-cli中开启AOF
            127 .0.0.1:6379> config set appendonly yes
        2. AOF默认不开启，需要手动在配置文件中配置
            appendonly no
        3. AOF文件保存的位置，与RDB的路径一致
            dir ./
    3. AOF同步频率
        # no: don't fsync, just let the OS flush the data when it wants. Faster.
        # always: fsync after every write to the append only log. Slow, Safest.
        # everysec: fsync only one time every second. Compromise.
    4. AOF文件损坏恢复
        redis-check-aof --fix appendonly.aof
    5. AOF备份
        AOF的备份机制和性能虽然和RDB不同, 但是备份和恢复的操作同RDB一样，都是拷贝备份文件，需要恢复时再拷贝到Redis工作目录下，启动系统即加载
    6. Rewrite
        AOF采用文件追加方式，文件会越来越大为避免出现此种情况，新增了重写机制,当AOF文件的大小超过所设定的阈值时，Redis就会启动AOF文件的重写，只保留可以恢复数据的最小指令集.可以使用命令bgrewriteaof手动开始重写
        重写虽然可以节约大量磁盘空间，减少恢复时间。但是每次重写还是有一定的负担的，因此设定Redis要满足一定条件才会进行重写
        系统载入时或者上次重写完毕时，Redis会记录此时AOF大小，设为base_size,如果Redis的AOF当前大小>= base_size +base_size*100%(默认)且当前大小>=64mb(默认)的情况下，Redis会对AOF进行重写
        auto-aof-rewrite-percentage 100
        auto-aof-rewrite-min-size 64mb
    7. AOF的优缺点
        1. 优点
            备份机制更稳健，丢失数据概率更低。
            可读的日志文本，通过操作AOF文件，可以处理误操作
        2. 缺点
            比起RDB占用更多的磁盘空间
            恢复备份速度要慢
            每次写都同步的话，有一定的性能压力
            存在个别bug，造成恢复不能
## 4.持久化的优先级
    AOF的优先级大于RDB，如果同时开启了AOF和RDB，Redis服务启动时恢复数据以AOF为准
## 5.RDB和AOF用哪个好
    官方推荐两个都启用
    如果对数据完整性不敏感，可以选单独用RDB
    不建议单独用AOF，因为可能会出现Bug
    如果只是做纯内存缓存，可以都不用