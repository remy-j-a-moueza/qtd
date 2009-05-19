cmake_minimum_required(VERSION 2.6)
find_package(Qt4 REQUIRED)

include_directories( ${QT_INCLUDE_DIR}
			${CMAKE_CURRENT_SOURCE_DIR})

########### next target ###############

set(drcc_bin_SRCS 
   main.cpp rcc.cpp )

set (QT_USE_QTMAIN true)
set (QT_USE_QTGUI false)
set (QT_USE_QTXML true)
include(${QT_USE_FILE} ${CMAKE_CURRENT_SOURCE_DIR}) 

add_executable(drcc ${drcc_bin_SRCS})
add_definitions(-DQT_UIC_D_GENERATOR)

target_link_libraries(drcc  ${QT_LIBRARIES} )

install(TARGETS drcc DESTINATION ${CMAKE_INSTALL_PREFIX}/bin COMPONENT qtd_tools)

