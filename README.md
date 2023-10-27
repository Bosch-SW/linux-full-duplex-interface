# What is it?

Full-duplex-interface module is only a definition of the
full-duplex-interface which is provided/implemented, say, by
[SymSPI](https://github.com/Bosch-SW/linux-symspi). It was
extracted to the separate module cause it is semantically
independent from the [SymSPI](https://github.com/Bosch-SW/linux-symspi)
itself and allows to abstract pretty wide range of similar
transports.

This module is to be used to build the
[SymSPI](https://github.com/Bosch-SW/linux-symspi)
itself and also interface it or similar transport layers to
transport client code like [ICCom](https://github.com/Bosch-SW/linux-iccom).

# Dependencies

This component docker chain depends on the
<https://sourcecode.socialcoding.bosch.com/projects/CM_CI2_LINUX/repos/linux-ext-modules-build-base/browse>
so, if you need to build the docker image of this component,
you will need one from `linux-ext-modules-build-base` first.

NOTE: if you need just to install it directly onto your system,
basically you don't need anything.

# How to build it?

To build it against current kernel:
```
$ make
```

To build it in host environment against the specific kernel:
```
$ make KVER=5.15.0-97-generic
```

# How to install it on host

To install it on host for running kernel:
```
$ make install
```

To install it on host for given kernel:
```
$ make install KVER=5.15.0-97-generic
```

# Build Docker image for docker images chain and testing

To make a tagged "bosch-linux-full-duplex-interface", which later can be
reused using this tag as a base image reference in docker build of
dependent drivers (note, the kernel version is given by default
setting in this case and not related to the running kernel):
```
$ make docker-image
```

To build a docker image tagged customly and using the specific kernel:
```
$ make docker-image DOCKER_OUT_IMAGE_TAG=my-custom-img-tag \
        KVER_DOCKER=5.15.0-97-generic
```

# How to test it?

To build and test it in a docker container:
```
$ make test
```

To build and test it in a docker container against given kernel:
```
$ make test KVER_DOCKER=5.15.0-97-generic

```

Note: Full Duplex Interface is tested in x86 and ARM (with device tree)
environment where the same tests are run in different architectures. The
code get's compiled for x86 and cross compiled for ARM and tested.

# Troubleshooting

* if you have the Docker build failure:
   "failed to solve with frontend dockerfile.v0: failed
    to create LLB definition: pull access denied, repository
    does not exist or may require authorization: server
    message: insufficient_scope: authorization failed"
  * Then you need to clone from
    <https://sourcecode.socialcoding.bosch.com/projects/CM_CI2_LINUX/repos/linux-ext-modules-build-base/browse>
    and then run 'make docker-image' there. This will make the
    docker image the current build is based on.
