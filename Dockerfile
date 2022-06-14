# The file describes the testing sequence of the Full Duplex Interface

FROM bosch-linux-ext-modules-build:latest

# NOTE: to purge the Docker unused files use:
#   $ docker system prune -a
# NOTE: to run shell on the image:
#   $ docker run -it YOUR_IMAGE_NAME sh
#   $ sudo -u YOUR_USERNAME docker run -it YOUR_IMAGE_HASH bash
#   FOR EXAMPLE:
#     $ sudo -u `whoami` docker run -it c8c279906c2e bash
# NOTE: to list available images:
#   $ docker images
# NOTE: to run the images:
#   $ docker run -i IMAGE_HASH
# NOTE: to run the docker on prepared system (from src root)
#   $ docker build .
# NOTE: if you have your permissions denied, try (from src root)
#   $ sudo -u `whoami` docker build .

########## Here we go: build and test

ENV repo_path=/repos/full-duplex-if
# And now the ICCom and its build itself using the
# ICCom source which contains our Dockerfile
RUN rm -rf ${repo_path} && mkdir -p ${repo_path}

# add only for the container, not for an image
WORKDIR ${repo_path}
COPY . .

### BUILD CONFIGURATIONS ###

# Base (default) version
ARG kernel_version=5.15.0-25-generic
ARG kernel_source_dir=/lib/modules/${kernel_version}/build

RUN make -C ${kernel_source_dir} M=${repo_path} \
    && make KVER=${kernel_version} install \
    && make KVER=${kernel_version} uninstall \
    && rm -rf ${repo_path}/*
COPY . .

