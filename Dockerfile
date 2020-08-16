FROM nodered/node-red

ARG RUN_PACKAGES=lirc

USER root

# Update index, install RUN_PACKAGES
RUN apk update && \
    apk add $RUN_PACKAGES && \
# Clean up
    rm -rf /var/cache/apk/*

USER node-red
