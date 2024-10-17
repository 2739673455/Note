# 1.获取连接
## 1.方式一
    Driver driver = new com.mysql.cj.jdbc.Driver();
    String url = "jdbc:mysql://localhost:3306/db1?serverTimezone=Asia/Shanghai";
    Properties info = new Properties();
    info.setProperty("user", "root");
    info.setProperty("password", "123321");
    Connection connection = driver.connect(url, info);
## 2.方式二
    Driver driver = new com.mysql.cj.jdbc.Driver();
    DriverManager.registerDriver(driver);
    // 或使用 Class.forName("com.mysql.cj.jdbc.Driver"); 与上两行等同
    Connection connection = DriverManager.getConnection("jdbc:mysql://localhost:3306/db1?serverTimezone=UTC", "root", "123321");
## 3.方式三
    jdbc.properties文件:
        url=jdbc:mysql://localhost:3306/db1?serverTimezone=UTC&rewriteBatchedStatements=true
        user=root
        password=123321
        driverClassName=com.mysql.cj.jdbc.Driver
    FileInputStream fis = new FileInputStream("jdbc.properties");
    Properties properties = new Properties();
    properties.load(fis);
    String user = properties.getProperty("user");
    String password = properties.getProperty("password");
    String url = properties.getProperty("url");
    String driverClassName = properties.getProperty("driverClassName");
    fis.close();
    Class.forName(driverClassName);
    Connection connection = DriverManager.getConnection(url, user, password);
# 2.增删改查操作
## 1.增
    Connection connection = JDBCUtils.getConnection();
    String sql = "insert into emp(id,name,salary) values(?,?,?)";
    PreparedStatement ps = connection.prepareStatement(sql);
    ps.setInt(1, 1);
    ps.setString(2, "zhangsan");
    ps.setDouble(3, 9.9);
    int result = ps.executeUpdate(); // 该方法用来执行增、删、改的SQL语句
    System.out.println("共" + result + "行受到影响");
    JDBCUtils.close(ps, connection);
## 2.删
    Connection connection = JDBCUtils.getConnection();
    String sql = "delete from emp where id=?";
    PreparedStatement ps = connection.prepareStatement(sql);
    ps.setInt(1, 1);
    int result = ps.executeUpdate();
    System.out.println("共" + result + "行受到影响");
    JDBCUtils.close(ps, connection);
## 3.改
    Connection connection = JDBCUtils.getConnection();
    String sql = "update emp set name=?,salary=? where id=?";
    PreparedStatement ps = connection.prepareStatement(sql);
    ps.setString(1, "lisi");
    ps.setDouble(2, 999.99);
    ps.setInt(3, 1);
    int result = ps.executeUpdate();
    System.out.println("共" + result + "行受到影响");
    JDBCUtils.close(ps, connection);
## 4.查
    List<Emp> empList = new ArrayList<Emp>();
    Connection connection = JDBCUtils.getConnection();
    String sql = "select * from emp";
    PreparedStatement ps = connection.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        int id = rs.getInt("id");
        String name = rs.getString("name");
        double salary = rs.getDouble("salary");
        empList.add(new Emp(id, name, salary));
    }
    JDBCUtils.close(ps, connection, rs);
# 3.数据库连接池
    druid.properties文件:
        driverClassName=com.mysql.cj.jdbc.Driver
        url=jdbc:mysql://localhost:3306/db1?serverTimezone=UTC&rewriteBatchedStatements=true
        username=root
        password=123321
        initialSize=5
        maxActive=10
        maxWait=1000
    // 1. 获取配置文件
    Properties properties = new Properties();
    properties.load(Files.newInputStream(Paths.get("druid.properties")));
    // 2. 创建数据库连接池对象
    DataSource dataSource = DruidDataSourceFactory.createDataSource(properties);
    // 3. 获取Connection对象
    Connection connection = dataSource.getConnection();
    // 4. 关闭资源
    connection.close();
# 4.Apache的DBUtils
## 1.增删改
    QueryRunner qr = new QueryRunner();
    int result = qr.update(JDBCUtils.getConnection(), "insert into emp values(?,?,?)", 4, "lisi", 0.5);
## 2.查
    QueryRunner qr = new QueryRunner();
    List<Emp> query = qr.query(JDBCUtils.getConnection(), "select * from emp", new BeanListHandler<Emp>(Emp.class));
    for (Emp emp : query)
        System.out.println(emp);
# 5.批处理
    url中需添加rewriteBatchedStatements=true:
        jdbc:mysql://localhost:3306/atguigu?serverTimezone=UTC&rewriteBatchedStatements=true
    Connection connection = JDBCUtils.getConnection();
    String sql = "insert into emp(id,name,salary) values(?,?,?)";
    PreparedStatement ps = connection.prepareStatement(sql);
    for (int i = 1; i <= 100000; i++) {
        ps.setInt(1, i);
        ps.setString(2, "" + i);
        ps.setDouble(3, i);
        ps.addBatch();
        if (i % 1000 == 0) {
            ps.executeBatch();
            ps.clearBatch();
        }
    }
    JDBCUtils.close(ps, connection);
# 6.事务
    Connection connection = JDBCUtils.getConnection();
    String sql = "update account set balance=? where name=?";
    PreparedStatement ps = null;
    try {
        ps = connection.prepareStatement(sql);
        connection.setAutoCommit(false);
        ps.setInt(1, 6000);
        ps.setString(2, "aa");
        ps.executeUpdate();
        ps.setInt(1, 500);
        ps.setString(2, "cc");
        ps.executeUpdate();
        connection.commit();
        System.out.println("转账成功");
    } catch (SQLException e) {
        connection.rollback();
        System.out.println("转账失败");
    } finally {
        connection.setAutoCommit(true);
        JDBCUtils.close(ps, connection);
    }