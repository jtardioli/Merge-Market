// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error FailedTransfer();
error YouLost();
error CannotBet();

contract MergePredictionMarket is ERC20, Ownable {
    mapping(address => bool) _mergedVote;
    uint256 totalMerge;
    uint256 totalNotMerge;

    constructor(uint256 initialSupply) ERC20("MergeMarket", "MM") {}

    uint stopBetting = 123;
    uint canWithdraw = 456;
    uint canWithdrawOwner = 567;

    // Make a bet
    function makeBet(bool _merged) external payable {
        if (block.timestamp > stopBetting) revert CannotBet();
        uint256 amount = msg.value * 99 / 100;
        _mint(msg.sender, amount);
        _mergedVote[msg.sender] = _merged;
    }

    // Change your position
    function changePosition(bool _merged) external {
        if (block.timestamp > stopBetting) revert CannotBet();
        uint256 amount = balanceOf(msg.sender);
        _mergedVote[msg.sender] = _merged;
        if (_merged) {
            totalMerge += amount;
            totalNotMerge -= amount;
        } else {
            totalMerge -= amount;
            totalNotMerge += amount;
        }
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (block.timestamp > stopBetting) revert CannotBet();
        address owner = _msgSender();
        _transfer(owner, to, amount);
        bool senderVote = _mergedVote[owner];
        bool recieverVote = _mergedVote[to];
        // make a table for this lol
        if (senderVote != recieverVote) {
            if (senderVote) {
                totalMerge -= amount;
                totalNotMerge += amount;
            } else {
                totalMerge += amount;
                totalNotMerge -= amount;
            }
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (block.timestamp > stopBetting) revert CannotBet();
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        bool senderVote = _mergedVote[from];
        bool recieverVote = _mergedVote[to];
        // make a table for this lol
        if (senderVote != recieverVote) {
            if (senderVote) {
                totalMerge -= amount;
                totalNotMerge += amount;
            } else {
                totalMerge += amount;
                totalNotMerge -= amount;
            }
        }
        return true;
    }

    function withdrawBet() external {
        if (block.timestamp < canWithdraw) revert FailedTransfer();
        bool vote = _mergedVote[msg.sender];
        bool mergedHappened = block.difficulty > type(uint64).max;

        if (vote != mergedHappened) revert YouLost();
        uint256 amountWon;

        if (mergedHappened) {
            amountWon = totalSupply() * balanceOf(msg.sender) / totalMerge;
        } else {
            amountWon = totalSupply() * balanceOf(msg.sender) / totalNotMerge;
        }

        transferFrom(msg.sender, address(0), balanceOf(msg.sender));

        (bool success,) =
            payable(msg.sender).call{value: amountWon}("");
        if (!success) revert FailedTransfer();
    }

    function withdraw() external onlyOwner {
        if (block.timestamp < canWithdrawOwner) revert FailedTransfer();
        (bool success,) =
            payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert FailedTransfer();
    }
}
