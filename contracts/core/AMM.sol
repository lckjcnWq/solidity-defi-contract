// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IAMM.sol";

abstract contract AMM is IAMM, ERC20, ReentrancyGuard {
    address public immutable token0;
    address public immutable token1;

    uint256 private reserve0;
    uint256 private reserve1;
    
    // 最小流动性，防止第一个LP操纵价格
    uint256 private constant MINIMUM_LIQUIDITY = 1000;
    
    constructor(
        address _token0,
        address _token1
    ) ERC20("AMM-LP", "ALP") {
        require(_token0 != address(0) && _token1 != address(0), "ZERO_ADDRESS");
        require(_token0 != _token1, "IDENTICAL_ADDRESSES");
        token0 = _token0;
        token1 = _token1;
    }

    //获取储备量
    function getReserves() public view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }

    //获取token地址
    function getTokens() public view returns (address, address) {
        return (token0, token1);
    }

    //更新储备量
    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
    }
}
