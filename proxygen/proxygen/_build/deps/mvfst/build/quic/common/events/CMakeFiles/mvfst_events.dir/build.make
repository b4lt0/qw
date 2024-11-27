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
include quic/common/events/CMakeFiles/mvfst_events.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include quic/common/events/CMakeFiles/mvfst_events.dir/compiler_depend.make

# Include the progress variables for this target.
include quic/common/events/CMakeFiles/mvfst_events.dir/progress.make

# Include the compile flags for this target's objects.
include quic/common/events/CMakeFiles/mvfst_events.dir/flags.make

quic/common/events/CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.o: quic/common/events/CMakeFiles/mvfst_events.dir/flags.make
quic/common/events/CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.o: ../quic/common/events/FollyQuicEventBase.cpp
quic/common/events/CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.o: quic/common/events/CMakeFiles/mvfst_events.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object quic/common/events/CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/common/events && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/common/events/CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.o -MF CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.o.d -o CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/common/events/FollyQuicEventBase.cpp

quic/common/events/CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/common/events && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/common/events/FollyQuicEventBase.cpp > CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.i

quic/common/events/CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/common/events && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/common/events/FollyQuicEventBase.cpp -o CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.s

# Object files for target mvfst_events
mvfst_events_OBJECTS = \
"CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.o"

# External object files for target mvfst_events
mvfst_events_EXTERNAL_OBJECTS =

quic/common/events/libmvfst_events.a: quic/common/events/CMakeFiles/mvfst_events.dir/FollyQuicEventBase.cpp.o
quic/common/events/libmvfst_events.a: quic/common/events/CMakeFiles/mvfst_events.dir/build.make
quic/common/events/libmvfst_events.a: quic/common/events/CMakeFiles/mvfst_events.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX static library libmvfst_events.a"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/common/events && $(CMAKE_COMMAND) -P CMakeFiles/mvfst_events.dir/cmake_clean_target.cmake
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/common/events && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/mvfst_events.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
quic/common/events/CMakeFiles/mvfst_events.dir/build: quic/common/events/libmvfst_events.a
.PHONY : quic/common/events/CMakeFiles/mvfst_events.dir/build

quic/common/events/CMakeFiles/mvfst_events.dir/clean:
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/common/events && $(CMAKE_COMMAND) -P CMakeFiles/mvfst_events.dir/cmake_clean.cmake
.PHONY : quic/common/events/CMakeFiles/mvfst_events.dir/clean

quic/common/events/CMakeFiles/mvfst_events.dir/depend:
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /client/qw/proxygen/proxygen/_build/deps/mvfst /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/common/events /client/qw/proxygen/proxygen/_build/deps/mvfst/build /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/common/events /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/common/events/CMakeFiles/mvfst_events.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : quic/common/events/CMakeFiles/mvfst_events.dir/depend

