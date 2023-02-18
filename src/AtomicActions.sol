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

contract AtomicActions {

  /// @notice Swap function with additional checks in place to ensure users don't lose funds by interacting
  ///         with TWAMM pools improperly. This function is only for regular swappers < SwapType.RegularSwap > 
  ///         and will be more gas expensive due to the additional checks.
  /// @param  _amountIn the amount of tokenIn sold to the pool
  /// @param  _slippage specified in percentage between 0 -> 10%, ex: 1 = 1%
  /// @param  _poolType the pool type of the pair, can be (Stable, Liquid, or Volatile). This affects the fee
  ///         tier and gas used to interact with the pool due to the OBI of executeVirtualOrders
  /// @param  _tokenIn the address of the token sold to the pool
  /// @param  _tokenOut the address of the token purchased from the pool
  /// @param  _to the address where the purchased tokens should be sent to
  /// @return amountOut the amount purchased and sent to the 
  ///
  function swap(
    uint256 _amountIn,
    uint256 _slippage,
    uint256 _poolType,
    address _tokenIn,
    address _tokenOut,
    address _to    
  ) external returns (uint256 amountOut) {
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
    require(_slippage >= 0 && _slippage < 10, "invalid slippage tolerance");
    // check pool has minimum liquidity
    bytes32 poolId = ICronV1Pool(pool).POOL_ID();
    (, uint256[] memory balances,) = IVault(CrossChain.VAULT).getPoolTokens(poolId);
    require(balances[0] > Standard.MINIMUM_LIQUIDITY && balances[1] > Standard.MINIMUM_LIQUIDITY, "pool does not have liquidity");
    // TODO: check current price with the oracle for setting a sane slippage value
    amountOut = CronV1PoolActions.swap(_amountIn, _slippage, 0, ICronV1PoolEnums.SwapType.RegularSwap, _tokenIn, pool, _to);
  }

  /// @notice Join function with additional checks in place to ensure users don't lose funds by interacting
  ///         with TWAMM pools improperly. This function is only for normal Joins < JoinType.Join > 
  ///         and will be more gas expensive due to the additional checks.
  /// @param  _liquidity0 the amount of token0 liquidity to be added
  /// @param  _liquidity1 the amount of token1 liquidity to be added
  /// @param  _pool the address of the pool to add liquidity to
  /// @param  _to the address where LP tokens should be sent to
  ///
  function join(
    uint256 _liquidity0,
    uint256 _liquidity1,
    address _pool,
    address _to
  ) external {
    // check non-zero pool address
    require(_pool != address(0), "zero pool address");
    // check valid Cron V1 Pool
    bytes32 poolId = ICronV1Pool(_pool).POOL_ID();
    require(poolId != "", "invalid pool address");
    // check valid liquidity amounts
    require(_liquidity0 > Standard.MINIMUM_LIQUIDITY && _liquidity1 > Standard.MINIMUM_LIQUIDITY, "liquidity amounts too low");
    // check user balances
    (IERC20[] memory tokens, , ) = IVault(CrossChain.VAULT).getPoolTokens(poolId);
    require(tokens[0].balanceOf(msg.sender) >= _liquidity0, "insufficient token0 user balance");
    require(tokens[1].balanceOf(msg.sender) >= _liquidity1, "insufficient token1 user balance");
    // TODO: check pool liquidity to set proper maxAmountsIn
    uint256[] memory maxAmountsIn = new uint256[](tokens.length);
    for (uint256 i; i < tokens.length; i++) {
      maxAmountsIn[i] = type(uint256).max;
    }
    CronV1PoolActions.join(_pool, _to, _liquidity0, _liquidity1, ICronV1PoolEnums.JoinType.Join, maxAmountsIn);
  }

  /// @notice Exit function with additional checks in place to ensure users don't lose funds by interacting
  ///         with TWAMM pools improperly. This function is only for burning liquidity < ExitType.Exit > 
  ///         and will be more gas expensive due to the additional checks.
  /// @param  _numLPTokens the amount of token0 liquidity to be added
  /// @param  _pool the address of the pool to remove liquidity from
  /// @param  _to the address where tokens should be sent to
  ///
  function exit(
    uint256 _numLPTokens,
    address _pool,
    address _to
  ) external {
    // check non-zero pool address
    require(_pool != address(0), "zero pool address");
    // check valid Cron V1 Pool
    bytes32 poolId = ICronV1Pool(_pool).POOL_ID();
    require(poolId != 0, "invalid pool address");
    // check valid liquidity amounts
    require(_numLPTokens > 0, "invalid amount of LP tokens");
    // check user LP balances
    require(IERC20(_pool).balanceOf(msg.sender) >= _numLPTokens, "insufficient LP tokens balance");
    CronV1PoolActions.exit(_numLPTokens, ICronV1PoolEnums.ExitType.Exit, _pool, _to);
  }
}