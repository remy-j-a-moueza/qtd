cmake_minimum_required(VERSION 2.6)
PROJECT(qtd CXX C)
FIND_PACKAGE(Qt4 REQUIRED)

##--------------------------------------------
## Settings.
##--------------------------------------------

include_directories(${QT_INCLUDES} include ${CMAKE_CURRENT_BINARY_DIR}/include)

## Options.
option(BUILD_EXAMPLES "Build examples" "ON")
option(BUILD_TOOLS "Build tools" "ON")
option(GENERATE_DI_FILES "Generate *.di files with DC -H command" "OFF")

set(all_packages Core Gui OpenGL Xml Svg Network WebKit) ## TODO: Loading.


## Strip utility.
find_program(STRIP strip)

## Find D compiler and parsing its version.

find_program(DC dmd ldc)
if (DC)   
    get_filename_component(dc_path ${DC} PATH)
    if("${dc_path}" STREQUAL ${CMAKE_BINARY_DIR})
	get_filename_component(DC ${DC} NAME)
    endif("${dc_path}" STREQUAL ${CMAKE_BINARY_DIR})
    exec_program(${DC} ARGS "" OUTPUT_VARIABLE d_output)   
    string(REGEX MATCH "Digital Mars D Compiler v[0-9]\\.[0-9]+" dmd_version "${d_output}")
    if (dmd_version)
	set(D_IS_MARS true)
	set(D_IS_DMD true)
	set(D_COMPILER_NAME "Digital Mars D Compiler")
	string(REGEX REPLACE "Digital Mars D Compiler v([0-9])\\.[0-9]+" "\\1" D_VERSION "${dmd_version}")
	string(REGEX REPLACE "Digital Mars D Compiler v[0-9]\\.([0-9]+)" "\\1" D_FRONTEND "${dmd_version}")    
    else (dmd_version)
	string(REGEX MATCH "LLVM-based D Compiler" is_ldc "${d_output}")   
	if (is_ldc)
	    exec_program(${DC} ARGS "--version" OUTPUT_VARIABLE d_output)
	    string(REGEX MATCH "based on DMD v[0-9]\\.[0-9]+" ldc_version "${d_output}")
	    set(D_IS_LLVM true)
	    set(D_IS_LDC true)
	    if(ldc_version)
		set(D_IS_LLVM true)
		set(D_COMPILER_NAME "LLVM-based D Compiler")
		string(REGEX REPLACE "based on DMD v([0-9])\\.[0-9]+" "\\1" D_VERSION "${ldc_version}")
		string(REGEX REPLACE "based on DMD v[0-9]\\.([0-9]+)" "\\1" D_FRONTEND "${ldc_version}")	    
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

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OR "${CMAKE_INSTALL_PREFIX}" STREQUAL "")
    get_filename_component(dc_path ${DC} PATH)
    if("${dc_path}" STREQUAL "")
	find_program(dc_path_tmp ${DC})
	get_filename_component(dc_path ${dc_path_tmp} PATH)
	mark_as_advanced(dc_path_tmp)
    endif("${dc_path}" STREQUAL "")
    get_filename_component(dc_parent_dir ${dc_path} NAME)
    if("${dc_parent_dir}" STREQUAL "bin")    	
	get_filename_component(dc_path ${dc_path} PATH)
    endif("${dc_parent_dir}" STREQUAL "bin")
    set(CMAKE_INSTALL_PREFIX
	${dc_path} CACHE PATH "QtD install prefix" FORCE
    )
endif(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OR "${CMAKE_INSTALL_PREFIX}" STREQUAL "")


if(D_IS_MARS)
    option(SINGLE_D_OBJECT "Build all d sources to one object file" "ON")
elseif(D_IS_LLVM)
    option(SINGLE_D_OBJECT "Build all d sources to one object file" "OFF")
    if(SINGLE_D_OBJECT)
	message(STATUS "LDC not support build multiple source files in one .obj file")
	set(SINGLE_D_OBJECT "OFF") 
	#set(D_FLAGS ${D_FLAGS} -singleobj)
    endif(SINGLE_D_OBJECT)
endif(D_IS_MARS)

# Check D compiler version
if(D_VERSION EQUAL "1")
    if (D_FRONTEND LESS "041")
	message(STATUS "Minimum required version of D compiler is 1.041 (or compiler based on this version)")
    endif(D_FRONTEND LESS "041")
    set(D_TARGET d1-tango)   
