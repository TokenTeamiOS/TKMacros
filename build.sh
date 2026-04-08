#!/bin/sh

# build.sh
# Builds the Swift Macro executable for CocoaPods distribution.
# Usage: ./build.sh

set -e

# Resolve script directory and cd into it
cd "$(dirname "$0")"

MACRO_NAME="TKMacrosExecutable"
OUTPUT_DIR="./Prebuilt"
BUILD_CONFIG="release"
mkdir -p "${OUTPUT_DIR}"

echo "Building ${MACRO_NAME}..."

# Build the macro executable with size optimization
swift build -c "${BUILD_CONFIG}" -Xswiftc -Osize

# Locate the binary in the build directory (usually .build/<config> or .build/<arch>/<config>)
BIN_PATH_ROOT=$(swift build -c "${BUILD_CONFIG}" --show-bin-path)

# Find the executable.
# SwiftPM might name it with a '-tool' suffix for macros
# Exclude .dSYM directories to avoid picking up the symbol file
FOUND_BINARY=$(find "${BIN_PATH_ROOT}" -name "${MACRO_NAME}" -type f -not -path "*.dSYM*" | head -n 1)
if [ -z "${FOUND_BINARY}" ]; then
    FOUND_BINARY=$(find "${BIN_PATH_ROOT}" -name "${MACRO_NAME}-tool" -type f -not -path "*.dSYM*" | head -n 1)
fi

if [ -n "${FOUND_BINARY}" ]; then
    echo "Found binary at ${FOUND_BINARY}"
    echo "Copying binary to ${OUTPUT_DIR}/${MACRO_NAME}..."
    cp "${FOUND_BINARY}" "${OUTPUT_DIR}/${MACRO_NAME}"
    chmod u+x "${OUTPUT_DIR}/${MACRO_NAME}"
    
    # Strip symbols to reduce binary size significantly
    echo "Stripping symbols..."
    strip -x "${OUTPUT_DIR}/${MACRO_NAME}"
    echo "Success! Macro executable is at ${OUTPUT_DIR}/${MACRO_NAME}"
else
    echo "Error: Macro executable not found in ${BIN_PATH_ROOT}"
    # Listing only the root to avoid massive output
    ls -F "${BIN_PATH_ROOT}"
    exit 1
fi
