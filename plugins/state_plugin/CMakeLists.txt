file(GLOB HEADERS "include/eosio/state_plugin/*.hpp")
add_library( state_plugin
             state_plugin.cpp
             ${HEADERS} )

target_link_libraries( state_plugin chain_plugin appbase )
target_include_directories( state_plugin PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include" )
