pragma solidity 0.4.10;


contract DutchAuction {
    function bid(address receiver) payable returns (uint);
    function claimTokens(address receiver);
    function stage() returns (uint);
    Token public gnosisToken;
}


contract Token {
    function transfer(address to, uint256 value) returns (bool success);
    function balanceOf(address owner) constant returns (uint256 balance);
}


contract ProxySender {

    event BidSubmission(address indexed sender, uint256 amount);
    event RefundReceived(uint256 amount);

    uint public constant AUCTION_STARTED = 2;
    uint public constant TRADING_STARTED = 4;

    DutchAuction public dutchAuction;
    Token public gnosisToken;
    uint totalContributions;
    uint totalTokens;
    uint totalBalance;
    mapping (address => uint) contributions;
    mapping (address => bool) public tokensSent;
    Stages public stage;

    enum Stages {
        ContributionsCollection,
        TokensClaimed
    }

    modifier atStage(Stages _stage) {
        if (stage != _stage)
            throw;
        _;
    }

    function ProxySender(address _dutchAuction)
        public
    {
        if (_dutchAuction == 0)
            throw;
        dutchAuction = DutchAuction(_dutchAuction);
        gnosisToken = dutchAuction.gnosisToken();
        stage = Stages.ContributionsCollection;
    }

    function()
        public
        payable
    {
        if (msg.sender == address(dutchAuction))
            RefundReceived(msg.value);
        else if (stage == Stages.ContributionsCollection)
            contribute();
        else if (stage == Stages.TokensClaimed)
            transferTokens();
        else
            throw;
    }

    function contribute()
        public
        payable
        atStage(Stages.ContributionsCollection)
    {
        // Check auction has started
        if (dutchAuction.stage() != AUCTION_STARTED)
            throw;
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        dutchAuction.bid.value(this.balance)(0);
        BidSubmission(msg.sender, msg.value);
    }

    function claimProxy()
        public
        atStage(Stages.ContributionsCollection)
    {
        // Auction is over
        if (dutchAuction.stage() != TRADING_STARTED)
            throw;
        dutchAuction.claimTokens(0);
        totalTokens = gnosisToken.balanceOf(this);
        totalBalance = this.balance;
        stage = Stages.TokensClaimed;
    }

    function transferTokens()
        public
        atStage(Stages.TokensClaimed)
        returns (uint amount)
    {
        if (tokensSent[msg.sender])
            throw;
        tokensSent[msg.sender] = true;
        // Calc. percentage of tokens for sender
        amount = totalTokens * contributions[msg.sender] / totalContributions;
        gnosisToken.transfer(msg.sender, amount);
    }

    function transferRefunds()
        public
        atStage(Stages.TokensClaimed)
        returns (uint amount)
    {
        if (!tokensSent[msg.sender])
            throw;
        uint contribution = contributions[msg.sender];
        contributions[msg.sender] = 0;
        // Calc. percentage of tokens for sender
        amount = totalBalance * contribution / totalContributions;
        if (amount > 0 && !msg.sender.send(amount))
            throw;
    }
}
