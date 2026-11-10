# Plugins, Reflection & Exceptions

Dynamic proxy interception (`org.apache.ibatis.plugin`), cached JavaBean/Record reflection (`org.apache.ibatis.reflection`), and runtime exception hierarchy (`org.apache.ibatis.exceptions`).

```drawlib align=center code=fold file=api_plugin_reflection_exceptions.png caption="MyBatis 3 v3.6.0 — Plugin Interception, MetaObject Reflection & Exception Hierarchy"
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

grp = d.add(
    NodeGroup(
        "Cross-Cutting Runtime Subsystems",
        width=132,
        height=22,
        style=Styles.SecondaryNeutral,
        text_style=Styles.DarkBold.patch(text_size=10.2, halign="left", valign="top"),
    ),
    xy=(4, 22),
)
n_plg = grp.add(Node("Plugin Interception\nInterceptor / @Intercepts / Plugin", icon=PhosphorIcon.PUZZLE_PIECE, width=38, height=13), xy=(23, 9))
n_ref = grp.add(Node("Reflection Engine\nMetaObject / Reflector / ObjectFactory", icon=PhosphorIcon.MAGNIFYING_GLASS, width=40, height=13), xy=(66, 9))
n_exc = grp.add(Node("Exception Hierarchy\nPersistenceException & Subclasses", icon=PhosphorIcon.WARNING_OCTAGON, width=38, height=13), xy=(109, 9))

n_core = d.add(
    Node("Interceptable Core Execution Targets (Executor / StatementHandler / ParameterHandler / ResultSetHandler)", icon=PhosphorIcon.CPU, width=116, height=12),
    xy=(70, 9),
)

n_plg.connect(n_core)
n_ref.connect(n_core)
n_exc.connect(n_core)

d.draw(xy=(0, 0))
save()
```

## `interface` Interceptor

**Package:** `org.apache.ibatis.plugin`

Extension SPI allowing custom interceptors to wrap and advise methods on MyBatis's four core execution targets: `Executor`, `StatementHandler`, `ParameterHandler`, and `ResultSetHandler`.

### Signature

```java
public interface Interceptor {
  Object intercept(Invocation invocation) throws Throwable;

  default Object plugin(Object target) {
    return Plugin.wrap(target, this);
  }

  default void setProperties(Properties properties) {
    // NOP
  }
}
```

### Usage Example

```java
@Intercepts({
  @Signature(
      type = StatementHandler.class,
      method = "prepare",
      args = {Connection.class, Integer.class})
})
public class SlowQueryCommentPlugin implements Interceptor {
  @Override
  public Object intercept(Invocation invocation) throws Throwable {
    StatementHandler handler = (StatementHandler) invocation.getTarget();
    BoundSql boundSql = handler.getBoundSql();
    // Inspect boundSql.getSql() before JDBC Statement preparation
    return invocation.proceed();
  }
}
```

---

## `annotation` @Intercepts

**Package:** `org.apache.ibatis.plugin`

