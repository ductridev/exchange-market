const Auction = artifacts.require('Auction');
const Web3 = require('web3');

const web3 = new Web3(Web3.givenProvider || "ws://127.0.0.1:8545");

module.exports = async function (deployer) {
    await deployer.deploy(Auction, 180, "0x29682d8250e596669a4Ea162B49e155a99DAEe20");
    var _Auction = await Auction.deployed();
}