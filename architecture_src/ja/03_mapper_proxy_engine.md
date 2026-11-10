# 3. MapperProxy 動的ディスパッチ

MyBatis 3 の大きな特徴は、開発者が **Java インターフェース（例: `UserMapper`）のみを定義**すればよく、DAO 実装クラスを一切記述する必要がない点です。`org.apache.ibatis.binding` パッケージ（全 `6` ファイル）が `java.lang.reflect.Proxy` と `MapperMethodInvoker` キャッシュを用いて、インターフェース呼び出しを `SqlSession` の各コマンドへと変換します。

```drawlib align=center code=fold file=arch_mapper_proxy_class.png caption="MyBatis 3 v3.6.0 — MapperRegistry・MapperProxyFactory・MapperProxy・MapperMethod のクラス構造"
from drawlib.canvas import save, setup
from drawlib.diagrams.class_diagram import ClassDiagram, ClassNode
from drawlib.fonts import FontMonoSpace, FontRoboto
from drawlib.styles import Colors, Styles

setup(width=144, height=74, dpi=150)

cd = ClassDiagram(
    width=144.0,
    height=74.0,
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

n_reg = cd.add(
    ClassNode("MapperRegistry", width=42.0, header_style=sec_hdr)
    .add_attribute("knownMappers", "Map<Class<?>, Factory>")
    .add_method("getMapper", "type, session", "T")
    .add_method("addMapper", "type", "void"),
    xy=(28.0, 56.0),
)

n_fac = cd.add(
    ClassNode("MapperProxyFactory<T>", width=44.0, header_style=sec_hdr)
    .add_attribute("mapperInterface", "Class<T>")
    .add_attribute("methodCache", "ConcurrentHashMap")
    .add_method("newInstance", "sqlSession", "T"),
    xy=(98.0, 56.0),
)

n_proxy = cd.add(
    ClassNode("MapperProxy<T>", stereotype="InvocationHandler", width=44.0, header_style=hero_hdr)
    .add_attribute("sqlSession", "SqlSession")
    .add_attribute("methodCache", "Map<Method, Invoker>")
    .add_method("invoke", "proxy, method, args", "Object"),
    xy=(32.0, 20.0),
)

n_method = cd.add(
    ClassNode("MapperMethod", width=48.0)
    .add_attribute("command", "SqlCommand (name, type)")
    .add_attribute("method", "MethodSignature (ParamNameResolver)")
    .add_method("execute", "sqlSession, args", "Object"),
    xy=(102.0, 20.0),
)

cd.connect(n_reg, n_fac, "composition", directed=True, start_side="right", end_side="left")
cd.connect(n_fac, n_proxy, "dependency", start_side="bottom", end_side="top")
cd.connect(n_proxy, n_method, "composition", directed=True, start_side="right", end_side="left")

cd.draw(xy=(0.0, 0.0))
save()
```

---

## `MapperProxy.invoke()` の3分岐ディスパッチ機構

`UserMapper` のメソッドが呼び出されると、`MapperProxy.invoke(Object proxy, Method method, Object[] args)` (`src/main/java/org/apache/ibatis/binding/MapperProxy.java:78-115`) は以下の3経路に分岐します。

1. **`Object` 基底メソッド (`toString`, `hashCode`, `equals`)**:
   - `Object.class.equals(method.getDeclaringClass())` で判定し、`SqlSession` を介さず直接実行します。
2. **Java 8+ インターフェース `default` メソッド (`DefaultMethodInvoker`)**:
   - `method.isDefault()` の場合、`MethodHandles.Lookup` (`privateLookupIn`) を用いた `DefaultMethodInvoker` を生成・キャッシュし、プロキシインスタンス上の default メソッドを直接呼び出します。
3. **通常の SQL マッパーメソッド (`PlainMethodInvoker` -> `MapperMethod`)**:
   - `MapperProxyFactory.methodCache` (`ConcurrentHashMap<Method, MapperMethodInvoker>`) にメソッド単位でキャッシュされ、`MapperMethod.execute(sqlSession, args)` へ委譲します。

---

## `MapperMethod.execute()` による SQL 種別・戻り値型ルーティング

`MapperMethod` (`src/main/java/org/apache/ibatis/binding/MapperMethod.java:60-128`) は、起動・初回呼び出し時に構築される2つのメタデータ構造を保持します。
- **`SqlCommand`**: ステートメント ID (`インターフェース完全修飾名.メソッド名`) と `SqlCommandType` (`INSERT`, `UPDATE`, `DELETE`, `SELECT`, `FLUSH`) を解決。
- **`MethodSignature`**: `TypeParameterResolver.resolveReturnType()` によるジェネリクス戻り値型解析、`RowBounds` / `ResultHandler` 引数位置の特定、および `ParamNameResolver` による引数名解決を担当。

```drawlib align=center code=fold file=arch_mapper_method_routing.png caption="MyBatis 3 v3.6.0 — SqlCommandType と戻り値シグネチャに基づく MapperMethod.execute() ルーティング表"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import Panel, Table
from drawlib.styles import Colors, Styles

setup(width=144, height=66, dpi=150)

panel = Panel(
    "MapperMethod.execute(sqlSession, args) Dispatch Matrix",
    "Pre-compiled SqlCommand + MethodSignature -> SqlSession Method",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=10.8),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.git_branch,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=8.0,
)
panel.draw((4.0, 4.5), width=136.0, height=57.0, align="bottom_left")

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

rows = [
    ["SqlCommandType", "Method Return Signature", "SqlSession Target Call", "Post-Processing / Return"],
    ["INSERT / UPDATE\n/ DELETE", "int / long / boolean / void", "insert() / update() / delete()", "rowCountResult(rowCount)\n(bool: >0, void: null)"],
    ["SELECT", "void + ResultHandler param", "select(id, param, handler)", "Streams rows to callback;\nreturns null"],
    ["SELECT", "Collection<E> or E[] array", "selectList(id, param, rb)", "executeForMany() converts\nList to Set or Array"],
    ["SELECT", "Map<K, V> + @MapKey(\"id\")", "selectMap(id, param, key, rb)", "executeForMap() indexes\nrows by @MapKey property"],
    ["SELECT", "Cursor<T>", "selectCursor(id, param, rb)", "executeForCursor() returns\nlazy JDBC stream iterator"],
    ["SELECT", "Single Domain Bean T\nor Optional<T>", "selectOne(id, param)", "Wraps in Optional.ofNullable\nif return type is Optional"],
]

tbl.draw_flexible(
    xy=(7.0, 51.5),
    column_widths=[25.0, 35.0, 35.0, 35.0],
    row_heights=[6.0] + [7.2] * 6,
    data=rows,
    align="top_left",
)

save()
```

### `ParamNameResolver.getNamedParams(Object[] args)` による引数パッケージング

マッパーメソッドの引数は `ParamNameResolver` (`src/main/java/org/apache/ibatis/reflection/ParamNameResolver.java:108-145`) によって以下のように変換されます。
- **引数 0 個**: `null` を返します。
- **引数 1 個（`@Param` なし）**: 引数値 `args[0]` をそのまま渡します（ただし `Collection` や配列の場合は `DefaultSqlSession.wrapCollection()` により `"collection"` / `"list"` / `"array"` キーを持つ `ParamMap` にラップされます）。
- **複数引数、または `@Param` 指定あり**: `MapperMethod.ParamMap<Object>` に **`@Param` 名（または `-parameters` コンパイル引数名）** と汎用キー **`"param1"`, `"param2"`, ...** の両方を格納します。未定義キーを参照した場合は、利用可能なパラメータ一覧を含む `BindingException` が即座に送出されます。
