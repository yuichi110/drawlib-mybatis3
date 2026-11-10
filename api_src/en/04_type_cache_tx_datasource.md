# TypeHandlers, Cache, Transaction & DataSource

Java-to-JDBC type conversion (`org.apache.ibatis.type`), L1/L2 caching (`org.apache.ibatis.cache`), transaction boundaries (`org.apache.ibatis.transaction`), and built-in JDBC connection pooling (`org.apache.ibatis.datasource`).

```drawlib align=center code=fold file=api_type_cache_tx_datasource.png caption="MyBatis 3 v3.6.0 — TypeHandler, Cache, Transaction & DataSource SPI Architecture"
from drawlib.canvas import save, setup
from drawlib.diagrams.architecture import ArchitectureDiagram, Node, NodeGroup, PhosphorIcon
from drawlib.styles import Colors, Styles

setup(width=140, height=48, dpi=150)

d = ArchitectureDiagram(
    node_style=Styles.Dark,
    node_text_style=Styles.DarkBold.patch(text_size=9.5),
    edge_style=Styles.Dark.patch(line_width=1.5),
    edge_text_style=Styles.DarkBold.patch(text_size=9.0),
    node_card_style=Styles.Neutral.patch(shape_fill_color=Colors.White),
)

spi = d.add(
    NodeGroup(
        "Pluggable Infrastructure SPIs",
        width=132,
        height=22,
        style=Styles.PrimaryNeutral,
        text_style=Styles.DarkBold.patch(text_size=10.2, halign="left", valign="top"),
    ),
    xy=(4, 22),
)
n_type = spi.add(Node("TypeHandler<T>\n& BaseTypeHandler", icon=PhosphorIcon.ARROWS_LEFT_RIGHT, width=28, height=13), xy=(18, 9))
n_cache = spi.add(Node("Cache SPI\nPerpetual / LRU / Serialized", icon=PhosphorIcon.DATABASE, width=30, height=13), xy=(50, 9))
n_tx = spi.add(Node("Transaction SPI\nJdbc / Managed", icon=PhosphorIcon.SHIELD_CHECK, width=28, height=13), xy=(82, 9))
n_ds = spi.add(Node("DataSource SPI\nPooled / Unpooled", icon=PhosphorIcon.PLUGS_CONNECTED, width=30, height=13), xy=(114, 9))

n_cfg = d.add(
    Node("Configuration Registry & Runtime Execution Pipeline (ParameterHandler / ResultSetHandler / Executor)", icon=PhosphorIcon.GEAR, width=116, height=12),
    xy=(70, 9),
)

n_type.connect(n_cfg)
n_cache.connect(n_cfg)
n_tx.connect(n_cfg)
n_ds.connect(n_cfg)

d.draw(xy=(0, 0))
save()
```

## `interface` TypeHandler&lt;T&gt;

**Package:** `org.apache.ibatis.type`

Contract for binding a Java type `T` to a `PreparedStatement` parameter and extracting `T` from a `ResultSet` or `CallableStatement`.

### Signature

```java
public interface TypeHandler<T> {
  void setParameter(PreparedStatement ps, int i, T parameter, JdbcType jdbcType) throws SQLException;
  T getResult(ResultSet rs, String columnName) throws SQLException;
  T getResult(ResultSet rs, int columnIndex) throws SQLException;
  T getResult(CallableStatement cs, int columnIndex) throws SQLException;
}
```

### Usage Example

Always prefer extending `BaseTypeHandler<T>` rather than implementing `TypeHandler<T>` directly so SQL `NULL` binding and `ResultSet.wasNull()` checks are handled automatically.

---

## `class` BaseTypeHandler&lt;T&gt;

**Package:** `org.apache.ibatis.type`

Abstract template class for custom `TypeHandler` implementations that automatically handles `null` parameters (`PreparedStatement.setNull`) and `TypeException` wrapping.

### Key Template Methods to Override

