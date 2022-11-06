// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/OperatorDenylistRegistry.sol";

contract OperatorDenylistRegistryTest is Test {
    OperatorDenylistRegistry public odr;

    function setUp() public {
        odr = new OperatorDenylistRegistry();
    }
}
