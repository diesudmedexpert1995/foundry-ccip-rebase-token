// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.24 < 0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    RebaseToken private rebaseToken;
    Vault private vault;

    address public user = makeAddr("user");
    address public owner = makeAddr("owner");

    uint256 public constant SEND_VALUE = 1 ether;

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        rebaseToken.grantMintAndBurnRole(address(vault));
        (bool success, ) = payable(address(vault)).call{value: SEND_VALUE}("");
        vm.stopPrank();
    }

    function addRewardsToVault(uint256 rewardsAmount) internal {
        (bool success, ) = payable(address(vault)).call{value: rewardsAmount}("");
    }

    function testDepositLinear(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        uint256 startBalance = rebaseToken.balanceOf(user);
        assertEq(startBalance, amount);
        vm.warp(block.timestamp + 1 hours);
        uint256 middleBalance = rebaseToken.balanceOf(user);
        assertGt(middleBalance, startBalance);
        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = rebaseToken.balanceOf(user);
        assertGt(endBalance, middleBalance);
        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance, 1);
        vm.stopPrank();
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
        assertEq(rebaseToken.balanceOf(user), amount);
        uint256 startEthBalance = address(user).balance;
        vm.prank(user);
        vault.redeem(type(uint256).max);
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, startEthBalance + amount);
    }

    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) public {
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);
        time = bound(time, 1000, type(uint96).max);

        vm.deal(user, depositAmount);
        vm.prank(user);
        vault.deposit{value:depositAmount}();
        vm.warp(block.timestamp + time);
        uint256 balanceSomeTimePassed = rebaseToken.balanceOf(user);

        uint256 rewardAmount = balanceSomeTimePassed - depositAmount;
        vm.deal(owner, rewardAmount);
        vm.prank(owner);

        addRewardsToVault(rewardAmount);
        uint256 ethBalanceBeforeRedeem = address(user).balance;
        vm.prank(user);
        vault.redeem(type(uint256).max);

        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, ethBalanceBeforeRedeem + balanceSomeTimePassed);
        assertGt(address(user).balance, ethBalanceBeforeRedeem+depositAmount);
    }

    function testTransfer(uint256 amount, uint256 amountToSend) public {
        amount = bound(amount, 2e5, type(uint96).max);
        amountToSend = bound(amountToSend, 1e5, amount-1e5);
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        address user2 = makeAddr("user2");
        uint256 userBalanceBefore = rebaseToken.balanceOf(user);
        uint256 user2BalanceBefore = rebaseToken.balanceOf(user2);

        assertEq(userBalanceBefore, amount);
        assertEq(user2BalanceBefore, 0);

        uint256 originalRate = rebaseToken.getUserInterestRate(user);
        uint256 newRate = 4e10;// or originalRate/2;

        vm.prank(owner);
        rebaseToken.setInterestRate(newRate);

        vm.prank(user);
        rebaseToken.transfer(user2, amountToSend);

        assertEq(rebaseToken.balanceOf(user), userBalanceBefore - amountToSend);
        assertEq(rebaseToken.balanceOf(user2), amountToSend);
        assertEq(rebaseToken.getUserInterestRate(user), originalRate);
        assertEq(rebaseToken.getUserInterestRate(user2), originalRate);
        
    }
    
    function testTransferAfterWarp(uint256 amount, uint256 amountToSend) public {
        amount = bound(amount, 2e5, type(uint96).max);
        amountToSend = bound(amountToSend, 1e5, amount-1e5);
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        address user2 = makeAddr("user2");
        uint256 userBalanceBefore = rebaseToken.balanceOf(user);
        uint256 user2BalanceBefore = rebaseToken.balanceOf(user2);

        assertEq(userBalanceBefore, amount);
        assertEq(user2BalanceBefore, 0);

        uint256 originalRate = rebaseToken.getUserInterestRate(user);
        uint256 newRate = 4e10;// or originalRate/2;

        vm.prank(owner);
        rebaseToken.setInterestRate(newRate);

        vm.prank(user);
        rebaseToken.transfer(user2, amountToSend);

        assertEq(rebaseToken.balanceOf(user), userBalanceBefore - amountToSend);
        assertEq(rebaseToken.balanceOf(user2), amountToSend);
        assertEq(rebaseToken.getUserInterestRate(user), originalRate);
        assertEq(rebaseToken.getUserInterestRate(user2), originalRate);

        vm.warp(block.timestamp + 1 days);
        uint256 userBalanceAfterWarp = rebaseToken.balanceOf(user);
        uint256 user2BalanceAfterWarp = rebaseToken.balanceOf(user2);
        // check their interest rates are as expected
        // since user two hadn't minted before, their interest rate should be the same as in the contract
        uint256 user2InterestRate = rebaseToken.getUserInterestRate(user2);
        assertEq(user2InterestRate, 5e10);
        // since user had minted before, their interest rate should be the previous interest rate
        uint256 userInterestRate = rebaseToken.getUserInterestRate(user);
        assertEq(userInterestRate, 5e10);

        assertGt(userBalanceAfterWarp, userBalanceBefore - amountToSend);
        assertGt(user2BalanceAfterWarp, amountToSend);
        
    }

    function testCannotSetInterestRate(uint256 newInterestRate) public {
        vm.prank(user);
        vm.expectPartialRevert(bytes4(Ownable.OwnableUnauthorizedAccount.selector));
        rebaseToken.setInterestRate(newInterestRate);
    }

    function testCannotCallMintAndBurn() public {
        vm.prank(user);
        vm.expectPartialRevert(bytes4(IAccessControl.AccessControlUnauthorizedAccount.selector));
        rebaseToken.mint(user, 100);
        
        vm.prank(user);
        vm.expectPartialRevert(bytes4(IAccessControl.AccessControlUnauthorizedAccount.selector));
        rebaseToken.burn(user, 100);
    }

    function testGetPrincipalBalance(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value:amount}();

        assertEq(rebaseToken.principalBalanceOf(user), amount);
        vm.warp(block.timestamp + 1 hours);
        assertEq(rebaseToken.principalBalanceOf(user), amount);
    }
}