# 6. Deep Dive: Security, Supply Chain & API Surface

MyBatis 3 `v3.6.0` exhibits a strong security and supply-chain posture (`security_vulnerability_audit`: **91/100, Grade S**; `security` axis: **91/100**; `dependencies` axis: **93/100**). Containerized Trivy `0.69.3` scanning (`engine=docker`, `scanned_filesystem=True`) across `pom.xml` and `dependencies-lock.json` confirmed **zero `CRITICAL`, `HIGH`, `MEDIUM`, or `LOW` CVEs** across all 9 direct and optional dependencies, **zero Dockerfile/IaC misconfigurations**, and **zero leaked secrets**.

```drawlib align=center code=fold file=supply_chain_cve_comparison.png caption="MyBatis 3 v3.6.0 — Trivy 0.69.3 SCA Vulnerability Counts Across Runtime, Dev/Optional Lockfile, and Container OS Scopes"
from drawlib.canvas import save, setup
from drawlib.charts.bar import BarChart
from drawlib.icons import phosphor
from drawlib.smartarts import KpiCards, Panel
from drawlib.styles import Colors, Styles

setup(width=146, height=68, dpi=150)

chart = BarChart(
    axis_line_style=Styles.MutedDashed,
    categories=["CRITICAL", "HIGH", "MEDIUM", "LOW"],
    width=88.0,
    height=46.5,
    title="Trivy 0.69.3 SCA Vulnerability Counts by Artifact Scope & Severity",
    title_style=Styles.BlackBold.patch(text_size=11.8),
    orientation="vertical",
    bar_mode="group",
    bar_width_ratio=0.72,
    bar_r=0.8,
    axis_text_style=Styles.DarkBold.patch(text_size=10.0),
    grid_style=Styles.MutedThin,
    value_text_style=Styles.DarkBold.patch(text_size=9.8),
    value_format="{:.0f}",
)
chart.add_series("Core Runtime JAR (0 mandatory deps)", [0, 0, 0, 0], style=Styles.PrimaryFlat)
chart.add_series("Optional/Dev Lockfile (9 deps)", [0, 0, 0, 0], style=Styles.SecondaryFlat)
chart.add_series("Project Dockerfile OS", [0, 0, 0, 0], style=Styles.Neutral)
chart.configure_y_axis(min_value=0.0, max_value=10.0, tick_step=2.0, label="CVE Count")
chart.draw(xy=(5.5, 15.0))
chart.draw_legend(
    xy=(6.5, 8.0),
    text_style=Styles.DarkBold.patch(text_size=9.6),
    orientation="horizontal",
    item_gap=3.5,
)

panel = Panel(
    "Security Gate Summary",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral,
    text_style=Styles.DarkBold.patch(text_size=11.0),
    icon=phosphor.shield_check,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.5,
)
panel.draw((96.5, 6.0), width=44.0, height=56.5)
r_xy, r_w, r_h = panel.get_content_box(
    (96.5, 6.0), width=44.0, height=56.5, padding=(2.5, 2.5)
)

kpis = KpiCards(
    style=Styles.Neutral.patch(shape_fill_color=Colors.White),
    metric_style=Styles.SuccessBold.patch(text_size=14.5),
    text_style=Styles.DarkBold.patch(text_size=10.2),
    description_style=Styles.Muted.patch(text_size=9.5),
    accent_style=Styles.SuccessFlat,
    accent_position="left_pill",
    metric_layout="left_column",
    metric_width_ratio=0.32,
    spacing=2.4,
)
kpis.add("0", "App & Lock CVEs", "ognl 3.4.16 · javassist 3.33")
kpis.add("0", "Leaked Secrets", "Trivy + AST literal scan")
kpis.add(
    "1",
    "CWE-502 Sink",
    "Guarded by JEP-290 check",
    accent_style=Styles.WarningFlat,
    metric_style=Styles.WarningBold.patch(text_size=14.5),
)
kpis.draw(xy=r_xy, width=r_w, height=r_h, columns=1)

save()
```

---

## 6.1 Supply-Chain Hygiene, Shaded Packaging & Governance Baseline

MyBatis 3's `pom.xml` and `dependencies-lock.json` enforce a zero-dependency runtime model for downstream applications: every logging adapter and bytecode library is marked `<optional>true</optional>`, while `maven-shade-plugin` (`pom.xml:365-411`) relocates `ognl:ognl:3.4.16` to `org.apache.ibatis.ognl` and `org.javassist:javassist:3.33.0-GA` to `org.apache.ibatis.javassist`.

