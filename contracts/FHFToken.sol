pragma solidity 0.4.18;
import './Owned.sol';
import './CrowdsaleParameters.sol';
import './FHFTokenInterface.sol';

contract FHFToken is Owned, CrowdsaleParameters, FHFTokenInterface {
    /* Arrays of all balances, vesting, approvals, and approval uses */
    mapping (address => uint256) private balances;              // Total token balances
    mapping (address => uint256) private balancesEndIcoFreeze;  // Balances frozen for ICO end by address
    mapping (address => uint256) private balances2yearFreeze;  // Balances frozen for 2 years after ICO end by address
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => mapping (address => bool)) private allowanceUsed;


    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event VestingTransfer(address indexed from, address indexed to, uint256 value, uint256 vestingTime);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Issuance(uint256 _amount); // triggered when the total supply is increased
    event Destruction(uint256 _amount); // triggered when the total supply is decreased
    event NewFHFToken(address _token);

    /* Miscellaneous */
    uint256 public totalSupply = 0; // 1 000 000 000 when minted

    /**
    *  Constructor
    *
    *  Initializes contract with initial supply tokens to the creator of the contract
    */
    function FHFToken() public {
        owner = msg.sender;

        mintToken(generalSaleWallet);
        mintToken(communityReserve);
        mintToken(team);
        mintToken(advisors);
        mintToken(bounty);
        mintToken(administrative);

        NewFHFToken(address(this));
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    /**
    *  1. Associate crowdsale contract address with this Token
    *  2. Allocate general sale amount
    *
    * @param _crowdsaleAddress - crowdsale contract address
    */
    function approveCrowdsale(address _crowdsaleAddress) external onlyOwner {
        uint uintDecimals = decimals;
        uint exponent = 10**uintDecimals;
        uint amount = generalSaleWallet.amount * exponent;

        allowed[generalSaleWallet.addr][_crowdsaleAddress] = amount;
        Approval(generalSaleWallet.addr, _crowdsaleAddress, amount);
    }

    /**
    *  Get token balance of an address
    *
    * @param _address - address to query
    * @return Token balance of _address
    */
    function balanceOf(address _address) public constant returns (uint256 balance) {
        return balances[_address];
    }

    /**
    *  Get vested token balance of an address
    *
    * @param _address - address to query
    * @return balance that has vested
    */
    function vestedBalanceOf(address _address) public constant returns (uint256 balance) {
        if (now < vestingBounty) {
            return balances[_address] - balances2yearFreeze[_address] - balancesEndIcoFreeze[_address];
        }
        if (now < vestingTeam) {
            return balances[_address] - balances2yearFreeze[_address];
        } else {
            return balances[_address];
        }
    }

    /**
    *  Get token amount allocated for a transaction from _owner to _spender addresses
    *
    * @param _owner - owner address, i.e. address to transfer from
    * @param _spender - spender address, i.e. address to transfer to
    * @return Remaining amount allowed to be transferred
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    *  Create token and credit it to target address
    *  Created tokens need to vest
    *
    */
    function mintToken(AddressTokenAllocation tokenAllocation) internal {
        uint uintDecimals = decimals;
        uint exponent = 10**uintDecimals;
        uint mintedAmount = tokenAllocation.amount * exponent;

        // Mint happens right here: Balance becomes non-zero from zero
        balances[tokenAllocation.addr] += mintedAmount;
        totalSupply += mintedAmount;

        // Emit Issue and Transfer events
        Issuance(mintedAmount);
        Transfer(address(this), tokenAllocation.addr, mintedAmount);
    }

    /**
    *  Allow another contract to spend some tokens on your behalf
    *
    * @param _spender - address to allocate tokens for
    * @param _value - number of tokens to allocate
    * @return True in case of success, otherwise false
    */
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2*32) returns (bool success) {
        require(_value == 0 || allowanceUsed[msg.sender][_spender] == false);

        allowed[msg.sender][_spender] = _value;
        allowanceUsed[msg.sender][_spender] = false;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
    *  Allow another contract to spend some tokens on your behalf
    *
    * @param _spender - address to allocate tokens for
    * @param _currentValue - current number of tokens approved for allocation
    * @param _value - number of tokens to allocate
    * @return True in case of success, otherwise false
    */
    function approve(address _spender, uint256 _currentValue, uint256 _value) public onlyPayloadSize(3*32) returns (bool success) {
        require(allowed[msg.sender][_spender] == _currentValue);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    *  Send coins from sender's address to address specified in parameters
    *
    * @param _to - address to send to
    * @param _value - amount to send in Wei
    */
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2*32) returns (bool success) {
        // Check if the sender has enough
        require(vestedBalanceOf(msg.sender) >= _value);

        // Subtract from the sender
        // _value is never greater than balance of input validation above
        balances[msg.sender] -= _value;

        // Overflow is never possible due to input validation above
        balances[_to] += _value;

        // If tokens issued from this address need to vest (i.e. this address is a team pool), freeze them here
        if ((msg.sender == bounty.addr) && (now < vestingBounty)) {
            balancesEndIcoFreeze[_to] += _value;
        }
        if ((msg.sender == team.addr) && (now < vestingTeam)) {
            balances2yearFreeze[_to] += _value;
        }

        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    *  A contract attempts to get the coins. Tokens should be previously allocated
    *
    * @param _to - address to transfer tokens to
    * @param _from - address to transfer tokens from
    * @param _value - number of tokens to transfer
    * @return True in case of success, otherwise false
    */
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3*32) returns (bool success) {
        // Check if the sender has enough
        require(vestedBalanceOf(_from) >= _value);

        // Check allowed
        require(_value <= allowed[_from][msg.sender]);

        // Subtract from the sender
        // _value is never greater than balance because of input validation above
        balances[_from] -= _value;
        // Add the same to the recipient
        // Overflow is not possible because of input validation above
        balances[_to] += _value;

        // Deduct allocation
        // _value is never greater than allowed amount because of input validation above
        allowed[_from][msg.sender] -= _value;

        // If tokens issued from this address need to vest (i.e. this address is a team pool), freeze them here
        if ((_from == bounty.addr) && (now < vestingBounty)) {
            balancesEndIcoFreeze[_to] += _value;
        }
        if ((_from == team.addr) && (now < vestingTeam)) {
            balances2yearFreeze[_to] += _value;
        }

        Transfer(_from, _to, _value);
        allowanceUsed[_from][msg.sender] = true;

        return true;
    }

    /**
    *  Default method
    *
    *  This unnamed function is called whenever someone tries to send ether to
    *  it. Just revert transaction because there is nothing that Token can do
    *  with incoming ether.
    *
    *  Missing payable modifier prevents accidental sending of ether
    */
    function() public {
    }
}
