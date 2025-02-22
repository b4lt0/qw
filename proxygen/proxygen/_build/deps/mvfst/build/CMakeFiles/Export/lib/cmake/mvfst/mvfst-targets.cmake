# Generated by CMake

if("${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}" LESS 2.6)
   message(FATAL_ERROR "CMake >= 2.6.0 required")
endif()
cmake_policy(PUSH)
cmake_policy(VERSION 2.6...3.20)
#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Protect against multiple inclusion, which would fail when already imported targets are added once more.
set(_targetsDefined)
set(_targetsNotDefined)
set(_expectedTargets)
foreach(_expectedTarget mvfst::mvfst_constants mvfst::mvfst_exception mvfst::mvfst_transport mvfst::mvfst_batch_writer mvfst::mvfst_client mvfst::mvfst_codec_types mvfst::mvfst_codec_decode mvfst::mvfst_codec_pktbuilder mvfst::mvfst_codec_pktrebuilder mvfst::mvfst_codec_packet_number_cipher mvfst::mvfst_codec mvfst::mvfst_looper mvfst::mvfst_buf_accessor mvfst::mvfst_bufutil mvfst::mvfst_transport_knobs mvfst::mvfst_events mvfst::mvfst_async_udp_socket mvfst::mvfst_cc_algo mvfst::mvfst_dsr_sender mvfst::mvfst_dsr_types mvfst::mvfst_dsr_frontend mvfst::mvfst_fizz_client mvfst::mvfst_fizz_handshake mvfst::mvfst_flowcontrol mvfst::mvfst_handshake mvfst::mvfst_happyeyeballs mvfst::mvfst_qlogger mvfst::mvfst_loss mvfst::mvfst_observer mvfst::mvfst_server mvfst::mvfst_server_state mvfst::mvfst_server_async_tran mvfst::mvfst_state_machine mvfst::mvfst_state_ack_handler mvfst::mvfst_state_datagram_handler mvfst::mvfst_state_stream_functions mvfst::mvfst_state_pacing_functions mvfst::mvfst_state_functions mvfst::mvfst_state_simple_frame_functions mvfst::mvfst_state_stream mvfst::mvfst_transport_settings_functions mvfst::mvfst_xsk)
  list(APPEND _expectedTargets ${_expectedTarget})
  if(NOT TARGET ${_expectedTarget})
    list(APPEND _targetsNotDefined ${_expectedTarget})
  endif()
  if(TARGET ${_expectedTarget})
    list(APPEND _targetsDefined ${_expectedTarget})
  endif()
endforeach()
if("${_targetsDefined}" STREQUAL "${_expectedTargets}")
  unset(_targetsDefined)
  unset(_targetsNotDefined)
  unset(_expectedTargets)
  set(CMAKE_IMPORT_FILE_VERSION)
  cmake_policy(POP)
  return()
endif()
if(NOT "${_targetsDefined}" STREQUAL "")
  message(FATAL_ERROR "Some (but not all) targets in this export set were already defined.\nTargets Defined: ${_targetsDefined}\nTargets not yet defined: ${_targetsNotDefined}\n")
endif()
unset(_targetsDefined)
unset(_targetsNotDefined)
unset(_expectedTargets)


# Compute the installation prefix relative to this file.
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
if(_IMPORT_PREFIX STREQUAL "/")
  set(_IMPORT_PREFIX "")
endif()

# Create imported target mvfst::mvfst_constants
add_library(mvfst::mvfst_constants STATIC IMPORTED)

set_target_properties(mvfst::mvfst_constants PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;Boost::context;Boost::filesystem;Boost::program_options;Boost::regex;Boost::system;Boost::thread"
)

# Create imported target mvfst::mvfst_exception
add_library(mvfst::mvfst_exception STATIC IMPORTED)

set_target_properties(mvfst::mvfst_exception PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;fizz::fizz"
)

