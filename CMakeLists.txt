cmake_minimum_required(VERSION 2.6)
PROJECT(qtd CXX C)

# Debug and release flags.
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif ()

if(${CMAKE_BUILD_TYPE} MATCHES [dD][eE][bB][uU][gG])
    set(CMAKE_BUILD_TYPE Debug)
    #set( SUFFIXLIB "${SUFFIXLIB}-debug" )
    #set( SUFFIXBIN "${SUFFIXBIN}-debug" )
    add_definitions(-DDEBUG)
elseif (NOT ${CMAKE_BUILD_TYPE} MATCHES [rR][eE][lL][eE][aA][sS])
    message(STATUS "Only debug and release configurations are supported. The configuration is changed to 'Release'")
    set(CMAKE_BUILD_TYPE Release)
endif ()

if (${CMAKE_BUILD_TYPE} MATCHES [rR][eE][lL][eE][aA][sS])
    #add_definitions(-UNO_DEBUG)
endif()

##########################################################
## Build generator.
##########################################################
if (NOT SECOND_RUN)

option(ALLOW_IN_SOURCE_BUILDS "Allow in-source builds" "OFF")
if (CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR AND NOT ALLOW_IN_SOURCE_BUILDS)
    message(FATAL_ERROR "In-source builds are not allowed. "
    "Please create a directory and run cmake from there, passing the path "
    "to this source directory as the last argument. "
    "This process created the file `CMakeCache.txt` and the directory `CMakeFiles'. Please delete them. "
    "Or you can restart cmake with `-DALLOW_IN_SOURCE_BUILDS=1`, but it is not recommended."
    )
endif ()

FIND_PACKAGE(Qt4 REQUIRED)
set(QT_USE_QTMAIN false)
set(QT_USE_QTGUI false)

##--------------------------------------------
## Settings.
##--------------------------------------------

## Options.
option(BUILD_EXAMPLES "Build examples" "OFF")
# option(BUILD_SHARED_LIBRARIES "Build shared library (very experemental and only for ldc)" "OFF")

if (CMAKE_HOST_WIN32)
    set(CPP_SHARED true CACHE INTERNAL "")
else()
    option(CPP_SHARED "Build C++ part into shared libraries" "ON")
endif()

option(BUILD_TOOLS "Build tools" "ON")
#option(GENERATE_DI_FILES "Generate *.di files with DC -H command" "OFF")
set(GENERATE_DI_FILES OFF) ## Very experimental option. Temporarily disabled.
option(VERBOSE_DEBUG "Verbose debug" "OFF")

set(all_packages Core Gui OpenGL Xml Svg Network WebKit Qwt CACHE INTERNAL "")

## Init D toolkit.
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
FIND_PACKAGE(D REQUIRED)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OR "${CMAKE_INSTALL_PREFIX}" STREQUAL "")
    set(CMAKE_INSTALL_PREFIX
    ${DC_PATH} CACHE PATH "QtD install prefix"
    )
endif()

set(D_MODULE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/include/d" CACHE PATH "D module install path" )

# Check D compiler version
if(D_VERSION EQUAL "1")
    if (D_FRONTEND LESS "050")
    message(STATUS "Minimum required version of D compiler is 1.050 (or compiler based on this version)")
    endif(D_FRONTEND LESS "050")
    set(D_TARGET d1-tango CACHE INTERNAL "")
elseif(D_VERSION EQUAL "2")
    set(D_TARGET d2-phobos CACHE INTERNAL "")
endif()

# System specific settings.
if(CMAKE_HOST_WIN32)
    set(implib implib)
    find_program(IMPLIB ${implib})
    if (NOT IMPLIB)
        message(FATAL_ERROR "implib is not found. You can donwload it from http://ftp.digitalmars.com/bup.zip")
    endif ()
endif()

if(CPP_SHARED)
    set(GEN_OPT ${GEN_OPT} --cpp-shared)
    add_definitions(-DCPP_SHARED)
endif()

set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} ./)
set(GEN_OPT ${GEN_OPT} --d-target=${D_TARGET})

set(packages CACHE INTERNAL "")
foreach(package_big ${all_packages})
    string(TOLOWER ${package_big} package)
    string(TOUPPER ${package_big} package_upper)
    set(package_default_option "ON")
    if(${package_big} STREQUAL "Qwt")
        set(package_default_option "OFF")
    endif()
    option(BUILD_QT_${package_upper} "Build Qt${package_big}" ${package_default_option})
    if(BUILD_QT_${package_upper})
        set(packages ${packages} ${package_big})
    endif()
