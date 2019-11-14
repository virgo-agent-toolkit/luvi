INCLUDE(CheckIncludeFiles)
INCLUDE(CheckFunctionExists)
INCLUDE(CheckTypeSize)

INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/include)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua)

if(MSVC)
  # Statically build against C runtime (use the right version for Release/Debug)
#  set(CompilerFlags
#        CMAKE_CXX_FLAGS
#        CMAKE_CXX_FLAGS_DEBUG
#        CMAKE_CXX_FLAGS_RELEASE
#        CMAKE_C_FLAGS
#        CMAKE_C_FLAGS_DEBUG
#        CMAKE_C_FLAGS_RELEASE
#        )
#  foreach(CompilerFlag ${CompilerFlags})
#    string(REPLACE "/MD" "/MT" ${CompilerFlag} "${${CompilerFlag}}")
#  endforeach()
endif()

IF(WIN32)
  IF(CMAKE_SIZEOF_VOID_P EQUAL 4)
    SET(WIN_ARCH "ia32")
  ELSEIF(CMAKE_SIZEOF_VOID_P EQUAL 8)
    SET(WIN_ARCH "amd64")
  ELSE()
    MESSAGE("Windows Arch Unknown")
  ENDIF()

  ## make sure we only use the smallest set of
  ## headers on win32. Otherwise we get clashes
  ## between winsock2.h and winsock.h
  ADD_DEFINITIONS(-DWIN32_LEAN_AND_MEAN)
  ADD_DEFINITIONS(-DWIN32)

  # turn off security warnings for system calls
  ADD_DEFINITIONS(-D_CRT_SECURE_NO_WARNINGS)
ENDIF(WIN32)

## sigar has some base files + a set of platform specific files

MESSAGE(STATUS "CMAKE_SYSTEM_NAME is ${CMAKE_SYSTEM_NAME}")

ADD_DEFINITIONS(-DLUA_COMPAT_MODULE)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/include/)

INCLUDE(CheckCSourceCompiles)

MACRO (CHECK_STRUCT_MEMBER _STRUCT _MEMBER _HEADER _RESULT)
   SET(_INCLUDE_FILES)
   FOREACH (it ${_HEADER})
      SET(_INCLUDE_FILES "${_INCLUDE_FILES}#include <${it}>\n")
   ENDFOREACH (it)

   SET(_CHECK_STRUCT_MEMBER_SOURCE_CODE "
${_INCLUDE_FILES}
int main()
{
   static ${_STRUCT} tmp;
   if (sizeof(tmp.${_MEMBER}))
      return 0;
  return 0;
}
")
   CHECK_C_SOURCE_COMPILES("${_CHECK_STRUCT_MEMBER_SOURCE_CODE}" ${_RESULT})

ENDMACRO (CHECK_STRUCT_MEMBER)


## linux
IF(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  SET(SIGAR_SRC ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/os/linux/linux_sigar.c)

  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/os/linux/)

  IF(EXISTS /usr/include/tirpc)
    INCLUDE_DIRECTORIES(/usr/include/tirpc)

    SET(EXTRA_LIBS ${EXTRA_LIBS} -ltirpc)
  ENDIF(EXISTS /usr/include/tirpc)

  CHECK_INCLUDE_FILES(sys/sysmacros.h HAVE_SYSMACROS_H)
  IF(HAVE_SYSMACROS_H)
    ADD_DEFINITIONS(-DHAVE_SYSMACROS_H)
  ENDIF(HAVE_SYSMACROS_H)
ENDIF(CMAKE_SYSTEM_NAME STREQUAL "Linux")

## macosx, freebsd
IF(CMAKE_SYSTEM_NAME MATCHES "(Darwin|FreeBSD)")
  SET(SIGAR_SRC ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/os/darwin/darwin_sigar.c)

  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/os/darwin/)
  IF(CMAKE_SYSTEM_NAME MATCHES "(Darwin)")
    ADD_DEFINITIONS(-DDARWIN)
    SET(SIGAR_LINK_FLAGS "-framework CoreServices -framework IOKit")
  ELSE(CMAKE_SYSTEM_NAME MATCHES "(Darwin)")
    ## freebsd needs libkvm
    SET(SIGAR_LINK_FLAGS "-lkvm")
  ENDIF(CMAKE_SYSTEM_NAME MATCHES "(Darwin)")
  SET(EXTRA_LIBS ${EXTRA_LIBS} ${SIGAR_LINK_FLAGS})
