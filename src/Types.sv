package Types;
    // Enum for specifying where in the ethernet frame we
    // are operating
    typedef enum bit [2:0] {        
        ETH_INTERPACKET_GAP,    // Space between packets                            (12= bytes)
        ETH_PREAMBLE,           // The 1-0-1-0 ... 1-0-1-1 alternating preamble     (8 octets)
        ETH_MAC_DESTINATION,    // Destination mac adress                           (6 bytes)
        ETH_MAC_SOURCE,         // Source mac adress                                (6 bytes)
        ETH_ETHER_TYPE,         // Type (or length)                                 (2 bytes)
        ETH_PAYLOAD,            // Frame payload - usually IPv4 type                (46-1500 bytes)
        ETH_CRC                 // Cyclic reduncancy check                          (4 bytes)
    } e_eth_frame_section;    
    
    typedef struct packed {
        bit[47:0] mac_destination;
        bit[47:0] mac_source;
        bit[15:0] ether_type;
    } st_eth_header;

    // Types of protocols on top 
    // of the Ethernet protocol
    typedef enum bit [15:0] {
        IPV4 = 16'h0800,
        ARP  = 16'h0806,
        IPV6 = 16'h86DD         // Will not be supported in this project
    } e_ether_type;
    
    typedef enum bit [3:0] {
        IPV4_HEADER,
        IPV4_PAYLOAD
    } e_ipv4_section;
    
    typedef enum bit [7:0] {
        TCP = 8'h06,
        UDP = 8'h11
    } e_ipv4_type;
    
    typedef struct packed {
        bit [3:0]  version;             // Will be 4 for all our intents and purposes
        bit [3:0]  ihl;                 // Number of 32-bit words in header
        bit [5:0]  dscp;                // Don't care
        bit [1:0]  ecn;                 // Don't care
        bit [15:0] length;              // Total length of the IPV4 packet including header
        bit [15:0] ident;               // IP fragmentation identifier - Don't care
        bit [2:0]  flags;               // Don't really care - we're not supporting fragmentation anyways
        bit [12:0] offset;              // Fragment offset - Don't care as we don't support fragmentation
        bit [7:0]  ttl;                 // Time to live. We don't care about this.
        bit [7:0]  protocol;            // Protocol building on top of the IPv4 packet
        bit [15:0] checksum;            // Checksum generated on the header - Currently we don't do anything with this
        bit [31:0] source_addr;         // Source IP address
        bit [31:0] destination_addr;    // Destination IP address
    } st_ipv4_header;
    
    typedef enum bit [15:0] {
        LINK_PROTOCOL_ETHERNET  = 16'h01
    } e_link_protocol;
    
    typedef enum bit [15:0] {
        ARP_OPER_REQUEST        = 16'h01,
        ARP_OPER_REPLY          = 16'h02
    } e_arp_oper;
    
    typedef struct packed {
        bit [15:0] htype;               // Network link protocol - We only support ETHERNET
        bit [15:0] ptype;               // Protocol type         - We only support IPv4
        bit [7:0]  hlen;                // Only support the value 6
        bit [7:0]  plen;                // Only support the value 4
        bit [15:0] oper;                // operation
        
        bit [47:0] sender_hardware_address; // Senders MAC address
        bit [31:0] sender_protocol_address; // Senders IP address
        bit [47:0] target_hardware_address; // Target MAC address
        bit [31:0] target_protocol_address; // Target IP address 
    } st_arp_packet;
    
    typedef struct packed {
        bit [47:0]  destination_addr;
        bit [47:0]  source_addr;
        bit [15:0]  eth_type;
        bit [367:0] payload;
    } st_eth_packet;
endpackage