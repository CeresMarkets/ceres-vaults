const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("TimelockedGovernor", function () {
    async function deployTimelock(minDelay = 2 * 3600) {
        const [admin, proposer, executor] = await ethers.getSigners();
        const Factory = await ethers.getContractFactory("TimelockedGovernor");
        const gov = await Factory.deploy(
            minDelay,
            [proposer.address],
            [executor.address],
            admin.address
        );
        await gov.waitForDeployment();
        return { gov, admin, proposer, executor, minDelay };
    }

    describe("bounds validation", function () {
        it("accepts a delay within [MIN, MAX]", async function () {
            const { gov, minDelay } = await deployTimelock(2 * 3600);
            expect(await gov.getMinDelay()).to.equal(BigInt(minDelay));
        });

        it("rejects a delay below MIN_DELAY_SECONDS", async function () {
            const [admin, proposer, executor] = await ethers.getSigners();
            const Factory = await ethers.getContractFactory("TimelockedGovernor");
            await expect(
                Factory.deploy(60, [proposer.address], [executor.address], admin.address)
            ).to.be.revertedWithCustomError(Factory, "BelowMinimum");
        });

        it("rejects a delay above MAX_DELAY_SECONDS", async function () {
            const [admin, proposer, executor] = await ethers.getSigners();
            const Factory = await ethers.getContractFactory("TimelockedGovernor");
            await expect(
                Factory.deploy(60 * 24 * 3600, [proposer.address], [executor.address], admin.address)
            ).to.be.revertedWithCustomError(Factory, "AboveMaximum");
        });
    });

    describe("role wiring", function () {
        it("proposer holds PROPOSER_ROLE", async function () {
            const { gov, proposer } = await deployTimelock();
            const PROPOSER_ROLE = await gov.PROPOSER_ROLE();
            expect(await gov.hasRole(PROPOSER_ROLE, proposer.address)).to.equal(true);
        });

        it("executor holds EXECUTOR_ROLE", async function () {
            const { gov, executor } = await deployTimelock();
            const EXECUTOR_ROLE = await gov.EXECUTOR_ROLE();
            expect(await gov.hasRole(EXECUTOR_ROLE, executor.address)).to.equal(true);
        });
    });

    describe("scheduled operation lifecycle", function () {
        it("schedules, waits, and executes a call", async function () {
            const { gov, proposer, executor, minDelay } = await deployTimelock(2 * 3600);

            // Prepare a trivial call: have the timelock update its own min delay.
            const newDelay = 3 * 3600;
            const target = await gov.getAddress();
            const value = 0n;
            const data = gov.interface.encodeFunctionData("updateDelay", [newDelay]);
            const predecessor = ethers.ZeroHash;
            const salt = ethers.ZeroHash;

            await gov
                .connect(proposer)
                .schedule(target, value, data, predecessor, salt, minDelay);

            // Cannot execute before the delay elapses.
            await expect(
                gov.connect(executor).execute(target, value, data, predecessor, salt)
            ).to.be.reverted;

            await time.increase(minDelay + 1);

            await gov.connect(executor).execute(target, value, data, predecessor, salt);
            expect(await gov.getMinDelay()).to.equal(BigInt(newDelay));
        });

        it("cancels a pending operation", async function () {
            const { gov, proposer, minDelay } = await deployTimelock();

            const target = await gov.getAddress();
            const data = gov.interface.encodeFunctionData("updateDelay", [3 * 3600]);
            const predecessor = ethers.ZeroHash;
            const salt = ethers.ZeroHash;

            await gov
                .connect(proposer)
                .schedule(target, 0n, data, predecessor, salt, minDelay);

            const opId = await gov.hashOperation(target, 0n, data, predecessor, salt);
            expect(await gov.isOperationPending(opId)).to.equal(true);

            // The proposer role is also granted CANCELLER_ROLE by OZ default.
            await gov.connect(proposer).cancel(opId);
            expect(await gov.isOperationPending(opId)).to.equal(false);
        });
    });

    describe("public execution", function () {
        it("allows any address to execute when executors include address(0)", async function () {
            const [admin, proposer, someone] = await ethers.getSigners();
            const Factory = await ethers.getContractFactory("TimelockedGovernor");
            const gov = await Factory.deploy(
                3600,
                [proposer.address],
                [ethers.ZeroAddress], // public execution
                admin.address
            );
            await gov.waitForDeployment();

            const target = await gov.getAddress();
            const data = gov.interface.encodeFunctionData("updateDelay", [4 * 3600]);
            const predecessor = ethers.ZeroHash;
            const salt = ethers.ZeroHash;

            await gov.connect(proposer).schedule(target, 0n, data, predecessor, salt, 3600);
            await time.increase(3601);
            // Any signer can execute.
            await gov.connect(someone).execute(target, 0n, data, predecessor, salt);
            expect(await gov.getMinDelay()).to.equal(BigInt(4 * 3600));
        });
    });
});
