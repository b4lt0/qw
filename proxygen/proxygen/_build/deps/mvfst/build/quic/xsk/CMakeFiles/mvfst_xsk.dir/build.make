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
include quic/xsk/CMakeFiles/mvfst_xsk.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include quic/xsk/CMakeFiles/mvfst_xsk.dir/compiler_depend.make

# Include the progress variables for this target.
include quic/xsk/CMakeFiles/mvfst_xsk.dir/progress.make

# Include the compile flags for this target's objects.
include quic/xsk/CMakeFiles/mvfst_xsk.dir/flags.make

quic/xsk/CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/flags.make
quic/xsk/CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.o: ../quic/xsk/packet_utils.cpp
quic/xsk/CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object quic/xsk/CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/xsk/CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.o -MF CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.o.d -o CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/packet_utils.cpp

quic/xsk/CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/packet_utils.cpp > CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.i

quic/xsk/CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/packet_utils.cpp -o CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.s

quic/xsk/CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/flags.make
quic/xsk/CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.o: ../quic/xsk/xsk_lib.cpp
quic/xsk/CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CXX object quic/xsk/CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/xsk/CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.o -MF CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.o.d -o CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/xsk_lib.cpp

quic/xsk/CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/xsk_lib.cpp > CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.i

quic/xsk/CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/xsk_lib.cpp -o CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.s

quic/xsk/CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/flags.make
quic/xsk/CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.o: ../quic/xsk/BaseXskContainer.cpp
quic/xsk/CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building CXX object quic/xsk/CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/xsk/CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.o -MF CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.o.d -o CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/BaseXskContainer.cpp

quic/xsk/CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/BaseXskContainer.cpp > CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.i

quic/xsk/CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/BaseXskContainer.cpp -o CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.s

quic/xsk/CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/flags.make
quic/xsk/CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.o: ../quic/xsk/HashingXskContainer.cpp
quic/xsk/CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building CXX object quic/xsk/CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/xsk/CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.o -MF CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.o.d -o CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/HashingXskContainer.cpp

quic/xsk/CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/HashingXskContainer.cpp > CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.i

quic/xsk/CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/HashingXskContainer.cpp -o CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.s

quic/xsk/CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/flags.make
quic/xsk/CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.o: ../quic/xsk/ThreadLocalXskContainer.cpp
quic/xsk/CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building CXX object quic/xsk/CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/xsk/CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.o -MF CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.o.d -o CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/ThreadLocalXskContainer.cpp

quic/xsk/CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/ThreadLocalXskContainer.cpp > CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.i

quic/xsk/CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/ThreadLocalXskContainer.cpp -o CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.s

quic/xsk/CMakeFiles/mvfst_xsk.dir/XskSender.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/flags.make
quic/xsk/CMakeFiles/mvfst_xsk.dir/XskSender.cpp.o: ../quic/xsk/XskSender.cpp
quic/xsk/CMakeFiles/mvfst_xsk.dir/XskSender.cpp.o: quic/xsk/CMakeFiles/mvfst_xsk.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building CXX object quic/xsk/CMakeFiles/mvfst_xsk.dir/XskSender.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/xsk/CMakeFiles/mvfst_xsk.dir/XskSender.cpp.o -MF CMakeFiles/mvfst_xsk.dir/XskSender.cpp.o.d -o CMakeFiles/mvfst_xsk.dir/XskSender.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/XskSender.cpp

quic/xsk/CMakeFiles/mvfst_xsk.dir/XskSender.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_xsk.dir/XskSender.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/XskSender.cpp > CMakeFiles/mvfst_xsk.dir/XskSender.cpp.i

quic/xsk/CMakeFiles/mvfst_xsk.dir/XskSender.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_xsk.dir/XskSender.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk/XskSender.cpp -o CMakeFiles/mvfst_xsk.dir/XskSender.cpp.s

# Object files for target mvfst_xsk
mvfst_xsk_OBJECTS = \
"CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.o" \
"CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.o" \
"CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.o" \
"CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.o" \
"CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.o" \
"CMakeFiles/mvfst_xsk.dir/XskSender.cpp.o"

# External object files for target mvfst_xsk
mvfst_xsk_EXTERNAL_OBJECTS =

quic/xsk/libmvfst_xsk.a: quic/xsk/CMakeFiles/mvfst_xsk.dir/packet_utils.cpp.o
quic/xsk/libmvfst_xsk.a: quic/xsk/CMakeFiles/mvfst_xsk.dir/xsk_lib.cpp.o
quic/xsk/libmvfst_xsk.a: quic/xsk/CMakeFiles/mvfst_xsk.dir/BaseXskContainer.cpp.o
quic/xsk/libmvfst_xsk.a: quic/xsk/CMakeFiles/mvfst_xsk.dir/HashingXskContainer.cpp.o
quic/xsk/libmvfst_xsk.a: quic/xsk/CMakeFiles/mvfst_xsk.dir/ThreadLocalXskContainer.cpp.o
quic/xsk/libmvfst_xsk.a: quic/xsk/CMakeFiles/mvfst_xsk.dir/XskSender.cpp.o
quic/xsk/libmvfst_xsk.a: quic/xsk/CMakeFiles/mvfst_xsk.dir/build.make
quic/xsk/libmvfst_xsk.a: quic/xsk/CMakeFiles/mvfst_xsk.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Linking CXX static library libmvfst_xsk.a"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && $(CMAKE_COMMAND) -P CMakeFiles/mvfst_xsk.dir/cmake_clean_target.cmake
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/mvfst_xsk.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
quic/xsk/CMakeFiles/mvfst_xsk.dir/build: quic/xsk/libmvfst_xsk.a
.PHONY : quic/xsk/CMakeFiles/mvfst_xsk.dir/build

quic/xsk/CMakeFiles/mvfst_xsk.dir/clean:
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk && $(CMAKE_COMMAND) -P CMakeFiles/mvfst_xsk.dir/cmake_clean.cmake
.PHONY : quic/xsk/CMakeFiles/mvfst_xsk.dir/clean

quic/xsk/CMakeFiles/mvfst_xsk.dir/depend:
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /client/qw/proxygen/proxygen/_build/deps/mvfst /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/xsk /client/qw/proxygen/proxygen/_build/deps/mvfst/build /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/xsk/CMakeFiles/mvfst_xsk.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : quic/xsk/CMakeFiles/mvfst_xsk.dir/depend
