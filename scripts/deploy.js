async function main() {
  const [deployer] = await ethers.getSigners();

  const ContractNFT = await ethers.getContractFactory("NFT");
  const RewardTokenContract = await ethers.getContractFactory("RewardToken");
  const StakingContract = await ethers.getContractFactory("StakingRewards");

  console.log("\nDeploying NFT contracts with the account:", deployer.address);
  const contractNFT = await ContractNFT.deploy(5000, 2);
  console.log(`NFT contracts deployed at ${contractNFT.address}!\n`);

  console.log(
    "Deploying Reward Token contracts with the account:",
    deployer.address
  );
  const rewardTokenContract = await RewardTokenContract.deploy();
  console.log(
    `Reward Token contracts deployed at ${rewardTokenContract.address}!\n`
  );

  console.log(
    "Deploying Staking contracts with the account:",
    deployer.address
  );
  const stakingContract = await StakingContract.deploy(
    contractNFT.address,
    rewardTokenContract.address
  );
  console.log(`Staking contracts deployed at ${stakingContract.address}!\n`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
