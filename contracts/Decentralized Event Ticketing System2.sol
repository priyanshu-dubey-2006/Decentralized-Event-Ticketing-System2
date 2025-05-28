// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralizedEventTicketingSystem {
    
    struct Event {
        uint256 eventId;
        string eventName;
        string eventDescription;
        uint256 ticketPrice;
        uint256 totalTickets;
        uint256 availableTickets;
        uint256 eventDate;
        address organizer;
        bool isActive;
    }
    
    struct Ticket {
        uint256 ticketId;
        uint256 eventId;
        address owner;
        bool isUsed;
        uint256 purchaseTime;
    }
    
    mapping(uint256 => Event) public events;
    mapping(uint256 => Ticket) public tickets;
    mapping(address => uint256[]) public userTickets;
    mapping(uint256 => uint256[]) public eventTickets;
    
    uint256 public nextEventId = 1;
    uint256 public nextTicketId = 1;
    
    event EventCreated(uint256 indexed eventId, string eventName, address indexed organizer);
    event TicketPurchased(uint256 indexed ticketId, uint256 indexed eventId, address indexed buyer);
    event TicketUsed(uint256 indexed ticketId, uint256 indexed eventId);
    
    modifier onlyEventOrganizer(uint256 _eventId) {
        require(events[_eventId].organizer == msg.sender, "Only event organizer can perform this action");
        _;
    }
    
    modifier eventExists(uint256 _eventId) {
        require(events[_eventId].eventId != 0, "Event does not exist");
        _;
    }
    
    modifier ticketExists(uint256 _ticketId) {
        require(tickets[_ticketId].ticketId != 0, "Ticket does not exist");
        _;
    }
    
    /**
     * @dev Create a new event with specified details
     * @param _eventName Name of the event
     * @param _eventDescription Description of the event
     * @param _ticketPrice Price per ticket in wei
     * @param _totalTickets Total number of tickets available
     * @param _eventDate Event date as Unix timestamp
     */
    function createEvent(
        string memory _eventName,
        string memory _eventDescription,
        uint256 _ticketPrice,
        uint256 _totalTickets,
        uint256 _eventDate
    ) external {
        require(_totalTickets > 0, "Total tickets must be greater than 0");
        require(_eventDate > block.timestamp, "Event date must be in the future");
        require(bytes(_eventName).length > 0, "Event name cannot be empty");
        
        events[nextEventId] = Event({
            eventId: nextEventId,
            eventName: _eventName,
            eventDescription: _eventDescription,
            ticketPrice: _ticketPrice,
            totalTickets: _totalTickets,
            availableTickets: _totalTickets,
            eventDate: _eventDate,
            organizer: msg.sender,
            isActive: true
        });
        
        emit EventCreated(nextEventId, _eventName, msg.sender);
        nextEventId++;
    }
    
    /**
     * @dev Purchase a ticket for a specific event
     * @param _eventId ID of the event to purchase ticket for
     */
    function purchaseTicket(uint256 _eventId) external payable eventExists(_eventId) {
        Event storage eventInfo = events[_eventId];
        
        require(eventInfo.isActive, "Event is not active");
        require(eventInfo.availableTickets > 0, "No tickets available");
        require(msg.value == eventInfo.ticketPrice, "Incorrect payment amount");
        require(block.timestamp < eventInfo.eventDate, "Event has already occurred");
        
        // Create new ticket
        tickets[nextTicketId] = Ticket({
            ticketId: nextTicketId,
            eventId: _eventId,
            owner: msg.sender,
            isUsed: false,
            purchaseTime: block.timestamp
        });
        
        // Update mappings
        userTickets[msg.sender].push(nextTicketId);
        eventTickets[_eventId].push(nextTicketId);
        
        // Update event availability
        eventInfo.availableTickets--;
        
        // Transfer payment to event organizer
        payable(eventInfo.organizer).transfer(msg.value);
        
        emit TicketPurchased(nextTicketId, _eventId, msg.sender);
        nextTicketId++;
    }
    
    /**
     * @dev Use/validate a ticket for event entry
     * @param _ticketId ID of the ticket to be used
     */
    function useTicket(uint256 _ticketId) external ticketExists(_ticketId) {
        Ticket storage ticket = tickets[_ticketId];
        Event storage eventInfo = events[ticket.eventId];
        
        require(msg.sender == eventInfo.organizer, "Only event organizer can validate tickets");
        require(!ticket.isUsed, "Ticket has already been used");
        require(eventInfo.isActive, "Event is not active");
        
        ticket.isUsed = true;
        
        emit TicketUsed(_ticketId, ticket.eventId);
    }
    
    // View functions
    function getEvent(uint256 _eventId) external view returns (Event memory) {
        return events[_eventId];
    }
    
    function getTicket(uint256 _ticketId) external view returns (Ticket memory) {
        return tickets[_ticketId];
    }
    
    function getUserTickets(address _user) external view returns (uint256[] memory) {
        return userTickets[_user];
    }
    
    function getEventTickets(uint256 _eventId) external view returns (uint256[] memory) {
        return eventTickets[_eventId];
    }
    
    function verifyTicketOwnership(uint256 _ticketId, address _user) external view returns (bool) {
        return tickets[_ticketId].owner == _user && tickets[_ticketId].ticketId != 0;
    }
}
