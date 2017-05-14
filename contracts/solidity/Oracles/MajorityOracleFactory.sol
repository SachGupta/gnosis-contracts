pragma solidity 0.4.11;
import "Oracles/MajorityOracle.sol";


/// @title Majority oracle factory contract - Allows to create majority oracle contracts.
/// @author Stefan George - <stefan@gnosis.pm>
contract MajorityOracleFactory {

    /*
     *  Storage
     */
    mapping (bytes32 => MajorityOracle) public majorityOracles;

    /*
     *  Public functions
     */
    /// @dev Creates a new majority oracle contract.
    /// @param oracles List of oracles taking part in the majority vote.
    /// @return Returns oracle contract.
    function createMajorityOracle(Oracle[] oracles)
        public
        returns (MajorityOracle majorityOracle)
    {
        bytes32 majorityOracleHash = keccak256(oracles);
        if (address(majorityOracles[majorityOracleHash]) != 0)
            // Majority oracle exists already
            revert();
        majorityOracle = new MajorityOracle(oracles);
        majorityOracles[majorityOracleHash] = majorityOracle;
    }
}
