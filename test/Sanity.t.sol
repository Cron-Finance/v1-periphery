pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";

import "../src/balancer-core-v2/vault/interfaces/IVault.sol";
import "../src/interfaces/ICronV1PoolFactory.sol";
import { CrossChain, GoerliChain } from "../src/libraries/Constants.sol";

contract Sanity is Test {

  function testGetVault() public {
    console.log(GoerliChain.FACTORY);
    address weth = address(IVault(CrossChain.VAULT).WETH());
    console.log("WETH", weth);
  }
  
}
