# XML Configuration & Mapper Elements

Complete reference for MyBatis 3's two XML DTD/XSD schemas resolved offline by `XMLMapperEntityResolver`:
1. **`mybatis-3-config.dtd`**: Global `<configuration>` bootstrap descriptor.
2. **`mybatis-3-mapper.dtd`**: Per-namespace `<mapper namespace="...">` SQL, `<resultMap>`, `<cache>`, and Dynamic SQL tags.

```drawlib align=center code=fold file=api_xml_dtd_hierarchy.png caption="MyBatis 3 v3.6.0 — mybatis-3-config.dtd & mybatis-3-mapper.dtd Element Trees"
from drawlib.canvas import save, setup
from drawlib.fonts import FontMonoSpace, FontRoboto
from drawlib.icons import phosphor
from drawlib.smartarts import Panel, TreeNode
from drawlib.styles import Colors, Styles

setup(width=144, height=68, dpi=150)

left_panel = Panel(
    "mybatis-3-config.dtd",
    "Strict Child Element Order!",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=10.8),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.gear_six,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.0,
)
left_panel.draw((4.0, 4.5), width=66.5, height=59.0, align="bottom_left")

TreeNode.register_drawing_item(
    name="xml_tag",
    location="before",
    padding_width=3.6,
    function=phosphor.code,
    style=Styles.Primary.patch(icon_color=Colors.Primary),
    args={"width": 2.5},
)

mono_bold = Styles.DarkBold.patch(text_font=FontMonoSpace.ROBOTO_MONO_BOLD, text_size=9.2)
mono_reg = Styles.Dark.patch(text_font=FontMonoSpace.ROBOTO_MONO_REGULAR, text_size=9.2)

cfg_root = TreeNode(
    "<configuration>",
    text_style=mono_bold,
    line_style=Styles.Muted.patch(line_width=1.1),
    line_horizontal_margin=2.0,
    line_horizontal_length=2.2,
    line_vertical_margin=3.55,
).set_drawing_item("xml_tag")

for item in [
    "1. <properties resource='...'>",
    "2. <settings> (<setting name=.../>)",
    "3. <typeAliases> (<package/>)",
    "4. <typeHandlers>",
    "5. <objectFactory> & <plugins>",
    "6. <environments default='...'>",
    "7. <databaseIdProvider>",
    "8. <mappers> (<mapper/>, <package/>)",
]:
    cfg_root.add(item, text_style=mono_reg).set_drawing_item("xml_tag")

cfg_root.draw(xy=(7.0, 52.5))

right_panel = Panel(
    "mybatis-3-mapper.dtd",
    "<mapper namespace='...'>",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=10.8),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.file_code,
    icon_style=Styles.DarkBold,
    header_variant="filled",
    header_height=8.0,
)
right_panel.draw((73.5, 4.5), width=66.5, height=59.0, align="bottom_left")

map_root = TreeNode(
    "<mapper namespace='...'>",
    text_style=mono_bold,
    line_style=Styles.Muted.patch(line_width=1.1),
    line_horizontal_margin=2.0,
    line_horizontal_length=2.2,
    line_vertical_margin=3.55,
).set_drawing_item("xml_tag")

for item in [
    "<cache/> & <cache-ref/>",
    "<resultMap id='...' type='...'>",
    "  <constructor>, <id>, <result>",
    "  <association>, <collection>",
    "<sql id='...'> & <include refid='...'>",
    "<select>, <insert>, <update>, <delete>",
    "  <if>, <choose>/<when>/<otherwise>",
    "  <where>, <set>, <trim>, <foreach>",
]:
    map_root.add(item, text_style=mono_reg).set_drawing_item("xml_tag")

map_root.draw(xy=(76.5, 52.5))

save()
```

## `xml` <configuration> (mybatis-3-config.dtd)

Root element of `mybatis-config.xml` parsed by `XMLConfigBuilder`. **Important**: The DTD enforces a strict ordering of child elements:

