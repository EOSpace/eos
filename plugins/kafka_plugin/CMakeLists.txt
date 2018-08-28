if(BUILD_KAFKA_PLUGIN)
    file(GLOB HEADERS "include/eosio/kafka_plugin/*.hpp")
    add_library( kafka_plugin
                kafka_plugin.cpp
                ${HEADERS} )

    target_link_libraries( kafka_plugin
          PRIVATE cppkafka ${RDKAFKA_LIBRARY} ${Boost_LIBRARIES} pthread ssl crypto dl z
          PUBLIC chain_plugin eosio_chain appbase fc
          )

    target_include_directories( kafka_plugin
      PRIVATE ${RDKAFKA_INCLUDE_DIR}
      PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")
else()
  message("kafka_plugin not selected and will be omitted.")
endif()