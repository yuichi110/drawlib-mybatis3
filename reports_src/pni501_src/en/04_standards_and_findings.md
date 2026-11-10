# 4. Audit Standards, Rule Compliance & Findings

PNI501 evaluated MyBatis 3 `v3.6.0` against **15 active engineering rules** across **6 audit steps**, recording **0 `FAIL`**, **6 `WARN`**, **8 `PASS`**, and **1 `NOT_APPLICABLE`** (`java/frameworks/spring_boot`). All 13 raw observations consolidate deterministically into **12 unique `file:line` locations** (`0 CRITICAL`, `0 HIGH`, `3 MEDIUM`, `8 LOW`, `1 INFO`).

```drawlib align=center code=fold file=audit_step_scores_bar.png caption="Figure 4.1 — Executed Audit Step Scores (Weakest-First) & Rule Compliance Distribution"
from drawlib.canvas import save, setup
from drawlib.charts.bar import BarChart
from drawlib.icons import phosphor
from drawlib.smartarts import KpiCards, Panel
from drawlib.styles import Colors, Styles

setup(width=146, height=68, dpi=150)

chart = BarChart(
    axis_line_style=Styles.MutedDashed,
    categories=[
        "java_ast\n(act-04)",
        "lib_hygiene\n(act-08)",
        "security\n(act-13)",
        "repo_struct\n(act-02)",
        "java_test\n(act-09)",
        "runtime\n(act-11)",
    ],
    width=92.0,
    height=48.0,
    title="Executed PNI501 Audit Step Scores (Sorted Weakest -> Strongest)",
    title_style=Styles.BlackBold.patch(text_size=11.8),
    orientation="vertical",
    bar_mode="group",
    bar_width_ratio=0.62,
    bar_r=0.8,
    axis_text_style=Styles.DarkBold.patch(text_size=9.6),
    grid_style=Styles.MutedThin,
    value_text_style=Styles.DarkBold.patch(text_size=10.0),
    value_format="{:.0f}",
)
chart.add_series("Step Score (0–100)", [84, 88, 91, 92, 94, 96], style=Styles.PrimaryFlat)
chart.configure_y_axis(min_value=0.0, max_value=105.0, tick_step=20.0, label="Score")
chart.draw(xy=(5.5, 11.5))

panel = Panel(
    "Compliance",
    "15 Rules",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.scales,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.2,
)
panel.draw((101.0, 6.0), width=40.5, height=56.5, align="bottom_left")
r_xy, r_w, r_h = panel.get_content_box(
    (101.0, 6.0), width=40.5, height=56.5, padding=(2.5, 2.5), align="bottom_left"
)

kpis = KpiCards(
    style=Styles.Neutral.patch(shape_fill_color=Colors.White),
    metric_style=Styles.PrimaryBold.patch(text_size=14.0),
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    accent_style=Styles.PrimaryFlat,
    accent_position="left_pill",
    metric_layout="left_column",
    metric_width_ratio=0.34,
    spacing=2.4,
)
kpis.add(
    "0 FAIL",
    "Zero Rule Failures",
    "All hard gates passed",
    accent_style=Styles.SuccessFlat,
    metric_style=Styles.SuccessBold.patch(text_size=13.5),
)
kpis.add(
    "8 PASS",
    "Compliant Standards",
    "Runtime, tests, typing, deps",
)
kpis.add(
    "6 WARN",
    "Refinement Advisories",
    "Complexity, cycles, Javadoc",
    accent_style=Styles.WarningFlat,
    metric_style=Styles.WarningBold.patch(text_size=13.5),
)
kpis.draw(xy=r_xy, width=r_w, height=r_h, columns=1, align="bottom_left")

save()
```

---

## 4.1 Executed Audit Step Score Breakdown

