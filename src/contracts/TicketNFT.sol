pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract TicketNFT is ERC721, ITicketNFT {
    // State variable to keep track of the last token ID
    uint256 private _lastTokenId;

    struct TicketMetadata {
        string eventName;
        string holderName;
        uint256 validityTimestamp;
        bool isUsed;
    }

    mapping(uint256 => TicketMetadata) private _ticketMetadata;

    constructor() ERC721("TicketNFT", "TICK") {
        _lastTokenId = 0;
    }

    function createTicket(
        address to,
        string memory eventName,
        string memory holderName,
        uint256 validityTimestamp
    ) public override returns (uint256) {
        uint256 newTicketId = _lastTokenId + 1;
        _lastTokenId = newTicketId;
        
        _safeMint(to, newTicketId);

        _ticketMetadata[newTicketId] = TicketMetadata({
            eventName: eventName,
            holderName: holderName,
            validityTimestamp: validityTimestamp,
            isUsed: false
        });

        return newTicketId;
    }

    function useTicket(uint256 ticketId) public override {
        require(_exists(ticketId), "TicketNFT: ticket does not exist");
        require(!_ticketMetadata[ticketId].isUsed, "TicketNFT: ticket already used");
        require(block.timestamp <= _ticketMetadata[ticketId].validityTimestamp, "TicketNFT: ticket is expired");
        
        _ticketMetadata[ticketId].isUsed = true;
        // You would also include any additional logic or events here
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        
        // Add any additional logic for token transfer here
    }

    function getTicketMetadata(uint256 ticketId) public view returns (TicketMetadata memory) {
        require(_exists(ticketId), "TicketNFT: ticket does not exist");
        return _ticketMetadata[ticketId];
    }

    // Implement other necessary functions from the ITicketNFT interface here
}
