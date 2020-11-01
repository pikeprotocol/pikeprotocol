pragma solidity >=0.5.0 <0.6.0;

import "./pike/BaseBank.sol";
import "./library/Interfaces.sol";

contract Bank is BaseBank, Interfaces {
    bool internal open_deposit = true;
    bool internal open_loan = true;

    modifier isNotBlackList(address _who) {
        require(
            !UserContract.isBlackList(_who),
            "You are already on the blacklist"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!PauseContract.isPaused(), "Data is being maintained");
        _;
    }

    function() external payable {
        revert();
    }

    function isRegister(address _who) public view returns (bool is_register) {
        return UserContract.isRegister(_who);
    }

    function isActive(address _who) public view returns (bool is_active) {
        return UserContract.isActive(_who);
    }

    // register
    function register(address _pid) public returns (bool) {
        if (UserContract.register(_pid, msg.sender)) {
            if (!NetContract.register(_pid, msg.sender)) {
                revert("register failed");
            }
            return true;
        }
        return false;
    }

    // active user
    function activeUser(address _pid)
        public
        payable
        whenNotPaused
        isNotBlackList(msg.sender)
    {
        require(msg.sender != _pid);
        if (!isRegister(msg.sender)) {
            UserContract.register(_pid, msg.sender);
        }
        if (address(uint160(address(FundsContract))).send(msg.value)) {
            require(FundsContract.activeUser(msg.sender, msg.value));
            UserContract.setActive(msg.sender);
            if (!NetContract.activeUser(_pid, msg.sender, msg.value)) {
                revert("upgrade failed");
            }
        }
    }

    // 升级矿工
    function upgradeUser()
        public
        payable
        whenNotPaused
        isNotBlackList(msg.sender)
    {
        require(isActive(msg.sender));
        if (address(uint160(address(FundsContract))).send(msg.value)) {
            require(FundsContract.upgradeUser(msg.sender, msg.value));
            if (!NetContract.upgradeUser(msg.sender, msg.value)) {
                revert("upgrade failed");
            }
        }
    }

    // buy mining
    function buyMiner()
        public
        payable
        whenNotPaused
        isNotBlackList(msg.sender)
    {
        require(isActive(msg.sender));
        if (address(uint160(address(FundsContract))).send(msg.value)) {
            require(FundsContract.buyMiner(msg.sender, msg.value));
            UserContract.setMiner(msg.sender);
            if (!NetContract.buyMiner(msg.sender, msg.value)) {
                revert("buy mining failed");
            }
        }
    }

    // deposit
    function deposit(address _tokenAddress, uint256 _tokens)
        public
        payable
        whenNotPaused
        isNotBlackList(msg.sender)
    {
        require(open_deposit == true);
        require(isActive(msg.sender));

        if (address(FundsContract) == _tokenAddress) {
            if (address(uint160(address(FundsContract))).send(msg.value)) {
                require(
                    FundsContract.deposit(_tokenAddress, msg.sender, msg.value)
                );
                if (
                    !NetContract.deposit(_tokenAddress, msg.sender, msg.value)
                ) {
                    revert("deposit failed");
                }
            }
        } else {
            require(FundsContract.deposit(_tokenAddress, msg.sender, _tokens));
            if (!NetContract.deposit(_tokenAddress, msg.sender, _tokens)) {
                revert("deposit failed");
            }
        }
    }

    // Tokens withdraw
    function withdraw(
        address _tokenAddress,
        address _who,
        uint256 _tokens
    )
        public
        whenNotPaused
        isNotBlackList(_who)
        onlySafe
        returns (bool success)
    {
        require(isActive(_who));
        return FundsContract.withdraw(_tokenAddress, _who, _tokens);
    }

    // loan
    function loan(
        address _tokenAddress,
        address _who,
        uint256 _tokens
    )
        public
        whenNotPaused
        isNotBlackList(_who)
        onlySafe
        returns (bool success)
    {
        require(open_loan == true);
        require(isActive(_who));
        return FundsContract.loan(_tokenAddress, _who, _tokens);
    }

    // repay
    function repay(address _tokenAddress, uint256 _tokens)
        public
        payable
        whenNotPaused
        isNotBlackList(msg.sender)
    {
        if (address(FundsContract) == _tokenAddress) {
            if (address(uint160(address(FundsContract))).send(msg.value)) {
                require(
                    FundsContract.repay(_tokenAddress, msg.sender, msg.value)
                );
                if (!NetContract.repay(_tokenAddress, msg.sender, msg.value)) {
                    revert("repay failed");
                }
            }
        } else {
            require(FundsContract.repay(_tokenAddress, msg.sender, _tokens));
            if (!NetContract.repay(_tokenAddress, msg.sender, _tokens)) {
                revert("repay failed");
            }
        }
    }

    // liquidate
    function liquidate(
        address _tokenAddress,
        address _owner,
        uint256 _tokens,
        uint256 _oid
    ) public payable whenNotPaused isNotBlackList(msg.sender) {
        require(isActive(_owner));
        require(isActive(msg.sender));
        if (address(FundsContract) == _tokenAddress) {
            if (address(uint160(address(FundsContract))).send(msg.value)) {
                require(
                    FundsContract.liquidate(
                        _tokenAddress,
                        msg.sender,
                        _owner,
                        msg.value
                    )
                );
                if (
                    !NetContract.liquidate(
                        _tokenAddress,
                        msg.sender,
                        msg.value,
                        _oid
                    )
                ) {
                    revert("liquidate failed");
                }
            }
        } else {
            require(
                FundsContract.liquidate(
                    _tokenAddress,
                    msg.sender,
                    _owner,
                    _tokens
                )
            );
            if (
                !NetContract.liquidate(_tokenAddress, msg.sender, _tokens, _oid)
            ) {
                revert("liquidate failed");
            }
        }
    }

    function setOpenDeposit(bool _status) public onlySafe {
        open_deposit = _status;
    }

    function setOpenLoan(bool _status) public onlySafe {
        open_loan = _status;
    }

    function getOpenDeposit() public view returns (bool deposit_status) {
        return open_deposit;
    }

    function getOpenLoan() public view returns (bool loan_status) {
        return open_loan;
    }

    // 获取存款余额
    function balanceOf(address _tokenAddress, address _who)
        public
        view
        returns (uint256 balance)
    {
        return ERC20Yes(_tokenAddress).balanceOf(_who);
    }

    function balanceEth(address _tokenAddress)
        public
        view
        returns (uint256 balance)
    {
        return address(uint160(address(_tokenAddress))).balance;
    }

    function isPaused() public view returns (bool paused) {
        return PauseContract.isPaused();
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
        return UserContract.getUser(_who);
    }

    function getActive(address _who) public view returns (uint256 amount) {
        return ReceiptContract.getActive(_who);
    }

    function getUpgrade(address _who) public view returns (uint256 amount) {
        return ReceiptContract.getUpgrade(_who);
    }

    function getMiner(address _who) public view returns (uint256 amount) {
        return ReceiptContract.getMiner(_who);
    }
}