| Audit Step ID | Action | Score | Grade | Rule Verdicts | Synthesis & Primary Observations |
| :--- | :---: | :---: | :---: | :---: | :--- |
| `java_ast_audit` | `act-04` | **84 / 100** | **A** | `3 PASS`, `3 WARN`, `0 FAIL` | `100.0%` import hygiene (`0` wildcard imports across `393` files / `23,364` LOC) and `99.9%` generic type coverage; `59` complex methods (`DefaultParameterHandler.setParameters=129`), `17` methods with `>6` params, `22` class cycles, and `16.3%` Javadoc coverage. |
| `library_hygiene_audit` | `act-08` | **88 / 100** | **A** | `1 PASS`, `2 WARN`, `0 FAIL` | Declares `Automatic-Module-Name: org.mybatis` and OSGi exports (`pom.xml:86-91`), ships `20/20` `package-info.java`, shades OGNL & Javassist, makes all 9 dependencies `<optional>true</optional>`, and has `0` `System.exit()` calls. |
| `security_vulnerability_audit` | `act-13` | **91 / 100** | **S** | `0 PASS`, `2 WARN`, `0 FAIL` | Trivy `0.69.3` verified `0` CVEs across `pom.xml` and `dependencies-lock.json`, `0` misconfigurations, and `0` secrets; `XPathParser` disables entity expansion; `AbstractSerialStateHolder.java:110` (`CWE-502`) calls warn-only `SerialFilterChecker.check()`. |
| `repo_structure_audit` | `act-02` | **92 / 100** | **S** | `4 PASS`, `1 WARN`, `0 FAIL` | Exact version pinning in `pom.xml`, committed `mvnw` and `dependencies-lock.json`, deterministic `project.build.outputTimestamp`, and clean Apache-2.0 licensing (`LICENSE` + `LICENSE-MYBATIS`). |
| `java_test_audit` | `act-09` | **94 / 100** | **S** | `1 PASS`, `0 WARN`, `0 FAIL` | `372` JUnit 5 test files (`1,918` methods, `81.5%` module mirror coverage) plus `src/test/java/org/apache/ibatis/submitted/` regression suite; hermetic HSQLDB/Derby/H2 databases via `BaseDataTest`. |
| `container_runtime_audit` | `act-11` | **96 / 100** | **S** | `2 PASS`, `0 WARN`, `0 FAIL` | All 4 stages passed in `maven:3.9-eclipse-temurin-21` under `--network=none`: `1,990` passed, `0` failed, `0` errors (`19` skipped) in `108.88s` with `87.4%` line (`9,985/11,418`) and `82.7%` branch coverage via JaCoCo `0.8.15`. |

---

## 4.2 Full Rule Compliance Matrix (`FAIL -> WARN -> PASS`)

