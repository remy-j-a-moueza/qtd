cmake_minimum_required(VERSION 2.6)
find_package(Qt4 REQUIRED)

## TODO: Is this definition correct?  
add_definitions(-DQDESIGNER_UILIB_LIBRARY)
set (QT_USE_QTXML true)
include (${QT_USE_FILE})
include_directories( ${QT_INCLUDE_DIR}
			${CMAKE_CURRENT_SOURCE_DIR}
			${CMAKE_CURRENT_SOURCE_DIR}/d )

########### next target ###############

set(uic_bin_SRCS 
   customwidgetsinfo.cpp 
   databaseinfo.cpp 
   driver.cpp 
   treewalker.cpp 
   ui4.cpp 
   uic.cpp 
   validator.cpp 
   ${CMAKE_CURRENT_SOURCE_DIR}/d/dextractimages.cpp
   ${CMAKE_CURRENT_SOURCE_DIR}/d/dwritedeclaration.cpp 
   ${CMAKE_CURRENT_SOURCE_DIR}/d/dwriteincludes.cpp 
   ${CMAKE_CURRENT_SOURCE_DIR}/d/dwriteicondata.cpp 
   ${CMAKE_CURRENT_SOURCE_DIR}/d/dwriteicondeclaration.cpp 
   ${CMAKE_CURRENT_SOURCE_DIR}/d/dwriteiconinitialization.cpp 
   ${CMAKE_CURRENT_SOURCE_DIR}/d/dwriteinitialization.cpp 
   main.cpp )

add_executable(duic ${uic_bin_SRCS})
set_target_properties(duic PROPERTIES OUTPUT_NAME duic)
set_target_properties(duic PROPERTIES COMPILE_FLAGS -DQT_UIC_D_GENERATOR)

target_link_libraries(duic  ${QT_QTCORE_LIBRARY} ${QT_QTXML_LIBRARY})

install(TARGETS duic DESTINATION ${CMAKE_INSTALL_PREFIX}/bin  COMPONENT qtd_tools)

