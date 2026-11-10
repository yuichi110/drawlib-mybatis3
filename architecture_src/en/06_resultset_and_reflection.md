# 6. ResultSet Hydration, MetaObject Reflection & Lazy Proxies

Once the JDBC driver returns a `ResultSet`, **`DefaultResultSetHandler`** (`src/main/java/org/apache/ibatis/executor/resultset/DefaultResultSetHandler.java`, `1,300+` LOC) transforms tabular rows into hydrated Java domain objects, Java `record` instances, nested collections, or streaming `Cursor<T>` iterators.

```drawlib align=center code=fold file=arch_resultset_hydration.png caption="MyBatis 3 v3.6.0 — DefaultResultSetHandler Row Hydration, Constructor Resolution & Nested Join Pipeline"
from drawlib.canvas import save, setup
from drawlib.diagrams.architecture import ArchitectureDiagram, Node, NodeGroup, PhosphorIcon
from drawlib.styles import Colors, Styles

setup(width=144, height=60, dpi=150)

d = ArchitectureDiagram(
    node_style=Styles.Dark,
    node_text_style=Styles.DarkBold.patch(text_size=9.6),
    edge_style=Styles.Dark.patch(line_width=1.5),
    edge_text_style=Styles.DarkBold.patch(text_size=9.2),
    node_card_style=Styles.Neutral.patch(shape_fill_color=Colors.White),
)

jdbc_grp = d.add(
    NodeGroup(
        "1. JDBC Metadata Wrapper",
        width=40,
        height=50,
        style=Styles.SecondaryNeutral,
        text_style=Styles.DarkBold.patch(text_size=10.2, halign="left", valign="top"),
    ),
    xy=(4, 5),
)
n_rsw = jdbc_grp.add(Node("ResultSetWrapper\n(Column & Type Map)", icon=PhosphorIcon.TABLE, width=32, height=15), xy=(20, 33))
n_disc = jdbc_grp.add(Node("Discriminator\nResolution", icon=PhosphorIcon.GIT_BRANCH, width=32, height=15), xy=(20, 13))

core_grp = d.add(
    NodeGroup(
        "2. DefaultResultSetHandler",
        width=50,
        height=50,
        style=Styles.PrimaryNeutral,
        text_style=Styles.DarkBold.patch(text_size=10.2, halign="left", valign="top"),
    ),
    xy=(48, 5),
)
n_inst = core_grp.add(
    Node(
        "createResultObject\n(ObjectFactory / Record)",
        icon=PhosphorIcon.CUBE,
        width=40,
        height=15,
        style=Styles.White,
        text_style=Styles.WhiteBold.patch(text_size=9.6),
        card_style=Styles.PrimaryFlat,
    ),
    xy=(25, 33),
)
n_nest = core_grp.add(Node("applyAutoMappings &\nNested RowKey Cache", icon=PhosphorIcon.STACK, width=40, height=15), xy=(25, 13))

refl_grp = d.add(
    NodeGroup(
        "3. MetaObject & Lazy Proxy",
        width=38,
        height=50,
        style=Styles.Neutral,
        text_style=Styles.DarkBold.patch(text_size=10.2, halign="left", valign="top"),
    ),
    xy=(102, 5),
)
n_meta = refl_grp.add(Node("MetaObject &\nReflector Invokers", icon=PhosphorIcon.LIGHTNING, width=30, height=15), xy=(19, 33))
n_lazy = refl_grp.add(Node("JavassistProxyFactory\n& ResultLoaderMap", icon=PhosphorIcon.MAGIC_WAND, width=30, height=15), xy=(19, 13))

n_rsw.connect(n_disc, label="resolve")
n_disc.connect(n_inst, label="ResultMap")
n_inst.connect(n_nest, label="hydrate")
n_inst.connect(n_meta, label="setValue()")
n_nest.connect(n_lazy, label="lazy load")

d.draw(xy=(0, 0))
save()
```

