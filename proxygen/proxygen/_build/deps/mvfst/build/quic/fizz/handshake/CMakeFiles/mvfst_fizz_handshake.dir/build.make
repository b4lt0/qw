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
include quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/compiler_depend.make

# Include the progress variables for this target.
include quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/progress.make

# Include the compile flags for this target's objects.
include quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/flags.make

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.o: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/flags.make
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.o: ../quic/fizz/handshake/FizzBridge.cpp
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.o: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.o -MF CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.o.d -o CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzBridge.cpp

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzBridge.cpp > CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.i

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzBridge.cpp -o CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.s

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.o: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/flags.make
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.o: ../quic/fizz/handshake/FizzCryptoFactory.cpp
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.o: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CXX object quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.o -MF CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.o.d -o CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzCryptoFactory.cpp

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzCryptoFactory.cpp > CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.i

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzCryptoFactory.cpp -o CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.s

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.o: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/flags.make
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.o: ../quic/fizz/handshake/FizzPacketNumberCipher.cpp
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.o: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building CXX object quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.o -MF CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.o.d -o CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzPacketNumberCipher.cpp

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzPacketNumberCipher.cpp > CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.i

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzPacketNumberCipher.cpp -o CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.s

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.o: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/flags.make
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.o: ../quic/fizz/handshake/FizzRetryIntegrityTagGenerator.cpp
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.o: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building CXX object quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.o -MF CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.o.d -o CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzRetryIntegrityTagGenerator.cpp

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzRetryIntegrityTagGenerator.cpp > CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.i

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/FizzRetryIntegrityTagGenerator.cpp -o CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.s

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.o: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/flags.make
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.o: ../quic/fizz/handshake/QuicFizzFactory.cpp
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.o: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building CXX object quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.o -MF CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.o.d -o CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/QuicFizzFactory.cpp

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/QuicFizzFactory.cpp > CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.i

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake/QuicFizzFactory.cpp -o CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.s

# Object files for target mvfst_fizz_handshake
mvfst_fizz_handshake_OBJECTS = \
"CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.o" \
"CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.o" \
"CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.o" \
"CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.o" \
"CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.o"

# External object files for target mvfst_fizz_handshake
mvfst_fizz_handshake_EXTERNAL_OBJECTS =

quic/fizz/handshake/libmvfst_fizz_handshake.a: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzBridge.cpp.o
quic/fizz/handshake/libmvfst_fizz_handshake.a: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzCryptoFactory.cpp.o
quic/fizz/handshake/libmvfst_fizz_handshake.a: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzPacketNumberCipher.cpp.o
quic/fizz/handshake/libmvfst_fizz_handshake.a: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/FizzRetryIntegrityTagGenerator.cpp.o
quic/fizz/handshake/libmvfst_fizz_handshake.a: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/QuicFizzFactory.cpp.o
quic/fizz/handshake/libmvfst_fizz_handshake.a: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/build.make
quic/fizz/handshake/libmvfst_fizz_handshake.a: quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Linking CXX static library libmvfst_fizz_handshake.a"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && $(CMAKE_COMMAND) -P CMakeFiles/mvfst_fizz_handshake.dir/cmake_clean_target.cmake
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/mvfst_fizz_handshake.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/build: quic/fizz/handshake/libmvfst_fizz_handshake.a
.PHONY : quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/build

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/clean:
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake && $(CMAKE_COMMAND) -P CMakeFiles/mvfst_fizz_handshake.dir/cmake_clean.cmake
.PHONY : quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/clean

quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/depend:
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /client/qw/proxygen/proxygen/_build/deps/mvfst /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/fizz/handshake /client/qw/proxygen/proxygen/_build/deps/mvfst/build /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : quic/fizz/handshake/CMakeFiles/mvfst_fizz_handshake.dir/depend

