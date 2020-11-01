pragma solidity >=0.5.0 <0.6.0;

import "../library/Ownable.sol";

contract BlackList is Ownable {
    mapping(address => bool) public isBlackListed;

    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    // function getBlackListStatus(address _who) external view returns (bool) {
    //     return isBlackListed[_who];
    // }

    function addBlackList(address _who) public onlySafe {
        isBlackListed[_who] = true;
        emit AddedBlackList(_who);
    }

    function removeBlackList(address _who) public onlySafe {
        isBlackListed[_who] = false;
        emit RemovedBlackList(_who);
    }

    modifier isNotBlackList(address _who) {
        require(!isBlackListed[_who], "You are already on the blacklist");
        _;
    }

    event DestroyedBlackFunds(address _who, uint256 _balance);

    event AddedBlackList(address _who);

    event RemovedBlackList(address _who);
}
