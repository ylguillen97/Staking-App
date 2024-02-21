// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//  FUNCTIONS
//  Stake: Lock tokens into our smart contact
//  withdraw: unlock tokens and pull out of the contract
//  claimReward: users get their reward tokens
// What's a good reward mechanism?
// What's sk e good reward math?

error Staking_TransferFailed();
error Staking_NeedsMoreThanZero();

contract Staking {

    IERC20 public s_stakingToken; //ERC20
    IERC20 public s_rewardsToken;

    //address -> how much they stake
    mapping (address => uint256) public s_balances;
    mapping (address => uint256) public s_rewards;
    mapping (address => uint256) public s_userRewardPerTokenPaid;

    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;

    uint256 public constant REWARD_RATE = 100; // 100 tokens / second

    modifier updateReward (address account) {
        //how much reward per token?
        //last timestamp
        // 12- 1, user earnd X tokens
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if(amount == 0) {
            revert Staking_NeedsMoreThanZero();
        }
        _;
    }

    constructor (address stakingToken, address rewardToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardsToken = IERC20(rewardToken);
        s_totalSupply=0;
    }

    function earned(address account) public view  returns (uint256) {
        uint256 currentBalance = s_balances[account];
        // how much they have been paid already
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();

        uint256 pastRewards = s_rewards[account];

        uint256 totalEarned = ((currentBalance * (currentRewardPerToken - amountPaid))/1e18) + pastRewards;

        return totalEarned;
    }

    //Based on how long it`s been during this most recent snapshot
    function rewardPerToken() public view returns(uint256) {
        if(s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }
        return s_rewardPerTokenStored + 
        (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18)/s_totalSupply);
    }

    // do we allow any tokens? 
    // or just a specific token? -> SPECIFIC TOKEN -> address in the constructor
    function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount){
        //keep track of how much this user has staked
        //keep track of how much token we have total
        //transfer the tokens to this contract

        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply = s_totalSupply+amount;

        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        if(!success) {
            revert Staking_TransferFailed();
        }

    }

    function withdraw(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {

        s_balances[msg.sender] = s_balances[msg.sender]-amount;
        s_totalSupply = s_totalSupply - amount;
        
        bool success = s_stakingToken.transfer(msg.sender, amount);

        if (!success) {
            revert Staking_TransferFailed();
        }
    }

        /* How much reward do they get?
        The contract is going to emit X tokens per second and disperse them to all token stakers
        100 reward tokens / second
        staked: 50 staked tokens, 20 staked tokens, 30 staked tokens
        rewards: 50 reward tokens, 20 reward tokens, 30 reward tokens

        staked: 100 staked tokens, 50 staked tokens, 30 staked tokens, 20 staked tokens (total = 200)
        rewards: 50 reward tokens, 25 reward tokens, 15 reward tokens, 10 reward tokens

        the more tokens staked, the less rewards they get -> track timestamp 

        why not 1 to 1? - bankupt your protocol*/

    function claimReward() external updateReward(msg.sender) {
        uint256 reward = s_rewards[msg.sender];
        bool success = s_rewardsToken.transfer(msg.sender, reward);

        if(!success) {
            revert Staking_TransferFailed();
        }
    }
}
