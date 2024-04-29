LOCAL_PATH := $(call my-dir)

# ------------------------------------------------------------------------------
#                Make the shared library (libqomx_core)
# ------------------------------------------------------------------------------

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional

LOCAL_CFLAGS := -Werror \
                   -g -O0

ifeq ($(MI8937_CAM_USE_RENAMED_BLOBS_L),true)
LOCAL_CFLAGS += -DRENAME_BLOBS
endif

LOCAL_C_INCLUDES := frameworks/native/include/media/openmax \
                    $(LOCAL_PATH)/../qexif

LOCAL_INC_FILES := qomx_core.h \
                   QOMX_JpegExtensions.h

LOCAL_SRC_FILES := qomx_core.c

LOCAL_MODULE           := libLomx_core
LOCAL_ODM_MODULE := true
LOCAL_SHARED_LIBRARIES := libcutils libdl liblog libutils

LOCAL_32_BIT_ONLY := true
include $(BUILD_SHARED_LIBRARY)
