# 1. Executive Summary

MyBatis 3 (`v3.6.0`, Maven artifact `org.mybatis:mybatis`) achieves an overall PNI501 engineering score of **90/100 (Grade S)** across a 15-stage static Java AST, package dependency DAG, library hygiene, hermetic Maven/JUnit 5 container runtime, and Trivy supply-chain audit. Across **393 Java source files** (**23,364 LOC**, **374 classes**, **2,721 methods**) and **372 JUnit 5 test files**, the framework demonstrates **100.0% import hygiene**, **99.9% generic type coverage**, **zero mandatory runtime dependencies** (with OGNL `3.4.16` and Javassist `3.33.0-GA` shaded into `org.apache.ibatis.*`), **zero Trivy CVEs**, and **100% offline test reliability** (`1,990` passed, `0` failed) with **87.4% measured JaCoCo line coverage** and **82.7% branch coverage**.

```drawlib align=center code=fold file=exec_health_radar.png caption="MyBatis 3 v3.6.0 — 7-Dimension Engineering Health Radar & Audit Step Scores"
from drawlib.canvas import save, setup
from drawlib.charts.radar import RadarChart
from drawlib.icons import phosphor
from drawlib.smartarts import KpiCards, Panel
from drawlib.styles import Colors, Styles

setup(width=146, height=68, dpi=150)

white_card = Styles.Neutral.patch(shape_fill_color=Colors.White)

left_panel = Panel(
    "7-Dimension Engineering Balance",
    "Overall: 90 / 100 (Grade S)",
    style=Styles.White,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.chart_polar,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.0,
)
left_panel.draw((4.0, 4.5), width=80.0, height=59.0, align="bottom_left")
l_xy, l_w, l_h = left_panel.get_content_box(
    (4.0, 4.5),
    width=80.0,
    height=59.0,
    padding=(2.5, 2.0),
    align="bottom_left",
)

radar = RadarChart(
    categories=[
        "Architecture",
        "Code Quality",
        "Typing",
        "Testing",
        "Dependencies",
        "Security",
        "Documentation",
    ],
    axis_line_style=Styles.MutedDashed,
    axis_text_style=Styles.DarkBold.patch(text_size=10.0),
    grid_style=Styles.MutedThin,
    value_text_style=Styles.PrimaryBold.patch(text_size=10.0),
    radius=16.0,
    width=l_w,
    height=l_h - 3.5,
    min_value=0.0,
    max_value=100.0,
    levels=5,
    grid_shape="polygon",
    value_format="{:.0f}",
)
radar.add_series(
    "MyBatis 3 v3.6.0 (Overall 90 / Grade S)",
    [86, 85, 94, 95, 93, 91, 85],
    style=Styles.PrimaryFlat,
    fill_alpha=0.26,
    line_width=2.2,
)
radar.draw(xy=(l_xy[0], l_xy[1] + 3.5))
radar.draw_legend(
    xy=(l_xy[0] + 10.0, l_xy[1] + 1.5),
    text_style=Styles.DarkBold.patch(text_size=9.8),
    orientation="horizontal",
)

right_panel = Panel(
    "Audit Steps",
    "6 Stages",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.list_checks,
    icon_style=Styles.DarkBold,
    header_variant="filled",
    header_height=8.0,
)
right_panel.draw((87.0, 4.5), width=55.0, height=59.0, align="bottom_left")
r_xy, r_w, r_h = right_panel.get_content_box(
    (87.0, 4.5), width=55.0, height=59.0, padding=(2.8, 2.5), align="bottom_left"
)

step_kpis = KpiCards(
    style=white_card,
    metric_style=Styles.PrimaryBold.patch(text_size=12.5),
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    accent_style=Styles.PrimaryFlat,
    accent_position="left_pill",
    metric_layout="left_column",
    metric_width_ratio=0.30,
    spacing=2.2,
)
step_kpis.add("96 / 100", "Container Runtime (S)", "1,990 passed · 87.4% cov")
step_kpis.add("94 / 100", "Java Test Audit (S)", "372 test files · 0 failures")
step_kpis.add("92 / 100", "Repo Structure (S)", "mvnw · lockfile · shaded")
step_kpis.add("91 / 100", "Security & SCA (S)", "0 CVEs · JEP-290 guard")
step_kpis.add(
    "88 / 100",
    "Library Hygiene (A)",
    "0 transitive deps · OSGi",
    accent_style=Styles.SecondaryFlat,
    metric_style=Styles.DarkBold.patch(text_size=12.5),
)
step_kpis.add(
    "84 / 100",
    "Java AST Audit (A)",
    "100% imports · 59 hotspots",
    accent_style=Styles.SecondaryFlat,
    metric_style=Styles.DarkBold.patch(text_size=12.5),
)
step_kpis.draw(xy=r_xy, width=r_w, height=r_h, columns=1, align="bottom_left")

save()
```

