#!/bin/bash

install_deps_linux() {
    sudo apt-get update && sudo apt-get install -y \
        libgl1-mesa-dev \
        libwayland-dev \
        libxinerama-dev \
        libxcursor-dev \
        libxkbcommon-dev \
        libxrandr-dev \
        libxi-dev \
        ninja-build
}

install_deps_windows() {
    true
}

install_deps_macos() {
    brew install ninja
}

install_deps() {
    if [[ $RUNNER_OS == "Linux" ]]; then
        install_deps_linux
    elif [[ $RUNNER_OS == "Windows" ]]; then
        install_deps_windows
    elif [[ $RUNNER_OS == "macOS" ]]; then
        install_deps_macos
    fi
}

prepare_build() {
    mkdir -p build
    cd build &&
    cmake .. \
        -DCMAKE_BUILD_TYPE:STRING=Release \
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION:BOOL=ON \
        -DMUJOCO_BUILD_EXAMPLES:BOOL=OFF
}

build_mujoco() {
    cd build && cmake --build . --config=Release
}

build_wheel_and_sdist() {
    cd python &&
    uv venv .venv &&
    if [[ "$RUNNER_OS" == "Windows" ]]; then
        source .venv/Scripts/activate
    else
        source .venv/bin/activate
    fi &&
    uv pip install pip &&
    bash make_sdist.sh
}

VALID_FUNCTIONS=()
while IFS= read -r func_name; do
  VALID_FUNCTIONS+=("$func_name")
done < <(grep -E '^[[:alnum:]_]+\(\)' "$0" | sed 's/().*$//')

if [[ ! " ${VALID_FUNCTIONS[*]} " =~ " ${1} " ]]; then
    echo "Usage: $0 {$(IFS='|'; echo "${VALID_FUNCTIONS[*]}")}, got '$1'"
    exit 1
fi

set -xe

"$1"