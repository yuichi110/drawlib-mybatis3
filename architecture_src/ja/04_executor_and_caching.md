# 4. Executor・L1/L2キャッシュ・Plugin

すべての `SqlSession` は、`Configuration.newExecutor(Transaction, ExecutorType)` (`src/main/java/org/apache/ibatis/session/Configuration.java:743-760`) が生成する **`org.apache.ibatis.executor.Executor`** に DB 操作を委譲します。このファクトリメソッドはわずか15行のコードで3つの GoF デザインパターンを合成しています。
1. **Template Method パターン (`BaseExecutor`)**: L1 キャッシュ（`PerpetualCache`）検索、遅延ロードキュー管理、トランザクション制御を共通実装し、実際の JDBC `Statement` 実行のみを `SimpleExecutor`・`ReuseExecutor`・`BatchExecutor` に委譲します。
2. **Decorator パターン (`CachingExecutor`)**: `cacheEnabled = true`（デフォルト）のとき `BaseExecutor` をラップし、`TransactionalCacheManager` による L2 名前空間キャッシュを付加します。
3. **Dynamic Proxy チェーン (`InterceptorChain.pluginAll`)**: `@Intercepts` アノテーションを持つプラグインを `Executor`・`StatementHandler`・`ParameterHandler`・`ResultSetHandler` に `Plugin.wrap()` で多重適用します。

```drawlib align=center code=fold file=arch_executor_hierarchy.png caption="MyBatis 3 v3.6.0 — Executor Template Method 階層と CachingExecutor L2 デコレータ"
from drawlib.canvas import save, setup
from drawlib.diagrams.class_diagram import ClassDiagram, ClassNode
from drawlib.fonts import FontMonoSpace, FontRoboto
from drawlib.styles import Colors, Styles

setup(width=144, height=76, dpi=150)

cd = ClassDiagram(
    width=144.0,
    height=76.0,
    node_style=Styles.Neutral.patch(
        shape_fill_color=Colors.White,
        shape_line_color=Colors.Gray6,
        text_color=Colors.Dark,
        text_font=FontMonoSpace.ROBOTO_MONO_REGULAR,
        text_size=9.2,
    ),
    header_style=Styles.PrimaryNeutral.patch(
        shape_line_color=Colors.Gray6,
        text_color=Colors.Dark,
        text_font=FontRoboto.ROBOTO_BOLD,
        text_size=9.8,
    ),
    edge_style=Styles.Dark.patch(line_width=1.4),
    edge_text_style=Styles.DarkBold.patch(text_font=FontRoboto.ROBOTO_BOLD, text_size=9.2),
)

hero_hdr = Styles.PrimaryFlat.patch(text_color=Colors.White, text_font=FontRoboto.ROBOTO_BOLD, text_size=9.8)
sec_hdr = Styles.SecondaryNeutral.patch(shape_line_color=Colors.Gray6, text_color=Colors.Dark, text_font=FontRoboto.ROBOTO_BOLD, text_size=9.8)

n_exec = cd.add(
    ClassNode("Executor", stereotype="interface", width=42.0, header_style=hero_hdr)
    .add_method("query / update", "ms, param, ...", "List<E> / int")
    .add_method("commit / rollback", "required", "void"),
    xy=(72.0, 62.0),
)

n_cache_exec = cd.add(
    ClassNode("CachingExecutor  [L2 Decorator]", width=44.0, header_style=sec_hdr)
    .add_attribute("delegate", "Executor")
    .add_attribute("tcm", "TransactionalCacheManager")
    .add_method("query (checks L2 Cache)", "ms, key", "List<E>"),
    xy=(28.0, 38.0),
)

n_base_exec = cd.add(
    ClassNode("BaseExecutor  [L1 Template]", stereotype="abstract", width=44.0, header_style=sec_hdr)
    .add_attribute("localCache", "PerpetualCache (L1)")
    .add_method("doQuery / doUpdate", "abstract", "List<E> / int"),
    xy=(110.0, 38.0),
)

n_simple = cd.add(
    ClassNode("SimpleExecutor", width=36.0)
    .add_method("doQuery (new Statement)", "", "List<E>"),
    xy=(36.0, 12.0),
)
n_reuse = cd.add(
    ClassNode("ReuseExecutor", width=38.0)
    .add_attribute("statementMap", "Map<String, Stmt>")
    .add_method("doQuery (reuses SQL)", "", "List<E>"),
    xy=(82.0, 12.0),
)
n_batch = cd.add(
    ClassNode("BatchExecutor", width=38.0)
    .add_attribute("statementList", "List<Statement>")
    .add_method("doFlushStatements", "", "List<BatchResult>"),
    xy=(124.0, 12.0),
)

cd.connect(n_cache_exec, n_exec, "realization", start_side="top", end_side="left")
cd.connect(n_base_exec, n_exec, "realization", start_side="top", end_side="right")
cd.connect(n_cache_exec, n_base_exec, "association", directed=True, start_side="right", end_side="left")
cd.connect(n_simple, n_base_exec, "inheritance", start_side="top", end_side="bottom")
cd.connect(n_reuse, n_base_exec, "inheritance", start_side="top", end_side="bottom")
cd.connect(n_batch, n_base_exec, "inheritance", start_side="top", end_side="bottom")

cd.draw(xy=(0.0, 0.0))
save()
```

