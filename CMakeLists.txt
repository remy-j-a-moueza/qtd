cmake_minimum_required(VERSION 2.6)
PROJECT(qtd CXX C)
FIND_PACKAGE(Qt4 REQUIRED)

##--------------------------------------------
## Settings.
##--------------------------------------------

include_directories(${QT_INCLUDES} include ${CMAKE_CURRENT_BINARY_DIR}/include)

## Options.
option(BUILD_QT_OPENGL "Build QtOpenGL" "ON")
option(BUILD_EXAMPLES "Build examples" "ON")
option(GENERATE_DI_FILES "Generate *.di files with DC -H command" "OFF")

## Packages list.
set(packages_big Core Gui)
if(BUILD_QT_OPENGL)
    set(packages_big ${packages_big} OpenGL)
endif(BUILD_QT_OPENGL)

set(packages)
foreach(package ${packages_big})
    string(TOLOWER ${package} package)
    set(packages ${packages} ${package})
endforeach(package ${packages_big})

## Find D compiler and parsing its version.
find_program(DC dmd ldc)
if (DC)   
    exec_program(${DC} ARGS "" OUTPUT_VARIABLE d_output)   
    string(REGEX MATCH "Digital Mars D Compiler v[0-9]\\.[0-9]+" dmd_version "${d_output}")
    if (dmd_version)
	set(D_IS_MARS true)
	set(D_COMPILER_NAME "Digital Mars D Compiler")
	string(REGEX REPLACE "Digital Mars D Compiler v([0-9])\\.[0-9]+" "\\1" D_VERSION "${dmd_version}")
	string(REGEX REPLACE "Digital Mars D Compiler v[0-9]\\.([0-9]+)" "\\1" D_FRONTEND "${dmd_version}")    
    else (dmd_version)
	string(REGEX MATCH "LLVM-based D Compiler" is_ldc "${d_output}")   
	if (is_ldc)
	    exec_program(${DC} ARGS "--version" OUTPUT_VARIABLE d_output)
	    string(REGEX MATCH "based on DMD v[0-9]\\.[0-9]+ and llvm [0-9]\\.[0-9]+" ldc_version "${d_output}")
	    set(D_IS_LLVM true)
	    if(ldc_version)
		set(D_IS_LLVM true)
		set(D_COMPILER_NAME "LLVM-based D Compiler")
		string(REGEX REPLACE "based on DMD v([0-9])\\.[0-9]+ and llvm [0-9]\\.[0-9]+" "\\1" D_VERSION "${ldc_version}")
		string(REGEX REPLACE "based on DMD v[0-9]\\.([0-9]+) and llvm [0-9]\\.[0-9]+" "\\1" D_FRONTEND "${ldc_version}")	    
	    else(ldc_version)
		message(FATAL_ERROR "LDC compiler was found, but the version can not be processed")
	    endif(ldc_version)
	else (is_ldc) 
	    message(FATAL_ERROR "D compliler not founded")
	endif(is_ldc)
    endif(dmd_version)   
    message(STATUS "D compiler founded -- ${D_COMPILER_NAME} v${D_VERSION}.${D_FRONTEND}")
else (DC)
    message(FATAL_ERROR "D compliler not founded")
endif (DC)

if(D_IS_MARS)
    option(SINGLE_D_OBJECT "Build all d sources to one object file" "ON")
elseif(D_IS_LLVM)
    option(SINGLE_D_OBJECT "Build all d sources to one object file" "OFF")
    if(SINGLE_D_OBJECT)
	set(D_FLAGS ${D_FLAGS} -singleobj)
    endif(SINGLE_D_OBJECT)
endif(D_IS_MARS)

# Check D compiler version
if(D_VERSION EQUAL "1")
    if (D_FRONTEND LESS "041")
	message(STATUS "Minimum required version of D compiler is 1.041 (or compiler based on this version)")
    endif(D_FRONTEND LESS "041")
    set(D_TARGET d1-tango)
    #set(D_FLAGS ${D_FLAGS} -I${CMAKE_SOURCE_DIR}/qtd/d1)
elseif(D_VERSION EQUAL "2")
    set(D_TARGET ) ## TODO: hm... I don`t known this parameter for D2 ^(
    #set(D_FLAGS ${D_FLAGS} -I${CMAKE_SOURCE_DIR}/qtd/d2)
endif(D_VERSION EQUAL "1")

