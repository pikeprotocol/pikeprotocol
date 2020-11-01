pragma solidity >=0.5.0 <0.6.0;

import "./BasePause.sol";
import "../library/Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pause is Ownable, BasePause {
    event Paused();
    event Unpaused();

    bool public _paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlySafe whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlySafe whenPaused {
        _paused = false;
        emit Unpaused();
    }

    function isPaused() public view returns (bool paused) {
        return _paused;
    }
}
