cmake_minimum_required(VERSION 2.6)
PROJECT(qtd CXX C)
FIND_PACKAGE(Qt4 REQUIRED)
set (QT_USE_QTMAIN false)
set (QT_USE_QTGUI false)

##--------------------------------------------
## Settings.
##--------------------------------------------

include_directories(${QT_INCLUDES} include ${CMAKE_CURRENT_BINARY_DIR}/include)

## Options.
option(BUILD_EXAMPLES "Build examples" "OFF")
option(BUILD_SHARED_LIBRARIES "Build shared library (very experemental and only for ldc)" "OFF")
option(BUILD_TOOLS "Build tools" "ON")
#option(GENERATE_DI_FILES "Generate *.di files with DC -H command" "OFF")
set(GENERATE_DI_FILES OFF) ## Very experemental option. Temporary disabled.

set(QTD_VERSION_STR ${QT_VERSION_MAJOR}.${QT_VERSION_MINOR}.${QT_VERSION_PATCH})
math(EXPR QTD_VERSION "(${QT_VERSION_MAJOR} << 16) + (${QT_VERSION_MINOR} << 8) + ${QT_VERSION_PATCH}")

set(all_packages Core Gui OpenGL Xml Svg Network WebKit) 

## Init D toolkit.
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
FIND_PACKAGE(D REQUIRED)

## Strip utility.
find_program(STRIP strip)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OR "${CMAKE_INSTALL_PREFIX}" STREQUAL "")
    set(CMAKE_INSTALL_PREFIX
	${DC_PATH} CACHE PATH "QtD install prefix" FORCE
    )
endif(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OR "${CMAKE_INSTALL_PREFIX}" STREQUAL "")

# Check D compiler version
if(D_VERSION EQUAL "1")
    if (D_FRONTEND LESS "041")
	message(STATUS "Minimum required version of D compiler is 1.041 (or compiler based on this version)")
    endif(D_FRONTEND LESS "041")
    set(D_TARGET d1-tango)   
elseif(D_VERSION EQUAL "2")
    set(D_TARGET d2-phobos)
endif(D_VERSION EQUAL "1")

# Debug and release flags.
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif (NOT CMAKE_BUILD_TYPE)
if(${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])
    set(CMAKE_BUILD_TYPE Debug)
    #set( SUFFIXLIB "${SUFFIXLIB}-debug" )
    #set( SUFFIXBIN "${SUFFIXBIN}-debug" )
    add_definitions(-DDEBUG)
elseif (NOT ${CMAKE_BUILD_TYPE} MATCHES [rR][eE][lL][eE][aA][sS])
    message(STATUS "Only debug and release configurations are supproted now. Configuration will change to 'Release'")
    set(CMAKE_BUILD_TYPE Release)
endif (${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])  
if (${CMAKE_BUILD_TYPE} MATCHES [rR][eE][lL][eE][aA][sS])
    #add_definitions(-UNO_DEBUG)
endif(${CMAKE_BUILD_TYPE} MATCHES [rR][eE][lL][eE][aA][sS] )

# System specifc settings.
if(CMAKE_HOST_WIN32)
    set(implib implib)
    find_program(IMPLIB ${implib})
    if (NOT IMPLIB)
	message(FATAL_ERROR "implib not found. You can donwload it from http://ftp.digitalmars.com/bup.zip")
    endif (NOT IMPLIB)
    if(D_IS_MARS)
      set(D_FLAGS ${D_FLAGS} -version=cpp_shared)    
      set(GEN_OPT ${GEN_OPT} --cpp_shared)
      add_definitions(-DCPP_SHARED)
    endif(D_IS_MARS)
    string(REGEX REPLACE ".dll([A-Za-z\\.0-9]+)" "\\1" CMAKE_IMPORT_LIBRARY_SUFFIX "${CMAKE_IMPORT_LIBRARY_SUFFIX}")
endif(CMAKE_HOST_WIN32) 

set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} ./)
set(GEN_OPT ${GEN_OPT} --d-target=${D_TARGET})

