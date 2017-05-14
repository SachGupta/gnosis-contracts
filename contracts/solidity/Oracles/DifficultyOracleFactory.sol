pragma solidity 0.4.11;
import "Oracles/DifficultyOracle.sol";


/// @title Difficulty oracle factory contract - Allows to create difficulty oracle contracts.
/// @author Stefan George - <stefan@gnosis.pm>
contract DifficultyOracleFactory {

    /*
     *  Storage
     */
    mapping (bytes32 => DifficultyOracle) public difficultyOracles;

    /*
     *  Public functions
     */
    /// @dev Creates a new difficulty oracle contract.
    /// @param blockNumber Target block number.
    /// @return Returns oracle contract.
    function createDifficultyOracle(uint blockNumber)
        public
        returns (DifficultyOracle difficultyOracle)
    {
        bytes32 difficultyOracleHash = keccak256(blockNumber);
        if (address(difficultyOracles[difficultyOracleHash]) != 0)
            // Difficulty oracle exists already
            revert();
        difficultyOracle = new DifficultyOracle(blockNumber);
        difficultyOracles[difficultyOracleHash] = difficultyOracle;
    }
}
