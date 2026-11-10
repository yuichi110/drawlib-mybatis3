# 5. Deep Dive: Code Quality, Testing & Runtime

MyBatis 3 `v3.6.0` combines disciplined static code hygiene across **393 Java source files** (**23,364 LOC**, **374 classes**, **2,721 methods**) with high-confidence runtime verification. Static AST analysis confirms **100.0% import hygiene** (`0` wildcard or unsorted imports) and **99.9% generic type coverage**, while hermetic `--network=none` container execution (`maven:3.9-eclipse-temurin-21`) verifies **1,990 passing JUnit 5 tests** (`0` failures, `0` errors, `19` skipped out of `2,009` total) with **87.4% measured JaCoCo line coverage** (`9,985 / 11,418` statements) and **82.7% branch coverage**.

```drawlib align=center code=fold file=code_quality_fitness_heatmap.png caption="MyBatis 3 v3.6.0 Core Package × Engineering Quality Dimension Fitness Matrix (0–100 Scale)"
from drawlib.canvas import save, setup
from drawlib.charts.heatmap import HeatmapChart
from drawlib.icons import phosphor
from drawlib.smartarts import KpiCards, Panel
from drawlib.styles import Colors, Styles

setup(width=146, height=70, dpi=150)

heatmap = HeatmapChart(
    styles=[
        Styles.WarningNeutral,
        Styles.SecondaryNeutral,
        Styles.PrimaryNeutral,
        Styles.PrimaryFlat,
    ],
    x_categories=[
        "Type Safety",
        "Line Cov.",
        "Branch Cov.",
        "Maintain.",
        "Imports",
    ],
    axis_line_style=Styles.Muted,
    axis_text_style=Styles.DarkBold.patch(text_size=10.0),
    value_text_style=Styles.DarkBold.patch(text_size=10.0),
    width=91.0,
    height=49.0,
    cell_gap=0.7,
    cell_r=0.6,
    title="Subsystem Fitness Matrix Across 5 Engineering Dimensions",
    title_style=Styles.BlackBold.patch(text_size=11.8),
    value_format="{:.1f}",
)
heatmap.add_row("session/*", [100.0, 91.5, 86.4, 88.0, 100.0])
heatmap.add_row("binding/*", [100.0, 94.8, 89.2, 86.0, 100.0])
heatmap.add_row("executor/*", [100.0, 88.6, 83.5, 82.0, 100.0])
heatmap.add_row("builder/*", [100.0, 89.4, 84.1, 74.0, 100.0])
heatmap.add_row("scripting/*", [99.2, 90.2, 84.8, 70.0, 100.0])
heatmap.add_row("reflection/*", [100.0, 91.0, 86.0, 84.0, 100.0])
heatmap.add_row("type/* & cache/*", [99.8, 86.2, 81.5, 90.0, 100.0])
heatmap.add_row("datasource/*", [100.0, 84.5, 79.0, 72.0, 100.0])

heatmap.draw(xy=(4.5, 16.0))
heatmap.draw_colorbar(
    xy=(30.0, 7.5),
    text_style=Styles.Dark.patch(text_size=10.0),
    length=44.0,
    thickness=2.2,
    label="Normalized Dimension Fitness (0–100)",
)

panel = Panel(
    "AST Static Highlights",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral,
    text_style=Styles.DarkBold.patch(text_size=11.0),
    icon=phosphor.code,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.5,
)
panel.draw((98.5, 6.5), width=42.5, height=58.5)
inner_xy, inner_w, inner_h = panel.get_content_box(
    (98.5, 6.5), width=42.5, height=58.5, padding=(2.5, 2.5)
)

kpis = KpiCards(
    style=Styles.Neutral.patch(shape_fill_color=Colors.White),
    metric_style=Styles.PrimaryBold.patch(text_size=14.0),
    text_style=Styles.DarkBold.patch(text_size=10.2),
    description_style=Styles.Muted.patch(text_size=9.5),
    accent_style=Styles.PrimaryFlat,
    accent_position="left_pill",
    metric_layout="left_column",
    metric_width_ratio=0.38,
    spacing=2.4,
)
kpis.add("100%", "Import Hygiene", "0 wildcard imports")
kpis.add("99.9%", "Type Coverage", "2,721 Java methods")
kpis.add(
    "81.5%",
    "Test Mirror",
    "372 JUnit 5 files",
    accent_style=Styles.SecondaryFlat,
    metric_style=Styles.SecondaryBold.patch(text_size=14.0),
)
kpis.draw(xy=inner_xy, width=inner_w, height=inner_h, columns=1)

save()
```

