// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { IVault } from "../src/balancer-core-v2/vault/interfaces/IVault.sol";
import { TestToken } from "../src/balancer-core-v2/test/TestToken.sol";
import { ICronV1PoolFactory } from "../src/interfaces/ICronV1PoolFactory.sol";
import { Standard, CrossChain, GoerliChain } from "../src/libraries/Constants.sol";

import { AtomicActions } from "../src/AtomicActions.sol";
import { NonAtomicActions } from "../src/NonAtomicActions.sol";

// forge script script/DeployScripts.s.sol:CronV1TestPool --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
// TO Address: 0x59333B737142340D57d8c1F62BfAB3334900243a
// T1 Address: 0x181161A3B61Add8E1328e5A042961Bc04dFd4845
// T0/T1 Pool 0x43ecE196d9987A0f01d06EfAA9454f91ab72aAaE

contract CronV1TestPool is Script {
  function run() external {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    uint256 mintAmount = 2**112;
    TestToken token0 = new TestToken(vm.envAddress("ETH_FROM"), "T0", "T0", 18);
    TestToken token1 = new TestToken(vm.envAddress("ETH_FROM"), "T1", "T1", 18);
    token0.mint(vm.envAddress("ETH_FROM"), mintAmount);
    token1.mint(vm.envAddress("ETH_FROM"), mintAmount);
    address pool = ICronV1PoolFactory(GoerliChain.FACTORY).create(address(token0), address(token1), "T0-T1-Liquid", "T0/T1/L", 1);
    vm.stopBroadcast();
  }
}

// forge script script/DeployScripts.s.sol:PeripheryTest --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
// Atomic Address: 0xAb3733c1A8A1f62AD4E149515084D198370D86da
// NonAtomic Address: 0x23e4AdDeAe6f4E2fb9e89A0E771841d10C5f1769
contract PeripheryTest is Script {
  function run() external {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    AtomicActions a = new AtomicActions();
    NonAtomicActions n = new NonAtomicActions();
    vm.stopBroadcast();
  }
}
