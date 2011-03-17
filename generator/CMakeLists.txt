PROJECT(generator CXX C)
cmake_minimum_required(VERSION 2.6)
find_package(Qt4 REQUIRED)

## Hack for msvc: force Release settings
string(TOUPPER "${CMAKE_BUILD_TYPE}" build_type_upper)
set(CMAKE_CXX_FLAGS_${build_type_upper} ${CMAKE_CXX_FLAGS_RELEASE})
get_property(dir_prop DIRECTORY
	    PROPERTY COMPILE_DEFINITIONS_RELEASE)
set_property(DIRECTORY PROPERTY COMPILE_DEFINITIONS_${build_type_upper} ${dir_prop})

## Sources
set(srcs
    global.cpp
    classlistgenerator.cpp
    cppgenerator.cpp
    cppheadergenerator.cpp
    cppimplgenerator.cpp
    docparser.cpp
    generatorsetd.cpp
    dgenerator.cpp
    jumptable.cpp
    metainfogenerator.cpp
    metajavabuilder.cpp
    qdocgenerator.cpp
    uiconverter.cpp
    containergenerator.cpp

    generator.cpp
    main.cpp
    reporthandler.cpp
    typeparser.cpp
    typesystem.cpp
    asttoxml.cpp
    fileout.cpp
    generatorset.cpp
    metajava.cpp
    customtypes.cpp
    abstractmetabuilder.cpp
    abstractmetalang.cpp
    prigenerator.cpp

    # rxx
    parser/ast.cpp
    parser/lexer.cpp
    parser/list.cpp
    parser/parser.cpp
    parser/smallobject.cpp
    parser/control.cpp
    parser/visitor.cpp
    parser/default_visitor.cpp
    parser/dumptree.cpp
    parser/tokens.cpp
    parser/binder.cpp
    parser/codemodel.cpp
    parser/type_compiler.cpp
    parser/name_compiler.cpp
    parser/declarator_compiler.cpp
    parser/class_compiler.cpp
    parser/codemodel_finder.cpp
    parser/compiler_utils.cpp

    ## rpp
    parser/rpp/preprocessor.cpp
)
## Moc headers
set(moc_hdrs
    #classlistgenerator.h
    cppgenerator.h
    cppheadergenerator.h
    cppimplgenerator.h
    #docparser.h
    generatorsetd.h
    dgenerator.h
    jumptable.h
    #metainfogenerator.h
    #metajavabuilder.h
    #qdocgenerator.h
    #uiconverter.h
    containergenerator.h
    generator.h
    #main.h
    #reporthandler.h
    #typeparser.h
    #typesystem.h
    #asttoxml.h
    fileout.h
    generatorset.h
    #metajava.h
    #customtypes.h
    #abstractmetabuilder.h
    #abstractmetalang.h
    prigenerator.h

    ## rxx
    #parser/ast.h
    #parser/lexer.h
    #parser/list.h
    #parser/parser.h
    #parser/rxx_allocator.h
    #parser/rpp-allocator.h
    #parser/smallobject.h
    #parser/tokens.h
    #parser/symbol.h
    #parser/control.h
    #parser/visitor.h
    #parser/default_visitor.h
    #parser/dumptree.h
    #parser/binder.h
    #parser/codemodel.h
    #parser/codemodel_pointer.h
    #parser/codemodel_fwd.h
    #parser/type_compiler.h
    #parser/name_compiler.h
    #parser/declarator_compiler.h
    #parser/class_compiler.h
    #parser/codemodel_finder.h
    #parser/compiler_utils.h

    # rpp
    #parser/rpp/pp-cctype.h
    #parser/rpp/pp-engine-bits.h
    #parser/rpp/pp-engine.h
    #parser/rpp/pp-environment.h
    #parser/rpp/pp-fwd.h
    #parser/rpp/pp-internal.h
    #parser/rpp/pp-iterator.h
    #parser/rpp/pp-macro-expander.h
    #parser/rpp/pp-macro.h
    #parser/rpp/pp-scanner.h
    #parser/rpp/pp-string.h
    #parser/rpp/pp-symbol.h
    #parser/rpp/pp.h
    #parser/rpp/preprocessor.h

)

## Resources.
set(res_files
    generator.qrc
)

## Includes path.
set(inc_paths_for_build
    ${CMAKE_CURRENT_SOURCE_DIR}/../common
    ${CMAKE_CURRENT_SOURCE_DIR}/parser
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/parser/rpp
    #${CMAKE_CURRENT_SOURCE_DIR}/parser/include
)

add_definitions(-DRXX_ALLOCATOR_INIT_0)

## Build project
find_package (Qt4 REQUIRED)
set (QT_USE_QTMAIN true)
set (QT_USE_QTGUI false)
set (QT_USE_QTXML true)

include(${QT_USE_FILE} ${CMAKE_CURRENT_SOURCE_DIR})

set(inc_paths_for_build
    ${inc_paths_for_build}
    ${QT_INCLUDES}
)
set(lib_paths
    ${lib_paths}
    ${QT_LIBRARY_DIR}
)
set(libs
    ${QT_LIBRARIES}
)

