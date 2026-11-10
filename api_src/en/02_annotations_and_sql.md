# Annotations & SQL Builder

Declarative Java mapper annotations (`org.apache.ibatis.annotations`, `39` source files) and programmatic SQL / JDBC execution utilities (`org.apache.ibatis.jdbc`, `13` source files).

```drawlib align=center code=fold file=api_annotations_taxonomy.png caption="MyBatis 3 v3.6.0 — Mapper Annotations Taxonomy & SQL Builder Pipeline"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, Panel
from drawlib.styles import Colors, Styles

setup(width=144, height=64, dpi=150)

white_card = Styles.Neutral.patch(shape_fill_color=Colors.White)

left_panel = Panel(
    "SQL & Provider Annotations",
    "org.apache.ibatis.annotations",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=10.8),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.code,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.0,
)
left_panel.draw((4.0, 4.5), width=66.5, height=55.0, align="bottom_left")
l_xy, l_w, l_h = left_panel.get_content_box((4.0, 4.5), width=66.5, height=55.0, padding=(2.6, 2.4), align="bottom_left")

sql_cards = CardList(
    style=white_card,
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Muted.patch(text_size=9.4),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
    direction="vertical",
    spacing=1.8,
)
sql_cards.add("@Select / @Insert / @Update / @Delete", "Inline SQL or <script> dynamic XML tags", badge_text="SQL")
sql_cards.add("@SelectProvider / @*Provider", "Delegates SQL generation to SQL builder", badge_text="PRV")
sql_cards.add("@Param & @Options & @SelectKey", "Named params, generated keys & timeouts", badge_text="OPT")
sql_cards.draw(l_xy, width=l_w, height=l_h, align="bottom_left")

right_panel = Panel(
    "Result Mapping & Cache Annotations",
    "Hydration, Joins & L2 Namespace",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=10.8),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.table,
    icon_style=Styles.DarkBold,
    header_variant="filled",
    header_height=8.0,
)
right_panel.draw((73.5, 4.5), width=66.5, height=55.0, align="bottom_left")
r_xy, r_w, r_h = right_panel.get_content_box((73.5, 4.5), width=66.5, height=55.0, padding=(2.6, 2.4), align="bottom_left")

map_cards = CardList(
    style=white_card,
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Muted.patch(text_size=9.4),
    badge_shape="rounded_rect",
    badge_style=Styles.SecondaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
    direction="vertical",
    spacing=1.8,
)
map_cards.add("@Results, @Result, @ResultMap", "Reusable property/column result mappings", badge_text="MAP")
map_cards.add("@ConstructorArgs & @Arg", "Immutable Java record & constructor args", badge_text="CON")
map_cards.add("@One, @Many & @CacheNamespace", "1:1 / 1:N joins & L2 cache configuration", badge_text="L2")
map_cards.draw(r_xy, width=r_w, height=l_h, align="bottom_left")

save()
```

## `annotation` @Select / @Insert / @Update / @Delete

Declares an inline SQL statement on a mapper interface method (`org.apache.ibatis.annotations.Select`, `Insert`, `Update`, `Delete`). Accepts `String[] value()` (concatenated with spaces) and `String databaseId() default ""`. Wrap the SQL string in `<script>...</script>` to enable Dynamic SQL XML tags (`<if>`, `<where>`, `<foreach>`).

```java
@Select({
    "SELECT id, email, status, created_at",
    "FROM users",
    "WHERE id = #{id}"
})
Optional<User> findById(@Param("id") long id);
```

## `annotation` @Param

Assigns an explicit parameter name (`org.apache.ibatis.annotations.Param`) referenced by `#{name}` tokens and OGNL `<if test="name != null">` predicates inside `MapperMethod.ParamMap`. Required whenever a mapper method accepts more than one parameter (or when referenced inside dynamic SQL `<if>`/`<foreach>` expressions without `-parameters`).

## `annotation` @Options

Configures statement-level execution attributes (`org.apache.ibatis.annotations.Options`) equivalent to XML `<select>` / `<insert>` attributes:

| Attribute | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `useGeneratedKeys` | `boolean` | `false` | Enables JDBC `Statement.getGeneratedKeys()` (`Jdbc3KeyGenerator`) for `INSERT` / `UPDATE`. |
| `keyProperty` | `String` | `""` | Target Java property name (or comma-separated list) populated with generated keys (e.g., `"id"`). |
| `keyColumn` | `String` | `""` | Database column name(s) holding generated keys (required on PostgreSQL/Oracle when not the first column). |
| `useCache` | `boolean` | `true` | Enables/disables L2 cache lookup for this `SELECT` statement. |
| `flushCache` | `FlushCachePolicy` | `DEFAULT` | Controls L1/L2 cache flushing (`DEFAULT`, `TRUE`, `FALSE`). |
| `fetchSize` | `int` | `-1` | JDBC `Statement.setFetchSize(rows)` hint. |
| `timeout` | `int` | `-1` | JDBC `Statement.setQueryTimeout(seconds)`. |
| `resultSetType` | `ResultSetType` | `DEFAULT` | `FORWARD_ONLY`, `SCROLL_INSENSITIVE`, `SCROLL_SENSITIVE`. |
| `statementType` | `StatementType` | `PREPARED` | `STATEMENT`, `PREPARED` (default), or `CALLABLE` (stored procedures). |

