#!/bin/sh
set -e
API_URL=${REACT_APP_API_URL:-http://localhost:4000}
sed "s|%REACT_APP_API_URL%|$API_URL|g" ./build/config.js > ./build/config.js.tmp && mv ./build/config.js.tmp ./build/config.js
exec "$@" 