// SPDX-License-Identifier:MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IERC20.sol";



contract FC_stake is  Ownable {
    using SafeMath for uint256;
    using Address for address;
    IERC20 private _FC;


    event Relieve(address user , uint256 reward);
    event Withdraw(address user, uint256 amount);
  

    receive() external payable {}


    function withdrawToken(IERC20 token) public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdrawBNB() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setToken(
        address FC
    ) public onlyOwner {
        _FC = IERC20(FC);
    }  

    function decimals() public pure returns (uint8) {
        return 18;
    }

    
    struct UserInfo {
        uint256 lockDays;   
        uint256 lastTime;   
        uint256 store_time;    
        uint256 amount;    
        uint256 storage_getreward; 
        uint256 _lastRewardTime;  
        uint256 _rewardPerMonth;   
        uint256 _endRewardTime;    
        uint256 _left_balance;     
        uint256 _endTime;          

    }

    mapping(address => UserInfo) public userInfos;


    function every_months_time() public pure returns(uint256){
        return 86400 * 30;
    }


    function relieve() public {
        UserInfo storage user = userInfos[msg.sender];
        userInfos[msg.sender]._endRewardTime = block.timestamp;  
        uint256 relieveTime = user._endTime;
        uint256 reward = get_reward(); 
       
        require(block.timestamp > relieveTime, "Fail: Locking");
        require((reward > 0) && (user._left_balance > 0),"No reward or Fund not enough");
        if(reward > user._left_balance ){
            reward = user._left_balance;
        }
        _FC.transferFrom(address(this),msg.sender, reward);
        user._left_balance =  user._left_balance.sub(reward);
        
        emit Relieve(msg.sender, reward);
        
    }
    

    function set_lock(address account,uint256 _lockDays, uint256 _rewardPerMonth, uint256 _left_balance) 
    external
    onlyOwner
    {
         UserInfo storage user = userInfos[account];
         require(_lockDays >= 30,"Not meeting the pledge time");
         user.lockDays = _lockDays;
         user._rewardPerMonth = _rewardPerMonth *10 **decimals();  
         user.lastTime = block.timestamp;   
         user._lastRewardTime =  block.timestamp.add((user.lockDays * 86400).sub(every_months_time()));
         user._left_balance = _left_balance  *10 **decimals();
         user._endTime = block.timestamp.add(user.lockDays * 86400 );
    }


    function get_reward() private returns(uint256) {

        if (block.timestamp <= userInfos[msg.sender]._endTime) {
            return 0;
        }
        uint256 month_s = get_months();
        userInfos[msg.sender].storage_getreward = month_s.mul(userInfos[msg.sender]._rewardPerMonth);
        userInfos[msg.sender].store_time = (userInfos[msg.sender]._endRewardTime.sub(userInfos[msg.sender]._lastRewardTime)).sub(month_s*every_months_time());
        userInfos[msg.sender]._lastRewardTime = block.timestamp;
        userInfos[msg.sender]._endTime = (block.timestamp).add((every_months_time().sub(userInfos[msg.sender].store_time)));  
        
        return userInfos[msg.sender].storage_getreward;

    }


    function get_months() private view returns (uint256) {
        if (userInfos[msg.sender]._endTime <= block.timestamp) {
            uint256 month_s = ((userInfos[msg.sender]._endRewardTime.add(userInfos[msg.sender].store_time)).sub(userInfos[msg.sender]._lastRewardTime)).div(every_months_time());
            require(month_s >= 1, "Not arrived for a month");
            return month_s;
        } else {
            return 0;
        }
    }

}