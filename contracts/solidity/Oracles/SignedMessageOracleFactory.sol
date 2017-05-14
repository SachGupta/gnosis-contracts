pragma solidity 0.4.11;
import "Oracles/SignedMessageOracle.sol";


/// @title Signed message oracle factory contract - Allows to create signed message oracle contracts.
/// @author Stefan George - <stefan@gnosis.pm>
contract SignedMessageOracleFactory {

    /*
     *  Storage
     */
    mapping (bytes32 => SignedMessageOracle) public signedMessageOracles;

    /*
     *  Public functions
     */
    /// @dev Creates a new signed message oracle contract.
    /// @param descriptionHash Hash identifying off chain event description.
    /// @param v Signature parameter.
    /// @param r Signature parameter.
    /// @param s Signature parameter.
    /// @return Returns oracle contract.
    function createSignedMessageOracle(bytes32 descriptionHash, uint8 v, bytes32 r, bytes32 s)
        public
        returns (SignedMessageOracle signedMessageOracle)
    {
        bytes32 signedMessageOracleHash = keccak256(descriptionHash, v, r, s);
        if (address(signedMessageOracles[signedMessageOracleHash]) != 0)
            // Signed message oracle exists already
            revert();
        signedMessageOracle = new SignedMessageOracle(descriptionHash, v, r, s);
        signedMessageOracles[signedMessageOracleHash] = signedMessageOracle;
    }
}