# Debug and release flags.
if (${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])
   #set(CMAKE_BUILD_TYPE Debug)
   #set( SUFFIXLIB "${SUFFIXLIB}-debug" )
   #set( SUFFIXBIN "${SUFFIXBIN}-debug" )
   add_definitions(-DDEBUG)
   set(D_FLAGS ${D_FLAGS} -g -gc -debug)
else (${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])
   #set(CMAKE_BUILD_TYPE Release)
    add_definitions(-UNO_DEBUG)
    set(D_FLAGS ${D_FLAGS} -O -release -inline)
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
      set(D_FLAGS ${D_FLAGS} -L/subsystem:windows)
    endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows)   
endif (${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])  
set(D_FLAGS ${D_FLAGS} -I${CMAKE_BINARY_DIR} -I${CMAKE_SOURCE_DIR})
if(D_IS_MARS AND ${CMAKE_SYSTEM_NAME} STREQUAL Windows)
else(D_IS_MARS AND ${CMAKE_SYSTEM_NAME} STREQUAL Windows)
    set(D_FLAGS ${D_FLAGS} -L-L${CMAKE_BINARY_DIR}/lib)
endif(D_IS_MARS AND ${CMAKE_SYSTEM_NAME} STREQUAL Windows)


# System specifc settings.
if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
    set(implib implib)
    find_program(IMPLIB ${implib})
    if (NOT IMPLIB)
	message(FATAL_ERROR "implib not found. You can donwload it from http://ftp.digitalmars.com/bup.zip")
    endif (NOT IMPLIB)
    set(D_OBJECT_SUFFIX .obj)
    if(D_IS_MARS)
      set(D_LIB_SUFFIX .lib)
      set(D_LIB_PREFIX )
    elseif(D_IS_LDC)
      set(D_LIB_SUFFIX .a)
      set(D_LIB_PREFIX lib)
    endif(D_IS_MARS)
    set(GEN_OPT ${GEN_OPT} --cpp_shared)
    add_definitions(-DCPP_SHARED)
    string(REGEX REPLACE ".dll([A-Za-z\\.0-9]+)" "\\1" CMAKE_IMPORT_LIBRARY_SUFFIX "${CMAKE_IMPORT_LIBRARY_SUFFIX}")
elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux) 
    set(D_LIB_SUFFIX .a)
    set(D_LIB_PREFIX lib)
    set(D_OBJECT_SUFFIX .o)
endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows) 

set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} ./)
set(GEN_OPT ${GEN_OPT} --d-target=${D_TARGET})

##--------------------------------------------
## Macroses and functions.
##--------------------------------------------

## Make native path.
## Usage:
##	set(path c:/file_path/file_name.cpp)
##	make_native_path(path)
##	message(STATUS ${path})
## Output:
##	-- "c:\file_path\file_name.cpp"
## Command "file(TO_NATIVE_PATH ...)" is wrong on Windows
macro(MAKE_NATIVE_PATH pathname)
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
	# An extra \\ escape is necessary to get a \ through CMake's processing.
	string(REPLACE "/" "\\" ${pathname} "${${pathname}}")
	# Enclose with UNESCAPED quotes.  This means we need to escape our
	# quotes once here, i.e. with \"
	set(${pathname} \"${${pathname}}\")
    endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows) 
endmacro(MAKE_NATIVE_PATH)

## Remove unnecessary travel to the object file.
## path -- path to object file.
## Example:
##	set(path ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/target.dir/main.d.obj)
##	obj_path(path)
##	message(STATUS ${path})
## Example output:
##	-- CMakeFiles/target.dir/main.d.obj
macro(OBJ_PATH path)
    set(test)
    string(REGEX MATCH "${CMAKE_CURRENT_BINARY_DIR}/.*" test "${${path}}")    
    if(NOT ${test} EQUAL "")
	string(LENGTH "${CMAKE_CURRENT_BINARY_DIR}" first)
	string(LENGTH "${${path}}" last)
	math(EXPR first "${first} + 1")
	math(EXPR len "${last} - ${first}")	
	string(SUBSTRING "${${path}}" ${first} ${len} ${path})
    else(NOT ${test} EQUAL "")
	string(REGEX MATCH "${CMAKE_CURRENT_SOURCE_DIR}/.*" test "${${path}}")    
	if(NOT ${test} EQUAL "")
	    string(LENGTH "${CMAKE_CURRENT_SOURCE_DIR}" first)
	    string(LENGTH "${${path}}" last)
	    math(EXPR first "${first} + 1")
	    math(EXPR len "${last} - ${first}")	
	    string(SUBSTRING "${${path}}" ${first} ${len} ${path})
	endif(NOT ${test} EQUAL "")
    endif(NOT ${test} EQUAL "")
