FROM alpine:3.11
RUN apk add --no-cache \
        bash=5.0.11-r1\
        curl=7.67.0-r0
COPY supload.sh /usr/bin/
CMD ["/usr/bin/supload.sh"] 
