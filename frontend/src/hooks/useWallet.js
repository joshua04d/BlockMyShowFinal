import { usePrivy, useWallets } from '@privy-io/react-auth'

export function useWallet() {
  const { ready, authenticated, login, logout, user } = usePrivy()
  const { wallets } = useWallets()

  const wallet = wallets?.[0] ?? null
  const address = wallet?.address ?? null

  const shortAddress = address
    ? `${address.slice(0, 6)}...${address.slice(-4)}`
    : null

  const isConnected = authenticated && !!address
  const isOnSepolia = wallet?.chainId === 'eip155:11155111'

  async function getSigner() {
    if (!wallet) return null
    await wallet.switchChain(11155111)
    const provider = await wallet.getEthersProvider()
    return provider.getSigner()
  }

  async function getProvider() {
    if (!wallet) return null
    await wallet.switchChain(11155111)
    const provider = await wallet.getEthersProvider()
    return provider
  }

  async function switchToSepolia() {
    if (!wallet) return
    await wallet.switchChain(11155111)
  }

  return {
    ready,
    authenticated,
    user,
    wallet,
    address,
    shortAddress,
    isConnected,
    isOnSepolia,
    login,
    logout,
    getSigner,
    getProvider,
    switchToSepolia,
  }
}
