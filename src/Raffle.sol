// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


/**
 * @title Raffle
 * @author Raamtaro
 * @notice This contract is used to create a smart contract lottery
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent"); //This is quite expensive due to the string.
    }

    function pickWinner() public {

    }

    /**
     * Getter Functions
     */

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}