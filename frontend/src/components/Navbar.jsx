import { Link } from 'react-router-dom'
import { SignInButton, SignedIn, SignedOut, UserButton } from '@clerk/clerk-react'
import { useWallet } from '../hooks/useWallet'

export default function Navbar() {
  const { isConnected } = useWallet()

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
          <UserButton afterSignOutUrl="/" />
        </SignedIn>
      </div>
    </nav>
  )
}