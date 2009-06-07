PROJECT(generator CXX C)
cmake_minimum_required(VERSION 2.6)
FIND_PACKAGE(Qt4 REQUIRED)

## Force Release settings
STRING(TOUPPER "${CMAKE_BUILD_TYPE}" build_type_upper)
set(CMAKE_CXX_FLAGS_${build_type_upper} ${CMAKE_CXX_FLAGS_RELEASE}) 
get_property(dir_prop DIRECTORY 
	    PROPERTY COMPILE_DEFINITIONS_RELEASE)
set_property(DIRECTORY PROPERTY COMPILE_DEFINITIONS_${build_type_upper} ${dir_prop})

## Sources
set(srcs
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

#win32-msvc2005:{
#        QMAKE_CXXFLAGS += -wd4996
#        QMAKE_CFLAGS += -wd4996
#}

#if(MSVC)
#    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zm500 /Zc:wchar_t-")
#endif(MSVC)

#win32-msvc.net {
#        QMAKE_CXXFLAGS += /Zm500
#        QMAKE_CXXFLAGS -= -Zm200
#        QMAKE_CFLAGS -= -Zm200
#}

## Includes path.
set(inc_paths
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

set(inc_paths
    ${inc_paths}
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
include_directories(${inc_paths})
add_executable(generator ${all_srcs} )
target_link_libraries(generator ${libs})

## TODO: Precompilated header work well, but I don`t known license of PCHSupport_26.cmake.
## downloaded from http://www.vtk.org/Bug/view.php?id=1260. 
#OPTION(USEPCH "Build the project with precompiled-headers" ON)
#include(../cmake/PCHSupport_26.cmake)
#	
#IF(NOT USEPCH)
#    MESSAGE(STATUS "NOT using precompiled-header")
#ELSE(NOT USEPCH)
#    MESSAGE(STATUS "Using precompiled-header")
#    add_precompiled_header(generator ${CMAKE_CURRENT_SOURCE_DIR}/generator_pch.h)
#ENDIF(NOT USEPCH)

macro(add_dgen_target package)
    string(TOLOWER ${package} package)
    set(dgen_build_conf ${CMAKE_BINARY_DIR}/CMakeFiles/built_${package}.txt)
    set(dgen_build_conf_req ${CMAKE_BINARY_DIR}/CMakeFiles/built_${package}_with_req.txt)
    file(REMOVE ${dgen_build_conf})
    file(REMOVE ${dgen_build_conf_req})
    file(APPEND ${dgen_build_conf} "<typesystem>\n")
    file(APPEND ${dgen_build_conf_req} "<typesystem>\n")
    foreach(req ${ARGN})
	string(TOLOWER ${req} req_lower)
	file(APPEND ${dgen_build_conf} "	<load-typesystem name=\"typesystem_${req_lower}.xml\" generate=\"no\" />\n")
	file(APPEND ${dgen_build_conf_req} "	<load-typesystem name=\"typesystem_${req_lower}.xml\" generate=\"yes\" />\n")
    endforeach(req ${ARGN})

    if(${package} STREQUAL "all")
	foreach(pack ${ARGN})   
	    set(dgen_impl ${CMAKE_BINARY_DIR}/cpp/qt_${pack}/metainfo.cpp)  ## Temporary     
	    break(pack ${ARGN})  
	endforeach(pack ${ARGN})  	
    else(${package} STREQUAL "all")
	set(dgen_impl ${CMAKE_BINARY_DIR}/cpp/qt_${package}/qt_${package}.pri)  
	set(gen_sources ${gen_sources} ${CMAKE_SOURCE_DIR}/generator/typesystem_${package}.xml
		${CMAKE_SOURCE_DIR}/generator/typesystem_${package}-java.java)
	file(APPEND ${dgen_build_conf} "	<load-typesystem name=\"typesystem_${package}.xml\" generate=\"yes\" />\n")
	file(APPEND ${dgen_build_conf_req} "	<load-typesystem name=\"typesystem_${package}.xml\" generate=\"yes\" />\n")
    endif(${package} STREQUAL "all")

    file(APPEND ${dgen_build_conf} "</typesystem>\n")
    file(APPEND ${dgen_build_conf_req} "</typesystem>\n")

    foreach(pack ${ARGN})   
	string(TOLOWER ${pack} pack_lower)
	set(gen_sources ${gen_sources} ${CMAKE_SOURCE_DIR}/generator/typesystem_${pack_lower}.xml
		${CMAKE_SOURCE_DIR}/generator/typesystem_${pack_lower}-java.java)
    endforeach(pack ${ARGN})

    add_custom_command(OUTPUT ${dgen_impl}
		    COMMAND ${CMAKE_COMMAND} -E remove -f ${dgen_impl}
		    COMMAND "generator"
		    ARGS ${GEN_OPT}  --no-repreprocess --qt-include-directory=${QT_INCLUDE_DIR} --output-directory=./ 
			--source-directory=${CMAKE_SOURCE_DIR}/generator
			qtjambi_masterinclude.h 
			${dgen_build_conf}
		    COMMENT "Generating binding..."
		    DEPENDS  generator ${gen_sources} 
		)
    add_custom_target(dgen_${package} DEPENDS ${dgen_impl} COMMENT "")
endmacro(add_dgen_target target package required)

foreach(pack ${packages})   
    set(gen_typesystem ${gen_typesystem} ${CMAKE_SOURCE_DIR}/generator/typesystem_${pack}.xml)
    set(gen_sources ${gen_sources} ${CMAKE_SOURCE_DIR}/generator/typesystem_${pack}-java.java)
endforeach(pack ${packages})

set(dgen_build_conf ${CMAKE_BINARY_DIR}/CMakeFiles/build.txt)
file(REMOVE ${dgen_build_conf})
file(APPEND ${dgen_build_conf} "<typesystem>\n")
foreach(package ${packages})
    file(APPEND ${dgen_build_conf} "	<load-typesystem name=\"typesystem_${package}.xml\" generate=\"yes\" />\n")
endforeach(package ${packages})
file(APPEND ${dgen_build_conf} "</typesystem>\n")

# macro(add_sources_for_generating)	
#     set(parameters_list_file ${CMAKE_BINARY_DIR}/CMakeFiles/dgen_parameters)
#     if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)	
# 	file(REMOVE ${parameters_list_file})
# 	foreach(arg ${ARGN})
# 	    file(APPEND ${parameters_list_file} "${arg}\n")
# 	endforeach(arg)
# 	set(param @${parameters_list_file})
#     elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux)
# 	set(param ${parameters})
#     endif(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
#     foreach(dgen_impl ${ARGN})
# 	add_custom_command(OUTPUT ${dgen_impl}
# 			    COMMAND ${CMAKE_COMMAND} -E remove -f ${param}
# 			    COMMAND "generator"
# 			    ARGS ${GEN_OPT}  --qt-include-directory=${QT_INCLUDE_DIR} --output-directory=${CMAKE_BINARY_DIR}
# 							--source-directory=${CMAKE_SOURCE_DIR}/generator 
# 							qtjambi_masterinclude.h  
# 							${CMAKE_BINARY_DIR}/CMakeFiles/build.txt
# 			    COMMENT "Generating binding..."
# 			    DEPENDS  generator ${gen_typesystem} ${gen_sources} 
# 			)
#     endforeach(dgen_impl ${ARGN})
#     add_custom_target(dgen DEPENDS ${ARGN})
# endmacro(add_sources_for_generating)

set(gen_sources)
foreach(package ${packages})   
    set(gen_sources ${gen_sources} ${CMAKE_SOURCE_DIR}/generator/typesystem_${package}.xml)
    find_file(d_inc_file_found typesystem_${package}-java.java PATHS ${CMAKE_SOURCE_DIR}/generator/) 
    if(d_inc_file_found)
	set(${CMAKE_SOURCE_DIR}/generator/typesystem_${package}-java.java)
    endif(d_inc_file_found)
endforeach(package ${packages})
mark_as_advanced(d_inc_file_found)
set(d_inc_file_found 1)
	
foreach(package ${packages})   
    set(dgen_impl ${CMAKE_BINARY_DIR}/cpp/qt_${package}/qt_${package}.pri) 
    break(package ${packages}) 
endforeach(package ${packages})    

add_custom_command(OUTPUT ${dgen_impl}
	COMMAND ${CMAKE_COMMAND} -E remove -f ${dgen_impl}
	COMMAND "generator"
	ARGS ${GEN_OPT}  --qt-include-directory=${QT_INCLUDE_DIR} --output-directory=${CMAKE_BINARY_DIR}
	    --source-directory=${CMAKE_SOURCE_DIR}/generator 
	    qtjambi_masterinclude.h  
	    ${CMAKE_BINARY_DIR}/CMakeFiles/build.txt
	COMMENT "Generating binding..."
	DEPENDS  generator ${gen_sources}
	)       
add_custom_target(dgen DEPENDS ${dgen_impl} COMMENT "")

macro(add_sources_for_generating)
    foreach(source ${ARGN})
	add_custom_command(OUTPUT "${source}"
		COMMAND ""
		ARGS ""
		DEPENDS ${dgen_impl}
		COMMENT ""
		)
    endforeach(source ${ARGN})
endmacro(add_sources_for_generating)