# syntax=docker/dockerfile:1.3-labs

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
# avainst the given kernel
RUN make LINUX_SRC_ROOT="/repos/linux" install-to-src

# The header must be there
RUN ls -al "/repos/linux/include/linux/full_duplex_interface.h"

#
# TESTING
#
FROM bosch-linux-full-duplex-interface AS bosch-linux-full-duplex-interface-test

RUN ls -al "/repos/linux/include/linux/full_duplex_interface.h" \
    && echo "fdi-test-driver.header: PASS"

RUN <<EOF
set -e

make -C /repos/linux M=${repo_path}/test                          \
    && mkdir -p "/builds/initramfs/content/modules"               \
    && cp ${repo_path}/test/fdi-test-driver.ko                    \
          "/builds/initramfs/content/modules/"
EOF

# Shell test
RUN mkdir -p /builds/full-duplex-interface/test
COPY <<-"EOT" /builds/full-duplex-interface/test/shell_test.sh
#!/bin/sh
set -e

insmod /modules/fdi-test-driver.ko
sleep 1
rmmod fdi-test-driver

dmesg

EOT
RUN shell-to-initramfs /builds/full-duplex-interface/test/shell_test.sh

RUN run-qemu-tests

RUN make LINUX_SRC_ROOT="/repos/linux" uninstall-from-src

RUN grep "fdi-test-driver.insmod: PASS" /qemu_run.log
RUN grep "fdi-test-driver.rmmod: PASS" /qemu_run.log
RUN grep "fdi-test-driver.data-exchange: PASS" /qemu_run.log
