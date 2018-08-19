file(GLOB HEADERS "include/eosio/kafka_plugin/*.hpp")
add_library( kafka_plugin
             kafka_plugin.cpp
             ${HEADERS} )

target_link_libraries( kafka_plugin appbase fc )
target_include_directories( kafka_plugin PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include" )
