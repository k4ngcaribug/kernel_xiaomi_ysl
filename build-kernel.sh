#!/bin/bash
#
# Copyright (C) 2020 azrim.
# All rights reserved.

# Init
KERNEL_DIR="${PWD}"
KERN_IMG="${KERNEL_DIR}"/out/arch/arm64/boot/Image.gz-dtb
ANYKERNEL=/workspace/Anykernel3
COMPILER_STRING="Aosp Clang"

# Repo URL
CLANG_REPO="https://github.com/alprjkt/aosp-clang"
ANYKERNEL_REPO="https://github.com/alprjkt/Anykernel3"
ANYKERNEL_BRANCH="ysl"

# Compiler
CLANG_DIR=/workspace/clang
#if ! [ -d "${CLANG_DIR}" ]; then
       git clone "$CLANG_REPO" --depth=1 "$CLANG_DIR"
#fi

# git clone https://github.com/baalajimaestro/aarch64-maestro-linux-android.git -b 07032020-9.2.1 --depth=1 "${KERNEL_DIR}/gcc"
# git clone https://github.com/baalajimaestro/arm-maestro-linux-gnueabi.git -b 07032020-9.2.1 --depth=1 "${KERNEL_DIR}/gcc32"

# Defconfig7
DEFCONFIG="ysl_defconfig"
REGENERATE_DEFCONFIG="false" # unset if don't want to regenerate defconfig

# Costumize
KERNEL="Shinigami-Kernel"
DEVICE="ysl"
KERNELTYPE="caf"
KERNELNAME="${KERNEL}-${DEVICE}-${KERNELTYPE}-$(TZ=Asia/Jakarta date +%y%m%d-%H%M)"
TEMPZIPNAME="${KERNELNAME}.zip"
ZIPNAME="${KERNELNAME}.zip"

# Telegram
CHATIDQ="-1002001516627"
CHATID="-1002001516627"
TELEGRAM_TOKEN="6661722181:AAHA86zdVQTkkAU7FQowuZa1RJk7tCBQCmY"

# Export Telegram.sh
TELEGRAM_FOLDER=/workspace/telegram
if ! [ -d "${TELEGRAM_FOLDER}" ]; then
    git clone https://github.com/ontheway69/telegram.sh/ "${TELEGRAM_FOLDER}"
fi

TELEGRAM="${TELEGRAM_FOLDER}"/telegram

tg_cast() {
    "${TELEGRAM}" -t "${TELEGRAM_TOKEN}" -c "${CHATID}" -H \
    "$(
        for POST in "${@}"; do
            echo "${POST}"
        done
    )"
}

# Regenerating Defconfig
regenerate() {
    cp out/.config arch/arm64/configs/"${DEFCONFIG}"
    git add arch/arm64/configs/"${DEFCONFIG}"
    git commit -m "defconfig: Regenerate"
}

# Building
makekernel() {
    echo ".........................."
    echo ".     Building Kernel    ."
    echo ".........................."
    export PATH="/workspace/clang/bin:$PATH"
#    export CROSS_COMPILE=${KERNEL_DIR}/gcc/bin/aarch64-maestro-linux-gnu-
#    export CROSS_COMPILE_ARM32=${KERNEL_DIR}/gcc32/bin/arm-maestro-linux-gnueabi-
    rm -rf "${KERNEL_DIR}"/out/arch/arm64/boot # clean previous compilation
    mkdir -p out
    make O=out ARCH=arm64 ${DEFCONFIG}
    if [[ "${REGENERATE_DEFCONFIG}" =~ "true" ]]; then
        regenerate
    fi
    make -j$(nproc --all) CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- O=out ARCH=arm64

# Check If compilation is success
    if ! [ -f "${KERN_IMG}" ]; then
        END=$(TZ=Asia/Jakarta date +"%s")
        DIFF=$(( END - START ))
        echo -e "Kernel compilation failed, See buildlog to fix errors"
        tg_cast "Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check Instance for errors"
        exit 1
    fi
}

# Packing kranul
packingkernel() {
    echo "........................"
    echo ".    Packing Kernel    ."
    echo "........................"
    # Copy compiled kernel
    if [ -d "${ANYKERNEL}" ]; then
        rm -rf "${ANYKERNEL}"
    fi
    git clone "$ANYKERNEL_REPO" -b "$ANYKERNEL_BRANCH" "${ANYKERNEL}"
     #   mkdir "${ANYKERNEL}"/kernel/
        cp "${KERN_IMG}" "${ANYKERNEL}"/Image.gz-dtb
   #     mkdir "${ANYKERNEL}"/dtb-nontreble/
  #      cp "${KERN_DTB_NONTB}" "${ANYKERNEL}"/dtb-nontreble/msm8953-qrd-sku3-tissot-nontreble.dtb
  #  mkdir "${ANYKERNEL}"/dtb-treble/
   #     cp "${KERN_DTB_NONTB}" "${ANYKERNEL}"/dtb-treble/msm8953-qrd-sku3-tissot-nontreble.dtb

    # Zip the kernel, or fail
    cd "${ANYKERNEL}" || exit
    zip -r9 "${TEMPZIPNAME}" ./*

    # Sign the zip before sending it to Telegram
   # curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/baalajimaestro/AnyKernel2/master/zipsigner-3.0.jar
   # java -jar zipsigner-3.0.jar "${TEMPZIPNAME}" "${ZIPNAME}"

    # Ship it to the CI channel
    "${TELEGRAM}" -f "$ZIPNAME" -t "${TELEGRAM_TOKEN}" -c "${CHATIDQ}" 
}

# Starting
tg_cast "<b>STARTING KERNEL BUILD</b>" \
    "Device: ${DEVICE}" \
    "Kernel Name: ${KERNEL}" \
    "Build Type: ${KERNELTYPE}"
START=$(TZ=Asia/Jakarta date +"%s")
makekernel
packingkernel
END=$(TZ=Asia/Jakarta date +"%s")
DIFF=$(( END - START ))
tg_cast "Build for ${DEVICE} with ${COMPILER_STRING} <b>succeed</b> took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! "

    echo "........................"
    echo ".    Build Finished    ."
    echo "........................"