| Supply-Chain & Security Gate | Metric / Value | Verdict | Architectural & Compliance Evidence |
| :--- | :--- | :---: | :--- |
| **Deterministic Lockfile (`has_lockfile`)** | `True` (`dependencies-lock.json`, `mvnw`) | **`PASS`** | Full Maven dependency lockfile and Maven Wrapper committed |
| **Optional/Provided Dependencies (`dependencies_count`)** | `9` packages (`0` mandatory) | **`PASS`** | All compile/provided dependencies marked `<optional>true</optional>` in `pom.xml` |
| **Unpinned Specifiers (`unpinned_dependencies_count`)** | **`0`** | **`PASS`** | Every dependency in `pom.xml` is pinned to an exact release version |
| **Dual Licensing Clarity (`has_license`)** | `True` | **`PASS`** | Repository Apache-2.0 `LICENSE` + upstream `LICENSE-MYBATIS` and `NOTICE` |
| **Trivy Application & OS CVEs (`vuln_counts.total`)** | **`0`** (`0` C / `0` H / `0` M / `0` L) | **`PASS`** | Clean across `pom.xml` and `dependencies-lock.json` (`trivy:0.69.3`) |
| **Committed / Hardcoded Secrets** | **`0` files / `0` literals** | **`PASS`** | Zero credential artifacts or tokens in source or test suites |
| **AST Dangerous Sinks (`ast_dangerous_sinks_count`)** | `1` (`CWE-502`) | `WARN` | `AbstractSerialStateHolder.java:110` (`ObjectInputStream`) guarded by warn-only `SerialFilterChecker.check()` |
| **Standalone HTTP Endpoints (`api_endpoints_count`)** | **`0`** | **`N/A`** | Pure Java persistence `library` archetype; exposes zero HTTP routes |
| **Repo Governance (`SECURITY.md` / Dependabot)** | `False` / `False` | `WARN` | Omitted in this standalone documentation snapshot |

### Pinned Dependency Inventory in `pom.xml` (`0` Trivy CVEs)

| Maven Coordinate (`groupId:artifactId`) | Pinned Version | Scope / Optional | Packaging & Architectural Role | Trivy CVEs |
| :--- | :---: | :---: | :--- | :---: |
| `ognl:ognl` | `3.4.16` | `compile` (`optional=true`) | Shaded into `org.apache.ibatis.ognl` for Dynamic SQL `<if>`/`<foreach>` expression evaluation | **`0`** |
| `org.javassist:javassist` | `3.33.0-GA` | `compile` (`optional=true`) | Shaded into `org.apache.ibatis.javassist` for `JavassistProxyFactory` lazy-loading proxies | **`0`** |
| `org.slf4j:slf4j-api` | `2.0.20` | `compile` (`optional=true`) | Primary structured logging bridge (`Slf4jImpl` / `Slf4jLocationAwareLoggerImpl`) | **`0`** |
| `org.apache.logging.log4j:log4j-api` | `2.26.1` | `compile` (`optional=true`) | Apache Log4j 2 logging adapter (`Log4j2Impl`) | **`0`** |
| `ch.qos.reload4j:reload4j` | `1.2.27` | `compile` (`optional=true`) | Security-hardened Log4j 1.x replacement bridge (`Log4jImpl`) | **`0`** |
| `commons-logging:commons-logging` | `1.4.0` | `compile` (`optional=true`) | Apache Commons Logging bridge (`JakartaCommonsLoggingImpl`) | **`0`** |
| `cglib:cglib` | `3.3.0` | `compile` (`optional=true`) | Deprecated legacy bytecode proxy provider (`CglibProxyFactory`) | **`0`** |
| `com.microsoft.sqlserver:mssql-jdbc` | `13.6.1.jre11` | `compile` (`optional=true`) | Optional SQL Server `DateTimeOffsetTypeHandler` support | **`0`** |
| `org.gaul:modernizer-maven-annotations` | `${modernizer.plugin}` | `provided` (`optional=true`) | Compile-time `@SuppressModernizer` annotations | **`0`** |

---

## 6.2 AST Dangerous Code Sinks (CWE SAST), XML Hardening & SQL Injection Defense

Because MyBatis 3 is a persistence library (`api_endpoints_count = 0`), its security surface centers on three internal mechanisms: (1) **Java deserialization in L2 caches and lazy-loading state holders (`CWE-502`)**, (2) **XML configuration/mapper DTD parsing (`CWE-611` XXE prevention)**, and (3) **SQL parameter binding (`#{}` `PreparedStatement` placeholders vs. `${}` string interpolation)**.

