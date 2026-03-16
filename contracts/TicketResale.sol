// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./TicketNFT.sol";

/// @title TicketResale
/// @notice Secondary market for BlockMyShow tickets.
///         Resale cap is variable — set by owner per event or globally.
contract TicketResale is Ownable, ReentrancyGuard {

    TicketNFT public ticketNFT;

    uint256 public platformFeeBps  = 0;
    address public feeRecipient;

    /// @notice Global default resale cap in basis points (1000 = 10%)
    uint256 public defaultResaleCapBps = 1000;

    /// @notice Per-event resale cap override (0 = use default)
    mapping(uint256 => uint256) public eventResaleCapBps;

    enum ListingStatus { Active, Sold, Cancelled }

    struct Listing {
        uint256       tokenId;
        address       seller;
        uint256       price;
        ListingStatus status;
    }

    uint256 private _listingCounter;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => uint256) public activeListingByToken;

    event TicketListed(uint256 indexed listingId, uint256 indexed tokenId, address seller, uint256 price);
    event TicketSold(uint256 indexed listingId, uint256 indexed tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 indexed listingId, uint256 indexed tokenId);
    event PlatformFeeUpdated(uint256 newFeeBps);
    event DefaultResaleCapUpdated(uint256 newCapBps);
    event EventResaleCapUpdated(uint256 indexed eventId, uint256 newCapBps);

    constructor(address _ticketNFT) Ownable() {
        require(_ticketNFT != address(0), "Zero address: NFT");
        ticketNFT    = TicketNFT(_ticketNFT);
        feeRecipient = msg.sender;
    }

    // ─── Admin: Set Resale Caps ─────────────────────────────────────────────

    /// @notice Set the global default resale cap (e.g. 1000 = 10%, 2000 = 20%)
    function setDefaultResaleCap(uint256 capBps) external onlyOwner {
        require(capBps <= 10000, "Cap cannot exceed 100%");
        defaultResaleCapBps = capBps;
        emit DefaultResaleCapUpdated(capBps);
    }

    /// @notice Set a per-event resale cap override
    function setEventResaleCap(uint256 eventId, uint256 capBps) external onlyOwner {
        require(capBps <= 10000, "Cap cannot exceed 100%");
        eventResaleCapBps[eventId] = capBps;
        emit EventResaleCapUpdated(eventId, capBps);
    }

    /// @notice Get the effective resale cap for a given event
    function getResaleCap(uint256 eventId) public view returns (uint256) {
        uint256 cap = eventResaleCapBps[eventId];
        return cap > 0 ? cap : defaultResaleCapBps;
    }

    // ─── List Ticket ────────────────────────────────────────────────────────

    function listTicket(uint256 tokenId, uint256 price) external returns (uint256) {
        require(ticketNFT.ownerOf(tokenId) == msg.sender, "Not ticket owner");
        require(activeListingByToken[tokenId] == 0, "Already listed");
        require(price > 0, "Price must be > 0");

        TicketNFT.TicketData memory ticket = ticketNFT.getTicket(tokenId);
        require(!ticket.used, "Ticket already used");

        // Apply resale cap for this ticket's event
        uint256 originalPrice = ticketNFT.getOriginalPrice(tokenId);
        uint256 capBps        = getResaleCap(ticket.eventId);
        uint256 maxAllowed    = originalPrice + (originalPrice * capBps / 10000);
        require(price <= maxAllowed, "Price exceeds resale cap");

        require(
            ticketNFT.getApproved(tokenId) == address(this) ||
            ticketNFT.isApprovedForAll(msg.sender, address(this)),
            "Resale contract not approved"
        );

        _listingCounter++;
        uint256 listingId = _listingCounter;
        listings[listingId] = Listing({
            tokenId: tokenId,
            seller:  msg.sender,
            price:   price,
            status:  ListingStatus.Active
        });
        activeListingByToken[tokenId] = listingId;
        emit TicketListed(listingId, tokenId, msg.sender, price);
        return listingId;
    }

    // ─── Buy Listed Ticket ──────────────────────────────────────────────────

    function buyTicket(uint256 listingId) external payable nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.status == ListingStatus.Active, "Listing not active");
        require(msg.value == listing.price, "Incorrect ETH amount");
        require(msg.sender != listing.seller, "Seller cannot buy own ticket");

        listing.status = ListingStatus.Sold;
        activeListingByToken[listing.tokenId] = 0;

        uint256 fee          = (listing.price * platformFeeBps) / 10000;
        uint256 sellerPayout = listing.price - fee;

        ticketNFT.safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        (bool sellerSent, ) = listing.seller.call{value: sellerPayout}("");
        require(sellerSent, "Seller payment failed");

        if (fee > 0) {
            (bool feeSent, ) = feeRecipient.call{value: fee}("");
            require(feeSent, "Fee transfer failed");
        }

        emit TicketSold(listingId, listing.tokenId, msg.sender, listing.price);
    }

    // ─── Cancel Listing ─────────────────────────────────────────────────────

    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender || msg.sender == owner(), "Not authorized");
        require(listing.status == ListingStatus.Active, "Listing not active");
        listing.status = ListingStatus.Cancelled;
        activeListingByToken[listing.tokenId] = 0;
        emit ListingCancelled(listingId, listing.tokenId);
    }

    // ─── Admin: Platform Fee ────────────────────────────────────────────────

    function setPlatformFee(uint256 feeBps) external onlyOwner {
        require(feeBps <= 1000, "Max 10% platform fee");
        platformFeeBps = feeBps;
        emit PlatformFeeUpdated(feeBps);
    }

    function setFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Zero address");
        feeRecipient = recipient;
    }

    // ─── Views ──────────────────────────────────────────────────────────────

    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }

    function isListed(uint256 tokenId) external view returns (bool) {
        return activeListingByToken[tokenId] != 0;
    }

    function totalListings() external view returns (uint256) {
        return _listingCounter;
    }
}
