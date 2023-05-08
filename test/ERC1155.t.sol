// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import "../src/ERC1155.sol";
import "../src/ERC1155Receiver.sol";
import "../src/ERC1155NonReceiver.sol";
import "../src/ERC1155ReceiverEmpty.sol";
import "../src/ERC1155ReceiverRevert.sol";
interface IERC1155 {
    function uri(uint256) external view returns(string memory);
    function mint(address, uint,uint) external;
    function balanceOfBatch(address[] calldata, uint[] calldata) external view returns(uint[] memory);
    function safeTransferFrom(address,address,uint,uint,bytes memory) external returns(bool);
    function setApprovalForAll(address operator, bool approved) external;
    function safeBatchTransferFrom(address from, address to, uint[] memory, uint[] memory, bytes memory) external returns(bytes memory);
}

contract ERC1155Test is Test {

    YulDeployer public yulDeployer = new YulDeployer();

    ERC1155 public solContract;
    ERC1155 public yulContract; 

    address public owner = 0x0000000000000000000000000000000000fffFfF;
    address public userA = 0x0000000000000000000000000000000000AbC123;
    address public userB = 0x0000000000000000000000000000000000123123;
    address public userC = 0x0000000000000000000000000000000000aBCabc;
    address public receiverContract;
    address public nonReceiverContract;
    address public receiverRevertContract;
    address public receiverEmptyContract;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function setUp() public {
        solContract = new ERC1155("https://token.com/");
        yulContract = ERC1155(yulDeployer.deployContract("ERC1155"));
        solContract.mint(owner, 1, 10_000);
        yulContract.mint(owner, 1, 10_000);
        vm.startPrank(owner, msg.sender);
        receiverContract = address(new ERC1155Receiver());
        nonReceiverContract = address(new ERC1155NonReceiver());
        receiverEmptyContract = address(new ERC1155ReceiverEmpty());
        receiverRevertContract = address(new ERC1155ReceiverRevert());
    }

    function testUri() public {
        assertEq(solContract.uri(1), yulContract.uri(1), "Failed: mismatch");
    }

    function testBalanceOfOwner() public { 
        assertEq(yulContract.balanceOf(owner, 1), 10_000);
        assertEq(solContract.balanceOf(owner, 1), 10_000);
    }

    function testBalanceOf() public { 
        assertEq(yulContract.balanceOf(owner, 1), solContract.balanceOf(owner, 1));
    }    

    function testBalanceOfWithZeroAddress(uint id) public {
        vm.expectRevert("ERC1155: address zero is not a valid owner");
        yulContract.balanceOf(address(0), id);
        vm.expectRevert("ERC1155: address zero is not a valid owner");
        solContract.balanceOf(address(0), id);
    }

    function testBatchBalance(uint amount) public {
        address[] memory addresses = new address[](5);
        addresses[0] = 0xB4bbCc562A3D49A384aFf6481377f2a5c19cf1bF;
        addresses[1] = 0x2D1A0Ead2a42E8b2731E8F6169f0041EC38F7c9a;
        addresses[2] = 0xCA16B6d3D34F781c3E504EC16433EC44b4ac49e6;
        addresses[3] = 0x5fd1a905c827Fd2AdDBCa5D5C4d2170Adcc4c969;
        addresses[4] = 0xFbdc16F71155B583698cfE8658925E6ac94cEB6f;
        
        uint[] memory ids = new uint[](5);
        ids[0] = 32;
        ids[1] = 64;
        ids[2] = 128;
        ids[3] = 256;
        ids[4] = 512;
        
        yulContract.mint(addresses[0], ids[0], amount);
        yulContract.mint(addresses[1], ids[1], amount);
        yulContract.mint(addresses[2], ids[2], amount);
        yulContract.mint(addresses[3], ids[3], amount);
        yulContract.mint(addresses[4], ids[4], amount);

        solContract.mint(addresses[0], ids[0], amount);
        solContract.mint(addresses[1], ids[1], amount);
        solContract.mint(addresses[2], ids[2], amount);
        solContract.mint(addresses[3], ids[3], amount);
        solContract.mint(addresses[4], ids[4], amount);

        assertEq(yulContract.balanceOfBatch(addresses, ids), solContract.balanceOfBatch(addresses, ids));
    }

    function testBalanceOfBatchMismatched() public {
        address[] memory addresses = new address[](4);
        addresses[0] = 0xB4bbCc562A3D49A384aFf6481377f2a5c19cf1bF;
        addresses[1] = 0x2D1A0Ead2a42E8b2731E8F6169f0041EC38F7c9a;
        addresses[2] = 0xCA16B6d3D34F781c3E504EC16433EC44b4ac49e6;
        addresses[3] = 0x5fd1a905c827Fd2AdDBCa5D5C4d2170Adcc4c969;
        
        uint[] memory ids = new uint[](5);
        ids[0] = 32;
        ids[1] = 64;
        ids[2] = 128;
        ids[3] = 256;
        ids[4] = 512;
        vm.expectRevert("ERC1155: accounts and ids length mismatch");
        yulContract.balanceOfBatch(addresses, ids);
        vm.expectRevert("ERC1155: accounts and ids length mismatch");
        solContract.balanceOfBatch(addresses, ids);
    }

    function testSetApprovalForAll(address operator, bool approved) public {
        vm.assume(operator != owner);
        
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        yulContract.setApprovalForAll(operator, approved);

        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(owner, operator, approved);
        solContract.setApprovalForAll(operator, approved);

        assertEq(yulContract.isApprovalForAll(owner, operator), approved);
        assertEq(solContract.isApprovalForAll(owner, operator), approved);
    }

     function testSetApprovalToSelf(bool approved) public {
        vm.expectRevert("ERC1155: setting approval status for self");
        yulContract.setApprovalForAll(owner, approved);
        vm.expectRevert("ERC1155: setting approval status for self");
        solContract.setApprovalForAll(owner, approved);
    }


    function testSafeTransferFromToReceiverContract() public {
        yulContract.safeTransferFrom(owner, receiverContract, 1, 1, "");
    }

    function testSafeTransferFromToReceiverEmptyContract() public {
        vm.expectRevert("ERC1155: transfer to non-ERC1155Receiver implementer");
        solContract.safeTransferFrom(owner, receiverEmptyContract, 1, 1, "");
        
        vm.expectRevert("ERC1155: transfer to non-ERC1155Receiver implementer");
        yulContract.safeTransferFrom(owner, receiverEmptyContract, 1, 1, "");
    }

    function testSafeTransferFromToNonReceiverContract() public {
        vm.expectRevert("ERC1155: ERC1155Receiver rejected tokens");
        solContract.safeTransferFrom(owner, nonReceiverContract, 1, 1, "");

        vm.expectRevert("ERC1155: ERC1155Receiver rejected tokens");
        yulContract.safeTransferFrom(owner, nonReceiverContract, 1, 1, "");
    }

    function testSafeTransferFromToReceiverRevertContract() public {
        vm.expectRevert("Revert something");
        solContract.safeTransferFrom(owner, receiverRevertContract, 1, 1, "");

        vm.expectRevert("Revert something");
        yulContract.safeTransferFrom(owner, receiverRevertContract, 1, 1, "");
    }

    function testSafeTransferFromAsOwner(uint8 id, uint8 amount) public {
        vm.assume(id != 1);
        address to = userA;

        assertEq(yulContract.balanceOf(owner, id), 0);
        assertEq(solContract.balanceOf(owner, id), 0);

        assertEq(yulContract.balanceOf(to, id), 0);
        assertEq(solContract.balanceOf(to, id), 0);

        
        yulContract.mint(owner, id, amount);
        solContract.mint(owner, id, amount);

        assertEq(yulContract.balanceOf(owner, id), amount);
        assertEq(solContract.balanceOf(owner, id), amount);        
        
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(owner, owner, to, id, amount);
        solContract.safeTransferFrom(owner, to, id, amount, "");

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(owner, owner, to, id, amount);
        yulContract.safeTransferFrom(owner, to, id, amount, "");

        assertEq(yulContract.balanceOf(to, id), amount);
        assertEq(solContract.balanceOf(to, id), amount);

        assertEq(yulContract.balanceOf(owner, id), 0);
        assertEq(solContract.balanceOf(owner, id), 0);
    }

    function testSafeTransferFromAsOperator(uint8 id, uint8 amount) public {
        vm.assume(id != 1);

        address to = userB;

        assertEq(yulContract.balanceOf(userA, id), 0);
        assertEq(solContract.balanceOf(userA, id), 0);

        assertEq(yulContract.balanceOf(to, id), 0);
        assertEq(solContract.balanceOf(to, id), 0);
        
        vm.stopPrank();
        vm.startPrank(userA, msg.sender);

        yulContract.setApprovalForAll(owner, true);
        solContract.setApprovalForAll(owner, true);

        vm.stopPrank();
        vm.startPrank(owner, msg.sender);
    
        yulContract.mint(userA, id, amount);
        solContract.mint(userA, id, amount);
        
        assertEq(yulContract.balanceOf(userA, id), amount);
        assertEq(solContract.balanceOf(userA, id), amount);
        

        yulContract.safeTransferFrom(userA, to, id, amount, "");
        solContract.safeTransferFrom(userA, to, id, amount, "");

        assertEq(yulContract.balanceOf(to, id), amount);
        assertEq(solContract.balanceOf(to, id), amount);

        assertEq(yulContract.balanceOf(userA, id), 0);
        assertEq(solContract.balanceOf(userA, id), 0);
    }


    function testSafeTransferFromNotOwner(uint8 id, uint8 amount) public {
        vm.assume(id != 1);

        address to = userB;

        assertEq(yulContract.balanceOf(userA, id), 0);
        assertEq(solContract.balanceOf(userA, id), 0);

        assertEq(yulContract.balanceOf(to, id), 0);
        assertEq(solContract.balanceOf(to, id), 0);    
        
        yulContract.mint(userA, id, amount);
        solContract.mint(userA, id, amount);
        
        assertEq(yulContract.balanceOf(userA, id), amount);
        assertEq(solContract.balanceOf(userA, id), amount);
        
        vm.expectRevert("ERC1155: caller is not token owner or approved");
        yulContract.safeTransferFrom(userA, to, id, amount, "");
        vm.expectRevert("ERC1155: caller is not token owner or approved");
        solContract.safeTransferFrom(userA, to, id, amount, "");
    }

    function testSafeTransferFromToZeroAddress(uint8 id, uint8 amount) public {
        vm.assume(id != 1);

        address to = address(0);
        
        yulContract.mint(owner, id, amount);
        solContract.mint(owner, id, amount);
        
        assertEq(yulContract.balanceOf(owner, id), amount);
        assertEq(solContract.balanceOf(owner, id), amount);

        vm.expectRevert("ERC1155: transfer to the zero address");
        yulContract.safeTransferFrom(owner, to, id, amount, "");
        vm.expectRevert("ERC1155: transfer to the zero address");
        solContract.safeTransferFrom(owner, to, id, amount, "");
    }

    function testSafeTransferFromWithInsufficientBalances() public {

        address to = userB;

        uint amount = 1000;
        uint id = 1010;

        vm.expectRevert("ERC1155: insufficient balance for transfer");
        yulContract.safeTransferFrom(owner, to, id, amount, "");
        
        vm.expectRevert("ERC1155: insufficient balance for transfer");
        solContract.safeTransferFrom(owner, to, id, amount, "");
    }

    function testBurnWithInsufficientBalances() public {
        uint amount = 100;
        uint id = 1010;

        vm.expectRevert("ERC1155: burn amount exceeds balance");
        yulContract.burn(id, amount);
    }

    function testBurnWithZeroAddress() public {
        uint id = 1010;
        vm.stopPrank();
        address zero = address(0);

        vm.prank(zero, msg.sender);
        vm.expectRevert("ERC1155: burn from the zero address");
        yulContract.burn(id, 0);
    }

    function testMintToZeroAddress(uint id, uint amount) public {
        vm.expectRevert("ERC1155: mint to the zero address");
        yulContract.mint(address(0), id, amount);
    }


    function testSafeBatchTransferFrom(address sender, address receiver) public {
        
        vm.assume(receiver != address(0));
        vm.assume(sender != address(0));
        vm.stopPrank();
        vm.startPrank(sender, msg.sender);
        uint[] memory ids = new uint[](5);
        ids[0] = 32;
        ids[1] = 64;
        ids[2] = 128;
        ids[3] = 256;
        ids[4] = 512;

        uint[] memory amounts = new uint[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        
        yulContract.mint(sender,  ids[0], amounts[0]);
        yulContract.mint(sender,  ids[1], amounts[1]);
        yulContract.mint(sender,  ids[2], amounts[2]);
        yulContract.mint(sender,  ids[3], amounts[3]);
        yulContract.mint(sender,  ids[4], amounts[4]);
        

        solContract.mint(sender,  ids[0], amounts[0]);
        solContract.mint(sender,  ids[1], amounts[1]);
        solContract.mint(sender,  ids[2], amounts[2]);
        solContract.mint(sender,  ids[3], amounts[3]);
        solContract.mint(sender,  ids[4], amounts[4]);
        


        vm.expectEmit(true, true, true, true);
        emit TransferBatch(msg.sender, sender, receiver, ids, amounts);
        solContract.safeBatchTransferFrom(sender, receiver, ids, amounts, "");

        vm.stopPrank();
        // assertEq(yulContract.balanceOfBatch(addresses, ids), solContract.balanceOfBatch(addresses, ids));
    }



}