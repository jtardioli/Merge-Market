// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./MergeYes.sol";
import "./MergeNo.sol";

error FailedTransfer();
error YouLost();
error CannotBet();

contract MergeMarket is Ownable {
    // same struct
    uint256 stopBetting = 123;
    uint256 canWithdraw = 456;
    uint256 canWithdrawOwner = 567;

    MergeYes mergeYes;
    MergeNo mergeNo;

    constructor() {
        mergeYes = new MergeYes();
        mergeNo = new MergeNo();
    }

    // Make a bet
    function makeBet(bool _merged) external payable {
        if (block.timestamp > stopBetting) revert CannotBet();
        uint256 amount = msg.value * 99 / 100;
        if (_merged) {
            mergeYes.mint(msg.sender, amount);
            return;
        }
        mergeNo.mint(msg.sender, amount);
    }

    function withdrawBet() external {
        if (block.timestamp < canWithdraw) revert FailedTransfer();
        bool mergedHappened = block.difficulty > type(uint64).max;

        uint256 amountWon;

        if (mergedHappened) {
            amountWon = (mergeYes.totalSupply() + mergeNo.totalSupply())
                * mergeYes.balanceOf(msg.sender)
                / mergeYes.totalSupply();
            mergeYes.burn(msg.sender, mergeYes.balanceOf(msg.sender));
        } else {
            amountWon = (mergeYes.totalSupply() + mergeNo.totalSupply())
                * mergeNo.balanceOf(msg.sender)
                / mergeNo.totalSupply();
            mergeNo.burn(msg.sender, mergeYes.balanceOf(msg.sender));
        }

        (bool success,) = payable(msg.sender).call{value: amountWon}("");
        if (!success) revert FailedTransfer();
    }

    function withdraw() external onlyOwner {
        if (block.timestamp < canWithdrawOwner) revert FailedTransfer();
        (bool success,) =
            payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert FailedTransfer();
    }
}
