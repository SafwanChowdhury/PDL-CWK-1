pragma solidity ^0.8.10;

import "../interfaces/IERC20.sol";
import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/ITicketNFT.sol";
import "./TicketNFT.sol";

contract PrimaryMarket is IPrimaryMarket {
    IERC20 public purchasingToken;
    address[] private ticketCollections;

    constructor(IERC20 _purchasingToken) {
        purchasingToken = _purchasingToken;
    }

    function createNewEvent(
        string memory eventName,
        uint256 price,
        uint256 maxNumberOfTickets
    ) external returns (ITicketNFT ticketCollection) {
        TicketNFT newTicketNFT = new TicketNFT(eventName, price, maxNumberOfTickets, msg.sender, address(this));
        ticketCollections.push(address(newTicketNFT));

        emit EventCreated(msg.sender, address(newTicketNFT), eventName, price, maxNumberOfTickets);
        return ITicketNFT(newTicketNFT);
    }

    modifier ticketCollectionExists(address ticketCollection) {
        bool exists = false;
        for (uint256 i = 0; i < ticketCollections.length; i++) {
            if (ticketCollections[i] == ticketCollection) {
                exists = true;
                break;
            }
        }
        require(exists, "Ticket collection does not exist");
        _;
    }

    function purchase(
        address ticketCollection,
        string memory holderName
    ) external ticketCollectionExists(ticketCollection) returns (uint256 id) {
        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        require(ticketNFT.balanceOf(msg.sender) < ticketNFT.maxNumberOfTickets(), "Max tickets reached for holder");
        
        uint256 ticketPrice = ticketNFT.ticketPrice();
        require(purchasingToken.transferFrom(msg.sender, ticketNFT.creator(), ticketPrice), "Token transfer failed");

        uint256 ticketId = ticketNFT.mint(msg.sender, holderName);

        emit Purchase(msg.sender, ticketCollection, ticketId, holderName);
        return ticketId;
    }

    function getPrice(
        address ticketCollection
    ) external view ticketCollectionExists(ticketCollection) returns (uint256 price) {
        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        return ticketNFT.ticketPrice();
    }
}