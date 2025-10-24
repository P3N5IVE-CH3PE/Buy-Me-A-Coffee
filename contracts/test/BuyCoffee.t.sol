// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/BuyCoffee.sol";

contract BuyCoffeeTest is Test {
    BuyCoffee public coffee;
    address public owner;
    address public buyer1;
    address public buyer2;

    // Events to test
    event CoffeeBought(address indexed buyer, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);

    function setUp() public {
        owner = address(this);
        buyer1 = makeAddr("buyer1");
        buyer2 = makeAddr("buyer2");

        // Deploy contract
        coffee = new BuyCoffee();

        // Give buyers some ETH
        vm.deal(buyer1, 10 ether);
        vm.deal(buyer2, 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ConstructorSetsOwner() public {
        assertEq(coffee.owner(), owner);
    }

    /*//////////////////////////////////////////////////////////////
                            BUY COFFEE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BuyCoffee_Success() public {
        uint256 amount = 0.1 ether;

        vm.prank(buyer1);
        coffee.buyCoffee{value: amount}();

        assertEq(coffee.getBalance(), amount);
    }

    function test_BuyCoffee_EmitsEvent() public {
        uint256 amount = 0.5 ether;

        vm.expectEmit(true, true, false, true);
        emit CoffeeBought(buyer1, amount);

        vm.prank(buyer1);
        coffee.buyCoffee{value: amount}();
    }

    function test_BuyCoffee_RevertsWithZeroValue() public {
        vm.prank(buyer1);
        vm.expectRevert("Send some ETH to buy coffee");
        coffee.buyCoffee{value: 0}();
    }

    function test_BuyCoffee_MultipleBuyers() public {
        vm.prank(buyer1);
        coffee.buyCoffee{value: 0.1 ether}();

        vm.prank(buyer2);
        coffee.buyCoffee{value: 0.2 ether}();

        assertEq(coffee.getBalance(), 0.3 ether);
    }

    function test_BuyCoffee_AccumulatesBalance() public {
        vm.startPrank(buyer1);
        coffee.buyCoffee{value: 0.1 ether}();
        coffee.buyCoffee{value: 0.2 ether}();
        coffee.buyCoffee{value: 0.3 ether}();
        vm.stopPrank();

        assertEq(coffee.getBalance(), 0.6 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            GET BALANCE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetBalance_InitiallyZero() public {
        assertEq(coffee.getBalance(), 0);
    }

    function test_GetBalance_AfterPurchase() public {
        uint256 amount = 1 ether;

        vm.prank(buyer1);
        coffee.buyCoffee{value: amount}();

        assertEq(coffee.getBalance(), amount);
    }

    function test_GetBalance_AfterMultiplePurchases() public {
        vm.prank(buyer1);
        coffee.buyCoffee{value: 0.5 ether}();

        vm.prank(buyer2);
        coffee.buyCoffee{value: 1.5 ether}();

        assertEq(coffee.getBalance(), 2 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Withdraw_Success() public {
        // Buy some coffee
        vm.prank(buyer1);
        coffee.buyCoffee{value: 1 ether}();

        uint256 ownerBalanceBefore = owner.balance;
        uint256 contractBalance = coffee.getBalance();

        // Withdraw as owner
        coffee.withdraw();

        assertEq(coffee.getBalance(), 0);
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
    }

    function test_Withdraw_EmitsEvent() public {
        vm.prank(buyer1);
        coffee.buyCoffee{value: 1 ether}();

        vm.expectEmit(true, true, false, true);
        emit Withdrawal(owner, 1 ether);

        coffee.withdraw();
    }

    function test_Withdraw_RevertsIfNotOwner() public {
        vm.prank(buyer1);
        coffee.buyCoffee{value: 1 ether}();

        vm.prank(buyer1);
        vm.expectRevert("Only owner can withdraw");
        coffee.withdraw();
    }

    function test_Withdraw_RevertsIfNoFunds() public {
        vm.expectRevert("No funds to withdraw");
        coffee.withdraw();
    }

    function test_Withdraw_MultipleWithdrawals() public {
        // First purchase and withdrawal
        vm.prank(buyer1);
        coffee.buyCoffee{value: 0.5 ether}();
        coffee.withdraw();
        assertEq(coffee.getBalance(), 0);

        // Second purchase and withdrawal
        vm.prank(buyer2);
        coffee.buyCoffee{value: 1 ether}();
        coffee.withdraw();
        assertEq(coffee.getBalance(), 0);
    }

    function test_Withdraw_TransfersAllFunds() public {
        // Multiple purchases
        vm.prank(buyer1);
        coffee.buyCoffee{value: 0.3 ether}();

        vm.prank(buyer2);
        coffee.buyCoffee{value: 0.7 ether}();

        uint256 ownerBalanceBefore = owner.balance;

        coffee.withdraw();

        assertEq(coffee.getBalance(), 0);
        assertEq(owner.balance, ownerBalanceBefore + 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            RECEIVE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Receive_DirectTransfer() public {
        uint256 amount = 0.5 ether;

        vm.prank(buyer1);
        (bool success, ) = address(coffee).call{value: amount}("");

        assertTrue(success);
        assertEq(coffee.getBalance(), amount);
    }

    function test_Receive_EmitsEvent() public {
        uint256 amount = 0.5 ether;

        vm.expectEmit(true, true, false, true);
        emit CoffeeBought(buyer1, amount);

        vm.prank(buyer1);
        (bool success, ) = address(coffee).call{value: amount}("");
        assertTrue(success);
    }

    function test_Receive_RevertsWithZeroValue() public {
        vm.prank(buyer1);
        vm.expectRevert("Send some ETH to buy coffee");
        (bool success, ) = address(coffee).call{value: 0}("");
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_BuyCoffee(uint256 amount) public {
        // Bound amount to reasonable range
        amount = bound(amount, 0.001 ether, 100 ether);

        vm.deal(buyer1, amount);

        vm.prank(buyer1);
        coffee.buyCoffee{value: amount}();

        assertEq(coffee.getBalance(), amount);
    }

    function testFuzz_Withdraw(uint256 amount) public {
        amount = bound(amount, 0.001 ether, 100 ether);

        vm.deal(buyer1, amount);

        vm.prank(buyer1);
        coffee.buyCoffee{value: amount}();

        uint256 ownerBalanceBefore = owner.balance;
        coffee.withdraw();

        assertEq(coffee.getBalance(), 0);
        assertEq(owner.balance, ownerBalanceBefore + amount);
    }

    function testFuzz_MultipleBuyers(uint256 amount1, uint256 amount2) public {
        amount1 = bound(amount1, 0.001 ether, 50 ether);
        amount2 = bound(amount2, 0.001 ether, 50 ether);

        vm.deal(buyer1, amount1);
        vm.deal(buyer2, amount2);

        vm.prank(buyer1);
        coffee.buyCoffee{value: amount1}();

        vm.prank(buyer2);
        coffee.buyCoffee{value: amount2}();

        assertEq(coffee.getBalance(), amount1 + amount2);
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Integration_BuyAndWithdrawCycle() public {
        // Scenario: Multiple buyers, then owner withdraws
        vm.prank(buyer1);
        coffee.buyCoffee{value: 0.5 ether}();

        vm.prank(buyer2);
        coffee.buyCoffee{value: 0.3 ether}();

        assertEq(coffee.getBalance(), 0.8 ether);

        uint256 ownerBalanceBefore = owner.balance;
        coffee.withdraw();

        assertEq(coffee.getBalance(), 0);
        assertEq(owner.balance, ownerBalanceBefore + 0.8 ether);
    }

    function test_Integration_MultipleWithdrawCycles() public {
        // Cycle 1
        vm.prank(buyer1);
        coffee.buyCoffee{value: 1 ether}();
        uint256 ownerBalance1 = owner.balance;
        coffee.withdraw();
        assertEq(owner.balance, ownerBalance1 + 1 ether);

        // Cycle 2
        vm.prank(buyer2);
        coffee.buyCoffee{value: 2 ether}();
        uint256 ownerBalance2 = owner.balance;
        coffee.withdraw();
        assertEq(owner.balance, ownerBalance2 + 2 ether);

        // Final balance check
        assertEq(coffee.getBalance(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                            EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_EdgeCase_VerySmallAmount() public {
        uint256 amount = 1 wei;

        vm.prank(buyer1);
        coffee.buyCoffee{value: amount}();

        assertEq(coffee.getBalance(), amount);
    }

    function test_EdgeCase_VeryLargeAmount() public {
        uint256 amount = 1000 ether;
        vm.deal(buyer1, amount);

        vm.prank(buyer1);
        coffee.buyCoffee{value: amount}();

        assertEq(coffee.getBalance(), amount);
    }

    function test_EdgeCase_WithdrawImmediatelyAfterDeploy() public {
        vm.expectRevert("No funds to withdraw");
        coffee.withdraw();
    }

    // Helper function to receive ETH
    receive() external payable {}
}
