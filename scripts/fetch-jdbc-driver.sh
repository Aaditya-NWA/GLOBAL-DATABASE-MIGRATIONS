#!/usr/bin/env sh
# Downloads the PostgreSQL JDBC driver that Liquibase needs.
#
#   sh scripts/fetch-jdbc-driver.sh
#
# Liquibase 5.x no longer bundles database drivers. The jar lives in drivers/
# (gitignored) and is passed with --classpath. See README.md.

set -eu

VERSION="${1:-42.7.9}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$ROOT/drivers"
DEST="$DEST_DIR/postgresql-$VERSION.jar"

mkdir -p "$DEST_DIR"

if [ -f "$DEST" ]; then
    echo "Already present: $DEST"
    exit 0
fi

URL="https://repo1.maven.org/maven2/org/postgresql/postgresql/$VERSION/postgresql-$VERSION.jar"
echo "Downloading $URL"
curl -fsSL "$URL" -o "$DEST"
echo "Saved to $DEST"
