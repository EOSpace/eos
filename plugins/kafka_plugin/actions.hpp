#pragma once

#include <eosio/chain/types.hpp>
#include <eosio/chain/asset.hpp>
#include <eosio/chain_plugin/chain_plugin.hpp>
#include "types.hpp"

namespace kafka {

using namespace std;
using namespace eosio::chain;

struct buyram {
   name buyer;
   name receiver;
   asset tokens;
};

struct buyrambytes {
   name buyer;
   name receiver;
   uint32_t bytes;
};

struct sellram {
   name receiver;
   int64_t bytes;
};

struct delegatebw {
   name from;
   name receiver;
   asset stake_net_quantity;
   asset stake_cpu_quantity;
   uint8_t transfer;
};

struct undelegatebw {
   name from;
   name receiver;
   asset unstake_net_quantity;
   asset unstake_cpu_quantity;
};

struct voteproducer {
   name voter;
   name proxy;
   std::vector<name> producers;
};

struct regproxy {
   name proxy;
   uint8_t isproxy;
};

struct regproducer {
   name producer;
   public_key_type producer_key;
   std::string url;
   uint16_t location;
};

struct unregprod {
   name producer;
};

struct rmvproducer {
   name producer;
};

struct claimrewards {
   name owner;
};

struct claimbonus {
   name owner;
};

struct create {
   name issuer;
   asset maximum_supply;
};

struct issue {
   name to;
   asset quantity;
   string memo;
};

struct transfer {
   name from;
   name to;
   asset quantity;
   string memo;
};

struct ram_deal {
   uint64_t global_seq;
   int64_t bytes; // positive: buy; negative: sell
   asset quantity;

   name_t action; // buyram/buyrambytes/sellram; DO NOT FC_REFLECT!
};

struct claimed_rewards {
   name owner;
   asset quantity; // total claimed rewards
   asset voter_bonus_balance; // only valid for eoscochain
};

// only valid for eoscochain
struct voter_bonus {
   name producer;
   asset balance;
};

// only valid for eoscochain
struct claimed_bonus {
   name owner;
   asset quantity; // total claimed bonus
   vector<voter_bonus> balances; // voter bonus balance of every producer who is voted for
};

struct voter_info {
   name owner;
   name proxy;
   std::vector<name> producers;
   int64_t staked;
   double last_vote_weight;
   double proxied_vote_weight;
   bool is_proxy;
   uint64_t last_change_time; // only valid for eoscochain
   uint32_t flags1;
   uint32_t reserved2;
   asset reserved3;
};

struct producer_info {
   name owner;
   double total_votes;
   public_key_type producer_key;
   bool is_active;
   string url;
   uint32_t unpaid_blocks;
   uint64_t last_claim_time;
   uint16_t location;
};

struct producer {
   name owner;
   double total_votes;
};

struct voter {
   name owner;
   name proxy;
   int64_t staked;
   double last_vote_weight;
   double proxied_vote_weight;
   bool is_proxy;
   uint64_t last_change_time; // only valid for eoscochain

   vector<producer> producers;
};

}

FC_REFLECT(kafka::buyram, (buyer)(receiver)(tokens))
FC_REFLECT(kafka::buyrambytes, (buyer)(receiver)(bytes))
FC_REFLECT(kafka::sellram, (receiver)(bytes))
FC_REFLECT(kafka::delegatebw, (from)(receiver)(stake_net_quantity)(stake_cpu_quantity)(transfer))
FC_REFLECT(kafka::undelegatebw, (from)(receiver)(unstake_net_quantity)(unstake_cpu_quantity))
FC_REFLECT(kafka::voteproducer, (voter)(proxy)(producers))
FC_REFLECT(kafka::regproxy, (proxy)(isproxy))
FC_REFLECT(kafka::regproducer, (producer)(producer_key)(url)(location))
FC_REFLECT(kafka::unregprod, (producer))
FC_REFLECT(kafka::rmvproducer, (producer))
FC_REFLECT(kafka::claimrewards, (owner))
FC_REFLECT(kafka::claimbonus, (owner))
FC_REFLECT(kafka::create, (issuer)(maximum_supply))
FC_REFLECT(kafka::issue, (to)(quantity)(memo))
FC_REFLECT(kafka::transfer, (from)(to)(quantity)(memo))
FC_REFLECT(kafka::ram_deal, (global_seq)(bytes)(quantity))
FC_REFLECT(kafka::claimed_rewards, (owner)(quantity)(voter_bonus_balance))
FC_REFLECT(kafka::voter_bonus, (producer)(balance))
FC_REFLECT(kafka::claimed_bonus, (owner)(quantity)(balances))
FC_REFLECT(kafka::voter_info, (owner)(proxy)(producers)(staked)
                              (last_vote_weight)(proxied_vote_weight)
                              (is_proxy)(last_change_time)(flags1)(reserved2)(reserved3))
FC_REFLECT(kafka::producer_info, (owner)(total_votes)(producer_key)(is_active)
                                 (url)(unpaid_blocks)(last_claim_time)(location))
FC_REFLECT(kafka::producer, (owner)(total_votes))
FC_REFLECT(kafka::voter, (owner)(proxy)(staked)(last_vote_weight)(proxied_vote_weight)
                         (is_proxy)(last_change_time)(producers))
