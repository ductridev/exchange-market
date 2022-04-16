const Web3 = require('web3');
const fs = require('fs');
const dotenv = require('dotenv');

const web3 = new Web3(Web3.givenProvider || "ws://127.0.0.1:8545");

dotenv.config({ path: require('path').resolve('./') + '/backend/.env' });

async function deploy() {
    let contractABI = JSON.parse(fs.readFileSync(require('path').resolve('./') + '/build/contracts/Auction.json'));
    const contract = new web3.eth.Contract(contractABI.abi);

    let gasEstimate = await contract.deploy({ data: contractABI.bytecode, arguments: [180, process.env.DEPLOY_ADDRESS.toString()] }).estimateGas(function (err, gasEstimate) {
        console.log('gasEstimate = ' + gasEstimate);
    });

    var _transactionHash;
    var _newContractInstance;

    await contract.deploy({ data: contractABI.bytecode, arguments: [180000, process.env.DEPLOY_ADDRESS.toString()] }).send({
        from: process.env.DEPLOY_ADDRESS.toString(),
        gas: gasEstimate + 50000
    }, (err, transactionHash) => {
        _transactionHash = transactionHash;
        console.log('Transaction Hash :', transactionHash);
    }).on('confirmation', () => { }).then((newContractInstance) => {
        _newContractInstance = newContractInstance;
        console.log('Deployed Contract Address : ', newContractInstance.options.address);
    });

    fs.readFile(require('path').resolve('./') + '/backend/contracts.json', 'utf8', function (err, data) {
        var obj = JSON.parse(data);
        obj.contracts.push({
            transactionHash: _transactionHash,
            deployedContractAddress: _newContractInstance.options.address,
            gas: gasEstimate + 50000
        });
        fs.writeFile(require('path').resolve('./') + '/backend/contracts.json', JSON.stringify(obj), 'utf8', function () {
            console.log('Wrote to contracts.json');
        });
    })
}
deploy();