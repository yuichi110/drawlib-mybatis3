# MyBatis 3 内部アーキテクチャ概要

> **非公式ソースコード内部設計ガイド (`v3.6.0`)** — `org.apache.ibatis.*` 配下の全 `20` パッケージ（`393` Java ファイル、`23,364` LOC、`374` クラス）に対する PNI501 静的 AST 解析および JUnit 5 コンテナ実行検証（`1,990` テスト合格、JaCoCo 行カバレッジ `87.4%`）に基づいています。

MyBatis 3 (`org.mybatis:mybatis`) は、JPA / Hibernate のような状態を持つ重い Persistence Context（Unit of Work）ではなく、**3層データマッパー＆インターセプタ・パイプライン**として設計されています。起動時に XML（`mybatis-config.xml`、`*Mapper.xml`）および Java アノテーション（`@Select`、`@Results` 等）を解析して不変の `Configuration`（`MappedStatement` / `ResultMap` レジストリ）へとコンパイルし、実行時は **`Executor`**・**`StatementHandler`**・**`ParameterHandler`**・**`ResultSetHandler`** の4つの協調オブジェクトを通じて SQL を実行します。

```drawlib align=center code=fold file=arch_overview_pipeline.png caption="MyBatis 3 v3.6.0 — MapperProxy から JDBC までのエンドツーエンド実行アーキテクチャ"
from drawlib.canvas import save, setup
from drawlib.diagrams.architecture import ArchitectureDiagram, Node, NodeGroup, PhosphorIcon
from drawlib.styles import Colors, Styles

setup(width=144, height=62, dpi=150)

d = ArchitectureDiagram(
    node_style=Styles.Dark,
    node_text_style=Styles.DarkBold.patch(text_size=10.0),
    edge_style=Styles.Dark.patch(line_width=1.5),
    edge_text_style=Styles.DarkBold.patch(text_size=9.5),
    node_card_style=Styles.Neutral.patch(shape_fill_color=Colors.White),
)

t1 = d.add(
    NodeGroup(
        "Tier 1: Session & Proxy",
        width=40,
        height=52,
        style=Styles.PrimaryNeutral,
        text_style=Styles.DarkBold.patch(text_size=10.5, halign="left", valign="top"),
    ),
    xy=(4, 5),
)
n_proxy = t1.add(
    Node(
        "MapperProxy<T>\n& MapperMethod",
        icon=PhosphorIcon.CODE,
        width=32,
        height=16,
        style=Styles.White,
        text_style=Styles.WhiteBold.patch(text_size=10.0),
        card_style=Styles.PrimaryFlat,
    ),
    xy=(20, 35),
)
n_sess = t1.add(
    Node("DefaultSqlSession\n& Configuration", icon=PhosphorIcon.STACK, width=32, height=16),
    xy=(20, 13),
)

t2 = d.add(
    NodeGroup(
        "Tier 2: Executor & Scripting Pipeline",
        width=52,
        height=52,
        style=Styles.SecondaryNeutral,
        text_style=Styles.DarkBold.patch(text_size=10.5, halign="left", valign="top"),
    ),
    xy=(48, 5),
)
n_exec = t2.add(
    Node("CachingExecutor\n-> BaseExecutor", icon=PhosphorIcon.LIGHTNING, width=42, height=16),
    xy=(26, 35),
)
n_stmt = t2.add(
    Node("StatementHandler\n& BoundSql (OGNL)", icon=PhosphorIcon.TERMINAL_WINDOW, width=42, height=16),
    xy=(26, 13),
)

t3 = d.add(
    NodeGroup(
        "Tier 3: Reflection & JDBC",
        width=36,
        height=52,
        style=Styles.Neutral,
        text_style=Styles.DarkBold.patch(text_size=10.5, halign="left", valign="top"),
    ),
    xy=(104, 5),
)
n_res = t3.add(
    Node("ResultSetHandler\n& MetaObject", icon=PhosphorIcon.SPARKLE, width=28, height=16),
    xy=(18, 35),
)
n_jdbc = t3.add(
    Node("TypeHandler<T>\n& PooledDataSource", icon=PhosphorIcon.DATABASE, width=28, height=16),
    xy=(18, 13),
)

n_proxy.connect(n_sess, label="invoke()")
n_sess.connect(n_exec, label="query/update")
n_exec.connect(n_stmt, label="prepare()")
n_stmt.connect(n_jdbc, label="bind #{}")
n_jdbc.connect(n_res, label="ResultSet")

d.draw(xy=(0, 0))
save()
```

---

## 6つのアーキテクチャ設計原則

| 設計原則 | 主要パッケージ (`org.apache.ibatis.*`) | 代表クラス | アーキテクチャ上の特徴 |
| :--- | :--- | :--- | :--- |
| **1. ゼロ外部必須依存 (Shading)** | `ognl.*` (shaded), `javassist.*` (shaded) | `OgnlCache`, `JavassistProxyFactory` | 実行時の必須外部依存は `0` 個。OGNL と Javassist は JAR 内にリロケート同梱。 |
| **2. 起動時メタデータ・コンパイル** | `builder`, `builder.xml`, `builder.annotation`, `mapping` | `XMLConfigBuilder`, `XMLMapperBuilder`, `MapperAnnotationBuilder`, `MappedStatement` | 起動時に XML とアノテーションを解析し、`Configuration` 内のスレッドセーフな `StrictMap` に登録。 |
| **3. JDK 動的プロキシ・バインディング** | `binding`, `session.defaults` | `MapperRegistry`, `MapperProxyFactory<T>`, `MapperProxy<T>`, `MapperMethod` | DAO 実装クラス不要。`Method` 単位の `MapperMethodInvoker` を `ConcurrentHashMap` にキャッシュ。 |
| **4. L1/L2 2階層キャッシュと Plugin** | `executor`, `cache`, `plugin` | `CachingExecutor`, `BaseExecutor`, `TransactionalCache`, `Plugin` | L2 トランザクションキャッシュ＋L1 セッションキャッシュ＋JDK Proxy による `Interceptor` チェーン。 |
| **5. Composite パターンによる動的 SQL AST** | `scripting.xmltags`, `scripting.defaults` | `DynamicSqlSource`, `RawSqlSource`, `SqlNode`, `DefaultParameterHandler` | `<if>` / `<foreach>` を OGNL AST で評価し、`#{}` トークンを安全な JDBC `?` プレースホルダへ変換。 |
| **6. MetaObject リフレクションと結果構築** | `executor.resultset`, `reflection`, `type` | `DefaultResultSetHandler`, `MetaObject`, `Reflector`, `TypeHandlerRegistry` | 外部 Bean マッパー無しでネスト結合・コンストラクタ注入・遅延ロードプロキシを構築。 |

