# 6. Java アノテーションと SQL Builder

Java 17 以降の複数行テキストブロック (`""" ... """`) と、`org.apache.ibatis.annotations` パッケージの全 39 アノテーションおよび流暢な `org.apache.ibatis.jdbc.SQL` ビルダを組み合わせることで、外部の XML ファイルを使わずに Java インターフェース単体で完結するクリーンな Mapper を記述できます。

---

## アノテーション・`*Provider`・XML の使い分け

```drawlib align=center code=fold file=ug_06_annotation_modes_ja.png caption="MyBatis 3 における 3 つの SQL 記述スタイルの使い分け"
from drawlib.canvas import save, setup
from drawlib.smartarts import CardList
from drawlib.styles import Colors, Styles

setup(width=144, height=38, dpi=150)

cards = CardList(
    style=Styles.Neutral.patch(shape_fill_color=Colors.White),
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Dark.patch(text_size=8.6),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.0),
    direction="horizontal",
    spacing=3.0,
)

cards.add(
    "1. 直接 @Select / @Insert",
    'Java 17+ の """ テキストブロックによる定型 CRUD。\n@Options, @Results, @Arg に完全対応。',
    badge_text="INLINE",
)
cards.add(
    "2. @SelectProvider + SQL",
    "ProviderMethodResolver と SQL.SELECT().WHERE() による\nIDE リファクタリング可能な型安全動的 SQL。",
    badge_text="BUILDER",
)
cards.add(
    "3. Mapper XML (ハイブリッド)",
    "多重 JOIN や CTE 集計向け。同一 Mapper 内で単純メソッドは\n@Select、複雑クエリは XML と混在可能!",
    badge_text="HYBRID",
)

cards.draw((4.0, 4.0), width=136.0, height=30.0, align="bottom_left")
save()
```

> [!TIP]
> **アノテーションと XML のハイブリッド構成が標準で可能:** プロジェクト全体、あるいは 1 つの Mapper インターフェースの中でさえ、アノテーションか XML の一方に統一する必要はありません。80% の定型 CRUD メソッドは `AuthorMapper.java` に直接 `@Select` / `@Insert` で記述し、残り 20% の複雑な集計クエリや多重 JOIN だけを `AuthorMapper.xml` に切り出すハイブリッド運用が最も生産的です。

---

## コア CRUD アノテーションと `@Results` の再利用

```java
package com.example.blog.mapper;

import java.util.Optional;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Options;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Result;
import org.apache.ibatis.annotations.ResultMap;
import org.apache.ibatis.annotations.Results;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

public interface AuthorMapper {

  @Results(id = "authorResultMap", value = {
    @Result(property = "id", column = "id", id = true),
    @Result(property = "username", column = "username"),
    @Result(property = "email", column = "email"),
    @Result(property = "createdAt", column = "created_at")
  })
  @Select("""
      SELECT id, username, email, created_at
      FROM authors
      WHERE id = #{id}
      """)
  Optional<Author> findById(@Param("id") long id);

  // 上記で定義した id = "authorResultMap" を @ResultMap で他メソッドから再利用!
  @ResultMap("authorResultMap")
  @Select("""
      SELECT id, username, email, created_at
      FROM authors
      WHERE email = #{email}
      """)
  Optional<Author> findByEmail(@Param("email") String email);

  @Insert("""
      INSERT INTO authors (username, email, created_at)
      VALUES (#{username}, #{email}, #{createdAt})
      """)
  @Options(useGeneratedKeys = true, keyProperty = "id", keyColumn = "id")
  int insert(Author author);

  @Update("""
      UPDATE authors
      SET username = #{username}, email = #{email}
      WHERE id = #{id}
      """)
  int update(Author author);

  @Delete("DELETE FROM authors WHERE id = #{id}")
  int deleteById(@Param("id") long id);
}
```

### `@Arg` によるコンストラクタマッピング

MyBatis 3.5.4 以降では、`@ConstructorArgs` で囲むことなく `@Arg` をメソッドへ直接複数付与できます。

```java
@Arg(id = true, column = "id", javaType = Long.class, name = "id")
@Arg(column = "username", javaType = String.class, name = "username")
@Arg(column = "email", javaType = String.class, name = "email")
@Select("SELECT id, username, email FROM authors WHERE id = #{id}")
AuthorRecord findRecordById(@Param("id") long id);
```

