# 3. Recommended Remediation Roadmap

MyBatis 3 `v3.6.0` enters remediation planning from a strong **90/100 (Grade S)** baseline with **zero `P0` urgent blockers**, **zero `FAIL` compliance rules**, and **zero `CRITICAL` or `HIGH` source-code findings** across all 393 Java source files and 1,990 passing offline tests. The 8-item engineering roadmap prioritizes **2 `P1` high-value maintainability and deserialization hardening enhancements** followed by **6 `P2` architectural, documentation, modernization, supply-chain, and test-suite polish actions**.

```drawlib align=center code=fold file=remediation_timeline_roadmap.png caption="Figure 3.1 — Phased Engineering Refinement Roadmap for MyBatis 3 v3.6.0 (0 P0 Urgent Blockers · 2 P1 High-Leverage · 6 P2 Polish)"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.shapes import rectangle
from drawlib.smartarts import Roadmap
from drawlib.styles import Colors, Styles
from drawlib.text import text

setup(width=146, height=66, dpi=150)

rectangle(
    (73.0, 59.5),
    width=134.0,
    height=7.5,
    style=Styles.Neutral.patch(shape_r=1.8, shape_fill_color=Colors.Gray1, shape_line_color=Colors.Gray3),
)
phosphor.rocket_launch((11.0, 59.5), width=4.4, style=Styles.PrimaryBold)
text(
    (75.0, 59.5),
    "MyBatis 3 v3.6.0 Remediation Horizon  ·  0 P0 Blockers  |  2 P1 Refinements  |  6 P2 Polish Items",
    style=Styles.DarkBold.patch(text_size=11.0),
)

rm = Roadmap(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.8),
    description_style=Styles.Dark.patch(text_size=9.6),
    spine_style=Styles.DarkBold,
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.2),
    icon_style=Styles.PrimaryBold,
    direction="vertical",
    curve_bend=0.0,
    card_shape="rounded_rect",
    spacing=2.8,
)

rm.add(
    "P0: None Required (0 Urgent Blockers)",
    "Zero FAIL rules, 0 Trivy CVEs, 0 secrets, and 100% offline test pass rate (1,990/2,009).",
    badge_text="P0",
    icon=phosphor.shield_check,
    style=Styles.SecondaryNeutral,
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.2),
    icon_style=Styles.SecondaryBold,
)
rm.add(
    "P1: Hot-Path Complexity Decomposition & JEP-290 Strict Mode (2 Actions)",
    "#1 Decompose DefaultParameterHandler & PooledDataSource  ·  #2 Optional strict ObjectInputFilter",
    badge_text="P1",
    icon=phosphor.wrench,
    style=Styles.PrimaryNeutral,
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.2),
    icon_style=Styles.PrimaryBold,
)
rm.add(
    "P2: Javadoc Sync, Cycle Breaking, JDK LTS & Test Modernization (6 Actions)",
    "#3 Fix @param & @Arg cycle  ·  #4 Java 17/21 target  ·  #5/#6 SECURITY.md  ·  #7/#8 Test polish",
    badge_text="P2",
    icon=phosphor.sparkle,
    style=Styles.Neutral,
    badge_style=Styles.Neutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.2),
    icon_style=Styles.DarkBold,
)

rm.draw(xy=(6.0, 5.0), width=134.0, height=49.0, align="bottom_left", scale=1.0)

save()
```

---

## 3.1 Action Plan Traceability Matrix (`P0 -> P1 -> P2`)

Every remediation item maps directly to existing repository files, expected engineering outcomes, and triggered rule IDs or CWE identifiers (`1..8` pre-sorted by priority):

