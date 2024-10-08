# 1.网络与系统配置
    1. 查看网络配置信息
        ifconfig [接口名] / ip addr [show] [接口名]
    2. 修改网络配置文件
        vi /etc/sysconfig/network-scripts/ifcfg-ens33
            TYPE=Ethernet  #网络类型(通常是Ethernet)
            PROXY_METHOD=none
            BROWSER_ONLY=no
            BOOTPROTO=static  #IP的配置方法[none|static|bootp|dhcp](不使用协议|静态分配IP|BOOTP协议|DHCP协议)
            DEFROUTE=yes
            IPV4_FAILURE_FATAL=no
            IPV6INIT=yes
            IPV6_AUTOCONF=yes
            IPV6_DEFROUTE=yes
            IPV6_FAILURE_FATAL=no
            IPV6_ADDR_GEN_MODE=stable-privacy
            NAME=ens33   
            UUID=e83804c1-3257-4584-81bb-660665ac22f6  #随机id
            DEVICE=ens33  #接口名(设备,网卡)
            ONBOOT=yes  #系统启动的时候网络接口是否有效(yes/no)
            IPADDR=192.168.10.100  
            GATEWAY=192.168.10.2      
            DNS1=192.168.10.2
    3. 重启网络服务
        systemctl restart network
    4. 关闭NetworkManager
        systemctl stop NetworkManager  #关闭
        systemctl disable NetworkManager  #禁止开机启动
    5. 配置主机名称
        vi /etc/hostname
    6. 配置IP映射文件
        vi /etc/hosts
    7. 防火墙
        systemctl stop/start firewalld  #开启/关闭 防火墙
        systemctl enable/disable firewalld  #开机启动/禁止开机启动 防火墙
        systemctl status firewalld  #查看防火墙状态
    8. 关机
        sync  #将数据由内存同步到硬盘中
        halt  #关闭系统
        reboot  #重启系统
        shutdown
            -h  #关机
            -r  #重启
                now  #现在执行
                时间  #等待多少分钟后执行
# 2.常用命令
| 参数 | 描述 |
| --- | --- |
| man 命令名 | 查看命令帮助
| pwd | 显示当前路径
| ls | 显示当前路径下文件<br>-a  显示所有文件，包括隐藏文件<br>-l  列出文件属性与权限
| cd | 切换路径<br>~  回到家目录<br>-  回到上次所在目录<br>-P  跳转到实际物理路径，而非快捷方式路径
| mkdir | 创建文件夹， -p  创建多层目录
| touch 文件名 | 创建空文件
| cp 源文件 目标路径 | 复制<br>-r  递归复制整个文件夹<br>强制覆盖不提示的方法:\cp
| rm 目标路径 | 删除<br>-r  递归删除目录中所有内容<br>-f  强制执行删除操作，而不提示用于进行确认<br>-v  显示指令的详细执行过程
| mv 源文件 目标路径/新文件名 | 剪切
| cat | 查看文件内容， -n 显示行号
| more/less | 分页查看文件内容
| tail | 输出文件尾部<br>-n  输出文件尾部n行内容<br>-f  显示文件最新追加的内容，监视文件变化
| ln -s 原文件或目录 软链接名 | 软链接
| history | 查看历史命令
| date | 时间日期<br>-d '时间字符串'  显示指定的“时间字符串”表示的时间，而非当前时间<br>	date -d '1 days ago'  显示前一天时间<br>	date -d '-1 days ago'  显示后一天时间<br>-s '日期时间'  设置系统日期时间<br>	date -s "2000-01-01 00:00:00"<br>+'日期时间格式'  指定显示时使用的日期时间格式<br>	date "+%Y %m %d %H %M %S"
# 3.用户管理
    1. 添加新用户
        useradd 用户名
        useradd -g 组名 用户名  #添加用户到指定组
    2. 设置用户密码
        passwd 用户名
    3. 查看用户
        id 用户名
    4. 查看所有用户
        cat /etc/passwd
    5. 切换用户
        su 用户名
        su - 用户名  #切换到用户并获得该用户的环境变量及执行权限
    6. 删除用户
        userdel 用户名
        userdel -r 用户名  #用户和用户主目录都删除
    7. 修改用户
        usermod -l 新用户名 旧用户名
        usermod -d /home/新用户名 -m 新用户名  #修改家目录
    8. 用户添加root权限
        visudo
            ## Allow root to run any commands anywhere
            root    ALL=(ALL)     ALL
            用户名   ALL=(ALL)     NOPASSWD:ALL
    
# 4.组管理
    1. 新增组
        groupadd 组名
    2. 删除组
        groupdel 组名
    3. 修改组
        groupmod -n 新组名 旧组名
    4. 查看所有组
        cat /etc/group
