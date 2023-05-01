// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
    struct Proposal{
        uint id;
        string description;
        uint amount;
        address payable receipient;
        uint vote;
        uint end;
        bool isExecuted;
    }
    mapping (address => bool) private isInvestor;
    mapping(address => uint) public numofshares;
    mapping(address => mapping (uint => bool)) public isVoted;
    mapping(address => mapping (address => bool)) public withdrawlStatus;
    address[] public investorsList;
    mapping ( uint => Proposal ) public proposals;

    uint public totalShares;
    uint public availableFunds;
    uint public contribuionTimeEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public manager;

    constructor(uint _contributionEndTime, uint _voteTime, uint _quorum){
        require(_quorum>0 && _quorum<100,"Not valid values");
        contribuionTimeEnd=block.timestamp+_contributionEndTime;
        voteTime=_voteTime;
        quorum= _quorum;
        manager=msg.sender;

    }

    modifier onlyInvestor(){
        require(isInvestor[msg.sender]==true,"You are not investor");
        _;
    }
    modifier onlyManager(){
        require(msg.sender==manager,"You are not manager");
        _;
    }
        
    function contribution() public payable{
        require(contribuionTimeEnd>=block.timestamp);
        require(msg.value>0,"Send more than 0 Ether");
        isInvestor[msg.sender]=true;
        numofshares[msg.sender]=numofshares[msg.sender]+ msg.value;
        totalShares+=msg.value;
        availableFunds+=msg.value;
        investorsList.push(msg.sender);


    }


    function reedemShare(uint amount) public onlyInvestor(){
        require(numofshares[msg.sender]>=amount,"You don't have engough funds");
        require(availableFunds>=amount,"Not enough funds");

        numofshares[msg.sender]-=amount;
        if(numofshares[msg.sender]==0)
        {
            isInvestor[msg.sender]=false;
        }
        availableFunds-=amount;
       payable( msg.sender).transfer(amount);


    } 
//investor's address share will get transefered to "to" address
    function transferShare(uint amount, address to) public onlyInvestor{
           require(numofshares[msg.sender]>=amount,"You don't have enough shares");
           require(availableFunds>=amount,"You don't have enough funds");
           numofshares[msg.sender]-=amount;
           if(numofshares[msg.sender]==0)
           {
               isInvestor[msg.sender]=false;
           }
           numofshares[to]+=amount;
           isInvestor[to]=true;
           investorsList.push(to);

    }

    function createProposal(string calldata description,uint amount,address payable receipient) public onlyManager() {
        require(amount<availableFunds,"Not enough funds");
        proposals[nextProposalId]=Proposal(nextProposalId,description,amount,receipient,0,block.timestamp+voteTime,false);
        nextProposalId++;

    }

    function voteProposal(uint proposalId) public onlyInvestor(){
        Proposal storage proposal =proposals[proposalId];
        require(isVoted[msg.sender][proposalId]==false,"You have already voted");
        require(proposal.end>=block.timestamp,"Voting time ended");
        require(proposal.isExecuted==false,"It is already executed");
        isVoted[msg.sender][proposalId]=true;
        proposal.vote+=numofshares[msg.sender];
        

    }
    function executeProposal(uint proposalId) public onlyManager(){
        Proposal storage proposal =proposals[proposalId];
        require(((proposal.vote*100)/totalShares)>=quorum,"majority does not support");
      proposal.isExecuted=true;
      availableFunds-=proposal.amount;
      _transfer(proposal.amount,proposal.receipient);

    }
    function _transfer(uint amount,address payable receipient) private  {
        receipient.transfer(amount);
    }
    
    function ProposalList() public view returns(Proposal[] memory){
        Proposal[] memory arr= new Proposal[](nextProposalId-1);
        for(uint i=0;i<nextProposalId;i++){
            arr[i]=proposals[i];

        }
        return  arr;
    }

}
