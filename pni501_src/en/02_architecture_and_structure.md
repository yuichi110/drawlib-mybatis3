# 2. Architecture & Source Code Structure

MyBatis 3 (`v3.6.0`) organizes **393 Java source files** (**23,364 LOC**, **374 classes**, **2,721 methods**) across **20 packages** under `org.apache.ibatis.*` into a **3-Tier Layered Data-Mapper & Interceptor Pipeline Architecture** (**86/100**, Grade **A**). Rather than imposing an invasive entity state manager like full JPA/Hibernate ORMs, MyBatis compiles XML descriptors (`mybatis-config.xml`, `*Mapper.xml`) and Java interface annotations (`@Select`, `@Insert`, `@Results`) at bootstrap time into immutable `MappedStatement` and `ResultMap` registries inside `Configuration`, and executes SQL through a composable `Executor -> StatementHandler -> ParameterHandler -> ResultSetHandler` pipeline.

```drawlib align=center code=fold file=arch_source_tree.png caption="MyBatis 3 v3.6.0 Source Package Tree & 20-Package Subsystem Inventory (393 Files, 23,364 LOC)"
from drawlib.canvas import save, setup
from drawlib.fonts import FontMonoSpace, FontRoboto
from drawlib.icons import phosphor
from drawlib.smartarts import Panel, Table, TreeNode
from drawlib.styles import Colors, Styles
from drawlib.text import text

setup(width=146, height=84, dpi=150)

text(
    (73.0, 80.2),
    "MyBatis 3 v3.6.0 — Physical Package Layout & Subsystem Inventory (393 Files · 23,364 LOC)",
    style=Styles.DarkBold.patch(text_font=FontRoboto.ROBOTO_BOLD, text_size=12.5),
)

left_panel = Panel(
    "Package Tree",
    "20 Packages",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_font=FontRoboto.ROBOTO_BOLD, text_size=10.8),
    description_style=Styles.Muted.patch(text_font=FontRoboto.ROBOTO_REGULAR, text_size=9.5),
    icon=phosphor.folder_open,
    icon_style=Styles.DarkBold,
    header_variant="filled",
    header_height=7.8,
)
left_panel.draw((4.0, 4.5), width=56.0, height=72.0, align="bottom_left")

TreeNode.register_drawing_item(
    name="pkg_dir",
    location="before",
    padding_width=3.8,
    function=phosphor.folder,
    style=Styles.Primary.patch(icon_color=Colors.Primary, icon_style="fill"),
    args={"width": 2.7},
)
TreeNode.register_drawing_item(
    name="java_mod",
    location="before",
    padding_width=3.8,
    function=phosphor.file_code,
    style=Styles.Dark.patch(icon_color=Colors.Dark),
    args={"width": 2.6},
)

root = TreeNode(
    "org/apache/ibatis/ (393 files · 23.4K LOC)",
    text_style=Styles.DarkBold.patch(text_font=FontMonoSpace.ROBOTO_MONO_BOLD, text_size=9.5),
    line_style=Styles.Muted.patch(line_width=1.1),
    line_horizontal_margin=2.2,
    line_horizontal_length=2.4,
    line_vertical_margin=3.95,
).set_drawing_item("pkg_dir")

mod_text = Styles.Dark.patch(text_font=FontMonoSpace.ROBOTO_MONO_REGULAR, text_size=9.5)
sub_text = Styles.DarkBold.patch(text_font=FontMonoSpace.ROBOTO_MONO_BOLD, text_size=9.5)

root.add("session/ (17 files · Configuration)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("binding/ (6 files · MapperProxy)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("annotations/ (39 files · @Select)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("builder/ (26 files · XML & Ann.)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("mapping/ (18 files · MappedStatement)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("scripting/ (25 files · OGNL SqlNode)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("executor/ (50 files · L1/L2 & JDBC)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("plugin/ (7 files · Interceptor SPI)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("reflection/ (36 files · MetaObject)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("type/ (74 files · 45+ TypeHandlers)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("cache/ (15 files · Lru/Transactional)", text_style=sub_text).set_drawing_item("pkg_dir")
root.add("datasource/ & transaction/ (22 files)", text_style=mod_text).set_drawing_item("java_mod")
root.add("io/, parsing/, jdbc/, cursor/, logging/", text_style=mod_text).set_drawing_item("java_mod")

root.draw(xy=(6.5, 66.5))

right_panel = Panel(
    "Core Subsystems by Architectural Tier",
    "Files, Tier & Key Classes",
    style=Styles.White,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_font=FontRoboto.ROBOTO_BOLD, text_size=10.8),
    description_style=Styles.White.patch(text_font=FontRoboto.ROBOTO_REGULAR, text_size=9.5),
    icon=phosphor.table,
    icon_style=Styles.White,
    header_variant="filled",
    header_height=7.8,
)
right_panel.draw((63.0, 4.5), width=79.0, height=72.0, align="bottom_left")

tbl_body = Styles.Dark.patch(text_font=FontRoboto.ROBOTO_REGULAR, text_size=9.5)
tbl_code = Styles.DarkBold.patch(text_font=FontMonoSpace.ROBOTO_MONO_REGULAR, text_size=9.5)
tbl_hdr = Styles.DarkBold.patch(text_font=FontRoboto.ROBOTO_BOLD, text_size=9.8)

tbl = Table(
    cell_style=Styles.White,
    text_style=tbl_body,
    header_cell_style=Styles.SecondaryNeutral,
    header_text_style=tbl_hdr,
    border_style=Styles.MutedThin,
)
tbl.set_style_cell_evenodd(
    even_color=Colors.Light,
    even_text_style=tbl_body,
    odd_color=Colors.White,
    odd_text_style=tbl_body,
)
tbl.set_style_cell_header(
    background_color=Colors.SecondaryNeutral,
    text_style=tbl_hdr,
)
tbl.set_style_cell(
    background_color=Colors.Light,
    text_style=tbl_code,
    rows=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    columns=[0],
)

inventory_rows = [
    ["Package", "Tier", "Files", "Key Classes & Responsibility"],
    ["session + binding", "T1", "23", "SqlSession, Configuration, MapperProxy"],
    ["annotations + jdbc", "T1", "49", "@Select/@Results, SQL builder, ScriptRunner"],
    ["builder (xml/ann)", "T2", "26", "XMLConfigBuilder, MapperAnnotationBuilder"],
    ["mapping + plugin", "T2", "25", "MappedStatement, ResultMap, Interceptor"],
    ["scripting (xmltags)", "T2", "25", "DynamicSqlSource, SqlNode AST, OgnlCache"],
    ["executor/*", "T2", "50", "CachingExecutor, BaseExecutor, ResultSetHandler"],
    ["reflection/*", "T3", "36", "MetaObject, Reflector, ObjectWrapper, Invoker"],
    ["type/*", "T3", "74", "TypeHandlerRegistry & 45+ JDBC TypeHandlers"],
    ["cache/* + tx/*", "T3", "22", "PerpetualCache, LruCache, TransactionalCache"],
    ["datasource + io", "T3", "63", "PooledDataSource, XPathParser, VFS, LogFactory"],
]

tbl.draw_flexible(
    xy=(65.5, 66.5),
    column_widths=[23.0, 6.0, 7.5, 37.5],
    row_heights=[5.8] + [5.4] * 10,
    data=inventory_rows,
    align="top_left",
)

save()
```

