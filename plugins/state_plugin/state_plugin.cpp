#include <eosio/state_plugin/state_plugin.hpp>
#include <fc/io/json.hpp>
#include <boost/algorithm/string.hpp>
#include <eosio/chain/controller.hpp>
#include <eosio/chain/trace.hpp>
#include <eosio/chain_plugin/chain_plugin.hpp>
#include <iostream>
#include <fstream>

namespace eosio {

using namespace std;
using namespace chain;
using boost::signals2::scoped_connection;

namespace bpo = boost::program_options;
using bpo::options_description;
using bpo::variables_map;

static appbase::abstract_plugin& _state_plugin = app().register_plugin<state_plugin>();

state_plugin::state_plugin() {}
state_plugin::~state_plugin() {}

void state_plugin::set_program_options(options_description&, options_description& cfg) {
    cfg.add_options()
            ("state-enable", bpo::value<bool>(), "State plugin enable")
            ("state-start-block-num", bpo::value<unsigned>()->default_value(1), "The block number which state plugin can take snapshot")
            ("state-snapshot-file", bpo::value<std::string>()->composing(), "File to append account creation information.")
            ;
}

void state_plugin::plugin_initialize(const variables_map& options) {
    if (not options.count("state-enable") || not options.at("state-enable").as<bool>()) {
        wlog("state_plugin disabled, since no --state-enable=true specified");
        return;
    }

    EOS_ASSERT(options.count("state-snapshot-file"), fc::invalid_arg_exception, "Missing value for --state-snapshot-file");
    // get option
    std::string fo = options.at( "state-snapshot-file" ).as<std::string>();
    ilog("Opening file ${u}", ("u", fo));
    state_file.open(fo, std::ios_base::out);

    ilog("Initialize state plugin");
    configured_ = true;
    unsigned start_block_num = options.at("state-start-block-num").as<unsigned>();

    chain_plugin_ = app().find_plugin<chain_plugin>();
    auto& chain = chain_plugin_->chain();
    auto ro_api = chain_plugin_->get_read_only_api();

    irreversible_block_conn_ = chain.irreversible_block.connect([=](const chain::block_state_ptr& b) {
        if (b->block_num == start_block_num) {
            auto& _chain = chain_plugin_->chain();
            chainbase::database& db = const_cast<chainbase::database&>( _chain.db() );
            const auto& account_idx = db.get_index<eosio::chain::account_index>().indices();
            chain_apis::read_only::get_account_params p;

            for( const auto& u : account_idx ) {
                ilog("query account on chain ${u}", ("u", u));
                p.account_name = u.name;
                auto res = ro_api.get_account(p);
                ilog("get_account: ${r}", ("r", res));

                boost::mutex::scoped_lock lock(flock);
                auto payload = fc::json::to_string(res, fc::json::legacy_generator);
                state_file << payload << std::endl;
                state_file.flush();
            }

            appbase::app().quit();
        }
    });
}

void state_plugin::plugin_startup() {
    if (not configured_) return;
    ilog("Starting state_plugin");
}

void state_plugin::plugin_shutdown() {
    if (not configured_) return;
    ilog("Stopping state_plugin");

    try {
        irreversible_block_conn_.disconnect();

        state_file.flush();
        state_file.close();
    } catch (const std::exception& e) {
        elog("Exception on state_plugin shutdown: ${e}", ("e", e.what()));
    }

    ilog("Stopped state_plugin");
}

}