```xml
<!ELEMENT configuration (properties?, settings?, typeAliases?, typeHandlers?,
  objectFactory?, objectWrapperFactory?, reflectorFactory?, plugins?,
  environments?, databaseIdProvider?, mappers?)>
```

## `xml` <settings> & <setting>

Configures global runtime behavior on `Configuration` (`<setting name="..." value="..."/>`). Most frequently used settings:

| Setting `name` | Valid Values | Default | Effect |
| :--- | :--- | :--- | :--- |
| `mapUnderscoreToCamelCase` | `true \| false` | `false` | Maps `user_id` -> `userId` automatically. |
| `cacheEnabled` | `true \| false` | `true` | Enables L2 `CachingExecutor` globally. |
| `lazyLoadingEnabled` | `true \| false` | `false` | Enables Javassist lazy-loading proxies for associations. |
| `aggressiveLazyLoading` | `true \| false` | `false` | Loads only the specific lazy property accessed. |
| `localCacheScope` | `SESSION \| STATEMENT` | `SESSION` | Use `STATEMENT` in multi-service deployments to disable session-long L1 caching. |
| `defaultExecutorType` | `SIMPLE \| REUSE \| BATCH` | `SIMPLE` | Default `Executor` implementation. |
| `defaultStatementTimeout` | Positive integer (seconds) | `null` | Default JDBC query timeout. |
| `jdbcTypeForNull` | `NULL \| VARCHAR \| OTHER` | `OTHER` | Set to `NULL` for Oracle/DB2 compatibility when binding `null`. |
| `logImpl` | `SLF4J \| LOG4J2 \| STDOUT_LOGGING ...` | Auto | Forces a specific `Log` adapter in `LogFactory`. |

## `xml` <environments>, <transactionManager> & <dataSource>

Configures one or more named database environments (`<environments default="development"><environment id="development">...`):
- **`<transactionManager type="JDBC | MANAGED"/>`**: `JDBC` delegates commit/rollback to the JDBC connection (`JdbcTransaction`); `MANAGED` lets a container manage transactions (`ManagedTransaction`).
- **`<dataSource type="POOLED | UNPOOLED | JNDI"/>`**: `POOLED` configures `PooledDataSource` (`driver`, `url`, `username`, `password`, `poolMaximumActiveConnections`, `poolMaximumIdleConnections`, `poolPingQuery`, `poolPingEnabled`).

## `xml` <mappers>

Registers SQL mappers into `Configuration` via one of four mutually exclusive forms:
- `<mapper resource="org/mybatis/example/AuthorMapper.xml"/>` (classpath relative path)
- `<mapper class="org.mybatis.example.AuthorMapper"/>` (Java mapper interface class)
- `<mapper url="file:///var/mappers/AuthorMapper.xml"/>` (URL path)
- `<package name="org.mybatis.example"/>` (scans all mapper interfaces in package)

## `xml` <select>, <insert>, <update> & <delete>

Statement elements inside `<mapper namespace="...">` parsed by `XMLStatementBuilder`:

| Attribute | Applies To | Description |
| :--- | :--- | :--- |
| `id` | All | Mandatory method name within the namespace (`findById`). |
| `resultType` | `<select>` | Fully qualified class name or alias (`User`, `map`, `int`). Mutually exclusive with `resultMap`. |
| `resultMap` | `<select>` | References a named `<resultMap id="...">` for complex joins, constructors, or type handlers. |
| `flushCache` | All | Defaults to `false` for `<select>` and `true` for `<insert>`/`<update>`/`<delete>`. |
| `useCache` | `<select>` | Defaults to `true` for `<select>` (stores result in L2 cache if namespace has `<cache/>`). |
| `useGeneratedKeys` | `<insert>`, `<update>` | Uses JDBC `getGeneratedKeys()` to populate `keyProperty` (e.g. `keyProperty="id" keyColumn="id"`). |
| `timeout` / `fetchSize` | All / `<select>` | Per-statement query timeout (seconds) and JDBC fetch size hint. |