---

## 2.1 3-Tier Package Topology & Thermal Risk Heatmap Overlay

MyBatis 3's 20 packages stratify into three architectural tiers:
- **Tier 1 — Public Session, Annotation & Dynamic Proxy Binding Layer** (`session`, `binding`, `annotations`, `cursor`, `jdbc`): Exposes `SqlSessionFactoryBuilder`, `SqlSessionFactory`, `SqlSession`, `MapperRegistry`, and `MapperProxyFactory<T>`.
- **Tier 2 — Core Configuration Builder, Mapping, Scripting & Executor Layer** (`builder`, `mapping`, `scripting`, `executor`, `plugin`): Compiles XML and annotation mappers into `MappedStatement` / `ResultMap` instances, evaluates OGNL `SqlNode` trees into `BoundSql`, and orchestrates L1/L2 cached JDBC execution wrapped by `Plugin.wrap()` interceptor chains.
- **Tier 3 — Foundation Reflection, Type, Cache, Transaction & IO Layer** (`reflection`, `type`, `cache`, `transaction`, `datasource`, `parsing`, `io`, `logging`, `exceptions`): Provides self-contained infrastructure (`MetaObject`, `Reflector`, `TypeHandlerRegistry`, `PerpetualCache` decorators, `PooledDataSource`, `XPathParser`, `VFS`, `LogFactory`).

