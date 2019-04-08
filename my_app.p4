#include <core.p4>
#include <v1model.p4>

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<48> time_t;

typedef bit<1> flag;
#define MAX_PORTS 255



//register<bit<1>>(1) need_drop;
register<bit<32>>(1024) counter_1;
register<bit<32>>(1024) counter_2;

struct meter_metadata_t {
    bit<16> meter_index;
}
//counter(MAX_PORTS, CounterType.bytes) rx_port_counter;

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}


header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}


header udp_t{
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header stream_t{
    bit<8> lid;
    bit<8> tid;
    bit<8> qid;
    bit<8> reserved;
    bit<32> naluid;
    bit<16> total_size;
    bit<16> frame_number;
}

header rtp_t{
    bit<2> version;
    bit<1> padding;
    bit<1> extension;
    bit<4> cc;
    bit<1> marker;
    bit<7> payloadtype;
    bit<16> sequence;
    bit<32> timestamp;
    bit<32> SSRC;
}

header ts{
    bit<8> sync_byte;
    bit<1> transport_error_indicator;
    bit<1> payload_unit_start_indicator; //1 start unit
    bit<1> transport_priority;
    bit<13> pid;
    bit<2> transport_scrambling_control;
    bit<2> adaptation_field_control; //01 payload only 11 adaptation 
    //field and payload
    bit<4> continuity_counter;
    bit<8> adapation_field;
}

header pes{
    /*0x000001*/
    bit<24> packet_start_code_prefix;
    bit<8> stream_id;
    bit<16> PES_packet_length;
    bit<16> extension;
    bit<8> header_data_length;
    bit<40> pre_time_stamp;
    bit<40> decode_time_stamp;
}

header nalu{
    bit<48> AUD;
    bit<24> prefix;  
    bit<8> nalu_header;
} 

header h264_nal{
    bit<1>  F;
    bit<2> NRI;  // 0 1 2 3
    bit<5> type; 
}

header svc_extend{
    bit<1> reserved;
    bit<1> idr;
    bit<6> priority;
    bit<1> no_inter_layer_pre;
    bit<3> dependency;
    bit<4> quality;
    bit<3> temporal;
    bit<1> use_base_ref;
    bit<1> discardable;
    bit<1> output;
    bit<2> reserved_2; 
}


struct metadata{
    bit<1> result;
    bit<32> result_1;
    bit<32> result_2;
}

struct headers{
    ethernet_t ethernet;
    ipv4_t ipv4;
    tcp_t tcp;
    udp_t udp;
    stream_t stream;
    //rtp_t rtp;
    //h264_nal h264;
    //svc_extend svc;

}


parser MyParser(packet_in packet, 
                out headers hdr, 
                inout metadata meta, 
                inout standard_metadata_t standard_metadata) {

    state start{
        transition parse_ethernet;
    }

    state parse_ethernet {

        packet.extract(hdr.ethernet);

        transition select(hdr.ethernet.etherType) {
            0x800: parse_ipv4;
            default:accept;
        }
    }


    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
            6 : parse_tcp;
            0x11: parse_udp;
            default:accept;
        }
    }

     state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp{
        packet.extract(hdr.udp);
        transition select(hdr.udp.dst_port){
            0x1167: parse_stream;
            default:accept;
        }
    }
    state parse_stream{
        packet.extract(hdr.stream);
        transition accept;
    }
/*
    state parse_rtp{
        packet.extract(hdr.rtp);
        transition parse_h264;
    }

    state parse_h264{
        packet.extract(hdr.h264);
        transition select(hdr.h264.type){
            14 : parse_svc;
            default:accept;
        }
    }

    state parse_svc{
        packet.extract(hdr.svc);
        transition accept;
    }
    */

}



control verifyChecksum(inout headers hdr, inout metadata meta) {

    apply {    }
}


control ingress(inout headers hdr, 
                inout metadata meta, 
                inout standard_metadata_t standard_metadata) {

   
   
//    meter(1024,MeterType.bytes) bitrate;
    action drop() {
        mark_to_drop();
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port){
            standard_metadata.egress_spec = port;
            hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
            hdr.ethernet.dstAddr = dstAddr;
            
            hdr.ipv4.ttl=hdr.ipv4.ttl-1;

            //bit<8> color;
            //bitrate.execute_meter<bit<8>>((bit<32>) standard_metadata.ingress_port,color);
            
            //hdr.ipv4.diffserv=color+1;
            
            
    }
    action count_1(){
        
        counter_1.read(meta.result_1,0);
        counter_1.write(0,meta.result_1+1);
    }

    action count_2(){
        
        counter_2.read(meta.result_2,0);
        counter_2.write(0,meta.result_2+1);
    }

    table ipv4_lpm {
    
        actions = {
            ipv4_forward;
            drop(); 
        }
    
        key = {
            hdr.ipv4.dstAddr : lpm;
        }
    
        size = 1024;
        default_action = drop();
    }

    table stream_match{
        actions={
            count_1;
        }
        key = {
            hdr.udp.dst_port: exact;
        }
    }

    table tcp_match{
        actions={
            count_2;
        }
        key = {
            hdr.ipv4.protocol:exact;
        }
    }

    apply {

        if(hdr.stream.isValid()){
            stream_match.apply();
        } 
        if(hdr.tcp.isValid()){
           tcp_match.apply();
        }
        if(hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
           
        }
    }
}




control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    /*action change_register(bit<1> value){
        
        hdr.ipv4.diffserv = (bit<8>) meta.result_1;
        need_drop.write(0,value);
        
    }*/
    

    action layer_drop(){

            mark_to_drop();

    }
    table spatial_scal{
        actions={
            layer_drop;
        }
        key={
            hdr.stream.lid: exact;
        }
        size = 1024;
    }
    table temporal_scal{
        actions={
            layer_drop;
        }
        key={
            hdr.stream.tid:exact;
        }
        size = 1024;
    }
    table quality_scal{
        actions={
            layer_drop;
        }
        key={
            hdr.stream.qid:exact;
        }
        size = 1024;
    }

    apply{
      if(hdr.stream.isValid()){

           /*
           if(hdr.stream.isValid() && meta.result_1<meta.result_2){ //RTP<TCP
             ...
           }
           if(hdr.stream.isValid() && 2*meta.result_1<meta.result_2){ //2*RTP<TCP
            ...
           }
           ...
           */

            spatial_scal.apply();
           temporal_scal.apply();
           quality_scal.apply();
            
            //need_drop.read(meta.result,0);
           // if(meta.result==1){
           //     layer.apply();
           // }
            
        }
        
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {

    apply {  
    update_checksum(
        hdr.ipv4.isValid(),
            { hdr.ipv4.version,
              hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }  
}


control DeparserImpl(packet_out packet, in headers hdr) {

    apply {

        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        packet.emit(hdr.stream);
        //packet.emit(hdr.rtp);
       // packet.emit(hdr.h264);
       // packet.emit(hdr.svc);
    }
}

V1Switch(MyParser(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;