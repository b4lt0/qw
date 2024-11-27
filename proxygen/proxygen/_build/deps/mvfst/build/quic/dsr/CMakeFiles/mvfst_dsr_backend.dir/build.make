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
include quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/compiler_depend.make

# Include the progress variables for this target.
include quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/progress.make

# Include the compile flags for this target's objects.
include quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/flags.make

quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.o: quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/flags.make
quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.o: ../quic/dsr/backend/DSRPacketizer.cpp
quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.o: quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.o"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/dsr && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.o -MF CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.o.d -o CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.o -c /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/dsr/backend/DSRPacketizer.cpp

quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.i"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/dsr && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/dsr/backend/DSRPacketizer.cpp > CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.i

quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.s"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/dsr && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/dsr/backend/DSRPacketizer.cpp -o CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.s

# Object files for target mvfst_dsr_backend
mvfst_dsr_backend_OBJECTS = \
"CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.o"

# External object files for target mvfst_dsr_backend
mvfst_dsr_backend_EXTERNAL_OBJECTS =

quic/dsr/libmvfst_dsr_backend.a: quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/backend/DSRPacketizer.cpp.o
quic/dsr/libmvfst_dsr_backend.a: quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/build.make
quic/dsr/libmvfst_dsr_backend.a: quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/client/qw/proxygen/proxygen/_build/deps/mvfst/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX static library libmvfst_dsr_backend.a"
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/dsr && $(CMAKE_COMMAND) -P CMakeFiles/mvfst_dsr_backend.dir/cmake_clean_target.cmake
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/dsr && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/mvfst_dsr_backend.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/build: quic/dsr/libmvfst_dsr_backend.a
.PHONY : quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/build

quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/clean:
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/dsr && $(CMAKE_COMMAND) -P CMakeFiles/mvfst_dsr_backend.dir/cmake_clean.cmake
.PHONY : quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/clean

quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/depend:
	cd /client/qw/proxygen/proxygen/_build/deps/mvfst/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /client/qw/proxygen/proxygen/_build/deps/mvfst /client/qw/proxygen/proxygen/_build/deps/mvfst/quic/dsr /client/qw/proxygen/proxygen/_build/deps/mvfst/build /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/dsr /client/qw/proxygen/proxygen/_build/deps/mvfst/build/quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : quic/dsr/CMakeFiles/mvfst_dsr_backend.dir/depend