| Status | Rule ID | Source Step | Deterministic Evidence & Compliance Rationale |
| :---: | :--- | :--- | :--- |
| **`[WARN]`** | `common/architecture` | `java_ast_audit` | `22` class-level circular dependencies: `4` cross-package cycles through `Configuration -> MapperRegistry -> MapperAnnotationBuilder -> @Arg/@Case -> UnknownTypeHandler -> Configuration`, plus `18` intra-package cycles (`PooledDataSource <-> PoolState <-> PooledConnection`, `MetaObject <-> SystemMetaObject`, `Reflector <-> Invoker`, `VFS <-> DefaultVFS/JBoss6VFS`). |
| **`[WARN]`** | `common/documentation` | `library_hygiene_audit` | `README.md` (`5` sections), `src/site/` multilingual XDoc/Markdown documentation, and `20/20` `package-info.java` files; inline `docstring_coverage_pct=16.3%` and `doc_signature_mismatches=24` (`AbstractSQL.java:62-175`, `ResolverUtil.java:197,221`, `MapperBuilderAssistant.java:277`). |
| **`[WARN]`** | `common/maintainability` | `java_ast_audit` | `59` complex functions led by `DefaultParameterHandler.java:89` (`cognitive=129`, `93` lines), `PooledDataSource.java:435` (`cognitive=78`, `117` lines), `CacheBuilder.java:142` (`cognitive=69`), and `MapperAnnotationBuilder.java:444` (`cognitive=68`); `17` methods with `>6` parameters in `MapperBuilderAssistant.java:203,277,287` (up to `22` params). |
| **`[WARN]`** | `common/security_vulnerability` | `act-13` | Trivy `0.69.3` filesystem scan passed with `0` application CVEs, `0` OS CVEs, `0` misconfigurations, and `0` secrets. `XPathParser.java:233-240` sets `FEATURE_SECURE_PROCESSING=true` and `expandEntityReferences=false`. One `CWE-502` `ObjectInputStream` sink at `AbstractSerialStateHolder.java:110` calls `SerialFilterChecker.check()` (line 107), which warns when JEP-290 `jdk.serialFilter` is unset. |
| **`[WARN]`** | `common/supply_chain` | `repo_structure_audit` | Committed `dependencies-lock.json` and `mvnw`; `0` unpinned dependencies; `LICENSE` and `LICENSE-MYBATIS` present; `.pni/dockerfiles/root/Dockerfile` pins `maven:3.9-eclipse-temurin-21` and runs as non-root `USER pni`; `SECURITY.md=False` and `dependency_automation=False` in snapshot repository. |
| **`[WARN]`** | `java/code_quality` | `java_ast_audit` | `import_hygiene_coverage_pct=100.0%` (`0` wildcard imports); `docstring_coverage_pct=16.3%` (`1,050` missing, `233` stub Javadocs, `24` `@param` mismatches); `9` mutable static fields in `JBoss6VFS.java:39-85`, `Resources.java:43`, `SerialFilterChecker.java:28`, and `LogFactory.java:33`. |
| **`[PASS]`** | `common/git_workflow` | `repo_structure_audit` | `.gitignore` (`244` lines covering Python, Java/Maven `target/`, Derby logs, `.drawlib/`, and `.pni/cache/`); clean trunk history with `0` conflict markers. |
| **`[PASS]`** | `common/library_guidelines` | `library_hygiene_audit` | `pom.xml:86-91` (`Automatic-Module-Name: org.mybatis`, `osgi.export`), `pom.xml:115-134,287-310` (`<optional>true</optional>`), `pom.xml:365-411` (`maven-shade-plugin` relocation), `0` `System.exit` calls, typed `PersistenceException` hierarchy, and `LogFactory.java` pluggable SPI. |
| **`[PASS]`** | `common/production_readiness` | `container_runtime_audit` | Thread-safe `Configuration`/`DefaultReflectorFactory`/`OgnlCache` registries, bounded `PooledDataSource` connection checkout/ping lifecycle, configurable `Statement.setQueryTimeout` propagation in `BaseStatementHandler`, and structured SLF4J/Log4j2 logging adapters. |
| **`[PASS]`** | `common/runtime_verification` | `container_runtime_audit` | `RuntimeFacts.status='passed'`; `harness_build.status='passed'`; `test_execution.status='passed'` (`2,009` total, `1,990` passed, `0` failed, `0` errors, `19` skipped in `108.88s` with `--network=none`); `line_coverage_pct=87.4%`, `branch_coverage_pct=82.7%` (`9,985/11,418` statements via JaCoCo `0.8.15`); `smoke_check.status='passed'`. |
| **`[PASS]`** | `common/security` | `repo_structure_audit` | `committed_secret_files=[]` across `393` source and `372` test files; `hardcoded_secrets=0`; `StdOutImpl.java:41-62` is an explicit opt-in stdout logger adapter; `DefaultVFS.java:67-341` and `Resources.java:273` open local classpath JAR/file URLs rather than external network sockets. |
| **`[PASS]`** | `java/dependencies` | `repo_structure_audit` | `pom.xml:67-325,365-411`, `mvnw`, `dependencies-lock.json` (`0` unpinned dependencies; strict `<optional>true</optional>` and `<scope>test</scope>` separation; shaded `ognl`/`javassist` relocation to `org.apache.ibatis.*`). |
| **`[PASS]`** | `java/testing` | `java_test_audit` | `372` test files vs `393` source files; `1,918` JUnit Jupiter `@Test`/`@ParameterizedTest` methods; `81.5%` package mirror coverage across all `20` packages plus `src/test/java/org/apache/ibatis/submitted/` regression suite; `BaseDataTest.java` hermetic HSQLDB/Derby/H2 seeding. |
| **`[PASS]`** | `java/typing` | `java_ast_audit` | `type_safety_coverage_pct=99.9%` across `393` files (`2,721` functions); `LruCache.java:54` uses `Map.Entry<Object, Object>`; `OgnlClassResolver.java:32` overrides OGNL `ClassResolver` raw signature; `248` `Object`/`@SuppressWarnings` usages confined to reflective boundaries. |
| **`[N/A]`** | `java/frameworks/spring_boot` | `java_ast_audit` | `ProjectFacts.runtime_types=['library']`, `frameworks=['junit5']`; standalone `org.mybatis:mybatis` SQL mapper library with zero Spring dependencies (Spring integration lives in separate `mybatis-spring` repository). |

