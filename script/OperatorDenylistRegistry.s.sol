// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import {OperatorDenylistRegistry} from "../src/OperatorDenylistRegistry.sol";

contract Deploy is Script {
    function run() public {
        vm.broadcast();
        new OperatorDenylistRegistry();
    }
}