---

## 5.1 Static Java AST, SIG Maintainability & Operational Readiness

| Metric Category | Metric Name | Measured Value | Engineering Interpretation & Key Code Coordinates |
| :--- | :--- | :---: | :--- |
| **Codebase Volume** | Source Files / LOC / Classes / Methods | `393` / `23,364` / `374` / `2,721` | Compact, cohesive core distributed across `20` packages under `org.apache.ibatis.*` |
| **Import Hygiene** | `import_hygiene_coverage_pct` | **`100.0%`** | `0` wildcard imports (`import foo.*`) and `0` unsorted import groups (enforced via `impsort-maven-plugin`) |
| **Generic Typing** | `type_safety_coverage_pct` | **`99.9%`** | Only `2` raw generic types (`LruCache.java:53`, `OgnlClassResolver.java:32`); `248` `Object` / `@SuppressWarnings("unchecked")` usages at reflection boundaries |
| **Javadoc Coverage** | `docstring_coverage_pct` | `16.3%` | `1,050` missing public Javadocs, `233` stubs, and `24` `@param` name mismatches (`AbstractSQL.java`, `ResolverUtil.java`, `MapperBuilderAssistant.java`) |
| **SIG Complexity** | `complex_functions_count` | `59` | Led by `DefaultParameterHandler.setParameters` (`cognitive=129`), `PooledDataSource.popConnection` (`78`), `CacheBuilder.setCacheProperties` (`69`), `MapperAnnotationBuilder.getReturnType` (`68`) |
| **SIG Interfacing** | `excessive_parameters_count` (`>6`) | `17` | `MapperBuilderAssistant.addMappedStatement` (`22`, `20`, `19` params) and `buildResultMapping` (`14`, `11` params) |
| **Coupling & Cycles** | `circular_dependencies_count` | `22` | `4` cross-package cycles (`@Arg/@Case -> UnknownTypeHandler -> Configuration -> MapperRegistry -> MapperAnnotationBuilder`) + `18` intra-package cycles |
| **Static State & Idioms** | `global_state_usages` / `bug_risk_idioms` | `9` / `5` | `JBoss6VFS.java:39-85` reflective cache fields, `Resources.charset`, `SerialFilterChecker.firstInvocation`, `LogFactory.logConstructor`; `StdOutImpl.java` opt-in console logger |
| **12-Factor / SRE PRR** | `missing_io_timeouts` / `env_access` | `5` / `1` | `DefaultVFS.java:67-341` and `Resources.java:273` open local classpath JAR/file `URL` streams; `SerialFilterChecker.java:37` reads `jdk.serialFilter` |

---

## 5.2 Hermetic Container Runtime Verification & JaCoCo Coverage Analysis

All 4 runtime verification gates (`RV-01` through `RV-04`) executed inside a hermetic `maven:3.9-eclipse-temurin-21` container (`.pni/dockerfiles/root/Dockerfile`) under `--network=none`, `--memory=2g`, `--cpus=2`, and non-root UID execution:

