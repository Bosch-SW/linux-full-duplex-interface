# The docker file describes the docker image with
# Linux Full Duplex Interface built and deployed

FROM bosch-linux-ext-modules-build:latest AS bosch-linux-full-duplex-interface

ENV repo_path=/repos/full-duplex-if

RUN rm -rf ${repo_path} && mkdir -p ${repo_path}

WORKDIR ${repo_path}
COPY . .

### BUILD CONFIGURATIONS ###

# installing into a kernel source tree inside the docker
# from there it can be used to build dependent modules
# against the given kernel
# x86
RUN make LINUX_SRC_ROOT="/repos/linux_x86" install-to-src
# ARM
RUN make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- LINUX_SRC_ROOT="/repos/linux_arm" install-to-src

# The header must be there
# x86
RUN ls -al "/repos/linux_x86/include/linux/full_duplex_interface.h"
# ARM
RUN ls -al "/repos/linux_arm/include/linux/full_duplex_interface.h"

#
# TESTING
#
FROM bosch-linux-full-duplex-interface AS bosch-linux-full-duplex-interface-test

# x86
RUN ls -al "/repos/linux_x86/include/linux/full_duplex_interface.h" \
    && echo "fdi-test-driver-x86.header: PASS"

ARG test_mod_repo_path_x86=/repos/bosch-linux-full-duplex-interface-x86
RUN mkdir -p "${test_mod_repo_path_x86}"
COPY ./test/* "${test_mod_repo_path_x86}"
RUN make -C /repos/linux_x86 M=${test_mod_repo_path_x86}               \
    && mkdir -p ${INITRAMFS_CHROOT_X86}/modules                        \
    && cp ${test_mod_repo_path_x86}/fdi-test-driver.ko             \
              ${INITRAMFS_CHROOT_X86}/modules/

# ARM
RUN ls -al "/repos/linux_arm/include/linux/full_duplex_interface.h" \
    && echo "fdi-test-driver-arm.header: PASS"

ARG test_mod_repo_path_arm=/repos/bosch-linux-full-duplex-interface-arm
RUN mkdir -p "${test_mod_repo_path_arm}"
COPY ./test/* "${test_mod_repo_path_arm}"
RUN make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -C /repos/linux_arm M=${test_mod_repo_path_arm}  \
    && mkdir -p ${INITRAMFS_CHROOT_ARM}/modules                                                    \
    && cp ${test_mod_repo_path_arm}/fdi-test-driver.ko                                              \
              ${INITRAMFS_CHROOT_ARM}/modules/

# Shell test
RUN mkdir -p /builds/shell-test
COPY /dockerfile_scripts/test-module-full-duplex.sh /builds/shell-test/

RUN shell-to-initramfs-x86 /builds/shell-test/test-module-full-duplex.sh
RUN shell-to-initramfs-arm /builds/shell-test/test-module-full-duplex.sh

#
# Run the tests themselves
#
ARG TEST_NAME="fdi-test-driver"

# x86
RUN run-qemu-tests-x86

RUN make LINUX_SRC_ROOT="/repos/linux_x86" uninstall-from-src

RUN grep "${TEST_NAME}.insmod: PASS" /qemu_run_x86.log
RUN grep "${TEST_NAME}.rmmod: PASS" /qemu_run_x86.log
RUN grep "${TEST_NAME}.data-exchange: PASS" /qemu_run_x86.log

# ARM
RUN run-qemu-tests-arm /builds/linux_arm/device_tree/versatile-pb.dtb

RUN make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- LINUX_SRC_ROOT="/repos/linux_arm" uninstall-from-src

RUN grep "${TEST_NAME}.insmod: PASS" /qemu_run_arm.log
RUN grep "${TEST_NAME}.rmmod: PASS" /qemu_run_arm.log
RUN grep "${TEST_NAME}.data-exchange: PASS" /qemu_run_arm.log