---

## 4.3 Consolidated Location Findings Index (`CRITICAL -> INFO`)

Deduplicating the 13 raw observations by `file:line` produces **12 unique finding locations** (`0 CRITICAL`, `0 HIGH`, `3 MEDIUM`, `8 LOW`, `1 INFO`):

```drawlib align=center code=fold file=consolidated_findings_matrix.png caption="Figure 4.2 — Consolidated Location Findings Matrix (12 Unique Locations: 0 CRITICAL · 0 HIGH · 3 MEDIUM · 8 LOW · 1 INFO)"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import Table
from drawlib.styles import Colors, Styles
from drawlib.text import text

setup(width=174, height=136, dpi=150)

phosphor.magnifying_glass((10.0, 130.5), width=4.2, style=Styles.PrimaryBold)
text(
    (87.0, 130.5),
    "Consolidated Location Findings Matrix (12 Unique file:line Coordinates  ·  3 MEDIUM  ·  8 LOW  ·  1 INFO)",
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
    background_color=Styles.WarningNeutral.shape_fill_color,
    text_style=Styles.DarkBold.patch(text_size=9.5),
    rows=[1, 2, 3],
    columns=[0],
)
table.set_style_cell(
    background_color=Styles.SecondaryNeutral.shape_fill_color,
    text_style=Styles.DarkBold.patch(text_size=9.5),
    rows=[4, 5, 6, 7, 8, 9, 10, 11],
    columns=[0],
)
table.set_style_cell(
    background_color=Styles.PrimaryNeutral.shape_fill_color,
    text_style=Styles.PrimaryBold.patch(text_size=9.5),
    rows=[12],
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

findings_rows = [
    ["Severity", "Location (file:line)", "Rule ID", "Diagnostic Evidence", "Recommended Fix"],
    [
        "[MEDIUM] #1",
        "PooledDataSource.java:435",
        "common/\nmaintainability",
        "popConnection: 117 LOC,\n21 branches, cognitive=78",
        "Split idle checkout, overdue\neviction & ping validation",
    ],
    [
        "[MEDIUM] #2",
        "AbstractSerialState-\nHolder.java:110",
        "common/\nsecurity_vulnerability",
        "ObjectInputStream (CWE-502)\nwith warn-only JEP-290 check",
        "Allow per-stream ObjectInput-\nFilter or strict fail-closed",
    ],
    [
        "[MEDIUM] #3",
        "DefaultParameter-\nHandler.java:89",
        "common/\nmaintainability",
        "setParameters: 93 LOC,\n22 branches, cognitive=129",
        "Extract value, ParamMap type &\nTypeHandler helper methods",
    ],
    [
        "[LOW] #4",
        "README.md:1",
        "common/supply_chain",
        "SECURITY.md=False,\ndependency_automation=False",
        "Add SECURITY.md & renovate.json\nin repository root",
    ],
    [
        "[LOW] #5",
        "pom.xml:1",
        "common/supply_chain",
        "dependencies-lock.json present;\nSECURITY.md omitted",
        "Publish SECURITY.md covering\n#{} vs ${} & JEP-290 filters",
    ],
    [
        "[LOW] #6",
        "pom.xml:67",
        "java/dependencies",
        "<java.version>11</java.version>\nbaseline bytecode target",
        "Advance baseline to Java 17/21\nLTS in next major release",
    ],
    [
        "[LOW] #7",
        "Arg.java:25",
        "common/architecture",
        "Cycle: Arg -> UnknownTypeHandler\n-> Configuration -> Arg",
        "Decouple @Arg/@Case default\nfrom UnknownTypeHandler",
    ],
    [
        "[LOW] #8",
        "MapperBuilder-\nAssistant.java:203",
        "common/\nmaintainability",
        "addMappedStatement: 22, 20,\nand 19 positional params",
        "Pass MappedStatement.Builder\nor descriptor object",
    ],
    [
        "[LOW] #9",
        "SerialFilter-\nChecker.java:43",
        "common/\nsecurity_vulnerability",
        "One-time log.warn when\njdk.serialFilter is missing",
        "Add strictSerialFilter option\nto fail closed when unset",
    ],
    [
        "[LOW] #10",
        "AbstractSQL.java:62",
        "common/documentation\njava/code_quality",
        "24 Javadoc @param mismatches;\n16.3% overall Javadoc cov.",
        "Sync @param tags in AbstractSQL,\nResolverUtil & Assistant",
    ],
    [
        "[LOW] #11",
        "BindingTest.java:151",
        "java/testing",
        "126 tests use BDDCatchException\ninstead of AssertJ/JUnit 5",
        "Migrate to assertThatThrownBy\nand retire catch-exception",
    ],
    [
        "[INFO] #12",
        "CglibProxyFactory.java:55",
        "common/\nruntime_verification",
        "0.0% JaCoCo coverage on JDK 21\n(RequireIllegalAccess skipped)",
        "Retire deprecated CGLIB proxy\nor test fallback loggers",
    ],
]

table.draw_flexible(
    xy=(4.5, 125.0),
    column_widths=[18.0, 32.0, 38.0, 38.0, 39.0],
    row_heights=[6.0] + [9.2] * 12,
    data=findings_rows,
    align="top_left",
)

save()
```

