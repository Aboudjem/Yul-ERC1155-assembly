object "ERC1155" {
  code {
    sstore(0, "ABC")
    
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    // Return the calldata
    code {
      require(iszero(callvalue()))

      let s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)


      switch s 
        case 0x0e89341c { // uri(uint256)
          uri(decodeAsUint(0))
        } 
        case 0x00fdd58e { // balanceOf(address,uint256)
          returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
        }
        case 0x156e29f6 { // mint(address,uint256,uint256) 
          mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
        }
        case 0x4e1273f4 { // balanceOfBatch(address[],uint256[])
          balanceOfBatch()
        }
        case 0xa22cb465 { // setApprovalForAll(address,bool)  
          setApprovalForAll(decodeAsAddress(0), decodeAsUint(1))
        }
        case 0xebd1d359 { // isApprovalForAll(address,address)
          returnUint(isApprovalForAll(decodeAsAddress(0), decodeAsAddress(1)))
        }
        case 0xf242432a { // safeTransferFrom(address,address,uint256,uint256,bytes)
          safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), 0x00)
        }
        case 0x2eb2c2d6 { // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
          safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1))
        }
        default {
          revert(0,0)
        }


        function decodeAsAddress(offset) -> v {
            v := decodeAsUint(offset)
            if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                revert(0, 0)
            }
        }

        function decodeAsUint(offset) -> v {
            let pos := add(4, mul(offset, 0x20))
            if lt(calldatasize(), add(pos, 0x20)) {
                revert(0, 0)
            }
            v := calldataload(pos)
        }
      
          /* ----- storage layout ----- */
          function uriPos() -> p { p := 0 }
          function balanceOfStorageOffset(account) -> offset {
            offset := add(0x1000, account)
          }

          function allowanceStorageOffset(account, spender) -> offset {
            offset := balanceOfStorageOffset(account)
            mstore(0x00, offset)
            mstore(0x20, spender)
            offset := keccak256(0, 0x40)
          }

          /* ----- storage layout ----- */

          function balanceOf(account, id) -> bal {
            if eq(account, 0x0000000000000000000000000000000000000000) { 
              revertWithMessage("Not a valid owner", 0x12)
            }

            mstore(0x00, balanceOfStorageOffset(account))
            mstore(0x20, id)
            bal := sload(keccak256(0x00, 0x40))
          }

          function balanceOfBatch() {
            let addrOffset := decodeAsUint(0)
            let uintOffset := decodeAsUint(1)
            let lenAddr := calldataload(add(4, addrOffset))
            let lenUint := calldataload(add(4, uintOffset))

            if iszero(eq(lenUint, lenAddr)) { revert(0x00, 0x00) }

            let currOffset := 0x40

            mstore(currOffset, 0x20)
            currOffset := add(currOffset, 0x20)
            mstore(currOffset, lenAddr)
            currOffset := add(currOffset, 0x20)

            for { let i := 0 } lt(i, lenUint) { i := add(i, 1) } {
              let addr := calldataload(add(add(4, sub(currOffset, 0x60)), addrOffset))
              let id := calldataload(add(add(4, sub(currOffset, 0x60)), uintOffset))
              mstore(currOffset, balanceOf(addr, id))
              currOffset := add(currOffset, 0x20)
            }
            return (0x40, currOffset)
          }

          function setApprovalForAll(operator, approved) {
            sstore(allowanceStorageOffset(caller(), operator), approved)
          }

          function isApprovalForAll(account, operator) -> allowed {
            allowed := sload(allowanceStorageOffset(account, operator))
          }

          function safeTransferFrom(from, to, id, amount, data) {
            if iszero(or(eq(caller(), from), isApprovalForAll(from, caller()))) { revert (0x80, 0x140) } 

            mstore(0x00, balanceOfStorageOffset(from))
            mstore(0x20, id)
            let fromLoc := keccak256(0x00, 0x40)

            mstore(0x00, balanceOfStorageOffset(to))
            let toLoc := keccak256(0x00, 0x40)

            let fromBalance := sload(fromLoc)
            let toBalance := sload(toLoc)

            require(gte(fromBalance, amount))

            sstore(fromLoc, sub(fromBalance, amount))
            sstore(toLoc, add(toBalance, amount)) 
            
            // return (0x80, 0x140)

          }

          function safeBatchTransferFrom(from, to) {
            
            if iszero(from) { revert(0x00, 0x00) }
            
            let idsOffset := decodeAsUint(2)
            let amountsOffset := decodeAsUint(3)


            let lenAmountsOffset := add(4, amountsOffset)
            let lenIdsOffset := add(4, idsOffset)

            let lenAmounts := calldataload(lenAmountsOffset)
            let lenIds := calldataload(lenIdsOffset)

            // mstore(0x00, lenIds)
            // return (0x00, 0x20)
            if iszero(eq(lenAmounts, lenIds)) { revert (0x00, 0x00) }

            let currentOffset := 0x00
            currentOffset := add(currentOffset, 0x20)



            for { let i := 0 } lt(i, lenIds) { i := add(i, 1) } {

            let id := calldataload(add(lenIdsOffset, currentOffset))
            let amount := calldataload(add(lenAmountsOffset, sub(currentOffset, 0x00)))
            
            mstore(0x00, balanceOfStorageOffset(from))
            mstore(0x20, id)
            let fromLoc := keccak256(0x00, 0x40)
            
            
            mstore(0x00, balanceOfStorageOffset(to))
            let toLoc := keccak256(0x00, 0x40)

            let fromBalance := sload(fromLoc)
            let toBalance := sload(toLoc)


            require(gte(fromBalance, amount))

            sstore(fromLoc, sub(fromBalance, amount))
            sstore(toLoc, add(toBalance, amount)) 



            
              // mstore(currentOffset, amount)
              // safeTransferFrom(from, to, id, amount, 0x00)
              currentOffset := add(currentOffset, 0x20)
            }
            return(0x00, currentOffset)
            // return (0x100, 0x120)

            // length should be equal

            // to != address(0)

            // fromBalance

            // fromBalance - amount

            // toBalance + amount

            // safeacceptant
            // revert(0x00, 0x40)
          }

          function mint(account, id, amount) {
            mstore(0x00, balanceOfStorageOffset(account))
            mstore(0x20, id)
            let loc := keccak256(0x00, 0x40)
            let bal := sload(loc)
            sstore(loc, add(bal, amount))
            returnTrue()
          }

          function uri(index) {
            mstore(0x00, 0x20)
            mstore(0x20, 0x03)
            mstore(0x40, sload(uriPos()))
            return(0x00, 0x60)
          }

          /* ---------- calldata encoding functions ---------- */
          function returnUint(v) {
              mstore(0, v)
              return(0, 0x20)
          }
          
          function returnTrue() {
              returnUint(1)
          }


          /* ---------- utility functions ---------- */
          function lte(a, b) -> r {
              r := iszero(gt(a, b))      
          }

          function gte(a, b) -> r {
              r := iszero(lt(a, b))
          }

          function safeAdd(a, b) -> r {
              r := add(a, b)
              if or(lt(r, a), lt(r, b)) { revert(0, 0) }
          }

          function revertIfZeroAddress(addr) {
              require(addr)
          }

          function require(condition) {
              if iszero(condition) { revert(0, 0) }
          }

          function revertWithMessage(msg, size) {
              mstore(0x00, 0x20)
              mstore(0x20, size)
              mstore(0x40, msg)
              revert(0x00, 0x60)
          }
    }
  }

}