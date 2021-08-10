//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.1;

contract PoolToken {
    string  public name = "Pool Token";
    string  public symbol = "Pool";
    string  public standard = "Pool Token v1.0";
    uint256 public totalSupply;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor () {
        totalSupply = 1000000;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _from, address _spender, uint256 _value) public returns (bool success) {
        allowance[_from][_spender] = _value;
        emit Approval(_from, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], 'Value exceeds account balance.' );
        require(_value <= allowance[_from][_to], 'Value exceeds spend allowance.' );

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][_to] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}

