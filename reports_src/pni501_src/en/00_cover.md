# PNI Software Health Diagnostic Report

**MyBatis 3 `v3.6.0`** — *Automated Architecture, Static Java AST, Hermetic Runtime & Supply-Chain Diagnostic*

This independent technical showcase evaluates **MyBatis 3 `v3.6.0`** (tag `mybatis-3.6.0` / commit `73a0c5d4`, Apache License 2.0) across 7 software engineering dimensions using [PNI501](https://pypi.org/project/pni501/) and [Drawlib](https://www.drawlib.com/). All upstream Java packages (`org.apache.ibatis.*`), JUnit 5 test suites, and Maven build manifests are inspected unmodified in zero-pollution hermetic environments.

```drawlib align=center code=fold file=pni_cover_scorecard.png caption="MyBatis 3 v3.6.0 — PNI501 Overall Engineering Health Scorecard"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import KpiCards, Panel
from drawlib.styles import Colors, Styles

setup(width=146, height=58, dpi=150)

white_card = Styles.Neutral.patch(shape_fill_color=Colors.White)

outer = Panel(
    "MyBatis 3 v3.6.0 — Health Scorecard",
    "PNI501 (wf-c05a2020) · Java 11+ (JDK 21 Tested) · org.mybatis:mybatis",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=12.0),
    description_style=Styles.Muted.patch(text_size=10.0),
    icon=phosphor.gauge,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=9.0,
)
outer.draw((4.5, 4.5), width=137.0, height=49.0, align="bottom_left")
inner_xy, inner_w, inner_h = outer.get_content_box(
    (4.5, 4.5),
    width=137.0,
    height=49.0,
    padding=(3.5, 3.0),
    align="bottom_left",
)

kpis = KpiCards(
    style=white_card,
    metric_style=Styles.DarkBold.patch(text_size=14.0),
    text_style=Styles.DarkBold.patch(text_size=11.2),
    description_style=Styles.Muted.patch(text_size=10.0),
    accent_style=Styles.PrimaryFlat,
    icon_style=Styles.PrimaryBold,
    accent_position="left_pill",
    metric_layout="left_column",
    metric_width_ratio=0.30,
    spacing=3.5,
)

kpis.add(
    "90 / 100",
    "Overall Score (Grade S)",
    "393 files · 23,364 LOC · Java",
    style=Styles.PrimaryFlat,
    metric_style=Styles.WhiteBold.patch(text_size=14.0),
    text_style=Styles.WhiteBold.patch(text_size=11.2),
    description_style=Styles.White.patch(text_size=10.0),
    accent_style=Styles.WhiteFlat,
    icon=phosphor.check_circle,
    icon_style=Styles.WhiteBold,
)
kpis.add(
    "8 / 15",
    "Rule Compliance (0 FAIL)",
    "8 PASS · 6 WARN · 1 N/A · 13 findings",
    accent_style=Styles.PrimaryFlat,
    icon=phosphor.clipboard_text,
    icon_style=Styles.PrimaryBold,
)
kpis.add(
    "87.4%",
    "Measured Line Coverage",
    "1,990 passed · 82.7% branch · JaCoCo",
    accent_style=Styles.SuccessFlat,
    icon=phosphor.shield_check,
    icon_style=Styles.SuccessBold,
)
kpis.add(
    "0 CVEs",
    "0 App & OS CVEs · JEP-290",
    "0 mandatory deps · 0 secrets · 0 IaC",
    accent_style=Styles.SuccessFlat,
    icon=phosphor.lock_key,
    icon_style=Styles.SuccessBold,
)

kpis.draw(inner_xy, width=inner_w, height=inner_h, columns=2, align="bottom_left")

save()
```

| Diagnostic Attribute | Verified Metadata & Audit Baseline |
| :--- | :--- |
| **Target Project** | `mybatis3` (`v3.6.0`, tag `mybatis-3.6.0` / commit `73a0c5d4`, Maven `org.mybatis:mybatis`, Java `11+`) |
| **Target Language & Profile** | `java` (`library` — SQL mapper & relational persistence framework over standard JDBC) |
| **Upstream License & Attribution** | Apache License 2.0 (`LICENSE-MYBATIS` & `NOTICE`; Copyright © 2009–2026 MyBatis.org) |
| **Diagnostic Workflow** | `pni501` (Workflow Run ID `wf-c05a2020`, category `audit`) |
| **Evaluated At** | `2026-11-10T03:44:29+00:00` (`2026-11-10T03:44:29.163937+00:00`) |
| **Overall Score & Grade** | **90 / 100 (Grade S)** — `8 / 15` rules `PASS`, `6 WARN`, `0 FAIL`, `1 NOT_APPLICABLE` (`13` raw findings across `12` unique locations: `0` CRITICAL, `0` HIGH, `3` MEDIUM, `9` LOW, `1` INFO) |
| **Analyzed Codebase Scope** | `393` Java source files (`23,364` LOC, `374` classes, `2,721` methods across `20` packages) & `372` JUnit 5 test files (`1,990` passed, `0` failed under `--network=none`) |

> **Unofficial Engineering Showcase Notice**: This diagnostic report is an independent automated analysis generated with [PNI501](https://pypi.org/project/pni501/) and [Drawlib](https://www.drawlib.com/) to study MyBatis 3's architecture and software engineering quality, and is not affiliated with or endorsed by the official [MyBatis project](https://mybatis.org/mybatis-3/).
