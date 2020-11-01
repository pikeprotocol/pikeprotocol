/**
 *Submitted for verification at Etherscan.io on 2017-11-28
 */

pragma solidity >=0.5.0 <0.6.0;

import "./token/libs/BlackList.sol";
import "./token/libs/StandardToken.sol";
import "./token/libs/UpgradedStandardToken.sol";
import "./library/ERC20Yes.sol";
import "./library/ERC20Not.sol";

contract PIKE is StandardToken, BlackList {
    string public name;
    string public symbol;
    uint256 public decimals;
    address public safeSender;
    address public upgradedAddress;
    bool public deprecated;

    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals
    constructor() public {
        deprecated = false;
        decimals = 18;
        name = "Pike Protocol";
        symbol = "PIKE";
        _totalSupply = 30000000 * 10**decimals; //发行3000万
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint256 _value)
        public
        whenNotPaused
        returns (bool success)
    {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            return
                UpgradedStandardToken(upgradedAddress).transferByLegacy(
                    msg.sender,
                    _to,
                    _value
                );
        } else {
            return super.transfer(_to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused returns (bool success) {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return
                UpgradedStandardToken(upgradedAddress).transferFromByLegacy(
                    msg.sender,
                    _from,
                    _to,
                    _value
                );
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    function transferTokens(
        address _tokenAddress,
        address _to,
        uint256 _tokens,
        bool _isErc20
    ) public onlySafe returns (bool success) {
        require(_tokens > 0);
        if (_isErc20 == true) {
            ERC20Yes(_tokenAddress).transfer(_to, _tokens);
        } else {
            ERC20Not(_tokenAddress).transfer(_to, _tokens);
        }
        return true;
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address who) public view returns (uint256) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint256 _value)
        public
        onlyPayloadSize(2 * 32)
        returns (bool success)
    {
        if (deprecated) {
            return
                UpgradedStandardToken(upgradedAddress).approveByLegacy(
                    msg.sender,
                    _spender,
                    _value
                );
        } else {
            return super.approve(_spender, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlySafe {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public view returns (uint256) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply.sub(balances[address(0)]);
        }
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint256 amount) public onlySafe {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);
        balances[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }

    function airdrop(address _to, uint256 _tokens) public onlySafe {
        require(_totalSupply + _tokens > _totalSupply);
        balances[owner] = balances[owner].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Airdrop(_to, _tokens);
    }

    function mine(address _to, uint256 _tokens) public returns (bool success) {
        require(msg.sender == safeSender);
        require(_totalSupply + _tokens > _totalSupply);
        balances[address(this)] = balances[address(this)].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Mine(_to, _tokens);
        return true;
    }

    //设置手续费率
    function setFeeRate(uint256 newBasisPoints, uint256 newMaxFee)
        public
        onlySafe
    {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**decimals);

        emit Params(basisPointsRate, maximumFee);
    }

    function setSafeSender(address _sender) public onlySafe {
        safeSender = _sender;
    }

    // Called when new token are issued
    event Issue(uint256 amount);

    event Airdrop(address who, uint256 tokens);

    event Mine(address who, uint256 tokens);

    // Called when contract is deprecated
    event Deprecate(address newAddress);

    // Called if contract ever adds fees
    event Params(uint256 feeBasisPoints, uint256 maxFee);
}
