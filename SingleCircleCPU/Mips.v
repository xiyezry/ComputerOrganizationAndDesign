module Mips();
	
	reg clk,rst;
	
		initial begin
			//$readmemh( "C:/Users/xiye/Desktop/SCPU-student/extendedtest.dat" , U_IM.ins_mem); // load instructions into instruction memory
			//$readmemh( "mipstest_extloop.dat" , U_IM.ins_mem); // load instructions into instruction memory
			//$readmemh( "mipstestloopjal_sim.dat" , U_IM.ins_mem); // load instructions into instruction memory
			$readmemh( "C:/Users/xiye/Desktop/SCPU-student/mipstestloop_sim.dat" , U_IM.ins_mem); // load instructions into instruction memory
			clk = 1;
			rst = 0;
			#5 rst = 1;
			#5 rst = 0;
		end	
		
		always
			#(50) clk = ~clk;
			
//PC 
	wire[31:0] PC;
	wire[31:0] RS;
//NPC
	wire[31:0] NPC;	
//IM
	wire[6:0] IMAdd;
	wire[31:0] Ins;	
//RF
	wire[4:0] rfws,RFWS,RFR1,RFR2;
	wire[31:0] RFDataIn;
	wire[31:0] RFDataOut1,RFDataOut2;	
//Ext
	wire[15:0] EXTDataIn;
	wire[31:0] EXTDataOut;	
//DMem
	wire[6:0] DMAdd;
	wire[31:0] DMDataOut;
//Control
	wire[5:0] op;
	wire[5:0] funct;
	wire RegDst;
	wire MemRead;
	wire MemWrite;
	wire MemToReg;
	wire RegWrite;
	wire ALUsrc;
	wire ALUasrc;
	wire EXTOP;
	wire ShiftIndex;
	wire ShiftDirection;
	wire SArith;
	wire[1:0] NPCOp;
	wire[3:0] ALUop;
	wire call;
	wire Spload;
	wire BorH;
	wire SorU;
	wire SpecialIn;
	wire DMemBorH;	
//ALU
	wire[31:0] ALUDataIn1;
	wire[31:0] ALUDataIn2;
	wire[31:0] ALUDataOut;
	wire zero;
	wire carry;
	wire negative;
	wire overflow;
	wire[1:0] LastTwo;	
//Shifter
	wire[31:0] ShifterIn;
	wire[4:0] ShifterIndex;
	wire[31:0] ShifterOut;
//else
	wire[31:0] preRFDataIn;
	wire[7:0] LoadbyteOut;
	wire[15:0] LoadhalfOut;
	wire[31:0] ByteEXTOut;
	wire[31:0] HalfEXTOut;
	wire[31:0] LoadEXTOut;
	wire[31:0] LoadOrNotOut;

	assign IMAdd = PC[8:2];
	assign op = Ins[31:26];
	assign funct = Ins[5:0];
	assign RFR1 = Ins[25:21];
	assign RFR2 = Ins[20:16];
	assign EXTDataIn = Ins[15:0];
	assign ShifterIn = RFDataOut2;
	assign RS = RFDataOut1;
	assign DMAdd = ALUDataOut[6:0];

//NPC实例化
	NPC U_Npc(.RS(RS),.PC(PC), .NPCOp(NPCOp), .IMM(EXTDataOut[25:0]), .NPC(NPC));

//PC实例化
	PC U_Pc(.clk(clk),.rst(rst),.NPC(NPC),.PC(PC));
	
//指令寄存器实例化
	instructionmemory U_IM(.IMAdd(IMAdd),.Ins(Ins));
	
//寄存器堆实例化
	RF U_Rf(.clk(clk),.rst(rst),.RFWr(RegWrite),.A1(RFR1),.A2(RFR2),.A3(RFWS),.WD(RFDataIn),.RD1(RFDataOut1),.RD2(RFDataOut2));
	
