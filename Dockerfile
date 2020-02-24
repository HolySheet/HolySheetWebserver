FROM google/dart-runtime-base

ADD server.aot .

CMD ["/usr/bin/dartaotruntime", "server.aot"]