elseif(D_VERSION EQUAL "2")
    set(D_TARGET ) ## TODO: hm... I don`t known this parameter for D2 ^(
endif(D_VERSION EQUAL "1")
set(D_FLAGS ${D_FLAGS} -I${CMAKE_SOURCE_DIR}/qt/d${D_VERSION})

# Debug and release flags.
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif (NOT CMAKE_BUILD_TYPE)
if(${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])
    set(CMAKE_BUILD_TYPE Debug)
    #set( SUFFIXLIB "${SUFFIXLIB}-debug" )
    #set( SUFFIXBIN "${SUFFIXBIN}-debug" )
    add_definitions(-DDEBUG)
    set(D_FLAGS ${D_FLAGS} -g -gc -debug)
elseif (NOT ${CMAKE_BUILD_TYPE} MATCHES [rR][eE][lL][eE][aA][sS])
    message(STATUS "Only debug and release configuration are now supproted. Configuration changed to 'Release'")
    set(CMAKE_BUILD_TYPE Release)
endif (${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])  
if (${CMAKE_BUILD_TYPE} MATCHES [rR][eE][lL][eE][aA][sS])
    #add_definitions(-UNO_DEBUG)
    set(D_FLAGS ${D_FLAGS} -O -release -inline)
    if(D_IS_MARS)
	set(D_FLAGS ${D_FLAGS} -inline)
    elseif(D_IS_LLVM)
	set(D_FLAGS ${D_FLAGS} -enable-inlining)	
    endif(D_IS_MARS)
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
      set(D_FLAGS ${D_FLAGS} -L/subsystem:windows)
    endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows)   
endif(${CMAKE_BUILD_TYPE} MATCHES [rR][eE][lL][eE][aA][sS] )

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

## Bootstrap settings for tools.
set(DRCC ${CMAKE_BINARY_DIR}/tools/drcc/drcc)

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

##
## Example:
##	set(path 24.3+23.bin)
##	obj_path(path)
##	message(STATUS ${path})
## Example output:
##	-- 24\.3\+23\.bin
macro(regex_safe_string outvariable)
    set(${outvariable} ${ARGN})
    set(__regex_chars__ ^ $ . ] [ - * + ? | \( \))
    foreach(__regex_char__ ${__regex_chars__})
	string(REPLACE "${__regex_char__}"
	    "\\${__regex_char__}" ${outvariable} ${${outvariable}}
	    )
    endforeach(__regex_char__ ${__regex_chars__})
endmacro(regex_safe_string outvariable)

## Remove unnecessary path to the object file.
## path -- path to object file.
## Example:
##	set(path ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/target.dir/main.d.obj)
##	obj_path(path)
##	message(STATUS ${path})
## Example output:
##	-- CMakeFiles/target.dir/main.d.obj
macro(OBJ_PATH path)
    regex_safe_string(__cbd_safe__ ${CMAKE_CURRENT_BINARY_DIR})
    regex_safe_string(__csd_safe__ ${CMAKE_CURRENT_SOURCE_DIR})
    set(regexp_str "(${__cbd_safe__}/|${__csd_safe__}/|)(.+)")
    string(REGEX REPLACE ${regexp_str} "\\2" ${path} "${${path}}") 
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
	set(parameters ${D_FLAGS} -c ${ARGN} -of${${objects_list}})
	set(parameters_list_file ${tmp_dir}/parameters)
	if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)	
	    file(REMOVE ${parameters_list_file})
	    foreach(arg ${parameters})
		file(APPEND ${parameters_list_file} "${arg}\n")
	    endforeach(arg)
	    set(param @${parameters_list_file})
	elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux)
	    set(param ${parameters})
	endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
	add_custom_command(OUTPUT "${${objects_list}}"
		    COMMAND "${DC}"
		    ARGS ${param}
		    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		    DEPENDS ${ARGN}
		    COMMENT ""
		    )
    endif(NOT SINGLE_D_OBJECT)
    add_custom_target(${target} DEPENDS "${${objects_list}}")
endmacro(compile_d_files objects_list)

