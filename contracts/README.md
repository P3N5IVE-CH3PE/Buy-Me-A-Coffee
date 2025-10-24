# ☕ Coffee DApp - Full Stack Web3 Application

A decentralized application that allows users to buy coffee with cryptocurrency and enables the owner to withdraw funds.

## 🚀 Features

- Connect with MetaMask wallet
- Buy coffee with ETH on Sepolia testnet
- View contract balance
- Owner can withdraw funds
- Fully tested smart contracts

## 📁 Project Structure
```
coffee-dapp-fullstack/
├── frontend/           # Frontend application
│   ├── index.html
│   ├── style.css
│   └── app.js
├── contracts/          # Smart contracts (Foundry)
│   ├── src/
│   ├── test/
│   ├── script/
│   └── foundry.toml
└── README.md
```

## 🛠️ Tech Stack

**Frontend:**
- HTML/CSS/JavaScript
- Viem (Ethereum library)
- MetaMask integration

**Smart Contracts:**
- Solidity ^0.8.30
- Foundry (development framework)
- Sepolia testnet

## 📦 Installation

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [MetaMask](https://metamask.io/)
- Sepolia ETH ([Get from faucet](https://sepoliafaucet.com/))

### Setup

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/coffee-dapp.git
cd coffee-dapp
```

2. Install Foundry dependencies:
```bash
cd contracts
forge install
```

3. Create `.env` file in contracts folder:
```bash
SEPOLIA_RPC_URL=https://rpc.sepolia.org
PRIVATE_KEY=your_private_key_here
```

## 🚀 Deployment

### Deploy Smart Contract
```bash
cd contracts
source .env
forge create --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  src/BuyCoffee.sol:BuyCoffee
```

### Run Tests
```bash
cd contracts
forge test
forge test -vv  # verbose output
forge coverage  # coverage report
```

### Update Frontend

After deployment, update `CONTRACT_ADDRESS` in `frontend/app.js` with your deployed contract address.

## 🌐 Running Frontend

Simply open `frontend/index.html` in your browser, or use a local server:
```bash
cd frontend
python -m http.server 8000
# Visit http://localhost:8000
```

## 📝 Smart Contract

**Contract Address (Sepolia):** `YOUR_CONTRACT_ADDRESS`

**Functions:**
- `buyCoffee()` - Send ETH to buy coffee
- `getBalance()` - View contract balance
- `withdraw()` - Owner withdraws funds

## 🧪 Testing

The project includes comprehensive tests:
- Unit tests for all functions
- Fuzz testing
- Integration tests
- Edge case handling

Run tests:
```bash
forge test --gas-report
```

## 📄 License

MIT

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## ⚠️ Security

**For educational purposes only.** Do not use in production without proper auditing.

---

Built with ❤️ using Foundry and Viem
