// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

contract CrowdFunding {
    mapping (address => uint) public contributor; //Contribution store against contributor address
    address public owner; 
    uint deadline; //mile-stones
    uint minContribution; //mile-stones
    uint target; //mile-stones
    uint public balance;
    uint public noOfContributors;

    //mapping variable is request store struct by number 0Request, 1Request
    mapping (uint => Request) public requests; 
    uint numRequest; //used to increase the uint of mapping request

    struct Request { //when struct is called it store all asign values
        string description; 
        uint value;
        address addr;
        bool completed;
        uint noOfVoters;
    }

    constructor(uint _deadline, uint _target) { //describe some details when deploying the contract
        owner = msg.sender; //who deploy the contract will be the owner
        deadline = block.timestamp + _deadline;
        minContribution = 1 ether;
        target = _target;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the Owner");
        _;
    }

    //address store false by default
    mapping (address => bool) voted; //this is used to prevent the second time voting by same person

    modifier _voted { //if it false mean contributor didn't vote before it its ture mean he already voted
        require(voted[msg.sender] == false, "You already voted");
        _;
    }

    function sendEther() public payable { //function to recive ether in contract
        require(msg.value >= minContribution, "Minimum Contribution is 1 Ether");
        require(block.timestamp < deadline && balance != target, "Program is ended");
        //if contributor uint is 0 mean the person contributing first time
        if(contributor[msg.sender] == 0) { 
            noOfContributors++; //number of contrubutors will increase
        }
        //if contributor uint is something mean the person is already a contributor
        //noOfContributors will not increase
        contributor[msg.sender] += msg.value; //contributor previous amount + new amount 
        balance += msg.value; //balance will increase
    }

    //Create Request for donation
    function createRequest (string memory _description, uint _value, address _addr) public onlyOwner {
        numRequest++; //function called numRequest will increase, there will be no Request on 0
        Request storage newRequest = requests[numRequest];
        newRequest.description =_description;
        newRequest.value = _value * 1 ether; //wei * 1ether 
        newRequest.addr = _addr;
    }

    //_voted modifier will check if contributor is false then run this function else not
    function vote(uint requestNum) public _voted {
        require(contributor[msg.sender] >0, "You must be a Contributor");
        Request storage newRequest = requests[requestNum];
        require(requestNum > 0, "There is no one to vote");
        newRequest.noOfVoters++;
        voted[msg.sender] = true;
    }

    function refund() public {
        require(contributor[msg.sender] > 0, "You are not the Contributor");
        require(block.timestamp > deadline && balance != target, "Project is ongoing");
        uint refundAmount = contributor[msg.sender];
        contributor[msg.sender] = 0; //it will 0 the contribution of the contrubutor
        payable(msg.sender).transfer(refundAmount); //it will transfer only contribution amount
        balance -= refundAmount; //refund amount - from balance
    }

    function makePayment(uint requestNum) public onlyOwner {
        Request storage paymentRequest = requests[requestNum];
        //completed == false mean paymment is not done 
        require(paymentRequest.completed == false, "Payment is already completed");
        require(paymentRequest.noOfVoters > noOfContributors/2, "Majority didn't vote for this program");
        require(balance >= paymentRequest.value, "Targeted amount is not completed");
        paymentRequest.completed = true; //when completed == true mean payment is done
        address payable user = payable (paymentRequest.addr); //make address payable 
        user.transfer(balance); //transfer all the balance 
        balance -= balance; 
    }
}