macro(qtd_add_resource name output)
    set(${output})
    foreach(res "${ARGN}")
	## Test input file exists.
	get_filename_component(res_path ${res} PATH)
	get_filename_component(res_name ${res} NAME_WE)
	get_filename_component(res_ext ${res} EXT)
	#if(NOT ${req_ext} STREQUAL "qrc")	
	#    get_filename_component(res_name ${res} NAME_WE)
	#endif(NOT ${req_ext} STREQUAL "qrc")
	set(out ${CMAKE_CURRENT_BINARY_DIR}/${res_path}qrc_${res_name}.d)
	add_custom_command(OUTPUT "${out}"
		    COMMAND "${DRCC}"
		    ARGS  -name ${name} ${res} -o ${out} 
		    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		    DEPENDS ${res}
		    COMMENT "Compile QtD resource ${res}"
		    )
	set(${output} ${${output}} ${out})
    endforeach(res "${ARGN}") 
endmacro(qtd_add_resource output)

## Build example macro.
## name -- example name.
## Options:
##	PACKAGES -- list of packages to link to exaple (for example, QtCore QtGui QtOpenGL).
##		Default value is "QtCore QtGui".
## params -- sources d files.
## Usage:
##	build_example(ExampleName PACKAGES QtCore QtGui QtXml  main.d another_d_file.d)
macro(build_example name)
    set(qtd_libs ${core_lib_param} ${gui_lib_param})
    set(type_dat SOURCES)
    set(RESOURCES)
    set(SOURCES)
    set(PACKAGES)
    ## Parse parameters list.
    set(params_dat RESOURCES SOURCES PACKAGES)
    foreach(arg_dat ${ARGN})
	set(founded_type_dat)
	foreach(param_dat ${params_dat})
	    if(${arg_dat} STREQUAL ${param_dat})		
		set(type_dat ${param_dat})
		set(founded_type_dat 1)
		break(${arg_dat} STREQUAL ${param_dat})
	    endif(${arg_dat} STREQUAL ${param_dat})
	endforeach(param_dat ${params_dat})	
	if(NOT founded_type_dat)
	    set(${type_dat} ${${type_dat}} ${arg_dat})
	endif(NOT founded_type_dat)
    endforeach(arg_dat ${ARGN})
    if(NOT PACKAGES)
	set(PACKAGES QtCore QtGui)
    endif(NOT PACKAGES)
    ## TODO: Tools building is acitve???    
    if(RESOURCES)
	if(NOT BUILD_TOOLS)
	    message(STATUS "Example '${name}' required drcc. Example will not build")
	    return(build_example name)
	endif(NOT BUILD_TOOLS)
	qtd_add_resource(${name} res_sources ${RESOURCES})
    endif(RESOURCES)
    compile_d_files(${name}_dobjs objects ${SOURCES} ${res_sources})
    set(output ${CMAKE_CURRENT_BINARY_DIR}/${name}${CMAKE_EXECUTABLE_SUFFIX})
    set(output_native ${output})
    make_native_path(output_native)
    foreach(package ${PACKAGES})
	string(REGEX REPLACE "Qt([A-Za-z0-9])" "\\1" req "${package}")
	set(is_founded)
	foreach(package_big ${packages_big})
	    string(TOLOWER ${package_big} package)  		
	    if(${req} STREQUAL ${package_big})		
		set(is_founded 1)
		break(package_big ${packages_big})
	    endif(${req} STREQUAL ${package_big})
	endforeach(package_big ${packages_big})
	if(NOT is_founded)
	      message(STATUS "Example '${name}' required package '${req}', but its not active. Example will not build")
	      return(build_example name)
	else(NOT is_founded)
	      set(qtd_libs ${${package}_lib_param} ${qtd_libs})
	endif(NOT is_founded)	
    endforeach(package ${PACKAGES})
    add_custom_command(OUTPUT "${output}"
		    COMMAND "${DC}"
		    ARGS ${D_FLAGS} ${libs_path} ${qtd_libs} ${objects} 
			-of${output_native}
		    DEPENDS ${objects}
		    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		    COMMENT "Building example ${name}"
		    )
    add_custom_target(example_${name} ALL DEPENDS "${output}")
    ## TODO: Enable on windows too.
    if(STRIP AND ${CMAKE_BUILD_TYPE} EQUAL "Release" AND ${CMAKE_SYSTEM_NAME} STREQUAL Linux) ##
	add_custom_command(TARGET example_${name} POST_BUILD COMMAND "${STRIP}" ARGS "${output}")
    endif(STRIP AND ${CMAKE_BUILD_TYPE} EQUAL "Release" AND ${CMAKE_SYSTEM_NAME} STREQUAL Linux)
    add_dependencies(example_${name} allpackages)