---

## オブジェクト・ライフサイクルとスレッド安全性境界

MyBatis 3 の並行処理モデルは、**アプリケーション全体で共有される不変メタデータ**と、**リクエスト（トランザクション）単位で閉じ込められる状態オブジェクト**を厳格に分離しています。

```drawlib align=center code=fold file=arch_concurrency_lifecycle.png caption="MyBatis 3 v3.6.0 — オブジェクトのライフサイクルスコープとスレッド安全性境界"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, Panel
from drawlib.styles import Colors, Styles

setup(width=144, height=62, dpi=150)

white_card = Styles.Neutral.patch(shape_fill_color=Colors.White)

left_panel = Panel(
    "Application-Scoped (Thread-Safe)",
    "Shared Across All Threads",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.shield_check,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.0,
)
left_panel.draw((4.0, 4.5), width=66.5, height=53.0, align="bottom_left")
l_xy, l_w, l_h = left_panel.get_content_box(
    (4.0, 4.5), width=66.5, height=53.0, padding=(2.6, 2.4), align="bottom_left"
)

app_cards = CardList(
    style=white_card,
    text_style=Styles.DarkBold.patch(text_size=10.2),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.8),
    direction="vertical",
    spacing=2.0,
)
app_cards.add(
    "SqlSessionFactory & Configuration",
    "Built once at startup; holds StrictMap registries",
    badge_text="APP",
)
app_cards.add(
    "MapperProxyFactory & OgnlCache",
    "ConcurrentHashMap caches for Method & OGNL ASTs",
    badge_text="APP",
)
app_cards.add(
    "L2 Cache (Synchronized / LruCache)",
    "Shared namespace cache updated on commit()",
    badge_text="APP",
)
app_cards.draw(l_xy, width=l_w, height=l_h, align="bottom_left")

right_panel = Panel(
    "Request / Method-Scoped (Thread-Confined)",
    "Never Share Across Threads",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.warning_circle,
    icon_style=Styles.WarningBold,
    header_variant="filled",
    header_height=8.0,
)
right_panel.draw((73.5, 4.5), width=66.5, height=53.0, align="bottom_left")
r_xy, r_w, r_h = right_panel.get_content_box(
    (73.5, 4.5), width=66.5, height=53.0, padding=(2.6, 2.4), align="bottom_left"
)

req_cards = CardList(
    style=white_card,
    text_style=Styles.DarkBold.patch(text_size=10.2),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.SecondaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.8),
    direction="vertical",
    spacing=2.0,
)
req_cards.add(
    "SqlSession & MapperProxy<T>",
    "Open per unit-of-work in try-with-resources",
    badge_text="REQ",
)
req_cards.add(
    "Executor & L1 PerpetualCache",
    "Holds uncommitted tx state & L1 session cache",
    badge_text="REQ",
)
req_cards.add(
    "StatementHandler & BoundSql",
    "Created per SQL execution; closed immediately",
    badge_text="CALL",
)
req_cards.draw(r_xy, width=r_w, height=r_h, align="bottom_left")

save()
```

---

## 章構成ガイド

1. **[3層パッケージ構成と Shading](01_package_and_layers.md)** — `org.apache.ibatis.*` 全20パッケージの3層構造と、`maven-shade-plugin` による OGNL / Javassist 同梱の仕組み。
2. **[起動コンパイルと Builder 群](02_bootstrap_and_builders.md)** — `SqlSessionFactoryBuilder`、`XMLConfigBuilder`、`XMLMapperBuilder`、`MapperAnnotationBuilder` による `Configuration` 構築。
3. **[MapperProxy 動的ディスパッチ](03_mapper_proxy_engine.md)** — `MapperRegistry`、`MapperProxyFactory<T>`、`MapperProxy<T>`、`MapperMethod` によるインターフェース呼び出しディスパッチ。
4. **[Executor・L1/L2 キャッシュ・Plugin](04_executor_and_caching.md)** — `BaseExecutor` (`Simple` / `Reuse` / `Batch`)、`CachingExecutor`、`TransactionalCacheManager`、および `Plugin.wrap()`。
5. **[動的 SQL AST と OGNL 評価](05_dynamic_sql_and_ognl.md)** — `XMLLanguageDriver`、`RawSqlSource` / `DynamicSqlSource`、`SqlNode` ツリー、`DefaultParameterHandler` の内部構造。
6. **[ResultSet マッピングと Reflection](06_resultset_and_reflection.md)** — `DefaultResultSetHandler`、`MetaObject`、`Reflector`、`JavassistProxyFactory` によるオブジェクトグラフ構築と遅延ロード。
