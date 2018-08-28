/**
 *  @file
 *  @copyright defined in eos/LICENSE.txt
 */
#include <eosio/kafka_plugin/kafka_plugin.hpp>
#include "cppkafka/producer.h"
#include "cppkafka/configuration.h"

namespace fc { class variant; }

namespace eosio {

static appbase::abstract_plugin& _kafka_plugin = app().register_plugin<kafka_plugin>();

class kafka_plugin_impl {
public:
  kafka_plugin_impl();
  ~kafka_plugin_impl();

  void consume_blocks();

  bool configured{false};

  void init();

  cppkafka::Configuration kafka_config;
  cppkafka::MessageBuilder kafka_blocks_builder;
  cppkafka::MessageBuilder kafka_tx_builder;
  cppkafka::MessageBuilder kafka_accounts_builder;

  // cppkafka::Producer kafka_blocks_producer;
  // cppkafka::Producer kakfa_tx_producer;
  // cppkafka::Producer kafka_accounts_producer;

  boost::thread consume_thread;
  std::atomic_bool done{false};
  std::atomic_bool startup{true};
};

kafka_plugin_impl::kafka_plugin_impl():kafka_blocks_builder("blocks"),kafka_tx_builder("transactions"),
kafka_accounts_builder("accounts") {
}

kafka_plugin_impl::~kafka_plugin_impl() {
   if (!startup) {
      try {
         ilog( "kafka_plugin shutdown in process please be patient this can take a few minutes" );

         consume_thread.join();
      } catch( std::exception& e ) {
         elog( "Exception on kafka_plugin shutdown of consume thread: ${e}", ("e", e.what()));
      }
   }
}

void kafka_plugin_impl::init() {

  // kafka_blocks_producer = cppkafka::Producer(kafka_config);
  // kafka_tx_producer = cppkafka::Producer(kafka_config);
  // kafka_accounts_producer = cppkafka::Producer(kafka_config);

  ilog( "Send blocks to kafka ==================================>" );
  ilog("starting kafka plugin thread");

  // consume_thread = boost::thread([this] { consume_blocks(); });
  startup = false;
}

////////////
// kafka_plugin
////////////

kafka_plugin::kafka_plugin()
:my(new kafka_plugin_impl)
{
}

kafka_plugin::~kafka_plugin()
{
}

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
          my->kafka_config = {
            { "metadata.broker.list", brokers_list }
          };
          my->init();
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
   my.reset();
}

}
