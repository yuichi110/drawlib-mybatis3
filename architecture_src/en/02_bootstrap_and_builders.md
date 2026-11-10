# 2. Bootstrap Compilation & Builders

At application startup, MyBatis 3 lowers external XML configuration (`mybatis-config.xml`), XML mapper files (`*Mapper.xml`), and Java interface annotations (`@Select`, `@Insert`, `@Results`, `@CacheNamespace`) into a single runtime hub: **`org.apache.ibatis.session.Configuration`**.

Every parser in `org.apache.ibatis.builder.*` extends the abstract **`BaseBuilder`** class (`src/main/java/org/apache/ibatis/builder/BaseBuilder.java`), which provides shared access to `Configuration`, `TypeAliasRegistry`, and `TypeHandlerRegistry`.

```drawlib align=center code=fold file=arch_builder_hierarchy.png caption="MyBatis 3 v3.6.0 — BaseBuilder Hierarchy & Configuration Lowering Pipeline"
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

n_base = cd.add(
    ClassNode("BaseBuilder", stereotype="abstract", width=44.0, header_style=sec_hdr)
    .add_attribute("configuration", "Configuration")
    .add_attribute("typeAliasRegistry", "TypeAliasRegistry")
    .add_method("resolveClass", "alias", "Class<T>"),
    xy=(48.0, 56.0),
)

n_cfg = cd.add(
    ClassNode("Configuration  [Singleton Hub]", width=44.0, header_style=hero_hdr)
    .add_attribute("mappedStatements", "StrictMap<MappedStatement>")
    .add_attribute("resultMaps / caches", "StrictMap<...>")
    .add_method("newExecutor", "tx, type", "Executor"),
    xy=(112.0, 56.0),
)

n_xml_cfg = cd.add(
    ClassNode("XMLConfigBuilder", width=40.0)
    .add_attribute("parser", "XPathParser")
    .add_method("parseConfiguration", "root", "void"),
    xy=(24.0, 20.0),
)

n_xml_map = cd.add(
    ClassNode("XMLMapperBuilder", width=40.0)
    .add_attribute("assistant", "MapperBuilderAssistant")
    .add_method("configurationElement", "node", "void"),
    xy=(72.0, 20.0),
)

n_ann_map = cd.add(
    ClassNode("MapperAnnotationBuilder", width=42.0)
    .add_attribute("type", "Class<?>")
    .add_method("parse / parseStatement", "method", "void"),
    xy=(119.0, 20.0),
)

cd.connect(n_base, n_cfg, "association", directed=True, start_side="right", end_side="left")
cd.connect(n_xml_cfg, n_base, "inheritance", start_side="top", end_side="bottom")
cd.connect(n_xml_map, n_base, "inheritance", start_side="top", end_side="bottom")
cd.connect(n_ann_map, n_base, "inheritance", start_side="top", end_side="bottom")

cd.draw(xy=(0.0, 0.0))
save()
```

---

## Step-by-Step Bootstrap Sequence

When `new SqlSessionFactoryBuilder().build(inputStream)` executes (`src/main/java/org/apache/ibatis/session/SqlSessionFactoryBuilder.java:50-85`):

1. **`XMLConfigBuilder` & Hardened `XPathParser`**:
   - `XMLConfigBuilder` constructs an `XPathParser` (`src/main/java/org/apache/ibatis/parsing/XPathParser.java:233-243`) configured with `XMLMapperEntityResolver` (offline DTD lookup from `org/apache/ibatis/builder/xml/*.dtd`), `FEATURE_SECURE_PROCESSING = true`, and `expandEntityReferences = false` (preventing XXE `CWE-611`).
   - `parseConfiguration(parser.evalNode("/configuration"))` processes `<properties>`, `<settings>`, `<typeAliases>`, `<plugins>`, `<objectFactory>`, `<objectWrapperFactory>`, `<reflectorFactory>`, `<environments>`, `<databaseIdProvider>`, `<typeHandlers>`, and `<mappers>` in strict order.