```drawlib align=center code=fold file=remediation_traceability_table.png caption="Figure 3.2 — Action Plan Traceability Matrix Mapping Priorities, Target Files, Expected Impact, and Audit Rules"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import Table
from drawlib.styles import Colors, Styles
from drawlib.text import text

setup(width=168, height=118, dpi=150)

phosphor.clipboard_text((10.0, 112.5), width=4.2, style=Styles.PrimaryBold)
text(
    (84.0, 112.5),
    "Remediation Action Plan Traceability Matrix (0 P0 Urgent  ·  2 P1 High-Leverage  ·  6 P2 Polish)",
    style=Styles.DarkBold.patch(text_size=11.5),
)

table = Table(
    cell_style=Styles.White,
    text_style=Styles.Dark.patch(text_size=9.5),
    header_cell_style=Styles.PrimaryFlat,
    header_text_style=Styles.WhiteBold.patch(text_size=10.0),
    border_style=Styles.MutedThin,
    has_header=True,
)

table.set_style_cell_evenodd(
    even_color=Colors.Gray1,
    even_text_style=Styles.Dark.patch(text_size=9.5),
    odd_color=Colors.White,
    odd_text_style=Styles.Dark.patch(text_size=9.5),
)

table.set_style_cell_header(
    background_color=Colors.Dark,
    text_style=Styles.WhiteBold.patch(text_size=10.0),
)

table.set_style_cell(
    background_color=Styles.PrimaryNeutral.shape_fill_color,
    text_style=Styles.PrimaryBold.patch(text_size=9.5),
    rows=[1, 2],
    columns=[0],
)
table.set_style_cell(
    background_color=Styles.SecondaryNeutral.shape_fill_color,
    text_style=Styles.DarkBold.patch(text_size=9.5),
    rows=[3, 4, 5, 6, 7, 8],
    columns=[0],
)

table.set_style_border(
    top=Styles.Dark.patch(line_width=1.4),
    top2=Styles.Dark.patch(line_width=1.1),
    bottom=Styles.Dark.patch(line_width=1.4),
    left=Styles.MutedThin,
    right=Styles.MutedThin,
    between_columns=Styles.MutedThin,
    between_rows=Styles.MutedThin,
)

traceability_rows = [
    ["Priority", "Action Title", "Target Files", "Expected Impact", "Related Rules"],
    [
        "[P1] #1\nmaintainability",
        "Decompose high-complexity hot\npaths in DefaultParameterHandler\nand PooledDataSource",
        "DefaultParameterHandler.java\nPooledDataSource.java\nMapperAnnotationBuilder.java",
        "Brings cognitive complexity\nbelow 25 and improves unit\ntestability of hot paths",
        "common/\nmaintainability",
    ],
    [
        "[P1] #2\nsecurity",
        "Add Optional Strict Per-Stream\nObjectInputFilter Enforcement\nfor Deserialization",
        "AbstractSerialStateHolder.java\nSerialFilterChecker.java\nSerializedCache.java",
        "Eliminates CWE-502 exposure\nwhen global jdk.serialFilter\nis omitted at JVM startup",
        "common/\nsecurity_vulnerability\nSEC-04 / CWE-502",
    ],
    [
        "[P2] #3\ncode_quality",
        "Fix Javadoc @param mismatches\nand break @Arg ->\nUnknownTypeHandler cycle",
        "AbstractSQL.java\nResolverUtil.java\nMapperBuilderAssistant.java\nArg.java",
        "Eliminates 24 Javadoc tag\nmismatches and removes 4\ncross-package cycles",
        "java/code_quality\ncommon/architecture",
    ],
    [
        "[P2] #4\nmodernization",
        "Plan baseline JDK target\nmigration from Java 11 to\nJava 17/21 LTS",
        "pom.xml",
        "Enables native Java records,\npattern matching, and modern\nbytecode optimizations",
        "java/dependencies",
    ],
    [
        "[P2] #5\nsecurity",
        "Publish SECURITY.md Emphasizing\n#{} Parameter Binding and\nJEP-290 Serial Filters",
        "pom.xml\nREADME.md",
        "Guides users on safe #{}\nbinding vs ${} interpolation\nand JEP-290 whitelists",
        "common/supply_chain\nSEC-01",
    ],
    [
        "[P2] #6\nsupply_chain",
        "Add SECURITY.md disclosure\npolicy and dependency\nupdate config",
        "README.md\npom.xml",
        "Improves OpenSSF Scorecard\nsupply-chain governance and\nautomated CVE tracking",
        "common/supply_chain",
    ],
    [
        "[P2] #7\ntesting",
        "Add unit tests for\nnon-LocationAware logger\nwrapper fallbacks",
        "Slf4jLoggerImpl.java\nLog4j2LoggerImpl.java",
        "Eliminates 0% coverage gaps\nin fallback SLF4J and Log4j2\nlogger adapters",
        "common/\nruntime_verification",
    ],
    [
        "[P2] #8\ntesting",
        "Migrate remaining\ncatch-exception tests to\nAssertJ assertThatThrownBy",
        "BindingTest.java\npom.xml",
        "Retires legacy catch-exception\nagent dependency across 126\nexception test methods",
        "java/testing",
    ],
]

table.draw_flexible(
    xy=(4.5, 107.0),
    column_widths=[21.0, 38.0, 36.0, 35.0, 29.0],
    row_heights=[6.5] + [11.6] * 8,
    data=traceability_rows,
    align="top_left",
)

save()
```

### Detailed Remediation Specifications (`1..8`)

1. **`[P1]` Decompose high-complexity hot paths in `DefaultParameterHandler` and `PooledDataSource` (`maintainability`)**:
   - **Targets**: `src/main/java/org/apache/ibatis/scripting/defaults/DefaultParameterHandler.java`, `src/main/java/org/apache/ibatis/datasource/pooled/PooledDataSource.java`, `src/main/java/org/apache/ibatis/builder/annotation/MapperAnnotationBuilder.java`
   - **Related Rules**: `common/maintainability`
   - **Action**: Extract focused private helper methods in `DefaultParameterHandler.setParameters` (`cognitive=129`), `PooledDataSource.popConnection` (`cognitive=78`), and `MapperAnnotationBuilder.getReturnType` (`cognitive=68`) to bring per-method cognitive complexity below `25`.
   - **Expected Impact**: Improves readability, unit testability, and maintainability of parameter binding and connection pooling hot paths.

