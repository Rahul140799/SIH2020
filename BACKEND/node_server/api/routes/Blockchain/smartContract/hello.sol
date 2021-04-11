pragma solidity ^0.4.17;

contract Hello {
    string greeting;

    constructor() public{
        greeting = "Hello Jay";
    }

    function getGreet() public view returns (string){
        return greeting;
    }
}