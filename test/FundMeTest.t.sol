// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_VALUE = 20 ether;

    modifier fundMeWithValue() {
        vm.prank(USER);
        vm.deal(USER, STARTING_VALUE);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinimumUSD() public view {
        uint256 minimumUSD = fundMe.MINIMUM_USD();
        assertEq(minimumUSD, 5e18);
    }

    function testOwner() public view {
        address owner = fundMe.getOwner();
        assertEq(owner, msg.sender);
    }

    function testPriceFeedVersion() public view {
        uint256 priceFeedVersion = fundMe.getVersion();
        assertEq(priceFeedVersion, 4);
    }

    function testFundFailForNotEnoughEth() public {
        vm.expectRevert();
        fundMe.fund{value: 0.001 ether}();
    }

    function testFundUpdateData() public payable fundMeWithValue {
        uint256 amountFunded = fundMe.addressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFundersToArray() public fundMeWithValue {
        address funder = fundMe.funders(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public fundMeWithValue {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdraw() public payable fundMeWithValue {
        // Arrange
        uint256 ownerBalance = fundMe.getOwner().balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 newOwnerBalance = fundMe.getOwner().balance;
        // Assert
        uint256 amountFunded = fundMe.addressToAmountFunded(USER);
        assertEq(amountFunded, 0);
        assertEq(newOwnerBalance, ownerBalance + SEND_VALUE);
    }
}
