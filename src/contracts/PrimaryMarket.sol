// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/IERC20.sol";
import "../interfaces/ITicketNFT.sol";
import "../contracts/TicketNFT.sol";

contract PrimaryMarket {
    // State variables
    IERC20 public purchaseToken;
    uint256 public fixedTicketPrice;
    mapping(address => TicketNFT) public eventToTicketNFT;

    // Events
    event EventCreated(address indexed eventAddress, string eventName, uint256 maxTickets);
    event TicketPurchased(address indexed buyer, uint256 ticketId, address eventAddress);

    // Constructor
    constructor(IERC20 _purchaseToken, uint256 _fixedTicketPrice) {
        purchaseToken = _purchaseToken;
        fixedTicketPrice = _fixedTicketPrice;
    }

    // Function to create a new Ticket NFT collection
    function createNewEvent(string memory eventName, uint256 maxTickets) external returns (address) {
        TicketNFT newTicketNFT = new TicketNFT(eventName, maxTickets);
        eventToTicketNFT[address(newTicketNFT)] = newTicketNFT;

        emit EventCreated(address(newTicketNFT), eventName, maxTickets);
        return address(newTicketNFT);
    }

    // Function to purchase tickets
    function purchase(address eventAddress, string memory purchaserName) external {
        TicketNFT ticketNFT = eventToTicketNFT[eventAddress];
        require(address(ticketNFT) != address(0), "Event does not exist");
        require(ticketNFT.balanceOf(msg.sender) < ticketNFT.maxNumberOfTickets(), "Purchase would exceed max supply of tickets");
        
        // Transfer the fixed price from the purchaser to the contract
        require(purchaseToken.transferFrom(msg.sender, ticketNFT.creator(), fixedTicketPrice), "Token transfer failed");

        // Mint the ticket
        uint256 ticketId = ticketNFT.mint(msg.sender, purchaserName);

        emit TicketPurchased(msg.sender, ticketId, eventAddress);
    }

}
