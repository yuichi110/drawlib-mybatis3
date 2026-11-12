# MyBatis 3 User Guide & Visual Documentation Suite

Welcome to the unofficial visual documentation and engineering suite for **[MyBatis 3](https://mybatis.org/mybatis-3/) (`v3.6.0`)**—the premier SQL-first persistence framework for Java—built with **[PNI501](https://pypi.org/project/pni501/)** and **[Drawlib](https://www.drawlib.com/)**.

Unlike monolithic Object-Relational Mappers (ORMs) that hide SQL behind opaque object-graph query languages, **MyBatis couples Java methods directly to hand-crafted SQL statements** via XML or Java annotations, while eliminating nearly 100% of raw JDBC `PreparedStatement` binding and `ResultSet` extraction boilerplate.

```drawlib align=center code=fold file=ug_index_overview.png caption="MyBatis 3 v3.6.0 — End-to-End SQL Mapping Workflow (Java Interface -> BoundSql -> JDBC -> Domain Record)"
from drawlib.canvas import save, setup
from drawlib.diagrams.architecture import ArchitectureDiagram, Node, NodeGroup, PhosphorIcon
from drawlib.styles import Colors, Styles

setup(width=144, height=54, dpi=150)

d = ArchitectureDiagram(
    node_style=Styles.Dark,
    node_text_style=Styles.DarkBold.patch(text_size=9.5),
    edge_style=Styles.Dark.patch(line_width=1.5),
    edge_text_style=Styles.DarkBold.patch(text_size=9.0),
    node_card_style=Styles.Neutral.patch(shape_fill_color=Colors.White),
)

app = d.add(
    NodeGroup(
        "1. Application Layer",
        width=36,
        height=44,
        style=Styles.PrimaryNeutral,
        text_style=Styles.DarkBold.patch(text_size=10.2, halign="left", valign="top"),
    ),
    xy=(4, 5),
)
n_if = app.add(
    Node(
        "AuthorMapper\n(Java Interface)",
        icon=PhosphorIcon.CODE,
        width=28,
        height=14,
        style=Styles.White,
        text_style=Styles.WhiteBold.patch(text_size=9.5),
        card_style=Styles.PrimaryFlat,
    ),
    xy=(18, 29),
)
n_rec = app.add(Node("Author Record /\nDomain DTO", icon=PhosphorIcon.CUBE, width=28, height=13), xy=(18, 11))

core = d.add(
    NodeGroup(
        "2. MyBatis 3 Runtime Engine (org.apache.ibatis)",
        width=62,
        height=44,
        style=Styles.SecondaryNeutral,
        text_style=Styles.DarkBold.patch(text_size=10.2, halign="left", valign="top"),
    ),
    xy=(44, 5),
)
n_xml = core.add(Node("Mapper XML / @Select\n+ Dynamic SQL (OGNL)", icon=PhosphorIcon.FILE_CODE, width=50, height=14), xy=(31, 29))
n_exe = core.add(Node("Executor + TypeHandler\n+ ResultSetHandler", icon=PhosphorIcon.GEAR, width=50, height=13), xy=(31, 11))

db = d.add(
    NodeGroup(
        "3. Relational Database",
        width=30,
        height=44,
        style=Styles.Neutral,
        text_style=Styles.DarkBold.patch(text_size=10.2, halign="left", valign="top"),
    ),
    xy=(110, 5),
)
n_jdbc = db.add(Node("JDBC Connection\nPreparedStatement", icon=PhosphorIcon.PLUGS_CONNECTED, width=24, height=14), xy=(15, 29))
n_sql = db.add(Node("PostgreSQL / MySQL\nOracle / H2", icon=PhosphorIcon.DATABASE, width=24, height=13), xy=(15, 11))

n_if.connect(n_xml, label="MapperProxy")
n_xml.connect(n_exe, label="BoundSql")
n_exe.connect(n_jdbc, label="bind #{} params")
n_jdbc.connect(n_sql, label="SQL")
n_exe.connect(n_rec, label="ResultMap")

d.draw(xy=(0, 0))
save()
```

---

## Explore the 4-Portal Documentation Suite

This site is organized into four interconnected portals covering usage, reference, internals, and quality diagnostics:

| Portal | Scope & Audience | URL |
| :--- | :--- | :--- |
| **1. User Guide** *(Current Portal)* | Practical tutorials, XML & Annotation patterns, Dynamic SQL, `<resultMap>`, caching, transactions, and plugins | [`/user_guide/`](index.md) |
| **2. API & XML Reference Catalog** | Searchable `/` reference for every public Java class, interface, annotation, and XML DTD element | [`/api/`](https://mybatis3.drawlib.com/api/) |
| **3. Internal Architecture Guide** | Source-level deep dive into `MapperProxy`, `CachingExecutor`, `DynamicSqlSource`, and `DefaultResultSetHandler` | [`/architecture/`](https://mybatis3.drawlib.com/architecture/) |
| **4. PNI501 Diagnostic Report** | 15-stage automated & expert architecture audit (`90/100`, Grade **S**) in HTML & printable PDF | [`/pni501/`](https://mybatis3.drawlib.com/pni501/) |

```drawlib align=center code=fold file=ug_index_portals.png caption="The Four Portals of mybatis3.drawlib.com"
from drawlib.canvas import save, setup
from drawlib.smartarts import CardList
from drawlib.styles import Colors, Styles

setup(width=144, height=40, dpi=150)

cards = CardList(
    style=Styles.Neutral.patch(shape_fill_color=Colors.White),
    text_style=Styles.DarkBold.patch(text_size=10.2),
    description_style=Styles.Dark.patch(text_size=8.8),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.2),
    direction="horizontal",
    spacing=2.5,
)

cards.add(
    "1. User Guide",
    "SqlSession lifecycle, XML & Annotations,\nResultMaps, Dynamic SQL & Caching",
    badge_text="GUIDE",
)
cards.add(
    "2. API & XML Catalog",
    "40+ Core classes/SPIs, 39 Annotations,\nConfig & Mapper DTDs with '/' search",
    badge_text="API",
)
cards.add(
    "3. Architecture Guide",
    "22-package layering, JDK Proxy, OGNL,\nL1/L2 Cache & ResultSet Automapper",
    badge_text="ARCH",
)
cards.add(
    "4. PNI501 Audit Report",
    "15-Stage Evaluation (Score 90/100, S):\nSecurity, Threading & Test Metrics",
    badge_text="AUDIT",
)

cards.draw((4.0, 4.0), width=136.0, height=32.0, align="bottom_left")
save()
```

---

## 60-Second Quickstart

### 1. Add Maven Dependency

```xml
<dependency>
  <groupId>org.mybatis</groupId>
  <artifactId>mybatis</artifactId>
  <version>3.6.0</version>
</dependency>
```

### 2. Define a Java Record & Mapper Interface

MyBatis 3 natively maps SQL columns directly into immutable Java `record` canonical constructors:

```java
package com.example.blog;

import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Options;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

public record Author(Long id, String username, String email, LocalDateTime createdAt) {}

public interface AuthorMapper {

  @Select("""
      SELECT id, username, email, created_at AS createdAt
      FROM authors
      WHERE id = #{id}
      """)
  Author findById(@Param("id") long id);

  @Select("""
      SELECT id, username, email, created_at AS createdAt
      FROM authors
      WHERE username LIKE #{pattern}
      ORDER BY id ASC
      """)
  List<Author> searchByUsername(@Param("pattern") String pattern);
}
```

### 3. Bootstrap `SqlSessionFactory` and Execute Queries

Build `SqlSessionFactory` **once** at application startup, then open short-lived `SqlSession` instances inside `try-with-resources` blocks per request:

```java
import javax.sql.DataSource;
import org.apache.ibatis.mapping.Environment;
import org.apache.ibatis.session.Configuration;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory;

// 1. Application-scoped singleton initialization
DataSource dataSource = createHikariDataSource();
Environment environment = new Environment("prod", new JdbcTransactionFactory(), dataSource);

Configuration config = new Configuration(environment);
config.setMapUnderscoreToCamelCase(true); // Maps created_at -> createdAt automatically
config.addMapper(AuthorMapper.class);

SqlSessionFactory sessionFactory = new SqlSessionFactoryBuilder().build(config);

// 2. Per-request execution using try-with-resources
try (SqlSession session = sessionFactory.openSession()) {
  AuthorMapper mapper = session.getMapper(AuthorMapper.class);
  Author author = mapper.findById(42L);
  System.out.println("Loaded author: " + author);
}
```

---

## Chapter Roadmap

1. **[1. Installation & SqlSession Lifecycle](01_getting_started.md)**: Maven/Gradle setup, `SqlSessionFactoryBuilder` -> `SqlSessionFactory` -> `SqlSession` -> `Mapper` thread-safety rules, and `try-with-resources`.
2. **[2. XML Configuration (`mybatis-config.xml`)](02_xml_configuration.md)**: Ordering of `<configuration>` elements, essential `<settings>` (`mapUnderscoreToCamelCase`, `localCacheScope`, `defaultFetchSize`), `<typeAliases>`, and `<environments>`.
3. **[3. Mapper XML & SQL Statements](03_mapper_xml_and_sql.md)**: `<select>`, `<insert>`, `<update>`, `<delete>`, auto-generated keys (`useGeneratedKeys="true"` & `<selectKey>`), `#{}` PreparedStatement binding vs `${}` string substitution, and reusable `<sql>` fragments.
4. **[4. ResultMaps, Records & Associations](04_result_maps_and_associations.md)**: `<resultMap>`, immutable Java `record` `<constructor>` mapping, `1:1` `<association>`, `1:N` `<collection>`, and avoiding the N+1 query pitfall with JOIN result maps.
5. **[5. Dynamic SQL & OGNL Tags](05_dynamic_sql.md)**: `<if>`, `<choose>`/`<when>`/`<otherwise>`, `<where>`, `<set>`, `<trim>`, `<foreach>` batch & `IN (...)` clauses, and `<bind>`.
6. **[6. Java Annotations & SQL Builder](06_java_annotations_and_sql_builder.md)**: `@Select`, `@Results`, `@Arg`, `@One`/`@Many`, and dynamic providers (`@SelectProvider` + `org.apache.ibatis.jdbc.SQL`).
7. **[7. L1/L2 Caching, Transactions & Batching](07_caching_and_transactions.md)**: L1 session cache (`localCacheScope`), L2 namespace `<cache>`, `jdk.serialFilter` security, `ExecutorType.BATCH`, and `Cursor<T>` streaming.
8. **[8. TypeHandlers, Plugins & Testing](08_typehandlers_plugins_and_testing.md)**: Custom `BaseTypeHandler<T>`, `@Intercepts` plugins on `Executor`/`StatementHandler`, and integration testing with `ScriptRunner`.