Container annotation placed on an `Interceptor` class declaring one or more `@Signature` method targets to intercept.

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface Intercepts {
  Signature[] value();
}
```

---

## `annotation` @Signature

**Package:** `org.apache.ibatis.plugin`

Identifies an exact method signature on one of the four interceptable interfaces (`Executor.class`, `StatementHandler.class`, `ParameterHandler.class`, `ResultSetHandler.class`).

| Attribute | Type | Description |
| :--- | :--- | :--- |
| `type` | `Class<?>` | Target interface (`Executor`, `StatementHandler`, `ParameterHandler`, or `ResultSetHandler`) |
| `method` | `String` | Method name on `type` (e.g., `"query"`, `"update"`, `"prepare"`) |
| `args` | `Class<?>[]` | Exact parameter type array used to resolve overloaded methods via `type.getMethod(method, args)` |

---

## `class` Invocation

**Package:** `org.apache.ibatis.plugin`

Encapsulates a single intercepted method call passed to `Interceptor.intercept(Invocation)`.

### Key Methods

| Method | Signature | Description |
| :--- | :--- | :--- |
| `getTarget` | `Object getTarget()` | Returns the underlying target (or inner proxy) instance |
| `getMethod` | `Method getMethod()` | Returns the intercepted `java.lang.reflect.Method` |
| `getArgs` | `Object[] getArgs()` | Returns the mutable array of method arguments |
| `proceed` | `Object proceed() throws InvocationTargetException, IllegalAccessException` | Invokes `method.invoke(target, args)` to continue the chain |

---

## `class` Plugin

**Package:** `org.apache.ibatis.plugin`

`InvocationHandler` implementation that parses `@Intercepts`/`@Signature` metadata on an `Interceptor` and wraps matching interfaces in a `java.lang.reflect.Proxy`.

### Key Method

```java
public static Object wrap(Object target, Interceptor interceptor)
```

---

## `class` MetaObject

**Package:** `org.apache.ibatis.reflection`

Unified property navigation facade capable of evaluating nested path expressions (`"author.address.city"`, `"orders[0].items['sku'].price"`) seamlessly across JavaBeans, Java `record`s, `Map`s, and `List`/array collections.

### Key Methods

| Method | Signature | Description |
| :--- | :--- | :--- |
| `forObject` | `static MetaObject forObject(Object object, ObjectFactory objectFactory, ObjectWrapperFactory wrapperFactory, ReflectorFactory reflectorFactory)` | Factory method (prefer `Configuration.newMetaObject(obj)` or `SystemMetaObject.forObject(obj)`) |
| `getValue` | `Object getValue(String name)` | Evaluates a potentially nested property expression |
| `setValue` | `void setValue(String name, Object value)` | Writes a value to a nested property path, auto-instantiating intermediate objects if needed |
| `hasGetter` / `hasSetter` | `boolean hasGetter(String name)` / `boolean hasSetter(String name)` | Checks whether the property path is readable or writable |
| `findProperty` | `String findProperty(String propName, boolean useCamelCaseMapping)` | Matches a column name to a property name (optionally stripping underscores) |

---

## `class` SystemMetaObject

**Package:** `org.apache.ibatis.reflection`

Utility helper providing a static `SystemMetaObject.forObject(Object)` factory backed by `DefaultObjectFactory`, `DefaultObjectWrapperFactory`, and `DefaultReflectorFactory`. Useful inside plugins to inspect private fields of `StatementHandler` or `RoutingStatementHandler`.

---

## `class` Reflector

**Package:** `org.apache.ibatis.reflection`

Per-class cached introspection metadata managed by `DefaultReflectorFactory` (`ConcurrentHashMap<Class<?>, Reflector>`). Pre-computes constructor, getter/setter `Invoker`s (`MethodInvoker`, `GetFieldInvoker`, `SetFieldInvoker`), and generic return/parameter types via `TypeParameterResolver`.

---

## `interface` ObjectFactory

**Package:** `org.apache.ibatis.reflection.factory`

SPI used by `DefaultResultSetHandler` and `MetaObject` to instantiate target result objects via default or parameterized constructors (`DefaultObjectFactory` is the standard implementation).

### Signature

```java
public interface ObjectFactory {
  default void setProperties(Properties properties) {}
  <T> T create(Class<T> type);
  <T> T create(Class<T> type, List<Class<?>> constructorArgTypes, List<Object> constructorArgs);
  <T> boolean isCollection(Class<T> type);
}
```

---

## `class` PersistenceException

**Package:** `org.apache.ibatis.exceptions`

Root unchecked (`RuntimeException`) base class for all MyBatis exceptions (replacing the deprecated `IbatisException`). All domain-specific exceptions (`BindingException`, `BuilderException`, `CacheException`, `DataSourceException`, `ExecutorException`, `LogException`, `PluginException`, `ReflectionException`, `ScriptingException`, `TransactionException`, `TypeException`) extend `PersistenceException`.

---

## `class` TooManyResultsException

**Package:** `org.apache.ibatis.exceptions`

Thrown by `DefaultSqlSession.selectOne(...)` (and single-object Mapper interface methods) when a query returns 2 or more rows instead of 0 or 1.