---

## Inside the `org.apache.ibatis.reflection` Subsystem (`36` Files)

Instead of calling slow raw `Class.getMethod()` lookups on every row, MyBatis 3 caches class metadata inside **`DefaultReflectorFactory`** (`ConcurrentHashMap<Class<?>, Reflector>`):

```drawlib align=center code=fold file=arch_reflection_metaobject.png caption="MyBatis 3 v3.6.0 — MetaObject, ObjectWrapper, MetaClass & Reflector Architecture"
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

n_meta = cd.add(
    ClassNode("MetaObject", width=44.0, header_style=hero_hdr)
    .add_attribute("originalObject", "Object")
    .add_attribute("objectWrapper", "ObjectWrapper")
    .add_method("getValue / setValue", "propPath", "Object"),
    xy=(28.0, 56.0),
)

n_wrap = cd.add(
    ClassNode("ObjectWrapper", stereotype="interface", width=44.0, header_style=sec_hdr)
    .add_method("get / set (Bean, Map, Collection)", "prop", "Object")
    .add_method("instantiatePropertyValue", "name", "MetaObject"),
    xy=(98.0, 56.0),
)

n_mclass = cd.add(
    ClassNode("MetaClass & PropertyTokenizer", width=44.0)
    .add_attribute("reflector", "Reflector")
    .add_method("findProperty (camelCase)", "name", "String"),
    xy=(28.0, 20.0),
)

n_refl = cd.add(
    ClassNode("Reflector  [Cached per Class]", width=48.0, header_style=sec_hdr)
    .add_attribute("getMethods / setMethods", "Map<String, Invoker>")
    .add_attribute("caseInsensitivePropertyMap", "Map<String, String>")
    .add_method("getGetInvoker / getSetInvoker", "prop", "Invoker"),
    xy=(100.0, 20.0),
)

cd.connect(n_meta, n_wrap, "composition", directed=True, start_side="right", end_side="left")
cd.connect(n_wrap, n_mclass, "dependency", start_side="bottom", end_side="top")
cd.connect(n_mclass, n_refl, "association", directed=True, start_side="right", end_side="left")

cd.draw(xy=(0.0, 0.0))
save()
```

### Key Reflection & Hydration Capabilities

| Component | File Coordinate | Architectural Mechanism |
| :--- | :--- | :--- |
| **`ResultSetWrapper`** | `executor/resultset/ResultSetWrapper.java` | Extracts `ResultSetMetaData` once per query (`columnNames`, `jdbcTypes`, `classNames`) and partitions columns into `mappedColumnNamesMap` and `unMappedColumnNamesMap` per `ResultMap` prefix. |
| **`ResultMappingConstructorResolver`** | `executor/resultset/ResultMappingConstructorResolver.java` | Matches `<constructor>` / `@Arg` mappings or auto-discovers canonical constructors for **Java `record` classes and immutable domain objects**, resolving constructor argument order by name or type. |
| **Nested Join De-Duplication (`CacheKey`)** | `DefaultResultSetHandler.java:1012-1120` | For `<collection>` and `<association>` joins (`resultMap="..."`), computes a per-row `CacheKey` (`createRowKey`) and merges child rows into the parent entity inside `nestedResultObjects`. |
| **`PropertyTokenizer`** | `reflection/property/PropertyTokenizer.java` | Parses arbitrarily nested property expressions such as `orders[0].billingAddress.postalCode`, automatically instantiating intermediate objects via `BeanWrapper.instantiatePropertyValue()`. |
| **`JavassistProxyFactory` & `ResultLoaderMap`** | `executor/loader/javassist/JavassistProxyFactory.java` | When `fetchType="lazy"` or `lazyLoadingEnabled=true`, wraps the target bean in a shaded Javassist proxy that intercepts getter calls and triggers `ResultLoader.loadResult()` on demand. |