| Method | Signature | Description |
| :--- | :--- | :--- |
| `setNonNullParameter` | `void setNonNullParameter(PreparedStatement ps, int i, T parameter, JdbcType jdbcType)` | Bind non-null Java value `parameter` at 1-based JDBC parameter index `i` |
| `getNullableResult(rs, name)` | `T getNullableResult(ResultSet rs, String columnName)` | Read value by column label/name (return `null` if SQL `NULL`) |
| `getNullableResult(rs, index)` | `T getNullableResult(ResultSet rs, int columnIndex)` | Read value by 1-based column index |
| `getNullableResult(cs, index)` | `T getNullableResult(CallableStatement cs, int columnIndex)` | Read value from a stored procedure `OUT` parameter |

### Usage Example

```java
@MappedTypes(Money.class)
@MappedJdbcTypes(JdbcType.DECIMAL)
public class MoneyTypeHandler extends BaseTypeHandler<Money> {

  @Override
  public void setNonNullParameter(PreparedStatement ps, int i, Money parameter, JdbcType jdbcType)
      throws SQLException {
    ps.setBigDecimal(i, parameter.amount());
  }

  @Override
  public Money getNullableResult(ResultSet rs, String columnName) throws SQLException {
    BigDecimal val = rs.getBigDecimal(columnName);
    return val == null ? null : new Money(val);
  }

  @Override
  public Money getNullableResult(ResultSet rs, int columnIndex) throws SQLException {
    BigDecimal val = rs.getBigDecimal(columnIndex);
    return val == null ? null : new Money(val);
  }

  @Override
  public Money getNullableResult(CallableStatement cs, int columnIndex) throws SQLException {
    BigDecimal val = cs.getBigDecimal(columnIndex);
    return val == null ? null : new Money(val);
  }
}
```

---

## `class` TypeHandlerRegistry

**Package:** `org.apache.ibatis.type`

Two-level lookup table (`Map<Type, Map<JdbcType, TypeHandler<?>>>`) mapping Java types and optional `JdbcType` constants to `TypeHandler` instances. Pre-registers over 40 standard handlers (`StringTypeHandler`, `LongTypeHandler`, `LocalDateTimeTypeHandler`, `EnumTypeHandler`, etc.).

### Key Methods

| Method | Signature | Description |
| :--- | :--- | :--- |
| `register(Class<T>, TypeHandler)` | `<T> void register(Class<T> javaType, TypeHandler<? extends T> typeHandler)` | Register a handler for a specific Java class |
| `register(Class<?>)` | `void register(Class<?> typeHandlerClass)` | Register a handler class inspecting `@MappedTypes` and `@MappedJdbcTypes` |
| `register(String)` | `void register(String packageName)` |Classpath scan a package for `TypeHandler` implementations |
| `setDefaultEnumTypeHandler` | `void setDefaultEnumTypeHandler(Class<? extends TypeHandler> typeHandler)` | Switch default enum handling (e.g., to `EnumOrdinalTypeHandler`) |

---

## `class` TypeAliasRegistry

**Package:** `org.apache.ibatis.type`

Case-insensitive registry mapping short alias strings (e.g., `"long"`, `"map"`, `"author"`) to `Class<?>` objects used in XML configurations and mapper files.

### Key Methods

| Method | Signature | Description |
| :--- | :--- | :--- |
| `registerAlias(String, Class<?>)` | `void registerAlias(String alias, Class<?> value)` | Register an explicit alias for a class |
| `registerAliases(String)` | `void registerAliases(String packageName)` | Register all classes in a package using their simple class name or `@Alias` value |
| `resolveAlias(String)` | `<T> Class<T> resolveAlias(String string)` | Resolve an alias or fully qualified class name to a `Class<T>` |

---

## `enum` JdbcType

**Package:** `org.apache.ibatis.type`

Enumeration wrapping `java.sql.Types` integer constants (`VARCHAR`, `BIGINT`, `TIMESTAMP`, `NUMERIC`, `OTHER`, `NULL`, etc.).

### Usage Example

```xml
<insert id="insertUser">
  INSERT INTO users (id, email, bio)
  VALUES (#{id}, #{email}, #{bio,jdbcType=VARCHAR})
</insert>
```

---

## `annotation` @MappedTypes

**Package:** `org.apache.ibatis.type`

