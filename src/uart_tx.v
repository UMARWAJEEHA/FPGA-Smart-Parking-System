module main(
input reset,
input clk,
input ir0,
input ir1,
input ir2,
input ir3,
input sw_0,
input sw_limit,
input id,
input RS232_DCE_RXD,
output RS232_DCE_TXD,
output [39:0] receive_data,
output reg orng,
output reg red,
output reg green,
output reg yellow,
output reg [2:0] park_lot,
output reg motor_cw,
output reg motor_ccw
);

parameter rcv_bit_per = 2604; 
parameter half_rcv_bit_per = 1302; 


parameter ready = 2&#39;b00;
parameter start_bit = 2&#39;b01;
parameter data_bits = 2&#39;b10;
parameter stop_bit = 2&#39;b11;

reg [12:0] counter, n_counter;
reg [5:0] data_bit_count, n_data_bit_count;
reg [39:0] rcv_sr, n_rcv_sr;
reg [1:0] p_state, n_state;

assign RS232_DCE_TXD = RS232_DCE_RXD;
assign receive_data = rcv_sr;

wire space;
assign space =(ir1+ir2+ir3);
reg [3:0] state;
parameter [3:0]
STATE_S0=4&#39;b0000,
STATE_S1=4&#39;b0001,
STATE_S2=4&#39;b0010,
STATE_S3=4&#39;b0011,
STATE_S4=4&#39;b0100,
STATE_S5=4&#39;b0101,

STATE_S6=4&#39;b0110,
STATE_S7=4&#39;b0111,
STATE_S8=4&#39;b1000;

always @ (posedge clk or negedge reset)
if (!reset)
state &lt;=STATE_S0;

else
begin
case(state)
STATE_S0:
begin
if (ir0==1)
state &lt;=STATE_S0;
else if (ir0==0)
state &lt;=STATE_S1;
end

STATE_S1:
begin
if (receive_data==93872916)
state &lt;=STATE_S1;
else if (receive_data==93872914)
state &lt;=STATE_S2;

else if (receive_data==93872915)
state &lt;=STATE_S3;
/*else if (id==10)
state &lt;=STATE_S2;*/
end
STATE_S2:
begin
if (ir0==1)
state &lt;=STATE_S0;
else if (ir0==0)
state &lt;=STATE_S2;
end

STATE_S3:
begin
if (space==0) 
state &lt;=STATE_S4;
else if (space==1) 
state &lt;=STATE_S5;
end

STATE_S4:
begin
if (ir0==0)
state &lt;=STATE_S4;

else if (ir0==1)
state &lt;=STATE_S0;
end

STATE_S5:
begin
if (sw_0==1) 
state &lt;=STATE_S6;
else if (sw_0==0) 
state &lt;=STATE_S5;
end

STATE_S6:
begin
if (sw_limit==1)
state &lt;=STATE_S7;
else if (sw_limit==0)
state &lt;=STATE_S6;
end

STATE_S7:
begin
if (ir0==1)
state &lt;=STATE_S8;
else if (ir0==0)

state &lt;=STATE_S7;
end

STATE_S8:
begin
if (sw_0==0)
state &lt;=STATE_S8;
else if (sw_0==1)
state &lt;=STATE_S0;
end
endcase
end

always @(state)
begin

case (state)
STATE_S0:
begin
orng&lt;=1;
red&lt;=1;
green&lt;=1;
yellow&lt;=1;
park_lot[0]&lt;=1;
park_lot[1]&lt;=1;

park_lot[2]&lt;=1;
motor_cw&lt;=1;
motor_ccw&lt;=1;

end

STATE_S1:
begin
orng&lt;=0;
red&lt;=1;
green&lt;=1;
yellow&lt;=1;
park_lot[0]&lt;=1;
park_lot[1]&lt;=1;
park_lot[2]&lt;=1;
motor_cw&lt;=1;
motor_ccw&lt;=1;
end

STATE_S2:
begin
orng&lt;=1;
red&lt;=0;
green&lt;=1;
yellow&lt;=1;

motor_cw&lt;=1;
motor_ccw&lt;=1;
end

STATE_S3:
begin
orng&lt;=1;
red&lt;=1;
green&lt;=~space;
yellow&lt;=1;
park_lot[0]&lt;=1;
park_lot[1]&lt;=1;
park_lot[2]&lt;=1;
motor_cw&lt;=1;
motor_ccw&lt;=1;
end

STATE_S4:
begin
green&lt;=1;
red&lt;=1;
orng&lt;=1;
yellow&lt;=0;
park_lot[0]&lt;=ir1;
park_lot[1]&lt;=ir2;

park_lot[2]&lt;=ir3;
motor_cw&lt;=1;
motor_ccw&lt;=1;
end

STATE_S5:
begin
green&lt;=0;
red&lt;=1;
orng&lt;=1;
yellow&lt;=1;
park_lot[0]&lt;=ir1;
park_lot[1]&lt;=ir2;
park_lot[2]&lt;=ir3;
motor_cw&lt;=1;
motor_ccw&lt;=1;
end

