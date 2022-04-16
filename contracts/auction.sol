// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "../utils/functions.sol";

contract Auction is Functions {
    // Variable
    address payable private beneficiary;

    uint256 public auctionEndTime;
    bool private ended;

    uint256 public highestBid;
    address public highestBidder;

    address[] bidder;

    struct Bid {
        address addressBidder;
        uint256 totalBid;
        uint256 lastTimeBid;
    }

    mapping(address => Bid) pendingReturns; 

    modifier onlyOwner() {
        require(msg.sender == beneficiary);
        _;
    }

    constructor(uint256 _biddingTime, address payable _beneficiary) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    // Event
    event highestBidIncrease(address bidder, uint amount);
    event BeneficiaryPaid(address addr, uint256 amount);
    event auctionEnded(address winner, uint256 amount);

    // Function
    function bid() public payable {
        if (block.timestamp > auctionEndTime) {
            revert("Auction has ended");
        } else if (msg.value <= 0) {
            revert(
                "Invalid bid value. Your bid has zero value and you can't bid with zero value"
            );
        } else if (msg.value == highestBid) {
            revert(
                string(abi.encodePacked("Please bid with value larger than highest bid. Highest bid at current is : ", toString(highestBid/1000000000000000000), " eth"))
            );
        }
        bool bidderExist = false;
        for (uint256 z = 0; z < bidder.length; z++) {
            if (bidder[z] == address(msg.sender)) {
                bidderExist = true;
            }
        }
        if (bidderExist == false) {
            bidder.push(msg.sender);
        }
        if (highestBid != 0) {
            if (highestBidder == msg.sender) {
                pendingReturns[highestBidder].totalBid += msg.value;
                highestBid = pendingReturns[highestBidder].totalBid;
                pendingReturns[highestBidder].lastTimeBid = block.timestamp;
            } else {
                if (
                    pendingReturns[highestBidder].totalBid <
                    pendingReturns[msg.sender].totalBid + msg.value
                ) {
                    highestBidder = msg.sender;
                    pendingReturns[highestBidder].totalBid += msg.value;
                    highestBid = pendingReturns[highestBidder].totalBid;
                    pendingReturns[highestBidder].lastTimeBid = block.timestamp;
                } else if (
                    pendingReturns[highestBidder].totalBid >
                    pendingReturns[msg.sender].totalBid + msg.value
                ) {
                    pendingReturns[msg.sender].totalBid += msg.value;
                    pendingReturns[msg.sender].lastTimeBid = block.timestamp;
                }
            }
        } else if (highestBid == 0) {
            highestBidder = msg.sender;
            pendingReturns[highestBidder].totalBid = msg.value;
            highestBid = pendingReturns[highestBidder].totalBid;
            pendingReturns[highestBidder].lastTimeBid = block.timestamp;
        }

        emit highestBidIncrease(highestBidder, highestBid);
    }

    function widthdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender].totalBid;
        if (amount > 0) {
            pendingReturns[msg.sender].totalBid = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender].totalBid = amount;
                return false;
            }
            if (highestBidder == msg.sender) {
                highestBid = 0;
                highestBidder = address(0);
            }
            for (uint256 z = 0; z < bidder.length; z++) {
                if (pendingReturns[bidder[z]].totalBid > highestBid) {
                    highestBid = pendingReturns[bidder[z]].totalBid;
                    highestBidder = bidder[z];
                }
            }
        }
        return true;
    }

    function getBidTotal() public view returns (uint256) {
        return pendingReturns[msg.sender].totalBid;
    }

    function getBidLastTime() public view returns (uint256) {
        return pendingReturns[msg.sender].lastTimeBid;
    }

    function auctionEnd() public onlyOwner {
        if (ended) {
            revert("Aution maybe has ended");
        }
        if (block.timestamp < auctionEndTime) {
            revert("Aution hasn't ended");
        }
        ended = true;
        emit auctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
        emit BeneficiaryPaid(highestBidder, highestBid);
    }
}
