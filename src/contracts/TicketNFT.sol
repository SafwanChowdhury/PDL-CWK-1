// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

contract TicketNFT is ITicketNFT {
    address private _creator;
    uint256 private _maxNumberOfTickets;
    string private _eventName;
    uint256 private _ticketCount;
    mapping(uint256 => address) private _ticketOwners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _ticketHolderNames;
    mapping(uint256 => bool) private _ticketUsed;
    mapping(uint256 => uint256) private _ticketExpiry;
    mapping(uint256 => address) private _ticketApprovals;

    constructor(string memory eventName, uint256 maxNumberOfTickets) {
        _creator = msg.sender;
        _eventName = eventName;
        _maxNumberOfTickets = maxNumberOfTickets;
    }

    function creator() external view override returns (address) {
        return _creator;
    }

    function maxNumberOfTickets() external view override returns (uint256) {
        return _maxNumberOfTickets;
    }

    function eventName() external view override returns (string memory) {
        return _eventName;
    }

    function mint(address holder, string memory holderName) external override returns (uint256 id) {
        require(msg.sender == _creator, "Only creator can mint tickets");
        require(_ticketCount < _maxNumberOfTickets, "Max ticket limit reached");

        uint256 ticketID = _ticketCount + 1;
        _ticketOwners[ticketID] = holder;
        _ticketHolderNames[ticketID] = holderName;
        _ticketExpiry[ticketID] = block.timestamp + 10 days;
        _ticketUsed[ticketID] = false;
        _balances[holder] += 1;
        _ticketCount += 1;

        emit Transfer(address(0), holder, ticketID);

        return ticketID;
    }

    function balanceOf(address holder) external view override returns (uint256 balance) {
        require(holder != address(0), "Zero address not allowed");
        return _balances[holder];
    }

    function holderOf(uint256 ticketID) external view override returns (address holder) {
        require(ticketID <= _ticketCount, "Ticket does not exist");
        return _ticketOwners[ticketID];
    }

    function transferFrom(
        address from,
        address to,
        uint256 ticketID
    ) external override {
        require(from != address(0) && to != address(0), "Zero address not allowed");
        require(_ticketOwners[ticketID] == from, "Sender is not the ticket owner");
        require(msg.sender == from || msg.sender == _ticketApprovals[ticketID], "Caller is not owner nor approved");

        _ticketOwners[ticketID] = to;
        _balances[from] -= 1;
        _balances[to] += 1;
        _ticketApprovals[ticketID] = address(0);

        emit Transfer(from, to, ticketID);
        emit Approval(from, address(0), ticketID);
    }

    function approve(address to, uint256 ticketID) external override {
        address owner = _ticketOwners[ticketID];
        require(msg.sender == owner, "Caller is not the ticket owner");
        require(ticketID <= _ticketCount, "Ticket does not exist");

        _ticketApprovals[ticketID] = to;

        emit Approval(owner, to, ticketID);
    }

    function getApproved(uint256 ticketID) external view override returns (address operator) {
        require(ticketID <= _ticketCount, "Ticket does not exist");
        return _ticketApprovals[ticketID];
    }

    function holderNameOf(uint256 ticketID) external view override returns (string memory holderName) {
        require(ticketID <= _ticketCount, "Ticket does not exist");
        return _ticketHolderNames[ticketID];
    }

    function updateHolderName(uint256 ticketID, string calldata newName) external override {
        require(ticketID <= _ticketCount, "Ticket does not exist");
        require(msg.sender == _ticketOwners[ticketID], "Caller is not the ticket owner");

        _ticketHolderNames[ticketID] = newName;
    }

    function setUsed(uint256 ticketID) external override {
        require(msg.sender == _creator, "Only creator can set ticket as used");
        require(!_ticketUsed[ticketID], "Ticket is already used");
        require(_ticketExpiry[ticketID] > block.timestamp, "Ticket is expired");
        require(ticketID <= _ticketCount, "Ticket does not exist");

        _ticketUsed[ticketID] = true;
    }

    function isExpiredOrUsed(uint256 ticketID) external view override returns (bool) {
        require(ticketID <= _ticketCount, "Ticket does not exist");
        return _ticketUsed[ticketID] || block.timestamp > _ticketExpiry[ticketID];
    }
}
