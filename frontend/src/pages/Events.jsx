import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import { useNavigate } from 'react-router-dom'
import { ADDRESSES, EVENT_MANAGER_ABI } from '../contracts/addresses'
import { useWallet } from '../hooks/useWallet'
import EventCard from '../components/EventCard'

export default function Events() {
  const { isConnected, isOnSepolia, login, switchToSepolia, getProvider } = useWallet()
  const navigate              = useNavigate()
  const [events, setEvents]   = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError]     = useState(null)

  useEffect(() => {
    if (isConnected) fetchEvents()
  }, [isConnected])

  async function fetchEvents() {
    if (!ADDRESSES.EventManager) {
      setError('Contract addresses not configured.')
      return
    }
    try {
      setLoading(true)
      setError(null)
      const provider = await getProvider()
      const contract = new ethers.Contract(ADDRESSES.EventManager, EVENT_MANAGER_ABI, provider)
      const total    = await contract.totalEvents()
      const fetched  = []
      for (let i = 1; i <= Number(total); i++) {
        const ev = await contract.getEvent(BigInt(i))
        fetched.push(ev)
      }
      setEvents(fetched)
    } catch (err) {
      setError(err.message || 'Failed to load events.')
    } finally {
      setLoading(false)
    }
  }

  if (!isConnected) return (
    <div className="empty-state">
      <h2>Sign in to view events</h2>
      <p style={{ marginBottom: '1.5rem' }}>You need to be signed in to browse and purchase tickets.</p>
      <button className="btn btn-primary" onClick={login}>🎟 Sign In</button>
    </div>
  )

  if (!isOnSepolia) return (
    <div className="empty-state">
      <h2>Wrong Network</h2>
      <p style={{ marginBottom: '1.5rem' }}>Please switch to Sepolia testnet.</p>
      <button className="btn btn-danger" onClick={switchToSepolia}>Switch to Sepolia</button>
    </div>
  )

  return (
    <div>
      <div className="page-header">
        <h1>🎟 Upcoming Events</h1>
        <p>Buy tickets as NFTs — yours forever on-chain.</p>
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      {loading && (
        <div style={{ textAlign: 'center', padding: '3rem' }}>
          <span className="spinner" style={{ width: 32, height: 32, borderWidth: 3 }} />
        </div>
      )}

      {!loading && events.length === 0 && !error && (
        <div className="empty-state">
          <h2>No events yet</h2>
          <p>Check back soon.</p>
        </div>
      )}

      {!loading && events.length > 0 && (
        <div className="card-grid">
          {events.map((ev, i) => (
            <EventCard key={i} event={ev} />
          ))}
        </div>
      )}
    </div>
  )
}
