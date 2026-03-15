import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Navbar from './components/Navbar'
import Landing from './pages/Landing'
import Events from './pages/Events'
import BuyTicket from './pages/BuyTicket'
import MyTickets from './pages/MyTickets'
import Resale from './pages/Resale'
import './index.css'

function App() {
  return (
    <BrowserRouter>
      <Navbar />
      <main className="container">
        <Routes>
          <Route path="/"             element={<Landing />} />
          <Route path="/events"       element={<Events />} />
          <Route path="/buy/:eventId" element={<BuyTicket />} />
          <Route path="/my-tickets"   element={<MyTickets />} />
          <Route path="/resale"       element={<Resale />} />
        </Routes>
      </main>
    </BrowserRouter>
  )
}

export default App
