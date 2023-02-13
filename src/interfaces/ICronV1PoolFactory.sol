// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

interface ICronV1PoolFactory {
  // Events
  event TWAMMPoolCreated(address indexed pool, address indexed token0, address indexed token1, uint256 poolType);

  // Functions
  function create(
    address _token0,
    address _token1,
    string memory _name,
    string memory _symbol,
    uint256 _poolType,
    address _pauser
  ) external returns (address);

  function transferOwnership(
    address _newOwner,
    bool _direct,
    bool _renounce
  ) external;

  function claimOwnership() external;

  function owner() external view returns (address);

  function getPool(
    address _token0,
    address _token1,
    uint8 _poolType
  ) external view returns (address pool);
}
