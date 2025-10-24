// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract BuyCoffee {
    address public owner;

    event CoffeeBought(address indexed buyer, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function buyCoffee() public payable {
        require(msg.value > 0, "Send some ETH to buy coffee");
        emit CoffeeBought(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(owner, balance);
    }

    receive() external payable {
        buyCoffee();
    }
}
