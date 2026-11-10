# Session & Binding API

`org.apache.ibatis.session`・`org.apache.ibatis.binding`・`org.apache.ibatis.cursor` パッケージが提供する、セッション管理・設定レジストリ・ストリーミング `Cursor`・動的マッパーバインディングのコア API リファレンスです。

```drawlib align=center code=fold file=api_session_lifecycle_ja.png caption="MyBatis 3 v3.6.0 — SqlSessionFactoryBuilder -> SqlSessionFactory -> SqlSession -> MapperProxy のライフサイクル"
from drawlib.canvas import save, setup
from drawlib.diagrams.sequence import Participant, PhosphorIcon, SequenceDiagram
from drawlib.styles import Styles

setup(width=144, height=62, dpi=150)

sd = SequenceDiagram(
    node_style=Styles.Dark,
    node_text_style=Styles.DarkBold.patch(text_size=9.6),
    edge_style=Styles.Dark.patch(line_width=1.4),
    edge_text_style=Styles.Dark.patch(text_size=9.2),
    node_card_style=Styles.Neutral,
    col_width=34.0,
    step_y=6.8,
)

p_app = sd.add(Participant("Caller / Service", icon=PhosphorIcon.CODE, width=26, card_style=Styles.Neutral))
p_fac = sd.add(Participant("SqlSessionFactory", icon=PhosphorIcon.FACTORY, width=26, card_style=Styles.PrimaryNeutral))
p_ses = sd.add(
    Participant(
        "SqlSession",
        icon=PhosphorIcon.STACK,
        width=26,
        style=Styles.White,
        text_style=Styles.WhiteBold.patch(text_size=9.6),
        card_style=Styles.PrimaryFlat,
    )
)
p_map = sd.add(Participant("MapperProxy<T>", icon=PhosphorIcon.LIGHTNING, width=26, card_style=Styles.SecondaryNeutral))

p_app.request(p_fac, "openSession() [try-with-resources]")
p_fac.reply(p_ses, "new DefaultSqlSession(cfg, exec)")
p_app.request(p_ses, "getMapper(UserMapper.class)")
p_ses.reply(p_map, "Proxy.newProxyInstance(...)")
p_app.request(p_map, "mapper.findById(42L)")
p_map.request(p_ses, "selectOne(id, 42L) & close()")

sd.draw(xy=(72, 31), align="center")
save()
```

## `class` SqlSessionFactoryBuilder

XML (`InputStream` / `Reader`) またはプログラマティックな `Configuration` から `DefaultSqlSessionFactory` を生成する起動用ビルダークラス (`org.apache.ibatis.session.SqlSessionFactoryBuilder`) です。`build()` 完了後は即座に破棄できます。

| メソッドシグネチャ | 戻り値型 | 説明 |
| :--- | :--- | :--- |
| `build(InputStream inputStream)` | `SqlSessionFactory` | デフォルトの `<environments default="...">` を用いて `mybatis-config.xml` を解析します。 |
| `build(InputStream in, String environment, Properties props)` | `SqlSessionFactory` | 環境 ID (`<environment id="...">`) と外部 `Properties` 変数を指定して XML 設定を解析します。 |
| `build(Reader reader, String environment, Properties props)` | `SqlSessionFactory` | 文字ストリーム (`Reader`) から `mybatis-config.xml` を解析します。 |
| `build(Configuration config)` | `SqlSessionFactory` | Java コードで組み立てた `Configuration` から `DefaultSqlSessionFactory` を生成します。 |

## `interface` SqlSessionFactory

アプリケーションスコープでシングルトン共有されるスレッドセーフなファクトリインターフェース (`org.apache.ibatis.session.SqlSessionFactory`, 実装クラスは `DefaultSqlSessionFactory`) です。