```drawlib align=center code=fold file=arch_layer_heatmap.png caption="MyBatis 3 v3.6.0 — 3-Tier Component Dependency Graph with Thermal Risk Overlay (Hotspots: CglibProxyFactory=0.30, DefaultParameterHandler=0.27, PooledDataSource=0.27)"
from drawlib.canvas import save, setup
from drawlib.charts.heatmap import HeatmapOverlay
from drawlib.diagrams.class_diagram import ClassDiagram, ClassNode
from drawlib.fonts import FontMonoSpace, FontRoboto
from drawlib.shapes import rectangle
from drawlib.styles import Colors, Styles
from drawlib.text import text

setup(width=146, height=112, dpi=150)

text(
    (73.0, 107.5),
    "MyBatis 3 v3.6.0 — 3-Tier Component Dependency DAG & Thermal Risk Overlay",
    style=Styles.DarkBold.patch(text_font=FontRoboto.ROBOTO_BOLD, text_size=12.5),
)

tier_specs = [
    (88.0, "Tier 1", "Session & Proxy"),
    (54.0, "Tier 2", "Builder & Exec"),
    (20.0, "Tier 3", "Refl, Type & Pool"),
]
lane_style = Styles.Neutral.patch(
    shape_fill_color=Colors.Gray1.patch(alpha=0.45),
    shape_line_color=Colors.Gray3,
    shape_line_width=0.8,
    shape_r=1.5,
)
badge_style = Styles.SecondaryNeutral.patch(shape_r=1.5, shape_line_width=1.0)

for cy, t_num, t_sub in tier_specs:
    rectangle((87.5, cy), width=110.0, height=22.0, style=lane_style)
    rectangle((16.5, cy), width=22.0, height=14.0, style=badge_style)
    text(
        (16.5, cy + 2.5),
        t_num,
        style=Styles.DarkBold.patch(text_font=FontRoboto.ROBOTO_BOLD, text_size=10.5),
    )
    text(
        (16.5, cy - 2.5),
        t_sub,
        style=Styles.Muted.patch(text_font=FontRoboto.ROBOTO_REGULAR, text_size=9.5),
    )

cd = ClassDiagram(
    width=146.0,
    height=112.0,
    node_style=Styles.Neutral.patch(
        shape_fill_color=Colors.White,
        shape_line_color=Colors.Gray6,
        text_color=Colors.Dark,
        text_font=FontMonoSpace.ROBOTO_MONO_REGULAR,
        text_size=9.5,
    ),
    header_style=Styles.PrimaryNeutral.patch(
        shape_line_color=Colors.Gray6,
        text_color=Colors.Dark,
        text_font=FontRoboto.ROBOTO_BOLD,
        text_size=10.0,
    ),
    edge_style=Styles.Dark.patch(line_width=1.5),
    edge_text_style=Styles.DarkBold.patch(text_font=FontRoboto.ROBOTO_BOLD, text_size=9.5),
)

hero_hdr = Styles.PrimaryFlat.patch(
    text_color=Colors.White,
    text_font=FontRoboto.ROBOTO_BOLD,
    text_size=10.0,
)
sec_hdr = Styles.SecondaryNeutral.patch(
    shape_line_color=Colors.Gray6,
    text_color=Colors.Dark,
    text_font=FontRoboto.ROBOTO_BOLD,
    text_size=10.0,
)

# Tier 1 (cy=88.0)
n_session = cd.add(
    ClassNode("DefaultSqlSession & Proxy", width=44.0, header_style=hero_hdr)
    .add_attribute("pkg", "session + binding (23 files)")
    .add_method("getMapper / selectList", "stmt", "List<E>"),
    xy=(58.0, 88.0),
)
n_config = cd.add(
    ClassNode("Configuration  [Hub]", width=43.0, header_style=sec_hdr)
    .add_attribute("pkg", "session/Configuration.java")
    .add_method("newExecutor / getMappedStmt", "", "Executor"),
    xy=(114.5, 88.0),
)

# Tier 2 (cy=54.0)
n_exec = cd.add(
    ClassNode("Executor & Loader  [0.30]", width=44.0)
    .add_attribute("pkg", "executor/* (50 files)")
    .add_method("query / readResolve", "ms", "List<E>"),
    xy=(58.0, 54.0),
)
n_script = cd.add(
    ClassNode("ParamHandler & Builder [0.27]", width=43.0)
    .add_attribute("pkg", "scripting + builder (51 files)")
    .add_method("setParameters [cog=129]", "ps", "void"),
    xy=(114.5, 54.0),
)

# Tier 3 (cy=20.0)
n_refl = cd.add(
    ClassNode("MetaObject & Type  [0.16]", width=44.0, header_style=sec_hdr)
    .add_attribute("pkg", "reflection + type (110 files)")
    .add_method("setValue / getTypeHandler", "prop", "Object"),
    xy=(58.0, 20.0),
)
n_pool = cd.add(
    ClassNode("PooledDataSource & IO [0.27]", width=43.0)
    .add_attribute("pkg", "datasource + io (33 files)")
    .add_method("popConnection [cog=78]", "u, p", "Conn"),
    xy=(114.5, 20.0),
)

cd.connect(n_session, n_config, "association", directed=True, start_side="right", end_side="left")
cd.connect(n_session, n_exec, "composition", directed=True, start_side="bottom", end_side="top")
cd.connect(n_script, n_config, "dependency", start_side="top", end_side="bottom")
cd.connect(n_exec, n_script, "dependency", start_side="right", end_side="left")
cd.connect(n_exec, n_refl, "dependency", start_side="bottom", end_side="top")
cd.connect(n_script, n_pool, "dependency", start_side="bottom", end_side="top")
cd.connect(n_refl, n_pool, "dependency", start_side="right", end_side="left")

cd.draw(xy=(0.0, 0.0))

overlay = HeatmapOverlay(
    styles=[Styles.PrimaryNeutral, Styles.WarningFlat, Styles.DangerFlat],
    width=146.0,
    height=112.0,
    mode="smooth",
    min_value=0.0,
    max_value=0.35,
    max_alpha=0.32,
    show_contour_lines=False,
)
overlay.add_spot(n_exec, value=0.30, radius=18.0)
overlay.add_spot(n_script, value=0.27, radius=18.0)
overlay.add_spot(n_pool, value=0.27, radius=18.0)
overlay.add_spot(n_refl, value=0.16, radius=15.0)
overlay.draw(xy=(0.0, 0.0))

save()
```

