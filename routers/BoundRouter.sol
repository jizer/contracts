pragma solidity ^0.6.6;

import "../interfaces/IRouter.sol";
import "../libs/SafeMath.sol";
import "../libs/SafeERC20.sol";
import "../interfaces/IUniswapV2Router02.sol";


contract BoundRouterOfTrx is IRouter{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address internal constant CONTRACT_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 internal uniswap;
     
    constructor() public {
        uniswap = IUniswapV2Router02(CONTRACT_ADDRESS);
    } 
    function getAddress() public override returns(address ads)
    {
        return CONTRACT_ADDRESS;
    }
    function swapSTD2Token(uint256 _srcAmount, address _dstToken, uint256 _minDstAmount)
        public payable override returns (uint256 dstAmount)
    {
        require(msg.value > 0);
        
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = _dstToken;

        uint256[] memory amounts = uniswap.swapExactETHForTokens{ value: _srcAmount }(
            _minDstAmount,
            path,
            msg.sender,
            now + 600
        );
        require(amounts.length >= 2);
        return amounts[amounts.length - 1];
    }
    function swapToken2STD(address _srcToken, uint256 _srcAmount, uint256 _minDstAmount)
        public override returns (uint256 dstAmount)
    {
        require(IERC20(_srcToken).balanceOf(msg.sender) >= _srcAmount);
        
        // IERC20(_srcToken).approve(address(CONTRACT_ADDRESS), _srcAmount + 1);
        // IERC20(_srcToken).safeIncreaseAllowance(CONTRACT_ADDRESS, _srcAmount);
        
        address[] memory path = new address[](2);
        path[0] = _srcToken;
        path[1] = uniswap.WETH();
        
        uint256[] memory amounts = uniswap.swapExactTokensForETH(
            _srcAmount,
            _minDstAmount,
            path,
            msg.sender,
            now + 600
        );
        require(amounts.length >= 2);
        return amounts[amounts.length - 1];
    }
}
contract BoundRouterOfEth is IRouter{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address internal constant CONTRACT_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 internal 1inch;
     
    constructor() public {
        1inch = IUniswapV2Router02(CONTRACT_ADDRESS);
    } 
    function getAddress() public override returns(address ads)
    {
        return CONTRACT_ADDRESS;
    }
    function swapSTD2Token(uint256 _srcAmount, address _dstToken, uint256 _minDstAmount)
        public payable override returns (uint256 dstAmount)
    {
        require(msg.value > 0);
        
        address[] memory path = new address[](2);
        path[0] = 1inch.WETH();
        path[1] = _dstToken;

        uint256[] memory amounts = 1inch.swapExactETHForTokens{ value: _srcAmount }(
            _minDstAmount,
            path,
            msg.sender,
            now + 600
        );
        require(amounts.length >= 2);
        return amounts[amounts.length - 1];
    }
    function swapToken2STD(address _srcToken, uint256 _srcAmount, uint256 _minDstAmount)
        public override returns (uint256 dstAmount)
    {
        require(IERC20(_srcToken).balanceOf(msg.sender) >= _srcAmount);
        
        // IERC20(_srcToken).approve(address(CONTRACT_ADDRESS), _srcAmount + 1);
        // IERC20(_srcToken).safeIncreaseAllowance(CONTRACT_ADDRESS, _srcAmount);
        
        address[] memory path = new address[](2);
        path[0] = _srcToken;
        path[1] = 1inch.WETH();
        
        uint256[] memory amounts = 1inch.swapExactTokensForETH(
            _srcAmount,
            _minDstAmount,
            path,
            msg.sender,
            now + 600
        );
        require(amounts.length >= 2);
        return amounts[amounts.length - 1];
    }
}
