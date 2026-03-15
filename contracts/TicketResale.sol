// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./TicketNFT.sol";

/// @title TicketResale
/// @notice Secondary market for BlockMyShow tickets.
///         Enforces 10% resale price cap based on originalPrice stored on-chain.
contract TicketResale is Ownable, ReentrancyGuard {

    TicketNFT public ticketNFT;

    uint256 public platformFeeBps = 0;
    address public feeRecipient;

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

    constructor(address _ticketNFT) Ownable() {
        require(_ticketNFT != address(0), "Zero address: NFT");
        ticketNFT    = TicketNFT(_ticketNFT);
        feeRecipient = msg.sender;
    }

    function listTicket(uint256 tokenId, uint256 price) external returns (uint256) {
        require(ticketNFT.ownerOf(tokenId) == msg.sender, "Not ticket owner");
        require(activeListingByToken[tokenId] == 0, "Already listed");
        uint256 originalPrice = ticketNFT.getOriginalPrice(tokenId);
        uint256 maxAllowed    = originalPrice + (originalPrice / 10);
        require(price <= maxAllowed, "Price exceeds 10% resale cap");
        require(price > 0, "Price must be > 0");
        require(
            ticketNFT.getApproved(tokenId) == address(this) ||
            ticketNFT.isApprovedForAll(msg.sender, address(this)),
            "Resale contract not approved"
        );
        TicketNFT.TicketData memory ticket = ticketNFT.getTicket(tokenId);
        require(!ticket.used, "Ticket already used");
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

    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender || msg.sender == owner(), "Not authorized");
        require(listing.status == ListingStatus.Active, "Listing not active");
        listing.status = ListingStatus.Cancelled;
        activeListingByToken[listing.tokenId] = 0;
        emit ListingCancelled(listingId, listing.tokenId);
    }

    function setPlatformFee(uint256 feeBps) external onlyOwner {
        require(feeBps <= 1000, "Max 10% platform fee");
        platformFeeBps = feeBps;
        emit PlatformFeeUpdated(feeBps);
    }

    function setFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Zero address");
        feeRecipient = recipient;
    }

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