---

## 1.1 Headline Engineering KPIs, Key Strengths & Top Risks

The seven-axis diagnostic profile reflects a battle-tested Java library whose core design choices—zero mandatory runtime dependencies, compile-time XML/annotation lowering into `MappedStatement` registries, and strict separation between thread-safe `Configuration` metadata and thread-confined `SqlSession`/`Executor` instances—have scaled cleanly across more than a decade of enterprise adoption.

```drawlib align=center code=fold file=exec_strengths_and_risks.png caption="MyBatis 3 v3.6.0 — Verified Engineering Strengths vs. Top Maintainability & Security Risks"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, KpiCards, Panel
from drawlib.styles import Colors, Styles

setup(width=146, height=78, dpi=150)

white_card = Styles.Neutral.patch(shape_fill_color=Colors.White)

top_kpis = KpiCards(
    style=Styles.Neutral,
    metric_style=Styles.DarkBold.patch(text_size=13.0),
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.8),
    accent_style=Styles.PrimaryFlat,
    accent_position="top_bar",
    metric_layout="top_stack",
    spacing=3.0,
)
top_kpis.add(
    "8 / 15",
    "Rules Passed",
    "6 WARN · 0 FAIL · 1 N/A",
    style=Styles.PrimaryNeutral,
    accent_style=Styles.PrimaryFlat,
)
top_kpis.add(
    "1,990",
    "Offline Tests Passed",
    "87.4% line · 82.7% branch",
    accent_style=Styles.SuccessFlat,
)
top_kpis.add(
    "0 CVEs",
    "Clean Supply Chain",
    "0 mandatory deps · 0 secrets",
    accent_style=Styles.SuccessFlat,
)
top_kpis.add(
    "3 MED · 9 LOW",
    "13 Total Findings",
    "0 CRITICAL · 0 HIGH · 1 INFO",
    accent_style=Styles.WarningFlat,
)
top_kpis.draw((4.5, 56.5), width=137.0, height=17.0, columns=4, align="bottom_left")

left_panel = Panel(
    "4 Key Strengths",
    "Shaded Deps · Hermetic Tests",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.medal,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.2,
)
left_panel.draw((4.5, 4.5), width=66.5, height=49.0, align="bottom_left")
l_xy, l_w, l_h = left_panel.get_content_box(
    (4.5, 4.5), width=66.5, height=49.0, padding=(2.8, 2.4), align="bottom_left"
)

strengths = CardList(
    style=white_card,
    text_style=Styles.DarkBold.patch(text_size=10.2),
    description_style=Styles.Muted.patch(text_size=9.6),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.0),
    direction="vertical",
    spacing=1.8,
)
strengths.add(
    "Zero Mandatory Runtime Deps",
    "All 9 deps optional; OGNL & Javassist shaded",
    badge_text="S1",
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
)
strengths.add(
    "100% Import & 99.9% Type Hygiene",
    "0 wildcard imports; typed TypeHandler<T>",
    badge_text="S2",
)
strengths.add(
    "Hermetic Multi-DB JUnit 5 Suite",
    "1,990 passed offline on HSQLDB/Derby/H2",
    badge_text="S3",
)
strengths.add(
    "Zero CVEs & Hardened XPathParser",
    "FEATURE_SECURE_PROCESSING & local DTDs",
    badge_text="S4",
)
strengths.draw(l_xy, width=l_w, height=l_h, align="bottom_left")

right_panel = Panel(
    "Top Focal Points",
    "3 [MEDIUM] · 9 [LOW]",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.warning_circle,
    icon_style=Styles.WarningBold,
    header_variant="filled",
    header_height=8.2,
)
right_panel.draw((75.0, 4.5), width=66.5, height=49.0, align="bottom_left")
r_xy, r_w, r_h = right_panel.get_content_box(
    (75.0, 4.5), width=66.5, height=49.0, padding=(2.8, 2.4), align="bottom_left"
)

risks = CardList(
    style=white_card,
    text_style=Styles.DarkBold.patch(text_size=10.2),
    description_style=Styles.Muted.patch(text_size=9.6),
    badge_shape="rounded_rect",
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.0),
    direction="vertical",
    spacing=1.8,
)
risks.add(
    "[MED] DefaultParameterHandler (129)",
    "setParameters (93 LOC) mixes lookup & bind",
    badge_text="M1",
    badge_style=Styles.WarningFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
)
risks.add(
    "[MED] PooledDataSource.pop (78)",
    "117 LOC checkout, eviction & ping retry",
    badge_text="M2",
    badge_style=Styles.WarningFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
)
risks.add(
    "[MED] Warn-Only JEP-290 Filter",
    "AbstractSerialStateHolder (CWE-502) warn",
    badge_text="M3",
    badge_style=Styles.WarningFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
)
risks.add(
    "[LOW] 22 Class Cycles & 16.3% Docs",
    "@Arg -> UnknownTypeHandler & @param tags",
    badge_text="L1",
)
risks.draw(r_xy, width=r_w, height=r_h, align="bottom_left")

save()
```

