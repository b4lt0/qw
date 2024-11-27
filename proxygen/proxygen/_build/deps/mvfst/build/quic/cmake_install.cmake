# Install script for directory: /client/qw/proxygen/proxygen/_build/deps/mvfst/quic

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/client/qw/proxygen/proxygen/_build/deps")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "RelWithDebInfo")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "1")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/objdump")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/quic" TYPE FILE FILES "/client/qw/proxygen/proxygen/_build/deps/mvfst/quic/QuicConstants.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/libmvfst_constants.a")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/quic" TYPE FILE FILES "/client/qw/proxygen/proxygen/_build/deps/mvfst/quic/QuicException.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/libmvfst_exception.a")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/api/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/client/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/codec/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/common/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/congestion_control/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/dsr/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/flowcontrol/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/handshake/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/happyeyeballs/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/logging/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/loss/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/observer/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/samples/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/state/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/tools/cmake_install.cmake")
  include("/client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk/cmake_install.cmake")

endif()

