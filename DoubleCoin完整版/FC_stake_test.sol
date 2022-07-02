// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IERC20.sol";





contract FC_stake is  Ownable {
    using SafeMath for uint256;
    using Address for address;
    IERC20 private _FC = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);

    

    event Relieve(address user , uint256 reward);
    event Withdraw(address user, uint256 amount);
  

   
    receive() external payable {}
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
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
    }   //这个是指向FC代币合约，用接口转FC代币

    function decimals() public pure  returns (uint8) {
        return 18;
    }
    


    struct UserInfo {
        uint256 lockDays;   //锁仓时间，全部按每个月30天算
        uint256 lastTime;   //就是给用户设置锁仓的 当时的时间，在这个基础上+锁仓时间 就是释放时间
        uint256 store_time;    // 存储的时间，比如 7月5号  质押了， 8月15 号释放上个月的， 那么就多出来10天， 他再9月15号之前都是不能释放的， 如果是10月4号的话，会再给一个月的，但是如果是10月5号的话（减去7月5号），在8月15已经给了一个月的了，就会给2个月的奖励了。
        uint256 amount;    //事件
        uint256 storage_getreward; //可以获得奖励
        uint256 _lastRewardTime;   //倒数第二次获取奖励的时间，按当前时间要获取为倒数第一次来说，这就是标志倒数第二次获取奖励的时间了
        uint256 _rewardPerMonth;   //每个用户每个月可以获取的代币数量
        uint256 _endRewardTime;    //最后倒数第一次获取的时间，一般都是现在的时间为 block.timestemp
        uint256 _left_balance;     //给用户存的总奖励，超过这个是没有的
        uint256 _endTime;          //到期可以获取奖励的时间

    }

    mapping(address => UserInfo) public userInfos;

    function every_months_time() public pure returns(uint256){
        return 86400*30;
    }


    uint256 public now1_time = block.timestamp;

    function set_now_time(uint256 _nowtime) public {
        now1_time = _nowtime;
    }

/*
     function relieve_for_user() public {
        UserInfo storage user = userInfos[msg.sender];
        userInfos[msg.sender]._endRewardTime = now_time;  //领取代币的时间肯定是现在的
        uint256 reward = get_reward(); //获取这个用户代币奖励
       
            //uint256 relieveTime = user.lastTime.add(user.lockDays * 86400 + every_months_time()); //只仅仅判断锁仓时间,比如7月1号解锁，但是要加上一个月时间，8月1号才能获取相应的奖励
            uint256 relieveTime = user._endTime;
            require(now_time > relieveTime, "Fail: Locking");
            require((reward > 0) && (user._left_balance > 0),"No reward or Fund not enough");
            if(reward > user._left_balance ){
                reward = user._left_balance;
            }
            _FC.transferFrom(address(this),msg.sender, reward);
            user._left_balance =  user._left_balance.sub(reward);
        
            emit Relieve(msg.sender, reward);
        
        }*/
    
    uint256 public relieveTime;



    function Relie() public {
        UserInfo storage user = userInfos[msg.sender];
        user._endRewardTime = now1_time;  //领取代币的时间肯定是现在的
        relieveTime = user._endTime;
        uint256 reward = get_reward(); //获取这个用户代币奖励
            //uint256 relieveTime = user.lastTime.add(user.lockDays * 86400 + every_months_time()); //只仅仅判断锁仓时间,比如7月1号解锁，但是要加上一个月时间，8月1号才能获取相应的奖励
            
            require(now1_time > relieveTime, "Fail: Locking");
            require((reward > 0) && (user._left_balance > 0),"No reward or Fund not enough");
            if(reward > user._left_balance ){
                reward = user._left_balance;
            }
            _FC.transferFrom(address(this),msg.sender, reward);
            user._left_balance =  user._left_balance.sub(reward);
        
            emit Relieve(msg.sender, reward);
        
        }

    function balance_of_this() public view  returns(uint256){
        return(_FC.balanceOf(address(this)));
    }


    function set_lock_for(address account,uint256 _lockDays, uint256 _rewardPerMonth, uint256 _left_balance) 
    external
    onlyOwner
    {
         UserInfo storage user = userInfos[account];
         require(_lockDays >= 30,"Not meeting the pledge time");//至少质押30天
         user.lockDays = _lockDays;
         user._rewardPerMonth = _rewardPerMonth *10 **decimals();  //每月给几个代币,最少一个
        user._lastRewardTime =  now1_time.add((user.lockDays * 86400).sub(every_months_time()));
         user._left_balance = _left_balance  *10 **decimals();
         user._endTime = now1_time.add(user.lockDays * 86400 );
    }


    function set_info(address account, uint256 _endtime) public {
        UserInfo storage user = userInfos[account];
        user._endTime = _endtime;
    }

 

    function get_reward() public returns(uint256) {


        if (now1_time <= userInfos[msg.sender]._endTime) {
            return 0;
        }
        uint256 month_s = get_months();
        userInfos[msg.sender].store_time = (userInfos[msg.sender]._endRewardTime.sub(userInfos[msg.sender]._lastRewardTime)).sub(month_s*every_months_time());
        userInfos[msg.sender].storage_getreward = month_s.mul(userInfos[msg.sender]._rewardPerMonth);
        userInfos[msg.sender]._lastRewardTime = now1_time;
        userInfos[msg.sender]._endTime = (now1_time).add((every_months_time().sub(userInfos[msg.sender].store_time)));  //比如8月15号领了，那么下个月9月5号还可以领,下次可以释放时间为 当前的时间+30天的时间-（8.15-8.5）的时间
        
        return userInfos[msg.sender].storage_getreward;

    }
    function get_months() public  view returns (uint256) {
        if (userInfos[msg.sender]._endTime <= now1_time) {
            uint256 month_s = ((now1_time.add(userInfos[msg.sender].store_time)).sub(userInfos[msg.sender]._lastRewardTime)).div(every_months_time());
            require(month_s >= 1, "Not arrived for a month");
            return month_s;
        } else {
            return 0;
        }
    }





}