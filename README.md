# What is it?

Full-duplex-interface module is only a definition of the
full-duplex-interface which is provided/implemented by
[SymSPI](https://github.com/Bosch-SW/linux-symspi). It was
extracted to the separate module cause it is semantically
independent from the [SymSPI](https://github.com/Bosch-SW/linux-symspi)
itself and allows to abstract pretty wide range of similar
transports.

This module is to be used to build the
[SymSPI](https://github.com/Bosch-SW/linux-symspi)
itself and also interface it or similar transport layers to
transport client code like [ICCom](https://github.com/Bosch-SW/linux-iccom).
