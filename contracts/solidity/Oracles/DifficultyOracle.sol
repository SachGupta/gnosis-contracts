pragma solidity 0.4.11;
import "Oracles/AbstractOracle.sol";


/// @title Difficulty oracle contract - On chain oracle to resolve difficulty events at given block.
/// @author Stefan George - <stefan.george@consensys.net>
/// @author Martin Koeppelmann - <martin.koeppelmann@consensys.net>
contract DifficultyOracle is Oracle {

    /*
     *  Storage
     */
    mapping (uint => uint) public difficultyResults;

    /*
     *  Public functions
     */
    /// @dev Sets difficulty as winning outcome for a specific block. Returns success.
    /// @param blockNumber Block number, which has to be passed to set difficulty for block.
    function setOutcome(uint blockNumber)
        public
    {
        if (block.number < blockNumber || difficultyResults[blockNumber] != 0)
            // Block number was not reached yet or it was set already
            throw;
        difficultyResults[blockNumber] = block.difficulty;
        bytes32 eventIdentifier = bytes32(blockNumber);
        int outcome = int(block.difficulty);
        EventResolution(eventIdentifier, outcome);
    }

    /// @dev Validates and registers event. Returns event identifier.
    /// @param blockNumber Block number, which has to be passed to set difficulty for block.
    function registerEvent(uint blockNumber)
        public
        returns (bytes32 eventIdentifier)
    {
        if (blockNumber <= block.number)
            // Block number was already reached
            throw;
        eventIdentifier = bytes32(blockNumber);
        EventRegistration(msg.sender, eventIdentifier);
    }

    /// @dev Returns if winning outcome is set for given event.
    /// @param eventIdentifier Event identifier.
    function isOutcomeSet(bytes32 eventIdentifier)
        public
        constant
        returns (bool)
    {
        uint blockNumber = uint(eventIdentifier);
        // Difficulty will never be 0
        return difficultyResults[blockNumber] > 0;
    }

    /// @dev Returns winning outcome for given event.
    /// @param eventIdentifier Event identifier.
    /// @return Returns outcome.
    function getOutcome(bytes32 eventIdentifier)
        public
        constant
        returns (int)
    {
        uint blockNumber = uint(eventIdentifier);
        return int(difficultyResults[blockNumber]);
    }
}
