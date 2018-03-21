pragma solidity 0.4.18;
import './Owned.sol';
import './FHFTokenInterface.sol';
import './CrowdsaleParameters.sol';

contract FHFTokenCrowdsale is Owned, CrowdsaleParameters {
    /* Token and records */
    FHFTokenInterface private token;
    address private saleWalletAddress;
    uint private tokenMultiplier = 10;
    uint public totalCollected = 0;
    uint public saleGoal;
    bool public goalReached = false;

    /* Events */
    event TokenSale(address indexed tokenReceiver, uint indexed etherAmount, uint indexed tokenAmount, uint tokensPerEther);
    event FundTransfer(address indexed from, address indexed to, uint indexed amount);

    /**
    * Constructor
    *
    * @param _tokenAddress - address of token (deployed before this contract)
    */
    function FHFTokenCrowdsale(address _tokenAddress) public {
        token = FHFTokenInterface(_tokenAddress);
        tokenMultiplier = tokenMultiplier ** token.decimals();
        saleWalletAddress = CrowdsaleParameters.generalSaleWallet.addr;

        // Initialize sale goal
        saleGoal = CrowdsaleParameters.generalSaleWallet.amount;
    }

    /**
    * Is sale active
    *
    * @return active - True, if sale is active
    */
    function isICOActive() public constant returns (bool active) {
        active = ((generalSaleStartDate <= now) && (now < generalSaleEndDate) && (!goalReached));
        return active;
    }

    /**
    *  Process received payment
    *
    *  Determine the integer number of tokens that was purchased considering current
    *  stage, tier bonus, and remaining amount of tokens in the sale wallet.
    *  Transfer purchased tokens to backerAddress and return unused portion of
    *  ether (change)
    *
    * @param backerAddress - address that ether was sent from
    * @param amount - amount of Wei received
    */
    function processPayment(address backerAddress, uint amount) internal {
        require(isICOActive());

        // Before Metropolis update require will not refund gas, but
        // for some reason require statement around msg.value always throws
        assert(msg.value > 0 finney);

        // Tell everyone about the transfer
        FundTransfer(backerAddress, address(this), amount);

        // Calculate tokens per ETH for this tier
        uint tokensPerEth = 10000;

        // Calculate token amount that is purchased,
        uint tokenAmount = amount * tokensPerEth;

        // Check that stage wallet has enough tokens. If not, sell the rest and
        // return change.
        uint remainingTokenBalance = token.balanceOf(saleWalletAddress);
        if (remainingTokenBalance <= tokenAmount) {
            tokenAmount = remainingTokenBalance;
            goalReached = true;
        }

        // Calculate Wei amount that was received in this transaction
        // adjusted to rounding and remaining token amount
        uint acceptedAmount = tokenAmount / tokensPerEth;

        // Update crowdsale performance
        totalCollected += acceptedAmount;

        // Transfer tokens to baker and return ETH change
        token.transferFrom(saleWalletAddress, backerAddress, tokenAmount);

        TokenSale(backerAddress, amount, tokenAmount, tokensPerEth);

        // Return change (in Wei)
        uint change = amount - acceptedAmount;
        if (change > 0) {
            if (backerAddress.send(change)) {
                FundTransfer(address(this), backerAddress, change);
            }
            else revert();
        }
    }

    /**
    *  Transfer ETH amount from contract to owner's address.
    *  Can only be used if ICO is closed
    *
    * @param amount - ETH amount to transfer in Wei
    */
    function safeWithdrawal(uint amount) external onlyOwner {
        require(this.balance >= amount);
        require(!isICOActive());

        if (owner.send(amount)) {
            FundTransfer(address(this), msg.sender, amount);
        }
    }

    /**
    *  Default method
    *
    *  Processes all ETH that it receives and credits FHF tokens to sender
    *  according to current stage bonus
    */
    function () external payable {
        processPayment(msg.sender, msg.value);
    }

    /**
    * Close main sale and move unsold tokens to playersReserve wallet
    */
    function closeMainSaleICO() external onlyOwner {
        require(!isICOActive());
        require(generalSaleStartDate < now);

        var amountToMove = token.balanceOf(generalSaleWallet.addr);
        token.transferFrom(generalSaleWallet.addr, playersReserve, amountToMove);
        generalSaleEndDate = now;
    }

    /**
    *  Kill method
    *
    *  Double-checks that unsold general sale tokens were moved off general sale wallet and
    *  destructs this contract
    */
    function kill() external onlyOwner {
        require(!isICOActive());
        if (now < generalSaleStartDate) {
            selfdestruct(owner);
        } else if (token.balanceOf(generalSaleWallet.addr) == 0) {
            FundTransfer(address(this), msg.sender, this.balance);
            selfdestruct(owner);
        } else {
            revert();
        }
    }
}