# Create imported target mvfst::mvfst_transport
add_library(mvfst::mvfst_transport STATIC IMPORTED)

set_target_properties(mvfst::mvfst_transport PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_batch_writer;mvfst::mvfst_buf_accessor;mvfst::mvfst_bufutil;mvfst::mvfst_cc_algo;mvfst::mvfst_codec;mvfst::mvfst_codec_pktbuilder;mvfst::mvfst_codec_pktrebuilder;mvfst::mvfst_codec_types;mvfst::mvfst_constants;mvfst::mvfst_events;mvfst::mvfst_exception;mvfst::mvfst_flowcontrol;mvfst::mvfst_happyeyeballs;mvfst::mvfst_looper;mvfst::mvfst_loss;mvfst::mvfst_observer;mvfst::mvfst_qlogger;mvfst::mvfst_state_ack_handler;mvfst::mvfst_state_datagram_handler;mvfst::mvfst_state_functions;mvfst::mvfst_state_machine;mvfst::mvfst_state_pacing_functions;mvfst::mvfst_state_simple_frame_functions;mvfst::mvfst_state_stream;mvfst::mvfst_state_stream_functions"
)

# Create imported target mvfst::mvfst_batch_writer
add_library(mvfst::mvfst_batch_writer STATIC IMPORTED)

set_target_properties(mvfst::mvfst_batch_writer PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_async_udp_socket;mvfst::mvfst_events;mvfst::mvfst_constants;mvfst::mvfst_state_machine"
)

# Create imported target mvfst::mvfst_client
add_library(mvfst::mvfst_client STATIC IMPORTED)

set_target_properties(mvfst::mvfst_client PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_flowcontrol;mvfst::mvfst_happyeyeballs;mvfst::mvfst_loss;mvfst::mvfst_qlogger;mvfst::mvfst_state_ack_handler;mvfst::mvfst_state_datagram_handler;mvfst::mvfst_state_pacing_functions;mvfst::mvfst_transport"
)

# Create imported target mvfst::mvfst_codec_types
add_library(mvfst::mvfst_codec_types STATIC IMPORTED)

set_target_properties(mvfst::mvfst_codec_types PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_bufutil;mvfst::mvfst_constants;mvfst::mvfst_exception;\$<LINK_ONLY:Boost::context>;\$<LINK_ONLY:Boost::filesystem>;\$<LINK_ONLY:Boost::program_options>;\$<LINK_ONLY:Boost::regex>;\$<LINK_ONLY:Boost::system>;\$<LINK_ONLY:Boost::thread>"
)

# Create imported target mvfst::mvfst_codec_decode
add_library(mvfst::mvfst_codec_decode STATIC IMPORTED)

set_target_properties(mvfst::mvfst_codec_decode PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec_types;mvfst::mvfst_exception"
)

# Create imported target mvfst::mvfst_codec_pktbuilder
add_library(mvfst::mvfst_codec_pktbuilder STATIC IMPORTED)

set_target_properties(mvfst::mvfst_codec_pktbuilder PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec_types;mvfst::mvfst_handshake"
)

# Create imported target mvfst::mvfst_codec_pktrebuilder
add_library(mvfst::mvfst_codec_pktrebuilder STATIC IMPORTED)

set_target_properties(mvfst::mvfst_codec_pktrebuilder PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec;mvfst::mvfst_codec_pktbuilder;mvfst::mvfst_flowcontrol;mvfst::mvfst_state_machine;mvfst::mvfst_state_simple_frame_functions;mvfst::mvfst_state_stream_functions"
)

# Create imported target mvfst::mvfst_codec_packet_number_cipher
add_library(mvfst::mvfst_codec_packet_number_cipher STATIC IMPORTED)

set_target_properties(mvfst::mvfst_codec_packet_number_cipher PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec_types;mvfst::mvfst_codec_decode"
)

# Create imported target mvfst::mvfst_codec
add_library(mvfst::mvfst_codec STATIC IMPORTED)