## Bootstrap settings for QtD.
set(DRCC ${CMAKE_BINARY_DIR}/tools/drcc/drcc)
set(DUIC ${CMAKE_BINARY_DIR}/tools/duic/duic)
set(QTD_IMPORT_PATH ${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/qt/d${D_VERSION})
set(QTD_LIBRARIES_PATH ${CMAKE_BINARY_DIR}/lib)

##--------------------------------------------
## Macros and functions.
##--------------------------------------------

macro(qtd_add_resource output)
    set (params NAME OPTIONS)
    qtd_parse_params (RESOURCES  params ${ARGN})

    if(NAME_tmp)
	set(OPTIONS_tmp ${OPTIONS_tmp} -name ${NAME_tmp})
    endif(NAME_tmp)

    qtd_command ("${output}" "${DRCC}" "${OPTIONS_tmp}" "qrc_" 
	"Generate" ${RESOURCES_tmp})
endmacro(qtd_add_resource output)

macro(qtd_wrap_ui output)
    set (params OPTIONS)
    qtd_parse_params (UI params ${ARGN})
    qtd_command ("${output}" "${DUIC}" "${OPTIONS_tmp}"  "uic_" 
	"Generate" ${UI_tmp})
endmacro(qtd_wrap_ui output)

macro(qtd_command output command options prefix comment)
    foreach(file "${ARGN}")
	## Test input file exists.
	get_filename_component(file_path ${file} PATH)
	get_filename_component(file_name ${file} NAME_WE)
	get_filename_component(file_ext ${file} EXT)

	set(out ${CMAKE_CURRENT_BINARY_DIR}/${file_path}${prefix}${file_name}.d)
	add_custom_command(OUTPUT "${out}"
		    COMMAND "${command}"
		    ARGS ${options} ${file} -o ${out} 
		    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		    DEPENDS ${file}
		    COMMENT "${comment} ${file}"
		    )
	set(${output} ${${output}} ${out})
    endforeach(file "${ARGN}")
endmacro(qtd_command output command options files prefix comment)

## Parse the parameters list.
macro(qtd_parse_params default params)
    set(type_tmp ${default})
    set(params_tmp ${default} ${${params}})  
    foreach(param_tmp ${params_tmp})	
	set(${param_tmp}_tmp )
    endforeach(param_tmp ${params_tmp})
    foreach(arg_tmp ${ARGN})
	set(founded_type_tmp)
	if(NOT founded_type_tmp)
	    foreach(param_tmp ${params_tmp})
		if(arg_tmp STREQUAL param_tmp)	
		    set(type_tmp ${param_tmp})
		    set(founded_type_tmp 1)
		    break(param_tmp ${params_tmp})
		endif(arg_tmp STREQUAL param_tmp)
	    endforeach(param_tmp ${params_tmp})	
	endif(NOT founded_type_tmp)
	if(NOT founded_type_tmp)
	    set(${type_tmp}_tmp ${${type_tmp}_tmp} ${arg_tmp})
	endif(NOT founded_type_tmp)
    endforeach(arg_tmp ${ARGN})
endmacro(qtd_parse_params default)

## Build example macro.
## name -- example name.
## Options:
##	PACKAGES -- list of packages to link to exaple (for example, QtCore QtGui QtOpenGL).
##		Default value is "QtCore QtGui".
## params -- sources d files.
## Usage:
##	build_example(ExampleName PACKAGES QtCore QtGui QtXml  main.d another_d_file.d)
macro(build_example name)
    set (params UIC RESOURCES PACKAGES)
    qtd_parse_params (SOURCES params ${ARGN})

    if(NOT PACKAGES_tmp)
	set(PACKAGES_tmp QtCore QtGui)
    endif(NOT PACKAGES_tmp)
 
    if(RESOURCES_tmp)
	if(NOT BUILD_TOOLS)
	    message(STATUS "Example '${name}' required drcc. Example will not build")
	    return(build_example name)
	endif(NOT BUILD_TOOLS)
	qtd_add_resource(res_sources ${RESOURCES_tmp} NAME ${name} )
    endif(RESOURCES_tmp)

    if(UIC_tmp)
	if(NOT BUILD_TOOLS)
	    message(STATUS "Example '${name}' required drcc. Example will not build")
	    return(build_example name)
	endif(NOT BUILD_TOOLS)
	qtd_wrap_ui(uic_sources ${UIC_tmp})
    endif(UIC_tmp)

    foreach(package ${PACKAGES_tmp})
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
    endforeach(package ${PACKAGES_tmp})
    add_d_program(${name} ${SOURCES_tmp} NO_DEPS_SOURCES ${res_sources} ${uic_sources}
	DEPENDS ${res_sources} INCLUDES ${QTD_IMPORT_PATH} ${CMAKE_CURRENT_BINARY_DIR}
	LIB_PATHS ${QTD_LIBRARIES_PATH} ${CMAKE_SOURCE_DIR}/lib LIBS ${qtd_libs})
    ## TODO: Enable on windows too.
    if(STRIP AND ${CMAKE_BUILD_TYPE} EQUAL "Release" AND CMAKE_HOST_UNIX) ##
	add_custom_command(TARGET example_${name} POST_BUILD COMMAND "${STRIP}" ARGS "${output}")
    endif(STRIP AND ${CMAKE_BUILD_TYPE} EQUAL "Release" AND CMAKE_HOST_UNIX)
    add_dependencies(${name} allpackages)
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
    set(cpp_generated_files)
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
	foreach(d_source ${package}/ArrayOps2 ${d_generated_files})
	    set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${d_source}.d)
	endforeach(d_source ${d_generated_files})
	set(classes ArrayOps ${classes})
	foreach(class ${classes})
	    set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${package}/${class}.d)	
	    set(cpp_sources ${cpp_sources} ${CMAKE_BINARY_DIR}/cpp/qt_${package}/${class}_shell.cpp) 
	endforeach(class ${classes})
	set(files_for_gen ${files_for_gen} ${cpp_sources} ${d_sources})

	foreach (cpp_source ${cpp_files})
	    set(cpp_sources ${cpp_sources} ${CMAKE_SOURCE_DIR}/cpp/${cpp_source}.cpp)
	endforeach(cpp_source ${cpp_files})
	foreach (cpp_source ${cpp_generated_files})
	    set(cpp_sources ${cpp_sources} ${CMAKE_BINARY_DIR}/cpp/${cpp_source}.cpp)
	endforeach(cpp_source ${cpp_generated_files})
	foreach(d_source ${d_version_files})
	    set(d_sources ${d_sources} ${CMAKE_SOURCE_DIR}/qt/d${D_VERSION}/qt/${d_source}.d)
	endforeach(d_source ${d_version_files})
	foreach(d_source ${d_files})
	    set(d_sources ${d_sources} ${CMAKE_SOURCE_DIR}/qt/${d_source}.d)
	endforeach(d_source ${d_files})

	if(NOT GENERATE_DI_FILES)
	    foreach(d_source ${d_sources})
	      get_filename_component(path ${d_source} PATH)
	      get_filename_component(name ${d_source} NAME_WE)
	      regex_safe_string(cbd_safe_tmp ${CMAKE_CURRENT_BINARY_DIR})
	      regex_safe_string(csd_safe_tmp ${CMAKE_CURRENT_SOURCE_DIR})
	      regex_safe_string(ver_safe_tmp ${CMAKE_CURRENT_SOURCE_DIR}/qt/d${D_VERSION})
	      set(regexp_str_tmp "(${ver_safe_tmp}/|${cbd_safe_tmp}/|${csd_safe_tmp}/|)(.+)")
	      string(REGEX REPLACE ${regexp_str_tmp} "\\2" ins_path "${path}") 
	      install(FILES ${d_source} DESTINATION include/d/${ins_path} COMPONENT qtd RENAME ${name}.di)
	      install(FILES ${path}/${name}_enum.d DESTINATION include/d/${ins_path} COMPONENT qtd RENAME ${name}_enum.di OPTIONAL)
	    endforeach(d_source ${d_sources})
	endif(NOT GENERATE_DI_FILES)

	## Link CPP library.
	add_library(cpp_${package} STATIC ${cpp_sources})
	set_property(TARGET cpp_${package} PROPERTY LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/CMakeFiles)
	if(CMAKE_HOST_WIN32 AND D_IS_MARS) ## TODO: Replace by SEPAREATE_CPP_PART	    
	else(CMAKE_HOST_WIN32 AND D_IS_MARS)
	    foreach(cpp_source ${cpp_sources})
		set(cpp_source ${cpp_source})
		obj_path(cpp_source)
		set(cpp_objs ${cpp_objs} ${CMAKE_BINARY_DIR}/CMakeFiles/cpp_${package}.dir/${cpp_source}${CMAKE_CXX_OUTPUT_EXTENSION})
	    endforeach(cpp_source ${cpp_sources})
	endif(CMAKE_HOST_WIN32 AND D_IS_MARS)

	## Link D library.
	set(lib_name qtd${package})
	if(BUILD_SHARED_LIBRARIES)
	    set(lib lib/${CMAKE_SHARED_LIBRARY_PREFIX}${lib_name}${CMAKE_SHARED_LIBRARY_SUFFIX})
	    set(build_type SHARED)
	else(BUILD_SHARED_LIBRARIES)
	    set(lib lib/${D_LIB_PREFIX}${lib_name}${D_LIB_SUFFIX})
	    set(build_type STATIC)
	endif(BUILD_SHARED_LIBRARIES)

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
	set(d_objs ${d_objs} ${objects}) 

	set_property(TARGET cpp_${package} PROPERTY RUNTIME_OUTPUT_DIRECTORY lib)
	set_property(TARGET cpp_${package} PROPERTY ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/CMakeFiles)
	string(TOUPPER ${package} package_upper)
	set(link_cpp ${link_cpp} ${QT_QT${package_upper}_LIBRARY})
	target_link_libraries(cpp_${package} ${link_cpp} )	
	if(CMAKE_HOST_WIN32 AND D_IS_MARS) ## TODO: Replace by SEPAREATE_CPP_PART
	    set(cpp_lib ${CMAKE_BINARY_DIR}/lib/libcpp_${package}.dll)
	    set(cpp_lib_native ${cpp_lib})
	    make_native_path(cpp_lib_native)
	    set(d_implib ${CMAKE_BINARY_DIR}/CMakeFiles/${package}.dir/cpp_${package}.lib)
	    set(d_implib_native ${d_implib})
	    make_native_path(d_implib_native)
	    add_custom_command(
			OUTPUT "${d_implib}"
			COMMAND "${IMPLIB}"
			ARGS  /system /PAGESIZE:32 ${d_implib_native} ${cpp_lib_native}
			DEPENDS  "cpp_${package}"
			COMMENT "Creating implib ${lib_name}"
		    )
	    install(FILES ${cpp_lib} COMPONENT qtd DESTINATION lib)
	else(CMAKE_HOST_WIN32 AND D_IS_MARS)
	    set(${package}_lib_param Qt${package_big}) ## Paths for QtD libs. Needed by examples.
	endif(CMAKE_HOST_WIN32 AND D_IS_MARS) 
	add_d_target(${lib_name} NOT_DETECT_DEPENDS TYPE ${build_type} INCLUDES ${QTD_IMPORT_PATH} SOURCES ${d_sources} OBJECTS ${cpp_objs} ${d_implib}
	      OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib DEPENDS ${d_implib})
	install(FILES ${CMAKE_BINARY_DIR}/${lib} COMPONENT qtd DESTINATION lib)
	
	## Paths for QtD libs. Needed by examples.
	set(${package}_lib_param qtd${package} ${${package}_lib_param} ${link_example})

	## Dependences.
	add_custom_target(${package} DEPENDS ${lib})
	foreach(depend ${required})
	    string(TOLOWER ${depend} depend)
	    add_dependencies(cpp_${package} cpp_${depend})
	    add_dependencies(${package} ${depend})
	endforeach(depend ${required})
	add_dependencies(allpackages ${package})

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

set(CPACK_COMPONENTS_ALL qtd qtd_tools)

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
if(CMAKE_HOST_WIN32)
    set(CPACK_GENERATOR "ZIP")
elseif(CMAKE_HOST_UNIX)
    set(CPACK_GENERATOR "TBZ2;DEB;RPM")
endif(CMAKE_HOST_WIN32)
include(CPack)