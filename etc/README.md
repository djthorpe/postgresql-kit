
There are a few scripts in this folder for building. Each script requires
a source and a destination, and you can  To build for the
different platforms, use the following:

Mac OS X 10.7
-------------

```
UNARCHIVE=/tmp
OUTPUT=/tmp
etc/make-openssl.sh tar/openssl-1.0.1c.tar.gz ${OUTPUT} \
  --platform=mac_x86_64
etc/make-postgresql.sh tar/postgresql-9.2.4.tar.gz ${OUTPUT} \
  --platform=mac_x86_64 --openssl=${OUTPUT}/openssl-current-mac_x86_64

```

This will create PostgreSQL in the following folder:

```
${OUTPUT}/postgresql-current-mac_x86_64
```

The subfolders `lib`, `bin`, `share` and `include` contains the full
server and client libraries.


iOS 6.1
-------

```
UNARCHIVE=/tmp
OUTPUT=/tmp

# make openssl
etc/make-openssl.sh tar/openssl-1.0.1c.tar.gz ${OUTPUT} \
  --platform=ios_armv7
etc/make-openssl.sh tar/openssl-1.0.1c.tar.gz ${OUTPUT} \
  --platform=ios_armv7s
etc/make-openssl.sh tar/openssl-1.0.1c.tar.gz ${OUTPUT} \
  --platform=ios_simulator

# make libpq
etc/make-libpq.sh tar/postgresql-9.2.4.tar.gz ${OUTPUT} \
  --platform=ios_armv7 --openssl=${OUTPUT}/openssl-current-ios_armv7
etc/make-libpq.sh tar/postgresql-9.2.4.tar.gz ${OUTPUT} \
  --platform=ios_armv7s --openssl=${OUTPUT}/openssl-current-ios_armv7s
etc/make-libpq.sh tar/postgresql-9.2.4.tar.gz ${OUTPUT} \
  --platform=ios_simulator --openssl=${OUTPUT}/openssl-current-ios_simulator
etc/lipo-libpq.sh ${OUTPUT} ios_armv7 ios_armv7s ios_simulator 
```

This will create the file ${OUTPUT}/libpq.a which is a FAT static library.

