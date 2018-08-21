/**
 *  @file
 *  @copyright defined in eos/LICENSE.txt
 */
#include <eosio/kafka_plugin/kafka_plugin.hpp>

#include <librdkafka/rdkafkacpp.h>

namespace eosio {
   static appbase::abstract_plugin& _kafka_plugin = app().register_plugin<kafka_plugin>();

class kafka_plugin_impl {
   public:
      bool configured{false};
};

kafka_plugin::kafka_plugin():my(new kafka_plugin_impl()){}
kafka_plugin::~kafka_plugin(){}

void kafka_plugin::set_program_options(options_description&, options_description& cfg) {
   cfg.add_options()
         ("kafka-brokers,b", bpo::value<string>()->default_value("localhost:9092"),
          "Kafka broker address string, separated by comma. See: https://kafka.apache.org/quickstart"
							" If not specified then plugin is disabled. Default 'localhost:9092' is used if not specified"
              " Example: localhost:9092,localhost:9093,localhost:9094")
         ;
}

void kafka_plugin::plugin_initialize(const variables_map& options) {
   try {
      if( options.count( "kafka-brokers" )) {
					ilog( "initializing kafka_plugin" );
          my->configured = true;

					std::string brokers_list = options.at( "kafka-brokers" ).as<std::string>();
					ilog( "connecting to ${u}", ("u", brokers_list));

      } else {
					wlog( "eosio::kafka_plugin configured, but no --kafka-brokers specified." );
					wlog( "kafka_plugin disabled." );
      }
   } FC_LOG_AND_RETHROW()
}

void kafka_plugin::plugin_startup() {
   // Make the magic happen
}

void kafka_plugin::plugin_shutdown() {
   // OK, that's enough magic
}

}