```drawlib align=center code=fold file=security_sinks_and_defenses.png caption="MyBatis 3 v3.6.0 — CWE-502 Deserialization Guard, Hardened JAXP XPathParser, and #{} PreparedStatement Defense Architecture"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, Panel, Table
from drawlib.styles import Colors, Styles

setup(width=146, height=70, dpi=150)

white_card = Styles.Neutral.patch(shape_fill_color=Colors.White)

left_panel = Panel(
    "AST Security Sinks",
    "1 CWE-502 · 0 HTTP",
    style=Styles.White,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=10.8),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.magnifying_glass,
    icon_style=Styles.WarningBold,
    header_variant="filled",
    header_height=8.0,
)
left_panel.draw((4.0, 4.5), width=76.0, height=61.0, align="bottom_left")

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

sink_rows = [
    ["Gate / CWE", "Location", "Status", "Mitigation & Guard"],
    [
        "CWE-502\nDeserial.",
        "AbstractSerial-\nStateHolder:110",
        "WARN",
        "SerialFilterChecker.check();\nwarns if serialFilter unset",
    ],
    [
        "CWE-502\nL2 Cache",
        "SerializedCache\n.java:100-102",
        "WARN",
        "SerialFilterChecker.check()\nbefore stream readObject()",
    ],
    [
        "CWE-611\nXXE / DTD",
        "XPathParser\n.java:233-243",
        "PASS",
        "SECURE_PROCESSING=true;\nlocal DTD EntityResolver",
    ],
    [
        "CWE-89\nSQL Bind",
        "SqlSourceBuilder\n& ParamHandler",
        "PASS",
        "#{} binds JDBC '?' params;\n${} for static metadata",
    ],
]

tbl.draw_flexible(
    xy=(6.5, 55.0),
    column_widths=[14.5, 19.0, 8.0, 29.5],
    row_heights=[6.0] + [10.5] * 4,
    data=sink_rows,
    align="top_left",
)

right_panel = Panel(
    "Built-In Safeguards",
    "org.apache.ibatis",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=10.8),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.lock_key,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.0,
)
right_panel.draw((83.0, 4.5), width=59.0, height=61.0, align="bottom_left")
r_xy, r_w, r_h = right_panel.get_content_box(
    (83.0, 4.5), width=59.0, height=61.0, padding=(2.6, 2.5), align="bottom_left"
)

cards = CardList(
    style=white_card,
    text_style=Styles.DarkBold.patch(text_size=10.2),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.0),
    direction="vertical",
    spacing=2.4,
)
cards.add(
    "JEP-290 SerialFilterChecker",
    "Checks jdk.serialFilter before stream read",
    badge_text="D1",
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
)
cards.add(
    "Offline Classpath DTD Resolver",
    "Loads config & mapper DTDs from local JAR",
    badge_text="D2",
)
cards.add(
    "PreparedStatement TypeHandlers",
    "Binds #{} tokens via JDBC TypeHandlers",
    badge_text="D3",
)
cards.draw(r_xy, width=r_w, height=r_h, align="bottom_left")

save()
```

### Detailed Assessment of `CWE-502` (`AbstractSerialStateHolder.java:110`)

- **Flagged AST Sink**: `[HIGH]` `CWE-502` (`unsafe_deserialization`) at `src/main/java/org/apache/ibatis/executor/loader/AbstractSerialStateHolder.java:110` (`new ObjectInputStream(new ByteArrayInputStream(this.userBeanBytes))`).
- **Existing Upstream Control**: At line `107` (immediately preceding `new ObjectInputStream(...)`), `AbstractSerialStateHolder.readResolve()` invokes `SerialFilterChecker.check()` (`src/main/java/org/apache/ibatis/io/SerialFilterChecker.java:42-54`), as does `SerializedCache.deserialize()` (`src/main/java/org/apache/ibatis/cache/decorators/SerializedCache.java:100`). `SerialFilterChecker` checks `ObjectInputFilter.Config.getSerialFilter()` (and `jdk.serialFilter` system/security properties) and logs an explicit warning pointing operators to Oracle's JEP-290 serialization filter documentation if no filter is active.
- **Recommended Hardening (`P1`)**: Introduce an optional `ObjectInputFilter` property on `Configuration` or a `strictSerialFilter=true` flag in `SerialFilterChecker` that attaches a per-stream allowlist filter (`in.setObjectInputFilter(...)`) or fails closed when `SERIAL_FILTER_MISSING` is `true`.