### Complete Consolidated Findings Reference (`1..12`)

1. **`[MEDIUM]` `src/main/java/org/apache/ibatis/datasource/pooled/PooledDataSource.java:435`** (`common/maintainability`):
   - **Evidence**: `length=117 lines, branches=21, cognitive=78`
   - **Recommendation**: Decompose `popConnection` into smaller private methods handling idle connection retrieval, overdue active connection reclamation, and connection validation.
2. **`[MEDIUM]` `src/main/java/org/apache/ibatis/executor/loader/AbstractSerialStateHolder.java:110`** (`common/security_vulnerability`):
   - **Evidence**: `SerialFilterChecker.check(); try (ObjectInputStream in = new ObjectInputStream(new ByteArrayInputStream(this.userBeanBytes))) { this.userBean = in.readObject(); ... }`
   - **Recommendation**: Allow configuring a dedicated `ObjectInputFilter` on `Configuration` (or enforce a default package allowlist on the `ObjectInputStream` instance via `in.setObjectInputFilter(...)`) when `jdk.serialFilter` is not set at the JVM level.
3. **`[MEDIUM]` `src/main/java/org/apache/ibatis/scripting/defaults/DefaultParameterHandler.java:89`** (`common/maintainability`):
   - **Evidence**: `length=93 lines, branches=22, cognitive=129`
   - **Recommendation**: Extract helper methods for parameter value resolution (`resolveParameterValue`), `ParamMap` generic type inference (`resolveParamMapGenericType`), and `TypeHandler` selection (`resolveTypeHandler`).
4. **`[LOW]` `README.md:1`** (`common/supply_chain`):
   - **Evidence**: `ProjectFacts.has_security_policy=False, has_dependency_automation=False`
   - **Recommendation**: Add a root `SECURITY.md` documenting vulnerability reporting channels and include `renovate.json` for automated dependency tracking.
5. **`[LOW]` `pom.xml:1`** (`common/supply_chain`):
   - **Evidence**: `ProjectFacts: LICENSE=True, dependencies-lock.json present, SECURITY.md=False, dependency_automation=False`
   - **Recommendation**: Add a `SECURITY.md` documenting the vulnerability disclosure process and JEP-290/SQL-injection security guidance (e.g., `#{}` `PreparedStatement` binding vs `${}` string substitution), and configure Dependabot for Maven dependencies.