# 5.文件属性
    1. d rwx rwx rwx  #r:读,w:写,x:执行
        0位代表文件类型
            '-'  #文件
            d  #目录
            l  #链接
        123位代表所属主的权限
        456位代表所属组的权限
        789位代表其他人的权限
    2. 改变文件权限
        chmod {ugoa} {+-=} {rwx} 文件或目录
        chmod 777 文件或目录
    3. 改变文件所有者
        chown 用户名 文件或目录
        chown 用户名:组名 文件或目录
        chown -r 用户名 文件或目录  #递归操作
    4. 改变文件所属组
        chgrp 组名 文件或目录
# 6.搜索查找
    1. 查找文件或者目录
        find 搜索范围  #将从指定目录向下递归地遍历其各个子目录，将满足条件的文件显示在终端
            -name 文件名
            -user 用户名
            -size [+-]文件大小
    2. 过滤查找及“|”管道符
        grep 查找内容 源文件
            -n  #显示匹配行及行号
# 7.压缩与解压
    1. gzip/gunzip
        gzip 文件名  #压缩文件，只能将文件压缩为*.gz文件
        gunzip 文件名  #解压缩文件
    2. tar
        tar [选项] 文件名.tar.gz 待打包内容  #打包目录，压缩后的文件格式.tar.gz
            -c  #产生.tar打包文件
            -v  #显示详细信息
            -f  #指定压缩后的文件名
            -z  #打包同时压缩
            -x  #解包.tar文件
            -C  #指定解压路径
        tar -zcvf 文件名.tar.gz 文件1 文件2  #压缩多个文件
        tar -zcvf 文件名.tar.gz 目录名       #压缩目录
        tar -zxvf 文件名.tar.gz             #解压到当前目录
        tar -zxvf 文件名.tar.gz -C 目录名    #解压到指定目录
# 8.磁盘
    1. 查看磁盘空间使用情况
        df
            -h	#以人们较易阅读的GBytes, MBytes, KBytes等格式自行显示
    2. 查看文件和目录的磁盘空间使用情况
        du 目录/文件
            -a  #显示当前目录下所有的文件目录及子目录大小
            -h	#以人们较易阅读的 GBytes, MBytes, KBytes 等格式自行显示
            -s  #只显示每个参数的总和大小
# 9.进程线程端口
    1. 查看当前系统进程状态
        ps
            -aux  #查看系统中所有进程
            -ef  #可以查看子父进程之间的关系
    2. 终止进程
        kill 进程号
            -9  #表示强迫进程立即停止
        killall 进程名
    3. 显示网络统计信息和端口占用情况
        netstat -anp | grep 进程号  #功能描述:查看该进程网络信息
        netstat -nlp | grep 端口号  #功能描述:查看网络端口号占用情况
    4. 查看系统健康状态
        top
            -d 秒数  #指定top命令每隔几秒更新，默认是3秒
            -i  #使top不显示任何闲置或者僵死进程
            -p  #通过指定监控进程ID来仅仅监控某个进程的状态
            在top中可执行的命令:
            P	#以CPU使用率排序，默认就是此项 
            M	#以内存的使用率排序
            N	#以PID排序
            q	#退出top
    5. 查看总体内存
        free -m
    6. 查看某个进程内存
        jmap -heap 进程号
    7. 定时任务
        crontab
        1. 重启crond服务
            systemctl restart crond
        2. 定时任务设置
            -e	#编辑crontab定时任务
                * * * * * 任务内容
                第一个*	 分钟
                第二个*	 小时
                第三个*	 天
                第四个*	 月
                第五个*	 星期几(0和7都代表星期日)
                */1 * * * *  #表示每隔一分钟
            -l	#查询crontab任务
            -r	#删除当前用户所有的crontab任务
# 10.软件包管理
    1. rpm
        1. 查询所安装的所有rpm软件包
            rpm -qa
        2. 卸载
            rpm -e [--nodeps] 软件包名
                --nodeps  #卸载软件时，不检查依赖。这样的话，那些使用该软件包的软件在此之后可能就不能正常工作了
        3. 安装
            rpm -ivh 软件包名
                -i  #安装
                -v  #显示详细信息
                -h  #进度条
                --nodeps  #不检测依赖
    2. yum
        1. 选项
            -y  #对所有提问都回答“yes”
            install  #安装rpm软件包
            update  #更新rpm软件包
            check-update  #检查是否有可用的更新rpm软件包
            remove  #删除指定的rpm软件包
            list  #显示软件包信息
            clean all  #清理yum过期的缓存
            makecache  #将当前yum源里的rpm包列表缓存到本地
            deplist  #显示yum软件包的所有依赖关系
        2. 修改yum源
            1. 进入目录
                cd /etc/yum.repos.d
            2. 将原本的源重命名
                mv CentOS-Base.repo CentOS-Base.repo.backup
            3. 将新的源重命名
                mv 新源 CentOS-Base.repo
            4. 清理旧缓存数据，缓存新数据
                yum clean all
                yum makecache
