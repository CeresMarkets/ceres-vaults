const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

async function deployRegistryFixture(initialMode = 0) {
    const [admin, listManager, alice, bob, carol] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("AccessRegistry");
    const registry = await upgrades.deployProxy(
        Factory,
        [admin.address, listManager.address, initialMode],
        { kind: "uups", initializer: "initialize" }
    );
    await registry.waitForDeployment();
    return { registry, admin, listManager, alice, bob, carol };
}

describe("AccessRegistry", function () {
    describe("initialization", function () {
        it("initializes with the requested mode and grants roles", async function () {
            const { registry, admin, listManager } = await deployRegistryFixture(1);
            expect(await registry.getMode()).to.equal(1n);
            const DEFAULT_ADMIN_ROLE = await registry.DEFAULT_ADMIN_ROLE();
            const LIST_MANAGER_ROLE = await registry.LIST_MANAGER_ROLE();
            expect(await registry.hasRole(DEFAULT_ADMIN_ROLE, admin.address)).to.equal(true);
            expect(await registry.hasRole(LIST_MANAGER_ROLE, listManager.address)).to.equal(true);
        });

        it("rejects zero addresses at init", async function () {
            const Factory = await ethers.getContractFactory("AccessRegistry");
            await expect(
                upgrades.deployProxy(Factory, [ethers.ZeroAddress, ethers.ZeroAddress, 0], {
                    kind: "uups",
                    initializer: "initialize",
                })
            ).to.be.reverted;
        });
    });

    describe("Open mode", function () {
        it("allows all addresses by default", async function () {
            const { registry, alice, bob } = await deployRegistryFixture(0);
            expect(await registry.isAllowed(alice.address)).to.equal(true);
            expect(await registry.isAllowed(bob.address)).to.equal(true);
        });

        it("explicit block overrides open default", async function () {
            const { registry, listManager, alice } = await deployRegistryFixture(0);
            await registry.connect(listManager).setBlocked(alice.address, true);
            expect(await registry.isAllowed(alice.address)).to.equal(false);
        });
    });

    describe("Allowlist mode", function () {
        it("denies by default, allows explicit entries", async function () {
            const { registry, listManager, alice, bob } = await deployRegistryFixture(1);
            expect(await registry.isAllowed(alice.address)).to.equal(false);
            await registry.connect(listManager).setAllowed(alice.address, true);
            expect(await registry.isAllowed(alice.address)).to.equal(true);
            expect(await registry.isAllowed(bob.address)).to.equal(false);
        });

        it("block override wins over allow", async function () {
            const { registry, listManager, alice } = await deployRegistryFixture(1);
            await registry.connect(listManager).setAllowed(alice.address, true);
            await registry.connect(listManager).setBlocked(alice.address, true);
            expect(await registry.isAllowed(alice.address)).to.equal(false);
        });
    });

    describe("Blocklist mode", function () {
        it("allows by default, denies explicit blocks", async function () {
            const { registry, listManager, alice, bob } = await deployRegistryFixture(2);
            expect(await registry.isAllowed(alice.address)).to.equal(true);
            await registry.connect(listManager).setBlocked(alice.address, true);
            expect(await registry.isAllowed(alice.address)).to.equal(false);
            expect(await registry.isAllowed(bob.address)).to.equal(true);
        });
    });

    describe("mode changes", function () {
        it("admin can flip modes", async function () {
            const { registry, admin } = await deployRegistryFixture(0);
            await registry.connect(admin).setMode(1);
            expect(await registry.getMode()).to.equal(1n);
            await registry.connect(admin).setMode(2);
            expect(await registry.getMode()).to.equal(2n);
        });

        it("non-admin cannot flip modes", async function () {
            const { registry, alice } = await deployRegistryFixture(0);
            await expect(registry.connect(alice).setMode(1)).to.be.reverted;
        });
    });

    describe("batch operations", function () {
        it("setAllowedBatch flips multiple addresses at once", async function () {
            const { registry, listManager, alice, bob, carol } = await deployRegistryFixture(1);
            await registry.connect(listManager).setAllowedBatch([alice.address, bob.address, carol.address], true);
            expect(await registry.isAllowed(alice.address)).to.equal(true);
            expect(await registry.isAllowed(bob.address)).to.equal(true);
            expect(await registry.isAllowed(carol.address)).to.equal(true);
        });

        it("setBlockedBatch flips multiple addresses at once", async function () {
            const { registry, listManager, alice, bob } = await deployRegistryFixture(2);
            await registry.connect(listManager).setBlockedBatch([alice.address, bob.address], true);
            expect(await registry.isAllowed(alice.address)).to.equal(false);
            expect(await registry.isAllowed(bob.address)).to.equal(false);
        });

        it("empty batch reverts", async function () {
            const { registry, listManager } = await deployRegistryFixture(0);
            await expect(registry.connect(listManager).setAllowedBatch([], true)).to.be.revertedWithCustomError(
                registry,
                "EmptyBatch"
            );
        });

        it("zero-address in batch reverts", async function () {
            const { registry, listManager, alice } = await deployRegistryFixture(0);
            await expect(
                registry.connect(listManager).setAllowedBatch([alice.address, ethers.ZeroAddress], true)
            ).to.be.revertedWithCustomError(registry, "ZeroAddress");
        });
    });

    describe("role gating", function () {
        it("non-list-manager cannot set allowed / blocked", async function () {
            const { registry, alice, bob } = await deployRegistryFixture(0);
            await expect(registry.connect(alice).setAllowed(bob.address, true)).to.be.reverted;
            await expect(registry.connect(alice).setBlocked(bob.address, true)).to.be.reverted;
        });
    });

    describe("query views", function () {
        it("isExplicitlyAllowed and isExplicitlyBlocked reflect storage", async function () {
            const { registry, listManager, alice } = await deployRegistryFixture(0);
            await registry.connect(listManager).setAllowed(alice.address, true);
            expect(await registry.isExplicitlyAllowed(alice.address)).to.equal(true);
            expect(await registry.isExplicitlyBlocked(alice.address)).to.equal(false);
            await registry.connect(listManager).setBlocked(alice.address, true);
            expect(await registry.isExplicitlyBlocked(alice.address)).to.equal(true);
        });
    });
});
