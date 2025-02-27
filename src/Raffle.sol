// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
/**
 * @title Raffle
 * @author Raamtaro
 * @notice This contract is used to create a smart contract lottery
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    /**
     * Type Declarations
     */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1

    }

    /**
     * State Variables
     */

    //@dev chainlink VRF coordinator confirmation count
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    //@dev number of random words to request
    uint32 private constant NUM_WORDS = 1;

    //@dev minimum amount of ETH to enter the lottery
    uint256 private immutable i_entranceFee;

    //@dev duration of the lottery in seconds
    uint256 private immutable i_interval;

    //@dev gas lane limit for the VRF Coordinator
    bytes32 private immutable i_keyHash;

    //@dev Subscription ID for the VRF Coordinator
    uint256 private immutable i_subscriptionId;

    //@dev Callback Gas Limit for the VRF Coordinator
    uint32 private immutable i_callbackGasLimit;

    //@dev last time the lottery was entered
    uint256 private s_lastTimeStamp;

    //@dev array of players
    address payable[] private s_players;

    //@dev the current state of the lottery
    RaffleState private s_raffleState;

    //@dev most recent winner
    address private s_recentWinner;

    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    /**
     * Constructor
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent"); //This is quite expensive due to the string.
        if (msg.value < i_entranceFee) {
            //This is more gas efficient
            revert Raffle__SendMoreToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev This is the function that the chainlink nodes will call to see if the lottery is ready to have a winner picked. The following should be true in order for upkeepNeeded to be true:
     * 1. Time interval has passed
     * 2. The Lottery is open
     * 3. The contract has ETH
     * 4. The subscription is funded with LINK
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return - ignored
     */
    function checkUpKeep(bytes memory /*checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData */ )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);

        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        // 1. Get a random number
        // 2. Use that random number to pick a winner
        // 3. Automatically called

        //Has enough time passed?
        // if (block.timestamp - s_lastTimeStamp < i_interval) {
        //     revert();
        // }

        (bool upkeepNeeded,) = checkUpKeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    //CEI: Checks, Effects, Interactions pattern
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(recentWinner);

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
