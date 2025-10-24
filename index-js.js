
  import { createWalletClient, createPublicClient, custom, http, parseEther, formatEther, getContract } from "https://esm.sh/viem";
import { sepolia } from "https://esm.sh/viem/chains";


let walletClient;
let publicClient;
let account;
let contract;

// ⚠️ Replace this with your deployed contract address
const CONTRACT_ADDRESS = "0x68Fa5c6f3f86e4AE6a3631ea7b76D7133ce236Fe" // e.g. "0x1234567890abcdef1234567890abcdef12345678"
const CONTRACT_ABI = [
    {
        name: "buyCoffee",
        type: "function",
        stateMutability: "payable",
        inputs: [],
        outputs: []
    },
    {
        name: "withdraw",
        type: "function",
        stateMutability: "nonpayable",
        inputs: [],
        outputs: []
    },
    {
        name: "getBalance",
        type: "function",
        stateMutability: "view",
        inputs: [],
        outputs: [{ name: "", type: "uint256" }]
    }
];

function showError(message) {
    const errorEl = document.getElementById('error');
    errorEl.textContent = message;
    errorEl.classList.add('show');
    setTimeout(() => errorEl.classList.remove('show'), 5000);
}

function updateStatus(message, isConnected = false) {
    const statusEl = document.getElementById('status');
    statusEl.textContent = message;
    if (isConnected) {
        statusEl.classList.add('connected');
    } else {
        statusEl.classList.remove('connected');
    }
}

async function connect() {
    try {
        if (!window.ethereum) {
            showError('MetaMask not detected. Please install MetaMask and refresh.');
            window.open('https://metamask.io/download/', '_blank');
            return;
        }

        // Create wallet client (for writes)
        walletClient = createWalletClient({
            chain: sepolia,
            transport: custom(window.ethereum)
        });

        // Create public client (for reads)
        publicClient = createPublicClient({
            chain: sepolia,
            transport: http()
        });

        // Request accounts
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        if (!accounts.length) {
            showError('No accounts found. Please unlock MetaMask.');
            return;
        }

        account = accounts[0];

        // Set up contract interface
        if (CONTRACT_ADDRESS && CONTRACT_ADDRESS.startsWith('0x')) {
            contract = getContract({
                address: CONTRACT_ADDRESS,
                abi: CONTRACT_ABI,
                client: walletClient
            });
            document.getElementById('buyBtn').disabled = false;
            document.getElementById('balanceBtn').disabled = false;
            document.getElementById('withdrawBtn').disabled = false;
        } else {
            showError('Contract address not set. Please update CONTRACT_ADDRESS.');
        }

        const shortAddress = `${account.slice(0, 6)}...${account.slice(-4)}`;
        updateStatus(`Connected: ${shortAddress}`, true);
        document.getElementById('connectBtn').textContent = 'Connected ✓';

    } catch (err) {
        console.error(err);
        if (err.code === 4001) {
            showError('Connection rejected in MetaMask.');
        } else {
            showError('Connection failed: ' + err.message);
        }
    }
}

async function buyCoffee() {
    try {
        const amount = document.getElementById('coffeeAmount').value;
        if (!amount || parseFloat(amount) <= 0) {
            showError('Please enter a valid amount');
            return;
        }

        updateStatus('Buying coffee... please confirm transaction.');

        const txHash = await walletClient.writeContract({
            address: CONTRACT_ADDRESS,
            abi: CONTRACT_ABI,
            functionName: "buyCoffee",
            account,
            value: parseEther(amount)
        });

        updateStatus('Transaction pending...', true);

        // Wait for confirmation
        await publicClient.waitForTransactionReceipt({ hash: txHash });

        updateStatus('Coffee bought successfully! ☕', true);

        setTimeout(() => {
            const shortAddress = `${account.slice(0, 6)}...${account.slice(-4)}`;
            updateStatus(`Connected: ${shortAddress}`, true);
        }, 3000);

    } catch (err) {
        console.error(err);
        showError('Transaction failed: ' + err.message);
    }
}

async function getBalance() {
    try {
        updateStatus('Fetching balance...', true);

        const balance = await publicClient.readContract({
            address: CONTRACT_ADDRESS,
            abi: CONTRACT_ABI,
            functionName: "getBalance"
        });

        const balanceDisplay = document.getElementById('balanceDisplay');
        balanceDisplay.textContent = `Contract Balance: ${formatEther(balance)} ETH`;
        balanceDisplay.classList.add('show');

        const shortAddress = `${account.slice(0, 6)}...${account.slice(-4)}`;
        updateStatus(`Connected: ${shortAddress}`, true);

    } catch (err) {
        console.error(err);
        showError('Failed to get balance: ' + err.message);
    }
}

async function withdraw() {
    try {
        updateStatus('Withdrawing... Please confirm in MetaMask', true);

        const txHash = await walletClient.writeContract({
            address: CONTRACT_ADDRESS,
            abi: CONTRACT_ABI,
            functionName: "withdraw",
            account
        });

        updateStatus('Withdrawal pending...', true);
        await publicClient.waitForTransactionReceipt({ hash: txHash });

        updateStatus('Withdrawal successful! 💰', true);
        document.getElementById('balanceDisplay').classList.remove('show');

        setTimeout(() => {
            const shortAddress = `${account.slice(0, 6)}...${account.slice(-4)}`;
            updateStatus(`Connected: ${shortAddress}`, true);
        }, 3000);

    } catch (err) {
        console.error(err);
        showError('Withdrawal failed: ' + err.message);
    }
}

// Auto setup
window.addEventListener('load', async () => {
    setTimeout(() => {
        document.getElementById('connectBtn').addEventListener('click', connect);
        document.getElementById('buyBtn').addEventListener('click', buyCoffee);
        document.getElementById('balanceBtn').addEventListener('click', getBalance);
        document.getElementById('withdrawBtn').addEventListener('click', withdraw);

        if (window.ethereum) {
            updateStatus('MetaMask detected! Click "Connect Wallet" to continue.');
        } else {
            updateStatus('MetaMask not detected. Please install MetaMask.');
        }
    }, 200);
});