### Pre-Sorted Module Hotspots (`HeatmapOverlay` Exact Risk Scores)

| Module Path | LOC | Risk Score | Findings | Triggered Rules & Primary Risk Driver |
| :--- | :---: | :---: | :---: | :--- |
| `src/main/java/org/apache/ibatis/executor/loader/cglib/CglibProxyFactory.java` | `174` | **`0.30`** | `1` (`info`) | `common/runtime_verification` — Deprecated legacy CGLIB proxy factory (`0.0%` coverage on JDK 21 due to `RequireIllegalAccess` exclusion) |
| `src/main/java/org/apache/ibatis/datasource/pooled/PooledDataSource.java` | `445` | **`0.27`** | `1` (`medium`) | `common/maintainability` — `popConnection` has cognitive complexity `78` (`117` lines, `21` branches) |
| `src/main/java/org/apache/ibatis/scripting/defaults/DefaultParameterHandler.java` | `171` | **`0.27`** | `1` (`medium`) | `common/maintainability` — `setParameters` has cognitive complexity `129` (`93` lines, `22` branches) |
| `src/main/java/org/apache/ibatis/executor/loader/AbstractSerialStateHolder.java` | `94` | **`0.27`** | `1` (`medium`) | `common/security_vulnerability` — `ObjectInputStream` deserialization (`CWE-502`) guarded by warn-only `SerialFilterChecker.check()` |
| `src/main/java/org/apache/ibatis/io/SerialFilterChecker.java` | `30` | **`0.20`** | `1` (`low`) | `common/security_vulnerability` — Logs one-time warning when JEP-290 `jdk.serialFilter` is unset; static `firstInvocation` flag |
| `src/main/java/org/apache/ibatis/logging/log4j2/Log4j2LoggerImpl.java` | `41` | **`0.16`** | `0` | Fallback non-`LocationAware` Log4j2 logger implementation (`0.0%` default test coverage) |
| `src/main/java/org/apache/ibatis/reflection/Jdk.java` | `39` | **`0.16`** | `0` | Legacy deprecated JDK capability flags (`0.0%` coverage) |
| `src/main/java/org/apache/ibatis/logging/slf4j/Slf4jLoggerImpl.java` | `37` | **`0.16`** | `0` | Fallback non-`LocationAwareLogger` SLF4J wrapper (`0.0%` default test coverage) |

---

## 2.2 End-to-End Runtime Execution Flows & Concurrency Model

