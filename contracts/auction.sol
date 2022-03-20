//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./zombieownership.sol";

contract Auction is ZombieOwnership {

    address winner;

    struct Seller {
        address retailer;
        uint minimumAskPrice;
        uint timeExpire;
    }

    struct Bidder {
        address buyer;
        uint bidPrice;
    }

    Bidder[] public Bidders;

    mapping(uint => Seller) public askLedger;

    function setPrice(uint _tokenId, uint _amount) public onlyOwnerOf(_tokenId) {
        require(askLedger[_tokenId].minimumAskPrice == 0, "You cannot change the minimum price during an auction");
        askLedger[_tokenId].retailer = zombieToOwner[_tokenId];
        askLedger[_tokenId].minimumAskPrice = _amount;
    }

    function setExpiration(uint _tokenId, uint _time) public onlyOwnerOf(_tokenId) {
        require(askLedger[_tokenId].timeExpire == 0, "You cannot change the expiration time during an auction");
        askLedger[_tokenId].timeExpire = uint(block.timestamp + _time * 1 days);
    }    

    function pickAuctionWinner(uint _tokenId) public onlyOwnerOf(_tokenId) returns(address) {
        require(askLedger[_tokenId].minimumAskPrice != 0, "Item does not have a price yet");
        require(askLedger[_tokenId].timeExpire != 0, "Expiration time not yet set");
        require(block.timestamp >= askLedger[_tokenId].timeExpire, "You cannot pick a winner yet");

        if(block.timestamp >= askLedger[_tokenId].timeExpire && Bidders[_tokenId].bidPrice >= askLedger[_tokenId].minimumAskPrice) {
            uint highestBid;

            for(uint i = 0; i < Bidders.length; i++) {
                if(Bidders[i].bidPrice > highestBid) {
                    highestBid = Bidders[i].bidPrice;
                }
            }
            return winner = Bidders[highestBid].buyer;
        } else {
            return winner;
        }
    }

    function bid(uint _tokenId) public payable {
        require(askLedger[_tokenId].minimumAskPrice != 0, "Item does not have a price yet");
        require(askLedger[_tokenId].timeExpire != 0, "Time expiration not yet set");
        require(block.timestamp < askLedger[_tokenId].timeExpire, "Auction bidding time has expired");

        Bidders[_tokenId].buyer = msg.sender;
        Bidders[_tokenId].bidPrice = msg.value;
    }

    function claim(uint _tokenId) public {
        require(block.timestamp > askLedger[_tokenId].timeExpire, "Auction is not finished yet");
        require(msg.sender == winner, "You are not the winner");

        _transfer(askLedger[_tokenId].retailer, winner, _tokenId);
    }
}