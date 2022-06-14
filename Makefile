KVER ?= `uname -r`
KDIR ?= /lib/modules/${KVER}/build

# Build on current machine with given (current kernel by default) kernel
default:
	$(MAKE) -C $(KDIR) M=$$PWD

# Install to current machine
install:
	cp  $$PWD/include/linux/full_duplex_interface.h /usr/src/linux-headers-${KVER}/include/linux/

# Try to remove the installed driver from current machine
uninstall:
	rm /usr/src/linux-headers-${KVER}/include/linux/full_duplex_interface.h

# Build Docker deployed image (Docker image with built and installed
# Linux Full Duplex Interface) on the basis of linux-full-duplex-interface
docker-image:
	cd $$PWD && sudo -u `whoami` docker build -t linux-full-duplex-interface \
		-f ./Dockerfile.docker-image .

# Test ourselves in Docker environment (similar to docker-image, but
# usually builds various build configurations and if all fine, just removes
# the build artifacts)
test:
	cd $$PWD && sudo -u `whoami` docker build -t linux-full-duplex-interface \
		.
