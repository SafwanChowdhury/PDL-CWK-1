pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Make sure to inherit from the ERC721 standard as well as the ITicketNFT interface
contract TicketNFT is ERC721, ITicketNFT {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Define the struct for the ticket metadata
    struct TicketMetadata {
        string eventName;
        string holderName;
        uint256 validityTimestamp;
        bool isUsed;
    }

    // Mapping from token ID to TicketMetadata
    mapping(uint256 => TicketMetadata) private _ticketMetadata;

    constructor() ERC721("TicketNFT", "TICK") {}

    // Implement the createTicket function from the ITicketNFT interface
    function createTicket(
        address to,
        string memory eventName,
        string memory holderName,
        uint256 validityTimestamp
    ) public override returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTicketId = _tokenIdCounter.current();
        _safeMint(to, newTicketId);
        _ticketMetadata[newTicketId] = TicketMetadata({
            eventName: eventName,
            holderName: holderName,
            validityTimestamp: validityTimestamp,
            isUsed: false
        });
        return newTicketId;
    }

    // Implement the useTicket function from the ITicketNFT interface
    function useTicket(uint256 ticketId) public override {
        require(_exists(ticketId), "TicketNFT: ticket does not exist");
        require(!_ticketMetadata[ticketId].isUsed, "TicketNFT: ticket already used");
        require(block.timestamp <= _ticketMetadata[ticketId].validityTimestamp, "TicketNFT: ticket is expired");
        
        // Here you'd implement the logic to mark the ticket as used
        _ticketMetadata[ticketId].isUsed = true;
        
        // Emit an event or other business logic
    }

    // Override the _beforeTokenTransfer function from ERC721 to include your business logic
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        
        // Include the business logic for when a ticket is transferred
        // For example, check if the ticket is not used or expired
    }

    // Implement other necessary functions from the ITicketNFT interface here

    // Optional: Implement a function to get the metadata of a ticket
    function getTicketMetadata(uint256 ticketId) public view returns (TicketMetadata memory) {
        require(_exists(ticketId), "TicketNFT: ticket does not exist");
        return _ticketMetadata[ticketId];
    }
}
