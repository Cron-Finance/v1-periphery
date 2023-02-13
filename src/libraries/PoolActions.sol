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

import { Cross_Chain, Goerli_Chain } from "./Constants.sol";

library PoolActions {

  function join(
    address _pool,
    address _to,
    uint256 _liquidity0,
    uint256 _liquidity1,
    uint256 _joinKind
  ) public {
    // setup parameters for joinPool
    uint256[] memory balances = new uint256[](2);
    balances[0] = _liquidity0;
    balances[1] = _liquidity1;
    bytes memory userData = abi.encode(_joinKind, balances);
    bytes32 poolId = ICronV1Pool(_pool).POOL_ID();
    (IERC20[] memory tokens, , ) = IVault(Cross_Chain.VAULT).getPoolTokens(poolId);
    IAsset[] memory assets = _convertERC20sToAssets(tokens);
    uint256[] memory maxAmountsIn = new uint256[](tokens.length);
    for (uint256 i; i < tokens.length; i++) {
      maxAmountsIn[i] = type(uint256).max;
    }
    bool fromInternalBalance = false;
    // approve tokens to be used by vault
    IERC20(tokens[0]).approve(Cross_Chain.VAULT, _liquidity0);
    IERC20(tokens[1]).approve(Cross_Chain.VAULT, _liquidity1);
    // call joinPool function on TWAMMs
    IVault(Cross_Chain.VAULT).joinPool(
      poolId,
      msg.sender,
      payable (_to),
      IVault.JoinPoolRequest(
        assets,
        maxAmountsIn,
        userData,
        fromInternalBalance
      )
    );
  }

  function swap(
    uint256 _amountIn,
    uint256 _argument,
    ICronV1Pool.SwapType _swapType,
    address _tokenIn,
    address _pool
  ) public returns (uint256 amountOut) {
    // setup parameters for swap
    bytes32 poolId = ICronV1Pool(_pool).POOL_ID();
    (IERC20[] memory tokens, , ) = IVault(Cross_Chain.VAULT).getPoolTokens(poolId);
    IAsset[] memory assets = _convertERC20sToAssets(tokens);
    // approve tokens to spend from this contract in the vault
    IERC20 token = (_tokenIn == address(tokens[0])) ? tokens[0] : tokens[1];
    token.approve(Cross_Chain.VAULT, _amountIn);
    // swap amounts with vault
    amountOut = IVault(Cross_Chain.VAULT).swap(
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
        payable (msg.sender),
        false
      ),
      0,
      block.timestamp + 1000
    );
  }

  function flashSwap(
    uint256 _amountIn,
    address _tokenIn,
    address[] memory _pools
  ) public returns (int256[] memory amountOut) {
    // setup parameters for flash swap
    bytes32 poolId = ICronV1Pool(_pools[0]).POOL_ID();
    (IERC20[] memory tokens, , ) = IVault(Cross_Chain.VAULT).getPoolTokens(poolId);
    IAsset[] memory assets = _convertERC20sToAssets(tokens);
    int256[] memory limits = new int256[](tokens.length);
    // approve tokens to spend from this contract in the vault
    IERC20 token = (_tokenIn == address(tokens[0])) ? tokens[0] : tokens[1];
    token.approve(Cross_Chain.VAULT, _amountIn);
    IVault.BatchSwapStep[] memory swaps = _generateFlashSwapSteps(_amountIn, _tokenIn, _pools);
    // swap amounts with vault
    amountOut = IVault(Cross_Chain.VAULT).batchSwap(
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
    uint _argument,
    ICronV1Pool.ExitType _exitType,
    address _pool
  ) public {
    // build userData field
    bytes memory userData = abi.encode(
      _exitType, // exit type
      _argument
    );
    bytes32 poolId = ICronV1Pool(_pool).POOL_ID();
    (IERC20[] memory tokens, , ) = IVault(Cross_Chain.VAULT).getPoolTokens(poolId);
    IAsset[] memory assets = _convertERC20sToAssets(tokens);
    // approve tokens to spend from this contract in the vault
    uint256[] memory minAmountIn = new uint256[](tokens.length);
    for (uint256 i; i < tokens.length; i++) {
      minAmountIn[i] = type(uint256).min;
    }
    // swap amounts with vault
    IVault(Cross_Chain.VAULT).exitPool(
      ICronV1Pool(_pool).POOL_ID(),
      msg.sender,
      payable (msg.sender),
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
      (IERC20[] memory tokens, , ) = IVault(Cross_Chain.VAULT).getPoolTokens(poolId);
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