endmacro(OBJ_PATH)


## Compile d files.
## target -- name of a new target.
## objects_list -- created object files.
## params -- sources files.
macro(compile_d_files target objects_list)
    set(${objects_list})
    set(tmp_dir ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${target}.dir)
    file(MAKE_DIRECTORY ${tmp_dir})
    if(NOT SINGLE_D_OBJECT)
	foreach (d_source_p ${ARGN})
	    ## TODO: why find_file command work wrong?
	    find_file(d_source_p ${d_source_p} PATHS ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}
		  ${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR})
	    set (d_source ${d_source_p})
	    obj_path(d_source)
	    set(d_obj ${tmp_dir}/${d_source}${D_OBJECT_SUFFIX})
	    set(${objects_list} ${${objects_list}} ${d_obj})
	    get_filename_component(path ${d_obj} PATH)	    
	    file(MAKE_DIRECTORY ${path})
	    set(d_obj_out ${d_obj})
	    obj_path(d_obj_out)
	    add_custom_command(OUTPUT "${d_obj}"
		    COMMAND "${DC}"
		    ARGS ${D_FLAGS} -c ${d_source_p} -of${d_obj}
		    COMMENT "Building ${d_obj_out}"
		    DEPENDS ${d_source_p}
		    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		    )
	endforeach(d_source_p)
    else(NOT SINGLE_D_OBJECT)
	set(${objects_list} ${tmp_dir}/${target}${D_OBJECT_SUFFIX})
	set(d_obj_out ${${objects_list}})
	obj_path(d_obj_out)
	set(parameters_list_file ${tmp_dir}/parameters)
	set(parameters ${D_FLAGS} -c ${ARGN} -of${${objects_list}})
	file(REMOVE ${parameters_list_file})
	foreach(arg ${parameters})
	    file(APPEND ${parameters_list_file} "${arg}\n")
	endforeach(arg)
	add_custom_command(OUTPUT "${${objects_list}}"
		    COMMAND "${DC}"
		    ARGS @${parameters_list_file}
		    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		    DEPENDS ${ARGN}
		    COMMENT ""
		    )
    endif(NOT SINGLE_D_OBJECT)
    add_custom_target(${target} DEPENDS "${${objects_list}}")
endmacro(compile_d_files objects_list)

## Build example macro.
## name -- example name.
## Options:
##	PACKAGES -- list of packages to link to exaple (for example, QtCore QtGui QtOpenGL).
##		Default value is "QtCore QtGui".
## params -- sources d files.
## Usage:
##	build_example(ExampleName PACKAGES QtCore QtGui QtXml  main.d another_d_file.d)
macro(build_example name)
    set(is_sources)
    set(is_libs)
    set(qtd_libs ${core_lib_param} ${gui_lib_param})
    foreach(param ${ARGN})
	if(is_libs)		
	    string(REGEX REPLACE "Qt([A-Za-z0-9])" "\\1" param_package "${param}")	
	    if(${param_package} STREQUAL ${param})
		set(is_libs)
		set(is_sources 1)
	    else(${param_package} STREQUAL ${param})
		set(is_founded)
		foreach(package_big ${packages_big})
		    string(TOLOWER ${package_big} package)  		
		    if(${param_package} STREQUAL ${package_big})
			set(qtd_libs ${qtd_libs} ${${package}_lib_param})
			set(is_founded 1)
			break(package_big ${packages_big})
		    endif(${param_package} STREQUAL ${package_big})
		endforeach(package_big ${packages_big})
		if(NOT is_founded)
		      message(STATUS "Module ${param_package} not founded for example ${name}")
		      return(build_example name)
		endif(NOT is_founded)
	    endif(${param_package} STREQUAL ${param})
	endif(is_libs)
	if(NOT is_libs)
	  if(NOT is_sources)	      
	      if(${param} STREQUAL PACKAGES)
		  set(is_libs 1)
		  set(qtd_libs)
	      else(${param} STREQUAL PACKAGES)
		  set(is_sources 1)
	      endif(${param} STREQUAL PACKAGES)	      
	  endif(NOT is_sources)	
	  if(is_sources)
	      set(sources ${sources} ${param})
	  endif(is_sources)  
	endif(NOT is_libs)
    endforeach(param ${ARGN})
    compile_d_files(${name}_dobjs objects ${sources} )
    set(output ${CMAKE_CURRENT_BINARY_DIR}/${name}${CMAKE_EXECUTABLE_SUFFIX})
    set(output_native ${output})
    make_native_path(output_native)
    ## Bug fix: Reverse libs for ldc.
    if(D_IS_LLVM)
      set(qtd_libs_tmp ${qtd_libs}) 
      set(qtd_libs)
      foreach(libs ${qtd_libs_tmp})
	  set(qtd_libs ${libs} ${qtd_libs})
      endforeach(libs ${qtd_libs_tmp})
    endif(D_IS_LLVM)
    add_custom_command(OUTPUT "${output}"
		    COMMAND "${DC}"
		    ARGS ${D_FLAGS} ${libs_path} ${qtd_libs} ${objects} 
			-of${output_native}
		    DEPENDS ${objects}
		    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		    COMMENT "Building example ${name}"
		    )
    add_custom_target(example_${name} ALL DEPENDS "${output}")
    add_dependencies(example_${name} allpackages)
