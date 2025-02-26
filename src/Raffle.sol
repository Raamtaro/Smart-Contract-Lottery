// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


/**
 * @title Raffle
 * @author Raamtaro
 * @notice This contract is used to create a smart contract lottery
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle {
    /**
     * Errors
     */
    error Raffle__SendMoreToEnterRaffle();


    /**
     * State Variables
     */

    //@dev minimum amount of ETH to enter the lottery
    uint256 private immutable i_entranceFee;

    //@dev duration of the lottery in seconds
    uint256 private immutable i_interval;

    //@dev last time the lottery was entered
    uint256 private s_lastTimeStamp;

    //@dev array of players
    address payable[] private s_players;

    /**
     * Events
     */
    event RaffleEntered(address indexed player);


    /**
     * Constructor
     */

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent"); //This is quite expensive due to the string.
        if (msg.value < i_entranceFee) { //This is more gas efficient 
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }



    function pickWinner() external {
        // 1. Get a random number
        // 2. Use that random number to pick a winner
        // 3. Automatically called

        //Has enough time passed?
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }

        //Else, get our random number from Chainlink VRF
    }

    /**
     * Getter Functions
     */

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}