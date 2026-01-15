#!/bin/bash
set -e

# ZMK local build script using Docker
# Usage: ./build.sh [left|right|both]

SIDE="${1:-both}"
ZMK_IMAGE="zmkfirmware/zmk-dev-arm:stable"
CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"

build_side() {
    local side=$1
    local studio_flag=""
    if [ "$side" = "left" ]; then
        studio_flag="-DCONFIG_ZMK_STUDIO=y"
    fi

    echo "Building corne_choc_pro_${side}..."

    docker run --rm \
        -v "${CONFIG_DIR}:/zmk-config" \
        -v zmk-root:/workspace \
        -w /workspace \
        ${ZMK_IMAGE} \
        /bin/bash -c "
            set -e
            if [ ! -d zmk/.west ]; then
                echo 'Cloning ZMK...'
                git clone --depth 1 https://github.com/zmkfirmware/zmk.git
                cd zmk
                west init -l app
                west update --narrow
            else
                cd zmk
            fi
            west build -p -d build/${side} -b corne_choc_pro_${side} app \
                -S studio-rpc-usb-uart \
                -- \
                -DZMK_CONFIG=/zmk-config/config \
                -DSHIELD=nice_view \
                -DZMK_EXTRA_MODULES=/zmk-config \
                ${studio_flag}
            cp build/${side}/zephyr/zmk.uf2 /zmk-config/corne_choc_pro_${side}.uf2
        "

    echo "Built: corne_choc_pro_${side}.uf2"
}

case "$SIDE" in
    left)
        build_side "left"
        ;;
    right)
        build_side "right"
        ;;
    both)
        build_side "left"
        build_side "right"
        ;;
    *)
        echo "Usage: $0 [left|right|both]"
        exit 1
        ;;
esac

echo "Done! Firmware files are in the current directory."
