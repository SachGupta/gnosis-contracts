pragma solidity 0.4.11;
import "Oracles/AbstractOracle.sol";
import "Tokens/AbstractToken.sol";


/// @title Ultimate oracle contract - Allows to swap oracle result for ultimate oracle result.
/// @author Stefan George - <stefan@gnosis.pm>
contract UltimateOracle is Oracle {

    /*
     *  Constants
     */
    uint public constant SPREAD_MULTIPLIER = 3;

    /*
     *  Storage
     */
    Oracle public oracle;
    Token public collateralToken;
    uint public challengePeriod;
    uint public challengeAmount;
    uint public frontRunnerPeriod;

    int public outcome;
    uint public outcomeSetTimestamp;
    int public frontRunner;
    uint public frontRunnerSetTimestamp;

    uint public totalAmount;
    mapping (int => uint) public totalOutcomeAmounts;
    mapping (address => mapping (int => uint)) public outcomeAmounts;

    /*
     *  Public functions
     */
    /// @dev Constructor sets Ultimate Oracle properties.
    /// @param _oracle Oracle address.
    /// @param _collateralToken Collateral token address.
    /// @param _challengePeriod Time to challenge oracle outcome.
    /// @param _challengeAmount Amount to challenge the outcome.
    /// @param _frontRunnerPeriod Time to overbid the front-runner.
    function UltimateOracle(
        Oracle _oracle,
        Token _collateralToken,
        uint _challengePeriod,
        uint _challengeAmount,
        uint _frontRunnerPeriod
    )
        public
    {
        if (   address(_oracle) == 0
            || address(_collateralToken) == 0
            || _challengePeriod == 0
            || _challengeAmount == 0
            || _frontRunnerPeriod == 0)
            // Values are null
            revert();
        oracle = _oracle;
        collateralToken = _collateralToken;
        challengeAmount = _challengeAmount;
        frontRunnerPeriod = _frontRunnerPeriod;
    }

    /// @dev Allows to set oracle outcome.
    function setOutcome()
        public
    {
        if (   frontRunnerSetTimestamp != 0
            || outcomeSetTimestamp != 0
            || !oracle.isOutcomeSet())
            // Outcome was set already or cannot be set yet
            revert();
        outcome = oracle.getOutcome();
        outcomeSetTimestamp = now;
    }

    /// @dev Allows to challenge the oracle outcome.
    /// @param _outcome Outcome to bid on.
    function challengeOutcome(int _outcome)
        public
    {
        if (   _outcome == outcome
            || frontRunnerSetTimestamp != 0
            || outcomeSetTimestamp != 0 && now - outcomeSetTimestamp > challengePeriod
            || !collateralToken.transferFrom(msg.sender, this, challengeAmount))
            // Outcome challenged already or challenge period is over or deposit cannot be paid
            revert();
        outcomeAmounts[msg.sender][_outcome] = challengeAmount;
        totalOutcomeAmounts[_outcome] = challengeAmount;
        totalAmount = challengeAmount;
        frontRunner = _outcome;
        frontRunnerSetTimestamp = now;
    }

    /// @dev Allows to challenge the oracle outcome.
    /// @param _outcome Outcome to bid on.
    /// @param amount Amount to bid.
    function voteForOutcome(int _outcome, uint amount)
        public
    {
        uint maxAmount =   (totalAmount - totalOutcomeAmounts[_outcome]) * SPREAD_MULTIPLIER
                         - totalOutcomeAmounts[_outcome];
        if (amount > maxAmount)
            amount = maxAmount;
        if (   frontRunnerSetTimestamp == 0
            || now - frontRunnerSetTimestamp <= frontRunnerPeriod
            || !collateralToken.transferFrom(msg.sender, this, amount))
            // Outcome is not challenged or leading period is over or deposit cannot be paid
            revert();
        outcomeAmounts[msg.sender][_outcome] = amount;
        totalOutcomeAmounts[_outcome] = amount;
        if (   _outcome != frontRunner
            && totalOutcomeAmounts[_outcome] > totalOutcomeAmounts[frontRunner])
        {
            frontRunner = _outcome;
            frontRunnerSetTimestamp = now;
        }
    }

    /// @dev Returns if winning outcome is set for given event.
    /// @return Returns if outcome is set.
    function isOutcomeSet()
        public
        constant
        returns (bool)
    {
        return    outcomeSetTimestamp != 0 && now - outcomeSetTimestamp > challengePeriod
               || frontRunnerSetTimestamp != 0 && now - frontRunnerSetTimestamp > frontRunnerPeriod;
    }

    /// @dev Returns winning outcome for given event.
    /// @return Returns outcome.
    function getOutcome()
        public
        constant
        returns (int)
    {
        if (frontRunnerSetTimestamp != 0 && now - frontRunnerSetTimestamp > frontRunnerPeriod)
            return frontRunner;
        return outcome;
    }
}
