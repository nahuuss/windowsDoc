#!/usr/bin/env bash
set -Eeuo pipefail

: "${BOOT_MODE:="windows"}"

APP="Windows"
SUPPORT="https://github.com/dockur/windows"

cd /run

# Asegurarse de que el directorio /run/storage existe
mkdir -p /run/storage

# Crear el disco si no existe
DISK_PATH="/run/storage/disk.qcow2"
if [ ! -f "$DISK_PATH" ]; then
    qemu-img create -f qcow2 "$DISK_PATH" 20G
fi

. reset.sh      # Initialize system
. define.sh     # Define versions
. mido.sh       # Download code
. install.sh    # Run installation
. disk.sh       # Initialize disks
. display.sh    # Initialize graphics
. network.sh    # Initialize network
. samba.sh      # Configure samba
. boot.sh       # Configure boot
. proc.sh       # Initialize processor
. power.sh      # Configure shutdown
. config.sh     # Configure arguments

trap - ERR

version=$(qemu-system-x86_64 --version | head -n 1 | cut -d '(' -f 1 | awk '{ print $NF }')
info "Booting ${APP}${BOOT_DESC} using QEMU v$version..."

{ qemu-system-x86_64 ${ARGS:+ $ARGS} >"$QEMU_OUT" 2>"$QEMU_LOG"; rc=$?; } || :
(( rc != 0 )) && error "$(<"$QEMU_LOG")" && exit 15

terminal
( sleep 10; boot ) &
tail -fn +0 "$QEMU_LOG" 2>/dev/null &
cat "$QEMU_TERM" 2> /dev/null | tee "$QEMU_PTY" &
wait $! || :

sleep 1 & wait $!
[ ! -f "$QEMU_END" ] && finish 0