6. **`[LOW]` `pom.xml:67`** (`java/dependencies`):
   - **Evidence**: `<java.version>11</java.version> / <java.release.version>11</java.release.version>`
   - **Recommendation**: Consider advancing the baseline bytecode target to Java 17 or Java 21 LTS in future major releases to leverage modern JVM intrinsics, records, and sealed types natively.
7. **`[LOW]` `src/main/java/org/apache/ibatis/annotations/Arg.java:25`** (`common/architecture`):
   - **Evidence**: `Circular dependency: Arg -> UnknownTypeHandler -> Configuration -> MapperRegistry -> MapperAnnotationBuilder -> Arg`
   - **Recommendation**: Decouple annotation defaults by referencing the `TypeHandler.class` interface as the default sentinel or breaking `UnknownTypeHandler`'s direct dependency on `Configuration`.
8. **`[LOW]` `src/main/java/org/apache/ibatis/builder/MapperBuilderAssistant.java:203`** (`common/maintainability`):
   - **Evidence**: `params=22 (> 6, SIG Unit Interfacing); overloaded at lines 277 (20 params) and 287 (19 params)`
   - **Recommendation**: Prefer passing `MappedStatement.Builder` or a dedicated `StatementDescriptor` parameter object.
9. **`[LOW]` `src/main/java/org/apache/ibatis/io/SerialFilterChecker.java:43`** (`common/security_vulnerability`):
   - **Evidence**: `if (firstInvocation && SERIAL_FILTER_MISSING) { firstInvocation = false; log.warn("As you are using functionality that deserializes object streams, it is recommended to define the JEP-290 serial filter..."); }`
   - **Recommendation**: Provide a strict mode configuration flag (e.g., `strictSerialFilter=true`) that throws a `PersistenceException` or `SerializedCacheException` if deserialization is attempted without an active JEP-290 `ObjectInputFilter`.
10. **`[LOW]` `src/main/java/org/apache/ibatis/jdbc/AbstractSQL.java:62`** (`common/documentation`, `java/code_quality`):
    - **Evidence**: `24 Javadoc @param mismatches across AbstractSQL.java (lines 62, 89, 104, 126, 148, 175), ResolverUtil.java (197, 221), and MapperBuilderAssistant.java (277); 16.3% overall Javadoc coverage`
    - **Recommendation**: Align `@param` tags in `AbstractSQL`, `ResolverUtil`, and `MapperBuilderAssistant` with actual parameter names and expand Javadoc on public SPIs.
11. **`[LOW]` `src/test/java/org/apache/ibatis/binding/BindingTest.java:151`** (`java/testing`):
    - **Evidence**: `126 test methods use BDDCatchException.when(() -> ...); then(caughtException()).isInstanceOf(...) instead of JUnit 5 Assertions.assertThrows or AssertJ assertThatThrownBy`
    - **Recommendation**: Migrate remaining `BDDCatchException.when/then(caughtException())` usages to AssertJ `Assertions.assertThatThrownBy(...)` or JUnit 5 `Assertions.assertThrows(...)` so the `catch-exception` dependency can be retired.
12. **`[INFO]` `src/main/java/org/apache/ibatis/executor/loader/cglib/CglibProxyFactory.java:55`** (`common/runtime_verification`):
    - **Evidence**: `JaCoCo line_coverage_pct=0.0% (0/76 statements covered, lines 55-80); Log4j2LoggerImpl.java line_coverage_pct=0.0% (0/16); Slf4jLoggerImpl.java line_coverage_pct=0.0% (0/15)`
    - **Recommendation**: Add targeted unit tests with mocked non-`LocationAware` SLF4J/Log4j2 `Logger` instances to cover `Slf4jLoggerImpl` and `Log4j2LoggerImpl`, and plan removal of deprecated CGLIB proxy classes in the next major release.

---

## 4.4 Configured Scope & Accepted Design Waivers (`pni.toml`)

| Waiver ID | Scope Pattern | Matched Count | Documented Engineering Rationale |
| :---: | :--- | :---: | :--- |
| `DS-0026` | `.pni/dockerfiles/**` | `0` | Hermetic batch test container exits upon Maven JUnit completion; daemon `HEALTHCHECK` is not applicable. |
