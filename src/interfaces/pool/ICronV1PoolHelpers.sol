// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;

pragma experimental ABIEncoderV2;

import { Order, PriceOracle, ExecVirtualOrdersMem } from "../Structs.sol";

interface ICronV1PoolHelpers {
  // solhint-disable-next-line func-name-mixedcase
  function POOL_ID() external view returns (bytes32);

  function getPriceOracle()
    external
    view
    returns (
      uint256 timestamp,
      uint256 token0U256F112,
      uint256 token1U256F112
    );

  function getOrderIds(
    address _owner,
    uint256 _offset,
    uint256 _maxResults
  )
    external
    view
    returns (
      uint256[] memory orderIds,
      uint256 numResults,
      uint256 totalResults
    );

  function getOrder(uint256 _orderId) external view returns (Order memory order);

  function getOrderIdCount() external view returns (uint256 nextOrderId);

  function getSalesRates() external view returns (uint256 salesRate0U112, uint256 salesRate1U112);

  function getVirtualReserves(uint256 _maxBlock, bool _paused)
    external
    view
    returns (ExecVirtualOrdersMem memory evoMem, uint256 blockNumber);

  function getLastVirtualOrderBlock() external view returns (uint256 lastVirtualOrderBlock);

  function getSalesRatesEndingPerBlock(uint256 _blockNumber)
    external
    view
    returns (uint256 salesRateEndingPerBlock0U112, uint256 salesRateEndingPerBlock1U112);

  function getShortTermFeePoints() external view returns (uint256);

  function getPartnerFeePoints() external view returns (uint256);

  function getLongTermFeePoints() external view returns (uint256);

  function getOrderAmounts() external view returns (uint256 orders0U112, uint256 orders1U112);

  function getProceedAmounts() external view returns (uint256 proceeds0U112, uint256 proceeds1U112);

  function getFeeShift() external view returns (uint256);

  function getCronFeeAmounts() external view returns (uint256 cronFee0U96, uint256 cronFee1U96);

  function isPaused() external view returns (bool);

  function isCollectingCronFees() external view returns (bool);

  function isCollectingBalancerFees() external view returns (bool);

  function getBalancerFee() external view returns (uint256);

  function getBalancerFeeAmounts() external view returns (uint256 balFee0U96, uint256 balFee1U96);
}
