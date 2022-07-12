let  sigUtil = require('eth-sig-util');
const ethUtil = require('ethereumjs-util');
const Web3 = require('web3');

const abi = [{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"seller","type":"address"},{"indexed":false,"internalType":"address","name":"buyer","type":"address"},{"indexed":false,"internalType":"address","name":"tokenAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Buy","type":"event"},{"anonymous":false,"inputs":[{"components":[{"internalType":"address","name":"seller","type":"address"},{"internalType":"bytes4","name":"saleType","type":"bytes4"},{"internalType":"address","name":"tokenAddress","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"startTime","type":"uint256"},{"internalType":"uint256","name":"endTime","type":"uint256"},{"internalType":"uint256","name":"nonce","type":"uint256"}],"indexed":false,"internalType":"struct Exchange.Order","name":"order","type":"tuple"},{"indexed":false,"internalType":"bytes32","name":"hash","type":"bytes32"},{"indexed":false,"internalType":"address","name":"signer","type":"address"}],"name":"OrderCreated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Unpaused","type":"event"},{"inputs":[],"name":"AUCTION_SALE_CLASS","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"CANCELLED_ORDER_CLASS","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"COMPLETED_ORDER_CLASS","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"FIXED_SALE_CLASS","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"NEW_ORDER_CLASS","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"OrderStatus","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"WEKTA","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"seller","type":"address"},{"internalType":"bytes4","name":"saleType","type":"bytes4"},{"internalType":"address","name":"tokenAddress","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"startTime","type":"uint256"},{"internalType":"uint256","name":"endTime","type":"uint256"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"address","name":"buyer","type":"address"},{"internalType":"uint256","name":"bidAmount","type":"uint256"}],"internalType":"struct Exchange.BidOrder","name":"bidOrder","type":"tuple"},{"internalType":"bytes","name":"signature","type":"bytes"}],"name":"completeBidding","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"seller","type":"address"},{"internalType":"bytes4","name":"saleType","type":"bytes4"},{"internalType":"address","name":"tokenAddress","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"startTime","type":"uint256"},{"internalType":"uint256","name":"endTime","type":"uint256"},{"internalType":"uint256","name":"nonce","type":"uint256"}],"internalType":"struct Exchange.Order","name":"order","type":"tuple"}],"name":"completeFixedSale","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"seller","type":"address"},{"internalType":"bytes4","name":"saleType","type":"bytes4"},{"internalType":"address","name":"tokenAddress","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"startTime","type":"uint256"},{"internalType":"uint256","name":"endTime","type":"uint256"},{"internalType":"uint256","name":"nonce","type":"uint256"}],"internalType":"struct Exchange.Order","name":"order","type":"tuple"},{"internalType":"bytes","name":"signature","type":"bytes"}],"name":"createOrder","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]
const contractAddress = "0x29B2aa68224108AbcEA26d73774B8acdEd06172A";

function Order(seller, saleType, tokenAddress, tokenId, amount, startTime, endTime, nonce) {
    return { seller, saleType, tokenAddress, tokenId, amount, startTime, endTime, nonce };
}

function BidOrder(order, buyer, bidAmount){
    const { seller, saleType, tokenAddress, tokenId, amount, startTime, endTime, nonce } = order;
    return { seller, saleType, tokenAddress, tokenId, amount, startTime, endTime, nonce , buyer, bidAmount };
}

async function recover() {
    let order = Order("0x217373AB5e0082B2Ce622169672ECa6F4462319C", "0xc5d24601", "0xAC62f9b62d128d8551a1CedFF69D7517B8ab1134", 8, (1*10**14).toString(), 0, 0, 0);
    let param = JSON.stringify({
        types: {
            EIP712Domain: [
                { name: 'name', type: 'string' },
                { name: 'version', type: 'string' },
                { name: 'chainId', type: 'uint256' },
                { name: 'verifyingContract', type: 'address' }
            ],
            Order: [
                { name: 'seller', type: 'address' },
                { name: 'saleType', type: 'bytes4' },
                { name: 'tokenAddress', type: 'address' },
                { name: 'tokenId', type: 'uint256' },
                { name: 'amount', type: 'uint256' },
                { name: 'startTime', type: 'uint256' },
                { name: 'endTime', type: 'uint256' },
                { name: 'nonce', type: 'uint256' }
            ]
        },
        primaryType: 'Order',
        domain: {
            name: 'Order',
            version: '1',
            chainId: 97,
            verifyingContract: contractAddress
        },
        message: order
    })
    
    signature = "0xd5564a19de02b36ec8322c90a026ed927004250d1c846b7a1c8379157f2e275b1dd472e79426560b1cf50f71ce329bd2f62830989de9bf38b63d50a5e19f25461b"

    const recovered = sigUtil.recoverTypedSignature_v4({ data: JSON.parse(param), sig: signature })

    console.log('recover', recovered)
}

async function recoverBidOrder() {
    let orderMade = Order("0x217373AB5e0082B2Ce622169672ECa6F4462319C", "0xc5d24601", "0xAC62f9b62d128d8551a1CedFF69D7517B8ab1134", 8, (1*10**14).toString(), 0, 0, 0);
    let bidOrder = BidOrder(orderMade, "0xFF0dF0BDA102aecDaD1b2A9BC96BBf7e59b216da", (1*10**15).toString());
    let param = JSON.stringify({
        types: {
            EIP712Domain: [
                { name: 'name', type: 'string' },
                { name: 'version', type: 'string' },
                { name: 'chainId', type: 'uint256' },
                { name: 'verifyingContract', type: 'address' }
            ],
            BidOrder: [
                { name: 'seller', type: 'address' },
                { name: 'saleType', type: 'bytes4' },
                { name: 'tokenAddress', type: 'address' },
                { name: 'tokenId', type: 'uint256' },
                { name: 'amount', type: 'uint256' },
                { name: 'startTime', type: 'uint256' },
                { name: 'endTime', type: 'uint256' },
                { name: 'nonce', type: 'uint256' },
                { name: 'buyer', type: 'address' },
                { name: 'bidAmount', type: 'uint256' }
            ]
        },
        primaryType: 'BidOrder',
        domain: {
            name: 'Order',
            version: '1',
            chainId: 97,
            verifyingContract: contractAddress
        },
        message: bidOrder
    })
    
    signature = "0xeeb2807099fd487b426bb444b1334bea6658c648ee05e0a9975f289179dab5332ae62b1007adb5cb7f839e444fbe6de9437b996d4a84320a60090c4cb0738b321b"

    const recovered = sigUtil.recoverTypedSignature_v4({ data: JSON.parse(param), sig: signature })

    console.log('recover bid order', recovered)
}

async function getSaleTypes(){
    console.log(`0x${ethUtil.keccak256(Buffer.from("FIXED", 'hex')).toString("hex").substring(0, 8)}`)
}

const web3Bsc = new Web3(new Web3.providers.WebsocketProvider("wss://bsc.getblock.io/testnet/?api_key=d5610cdf-eba5-454f-8e44-57e16146f715", {
    clientConfig: {
        // Useful to keep a connection alive
        keepalive: true,
        keepaliveInterval: 60000 // ms
    },
    // Enable auto reconnection
    reconnect:{
        auto: true,
        delay: 5000, // ms
        maxAttempts: 6,
        onTimeout: false
    }
}));

const BscBridge = new web3Bsc.eth.Contract(
    abi, contractAddress
);

const initBscListener = async () => {  
    try {
        BscBridge.events.OrderCreated({fromBlock: 15589953}).on('data', async event => {
            console.log('Bsc deposit event received', event);
            console.log('return values', event.returnValues);
        });
    } catch(error) {
        console.log('error', error)
    }
}

recover()
recoverBidOrder()
getSaleTypes()
// initBscListener()