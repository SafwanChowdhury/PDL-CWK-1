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

    // Set up the initial balances for ETH and tokens for testing (in wei)
    uint256 initialBalance = 10 ether;

    // Define ticket prices for the primary market (in wei)
    uint256 ticketPrice = 1 ether;
    uint256 bobListPrice = 2 ether;
    uint256 daveBidPrice = 3 ether;

    uint256 initialPT = 100 ether;

    uint256 alicePTbalance = 0 ether;
    uint256 bobPTbalance = 0 ether;
    uint256 charliePTbalance = 0 ether;
    uint256 davePTbalance = 0 ether;
    
    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        secondaryMarket = new SecondaryMarket(purchaseToken);

        // Allocate ETH to test accounts to be able to mint tokens
        vm.deal(alice, initialBalance);
        vm.deal(bob, initialBalance);
        vm.deal(charlie, initialBalance);
        vm.deal(dave, initialBalance);

        // Mint tokens for users (the mint function expects ether and returns 100 times the tokens in wei)
        vm.startPrank(alice);
        purchaseToken.mint{value: 1 ether}(); // Alice gets 100 PT
        alicePTbalance = purchaseToken.balanceOf(alice);
        vm.stopPrank();

        vm.startPrank(bob);
        purchaseToken.mint{value: 1 ether}(); // Bob gets 100 PT
        bobPTbalance = purchaseToken.balanceOf(bob);
        vm.stopPrank();

        vm.startPrank(charlie);
        purchaseToken.mint{value: 1 ether}(); // Charlie gets 100 PT
        charliePTbalance = purchaseToken.balanceOf(charlie);
        vm.stopPrank();

        vm.startPrank(dave);
        purchaseToken.mint{value: 1 ether}(); // Dave gets 100 PT
        davePTbalance = purchaseToken.balanceOf(dave);
        vm.stopPrank();
    }

    function testCompleteSystem() external {
        // Alice creates a new event on the primary market
        vm.startPrank(alice);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Live Concert", ticketPrice, 100);
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
        secondaryMarket.listTicket(address(ticketNFT), ticketIdBob, bobListPrice); // List for double price
        vm.stopPrank();

        // Dave bids on Bob's ticket on the secondary market for price + 1
        vm.startPrank(dave);
        purchaseToken.approve(address(secondaryMarket), daveBidPrice);
        secondaryMarket.submitBid(address(ticketNFT), ticketIdBob, daveBidPrice, "Dave");
        uint256 daveTokenBalanceAfterBid = purchaseToken.balanceOf(dave);
        vm.stopPrank();

        // Bob accepts Dave's bid on the secondary market
        vm.startPrank(bob);
        secondaryMarket.acceptBid(address(ticketNFT), ticketIdBob);
        uint256 bobTokenBalanceAfterSale = purchaseToken.balanceOf(bob);
        vm.stopPrank();

        // Calculate the fee in wei
        uint256 feeAmount = (daveBidPrice * 5) / 100;

        // Bob's final balance should be his initial balance minus the ticket price plus Dave's bid price minus the fee
        uint256 bobFinalBalance = bobPTbalance - ticketPrice + daveBidPrice - feeAmount;

        // Dave's final balance should be his initial balance minus Dave's bid price
        uint256 daveFinalBalance = davePTbalance - daveBidPrice;

        // Alice's final balance should be her initial balance plus the ticket price from the primary market sale plus the fee from the secondary market sale
        uint256 aliceFinalBalance = alicePTbalance + ticketPrice + ticketPrice + feeAmount;

        // Charlie's final balance should remain unchanged after his initial purchase
        uint256 charlieFinalBalance = charliePTbalance - ticketPrice; // Assuming Charlie bought 1 ticket in the primary market

        assertEq(purchaseToken.balanceOf(alice), aliceFinalBalance, "Alice's balance should be correct after the market activities");
        assertEq(purchaseToken.balanceOf(bob), bobFinalBalance, "Bob's balance should be correct after the market activities");
        assertEq(purchaseToken.balanceOf(dave), daveFinalBalance, "Dave's balance should be correct after the market activities");
        assertEq(purchaseToken.balanceOf(charlie), charlieFinalBalance, "Charlie's balance should remain unchanged after the market activities");
    }
}