require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const { REPORT_GAS } = process.env;

module.exports = {
    solidity: {
        version: "0.8.36",
        settings: {
            optimizer: {
                enabled: true,
                runs: 0,
            },
            viaIR: true,
            evmVersion: "cancun",
        },
    },
    networks: {
        hardhat: {
            allowUnlimitedContractSize: true,
        },
    },
    gasReporter: {
        enabled: REPORT_GAS === "true",
        currency: "USD",
    },
    mocha: {
        timeout: 200000,
    },
};
