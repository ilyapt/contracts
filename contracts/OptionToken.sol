pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract _ERC20 is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
}

contract OptionToken is MintableToken {
    address owner;
    _ERC20 public erc;
    uint256 decimalPower;
    uint256 public strikePrice;
    uint256 public burningTime;

    function OptionToken (
        address _owner,
        address _erc,
        uint256 _strikePrice,
        uint256 _burningTime) public
    {
        require(now < _burningTime);
        owner = _owner;
        erc = _ERC20(_erc);
        decimalPower = SafeDecimalsCalc(erc.decimals());
        strikePrice = _strikePrice;
        burningTime = _burningTime;
    }

    function name () public constant returns(string) {
        return erc.name();
    }

    function symbol () public constant returns(string) {
        return erc.symbol();
    }

    function decimals () public constant returns(uint8) {
        return erc.decimals();
    }

    function SafeDecimalsCalc(uint256 decimals) private pure returns (uint256 result)
    {
        result = 1;
        for (uint256 i = 0; i < decimals; i++){
            result *= 10;
            assert(result >= 10);
        }
    }

    modifier onlyWhileBuyout {
        require(now < burningTime);
        _;
    }

    // buyouts erc-tokens when received eth
    // less or equal to the buyer's options
    function () public payable onlyWhileBuyout {
        uint tokenCount = msg.value.mul(decimalPower).div(strikePrice);
        require(balances[msg.sender] >= tokenCount);
        balances[msg.sender] = balances[msg.sender].sub(tokenCount);
        erc.transfer(msg.sender, tokenCount);
    }

    function withdraw() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}

