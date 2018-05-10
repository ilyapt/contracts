pragma solidity ^0.4.18;

import "./OptionSale.sol";
import "./OptionHub.sol";

contract OptionFactory {
    address admin;
    OptionHub public hub;

    function OptionFactory(address _hub) public {
        admin = msg.sender;
        hub = OptionHub(_hub);
    }

    function newOptionSale (
        uint256 _optionPrice,
        uint256 _closingSaleTime,
        address _ercToken,
        uint256 _strikePrice,
        uint256 _burningTime
    ) public returns(address)
    {
        OptionSale sale = new OptionSale(
            msg.sender,
            _optionPrice,
            _closingSaleTime,
            _ercToken,
            _strikePrice,
            _burningTime
        );
        hub.addOption(sale);
        return sale;
    }
}
