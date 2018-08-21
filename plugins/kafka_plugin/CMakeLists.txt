if(BUILD_KAFKA_PLUGIN)
    file(GLOB HEADERS "include/eosio/kafka_plugin/*.hpp")
    add_library( kafka_plugin
                kafka_plugin.cpp
                ${HEADERS} )

    target_link_libraries( kafka_plugin
          PUBLIC chain_plugin eosio_chain appbase fc
          )
    target_include_directories( kafka_plugin PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include" )
else()
  message("kafka_plugin not selected and will be omitted.")
endif()