MyBatis 3 separates its runtime into three primary execution flows: (1) **Bootstrap Compilation** (`SqlSessionFactoryBuilder` -> `XMLConfigBuilder` / `MapperAnnotationBuilder` -> `Configuration`), (2) **Mapper Proxy & L1/L2 Cache Query Execution** (`MapperProxy` -> `MapperMethod` -> `DefaultSqlSession` -> `CachingExecutor` -> `BaseExecutor` -> `PreparedStatementHandler`), and (3) **ResultSet Hydration & Lazy Proxy Loading** (`DefaultResultSetHandler` -> `MetaObject` / `Reflector` / `JavassistProxyFactory`).

```drawlib align=center code=fold file=arch_execution_flows.png caption="MyBatis 3 v3.6.0 — 3 Core End-to-End Execution Flows (Bootstrap Compilation, L1/L2 Cached Query Pipeline, and ResultSet Hydration)"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import Panel, Roadmap
from drawlib.styles import Styles

setup(width=146, height=66, dpi=150)

panel = Panel(
    "MyBatis 3 v3.6.0 — End-to-End Execution Pipeline",
    "XML/Annotation Bootstrap -> Proxy Dispatch -> L1/L2 Cache -> Hydration",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.2),
    description_style=Styles.Muted.patch(text_size=9.6),
    icon=phosphor.flow_arrow,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.5,
)
panel.draw((4.0, 4.5), width=138.0, height=57.0, align="bottom_left")
inner_xy, inner_w, inner_h = panel.get_content_box(
    (4.0, 4.5), width=138.0, height=57.0, padding=(3.0, 2.5), align="bottom_left"
)

rm = Roadmap(
    style=Styles.White,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    spine_style=Styles.PrimaryBold,
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
    icon_style=Styles.PrimaryBold,
    direction="vertical",
    curve_bend=0.0,
    card_shape="rounded_rect",
    spacing=2.6,
)

rm.add(
    "Flow 1: Bootstrap Configuration & Mapper Compilation",
    "SqlSessionFactoryBuilder -> XMLConfigBuilder & MapperAnnotationBuilder -> MappedStatement in Configuration.",
    badge_text="F1",
    icon=phosphor.file_code,
)
rm.add(
    "Flow 2: Mapper Proxy Dispatch & L1/L2 Cache Execution",
    "getMapper() -> MapperProxy -> DefaultSqlSession -> CachingExecutor (L2) -> BaseExecutor (L1) -> JDBC.",
    badge_text="F2",
    icon=phosphor.lightning,
    style=Styles.PrimaryNeutral,
)
rm.add(
    "Flow 3: ResultSet Mapping, Nested Joins & Lazy Hydration",
    "DefaultResultSetHandler -> ResultSetWrapper -> ObjectFactory -> MetaObject & JavassistProxyFactory.",
    badge_text="F3",
    icon=phosphor.database,
    style=Styles.SecondaryNeutral,
    badge_style=Styles.SecondaryFlat,
    icon_style=Styles.SecondaryBold,
)

rm.draw(xy=inner_xy, width=inner_w, height=inner_h, align="bottom_left")

save()
```

### State Management, Error Translation & Thread-Safety Contract

| Runtime Mechanism | Scope & Concurrency Contract | Key Implementation Classes |
| :--- | :--- | :--- |
| **`Configuration` Registry** | **Application-scoped (Thread-Safe after bootstrap)**: Stores `StrictMap` and `ConcurrentHashMap` registries of `MappedStatement`, `ResultMap`, `Cache`, `TypeHandler`, and `MapperProxyFactory`. | `Configuration`, `MapperRegistry`, `DefaultReflectorFactory`, `OgnlCache` |
| **L2 Namespace Cache** | **Application/Namespace-scoped (Transactional)**: Buffers reads/writes per session inside `TransactionalCache` (`TransactionalCacheManager`) and flushes to `LruCache` / `SerializedCache` / `SynchronizedCache` only upon `SqlSession.commit()`. | `CachingExecutor`, `TransactionalCacheManager`, `TransactionalCache`, `CacheBuilder` |
| **L1 Local Cache** | **Request/`SqlSession`-scoped (Single-Thread Confined)**: `PerpetualCache` inside `BaseExecutor` (`SESSION` or `STATEMENT` scope), automatically cleared on any `insert`/`update`/`delete`/`commit`/`rollback`. | `BaseExecutor`, `PerpetualCache`, `LocalCacheScope` |
| **`ErrorContext` & Exceptions** | **ThreadLocal Breadcrumbs**: `ErrorContext.instance()` records the active XML resource, `MappedStatement` ID, SQL string, and cause before `ExceptionFactory.wrapException()` translates checked `SQLException`s into unchecked `PersistenceException` subclasses. | `ErrorContext`, `ExceptionFactory`, `PersistenceException` |
