// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Auction} from "../../src/Auction.sol";

contract AuctionTest is Test {
    Auction public auction;

    address public BIDDER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
    uint256 bidValue = 1.5 ether;
    uint256 public interval = 3600;
    uint256 public minimumValue = 1 ether;

    /* Events */
    event AuctionEntered(address indexed bidder, uint256 bid);

    function setUp() public {
        auction = new Auction(minimumValue, interval); // Initial setup for the auction with a 1 ETH minimum and 1 hour interval
        vm.deal(BIDDER, STARTING_PLAYER_BALANCE); // Give BIDDER some starting balance
    }

    function testAuctionRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(BIDDER);
        uint256 insufficientBid = 0.5 ether; // Less than the minimum price
        // Act / Assert
        vm.expectRevert(Auction.Auction__LessThenHighestBidder.selector);
        auction.enterAuction{value: insufficientBid}(); // Pass insufficient ETH
    }

    function testEnteringAuctionEmitsEvent() public {
        // Arrange
        vm.prank(BIDDER);
        // Act
        vm.expectEmit(true, false, false, false, address(auction));
        emit AuctionEntered(BIDDER, bidValue);
        // Assert
        auction.enterAuction{value: bidValue}();
    }

    function testDontAllowBidderToEnterIfAuctionIsClosed() public {
        // Arrange
        vm.prank(BIDDER);
        auction.enterAuction{value: bidValue}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        auction.performUpkeep("");

        // Act / Assert
        vm.expectRevert();
        vm.prank(BIDDER);
        auction.enterAuction{value: bidValue}();
    }

    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = auction.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(BIDDER);
        auction.enterAuction{value: bidValue}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        auction.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;

        vm.prank(BIDDER);
        auction.enterAuction{value: bidValue}();
        currentBalance = currentBalance + bidValue;

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Auction.Auction__UpkeepNotNeeded.selector,
                currentBalance
            )
        );
        auction.performUpkeep("");
    }
}
