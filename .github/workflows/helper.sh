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

    COMMON_FLAGS=(
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION:BOOL=ON
        -DMUJOCO_BUILD_EXAMPLES:BOOL=OFF
        -DCMAKE_INSTALL_RPATH:STRING="@loader_path"
        -DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=ON
    )

    if [[ "$RUNNER_OS" == "Windows" ]]; then
        cmake .. \
            -GNinja \
            -DCMAKE_C_COMPILER:STRING=clang \
            -DCMAKE_CXX_COMPILER:STRING=clang++ \
            "${COMMON_FLAGS[@]}"
    else
        cmake .. "${COMMON_FLAGS[@]}"
    fi
}

build_mujoco() {
    cd build && 
    cmake --build . --config=Release &&
    cmake --install . --config=Release
}

build_wheel_and_sdist() {
    export MUJOCO_LIBRARY_DIR="${GITHUB_WORKSPACE}/install/lib"
    export MUJOCO_INCLUDE_DIR="${GITHUB_WORKSPACE}/install/include"

    if [[ "$RUNNER_OS" == "Windows" ]]; then
        export MUJOCO_LIBRARY_DIR="${GITHUB_WORKSPACE}/install/bin"
    fi

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