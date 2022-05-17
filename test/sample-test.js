const { expect } = require("chai");
const { ethers } = require("hardhat");

let owner;
let stakingContract;
let contractNFT;
let rewardTokenContract;
let ids, arrayIDs;

describe("Staking Contract:", function () {
  it("Should deploy contracts", async () => {
    [owner] = await ethers.getSigners();
    const ContractNFT = await ethers.getContractFactory("NFT");
    const RewardTokenContract = await ethers.getContractFactory("RewardToken");
    const StakingContract = await ethers.getContractFactory("StakingRewards");

    contractNFT = await ContractNFT.deploy(5000, 5);
    rewardTokenContract = await RewardTokenContract.deploy();
    stakingContract = await StakingContract.deploy(
      contractNFT.address,
      rewardTokenContract.address
    );

    const role = await rewardTokenContract.MINTER_ROLE();

    await rewardTokenContract.grantRole(role, stakingContract.address);
  });
  it("Should stake NFTs", async function () {
    await contractNFT.MintToken(5);
    await contractNFT.setApprovalForAll(stakingContract.address, true);

    await stakingContract.stake(1);

    arrayIDs = [];
    IDs = await stakingContract.walletOfOwner(owner.getAddress());
    for (let i = 0; i < IDs.length; i++) {
      arrayIDs[i] = IDs[i].toNumber();
    }

    expect(arrayIDs).to.be.deep.equal([1]);

    await stakingContract.stakeMultiple([2, 3, 4, 5]);

    arrayIDs = [];
    IDs = await stakingContract.walletOfOwner(owner.getAddress());
    for (let i = 0; i < IDs.length; i++) {
      arrayIDs[i] = IDs[i].toNumber();
    }

    expect(arrayIDs).to.be.deep.equal([1, 2, 3, 4, 5]);
  });

  it("Should unstake NFTs", async () => {
    await stakingContract.unstake(2);

    arrayIDs = [];
    IDs = await stakingContract.walletOfOwner(owner.getAddress());
    for (let i = 0; i < IDs.length; i++) {
      arrayIDs[i] = IDs[i].toNumber();
    }

    expect(arrayIDs).to.be.deep.equal([1, 2, 5, 4]);

    await stakingContract.unstakeAll();

    arrayIDs = [];
    IDs = await stakingContract.walletOfOwner(owner.getAddress());
    for (let i = 0; i < IDs.length; i++) {
      arrayIDs[i] = IDs[i].toNumber();
    }

    expect(arrayIDs).to.be.empty;
  });

  it("Should harvest rewards", async () => {
    const balance = await rewardTokenContract.balanceOf(owner.getAddress());

    await stakingContract.getReward();

    expect(await rewardTokenContract.balanceOf(owner.getAddress())).to.be.above(
      balance
    );
  });
});
