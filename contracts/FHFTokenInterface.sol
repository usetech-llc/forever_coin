pragma solidity 0.4.18;

contract FHFTokenInterface {
    /* Public parameters of the token */
    string public standard = 'Token 0.1';
    string public name = 'Forever Has Fallen';
    string public symbol = 'FC';
    uint8 public decimals = 18;

    function approveCrowdsale(address _crowdsaleAddress) external;
    function balanceOf(address _address) public constant returns (uint256 balance);
    function vestedBalanceOf(address _address) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _currentValue, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}
