/*
Copyright 2019 Cisco Systems, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <core.p4>
#include <v1model.p4>


// The intent of this program is to exercise most or all of the types
// supported by the P4Runtime v1.0 specification.  It is not intended
// to be an example of a useful program for packet processing, but
// more of a stress test for corner cases of the P4 tools.

// According to the restriction in Section 20 of the specification,
// this is a fairly restricted list for these places in a program:

// + table search key fields
// + value_set search fields
// + action parameters
// + controller_header metadata fields

// In those places, the only types supported are:

// + bit<W>
// + enum bit<W>, aka serializable enums
// + typedef based upon one of the types above, or on a 'type'

// + type based upon one of the types above, with two variants that
//   affect P4Info file generation and the behavior of a P4Runtime
//   server:
//   + with a @p4runtime_translation("uri_string", bitwidth_integer) annotation
//   + without such an annotation


// Naming convention used here:

// 0 means a `typedef`
// 1 means a `type` without a @p4runtime_translation annotation
// 2 means a  `type` with a @p4runtime_translation annotation

// Since types and typedefs can be defined in terms of each other, the
// names I use here contain sequences of digits 0, 1, and 2 to
// indicate the order in which they have been "stacked", e.g. Eth01_t
// is a `type` (the 1 is last) defined on type of a `typedef` (the 0
// just before the 1).

// I am choosing to make the URI strings and bitwidths in all
// occurrences of a p4runtime_tranlsation annotation different from
// each other, to make it easier to tell from the output which
// annotation was used in any particular instance, and catch any
// mistakes that may exist in the compiler.

// All ways to have a single type or typedef on a bit<8>
typedef bit<48> Eth0_t;
type    bit<48> Eth1_t;
@p4runtime_translation("mycompany.com/EthernetAddress", 49)
type    bit<48> Eth2_t;

// All possible ways to have a second type or typedef on top of any of
// the 3 above.

typedef bit<8>     Custom0_t;
type    bit<8>     Custom1_t;
@p4runtime_translation("mycompany.com/My_Byte2", 12)
type    bit<8>     Custom2_t;

typedef Custom0_t  Custom00_t;
type    Custom0_t  Custom01_t;
@p4runtime_translation("mycompany.com/My_Byte3", 13)
type    Custom0_t  Custom02_t;

typedef Custom1_t  Custom10_t;
type    Custom1_t  Custom11_t;
@p4runtime_translation("mycompany.com/My_Byte4", 14)
type    Custom1_t  Custom12_t;

typedef Custom2_t  Custom20_t;
type    Custom2_t  Custom21_t;
@p4runtime_translation("mycompany.com/My_Byte5", 15)
type    Custom2_t  Custom22_t;

// Starting here I will not exhaustively enumerate all possible
// 'stackings', but pick a few selected ones.

type    Custom00_t Custom001_t;
@p4runtime_translation("mycompany.com/My_Byte6", 16)
type    Custom00_t Custom002_t;

type    Custom10_t Custom101_t;
@p4runtime_translation("mycompany.com/My_Byte7", 17)
type    Custom10_t Custom102_t;

type    Custom20_t Custom201_t;
@p4runtime_translation("mycompany.com/My_Byte8", 18)
type    Custom20_t Custom202_t;

typedef Custom22_t Custom220_t;

typedef Custom002_t  Custom0020_t;
typedef Custom0020_t Custom00200_t;
type    Custom00200_t Custom002001_t;
@p4runtime_translation("mycompany.com/My_Byte9", 19)
type    Custom00200_t Custom002002_t;

typedef Custom002001_t Custom0020010_t;
typedef Custom002002_t Custom0020020_t;

header ethernet_t {
    Eth0_t  dstAddr;
    Eth1_t  srcAddr;
    bit<16> etherType;
}

// Note: When I uncomment the #define PROBLEM_NESTED_STRUCT_FIELD_TYPE
// line below, I get an error when compiling, even with this version
// of Hemant Singh's proposed changes for handling more types:

// $ git clone https://github.com/familysingh/p4c
// $ cd p4c
// $ git log -n 1 | head -n 3
// commit 8964809fbce40032a6fa9a0a2d11785fea66996f
// Author: hemant_mnkcg <hemant@mnkcg.com>
// Date:   Thu Mar 7 19:32:58 2019 -0500

//#define PROBLEM_NESTED_STRUCT_FIELD_TYPE
#undef PROBLEM_NESTED_STRUCT_FIELD_TYPE

struct struct1_t {
    bit<7> x;
    bit<9> y;
#ifdef PROBLEM_NESTED_STRUCT_FIELD_TYPE
    Custom0020010_t z;
#endif  // PROBLEM_NESTED_STRUCT_FIELD_TYPE
}

header custom_t {
    Eth0_t      addr0;
    Eth1_t      addr1;
    Eth2_t      addr2;
    bit<8>      e;

    Custom0_t   e0;
    Custom1_t   e1;
    Custom2_t   e2;

    Custom00_t  e00;
    Custom01_t  e01;
    Custom02_t  e02;

    Custom10_t  e10;
    Custom11_t  e11;
    Custom12_t  e12;

    Custom20_t  e20;
    Custom21_t  e21;
    Custom22_t  e22;

    Custom001_t  e001;
    Custom002_t  e002;
    Custom101_t  e101;
    Custom102_t  e102;
    Custom201_t  e201;
    Custom202_t  e202;
    Custom220_t  e220;

    Custom0020010_t e0020010;
    Custom0020020_t e0020020;

    struct1_t my_nested_struct1;

    bit<16>     checksum;
}

struct headers_t {
    ethernet_t ethernet;
    custom_t   custom;
}


enum enum1_t {
    A,
    B,
    C
}

// Note: When I uncomment the #define PROBLEM_DIGEST_MSG_FIELD_TYPE
// line below, many additional fields are added to the struct
// digest_msg1_t, which is the set of fields in a digest message
// created by the send_digest_msg1 action below.  All of the fields
// disabled when you #undef PROBLEM_DIGEST_MSG_FIELD_TYPE cause the
// compiler to crash while attempting to write the P4Info file, even
// with this version of Hemant Singh's proposed changes for handling
// more types:

// $ git clone https://github.com/familysingh/p4c
// $ cd p4c
// $ git log -n 1 | head -n 3
// commit 8964809fbce40032a6fa9a0a2d11785fea66996f
// Author: hemant_mnkcg <hemant@mnkcg.com>
// Date:   Thu Mar 7 19:32:58 2019 -0500

//#define PROBLEM_DIGEST_MSG_FIELD_TYPE
#undef PROBLEM_DIGEST_MSG_FIELD_TYPE


struct digest_msg1_t {
    Eth0_t      addr0;
#ifdef PROBLEM_DIGEST_MSG_FIELD_TYPE
    Eth1_t      addr1;
    Eth2_t      addr2;
#endif  // PROBLEM_DIGEST_MSG_FIELD_TYPE
    bit<8>      e;

    Custom0_t   e0;
#ifdef PROBLEM_DIGEST_MSG_FIELD_TYPE
    Custom1_t   e1;
    Custom2_t   e2;
#endif  // PROBLEM_DIGEST_MSG_FIELD_TYPE

    Custom00_t  e00;
    Custom01_t  e01;
    Custom02_t  e02;

#ifdef PROBLEM_DIGEST_MSG_FIELD_TYPE
    Custom10_t  e10;
    Custom11_t  e11;
    Custom12_t  e12;

    Custom20_t  e20;
    Custom21_t  e21;
    Custom22_t  e22;
#endif  // PROBLEM_DIGEST_MSG_FIELD_TYPE

    Custom001_t  e001;
    Custom002_t  e002;
#ifdef PROBLEM_DIGEST_MSG_FIELD_TYPE
    Custom101_t  e101;
    Custom102_t  e102;
    Custom201_t  e201;
    Custom202_t  e202;
    Custom220_t  e220;
#endif  // PROBLEM_DIGEST_MSG_FIELD_TYPE

    Custom0020010_t e0020010;
    Custom0020020_t e0020020;

    bool my_bool;
    error my_error;
    enum1_t my_enum1;
    struct1_t my_nested_struct1;

    // TBD: Could also try out other things here, too.  Maybe later.

    // varbit
    // header
    // header stack
    // header_union
    // struct nested one level deeper than my_nested_struct1
    // tuple
}


struct metadata_t {
    digest_msg1_t       digest_msg1;
}

action my_drop() {
    mark_to_drop();
}

parser ParserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    const bit<16> ETHERTYPE_CUSTOM = 0xdead;

    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_CUSTOM: parse_custom;
            default: accept;
        }
    }
    state parse_custom {
        packet.extract(hdr.custom);
        transition accept;
    }
}

control ingress(inout headers_t hdr,
                inout metadata_t meta,
                inout standard_metadata_t stdmeta)
{
    action set_output(bit<9> out_port) {
        stdmeta.egress_spec = out_port;
    }

    action send_digest_msg1 () {
        meta.digest_msg1.addr0 = hdr.custom.addr0;
#ifdef PROBLEM_DIGEST_MSG_FIELD_TYPE
        meta.digest_msg1.addr1 = hdr.custom.addr1;
        meta.digest_msg1.addr2 = hdr.custom.addr2;
#endif  // PROBLEM_DIGEST_MSG_FIELD_TYPE
        meta.digest_msg1.e = hdr.custom.e;

        meta.digest_msg1.e0 = hdr.custom.e0;
#ifdef PROBLEM_DIGEST_MSG_FIELD_TYPE
        meta.digest_msg1.e1 = hdr.custom.e1;
        meta.digest_msg1.e2 = hdr.custom.e2;
#endif  // PROBLEM_DIGEST_MSG_FIELD_TYPE

        meta.digest_msg1.e00 = hdr.custom.e00;
        meta.digest_msg1.e01 = hdr.custom.e01;
        meta.digest_msg1.e02 = hdr.custom.e02;

#ifdef PROBLEM_DIGEST_MSG_FIELD_TYPE
        meta.digest_msg1.e10 = hdr.custom.e10;
        meta.digest_msg1.e11 = hdr.custom.e11;
        meta.digest_msg1.e12 = hdr.custom.e12;

        meta.digest_msg1.e20 = hdr.custom.e20;
        meta.digest_msg1.e21 = hdr.custom.e21;
        meta.digest_msg1.e22 = hdr.custom.e22;
#endif  // PROBLEM_DIGEST_MSG_FIELD_TYPE

        meta.digest_msg1.e001 = hdr.custom.e001;
        meta.digest_msg1.e002 = hdr.custom.e002;
#ifdef PROBLEM_DIGEST_MSG_FIELD_TYPE
        meta.digest_msg1.e101 = hdr.custom.e101;
        meta.digest_msg1.e102 = hdr.custom.e102;
        meta.digest_msg1.e201 = hdr.custom.e201;
        meta.digest_msg1.e202 = hdr.custom.e202;
        meta.digest_msg1.e220 = hdr.custom.e220;
#endif  // PROBLEM_DIGEST_MSG_FIELD_TYPE

        meta.digest_msg1.e0020010 = hdr.custom.e0020010;
        meta.digest_msg1.e0020020 = hdr.custom.e0020020;

        meta.digest_msg1.my_bool = true;
        meta.digest_msg1.my_error = stdmeta.parser_error;
        meta.digest_msg1.my_enum1 = enum1_t.A;

        meta.digest_msg1.my_nested_struct1 = hdr.custom.my_nested_struct1;

        digest(1, meta.digest_msg1);
    }

    table custom_table {
        key = {
            hdr.custom.addr0 : exact;
        }
        actions = {
            set_output;
            send_digest_msg1;
            my_drop;
        }
        default_action = my_drop;
    }

    apply {
        if (hdr.custom.isValid()) {
            custom_table.apply();
        }
    }
}

control egress(inout headers_t hdr,
               inout metadata_t meta,
               inout standard_metadata_t stdmeta)
{
    apply { }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.custom);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

V1Switch(ParserImpl(),
         verifyChecksum(),
         ingress(),
         egress(),
         computeChecksum(),
         DeparserImpl()) main;

