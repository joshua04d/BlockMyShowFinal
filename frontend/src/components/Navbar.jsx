import { Link } from 'react-router-dom'
import { SignInButton, SignedIn, SignedOut, UserButton } from '@clerk/clerk-react'
import { useMetaMask } from '../hooks/useMetaMask'

export default function Navbar() {
  const {
    isConnected,
    isOnSepolia,
    shortAddress,
    connecting,
    connect,
    switchToSepolia,
  } = useMetaMask()

  return (
    <nav className="navbar">
      <Link to="/" className="navbar-brand">
        Block<span>MyShow</span>
      </Link>

      <div className="navbar-links">
        <Link to="/">Home</Link>
        <SignedIn>
          <Link to="/events">Events</Link>
          <Link to="/my-tickets">My Tickets</Link>
          <Link to="/resale">Resale</Link>
        </SignedIn>

        <SignedOut>
          <SignInButton mode="modal">
            <button className="btn btn-primary">Sign In</button>
          </SignInButton>
        </SignedOut>

        <SignedIn>
          {!isConnected ? (
            <button
              className="btn btn-outline"
              onClick={() => connect()}
              disabled={connecting}
            >
              {connecting ? <span className="spinner" /> : 'Connect Wallet'}
            </button>
          ) : !isOnSepolia ? (
            <button className="btn btn-danger" onClick={switchToSepolia}>
              Switch to Sepolia
            </button>
          ) : (
            <span className="wallet-address">{shortAddress}</span>
          )}
          <UserButton afterSignOutUrl="/" />
        </SignedIn>
      </div>
    </nav>
  )
}