#!/bin/bash

# Print debugging information
printf "TSM certificate shim start\nPassed %s args: %s\n" "$#" "$*"

# Extract the TCP server and TCP port from the DSM config file
# we do this by searching (grep) for the correct fields, then extracting by
# trimming multiple whitspace characters into 1, then pulling out the last
# "field" (e.g. space-separated list) with cut.
# after the `tr` command, we have a string like " tcpserveraddress something.com"
# This is similar to Python's result.split(' ')[2]
SERVER=$(grep -i "tcpserveraddress" /opt/tivoli/tsm/client/ba/bin/dsm.sys | tr -s ' ' | cut -d ' ' -f 3)
PORT=$(grep -i "tcpport" /opt/tivoli/tsm/client/ba/bin/dsm.sys | tr -s ' ' | cut -d ' ' -f 3)

# use openssl to actually download the certificate and process it into a PEM file
openssl s_client -connect "$SERVER:$PORT" -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM > /tmp/server_cert.pem

# Check certificate hashes to prevent man-in-the-middle attacks
DOWNLOADED_HASH=$(sha256sum /tmp/server_cert.pem | cut -d ' ' -f 1)
if [[ ! -v SERVER_CERT_SHA256_HASH ]]; then
    printf "No certificate hash provided as environment variable SERVER_CERT_SHA256_HASH\n"
    printf "This is unsafe! If you want to trust this server certificate, add this hash\n"
    printf "into this container's environment:\n"
    printf "%s\n" "$DOWNLOADED_HASH"
    exit 1
fi

if ! printf "%s /tmp/server_cert.pem\n" "$SERVER_CERT_SHA256_HASH" | sha256sum --check --status; then
    printf "Certificate hash failed! The downloaded server certificate has hash:\n"
    printf "%s\n" "$DOWNLOADED_HASH"
    printf "but this does not match the provided one:"
    printf "%s\n" "$CERT_SHA256_HASH"
    printf "Update the container environment variable SERVER_CERT_SHA256_HASH\n"
    printf "if you know that the certificate changed!\n"
    exit 1
fi

# Install the certificate
printf "Certificate validated! Installing certificate for %s\n" "$SERVER"
dsmcert -add -server "$SERVER" -file /tmp/server_cert.pem

# If we aren't given arguments, run the default (dsmc scheduler)
if [[ $# -eq 0 ]]; then
    printf "Certificate shim done. Starting backup by exec'ing default (/usr/bin/dsmc schedule)\n"
    exec /usr/bin/dsmc schedule
else
    # otherwise call whatever program the user requested (in the COMMAND arg)
    printf "Certificate shim done. Starting backup by exec'ing passed args: %s\n" "$*"
    exec "$@"
fi
