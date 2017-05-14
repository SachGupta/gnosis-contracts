pragma solidity 0.4.11;
import "Events/AbstractEvent.sol";
import "Markets/DefaultMarketFactory.sol";


/// @title Campaign contract - Allows to crowdfund a market.
/// @author Stefan George - <stefan@gnosis.pm>
contract Campaign {

    /*
     *  Constants
     */
    uint public constant FEE_RANGE = 1000000; // 100%

    /*
     *  Storage
     */
    Event public eventContract;
    MarketFactory public marketFactory;
    MarketMaker public marketMaker;
    Market public market;
    uint public fee;
    uint public funding;
    uint public deadline;
    mapping (address => uint) public contributions;
    Stages public stage;

    enum Stages {
        AuctionStarted,
        AuctionSuccessful,
        AuctionFailed,
        MarketCreated
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        if (stage != _stage)
            // Contract not in expected state
            revert();
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted)
            if (eventContract.collateralToken().balanceOf(this) >= funding)
                stage = Stages.AuctionSuccessful;
            else if (deadline < now)
                stage = Stages.AuctionFailed;
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Constructor validates and sets campaign properties.
    /// @param _eventContract Event contract.
    /// @param _marketFactory Market factory contract.
    /// @param _marketMaker Market maker contract.
    /// @param _fee Market fee.
    /// @param _funding Initial funding for market.
    /// @param _deadline Campaign deadline.
    function Campaign(
        Event _eventContract,
        MarketFactory _marketFactory,
        MarketMaker _marketMaker,
        uint _fee,
        uint _funding,
        uint _deadline
    )
        public
    {
        if (   address(_eventContract) == 0
            || address(_marketFactory) == 0
            || address(_marketMaker) == 0
            || _fee >= FEE_RANGE
            || _funding == 0
            || deadline < now)
            // Invalid arguments
            throw;
        eventContract = _eventContract;
        marketFactory = _marketFactory;
        marketMaker = _marketMaker;
        fee = _fee;
        funding = _funding;
        deadline = _deadline;
    }

    /// @dev Allows to contribute to required market funding.
    /// @param amount Amount of collateral tokens.
    function fund(uint amount)
        public
        timedTransitions
        atStage(Stages.AuctionStarted)
    {
        uint raisedAmount = eventContract.collateralToken().balanceOf(this);
        uint maxAmount = funding - raisedAmount;
        if (maxAmount < amount)
            amount = maxAmount;
        if (!eventContract.collateralToken().transferFrom(msg.sender, this, amount))
            throw;
        contributions[msg.sender] += amount;
    }

    /// @dev Withdraws refund amount.
    /// @return Refund amount.
    function refund()
        public
        timedTransitions
        atStage(Stages.AuctionFailed)
        returns (uint refundAmount)
    {
        refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        if (!eventContract.collateralToken().transfer(msg.sender, refundAmount))
            // Refund failed
            throw;
    }

    /// @dev Allows to create market after successful funding.
    /// @return Returns market address.
    function createMarket()
        public
        timedTransitions
        atStage(Stages.AuctionSuccessful)
        returns (Market)
    {
        market = marketFactory.createMarket(eventContract, marketMaker, fee, funding);
        stage = Stages.MarketCreated;
        return market;
    }

    /// @dev Allows to withdraw fees from market contract to campaign contract.
    /// @return Fee amount.
    function withdrawFeesFromMarket()
        public
        atStage(Stages.MarketCreated)
        returns (uint)
    {
        return market.withdrawFees();
    }

    /// @dev Allows to withdraw fees from campaign contract to contributor.
    /// @return Fee amount.
    function withdrawFeesFromCampaign()
        public
        atStage(Stages.MarketCreated)
        returns (uint fees)
    {
        fees = eventContract.collateralToken().balanceOf(this) * contributions[msg.sender] / funding;
        contributions[msg.sender] = 0;
        if (!eventContract.collateralToken().transfer(msg.sender, fees))
            // Transfer failed
            throw;
    }
}