### Summary of 7-Dimension Scores & Rationales

| Dimension | Score | Grade | Key Quantitative Evidence & Architectural Rationale |
| :--- | :---: | :---: | :--- |
| **Testing** | **95 / 100** | **S** | `372` JUnit 5 test files (`1,918` AST methods, `2,009` runtime executions); `1,990` passed, `0` failed, `0` errors offline (`--network=none`) in `108.88s`; `87.4%` line (`9,985/11,418`) and `82.7%` branch coverage via JaCoCo `0.8.15`. |
| **Typing** | **94 / 100** | **S** | `99.9%` generic type safety coverage across `2,721` methods; only `2` raw generic signatures (`LruCache.java:53`, `OgnlClassResolver.java:32`); `248` `Object`/`@SuppressWarnings("unchecked")` usages confined to reflection/proxy boundaries. |
| **Dependencies** | **93 / 100** | **S** | `9` pinned optional/provided dependencies in `pom.xml`; `maven-shade-plugin` relocates `ognl:3.4.16` and `javassist:3.33.0-GA` into `org.apache.ibatis.*`; reproducible `mvnw`, `dependencies-lock.json`, and `project.build.outputTimestamp`. |
| **Security** | **91 / 100** | **S** | `0` Trivy CVEs (`CRITICAL=0`, `HIGH=0`, `MEDIUM=0`, `LOW=0`), `0` secrets, `0` IaC misconfigs; hardened `XPathParser` (`FEATURE_SECURE_PROCESSING=true`); `SerialFilterChecker.check()` warns on missing JEP-290 `jdk.serialFilter` (`CWE-502`). |
| **Architecture** | **86 / 100** | **A** | Cohesive 3-tier layout across `20` packages under `org.apache.ibatis.*` using Decorator, Template Method, Composite, and Dynamic Proxy patterns; `22` class-level cycles (`4` cross-package via `@Arg -> UnknownTypeHandler -> Configuration`). |
| **Code Quality** | **85 / 100** | **A** | `100.0%` import hygiene (`0` wildcard imports across `393` files); `59` complex methods led by `DefaultParameterHandler.setParameters` (`cognitive=129`) and `PooledDataSource.popConnection` (`cognitive=78`), plus `17` methods with `>6` parameters. |
| **Documentation** | **85 / 100** | **A** | `20/20` `package-info.java` descriptors, structured `src/site/` documentation, and `README.md`, offset by `16.3%` inline public Javadoc coverage and `24` `@param` tag mismatches in `AbstractSQL.java` and `ResolverUtil.java`. |