## `annotation` @Results & @Result & @ResultMap

Defines column-to-property mappings (`org.apache.ibatis.annotations.Results`, `Result`, `ResultMap`) directly on a mapper method. Setting `id = "userResultMap"` on `@Results` registers a reusable `ResultMap` in `Configuration` that other methods can reference via `@ResultMap("userResultMap")`.

| `@Result` Attribute | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `id` | `boolean` | `false` | Marks the primary-key column used for nested join de-duplication (`CacheKey`). |
| `column` | `String` | `""` | Database column name or alias (`"user_id"` or `"{id=user_id,status=status}"` for composite keys). |
| `property` | `String` | `""` | Target JavaBean property name (`"userId"`). |
| `javaType` | `Class<?>` | `void.class` | Explicit Java property type override. |
| `jdbcType` | `JdbcType` | `UNDEFINED` | Explicit JDBC column type (`JdbcType.VARCHAR`, `JdbcType.TIMESTAMP`, etc.). |
| `typeHandler` | `Class<? extends TypeHandler>` | `UnknownTypeHandler.class` | Custom `TypeHandler` implementation class. |
| `one` | `@One` | `@One` | Nested `1:1` association (`select = "..."` or `resultMap = "..."`, `fetchType = FetchType.LAZY`). |
| `many` | `@Many` | `@Many` | Nested `1:N` collection (`select = "..."` or `resultMap = "..."`, `fetchType = FetchType.LAZY`). |

## `annotation` @ConstructorArgs & @Arg

Maps `ResultSet` columns directly to constructor parameters (`org.apache.ibatis.annotations.ConstructorArgs`, `Arg`, or repeatable `@Arg`), enabling clean hydration of immutable domain objects and Java `record` classes (`column`, `javaType`, `jdbcType`, `typeHandler`, `select`, `resultMap`, `name`, `id`).

## `annotation` @One & @Many

Configures `1:1` (`@One`) and `1:N` (`@Many`) nested associations inside `@Result`:
- `select`: Qualified ID of another mapped statement (`"com.example.OrderMapper.findByUserId"`).
- `resultMap`: ID of an existing `ResultMap` for single-query `JOIN` hydration.
- `columnPrefix`: Column prefix applied to the nested `ResultMap` (`"ord_"`).
- `fetchType`: `FetchType.LAZY`, `FetchType.EAGER`, or `FetchType.DEFAULT`.

## `annotation` @SelectKey

Executes a pre- or post-insert key-generation query (`org.apache.ibatis.annotations.SelectKey`, equivalent to XML `<selectKey>`) for databases using sequences (`statement`, `keyProperty`, `keyColumn`, `before = true|false`, `resultType`).

## `annotation` @SelectProvider / @InsertProvider / @UpdateProvider / @DeleteProvider

Delegates dynamic SQL construction to a Java provider class (`type` / `value`) and `method` (or `ProviderMethodResolver`, where the provider method name matches the mapper method name).

```java
@SelectProvider(type = UserSqlProvider.class, method = "buildFindUsers")
List<User> findUsers(@Param("status") String status, @Param("emailLike") String emailLike);
```

## `annotation` @CacheNamespace & @CacheNamespaceRef

Enables and configures an L2 cache for the mapper interface namespace (`org.apache.ibatis.annotations.CacheNamespace`): `implementation = PerpetualCache.class`, `eviction = LruCache.class`, `flushInterval = 0`, `size = 1024`, `readWrite = true` (uses `SerializedCache`), `blocking = false`. `@CacheNamespaceRef` shares another mapper's L2 cache namespace.

## `class` SQL

Fluent thread-safe SQL builder (`org.apache.ibatis.jdbc.SQL extends AbstractSQL<SQL>`) designed for `@SelectProvider` / `@UpdateProvider` classes. Automatically strips leading `AND`/`OR` in `WHERE`/`HAVING` clauses and trailing commas in `SELECT`/`SET` clauses.

```java
String sql = new SQL()
    .SELECT("u.id", "u.email", "u.status")
    .FROM("users u")
    .WHERE("u.active = #{active}")
    .applyIf(email != null, s -> s.WHERE("u.email LIKE #{email}"))
    .ORDER_BY("u.id DESC")
    .OFFSET_ROWS("#{offset}")
    .FETCH_FIRST_ROWS_ONLY("#{limit}")
    .toString();
```

## `class` ScriptRunner & SqlRunner

Lightweight JDBC utilities in `org.apache.ibatis.jdbc`:
- **`ScriptRunner`**: Executes DDL/DML SQL scripts (`Reader`) with configurable `setAutoCommit(boolean)`, `setStopOnError(boolean)`, `setSendFullScript(boolean)`, and `setDelimiter(String)`—used throughout MyBatis's `BaseDataTest` suite.
- **`SqlRunner`**: Executes ad-hoc SQL queries (`selectOne`, `selectAll`, `insert`, `update`, `delete`) directly against a `java.sql.Connection`, returning `Map<String, Object>` rows.
