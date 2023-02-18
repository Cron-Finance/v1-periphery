// (c) Copyright 2023, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

library Standard {
  uint256 internal constant MINIMUM_LIQUIDITY = 1000;
}

library CrossChain {
  address internal constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
}

library GoerliChain {
  address internal constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
  address internal constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
  address internal constant FACTORY = 0xa69BE5c9a20cd04C949718d564C643bA5dCDA47f;
}