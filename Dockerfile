FROM docker:24

RUN apk add bash git

COPY depots.txt initial.sh run.sh /

ENTRYPOINT ["/bin/bash", "/initial.sh"]