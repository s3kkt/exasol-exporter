FROM ncabatoff/dbms_exporter_builder:1.1.5 as build
ARG drivers="odbc"
ARG ldflags=""
ENV GOFLAGS="-mod=vendor"

WORKDIR /build/
#RUN apt update && apt install -y git-core
RUN git clone https://github.com/ncabatoff/dbms_exporter.git
WORKDIR /build/dbms_exporter

ADD https://x-up.s3.amazonaws.com/7.x/7.1.19/EXASOL_ODBC-7.1.19.tar.gz /tmp/
RUN mkdir -p /tmp/EXASOL && \
  tar -vzxf /tmp/EXASOL_ODBC-7.1.19.tar.gz -C /tmp/EXASOL && \
  mkdir -p /opt/lib/exasol-odbc && \
  cp /tmp/EXASOL/EXASolution_ODBC-7.1.19/lib/linux/x86_64/libexaodbc-uo2214lv2.so /opt/lib/exasol-odbc && \
  rm -rf /tmp/EXASOL /tmp/EXASOL_ODBC-7.1.19.tar.gz

RUN cp /build/dbms_exporter/odbcinst.ini /etc/odbcinst.ini && \
  odbcinst -i -d -f /etc/odbcinst.ini

RUN make DRIVERS="$drivers" LDFLAGS="$ldflags"

FROM --platform=linux/amd64 debian:stable-slim
RUN apt-get update && \
  apt-get -y install libodbc1 odbcinst libsybdb5 tdsodbc openssl && \
  apt-get clean && \
  rm -rf /var/cache/apt/

COPY --from=build /usr/local/etc/freetds.conf /usr/local/etc/freetds.conf
COPY --from=build /opt/lib/exasol-odbc/libexaodbc-uo2214lv2.so /opt/lib/exasol-odbc/libexaodbc-uo2214lv2.so
COPY --from=build /build/dbms_exporter /
ADD ./files/odbcinst.ini /etc/odbcinst.ini

EXPOSE 9113
ENTRYPOINT [ "/dbms_exporter" ]
