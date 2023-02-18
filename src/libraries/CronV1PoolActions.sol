// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";

import "../balancer-core-v2/vault/interfaces/IVault.sol";
import "../balancer-core-v2/vault/interfaces/IAsset.sol";
import "../balancer-core-v2/test/WETH.sol";

import "../interfaces/ICronV1Pool.sol";
import "../interfaces/pool/ICronV1PoolEnums.sol";
import "../interfaces/ICronV1PoolFactory.sol";

import { CrossChain, GoerliChain } from "./Constants.sol";

library CronV1PoolActions {

  function join(
    address _pool,
    address _to,
    uint256 _liquidity0,
    uint256 _liquidity1,
    ICronV1Pool.JoinType _joinKind,
    uint256[] memory _maxAmountsIn
  ) internal {
    // setup parameters for joinPool
    uint256[] memory balances = new uint256[](2);
    balances[0] = _liquidity0;
    balances[1] = _liquidity1;
    bytes memory userData = abi.encode(_joinKind, new uint256[](2));
    bytes32 poolId = ICronV1Pool(_pool).POOL_ID();
    (IERC20[] memory tokens, , ) = IVault(CrossChain.VAULT).getPoolTokens(poolId);
    IAsset[] memory assets = _convertERC20sToAssets(tokens);
    // call joinPool function on TWAMMs
    IVault(CrossChain.VAULT).joinPool(
      poolId,
      msg.sender,
      payable (_to),
      IVault.JoinPoolRequest(
        assets,
        _maxAmountsIn,
        userData,
        false // fromInternalBalance
      )
    );
  }

  function swap(
    uint256 _amountIn,
    uint256 _slippage,
    uint256 _argument,
    ICronV1Pool.SwapType _swapType,
    address _tokenIn,
    address _pool,
    address _to
  ) internal returns (uint256 amountOut) {
    // setup parameters for swap
    (IERC20[] memory tokens, , ) = IVault(CrossChain.VAULT).getPoolTokens(ICronV1Pool(_pool).POOL_ID());
    IAsset[] memory assets = _convertERC20sToAssets(tokens);
    // approve tokens to spend from this contract in the vault
    IERC20 token = (_tokenIn == address(tokens[0])) ? tokens[0] : tokens[1];
    token.approve(CrossChain.VAULT, _amountIn);
    uint256 limit = (_slippage > 0) ? (_amountIn * (100 - _slippage))/100 : 0;
    // swap amounts with vault
    amountOut = IVault(CrossChain.VAULT).swap(
      IVault.SingleSwap(
        ICronV1Pool(_pool).POOL_ID(),
        IVault.SwapKind.GIVEN_IN,
        (_tokenIn == address(tokens[0])) ? assets[0] : assets[1],
        (_tokenIn == address(tokens[0])) ? assets[1] : assets[0],
        _amountIn,
        abi.encode(
          _swapType,
          _argument
        )
      ),
      IVault.FundManagement(
        msg.sender,
        false,
        payable (_to),
        false
      ),
      limit,
      block.timestamp + 1000
    );
  }

  function flashSwap(
    uint256 _amountIn,
    address _tokenIn,
    address[] memory _pools
  ) internal returns (int256[] memory amountOut) {
    // setup parameters for flash swap
    bytes32 poolId = ICronV1Pool(_pools[0]).POOL_ID();
    (IERC20[] memory tokens, , ) = IVault(CrossChain.VAULT).getPoolTokens(poolId);
    IAsset[] memory assets = _convertERC20sToAssets(tokens);
    int256[] memory limits = new int256[](tokens.length);
    // approve tokens to spend from this contract in the vault
    IERC20 token = (_tokenIn == address(tokens[0])) ? tokens[0] : tokens[1];
    token.approve(CrossChain.VAULT, _amountIn);
    IVault.BatchSwapStep[] memory swaps = _generateFlashSwapSteps(_amountIn, _tokenIn, _pools);
    // swap amounts with vault
    amountOut = IVault(CrossChain.VAULT).batchSwap(
      IVault.SwapKind.GIVEN_IN,
      swaps,
      assets,
      IVault.FundManagement(
        msg.sender,
        false,
        payable (msg.sender),
        false
      ),
      limits,
      999999999999999999
    );
  }

  function exit(
    uint256 _argument,
    ICronV1Pool.ExitType _exitType,
    address _pool,
    address _to
  ) internal returns (uint256[] memory amountsOutU112, uint256[] memory dueProtocolFeeAmountsU96) {
    // build userData field
    bytes memory userData = abi.encode(
      _exitType, // exit type
      _argument
    );
    bytes32 poolId = ICronV1Pool(_pool).POOL_ID();
    (IERC20[] memory tokens, , ) = IVault(CrossChain.VAULT).getPoolTokens(poolId);
    IAsset[] memory assets = _convertERC20sToAssets(tokens);
    // approve tokens to spend from this contract in the vault
    uint256[] memory minAmountIn = new uint256[](tokens.length);
    for (uint256 i; i < tokens.length; i++) {
      minAmountIn[i] = type(uint256).min;
    }
    // swap amounts with vault
    IVault(CrossChain.VAULT).exitPool(
      ICronV1Pool(_pool).POOL_ID(),
      msg.sender,
      payable (_to),
      IVault.ExitPoolRequest(
        assets,
        minAmountIn,
        userData,
        false
      )
    );
  }

  function _generateFlashSwapSteps(
    uint256 _amountIn,
    address _tokenIn,
    address[] memory _pools
  ) internal returns (IVault.BatchSwapStep[] memory swaps) {
    bytes memory userData = abi.encode(ICronV1PoolEnums.SwapType.RegularSwap, 0);
    for (uint256 i = 0; i < _pools.length; i++) {
      bytes32 poolId = ICronV1Pool(_pools[i]).POOL_ID();
      (IERC20[] memory tokens, , ) = IVault(CrossChain.VAULT).getPoolTokens(poolId);
      uint256 assetInIndex = (_tokenIn == address(tokens[0])) ? 0 : 1;
      uint256 assetOutIndex = (_tokenIn == address(tokens[0])) ? 1 : 0;
      uint256 amount = (i == 0) ? _amountIn : 0;
      swaps[i] = IVault.BatchSwapStep(poolId, assetInIndex, assetOutIndex, amount, userData);
    }
  }

  function _convertERC20sToAssets(IERC20[] memory tokens) internal pure returns (IAsset[] memory assets) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      assets := tokens
    }
  }
}
