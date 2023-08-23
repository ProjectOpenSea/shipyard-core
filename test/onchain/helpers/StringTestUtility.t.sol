// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {StringTestUtility} from "./StringTestUtility.sol";

contract StringTestUtilityTest is Test {
    using StringTestUtility for string;

    function testCountChar() public {
        string memory str = "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z";
        uint256 count = str.countChar(",");
        assertTrue(count == 25);
    }
}