qt4_wrap_cpp(moc_srcs ${moc_hdrs})
qt4_add_resources(res_wrapped_files ${res_files})

set (all_srcs
    ${srcs} ${moc_srcs}
    ${res_wrapped_files})
include_directories(${inc_paths_for_build})
add_executable(generator ${all_srcs} )
target_link_libraries(generator ${libs})

## TODO: Precompilated header works well, but I don't know a license of PCHSupport_26.cmake which
## was downloaded from http://www.vtk.org/Bug/view.php?id=1260.
#OPTION(USEPCH "Build the project with precompiled-headers" ON)
#include(../cmake/PCHSupport_26.cmake)
#
#IF(NOT USEPCH)
#    MESSAGE(STATUS "NOT using precompiled-header")
#ELSE(NOT USEPCH)
#    MESSAGE(STATUS "Using precompiled-header")
#    add_precompiled_header(generator ${CMAKE_CURRENT_SOURCE_DIR}/generator_pch.h)
#ENDIF(NOT USEPCH)

set(dgen_build_conf ${CMAKE_BINARY_DIR}/CMakeFiles/build.txt)
set(jambi_inc ${CMAKE_BINARY_DIR}/CMakeFiles/qtjambi_masterinclude.h)
if(	NOT "${packages_in_build_txt}" STREQUAL "${packages}"
	OR NOT EXISTS ${dgen_build_conf}
	OR NOT EXISTS ${jambi_inc})
    file(REMOVE ${dgen_build_conf})
    file(REMOVE ${jambi_inc})

	# Explicitly include qglobal.h before all the »master includes« to make
	# sure Q_CORE_EXPORT and other macros are already defined for all
	# processed headers. Otherwise, the parser would choke on classes in files
	# included before "qglobal.h" in <QtCore/QtCore> using one of these macros
	# (e.g. QXmlStreamReader).
	file(APPEND ${jambi_inc} "#include <${QT_QTCORE_INCLUDE_DIR}/qglobal.h>\n")

    file(APPEND ${dgen_build_conf} "<typesystem>\n")
    foreach(package_normal ${packages})
    	string(TOLOWER ${package_normal} package)
    	string(TOUPPER ${package_normal} package_upper)
    	file(APPEND ${dgen_build_conf} "	<load-typesystem name=\"typesystem_${package}.xml\" generate=\"yes\" />\n")
    	# only append include if we have QT_QT${MODULE}_INCLUDE_DIR defined, otherwise handle customly
    	if(NOT ${QT_QT${package_upper}_INCLUDE_DIR} STREQUAL "")
        	file(APPEND ${jambi_inc} "#include <${QT_QT${package_upper}_INCLUDE_DIR}/Qt${package_normal}>\n")
        endif()
    endforeach()
    file(APPEND ${dgen_build_conf} "</typesystem>\n")
    set(packages_in_build_txt ${packages} CACHE INTERNAL "")
    # merge include file for Qwt
    if(BUILD_QT_QWT)
        file(READ "${CMAKE_SOURCE_DIR}/include/qwt_masterinclude.h" jambi_inc_qwt)
        file(APPEND ${jambi_inc} ${jambi_inc_qwt})
    endif()
endif()

set(gen_sources)
foreach(package_normal ${packages})
    string(TOLOWER ${package_normal} package)
    set(gen_sources ${gen_sources} ${CMAKE_CURRENT_SOURCE_DIR}/typesystem_${package}.xml)
    set(d_inc_file_found d_inc_file_found-NOTFOUND)
    find_file(d_inc_file_found typesystem_${package}-java.java PATHS ${CMAKE_CURRENT_SOURCE_DIR}/)
    if(d_inc_file_found)
	    set(gen_sources ${gen_sources} ${d_inc_file_found})
    endif()
endforeach()
mark_as_advanced(d_inc_file_found)
set(d_inc_file_found 1)

foreach(path ${QT_INCLUDES})
    set(inc_paths_tmp ${path}${sep}${inc_paths_tmp})
endforeach()
set(inc_paths ${inc_paths}${sep}${inc_paths_tmp})

if(${CMAKE_BINARY_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
    set(out_dir ${CMAKE_SOURCE_DIR})
else()
    set(out_dir ${CMAKE_BINARY_DIR}/build)
endif()
set(dgen_impl ${out_dir}/cpp/qt_core/ArrayOps_shell.cpp)
add_custom_command(OUTPUT ${dgen_impl}
	COMMAND ${CMAKE_COMMAND} -E remove -f ${dgen_impl}
	COMMAND "generator"
	ARGS ${GEN_OPT} --include-paths=${inc_paths}
	    --output-directory=${out_dir}
	    --source-directory=${CMAKE_CURRENT_SOURCE_DIR}
	    ${CMAKE_BINARY_DIR}/CMakeFiles/qtjambi_masterinclude.h
	    ${CMAKE_BINARY_DIR}/CMakeFiles/build.txt
	COMMENT "Generating binding..."
	DEPENDS generator ${gen_sources} ${CMAKE_BINARY_DIR}/CMakeFiles/build.txt
)
add_custom_target(dgen ALL DEPENDS ${dgen_impl} COMMENT "")
