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


# Defines the kernel version to work with directly (not-in-docker
# build), normally this defaults to the host system kernel name.
KVER ?= `uname -r`
# Defines the kernel version to be used inside the docker
# environment - this is fixed to predefined by default,
# to keep the build reproducible.
KVER_DOCKER ?= 5.4.0-97-generic
# The default linux sources folder (fits only to Docker env
# of the linux-ext-modules-build-base image). To use it effectively
# set this variable explicitly.
LINUX_SRC_ROOT ?= "/repos/linux"

# NOTE: don't change this unless you're sure what you're doing
# 	cause by this tag the dependent components refer to the current
# 	component
DOCKER_OUT_IMAGE_TAG ?= bosch-linux-full-duplex-interface
DOCKER_OUT_TEST_IMAGE_TAG ?= bosch-linux-full-duplex-interface-test

# To track the sources root dir
SRC_ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: test docker-image

# Build on current machine with given (current kernel by default) kernel
default:
	@echo "Making against the ${KVER} kernel"
	$(MAKE) -C /lib/modules/${KVER}/build M=$$PWD

# Install to current machine
install:
	@echo "Installing headers to: " 							        \
		"/usr/src/linux-headers-${KVER}/include/linux/"
	cp -v ${SRC_ROOT_DIR}/include/linux/full_duplex_interface.h 			\
		/usr/src/linux-headers-${KVER}/include/linux/

# Install to the Linux kernel sources directly
install-to-src:
	@echo "Installing headers to: ${LINUX_SRC_ROOT}/include/linux"
	cp -v ${SRC_ROOT_DIR}/include/linux/full_duplex_interface.h 			\
		${LINUX_SRC_ROOT}/include/linux/

# Try to remove the installed driver from current machine
uninstall:
	@echo "Removing installed headers from: " 							\
		"/usr/src/linux-headers-${KVER}/include/linux/"
	rm /usr/src/linux-headers-${KVER}/include/linux/full_duplex_interface.h

# Removing installed files from the source tree
uninstall-from-src:
	@echo "Removing installed headers from: ${LINUX_SRC_ROOT}/include/linux"
	rm ${LINUX_SRC_ROOT}/include/linux/full_duplex_interface.h

# Build Docker deployed image (Docker image with built and installed
# Linux Full Duplex Interface) on the basis of linux-full-duplex-interface
docker-image:
	./scripts/docker_build_wrapper.sh       				\
		--tag=${DOCKER_OUT_IMAGE_TAG} 						\
		--target=${DOCKER_OUT_IMAGE_TAG}					\
		--progress=plain                                    \
		.													\
		&& echo "docker-image: \033[0;32mOK\033[0m"

# Test ourselves in Docker environment (similar to docker-image, but
# usually builds various build configurations and if all fine, just removes
# the build artifacts)
test: docker-image
	./scripts/docker_build_wrapper.sh 						\
		--tag=${DOCKER_OUT_TEST_IMAGE_TAG}                  \
		--target=${DOCKER_OUT_TEST_IMAGE_TAG}               \
		--progress=plain                                    \
		. 													\
		&& echo "test: \033[0;32mOK\033[0m"

# combines both: `test` and `docker-image` target
base: docker-image test
	@echo "base: \033[0;32mOK\033[0m"

# Will remove the docker image generated by the build
# and all dangling images as well
clean-docker-images:
	docker rmi ${DOCKER_OUT_IMAGE_TAG} || true
	docker rmi ${DOCKER_OUT_TEST_IMAGE_TAG} || true
	docker image prune
	docker system prune

print-output-docker-image-tag:
	@echo "${DOCKER_OUT_IMAGE_TAG}"
