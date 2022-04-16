const Web3 = require('web3');
const fs = require('fs');
const dotenv = require('dotenv');

const web3 = new Web3(Web3.givenProvider || "ws://127.0.0.1:8545");

dotenv.config({ path: require('path').resolve('./') + '/backend/.env' });

async function main() {

    let contractABI = JSON.parse(fs.readFileSync(require('path').resolve('./') + '/build/contracts/Auction.json'));

    let obj = JSON.parse(fs.readFileSync(require('path').resolve('./') + '/backend/contracts.json', 'utf8', function (err, data) { }));

    const contractInstance = new web3.eth.Contract(contractABI.abi, obj.contracts[0].deployedContractAddress.toString());

    let lastBidTime = await contractInstance.methods.highestBid().call();
    console.log(lastBidTime);

    await contractInstance.methods.bid().send({ from: '0x19aD65D2A8308be8Df36c4F0054fd5c0754dD7ec', value: '15', gas: obj.contracts[0].gas }, function (error, transactionHash) {
        if (error) {
            console.log(error);
        }
        else {
            console.log(transactionHash);
        }
    });
}

main();