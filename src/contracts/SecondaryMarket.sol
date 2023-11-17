// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ISecondaryMarket.sol";
import "../interfaces/ITicketNFT.sol";
import "../interfaces/IERC20.sol";
import "./TicketNFT.sol";

contract SecondaryMarket is ISecondaryMarket {
    IERC20 public purchasingToken;

    struct TicketListing {
        uint256 ticketID;
        address ticketOwner;
        address highestBidder;
        string highestBidderName;
        uint256 highestBid;
    }

    mapping(address => mapping(uint256 => TicketListing)) public listings;
    address public primaryMarketAdmin;

    // Fee percentage (5%)
    uint256 public constant feePercentage = 5;
    // Divisor for fee calculation
    uint256 public constant feeDivisor = 100;

    constructor(IERC20 _purchasingToken) {
        purchasingToken = _purchasingToken;
        primaryMarketAdmin = msg.sender; // Set the deployer as the admin
    }

    modifier onlyTicketHolder(ITicketNFT ticketNFT, uint256 ticketID) {
        require(ticketNFT.holderOf(ticketID) == msg.sender, "Caller is not the ticket holder");
        _;
    }

    modifier isNotExpiredOrUsed(ITicketNFT ticketNFT, uint256 ticketID) {
        require(!ticketNFT.isExpiredOrUsed(ticketID), "Ticket is either expired or used");
        _;
    }

    function listTicket(
        address ticketCollection,
        uint256 ticketID,
        uint256 price
    ) external {
        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        require(ticketNFT.holderOf(ticketID) == msg.sender, "Only the ticket owner can list the ticket");
        require(!ticketNFT.isExpiredOrUsed(ticketID), "Ticket is either expired or used");

        ticketNFT.transferFrom(msg.sender, address(this), ticketID);

        listings[ticketCollection][ticketID] = TicketListing({
            ticketID: ticketID,
            ticketOwner: msg.sender,
            highestBidder: address(0),
            highestBidderName: "",
            highestBid: price
        });

        emit Listing(msg.sender, ticketCollection, ticketID, price);
    }

    function submitBid(
        address ticketCollection,
        uint256 ticketID,
        uint256 bidAmount,
        string calldata name
    ) external {
        TicketListing storage listing = listings[ticketCollection][ticketID];
        require(bidAmount > listing.highestBid, "Bid must be higher than the current highest");

        if (listing.highestBidder != address(0)) {
            // Refund the previous highest bidder
            purchasingToken.transfer(listing.highestBidder, listing.highestBid);
        }

        purchasingToken.transferFrom(msg.sender, address(this), bidAmount);

        listing.highestBidder = msg.sender;
        listing.highestBidderName = name;
        listing.highestBid = bidAmount;

        emit BidSubmitted(msg.sender, ticketCollection, ticketID, bidAmount, name);
    }

    function acceptBid(address ticketCollection, uint256 ticketID) external {
        TicketListing storage listing = listings[ticketCollection][ticketID];
        require(listing.ticketOwner == msg.sender, "Only the listing owner can accept a bid");
        require(listing.highestBidder != address(0), "No bid to accept");

        // Calculate the fee to be paid to the primary market's admin 
        uint256 feeAmount = (listing.highestBid * feePercentage) / feeDivisor;
        uint256 payoutAmount = listing.highestBid - feeAmount;

        // Transfer the payout amount to the ticket owner (Alice)
        purchasingToken.transfer(listing.ticketOwner, payoutAmount);

        address eventCreator = ITicketNFT(ticketCollection).creator();
        purchasingToken.transfer(eventCreator, feeAmount);

        // Transfer the ticket to the highest bidder and update the ticket's holder name
        ITicketNFT(ticketCollection).updateHolderName(ticketID, listing.highestBidderName);
        ITicketNFT(ticketCollection).transferFrom(address(this), listing.highestBidder, ticketID);

        emit BidAccepted(listing.highestBidder, ticketCollection, ticketID, listing.highestBid, listing.highestBidderName);

        // Clear the listing after the bid is accepted
        delete listings[ticketCollection][ticketID];
    }

    function delistTicket(address ticketCollection, uint256 ticketID) external {
        TicketListing storage listing = listings[ticketCollection][ticketID];
        require(listing.ticketOwner == msg.sender, "Only the listing owner can delist the ticket");

        if (listing.highestBidder != address(0)) {
            // Refund the current highest bidder
            purchasingToken.transfer(listing.highestBidder, listing.highestBid);
        }

        ITicketNFT(ticketCollection).transferFrom(address(this), msg.sender, ticketID);

        emit Delisting(ticketCollection, ticketID);

        delete listings[ticketCollection][ticketID];
    }

    function getHighestBid(address ticketCollection, uint256 ticketId) external view returns (uint256) {
        return listings[ticketCollection][ticketId].highestBid;
    }

    function getHighestBidder(address ticketCollection, uint256 ticketId) external view returns (address) {
        return listings[ticketCollection][ticketId].highestBidder;
    }
}