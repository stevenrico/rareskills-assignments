// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

contract DeployScript is Script {
    uint256 private _deployer;

    constructor() {
        _deployer = vm.envUint("DEPLOYER_PRIVATE_KEY");
    }

    modifier broadcaster() {
        vm.startBroadcast(_deployer);
        _;
        vm.stopBroadcast();
    }

    function run() external broadcaster { }
}
