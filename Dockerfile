FROM scratch

MAINTAINER Havard Bakke <havard.bakke@pexip.com>

ADD build/lazy-chat /usr/bin/lazy-chat

COPY web /web

USER 1000:1000

EXPOSE 8080

ENTRYPOINT ["/usr/bin/lazy-chat"]
