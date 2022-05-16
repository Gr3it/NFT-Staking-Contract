// SPDX-License-Identifier: MIT
// Author: Greit
// GitHub: https://github.com/Gr3it

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./RewardToken.sol";

pragma solidity ^0.8;

contract StakingRewards is Ownable {
    RewardToken public rewardsToken;
    IERC721 public NFTContract;

    uint256 public rewardRate = 100; // amount of token distributed each second
    uint256 public lastUpdateTime;
    uint256 public accRewardPerShare; // sum of reward rate divider by the total supply of NFTs staked at each time

    uint256 public totalSupply;

    struct User {
        uint256 rewardDebt;
        uint256 rewards;
        uint256 balance;
        uint256[] ownedIds;
    }

    mapping(address => User) public userInfo;

    event Staked(address indexed user, uint256[] indexed tokenId);
    event Unstake(address indexed user, uint256[] indexed tokenId);

    event RewardPaid(address indexed user, uint256 amount);

    constructor(address _NFTContract, address _rewardsToken) {
        NFTContract = IERC721(_NFTContract);
        rewardsToken = RewardToken(_rewardsToken);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[_owner].ownedIds;
    }

    function pendingRewards(address _user) external view returns (uint256) {
        User storage user = userInfo[_user];
        uint256 accRewardPerShareCurrent = accRewardPerShare;
        if (block.timestamp > lastUpdateTime && totalSupply != 0) {
            accRewardPerShareCurrent += ((rewardRate *
                (block.timestamp - lastUpdateTime) *
                1e18) / totalSupply);
        }
        return (((user.balance * (accRewardPerShareCurrent - user.rewardDebt)) /
            1e18) + user.rewards);
    }

    // Update reward variables of the given pool to be up-to-date. It is executed on stake, unstake
    modifier updateContract() {
        uint256 timestamp = block.timestamp;
        if (timestamp <= lastUpdateTime) {} else if (
            totalSupply == 0 || rewardRate == 0
        ) {
            lastUpdateTime = timestamp;
        } else {
            accRewardPerShare +=
                (rewardRate * (timestamp - lastUpdateTime) * 1e18) /
                totalSupply;
            lastUpdateTime = timestamp;
        }

        _;
    }

    // Update user rewards. It is executed on stake, unstake, getRewards
    modifier updateUserRewards() {
        User storage user = userInfo[msg.sender];
        user.rewards +=
            (user.balance * (accRewardPerShare - user.rewardDebt)) /
            1e18;
        user.rewardDebt = accRewardPerShare;

        _;
    }

    function stake(uint256 _id) external updateContract updateUserRewards {
        User storage user = userInfo[msg.sender];

        totalSupply++;
        user.balance++;
        user.ownedIds.push(_id);
        NFTContract.transferFrom(msg.sender, address(this), _id);

        emit Staked(msg.sender, singleToArray(_id));
    }

    function stakeMultiple(uint256[] calldata _ids)
        external
        updateContract
        updateUserRewards
    {
        User storage user = userInfo[msg.sender];
        uint256 length = _ids.length;

        totalSupply += length;
        user.balance += length;
        for (uint256 i; i < length; i++) {
            user.ownedIds.push(_ids[i]);
            NFTContract.transferFrom(msg.sender, address(this), _ids[i]);
        }
        emit Staked(msg.sender, _ids);
    }

    function unstake(uint256 _atIndex)
        external
        updateContract
        updateUserRewards
    {
        User storage user = userInfo[msg.sender];
        uint256 id = user.ownedIds[_atIndex];
        totalSupply--;
        user.balance--;
        user.ownedIds[_atIndex] = user.ownedIds[user.balance];
        NFTContract.transferFrom(address(this), msg.sender, id);
        user.ownedIds.pop();

        emit Unstake(msg.sender, singleToArray(id));
    }

    function unstakeAll() external updateContract updateUserRewards {
        User storage user = userInfo[msg.sender];
        uint256 balance = user.balance;
        totalSupply -= balance;
        user.balance = 0;
        for (uint256 i; i < balance; i++) {
            NFTContract.transferFrom(
                address(this),
                msg.sender,
                user.ownedIds[i]
            );
        }

        emit Unstake(msg.sender, user.ownedIds);
        delete user.ownedIds;
    }

    function getReward() external updateContract updateUserRewards {
        User storage user = userInfo[msg.sender];
        uint256 reward = user.rewards;
        user.rewards = 0;
        rewardsToken.mint(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function singleToArray(uint256 value)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = value;
        return array;
    }
}
