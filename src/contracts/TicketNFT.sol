pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

contract TicketNFT is ITicketNFT {
    address immutable private _creator;
    uint256 private _maxNumberOfTickets;
    string private _eventName;
    address immutable private _primaryMarket;
    uint256 private _ticketCount;
    uint256 immutable public ticketPrice;

    struct TicketInfo {
        address holder;
        string holderName;
        uint256 timestampTillValid;
        bool isUsed;
    }

    mapping(uint256 => TicketInfo) private _tickets;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _ticketApprovals;

    constructor(string memory __eventName, uint256 _price, uint256 _maxTickets, address __creator, address primaryMarket) {
        _creator = __creator;
        _eventName = __eventName;
        _maxNumberOfTickets = _maxTickets;
        _primaryMarket = primaryMarket;
        ticketPrice = _price;
    }

    modifier onlyPrimaryMarket() {
        require(msg.sender == _primaryMarket, "Caller is not the primary market");
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == _creator, "Caller is not the creator");
        _;
    }

    modifier onlyTicketHolder(uint256 ticketID) {
        require(_tickets[ticketID].holder == msg.sender, "Caller is not the ticket holder");
        _;
    }

    modifier ticketExists(uint256 ticketID) {
        require(ticketID < _ticketCount, "Ticket does not exist");
        _;
    }

    modifier isNotExpiredOrUsed(uint256 ticketID) {
        require(!_tickets[ticketID].isUsed, "Ticket is already used");
        require(block.timestamp < _tickets[ticketID].timestampTillValid, "Ticket is expired");
        _;
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

    function mint(address holder, string memory holderName) external override onlyPrimaryMarket returns (uint256 id) {
        require(_ticketCount < _maxNumberOfTickets, "Max ticket limit reached");

        _tickets[_ticketCount] = TicketInfo({
            holder: holder,
            holderName: holderName,
            timestampTillValid: block.timestamp + 10 days,
            isUsed: false
        });
        _balances[holder]++;
        
        emit Transfer(address(0), holder, _ticketCount);

        return _ticketCount++;
    }

    function balanceOf(address holder) external view override returns (uint256 balance) {
        return _balances[holder];
    }

    function holderOf(uint256 ticketID) external view override ticketExists(ticketID) returns (address holder) {
        return _tickets[ticketID].holder;
    }

    function transferFrom(address from, address to, uint256 ticketID) external override ticketExists(ticketID) {
        require(from != address(0) && to != address(0), "Address zero is not valid");
        require(_tickets[ticketID].holder == from, "Sender is not the ticket owner");
        require(msg.sender == from || msg.sender == _ticketApprovals[ticketID], "Caller is not owner nor approved");

        _tickets[ticketID].holder = to;
        _balances[from]--;
        _balances[to]++;
        _ticketApprovals[ticketID] = address(0);

        emit Transfer(from, to, ticketID);
        emit Approval(from, address(0), ticketID);
    }

    function approve(address to, uint256 ticketID) external override onlyTicketHolder(ticketID) ticketExists(ticketID) {
        _ticketApprovals[ticketID] = to;

        emit Approval(_tickets[ticketID].holder, to, ticketID);
    }

    function getApproved(uint256 ticketID) external view override ticketExists(ticketID) returns (address operator) {
        return _ticketApprovals[ticketID];
    }

    function holderNameOf(uint256 ticketID) external view override ticketExists(ticketID) returns (string memory holderName) {
        return _tickets[ticketID].holderName;
    }

    function updateHolderName(uint256 ticketID, string calldata newName) external override onlyTicketHolder(ticketID) ticketExists(ticketID) {
        _tickets[ticketID].holderName = newName;
    }

    function setUsed(uint256 ticketID) external override onlyCreator ticketExists(ticketID) isNotExpiredOrUsed(ticketID) {
        _tickets[ticketID].isUsed = true;
    }

    function isExpiredOrUsed(uint256 ticketID) external view override ticketExists(ticketID) returns (bool) {
        return _tickets[ticketID].isUsed || block.timestamp > _tickets[ticketID].timestampTillValid;
    }
}