---

## `@SelectProvider` と `SQL` ビルダによるプログラマティック動的 SQL

アノテーション内に `<script>` XML タグを埋め込む代わりに、`@SelectProvider` (および `@InsertProvider`・`@UpdateProvider`・`@DeleteProvider`) を `ProviderMethodResolver` および `org.apache.ibatis.jdbc.SQL` と組み合わせることができます。

プロバイダクラスが `ProviderMethodResolver` を実装していれば、MyBatis は Mapper メソッドと **同名のプロバイダメソッド** を自動的に呼び出します。

```drawlib align=center code=fold file=ug_06_provider_flow_ja.png caption="ProviderSqlSource と org.apache.ibatis.jdbc.SQL ビルダの実行パイプライン"
from drawlib.canvas import save, setup
from drawlib.diagrams.architecture import ArchitectureDiagram, Node, NodeGroup, PhosphorIcon
from drawlib.styles import Colors, Styles

setup(width=144, height=46, dpi=150)

d = ArchitectureDiagram(
    node_style=Styles.Dark,
    node_text_style=Styles.DarkBold.patch(text_size=9.2),
    edge_style=Styles.Dark.patch(line_width=1.5),
    edge_text_style=Styles.DarkBold.patch(text_size=8.8),
    node_card_style=Styles.Neutral.patch(shape_fill_color=Colors.White),
)

grp = d.add(
    NodeGroup(
        "@SelectProvider と ProviderMethodResolver による型安全な動的 SQL 生成",
        width=136,
        height=36,
        style=Styles.SecondaryNeutral,
        text_style=Styles.DarkBold.patch(text_size=10.0, halign="left", valign="top"),
    ),
    xy=(4, 5),
)
n_m = grp.add(Node("Mapper インターフェース\n@SelectProvider(PostSqlProvider.class)\nsearchPosts(filter)", icon=PhosphorIcon.CODE, width=40, height=15), xy=(24, 15))
n_b = grp.add(Node("PostSqlProvider.searchPosts()\nnew SQL().SELECT(...)\n.WHERE(...).toString()", icon=PhosphorIcon.SLIDERS, width=42, height=15), xy=(69, 15))
n_s = grp.add(Node("ProviderSqlSource\n#{...} を '?' に変換し\nTypeHandler で安全バインド", icon=PhosphorIcon.SHIELD_CHECK, width=38, height=15), xy=(113, 15))

n_m.connect(n_b, label="同名メソッド呼出")
n_b.connect(n_s, label="#{} 付き SQL")

d.draw(xy=(0, 0))
save()
```

```java
package com.example.blog.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.SelectProvider;
import org.apache.ibatis.builder.annotation.ProviderMethodResolver;
import org.apache.ibatis.jdbc.SQL;

public interface PostMapper {

  @SelectProvider(type = PostSqlProvider.class)
  List<Post> searchPosts(
      @Param("authorId") Long authorId,
      @Param("status") String status,
      @Param("keyword") String keyword);

  class PostSqlProvider implements ProviderMethodResolver {

    public static String searchPosts(
        @Param("authorId") Long authorId,
        @Param("status") String status,
        @Param("keyword") String keyword) {
      return new SQL() {{
        SELECT("p.id, p.author_id, p.title, p.status, p.published_at");
        FROM("posts p");
        INNER_JOIN("authors a ON a.id = p.author_id");
        if (authorId != null) {
          WHERE("p.author_id = #{authorId}");
        }
        if (status != null && !status.isBlank()) {
          WHERE("p.status = #{status}");
        }
        if (keyword != null && !keyword.isBlank()) {
          WHERE("p.title ILIKE '%' || #{keyword} || '%'");
        }
        ORDER_BY("p.published_at DESC");
        LIMIT(50);
      }}.toString();
    }
  }
}
```

`new SQL()` は複数の `WHERE(...)` 呼び出しを自動的に `AND` で結合します。また、返却される文字列内では引き続き `#{authorId}`・`#{status}`・`#{keyword}` を使用するため、`ProviderSqlSource` によってすべてのパラメータが安全な `PreparedStatement` の `?` プレースホルダへコンパイルされます。
