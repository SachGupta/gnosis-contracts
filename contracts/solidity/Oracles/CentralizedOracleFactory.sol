pragma solidity 0.4.11;
import "Oracles/CentralizedOracle.sol";


/// @title Centralized oracle factory contract - Allows to create centralized oracle contracts.
/// @author Stefan George - <stefan@gnosis.pm>
contract CentralizedOracleFactory {

    /*
     *  Storage
     */
    mapping (bytes32 => CentralizedOracle) public centralizedOracles;

    /*
     *  Public functions
     */
    /// @dev Creates a new centralized oracle contract.
    /// @param descriptionHash Hash identifying off chain event description.
    /// @return Returns oracle contract.
    function createCentralizedOracle(bytes32 descriptionHash)
        public
        returns (CentralizedOracle centralizedOracle)
    {
        bytes32 centralizedOracleHash = keccak256(descriptionHash, msg.sender);
        if (address(centralizedOracles[centralizedOracleHash]) != 0)
            // Centralized oracle exists already
            revert();
        centralizedOracle = new CentralizedOracle(descriptionHash);
        centralizedOracles[centralizedOracleHash] = centralizedOracle;
    }
}