Declares the Java class(es) a `TypeHandler` handles when registered via class or package scanning.

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface MappedTypes {
  Class<?>[] value();
}
```

---

## `annotation` @MappedJdbcTypes

**Package:** `org.apache.ibatis.type`

Declares the `JdbcType` constant(s) a `TypeHandler` handles when registered via class or package scanning.

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface MappedJdbcTypes {
  JdbcType[] value();
  boolean includeNullJdbcType() default false;
}
```

---

## `interface` Cache

**Package:** `org.apache.ibatis.cache`

Core SPI for MyBatis L1 (`PerpetualCache`) and L2 (`CachingExecutor`) caches. Uses the Decorator pattern (`LruCache`, `FifoCache`, `SerializedCache`, `LoggingCache`, `SynchronizedCache`, `BlockingCache`, `TransactionalCache`) to layer eviction, serialization, and transactional isolation on top of a base storage implementation.

### Signature

```java
public interface Cache {
  String getId();
  void putObject(Object key, Object value);
  Object getObject(Object key);
  Object removeObject(Object key);
  void clear();
  int getSize();
  default ReadWriteLock getReadWriteLock() { return null; }
}
```

---

## `class` PerpetualCache

**Package:** `org.apache.ibatis.cache.impl`

Base `HashMap<Object, Object>`-backed `Cache` implementation used as the L1 `localCache` inside `BaseExecutor` and as the innermost storage target of decorated L2 caches.

---

## `class` LruCache

**Package:** `org.apache.ibatis.cache.decorators`

Decorator `Cache` that evicts the least-recently-used entry using a `LinkedHashMap` with access-order tracking when the cache exceeds `size` (default `1024`).

---

## `class` SerializedCache

**Package:** `org.apache.ibatis.cache.decorators`

Decorator `Cache` enabled when `readOnly="false"` (the default for `<cache/>`). Serializes cached Java objects into `byte[]` on `putObject` and deserializes a fresh copy on `getObject` so concurrent sessions cannot mutate shared instances. Calls `SerialFilterChecker.check()` once to warn if no JEP-290 `jdk.serialFilter` is configured.

---

## `interface` Transaction

**Package:** `org.apache.ibatis.transaction`

Wraps a JDBC `Connection` and manages its transaction lifecycle (`getConnection()`, `commit()`, `rollback()`, `close()`, `getTimeout()`).

### Implementations

| Implementation | Package | Behavior |
| :--- | :--- | :--- |
| `JdbcTransaction` | `org.apache.ibatis.transaction.jdbc` | Manages `Connection.setAutoCommit(false)`, `commit()`, and `rollback()` directly |
| `ManagedTransaction` | `org.apache.ibatis.transaction.managed` | Delegates commit/rollback lifecycle to an external container (Spring, Jakarta EE) |

---

## `interface` TransactionFactory

**Package:** `org.apache.ibatis.transaction`

Factory that creates `Transaction` instances from an existing `Connection` or a `DataSource`.

```java
public interface TransactionFactory {
  default void setProperties(Properties props) {}
  Transaction newTransaction(Connection conn);
  Transaction newTransaction(DataSource dataSource, TransactionIsolationLevel level, boolean autoCommit);
}
```

---

## `class` PooledDataSource

**Package:** `org.apache.ibatis.datasource.pooled`

Built-in synchronous JDBC `javax.sql.DataSource` connection pool configured via `<dataSource type="POOLED">`. Tracks active and idle `PooledConnection` proxies inside `PoolState`.

### Key Configuration Properties

| Property | Default | Description |
| :--- | :--- | :--- |
| `poolMaximumActiveConnections` | `10` | Maximum concurrent active connections |
| `poolMaximumIdleConnections` | `5` | Maximum idle connections retained in the pool |
| `poolMaximumCheckoutTime` | `20000` (ms) | Maximum time a connection can run before being reclaimed as overdue |
| `poolTimeToWait` | `20000` (ms) | Wait time before retrying when the pool is exhausted |
| `poolPingEnabled` | `false` | Enable health check query (`poolPingQuery`) on checkout/checkin |

---

## `class` UnpooledDataSource

**Package:** `org.apache.ibatis.datasource.unpooled`

Simple `javax.sql.DataSource` implementation configured via `<dataSource type="UNPOOLED">` that opens a new JDBC `DriverManager.getConnection(...)` on every request. Suitable for CLI scripts or unit tests with in-memory databases.
