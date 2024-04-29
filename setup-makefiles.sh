#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=Mi8937
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

if [ -z "${DEVICE_PARENT}" ]; then
    DEVICE_PARENT="."
fi

# Initialize the helper
setup_vendor "${DEVICE=}" "${VENDOR}" "${ANDROID_ROOT}"

# Warning headers and guards
write_headers

# The standard device blobs
write_makefiles "${MY_DIR}/proprietary-files.txt" true
write_makefiles "${MY_DIR}/proprietary-files-camera.txt" true
write_makefiles "${MY_DIR}/proprietary-files-device.txt" true
write_makefiles "${MY_DIR}/proprietary-files-qc-sys.txt" true
write_makefiles "${MY_DIR}/proprietary-files-qc-vndr.txt" true
write_makefiles "${MY_DIR}/proprietary-files-qc-vndr-32.txt" true

# Finish
write_footers
