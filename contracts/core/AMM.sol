// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IAMM.sol";
import "../libraries/AMMLibrary.sol";

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

    //添加流动性
    function addLiquidity( 
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to,
        uint256 deadline) external nonReentrant returns (uint256 amount0, uint256 amount1,uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        require(deadline >= block.timestamp, "EXPIRED");
        if(reserve0==0 && reserve1==0){
            (amount0, amount1) = (amount0Desired, amount1Desired);
        }else{
            (amount0, amount1) = (reserve0, reserve1);
           uint256 amount1Optimal = AMMLibrary.getAmountOut(amount0Desired,_reserve0, _reserve1);
           if (amount1Optimal <= amount1Desired) {
                require(amount1Optimal >= amount1Min, "INSUFFICIENT_1_AMOUNT");
                (amount0, amount1) = (amount0Desired, amount1Optimal);
            } else {
                uint256 amount0Optimal = AMMLibrary.getOptimalAmount(amount1Desired, reserve1, reserve0);
                require(amount0Optimal <= amount0Desired, "EXCESSIVE_0_AMOUNT");
                require(amount0Optimal >= amount0Min, "INSUFFICIENT_0_AMOUNT");
                (amount0, amount1) = (amount0Optimal, amount1Desired);
            }
        }
        _transferTokensToAMM(amount0, amount1);
         // 计算LP代币数量
        liquidity = _mintLPTokens(amount0, amount1, to);
        emit AddLiquidity(msg.sender, amount0, amount1, liquidity);
    }


    // 移除流动性
    function removeLiquidity(
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(deadline >= block.timestamp, "EXPIRED");
        
        // 销毁LP代币
        _burn(msg.sender, liquidity);
        
        // 计算返还的代币数量
        amount0 = (liquidity * reserve0) / totalSupply();
        amount1 = (liquidity * reserve1) / totalSupply();
        
        require(amount0 >= amount0Min, "INSUFFICIENT_0_AMOUNT");
        require(amount1 >= amount1Min, "INSUFFICIENT_1_AMOUNT");
        
        // 更新储备量
        _update(reserve0 - amount0, reserve1 - amount1);
        
        // 转移代币
        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);
        
        emit RemoveLiquidity(msg.sender, amount0, amount1, liquidity);
    }

     // 代币兑换
    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountOut) {
        require(deadline >= block.timestamp, "EXPIRED");
        require(tokenIn == token0 || tokenIn == token1, "INVALID_TOKEN");
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        
        bool isToken0 = tokenIn == token0;
        (uint256 reserveIn, uint256 reserveOut) = isToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
        
        // 转入代币
        _safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        
        // 计算输出金额
        amountOut = AMMLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
        
        // 转出代币
        _safeTransfer(
            isToken0 ? token1 : token0,
            to,
            amountOut
        );
        
        // 更新储备量
        _update(
            isToken0 ? reserve0 + amountIn : reserve0 - amountOut,
            isToken0 ? reserve1 - amountOut : reserve1 + amountIn
        );
        
        emit Swap(msg.sender, amountIn, amountOut, tokenIn);
    }


    // 查询兑换数量
    function quote(
        uint256 amountIn,
        address tokenIn
    ) external view returns (uint256 amountOut) {
        require(tokenIn == token0 || tokenIn == token1, "INVALID_TOKEN");
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        
        (uint256 reserveIn, uint256 reserveOut) = tokenIn == token0 
            ? (reserve0, reserve1) 
            : (reserve1, reserve0);
            
        return AMMLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    // 内部辅助函数
    function _mintLPTokens(
        uint256 amount0,
        uint256 amount1,
        address to
    ) private returns (uint256 liquidity) {
        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(1), MINIMUM_LIQUIDITY); // 永久锁定最小流动性
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply()) / reserve0,
                (amount1 * totalSupply()) / reserve1
            );
        }
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);
    }

    function _transferTokensToAMM(uint256 amount0, uint256 amount1) private {
        _safeTransferFrom(token0, msg.sender, address(this), amount0);
        _safeTransferFrom(token1, msg.sender, address(this), amount1);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }
}
