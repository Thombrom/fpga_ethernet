#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>

#define MY_DEST_MAC0	0x12
#define MY_DEST_MAC1	0x34
#define MY_DEST_MAC2	0x56
#define MY_DEST_MAC3	0x78
#define MY_DEST_MAC4	0x9a
#define MY_DEST_MAC5	0xbc

#define DEFAULT_IF	"enp0s31f6"
#define BUF_SIZ		2048

char udp_packet[] = {
    0x45, 0x00, 0x00, 0x24,
    0x7d, 0x2f, 0x40, 0x00,
    0x40, 0x11, 0xf3, 0xf2,
    0xc0, 0xa8, 0x00, 0x01,
    0xc0, 0xa8, 0x00, 0x02,
    0x05, 0xfe, 0x05, 0xfe,
    0x00, 0x10, 0xc9, 0xc8,
    0x54, 0x43, 0x46, 0x32,
    0x04, 0x00, 0x00, 0x00,

};

char arp_packet[] = {
    0x00, 0x01, 0x08, 0x00,
    0x06, 0x04, 0x00, 0x01,
    0x10, 0x65, 0x30, 0x70,     // Make sure to put your own MAC address as sender MAC
    0x3d, 0x6d, 0xc0, 0xa8,     // and configure with the relevant IP address that you want
    0x00, 0x02, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0xc0, 0xa8, 0x00, 0x01,
};


int main(int argc, char *argv[])
{
    uint32_t broadcast = 0;
    uint16_t ether_type = ETH_P_IP;

	int sockfd;
	struct ifreq if_idx;
	struct ifreq if_mac;
	int tx_len = 0;
	char sendbuf[BUF_SIZ];
	struct ether_header *eh = (struct ether_header *) sendbuf;
	struct iphdr *iph = (struct iphdr *) (sendbuf + sizeof(struct ether_header));
	struct sockaddr_ll socket_address;
	char ifName[IFNAMSIZ];
	
	/* Get interface name */
	if (argc > 1)
		strcpy(ifName, argv[1]);
	else
		strcpy(ifName, DEFAULT_IF);

	/* Open RAW socket to send on */
	if ((sockfd = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) == -1) {
	    perror("socket");
	}

	/* Get the index of the interface to send on */
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, ifName, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFINDEX, &if_idx) < 0)
	    perror("SIOCGIFINDEX");
	/* Get the MAC address of the interface to send on */
	memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, ifName, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFHWADDR, &if_mac) < 0)
	    perror("SIOCGIFHWADDR");

	/* Construct the Ethernet header */
	memset(sendbuf, 0, BUF_SIZ);
	/* Ethernet header */
	eh->ether_shost[0] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[0];
	eh->ether_shost[1] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[1];
	eh->ether_shost[2] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[2];
	eh->ether_shost[3] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[3];
	eh->ether_shost[4] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[4];
	eh->ether_shost[5] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[5];
	eh->ether_dhost[0] = broadcast ? 0xff : MY_DEST_MAC0;
	eh->ether_dhost[1] = broadcast ? 0xff : MY_DEST_MAC1;
	eh->ether_dhost[2] = broadcast ? 0xff : MY_DEST_MAC2;
	eh->ether_dhost[3] = broadcast ? 0xff : MY_DEST_MAC3;
	eh->ether_dhost[4] = broadcast ? 0xff : MY_DEST_MAC4;
	eh->ether_dhost[5] = broadcast ? 0xff : MY_DEST_MAC5;
	/* Ethertype field */
	eh->ether_type = htons(ether_type);
	tx_len += sizeof(struct ether_header);

	/* Packet data */
    char* packet_data   = udp_packet;
    uint32_t packet_len = sizeof(arp_packet) / sizeof(char);

    for (size_t itt = 0; itt < packet_len; itt++)
        sendbuf[tx_len++] = packet_data[itt];

	/* Index of the network device */
	socket_address.sll_ifindex = if_idx.ifr_ifindex;
	/* Address length*/
	socket_address.sll_halen = ETH_ALEN;
	/* Destination MAC */
	socket_address.sll_addr[0] = MY_DEST_MAC0;
	socket_address.sll_addr[1] = MY_DEST_MAC1;
	socket_address.sll_addr[2] = MY_DEST_MAC2;
	socket_address.sll_addr[3] = MY_DEST_MAC3;
	socket_address.sll_addr[4] = MY_DEST_MAC4;
	socket_address.sll_addr[5] = MY_DEST_MAC5;

	/* Send packet */
	for (size_t itt = 0; itt < 200000; itt++)
	    if (sendto(sockfd, sendbuf, tx_len, 0, (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll)) < 0)
	    	printf("Send failed\n");

	return 0;
}