STATE_S6:
begin
motor_cw&lt;=0;
motor_ccw&lt;=1;
end

STATE_S7:

begin
motor_cw&lt;=1;
motor_ccw&lt;=1;
end

STATE_S8:
begin
motor_cw&lt;=1;
motor_ccw&lt;=0;
end

endcase
end

always @(p_state, RS232_DCE_RXD, counter, data_bit_count) begin
n_rcv_sr &lt;= rcv_sr;
n_counter &lt;= counter;
n_state &lt;= p_state;
n_data_bit_count &lt;= data_bit_count;

case (p_state)

ready: begin
if(RS232_DCE_RXD == 0) begin
n_state &lt;= start_bit;

n_counter &lt;= counter + 1;
end
else begin
n_state &lt;= ready;
n_counter &lt;= 0;
n_data_bit_count &lt;= 0;
end
end

start_bit: begin

if(counter == half_rcv_bit_per) begin
n_state &lt;= data_bits;
n_data_bit_count &lt;= data_bit_count + 1;
n_counter &lt;= 0;
end
else begin
n_state &lt;= start_bit;
n_counter &lt;= counter + 1;
end
end

data_bits: begin
if(counter == rcv_bit_per) begin
//n_rcv_sr &lt;= {rcv_sr[6:0], RS232_DCE_RXD};

n_rcv_sr &lt;= {RS232_DCE_RXD,rcv_sr[39:1]};
n_data_bit_count &lt;= data_bit_count + 1;
n_counter &lt;= 0;
if(data_bit_count == 40)
n_state &lt;= stop_bit;
end
else
n_counter &lt;= counter + 1;
end

stop_bit: begin
n_counter &lt;= counter + 1;
if(counter == rcv_bit_per) 
n_state &lt;= ready;
end
endcase
end 


always @(posedge clk) begin
if(reset == 0) begin
p_state &lt;= ready;
rcv_sr &lt;= 0;
counter &lt;= 0;
data_bit_count &lt;= 0;

end
else begin
p_state &lt;= n_state;
rcv_sr &lt;= n_rcv_sr;
counter &lt;= n_counter;
data_bit_count &lt;= n_data_bit_count;
end
end

endmodule

module test2;

reg reset;
reg clk;
reg ir0;
reg ir1;
reg ir2;
reg ir3;
reg sw_0;
reg sw_limit;

reg id;
reg RS232_DCE_RXD;


wire RS232_DCE_TXD;
wire [39:0] receive_data;
wire orng;
wire red;
wire green;
wire yellow;
wire [2:0] park_lot;
wire motor_cw;
wire motor_ccw;


main uut (
.reset(reset),
.clk(clk),
.ir0(ir0),
.ir1(ir1),
.ir2(ir2),
.ir3(ir3),
.sw_0(sw_0),
.sw_limit(sw_limit),
.id(id),

.RS232_DCE_RXD(RS232_DCE_RXD),
.RS232_DCE_TXD(RS232_DCE_TXD),
.receive_data(receive_data),
.orng(orng),
.red(red),
.green(green),
.yellow(yellow),
.park_lot(park_lot),
.motor_cw(motor_cw),
.motor_ccw(motor_ccw)
);

initial begin
// Initialize Inputs
reset = 0;
clk = 0;
ir0 = 1;
ir1 = 0;
ir2 = 1;
ir3 = 0;
sw_0 = 1;
sw_limit = 0;
id = 0;
RS232_DCE_RXD = 1;


#100;
reset = 1;

#1000;

ir0 = 0;
#30000;


RS232_DCE_RXD = 0; 


#52090; 
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 1; 
#52090; 
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 0; 
#52090; 
RS232_DCE_RXD = 1;
#52090; 
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 0;
#52090; 

RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 1; 
#52090;
RS232_DCE_RXD = 1; 
#52090;
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 0; 
#52090; 
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 1;
#52090; 
RS232_DCE_RXD = 1; 
#52090; 
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 0;
#52090;
RS232_DCE_RXD = 1;

#52090;
RS232_DCE_RXD = 1; 
#52090; 
RS232_DCE_RXD = 0;
#52090;
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 1; 
#52090;
RS232_DCE_RXD = 1; 
#52090; 
RS232_DCE_RXD = 0; 
#52090; 
RS232_DCE_RXD = 1; 
#52090;
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD =0; 
#52090;

RS232_DCE_RXD = 0;
#52090; 
RS232_DCE_RXD = 0; 
#52090; 
RS232_DCE_RXD = 0; 
#52090; 
RS232_DCE_RXD = 0; 
#52090;
RS232_DCE_RXD = 0;
#52090; 
RS232_DCE_RXD = 0; 
#52090; 
RS232_DCE_RXD = 0;
#52090; 
RS232_DCE_RXD = 0; 
#52090;

RS232_DCE_RXD = 1; 
#30000

sw_0 = 0;

#30000
sw_limit = 1;
#30000
ir0 = 1;
#30000
sw_0 = 1;

end
always @(*)

#10 clk &lt;=~clk;

endmodule