| メソッドシグネチャ | 戻り値型 | 説明 |
| :--- | :--- | :--- |
| `openSession()` | `SqlSession` | `autoCommit = false`・デフォルト `ExecutorType` (`SIMPLE`) でトランザクションセッションを開始します。 |
| `openSession(boolean autoCommit)` | `SqlSession` | `autoCommit` を明示指定してセッションを開始します（明示的トランザクション制御には `false` を推奨）。 |
| `openSession(ExecutorType execType)` | `SqlSession` | `ExecutorType.SIMPLE` / `REUSE` / `BATCH` を指定してセッションを開始します。 |
| `openSession(TransactionIsolationLevel level)` | `SqlSession` | トランザクション分離レベル（`READ_COMMITTED`, `SERIALIZABLE` 等）を指定してセッションを開始します。 |
| `openSession(Connection connection)` | `SqlSession` | 外部から渡された JDBC `Connection` を用いてセッションを開始します。 |
| `getConfiguration()` | `Configuration` | 保持している不変の `Configuration` インスタンスを返します。 |

## `interface` SqlSession

SQL 実行・Mapper プロキシ取得・トランザクション制御を担う中核インターフェース (`org.apache.ibatis.session.SqlSession extends Closeable`, 実装は `DefaultSqlSession`) です。**スレッドセーフではない**ため、必ずリクエスト／メソッド単位の `try-with-resources` ブロック内で使用してください。

| メソッドシグネチャ | 戻り値型 | 説明 |
| :--- | :--- | :--- |
| `<T> T getMapper(Class<T> type)` | `T` | この `SqlSession` に紐づくマッパーインターフェース `T` の JDK 動的プロキシを返します。 |
| `<T> T selectOne(String statement, Object parameter)` | `T` | 最大1件の行を返す SELECT を実行します。2件以上ヒットした場合は `TooManyResultsException` を送出します。 |
| `<E> List<E> selectList(String statement, Object param, RowBounds rb)` | `List<E>` | 複数行を返す SELECT を実行し、マッピング済みオブジェクトの `List<E>` を返します。 |
| `<K, V> Map<K, V> selectMap(String stmt, Object param, String mapKey)` | `Map<K, V>` | SELECT 結果を指定プロパティ `mapKey` をキーとする `Map<K, V>` に格納して返します。 |
| `<T> Cursor<T> selectCursor(String stmt, Object param, RowBounds rb)` | `Cursor<T>` | オープン状態の JDBC `ResultSet` から逐次フェッチを行う遅延イテレータ `Cursor<T>` を返します。 |
| `void select(String stmt, Object param, ResultHandler<?> handler)` | `void` | `List` に溜め込まず、1行ごとに `ResultHandler.handleResult(ResultContext)` コールバックへ渡します。 |
| `int insert(String statement, Object parameter)` | `int` | `INSERT` を実行（設定された `KeyGenerator` も実行）し、更新行数を返します。 |
| `int update(String statement, Object parameter)` | `int` | `UPDATE` を実行し、L1 キャッシュをクリアして更新行数を返します。 |
| `int delete(String statement, Object parameter)` | `int` | `DELETE` を実行し、L1 キャッシュをクリアして更新行数を返します。 |
| `List<BatchResult> flushStatements()` | `List<BatchResult>` | `ExecutorType.BATCH` 使用時に蓄積されたバッチ更新をフラッシュします。 |
| `void commit()` / `void commit(boolean force)` | `void` | トランザクションをコミットし、バッチのフラッシュおよび L2 `TransactionalCache` の本反映を行います。 |
| `void rollback()` / `void rollback(boolean force)` | `void` | トランザクションをロールバックし、ステージングされた L2 キャッシュ変更を破棄します。 |
| `void clearCache()` | `void` | セッション内の L1 ローカルキャッシュ (`PerpetualCache`) を消去します。 |
| `void close()` | `void` | 未コミットの変更をロールバックし、`Executor`・`Transaction`・JDBC 接続をクローズします。 |

## `class` Configuration

すべての `<settings>`、`Environment`、`TypeHandlerRegistry`、`TypeAliasRegistry`、`MapperRegistry`、`InterceptorChain`、および `MappedStatement` / `ResultMap` / `Cache` 等の `StrictMap` を保持する中央メタデータ・クラス (`org.apache.ibatis.session.Configuration`) です。