set_target_properties(mvfst::mvfst_codec PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_constants;mvfst::mvfst_codec_decode;mvfst::mvfst_codec_types;mvfst::mvfst_exception;mvfst::mvfst_handshake"
)

# Create imported target mvfst::mvfst_looper
add_library(mvfst::mvfst_looper STATIC IMPORTED)

set_target_properties(mvfst::mvfst_looper PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly"
)

# Create imported target mvfst::mvfst_buf_accessor
add_library(mvfst::mvfst_buf_accessor STATIC IMPORTED)

set_target_properties(mvfst::mvfst_buf_accessor PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly"
)

# Create imported target mvfst::mvfst_bufutil
add_library(mvfst::mvfst_bufutil STATIC IMPORTED)

set_target_properties(mvfst::mvfst_bufutil PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly"
)

# Create imported target mvfst::mvfst_transport_knobs
add_library(mvfst::mvfst_transport_knobs STATIC IMPORTED)

set_target_properties(mvfst::mvfst_transport_knobs PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "mvfst::mvfst_constants;Folly::folly"
)

# Create imported target mvfst::mvfst_events
add_library(mvfst::mvfst_events STATIC IMPORTED)

set_target_properties(mvfst::mvfst_events PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly"
)

# Create imported target mvfst::mvfst_async_udp_socket
add_library(mvfst::mvfst_async_udp_socket STATIC IMPORTED)

set_target_properties(mvfst::mvfst_async_udp_socket PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_events"
)

# Create imported target mvfst::mvfst_cc_algo
add_library(mvfst::mvfst_cc_algo STATIC IMPORTED)

set_target_properties(mvfst::mvfst_cc_algo PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_constants;mvfst::mvfst_exception;mvfst::mvfst_state_machine;mvfst::mvfst_state_functions"
)

# Create imported target mvfst::mvfst_dsr_sender
add_library(mvfst::mvfst_dsr_sender INTERFACE IMPORTED)

set_target_properties(mvfst::mvfst_dsr_sender PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
)

# Create imported target mvfst::mvfst_dsr_types
add_library(mvfst::mvfst_dsr_types STATIC IMPORTED)

set_target_properties(mvfst::mvfst_dsr_types PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec_types"
)

# Create imported target mvfst::mvfst_dsr_frontend
add_library(mvfst::mvfst_dsr_frontend STATIC IMPORTED)

set_target_properties(mvfst::mvfst_dsr_frontend PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec_types;mvfst::mvfst_dsr_types"
)

# Create imported target mvfst::mvfst_fizz_client
add_library(mvfst::mvfst_fizz_client STATIC IMPORTED)

set_target_properties(mvfst::mvfst_fizz_client PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "mvfst::mvfst_client;mvfst::mvfst_fizz_handshake"
)

# Create imported target mvfst::mvfst_fizz_handshake
add_library(mvfst::mvfst_fizz_handshake STATIC IMPORTED)

set_target_properties(mvfst::mvfst_fizz_handshake PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "fizz::fizz;mvfst::mvfst_handshake;mvfst::mvfst_codec_packet_number_cipher"
)

# Create imported target mvfst::mvfst_flowcontrol
add_library(mvfst::mvfst_flowcontrol STATIC IMPORTED)

set_target_properties(mvfst::mvfst_flowcontrol PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec_types;mvfst::mvfst_constants;mvfst::mvfst_exception;mvfst::mvfst_state_machine;mvfst::mvfst_qlogger"
)

# Create imported target mvfst::mvfst_handshake
add_library(mvfst::mvfst_handshake STATIC IMPORTED)

set_target_properties(mvfst::mvfst_handshake PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_constants;mvfst::mvfst_exception;mvfst::mvfst_codec_types;mvfst::mvfst_codec_packet_number_cipher"
)

# Create imported target mvfst::mvfst_happyeyeballs
add_library(mvfst::mvfst_happyeyeballs STATIC IMPORTED)

