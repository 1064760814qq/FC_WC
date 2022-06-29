// SPDX-License-Identifier:MIT
pragma solidity ^0.8.1;
//接口就是用来让别的合约来调用的，方法名字和自己的合约里的函数名字一样，接口函数也可以很少，指定对应的就好

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IERC20.sol";



contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;   //每个地址对应拥有多少个代币
    mapping(address => mapping(address => uint256)) private _allowances;  //一个地址对另一个地址所持有多少代币的控制权限
    uint256 private _totalSupply;  //总供应量
    uint256 private _totalCirculation; //当前的流通量
    uint256 private _minTotalSupply;  //主要是为了burn判定
    string private _name; //代币的名称
    string private _symbol; //代币的符号
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function totalCirculation() public view virtual returns (uint256) {
        return _totalCirculation;
    }
    function balanceOf(address account)   //给一个地址，查询这个地址所持有这个合约代币的数量
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }
    function transfer(address to, uint256 amount)   //调用者给to地址转多少代币
        public
        virtual
        override
        returns (bool)
    {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender)  //查看owner对spender地址的控制代币的数量
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount)  //执行_approve
        public
        virtual
        override
        returns (bool)
    {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(          //带了From 谁转给谁多少代币
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue)  //增加msg.sender对spender控制的代币
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) //减少msg.sender对spender控制的代币
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(              //真实的转移函数,internal 表示只能这个合约中继承 才能用， 用接口或者底层调用是用不了的
        address from,
        address to,
        uint256 amount
    ) internal  {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }



    function _mint(address account, uint256 amount) internal virtual {   //造币函数,随意造币的函数，但是没有提供接口也没用public，所以合约一旦部署之后任何人无权限调用
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _totalCirculation += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount)   //销毁代币
        internal
        virtual
        returns (bool)
    {
        require(account != address(0), "ERC20: burn from the zero address");
        if (_totalCirculation > _minTotalSupply + amount) {
            _beforeTokenTransfer(account, address(0), amount);
            uint256 accountBalance = _balances[account];
            require(
                accountBalance >= amount,
                "ERC20: burn amount exceeds balance"
            );
            unchecked {
                _balances[account] = accountBalance - amount;
                _balances[address(0)] += amount;
            }
            _totalCirculation -= amount;
            emit Transfer(account, address(0), amount);
            _afterTokenTransfer(account, address(0), amount);
            return true;
        }
        return false;
    }
    function _approve(    //批准额度
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(    //减少批准额度
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    function _beforeTokenTransfer(  //为了以后一些操作，这里没用
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(  //为了以后一些操作，这里没用
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
}


contract FC is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
 


    event Withdraw(address user, uint256 amount);  //事件


    receive() external payable {}  //接受主币

    function withdraw() public onlyOwner {  //提取主币
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(IERC20 token) public onlyOwner {  //提取某个打入进来的ERC20代币
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function burn(uint256 amount) public virtual { //销毁
        super._burn(_msgSender(), amount);
    }


    constructor() ERC20("FC", "FC") {   //铸造给合约部署者60亿代币，上限就是60亿
        _mint(owner(), 60 *10**8 * 10**decimals());
    }

    function BatchTransfer(address[] memory accounts, uint256[] memory amounts)  //部署者批量转让代币
        public
        onlyOwner
    {
        require(accounts.length == amounts.length,"length is invalid");
        for (uint256 index = 0; index < accounts.length; index++) {
            super._transfer(address(this), accounts[index],amounts[index]);
        }
    }


}