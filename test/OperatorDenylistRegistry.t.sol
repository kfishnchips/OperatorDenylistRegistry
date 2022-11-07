// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {OperatorDenylistRegistry} from "../src/OperatorDenylistRegistry.sol";
import {IOperatorDenylistRegistry} from "../src/interfaces/IOperatorDenylistRegistry.sol";
import {OwnableSimpleNFT} from "./fixtures/OwnableSimpleNFT.sol";
import {RoleSimpleNFT} from "./fixtures/RoleSimpleNFT.sol";
import {Exchange} from "./fixtures/Exchange.sol";

contract OperatorDenylistRegistryTest is Test {
    event RegisteredNewOperator(
        address indexed sender,
        address indexed operator,
        bytes32 codeHash
    );
    event DeniedOperator(
        address indexed sender,
        address indexed operatedContract,
        address indexed operator,
        bool denied
    );
    event ApprovedRegistryOperator(
        address indexed sender,
        address indexed operatedContract,
        address indexed operator,
        bool approved
    );

    OperatorDenylistRegistry public operatorDenylistRegistry;
    OwnableSimpleNFT public ownableSimpleNFT;
    OwnableSimpleNFT public ownableSimpleNFTDeriv;
    RoleSimpleNFT public roleSimpleNFT;
    RoleSimpleNFT public roleSimpleNFTDeriv;
    Exchange public exchange;

    address constant DEPLOYER = address(0x1337);
    address constant BOB = address(0xB0B);
    address constant CAFE = address(0xC4F3);
    address constant DEEDEE = address(0xD33D33);
    address constant BLUR_EXECUTION_DELEGATE = 0x00000000000111AbE46ff893f3B2fdF1F759a8A8;
    address constant LOOKSRARE_EXCHANGE = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address constant X2Y2_ERC721_DELEGATE = 0xF849de01B080aDC3A814FaBE1E2087475cF2E354;
    address constant SUDOSWAP_LSSVM_PAIR_ROUTER = 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;
    address constant OPENSEA_SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    function setUp() public {
        exchange = new Exchange();
        operatorDenylistRegistry = new OperatorDenylistRegistry();
        startHoax(DEPLOYER, DEPLOYER, 1 ether);
        ownableSimpleNFT = new OwnableSimpleNFT(address(operatorDenylistRegistry));
        ownableSimpleNFTDeriv = new OwnableSimpleNFT(address(0));

        roleSimpleNFT = new RoleSimpleNFT(address(operatorDenylistRegistry));
        roleSimpleNFTDeriv = new RoleSimpleNFT(address(0));
        vm.stopPrank();
    }

    modifier asDeployer {
        startHoax(DEPLOYER, DEPLOYER, 1 ether);
        _;
        vm.stopPrank();
    }

    function testAddRegistryOperatorOwnable() public asDeployer {
        ownableSimpleNFT.transferOwnership(BOB);
        vm.stopPrank();
        startHoax(BOB, BOB, 1 ether);
        vm.expectEmit(true, true, false, true);
        emit ApprovedRegistryOperator(BOB, address(ownableSimpleNFT), CAFE, true);
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(ownableSimpleNFT), CAFE, true);
        vm.stopPrank();

        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), CAFE));
    }

    function testAddRegistryOperatorOwnableWithInvalidUser() public {
        startHoax(BOB, BOB, 1 ether);
        vm.expectRevert(IOperatorDenylistRegistry.SenderNotContractOwnerOrRegistryOperator.selector);
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(ownableSimpleNFT), CAFE, true);
        vm.stopPrank();
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), CAFE));
    }

    function testOperatorAddRegistryOperatorOwnable() public asDeployer {
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(ownableSimpleNFT), BOB, true);
        vm.stopPrank();
        startHoax(BOB, BOB, 1 ether);
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(ownableSimpleNFT), CAFE, true);
        vm.stopPrank();

        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), CAFE));
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), BOB));

        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFTDeriv), CAFE));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFTDeriv), BOB));
    }

    function testOperatorAddRegistryOperatorOwnableAfterTransfer() public asDeployer {
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), DEPLOYER));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), BOB));
        ownableSimpleNFT.transferOwnership(BOB);
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), DEPLOYER));
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), BOB));
    }

    function testOperatorAddRegistryOperatorOwnableRenouncedOwnerhsip() public asDeployer {
        ownableSimpleNFT.renounceOwnership();
        vm.expectRevert(IOperatorDenylistRegistry.SenderNotContractOwnerOrRegistryOperator.selector);
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(ownableSimpleNFT), CAFE, true);
    }

    function testOperatorAddRegistryOperatorOwnableAddressZero() public asDeployer {
        vm.expectRevert(IOperatorDenylistRegistry.AddressZero.selector);
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(ownableSimpleNFT), address(0), true);
    }

    function testBatchOperatorAddRegistryOperatorOwnable() public asDeployer {
        address[] memory operators = new address[](3);
        operators[0] = BOB;
        operators[1] = CAFE;
        operators[2] = DEEDEE;

        bool[] memory approvals = new bool[](3);
        approvals[0] = true;
        approvals[1] = false;
        approvals[2] = true;

        operatorDenylistRegistry.batchSetApprovalForRegistryOperator(address(ownableSimpleNFT), operators, approvals);

        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), BOB));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), CAFE));
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), DEEDEE));

        approvals[0] = false;
        approvals[1] = true;
        approvals[2] = false;

        operatorDenylistRegistry.batchSetApprovalForRegistryOperator(address(ownableSimpleNFT), operators, approvals);

        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), BOB));
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), CAFE));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFT), DEEDEE));

        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFTDeriv), BOB));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFTDeriv), CAFE));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(ownableSimpleNFTDeriv), DEEDEE));
    }

    function testSetOperatorDeniedOwnableAsOwner() public asDeployer {
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(exchange)));
        operatorDenylistRegistry.setOperatorDenied(address(ownableSimpleNFT), address(exchange), true);
        assertTrue(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(exchange)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFTDeriv), address(exchange)));
        operatorDenylistRegistry.setOperatorDenied(address(ownableSimpleNFT), address(exchange), false);
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(exchange)));
    }

    function testBatchSetOperatorDeniedOwnableAsOwner() public asDeployer {
        Exchange one = new Exchange();
        Exchange two = new Exchange();
        Exchange three = new Exchange();

        address[] memory exchanges = new address[](3);
        exchanges[0] = address(one);
        exchanges[1] = address(two);
        exchanges[2] = address(three);

        bool[] memory denials = new bool[](3);
        denials[0] = true;
        denials[1] = false;
        denials[2] = true;

        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(one)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(two)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(three)));

        operatorDenylistRegistry.batchSetOperatorDenied(address(ownableSimpleNFT), exchanges, denials);

        assertTrue(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(one)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(two)));
        assertTrue(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(three)));

        denials[0] = false;
        denials[1] = true;
        denials[2] = false;

        operatorDenylistRegistry.batchSetOperatorDenied(address(ownableSimpleNFT), exchanges, denials);

        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(one)));
        assertTrue(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(two)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFT), address(three)));

        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFTDeriv), address(one)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFTDeriv), address(two)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(ownableSimpleNFTDeriv), address(three)));
    }

    function testTransferApprovedOperatorOwnable() public asDeployer {
        ownableSimpleNFT.safeMint(BOB);
        ownableSimpleNFT.safeMint(DEEDEE);
        vm.stopPrank();
        assertEq(ownableSimpleNFT.balanceOf(BOB), 1);
        assertEq(ownableSimpleNFT.balanceOf(DEEDEE), 1);

        startHoax(BOB, BOB, 1 ether);
        ownableSimpleNFT.setApprovalForAll(address(exchange), true);
        vm.stopPrank();

        exchange.transfer(address(ownableSimpleNFT), BOB, DEEDEE, 0);

        assertEq(ownableSimpleNFT.balanceOf(DEEDEE), 2);

        startHoax(DEPLOYER, DEPLOYER, 1 ether);
        operatorDenylistRegistry.setOperatorDenied(address(ownableSimpleNFT), address(exchange), true);
        vm.stopPrank();

        startHoax(DEEDEE, DEEDEE, 1 ether);
        ownableSimpleNFT.setApprovalForAll(address(exchange), true);
        vm.stopPrank();

        vm.expectRevert(OwnableSimpleNFT.OperatorDenied.selector);
        exchange.transfer(address(ownableSimpleNFT), DEEDEE, BOB, 0);

        startHoax(DEPLOYER, DEPLOYER, 1 ether);
        operatorDenylistRegistry.setOperatorDenied(address(ownableSimpleNFT), address(exchange), false);
        vm.stopPrank();

        exchange.transfer(address(ownableSimpleNFT), DEEDEE, BOB, 0);

        assertEq(ownableSimpleNFT.balanceOf(BOB), 1);
        assertEq(ownableSimpleNFT.balanceOf(DEEDEE), 1);
    }

    function testAddRegistryOperatorRole() public asDeployer {
        roleSimpleNFT.grantRole(roleSimpleNFT.DEFAULT_ADMIN_ROLE(), BOB);
        vm.stopPrank();
        startHoax(BOB, BOB, 1 ether);
        vm.expectEmit(true, true, false, true);
        emit ApprovedRegistryOperator(BOB, address(roleSimpleNFT), CAFE, true);
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(roleSimpleNFT), CAFE, true);
        vm.stopPrank();

        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), CAFE));
    }

    function testAddRegistryOperatorRoleWithInvalidUser() public {
        startHoax(BOB, BOB, 1 ether);
        vm.expectRevert(IOperatorDenylistRegistry.SenderNotContractOwnerOrRegistryOperator.selector);
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(roleSimpleNFT), CAFE, true);
        vm.stopPrank();
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), CAFE));
    }

    function testOperatorAddRegistryOperatorRole() public asDeployer {
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(roleSimpleNFT), BOB, true);
        vm.stopPrank();
        startHoax(BOB, BOB, 1 ether);
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(roleSimpleNFT), CAFE, true);
        vm.stopPrank();

        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), CAFE));
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), BOB));

        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFTDeriv), CAFE));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFTDeriv), BOB));
    }

    function testOperatorAddRegistryOperatorRoleAfterGrantAdmin() public asDeployer {
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), DEPLOYER));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), BOB));
        roleSimpleNFT.grantRole(roleSimpleNFT.DEFAULT_ADMIN_ROLE(), BOB);
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), DEPLOYER));
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), BOB));
    }

    function testOperatorAddRegistryOperatorRoleRenouncedAdmin() public asDeployer {
        roleSimpleNFT.renounceRole(roleSimpleNFT.DEFAULT_ADMIN_ROLE(), DEPLOYER);
        vm.expectRevert(IOperatorDenylistRegistry.SenderNotContractOwnerOrRegistryOperator.selector);
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(roleSimpleNFT), CAFE, true);
    }

    function testOperatorAddRegistryOperatorRoleAddressZero() public asDeployer {
        vm.expectRevert(IOperatorDenylistRegistry.AddressZero.selector);
        operatorDenylistRegistry.setApprovalForRegistryOperator(address(roleSimpleNFT), address(0), true);
    }

    function testBatchOperatorAddRegistryOperatorRole() public asDeployer {
        address[] memory operators = new address[](3);
        operators[0] = BOB;
        operators[1] = CAFE;
        operators[2] = DEEDEE;

        bool[] memory approvals = new bool[](3);
        approvals[0] = true;
        approvals[1] = false;
        approvals[2] = true;

        operatorDenylistRegistry.batchSetApprovalForRegistryOperator(address(roleSimpleNFT), operators, approvals);

        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), BOB));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), CAFE));
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), DEEDEE));

        approvals[0] = false;
        approvals[1] = true;
        approvals[2] = false;

        operatorDenylistRegistry.batchSetApprovalForRegistryOperator(address(roleSimpleNFT), operators, approvals);

        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), BOB));
        assertTrue(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), CAFE));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFT), DEEDEE));

        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFTDeriv), BOB));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFTDeriv), CAFE));
        assertFalse(operatorDenylistRegistry.isRegistryOperatorApproved(address(roleSimpleNFTDeriv), DEEDEE));
    }

    function testSetOperatorDeniedRoleAsAdmin() public asDeployer {
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(exchange)));
        operatorDenylistRegistry.setOperatorDenied(address(roleSimpleNFT), address(exchange), true);
        assertTrue(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(exchange)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFTDeriv), address(exchange)));
        operatorDenylistRegistry.setOperatorDenied(address(roleSimpleNFT), address(exchange), false);
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(exchange)));
    }

    function testBatchSetOperatorDeniedRoleAsAdmin() public asDeployer {
        Exchange one = new Exchange();
        Exchange two = new Exchange();
        Exchange three = new Exchange();

        address[] memory exchanges = new address[](3);
        exchanges[0] = address(one);
        exchanges[1] = address(two);
        exchanges[2] = address(three);

        bool[] memory denials = new bool[](3);
        denials[0] = true;
        denials[1] = false;
        denials[2] = true;

        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(one)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(two)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(three)));

        operatorDenylistRegistry.batchSetOperatorDenied(address(roleSimpleNFT), exchanges, denials);

        assertTrue(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(one)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(two)));
        assertTrue(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(three)));

        denials[0] = false;
        denials[1] = true;
        denials[2] = false;

        operatorDenylistRegistry.batchSetOperatorDenied(address(roleSimpleNFT), exchanges, denials);

        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(one)));
        assertTrue(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(two)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFT), address(three)));

        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFTDeriv), address(one)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFTDeriv), address(two)));
        assertFalse(operatorDenylistRegistry.isOperatorDenied(address(roleSimpleNFTDeriv), address(three)));
    }

    function testTransferApprovedOperatorRoleBased() public asDeployer {
        roleSimpleNFT.safeMint(BOB);
        roleSimpleNFT.safeMint(DEEDEE);
        vm.stopPrank();
        assertEq(roleSimpleNFT.balanceOf(BOB), 1);
        assertEq(roleSimpleNFT.balanceOf(DEEDEE), 1);

        startHoax(BOB, BOB, 1 ether);
        roleSimpleNFT.setApprovalForAll(address(exchange), true);
        vm.stopPrank();

        exchange.transfer(address(roleSimpleNFT), BOB, DEEDEE, 0);

        assertEq(roleSimpleNFT.balanceOf(DEEDEE), 2);

        startHoax(DEPLOYER, DEPLOYER, 1 ether);
        operatorDenylistRegistry.setOperatorDenied(address(roleSimpleNFT), address(exchange), true);
        vm.stopPrank();

        startHoax(DEEDEE, DEEDEE, 1 ether);
        roleSimpleNFT.setApprovalForAll(address(exchange), true);
        vm.stopPrank();

        vm.expectRevert(RoleSimpleNFT.OperatorDenied.selector);
        exchange.transfer(address(roleSimpleNFT), DEEDEE, BOB, 0);

        startHoax(DEPLOYER, DEPLOYER, 1 ether);
        operatorDenylistRegistry.setOperatorDenied(address(roleSimpleNFT), address(exchange), false);
        vm.stopPrank();

        exchange.transfer(address(roleSimpleNFT), DEEDEE, BOB, 0);

        assertEq(roleSimpleNFT.balanceOf(BOB), 1);
        assertEq(roleSimpleNFT.balanceOf(DEEDEE), 1);
    }
}
