import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ethers } from 'ethers'
import { useWallet } from '../hooks/useWallet'
import { ADDRESSES, EVENT_MANAGER_ABI } from '../contracts/addresses'

const RPC = 'https://rpc.sepolia.org'

const STATUS_LABELS = ['Pending', 'Active', 'Completed', 'Cancelled']
const STATUS_CLS    = ['badge-pending', 'badge-active', 'badge-complete', 'badge-cancelled']

export default function Landing() {
  const { isConnected, login } = useWallet()
  const navigate               = useNavigate()
  const [events, setEvents]    = useState([])
  const [loading, setLoading]  = useState(true)

  // Redirect to events page if already logged in
  useEffect(() => {
    if (isConnected) navigate('/events')
  }, [isConnected])

  useEffect(() => { fetchEvents() }, [])

  async function fetchEvents() {
    try {
      if (!ADDRESSES.EventManager) return
      const provider = new ethers.JsonRpcProvider(RPC)
      const contract = new ethers.Contract(ADDRESSES.EventManager, EVENT_MANAGER_ABI, provider)
      const total    = await contract.totalEvents()
      const fetched  = []
      for (let i = 1; i <= Number(total); i++) {
        const ev = await contract.getEvent(BigInt(i))
        fetched.push(ev)
      }
      setEvents(fetched)
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }

  async function handleSignIn() {
    await login()
  }

  return (
    <div className="landing">

      {/* ── Hero ── */}
      <section className="hero-section">
        <div className="hero-badge">⛓ Powered by Ethereum</div>
        <h1 className="hero-title">
          The Future of<br />
          <span className="hero-accent">Live Events</span>
        </h1>
        <p className="hero-sub">
          Buy, own, and resell tickets as NFTs. No scalpers. No fakes.<br />
          Your ticket lives on-chain — forever yours.
        </p>
        <div className="hero-actions">
          <button className="btn btn-primary btn-lg" onClick={handleSignIn}>
            🎟 Get Started
          </button>
          <a href="#events" className="btn btn-outline btn-lg">
            See Events
          </a>
        </div>

        {/* Stats */}
        <div className="hero-stats">
          <div className="stat">
            <span className="stat-num">100%</span>
            <span className="stat-label">On-chain</span>
          </div>
          <div className="stat-divider" />
          <div className="stat">
            <span className="stat-num">0%</span>
            <span className="stat-label">Fake tickets</span>
          </div>
          <div className="stat-divider" />
          <div className="stat">
            <span className="stat-num">10%</span>
            <span className="stat-label">Max resale cap</span>
          </div>
        </div>
      </section>

      {/* ── How it works ── */}
      <section className="how-section">
        <h2 className="section-title">How It Works</h2>
        <div className="steps-grid">
          <div className="step-card">
            <div className="step-icon">🔐</div>
            <h3>Sign In</h3>
            <p>Use Google or email. A wallet is created for you automatically — no crypto knowledge needed.</p>
          </div>
          <div className="step-card">
            <div className="step-icon">🎟</div>
            <h3>Buy a Ticket</h3>
            <p>Purchase your ticket with ETH. It's minted as an NFT directly to your wallet on-chain.</p>
          </div>
          <div className="step-card">
            <div className="step-icon">📱</div>
            <h3>Show QR at Gate</h3>
            <p>Your ticket generates a unique QR code. Scan it at the venue — instant, tamper-proof verification.</p>
          </div>
          <div className="step-card">
            <div className="step-icon">💸</div>
            <h3>Resell Fairly</h3>
            <p>Can't make it? Resell your ticket at up to 10% above face value. No scalping, enforced on-chain.</p>
          </div>
        </div>
      </section>

      {/* ── Events teaser ── */}
      <section className="events-section" id="events">
        <h2 className="section-title">Upcoming Events</h2>
        <p className="section-sub">Sign in to view full details and purchase tickets.</p>

        {loading && (
          <div style={{ textAlign: 'center', padding: '3rem' }}>
            <span className="spinner" style={{ width: 36, height: 36, borderWidth: 3 }} />
          </div>
        )}

        {!loading && events.length === 0 && (
          <div className="empty-state">
            <p>No events listed yet — check back soon.</p>
          </div>
        )}

        {!loading && events.length > 0 && (
          <div className="card-grid">
            {events.map((ev, i) => {
              const status  = Number(ev.status)
              const dateStr = new Date(Number(ev.date) * 1000).toLocaleDateString('en-IN', {
                day: 'numeric', month: 'short', year: 'numeric'
              })
              return (
                <div className="teaser-card" key={i}>
                  <div className="teaser-top">
                    <span className={`badge ${STATUS_CLS[status]}`}>
                      {STATUS_LABELS[status]}
                    </span>
                  </div>
                  <h3 className="teaser-name">{ev.name}</h3>
                  <p className="teaser-venue">📍 {ev.venue}</p>
                  <p className="teaser-date">🗓 {dateStr}</p>
                  <div className="teaser-footer">
                    <span className="teaser-seats">
                      🎟 {Number(ev.totalSeats) - Number(ev.seatsSold)} seats left
                    </span>
                    <button
                      className="btn btn-primary"
                      onClick={handleSignIn}
                      disabled={status !== 1}
                    >
                      {status === 1 ? 'Sign in to Buy' : 'Unavailable'}
                    </button>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </section>

      {/* ── CTA ── */}
      <section className="cta-section">
        <h2>Ready to experience ticketing the right way?</h2>
        <p>Join BlockMyShow — where your ticket is truly yours.</p>
        <button className="btn btn-primary btn-lg" onClick={handleSignIn}>
          🎟 Sign In with Google
        </button>
      </section>

      {/* ── Footer ── */}
      <footer className="footer">
        <p>Built on Ethereum Sepolia · ERC-721 NFT Tickets · <span style={{ color: 'var(--accent-lt)' }}>BlockMyShow</span></p>
      </footer>

    </div>
  )
}