2. **`[P1]` Add Optional Strict Per-Stream `ObjectInputFilter` Enforcement for Deserialization (`security`)**:
   - **Targets**: `src/main/java/org/apache/ibatis/executor/loader/AbstractSerialStateHolder.java`, `src/main/java/org/apache/ibatis/io/SerialFilterChecker.java`, `src/main/java/org/apache/ibatis/cache/decorators/SerializedCache.java`
   - **Related Rules**: `common/security_vulnerability`, `SEC-04`, `CWE-502`
   - **Action**: Support configuring a custom `ObjectInputFilter` (Java 9+) or fail-closed strict mode in `SerialFilterChecker` so applications using `SerializedCache` or lazy-loader serialization are protected even when the global JVM `jdk.serialFilter` property is omitted.
   - **Expected Impact**: Eliminates `CWE-502` unsafe deserialization exposure when L2 cache or lazy state payloads are stored in external or shared media.

3. **`[P2]` Fix Javadoc `@param` mismatches and break `@Arg -> UnknownTypeHandler` cycle (`code_quality`)**:
   - **Targets**: `src/main/java/org/apache/ibatis/jdbc/AbstractSQL.java`, `src/main/java/org/apache/ibatis/io/ResolverUtil.java`, `src/main/java/org/apache/ibatis/builder/MapperBuilderAssistant.java`, `src/main/java/org/apache/ibatis/annotations/Arg.java`
   - **Related Rules**: `java/code_quality`, `common/architecture`
   - **Action**: Synchronize the `24` mismatched Javadoc `@param` tags in `AbstractSQL`, `ResolverUtil`, and `MapperBuilderAssistant`, and decouple `@Arg`/`@Case` from concrete `UnknownTypeHandler -> Configuration` dependencies.
   - **Expected Impact**: Eliminates Javadoc compiler warnings and removes the 4 cross-package dependency cycles.

4. **`[P2]` Plan baseline JDK target migration from Java 11 to Java 17/21 LTS (`modernization`)**:
   - **Targets**: `pom.xml`
   - **Related Rules**: `java/dependencies`
   - **Action**: Update `<java.version>` and `<java.release.version>` in `pom.xml` (lines 67–68) to `17` or `21` LTS on the next major release line and consolidate legacy JDK activation profiles.
   - **Expected Impact**: Enables native Java records, pattern matching, and modern bytecode optimizations without multi-profile workarounds.

5. **`[P2]` Publish `SECURITY.md` Emphasizing `#{}` Parameter Binding and JEP-290 Serial Filters (`security`)**:
   - **Targets**: `pom.xml`, `README.md`
   - **Related Rules**: `common/supply_chain`, `SEC-01`
   - **Action**: Add a `SECURITY.md` policy detailing upstream security reporting channels, mandatory JEP-290 `jdk.serialFilter` patterns for `SerializedCache`, and safe `#{}` `PreparedStatement` parameter binding versus `${}` OGNL string interpolation.
   - **Expected Impact**: Improves OpenSSF Scorecard supply-chain governance and helps downstream developers prevent SQL injection and deserialization misconfigurations.

6. **`[P2]` Add `SECURITY.md` disclosure policy and dependency update config (`supply_chain`)**:
   - **Targets**: `README.md`, `pom.xml`
   - **Related Rules**: `common/supply_chain`
   - **Action**: Add a `SECURITY.md` file detailing upstream MyBatis security reporting procedures and commit `renovate.json` for automated dependency monitoring.
   - **Expected Impact**: Improves OpenSSF Scorecard supply-chain governance posture.

7. **`[P2]` Add unit tests for non-`LocationAware` logger wrapper fallbacks (`testing`)**:
   - **Targets**: `src/main/java/org/apache/ibatis/logging/slf4j/Slf4jLoggerImpl.java`, `src/main/java/org/apache/ibatis/logging/log4j2/Log4j2LoggerImpl.java`
   - **Related Rules**: `common/runtime_verification`
   - **Action**: Add unit tests in `src/test/java/org/apache/ibatis/logging/` exercising `Slf4jLoggerImpl` and `Log4j2LoggerImpl` directly with mock `Logger` instances.
   - **Expected Impact**: Eliminates `0%` coverage gaps in fallback logging adapters.

8. **`[P2]` Migrate remaining `catch-exception` tests to AssertJ `assertThatThrownBy` or JUnit 5 `assertThrows` (`testing`)**:
   - **Targets**: `src/test/java/org/apache/ibatis/binding/BindingTest.java`, `pom.xml`
   - **Related Rules**: `java/testing`
   - **Action**: Replace `BDDCatchException.when(...)/then(caughtException())` calls in `126` test methods with AssertJ `assertThatThrownBy(...)` and remove `com.github.hazendaz.catch-exception` from `pom.xml`.
   - **Expected Impact**: Simplifies the test dependency graph and eliminates bytecode agent overhead for exception assertions.
