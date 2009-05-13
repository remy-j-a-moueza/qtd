cmake_minimum_required(VERSION 2.6)
PROJECT(qtd CXX C)
FIND_PACKAGE(Qt4 REQUIRED)

include_directories(${QT_INCLUDES} include)

option(BUILD_QT_OPENGL "Build QtOpenGL" "ON")
option(BUILD_EXAMPLES "Build examples" "ON")

set(PACKAGES Core Gui)
if(BUILD_QT_OPENGL)
    set(PACKAGES ${PACKAGES} OpenGL)
endif(BUILD_QT_OPENGL)

set(packages_big ${PACKAGES})
set(packages)
foreach(package ${packages_big})
    string(TOLOWER ${package} package)
    set(packages ${packages} ${package})
endforeach(package ${packages_big})

#set(CMAKE_LIBRARY_OUTPUT_DIRECTORY CMakeFiles)

find_program(DC dmd ldc)
## Parsing D compiler version.
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

# Check D compiler version
if(D_VERSION EQUAL "1")
    if (D_FRONTEND LESS "041")
	message(STATUS "Minimum required version of D compiler is 1.041 (or compiler based on this version)")
    endif(D_FRONTEND LESS "041")
    set(D_TARGET d1-tango)
elseif(D_VERSION EQUAL "2")
    set(D_TARGET ) ## TODO: hm... I don`t known this parameter for D2 ^(
endif(D_VERSION EQUAL "1")

if(D_IS_MARS)
    set(SEPARETLY_D_OBJECTS true)
elseif(D_IS_LLVM)
    set(SEPARETLY_D_OBJECTS true)
endif(D_IS_MARS)

# Debug and release flags.
if (${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])
   #set(CMAKE_BUILD_TYPE Debug)
   #set( SUFFIXLIB "${SUFFIXLIB}-debug" )
   #set( SUFFIXBIN "${SUFFIXBIN}-debug" )
   add_definitions(-DDEBUG)
   set(D_FLAGS -g -gc -debug)
else (${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])
   #set(CMAKE_BUILD_TYPE Release)
    add_definitions(-UNO_DEBUG)
    set(D_FLAGS -O -release -inline)
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
      set(D_FLAGS ${D_FLAGS} -L/subsystem:windows)
    endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows)   
endif (${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])  
set(D_FLAGS ${D_FLAGS} -I${CMAKE_BINARY_DIR} -I${CMAKE_SOURCE_DIR})

MACRO(MAKE_WINDOWS_PATH pathname)
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
	# An extra \\ escape is necessary to get a \ through CMake's processing.
	STRING(REPLACE "/" "\\" ${pathname} "${${pathname}}")
	# Enclose with UNESCAPED quotes.  This means we need to escape our
	# quotes once here, i.e. with \"
	SET(${pathname} \"${${pathname}}\")
    endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows) 
ENDMACRO(MAKE_WINDOWS_PATH)

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
elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux) 
    set(D_LIB_SUFFIX .a)
    set(D_LIB_PREFIX lib)
    set(D_OBJECT_SUFFIX .o)
endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows) 

set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} ./)
set(GEN_OPT ${GEN_OPT} --d-target=${D_TARGET})

add_subdirectory(generator)

macro(OBJ_PATH path)
    unset(test)
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

