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

    function testRedeemWinningsMany(uint32 betOne, uint32 betTwo, uint32 betThree) public {
        vm.assume(uint256(betOne) > 0 && uint256(betThree) > 0);
        vm.warp(mergeMarket.bettingEnd() - 1);

        mergeMarket.makeBet{value: betOne}(true);
        assertEq(mergeYes.balanceOf(address(this)), betOne);

        hoax(address(0xBEEF));
        mergeMarket.makeBet{value: betTwo}(false);

        hoax(address(0xC0FFEE));
        mergeMarket.makeBet{value: betThree}(true);

        vm.warp(mergeMarket.withdrawStart());
        mergeMarket.finalize();

        uint256 mergeYesTotalSupplyBeforeOne = mergeYes.totalSupply();

        // Check betOne result
        uint256 balanceOneBefore = address(this).balance;
        mergeMarket.redeemWinnings();
        uint256 balanceOneAfter = address(this).balance;

        assertEq(
            balanceOneAfter - balanceOneBefore, 
            (mergeYesTotalSupplyBeforeOne + mergeNo.totalSupply()) * uint256(betOne) / mergeYesTotalSupplyBeforeOne
        );
        assertEq(mergeYes.balanceOf(address(this)), 0);

        // Check betTwo result
        vm.expectRevert(NoWinnings.selector);
        vm.prank(address(0xBEEF));
        mergeMarket.redeemWinnings();

        uint256 mergeYesTotalSupplyBeforeThree = mergeYes.totalSupply();

        // Check betThree result
        uint256 balanceThreeBefore = address(0xC0FFEE).balance;
        vm.prank(address(0xC0FFEE));
        mergeMarket.redeemWinnings();
        uint256 balanceThreeAfter = address(0xC0FFEE).balance;

        assertEq(
            balanceThreeAfter - balanceThreeBefore, 
            (mergeYesTotalSupplyBeforeThree + mergeNo.totalSupply()) * uint256(betThree) / mergeYesTotalSupplyBeforeThree
        );
        assertEq(mergeYes.balanceOf(address(0xC0FFEE)), 0);
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
