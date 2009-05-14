PROJECT(generator CXX C)
cmake_minimum_required(VERSION 2.6)
FIND_PACKAGE(Qt4 REQUIRED)

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
    classlistgenerator.h
    cppgenerator.h
    cppheadergenerator.h
    cppimplgenerator.h
    docparser.h
    generatorsetd.h
    dgenerator.h
    jumptable.h
    metainfogenerator.h
    metajavabuilder.h
    qdocgenerator.h
    uiconverter.h
    containergenerator.h
    generator.h
    main.h
    reporthandler.h
    typeparser.h
    typesystem.h
    asttoxml.h
    fileout.h
    generatorset.h
    metajava.h
    customtypes.h
    abstractmetabuilder.h
    abstractmetalang.h
    prigenerator.h
    
    ## rxx
    parser/ast.h
    parser/lexer.h
    parser/list.h
    parser/parser.h
    parser/rxx_allocator.h
    parser/rpp-allocator.h
    parser/smallobject.h
    parser/tokens.h
    parser/symbol.h
    parser/control.h
    parser/visitor.h
    parser/default_visitor.h
    parser/dumptree.h
    parser/binder.h
    parser/codemodel.h
    parser/codemodel_pointer.h
    parser/codemodel_fwd.h
    parser/type_compiler.h
    parser/name_compiler.h
    parser/declarator_compiler.h
    parser/class_compiler.h
    parser/codemodel_finder.h
    parser/compiler_utils.h
    
    # rpp
    parser/rpp/pp-cctype.h
    parser/rpp/pp-engine-bits.h
    parser/rpp/pp-engine.h
    parser/rpp/pp-environment.h
    parser/rpp/pp-fwd.h
    parser/rpp/pp-internal.h
    parser/rpp/pp-iterator.h
    parser/rpp/pp-macro-expander.h
    parser/rpp/pp-macro.h
    parser/rpp/pp-scanner.h
    parser/rpp/pp-string.h
    parser/rpp/pp-symbol.h
    parser/rpp/pp.h
    parser/rpp/preprocessor.h
    
)

## Resources.
set(res_files
    generator.qrc
)

#win32-msvc2005:{
#        QMAKE_CXXFLAGS += -wd4996
#        QMAKE_CFLAGS += -wd4996
#}

#win32-msvc.net {
#        QMAKE_CXXFLAGS += /Zm500
#        QMAKE_CXXFLAGS -= -Zm200
#        QMAKE_CFLAGS -= -Zm200
#}

## Includes path.
set(inc_paths
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../common
    ${CMAKE_CURRENT_SOURCE_DIR}/parser
    ${CMAKE_CURRENT_SOURCE_DIR}/parser/include
    ${CMAKE_CURRENT_SOURCE_DIR}/parser/rpp
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

foreach(package ${packages})   
    set(gen_sources ${gen_sources} ${CMAKE_SOURCE_DIR}/generator/typesystem_${package}.xml
	    ${CMAKE_SOURCE_DIR}/generator/typesystem_${package}-java.java)
endforeach(package ${packages})

foreach(package ${packages})   
    set(dgen_impl ${CMAKE_BINARY_DIR}/cpp/qt_${package}/qt_${package}.pri)       
    break(package ${packages})  
endforeach(package ${packages})    

add_custom_command(OUTPUT ${dgen_impl}
		COMMAND ${CMAKE_COMMAND} -E remove -f ${dgen_impl}
		COMMAND "generator"
		ARGS ${GEN_OPT}  --qt-include-directory=${QT_INCLUDE_DIR} --output-directory=../ 
		    --source-directory=${CMAKE_SOURCE_DIR}/generator
		    qtjambi_masterinclude.h 
		    build_opengl.txt
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
    endforeach(source ${allcppsources})
endmacro(add_sources_for_generating)