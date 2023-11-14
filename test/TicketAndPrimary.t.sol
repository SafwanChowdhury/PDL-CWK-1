// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// import "forge-std/Test.sol";
// import "../src/interfaces/IERC20.sol";
// import "../src/interfaces/ITicketNFT.sol";
// import "../src/contracts/PurchaseToken.sol";
// import "../src/contracts/TicketNFT.sol";
// import "../src/contracts/PrimaryMarket.sol";

// contract PrimaryMarketTest is Test {
//     PurchaseToken public purchaseToken;
//     PrimaryMarket public primaryMarket;

//     address public eventCreator;
//     address public purchaser;
//     uint256 public ticketPrice = 1 ether;
//     string public eventName = "Blockchain Concert";
//     uint256 public maxTickets = 100;

//     function setUp() public {
//         eventCreator = makeAddr("eventCreator");
//         purchaser = makeAddr("purchaser");

//         purchaseToken = new PurchaseToken();
//         primaryMarket = new PrimaryMarket(purchaseToken);

//         // Providing ETH to the event creator and purchaser to mint PurchaseTokens
//         vm.deal(eventCreator, 10 ether);
//         vm.deal(purchaser, 10 ether);

//         // Event creator mints PurchaseTokens
//         vm.startPrank(eventCreator);
//         purchaseToken.mint{value: 5 ether}();
//         vm.stopPrank();

//         // Purchaser mints PurchaseTokens
//         vm.startPrank(purchaser);
//         purchaseToken.mint{value: 5 ether}();
//         vm.stopPrank();
//     }

//     function testCreateNewEvent() public {
//         vm.startPrank(eventCreator);
//         ITicketNFT ticketNFT = primaryMarket.createNewEvent(eventName, ticketPrice, maxTickets);

//         assertEq(ticketNFT.creator(), eventCreator, "Event creator should be set correctly.");
//         assertEq(ticketNFT.maxNumberOfTickets(), maxTickets, "Max number of tickets should be set correctly.");
//         assertEq(ticketNFT.eventName(), eventName, "Event name should be set correctly.");

//         vm.stopPrank();
//     }

//     function testPurchaseTicket() public {
//         // Event creator creates a new event
//         vm.startPrank(eventCreator);
//         ITicketNFT ticketNFT = primaryMarket.createNewEvent(eventName, ticketPrice, maxTickets);
//         vm.stopPrank();

//         // Purchaser approves ERC20 token spending and purchases a ticket
//         vm.startPrank(purchaser);
//         uint256 purchaserBalanceBefore = purchaseToken.balanceOf(purchaser);
//         purchaseToken.approve(address(primaryMarket), ticketPrice);

//         // Ensure the correct amount of tokens is approved
//         assertEq(purchaseToken.allowance(purchaser, address(primaryMarket)), ticketPrice, "Approval amount incorrect.");

//         uint256 ticketId = primaryMarket.purchase(address(ticketNFT), "Purchaser");

//         // Check balances after purchase
//         uint256 purchaserBalanceAfter = purchaseToken.balanceOf(purchaser);
//         uint256 expectedBalance = purchaserBalanceBefore - ticketPrice;
//         assertEq(purchaserBalanceAfter, expectedBalance, "Purchaser's token balance should be reduced by the ticket price.");

//         // Other assertions remain the same
//         // ...

//         vm.stopPrank();
//     }


//     function testGetPrice() public {
//         // Event creator creates a new event
//         vm.startPrank(eventCreator);
//         ITicketNFT ticketNFT = primaryMarket.createNewEvent(eventName, ticketPrice, maxTickets);
//         vm.stopPrank();

//         uint256 fetchedPrice = primaryMarket.getPrice(address(ticketNFT));
//         assertEq(fetchedPrice, ticketPrice, "The fetched price should match the set ticket price.");
//     }
// }
