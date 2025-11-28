#!/bin/bash

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
if [[ ! -v CERT_SHA256_HASH ]]; then 
       printf "No certificate hash provided as environment variable CERT_SHA256_HASH\n"
          printf "This is unsafe! If you want to trust this certificate, add this hash\n"
             printf "into this container's environment:"
                printf "%s\n" "$DOWNLOADED_HASH"
                   exit 1
fi

if ! echo "$CERT_SHA256_HASH  /tmp/server_cert.pem" | sha1sum --check --status; then
       printf "Certificate hash failed! The downloaded certificate has hash:\n"
          printf "%s\n" "$DOWNLOADED_HASH"
             printf "but this does not match the provided one. Update the container environment\n"
                printf "variable CERT_SHA256_HASH if you know that the certificate changed!"
                   exit 1
fi

# Install the certificate
dsmcert -add -server "$SERVER" -file /tmp/server_cert.pem

# If we aren't given arguments, run the default (dsmc scheduler)
if [[ $# -eq 1 ]]; then
        exec /bin/bash/dsmc schedule
    else
        # otherwise call whatever program the user requested (in the COMMAND arg)
            exec "$@"
fi
