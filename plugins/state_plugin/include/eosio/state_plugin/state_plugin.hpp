#pragma once

#include <appbase/application.hpp>
#include <eosio/chain_plugin/chain_plugin.hpp>
#include <boost/thread/mutex.hpp>

namespace eosio {

using namespace appbase;

class state_plugin : public appbase::plugin<state_plugin> {
public:
    APPBASE_PLUGIN_REQUIRES((state_plugin))

    state_plugin();
    virtual ~state_plugin();

    void set_program_options(options_description&, options_description& cfg) override;
    void plugin_initialize(const variables_map& options);
    void plugin_startup();
    void plugin_shutdown();

private:
    bool configured_{};
    chain_plugin* chain_plugin_{};
    boost::signals2::connection irreversible_block_conn_;
    std::ofstream state_file;
    boost::mutex flock;
};

}