## `xml` <resultMap>, <id>, <result>, <constructor>, <association> & <collection>

The most powerful element in MyBatis (`parsed by XMLMapperBuilder.resultMapElement()`), eliminating 90%+ of JDBC `ResultSet` boilerplate:

```xml
<resultMap id="detailedBlogResultMap" type="Blog">
  <constructor>
    <idArg column="blog_id" javaType="_int" name="id"/>
  </constructor>
  <result property="title" column="blog_title"/>
  <association property="author" javaType="Author">
    <id property="id" column="author_id"/>
    <result property="username" column="author_username"/>
  </association>
  <collection property="posts" ofType="Post">
    <id property="id" column="post_id"/>
    <result property="subject" column="post_subject"/>
  </collection>
</resultMap>
```

| Child Element | Key Attributes | Role |
| :--- | :--- | :--- |
| `<constructor>` | `<idArg>`, `<arg>` (`column`, `javaType`, `name`) | Injects columns into a constructor or Java `record` canonical constructor. |
| `<id>` | `property`, `column`, `javaType`, `jdbcType`, `typeHandler` | Primary key mapping; critical for nested join de-duplication performance. |
| `<result>` | `property`, `column`, `javaType`, `jdbcType`, `typeHandler` | Standard column-to-field/setter mapping. |
| `<association>` | `property`, `javaType`, `resultMap`, `select`, `columnPrefix`, `fetchType` | `1:1` nested object mapping (either nested `SELECT` or single-query `JOIN`). |
| `<collection>` | `property`, `ofType`, `javaType`, `resultMap`, `select`, `columnPrefix` | `1:N` collection mapping (`ofType` specifies the element type inside `List<E>`). |
| `<discriminator>` | `column`, `javaType`, `<case value="..." resultMap="..."/>` | Switches the active `ResultMap` dynamically based on a discriminator column value. |

## `xml` <if>, <choose>, <when>, <otherwise>, <where>, <set>, <trim>, <foreach> & <bind>

Dynamic SQL XML tags (`org.apache.ibatis.scripting.xmltags`) evaluated via OGNL:

| XML Tag | Key Attributes | Behavior & SQL Generation |
| :--- | :--- | :--- |
| `<if>` | `test="ognlExpr"` | Includes body when OGNL `test` evaluates to `true`. |
| `<choose>` / `<when>` / `<otherwise>` | `test="ognlExpr"` on `<when>` | `switch/case` conditional: applies the first matching `<when>`, or `<otherwise>`. |
| `<where>` | — | Inserts `WHERE` if body is non-empty and strips any leading `AND ` or `OR `. |
| `<set>` | — | Inserts `SET` for `UPDATE` statements and strips trailing commas `,`. |
| `<trim>` | `prefix`, `prefixOverrides`, `suffix`, `suffixOverrides` | Custom `<where>` / `<set>` generalization (`TrimSqlNode`). |
| `<foreach>` | `collection`, `item`, `index`, `open`, `separator`, `close`, `nullable` | Iterates over a `List`, `Set`, array, or `Map` (e.g., `WHERE id IN (?,?,?)`). |
| `<bind>` | `name="varName"`, `value="ognlExpr"` | Binds an OGNL expression into the `DynamicContext` scope (e.g., `<bind name="pat" value="'%' + q + '%'"/>`). |
| `<sql>` & `<include>` | `<sql id="...">`, `<include refid="...">` | Defines reusable SQL fragments with `<property name="..." value="..."/>` parameter substitution. |

## `xml` <cache> & <cache-ref>

Configures the L2 cache for the current mapper namespace (`<cache eviction="LRU" flushInterval="60000" size="512" readOnly="false" blocking="false"/>`) or shares another namespace's cache (`<cache-ref namespace="com.example.UserMapper"/>`).