endmacro(build_example sources)

##--------------------------------------------
## Build library.
##--------------------------------------------
add_subdirectory(generator)
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
add_custom_target(allpackages ALL)
link_directories(${CMAKE_BINARY_DIR}/CMakeFiles)

foreach(package_big ${packages_big}) 
    string(TOLOWER ${package_big} package) 
    ## Loading settings for package.
    set(d_objs)
    set(cpp_objs)
    set(d_sources)
    set(cpp_sources)
    set(lib_name)
    set(link_cpp)
    set(link_d)
    set(cpp_files)
    set(d_files)
    set(classes)
    set(d_generated_files)
    set(link_example)
    include (${CMAKE_SOURCE_DIR}/build/${package}.txt)    

    ## Loading package sources list.
    foreach(d_source ${d_files})
	set(d_sources ${d_sources} ${CMAKE_SOURCE_DIR}/qt/${d_source}.d)
    endforeach(d_source)
    foreach(d_source ${d_generated_files})
	set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${d_source}.d)
    endforeach(d_source)
    foreach (cpp_source ${cpp_files})
	set(cpp_sources ${cpp_sources} ${CMAKE_SOURCE_DIR}/cpp/${cpp_source}.cpp)
    endforeach(cpp_source)
    set(classes ArrayOps ${classes})
    foreach(class ${classes})
	set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${package}/${class}.d)	
	set(cpp_sources ${cpp_sources} ${CMAKE_BINARY_DIR}/cpp/qt_${package}/${class}_shell.cpp) 
	add_sources_for_generating(${CMAKE_BINARY_DIR}/cpp/qt_${package}/${class}_shell.cpp)	
	add_sources_for_generating(${CMAKE_BINARY_DIR}/qt/${package}/${class}.d)
    endforeach(class)

    ## Link CPP library.
    set(lib_name ${D_LIB_PREFIX}qtd${package}${D_LIB_SUFFIX})    
    add_library(cpp_${package} SHARED ${cpp_sources})

    ## Link D library.
    compile_d_files(${package}_dobjs objects  ${d_sources})
    set(d_objs ${d_objs} ${objects}) 
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
	set_property(TARGET cpp_${package} PROPERTY RUNTIME_OUTPUT_DIRECTORY lib)
	set_property(TARGET cpp_${package} PROPERTY ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/CMakeFiles)	
	target_link_libraries(cpp_${package} ${link_cpp} )
	set(cpp_lib ${CMAKE_BINARY_DIR}/lib/libcpp_${package}.dll)
	set(cpp_lib_native ${cpp_lib})
	make_native_path(cpp_lib_native)
	set(d_implib ${CMAKE_BINARY_DIR}/CMakeFiles/${package}.dir/cpp_${package}.lib)
	set(d_implib_native ${d_implib})
	make_native_path(d_implib_native)
	add_custom_command(
			OUTPUT "${d_implib}"
			COMMAND "${IMPLIB}"
			ARGS /system /PAGESIZE:32 ${d_implib_native} ${cpp_lib_native}
			DEPENDS  "cpp_${package}"
			COMMENT "Creating implib ${lib_name}"
		    )
	add_custom_command(
			OUTPUT "${lib_name}"
			COMMAND "${DC}"
			ARGS -lib ${d_objs} ${d_implib} -oflib/${lib_name}
			DEPENDS ${d_objs} ${d_implib}
			COMMENT "Linking ${lib_name}"
		    )
    else(${CMAKE_SYSTEM_NAME} STREQUAL Linux)   
	set_property(TARGET cpp_${package} PROPERTY LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/CMakeFiles)
	foreach(cpp_source ${cpp_sources})
	    set(cpp_source ${cpp_source})
	    obj_path(cpp_source)
	    set(cpp_objs ${cpp_objs} CMakeFiles/cpp_${package}.dir/${cpp_source}.o)
	endforeach(cpp_source)	
	add_custom_command(
			OUTPUT "${lib_name}"
			COMMAND "${CMAKE_AR}"
			ARGS rcs lib/${lib_name} ${d_objs} ${cpp_objs}
			DEPENDS ${d_objs} cpp_${package}
			COMMENT "Linking ${lib_name}"
		    )
    endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows) 

    ## Dependences.
    add_dependencies(cpp_${package} dgen)
    add_custom_target(${package} DEPENDS ${lib_name})
    foreach(depend ${depends})
	add_dependencies(cpp_${package} cpp_${depend})
	add_dependencies(${package} ${depend})
    endforeach(depend ${depends})
    add_dependencies(allpackages ${package})
    set(depends ${depends} ${package})

    ## Paths for QtD libs. Needed by examples.
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows AND D_IS_MARS)
	set(libs_path ${CMAKE_BINARY_DIR}/lib/qtd${package}.lib)
	make_native_path(libs_path)
	set(${package}_lib_param -L+${libs_path})
	foreach(link ${link_example})
	    set(link ${CMAKE_SOURCE_DIR}/lib/${link}.lib)
	    make_native_path(link)
	    set(link -L+${link})
	    set(${package}_lib_param ${${package}_lib_param} ${link})
	endforeach(link ${link_example})
    else (${CMAKE_SYSTEM_NAME} STREQUAL Windows AND D_IS_MARS)
	set(${package}_lib_param -L-lqtd${package} -L-lQt${package_big})
	foreach(link ${link_example})
	    set(${package}_lib_param ${${package}_lib_param} ${link})
	endforeach(link ${link_example})
    endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows AND D_IS_MARS)

