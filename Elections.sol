pragma solidity ^0.8.0;

contract Voting{
    address public chairman;            //the one who create voting  
    string public title;                //title of voting
    mapping (address => Voter) voters;  //address of voters
    uint public limit_votes;            //limit of number of people can be permitted to vote
    uint public permission_counts;      //number of permissions until now
    uint public vote_counts;            //number of vote until now
    uint public start_time; 
    uint public end_time;
    string[3] public candidates;        //list of candidates
    uint[3] public candidate_votes;     //number of votes for each candidate

    struct Voter{
        bool can_vote; // permission from chairman
        uint chance;   //number of chance for voting -> defult=1
    }

    constructor(string memory _title, uint _limit, uint _start, uint _end, string[3] memory _condidate_list){
        chairman = msg.sender;
        title = _title;
        limit_votes = _limit;
        start_time = _start;
        end_time = _end;
        candidates = _condidate_list;
    }


    /*
       this function can be called from chairman to give permission to list of addresses

       these are parameters you can pass for vs:
       ["0x2aB0f5204cC208EF5c9E2Ce969577cf0bf9Cdf16","0xFA0fe02b2103a14F13Da141dA2E424E587ab25e6"]
       ["0x5b37EEEC8482Afd46B1DC5403C4d95D597Bb4a73","0x808bFc543Fa4F438aE228F9C5c13228F394143d6"]
       ["0x2aB0f5204cC208EF5c9E2Ce969577cf0bf9Cdf16","0x5b37EEEC8482Afd46B1DC5403C4d95D597Bb4a73"]
    */
    function group_permission(address[] memory vs, uint _size) public{
        //should be in valid time
        require(
            block.timestamp < end_time && block.timestamp>start_time,
            "Voting is over or not started yet"
        );
        //sender must be chairman
        require(
            msg.sender == chairman,
            "only chairman can give permission to voter."
        );
        //number of permissions should be check.there is a limit for it.
        require(
            limit_votes >= permission_counts+_size,
            "Vote limit is completed."
        );
        //each address in list should be a new address who wasent permitted yet
        for(uint i=0;i<_size;i++){
            require(
                !voters[vs[i]].can_vote,
                "Voter has already have permission."
            );
        }
        for(uint i=0;i<_size;i++){
            voters[vs[i]].can_vote = true;
            voters[vs[i]].chance = 1;
        }
        permission_counts = permission_counts + _size;
    }
    
    //this function can be called from chairman to give permission to an addresses
    function give_permission(address voter) public{
        require(
            block.timestamp < end_time && block.timestamp>start_time,
            "Voting is over or not started yet"
        );
        require(
            msg.sender == chairman,
            "only chairman can give permission to voter."
        );
        //the voter must have permission to vote
        require(
            !voters[voter].can_vote,
            "Voter has already have permission."
        );
        require(
            limit_votes>permission_counts,
            "Vote limit is completed."
        );
        permission_counts++;
        voters[voter].can_vote = true;
        voters[voter].chance = 1;
    }

    //this function is for voting 
    function vote(string memory _vote) public {
        require(
            block.timestamp < end_time && block.timestamp>start_time,
            "Voting is over or not started yet"
        );
        Voter storage sender = voters[msg.sender];
        require(
            sender.can_vote,
            "The voter has no permission to vote!"
        );
        //voter must have chance to vote
        require(
            sender.chance>0,
            "This voter has already voted!"
        );
        //the person must be a candidate of the list
        bool in_list = false;   
        for (uint i = 0; i<candidates.length;i++){
            if( keccak256(bytes(candidates[i])) == keccak256(bytes(_vote)) ){
                candidate_votes[i]++;   //votes of the candidate increase
                sender.chance--;        //loss 1 chance to vote
                vote_counts++;          //number of all votes increase
                in_list = true;         //that was a valid candidate 
            }
        }
        require(
            in_list,
            "The person you chose is not a candidate"
        );
    }

    function transfer_chance(address next_voter) public{
        Voter storage sender = voters[msg.sender];
        require(
            block.timestamp < end_time && block.timestamp>start_time,
            "Voting is over or not started yet"
        );
        require(
            sender.can_vote,
            "The voter has no permission to vote!"
        );
        require(
            sender.chance>0,
            "This voter has already voted!"
        );
        Voter storage reciever = voters[next_voter];
        require(
            reciever.can_vote,
            "The reciever has no permission to vote!"
        );
        reciever.chance++;  //reciever has second chance to vote
        sender.chance--;    //sender have no long any chance to vote
    }

    function result() public view returns (string memory){
        //voting must be ended to see result
        require(
            block.timestamp >= end_time,
            "Voting time is not over yet"
        );
        //if less than half voted the voting will be canceled
        if(vote_counts < limit_votes/2){
            return "CANCELED";
        }
        //find the winner candidate
        uint max_count;
        string memory max_name;
        bool same_count;
        for (uint i = 0; i<candidates.length;i++){
            if( candidate_votes[i] == max_count){
                same_count = true;
            }else if(candidate_votes[i] > max_count){
                same_count = false;
                max_count = candidate_votes[i];
                max_name = candidates[i];
            }
        }
        //if some of candidates have same number of votes there is no winner
        if(same_count){
            return "NO_WINNER";
        }else{
            return max_name;
        }
    }

    //this function return time - it is for debugging part
    function Time_call() public view returns (uint){
        return block.timestamp;
    }

    //chairman can extend the time of the voting
    function time_extention(uint _new_time) public{
        require(
            msg.sender == chairman,
            "Only chairman can stop voting!"
        );
        //the new end-time should be after the old one
        require(
            _new_time>end_time,
            "previous end time > the new end time"
        );
        end_time = _new_time;
    }


}