```drawlib align=center code=fold file=runtime_coverage_breakdown.png caption="MyBatis 3 v3.6.0 — Hermetic Container Runtime Verification KPIs & Lowest-Covered Legacy/Fallback Classes"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import KpiCards, Panel, Table
from drawlib.styles import Colors, Styles

setup(width=146, height=74, dpi=150)

left_panel = Panel(
    "Runtime Gates",
    "JDK 21 · Offline",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=10.8),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.check_circle,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.0,
)
left_panel.draw((4.0, 4.5), width=54.0, height=65.0, align="bottom_left")
l_xy, l_w, l_h = left_panel.get_content_box(
    (4.0, 4.5), width=54.0, height=65.0, padding=(2.6, 2.5), align="bottom_left"
)

kpis = KpiCards(
    style=Styles.Neutral.patch(shape_fill_color=Colors.White),
    metric_style=Styles.PrimaryBold.patch(text_size=13.5),
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    accent_style=Styles.SuccessFlat,
    accent_position="left_pill",
    metric_layout="left_column",
    metric_width_ratio=0.34,
    spacing=2.2,
)
kpis.add("PASSED", "RV-01 Harness Build", "maven:3.9-temurin-21")
kpis.add("1,990", "RV-02 Offline Tests", "0 failed · 19 skipped")
kpis.add("87.4%", "RV-03 Line Coverage", "9,985 stmts · 82.7% br")
kpis.add("PASSED", "RV-04 Smoke Probe", "Library artifact ok")
kpis.draw(xy=l_xy, width=l_w, height=l_h, columns=1, align="bottom_left")

right_panel = Panel(
    "Lowest-Covered Modules",
    "CGLIB & Fallback Loggers",
    style=Styles.White,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=10.8),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.table,
    icon_style=Styles.DarkBold,
    header_variant="filled",
    header_height=8.0,
)
right_panel.draw((61.0, 4.5), width=81.0, height=65.0, align="bottom_left")

tbl = Table(
    cell_style=Styles.White,
    text_style=Styles.Dark.patch(text_size=9.5),
    header_cell_style=Styles.PrimaryFlat,
    header_text_style=Styles.WhiteBold.patch(text_size=9.8),
    border_style=Styles.MutedThin,
)
tbl.set_style_cell_evenodd(
    even_color=Colors.Gray1,
    even_text_style=Styles.Dark.patch(text_size=9.5),
    odd_color=Colors.White,
    odd_text_style=Styles.Dark.patch(text_size=9.5),
)
tbl.set_style_cell_header(
    background_color=Colors.Dark,
    text_style=Styles.WhiteBold.patch(text_size=9.8),
)

cov_rows = [
    ["Class (org.apache.ibatis.*)", "Line", "Stmts", "Architectural Context"],
    ["CglibProxyFactory.java", "0.0%", "0 / 76", "@Deprecated (JDK 16+ skipped)"],
    ["Jdk.java", "0.0%", "0 / 19", "@Deprecated legacy flags"],
    ["Log4j2LoggerImpl.java", "0.0%", "0 / 16", "Log4j2 fallback adapter"],
    ["Slf4jLoggerImpl.java", "0.0%", "0 / 15", "SLF4J fallback adapter"],
    ["BatchExecutorException.java", "0.0%", "0 / 9", "Batch failure accessors"],
    ["CglibSerialStateHolder.java", "0.0%", "0 / 5", "@Deprecated CGLIB holder"],
    ["NullCacheKey.java", "0.0%", "0 / 4", "Sentinel mutation guard"],
    ["ObjectWrapper.java", "0.0%", "0 / 4", "Default interface stubs"],
]

tbl.draw_flexible(
    xy=(63.5, 59.0),
    column_widths=[27.5, 8.5, 9.5, 30.5],
    row_heights=[5.8] + [5.6] * 8,
    data=cov_rows,
    align="top_left",
)

save()
```

### Lowest-Covered Modules (Measured Line & Branch Coverage, Ascending)

| Module Path | Line Coverage | Branch Coverage | Statements Covered | Missing Lines & Root Cause |
| :--- | :---: | :---: | :---: | :--- |
| `src/main/java/org/apache/ibatis/executor/loader/cglib/CglibProxyFactory.java` | `0.0%` | `0.0%` | `0 / 76` | Lines `55..80` — `@Deprecated`; `RequireIllegalAccess` tests excluded on JDK 16+ (`pom.xml:83`) |
| `src/main/java/org/apache/ibatis/reflection/Jdk.java` | `0.0%` | `—` | `0 / 19` | Lines `34..55` — `@Deprecated` compatibility constants from Java 7/8 transition |
| `src/main/java/org/apache/ibatis/logging/log4j2/Log4j2LoggerImpl.java` | `0.0%` | `—` | `0 / 16` | Lines `29..55` — Fallback adapter when Log4j2 `Logger` is not an `AbstractLogger` |
| `src/main/java/org/apache/ibatis/logging/slf4j/Slf4jLoggerImpl.java` | `0.0%` | `—` | `0 / 15` | Lines `28..54` — Fallback adapter when SLF4J `Logger` does not implement `LocationAwareLogger` |
| `src/main/java/org/apache/ibatis/executor/BatchExecutorException.java` | `0.0%` | `—` | `0 / 9` | Lines `37..78` — Diagnostic accessor methods on `BatchExecutorException` |
| `src/main/java/org/apache/ibatis/executor/loader/cglib/CglibSerialStateHolder.java` | `0.0%` | `—` | `0 / 5` | Lines `35..46` — `@Deprecated` companion to `CglibProxyFactory` |
| `src/main/java/org/apache/ibatis/cache/NullCacheKey.java` | `0.0%` | `—` | `0 / 4` | Lines `28..38` — `CacheException` guards when attempting to mutate `CacheKey.NULL_CACHE_KEY` |
| `src/main/java/org/apache/ibatis/reflection/wrapper/ObjectWrapper.java` | `0.0%` | `—` | `0 / 4` | Lines `46..52` — Interface default methods overridden by all concrete `ObjectWrapper` implementations |
