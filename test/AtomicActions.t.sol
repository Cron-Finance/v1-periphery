pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";

import "../src/balancer-core-v2/vault/Vault.sol";
import "../src/balancer-core-v2/test/WETH.sol";
import "../src/balancer-core-v2/test/TestToken.sol";

import "../src/interfaces/ICronV1Pool.sol";
import "../src/interfaces/ICronV1PoolFactory.sol";
import "../src/interfaces/pool/ICronV1PoolEnums.sol";
import { Standard, CrossChain, GoerliChain } from "../src/libraries/Constants.sol";

contract AtomicActions is Test {
  address public owner;
  TestToken public token0;
  TestToken public token1;
  address public pool;

  function setUp() public {
    owner = address(this);
    // create two mock tokens
    uint256 mintAmount = 2**112;
    token0 = new TestToken(owner, "T0", "T0", 18);
    token1 = new TestToken(owner, "T1", "T1", 18);
    token0.mint(owner, mintAmount);
    token0.mint(owner, mintAmount);
    // create a TWAMM pool
    pool = ICronV1PoolFactory(GoerliChain.FACTORY).create(
      address(token0),
      address(token1),
      "T0-T1-Liquid",
      "T0-T1-L",
      1
    );
  }
}
