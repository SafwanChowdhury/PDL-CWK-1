// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/interfaces/ITicketNFT.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/SecondaryMarket.sol";

contract CompleteSystemTest is Test {
    PrimaryMarket primaryMarket;
    PurchaseToken purchaseToken;
    SecondaryMarket secondaryMarket;

    // Define the actors of the tests
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    address dave = makeAddr("dave");

    // Set up the initial balances for ETH and tokens for testing
    uint256 initialBalance = 10 ether;

    // Define ticket prices for the primary market
    uint256 ticketPrice = 1 ether;

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        secondaryMarket = new SecondaryMarket(purchaseToken);

        // Allocate ETH to test accounts to be able to mint tokens
        vm.deal(alice, initialBalance);
        vm.deal(bob, initialBalance);
        vm.deal(charlie, initialBalance);
        vm.deal(dave, initialBalance);

        // Mint tokens for users
        vm.startPrank(alice);
        purchaseToken.mint{value: initialBalance}();
        vm.stopPrank();

        vm.startPrank(bob);
        purchaseToken.mint{value: initialBalance}();
        vm.stopPrank();

        vm.startPrank(charlie);
        purchaseToken.mint{value: initialBalance}();
        vm.stopPrank();

        vm.startPrank(dave);
        purchaseToken.mint{value: initialBalance}();
        vm.stopPrank();
    }

    function testCompleteSystem() external {
        // Alice creates a new event on the primary market
        vm.startPrank(alice);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Live Concert", ticketPrice, 100);
        uint256 aliceTokenBalanceAfterEvent = purchaseToken.balanceOf(alice);
        vm.stopPrank();

        // Bob purchases a ticket for the event
        vm.startPrank(bob);
        purchaseToken.approve(address(primaryMarket), ticketPrice);
        uint256 ticketIdBob = primaryMarket.purchase(address(ticketNFT), "Bob");
        uint256 bobTokenBalanceAfterPurchase = purchaseToken.balanceOf(bob);
        vm.stopPrank();

        // Charlie purchases a ticket for the event
        vm.startPrank(charlie);
        purchaseToken.approve(address(primaryMarket), ticketPrice);
        uint256 ticketIdCharlie = primaryMarket.purchase(address(ticketNFT), "Charlie");
        uint256 charlieTokenBalanceAfterPurchase = purchaseToken.balanceOf(charlie);
        vm.stopPrank();

        // Bob lists his ticket on the secondary market
        vm.startPrank(bob);
        ticketNFT.approve(address(secondaryMarket), ticketIdBob);
        secondaryMarket.listTicket(address(ticketNFT), ticketIdBob, ticketPrice * 2); // List for double price
        vm.stopPrank();

        // Dave bids on Bob's ticket on the secondary market
        vm.startPrank(dave);
        purchaseToken.approve(address(secondaryMarket), ticketPrice * 2);
        secondaryMarket.submitBid(address(ticketNFT), ticketIdBob, ticketPrice * 2, "Dave");
        uint256 daveTokenBalanceAfterBid = purchaseToken.balanceOf(dave);
        vm.stopPrank();

        // Bob accepts Dave's bid on the secondary market
        vm.startPrank(bob);
        secondaryMarket.acceptBid(address(ticketNFT), ticketIdBob);
        uint256 bobTokenBalanceAfterSale = purchaseToken.balanceOf(bob);
        vm.stopPrank();

        // Assert final balances and ticket ownership
        assertEq(ticketNFT.holderOf(ticketIdBob), dave, "Dave should now own the ticket");
        assertEq(ticketNFT.holderOf(ticketIdCharlie), charlie, "Charlie should still own his ticket");
        assertEq(purchaseToken.balanceOf(bob), bobTokenBalanceAfterSale, "Bob's balance should reflect the ticket sale");
        assertEq(purchaseToken.balanceOf(dave), daveTokenBalanceAfterBid - ticketPrice * 2, "Dave's balance should reflect the ticket purchase");
        assertEq(purchaseToken.balanceOf(alice), aliceTokenBalanceAfterEvent, "Alice's balance should remain unchanged");
        assertEq(purchaseToken.balanceOf(charlie), charlieTokenBalanceAfterPurchase, "Charlie's balance should remain unchanged after the market activities");
    }
}