ENDIF(CMAKE_SYSTEM_NAME MATCHES "(Darwin|FreeBSD)")

## solaris
IF (CMAKE_SYSTEM_NAME MATCHES "(Solaris|SunOS)" )
  SET(SIGAR_SRC
    deps/sigar/src/os/solaris/solaris_sigar.c
    deps/sigar/src/os/solaris/get_mib2.c
    deps/sigar/src/os/solaris/kstats.c
    deps/sigar/src/os/solaris/procfs.c
  )

  INCLUDE_DIRECTORIES(deps/sigar/src/os/solaris/)
  ADD_DEFINITIONS(-DSOLARIS)
  SET(SIGAR_LINK_FLAGS -lkstat -ldl -lnsl -lsocket -lresolv)
ENDIF(CMAKE_SYSTEM_NAME MATCHES "(Solaris|SunOS)" )

## solaris
IF (CMAKE_SYSTEM_NAME MATCHES "(hpux)" )
  SET(SIGAR_SRC deps/sigar/src/os/hpux/hpux_sigar.c)
  INCLUDE_DIRECTORIES(deps/sigar/src/os/hpux/)
  ADD_DEFINITIONS(-DSIGAR_HPUX)
  SET(SIGAR_LINK_FLAGS -lnm)
ENDIF(CMAKE_SYSTEM_NAME MATCHES "(hpux)" )

## aix
IF (CMAKE_SYSTEM_NAME MATCHES "(AIX)" )
  SET(SIGAR_SRC deps/sigar/src/os/aix/aix_sigar.c)

  INCLUDE_DIRECTORIES(os/aix/)
  SET(SIGAR_LINK_FLAGS -lodm -lcfg)
ENDIF(CMAKE_SYSTEM_NAME MATCHES "(AIX)" )

IF(WIN32)
  SET(SIGAR_SRC
    ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/os/win32/wmi.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/os/win32/peb.c
    ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/os/win32/win32_sigar.c)
  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/os/win32)
  CHECK_STRUCT_MEMBER(MIB_IPADDRROW wType "windows.h;iphlpapi.h" wType_in_MIB_IPADDRROW)
  add_definitions(-DHAVE_MIB_IPADDRROW_WTYPE=${wType_in_MIB_IPADDRROW})
ENDIF(WIN32)

SET(SIGAR_SRC ${SIGAR_SRC}
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/sigar.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/sigar_cache.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/sigar_fileinfo.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/sigar_format.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/sigar_getline.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/sigar_ptql.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/sigar_signal.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/src/sigar_util.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-cpu.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-disk.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-fs.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-load.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-mem.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-netif.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-proc.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-swap.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-sysinfo.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-test.lua
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar-who.c
  ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-sigar/deps/sigar/bindings/lua/sigar.c
)

ADD_LIBRARY(sigar STATIC ${SIGAR_SRC})

IF(SIGAR_LINK_FLAGS)
  SET_TARGET_PROPERTIES(sigar PROPERTIES LINK_FLAGS "${SIGAR_LINK_FLAGS}")
ENDIF(SIGAR_LINK_FLAGS)

add_definitions( -DWITH_SIGAR )
set(EXTRA_LIBS ${EXTRA_LIBS} sigar)
if(WIN32)
  list(APPEND LIB_LIST ws2_32 netapi32 version)
endif()
