#!/usr/bin/env bash
# 用飞牛官方 fnpack 打包电销CRM 应用（x86 / all / arm 三个平台）
#
# 用法： ./build.sh
# 产物： ../build/telecrm_1.0.0_{x86,all,arm}.fpk
set -e

FNVER="1.2.3"
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/../source_telecrm"
BUILD="$HERE/../build"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
  x86_64|amd64) FNARCH="amd64" ;;
  aarch64|arm64) FNARCH="arm64" ;;
  *) echo "不支持的架构: $ARCH"; exit 1 ;;
esac
case "$OS" in
  linux|darwin) ;;
  *) echo "请用 Linux / macOS，或在 WSL 中执行（Windows 版请手动下载 fnpack）"; exit 1 ;;
esac

# 1. 下载官方 fnpack
FNPACK="$HERE/fnpack"
if [ ! -x "$FNPACK" ]; then
  URL="https://static2.fnnas.com/fnpack/fnpack-${FNVER}-${OS}-${FNARCH}"
  echo "下载 fnpack ${FNVER} (${OS}-${FNARCH}) ..."
  curl -fL --progress-bar -o "$FNPACK" "$URL"
  chmod +x "$FNPACK"
fi
"$FNPACK" --version 2>/dev/null | head -1 || true

rm -rf "$BUILD"
mkdir -p "$BUILD"

# 2. 逐平台打包（fnpack 要求应用目录名 == appname）
for P in x86 all arm; do
  D="$BUILD/pkg-$P"
  mkdir -p "$D"
  cp -r "$SRC" "$D/telecrm"
  sed -i.bak "s/^platform.*/platform              = $P/" "$D/telecrm/manifest"
  rm -f "$D/telecrm/manifest.bak"
  if [ "$P" = "arm" ]; then
    # ARM 机型使用 arm64 镜像
    if grep -q "jiankujidu/telecrm:1.0.0-arm64" "$D/telecrm/app/docker/docker-compose.yaml"; then
      :
    else
      sed -i.bak "s|jiankujidu/telecrm:1.0.0|jiankujidu/telecrm:1.0.0-arm64|" "$D/telecrm/app/docker/docker-compose.yaml"
      rm -f "$D/telecrm/app/docker/docker-compose.yaml.bak"
    fi
  fi
  echo "--- 打包 $P ---"
  (cd "$D/telecrm" && "$FNPACK" build)
  mv "$D/telecrm/telecrm.fpk" "$BUILD/telecrm_1.0.0_$P.fpk"
  rm -rf "$D"
done

echo
echo "产物："
ls -lh "$BUILD"/*.fpk
