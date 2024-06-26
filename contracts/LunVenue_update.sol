/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Contract to agree on the lunch venue
/// @author Dilum Bandara, CSIRO's Data61

contract LunchVenue{
    
    struct Friend {
        string name;
        bool voted; //Vote state
    }
    
    struct Vote {
        address voterAddress;
        uint restaurant;
    }

    mapping (uint => string) public restaurants; //List of restaurants (restaurant no, name)
    mapping(address => Friend) public friends;  //List of friends (address, Friend)
    mapping(string => bool) public restaurantExists; //To check if a restaurant exists (name, boolean)
    uint public numRestaurants = 0;
    uint public numFriends = 0;
    uint public numVotes = 0;
    address public manager;                     //Contract manager
    string public votedRestaurant = "";         //Where to have lunch

    mapping (uint => Vote) public votes;        //List of votes (vote no, Vote)
    mapping (uint => uint) private _results;    //List of vote counts (restaurant no, no of votes)
    bool public voteOpen = false;               //voting is open
    bool public isActive = true;                //Contract is active
    uint public votingDDL;                      //When voting time is up

    /**
     * @dev Set manager when contract starts
     */
    constructor () {
        manager = msg.sender;                   //Set contract creator as manager
    }

    /**
     * @notice Add a new restaurant
     *
     * @param name Restaurant name
     * @return Number of restaurants added so far
     */
    function addRestaurant(string memory name) public restricted whenActive returns (uint){
        require(!voteOpen, "Cannot add restaurants while voting is open");
        require(!restaurantExists[name], "Restaurant already exists");
        numRestaurants++;
        restaurants[numRestaurants] = name;
        restaurantExists[name] = true;
        return numRestaurants;
    }

    /**
     * @notice Add a new friend to voter list
     *
     * @param friendAddress Friend's account/address
     * @param name Friend's name
     * @return Number of friends added so far
     */
    function addFriend(address friendAddress, string memory name) public restricted whenActive returns (uint){
        require(!voteOpen, "Cannot add friends while voting is open");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(friends[friendAddress].name).length == 0, "Friend already exists");
        Friend memory f;
        f.name = name;
        f.voted = false;
        friends[friendAddress] = f;
        numFriends++;
        return numFriends;
    }
    
    /** 
     * @notice Vote for a restaurant
     * @dev To simplify the code duplicate votes by a friend is not checked
     *
     * @param restaurant Restaurant number being voted
     * @return validVote Is the vote valid? A valid vote should be from a registered 
     * friend to a registered restaurant
    */
    function doVote(uint restaurant) public votingOpen whenActive returns (bool validVote){
        require(!friends[msg.sender].voted, "You have already voted a restaurant");
        require(block.number <= votingDDL, "Voting time has passed");
        validVote = false;                                  //Is the vote valid?
        if (bytes(friends[msg.sender].name).length != 0) {  //Does friend exist?
            if (bytes(restaurants[restaurant]).length != 0) {   //Does restaurant exist?
                validVote = true;
                friends[msg.sender].voted = true;
                Vote memory v;
                v.voterAddress = msg.sender;
                v.restaurant = restaurant;
                numVotes++;
                votes[numVotes] = v;
                _results[restaurant++];
            }
        }
        
        if (numVotes >= numFriends/2 + 1) { //Quorum is met
            finalResult();
        }
        return validVote;
    }

    /** 
     * @notice Determine winner restaurant
     * @dev If top 2 restaurants have the same no of votes, result depends on vote order
    */
    function finalResult() private{
        uint highestVotes = 0;
        uint highestRestaurant = 0;
        
        for (uint i = 1; i <= numRestaurants; i++){   //For each vote
            if (_results[i] > highestVotes) {
                highestVotes = _results[i];
                highestRestaurant = i;
            }
        }
        votedRestaurant = restaurants[highestRestaurant];   //Chosen restaurant
        voteOpen = false;                                   //Voting is now closed
    }

    /** 
     * @notice stop the contract
    */
    function stopContract() public restricted whenActive {
        isActive = false;
    }

    function startVoting(uint timeout) public  restricted whenActive {
        require(!voteOpen, "Volting is already opened");
        require(numFriends > 0 && numRestaurants > 0, "At least having one restaurants and firends");
        votingDDL = timeout + block.number;
        voteOpen = true;
    }
    
    /** 
     * @notice Only the manager can do
     */
    modifier restricted() {
        require (msg.sender == manager, "Can only be executed by the manager");
        _;
    }
    
    /**
     * @notice Only when voting is still open
     */
    modifier votingOpen() {
        require(voteOpen == true, "Can vote only while voting is open.");
        _;
    }

    /**
     * @notice Only when contract is active
     */
     modifier whenActive() {
        require(isActive == true, "Contract is stopped");
        _;
     }
}