macro(compile_d_files target objects_list)
    unset(${objects_list})
    set(tmp_dir ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${target}.dir)
    file(MAKE_DIRECTORY ${tmp_dir})
    if(${SEPARETLY_D_OBJECTS})
	foreach (d_source ${ARGN})
	    OBJ_PATH(d_source)
	    set(d_obj ${tmp_dir}/${d_source}${D_OBJECT_SUFFIX})
	    set(${objects_list} ${${objects_list} ${d_obj})
	    get_filename_component(path ${d_obj} PATH)	    
	    file(MAKE_DIRECTORY ${path})
	    set(d_obj_out ${d_obj})
	    OBJ_PATH(d_obj_out)
	    add_custom_command(OUTPUT "${d_obj}"
		    COMMAND "${DC}"
		    ARGS ${D_FLAGS} -c ${d_source} -of${d_obj}
		    COMMENT "Building ${d_obj_out}"
		    DEPENDS ${d_source}
		    )
	endforeach(d_source)
    else(${SEPARETLY_D_OBJECTS})
	set(${objects_list} ${tmp_dir}/${target}${D_OBJECT_SUFFIX})
	set(d_obj_out ${${objects_list}})
	OBJ_PATH(d_obj_out)
	set(parameters_list_file ${tmp_dir}/parameters)
	SET (parameters ${D_FLAGS} -c ${ARGN} -of${${objects_list}})
	FILE (REMOVE ${parameters_list_file})
	FOREACH(arg ${parameters})
	    FILE (APPEND ${parameters_list_file} "${arg}\n")
	ENDFOREACH(arg)
	add_custom_command(OUTPUT "${${objects_list}}"
		    COMMAND "${DC}"
		    ARGS @${parameters_list_file}
		    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		    DEPENDS ${ARGN}
		    COMMENT ""
		    )
    endif(${SEPARETLY_D_OBJECTS})
endmacro(compile_d_files objects_list)

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
add_custom_target(allpackages ALL)

link_directories(${CMAKE_BINARY_DIR}/CMakeFiles)

foreach(package ${packages})    
    unset(d_objs)
    unset(cpp_objs)
    unset(d_sources)
    unset(cpp_sources)
    unset(lib_name)
    unset(link_cpp)
    unset(link_d)
    unset(cpp_files)
    unset(d_files)
    unset(classes)
    unset(d_generated_files)
   
    include (${CMAKE_SOURCE_DIR}/build/${package}.txt)    

    set(${package}_link_example "${link_example}")
    set(${link_example} "")

    set(CUR_TMP_PATH CMakeFiles/${package}.dir)  
    
    set(classes ArrayOps ${classes})
    foreach(class ${classes})
	set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${package}/${class}.d)	
	set(cpp_sources ${cpp_sources} ${CMAKE_BINARY_DIR}/cpp/qt_${package}/${class}_shell.cpp)	
    endforeach(class)
    add_sources_for_generating(${cpp_sources})
    
    foreach(d_source ${d_files})
	set(d_sources ${d_sources} ${CMAKE_SOURCE_DIR}/qt/${d_source}.d)
    endforeach(d_source)
    foreach(d_source ${d_generated_files})
	set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${d_source}.d)
    endforeach(d_source)
    foreach (cpp_source ${cpp_files})
	set(cpp_sources ${cpp_sources} ${CMAKE_SOURCE_DIR}/cpp/${cpp_source}.cpp)
    endforeach(cpp_source)
    
    compile_d_files(${package}_dobjs objects  ${d_sources})
    set(d_objs ${d_objs} ${objects}) 
    
    set(lib_name ${D_LIB_PREFIX}qtd${package}${D_LIB_SUFFIX})
    
    add_library(cpp_${package} SHARED ${cpp_sources})
    add_dependencies(cpp_${package} dgen)
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
	set_property(TARGET cpp_${package} PROPERTY RUNTIME_OUTPUT_DIRECTORY lib)
	set_property(TARGET cpp_${package} PROPERTY ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/CMakeFiles)	
	ADD_CUSTOM_COMMAND(
	      TARGET cpp_${package}
	      POST_BUILD
	      COMMAND ${CMAKE_COMMAND} -E remove
		      ${CMAKE_BINARY_DIR}/CMakeFiles/${CMAKE_IMPORT_LIBRARY_PREFIX}cpp${package}${CMAKE_IMPORT_LIBRARY_SUFFIX}
	      COMMAND ${CMAKE_COMMAND} -E copy 
		      ${CMAKE_BINARY_DIR}/CMakeFiles/${CMAKE_IMPORT_LIBRARY_PREFIX}cpp_${package}.dll${CMAKE_IMPORT_LIBRARY_SUFFIX}
		      ${CMAKE_BINARY_DIR}/CMakeFiles/${CMAKE_IMPORT_LIBRARY_PREFIX}cpp${package}${CMAKE_IMPORT_LIBRARY_SUFFIX}
	)

	target_link_libraries(cpp_${package} ${link_cpp} )
	set(cpp_lib ${CMAKE_BINARY_DIR}/lib/libcpp_${package}.dll)
	set(cpp_lib_native ${cpp_lib})
	MAKE_WINDOWS_PATH(cpp_lib_native)
	set(d_implib ${CMAKE_BINARY_DIR}/CMakeFiles/${package}.dir/cpp_${package}.lib)
	set(d_implib_native ${d_implib})
	MAKE_WINDOWS_PATH(d_implib_native)	
	set(cpp_${package}_implib cpp${package})
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
	    OBJ_PATH(cpp_source)
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
    add_custom_target(${package} DEPENDS ${lib_name})
    foreach(depend ${depends})
	add_dependencies(cpp_${package} cpp_${depend})
	add_dependencies(${package} ${depend})
    endforeach(depend ${depends})
    add_dependencies(allpackages ${package})
    set(depends ${depends} ${package})
endforeach(package)

foreach(package_big ${packages_big})
    string(TOLOWER ${package_big} package)  
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows AND D_IS_MARS)
	set(libs_path ${CMAKE_BINARY_DIR}/lib/qtd${package}.lib)
	MAKE_WINDOWS_PATH(libs_path)
	set(${package}_lib_param -L+${libs_path})
	foreach(link ${${package}_link_example})
	    set(link ${CMAKE_SOURCE_DIR}/lib/${link}.lib)
	    MAKE_WINDOWS_PATH(link)
	    set(link -L+${link})
	    set(${package}_lib_param ${${package}_lib_param} ${link})
	endforeach(link ${link_example})
    else (${CMAKE_SYSTEM_NAME} STREQUAL Windows AND D_IS_MARS)
	set(${package}_lib_param -L-lqtd${package} -L-lQt${package_big})
	foreach(link ${link_example})
	    set(${package}_lib_param ${${package}_lib_param} ${link})
	endforeach(link ${link_example})
    endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows AND D_IS_MARS)
endforeach(package_big ${packages_big})

macro(build_example name)
    unset(is_sources)
    unset(is_libs)
    set(qtd_libs ${core_lib_param} ${gui_lib_param})
    foreach(param ${ARGN})
	if(is_libs)		
	    string(REGEX REPLACE "Qt([A-Za-z0-9])" "\\1" param_package "${param}")	
	    if(${param_package} STREQUAL ${param})
		unset(is_libs)
		set(is_sources 1)
	    else(${param_package} STREQUAL ${param})
		unset(is_founded)
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
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows AND D_IS_MARS)
	set(libs_path )
    else(${CMAKE_SYSTEM_NAME} STREQUAL Windows AND D_IS_MARS)
	set(libs_path -L-L${CMAKE_BINARY_DIR}/lib)
    endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows AND D_IS_MARS)
    compile_d_files(${name}_dobjs objects ${sources} )
    set(output ${CMAKE_CURRENT_BINARY_DIR}/${name}${CMAKE_EXECUTABLE_SUFFIX})
    set(output_native ${output})
    make_windows_path(output_native)
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

if(BUILD_QT_OPENGL)
    add_subdirectory(demos)
    add_subdirectory(examples)
endif(BUILD_QT_OPENGL)