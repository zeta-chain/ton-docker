#!/bin/bash

set -eo pipefail

jar_version="v120"
arch=$(uname -m)
case $arch in
    x86_64)
        arch_suffix="x86-64"
        ;;
    aarch64|arm64)
        arch_suffix="arm64"
        ;;
    *)
        echo "Unsupported architecture: $arch"
        exit 1
        ;;
esac
jar_url="https://github.com/neodix42/MyLocalTon/releases/download/${jar_version}/MyLocalTon-${arch_suffix}.jar"

echo "URL: $jar_url"
curl -L -o "my-local-ton.jar" "$jar_url"
