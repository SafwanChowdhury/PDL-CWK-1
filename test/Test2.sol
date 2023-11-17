// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/interfaces/ITicketNFT.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/SecondaryMarket.sol";


contract Test2 is Test {
    PrimaryMarket public primaryMarket;
    PurchaseToken public purchaseToken;
    SecondaryMarket public secondaryMarket;

    address public charlie = makeAddr("charlie");
    address public dan = makeAddr("Dan");
    address public emma = makeAddr("Emma");
    
    // The amount of purchaseToken both our test users have initially
    uint initialCharlie = 1000e18;
    uint initialDan = 5000e18;
    uint initialEmma = 5000e18;

    uint256 ticketPrice1 = 2e18;
    uint256 ticketPrice2 = 5e18;
    uint256 ticketPrice3 = 3e18;
    uint256 ticketPrice4 = 1e18;

    ITicketNFT ticketNFT1;
    ITicketNFT ticketNFT2;
    ITicketNFT ticketNFT3;
    ITicketNFT ticketNFT4;

    uint[] danTickets = new uint[](5);
    uint[] charlieTickets = new uint[](4);

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        secondaryMarket = new SecondaryMarket(purchaseToken);

        payable(charlie).transfer(initialCharlie / 100);
        payable(dan).transfer(initialDan / 100);
        payable(emma).transfer(initialEmma / 100);
    }

    function buyCoins() internal {
        vm.startPrank(charlie);
        purchaseToken.mint{value: initialCharlie / 100}();
        assertEq(purchaseToken.balanceOf(charlie), initialCharlie);
        purchaseToken.approve(address(primaryMarket), initialCharlie);
        vm.stopPrank();
        
        vm.startPrank(dan);
        purchaseToken.mint{value: initialDan / 100}();
        assertEq(purchaseToken.balanceOf(dan), initialDan);
        purchaseToken.approve(address(primaryMarket), initialDan);
        vm.stopPrank();

        vm.startPrank(emma);
        purchaseToken.mint{value: initialEmma / 100}();
        assertEq(purchaseToken.balanceOf(emma), initialEmma);
        vm.stopPrank();
    }

    function createEvents() internal {

        vm.startPrank(charlie);
        ticketNFT1 = primaryMarket.createNewEvent(
            "Charlie's concert 1",
            ticketPrice1,
            100
        );

        ticketNFT2 = primaryMarket.createNewEvent(
            "Charlie's concert 2",
            ticketPrice2,
            155
        );
        vm.stopPrank();

        vm.startPrank(dan);
        ticketNFT3 = primaryMarket.createNewEvent(
            "Dan's concert 1",
            ticketPrice3,
            200
        );

        ticketNFT4 = primaryMarket.createNewEvent(
            "Dan's concert 2",
            ticketPrice4,
            10 
        );
        vm.stopPrank();
    }

    function assertBalancesAndHolders() internal {
        assertEq(ticketNFT1.balanceOf(dan), 3);
        assertEq(ticketNFT2.balanceOf(dan), 2);
        assertEq(ticketNFT4.balanceOf(dan), 0);
        assertEq(ticketNFT1.balanceOf(charlie), 1);
        assertEq(ticketNFT3.balanceOf(charlie), 1);
        assertEq(ticketNFT4.balanceOf(charlie), 1);

        assertEq(ticketNFT1.holderOf(danTickets[0]), dan);
        assertEq(ticketNFT1.holderOf(danTickets[1]), dan);
        assertEq(ticketNFT2.holderOf(danTickets[3]), dan);
        assertEq(ticketNFT2.holderOf(danTickets[4]), dan);

        assertEq(ticketNFT1.holderOf(charlieTickets[0]), charlie);
        assertEq(ticketNFT2.holderOf(charlieTickets[1]), charlie);
        assertEq(ticketNFT3.holderOf(charlieTickets[2]), charlie);

        assertEq(purchaseToken.balanceOf(dan), initialDan - 3 * ticketPrice1 - 2 * ticketPrice2 + ticketPrice3 + ticketPrice4);
        assertEq(purchaseToken.balanceOf(charlie), initialCharlie - ticketPrice3 - ticketPrice4 + 3 * ticketPrice1 + 2 * ticketPrice2);
    }

    function asssertCreatorsAndPrice() internal {
        assertEq(ticketNFT1.creator(), charlie);
        assertEq(ticketNFT2.creator(), charlie);
        assertEq(ticketNFT3.creator(), dan);
        assertEq(ticketNFT4.creator(), dan);

        assertEq(ticketNFT1.maxNumberOfTickets(), 100);
        assertEq(ticketNFT2.maxNumberOfTickets(), 155);
        assertEq(ticketNFT3.maxNumberOfTickets(), 200);
        assertEq(ticketNFT4.maxNumberOfTickets(), 10);

        assertEq(primaryMarket.getPrice(address(ticketNFT1)), ticketPrice1);
        assertEq(primaryMarket.getPrice(address(ticketNFT2)), ticketPrice2);
        assertEq(primaryMarket.getPrice(address(ticketNFT3)), ticketPrice3);
        assertEq(primaryMarket.getPrice(address(ticketNFT4)), ticketPrice4);

    }


    function buyTickets() internal {
        vm.startPrank(dan);
        danTickets[0] = primaryMarket.purchase(address(ticketNFT1), "Dan");
        danTickets[1] = primaryMarket.purchase(address(ticketNFT1), "Dan");
        danTickets[2] = primaryMarket.purchase(address(ticketNFT1), "Dan");
        danTickets[3] = primaryMarket.purchase(address(ticketNFT2), "Dan");
        danTickets[4] = primaryMarket.purchase(address(ticketNFT2), "Dan");
        vm.stopPrank();

        vm.startPrank(charlie);
        charlieTickets[0] = primaryMarket.purchase(address(ticketNFT1), "Charlie");
        charlieTickets[1] = primaryMarket.purchase(address(ticketNFT2), "Charlie");
        charlieTickets[2] = primaryMarket.purchase(address(ticketNFT3), "Charlie");
        charlieTickets[3] = primaryMarket.purchase(address(ticketNFT4), "Charlie");
        vm.stopPrank();
    }

    function approveAndListTickets() internal {
        
        vm.startPrank(dan);
        ticketNFT1.approve(address(secondaryMarket), danTickets[0]);
        ticketNFT1.approve(address(secondaryMarket), danTickets[1]);
        ticketNFT1.approve(address(secondaryMarket), danTickets[2]);
        ticketNFT2.approve(address(secondaryMarket), danTickets[3]);
        ticketNFT2.approve(address(secondaryMarket), danTickets[4]);

        secondaryMarket.listTicket(address(ticketNFT1), danTickets[0], 150e18);
        assertEq(ticketNFT1.balanceOf(dan), 2);
        assertEq(ticketNFT1.balanceOf(address(secondaryMarket)), 1);
        secondaryMarket.listTicket(address(ticketNFT1), danTickets[1], 30e18);
        assertEq(ticketNFT1.balanceOf(dan), 1);
        assertEq(ticketNFT1.balanceOf(address(secondaryMarket)), 2);
        secondaryMarket.listTicket(address(ticketNFT1), danTickets[2], 110e18);
        assertEq(ticketNFT1.balanceOf(dan), 0);
        assertEq(ticketNFT1.balanceOf(address(secondaryMarket)), 3);
        secondaryMarket.listTicket(address(ticketNFT2), danTickets[3], 200e18);
        assertEq(ticketNFT2.balanceOf(dan), 1);
        assertEq(ticketNFT2.balanceOf(address(secondaryMarket)), 1);
        secondaryMarket.listTicket(address(ticketNFT2), danTickets[4], 100e18);
        assertEq(ticketNFT2.balanceOf(dan), 0);
        assertEq(ticketNFT2.balanceOf(address(secondaryMarket)), 2);

        assertEq(secondaryMarket.getHighestBid(address(ticketNFT1), danTickets[0]), 150e18);
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT1), danTickets[1]), 30e18);
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT1), danTickets[2]), 110e18);
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT2), danTickets[3]), 200e18);
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT2), danTickets[4]), 100e18);

        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT1), danTickets[0]), address(0));
        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT1), danTickets[0]), address(0));
        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT1), danTickets[0]), address(0));
        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT2), danTickets[0]), address(0));
        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT2), danTickets[0]), address(0));
        vm.stopPrank();
        
        vm.startPrank(charlie);
        ticketNFT1.approve(address(secondaryMarket), charlieTickets[0]);
        ticketNFT2.approve(address(secondaryMarket), charlieTickets[1]);
        ticketNFT3.approve(address(secondaryMarket), charlieTickets[2]);
        ticketNFT4.approve(address(secondaryMarket), charlieTickets[3]);

        secondaryMarket.listTicket(address(ticketNFT1), charlieTickets[0], 150e18);
        assertEq(ticketNFT1.balanceOf(charlie), 0);
        assertEq(ticketNFT1.balanceOf(address(secondaryMarket)), 4);
        secondaryMarket.listTicket(address(ticketNFT2), charlieTickets[1], 30e18);
        assertEq(ticketNFT2.balanceOf(charlie), 0);
        assertEq(ticketNFT2.balanceOf(address(secondaryMarket)), 3);
        secondaryMarket.listTicket(address(ticketNFT3), charlieTickets[2], 110e18);
        assertEq(ticketNFT3.balanceOf(charlie), 0);
        assertEq(ticketNFT3.balanceOf(address(secondaryMarket)), 1);
        secondaryMarket.listTicket(address(ticketNFT4), charlieTickets[3], 200e18);
        assertEq(ticketNFT4.balanceOf(charlie), 0);
        assertEq(ticketNFT4.balanceOf(address(secondaryMarket)), 1);

        assertEq(ticketNFT1.balanceOf(address(secondaryMarket)), 4);
        assertEq(ticketNFT2.balanceOf(address(secondaryMarket)), 3);

        assertEq(secondaryMarket.getHighestBid(address(ticketNFT1), charlieTickets[0]), 150e18);
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT2), charlieTickets[1]), 30e18);
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT3), charlieTickets[2]), 110e18);
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT4), charlieTickets[3]), 200e18);

        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT1), charlieTickets[0]), address(0));
        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT2), charlieTickets[1]), address(0));
        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT3), charlieTickets[2]), address(0));
        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT4), charlieTickets[3]), address(0));
        vm.stopPrank();

    }

    function startBidding() internal {
        vm.startPrank(dan);
        purchaseToken.approve(address(secondaryMarket), 700e18);
        secondaryMarket.submitBid(address(ticketNFT1), charlieTickets[0], 200e18, "Dan");
        secondaryMarket.submitBid(address(ticketNFT4), charlieTickets[3], 500e18, "Dan");

        assertEq(
            secondaryMarket.getHighestBid(address(ticketNFT1), charlieTickets[0]),
            200e18
        );
        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT1), charlieTickets[0]), dan);

        assertEq(ticketNFT1.balanceOf(address(dan)), 0);
        assertEq(ticketNFT2.balanceOf(address(dan)), 0);
        assertEq(ticketNFT3.balanceOf(address(dan)), 0);
        assertEq(ticketNFT4.balanceOf(address(dan)), 0);

        assertEq(ticketNFT1.balanceOf(address(secondaryMarket)), 4);
        assertEq(ticketNFT2.balanceOf(address(secondaryMarket)), 3);
        assertEq(ticketNFT3.balanceOf(address(secondaryMarket)), 1);
        assertEq(ticketNFT4.balanceOf(address(secondaryMarket)), 1);

        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), 700e18);
        assertEq(purchaseToken.balanceOf(dan), initialDan - 3 * ticketPrice1 - 2 * ticketPrice2 + ticketPrice3 + ticketPrice4 - 700e18);
        assertEq(purchaseToken.balanceOf(charlie), initialCharlie - ticketPrice3 - ticketPrice4 + 3 * ticketPrice1 + 2 * ticketPrice2);
        assertEq(purchaseToken.balanceOf(emma), initialEmma);

        assertEq(ticketNFT1.holderOf(danTickets[0]), address(secondaryMarket));
        assertEq(ticketNFT1.holderOf(danTickets[1]), address(secondaryMarket));
        assertEq(ticketNFT1.holderOf(danTickets[2]), address(secondaryMarket));
        assertEq(ticketNFT1.holderOf(charlieTickets[0]), address(secondaryMarket));
        assertEq(ticketNFT2.holderOf(charlieTickets[1]), address(secondaryMarket));
        assertEq(ticketNFT3.holderOf(charlieTickets[2]), address(secondaryMarket));
        vm.stopPrank();

        vm.startPrank(emma);
        purchaseToken.approve(address(secondaryMarket), 3000e18);
        secondaryMarket.submitBid(address(ticketNFT1), charlieTickets[0], 210e18, "Emma");
        secondaryMarket.submitBid(address(ticketNFT2), charlieTickets[1], 210e18, "Emma");
        secondaryMarket.submitBid(address(ticketNFT3), charlieTickets[2], 210e18, "Emma");
        secondaryMarket.submitBid(address(ticketNFT4), charlieTickets[3], 900e18, "Emma");
        vm.stopPrank();

        vm.startPrank(dan);
        purchaseToken.approve(address(secondaryMarket), 600e18);
        secondaryMarket.submitBid(address(ticketNFT1), charlieTickets[0], 300e18, "Dan");
        secondaryMarket.submitBid(address(ticketNFT3), charlieTickets[2], 300e18, "Dan");
        vm.stopPrank();

        assertEq(ticketNFT1.holderOf(charlieTickets[0]), address(secondaryMarket));
        assertEq(ticketNFT2.holderOf(charlieTickets[1]), address(secondaryMarket));
        assertEq(ticketNFT3.holderOf(charlieTickets[2]), address(secondaryMarket));
        assertEq(ticketNFT4.holderOf(charlieTickets[3]), address(secondaryMarket));

        assertEq(ticketNFT1.holderOf(danTickets[0]), address(secondaryMarket));
        assertEq(ticketNFT1.holderOf(danTickets[1]), address(secondaryMarket));
        assertEq(ticketNFT1.holderOf(danTickets[2]), address(secondaryMarket));

        assertEq(purchaseToken.balanceOf(dan), initialDan - 3 * ticketPrice1 - 2 * ticketPrice2 + ticketPrice3 + ticketPrice4 - 600e18);
        assertEq(purchaseToken.balanceOf(emma), initialEmma - 1110e18);
        assertEq(purchaseToken.balanceOf(charlie), initialCharlie - ticketPrice3 - ticketPrice4 + 3 * ticketPrice1 + 2 * ticketPrice2);
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), 1110e18 + 600e18);
    }

    function endBidding() internal {
        vm.startPrank(charlie);

        secondaryMarket.acceptBid(address(ticketNFT1), charlieTickets[0]);
        secondaryMarket.acceptBid(address(ticketNFT4), charlieTickets[3]);

        uint256 feeTicket3 = (900e18 * 0.05e18) / 1e18;
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), 1110e18 + 600e18 - 300e18 - 900e18);
        assertEq(purchaseToken.balanceOf(charlie), initialCharlie - ticketPrice3 - ticketPrice4 + 3 * ticketPrice1 + 2 * ticketPrice2 + 300e18 + 900e18 - feeTicket3);
        assertEq(purchaseToken.balanceOf(dan), initialDan - 3 * ticketPrice1 - 2 * ticketPrice2 + ticketPrice3 + ticketPrice4 - 600e18 + feeTicket3);
        assertEq(purchaseToken.balanceOf(emma), initialEmma - 1110e18);

        assertEq(ticketNFT1.holderOf(charlieTickets[0]), dan);
        assertEq(ticketNFT1.holderNameOf(charlieTickets[0]), "Dan");
        assertEq(ticketNFT4.holderOf(charlieTickets[3]), emma);
        assertEq(ticketNFT4.holderNameOf(charlieTickets[3]), "Emma");
        vm.stopPrank();
        
        vm.startPrank(dan);
        secondaryMarket.delistTicket(address(ticketNFT1), danTickets[0]);
        secondaryMarket.delistTicket(address(ticketNFT1), danTickets[1]) ;
        secondaryMarket.delistTicket(address(ticketNFT1), danTickets[2]) ;
        secondaryMarket.delistTicket(address(ticketNFT2), danTickets[3]) ;
        secondaryMarket.delistTicket(address(ticketNFT2), danTickets[4]) ;
        vm.stopPrank();

        vm.startPrank(charlie);
        secondaryMarket.delistTicket(address(ticketNFT2), charlieTickets[1]) ;
        secondaryMarket.delistTicket(address(ticketNFT3), charlieTickets[2]) ;
        vm.stopPrank();

        assertEq(ticketNFT1.balanceOf(dan), 4);
        assertEq(ticketNFT2.balanceOf(dan), 2);
        assertEq(ticketNFT3.balanceOf(dan), 0);
        assertEq(ticketNFT4.balanceOf(dan), 0);

        assertEq(ticketNFT1.balanceOf(charlie), 0);
        assertEq(ticketNFT2.balanceOf(charlie), 1);
        assertEq(ticketNFT3.balanceOf(charlie), 1);
        assertEq(ticketNFT4.balanceOf(charlie), 0);

        assertEq(ticketNFT1.balanceOf(emma), 0);
        assertEq(ticketNFT2.balanceOf(emma), 0);
        assertEq(ticketNFT3.balanceOf(emma), 0);
        assertEq(ticketNFT4.balanceOf(emma), 1);

    }

    function testEndToEndCustom1() external {

        buyCoins();
        createEvents();
        asssertCreatorsAndPrice();
        buyTickets();
        assertBalancesAndHolders();
        approveAndListTickets();
        startBidding();
        endBidding();

    }
}
