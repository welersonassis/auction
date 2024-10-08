// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title Simple auction contract
 * @author Welerson Assis
 * @notice This contrcat is just for study porpuses
 */

contract Auction {
    /* Errors */
    error Auction__LessThenHighestBidder();
    error Auction__Closed();
    error Auction__NotOwner();
    error Auction__UpkeepNotNeeded(uint256 balance);

    /* Events */
    event AuctionEntered(address indexed bidder, uint256 bid);

    address private s_bidderAddress;
    uint256 private s_highestBidder;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_minimumPrice;
    address private immutable i_owner;
    // @dev The duration of the auction
    uint256 private immutable i_interval;

    constructor(uint256 _minimumPrice, uint256 _interval) {
        i_owner = msg.sender;
        // i_minimumPrice = _minimumPrice;
        s_highestBidder = _minimumPrice;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
    }

    receive() external payable {
        enterAuction();
    }

    fallback() external payable {
        enterAuction();
    }

    // CEI: Checks, Effects, Interactions Pattern
    function enterAuction() public payable {
        bool auctionIsClosed = (block.timestamp - s_lastTimeStamp) > i_interval;

        if (auctionIsClosed) {
            revert Auction__Closed();
        }

        if (msg.value <= s_highestBidder) {
            revert Auction__LessThenHighestBidder();
        }

        emit AuctionEntered(msg.sender, msg.value);

        s_bidderAddress = msg.sender;
        s_highestBidder = msg.value;
    }

    /**
     * @dev This is the function that the Chainlink nodes will call to see
     * if the auction is ready to finish.
     * The following should be true in order for upkeepNeeded to be true:
     * 1. The time interval has passed between auction runs
     * 2. The contract has ETH
     */

    function checkUpkeep(
        bytes memory /* checkDate */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = timeHasPassed && hasBalance;

        return (upkeepNeeded, "");
    }

    function performUpkeep() external view {
        // check to see if enough time has passed
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Auction__UpkeepNotNeeded(address(this).balance);
        }

        bool auctionIsClosed = (block.timestamp - s_lastTimeStamp) > i_interval;

        if (!auctionIsClosed) {
            revert();
        }
    }

    //** Getter Functions  */

    function gets_highestBidder() external view returns (uint256) {
        return s_highestBidder;
    }

    function withdraw() public onlyOwner {
        uint256 amount = s_highestBidder;
        payable(msg.sender).transfer(amount);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Auction__NotOwner();
        }
        _;
    }
}
