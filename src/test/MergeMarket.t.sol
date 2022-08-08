// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../MergeMarket.sol";

contract MergeMarketTest is Test {
    MergeMarket mergeMarket;
    ERC20 mergeYes;
    ERC20 mergeNo;

    function setUp() public {
        mergeMarket = new MergeMarket();
        mergeYes = mergeMarket.mergeYes();
        mergeNo = mergeMarket.mergeNo();
    }

    function testMakeBet(bool betValue, uint96 amount) public {
        vm.warp(mergeMarket.bettingEnd() - 1);

        if (betValue) {
            mergeMarket.makeBet{value: amount}(true);
            assertEq(mergeYes.balanceOf(address(this)), amount);
        } else {
            mergeMarket.makeBet{value: amount}(false);
            assertEq(mergeNo.balanceOf(address(this)), amount);
        }
    }

    function testCannotBetAfterBettingPeriod(bool betValue, uint96 amount) public {
        vm.warp(mergeMarket.bettingEnd() + 1);

        vm.expectRevert(BettingPeriodOver.selector);
        mergeMarket.makeBet{value: amount}(betValue);
    }

    function testFinalize() public {
        vm.warp(mergeMarket.withdrawStart());

        mergeMarket.finalize();
        assertEq(mergeMarket.isFinalized(), true);
        // Should always return true since block.difficulty is 0 locally
        assertEq(mergeMarket.mergeSuccess(), true);
    }

    function testCannotFinalizeBeforeMerge() public {
        vm.warp(mergeMarket.withdrawStart() - 1);

        vm.expectRevert(BeforeMerge.selector);
        mergeMarket.finalize();
    }

    function testCannotFinalizeIfAlreadyFinalized() public {
        vm.warp(mergeMarket.withdrawStart());

        mergeMarket.finalize();
        vm.expectRevert(AlreadyFinalized.selector);
        mergeMarket.finalize();
    }

    function testRedeemWinnings() public {
        vm.warp(mergeMarket.bettingEnd() - 1);

        mergeMarket.makeBet{value: 1 ether}(true);
        assertEq(mergeYes.balanceOf(address(this)), 1 ether);

        hoax(address(0xBEEF));
        mergeMarket.makeBet{value: 1 ether}(false);

        vm.warp(mergeMarket.withdrawStart());
        mergeMarket.finalize();

        uint256 balanceBefore = address(this).balance;
        mergeMarket.redeemWinnings();
        uint256 balanceAfter = address(this).balance;

        assertEq(balanceAfter - balanceBefore, 2 ether);
        assertEq(mergeYes.balanceOf(address(this)), 0);
    }
    
    function testCannotRedeemWinningsUnfinalized() public {
        vm.warp(mergeMarket.bettingEnd() - 1);

        mergeMarket.makeBet{value: 1 ether}(true);
        assertEq(mergeYes.balanceOf(address(this)), 1 ether);

        vm.warp(mergeMarket.withdrawStart());

        vm.expectRevert(NotFinalized.selector);
        mergeMarket.redeemWinnings();
    }

    function testCannotRedeemWinningsLosingToken() public {
        vm.warp(mergeMarket.bettingEnd() - 1);

        mergeMarket.makeBet{value: 1 ether}(false);
        assertEq(mergeNo.balanceOf(address(this)), 1 ether);

        hoax(address(0xBEEF));
        mergeMarket.makeBet{value: 1 ether}(true);

        vm.warp(mergeMarket.withdrawStart());
        mergeMarket.finalize();

        vm.expectRevert(NoWinnings.selector);
        mergeMarket.redeemWinnings();
    }

    receive() external payable {}
}