set_target_properties(mvfst::mvfst_happyeyeballs PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_async_udp_socket;mvfst::mvfst_state_machine"
)

# Create imported target mvfst::mvfst_qlogger
add_library(mvfst::mvfst_qlogger STATIC IMPORTED)

set_target_properties(mvfst::mvfst_qlogger PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec_types"
)

# Create imported target mvfst::mvfst_loss
add_library(mvfst::mvfst_loss STATIC IMPORTED)

set_target_properties(mvfst::mvfst_loss PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec_types;mvfst::mvfst_constants;mvfst::mvfst_exception;mvfst::mvfst_flowcontrol;mvfst::mvfst_state_functions;mvfst::mvfst_state_machine;mvfst::mvfst_state_simple_frame_functions"
)

# Create imported target mvfst::mvfst_observer
add_library(mvfst::mvfst_observer STATIC IMPORTED)

set_target_properties(mvfst::mvfst_observer PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_constants;mvfst::mvfst_exception;mvfst::mvfst_state_ack_handler;mvfst::mvfst_state_machine"
)

# Create imported target mvfst::mvfst_server
add_library(mvfst::mvfst_server STATIC IMPORTED)

set_target_properties(mvfst::mvfst_server PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;fizz::fizz;mvfst::mvfst_buf_accessor;mvfst::mvfst_constants;mvfst::mvfst_codec;mvfst::mvfst_codec_types;mvfst::mvfst_dsr_frontend;mvfst::mvfst_fizz_handshake;mvfst::mvfst_qlogger;mvfst::mvfst_server_state;mvfst::mvfst_state_ack_handler;mvfst::mvfst_state_datagram_handler;mvfst::mvfst_transport;mvfst::mvfst_transport_knobs;mvfst::mvfst_transport_settings_functions"
)

# Create imported target mvfst::mvfst_server_state
add_library(mvfst::mvfst_server_state STATIC IMPORTED)

set_target_properties(mvfst::mvfst_server_state PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;fizz::fizz;mvfst::mvfst_buf_accessor;mvfst::mvfst_constants;mvfst::mvfst_codec;mvfst::mvfst_codec_types;mvfst::mvfst_dsr_frontend;mvfst::mvfst_fizz_handshake;mvfst::mvfst_qlogger;mvfst::mvfst_state_ack_handler;mvfst::mvfst_transport;mvfst::mvfst_transport_knobs"
)

# Create imported target mvfst::mvfst_server_async_tran
add_library(mvfst::mvfst_server_async_tran STATIC IMPORTED)

set_target_properties(mvfst::mvfst_server_async_tran PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;fizz::fizz;mvfst::mvfst_server;mvfst::mvfst_buf_accessor;mvfst::mvfst_constants;mvfst::mvfst_codec;mvfst::mvfst_codec_types;mvfst::mvfst_dsr_frontend;mvfst::mvfst_fizz_handshake;mvfst::mvfst_qlogger;mvfst::mvfst_server_state;mvfst::mvfst_state_ack_handler;mvfst::mvfst_state_datagram_handler;mvfst::mvfst_transport;mvfst::mvfst_transport_knobs"
)

# Create imported target mvfst::mvfst_state_machine
add_library(mvfst::mvfst_state_machine STATIC IMPORTED)

set_target_properties(mvfst::mvfst_state_machine PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_bufutil;mvfst::mvfst_constants;mvfst::mvfst_codec;mvfst::mvfst_codec_types;mvfst::mvfst_dsr_sender;mvfst::mvfst_handshake"
)

# Create imported target mvfst::mvfst_state_ack_handler
add_library(mvfst::mvfst_state_ack_handler STATIC IMPORTED)

set_target_properties(mvfst::mvfst_state_ack_handler PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_constants;mvfst::mvfst_codec_types;mvfst::mvfst_loss;mvfst::mvfst_state_functions;mvfst::mvfst_state_machine"
)