2. **Dual XML + Annotation Mapper Discovery (`XMLMapperBuilder` <-> `MapperAnnotationBuilder`)**:
   - Whether a mapper is registered via `<mapper resource="..."/>` (`XMLMapperBuilder`) or `configuration.addMapper(UserMapper.class)` (`MapperRegistry`), MyBatis binds **both** the XML resource and the companion Java interface if present (`XMLMapperBuilder.bindMapperForNamespace()`).
   - `MapperBuilderAssistant` (`src/main/java/org/apache/ibatis/builder/MapperBuilderAssistant.java`) namespaces every ID (`namespace + "." + id`), constructs `Cache`, `ParameterMap`, `ResultMap`, and `MappedStatement` instances, and registers them into `Configuration`.
3. **Deferred Resolution for Forward References**:
   - Because `<resultMap extends="...">`, `<cache-ref namespace="..."/>`, and `<select resultMap="..."/>` can reference declarations in mappers that have not been parsed yet, `XMLMapperBuilder` catches `IncompleteElementException` and queues `ResultMapResolver`, `CacheRefResolver`, and `MethodResolver` instances on `Configuration` (`parsePendingResultMaps()`, `parsePendingCacheRefs()`, `parsePendingStatements()`).

```drawlib align=center code=fold file=arch_bootstrap_sequence.png caption="MyBatis 3 v3.6.0 — Bootstrap Sequence from SqlSessionFactoryBuilder to DefaultSqlSessionFactory"
from drawlib.canvas import save, setup
from drawlib.diagrams.sequence import Participant, PhosphorIcon, SequenceDiagram
from drawlib.styles import Styles

setup(width=144, height=64, dpi=150)

sd = SequenceDiagram(
    node_style=Styles.Dark,
    node_text_style=Styles.DarkBold.patch(text_size=9.8),
    edge_style=Styles.Dark.patch(line_width=1.4),
    edge_text_style=Styles.Dark.patch(text_size=9.2),
    node_card_style=Styles.Neutral,
    col_width=34.0,
    step_y=7.2,
)

p_builder = sd.add(Participant("FactoryBuilder", icon=PhosphorIcon.WRENCH, width=26, card_style=Styles.PrimaryNeutral))
p_xmlcfg = sd.add(Participant("XMLConfigBuilder", icon=PhosphorIcon.FILE_CODE, width=26, card_style=Styles.Neutral))
p_mapper = sd.add(Participant("MapperBuilders", icon=PhosphorIcon.CODE, width=26, card_style=Styles.SecondaryNeutral))
p_config = sd.add(
    Participant(
        "Configuration",
        icon=PhosphorIcon.DATABASE,
        width=26,
        style=Styles.White,
        text_style=Styles.WhiteBold.patch(text_size=9.8),
        card_style=Styles.PrimaryFlat,
    )
)

p_builder.request(p_xmlcfg, "new + parse()")
p_xmlcfg.request(p_config, "settings, aliases, env")
p_xmlcfg.request(p_mapper, "mapperElement(<mappers>)")
p_mapper.request(p_config, "addMappedStatement / ResultMap")
p_mapper.request(p_config, "parsePendingResultMaps/Stmts()")
p_xmlcfg.reply(p_builder, "Configuration (immutable)")

sd.draw(xy=(72, 32), align="center")
save()
```

---

## Inside `Configuration.StrictMap<V>`: Short-Key Convenience & Ambiguity Guard

All top-level registries inside `Configuration` (`mappedStatements`, `caches`, `resultMaps`, `parameterMaps`, `keyGenerators`, `sqlFragments`) use a custom `ConcurrentHashMap<String, V>` subclass named **`StrictMap<V>`** (`src/main/java/org/apache/ibatis/session/Configuration.java:1022-1102`):

- **Dual Registration (Full Namespace + Short Name)**: When `put("com.example.UserMapper.findById", ms)` is called, `StrictMap` stores the entry under the full key `"com.example.UserMapper.findById"` **and** under the short key `"findById"`.
- **`Ambiguity` Sentinel on Collision**: If a second mapper registers `"com.example.OrderMapper.findById"`, `StrictMap` replaces the short key `"findById"` with an internal `Ambiguity` sentinel object. Calling `session.selectOne("findById")` then throws a descriptive `IllegalArgumentException: Ambiguous collection! Cannotchoose between com.example.UserMapper.findById and com.example.OrderMapper.findById`, whereas calling the fully qualified mapper interface method (`UserMapper.findById`) always resolves deterministically.
