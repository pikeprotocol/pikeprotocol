pragma solidity >=0.5.0 <0.6.0;

import "./BaseUsers.sol";
import "./BlackList.sol";
import "../library/Interfaces.sol";

contract Users is BaseUsers, BlackList, Interfaces {
    struct user {
        address id;
        address pid;
        bool miner;
        bool active;
        uint256 created_at;
    }

    mapping(address => user) internal users;

    bool internal empty = true;

    event Register(address who, address inviter);

    modifier safeSender() {
        require(address(BankContract) == msg.sender);
        _;
    }

    // constructor() public {
    //     users[msg.sender].id = msg.sender;
    //     users[msg.sender].pid = address(0);
    //     users[msg.sender].active = true;
    //     users[msg.sender].created_at = now;
    // }

    function register(address _pid, address _who)
        public
        safeSender
        returns (bool success)
    {
        require(!isRegister(_who), "account already exists");
        if (empty == false) {
            require(isRegister(_pid), "account not already exists");
        }

        users[_who].id = _who;
        users[_who].pid = _pid;
        users[_who].created_at = now;
        emit Register(_who, _pid);
        if (empty == true) {
            users[_who].active = true;
            empty = false;
        }
        return true;
    }

    function setActive(address _who) public safeSender returns (bool success) {
        users[_who].active = true;
        return true;
    }

    function setMiner(address _who) public safeSender returns (bool success) {
        users[_who].miner = true;
        return true;
    }

    function isActive(address _who) public view returns (bool success) {
        return users[_who].active;
    }

    function inviteUser(address _who) public view returns (address pid) {
        return users[_who].pid;
    }

    function isRegister(address _who) public view returns (bool success) {
        if (users[_who].id == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    function isBlackList(address _who) public view returns (bool) {
        return isBlackListed[_who];
    }

    function getUser(address _who)
        public
        view
        returns (
            address id,
            address pid,
            bool miner,
            bool active,
            uint256 created_at
        )
    {
        address _id = _who;
        return (
            users[_id].id,
            users[_id].pid,
            users[_id].miner,
            users[_id].active,
            users[_id].created_at
        );
    }
}
