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

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

SETUP_MAKEFILES_ARGS=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

if [ -z "${DEVICE_PARENT}" ]; then
    DEVICE_PARENT="."
fi

function patchelf_add_needed() {
    local LOCAL_PATCHELF="${PATCHELF}"
    [ -x "${3}" ] && LOCAL_PATCHELF="${3}"
    if ! "${LOCAL_PATCHELF}" --print-needed "${2}" | grep -q "${1}"; then
        "${LOCAL_PATCHELF}" --add-needed "${1}" "${2}"
    fi
}

function blob_fixup() {
    # Camera
    if [[ "${1}" =~ ^odm/overlayfs/.*/lib/libmmcamera.*\.so$ ]]; then
        sed -i 's|data/misc/camera|data/vendor/qcam|g;s|libgui.so|libwui.so|g' "${2}"
    fi

    case "${1}" in
        # Camera
        odm/overlayfs/*/bin/mm-qcamera-daemon)
            sed -i 's|data/misc/camera|data/vendor/qcam|g' "${2}"
            if [ "${1}" == "odm/overlayfs/land/bin/mm-qcamera-daemon" ]; then
                patchelf_add_needed "libshim_mutexdestroy.so" "${2}"
                patchelf_add_needed "libshim_pthreadts.so" "${2}"
            fi
            ;;
        odm/overlayfs/*/lib/libmmcamera_ppeiscore.so)
            patchelf_add_needed "libshims_ui.so"
            ;;
        odm/overlayfs/*/lib/libmmcamera2_sensor_modules.so)
            sed -i 's|/system/etc/camera/|////odm/etc/camera/|g' "${2}"
            sed -i 's|/system/vendor/lib|////vendor/odm/lib|g' "${2}"
            ;;
        odm/overlayfs/*/lib/libmmcamera2_stats_modules.so)
            "${PATCHELF}" --replace-needed "libandroid.so" "libshims_android.so" "${2}"
            ;;
        odm/overlayfs/*/lib/libmmsw_platform.so|odm/overlayfs/*/lib/libmmsw_detail_enhancement.so)
            "${PATCHELF}" --remove-needed "libbinder.so" "${2}"
            sed -i 's|libgui.so|libwui.so|g' "${2}"
            ;;
        odm/overlayfs/*/lib/libmpbase.so)
            "${PATCHELF}" --replace-needed "libandroid.so" "libshims_android.so" "${2}"
            ;;
        # Fingerprint (Legacy Goodix)
        odm/overlayfs/*/bin/gx_fpcmd|odm/overlayfs/*/bin/gx_fpd)
            "${PATCHELF_0_17_2}" --remove-needed "libbacktrace.so" "${2}"
            "${PATCHELF_0_17_2}" --remove-needed "libunwind.so" "${2}"
            patchelf_add_needed "libfakelogprint.so" "${2}" "${PATCHELF_0_17_2}"
            ;;
        odm/overlayfs/*/lib64/libfpservice.so)
            patchelf_add_needed "libbinder_shim.so" "${2}" "${PATCHELF_0_17_2}"
            ;;
        odm/overlayfs/*/lib64/hw/fingerprint.*_goodix.so)
            sed -i 's|libandroid_runtime.so|libshims_android.so\x00\x00|g' "${2}"
            patchelf_add_needed "libfakelogprint.so" "${2}" "${PATCHELF_0_17_2}"
            ;;
        odm/overlayfs/*/lib64/hw/gxfingerprint.*.so)
            patchelf_add_needed "libfakelogprint.so" "${2}" "${PATCHELF_0_17_2}"
            ;;
        # Fingerprint (ugg)
        odm/lib64/lib_fpc_tac_shared.so)
            patchelf_add_needed "libbinder_shim.so" "${2}" "${PATCHELF_0_17_2}"
            ;;
        odm/lib64/libgf_ca.so)
            sed -i 's|/system/etc/firmware|////odm/firmware/ugg|g' "${2}"
            ;;
        odm/lib64/libvendor.goodix.hardware.fingerprint@1.0.so)
            "${PATCHELF_0_17_2}" --replace-needed "libhidlbase.so" "libhidlbase-v32.so" "${2}"
            ;;
        odm/lib64/libvendor.goodix.hardware.fingerprint@1.0-service.so)
            "${PATCHELF_0_17_2}" --remove-needed "libprotobuf-cpp-lite.so" "${2}"
            ;;
    esac

    case "${1}" in
        product/etc/permissions/vendor.qti.hardware.data.connection-V1.0-java.xml \
        | product/etc/permissions/vendor.qti.hardware.data.connection-V1.1-java.xml)
            sed -i 's|version="2.0"|version="1.0"|g' "${2}"
            ;;
        system_ext/lib64/lib-imscamera.so)
            for LIBSHIM_IMSVIDEOCODEC in $(grep -L "libshim_imscamera.so" "${2}"); do
                "${PATCHELF}" --add-needed "libshim_imscamera.so" "${2}"
            done
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
extract "${MY_DIR}/proprietary-files-camera.txt" "${SRC}" "${KANG}" --section "${SECTION}"
extract "${MY_DIR}/proprietary-files-device.txt" "${SRC}" "${KANG}" --section "${SECTION}"
extract "${MY_DIR}/proprietary-files-qc-sys.txt" "${SRC}" "${KANG}" --section "${SECTION}"
extract "${MY_DIR}/proprietary-files-qc-vndr.txt" "${SRC}" "${KANG}" --section "${SECTION}"
extract "${MY_DIR}/proprietary-files-qc-vndr-32.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh" ${SETUP_MAKEFILES_ARGS}
