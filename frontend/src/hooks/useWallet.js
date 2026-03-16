import { useAuth, useUser } from '@clerk/clerk-react'

export function useWallet() {
  const { isLoaded, isSignedIn, signOut } = useAuth()
  const { user } = useUser()

  const isConnected = isSignedIn ?? false
  const ready       = isLoaded

  const address     = user?.publicMetadata?.walletAddress ?? null
  const shortAddress = address
    ? `${address.slice(0, 6)}...${address.slice(-4)}`
    : null

  // Placeholder — wallet/signer will be wired in later phases
  async function getSigner()   { return null }
  async function getProvider() { return null }
  async function switchToSepolia() {}

  return {
    ready,
    isConnected,
    isOnSepolia: false, // will be updated in later phase
    user,
    address,
    shortAddress,
    logout: signOut,
    getSigner,
    getProvider,
    switchToSepolia,
  }
}