# The builds should work like following:
#
# * The direct build and install
#   * build against the `uname -r` kernel headers on host
#   * install to the host
#
# * The docker-test
#   * run the image against the predefined kernel headers
#     by default, but with option to choose specific version
#
# * The docker-image
#   * make the image for the predefined kernel headers
#     by default, but with option to choose specific version


# To make the build reproducible, we fix the kernel headers
# version, but leave opportunity to update it (KVER ?= `uname -r`).
KVER_TEST ?= 5.4.0-97-generic
KVER_NATIVE ?= `uname -r`

KDIR_TEST ?= /lib/modules/${KVER_TEST}/build
KDIR_NATIVE ?= /lib/modules/${KVER_NATIVE}/build

DOCKER_OUT_IMAGE_TAGE = bosch-linux-full-duplex-interface

# Build on current machine with given (current kernel by default) kernel
default:
	@echo "Making against the ${KVER_NATIVE} kernel"
	$(MAKE) -C ${KDIR_NATIVE} M=$$PWD

# Install to current machine
install:
	@echo "Installing headers to: " 							\
		"/usr/src/linux-headers-${KVER_NATIVE}/include/linux/"
	cp  $$PWD/include/linux/full_duplex_interface.h 			\
		/usr/src/linux-headers-${KVER_NATIVE}/include/linux/

# Try to remove the installed driver from current machine
uninstall:
	rm /usr/src/linux-headers-${KVER_NATIVE}/include/linux/full_duplex_interface.h

# Build Docker deployed image (Docker image with built and installed
# Linux Full Duplex Interface) on the basis of linux-full-duplex-interface
docker-image:
	./docker_wrapper.sh --kernel-version=${KVER_TEST}           \
		                --docker-file=./Dockerfile.docker-image \
					    --docker-out-image-tag=${DOCKER_OUT_IMAGE_TAGE} \
		.

# Test ourselves in Docker environment (similar to docker-image, but
# usually builds various build configurations and if all fine, just removes
# the build artifacts)
test:
	./docker_wrapper.sh --kernel-version=${KVER_TEST}           \
		.

# combines both: `test` and `docker-image` target
base: docker-image test
	@echo "base: \033[0;32mOK\033[0m"
