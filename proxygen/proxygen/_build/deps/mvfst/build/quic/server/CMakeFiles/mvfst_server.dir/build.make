# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.22

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /client/qw/proxygen/proxygen/_build/deps/mvfst

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /client/qw/proxygen/proxygen/_build/deps/mvfst/build

# Include any dependencies generated for this target.
include quic/server/CMakeFiles/mvfst_server.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.make

# Include the progress variables for this target.
include quic/server/CMakeFiles/mvfst_server.dir/progress.make

# Include the compile flags for this target's objects.
include quic/server/CMakeFiles/mvfst_server.dir/flags.make

quic/server/CMakeFiles/mvfst_server.dir/QuicServer.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/QuicServer.cpp.o: ../quic/server/QuicServer.cpp
quic/server/CMakeFiles/mvfst_server.dir/QuicServer.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/QuicServer.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/QuicServer.cpp.o -MF CMakeFiles/mvfst_server.dir/QuicServer.cpp.o.d -o CMakeFiles/mvfst_server.dir/QuicServer.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServer.cpp

quic/server/CMakeFiles/mvfst_server.dir/QuicServer.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/QuicServer.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServer.cpp > CMakeFiles/mvfst_server.dir/QuicServer.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/QuicServer.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/QuicServer.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServer.cpp -o CMakeFiles/mvfst_server.dir/QuicServer.cpp.s

quic/server/CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.o: ../quic/server/QuicServerBackend.cpp
quic/server/CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.o -MF CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.o.d -o CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerBackend.cpp

quic/server/CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerBackend.cpp > CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerBackend.cpp -o CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.s

quic/server/CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.o: ../quic/server/QuicServerPacketRouter.cpp
quic/server/CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.o -MF CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.o.d -o CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerPacketRouter.cpp

quic/server/CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerPacketRouter.cpp > CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerPacketRouter.cpp -o CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.s

quic/server/CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.o: ../quic/server/QuicServerTransport.cpp
quic/server/CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.o -MF CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.o.d -o CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerTransport.cpp

quic/server/CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerTransport.cpp > CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerTransport.cpp -o CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.s

quic/server/CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.o: ../quic/server/QuicServerWorker.cpp
quic/server/CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.o -MF CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.o.d -o CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerWorker.cpp

quic/server/CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerWorker.cpp > CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/QuicServerWorker.cpp -o CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.s

quic/server/CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.o: ../quic/server/SlidingWindowRateLimiter.cpp
quic/server/CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.o -MF CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.o.d -o CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/SlidingWindowRateLimiter.cpp

quic/server/CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/SlidingWindowRateLimiter.cpp > CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/SlidingWindowRateLimiter.cpp -o CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.s

quic/server/CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.o: ../quic/server/handshake/DefaultAppTokenValidator.cpp
quic/server/CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.o -MF CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.o.d -o CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/handshake/DefaultAppTokenValidator.cpp

quic/server/CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/handshake/DefaultAppTokenValidator.cpp > CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/handshake/DefaultAppTokenValidator.cpp -o CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.s

quic/server/CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.o: ../quic/server/handshake/TokenGenerator.cpp
quic/server/CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_8) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.o -MF CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.o.d -o CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/handshake/TokenGenerator.cpp

quic/server/CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/handshake/TokenGenerator.cpp > CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server/handshake/TokenGenerator.cpp -o CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.s

quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.o: ../quic/fizz/server/handshake/AppToken.cpp
quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_9) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.o -MF CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.o.d -o CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/server/handshake/AppToken.cpp

quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/server/handshake/AppToken.cpp > CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/server/handshake/AppToken.cpp -o CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.s

quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.o: ../quic/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp
quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_10) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.o -MF CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.o.d -o CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp

quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp > CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp -o CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.s

quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/flags.make
quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.o: ../quic/fizz/server/handshake/FizzServerHandshake.cpp
quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.o: quic/server/CMakeFiles/mvfst_server.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_11) "Building CXX object quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.o -MF CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.o.d -o CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/server/handshake/FizzServerHandshake.cpp

quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/server/handshake/FizzServerHandshake.cpp > CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.i

quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/server/handshake/FizzServerHandshake.cpp -o CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.s

# Object files for target mvfst_server
mvfst_server_OBJECTS = \
"CMakeFiles/mvfst_server.dir/QuicServer.cpp.o" \
"CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.o" \
"CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.o" \
"CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.o" \
"CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.o" \
"CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.o" \
"CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.o" \
"CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.o" \
"CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.o" \
"CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.o" \
"CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.o"

# External object files for target mvfst_server
mvfst_server_EXTERNAL_OBJECTS =

quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/QuicServer.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/QuicServerBackend.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/QuicServerPacketRouter.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/QuicServerTransport.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/QuicServerWorker.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/SlidingWindowRateLimiter.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/handshake/DefaultAppTokenValidator.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/handshake/TokenGenerator.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/AppToken.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerQuicHandshakeContext.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/__/fizz/server/handshake/FizzServerHandshake.cpp.o
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/build.make
quic/server/libmvfst_server.a: quic/server/CMakeFiles/mvfst_server.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_12) "Linking CXX static library libmvfst_server.a"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && $(CMAKE_COMMAND) -P CMakeFiles/mvfst_server.dir/cmake_clean_target.cmake
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/mvfst_server.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
quic/server/CMakeFiles/mvfst_server.dir/build: quic/server/libmvfst_server.a
.PHONY : quic/server/CMakeFiles/mvfst_server.dir/build

quic/server/CMakeFiles/mvfst_server.dir/clean:
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server && $(CMAKE_COMMAND) -P CMakeFiles/mvfst_server.dir/cmake_clean.cmake
.PHONY : quic/server/CMakeFiles/mvfst_server.dir/clean

quic/server/CMakeFiles/mvfst_server.dir/depend:
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /client/qw/proxygen/proxygen/_build/deps/mvfst /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/server /client/qw/proxygen/proxygen/_build/deps/mvfst/build /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/server/CMakeFiles/mvfst_server.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : quic/server/CMakeFiles/mvfst_server.dir/depend