endmacro(build_example sources)

##--------------------------------------------
## Build and install library.
##--------------------------------------------

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
add_custom_target(allpackages)
link_directories(${CMAKE_BINARY_DIR}/CMakeFiles)

foreach(package_big ${all_packages})
    string(TOLOWER ${package_big} package) 
    ## Loading settings for package.
    set(required)
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
    set(d_version_files)
    set(link_example)
    include (${CMAKE_SOURCE_DIR}/build/${package}.txt)    

    set(all_req_found 1)
    string(TOUPPER ${package} package_upper)
    option(BUILD_QT_${package_upper} "Build Qt${package_big}" "ON")
    if(BUILD_QT_${package_upper})
	foreach(req ${required})
	    set(req_found)
	    foreach(pack ${packages_big})
		if(${pack} STREQUAL ${req})
		    set(req_found 1)
		endif(${pack} STREQUAL ${req})
	    endforeach(pack ${packages})	
	    if(NOT req_found)
		set(req_found)
		foreach(pack ${all_packages})
		    if(${pack} STREQUAL ${req})
			set(req_found 1)
		    endif(${pack} STREQUAL ${req})
		endforeach(pack ${all_packages})
		if(req_found)
		    message(STATUS "Package '${package_big}' required '${req}', but its not active")
		else(req_found)
		    message(STATUS "Package '${package_big}' required '${req}', but its not found")
		endif(req_found)
		set(all_req_found)
	    endif(NOT req_found)
	endforeach(req ${required})
    else(BUILD_QT_${package_upper})
	set(all_req_found)
    endif(BUILD_QT_${package_upper})
    
    ## TODO: cleanup. 
    if("${all_req_found}" EQUAL 1)
	set(packages_big ${packages_big} ${package_big})
	set(packages ${packages} ${package})
	## Loading package sources list.
	foreach(d_source ${d_version_files})
	    set(d_sources ${d_sources} ${CMAKE_SOURCE_DIR}/qt/d${D_VERSION}/qt/${d_source}.d)
	    if(NOT GENERATE_DI_FILES)
		get_filename_component(path ${d_source}.d PATH)
		get_filename_component(name ${d_source}.d NAME_WE)
		install(FILES ${CMAKE_SOURCE_DIR}/qt/d${D_VERSION}/qt/${d_source}.d COMPONENT qtd DESTINATION include/d/qt/${path} RENAME ${name}.di)
		install(FILES ${CMAKE_SOURCE_DIR}/qt/d${D_VERSION}/qt/${d_source}_enum.d COMPONENT qtd DESTINATION include/d/qt/${path} RENAME ${name}_enum.di OPTIONAL)
	    endif(NOT GENERATE_DI_FILES)
	endforeach(d_source)
	foreach(d_source ${d_files})
	    set(d_sources ${d_sources} ${CMAKE_SOURCE_DIR}/qt/${d_source}.d)
	    if(NOT GENERATE_DI_FILES)
		get_filename_component(path ${d_source}.d PATH)
		get_filename_component(name ${d_source}.d NAME_WE)
		install(FILES ${CMAKE_SOURCE_DIR}/qt/${d_source}.d DESTINATION include/d/qt/${path} COMPONENT qtd RENAME ${name}.di)
		install(FILES ${CMAKE_SOURCE_DIR}/qt/${d_source}_enum.d DESTINATION include/d/qt/${path} COMPONENT qtd RENAME ${name}_enum.di OPTIONAL)
	    endif(NOT GENERATE_DI_FILES)
	endforeach(d_source)
	foreach(d_source ${d_generated_files})
	    set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${d_source}.d)
	    if(NOT GENERATE_DI_FILES)
		get_filename_component(path ${d_source}.d PATH)
		get_filename_component(name ${d_source}.d NAME_WE)
		install(FILES ${CMAKE_BINARY_DIR}/qt/${d_source}.d DESTINATION include/d/qt/${path} COMPONENT qtd RENAME ${name}.di)
		install(FILES ${CMAKE_BINARY_DIR}/qt/${d_source}_enum.d DESTINATION include/d/qt/${path} COMPONENT qtd RENAME ${name}_enum.di OPTIONAL)
	    endif(NOT GENERATE_DI_FILES)
	endforeach(d_source)
	foreach (cpp_source ${cpp_files})
	    set(cpp_sources ${cpp_sources} ${CMAKE_SOURCE_DIR}/cpp/${cpp_source}.cpp)
	endforeach(cpp_source)
	set(classes ArrayOps ${classes})
	foreach(class ${classes})
	    set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${package}/${class}.d)	
	    set(cpp_sources ${cpp_sources} ${CMAKE_BINARY_DIR}/cpp/qt_${package}/${class}_shell.cpp) 
	    set(files_for_gen ${files_for_gen} ${CMAKE_BINARY_DIR}/cpp/qt_${package}/${class}_shell.cpp
		  ${CMAKE_BINARY_DIR}/qt/${package}/${class}.d)
	    if(NOT GENERATE_DI_FILES)
		install(FILES ${CMAKE_BINARY_DIR}/qt/${package}/${class}.d DESTINATION include/d/qt/${package} COMPONENT qtd RENAME ${class}.di)
		install(FILES ${CMAKE_BINARY_DIR}/qt/${package}/${class}_enum.d DESTINATION include/d/qt/${package} COMPONENT qtd RENAME ${class}_enum.di OPTIONAL)
	    endif(NOT GENERATE_DI_FILES)
	endforeach(class)

	## Link CPP library.
	add_library(cpp_${package} SHARED ${cpp_sources})

	## Link D library.
	set(lib_name ${D_LIB_PREFIX}qtd${package}${D_LIB_SUFFIX})    
	set(lib lib/${lib_name})  
	compile_d_files(${package}_dobjs objects  ${d_sources})
	set(d_objs ${d_objs} ${objects}) 
	if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
	    set_property(TARGET cpp_${package} PROPERTY RUNTIME_OUTPUT_DIRECTORY lib)
	    set_property(TARGET cpp_${package} PROPERTY ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/CMakeFiles)	
	    foreach(req ${required})
		set(is_found)
		foreach(pack ${packages_big})
		    if("${pack}" STREQUAL "${req}")
			set(is_found 1)
			break(pack ${packages_big})
		    endif("${pack}" STREQUAL "${req}")
		endforeach(pack ${packages_big})
		if(NOT is_found)
		    message(FATAL_ERROR "Package ${package_big} required ${req}, but its not found")
		endif(NOT is_found)
		string(TOUPPER ${req} req_upper)
		string(TOLOWER ${req} req_lower)
		set(link_cpp ${link_cpp} cpp_${req_lower} ${QT_QT${req_upper}_LIBRARY})
	    endforeach(req ${require})
	    string(TOUPPER ${package} package_upper)
	    set(link_cpp ${link_cpp} ${QT_QT${package_upper}_LIBRARY})
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
			    OUTPUT "${lib}"
			    COMMAND "${DC}"
			    ARGS -lib ${d_objs} ${d_implib} -of${lib}
			    DEPENDS ${d_objs} ${d_implib}
			    COMMENT "Linking ${lib_name}"
			)
	    install(FILES ${cpp_lib} COMPONENT qtd DESTINATION lib)
	else(${CMAKE_SYSTEM_NAME} STREQUAL Linux)   
	    set_property(TARGET cpp_${package} PROPERTY LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/CMakeFiles)
	    foreach(cpp_source ${cpp_sources})
		set(cpp_source ${cpp_source})
		obj_path(cpp_source)
		set(cpp_objs ${cpp_objs} CMakeFiles/cpp_${package}.dir/${cpp_source}${CMAKE_CXX_OUTPUT_EXTENSION})
	    endforeach(cpp_source)
	    add_custom_command(
			    OUTPUT "${lib}"
			    COMMAND "${CMAKE_AR}"
			    ARGS rcs ${lib} ${d_objs} ${cpp_objs}
			    DEPENDS ${d_objs} cpp_${package}
			    COMMENT "Linking ${lib_name}"
			)
	endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows) 
	install(FILES ${CMAKE_BINARY_DIR}/${lib} COMPONENT qtd DESTINATION lib)

	## Dependences.
	add_custom_target(${package} DEPENDS ${lib})
	foreach(depend ${required})
	    string(TOLOWER ${depend} depend)
	    add_dependencies(cpp_${package} cpp_${depend})
	    add_dependencies(${package} ${depend})
	endforeach(depend ${required})
	add_dependencies(allpackages ${package})

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

	if(GENERATE_DI_FILES)
	  regexseafestring(cbd_safe ${CMAKE_BINARY_DIR})
	  regexseafestring(csd_safe ${CMAKE_SOURCE_DIR})
	  set(regexp_str "(${csd}/qt/d${D_VERSION}|${csd_safe}|${cbd_safe})/([A-Za-z0-9\\-_\\\\/]+)[/]+([A-Za-z0-9\\-_\\\\]+).d")
	  foreach(source ${d_sources})
      # 	find_file(source ${source} PATHS ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}
      # 		  ${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR})
	      string(REGEX REPLACE ${regexp_str} "\\2" inc_path "${source}")
	      string(REGEX REPLACE ${regexp_str} "\\3" file_name "${source}")
	      set(interface_file_path ${CMAKE_BINARY_DIR}/d/${inc_path})
	      set(interface_file "${interface_file_path}/${file_name}.di")
	      if(NOT "${file_name}" STREQUAL "QGlobal")
		  add_custom_command(OUTPUT "${interface_file}"
			      COMMAND "${DC}"
			      ARGS ${D_FLAGS} -o- -H -Hd${interface_file_path} ${source}
			      COMMENT "Generating header for ${source}"
			      DEPENDS ${source}
			      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			      )		   
	      else(NOT "${file_name}" STREQUAL "QGlobal") ## DMD frontend crash on this file.
		  add_custom_command(OUTPUT "${interface_file}"
			      COMMAND ${CMAKE_COMMAND} -E make_directory ${interface_file_path}
			      COMMAND ${CMAKE_COMMAND} -E remove -f ${interface_file}
			      COMMAND ${CMAKE_COMMAND} -E copy ${source} ${interface_file}
			      COMMENT ""
			      DEPENDS ${source}
			      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			      )	    
	      endif(NOT "${file_name}" STREQUAL "QGlobal" AND GENERATE_DI_FILES)
	      set(interfaces_list ${interfaces_list} ${interface_file_path}/${file_name}.di) 
	      install(FILES ${interface_file} COMPONENT qtd DESTINATION include/d/${inc_path})
	  endforeach(source)
	endif(GENERATE_DI_FILES)
    endif("${all_req_found}" EQUAL 1)
