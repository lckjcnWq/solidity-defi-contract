// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library AMMLibrary {

    //计算最佳数量
    function  getOptimalAmounts(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "INSUFFICIENT_LIQUIDITY");

        amountB = (amountA * reserveB) / reserveA;
    }

    // 计算交换后的数量
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");

        uint256 amountInWithFee = amountIn * 997; // 0.3% 手续费
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // 计算k值
    function getK(uint256 reserve0, uint256 reserve1) internal pure returns (uint256) {
        return reserve0 * reserve1;
    }
}
