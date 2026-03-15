// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TicketNFT.sol";
import "./TicketPricing.sol";

interface IEscrow {
    function deposit(uint256 eventId, address organizer) external payable;
}

/// @title EventManager
/// @notice Core orchestrator. Handles event lifecycle, admin approval,
///         ticket purchasing, and event completion triggering.
contract EventManager is Ownable, ReentrancyGuard {

    TicketNFT     public ticketNFT;
    TicketPricing public ticketPricing;
    address       public escrow;

    enum EventStatus { Pending, Active, Completed, Cancelled }

    struct Event {
        uint256     id;
        string      name;
        string      venue;
        uint256     date;
        uint256     totalSeats;
        uint256     seatsSold;
        EventStatus status;
        address     organizer;
    }

    uint256 private _eventCounter;

    mapping(uint256 => Event)                          public events;
    mapping(address => bool)                           public approvedAdmins;
    mapping(uint256 => mapping(string => bool))        public seatTaken;
    mapping(uint256 => mapping(string => uint256))     public tierSeats;

    event AdminApproved(address indexed admin);
    event AdminRevoked(address indexed admin);
    event EventCreated(uint256 indexed eventId, string name, address organizer);
    event EventActivated(uint256 indexed eventId);
    event EventCompleted(uint256 indexed eventId);
    event EventCancelled(uint256 indexed eventId);
    event TicketPurchased(uint256 indexed eventId, uint256 tokenId, address buyer, string seat, string tier);

    modifier onlyAdmin() {
        require(approvedAdmins[msg.sender] || msg.sender == owner(), "Not an approved admin");
        _;
    }

    modifier eventExists(uint256 eventId) {
        require(eventId > 0 && eventId <= _eventCounter, "Event does not exist");
        _;
    }

    constructor(address _ticketNFT, address _ticketPricing) Ownable() {
        require(_ticketNFT != address(0), "Zero address: NFT");
        require(_ticketPricing != address(0), "Zero address: Pricing");
        ticketNFT     = TicketNFT(_ticketNFT);
        ticketPricing = TicketPricing(_ticketPricing);
    }

    function approveAdmin(address admin) external onlyOwner {
        require(admin != address(0), "Zero address");
        approvedAdmins[admin] = true;
        emit AdminApproved(admin);
    }

    function revokeAdmin(address admin) external onlyOwner {
        approvedAdmins[admin] = false;
        emit AdminRevoked(admin);
    }

    function setEscrow(address _escrow) external onlyOwner {
        require(_escrow != address(0), "Zero address");
        escrow = _escrow;
    }

    function createEvent(
        string calldata name,
        string calldata venue,
        uint256 date,
        uint256 totalSeats
    ) external onlyAdmin returns (uint256) {
        require(date > block.timestamp, "Event date must be in future");
        require(totalSeats > 0, "Must have at least 1 seat");
        _eventCounter++;
        uint256 eventId = _eventCounter;
        events[eventId] = Event({
            id:         eventId,
            name:       name,
            venue:      venue,
            date:       date,
            totalSeats: totalSeats,
            seatsSold:  0,
            status:     EventStatus.Pending,
            organizer:  msg.sender
        });
        emit EventCreated(eventId, name, msg.sender);
        return eventId;
    }

    function setTierSeats(
        uint256 eventId,
        string calldata tier,
        uint256 seats
    ) external onlyAdmin eventExists(eventId) {
        require(events[eventId].status == EventStatus.Pending, "Event already active");
        tierSeats[eventId][tier] = seats;
    }

    function activateEvent(uint256 eventId) external onlyOwner eventExists(eventId) {
        require(events[eventId].status == EventStatus.Pending, "Not pending");
        events[eventId].status = EventStatus.Active;
        emit EventActivated(eventId);
    }

    function completeEvent(uint256 eventId) external onlyOwner eventExists(eventId) {
        require(events[eventId].status == EventStatus.Active, "Not active");
        events[eventId].status = EventStatus.Completed;
        emit EventCompleted(eventId);
    }

    function cancelEvent(uint256 eventId) external onlyOwner eventExists(eventId) {
        EventStatus s = events[eventId].status;
        require(s == EventStatus.Pending || s == EventStatus.Active, "Cannot cancel");
        events[eventId].status = EventStatus.Cancelled;
        emit EventCancelled(eventId);
    }

    function buyTicket(
        uint256 eventId,
        string calldata seat,
        string calldata tier
    ) external payable nonReentrant eventExists(eventId) {
        Event storage ev = events[eventId];
        require(ev.status == EventStatus.Active, "Event not active");
        require(ev.seatsSold < ev.totalSeats, "Sold out");
        require(!seatTaken[eventId][seat], "Seat already taken");
        require(tierSeats[eventId][tier] > 0, "No seats left in tier");
        require(escrow != address(0), "Escrow not configured");
        uint256 price = ticketPricing.getPrice(tier);
        require(msg.value == price, "Incorrect ETH amount");
        seatTaken[eventId][seat] = true;
        tierSeats[eventId][tier]--;
        ev.seatsSold++;
        uint256 tokenId = ticketNFT.mint(msg.sender, eventId, seat, tier, price);
        IEscrow(escrow).deposit{value: msg.value}(eventId, ev.organizer);
        emit TicketPurchased(eventId, tokenId, msg.sender, seat, tier);
    }

    function useTicket(uint256 tokenId) external onlyAdmin {
        ticketNFT.markUsed(tokenId);
    }

    function getEvent(uint256 eventId) external view returns (Event memory) {
        return events[eventId];
    }

    function totalEvents() external view returns (uint256) {
        return _eventCounter;
    }
}
