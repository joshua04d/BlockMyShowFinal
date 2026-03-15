# BlockMyShow 🎟

A decentralized NFT ticketing platform built on Ethereum. Buy, own, and resell event tickets as ERC-721 NFTs — no scalpers, no fakes, everything on-chain.

---

## Tech Stack

### Blockchain
| Tool | Version |
|---|---|
| Solidity | 0.8.20 |
| Hardhat | 2.22.0 |
| @nomicfoundation/hardhat-toolbox | hh2 (Hardhat 2 compatible) |
| @openzeppelin/contracts | 4.9.6 |
| dotenv | latest |
| Node.js | v22.22.1 |
| Network | Ethereum Sepolia Testnet |

### Frontend
| Tool | Version |
|---|---|
| React | 18 |
| Vite | 5.4.0 |
| Ethers.js | v6 |
| Privy | latest (@privy-io/react-auth) |
| React Router | v6 |
| qrcode.react | latest |

---

## Project Structure

```
BlockMyShow/
├── contracts/
│   ├── TicketNFT.sol          # ERC-721 ticket token
│   ├── TicketPricing.sol      # Static pricing per tier (swappable)
│   ├── EventManager.sol       # Core orchestrator
│   ├── Escrow.sol             # ETH escrow + refunds
│   └── TicketResale.sol       # Secondary market, 10% cap
├── scripts/
│   └── deploy.js              # Deployment script
├── test/
│   └── BlockMyShow.test.js    # Full test suite
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Navbar.jsx
│   │   │   ├── EventCard.jsx
│   │   │   └── TicketQR.jsx
│   │   ├── pages/
│   │   │   ├── Landing.jsx    # Public landing page
│   │   │   ├── Events.jsx     # Event listings (auth required)
│   │   │   ├── BuyTicket.jsx  # Purchase flow
│   │   │   ├── MyTickets.jsx  # User NFTs + QR
│   │   │   └── Resale.jsx     # Resale marketplace
│   │   ├── hooks/
│   │   │   └── useWallet.js   # Privy wallet hook
│   │   └── contracts/
│   │       └── addresses.js   # Deployed addresses + ABIs
├── hardhat.config.js
├── .env                       # Never commit this
└── README.md
```

---

## Smart Contract Architecture

```
Owner (deployer)
├── EventManager.sol        ← core orchestrator
│   ├── creates/manages events
│   ├── approves admins
│   ├── mints tickets via TicketNFT
│   └── triggers escrow release
├── TicketNFT.sol           ← ERC-721, minted only by EventManager
│   └── stores: eventId, seat, tier, originalPrice on-chain
├── Escrow.sol              ← holds ETH, releases on completeEvent()
│   └── manual refunds per ticket on cancellation
├── TicketResale.sol        ← secondary market, 10% cap enforced
└── TicketPricing.sol       ← static pricing, swappable interface
```

---

## Key Features

- **ERC-721 NFT Tickets** — each ticket is a unique on-chain token
- **Escrow Payments** — ETH held safely, released only on event completion
- **10% Resale Cap** — enforced in `TicketResale.sol`, cannot be bypassed
- **On-chain Metadata** — eventId, seat, tier, originalPrice stored on-chain
- **Wallet-signed QR** — tamper-proof QR codes for gate verification
- **Privy Auth** — Google/email login with auto embedded wallet creation
- **Admin Panel** — owner-gated event management

---

## Deployed Contracts (Sepolia)

| Contract | Address |
|---|---|
| TicketPricing | `0x03ffE6E9964CFd780687eDF8002B8BcB6989F3B3` |
| TicketNFT | `0x72FE433D93bC0B0BF8CcbcAcc59a5b24EEAa9CbD` |
| EventManager | `0xA96831F15AC3e4D350527c6D9924cf98c48f12D3` |
| Escrow | `0x928bDD0a6E920601b6aFa054Beb363A498F60b83` |
| TicketResale | `0x5F8A19C207468e004b1274fd073170fDc2fd44e3` |

---

## Setup

```bash
# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to Sepolia
npx hardhat run scripts/deploy.js --network sepolia

# Run frontend
cd frontend
npm install
npm run dev
```

---

## Environment Variables

Create a `.env` file in the root:

```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=YOUR_PRIVATE_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY
```

---

## Build Phases

| Phase | Description | Status |
|---|---|---|
| 0 | Project scaffold, Hardhat config | ✅ |
| 1 | TicketNFT.sol + TicketPricing.sol | ✅ |
| 2 | EventManager.sol | ✅ |
| 3 | Escrow.sol | ✅ |
| 4 | TicketResale.sol | ✅ |
| 5 | Deploy script + test suite (17/17) | ✅ |
| 6 | React frontend shell | ✅ |
| 7 | Sepolia deployment | ✅ |
| 8 | Privy auth + landing page | 🔜 |
| 9 | User pages + resale | 🔜 |
| 10 | Admin panel | 🔜 |
| 11 | UI polish + toasts | 🔜 |
| 12 | Vercel deployment | 🔜 |

---

## License
MIT