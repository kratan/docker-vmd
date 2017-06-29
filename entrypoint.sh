#!/bin/bash

set -e
set -x

for f in /entrypoint.d/*.conf ; do
	echo "Loading $f ..."
	. $f
done

exec /usr/local/bin/tini -- "$@"
