// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

pragma experimental ABIEncoderV2;

import "forge-std/console.sol";

import "./balancer-core-v2/vault/interfaces/IVault.sol";
import "./balancer-core-v2/vault/interfaces/IAsset.sol";

import "./balancer-core-v2/lib/openzeppelin/IERC20.sol";

import "./balancer-core-v2/test/WETH.sol";

import "./interfaces/ICronV1Pool.sol";
import { ICronV1PoolEnums } from "./interfaces/pool/ICronV1PoolEnums.sol";
import "./interfaces/ICronV1PoolFactory.sol";

import { CronV1PoolActions } from "./libraries/CronV1PoolActions.sol";
import { Standard, CrossChain, GoerliChain } from "./libraries/Constants.sol";

contract NonAtomicActions {

  /// @notice ltSwap function with additional checks in place to ensure users don't lose funds by interacting
  ///         with TWAMM pools improperly. This function is only for long term swappers < SwapType.LongTermSwap > 
  ///         and will be more gas expensive due to the additional checks.
  /// @param  _amountIn the amount of tokenIn sold to the pool
  /// @param  _intervals number of intervals trade should be executed in
  /// @param  _poolType the pool type of the pair, can be (Stable, Liquid, or Volatile). This affects the fee
  ///         tier and gas used to interact with the pool due to the OBI of executeVirtualOrders
  /// @param  _tokenIn the address of the token sold to the pool
  /// @param  _tokenOut the address of the token purchased from the pool
  /// @param  _to the address where the purchased tokens should be sent to
  ///
  function ltSwap(
    uint256 _amountIn,
    uint256 _intervals,
    uint256 _poolType,
    address _tokenIn,
    address _tokenOut,
    address _to
  ) external {
    // check valid token addresses
    require(_tokenIn != address(0), "invalid token in address");
    require(_tokenOut != address(0), "invalid token out address");
    // check valid pool type
    require(_poolType >= 0 && _poolType < 3, "invalid pool type");
    // check valid pool
    address pool = ICronV1PoolFactory(GoerliChain.FACTORY).getPool(_tokenIn, _tokenOut, uint8(_poolType));
    require(pool != address(0), "pool does not exist");
    // check correct amounts
    require(_amountIn > 0, "invalid amount in");
    // check user balances
    require(IERC20(_tokenIn).balanceOf(msg.sender) >= _amountIn, "insufficient balance");
    // check slippage tolerance
    require(_intervals > 0, "invalid intervals");
    // check pool has minimum liquidity
    bytes32 poolId = ICronV1Pool(pool).POOL_ID();
    (, uint256[] memory balances,) = IVault(CrossChain.VAULT).getPoolTokens(poolId);
    require(balances[0] > Standard.MINIMUM_LIQUIDITY && balances[1] > Standard.MINIMUM_LIQUIDITY, "pool does not have liquidity");
    CronV1PoolActions.swap(_amountIn, 0, _intervals, ICronV1PoolEnums.SwapType.LongTermSwap, _tokenIn, pool, _to);
  }

  /// @notice Withdraw function with additional checks in place to ensure users don't lose funds by interacting
  ///         with TWAMM pools improperly. This function is only for withdrawing proceeds < ExitType.Withdraw > 
  ///         and will be more gas expensive due to the additional checks.
  /// @param  _orderId the order you want to withdraw proceeds for
  /// @param  _pool the address of the pool to remove liquidity from
  /// @param  _to the address where tokens should be sent to
  ///
  function withdraw(
    uint256 _orderId,
    address _pool,
    address _to
  ) external {
    // check non-zero pool address
    require(_pool != address(0), "zero pool address");
    // check valid Cron V1 Pool
    bytes32 poolId = ICronV1Pool(_pool).POOL_ID();
    require(poolId != 0, "invalid pool address");
    (, , uint256 totalResults) = ICronV1Pool(_pool).getOrderIds(msg.sender, 0, 100);
    // check valid orderId
    require(_orderId >= 0 && _orderId < totalResults, "invalid order id");
    CronV1PoolActions.exit(_orderId, ICronV1PoolEnums.ExitType.Withdraw, _pool, _to);
  }

  /// @notice Cancel function with additional checks in place to ensure users don't lose funds by interacting
  ///         with TWAMM pools improperly. This function is only for canceling your LT order < ExitType.Cancel > 
  ///         and will be more gas expensive due to the additional checks.
  /// @param  _orderId the order you want to withdraw proceeds for
  /// @param  _pool the address of the pool to remove liquidity from
  /// @param  _to the address where tokens should be sent to
  ///
  function cancel(
    uint256 _orderId,
    address _pool,
    address _to
  ) external {
    // check non-zero pool address
    require(_pool != address(0), "zero pool address");
    // check valid Cron V1 Pool
    bytes32 poolId = ICronV1Pool(_pool).POOL_ID();
    require(poolId != 0, "invalid pool address");
    (, , uint256 totalResults) = ICronV1Pool(_pool).getOrderIds(msg.sender, 0, 100);
    // check valid orderId
    require(_orderId >= 0 && _orderId < totalResults, "invalid order id");
    CronV1PoolActions.exit(_orderId, ICronV1PoolEnums.ExitType.Cancel, _pool, _to);
  }
}