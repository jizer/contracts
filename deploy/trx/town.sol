pragma solidity ^0.5.8;

interface ICzzSwap {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint(address _to, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

interface IRouter {
    function getAddress() external returns(address ads); 
    // function getAmountsOut(IERC20 _srcToken, IERC20 _dstToken, uint256 _srcAmount)
    //     external view returns (uint256 dstAmount);
    function swapSTD2Token(uint256 _srcAmount, address _dstToken, uint256 _minDstAmount)
        external payable returns (uint256 dstAmount);
    function swapToken2STD(address _srcToken, uint256 _srcAmount, uint256 _minDstAmount)
        external returns (uint256 dstAmount);
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenBound is Ownable {
    using SafeMath for uint256;

    address public czzToken;
    address public baseSwap;
    
    uint constant MIN_SIGNATURES = 5;
    mapping (address => uint8) private managers;
    mapping (uint => MintItem) private mintItems;
    uint256[] private pendingItems;

    struct MintItem {
        address to;
        uint256 amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }
    
    event MintItemCreated(
        address indexed from,
        address to,
        uint256 amount,
        uint256 mId
    );
    event MintToken(
        address indexed MintAddress,
        address indexed to,
        uint256  MintAmount,
        uint256  TransAmount
    );
    event BurnToken(
        address  indexed BurnAddress,
        uint256 InAmount,
        uint256 OutAmount
    );
    event SwapToken(
        uint indexed Direction,
        uint256 InAmount,
        uint256 OutAmount
    );


    modifier isManager {
        require(
            msg.sender == owner() || managers[msg.sender] == 1);
        _;
    }

    constructor(address _token,address router) public {
        czzToken = _token;
        baseSwap = router;
    }
    function() external payable {}

    function safeTransferTrx(address to, uint value) internal isManager {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETHorTRX_TRANSFER_FAILED');
    }
    
    function addManager(address manager) public onlyOwner{
        managers[manager] = 1;
    }
    function removeManager(address manager) public onlyOwner{
        managers[manager] = 0;
    }
    function deleteItems(uint256 mid) public isManager {
        uint8 replace = 0;
        for(uint i = 0; i< pendingItems.length; i++){
            if(1==replace){
                pendingItems[i-1] = pendingItems[i];
            }else if(mid == pendingItems[i]){
                replace = 1;
            }
        } 
        delete pendingItems[pendingItems.length - 1];
        // pendingItems.length--;
        // delete mintItems[mid];
    }
    function mint(address _to, uint256 _amount,uint256 _minAmountOut,uint256 mid) payable public isManager {
        require(address(0) != _to);
        require(_amount > 0);
        // require(address(this).balance >= _amount);
     
        MintItem storage item = mintItems[mid];
        if (address(0) != item.to && item.amount > 0) {
            require(item.signatures[msg.sender]!=1, "repeat sign");
            require(item.to == _to, "mismatch to address");
            require(item.amount == _amount, "mismatch amount");

            item.signatures[msg.sender] = 1;
            item.signatureCount++;
            if(item.signatureCount >= MIN_SIGNATURES){
                ICzzSwap(czzToken).mint(address(this), _amount);    // mint to contract address   
                uint256 eOut = stdSwap(_amount,_minAmountOut);
                emit SwapToken(0,_amount, eOut);
                safeTransferTrx(_to,eOut);
                emit MintToken(address(this),_to,_amount,eOut);
                // deleteItems(mid);
            }
        } else {
            // MintItem item;
            item.to = _to;
            item.amount = _amount;
            item.signatureCount = 0;
            item.signatures[msg.sender] = 1;
            item.signatureCount++;
            mintItems[mid] = item;
            pendingItems.push(mid);
            emit MintItemCreated(msg.sender, _to, _amount, mid);
        }
    }
    function burn(uint256 _minAmountOut) payable public {
        require(msg.value > 0);
        uint256 czzOut = czzSwap(msg.value,_minAmountOut);
        emit SwapToken(1, msg.value,czzOut);
        ICzzSwap(czzToken).burn(address(this), czzOut);
        emit BurnToken(address(this),msg.value, czzOut);
    }
    // swap to eth or trx
    function stdSwap(uint256 amountCzzIn,uint256 _minAmountOut) internal returns (uint256 amountOut) {
        address swapAddress = IRouter(baseSwap).getAddress();
        ICzzSwap(czzToken).approve(swapAddress, amountCzzIn);
        return IRouter(baseSwap).swapToken2STD(czzToken,amountCzzIn,_minAmountOut);
    }
    // swap to czz
    function czzSwap(uint256 amountIn,uint256 _minAmountOut) internal returns (uint256 amountCzzOut) {
        return IRouter(baseSwap).swapSTD2Token.value(amountIn)(amountIn,czzToken,_minAmountOut);
    }
}