---

## 2階層キャッシュの動作原理 (`L2 TransactionalCache` -> `L1 PerpetualCache` -> JDBC)

`CachingExecutor.query()` (`src/main/java/org/apache/ibatis/executor/CachingExecutor.java:86-122`) の実行フローは以下の通りです。

1. **`CacheKey` の生成**: `BaseExecutor.createCacheKey()` が `[mappedStatement.id, rowBounds.offset, rowBounds.limit, boundSql.sql, パラメータ値群, environment.id]` から複合ハッシュキーを生成します。
2. **L2 名前空間キャッシュ検索 (`TransactionalCacheManager`)**:
   - `<cache/>` または `@CacheNamespace` が有効な場合、`TransactionalCacheManager.getObject(cache, key)` を検索します。
   - **トランザクション分離の要諦**: L2 キャッシュへの書き込みはセッション固有の `TransactionalCache`（`entriesToAddOnCommit` バッファ）に一旦ステージングされ、**`sqlSession.commit()` が成功した時点でのみ共有 L2 キャッシュ（`SynchronizedCache -> LoggingCache -> SerializedCache -> LruCache -> PerpetualCache`）へ反映**されます。これにより未コミットデータの Dirty Read が完全に防がれます。
   - また、`SerializedCache` および遅延ローダ `AbstractSerialStateHolder` がデシリアライズを行う際（`CWE-502`）には、直前で `SerialFilterChecker.check()` を呼び出して JEP-290 `jdk.serialFilter` の設定有無を検証します。
3. **L1 ローカルキャッシュ検索 (`BaseExecutor.localCache`)**:
   - L2 ミス時は `BaseExecutor.localCache` (`PerpetualCache`) を検索します。
   - デフォルトの `localCacheScope = SESSION` では同一 `SqlSession` 内の同一クエリ結果を返しますが、`localCacheScope = STATEMENT` に設定するとステートメント完了ごとにクリアされます（Spring 連携環境やマルチインスタンス環境で推奨）。

```drawlib align=center code=fold file=arch_cache_and_plugin_flow.png caption="MyBatis 3 v3.6.0 — L2 TransactionalCache ステージング、L1 キャッシュ、および Plugin.wrap() インターセプト連鎖"
from drawlib.canvas import save, setup
from drawlib.diagrams.sequence import Participant, PhosphorIcon, SequenceDiagram
from drawlib.styles import Styles

setup(width=144, height=66, dpi=150)

sd = SequenceDiagram(
    node_style=Styles.Dark,
    node_text_style=Styles.DarkBold.patch(text_size=9.6),
    edge_style=Styles.Dark.patch(line_width=1.4),
    edge_text_style=Styles.Dark.patch(text_size=9.2),
    node_card_style=Styles.Neutral,
    col_width=34.0,
    step_y=6.8,
)

p_plugin = sd.add(Participant("Plugin Proxy", icon=PhosphorIcon.PLUGS, width=26, card_style=Styles.SecondaryNeutral))
p_c_exec = sd.add(
    Participant(
        "CachingExecutor",
        icon=PhosphorIcon.STACK,
        width=26,
        style=Styles.White,
        text_style=Styles.WhiteBold.patch(text_size=9.6),
        card_style=Styles.PrimaryFlat,
    )
)
p_b_exec = sd.add(Participant("BaseExecutor (L1)", icon=PhosphorIcon.LIGHTNING, width=26, card_style=Styles.PrimaryNeutral))
p_stmt = sd.add(Participant("StatementHandler", icon=PhosphorIcon.DATABASE, width=26, card_style=Styles.Neutral))

p_plugin.request(p_c_exec, "intercept -> query(ms, param)")
p_c_exec.request(p_b_exec, "L2 Miss -> delegate.query()")
p_b_exec.request(p_stmt, "L1 Miss -> prepare & query()")
p_stmt.reply(p_b_exec, "List<E> hydrated rows")
p_b_exec.reply(p_c_exec, "stage in TransactionalCache")
p_c_exec.reply(p_plugin, "commit() flushes to L2 Cache")

sd.draw(xy=(72, 33), align="center")
save()
```

---

## `Plugin.wrap()` による4大パイプライン・インターセプト

`org.apache.ibatis.plugin.*` パッケージは、パイプラインを構成する以下4つのインターフェースに対する宣言的インターセプト機構を提供します。
- `Executor` (`update`, `query`, `flushStatements`, `commit`, `rollback`, `getTransaction`, `close`, `isClosed`)
- `ParameterHandler` (`getParameterObject`, `setParameters`)
- `ResultSetHandler` (`handleResultSets`, `handleCursorResultSets`, `handleOutputParameters`)
- `StatementHandler` (`prepare`, `parameterize`, `batch`, `update`, `query`, `queryCursor`)

`Configuration` がこれら4種のオブジェクトを生成する際、`interceptorChain.pluginAll(target)` が呼ばれます。`Plugin.wrap(target, interceptor)` は `@Intercepts({@Signature(type=..., method=..., args=...)})` アノテーションを解析し、対象インターフェースに一致する場合のみ JDK 動的プロキシでラップします。