# 11.shell
## 1.变量
    1. 自定义变量
        定义变量:变量名=变量值，注意，=号前后不能有空格
        撤销变量:unset 变量名
        声明静态变量:readonly变量，注意:不能unset
        使用变量:$变量名
    2. 特殊变量
        $n  #n为数字，$0代表该脚本名称，$1-$9代表第一到第九个参数，十以上的参数需要用大括号包含，如${10}
        $#  #获取所有输入参数个数
        $*  #代表命令行中所有的参数，把所有的参数看成一个整体
        $@  #代表命令行中所有的参数，把每个参数区分对待
        $?  #最后一次执行的命令的返回状态。如果为0，证明上一个命令正确执行。如果非0，则证明上一个命令执行不正确
    3. 数组
        1. 数组名=(值1 值2 值3)
        2. 取数组元素
            ${数组名[下标]}  #取单个元素
            ${数组名[@]}  #取所有元素
            ${数组名[*]}  #取所有元素
        3. 取数组长度
            ${#数组名[@]}
            ${#数组名[*]}
    4. 字符串
        1. 取字符串长度
            ${#string}
        2. 截取字符串
            ${string:start:length}
        3. 使用字符拼接列表元素
            joined=$(IFS=,; echo "${list[*]}")
            echo $joined
## 2.运算符
    $((运算式))
    $[运算式]
    单引号不取变量值
    双引号取变量值
    反引号`，执行引号中命令
    双引号内部嵌套单引号，取出变量值
    单引号内部嵌套双引号，不取出变量值
## 3.条件判断
    1. 基本语法
        test 条件
        [·条件·]  #条件前后必须有空格
    2. 常用判断条件
        1. 整数比较
            -eq  等于(equal)
            -ne  不等于(not equal)
            -lt  小于(less than)
            -le  小于等于(less equal)
            -gt  大于(greater than)
            -ge  大于等于(greater equal)
        2. 按照文件权限进行判断
            -r  有读的权限(read)
            -w  有写的权限(write)
            -x  有执行的权限(execute)
        3. 按照文件类型进行判断
            -e  文件存在(existence)
            -f  文件存在并且是一个常规的文件(file)
            -d  文件存在并且是一个目录(directory)
        4. 字符串运算符
            -z  检测字符串长度是否为0，为0返回 true
            -n  检测字符串长度是否不为 0，不为 0 返回 true
            $   检测字符串是否不为空，不为空返回 true
## 4.流程控制
### 1.if
    if·[ 条件 ]
    then
        程序
    elif [ 条件 ]
    then
        程序
    else
        程序
    fi
    #if后要有空格
### 2.case
    case $变量名 in
    "值1")
        程序
    ;;
    "值2")
        程序
    ;;
    *)
        如果变量的值都不是以上的值，则执行此程序
    ;;
    esac
### 3.for
    1. 语法一
        for ((初始值;循环控制条件;变量变化))
        do
            程序
        done
    2. 语法二
        for 变量 in 值1 值2 值3
        do
            程序
        done
### 4.while
    while [ 条件 ]
    do
        程序
    done
## 5.read 读取参数
    read [选项] [参数]
        -p  #指定读取值时的提示符
        -t  #指定读取值时等待的时间(秒)如果-t不加表示一直等待
## 6.函数
    1. basename  #取文件路径里的文件名称
    2. dirname  #取文件路径的绝对路径名称
    3. 自定义函数
        function func()
        {
            程序
        }
        函数调用:func
## 7.shell工具
    1. cut
        cut 选项 文件名
            -f  #列号，提取第几列
            -d  #分隔符，按照指定分隔符分割列，默认是制表符"\t"
            -c  #按字符进行切割,后加n,表示取第几列,比如 -c 1
    2. awk
        awk 选项参数 '/pattern1/{action1} /pattern2/{action2}' 文件名
            -F  #指定输入文件折分隔符
            -v  #赋值一个用户定义变量
            pattern  #查找的内容，就是匹配模式
            action  #找到匹配内容时所执行的命令
        awk内置变量
            FILENAME  #文件名
            NR  #已读的记录数(行号)
            NF	#浏览记录的域的个数(切割后，列的个数)
    3. rsync远程同步工具
        rsync -av 本地文件 用户名@主机:远程目录