// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

/// @title A contract for crowd funding
/// @author Radek Sienkiewicz
/// @notice This contract is to demo a sample funding contract
/// @dev This implements price feeds as library
contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    // State variables
    mapping(address => uint256) private addressToAmountFunded;
    address[] private funders;

    address private immutable owner;
    uint256 public constant MINIMUM_USD = 50 * 10**18;

    AggregatorV3Interface private priceFeed;

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory mem_funders = funders;

        for (
            uint256 funderIndex = 0;
            funderIndex < mem_funders.length;
            funderIndex++
        ) {
            address funder = mem_funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Call failed");
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }
}
