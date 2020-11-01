pragma solidity >=0.5.0 <0.6.0;

contract BaseUsers {
    //
    function register(address _pid, address _who) external returns (bool);

    function setActive(address _who) external returns (bool);
    
    function setMiner(address _who) external returns (bool);

    function isActive(address _who) external view returns (bool);

    // Determine if the address has been registered
    function isRegister(address _who) external view returns (bool);

    // Get invitees
    function inviteUser(address _who) external view returns (address);

    function isBlackList(address _who) external view returns (bool);

    function getUser(address _who)
        external
        view
        returns (
            address id,
            address pid,
            bool miner,
            bool active,
            uint256 created_at
        );

}