endforeach()

set(QWT_INCLUDE_PATH "/usr/include/qwt-qt4" CACHE STRING "Qwt include path")
if(CMAKE_HOST_WIN32)
    set(QWT_LIB_PATH "" CACHE STRING "Qwt lib path")
endif()
set(inc_paths "")

if(CMAKE_HOST_WIN32)
    set(sep "*")
else()
    set(sep ":")
endif()

if(BUILD_QT_QWT)
    set(inc_paths ${inc_paths}${sep}${QWT_INCLUDE_PATH}${sep})
endif()

add_subdirectory(generator)

add_custom_target(main ALL)
add_dependencies(main dgen)

if(${CMAKE_GENERATOR} STREQUAL "NMake Makefiles")
    set(make_util nmake)
elseif(${CMAKE_GENERATOR} STREQUAL "MinGW Makefiles" OR
    ${CMAKE_GENERATOR} STREQUAL "Unix Makefiles")
    set(make_util $(MAKE))
else()
    message(FATAL_ERROR "${CMAKE_GENERATOR} is not supported")
endif()

if(${CMAKE_BINARY_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
    set(cd_path ${CMAKE_SOURCE_DIR})
else()
    set(cd_path ${CMAKE_BINARY_DIR}/build)
endif()

make_native_path(cd_path)
add_custom_command(TARGET main POST_BUILD
    COMMAND ${CMAKE_COMMAND} ARGS -E make_directory ${CMAKE_BINARY_DIR}/build
    COMMAND cd  ARGS ${cd_path} && ${CMAKE_COMMAND} -G${CMAKE_GENERATOR} -DSECOND_RUN=1 ${CMAKE_SOURCE_DIR} && ${make_util}
    COMMENT ""
    )

## "Make install" command.
set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${CMAKE_BINARY_DIR}/build)

set(native_build_path ${CMAKE_BINARY_DIR}/build)
make_native_path(native_build_path)
add_custom_target(install
    COMMAND cd ${native_build_path} && ${make_util} install
    COMMENT ""
    )
add_dependencies(install preinstall)

##########################################################
## Build QtD.
##########################################################
else(NOT SECOND_RUN)

PROJECT(qtd CXX C)
if(NOT ${CMAKE_BINARY_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
    load_cache(${CMAKE_BINARY_DIR}/.. INCLUDE_INTERNALS all_packages QTD_VERSION_STR QTD_VERSION CPP_SHARED D_MODULE_INSTALL_DIR)
endif()
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
FIND_PACKAGE(D REQUIRED)
FIND_PACKAGE(Qt4 REQUIRED)

set(QTD_VERSION_STR ${QT_VERSION_MAJOR}.${QT_VERSION_MINOR}.${QT_VERSION_PATCH})
math(EXPR QTD_VERSION "(${QT_VERSION_MAJOR} << 16) + (${QT_VERSION_MINOR} << 8) + ${QT_VERSION_PATCH}")

include_directories(${QT_INCLUDES} ${CMAKE_SOURCE_DIR}/include ${CMAKE_CURRENT_BINARY_DIR}/include)
if(BUILD_QT_QWT)
    include_directories(${QWT_INCLUDE_PATH})
endif()

# System specifc settings.
if(CMAKE_HOST_WIN32)
    string(REGEX REPLACE ".dll([A-Za-z\\.0-9]+)" "\\1" CMAKE_IMPORT_LIBRARY_SUFFIX "${CMAKE_IMPORT_LIBRARY_SUFFIX}")
endif()

if(CPP_SHARED)
    set(D_FLAGS -version=QtdCppShared)
    add_definitions(-DCPP_SHARED)
endif()

if(UNITTEST)
    add_d_versions(QtdUnittest)
    set(D_FLAGS ${D_FLAGS} -unittest)
endif()

if(VERBOSE_DEBUG)
    add_d_debugs(QtdVerbose)
endif()

if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    add_d_debugs(QtdDebug)
endif()

## Bootstrap settings for QtD.
set(DRCC ${CMAKE_BINARY_DIR}/tools/drcc/drcc CACHE INTERNAL "")
set(DUIC ${CMAKE_BINARY_DIR}/tools/duic/duic CACHE INTERNAL "")
set(QTD_IMPORT_PATH ${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/d${D_VERSION} CACHE INTERNAL "")
set(QTD_LIBRARIES_PATH ${CMAKE_BINARY_DIR}/lib CACHE INTERNAL "")

##--------------------------------------------
## Macros and functions.
##--------------------------------------------

macro(load_generated_classes )
    include(${CMAKE_BINARY_DIR}/cpp/qt_${package}/qt_${package}.txt)
endmacro()

macro(qtd_add_resource output)
    set (params NAME OPTIONS)
    qtd_parse_params (RESOURCES  params ${ARGN})
    if(NAME_tmp)
        set(OPTIONS_tmp ${OPTIONS_tmp} -name ${NAME_tmp})
    endif()
    qtd_command ("${output}" "${DRCC}" "${OPTIONS_tmp}" "qrc_"
    "Generate" ${RESOURCES_tmp})
endmacro()

macro(qtd_wrap_ui output)
    set (params OPTIONS)
    qtd_parse_params (UI params ${ARGN})
    qtd_command ("${output}" "${DUIC}" "${OPTIONS_tmp}"  "uic_"
    "Generate" ${UI_tmp})
endmacro()

macro(qtd_command output command options prefix comment)
    foreach(file "${ARGN}")
        ## Test if the input file exists
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
    endforeach()
endmacro()

## Parses the parameters list.
macro(qtd_parse_params default params)
    set(type_tmp ${default})
    set(params_tmp ${default} ${${params}})
    foreach(param_tmp ${params_tmp})
        set(${param_tmp}_tmp )
    endforeach()
    foreach(arg_tmp ${ARGN})
        set(found_type_tmp)
        if(NOT found_type_tmp)
            foreach(param_tmp ${params_tmp})
                if(arg_tmp STREQUAL param_tmp)
                    set(type_tmp ${param_tmp})
                    set(found_type_tmp 1)
                    break(param_tmp ${params_tmp})
                endif()
            endforeach()
        endif()
        if(NOT found_type_tmp)
            set(${type_tmp}_tmp ${${type_tmp}_tmp} ${arg_tmp})
        endif()
    endforeach()
endmacro()

## Adds a new example.
## name -- example name.
## Options:
##    PACKAGES -- list of packages for link to example (for example, QtCore QtGui QtOpenGL).
##        Default value is "QtCore QtGui".
## params -- sources d files.
## Usage:
##    build_example(ExampleName PACKAGES QtCore QtGui QtXml  main.d another_d_file.d)
macro(build_example name)
    set (params UIC RESOURCES PACKAGES)
    qtd_parse_params (SOURCES params ${ARGN})

    if(NOT PACKAGES_tmp)
        set(PACKAGES_tmp QtCore QtGui)
    endif()

    if(RESOURCES_tmp)
        if(NOT BUILD_TOOLS)
            message(STATUS "Example '${name}' requires drcc. Example will not be built")
            return(build_example name)
        endif()
        qtd_add_resource(res_sources ${RESOURCES_tmp} NAME ${name} )
    endif()

    if(UIC_tmp)
        if(NOT BUILD_TOOLS)
            message(STATUS "Example '${name}' requires drcc. Example will not be built")
            return(build_example name)
        endif()
        qtd_wrap_ui(uic_sources ${UIC_tmp})
    endif()

    foreach(package ${PACKAGES_tmp})
        string(REGEX REPLACE "Qt([A-Za-z0-9])" "\\1" req "${package}")
        set(is_found)
        foreach(package_big ${packages_big})
            string(TOLOWER ${package_big} package)
            if(${req} STREQUAL ${package_big})
                set(is_found 1)
                break(package_big ${packages_big})
            endif()
        endforeach()
        if(NOT is_found)
            message(STATUS "Example '${name}' requires the package '${req}', but it is not active. Example will not be built")
            return(build_example name)
        else()
            set(qtd_libs ${${package}_lib_param} ${qtd_libs})
            if(CPP_SHARED AND CMAKE_HOST_UNIX)
                set(qtd_libs cpp_${package} ${qtd_libs})
            endif()
        endif()
    endforeach()
    add_d_program(${name} ${SOURCES_tmp} NO_DEPS_SOURCES ${res_sources} ${uic_sources}
    DEPENDS ${res_sources} INCLUDES ${QTD_IMPORT_PATH} ${CMAKE_CURRENT_BINARY_DIR}
    LIB_PATHS ${QTD_LIBRARIES_PATH} ${CMAKE_SOURCE_DIR}/lib ${QT_LIBRARY_DIR} LIBS ${qtd_libs})
    ## TODO: Uncomment.
    #if(STRIP AND ${CMAKE_BUILD_TYPE} EQUAL "Release" AND CMAKE_HOST_UNIX) ##
    #    add_custom_command(TARGET example_${name} POST_BUILD COMMAND "${STRIP}" ARGS "${output}")
    #endif(STRIP AND ${CMAKE_BUILD_TYPE} EQUAL "Release" AND CMAKE_HOST_UNIX)
    add_dependencies(examples ${name})
    add_dependencies(${name} allpackages tools)
endmacro()

##--------------------------------------------
## Build and install the QtD libraries.
##--------------------------------------------

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
add_custom_target(allpackages)
link_directories(${CMAKE_BINARY_DIR}/CMakeFiles)

foreach(package_big ${all_packages})
    string(TOLOWER ${package_big} package)
    string(TOUPPER ${package} package_upper)
    ## Load settings for the package.
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
    set(d_qt_files)
    set(d_qtd_files)
    set(classes)
    set(d_generated_files)
    set(link_example)
    include (${CMAKE_SOURCE_DIR}/build/${package}.txt)

    set(all_req_found 1)
    if(BUILD_QT_${package_upper})
        foreach(req ${required})
            set(req_found)
            foreach(pack ${packages_big})
            if(${pack} STREQUAL ${req})
                set(req_found 1)
            endif()
            endforeach(pack ${packages})
            if(NOT req_found)
                set(req_found)
                foreach(pack ${all_packages})
                    if(${pack} STREQUAL ${req})
                        set(req_found 1)
                    endif(${pack} STREQUAL ${req})
                endforeach(pack ${all_packages})
                if(req_found)
                    message(STATUS "Package '${package_big}' requires '${req}', but it is not active")
                else()
                    message(STATUS "Package '${package_big}' requires '${req}', but it is not found")
                endif()
                set(all_req_found)
            endif()
        endforeach(req ${required})
    else(BUILD_QT_${package_upper})
        set(all_req_found)
    endif(BUILD_QT_${package_upper})

    if("${all_req_found}" EQUAL 1)
        set(packages_big ${packages_big} ${package_big})
        set(packages ${packages} ${package})
        ## Load a package sources list.
        foreach(d_source ${package}/ArrayOps2 ${d_generated_files})
            set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${d_source}.d)
            if(EXISTS ${CMAKE_BINARY_DIR}/qt/${d_source}_aux.d)
                set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${d_source}_aux.d)
            endif()
        endforeach()
        set(classes ArrayOps ${classes})
        foreach(class ${classes})
            set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${package}/${class}.d)
            set(cpp_sources ${cpp_sources} ${CMAKE_BINARY_DIR}/cpp/qt_${package}/${class}_shell.cpp)
            if(EXISTS ${CMAKE_BINARY_DIR}/qt/${package}/${class}_aux.d)
                set(d_sources ${d_sources} ${CMAKE_BINARY_DIR}/qt/${package}/${class}_aux.d)
            endif()
        endforeach()
        set(files_for_gen ${files_for_gen} ${cpp_sources} ${d_sources})

        foreach (cpp_source ${cpp_files})
            set(cpp_sources ${cpp_sources} ${CMAKE_SOURCE_DIR}/cpp/${cpp_source}.cpp)
        endforeach()
        foreach (cpp_source ${cpp_generated_files})
            set(cpp_sources ${cpp_sources} ${CMAKE_BINARY_DIR}/cpp/${cpp_source}.cpp)
        endforeach()
        foreach(d_source ${d_qt_files})
            set(d_sources ${d_sources} ${CMAKE_SOURCE_DIR}/d${D_VERSION}/qt/${d_source}.d)
        endforeach()
        foreach(d_source ${d_qtd_files})
            set(d_sources ${d_sources} ${CMAKE_SOURCE_DIR}/d${D_VERSION}/qtd/${d_source}.d)
        endforeach()

        if(NOT GENERATE_DI_FILES)
            foreach(d_source ${d_sources})
            get_filename_component(path ${d_source} PATH)
            get_filename_component(name ${d_source} NAME_WE)
            regex_safe_string(cbd_safe_tmp ${CMAKE_CURRENT_BINARY_DIR})
            regex_safe_string(csd_safe_tmp ${CMAKE_CURRENT_SOURCE_DIR})
            regex_safe_string(ver_safe_tmp ${CMAKE_CURRENT_SOURCE_DIR}/d${D_VERSION})
            set(regexp_str_tmp "(${ver_safe_tmp}/|${cbd_safe_tmp}/|${csd_safe_tmp}/|)(.+)")
            string(REGEX REPLACE ${regexp_str_tmp} "\\2" ins_path "${path}")
            install(FILES ${d_source} DESTINATION ${D_MODULE_INSTALL_DIR}/${ins_path} COMPONENT qtd RENAME ${name}.di)
            endforeach()
        endif(NOT GENERATE_DI_FILES)

        ### Build the CPP part.
        if(CPP_SHARED)
            set(cpp_method SHARED)
        else()
            set(cpp_method STATIC)
        endif()
        add_library(cpp_${package} ${cpp_method} ${cpp_sources})

        set_target_properties(cpp_${package} PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
            RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
            ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/CMakeFiles
            COMPILE_DEFINITIONS QTD_${package_upper}
        )

        if(CMAKE_HOST_WIN32)
            set_target_properties(cpp_${package} PROPERTIES
                LINK_FLAGS -Wl,-enable-auto-import
            )
        endif()

        set(link_cpp ${link_cpp} ${QT_QT${package_upper}_LIBRARY})
        if(NOT CPP_SHARED)
            ## Get an objects list. It will be used in building the D part.
            foreach(cpp_source ${cpp_sources})
            set(cpp_source ${cpp_source})
            obj_path(cpp_source)
            set(cpp_objs ${cpp_objs} ${CMAKE_BINARY_DIR}/CMakeFiles/cpp_${package}.dir/${cpp_source}${CMAKE_CXX_OUTPUT_EXTENSION})
            endforeach()
        endif()

        ## Settings for the D part.
        set(lib_name qtd${package})
        # if(BUILD_SHARED_LIBRARIES)
        #    set(lib lib/${CMAKE_SHARED_LIBRARY_PREFIX}${lib_name}${CMAKE_SHARED_LIBRARY_SUFFIX})
        #    set(build_type SHARED)
        # else()
            set(lib lib/${D_LIB_PREFIX}${lib_name}${D_LIB_SUFFIX})
            set(build_type STATIC)
        # endif()

        ## Package dependencies.
        foreach(req ${required})
            set(is_found)
            foreach(pack ${packages_big})
                if("${pack}" STREQUAL "${req}")
                    set(is_found 1)
                    break(pack ${packages_big})
                endif()
            endforeach()
            if(NOT is_found)
                message(FATAL_ERROR "Package ${package_big} requires ${req}, but it is not found")
            endif()
            string(TOUPPER ${req} req_upper)
            string(TOLOWER ${req} req_lower)
            set(link_cpp ${link_cpp} cpp_${req_lower} ${QT_QT${req_upper}_LIBRARY})
        endforeach()

        if(${package_big} STREQUAL "Qwt" AND CMAKE_HOST_WIN32)
            set(qwt_release_lib ${QWT_LIB_PATH}/libqwt5.a)
            set(qwt_debug_lib ${QWT_LIB_PATH}/libqwtd5.a)
            if(EXISTS ${qwt_release_lib})
                set(qwt_lib ${qwt_release_lib})
            elseif(EXISTS ${qwt_debug_lib})
                set(qwt_lib ${qwt_debug_lib})
            endif()
            set(link_cpp ${link_cpp} ${qwt_lib})
        endif()

        target_link_libraries(cpp_${package} ${link_cpp} )
        set(d_objs ${d_objs} ${objects})

        if(CPP_SHARED)
            set(cpp_lib ${CMAKE_BINARY_DIR}/lib/libcpp_${package}${CMAKE_SHARED_LIBRARY_SUFFIX})
            install(FILES ${cpp_lib} COMPONENT qtd DESTINATION lib)

            if(CMAKE_HOST_WIN32)
                ## Create an implib library which will be linked to the D part.
                set(cpp_lib_native ${cpp_lib})
                make_native_path(cpp_lib_native)
                set(d_implib ${CMAKE_BINARY_DIR}/CMakeFiles/${package}.dir/cpp_${package}.lib)
                set(d_implib_native ${d_implib})
                make_native_path(d_implib_native)
                add_custom_command(
                    OUTPUT "${d_implib}"
                    COMMAND "${IMPLIB}"
                    ARGS  /system /PAGESIZE:64 ${d_implib_native} ${cpp_lib_native}
                    DEPENDS  "cpp_${package}"
                    COMMENT "Creating implib ${lib_name}"
                    )
            endif()
        else()
            set(${package}_lib_param Qt${package_big})
        endif()

        ## Link the D part.
        add_d_target(${lib_name} NOT_DETECT_DEPENDS TYPE ${build_type} INCLUDES ${QTD_IMPORT_PATH} SOURCES ${d_sources} OBJECTS ${cpp_objs} ${d_implib}
              OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib DEPENDS ${d_implib} )
        install(FILES ${CMAKE_BINARY_DIR}/${lib} COMPONENT qtd DESTINATION lib)
        ## Paths for the QtD libs. It is necessary for examples.
        set(${package}_lib_param qtd${package} ${${package}_lib_param} ${link_example})

        ## Generate dependences for make (or nmake).
        add_custom_target(${package})
        add_dependencies(${package} ${lib_name})

        add_dependencies(${lib_name} cpp_${package})
        foreach(depend ${required})
            string(TOLOWER ${depend} depend)
            add_dependencies(cpp_${package} cpp_${depend})
            add_dependencies(${package} ${depend})
        endforeach()
        add_dependencies(allpackages ${package})

        ## TODO: Do we need to generate *.di files?
        if(GENERATE_DI_FILES)
            regexseafestring(cbd_safe ${CMAKE_BINARY_DIR})
            regexseafestring(csd_safe ${CMAKE_SOURCE_DIR})
            set(regexp_str "(${csd}/qt/d${D_VERSION}|${csd_safe}|${cbd_safe})/([A-Za-z0-9\\-_\\\\/]+)[/]+([A-Za-z0-9\\-_\\\\]+).d")
            foreach(source ${d_sources})
            #     find_file(source ${source} PATHS ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}
            #           ${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR})
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
                else(NOT "${file_name}" STREQUAL "QGlobal") ## The DMD frontend crashes on this file.
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
                install(FILES ${interface_file} COMPONENT qtd DESTINATION ${D_MODULE_INSTALL_DIR}/${inc_path})
            endforeach()
        endif()
    endif()
endforeach()
if(GENERATE_DI_FILES)
    add_custom_target(generate_headers ALL DEPENDS ${interfaces_list})
endif(GENERATE_DI_FILES)

set(CPACK_COMPONENTS_ALL qtd qtd_tools)

##--------------------------------------------
## Build other parts of the QtD.
##--------------------------------------------

if(BUILD_TOOLS)
    add_custom_target(tools ALL)
    add_subdirectory(tools)
    add_dependencies(tools drcc duic)
endif(BUILD_TOOLS)

if(BUILD_EXAMPLES)
    add_custom_target(examples ALL)
    add_dependencies(examples allpackages tools)
    add_subdirectory(demos)
    add_subdirectory(examples)
endif(BUILD_EXAMPLES)

set(SECOND_RUN 0 CACHE INTERNAL "")

endif(NOT SECOND_RUN)

##--------------------------------------------
## CPack.
##--------------------------------------------
set(CPACK_PACKAGE_VERSION_PATCH 1)
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "QtD is a D binding to the Qt application and UI framework.")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/changelog.txt")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/license.txt")
set(CPACK_PACKAGE_VENDOR "QtD team")
set(CPACK_PACKAGE_CONTACT "qtd@qtd.org")
set(CPACK_PACKAGE_VERSION "0.6")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "qtd ${CPACK_PACKAGE_VERSION}")
set(CPACK_PACKAGE_FILE_NAME "qtd-${CPACK_PACKAGE_VERSION}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "qtd-${CPACK_PACKAGE_VERSION}")
if(CMAKE_HOST_WIN32)
    set(CPACK_GENERATOR "ZIP")
elseif(CMAKE_HOST_UNIX)
    set(CPACK_GENERATOR "TBZ2;DEB")
endif()
include(CPack)
