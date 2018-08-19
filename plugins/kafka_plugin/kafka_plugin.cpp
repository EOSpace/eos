/**
 *  @file
 *  @copyright defined in eos/LICENSE.txt
 */
#include <eosio/kafka_plugin/kafka_plugin.hpp>

namespace eosio {
   static appbase::abstract_plugin& _kafka_plugin = app().register_plugin<kafka_plugin>();

class kafka_plugin_impl {
   public:
};

kafka_plugin::kafka_plugin():my(new kafka_plugin_impl()){}
kafka_plugin::~kafka_plugin(){}

void kafka_plugin::set_program_options(options_description&, options_description& cfg) {
   cfg.add_options()
         ("option-name", bpo::value<string>()->default_value("default value"),
          "Option Description")
         ;
}

void kafka_plugin::plugin_initialize(const variables_map& options) {
   try {
      if( options.count( "option-name" )) {
         // Handle the option
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
