FROM google/dart AS dartc
FROM bitnami/minideb

COPY --from=dartc /usr/lib/dart/bin/dartaotruntime /dartaotruntime

ADD server.aot /.

CMD ["/dartaotruntime", "server.aot"]
