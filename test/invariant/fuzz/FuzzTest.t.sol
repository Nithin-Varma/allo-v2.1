// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {PropertiesParent} from "./properties/PropertiesParent.t.sol";

contract FuzzTest is PropertiesParent {
    /// @custom:property-id 0
    /// @custom:property Check sanity
    function property_sanityCheck() public {
        assertTrue(address(allo) != address(0), "sanity check");
        assertTrue(address(registry) != address(0), "sanity check");
        assertEq(address(treasury), allo.getTreasury(), "sanity check");
        assertEq(percentFee, allo.getPercentFee(), "sanity check");
        assertEq(baseFee, allo.getBaseFee(), "sanity check");
        assertTrue(allo.isTrustedForwarder(forwarder), "sanity check");
    }

    function test_debug() public {
        // vm.prank(0x0000000000000000000000000000000000090000);
        // this.handler_removeMembers(
        //     12493832144150206220818440330241996117972073788132942891394489973530611
        // );
        vm.prank(0x0000000000000000000000000000000000020000);
        // (block=30950, time=612166, gas=12500000, gasprice=1, value=0, sender=0x0000000000000000000000000000000000020000)
        vm.warp(612166);
        vm.roll(30950);
        this.prop_userShouldBeAbleToAllocateForRecipient(
            252323675179693227506387432992956186566137662333635639084452108111127,
            41077471260566049543246665642535067927721766624197301745125342130166593678999,
            7935858344945719938663613590712156476343446907510920962262409689677475083008
        );
    }
}
