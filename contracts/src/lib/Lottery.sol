// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./DIARandomOracle.sol";

contract Lottery {
    address public randomOracle; // Randomness oracle
    uint256 latestRoundId = 0; // latest randomness round

    address[] public participants;
    address[] public winners;

    constructor(address oracle, address[] memory _participants) {
        randomOracle = oracle; //Oracle address : 0x48d351aB7f8646239BbadE95c3Cc6de3eF4A6cec (also in constants.sol)
        participants = _participants;
        latestRoundId = DIARandomOracle(randomOracle).getLastRound();
    }

    function getRandomValue(uint256 _round) public view returns (string memory) {
        return DIARandomOracle(randomOracle).getRandomValueFromRound(_round);
    }

    // main function: executing the protocol here
    function drawWinners() public {
        // Clear the winners array
        winners = new address[](0);

        // Ensure there is at least one participant
        require(participants.length >= 1, "There should be at least 1 participant");

        // Determine the number of winners
        uint256 num_winners;
        if (participants.length == 1) {
            num_winners = 1;
            winners.push(participants[0]);
        } else if (participants.length == 2) {
            num_winners = 2;
        } else {
            num_winners = 3;
        }

        if (participants.length > 1) {
            // Get the latest round ID
            latestRoundId = DIARandomOracle(randomOracle).getLastRound();

            // Ensure the latest round is greater than or equal to the buffer
            require(
                DIARandomOracle(randomOracle).getLastRound() >= latestRoundId,
                "Wait for the randomness round to draw the lottery."
            );

            // Get the random value for the round
            string memory rand = getRandomValue(latestRoundId);

            // Draw winners
            for (uint256 i = 0; i < num_winners; i++) {
                uint256 randomIndex = (uint256(keccak256(abi.encodePacked(rand, i))) % participants.length);
                winners.push(participants[randomIndex]);

                // Remove the winner from the participants array
                participants[randomIndex] = participants[participants.length - 1];
                participants.pop();
            }
        }
    }

    function getWinners() public view returns (address[] memory) {
        return winners;
    }
}
