ARG JAVA_VERSION=21
FROM maven:3.9-eclipse-temurin-21

ENV MAVEN_CONFIG="/tmp/.m2" \
    MAVEN_OPTS="-Dmaven.repo.local=/m2repo -Dlicense.skip=true -Dformatter.skip=true -Dimpsort.skip=true"

RUN useradd --uid 10001 --create-home --shell /bin/bash pni \
    && mkdir -p /workspace /out /m2repo \
    && chmod 0777 /out

WORKDIR /workspace
COPY --chown=pni:pni pom.xml dependencies-lock.json mvnw mvnw.cmd format.xml LICENSE LICENSE-MYBATIS LICENSE_HEADER NOTICE README.md /workspace/
COPY --chown=pni:pni .mvn /workspace/.mvn

RUN git init /workspace \
    && git -C /workspace config user.email "pni@localhost" \
    && git -C /workspace config user.name "pni" \
    && git -C /workspace commit --allow-empty -m "mybatis-3.6.0 snapshot" \
    && git config --system --add safe.directory /workspace \
    && mvn -B -Dmaven.repo.local=/m2repo \
      -Dlicense.skip=true \
      dependency:go-offline \
      org.jacoco:jacoco-maven-plugin:0.8.12:help \
      dependency:build-classpath -Dmdep.outputFile=/m2repo/runtime_cp.txt

COPY --chown=pni:pni src /workspace/src

RUN mvn -B -Dmaven.repo.local=/m2repo \
      -Dlicense.skip=true \
      test \
      -Dtest=org.apache.ibatis.reflection.MetaObjectTest \
      -DfailIfNoTests=false \
      -Dmaven.test.failure.ignore=true \
      jacoco:report \
    && rm -rf target/surefire-reports target/site target/jacoco.exec \
    && chown -R pni:pni /workspace /m2repo \
    && chmod -R a+rwX /workspace /m2repo /out

USER pni
CMD ["mvn", "-B", "-o", "-Dmaven.repo.local=/m2repo", "test"]
