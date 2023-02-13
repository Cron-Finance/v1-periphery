pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";

import "../src/balancer-core-v2/vault/interfaces/IVault.sol";
import "../src/interfaces/ICronV1PoolFactory.sol";
import { Cross_Chain, Goerli_Chain } from "../src/libraries/Constants.sol";

contract Sanity is Test {

  function testGetVault() public {
    console.log(Goerli_Chain.FACTORY);
    address WETH = address(IVault(Cross_Chain.VAULT).WETH());
    console.log("WETH", WETH);
  }
  
}