# Create imported target mvfst::mvfst_state_datagram_handler
add_library(mvfst::mvfst_state_datagram_handler STATIC IMPORTED)

set_target_properties(mvfst::mvfst_state_datagram_handler PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_constants;mvfst::mvfst_codec_types;mvfst::mvfst_loss;mvfst::mvfst_state_functions;mvfst::mvfst_state_machine"
)

# Create imported target mvfst::mvfst_state_stream_functions
add_library(mvfst::mvfst_state_stream_functions STATIC IMPORTED)

set_target_properties(mvfst::mvfst_state_stream_functions PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_bufutil;mvfst::mvfst_codec;mvfst::mvfst_codec_types;mvfst::mvfst_state_machine"
)

# Create imported target mvfst::mvfst_state_pacing_functions
add_library(mvfst::mvfst_state_pacing_functions STATIC IMPORTED)

set_target_properties(mvfst::mvfst_state_pacing_functions PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_state_machine"
)

# Create imported target mvfst::mvfst_state_functions
add_library(mvfst::mvfst_state_functions STATIC IMPORTED)

set_target_properties(mvfst::mvfst_state_functions PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec_pktbuilder;mvfst::mvfst_codec_types;mvfst::mvfst_state_machine;mvfst::mvfst_state_stream"
)

# Create imported target mvfst::mvfst_state_simple_frame_functions
add_library(mvfst::mvfst_state_simple_frame_functions STATIC IMPORTED)

set_target_properties(mvfst::mvfst_state_simple_frame_functions PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_state_functions;mvfst::mvfst_state_machine;mvfst::mvfst_codec_types"
)

# Create imported target mvfst::mvfst_state_stream
add_library(mvfst::mvfst_state_stream STATIC IMPORTED)

set_target_properties(mvfst::mvfst_state_stream PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly;mvfst::mvfst_codec_types;mvfst::mvfst_exception;mvfst::mvfst_flowcontrol;mvfst::mvfst_state_machine;mvfst::mvfst_state_stream_functions"
)

# Create imported target mvfst::mvfst_transport_settings_functions
add_library(mvfst::mvfst_transport_settings_functions STATIC IMPORTED)

set_target_properties(mvfst::mvfst_transport_settings_functions PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly"
)

# Create imported target mvfst::mvfst_xsk
add_library(mvfst::mvfst_xsk STATIC IMPORTED)

set_target_properties(mvfst::mvfst_xsk PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include/"
  INTERFACE_LINK_LIBRARIES "Folly::folly"
)

if(CMAKE_VERSION VERSION_LESS 3.0.0)
  message(FATAL_ERROR "This file relies on consumers using CMake 3.0.0 or greater.")
endif()

# Load information for each installed configuration.
get_filename_component(_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)
file(GLOB CONFIG_FILES "${_DIR}/mvfst-targets-*.cmake")
foreach(f ${CONFIG_FILES})
  include(${f})
endforeach()

# Cleanup temporary variables.
set(_IMPORT_PREFIX)

# Loop over all imported files and verify that they actually exist
foreach(target ${_IMPORT_CHECK_TARGETS} )
  foreach(file ${_IMPORT_CHECK_FILES_FOR_${target}} )
    if(NOT EXISTS "${file}" )
      message(FATAL_ERROR "The imported target \"${target}\" references the file
   \"${file}\"
but this file does not exist.  Possible reasons include:
* The file was deleted, renamed, or moved to another location.
* An install or uninstall procedure did not complete successfully.
* The installation package was faulty and contained
   \"${CMAKE_CURRENT_LIST_FILE}\"
but not all the files it references.
")
    endif()
  endforeach()
  unset(_IMPORT_CHECK_FILES_FOR_${target})
endforeach()
unset(_IMPORT_CHECK_TARGETS)

# This file does not depend on other imported targets which have
# been exported from the same project but in a separate export set.

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
cmake_policy(POP)