endforeach(package_big ${packages_big})
if(GENERATE_DI_FILES) 
    add_custom_target(generate_headers ALL DEPENDS ${interfaces_list})
endif(GENERATE_DI_FILES)

add_subdirectory(generator)
## Dependences.
foreach(package ${packages})
    add_dependencies(cpp_${package} dgen)
endforeach(package ${packages})
add_sources_for_generating(${files_for_gen})	

set(CPACK_COMPONENTS_ALL qtd)


##--------------------------------------------
## Build other parts of the QtD.
##--------------------------------------------
add_custom_target(tools ALL)
if(BUILD_TOOLS)
    add_subdirectory(tools)
    add_dependencies(tools drcc duic)
endif(BUILD_TOOLS)

if(BUILD_EXAMPLES)
    add_subdirectory(demos)
    add_subdirectory(examples)
endif(BUILD_EXAMPLES)



##--------------------------------------------
## CPack.
##--------------------------------------------
set(CPACK_PACKAGE_VERSION_PATCH 1)
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "QtD is a D binding to the Qt application and UI framework. 
QtD is a D binding to the Qt application and UI framework. 
This package installs binding and static library for qt port on D programming language.
")
#SET(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/ReadMe.txt")
SET(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/license.txt")
set(CPACK_PACKAGE_VENDOR "QtD team")
set(CPACK_PACKAGE_CONTACT "e@mail.ru" )
SET(CPACK_PACKAGE_VERSION "0.1")
#set(CPACK_PACKAGE_VERSION_PATCH "${RFS_VERSION_BUILD}")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "qtd ${CPACK_PACKAGE_VERSION}")
set(CPACK_PACKAGE_FILE_NAME "qtd-${CPACK_PACKAGE_VERSION}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "qtd-${CPACK_PACKAGE_VERSION}")
if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
    set(CPACK_GENERATOR "ZIP")
elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux)
    set(CPACK_GENERATOR "TBZ2;DEB;RPM")
endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
include(CPack)