FROM clojure AS uberjar
COPY zprint /usr/src/app
WORKDIR /usr/src/app
ENV ZPRINT_VERSION 1.2.3
RUN curl -sSL https://github.com/kkinnear/zprint/archive/refs/tags/$ZPRINT_VERSION.tar.gz -o zprint.tar.gz \
      && tar -xzvf zprint.tar.gz \
      && mv zprint-$ZPRINT_VERSION zprint \
      && cd zprint \
      && lein uberjar

FROM ghcr.io/graalvm/native-image AS build
ENV ZPRINT_VERSION 1.2.3
WORKDIR /app
COPY --from=uberjar /usr/src/app/zprint/target/zprint-filter-$ZPRINT_VERSION .
RUN native-image --no-server -J-Xmx8G -jar zprint-filter-$ZPRINT_VERSION \
    -H:Name="zprint" \
    -H:EnableURLProtocols=https,http \
    -H:+ReportExceptionStackTraces \
    --report-unsupported-elements-at-runtime \
    --initialize-at-build-time --no-fallback

FROM fedora
WORKDIR /src
COPY --from=build /app/zprint /usr/bin/
RUN echo '{:cwd-zprintrc? true}' | tee /.zprintrc /root/.zprintrc
ENTRYPOINT ["/usr/bin/zprint"]
CMD []/
