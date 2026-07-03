#!/bin/sh
set -eu
BASE=/srv
APP="${1:?usage: deploy.sh <app>}"
git -C "$BASE/$APP" pull
docker compose \
	-f "$BASE/$APP/compose.yaml" \
	-f "$BASE/qxyz.me/deploy/apps/$APP.yaml" \
	up -d --build
