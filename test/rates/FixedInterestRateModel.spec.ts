import { expect } from "chai";
import { ethers, network } from "hardhat";

import { FixedInterestRateModel } from "../../typechain";

import { FixedPoint } from "../helpers/FixedPoint.ts";

describe("FixedInterestRateModel", function () {
  const FIXED_INTEREST_RATE = FixedPoint.normalizeRate("0.02");

  let interestRateModel: FixedInterestRateModel;
  let snapshotId: string;

  before("deploy fixture", async () => {
    const fixedInterestRateModelFactory = await ethers.getContractFactory("FixedInterestRateModel");
    const testProxyFactory = await ethers.getContractFactory("TestProxy");

    const interestRateModelImpl = await fixedInterestRateModelFactory.deploy();
    await interestRateModelImpl.deployed();

    const proxy = await testProxyFactory.deploy(
      interestRateModelImpl.address,
      interestRateModelImpl.interface.encodeFunctionData("initialize", [
        ethers.utils.defaultAbiCoder.encode(["uint256"], [FIXED_INTEREST_RATE]),
      ])
    );
    await proxy.deployed();

    interestRateModel = (await ethers.getContractAt("FixedInterestRateModel", proxy.address)) as FixedInterestRateModel;
  });

  beforeEach("snapshot blockchain", async () => {
    snapshotId = await network.provider.send("evm_snapshot", []);
  });

  afterEach("restore blockchain snapshot", async () => {
    await network.provider.send("evm_revert", [snapshotId]);
  });

  describe("constants", async function () {
    it("matches expected name", async function () {
      expect(await interestRateModel.name()).to.equal("FixedInterestRateModel");
    });
  });

  describe("rate", async function () {
    it("returns correct rate", async function () {
      expect(await interestRateModel.rate()).to.equal(FIXED_INTEREST_RATE);
    });
  });

  describe("distribute", async function () {
    it("distributes interest", async function () {
      /* Distribute to one node */
      let sources = [
        {
          depth: FixedPoint.from("15"),
          available: FixedPoint.from("10"),
          used: FixedPoint.from("10"),
          pending: FixedPoint.Zero,
        },
      ];
      let distribution = await interestRateModel.distribute(FixedPoint.from("1"), sources, sources.length);
      expect(distribution.length).to.equal(1);
      expect(distribution[0]).to.equal(FixedPoint.from("1"));

      /* Distribute to four nodes */
      sources = [
        {
          depth: FixedPoint.from("1"),
          available: FixedPoint.from("29"),
          used: FixedPoint.from("1"),
          pending: FixedPoint.Zero,
        },
        {
          depth: FixedPoint.from("5"),
          available: FixedPoint.from("16"),
          used: FixedPoint.from("4"),
          pending: FixedPoint.Zero,
        },
        {
          depth: FixedPoint.from("10"),
          available: FixedPoint.from("5"),
          used: FixedPoint.from("5"),
          pending: FixedPoint.Zero,
        },
        {
          depth: FixedPoint.from("15"),
          available: FixedPoint.from("3"),
          used: FixedPoint.from("2"),
          pending: FixedPoint.Zero,
        },
      ];
      distribution = await interestRateModel.distribute(ethers.utils.parseEther("2"), sources, sources.length);
      expect(distribution.length).to.equal(4);
      expect(distribution[0]).to.equal(FixedPoint.from("0.5"));
      expect(distribution[1]).to.equal(FixedPoint.from("0.5"));
      expect(distribution[2]).to.equal(FixedPoint.from("0.5"));
      expect(distribution[3]).to.equal(FixedPoint.from("0.5"));
    });
  });
});