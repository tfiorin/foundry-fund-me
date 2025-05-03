// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error NotOwner();
error NotEnoughMoney();
error WithdrawFailed();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18; //Minimum is $5

    address payable private immutable i_owner;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;

    // Events
    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(uint256 amount, uint256 timestamp);

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Caller is not the contract's deployer!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    constructor(address _priceFeed) {
        i_owner = payable(msg.sender);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        // to accept ETH from a user
        //require(msg.value.getConvertionRate() >= MINIMUM_USD, "Not enough money!");
        if (msg.value.getConvertionRate(priceFeed) < MINIMUM_USD) {
            revert NotEnoughMoney();
        }

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender); // save to a list of funders

        emit Funded(msg.sender, msg.value);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function withdraw() public onlyOwner {
        uint256 totalToWithdraw = 0;

        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];

            uint256 amount = addressToAmountFunded[funder];
            totalToWithdraw += amount;

            // Transfer all ETH from this contract to the sender
            //owner.transfer(amount);

            // Using call to transfer all ETH from this contract to the sender
            (bool callSucess, ) = i_owner.call{value: amount}("");
            //require(callSucess, "Withdrawal failed!");
            if (!callSucess) {
                revert WithdrawFailed();
            }

            addressToAmountFunded[funder] = 0;
        }

        emit Withdrawn(totalToWithdraw, block.timestamp);

        //reset funders
        funders = new address[](0);
    }

    function optmizeWithdraw() public onlyOwner {
        address[] memory fundersCopy = funders;
        uint256 fundersLength = fundersCopy.length;

        for (uint256 i = 0; i < fundersLength; i++) {
            address funder = fundersCopy[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // Transfer all ETH from this contract to the sender
        uint256 amountToWithdraw = address(this).balance;
        (bool callSucess, ) = i_owner.call{value: amountToWithdraw}("");
        if (!callSucess) {
            revert WithdrawFailed();
        } else {
            emit Withdrawn(amountToWithdraw, block.timestamp);
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}