//控制器实例化
	Control U_Control(.Opcode(op),.Funct(funct),.RegDst(RegDst),.MemRead(MemRead),.MemtoReg(MemToReg),.ALUOp(ALUop),.MemWrite(MemWrite),.ALUSrc(ALUsrc),.RegWrite(RegWrite),.EXTOP(EXTOP),.NPCOP(NPCOp),.Zero(zero),.ShiftIndex(ShiftIndex),.ShiftDirection(ShiftDirection),.SArith(SArith),.ALUasrc(ALUasrc),.call(call),.SpLoad(Spload),.BorH(BorH),.SorU(SorU),.SpecialIn(SpecialIn),.DMemBorH(DMemBorH));

//扩展器实例化
	EXT U_Ext(.Imm16(EXTDataIn),.EXTOp(EXTOP),.Imm32(EXTDataOut));
	EXT U_HalfEXT(LoadhalfOut,SorU,HalfEXTOut);
	EXT_8 U_ByteEXT(LoadbyteOut,SorU,ByteEXTOut);

//移位器实例化
	Shifter U_Shifter(.orignial(ShifterIn),.index(ShifterIndex),.right(ShiftDirection),.arith(SArith),.result(ShifterOut));
	
//ALU实例化
	alu U_Alu(.A(ALUDataIn1), .B(ALUDataIn2), .ALUOp(ALUop), .C(ALUDataOut), .Zero(zero),.Carry(carry),.Negative(negative),.Overflow(overflow),.LastTwo(LastTwo));
	
//DM实例化
	datamemory U_Dmem(.SpecialIn(SpecialIn),.BorH(DMemBorH),.LastTwo(LastTwo),.DMAdd(DMAdd),.DataIn(RFDataOut2),.DataOut(DMDataOut),.DMW(MemWrite),.DMR(MemRead),.clk(clk));

//多路选择器实例化	
	mux2_5 rfw1(Ins[20:16],Ins[15:11],RegDst,rfws);	//写寄存器2路选择器（一）用于确定是写入20-16位还是15-11位 其中控制信号为RegDst
	mux2_5 rfw2(rfws,5'b11111,call,RFWS);//写寄存器2路选择器（二）用于确定是写入一选择的寄存器还是31号寄存器 其中控制信号位Call
	mux2_5 shift1(Ins[10:6],RFDataOut1[4:0],ShiftIndex,ShifterIndex);//移位器源操作数选择器 如果有移位操作则置位1 其中控制信号为ShiftIndex
	mux2_32 alua(RFDataOut1,ShifterOut,ALUasrc,ALUDataIn1);//ALU第一个操作数选择器，从寄存器组中读出的第一个数据和移位器的数据中进行选择 
	mux2_32 alub(RFDataOut2,EXTDataOut,ALUsrc,ALUDataIn2);//ALU第二个操作数选择器，从拓展后的imm和寄存器组中读出的第二个数进行选择
	mux4 loadbyte(preRFDataIn[7:0],preRFDataIn[15:8],preRFDataIn[23:16],preRFDataIn[31:24],LastTwo[1:0],LoadbyteOut);//字节源操作数选择器
	mux2_16 loadhalf(preRFDataIn[15:0],preRFDataIn[31:16],LastTwo[1],LoadhalfOut);//半字源操作数选择器，以LastTwo信号的高位作为控制信号
	mux2_32 loadExtOut(ByteEXTOut,HalfEXTOut,BorH,LoadEXTOut);//半字、字节操作选择器
	mux2_32 outchoose(ALUDataOut,DMDataOut,MemToReg,preRFDataIn);//寄存器堆写操作数选择（一），从运算器和数据存储器的输出中进行选择
	mux2_32 LoadOrNot(preRFDataIn,LoadEXTOut,Spload,LoadOrNotOut);//寄存器堆写操作数选择（二），从（一）和特殊Load中选择
	mux2_32 rfDIn(LoadOrNotOut,PC+4,call,RFDataIn);//寄存器堆写操作数选择（三），从（二）和PC+4（仅jal|jalr指令）中选择
endmodule
	
	