#     set(regexp_str "(${CMAKE_BINARY_DIR}|${CMAKE_SOURCE_DIR})/([A-Za-z0-9\\-_\\\\/]+)[/]+([A-Za-z0-9\\-_\\\\]+).d")
#     foreach(source ${d_sources})
# # 	find_file(source ${source} PATHS ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}
# # 		  ${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR})
# 	string(REGEX REPLACE ${regexp_str} "\\2" inc_path "${source}")
# 	string(REGEX REPLACE ${regexp_str} "\\3" file_name "${source}")
# 	set(interface_file_path ${CMAKE_BINARY_DIR}/include/${inc_path})
# 	set(interface_file "${interface_file_path}/${file_name}.di")
# 	if(NOT "${file_name}" STREQUAL "QGlobal" AND GENERATE_DI_FILES)
# 	    add_custom_command(OUTPUT "${interface_file}"
# 			COMMAND "${DC}"
# 			ARGS ${D_FLAGS} -o- -H -Hd${interface_file_path} ${source}
# 			COMMENT "Generating header for ${source}"
# 			DEPENDS ${source}
# 			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
# 			)	    
# 	else(NOT "${file_name}" STREQUAL "QGlobal" AND GENERATE_DI_FILES)
# 	    add_custom_command(OUTPUT "${interface_file}"
# 			COMMAND ${CMAKE_COMMAND} -E make_directory ${interface_file_path}
# 			COMMAND ${CMAKE_COMMAND} -E remove -f ${interface_file}
# 			COMMAND ${CMAKE_COMMAND} -E copy ${source} ${interface_file}
# 			COMMENT ""
# 			DEPENDS ${source}
# 			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
# 			)	    
# 	endif(NOT "${file_name}" STREQUAL "QGlobal" AND GENERATE_DI_FILES)
# 	set(interfaces_list ${interfaces_list} ${interface_file_path}/${file_name}.di)
#     endforeach(source)
 endforeach(package_big ${packages_big}) 
# add_custom_target(generate_headers DEPENDS ${interfaces_list})

##--------------------------------------------
## Build other parts of the QtD.
##--------------------------------------------
if(BUILD_EXAMPLES)
    add_subdirectory(demos)
    add_subdirectory(examples)
endif(BUILD_EXAMPLES)