#!/usr/bin/env python
import sys
import time
from datetime import datetime
import socket
import struct
import argparse
import logging
import pickle

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.WARNING)

logger = logging.getLogger('mctest')

group = '232.9.X.X'
mport = 19000
mttl = 10
message = 'multicast test tool'

parser = argparse.ArgumentParser()
parser = argparse.ArgumentParser(description='Multicast Send/Receive Test Tool')
parser.add_argument("-send", metavar="string", help="Send a Message", type=str)
parser.add_argument("-receive", help="Receive Messages from Group", action="store_true")
parser.add_argument("-group", metavar="Multicast Group (default: 232.9.X.X)", type=str)
parser.add_argument("-port", metavar="UDP Port", help="UDP Port to receive on (default 19000)")
parser.add_argument('-ttl', metavar='int', help="Multicast TTL (default 10)", type=int)
parser.add_argument("-v", help="Verbose Output", action="store_true")
args = parser.parse_args()

def receiver(mgroup):
    # Receive msg on a multicast group
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    # Windows workaround
    try:
        sock.bind((mgroup, mport))
    except socket.error:
        sock.bind(('', mport))

    mreq = struct.pack("4sl", socket.inet_aton(group), socket.INADDR_ANY)

    sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
    sock.settimeout(5)

    while True:
        try:
            (data, address) = sock.recvfrom(12000)
        except Exception as e:
            # receive msg timeout
            print("receive msg timeout")
            sys.exit(1)

        # Try to unpickle log record from a DatagramHandler
        try:
            lrtxt = pickle.loads(data[4:])
            lr = logging.makeLogRecord(lrtxt)
            logger.handle(lr)

        # Print message normally
        except Exception as e:
            # receive msg success
            print('Received on ' + mgroup + ' from ' + address[0] + ' from port ' + str(address[1]) + ': ' + data)
            sys.exit(0)

def sender(mgroup):
    # Send msg to a multicast group
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    ttl_bin = struct.pack('@i', mttl)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, ttl_bin)
    times = 10
    while times:
        time_now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        mcast_msg = message + ': ' + time_now
        print('Sending msg to ' + mgroup + ' (TTL ' + str(mttl) + '): ' + mcast_msg)
        sock.sendto(mcast_msg, (mgroup, mport))
        time.sleep(1)
        times = times - 1

if args.group:
    group = args.group
if args.ttl:
    mttl = int(args.ttl)
if args.port:
    mport = int(args.port)

if args.send:
    message = args.send
    sender(group)
elif args.receive:
    print(receiver(group))
else:
    parser.print_help()