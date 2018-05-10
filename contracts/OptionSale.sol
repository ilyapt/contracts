pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "./OptionToken.sol";

contract OptionSale {
    using SafeMath for uint256;
    address factory;
    address startup;
    bool closed = false;
    uint256 public optionPrice;
    uint256 public closingSaleTime;
    OptionToken public option;
    _ERC20 public erc20;
    uint256 decimalPower;

    function OptionSale (
        address _startup,
        uint256 _optionPrice,
        uint256 _closingSaleTime,
        address _ercToken,
        uint256 _strikePrice,
        uint256 _burningTime
        ) public
    {
        factory = msg.sender;
        startup = _startup;
        optionPrice = _optionPrice;
        closingSaleTime = _closingSaleTime;
        erc20 = _ERC20(_ercToken);
        decimalPower = SafeDecimalsCalc(erc20.decimals());
        option = new OptionToken(startup, address(erc20), _strikePrice, _burningTime);
    }

    function SafeDecimalsCalc(uint256 decimals) private pure returns (uint256 result)
    {
        result = 1;
        for (uint256 i = 0; i < decimals; i++){
            result *= 10;
            assert(result >= 10);
        }
    }

    modifier onlyStartup {
        require(msg.sender == startup);
        _;
    }

    modifier onlyWhileOpen {
        require(now <= closingSaleTime);
        _;
    }

    function () public payable onlyWhileOpen {
        uint optionCount = msg.value.mul(decimalPower).div(optionPrice);

        if (erc20.balanceOf(address(this)) >= optionCount) {
            erc20.transfer(option, optionCount);
            option.mint(msg.sender, optionCount);
        } else if(erc20.allowance(startup, address(this)) >= optionCount) {
            erc20.transferFrom(startup, option, optionCount);
            option.mint(msg.sender, optionCount);
        } else {
            revert();
        }
    }

    function withdraw() public onlyStartup {
        startup.transfer(address(this).balance);
    }

    function close() public onlyStartup {
        uint256 extra = erc20.balanceOf(address(this));
        if (extra > 0) {
            erc20.transfer(startup, extra);
        }
        startup.transfer(address(this).balance);
        closed = true;
    }
}

