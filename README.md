# MyBatis 3 User Guide, API Reference, Architecture & PNI501 Audit (`drawlib-mybatis3`)

> **Unofficial Multi-Portal Documentation & Diagnostic Suite — Built with [Drawlib](https://www.drawlib.com/) & [PNI501](https://pypi.org/project/pni501/)**
>
> This repository hosts an **independent, unofficial** four-portal documentation, API & XML catalog, internal architecture guide, and software diagnostic site covering **[MyBatis 3](https://mybatis.org/mybatis-3/)** (`v3.6.0`, tag `mybatis-3.6.0` / commit `73a0c5d4`).
> For official MyBatis 3 documentation, release notes, and issue tracking, always visit **[https://mybatis.org/mybatis-3/](https://mybatis.org/mybatis-3/)**.

---

## Live Portals (`https://mybatis3.drawlib.com/`)

1. **MyBatis 3 User Guide (`docs_src/` -> `docs/`)**: [https://mybatis3.drawlib.com/](https://mybatis3.drawlib.com/) (English & 日本語)
   - Practical user guide, enterprise architecture & Spring Boot integration patterns, XML & annotation mapper design, `<resultMap>` nested associations/collections, Dynamic SQL OGNL engine, L1/L2 caching semantics, TypeHandlers, Plugins, and JUnit 5 testing recipes backed by `v3.6.0` examples.
2. **MyBatis 3 API & XML Reference Catalog (`api_src/` -> `docs/api/`)**: [https://mybatis3.drawlib.com/api/](https://mybatis3.drawlib.com/api/) (English & 日本語)
   - Searchable symbol & XML schema catalog (`type = "catalog"`) covering every public Java interface/class (`SqlSessionFactory`, `SqlSession`, `Configuration`, `Cursor`, `SQL`), mapper annotation (`@Select`, `@Results`, `@Many`, `@One`, `@Options`, `@Param`, `@SelectProvider`), XML configuration/mapper DTD/XSD element, `TypeHandler`, `Interceptor` plugin SPI, and exception in MyBatis `v3.6.0`.
3. **MyBatis 3 Internal Architecture Guide (`architecture_src/` -> `docs/architecture/`)**: [https://mybatis3.drawlib.com/architecture/](https://mybatis3.drawlib.com/architecture/) (English & 日本語)
   - Source-level walkthrough of how MyBatis `v3.6.0` (`org.apache.ibatis`) works internally: 3-tier package topology, `XMLConfigBuilder` & `MapperAnnotationBuilder` compilation into `Configuration` and `MappedStatement`, JDK Dynamic Proxy (`MapperProxyFactory` & `MapperMethod`), `CachingExecutor` & `BaseExecutor` L1/L2 cache and JDBC `StatementHandler` pipeline, `DynamicSqlSource` & `SqlNode` OGNL AST evaluation, and `DefaultResultSetHandler` nested result mapping with `MetaObject` / `Reflector` reflection and `Plugin.wrap()` interceptor chains.
4. **PNI501 Engineering & Architecture Diagnostic Report (`reports_src/pni501_src/` -> `docs/reports/pni501/`)**: [https://mybatis3.drawlib.com/reports/pni501/](https://mybatis3.drawlib.com/reports/pni501/) ([PDF](https://mybatis3.drawlib.com/reports/pni501/pni501.pdf))
   - Deterministic 15-stage Java AST, package dependency DAG, library hygiene, hermetic Maven/JUnit 5 container runtime, and supply-chain diagnostic audit.

---

## Repository Layout

```text
drawlib-mybatis3/
├── src/                      # Upstream MyBatis v3.6.0 Java source, resources & JUnit 5 test suite (Apache-2.0, unmodified)
├── pom.xml                   # Upstream MyBatis v3.6.0 Maven POM manifest (unmodified)
├── dependencies-lock.json    # Upstream dependency lockfile (unmodified)
├── mvnw, mvnw.cmd, .mvn/     # Upstream Maven Wrapper (unmodified)
├── LICENSE-MYBATIS           # Upstream Apache-2.0 License & NOTICE (Copyright 2009-2026 MyBatis.org)
├── LICENSE                   # Apache-2.0 License for original documentation, diagrams & audit assets
├── .pni/                     # PNI501 workflow & Java audit configuration
├── docs_src/                 # Portal 1: MyBatis 3 User Guide source (bilingual en/ja, type = "site")
├── api_src/                  # Portal 2: MyBatis 3 API & XML Reference source (bilingual en/ja, type = "catalog")
├── architecture_src/         # Portal 3: MyBatis 3 Internal Architecture Guide source (bilingual en/ja, type = "site")
├── reports_src/
│   └── pni501_src/           # Portal 4: PNI501 diagnostic report source (type = "doc")
└── docs/                     # Unified compiled GitHub Pages output
    ├── index.html            # User Guide root
    ├── api/                  # API & XML Reference Catalog
    ├── architecture/         # Internal Architecture Guide
    └── reports/
        └── pni501/           # PNI501 HTML & PDF report
```

---

## Installation, Quickstart & Reproducing Locally with `uvx`

`src/`, `pom.xml`, `dependencies-lock.json`, and `mvnw` remain unmodified from upstream MyBatis `v3.6.0`; `drawlib` and `pni501` run ephemerally via `uvx` without polluting the Java repository with Python virtual environments:

```bash
# Build all 4 portals (User Guide + API Catalog + Internal Architecture + PNI501 HTML/PDF) & check links
./build.sh

# Or build each portal individually:
./docs_src/build_html.sh
./api_src/build_html.sh
./architecture_src/build_html.sh
uvx --default-index https://pypi.org/simple --from pni501 pni report build pni501 \
  --src-dir reports_src \
  --html-output-dir docs/reports/pni501 \
  --output-dir docs/reports/pni501 \
  -f html -f pdf

# Preview locally & verify zero broken links
uvx --default-index https://pypi.org/simple drawlib serve docs/ --check
uvx --default-index https://pypi.org/simple drawlib serve docs/

# Run upstream MyBatis 3.6.0 Maven JUnit 5 test suite
./mvnw test
```

---

## Licensing & Trademark Notice

- **Upstream MyBatis 3 Snapshot (`src/`, `pom.xml`, `dependencies-lock.json`, `mvnw`, `.mvn/`, `NOTICE`)**:
  Copyright 2009-2026 the original author or authors (MyBatis.org). Distributed under the **Apache License, Version 2.0** — see [`LICENSE-MYBATIS`](./LICENSE-MYBATIS) and [`NOTICE`](./NOTICE).
- **Original Documentation, API Catalog, Diagrams & PNI501 Audit (`docs_src/`, `api_src/`, `architecture_src/`, `reports_src/`, `docs/`, `.pni/`, build scripts)**:
  Copyright (c) 2026 Yuichi Ito. Distributed under the **Apache License, Version 2.0** — see [`LICENSE`](./LICENSE).
- **Attribution**:
  MyBatis is a project of MyBatis.org. This repository is an independent community documentation and architecture study built with [Drawlib](https://www.drawlib.com/) and [PNI501](https://pypi.org/project/pni501/) and is not affiliated with, sponsored by, or endorsed by the official MyBatis project.