import { Link } from 'react-router-dom'
import { useWallet } from '../hooks/useWallet'

export default function Navbar() {
  const {
    ready,
    isConnected,
    isOnSepolia,
    shortAddress,
    login,
    logout,
    switchToSepolia,
  } = useWallet()

  return (
    <nav className="navbar">
      <Link to="/" className="navbar-brand">
        Block<span>MyShow</span>
      </Link>

      <div className="navbar-links">
        <Link to="/">Home</Link>
        {isConnected && <Link to="/events">Events</Link>}
        {isConnected && <Link to="/my-tickets">My Tickets</Link>}
        {isConnected && <Link to="/resale">Resale</Link>}

        {!ready ? (
          <button className="btn btn-outline" disabled>Loading...</button>
        ) : !isConnected ? (
          <button className="btn btn-primary" onClick={login}>
            🎟 Sign In
          </button>
        ) : !isOnSepolia ? (
          <button className="btn btn-danger" onClick={switchToSepolia}>
            ⚠️ Switch to Sepolia
          </button>
        ) : (
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <span className="wallet-address">{shortAddress}</span>
            <button className="btn btn-outline" onClick={logout}>
              Sign Out
            </button>
          </div>
        )}
      </div>
    </nav>
  )
}