| 主要設定プロパティ / メソッド | 型 / デフォルト値 | 説明 |
| :--- | :--- | :--- |
| `mapUnderscoreToCamelCase` | `boolean` (`false`) | SQL の `snake_case` カラム名 (`created_at`) を Java の `camelCase` プロパティ (`createdAt`) に自動マッピングします。 |
| `cacheEnabled` | `boolean` (`true`) | `CachingExecutor` による L2 キャッシュ機能全体の有効／無効を制御します。 |
| `lazyLoadingEnabled` | `boolean` (`false`) | `<association>` / `<collection>` における遅延ロードプロキシ (`JavassistProxyFactory`) を有効化します。 |
| `aggressiveLazyLoading` | `boolean` (`false`) | `false`（推奨デフォルト）の場合、アクセスされた遅延プロパティのみをオンデマンドでロードします。 |
| `localCacheScope` | `LocalCacheScope` (`SESSION`) | L1 キャッシュの有効範囲（`SESSION` または `STATEMENT`）を指定します。 |
| `defaultExecutorType` | `ExecutorType` (`SIMPLE`) | デフォルトの `Executor` 実装（`SIMPLE`, `REUSE`, `BATCH`）を指定します。 |
| `defaultStatementTimeout` | `Integer` (`null`) | 全ステートメントに適用する JDBC `Statement.setQueryTimeout(秒)` のデフォルト値。 |
| `defaultFetchSize` | `Integer` (`null`) | 全 SELECT に適用する JDBC `Statement.setFetchSize(行数)` ヒント。 |
| `jdbcTypeForNull` | `JdbcType` (`OTHER`) | `null` パラメータに `jdbcType` 指定がない場合のデフォルト型（`NULL`, `VARCHAR`, `OTHER`）。 |
| `useGeneratedKeys` | `boolean` (`false`) | `INSERT` 時に JDBC `getGeneratedKeys()` (`Jdbc3KeyGenerator`) をデフォルトで使用します。 |
| `shrinkWhitespacesInSql` | `boolean` (`false`) | SQL 文字列内の連続する空白や改行を圧縮します。 |
| `argNameBasedConstructorAutoMapping` | `boolean` (`false`) | Java `record` 等のコンストラクタ自動マッピング時に引数名ベースでカラムを照合します。 |
| `addMapper(Class<T> type)` | `void` | マッパーインターフェースを登録し、`MapperAnnotationBuilder.parse()` を実行します。 |
| `addMappers(String packageName)` | `void` | 指定パッケージ配下のマッパーインターフェースを一括スキャン・登録します。 |

## `enum` ExecutorType

`SqlSession` が使用する `BaseExecutor` サブクラス (`org.apache.ibatis.session.ExecutorType`) を選択します。
- `SIMPLE`: 各 SQL 実行ごとに新しい `PreparedStatement` を生成します（デフォルト）。
- `REUSE`: SQL 文字列をキーとして `PreparedStatement` をセッション内で再利用します (`ReuseExecutor`)。
- `BATCH`: 連続する更新系 SQL を `Statement.addBatch()` でバッチ化し、`flushStatements()` または `commit()` 時に一括送信します (`BatchExecutor`)。

## `class` RowBounds

オフセット `offset` と件数上限 `limit` を表すページング値オブジェクト (`org.apache.ibatis.session.RowBounds`) です（デフォルト `RowBounds.DEFAULT`: `offset = 0`, `limit = Integer.MAX_VALUE`）。大量データでは DB 側の `LIMIT / OFFSET` 句の併用を推奨します。

## `interface` ResultHandler<T>

結果行を `List<T>` に蓄積せず1件ずつコールバック処理するためのインターフェース (`org.apache.ibatis.session.ResultHandler<T>`) です。`handleResult(ResultContext<? extends T> ctx)` 内で `ctx.getResultObject()`・`ctx.getResultCount()`・`ctx.stop()` を利用できます。

## `interface` Cursor<T>

オープン状態の JDBC `ResultSet` からイテレーション時にオンデマンドで行を読み出すストリーミング・イテレータ (`org.apache.ibatis.cursor.Cursor<T> extends Closeable, Iterable<T>`, 実装は `DefaultCursor<T>`) です。開いている `SqlSession` 内で `try-with-resources` を用いて確実にクローズする必要があります。

## `class` MapperRegistry

マッパーインターフェース `Class<?>` と `MapperProxyFactory<?>` の対応を保持するレジストリ (`org.apache.ibatis.binding.MapperRegistry`) です。`getMapper(Class<T>, SqlSession)`・`hasMapper(Class<T>)`・`addMapper(Class<T>)`・`addMappers(String packageName)` を提供します。
