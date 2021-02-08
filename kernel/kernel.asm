
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	c4478793          	addi	a5,a5,-956 # 80005ca0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	472080e7          	jalr	1138(ra) # 80002598 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	906080e7          	jalr	-1786(ra) # 80001ad4 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	102080e7          	jalr	258(ra) # 800022e0 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	328080e7          	jalr	808(ra) # 80002542 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	2f2080e7          	jalr	754(ra) # 800025ee <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	016080e7          	jalr	22(ra) # 80002466 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	bb0080e7          	jalr	-1104(ra) # 80002466 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	990080e7          	jalr	-1648(ra) # 800022e0 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	f0e080e7          	jalr	-242(ra) # 80001ab8 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	edc080e7          	jalr	-292(ra) # 80001ab8 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	ed0080e7          	jalr	-304(ra) # 80001ab8 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	eb8080e7          	jalr	-328(ra) # 80001ab8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	e78080e7          	jalr	-392(ra) # 80001ab8 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	e4c080e7          	jalr	-436(ra) # 80001ab8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	be2080e7          	jalr	-1054(ra) # 80001aa8 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	bc6080e7          	jalr	-1082(ra) # 80001aa8 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0e0080e7          	jalr	224(ra) # 80000fdc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	82a080e7          	jalr	-2006(ra) # 8000272e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	dd4080e7          	jalr	-556(ra) # 80005ce0 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	0f0080e7          	jalr	240(ra) # 80002004 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00005097          	auipc	ra,0x5
    80000f28:	57e080e7          	jalr	1406(ra) # 800064a2 <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	19450513          	addi	a0,a0,404 # 800080c8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	15c50513          	addi	a0,a0,348 # 800080a0 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	17450513          	addi	a0,a0,372 # 800080c8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	2a0080e7          	jalr	672(ra) # 8000120c <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	068080e7          	jalr	104(ra) # 80000fdc <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	a5c080e7          	jalr	-1444(ra) # 800019d8 <procinit>
    trapinit();      // trap vectors
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	782080e7          	jalr	1922(ra) # 80002706 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	7a2080e7          	jalr	1954(ra) # 8000272e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	d36080e7          	jalr	-714(ra) # 80005cca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	d44080e7          	jalr	-700(ra) # 80005ce0 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	ecc080e7          	jalr	-308(ra) # 80002e70 <binit>
    iinit();         // inode cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	55c080e7          	jalr	1372(ra) # 80003508 <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	4f6080e7          	jalr	1270(ra) # 800044aa <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	e2c080e7          	jalr	-468(ra) # 80005de8 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	dda080e7          	jalr	-550(ra) # 80001d9e <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fdc:	1141                	addi	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	02e7b783          	ld	a5,46(a5) # 80009010 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0aa50513          	addi	a0,a0,170 # 800080d0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	51a080e7          	jalr	1306(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	ae6080e7          	jalr	-1306(ra) # 80000b20 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cc2080e7          	jalr	-830(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	00a7d513          	srli	a0,a5,0xa
    800010e0:	0532                	slli	a0,a0,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e8:	1101                	addi	sp,sp,-32
    800010ea:	ec06                	sd	ra,24(sp)
    800010ec:	e822                	sd	s0,16(sp)
    800010ee:	e426                	sd	s1,8(sp)
    800010f0:	1000                	addi	s0,sp,32
    800010f2:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010f4:	1552                	slli	a0,a0,0x34
    800010f6:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010fa:	4601                	li	a2,0
    800010fc:	00008517          	auipc	a0,0x8
    80001100:	f1453503          	ld	a0,-236(a0) # 80009010 <kernel_pagetable>
    80001104:	00000097          	auipc	ra,0x0
    80001108:	efc080e7          	jalr	-260(ra) # 80001000 <walk>
  if(pte == 0)
    8000110c:	cd09                	beqz	a0,80001126 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000110e:	6108                	ld	a0,0(a0)
    80001110:	00157793          	andi	a5,a0,1
    80001114:	c38d                	beqz	a5,80001136 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001116:	8129                	srli	a0,a0,0xa
    80001118:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000111a:	9526                	add	a0,a0,s1
    8000111c:	60e2                	ld	ra,24(sp)
    8000111e:	6442                	ld	s0,16(sp)
    80001120:	64a2                	ld	s1,8(sp)
    80001122:	6105                	addi	sp,sp,32
    80001124:	8082                	ret
    panic("kvmpa");
    80001126:	00007517          	auipc	a0,0x7
    8000112a:	fb250513          	addi	a0,a0,-78 # 800080d8 <digits+0x98>
    8000112e:	fffff097          	auipc	ra,0xfffff
    80001132:	41a080e7          	jalr	1050(ra) # 80000548 <panic>
    panic("kvmpa");
    80001136:	00007517          	auipc	a0,0x7
    8000113a:	fa250513          	addi	a0,a0,-94 # 800080d8 <digits+0x98>
    8000113e:	fffff097          	auipc	ra,0xfffff
    80001142:	40a080e7          	jalr	1034(ra) # 80000548 <panic>

0000000080001146 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001146:	715d                	addi	sp,sp,-80
    80001148:	e486                	sd	ra,72(sp)
    8000114a:	e0a2                	sd	s0,64(sp)
    8000114c:	fc26                	sd	s1,56(sp)
    8000114e:	f84a                	sd	s2,48(sp)
    80001150:	f44e                	sd	s3,40(sp)
    80001152:	f052                	sd	s4,32(sp)
    80001154:	ec56                	sd	s5,24(sp)
    80001156:	e85a                	sd	s6,16(sp)
    80001158:	e45e                	sd	s7,8(sp)
    8000115a:	0880                	addi	s0,sp,80
    8000115c:	8aaa                	mv	s5,a0
    8000115e:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001160:	777d                	lui	a4,0xfffff
    80001162:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001166:	167d                	addi	a2,a2,-1
    80001168:	00b609b3          	add	s3,a2,a1
    8000116c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001170:	893e                	mv	s2,a5
    80001172:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001176:	6b85                	lui	s7,0x1
    80001178:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000117c:	4605                	li	a2,1
    8000117e:	85ca                	mv	a1,s2
    80001180:	8556                	mv	a0,s5
    80001182:	00000097          	auipc	ra,0x0
    80001186:	e7e080e7          	jalr	-386(ra) # 80001000 <walk>
    8000118a:	c51d                	beqz	a0,800011b8 <mappages+0x72>
    if(*pte & PTE_V)
    8000118c:	611c                	ld	a5,0(a0)
    8000118e:	8b85                	andi	a5,a5,1
    80001190:	ef81                	bnez	a5,800011a8 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001192:	80b1                	srli	s1,s1,0xc
    80001194:	04aa                	slli	s1,s1,0xa
    80001196:	0164e4b3          	or	s1,s1,s6
    8000119a:	0014e493          	ori	s1,s1,1
    8000119e:	e104                	sd	s1,0(a0)
    if(a == last)
    800011a0:	03390863          	beq	s2,s3,800011d0 <mappages+0x8a>
    a += PGSIZE;
    800011a4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011a6:	bfc9                	j	80001178 <mappages+0x32>
      panic("remap");
    800011a8:	00007517          	auipc	a0,0x7
    800011ac:	f3850513          	addi	a0,a0,-200 # 800080e0 <digits+0xa0>
    800011b0:	fffff097          	auipc	ra,0xfffff
    800011b4:	398080e7          	jalr	920(ra) # 80000548 <panic>
      return -1;
    800011b8:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011ba:	60a6                	ld	ra,72(sp)
    800011bc:	6406                	ld	s0,64(sp)
    800011be:	74e2                	ld	s1,56(sp)
    800011c0:	7942                	ld	s2,48(sp)
    800011c2:	79a2                	ld	s3,40(sp)
    800011c4:	7a02                	ld	s4,32(sp)
    800011c6:	6ae2                	ld	s5,24(sp)
    800011c8:	6b42                	ld	s6,16(sp)
    800011ca:	6ba2                	ld	s7,8(sp)
    800011cc:	6161                	addi	sp,sp,80
    800011ce:	8082                	ret
  return 0;
    800011d0:	4501                	li	a0,0
    800011d2:	b7e5                	j	800011ba <mappages+0x74>

00000000800011d4 <kvmmap>:
{
    800011d4:	1141                	addi	sp,sp,-16
    800011d6:	e406                	sd	ra,8(sp)
    800011d8:	e022                	sd	s0,0(sp)
    800011da:	0800                	addi	s0,sp,16
    800011dc:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011de:	86ae                	mv	a3,a1
    800011e0:	85aa                	mv	a1,a0
    800011e2:	00008517          	auipc	a0,0x8
    800011e6:	e2e53503          	ld	a0,-466(a0) # 80009010 <kernel_pagetable>
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f5c080e7          	jalr	-164(ra) # 80001146 <mappages>
    800011f2:	e509                	bnez	a0,800011fc <kvmmap+0x28>
}
    800011f4:	60a2                	ld	ra,8(sp)
    800011f6:	6402                	ld	s0,0(sp)
    800011f8:	0141                	addi	sp,sp,16
    800011fa:	8082                	ret
    panic("kvmmap");
    800011fc:	00007517          	auipc	a0,0x7
    80001200:	eec50513          	addi	a0,a0,-276 # 800080e8 <digits+0xa8>
    80001204:	fffff097          	auipc	ra,0xfffff
    80001208:	344080e7          	jalr	836(ra) # 80000548 <panic>

000000008000120c <kvminit>:
{
    8000120c:	1101                	addi	sp,sp,-32
    8000120e:	ec06                	sd	ra,24(sp)
    80001210:	e822                	sd	s0,16(sp)
    80001212:	e426                	sd	s1,8(sp)
    80001214:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	90a080e7          	jalr	-1782(ra) # 80000b20 <kalloc>
    8000121e:	00008797          	auipc	a5,0x8
    80001222:	dea7b923          	sd	a0,-526(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001226:	6605                	lui	a2,0x1
    80001228:	4581                	li	a1,0
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	ae2080e7          	jalr	-1310(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001232:	4699                	li	a3,6
    80001234:	6605                	lui	a2,0x1
    80001236:	100005b7          	lui	a1,0x10000
    8000123a:	10000537          	lui	a0,0x10000
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f96080e7          	jalr	-106(ra) # 800011d4 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001246:	4699                	li	a3,6
    80001248:	6605                	lui	a2,0x1
    8000124a:	100015b7          	lui	a1,0x10001
    8000124e:	10001537          	lui	a0,0x10001
    80001252:	00000097          	auipc	ra,0x0
    80001256:	f82080e7          	jalr	-126(ra) # 800011d4 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000125a:	4699                	li	a3,6
    8000125c:	6641                	lui	a2,0x10
    8000125e:	020005b7          	lui	a1,0x2000
    80001262:	02000537          	lui	a0,0x2000
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f6e080e7          	jalr	-146(ra) # 800011d4 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000126e:	4699                	li	a3,6
    80001270:	00400637          	lui	a2,0x400
    80001274:	0c0005b7          	lui	a1,0xc000
    80001278:	0c000537          	lui	a0,0xc000
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	f58080e7          	jalr	-168(ra) # 800011d4 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001284:	00007497          	auipc	s1,0x7
    80001288:	d7c48493          	addi	s1,s1,-644 # 80008000 <etext>
    8000128c:	46a9                	li	a3,10
    8000128e:	80007617          	auipc	a2,0x80007
    80001292:	d7260613          	addi	a2,a2,-654 # 8000 <_entry-0x7fff8000>
    80001296:	4585                	li	a1,1
    80001298:	05fe                	slli	a1,a1,0x1f
    8000129a:	852e                	mv	a0,a1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f38080e7          	jalr	-200(ra) # 800011d4 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012a4:	4699                	li	a3,6
    800012a6:	4645                	li	a2,17
    800012a8:	066e                	slli	a2,a2,0x1b
    800012aa:	8e05                	sub	a2,a2,s1
    800012ac:	85a6                	mv	a1,s1
    800012ae:	8526                	mv	a0,s1
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f24080e7          	jalr	-220(ra) # 800011d4 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012b8:	46a9                	li	a3,10
    800012ba:	6605                	lui	a2,0x1
    800012bc:	00006597          	auipc	a1,0x6
    800012c0:	d4458593          	addi	a1,a1,-700 # 80007000 <_trampoline>
    800012c4:	04000537          	lui	a0,0x4000
    800012c8:	157d                	addi	a0,a0,-1
    800012ca:	0532                	slli	a0,a0,0xc
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	f08080e7          	jalr	-248(ra) # 800011d4 <kvmmap>
}
    800012d4:	60e2                	ld	ra,24(sp)
    800012d6:	6442                	ld	s0,16(sp)
    800012d8:	64a2                	ld	s1,8(sp)
    800012da:	6105                	addi	sp,sp,32
    800012dc:	8082                	ret

00000000800012de <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012de:	715d                	addi	sp,sp,-80
    800012e0:	e486                	sd	ra,72(sp)
    800012e2:	e0a2                	sd	s0,64(sp)
    800012e4:	fc26                	sd	s1,56(sp)
    800012e6:	f84a                	sd	s2,48(sp)
    800012e8:	f44e                	sd	s3,40(sp)
    800012ea:	f052                	sd	s4,32(sp)
    800012ec:	ec56                	sd	s5,24(sp)
    800012ee:	e85a                	sd	s6,16(sp)
    800012f0:	e45e                	sd	s7,8(sp)
    800012f2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f4:	03459793          	slli	a5,a1,0x34
    800012f8:	e795                	bnez	a5,80001324 <uvmunmap+0x46>
    800012fa:	8a2a                	mv	s4,a0
    800012fc:	892e                	mv	s2,a1
    800012fe:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001300:	0632                	slli	a2,a2,0xc
    80001302:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001306:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001308:	6b05                	lui	s6,0x1
    8000130a:	0735e863          	bltu	a1,s3,8000137a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000130e:	60a6                	ld	ra,72(sp)
    80001310:	6406                	ld	s0,64(sp)
    80001312:	74e2                	ld	s1,56(sp)
    80001314:	7942                	ld	s2,48(sp)
    80001316:	79a2                	ld	s3,40(sp)
    80001318:	7a02                	ld	s4,32(sp)
    8000131a:	6ae2                	ld	s5,24(sp)
    8000131c:	6b42                	ld	s6,16(sp)
    8000131e:	6ba2                	ld	s7,8(sp)
    80001320:	6161                	addi	sp,sp,80
    80001322:	8082                	ret
    panic("uvmunmap: not aligned");
    80001324:	00007517          	auipc	a0,0x7
    80001328:	dcc50513          	addi	a0,a0,-564 # 800080f0 <digits+0xb0>
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	21c080e7          	jalr	540(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001334:	00007517          	auipc	a0,0x7
    80001338:	dd450513          	addi	a0,a0,-556 # 80008108 <digits+0xc8>
    8000133c:	fffff097          	auipc	ra,0xfffff
    80001340:	20c080e7          	jalr	524(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001344:	00007517          	auipc	a0,0x7
    80001348:	dd450513          	addi	a0,a0,-556 # 80008118 <digits+0xd8>
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	1fc080e7          	jalr	508(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001354:	00007517          	auipc	a0,0x7
    80001358:	ddc50513          	addi	a0,a0,-548 # 80008130 <digits+0xf0>
    8000135c:	fffff097          	auipc	ra,0xfffff
    80001360:	1ec080e7          	jalr	492(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001364:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001366:	0532                	slli	a0,a0,0xc
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	6bc080e7          	jalr	1724(ra) # 80000a24 <kfree>
    *pte = 0;
    80001370:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001374:	995a                	add	s2,s2,s6
    80001376:	f9397ce3          	bgeu	s2,s3,8000130e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000137a:	4601                	li	a2,0
    8000137c:	85ca                	mv	a1,s2
    8000137e:	8552                	mv	a0,s4
    80001380:	00000097          	auipc	ra,0x0
    80001384:	c80080e7          	jalr	-896(ra) # 80001000 <walk>
    80001388:	84aa                	mv	s1,a0
    8000138a:	d54d                	beqz	a0,80001334 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000138c:	6108                	ld	a0,0(a0)
    8000138e:	00157793          	andi	a5,a0,1
    80001392:	dbcd                	beqz	a5,80001344 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001394:	3ff57793          	andi	a5,a0,1023
    80001398:	fb778ee3          	beq	a5,s7,80001354 <uvmunmap+0x76>
    if(do_free){
    8000139c:	fc0a8ae3          	beqz	s5,80001370 <uvmunmap+0x92>
    800013a0:	b7d1                	j	80001364 <uvmunmap+0x86>

00000000800013a2 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a2:	1101                	addi	sp,sp,-32
    800013a4:	ec06                	sd	ra,24(sp)
    800013a6:	e822                	sd	s0,16(sp)
    800013a8:	e426                	sd	s1,8(sp)
    800013aa:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ac:	fffff097          	auipc	ra,0xfffff
    800013b0:	774080e7          	jalr	1908(ra) # 80000b20 <kalloc>
    800013b4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013b6:	c519                	beqz	a0,800013c4 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b8:	6605                	lui	a2,0x1
    800013ba:	4581                	li	a1,0
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	950080e7          	jalr	-1712(ra) # 80000d0c <memset>
  return pagetable;
}
    800013c4:	8526                	mv	a0,s1
    800013c6:	60e2                	ld	ra,24(sp)
    800013c8:	6442                	ld	s0,16(sp)
    800013ca:	64a2                	ld	s1,8(sp)
    800013cc:	6105                	addi	sp,sp,32
    800013ce:	8082                	ret

00000000800013d0 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013d0:	7179                	addi	sp,sp,-48
    800013d2:	f406                	sd	ra,40(sp)
    800013d4:	f022                	sd	s0,32(sp)
    800013d6:	ec26                	sd	s1,24(sp)
    800013d8:	e84a                	sd	s2,16(sp)
    800013da:	e44e                	sd	s3,8(sp)
    800013dc:	e052                	sd	s4,0(sp)
    800013de:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013e0:	6785                	lui	a5,0x1
    800013e2:	04f67863          	bgeu	a2,a5,80001432 <uvminit+0x62>
    800013e6:	8a2a                	mv	s4,a0
    800013e8:	89ae                	mv	s3,a1
    800013ea:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013ec:	fffff097          	auipc	ra,0xfffff
    800013f0:	734080e7          	jalr	1844(ra) # 80000b20 <kalloc>
    800013f4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013f6:	6605                	lui	a2,0x1
    800013f8:	4581                	li	a1,0
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	912080e7          	jalr	-1774(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001402:	4779                	li	a4,30
    80001404:	86ca                	mv	a3,s2
    80001406:	6605                	lui	a2,0x1
    80001408:	4581                	li	a1,0
    8000140a:	8552                	mv	a0,s4
    8000140c:	00000097          	auipc	ra,0x0
    80001410:	d3a080e7          	jalr	-710(ra) # 80001146 <mappages>
  memmove(mem, src, sz);
    80001414:	8626                	mv	a2,s1
    80001416:	85ce                	mv	a1,s3
    80001418:	854a                	mv	a0,s2
    8000141a:	00000097          	auipc	ra,0x0
    8000141e:	952080e7          	jalr	-1710(ra) # 80000d6c <memmove>
}
    80001422:	70a2                	ld	ra,40(sp)
    80001424:	7402                	ld	s0,32(sp)
    80001426:	64e2                	ld	s1,24(sp)
    80001428:	6942                	ld	s2,16(sp)
    8000142a:	69a2                	ld	s3,8(sp)
    8000142c:	6a02                	ld	s4,0(sp)
    8000142e:	6145                	addi	sp,sp,48
    80001430:	8082                	ret
    panic("inituvm: more than a page");
    80001432:	00007517          	auipc	a0,0x7
    80001436:	d1650513          	addi	a0,a0,-746 # 80008148 <digits+0x108>
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	10e080e7          	jalr	270(ra) # 80000548 <panic>

0000000080001442 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001442:	1101                	addi	sp,sp,-32
    80001444:	ec06                	sd	ra,24(sp)
    80001446:	e822                	sd	s0,16(sp)
    80001448:	e426                	sd	s1,8(sp)
    8000144a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000144c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000144e:	00b67d63          	bgeu	a2,a1,80001468 <uvmdealloc+0x26>
    80001452:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001454:	6785                	lui	a5,0x1
    80001456:	17fd                	addi	a5,a5,-1
    80001458:	00f60733          	add	a4,a2,a5
    8000145c:	767d                	lui	a2,0xfffff
    8000145e:	8f71                	and	a4,a4,a2
    80001460:	97ae                	add	a5,a5,a1
    80001462:	8ff1                	and	a5,a5,a2
    80001464:	00f76863          	bltu	a4,a5,80001474 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001468:	8526                	mv	a0,s1
    8000146a:	60e2                	ld	ra,24(sp)
    8000146c:	6442                	ld	s0,16(sp)
    8000146e:	64a2                	ld	s1,8(sp)
    80001470:	6105                	addi	sp,sp,32
    80001472:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001474:	8f99                	sub	a5,a5,a4
    80001476:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001478:	4685                	li	a3,1
    8000147a:	0007861b          	sext.w	a2,a5
    8000147e:	85ba                	mv	a1,a4
    80001480:	00000097          	auipc	ra,0x0
    80001484:	e5e080e7          	jalr	-418(ra) # 800012de <uvmunmap>
    80001488:	b7c5                	j	80001468 <uvmdealloc+0x26>

000000008000148a <uvmalloc>:
  if(newsz < oldsz)
    8000148a:	0ab66163          	bltu	a2,a1,8000152c <uvmalloc+0xa2>
{
    8000148e:	7139                	addi	sp,sp,-64
    80001490:	fc06                	sd	ra,56(sp)
    80001492:	f822                	sd	s0,48(sp)
    80001494:	f426                	sd	s1,40(sp)
    80001496:	f04a                	sd	s2,32(sp)
    80001498:	ec4e                	sd	s3,24(sp)
    8000149a:	e852                	sd	s4,16(sp)
    8000149c:	e456                	sd	s5,8(sp)
    8000149e:	0080                	addi	s0,sp,64
    800014a0:	8aaa                	mv	s5,a0
    800014a2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6985                	lui	s3,0x1
    800014a6:	19fd                	addi	s3,s3,-1
    800014a8:	95ce                	add	a1,a1,s3
    800014aa:	79fd                	lui	s3,0xfffff
    800014ac:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	08c9f063          	bgeu	s3,a2,80001530 <uvmalloc+0xa6>
    800014b4:	894e                	mv	s2,s3
    mem = kalloc();
    800014b6:	fffff097          	auipc	ra,0xfffff
    800014ba:	66a080e7          	jalr	1642(ra) # 80000b20 <kalloc>
    800014be:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c0:	c51d                	beqz	a0,800014ee <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014c2:	6605                	lui	a2,0x1
    800014c4:	4581                	li	a1,0
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	846080e7          	jalr	-1978(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014ce:	4779                	li	a4,30
    800014d0:	86a6                	mv	a3,s1
    800014d2:	6605                	lui	a2,0x1
    800014d4:	85ca                	mv	a1,s2
    800014d6:	8556                	mv	a0,s5
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	c6e080e7          	jalr	-914(ra) # 80001146 <mappages>
    800014e0:	e905                	bnez	a0,80001510 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e2:	6785                	lui	a5,0x1
    800014e4:	993e                	add	s2,s2,a5
    800014e6:	fd4968e3          	bltu	s2,s4,800014b6 <uvmalloc+0x2c>
  return newsz;
    800014ea:	8552                	mv	a0,s4
    800014ec:	a809                	j	800014fe <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014ee:	864e                	mv	a2,s3
    800014f0:	85ca                	mv	a1,s2
    800014f2:	8556                	mv	a0,s5
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	f4e080e7          	jalr	-178(ra) # 80001442 <uvmdealloc>
      return 0;
    800014fc:	4501                	li	a0,0
}
    800014fe:	70e2                	ld	ra,56(sp)
    80001500:	7442                	ld	s0,48(sp)
    80001502:	74a2                	ld	s1,40(sp)
    80001504:	7902                	ld	s2,32(sp)
    80001506:	69e2                	ld	s3,24(sp)
    80001508:	6a42                	ld	s4,16(sp)
    8000150a:	6aa2                	ld	s5,8(sp)
    8000150c:	6121                	addi	sp,sp,64
    8000150e:	8082                	ret
      kfree(mem);
    80001510:	8526                	mv	a0,s1
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	512080e7          	jalr	1298(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000151a:	864e                	mv	a2,s3
    8000151c:	85ca                	mv	a1,s2
    8000151e:	8556                	mv	a0,s5
    80001520:	00000097          	auipc	ra,0x0
    80001524:	f22080e7          	jalr	-222(ra) # 80001442 <uvmdealloc>
      return 0;
    80001528:	4501                	li	a0,0
    8000152a:	bfd1                	j	800014fe <uvmalloc+0x74>
    return oldsz;
    8000152c:	852e                	mv	a0,a1
}
    8000152e:	8082                	ret
  return newsz;
    80001530:	8532                	mv	a0,a2
    80001532:	b7f1                	j	800014fe <uvmalloc+0x74>

0000000080001534 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001534:	7179                	addi	sp,sp,-48
    80001536:	f406                	sd	ra,40(sp)
    80001538:	f022                	sd	s0,32(sp)
    8000153a:	ec26                	sd	s1,24(sp)
    8000153c:	e84a                	sd	s2,16(sp)
    8000153e:	e44e                	sd	s3,8(sp)
    80001540:	e052                	sd	s4,0(sp)
    80001542:	1800                	addi	s0,sp,48
    80001544:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001546:	84aa                	mv	s1,a0
    80001548:	6905                	lui	s2,0x1
    8000154a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000154c:	4985                	li	s3,1
    8000154e:	a821                	j	80001566 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001550:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001552:	0532                	slli	a0,a0,0xc
    80001554:	00000097          	auipc	ra,0x0
    80001558:	fe0080e7          	jalr	-32(ra) # 80001534 <freewalk>
      pagetable[i] = 0;
    8000155c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001560:	04a1                	addi	s1,s1,8
    80001562:	03248163          	beq	s1,s2,80001584 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001566:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001568:	00f57793          	andi	a5,a0,15
    8000156c:	ff3782e3          	beq	a5,s3,80001550 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001570:	8905                	andi	a0,a0,1
    80001572:	d57d                	beqz	a0,80001560 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001574:	00007517          	auipc	a0,0x7
    80001578:	bf450513          	addi	a0,a0,-1036 # 80008168 <digits+0x128>
    8000157c:	fffff097          	auipc	ra,0xfffff
    80001580:	fcc080e7          	jalr	-52(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    80001584:	8552                	mv	a0,s4
    80001586:	fffff097          	auipc	ra,0xfffff
    8000158a:	49e080e7          	jalr	1182(ra) # 80000a24 <kfree>
}
    8000158e:	70a2                	ld	ra,40(sp)
    80001590:	7402                	ld	s0,32(sp)
    80001592:	64e2                	ld	s1,24(sp)
    80001594:	6942                	ld	s2,16(sp)
    80001596:	69a2                	ld	s3,8(sp)
    80001598:	6a02                	ld	s4,0(sp)
    8000159a:	6145                	addi	sp,sp,48
    8000159c:	8082                	ret

000000008000159e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000159e:	1101                	addi	sp,sp,-32
    800015a0:	ec06                	sd	ra,24(sp)
    800015a2:	e822                	sd	s0,16(sp)
    800015a4:	e426                	sd	s1,8(sp)
    800015a6:	1000                	addi	s0,sp,32
    800015a8:	84aa                	mv	s1,a0
  if(sz > 0)
    800015aa:	e999                	bnez	a1,800015c0 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ac:	8526                	mv	a0,s1
    800015ae:	00000097          	auipc	ra,0x0
    800015b2:	f86080e7          	jalr	-122(ra) # 80001534 <freewalk>
}
    800015b6:	60e2                	ld	ra,24(sp)
    800015b8:	6442                	ld	s0,16(sp)
    800015ba:	64a2                	ld	s1,8(sp)
    800015bc:	6105                	addi	sp,sp,32
    800015be:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c0:	6605                	lui	a2,0x1
    800015c2:	167d                	addi	a2,a2,-1
    800015c4:	962e                	add	a2,a2,a1
    800015c6:	4685                	li	a3,1
    800015c8:	8231                	srli	a2,a2,0xc
    800015ca:	4581                	li	a1,0
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	d12080e7          	jalr	-750(ra) # 800012de <uvmunmap>
    800015d4:	bfe1                	j	800015ac <uvmfree+0xe>

00000000800015d6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015d6:	c679                	beqz	a2,800016a4 <uvmcopy+0xce>
{
    800015d8:	715d                	addi	sp,sp,-80
    800015da:	e486                	sd	ra,72(sp)
    800015dc:	e0a2                	sd	s0,64(sp)
    800015de:	fc26                	sd	s1,56(sp)
    800015e0:	f84a                	sd	s2,48(sp)
    800015e2:	f44e                	sd	s3,40(sp)
    800015e4:	f052                	sd	s4,32(sp)
    800015e6:	ec56                	sd	s5,24(sp)
    800015e8:	e85a                	sd	s6,16(sp)
    800015ea:	e45e                	sd	s7,8(sp)
    800015ec:	0880                	addi	s0,sp,80
    800015ee:	8b2a                	mv	s6,a0
    800015f0:	8aae                	mv	s5,a1
    800015f2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015f4:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015f6:	4601                	li	a2,0
    800015f8:	85ce                	mv	a1,s3
    800015fa:	855a                	mv	a0,s6
    800015fc:	00000097          	auipc	ra,0x0
    80001600:	a04080e7          	jalr	-1532(ra) # 80001000 <walk>
    80001604:	c531                	beqz	a0,80001650 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001606:	6118                	ld	a4,0(a0)
    80001608:	00177793          	andi	a5,a4,1
    8000160c:	cbb1                	beqz	a5,80001660 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000160e:	00a75593          	srli	a1,a4,0xa
    80001612:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001616:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	506080e7          	jalr	1286(ra) # 80000b20 <kalloc>
    80001622:	892a                	mv	s2,a0
    80001624:	c939                	beqz	a0,8000167a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001626:	6605                	lui	a2,0x1
    80001628:	85de                	mv	a1,s7
    8000162a:	fffff097          	auipc	ra,0xfffff
    8000162e:	742080e7          	jalr	1858(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001632:	8726                	mv	a4,s1
    80001634:	86ca                	mv	a3,s2
    80001636:	6605                	lui	a2,0x1
    80001638:	85ce                	mv	a1,s3
    8000163a:	8556                	mv	a0,s5
    8000163c:	00000097          	auipc	ra,0x0
    80001640:	b0a080e7          	jalr	-1270(ra) # 80001146 <mappages>
    80001644:	e515                	bnez	a0,80001670 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001646:	6785                	lui	a5,0x1
    80001648:	99be                	add	s3,s3,a5
    8000164a:	fb49e6e3          	bltu	s3,s4,800015f6 <uvmcopy+0x20>
    8000164e:	a081                	j	8000168e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001650:	00007517          	auipc	a0,0x7
    80001654:	b2850513          	addi	a0,a0,-1240 # 80008178 <digits+0x138>
    80001658:	fffff097          	auipc	ra,0xfffff
    8000165c:	ef0080e7          	jalr	-272(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    80001660:	00007517          	auipc	a0,0x7
    80001664:	b3850513          	addi	a0,a0,-1224 # 80008198 <digits+0x158>
    80001668:	fffff097          	auipc	ra,0xfffff
    8000166c:	ee0080e7          	jalr	-288(ra) # 80000548 <panic>
      kfree(mem);
    80001670:	854a                	mv	a0,s2
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	3b2080e7          	jalr	946(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000167a:	4685                	li	a3,1
    8000167c:	00c9d613          	srli	a2,s3,0xc
    80001680:	4581                	li	a1,0
    80001682:	8556                	mv	a0,s5
    80001684:	00000097          	auipc	ra,0x0
    80001688:	c5a080e7          	jalr	-934(ra) # 800012de <uvmunmap>
  return -1;
    8000168c:	557d                	li	a0,-1
}
    8000168e:	60a6                	ld	ra,72(sp)
    80001690:	6406                	ld	s0,64(sp)
    80001692:	74e2                	ld	s1,56(sp)
    80001694:	7942                	ld	s2,48(sp)
    80001696:	79a2                	ld	s3,40(sp)
    80001698:	7a02                	ld	s4,32(sp)
    8000169a:	6ae2                	ld	s5,24(sp)
    8000169c:	6b42                	ld	s6,16(sp)
    8000169e:	6ba2                	ld	s7,8(sp)
    800016a0:	6161                	addi	sp,sp,80
    800016a2:	8082                	ret
  return 0;
    800016a4:	4501                	li	a0,0
}
    800016a6:	8082                	ret

00000000800016a8 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016a8:	1141                	addi	sp,sp,-16
    800016aa:	e406                	sd	ra,8(sp)
    800016ac:	e022                	sd	s0,0(sp)
    800016ae:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016b0:	4601                	li	a2,0
    800016b2:	00000097          	auipc	ra,0x0
    800016b6:	94e080e7          	jalr	-1714(ra) # 80001000 <walk>
  if(pte == 0)
    800016ba:	c901                	beqz	a0,800016ca <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016bc:	611c                	ld	a5,0(a0)
    800016be:	9bbd                	andi	a5,a5,-17
    800016c0:	e11c                	sd	a5,0(a0)
}
    800016c2:	60a2                	ld	ra,8(sp)
    800016c4:	6402                	ld	s0,0(sp)
    800016c6:	0141                	addi	sp,sp,16
    800016c8:	8082                	ret
    panic("uvmclear");
    800016ca:	00007517          	auipc	a0,0x7
    800016ce:	aee50513          	addi	a0,a0,-1298 # 800081b8 <digits+0x178>
    800016d2:	fffff097          	auipc	ra,0xfffff
    800016d6:	e76080e7          	jalr	-394(ra) # 80000548 <panic>

00000000800016da <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016da:	c6bd                	beqz	a3,80001748 <copyout+0x6e>
{
    800016dc:	715d                	addi	sp,sp,-80
    800016de:	e486                	sd	ra,72(sp)
    800016e0:	e0a2                	sd	s0,64(sp)
    800016e2:	fc26                	sd	s1,56(sp)
    800016e4:	f84a                	sd	s2,48(sp)
    800016e6:	f44e                	sd	s3,40(sp)
    800016e8:	f052                	sd	s4,32(sp)
    800016ea:	ec56                	sd	s5,24(sp)
    800016ec:	e85a                	sd	s6,16(sp)
    800016ee:	e45e                	sd	s7,8(sp)
    800016f0:	e062                	sd	s8,0(sp)
    800016f2:	0880                	addi	s0,sp,80
    800016f4:	8b2a                	mv	s6,a0
    800016f6:	8c2e                	mv	s8,a1
    800016f8:	8a32                	mv	s4,a2
    800016fa:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016fc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016fe:	6a85                	lui	s5,0x1
    80001700:	a015                	j	80001724 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001702:	9562                	add	a0,a0,s8
    80001704:	0004861b          	sext.w	a2,s1
    80001708:	85d2                	mv	a1,s4
    8000170a:	41250533          	sub	a0,a0,s2
    8000170e:	fffff097          	auipc	ra,0xfffff
    80001712:	65e080e7          	jalr	1630(ra) # 80000d6c <memmove>

    len -= n;
    80001716:	409989b3          	sub	s3,s3,s1
    src += n;
    8000171a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000171c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001720:	02098263          	beqz	s3,80001744 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001724:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001728:	85ca                	mv	a1,s2
    8000172a:	855a                	mv	a0,s6
    8000172c:	00000097          	auipc	ra,0x0
    80001730:	97a080e7          	jalr	-1670(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    80001734:	cd01                	beqz	a0,8000174c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001736:	418904b3          	sub	s1,s2,s8
    8000173a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000173c:	fc99f3e3          	bgeu	s3,s1,80001702 <copyout+0x28>
    80001740:	84ce                	mv	s1,s3
    80001742:	b7c1                	j	80001702 <copyout+0x28>
  }
  return 0;
    80001744:	4501                	li	a0,0
    80001746:	a021                	j	8000174e <copyout+0x74>
    80001748:	4501                	li	a0,0
}
    8000174a:	8082                	ret
      return -1;
    8000174c:	557d                	li	a0,-1
}
    8000174e:	60a6                	ld	ra,72(sp)
    80001750:	6406                	ld	s0,64(sp)
    80001752:	74e2                	ld	s1,56(sp)
    80001754:	7942                	ld	s2,48(sp)
    80001756:	79a2                	ld	s3,40(sp)
    80001758:	7a02                	ld	s4,32(sp)
    8000175a:	6ae2                	ld	s5,24(sp)
    8000175c:	6b42                	ld	s6,16(sp)
    8000175e:	6ba2                	ld	s7,8(sp)
    80001760:	6c02                	ld	s8,0(sp)
    80001762:	6161                	addi	sp,sp,80
    80001764:	8082                	ret

0000000080001766 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001766:	c6bd                	beqz	a3,800017d4 <copyin+0x6e>
{
    80001768:	715d                	addi	sp,sp,-80
    8000176a:	e486                	sd	ra,72(sp)
    8000176c:	e0a2                	sd	s0,64(sp)
    8000176e:	fc26                	sd	s1,56(sp)
    80001770:	f84a                	sd	s2,48(sp)
    80001772:	f44e                	sd	s3,40(sp)
    80001774:	f052                	sd	s4,32(sp)
    80001776:	ec56                	sd	s5,24(sp)
    80001778:	e85a                	sd	s6,16(sp)
    8000177a:	e45e                	sd	s7,8(sp)
    8000177c:	e062                	sd	s8,0(sp)
    8000177e:	0880                	addi	s0,sp,80
    80001780:	8b2a                	mv	s6,a0
    80001782:	8a2e                	mv	s4,a1
    80001784:	8c32                	mv	s8,a2
    80001786:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001788:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000178a:	6a85                	lui	s5,0x1
    8000178c:	a015                	j	800017b0 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000178e:	9562                	add	a0,a0,s8
    80001790:	0004861b          	sext.w	a2,s1
    80001794:	412505b3          	sub	a1,a0,s2
    80001798:	8552                	mv	a0,s4
    8000179a:	fffff097          	auipc	ra,0xfffff
    8000179e:	5d2080e7          	jalr	1490(ra) # 80000d6c <memmove>

    len -= n;
    800017a2:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017a6:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017a8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ac:	02098263          	beqz	s3,800017d0 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017b0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017b4:	85ca                	mv	a1,s2
    800017b6:	855a                	mv	a0,s6
    800017b8:	00000097          	auipc	ra,0x0
    800017bc:	8ee080e7          	jalr	-1810(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    800017c0:	cd01                	beqz	a0,800017d8 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800017c2:	418904b3          	sub	s1,s2,s8
    800017c6:	94d6                	add	s1,s1,s5
    if(n > len)
    800017c8:	fc99f3e3          	bgeu	s3,s1,8000178e <copyin+0x28>
    800017cc:	84ce                	mv	s1,s3
    800017ce:	b7c1                	j	8000178e <copyin+0x28>
  }
  return 0;
    800017d0:	4501                	li	a0,0
    800017d2:	a021                	j	800017da <copyin+0x74>
    800017d4:	4501                	li	a0,0
}
    800017d6:	8082                	ret
      return -1;
    800017d8:	557d                	li	a0,-1
}
    800017da:	60a6                	ld	ra,72(sp)
    800017dc:	6406                	ld	s0,64(sp)
    800017de:	74e2                	ld	s1,56(sp)
    800017e0:	7942                	ld	s2,48(sp)
    800017e2:	79a2                	ld	s3,40(sp)
    800017e4:	7a02                	ld	s4,32(sp)
    800017e6:	6ae2                	ld	s5,24(sp)
    800017e8:	6b42                	ld	s6,16(sp)
    800017ea:	6ba2                	ld	s7,8(sp)
    800017ec:	6c02                	ld	s8,0(sp)
    800017ee:	6161                	addi	sp,sp,80
    800017f0:	8082                	ret

00000000800017f2 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017f2:	c6c5                	beqz	a3,8000189a <copyinstr+0xa8>
{
    800017f4:	715d                	addi	sp,sp,-80
    800017f6:	e486                	sd	ra,72(sp)
    800017f8:	e0a2                	sd	s0,64(sp)
    800017fa:	fc26                	sd	s1,56(sp)
    800017fc:	f84a                	sd	s2,48(sp)
    800017fe:	f44e                	sd	s3,40(sp)
    80001800:	f052                	sd	s4,32(sp)
    80001802:	ec56                	sd	s5,24(sp)
    80001804:	e85a                	sd	s6,16(sp)
    80001806:	e45e                	sd	s7,8(sp)
    80001808:	0880                	addi	s0,sp,80
    8000180a:	8a2a                	mv	s4,a0
    8000180c:	8b2e                	mv	s6,a1
    8000180e:	8bb2                	mv	s7,a2
    80001810:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001812:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001814:	6985                	lui	s3,0x1
    80001816:	a035                	j	80001842 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001818:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000181c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000181e:	0017b793          	seqz	a5,a5
    80001822:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001826:	60a6                	ld	ra,72(sp)
    80001828:	6406                	ld	s0,64(sp)
    8000182a:	74e2                	ld	s1,56(sp)
    8000182c:	7942                	ld	s2,48(sp)
    8000182e:	79a2                	ld	s3,40(sp)
    80001830:	7a02                	ld	s4,32(sp)
    80001832:	6ae2                	ld	s5,24(sp)
    80001834:	6b42                	ld	s6,16(sp)
    80001836:	6ba2                	ld	s7,8(sp)
    80001838:	6161                	addi	sp,sp,80
    8000183a:	8082                	ret
    srcva = va0 + PGSIZE;
    8000183c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001840:	c8a9                	beqz	s1,80001892 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001842:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001846:	85ca                	mv	a1,s2
    80001848:	8552                	mv	a0,s4
    8000184a:	00000097          	auipc	ra,0x0
    8000184e:	85c080e7          	jalr	-1956(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    80001852:	c131                	beqz	a0,80001896 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001854:	41790833          	sub	a6,s2,s7
    80001858:	984e                	add	a6,a6,s3
    if(n > max)
    8000185a:	0104f363          	bgeu	s1,a6,80001860 <copyinstr+0x6e>
    8000185e:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001860:	955e                	add	a0,a0,s7
    80001862:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001866:	fc080be3          	beqz	a6,8000183c <copyinstr+0x4a>
    8000186a:	985a                	add	a6,a6,s6
    8000186c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000186e:	41650633          	sub	a2,a0,s6
    80001872:	14fd                	addi	s1,s1,-1
    80001874:	9b26                	add	s6,s6,s1
    80001876:	00f60733          	add	a4,a2,a5
    8000187a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    8000187e:	df49                	beqz	a4,80001818 <copyinstr+0x26>
        *dst = *p;
    80001880:	00e78023          	sb	a4,0(a5)
      --max;
    80001884:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001888:	0785                	addi	a5,a5,1
    while(n > 0){
    8000188a:	ff0796e3          	bne	a5,a6,80001876 <copyinstr+0x84>
      dst++;
    8000188e:	8b42                	mv	s6,a6
    80001890:	b775                	j	8000183c <copyinstr+0x4a>
    80001892:	4781                	li	a5,0
    80001894:	b769                	j	8000181e <copyinstr+0x2c>
      return -1;
    80001896:	557d                	li	a0,-1
    80001898:	b779                	j	80001826 <copyinstr+0x34>
  int got_null = 0;
    8000189a:	4781                	li	a5,0
  if(got_null){
    8000189c:	0017b793          	seqz	a5,a5
    800018a0:	40f00533          	neg	a0,a5
}
    800018a4:	8082                	ret

00000000800018a6 <vmprint>:

void vmprint(pagetable_t  p)
{
    800018a6:	7159                	addi	sp,sp,-112
    800018a8:	f486                	sd	ra,104(sp)
    800018aa:	f0a2                	sd	s0,96(sp)
    800018ac:	eca6                	sd	s1,88(sp)
    800018ae:	e8ca                	sd	s2,80(sp)
    800018b0:	e4ce                	sd	s3,72(sp)
    800018b2:	e0d2                	sd	s4,64(sp)
    800018b4:	fc56                	sd	s5,56(sp)
    800018b6:	f85a                	sd	s6,48(sp)
    800018b8:	f45e                	sd	s7,40(sp)
    800018ba:	f062                	sd	s8,32(sp)
    800018bc:	ec66                	sd	s9,24(sp)
    800018be:	e86a                	sd	s10,16(sp)
    800018c0:	e46e                	sd	s11,8(sp)
    800018c2:	1880                	addi	s0,sp,112
    800018c4:	8caa                	mv	s9,a0
    printf("page table %p\n",p);
    800018c6:	85aa                	mv	a1,a0
    800018c8:	00007517          	auipc	a0,0x7
    800018cc:	90050513          	addi	a0,a0,-1792 # 800081c8 <digits+0x188>
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	cc2080e7          	jalr	-830(ra) # 80000592 <printf>
    pte_t *pte2 = p;
    uint64 pa2; 
  for(int i =0;i<512;i++)
    800018d8:	0ca1                	addi	s9,s9,8
    800018da:	4d01                	li	s10,0
      continue;
    }
    pa2 = PTE2PA(*pte2);
    pte_t* pte1;
    pte1 = (pte_t *)pa2;
    printf("..%d: pte %p pa %p\n",i,*pte2,pa2);
    800018dc:	00007d97          	auipc	s11,0x7
    800018e0:	8fcd8d93          	addi	s11,s11,-1796 # 800081d8 <digits+0x198>
      {
        pte1+=1;
        continue;
      }
      uint64 pa1 = PTE2PA(*pte1);
      printf("....%d: pte %p pa %p\n",j,*pte1,pa1);
    800018e4:	00007c17          	auipc	s8,0x7
    800018e8:	90cc0c13          	addi	s8,s8,-1780 # 800081f0 <digits+0x1b0>
      pte_t* pte0 ;
      pte0 = (pte_t *)pa1;
      for(int k=0;k<512;k++)
    800018ec:	20000993          	li	s3,512
    800018f0:	4b81                	li	s7,0
        if(!(*pte0 & PTE_V))
        {
          pte0+=1;
          continue;
        }
        printf("......%d: pte %p pa %p\n",k,*pte0,PTE2PA(*pte0));
    800018f2:	00007a17          	auipc	s4,0x7
    800018f6:	916a0a13          	addi	s4,s4,-1770 # 80008208 <digits+0x1c8>
    800018fa:	a8a9                	j	80001954 <vmprint+0xae>
      for(int k=0;k<512;k++)
    800018fc:	2485                	addiw	s1,s1,1
    800018fe:	0921                	addi	s2,s2,8
    80001900:	03348163          	beq	s1,s3,80001922 <vmprint+0x7c>
        if(!(*pte0 & PTE_V))
    80001904:	00093603          	ld	a2,0(s2) # 1000 <_entry-0x7ffff000>
    80001908:	00167793          	andi	a5,a2,1
    8000190c:	dbe5                	beqz	a5,800018fc <vmprint+0x56>
        printf("......%d: pte %p pa %p\n",k,*pte0,PTE2PA(*pte0));
    8000190e:	00a65693          	srli	a3,a2,0xa
    80001912:	06b2                	slli	a3,a3,0xc
    80001914:	85a6                	mv	a1,s1
    80001916:	8552                	mv	a0,s4
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	c7a080e7          	jalr	-902(ra) # 80000592 <printf>
        pte0+=1;
    80001920:	bff1                	j	800018fc <vmprint+0x56>
    for(int j=0;j<512;j++)
    80001922:	2a85                	addiw	s5,s5,1
    80001924:	0b21                	addi	s6,s6,8
    80001926:	033a8363          	beq	s5,s3,8000194c <vmprint+0xa6>
      if(!(*pte1 & PTE_V))
    8000192a:	000b3603          	ld	a2,0(s6) # 1000 <_entry-0x7ffff000>
    8000192e:	00167793          	andi	a5,a2,1
    80001932:	dbe5                	beqz	a5,80001922 <vmprint+0x7c>
      uint64 pa1 = PTE2PA(*pte1);
    80001934:	00a65913          	srli	s2,a2,0xa
    80001938:	0932                	slli	s2,s2,0xc
      printf("....%d: pte %p pa %p\n",j,*pte1,pa1);
    8000193a:	86ca                	mv	a3,s2
    8000193c:	85d6                	mv	a1,s5
    8000193e:	8562                	mv	a0,s8
    80001940:	fffff097          	auipc	ra,0xfffff
    80001944:	c52080e7          	jalr	-942(ra) # 80000592 <printf>
      for(int k=0;k<512;k++)
    80001948:	84de                	mv	s1,s7
    8000194a:	bf6d                	j	80001904 <vmprint+0x5e>
  for(int i =0;i<512;i++)
    8000194c:	2d05                	addiw	s10,s10,1
    8000194e:	0ca1                	addi	s9,s9,8
    80001950:	033d0363          	beq	s10,s3,80001976 <vmprint+0xd0>
    if(!(*pte2 & PTE_V))
    80001954:	ff8cb603          	ld	a2,-8(s9)
    80001958:	00167793          	andi	a5,a2,1
    8000195c:	dbe5                	beqz	a5,8000194c <vmprint+0xa6>
    pa2 = PTE2PA(*pte2);
    8000195e:	00a65b13          	srli	s6,a2,0xa
    80001962:	0b32                	slli	s6,s6,0xc
    printf("..%d: pte %p pa %p\n",i,*pte2,pa2);
    80001964:	86da                	mv	a3,s6
    80001966:	85ea                	mv	a1,s10
    80001968:	856e                	mv	a0,s11
    8000196a:	fffff097          	auipc	ra,0xfffff
    8000196e:	c28080e7          	jalr	-984(ra) # 80000592 <printf>
    for(int j=0;j<512;j++)
    80001972:	4a81                	li	s5,0
    80001974:	bf5d                	j	8000192a <vmprint+0x84>
      pte1+=1;
    }
    pte2+=1;
  }

}
    80001976:	70a6                	ld	ra,104(sp)
    80001978:	7406                	ld	s0,96(sp)
    8000197a:	64e6                	ld	s1,88(sp)
    8000197c:	6946                	ld	s2,80(sp)
    8000197e:	69a6                	ld	s3,72(sp)
    80001980:	6a06                	ld	s4,64(sp)
    80001982:	7ae2                	ld	s5,56(sp)
    80001984:	7b42                	ld	s6,48(sp)
    80001986:	7ba2                	ld	s7,40(sp)
    80001988:	7c02                	ld	s8,32(sp)
    8000198a:	6ce2                	ld	s9,24(sp)
    8000198c:	6d42                	ld	s10,16(sp)
    8000198e:	6da2                	ld	s11,8(sp)
    80001990:	6165                	addi	sp,sp,112
    80001992:	8082                	ret

0000000080001994 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001994:	1101                	addi	sp,sp,-32
    80001996:	ec06                	sd	ra,24(sp)
    80001998:	e822                	sd	s0,16(sp)
    8000199a:	e426                	sd	s1,8(sp)
    8000199c:	1000                	addi	s0,sp,32
    8000199e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1f6080e7          	jalr	502(ra) # 80000b96 <holding>
    800019a8:	c909                	beqz	a0,800019ba <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800019aa:	749c                	ld	a5,40(s1)
    800019ac:	00978f63          	beq	a5,s1,800019ca <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800019b0:	60e2                	ld	ra,24(sp)
    800019b2:	6442                	ld	s0,16(sp)
    800019b4:	64a2                	ld	s1,8(sp)
    800019b6:	6105                	addi	sp,sp,32
    800019b8:	8082                	ret
    panic("wakeup1");
    800019ba:	00007517          	auipc	a0,0x7
    800019be:	86650513          	addi	a0,a0,-1946 # 80008220 <digits+0x1e0>
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	b86080e7          	jalr	-1146(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800019ca:	4c98                	lw	a4,24(s1)
    800019cc:	4785                	li	a5,1
    800019ce:	fef711e3          	bne	a4,a5,800019b0 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019d2:	4789                	li	a5,2
    800019d4:	cc9c                	sw	a5,24(s1)
}
    800019d6:	bfe9                	j	800019b0 <wakeup1+0x1c>

00000000800019d8 <procinit>:
{
    800019d8:	715d                	addi	sp,sp,-80
    800019da:	e486                	sd	ra,72(sp)
    800019dc:	e0a2                	sd	s0,64(sp)
    800019de:	fc26                	sd	s1,56(sp)
    800019e0:	f84a                	sd	s2,48(sp)
    800019e2:	f44e                	sd	s3,40(sp)
    800019e4:	f052                	sd	s4,32(sp)
    800019e6:	ec56                	sd	s5,24(sp)
    800019e8:	e85a                	sd	s6,16(sp)
    800019ea:	e45e                	sd	s7,8(sp)
    800019ec:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800019ee:	00007597          	auipc	a1,0x7
    800019f2:	83a58593          	addi	a1,a1,-1990 # 80008228 <digits+0x1e8>
    800019f6:	00010517          	auipc	a0,0x10
    800019fa:	f5a50513          	addi	a0,a0,-166 # 80011950 <pid_lock>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	182080e7          	jalr	386(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a06:	00010917          	auipc	s2,0x10
    80001a0a:	36290913          	addi	s2,s2,866 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001a0e:	00007b97          	auipc	s7,0x7
    80001a12:	822b8b93          	addi	s7,s7,-2014 # 80008230 <digits+0x1f0>
      uint64 va = KSTACK((int) (p - proc));
    80001a16:	8b4a                	mv	s6,s2
    80001a18:	00006a97          	auipc	s5,0x6
    80001a1c:	5e8a8a93          	addi	s5,s5,1512 # 80008000 <etext>
    80001a20:	040009b7          	lui	s3,0x4000
    80001a24:	19fd                	addi	s3,s3,-1
    80001a26:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a28:	00016a17          	auipc	s4,0x16
    80001a2c:	d40a0a13          	addi	s4,s4,-704 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001a30:	85de                	mv	a1,s7
    80001a32:	854a                	mv	a0,s2
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	14c080e7          	jalr	332(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	0e4080e7          	jalr	228(ra) # 80000b20 <kalloc>
    80001a44:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a46:	c929                	beqz	a0,80001a98 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a48:	416904b3          	sub	s1,s2,s6
    80001a4c:	848d                	srai	s1,s1,0x3
    80001a4e:	000ab783          	ld	a5,0(s5)
    80001a52:	02f484b3          	mul	s1,s1,a5
    80001a56:	2485                	addiw	s1,s1,1
    80001a58:	00d4949b          	slliw	s1,s1,0xd
    80001a5c:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a60:	4699                	li	a3,6
    80001a62:	6605                	lui	a2,0x1
    80001a64:	8526                	mv	a0,s1
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	76e080e7          	jalr	1902(ra) # 800011d4 <kvmmap>
      p->kstack = va;
    80001a6e:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a72:	16890913          	addi	s2,s2,360
    80001a76:	fb491de3          	bne	s2,s4,80001a30 <procinit+0x58>
  kvminithart();
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	562080e7          	jalr	1378(ra) # 80000fdc <kvminithart>
}
    80001a82:	60a6                	ld	ra,72(sp)
    80001a84:	6406                	ld	s0,64(sp)
    80001a86:	74e2                	ld	s1,56(sp)
    80001a88:	7942                	ld	s2,48(sp)
    80001a8a:	79a2                	ld	s3,40(sp)
    80001a8c:	7a02                	ld	s4,32(sp)
    80001a8e:	6ae2                	ld	s5,24(sp)
    80001a90:	6b42                	ld	s6,16(sp)
    80001a92:	6ba2                	ld	s7,8(sp)
    80001a94:	6161                	addi	sp,sp,80
    80001a96:	8082                	ret
        panic("kalloc");
    80001a98:	00006517          	auipc	a0,0x6
    80001a9c:	7a050513          	addi	a0,a0,1952 # 80008238 <digits+0x1f8>
    80001aa0:	fffff097          	auipc	ra,0xfffff
    80001aa4:	aa8080e7          	jalr	-1368(ra) # 80000548 <panic>

0000000080001aa8 <cpuid>:
{
    80001aa8:	1141                	addi	sp,sp,-16
    80001aaa:	e422                	sd	s0,8(sp)
    80001aac:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aae:	8512                	mv	a0,tp
}
    80001ab0:	2501                	sext.w	a0,a0
    80001ab2:	6422                	ld	s0,8(sp)
    80001ab4:	0141                	addi	sp,sp,16
    80001ab6:	8082                	ret

0000000080001ab8 <mycpu>:
mycpu(void) {
    80001ab8:	1141                	addi	sp,sp,-16
    80001aba:	e422                	sd	s0,8(sp)
    80001abc:	0800                	addi	s0,sp,16
    80001abe:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ac0:	2781                	sext.w	a5,a5
    80001ac2:	079e                	slli	a5,a5,0x7
}
    80001ac4:	00010517          	auipc	a0,0x10
    80001ac8:	ea450513          	addi	a0,a0,-348 # 80011968 <cpus>
    80001acc:	953e                	add	a0,a0,a5
    80001ace:	6422                	ld	s0,8(sp)
    80001ad0:	0141                	addi	sp,sp,16
    80001ad2:	8082                	ret

0000000080001ad4 <myproc>:
myproc(void) {
    80001ad4:	1101                	addi	sp,sp,-32
    80001ad6:	ec06                	sd	ra,24(sp)
    80001ad8:	e822                	sd	s0,16(sp)
    80001ada:	e426                	sd	s1,8(sp)
    80001adc:	1000                	addi	s0,sp,32
  push_off();
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	0e6080e7          	jalr	230(ra) # 80000bc4 <push_off>
    80001ae6:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001ae8:	2781                	sext.w	a5,a5
    80001aea:	079e                	slli	a5,a5,0x7
    80001aec:	00010717          	auipc	a4,0x10
    80001af0:	e6470713          	addi	a4,a4,-412 # 80011950 <pid_lock>
    80001af4:	97ba                	add	a5,a5,a4
    80001af6:	6f84                	ld	s1,24(a5)
  pop_off();
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	16c080e7          	jalr	364(ra) # 80000c64 <pop_off>
}
    80001b00:	8526                	mv	a0,s1
    80001b02:	60e2                	ld	ra,24(sp)
    80001b04:	6442                	ld	s0,16(sp)
    80001b06:	64a2                	ld	s1,8(sp)
    80001b08:	6105                	addi	sp,sp,32
    80001b0a:	8082                	ret

0000000080001b0c <forkret>:
{
    80001b0c:	1141                	addi	sp,sp,-16
    80001b0e:	e406                	sd	ra,8(sp)
    80001b10:	e022                	sd	s0,0(sp)
    80001b12:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	fc0080e7          	jalr	-64(ra) # 80001ad4 <myproc>
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	1a8080e7          	jalr	424(ra) # 80000cc4 <release>
  if (first) {
    80001b24:	00007797          	auipc	a5,0x7
    80001b28:	d8c7a783          	lw	a5,-628(a5) # 800088b0 <first.1672>
    80001b2c:	eb89                	bnez	a5,80001b3e <forkret+0x32>
  usertrapret();
    80001b2e:	00001097          	auipc	ra,0x1
    80001b32:	c18080e7          	jalr	-1000(ra) # 80002746 <usertrapret>
}
    80001b36:	60a2                	ld	ra,8(sp)
    80001b38:	6402                	ld	s0,0(sp)
    80001b3a:	0141                	addi	sp,sp,16
    80001b3c:	8082                	ret
    first = 0;
    80001b3e:	00007797          	auipc	a5,0x7
    80001b42:	d607a923          	sw	zero,-654(a5) # 800088b0 <first.1672>
    fsinit(ROOTDEV);
    80001b46:	4505                	li	a0,1
    80001b48:	00002097          	auipc	ra,0x2
    80001b4c:	940080e7          	jalr	-1728(ra) # 80003488 <fsinit>
    80001b50:	bff9                	j	80001b2e <forkret+0x22>

0000000080001b52 <allocpid>:
allocpid() {
    80001b52:	1101                	addi	sp,sp,-32
    80001b54:	ec06                	sd	ra,24(sp)
    80001b56:	e822                	sd	s0,16(sp)
    80001b58:	e426                	sd	s1,8(sp)
    80001b5a:	e04a                	sd	s2,0(sp)
    80001b5c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b5e:	00010917          	auipc	s2,0x10
    80001b62:	df290913          	addi	s2,s2,-526 # 80011950 <pid_lock>
    80001b66:	854a                	mv	a0,s2
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	0a8080e7          	jalr	168(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001b70:	00007797          	auipc	a5,0x7
    80001b74:	d4478793          	addi	a5,a5,-700 # 800088b4 <nextpid>
    80001b78:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b7a:	0014871b          	addiw	a4,s1,1
    80001b7e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b80:	854a                	mv	a0,s2
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	142080e7          	jalr	322(ra) # 80000cc4 <release>
}
    80001b8a:	8526                	mv	a0,s1
    80001b8c:	60e2                	ld	ra,24(sp)
    80001b8e:	6442                	ld	s0,16(sp)
    80001b90:	64a2                	ld	s1,8(sp)
    80001b92:	6902                	ld	s2,0(sp)
    80001b94:	6105                	addi	sp,sp,32
    80001b96:	8082                	ret

0000000080001b98 <proc_pagetable>:
{
    80001b98:	1101                	addi	sp,sp,-32
    80001b9a:	ec06                	sd	ra,24(sp)
    80001b9c:	e822                	sd	s0,16(sp)
    80001b9e:	e426                	sd	s1,8(sp)
    80001ba0:	e04a                	sd	s2,0(sp)
    80001ba2:	1000                	addi	s0,sp,32
    80001ba4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	7fc080e7          	jalr	2044(ra) # 800013a2 <uvmcreate>
    80001bae:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bb0:	c121                	beqz	a0,80001bf0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bb2:	4729                	li	a4,10
    80001bb4:	00005697          	auipc	a3,0x5
    80001bb8:	44c68693          	addi	a3,a3,1100 # 80007000 <_trampoline>
    80001bbc:	6605                	lui	a2,0x1
    80001bbe:	040005b7          	lui	a1,0x4000
    80001bc2:	15fd                	addi	a1,a1,-1
    80001bc4:	05b2                	slli	a1,a1,0xc
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	580080e7          	jalr	1408(ra) # 80001146 <mappages>
    80001bce:	02054863          	bltz	a0,80001bfe <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bd2:	4719                	li	a4,6
    80001bd4:	05893683          	ld	a3,88(s2)
    80001bd8:	6605                	lui	a2,0x1
    80001bda:	020005b7          	lui	a1,0x2000
    80001bde:	15fd                	addi	a1,a1,-1
    80001be0:	05b6                	slli	a1,a1,0xd
    80001be2:	8526                	mv	a0,s1
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	562080e7          	jalr	1378(ra) # 80001146 <mappages>
    80001bec:	02054163          	bltz	a0,80001c0e <proc_pagetable+0x76>
}
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	60e2                	ld	ra,24(sp)
    80001bf4:	6442                	ld	s0,16(sp)
    80001bf6:	64a2                	ld	s1,8(sp)
    80001bf8:	6902                	ld	s2,0(sp)
    80001bfa:	6105                	addi	sp,sp,32
    80001bfc:	8082                	ret
    uvmfree(pagetable, 0);
    80001bfe:	4581                	li	a1,0
    80001c00:	8526                	mv	a0,s1
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	99c080e7          	jalr	-1636(ra) # 8000159e <uvmfree>
    return 0;
    80001c0a:	4481                	li	s1,0
    80001c0c:	b7d5                	j	80001bf0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c0e:	4681                	li	a3,0
    80001c10:	4605                	li	a2,1
    80001c12:	040005b7          	lui	a1,0x4000
    80001c16:	15fd                	addi	a1,a1,-1
    80001c18:	05b2                	slli	a1,a1,0xc
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	6c2080e7          	jalr	1730(ra) # 800012de <uvmunmap>
    uvmfree(pagetable, 0);
    80001c24:	4581                	li	a1,0
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	976080e7          	jalr	-1674(ra) # 8000159e <uvmfree>
    return 0;
    80001c30:	4481                	li	s1,0
    80001c32:	bf7d                	j	80001bf0 <proc_pagetable+0x58>

0000000080001c34 <proc_freepagetable>:
{
    80001c34:	1101                	addi	sp,sp,-32
    80001c36:	ec06                	sd	ra,24(sp)
    80001c38:	e822                	sd	s0,16(sp)
    80001c3a:	e426                	sd	s1,8(sp)
    80001c3c:	e04a                	sd	s2,0(sp)
    80001c3e:	1000                	addi	s0,sp,32
    80001c40:	84aa                	mv	s1,a0
    80001c42:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c44:	4681                	li	a3,0
    80001c46:	4605                	li	a2,1
    80001c48:	040005b7          	lui	a1,0x4000
    80001c4c:	15fd                	addi	a1,a1,-1
    80001c4e:	05b2                	slli	a1,a1,0xc
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	68e080e7          	jalr	1678(ra) # 800012de <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c58:	4681                	li	a3,0
    80001c5a:	4605                	li	a2,1
    80001c5c:	020005b7          	lui	a1,0x2000
    80001c60:	15fd                	addi	a1,a1,-1
    80001c62:	05b6                	slli	a1,a1,0xd
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	678080e7          	jalr	1656(ra) # 800012de <uvmunmap>
  uvmfree(pagetable, sz);
    80001c6e:	85ca                	mv	a1,s2
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	92c080e7          	jalr	-1748(ra) # 8000159e <uvmfree>
}
    80001c7a:	60e2                	ld	ra,24(sp)
    80001c7c:	6442                	ld	s0,16(sp)
    80001c7e:	64a2                	ld	s1,8(sp)
    80001c80:	6902                	ld	s2,0(sp)
    80001c82:	6105                	addi	sp,sp,32
    80001c84:	8082                	ret

0000000080001c86 <freeproc>:
{
    80001c86:	1101                	addi	sp,sp,-32
    80001c88:	ec06                	sd	ra,24(sp)
    80001c8a:	e822                	sd	s0,16(sp)
    80001c8c:	e426                	sd	s1,8(sp)
    80001c8e:	1000                	addi	s0,sp,32
    80001c90:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c92:	6d28                	ld	a0,88(a0)
    80001c94:	c509                	beqz	a0,80001c9e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	d8e080e7          	jalr	-626(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001c9e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ca2:	68a8                	ld	a0,80(s1)
    80001ca4:	c511                	beqz	a0,80001cb0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ca6:	64ac                	ld	a1,72(s1)
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f8c080e7          	jalr	-116(ra) # 80001c34 <proc_freepagetable>
  p->pagetable = 0;
    80001cb0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cb4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cb8:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001cbc:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001cc0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cc4:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001cc8:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001ccc:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001cd0:	0004ac23          	sw	zero,24(s1)
}
    80001cd4:	60e2                	ld	ra,24(sp)
    80001cd6:	6442                	ld	s0,16(sp)
    80001cd8:	64a2                	ld	s1,8(sp)
    80001cda:	6105                	addi	sp,sp,32
    80001cdc:	8082                	ret

0000000080001cde <allocproc>:
{
    80001cde:	1101                	addi	sp,sp,-32
    80001ce0:	ec06                	sd	ra,24(sp)
    80001ce2:	e822                	sd	s0,16(sp)
    80001ce4:	e426                	sd	s1,8(sp)
    80001ce6:	e04a                	sd	s2,0(sp)
    80001ce8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cea:	00010497          	auipc	s1,0x10
    80001cee:	07e48493          	addi	s1,s1,126 # 80011d68 <proc>
    80001cf2:	00016917          	auipc	s2,0x16
    80001cf6:	a7690913          	addi	s2,s2,-1418 # 80017768 <tickslock>
    acquire(&p->lock);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	f14080e7          	jalr	-236(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001d04:	4c9c                	lw	a5,24(s1)
    80001d06:	cf81                	beqz	a5,80001d1e <allocproc+0x40>
      release(&p->lock);
    80001d08:	8526                	mv	a0,s1
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	fba080e7          	jalr	-70(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d12:	16848493          	addi	s1,s1,360
    80001d16:	ff2492e3          	bne	s1,s2,80001cfa <allocproc+0x1c>
  return 0;
    80001d1a:	4481                	li	s1,0
    80001d1c:	a0b9                	j	80001d6a <allocproc+0x8c>
  p->pid = allocpid();
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	e34080e7          	jalr	-460(ra) # 80001b52 <allocpid>
    80001d26:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	df8080e7          	jalr	-520(ra) # 80000b20 <kalloc>
    80001d30:	892a                	mv	s2,a0
    80001d32:	eca8                	sd	a0,88(s1)
    80001d34:	c131                	beqz	a0,80001d78 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d36:	8526                	mv	a0,s1
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	e60080e7          	jalr	-416(ra) # 80001b98 <proc_pagetable>
    80001d40:	892a                	mv	s2,a0
    80001d42:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d44:	c129                	beqz	a0,80001d86 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d46:	07000613          	li	a2,112
    80001d4a:	4581                	li	a1,0
    80001d4c:	06048513          	addi	a0,s1,96
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	fbc080e7          	jalr	-68(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001d58:	00000797          	auipc	a5,0x0
    80001d5c:	db478793          	addi	a5,a5,-588 # 80001b0c <forkret>
    80001d60:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d62:	60bc                	ld	a5,64(s1)
    80001d64:	6705                	lui	a4,0x1
    80001d66:	97ba                	add	a5,a5,a4
    80001d68:	f4bc                	sd	a5,104(s1)
}
    80001d6a:	8526                	mv	a0,s1
    80001d6c:	60e2                	ld	ra,24(sp)
    80001d6e:	6442                	ld	s0,16(sp)
    80001d70:	64a2                	ld	s1,8(sp)
    80001d72:	6902                	ld	s2,0(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret
    release(&p->lock);
    80001d78:	8526                	mv	a0,s1
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	f4a080e7          	jalr	-182(ra) # 80000cc4 <release>
    return 0;
    80001d82:	84ca                	mv	s1,s2
    80001d84:	b7dd                	j	80001d6a <allocproc+0x8c>
    freeproc(p);
    80001d86:	8526                	mv	a0,s1
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	efe080e7          	jalr	-258(ra) # 80001c86 <freeproc>
    release(&p->lock);
    80001d90:	8526                	mv	a0,s1
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	f32080e7          	jalr	-206(ra) # 80000cc4 <release>
    return 0;
    80001d9a:	84ca                	mv	s1,s2
    80001d9c:	b7f9                	j	80001d6a <allocproc+0x8c>

0000000080001d9e <userinit>:
{
    80001d9e:	1101                	addi	sp,sp,-32
    80001da0:	ec06                	sd	ra,24(sp)
    80001da2:	e822                	sd	s0,16(sp)
    80001da4:	e426                	sd	s1,8(sp)
    80001da6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	f36080e7          	jalr	-202(ra) # 80001cde <allocproc>
    80001db0:	84aa                	mv	s1,a0
  initproc = p;
    80001db2:	00007797          	auipc	a5,0x7
    80001db6:	26a7b323          	sd	a0,614(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dba:	03400613          	li	a2,52
    80001dbe:	00007597          	auipc	a1,0x7
    80001dc2:	b0258593          	addi	a1,a1,-1278 # 800088c0 <initcode>
    80001dc6:	6928                	ld	a0,80(a0)
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	608080e7          	jalr	1544(ra) # 800013d0 <uvminit>
  p->sz = PGSIZE;
    80001dd0:	6785                	lui	a5,0x1
    80001dd2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dd4:	6cb8                	ld	a4,88(s1)
    80001dd6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dda:	6cb8                	ld	a4,88(s1)
    80001ddc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dde:	4641                	li	a2,16
    80001de0:	00006597          	auipc	a1,0x6
    80001de4:	46058593          	addi	a1,a1,1120 # 80008240 <digits+0x200>
    80001de8:	15848513          	addi	a0,s1,344
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	076080e7          	jalr	118(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001df4:	00006517          	auipc	a0,0x6
    80001df8:	45c50513          	addi	a0,a0,1116 # 80008250 <digits+0x210>
    80001dfc:	00002097          	auipc	ra,0x2
    80001e00:	0b4080e7          	jalr	180(ra) # 80003eb0 <namei>
    80001e04:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e08:	4789                	li	a5,2
    80001e0a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	eb6080e7          	jalr	-330(ra) # 80000cc4 <release>
}
    80001e16:	60e2                	ld	ra,24(sp)
    80001e18:	6442                	ld	s0,16(sp)
    80001e1a:	64a2                	ld	s1,8(sp)
    80001e1c:	6105                	addi	sp,sp,32
    80001e1e:	8082                	ret

0000000080001e20 <growproc>:
{
    80001e20:	1101                	addi	sp,sp,-32
    80001e22:	ec06                	sd	ra,24(sp)
    80001e24:	e822                	sd	s0,16(sp)
    80001e26:	e426                	sd	s1,8(sp)
    80001e28:	e04a                	sd	s2,0(sp)
    80001e2a:	1000                	addi	s0,sp,32
    80001e2c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	ca6080e7          	jalr	-858(ra) # 80001ad4 <myproc>
    80001e36:	892a                	mv	s2,a0
  sz = p->sz;
    80001e38:	652c                	ld	a1,72(a0)
    80001e3a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e3e:	00904f63          	bgtz	s1,80001e5c <growproc+0x3c>
  } else if(n < 0){
    80001e42:	0204cc63          	bltz	s1,80001e7a <growproc+0x5a>
  p->sz = sz;
    80001e46:	1602                	slli	a2,a2,0x20
    80001e48:	9201                	srli	a2,a2,0x20
    80001e4a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e4e:	4501                	li	a0,0
}
    80001e50:	60e2                	ld	ra,24(sp)
    80001e52:	6442                	ld	s0,16(sp)
    80001e54:	64a2                	ld	s1,8(sp)
    80001e56:	6902                	ld	s2,0(sp)
    80001e58:	6105                	addi	sp,sp,32
    80001e5a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e5c:	9e25                	addw	a2,a2,s1
    80001e5e:	1602                	slli	a2,a2,0x20
    80001e60:	9201                	srli	a2,a2,0x20
    80001e62:	1582                	slli	a1,a1,0x20
    80001e64:	9181                	srli	a1,a1,0x20
    80001e66:	6928                	ld	a0,80(a0)
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	622080e7          	jalr	1570(ra) # 8000148a <uvmalloc>
    80001e70:	0005061b          	sext.w	a2,a0
    80001e74:	fa69                	bnez	a2,80001e46 <growproc+0x26>
      return -1;
    80001e76:	557d                	li	a0,-1
    80001e78:	bfe1                	j	80001e50 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e7a:	9e25                	addw	a2,a2,s1
    80001e7c:	1602                	slli	a2,a2,0x20
    80001e7e:	9201                	srli	a2,a2,0x20
    80001e80:	1582                	slli	a1,a1,0x20
    80001e82:	9181                	srli	a1,a1,0x20
    80001e84:	6928                	ld	a0,80(a0)
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	5bc080e7          	jalr	1468(ra) # 80001442 <uvmdealloc>
    80001e8e:	0005061b          	sext.w	a2,a0
    80001e92:	bf55                	j	80001e46 <growproc+0x26>

0000000080001e94 <fork>:
{
    80001e94:	7179                	addi	sp,sp,-48
    80001e96:	f406                	sd	ra,40(sp)
    80001e98:	f022                	sd	s0,32(sp)
    80001e9a:	ec26                	sd	s1,24(sp)
    80001e9c:	e84a                	sd	s2,16(sp)
    80001e9e:	e44e                	sd	s3,8(sp)
    80001ea0:	e052                	sd	s4,0(sp)
    80001ea2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ea4:	00000097          	auipc	ra,0x0
    80001ea8:	c30080e7          	jalr	-976(ra) # 80001ad4 <myproc>
    80001eac:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	e30080e7          	jalr	-464(ra) # 80001cde <allocproc>
    80001eb6:	c175                	beqz	a0,80001f9a <fork+0x106>
    80001eb8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eba:	04893603          	ld	a2,72(s2)
    80001ebe:	692c                	ld	a1,80(a0)
    80001ec0:	05093503          	ld	a0,80(s2)
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	712080e7          	jalr	1810(ra) # 800015d6 <uvmcopy>
    80001ecc:	04054863          	bltz	a0,80001f1c <fork+0x88>
  np->sz = p->sz;
    80001ed0:	04893783          	ld	a5,72(s2)
    80001ed4:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001ed8:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001edc:	05893683          	ld	a3,88(s2)
    80001ee0:	87b6                	mv	a5,a3
    80001ee2:	0589b703          	ld	a4,88(s3)
    80001ee6:	12068693          	addi	a3,a3,288
    80001eea:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001eee:	6788                	ld	a0,8(a5)
    80001ef0:	6b8c                	ld	a1,16(a5)
    80001ef2:	6f90                	ld	a2,24(a5)
    80001ef4:	01073023          	sd	a6,0(a4)
    80001ef8:	e708                	sd	a0,8(a4)
    80001efa:	eb0c                	sd	a1,16(a4)
    80001efc:	ef10                	sd	a2,24(a4)
    80001efe:	02078793          	addi	a5,a5,32
    80001f02:	02070713          	addi	a4,a4,32
    80001f06:	fed792e3          	bne	a5,a3,80001eea <fork+0x56>
  np->trapframe->a0 = 0;
    80001f0a:	0589b783          	ld	a5,88(s3)
    80001f0e:	0607b823          	sd	zero,112(a5)
    80001f12:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f16:	15000a13          	li	s4,336
    80001f1a:	a03d                	j	80001f48 <fork+0xb4>
    freeproc(np);
    80001f1c:	854e                	mv	a0,s3
    80001f1e:	00000097          	auipc	ra,0x0
    80001f22:	d68080e7          	jalr	-664(ra) # 80001c86 <freeproc>
    release(&np->lock);
    80001f26:	854e                	mv	a0,s3
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d9c080e7          	jalr	-612(ra) # 80000cc4 <release>
    return -1;
    80001f30:	54fd                	li	s1,-1
    80001f32:	a899                	j	80001f88 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f34:	00002097          	auipc	ra,0x2
    80001f38:	608080e7          	jalr	1544(ra) # 8000453c <filedup>
    80001f3c:	009987b3          	add	a5,s3,s1
    80001f40:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f42:	04a1                	addi	s1,s1,8
    80001f44:	01448763          	beq	s1,s4,80001f52 <fork+0xbe>
    if(p->ofile[i])
    80001f48:	009907b3          	add	a5,s2,s1
    80001f4c:	6388                	ld	a0,0(a5)
    80001f4e:	f17d                	bnez	a0,80001f34 <fork+0xa0>
    80001f50:	bfcd                	j	80001f42 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001f52:	15093503          	ld	a0,336(s2)
    80001f56:	00001097          	auipc	ra,0x1
    80001f5a:	76c080e7          	jalr	1900(ra) # 800036c2 <idup>
    80001f5e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f62:	4641                	li	a2,16
    80001f64:	15890593          	addi	a1,s2,344
    80001f68:	15898513          	addi	a0,s3,344
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	ef6080e7          	jalr	-266(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001f74:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f78:	4789                	li	a5,2
    80001f7a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f7e:	854e                	mv	a0,s3
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	d44080e7          	jalr	-700(ra) # 80000cc4 <release>
}
    80001f88:	8526                	mv	a0,s1
    80001f8a:	70a2                	ld	ra,40(sp)
    80001f8c:	7402                	ld	s0,32(sp)
    80001f8e:	64e2                	ld	s1,24(sp)
    80001f90:	6942                	ld	s2,16(sp)
    80001f92:	69a2                	ld	s3,8(sp)
    80001f94:	6a02                	ld	s4,0(sp)
    80001f96:	6145                	addi	sp,sp,48
    80001f98:	8082                	ret
    return -1;
    80001f9a:	54fd                	li	s1,-1
    80001f9c:	b7f5                	j	80001f88 <fork+0xf4>

0000000080001f9e <reparent>:
{
    80001f9e:	7179                	addi	sp,sp,-48
    80001fa0:	f406                	sd	ra,40(sp)
    80001fa2:	f022                	sd	s0,32(sp)
    80001fa4:	ec26                	sd	s1,24(sp)
    80001fa6:	e84a                	sd	s2,16(sp)
    80001fa8:	e44e                	sd	s3,8(sp)
    80001faa:	e052                	sd	s4,0(sp)
    80001fac:	1800                	addi	s0,sp,48
    80001fae:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fb0:	00010497          	auipc	s1,0x10
    80001fb4:	db848493          	addi	s1,s1,-584 # 80011d68 <proc>
      pp->parent = initproc;
    80001fb8:	00007a17          	auipc	s4,0x7
    80001fbc:	060a0a13          	addi	s4,s4,96 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fc0:	00015997          	auipc	s3,0x15
    80001fc4:	7a898993          	addi	s3,s3,1960 # 80017768 <tickslock>
    80001fc8:	a029                	j	80001fd2 <reparent+0x34>
    80001fca:	16848493          	addi	s1,s1,360
    80001fce:	03348363          	beq	s1,s3,80001ff4 <reparent+0x56>
    if(pp->parent == p){
    80001fd2:	709c                	ld	a5,32(s1)
    80001fd4:	ff279be3          	bne	a5,s2,80001fca <reparent+0x2c>
      acquire(&pp->lock);
    80001fd8:	8526                	mv	a0,s1
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	c36080e7          	jalr	-970(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001fe2:	000a3783          	ld	a5,0(s4)
    80001fe6:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fe8:	8526                	mv	a0,s1
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	cda080e7          	jalr	-806(ra) # 80000cc4 <release>
    80001ff2:	bfe1                	j	80001fca <reparent+0x2c>
}
    80001ff4:	70a2                	ld	ra,40(sp)
    80001ff6:	7402                	ld	s0,32(sp)
    80001ff8:	64e2                	ld	s1,24(sp)
    80001ffa:	6942                	ld	s2,16(sp)
    80001ffc:	69a2                	ld	s3,8(sp)
    80001ffe:	6a02                	ld	s4,0(sp)
    80002000:	6145                	addi	sp,sp,48
    80002002:	8082                	ret

0000000080002004 <scheduler>:
{
    80002004:	715d                	addi	sp,sp,-80
    80002006:	e486                	sd	ra,72(sp)
    80002008:	e0a2                	sd	s0,64(sp)
    8000200a:	fc26                	sd	s1,56(sp)
    8000200c:	f84a                	sd	s2,48(sp)
    8000200e:	f44e                	sd	s3,40(sp)
    80002010:	f052                	sd	s4,32(sp)
    80002012:	ec56                	sd	s5,24(sp)
    80002014:	e85a                	sd	s6,16(sp)
    80002016:	e45e                	sd	s7,8(sp)
    80002018:	e062                	sd	s8,0(sp)
    8000201a:	0880                	addi	s0,sp,80
    8000201c:	8792                	mv	a5,tp
  int id = r_tp();
    8000201e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002020:	00779b13          	slli	s6,a5,0x7
    80002024:	00010717          	auipc	a4,0x10
    80002028:	92c70713          	addi	a4,a4,-1748 # 80011950 <pid_lock>
    8000202c:	975a                	add	a4,a4,s6
    8000202e:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002032:	00010717          	auipc	a4,0x10
    80002036:	93e70713          	addi	a4,a4,-1730 # 80011970 <cpus+0x8>
    8000203a:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    8000203c:	4c0d                	li	s8,3
        c->proc = p;
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	00010a17          	auipc	s4,0x10
    80002044:	910a0a13          	addi	s4,s4,-1776 # 80011950 <pid_lock>
    80002048:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000204a:	00015997          	auipc	s3,0x15
    8000204e:	71e98993          	addi	s3,s3,1822 # 80017768 <tickslock>
        found = 1;
    80002052:	4b85                	li	s7,1
    80002054:	a899                	j	800020aa <scheduler+0xa6>
        p->state = RUNNING;
    80002056:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    8000205a:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    8000205e:	06048593          	addi	a1,s1,96
    80002062:	855a                	mv	a0,s6
    80002064:	00000097          	auipc	ra,0x0
    80002068:	638080e7          	jalr	1592(ra) # 8000269c <swtch>
        c->proc = 0;
    8000206c:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002070:	8ade                	mv	s5,s7
      release(&p->lock);
    80002072:	8526                	mv	a0,s1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	c50080e7          	jalr	-944(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000207c:	16848493          	addi	s1,s1,360
    80002080:	01348b63          	beq	s1,s3,80002096 <scheduler+0x92>
      acquire(&p->lock);
    80002084:	8526                	mv	a0,s1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b8a080e7          	jalr	-1142(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    8000208e:	4c9c                	lw	a5,24(s1)
    80002090:	ff2791e3          	bne	a5,s2,80002072 <scheduler+0x6e>
    80002094:	b7c9                	j	80002056 <scheduler+0x52>
    if(found == 0) {
    80002096:	000a9a63          	bnez	s5,800020aa <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000209a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000209e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020a2:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020a6:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020aa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020ae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020b2:	10079073          	csrw	sstatus,a5
    int found = 0;
    800020b6:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    800020b8:	00010497          	auipc	s1,0x10
    800020bc:	cb048493          	addi	s1,s1,-848 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    800020c0:	4909                	li	s2,2
    800020c2:	b7c9                	j	80002084 <scheduler+0x80>

00000000800020c4 <sched>:
{
    800020c4:	7179                	addi	sp,sp,-48
    800020c6:	f406                	sd	ra,40(sp)
    800020c8:	f022                	sd	s0,32(sp)
    800020ca:	ec26                	sd	s1,24(sp)
    800020cc:	e84a                	sd	s2,16(sp)
    800020ce:	e44e                	sd	s3,8(sp)
    800020d0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	a02080e7          	jalr	-1534(ra) # 80001ad4 <myproc>
    800020da:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	aba080e7          	jalr	-1350(ra) # 80000b96 <holding>
    800020e4:	c93d                	beqz	a0,8000215a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020e6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020e8:	2781                	sext.w	a5,a5
    800020ea:	079e                	slli	a5,a5,0x7
    800020ec:	00010717          	auipc	a4,0x10
    800020f0:	86470713          	addi	a4,a4,-1948 # 80011950 <pid_lock>
    800020f4:	97ba                	add	a5,a5,a4
    800020f6:	0907a703          	lw	a4,144(a5)
    800020fa:	4785                	li	a5,1
    800020fc:	06f71763          	bne	a4,a5,8000216a <sched+0xa6>
  if(p->state == RUNNING)
    80002100:	4c98                	lw	a4,24(s1)
    80002102:	478d                	li	a5,3
    80002104:	06f70b63          	beq	a4,a5,8000217a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002108:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000210c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000210e:	efb5                	bnez	a5,8000218a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002110:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002112:	00010917          	auipc	s2,0x10
    80002116:	83e90913          	addi	s2,s2,-1986 # 80011950 <pid_lock>
    8000211a:	2781                	sext.w	a5,a5
    8000211c:	079e                	slli	a5,a5,0x7
    8000211e:	97ca                	add	a5,a5,s2
    80002120:	0947a983          	lw	s3,148(a5)
    80002124:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002126:	2781                	sext.w	a5,a5
    80002128:	079e                	slli	a5,a5,0x7
    8000212a:	00010597          	auipc	a1,0x10
    8000212e:	84658593          	addi	a1,a1,-1978 # 80011970 <cpus+0x8>
    80002132:	95be                	add	a1,a1,a5
    80002134:	06048513          	addi	a0,s1,96
    80002138:	00000097          	auipc	ra,0x0
    8000213c:	564080e7          	jalr	1380(ra) # 8000269c <swtch>
    80002140:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002142:	2781                	sext.w	a5,a5
    80002144:	079e                	slli	a5,a5,0x7
    80002146:	97ca                	add	a5,a5,s2
    80002148:	0937aa23          	sw	s3,148(a5)
}
    8000214c:	70a2                	ld	ra,40(sp)
    8000214e:	7402                	ld	s0,32(sp)
    80002150:	64e2                	ld	s1,24(sp)
    80002152:	6942                	ld	s2,16(sp)
    80002154:	69a2                	ld	s3,8(sp)
    80002156:	6145                	addi	sp,sp,48
    80002158:	8082                	ret
    panic("sched p->lock");
    8000215a:	00006517          	auipc	a0,0x6
    8000215e:	0fe50513          	addi	a0,a0,254 # 80008258 <digits+0x218>
    80002162:	ffffe097          	auipc	ra,0xffffe
    80002166:	3e6080e7          	jalr	998(ra) # 80000548 <panic>
    panic("sched locks");
    8000216a:	00006517          	auipc	a0,0x6
    8000216e:	0fe50513          	addi	a0,a0,254 # 80008268 <digits+0x228>
    80002172:	ffffe097          	auipc	ra,0xffffe
    80002176:	3d6080e7          	jalr	982(ra) # 80000548 <panic>
    panic("sched running");
    8000217a:	00006517          	auipc	a0,0x6
    8000217e:	0fe50513          	addi	a0,a0,254 # 80008278 <digits+0x238>
    80002182:	ffffe097          	auipc	ra,0xffffe
    80002186:	3c6080e7          	jalr	966(ra) # 80000548 <panic>
    panic("sched interruptible");
    8000218a:	00006517          	auipc	a0,0x6
    8000218e:	0fe50513          	addi	a0,a0,254 # 80008288 <digits+0x248>
    80002192:	ffffe097          	auipc	ra,0xffffe
    80002196:	3b6080e7          	jalr	950(ra) # 80000548 <panic>

000000008000219a <exit>:
{
    8000219a:	7179                	addi	sp,sp,-48
    8000219c:	f406                	sd	ra,40(sp)
    8000219e:	f022                	sd	s0,32(sp)
    800021a0:	ec26                	sd	s1,24(sp)
    800021a2:	e84a                	sd	s2,16(sp)
    800021a4:	e44e                	sd	s3,8(sp)
    800021a6:	e052                	sd	s4,0(sp)
    800021a8:	1800                	addi	s0,sp,48
    800021aa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	928080e7          	jalr	-1752(ra) # 80001ad4 <myproc>
    800021b4:	89aa                	mv	s3,a0
  if(p == initproc)
    800021b6:	00007797          	auipc	a5,0x7
    800021ba:	e627b783          	ld	a5,-414(a5) # 80009018 <initproc>
    800021be:	0d050493          	addi	s1,a0,208
    800021c2:	15050913          	addi	s2,a0,336
    800021c6:	02a79363          	bne	a5,a0,800021ec <exit+0x52>
    panic("init exiting");
    800021ca:	00006517          	auipc	a0,0x6
    800021ce:	0d650513          	addi	a0,a0,214 # 800082a0 <digits+0x260>
    800021d2:	ffffe097          	auipc	ra,0xffffe
    800021d6:	376080e7          	jalr	886(ra) # 80000548 <panic>
      fileclose(f);
    800021da:	00002097          	auipc	ra,0x2
    800021de:	3b4080e7          	jalr	948(ra) # 8000458e <fileclose>
      p->ofile[fd] = 0;
    800021e2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021e6:	04a1                	addi	s1,s1,8
    800021e8:	01248563          	beq	s1,s2,800021f2 <exit+0x58>
    if(p->ofile[fd]){
    800021ec:	6088                	ld	a0,0(s1)
    800021ee:	f575                	bnez	a0,800021da <exit+0x40>
    800021f0:	bfdd                	j	800021e6 <exit+0x4c>
  begin_op();
    800021f2:	00002097          	auipc	ra,0x2
    800021f6:	eca080e7          	jalr	-310(ra) # 800040bc <begin_op>
  iput(p->cwd);
    800021fa:	1509b503          	ld	a0,336(s3)
    800021fe:	00001097          	auipc	ra,0x1
    80002202:	6bc080e7          	jalr	1724(ra) # 800038ba <iput>
  end_op();
    80002206:	00002097          	auipc	ra,0x2
    8000220a:	f36080e7          	jalr	-202(ra) # 8000413c <end_op>
  p->cwd = 0;
    8000220e:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002212:	00007497          	auipc	s1,0x7
    80002216:	e0648493          	addi	s1,s1,-506 # 80009018 <initproc>
    8000221a:	6088                	ld	a0,0(s1)
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	9f4080e7          	jalr	-1548(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    80002224:	6088                	ld	a0,0(s1)
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	76e080e7          	jalr	1902(ra) # 80001994 <wakeup1>
  release(&initproc->lock);
    8000222e:	6088                	ld	a0,0(s1)
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	a94080e7          	jalr	-1388(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002238:	854e                	mv	a0,s3
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	9d6080e7          	jalr	-1578(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    80002242:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002246:	854e                	mv	a0,s3
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	a7c080e7          	jalr	-1412(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    80002250:	8526                	mv	a0,s1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	9be080e7          	jalr	-1602(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    8000225a:	854e                	mv	a0,s3
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	9b4080e7          	jalr	-1612(ra) # 80000c10 <acquire>
  reparent(p);
    80002264:	854e                	mv	a0,s3
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	d38080e7          	jalr	-712(ra) # 80001f9e <reparent>
  wakeup1(original_parent);
    8000226e:	8526                	mv	a0,s1
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	724080e7          	jalr	1828(ra) # 80001994 <wakeup1>
  p->xstate = status;
    80002278:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000227c:	4791                	li	a5,4
    8000227e:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a40080e7          	jalr	-1472(ra) # 80000cc4 <release>
  sched();
    8000228c:	00000097          	auipc	ra,0x0
    80002290:	e38080e7          	jalr	-456(ra) # 800020c4 <sched>
  panic("zombie exit");
    80002294:	00006517          	auipc	a0,0x6
    80002298:	01c50513          	addi	a0,a0,28 # 800082b0 <digits+0x270>
    8000229c:	ffffe097          	auipc	ra,0xffffe
    800022a0:	2ac080e7          	jalr	684(ra) # 80000548 <panic>

00000000800022a4 <yield>:
{
    800022a4:	1101                	addi	sp,sp,-32
    800022a6:	ec06                	sd	ra,24(sp)
    800022a8:	e822                	sd	s0,16(sp)
    800022aa:	e426                	sd	s1,8(sp)
    800022ac:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	826080e7          	jalr	-2010(ra) # 80001ad4 <myproc>
    800022b6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	958080e7          	jalr	-1704(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800022c0:	4789                	li	a5,2
    800022c2:	cc9c                	sw	a5,24(s1)
  sched();
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	e00080e7          	jalr	-512(ra) # 800020c4 <sched>
  release(&p->lock);
    800022cc:	8526                	mv	a0,s1
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	9f6080e7          	jalr	-1546(ra) # 80000cc4 <release>
}
    800022d6:	60e2                	ld	ra,24(sp)
    800022d8:	6442                	ld	s0,16(sp)
    800022da:	64a2                	ld	s1,8(sp)
    800022dc:	6105                	addi	sp,sp,32
    800022de:	8082                	ret

00000000800022e0 <sleep>:
{
    800022e0:	7179                	addi	sp,sp,-48
    800022e2:	f406                	sd	ra,40(sp)
    800022e4:	f022                	sd	s0,32(sp)
    800022e6:	ec26                	sd	s1,24(sp)
    800022e8:	e84a                	sd	s2,16(sp)
    800022ea:	e44e                	sd	s3,8(sp)
    800022ec:	1800                	addi	s0,sp,48
    800022ee:	89aa                	mv	s3,a0
    800022f0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	7e2080e7          	jalr	2018(ra) # 80001ad4 <myproc>
    800022fa:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022fc:	05250663          	beq	a0,s2,80002348 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	910080e7          	jalr	-1776(ra) # 80000c10 <acquire>
    release(lk);
    80002308:	854a                	mv	a0,s2
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	9ba080e7          	jalr	-1606(ra) # 80000cc4 <release>
  p->chan = chan;
    80002312:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002316:	4785                	li	a5,1
    80002318:	cc9c                	sw	a5,24(s1)
  sched();
    8000231a:	00000097          	auipc	ra,0x0
    8000231e:	daa080e7          	jalr	-598(ra) # 800020c4 <sched>
  p->chan = 0;
    80002322:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	99c080e7          	jalr	-1636(ra) # 80000cc4 <release>
    acquire(lk);
    80002330:	854a                	mv	a0,s2
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	8de080e7          	jalr	-1826(ra) # 80000c10 <acquire>
}
    8000233a:	70a2                	ld	ra,40(sp)
    8000233c:	7402                	ld	s0,32(sp)
    8000233e:	64e2                	ld	s1,24(sp)
    80002340:	6942                	ld	s2,16(sp)
    80002342:	69a2                	ld	s3,8(sp)
    80002344:	6145                	addi	sp,sp,48
    80002346:	8082                	ret
  p->chan = chan;
    80002348:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000234c:	4785                	li	a5,1
    8000234e:	cd1c                	sw	a5,24(a0)
  sched();
    80002350:	00000097          	auipc	ra,0x0
    80002354:	d74080e7          	jalr	-652(ra) # 800020c4 <sched>
  p->chan = 0;
    80002358:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000235c:	bff9                	j	8000233a <sleep+0x5a>

000000008000235e <wait>:
{
    8000235e:	715d                	addi	sp,sp,-80
    80002360:	e486                	sd	ra,72(sp)
    80002362:	e0a2                	sd	s0,64(sp)
    80002364:	fc26                	sd	s1,56(sp)
    80002366:	f84a                	sd	s2,48(sp)
    80002368:	f44e                	sd	s3,40(sp)
    8000236a:	f052                	sd	s4,32(sp)
    8000236c:	ec56                	sd	s5,24(sp)
    8000236e:	e85a                	sd	s6,16(sp)
    80002370:	e45e                	sd	s7,8(sp)
    80002372:	e062                	sd	s8,0(sp)
    80002374:	0880                	addi	s0,sp,80
    80002376:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	75c080e7          	jalr	1884(ra) # 80001ad4 <myproc>
    80002380:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002382:	8c2a                	mv	s8,a0
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	88c080e7          	jalr	-1908(ra) # 80000c10 <acquire>
    havekids = 0;
    8000238c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000238e:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002390:	00015997          	auipc	s3,0x15
    80002394:	3d898993          	addi	s3,s3,984 # 80017768 <tickslock>
        havekids = 1;
    80002398:	4a85                	li	s5,1
    havekids = 0;
    8000239a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000239c:	00010497          	auipc	s1,0x10
    800023a0:	9cc48493          	addi	s1,s1,-1588 # 80011d68 <proc>
    800023a4:	a08d                	j	80002406 <wait+0xa8>
          pid = np->pid;
    800023a6:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023aa:	000b0e63          	beqz	s6,800023c6 <wait+0x68>
    800023ae:	4691                	li	a3,4
    800023b0:	03448613          	addi	a2,s1,52
    800023b4:	85da                	mv	a1,s6
    800023b6:	05093503          	ld	a0,80(s2)
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	320080e7          	jalr	800(ra) # 800016da <copyout>
    800023c2:	02054263          	bltz	a0,800023e6 <wait+0x88>
          freeproc(np);
    800023c6:	8526                	mv	a0,s1
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	8be080e7          	jalr	-1858(ra) # 80001c86 <freeproc>
          release(&np->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8f2080e7          	jalr	-1806(ra) # 80000cc4 <release>
          release(&p->lock);
    800023da:	854a                	mv	a0,s2
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8e8080e7          	jalr	-1816(ra) # 80000cc4 <release>
          return pid;
    800023e4:	a8a9                	j	8000243e <wait+0xe0>
            release(&np->lock);
    800023e6:	8526                	mv	a0,s1
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	8dc080e7          	jalr	-1828(ra) # 80000cc4 <release>
            release(&p->lock);
    800023f0:	854a                	mv	a0,s2
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8d2080e7          	jalr	-1838(ra) # 80000cc4 <release>
            return -1;
    800023fa:	59fd                	li	s3,-1
    800023fc:	a089                	j	8000243e <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023fe:	16848493          	addi	s1,s1,360
    80002402:	03348463          	beq	s1,s3,8000242a <wait+0xcc>
      if(np->parent == p){
    80002406:	709c                	ld	a5,32(s1)
    80002408:	ff279be3          	bne	a5,s2,800023fe <wait+0xa0>
        acquire(&np->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	802080e7          	jalr	-2046(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    80002416:	4c9c                	lw	a5,24(s1)
    80002418:	f94787e3          	beq	a5,s4,800023a6 <wait+0x48>
        release(&np->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	8a6080e7          	jalr	-1882(ra) # 80000cc4 <release>
        havekids = 1;
    80002426:	8756                	mv	a4,s5
    80002428:	bfd9                	j	800023fe <wait+0xa0>
    if(!havekids || p->killed){
    8000242a:	c701                	beqz	a4,80002432 <wait+0xd4>
    8000242c:	03092783          	lw	a5,48(s2)
    80002430:	c785                	beqz	a5,80002458 <wait+0xfa>
      release(&p->lock);
    80002432:	854a                	mv	a0,s2
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	890080e7          	jalr	-1904(ra) # 80000cc4 <release>
      return -1;
    8000243c:	59fd                	li	s3,-1
}
    8000243e:	854e                	mv	a0,s3
    80002440:	60a6                	ld	ra,72(sp)
    80002442:	6406                	ld	s0,64(sp)
    80002444:	74e2                	ld	s1,56(sp)
    80002446:	7942                	ld	s2,48(sp)
    80002448:	79a2                	ld	s3,40(sp)
    8000244a:	7a02                	ld	s4,32(sp)
    8000244c:	6ae2                	ld	s5,24(sp)
    8000244e:	6b42                	ld	s6,16(sp)
    80002450:	6ba2                	ld	s7,8(sp)
    80002452:	6c02                	ld	s8,0(sp)
    80002454:	6161                	addi	sp,sp,80
    80002456:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002458:	85e2                	mv	a1,s8
    8000245a:	854a                	mv	a0,s2
    8000245c:	00000097          	auipc	ra,0x0
    80002460:	e84080e7          	jalr	-380(ra) # 800022e0 <sleep>
    havekids = 0;
    80002464:	bf1d                	j	8000239a <wait+0x3c>

0000000080002466 <wakeup>:
{
    80002466:	7139                	addi	sp,sp,-64
    80002468:	fc06                	sd	ra,56(sp)
    8000246a:	f822                	sd	s0,48(sp)
    8000246c:	f426                	sd	s1,40(sp)
    8000246e:	f04a                	sd	s2,32(sp)
    80002470:	ec4e                	sd	s3,24(sp)
    80002472:	e852                	sd	s4,16(sp)
    80002474:	e456                	sd	s5,8(sp)
    80002476:	0080                	addi	s0,sp,64
    80002478:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000247a:	00010497          	auipc	s1,0x10
    8000247e:	8ee48493          	addi	s1,s1,-1810 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002482:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002484:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002486:	00015917          	auipc	s2,0x15
    8000248a:	2e290913          	addi	s2,s2,738 # 80017768 <tickslock>
    8000248e:	a821                	j	800024a6 <wakeup+0x40>
      p->state = RUNNABLE;
    80002490:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	82e080e7          	jalr	-2002(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000249e:	16848493          	addi	s1,s1,360
    800024a2:	01248e63          	beq	s1,s2,800024be <wakeup+0x58>
    acquire(&p->lock);
    800024a6:	8526                	mv	a0,s1
    800024a8:	ffffe097          	auipc	ra,0xffffe
    800024ac:	768080e7          	jalr	1896(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800024b0:	4c9c                	lw	a5,24(s1)
    800024b2:	ff3791e3          	bne	a5,s3,80002494 <wakeup+0x2e>
    800024b6:	749c                	ld	a5,40(s1)
    800024b8:	fd479ee3          	bne	a5,s4,80002494 <wakeup+0x2e>
    800024bc:	bfd1                	j	80002490 <wakeup+0x2a>
}
    800024be:	70e2                	ld	ra,56(sp)
    800024c0:	7442                	ld	s0,48(sp)
    800024c2:	74a2                	ld	s1,40(sp)
    800024c4:	7902                	ld	s2,32(sp)
    800024c6:	69e2                	ld	s3,24(sp)
    800024c8:	6a42                	ld	s4,16(sp)
    800024ca:	6aa2                	ld	s5,8(sp)
    800024cc:	6121                	addi	sp,sp,64
    800024ce:	8082                	ret

00000000800024d0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024d0:	7179                	addi	sp,sp,-48
    800024d2:	f406                	sd	ra,40(sp)
    800024d4:	f022                	sd	s0,32(sp)
    800024d6:	ec26                	sd	s1,24(sp)
    800024d8:	e84a                	sd	s2,16(sp)
    800024da:	e44e                	sd	s3,8(sp)
    800024dc:	1800                	addi	s0,sp,48
    800024de:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024e0:	00010497          	auipc	s1,0x10
    800024e4:	88848493          	addi	s1,s1,-1912 # 80011d68 <proc>
    800024e8:	00015997          	auipc	s3,0x15
    800024ec:	28098993          	addi	s3,s3,640 # 80017768 <tickslock>
    acquire(&p->lock);
    800024f0:	8526                	mv	a0,s1
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	71e080e7          	jalr	1822(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    800024fa:	5c9c                	lw	a5,56(s1)
    800024fc:	01278d63          	beq	a5,s2,80002516 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002500:	8526                	mv	a0,s1
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	7c2080e7          	jalr	1986(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000250a:	16848493          	addi	s1,s1,360
    8000250e:	ff3491e3          	bne	s1,s3,800024f0 <kill+0x20>
  }
  return -1;
    80002512:	557d                	li	a0,-1
    80002514:	a829                	j	8000252e <kill+0x5e>
      p->killed = 1;
    80002516:	4785                	li	a5,1
    80002518:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000251a:	4c98                	lw	a4,24(s1)
    8000251c:	4785                	li	a5,1
    8000251e:	00f70f63          	beq	a4,a5,8000253c <kill+0x6c>
      release(&p->lock);
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	7a0080e7          	jalr	1952(ra) # 80000cc4 <release>
      return 0;
    8000252c:	4501                	li	a0,0
}
    8000252e:	70a2                	ld	ra,40(sp)
    80002530:	7402                	ld	s0,32(sp)
    80002532:	64e2                	ld	s1,24(sp)
    80002534:	6942                	ld	s2,16(sp)
    80002536:	69a2                	ld	s3,8(sp)
    80002538:	6145                	addi	sp,sp,48
    8000253a:	8082                	ret
        p->state = RUNNABLE;
    8000253c:	4789                	li	a5,2
    8000253e:	cc9c                	sw	a5,24(s1)
    80002540:	b7cd                	j	80002522 <kill+0x52>

0000000080002542 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002542:	7179                	addi	sp,sp,-48
    80002544:	f406                	sd	ra,40(sp)
    80002546:	f022                	sd	s0,32(sp)
    80002548:	ec26                	sd	s1,24(sp)
    8000254a:	e84a                	sd	s2,16(sp)
    8000254c:	e44e                	sd	s3,8(sp)
    8000254e:	e052                	sd	s4,0(sp)
    80002550:	1800                	addi	s0,sp,48
    80002552:	84aa                	mv	s1,a0
    80002554:	892e                	mv	s2,a1
    80002556:	89b2                	mv	s3,a2
    80002558:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	57a080e7          	jalr	1402(ra) # 80001ad4 <myproc>
  if(user_dst){
    80002562:	c08d                	beqz	s1,80002584 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002564:	86d2                	mv	a3,s4
    80002566:	864e                	mv	a2,s3
    80002568:	85ca                	mv	a1,s2
    8000256a:	6928                	ld	a0,80(a0)
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	16e080e7          	jalr	366(ra) # 800016da <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002574:	70a2                	ld	ra,40(sp)
    80002576:	7402                	ld	s0,32(sp)
    80002578:	64e2                	ld	s1,24(sp)
    8000257a:	6942                	ld	s2,16(sp)
    8000257c:	69a2                	ld	s3,8(sp)
    8000257e:	6a02                	ld	s4,0(sp)
    80002580:	6145                	addi	sp,sp,48
    80002582:	8082                	ret
    memmove((char *)dst, src, len);
    80002584:	000a061b          	sext.w	a2,s4
    80002588:	85ce                	mv	a1,s3
    8000258a:	854a                	mv	a0,s2
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	7e0080e7          	jalr	2016(ra) # 80000d6c <memmove>
    return 0;
    80002594:	8526                	mv	a0,s1
    80002596:	bff9                	j	80002574 <either_copyout+0x32>

0000000080002598 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002598:	7179                	addi	sp,sp,-48
    8000259a:	f406                	sd	ra,40(sp)
    8000259c:	f022                	sd	s0,32(sp)
    8000259e:	ec26                	sd	s1,24(sp)
    800025a0:	e84a                	sd	s2,16(sp)
    800025a2:	e44e                	sd	s3,8(sp)
    800025a4:	e052                	sd	s4,0(sp)
    800025a6:	1800                	addi	s0,sp,48
    800025a8:	892a                	mv	s2,a0
    800025aa:	84ae                	mv	s1,a1
    800025ac:	89b2                	mv	s3,a2
    800025ae:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025b0:	fffff097          	auipc	ra,0xfffff
    800025b4:	524080e7          	jalr	1316(ra) # 80001ad4 <myproc>
  if(user_src){
    800025b8:	c08d                	beqz	s1,800025da <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025ba:	86d2                	mv	a3,s4
    800025bc:	864e                	mv	a2,s3
    800025be:	85ca                	mv	a1,s2
    800025c0:	6928                	ld	a0,80(a0)
    800025c2:	fffff097          	auipc	ra,0xfffff
    800025c6:	1a4080e7          	jalr	420(ra) # 80001766 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025ca:	70a2                	ld	ra,40(sp)
    800025cc:	7402                	ld	s0,32(sp)
    800025ce:	64e2                	ld	s1,24(sp)
    800025d0:	6942                	ld	s2,16(sp)
    800025d2:	69a2                	ld	s3,8(sp)
    800025d4:	6a02                	ld	s4,0(sp)
    800025d6:	6145                	addi	sp,sp,48
    800025d8:	8082                	ret
    memmove(dst, (char*)src, len);
    800025da:	000a061b          	sext.w	a2,s4
    800025de:	85ce                	mv	a1,s3
    800025e0:	854a                	mv	a0,s2
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	78a080e7          	jalr	1930(ra) # 80000d6c <memmove>
    return 0;
    800025ea:	8526                	mv	a0,s1
    800025ec:	bff9                	j	800025ca <either_copyin+0x32>

00000000800025ee <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ee:	715d                	addi	sp,sp,-80
    800025f0:	e486                	sd	ra,72(sp)
    800025f2:	e0a2                	sd	s0,64(sp)
    800025f4:	fc26                	sd	s1,56(sp)
    800025f6:	f84a                	sd	s2,48(sp)
    800025f8:	f44e                	sd	s3,40(sp)
    800025fa:	f052                	sd	s4,32(sp)
    800025fc:	ec56                	sd	s5,24(sp)
    800025fe:	e85a                	sd	s6,16(sp)
    80002600:	e45e                	sd	s7,8(sp)
    80002602:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002604:	00006517          	auipc	a0,0x6
    80002608:	ac450513          	addi	a0,a0,-1340 # 800080c8 <digits+0x88>
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	f86080e7          	jalr	-122(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002614:	00010497          	auipc	s1,0x10
    80002618:	8ac48493          	addi	s1,s1,-1876 # 80011ec0 <proc+0x158>
    8000261c:	00015917          	auipc	s2,0x15
    80002620:	2a490913          	addi	s2,s2,676 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002624:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002626:	00006997          	auipc	s3,0x6
    8000262a:	c9a98993          	addi	s3,s3,-870 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    8000262e:	00006a97          	auipc	s5,0x6
    80002632:	c9aa8a93          	addi	s5,s5,-870 # 800082c8 <digits+0x288>
    printf("\n");
    80002636:	00006a17          	auipc	s4,0x6
    8000263a:	a92a0a13          	addi	s4,s4,-1390 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000263e:	00006b97          	auipc	s7,0x6
    80002642:	cc2b8b93          	addi	s7,s7,-830 # 80008300 <states.1712>
    80002646:	a00d                	j	80002668 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002648:	ee06a583          	lw	a1,-288(a3)
    8000264c:	8556                	mv	a0,s5
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	f44080e7          	jalr	-188(ra) # 80000592 <printf>
    printf("\n");
    80002656:	8552                	mv	a0,s4
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	f3a080e7          	jalr	-198(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002660:	16848493          	addi	s1,s1,360
    80002664:	03248163          	beq	s1,s2,80002686 <procdump+0x98>
    if(p->state == UNUSED)
    80002668:	86a6                	mv	a3,s1
    8000266a:	ec04a783          	lw	a5,-320(s1)
    8000266e:	dbed                	beqz	a5,80002660 <procdump+0x72>
      state = "???";
    80002670:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002672:	fcfb6be3          	bltu	s6,a5,80002648 <procdump+0x5a>
    80002676:	1782                	slli	a5,a5,0x20
    80002678:	9381                	srli	a5,a5,0x20
    8000267a:	078e                	slli	a5,a5,0x3
    8000267c:	97de                	add	a5,a5,s7
    8000267e:	6390                	ld	a2,0(a5)
    80002680:	f661                	bnez	a2,80002648 <procdump+0x5a>
      state = "???";
    80002682:	864e                	mv	a2,s3
    80002684:	b7d1                	j	80002648 <procdump+0x5a>
  }
}
    80002686:	60a6                	ld	ra,72(sp)
    80002688:	6406                	ld	s0,64(sp)
    8000268a:	74e2                	ld	s1,56(sp)
    8000268c:	7942                	ld	s2,48(sp)
    8000268e:	79a2                	ld	s3,40(sp)
    80002690:	7a02                	ld	s4,32(sp)
    80002692:	6ae2                	ld	s5,24(sp)
    80002694:	6b42                	ld	s6,16(sp)
    80002696:	6ba2                	ld	s7,8(sp)
    80002698:	6161                	addi	sp,sp,80
    8000269a:	8082                	ret

000000008000269c <swtch>:
    8000269c:	00153023          	sd	ra,0(a0)
    800026a0:	00253423          	sd	sp,8(a0)
    800026a4:	e900                	sd	s0,16(a0)
    800026a6:	ed04                	sd	s1,24(a0)
    800026a8:	03253023          	sd	s2,32(a0)
    800026ac:	03353423          	sd	s3,40(a0)
    800026b0:	03453823          	sd	s4,48(a0)
    800026b4:	03553c23          	sd	s5,56(a0)
    800026b8:	05653023          	sd	s6,64(a0)
    800026bc:	05753423          	sd	s7,72(a0)
    800026c0:	05853823          	sd	s8,80(a0)
    800026c4:	05953c23          	sd	s9,88(a0)
    800026c8:	07a53023          	sd	s10,96(a0)
    800026cc:	07b53423          	sd	s11,104(a0)
    800026d0:	0005b083          	ld	ra,0(a1)
    800026d4:	0085b103          	ld	sp,8(a1)
    800026d8:	6980                	ld	s0,16(a1)
    800026da:	6d84                	ld	s1,24(a1)
    800026dc:	0205b903          	ld	s2,32(a1)
    800026e0:	0285b983          	ld	s3,40(a1)
    800026e4:	0305ba03          	ld	s4,48(a1)
    800026e8:	0385ba83          	ld	s5,56(a1)
    800026ec:	0405bb03          	ld	s6,64(a1)
    800026f0:	0485bb83          	ld	s7,72(a1)
    800026f4:	0505bc03          	ld	s8,80(a1)
    800026f8:	0585bc83          	ld	s9,88(a1)
    800026fc:	0605bd03          	ld	s10,96(a1)
    80002700:	0685bd83          	ld	s11,104(a1)
    80002704:	8082                	ret

0000000080002706 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002706:	1141                	addi	sp,sp,-16
    80002708:	e406                	sd	ra,8(sp)
    8000270a:	e022                	sd	s0,0(sp)
    8000270c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000270e:	00006597          	auipc	a1,0x6
    80002712:	c1a58593          	addi	a1,a1,-998 # 80008328 <states.1712+0x28>
    80002716:	00015517          	auipc	a0,0x15
    8000271a:	05250513          	addi	a0,a0,82 # 80017768 <tickslock>
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	462080e7          	jalr	1122(ra) # 80000b80 <initlock>
}
    80002726:	60a2                	ld	ra,8(sp)
    80002728:	6402                	ld	s0,0(sp)
    8000272a:	0141                	addi	sp,sp,16
    8000272c:	8082                	ret

000000008000272e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000272e:	1141                	addi	sp,sp,-16
    80002730:	e422                	sd	s0,8(sp)
    80002732:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002734:	00003797          	auipc	a5,0x3
    80002738:	4dc78793          	addi	a5,a5,1244 # 80005c10 <kernelvec>
    8000273c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002740:	6422                	ld	s0,8(sp)
    80002742:	0141                	addi	sp,sp,16
    80002744:	8082                	ret

0000000080002746 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002746:	1141                	addi	sp,sp,-16
    80002748:	e406                	sd	ra,8(sp)
    8000274a:	e022                	sd	s0,0(sp)
    8000274c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000274e:	fffff097          	auipc	ra,0xfffff
    80002752:	386080e7          	jalr	902(ra) # 80001ad4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002756:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000275a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000275c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002760:	00005617          	auipc	a2,0x5
    80002764:	8a060613          	addi	a2,a2,-1888 # 80007000 <_trampoline>
    80002768:	00005697          	auipc	a3,0x5
    8000276c:	89868693          	addi	a3,a3,-1896 # 80007000 <_trampoline>
    80002770:	8e91                	sub	a3,a3,a2
    80002772:	040007b7          	lui	a5,0x4000
    80002776:	17fd                	addi	a5,a5,-1
    80002778:	07b2                	slli	a5,a5,0xc
    8000277a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000277c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002780:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002782:	180026f3          	csrr	a3,satp
    80002786:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002788:	6d38                	ld	a4,88(a0)
    8000278a:	6134                	ld	a3,64(a0)
    8000278c:	6585                	lui	a1,0x1
    8000278e:	96ae                	add	a3,a3,a1
    80002790:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002792:	6d38                	ld	a4,88(a0)
    80002794:	00000697          	auipc	a3,0x0
    80002798:	13868693          	addi	a3,a3,312 # 800028cc <usertrap>
    8000279c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000279e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027a0:	8692                	mv	a3,tp
    800027a2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027a4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027a8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027ac:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027b0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027b4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027b6:	6f18                	ld	a4,24(a4)
    800027b8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027bc:	692c                	ld	a1,80(a0)
    800027be:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027c0:	00005717          	auipc	a4,0x5
    800027c4:	8d070713          	addi	a4,a4,-1840 # 80007090 <userret>
    800027c8:	8f11                	sub	a4,a4,a2
    800027ca:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027cc:	577d                	li	a4,-1
    800027ce:	177e                	slli	a4,a4,0x3f
    800027d0:	8dd9                	or	a1,a1,a4
    800027d2:	02000537          	lui	a0,0x2000
    800027d6:	157d                	addi	a0,a0,-1
    800027d8:	0536                	slli	a0,a0,0xd
    800027da:	9782                	jalr	a5
}
    800027dc:	60a2                	ld	ra,8(sp)
    800027de:	6402                	ld	s0,0(sp)
    800027e0:	0141                	addi	sp,sp,16
    800027e2:	8082                	ret

00000000800027e4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027e4:	1101                	addi	sp,sp,-32
    800027e6:	ec06                	sd	ra,24(sp)
    800027e8:	e822                	sd	s0,16(sp)
    800027ea:	e426                	sd	s1,8(sp)
    800027ec:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027ee:	00015497          	auipc	s1,0x15
    800027f2:	f7a48493          	addi	s1,s1,-134 # 80017768 <tickslock>
    800027f6:	8526                	mv	a0,s1
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	418080e7          	jalr	1048(ra) # 80000c10 <acquire>
  ticks++;
    80002800:	00007517          	auipc	a0,0x7
    80002804:	82050513          	addi	a0,a0,-2016 # 80009020 <ticks>
    80002808:	411c                	lw	a5,0(a0)
    8000280a:	2785                	addiw	a5,a5,1
    8000280c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000280e:	00000097          	auipc	ra,0x0
    80002812:	c58080e7          	jalr	-936(ra) # 80002466 <wakeup>
  release(&tickslock);
    80002816:	8526                	mv	a0,s1
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	4ac080e7          	jalr	1196(ra) # 80000cc4 <release>
}
    80002820:	60e2                	ld	ra,24(sp)
    80002822:	6442                	ld	s0,16(sp)
    80002824:	64a2                	ld	s1,8(sp)
    80002826:	6105                	addi	sp,sp,32
    80002828:	8082                	ret

000000008000282a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000282a:	1101                	addi	sp,sp,-32
    8000282c:	ec06                	sd	ra,24(sp)
    8000282e:	e822                	sd	s0,16(sp)
    80002830:	e426                	sd	s1,8(sp)
    80002832:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002834:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002838:	00074d63          	bltz	a4,80002852 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000283c:	57fd                	li	a5,-1
    8000283e:	17fe                	slli	a5,a5,0x3f
    80002840:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002842:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002844:	06f70363          	beq	a4,a5,800028aa <devintr+0x80>
  }
}
    80002848:	60e2                	ld	ra,24(sp)
    8000284a:	6442                	ld	s0,16(sp)
    8000284c:	64a2                	ld	s1,8(sp)
    8000284e:	6105                	addi	sp,sp,32
    80002850:	8082                	ret
     (scause & 0xff) == 9){
    80002852:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002856:	46a5                	li	a3,9
    80002858:	fed792e3          	bne	a5,a3,8000283c <devintr+0x12>
    int irq = plic_claim();
    8000285c:	00003097          	auipc	ra,0x3
    80002860:	4bc080e7          	jalr	1212(ra) # 80005d18 <plic_claim>
    80002864:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002866:	47a9                	li	a5,10
    80002868:	02f50763          	beq	a0,a5,80002896 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000286c:	4785                	li	a5,1
    8000286e:	02f50963          	beq	a0,a5,800028a0 <devintr+0x76>
    return 1;
    80002872:	4505                	li	a0,1
    } else if(irq){
    80002874:	d8f1                	beqz	s1,80002848 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002876:	85a6                	mv	a1,s1
    80002878:	00006517          	auipc	a0,0x6
    8000287c:	ab850513          	addi	a0,a0,-1352 # 80008330 <states.1712+0x30>
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	d12080e7          	jalr	-750(ra) # 80000592 <printf>
      plic_complete(irq);
    80002888:	8526                	mv	a0,s1
    8000288a:	00003097          	auipc	ra,0x3
    8000288e:	4b2080e7          	jalr	1202(ra) # 80005d3c <plic_complete>
    return 1;
    80002892:	4505                	li	a0,1
    80002894:	bf55                	j	80002848 <devintr+0x1e>
      uartintr();
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	13e080e7          	jalr	318(ra) # 800009d4 <uartintr>
    8000289e:	b7ed                	j	80002888 <devintr+0x5e>
      virtio_disk_intr();
    800028a0:	00004097          	auipc	ra,0x4
    800028a4:	936080e7          	jalr	-1738(ra) # 800061d6 <virtio_disk_intr>
    800028a8:	b7c5                	j	80002888 <devintr+0x5e>
    if(cpuid() == 0){
    800028aa:	fffff097          	auipc	ra,0xfffff
    800028ae:	1fe080e7          	jalr	510(ra) # 80001aa8 <cpuid>
    800028b2:	c901                	beqz	a0,800028c2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028b4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028b8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028ba:	14479073          	csrw	sip,a5
    return 2;
    800028be:	4509                	li	a0,2
    800028c0:	b761                	j	80002848 <devintr+0x1e>
      clockintr();
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	f22080e7          	jalr	-222(ra) # 800027e4 <clockintr>
    800028ca:	b7ed                	j	800028b4 <devintr+0x8a>

00000000800028cc <usertrap>:
{
    800028cc:	1101                	addi	sp,sp,-32
    800028ce:	ec06                	sd	ra,24(sp)
    800028d0:	e822                	sd	s0,16(sp)
    800028d2:	e426                	sd	s1,8(sp)
    800028d4:	e04a                	sd	s2,0(sp)
    800028d6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028dc:	1007f793          	andi	a5,a5,256
    800028e0:	e3ad                	bnez	a5,80002942 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028e2:	00003797          	auipc	a5,0x3
    800028e6:	32e78793          	addi	a5,a5,814 # 80005c10 <kernelvec>
    800028ea:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ee:	fffff097          	auipc	ra,0xfffff
    800028f2:	1e6080e7          	jalr	486(ra) # 80001ad4 <myproc>
    800028f6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028f8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fa:	14102773          	csrr	a4,sepc
    800028fe:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002900:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002904:	47a1                	li	a5,8
    80002906:	04f71c63          	bne	a4,a5,8000295e <usertrap+0x92>
    if(p->killed)
    8000290a:	591c                	lw	a5,48(a0)
    8000290c:	e3b9                	bnez	a5,80002952 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000290e:	6cb8                	ld	a4,88(s1)
    80002910:	6f1c                	ld	a5,24(a4)
    80002912:	0791                	addi	a5,a5,4
    80002914:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002916:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000291a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000291e:	10079073          	csrw	sstatus,a5
    syscall();
    80002922:	00000097          	auipc	ra,0x0
    80002926:	2e0080e7          	jalr	736(ra) # 80002c02 <syscall>
  if(p->killed)
    8000292a:	589c                	lw	a5,48(s1)
    8000292c:	ebc1                	bnez	a5,800029bc <usertrap+0xf0>
  usertrapret();
    8000292e:	00000097          	auipc	ra,0x0
    80002932:	e18080e7          	jalr	-488(ra) # 80002746 <usertrapret>
}
    80002936:	60e2                	ld	ra,24(sp)
    80002938:	6442                	ld	s0,16(sp)
    8000293a:	64a2                	ld	s1,8(sp)
    8000293c:	6902                	ld	s2,0(sp)
    8000293e:	6105                	addi	sp,sp,32
    80002940:	8082                	ret
    panic("usertrap: not from user mode");
    80002942:	00006517          	auipc	a0,0x6
    80002946:	a0e50513          	addi	a0,a0,-1522 # 80008350 <states.1712+0x50>
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	bfe080e7          	jalr	-1026(ra) # 80000548 <panic>
      exit(-1);
    80002952:	557d                	li	a0,-1
    80002954:	00000097          	auipc	ra,0x0
    80002958:	846080e7          	jalr	-1978(ra) # 8000219a <exit>
    8000295c:	bf4d                	j	8000290e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	ecc080e7          	jalr	-308(ra) # 8000282a <devintr>
    80002966:	892a                	mv	s2,a0
    80002968:	c501                	beqz	a0,80002970 <usertrap+0xa4>
  if(p->killed)
    8000296a:	589c                	lw	a5,48(s1)
    8000296c:	c3a1                	beqz	a5,800029ac <usertrap+0xe0>
    8000296e:	a815                	j	800029a2 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002970:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002974:	5c90                	lw	a2,56(s1)
    80002976:	00006517          	auipc	a0,0x6
    8000297a:	9fa50513          	addi	a0,a0,-1542 # 80008370 <states.1712+0x70>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	c14080e7          	jalr	-1004(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002986:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000298a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000298e:	00006517          	auipc	a0,0x6
    80002992:	a1250513          	addi	a0,a0,-1518 # 800083a0 <states.1712+0xa0>
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	bfc080e7          	jalr	-1028(ra) # 80000592 <printf>
    p->killed = 1;
    8000299e:	4785                	li	a5,1
    800029a0:	d89c                	sw	a5,48(s1)
    exit(-1);
    800029a2:	557d                	li	a0,-1
    800029a4:	fffff097          	auipc	ra,0xfffff
    800029a8:	7f6080e7          	jalr	2038(ra) # 8000219a <exit>
  if(which_dev == 2)
    800029ac:	4789                	li	a5,2
    800029ae:	f8f910e3          	bne	s2,a5,8000292e <usertrap+0x62>
    yield();
    800029b2:	00000097          	auipc	ra,0x0
    800029b6:	8f2080e7          	jalr	-1806(ra) # 800022a4 <yield>
    800029ba:	bf95                	j	8000292e <usertrap+0x62>
  int which_dev = 0;
    800029bc:	4901                	li	s2,0
    800029be:	b7d5                	j	800029a2 <usertrap+0xd6>

00000000800029c0 <kerneltrap>:
{
    800029c0:	7179                	addi	sp,sp,-48
    800029c2:	f406                	sd	ra,40(sp)
    800029c4:	f022                	sd	s0,32(sp)
    800029c6:	ec26                	sd	s1,24(sp)
    800029c8:	e84a                	sd	s2,16(sp)
    800029ca:	e44e                	sd	s3,8(sp)
    800029cc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ce:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029d6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029da:	1004f793          	andi	a5,s1,256
    800029de:	cb85                	beqz	a5,80002a0e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029e4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029e6:	ef85                	bnez	a5,80002a1e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029e8:	00000097          	auipc	ra,0x0
    800029ec:	e42080e7          	jalr	-446(ra) # 8000282a <devintr>
    800029f0:	cd1d                	beqz	a0,80002a2e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029f2:	4789                	li	a5,2
    800029f4:	06f50a63          	beq	a0,a5,80002a68 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029f8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029fc:	10049073          	csrw	sstatus,s1
}
    80002a00:	70a2                	ld	ra,40(sp)
    80002a02:	7402                	ld	s0,32(sp)
    80002a04:	64e2                	ld	s1,24(sp)
    80002a06:	6942                	ld	s2,16(sp)
    80002a08:	69a2                	ld	s3,8(sp)
    80002a0a:	6145                	addi	sp,sp,48
    80002a0c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	9b250513          	addi	a0,a0,-1614 # 800083c0 <states.1712+0xc0>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b32080e7          	jalr	-1230(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a1e:	00006517          	auipc	a0,0x6
    80002a22:	9ca50513          	addi	a0,a0,-1590 # 800083e8 <states.1712+0xe8>
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	b22080e7          	jalr	-1246(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a2e:	85ce                	mv	a1,s3
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	9d850513          	addi	a0,a0,-1576 # 80008408 <states.1712+0x108>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b5a080e7          	jalr	-1190(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a40:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a44:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	9d050513          	addi	a0,a0,-1584 # 80008418 <states.1712+0x118>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	b42080e7          	jalr	-1214(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	9d850513          	addi	a0,a0,-1576 # 80008430 <states.1712+0x130>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	ae8080e7          	jalr	-1304(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	06c080e7          	jalr	108(ra) # 80001ad4 <myproc>
    80002a70:	d541                	beqz	a0,800029f8 <kerneltrap+0x38>
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	062080e7          	jalr	98(ra) # 80001ad4 <myproc>
    80002a7a:	4d18                	lw	a4,24(a0)
    80002a7c:	478d                	li	a5,3
    80002a7e:	f6f71de3          	bne	a4,a5,800029f8 <kerneltrap+0x38>
    yield();
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	822080e7          	jalr	-2014(ra) # 800022a4 <yield>
    80002a8a:	b7bd                	j	800029f8 <kerneltrap+0x38>

0000000080002a8c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a8c:	1101                	addi	sp,sp,-32
    80002a8e:	ec06                	sd	ra,24(sp)
    80002a90:	e822                	sd	s0,16(sp)
    80002a92:	e426                	sd	s1,8(sp)
    80002a94:	1000                	addi	s0,sp,32
    80002a96:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	03c080e7          	jalr	60(ra) # 80001ad4 <myproc>
  switch (n) {
    80002aa0:	4795                	li	a5,5
    80002aa2:	0497e163          	bltu	a5,s1,80002ae4 <argraw+0x58>
    80002aa6:	048a                	slli	s1,s1,0x2
    80002aa8:	00006717          	auipc	a4,0x6
    80002aac:	9c070713          	addi	a4,a4,-1600 # 80008468 <states.1712+0x168>
    80002ab0:	94ba                	add	s1,s1,a4
    80002ab2:	409c                	lw	a5,0(s1)
    80002ab4:	97ba                	add	a5,a5,a4
    80002ab6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ab8:	6d3c                	ld	a5,88(a0)
    80002aba:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002abc:	60e2                	ld	ra,24(sp)
    80002abe:	6442                	ld	s0,16(sp)
    80002ac0:	64a2                	ld	s1,8(sp)
    80002ac2:	6105                	addi	sp,sp,32
    80002ac4:	8082                	ret
    return p->trapframe->a1;
    80002ac6:	6d3c                	ld	a5,88(a0)
    80002ac8:	7fa8                	ld	a0,120(a5)
    80002aca:	bfcd                	j	80002abc <argraw+0x30>
    return p->trapframe->a2;
    80002acc:	6d3c                	ld	a5,88(a0)
    80002ace:	63c8                	ld	a0,128(a5)
    80002ad0:	b7f5                	j	80002abc <argraw+0x30>
    return p->trapframe->a3;
    80002ad2:	6d3c                	ld	a5,88(a0)
    80002ad4:	67c8                	ld	a0,136(a5)
    80002ad6:	b7dd                	j	80002abc <argraw+0x30>
    return p->trapframe->a4;
    80002ad8:	6d3c                	ld	a5,88(a0)
    80002ada:	6bc8                	ld	a0,144(a5)
    80002adc:	b7c5                	j	80002abc <argraw+0x30>
    return p->trapframe->a5;
    80002ade:	6d3c                	ld	a5,88(a0)
    80002ae0:	6fc8                	ld	a0,152(a5)
    80002ae2:	bfe9                	j	80002abc <argraw+0x30>
  panic("argraw");
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	95c50513          	addi	a0,a0,-1700 # 80008440 <states.1712+0x140>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	a5c080e7          	jalr	-1444(ra) # 80000548 <panic>

0000000080002af4 <fetchaddr>:
{
    80002af4:	1101                	addi	sp,sp,-32
    80002af6:	ec06                	sd	ra,24(sp)
    80002af8:	e822                	sd	s0,16(sp)
    80002afa:	e426                	sd	s1,8(sp)
    80002afc:	e04a                	sd	s2,0(sp)
    80002afe:	1000                	addi	s0,sp,32
    80002b00:	84aa                	mv	s1,a0
    80002b02:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	fd0080e7          	jalr	-48(ra) # 80001ad4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b0c:	653c                	ld	a5,72(a0)
    80002b0e:	02f4f863          	bgeu	s1,a5,80002b3e <fetchaddr+0x4a>
    80002b12:	00848713          	addi	a4,s1,8
    80002b16:	02e7e663          	bltu	a5,a4,80002b42 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b1a:	46a1                	li	a3,8
    80002b1c:	8626                	mv	a2,s1
    80002b1e:	85ca                	mv	a1,s2
    80002b20:	6928                	ld	a0,80(a0)
    80002b22:	fffff097          	auipc	ra,0xfffff
    80002b26:	c44080e7          	jalr	-956(ra) # 80001766 <copyin>
    80002b2a:	00a03533          	snez	a0,a0
    80002b2e:	40a00533          	neg	a0,a0
}
    80002b32:	60e2                	ld	ra,24(sp)
    80002b34:	6442                	ld	s0,16(sp)
    80002b36:	64a2                	ld	s1,8(sp)
    80002b38:	6902                	ld	s2,0(sp)
    80002b3a:	6105                	addi	sp,sp,32
    80002b3c:	8082                	ret
    return -1;
    80002b3e:	557d                	li	a0,-1
    80002b40:	bfcd                	j	80002b32 <fetchaddr+0x3e>
    80002b42:	557d                	li	a0,-1
    80002b44:	b7fd                	j	80002b32 <fetchaddr+0x3e>

0000000080002b46 <fetchstr>:
{
    80002b46:	7179                	addi	sp,sp,-48
    80002b48:	f406                	sd	ra,40(sp)
    80002b4a:	f022                	sd	s0,32(sp)
    80002b4c:	ec26                	sd	s1,24(sp)
    80002b4e:	e84a                	sd	s2,16(sp)
    80002b50:	e44e                	sd	s3,8(sp)
    80002b52:	1800                	addi	s0,sp,48
    80002b54:	892a                	mv	s2,a0
    80002b56:	84ae                	mv	s1,a1
    80002b58:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	f7a080e7          	jalr	-134(ra) # 80001ad4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b62:	86ce                	mv	a3,s3
    80002b64:	864a                	mv	a2,s2
    80002b66:	85a6                	mv	a1,s1
    80002b68:	6928                	ld	a0,80(a0)
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	c88080e7          	jalr	-888(ra) # 800017f2 <copyinstr>
  if(err < 0)
    80002b72:	00054763          	bltz	a0,80002b80 <fetchstr+0x3a>
  return strlen(buf);
    80002b76:	8526                	mv	a0,s1
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	31c080e7          	jalr	796(ra) # 80000e94 <strlen>
}
    80002b80:	70a2                	ld	ra,40(sp)
    80002b82:	7402                	ld	s0,32(sp)
    80002b84:	64e2                	ld	s1,24(sp)
    80002b86:	6942                	ld	s2,16(sp)
    80002b88:	69a2                	ld	s3,8(sp)
    80002b8a:	6145                	addi	sp,sp,48
    80002b8c:	8082                	ret

0000000080002b8e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b8e:	1101                	addi	sp,sp,-32
    80002b90:	ec06                	sd	ra,24(sp)
    80002b92:	e822                	sd	s0,16(sp)
    80002b94:	e426                	sd	s1,8(sp)
    80002b96:	1000                	addi	s0,sp,32
    80002b98:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b9a:	00000097          	auipc	ra,0x0
    80002b9e:	ef2080e7          	jalr	-270(ra) # 80002a8c <argraw>
    80002ba2:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ba4:	4501                	li	a0,0
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret

0000000080002bb0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
    80002bba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	ed0080e7          	jalr	-304(ra) # 80002a8c <argraw>
    80002bc4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bc6:	4501                	li	a0,0
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	64a2                	ld	s1,8(sp)
    80002bce:	6105                	addi	sp,sp,32
    80002bd0:	8082                	ret

0000000080002bd2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bd2:	1101                	addi	sp,sp,-32
    80002bd4:	ec06                	sd	ra,24(sp)
    80002bd6:	e822                	sd	s0,16(sp)
    80002bd8:	e426                	sd	s1,8(sp)
    80002bda:	e04a                	sd	s2,0(sp)
    80002bdc:	1000                	addi	s0,sp,32
    80002bde:	84ae                	mv	s1,a1
    80002be0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	eaa080e7          	jalr	-342(ra) # 80002a8c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bea:	864a                	mv	a2,s2
    80002bec:	85a6                	mv	a1,s1
    80002bee:	00000097          	auipc	ra,0x0
    80002bf2:	f58080e7          	jalr	-168(ra) # 80002b46 <fetchstr>
}
    80002bf6:	60e2                	ld	ra,24(sp)
    80002bf8:	6442                	ld	s0,16(sp)
    80002bfa:	64a2                	ld	s1,8(sp)
    80002bfc:	6902                	ld	s2,0(sp)
    80002bfe:	6105                	addi	sp,sp,32
    80002c00:	8082                	ret

0000000080002c02 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c02:	1101                	addi	sp,sp,-32
    80002c04:	ec06                	sd	ra,24(sp)
    80002c06:	e822                	sd	s0,16(sp)
    80002c08:	e426                	sd	s1,8(sp)
    80002c0a:	e04a                	sd	s2,0(sp)
    80002c0c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	ec6080e7          	jalr	-314(ra) # 80001ad4 <myproc>
    80002c16:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c18:	05853903          	ld	s2,88(a0)
    80002c1c:	0a893783          	ld	a5,168(s2)
    80002c20:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c24:	37fd                	addiw	a5,a5,-1
    80002c26:	4751                	li	a4,20
    80002c28:	00f76f63          	bltu	a4,a5,80002c46 <syscall+0x44>
    80002c2c:	00369713          	slli	a4,a3,0x3
    80002c30:	00006797          	auipc	a5,0x6
    80002c34:	85078793          	addi	a5,a5,-1968 # 80008480 <syscalls>
    80002c38:	97ba                	add	a5,a5,a4
    80002c3a:	639c                	ld	a5,0(a5)
    80002c3c:	c789                	beqz	a5,80002c46 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c3e:	9782                	jalr	a5
    80002c40:	06a93823          	sd	a0,112(s2)
    80002c44:	a839                	j	80002c62 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c46:	15848613          	addi	a2,s1,344
    80002c4a:	5c8c                	lw	a1,56(s1)
    80002c4c:	00005517          	auipc	a0,0x5
    80002c50:	7fc50513          	addi	a0,a0,2044 # 80008448 <states.1712+0x148>
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	93e080e7          	jalr	-1730(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c5c:	6cbc                	ld	a5,88(s1)
    80002c5e:	577d                	li	a4,-1
    80002c60:	fbb8                	sd	a4,112(a5)
  }
}
    80002c62:	60e2                	ld	ra,24(sp)
    80002c64:	6442                	ld	s0,16(sp)
    80002c66:	64a2                	ld	s1,8(sp)
    80002c68:	6902                	ld	s2,0(sp)
    80002c6a:	6105                	addi	sp,sp,32
    80002c6c:	8082                	ret

0000000080002c6e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c6e:	1101                	addi	sp,sp,-32
    80002c70:	ec06                	sd	ra,24(sp)
    80002c72:	e822                	sd	s0,16(sp)
    80002c74:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c76:	fec40593          	addi	a1,s0,-20
    80002c7a:	4501                	li	a0,0
    80002c7c:	00000097          	auipc	ra,0x0
    80002c80:	f12080e7          	jalr	-238(ra) # 80002b8e <argint>
    return -1;
    80002c84:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c86:	00054963          	bltz	a0,80002c98 <sys_exit+0x2a>
  exit(n);
    80002c8a:	fec42503          	lw	a0,-20(s0)
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	50c080e7          	jalr	1292(ra) # 8000219a <exit>
  return 0;  // not reached
    80002c96:	4781                	li	a5,0
}
    80002c98:	853e                	mv	a0,a5
    80002c9a:	60e2                	ld	ra,24(sp)
    80002c9c:	6442                	ld	s0,16(sp)
    80002c9e:	6105                	addi	sp,sp,32
    80002ca0:	8082                	ret

0000000080002ca2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ca2:	1141                	addi	sp,sp,-16
    80002ca4:	e406                	sd	ra,8(sp)
    80002ca6:	e022                	sd	s0,0(sp)
    80002ca8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	e2a080e7          	jalr	-470(ra) # 80001ad4 <myproc>
}
    80002cb2:	5d08                	lw	a0,56(a0)
    80002cb4:	60a2                	ld	ra,8(sp)
    80002cb6:	6402                	ld	s0,0(sp)
    80002cb8:	0141                	addi	sp,sp,16
    80002cba:	8082                	ret

0000000080002cbc <sys_fork>:

uint64
sys_fork(void)
{
    80002cbc:	1141                	addi	sp,sp,-16
    80002cbe:	e406                	sd	ra,8(sp)
    80002cc0:	e022                	sd	s0,0(sp)
    80002cc2:	0800                	addi	s0,sp,16
  return fork();
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	1d0080e7          	jalr	464(ra) # 80001e94 <fork>
}
    80002ccc:	60a2                	ld	ra,8(sp)
    80002cce:	6402                	ld	s0,0(sp)
    80002cd0:	0141                	addi	sp,sp,16
    80002cd2:	8082                	ret

0000000080002cd4 <sys_wait>:

uint64
sys_wait(void)
{
    80002cd4:	1101                	addi	sp,sp,-32
    80002cd6:	ec06                	sd	ra,24(sp)
    80002cd8:	e822                	sd	s0,16(sp)
    80002cda:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cdc:	fe840593          	addi	a1,s0,-24
    80002ce0:	4501                	li	a0,0
    80002ce2:	00000097          	auipc	ra,0x0
    80002ce6:	ece080e7          	jalr	-306(ra) # 80002bb0 <argaddr>
    80002cea:	87aa                	mv	a5,a0
    return -1;
    80002cec:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cee:	0007c863          	bltz	a5,80002cfe <sys_wait+0x2a>
  return wait(p);
    80002cf2:	fe843503          	ld	a0,-24(s0)
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	668080e7          	jalr	1640(ra) # 8000235e <wait>
}
    80002cfe:	60e2                	ld	ra,24(sp)
    80002d00:	6442                	ld	s0,16(sp)
    80002d02:	6105                	addi	sp,sp,32
    80002d04:	8082                	ret

0000000080002d06 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d06:	7179                	addi	sp,sp,-48
    80002d08:	f406                	sd	ra,40(sp)
    80002d0a:	f022                	sd	s0,32(sp)
    80002d0c:	ec26                	sd	s1,24(sp)
    80002d0e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d10:	fdc40593          	addi	a1,s0,-36
    80002d14:	4501                	li	a0,0
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	e78080e7          	jalr	-392(ra) # 80002b8e <argint>
    80002d1e:	87aa                	mv	a5,a0
    return -1;
    80002d20:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d22:	0207c063          	bltz	a5,80002d42 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d26:	fffff097          	auipc	ra,0xfffff
    80002d2a:	dae080e7          	jalr	-594(ra) # 80001ad4 <myproc>
    80002d2e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d30:	fdc42503          	lw	a0,-36(s0)
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	0ec080e7          	jalr	236(ra) # 80001e20 <growproc>
    80002d3c:	00054863          	bltz	a0,80002d4c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d40:	8526                	mv	a0,s1
}
    80002d42:	70a2                	ld	ra,40(sp)
    80002d44:	7402                	ld	s0,32(sp)
    80002d46:	64e2                	ld	s1,24(sp)
    80002d48:	6145                	addi	sp,sp,48
    80002d4a:	8082                	ret
    return -1;
    80002d4c:	557d                	li	a0,-1
    80002d4e:	bfd5                	j	80002d42 <sys_sbrk+0x3c>

0000000080002d50 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d50:	7139                	addi	sp,sp,-64
    80002d52:	fc06                	sd	ra,56(sp)
    80002d54:	f822                	sd	s0,48(sp)
    80002d56:	f426                	sd	s1,40(sp)
    80002d58:	f04a                	sd	s2,32(sp)
    80002d5a:	ec4e                	sd	s3,24(sp)
    80002d5c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d5e:	fcc40593          	addi	a1,s0,-52
    80002d62:	4501                	li	a0,0
    80002d64:	00000097          	auipc	ra,0x0
    80002d68:	e2a080e7          	jalr	-470(ra) # 80002b8e <argint>
    return -1;
    80002d6c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d6e:	06054563          	bltz	a0,80002dd8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d72:	00015517          	auipc	a0,0x15
    80002d76:	9f650513          	addi	a0,a0,-1546 # 80017768 <tickslock>
    80002d7a:	ffffe097          	auipc	ra,0xffffe
    80002d7e:	e96080e7          	jalr	-362(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002d82:	00006917          	auipc	s2,0x6
    80002d86:	29e92903          	lw	s2,670(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d8a:	fcc42783          	lw	a5,-52(s0)
    80002d8e:	cf85                	beqz	a5,80002dc6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d90:	00015997          	auipc	s3,0x15
    80002d94:	9d898993          	addi	s3,s3,-1576 # 80017768 <tickslock>
    80002d98:	00006497          	auipc	s1,0x6
    80002d9c:	28848493          	addi	s1,s1,648 # 80009020 <ticks>
    if(myproc()->killed){
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	d34080e7          	jalr	-716(ra) # 80001ad4 <myproc>
    80002da8:	591c                	lw	a5,48(a0)
    80002daa:	ef9d                	bnez	a5,80002de8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dac:	85ce                	mv	a1,s3
    80002dae:	8526                	mv	a0,s1
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	530080e7          	jalr	1328(ra) # 800022e0 <sleep>
  while(ticks - ticks0 < n){
    80002db8:	409c                	lw	a5,0(s1)
    80002dba:	412787bb          	subw	a5,a5,s2
    80002dbe:	fcc42703          	lw	a4,-52(s0)
    80002dc2:	fce7efe3          	bltu	a5,a4,80002da0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dc6:	00015517          	auipc	a0,0x15
    80002dca:	9a250513          	addi	a0,a0,-1630 # 80017768 <tickslock>
    80002dce:	ffffe097          	auipc	ra,0xffffe
    80002dd2:	ef6080e7          	jalr	-266(ra) # 80000cc4 <release>
  return 0;
    80002dd6:	4781                	li	a5,0
}
    80002dd8:	853e                	mv	a0,a5
    80002dda:	70e2                	ld	ra,56(sp)
    80002ddc:	7442                	ld	s0,48(sp)
    80002dde:	74a2                	ld	s1,40(sp)
    80002de0:	7902                	ld	s2,32(sp)
    80002de2:	69e2                	ld	s3,24(sp)
    80002de4:	6121                	addi	sp,sp,64
    80002de6:	8082                	ret
      release(&tickslock);
    80002de8:	00015517          	auipc	a0,0x15
    80002dec:	98050513          	addi	a0,a0,-1664 # 80017768 <tickslock>
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	ed4080e7          	jalr	-300(ra) # 80000cc4 <release>
      return -1;
    80002df8:	57fd                	li	a5,-1
    80002dfa:	bff9                	j	80002dd8 <sys_sleep+0x88>

0000000080002dfc <sys_kill>:

uint64
sys_kill(void)
{
    80002dfc:	1101                	addi	sp,sp,-32
    80002dfe:	ec06                	sd	ra,24(sp)
    80002e00:	e822                	sd	s0,16(sp)
    80002e02:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e04:	fec40593          	addi	a1,s0,-20
    80002e08:	4501                	li	a0,0
    80002e0a:	00000097          	auipc	ra,0x0
    80002e0e:	d84080e7          	jalr	-636(ra) # 80002b8e <argint>
    80002e12:	87aa                	mv	a5,a0
    return -1;
    80002e14:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e16:	0007c863          	bltz	a5,80002e26 <sys_kill+0x2a>
  return kill(pid);
    80002e1a:	fec42503          	lw	a0,-20(s0)
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	6b2080e7          	jalr	1714(ra) # 800024d0 <kill>
}
    80002e26:	60e2                	ld	ra,24(sp)
    80002e28:	6442                	ld	s0,16(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret

0000000080002e2e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e2e:	1101                	addi	sp,sp,-32
    80002e30:	ec06                	sd	ra,24(sp)
    80002e32:	e822                	sd	s0,16(sp)
    80002e34:	e426                	sd	s1,8(sp)
    80002e36:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e38:	00015517          	auipc	a0,0x15
    80002e3c:	93050513          	addi	a0,a0,-1744 # 80017768 <tickslock>
    80002e40:	ffffe097          	auipc	ra,0xffffe
    80002e44:	dd0080e7          	jalr	-560(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002e48:	00006497          	auipc	s1,0x6
    80002e4c:	1d84a483          	lw	s1,472(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e50:	00015517          	auipc	a0,0x15
    80002e54:	91850513          	addi	a0,a0,-1768 # 80017768 <tickslock>
    80002e58:	ffffe097          	auipc	ra,0xffffe
    80002e5c:	e6c080e7          	jalr	-404(ra) # 80000cc4 <release>
  return xticks;
}
    80002e60:	02049513          	slli	a0,s1,0x20
    80002e64:	9101                	srli	a0,a0,0x20
    80002e66:	60e2                	ld	ra,24(sp)
    80002e68:	6442                	ld	s0,16(sp)
    80002e6a:	64a2                	ld	s1,8(sp)
    80002e6c:	6105                	addi	sp,sp,32
    80002e6e:	8082                	ret

0000000080002e70 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e70:	7179                	addi	sp,sp,-48
    80002e72:	f406                	sd	ra,40(sp)
    80002e74:	f022                	sd	s0,32(sp)
    80002e76:	ec26                	sd	s1,24(sp)
    80002e78:	e84a                	sd	s2,16(sp)
    80002e7a:	e44e                	sd	s3,8(sp)
    80002e7c:	e052                	sd	s4,0(sp)
    80002e7e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e80:	00005597          	auipc	a1,0x5
    80002e84:	6b058593          	addi	a1,a1,1712 # 80008530 <syscalls+0xb0>
    80002e88:	00015517          	auipc	a0,0x15
    80002e8c:	8f850513          	addi	a0,a0,-1800 # 80017780 <bcache>
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	cf0080e7          	jalr	-784(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e98:	0001d797          	auipc	a5,0x1d
    80002e9c:	8e878793          	addi	a5,a5,-1816 # 8001f780 <bcache+0x8000>
    80002ea0:	0001d717          	auipc	a4,0x1d
    80002ea4:	b4870713          	addi	a4,a4,-1208 # 8001f9e8 <bcache+0x8268>
    80002ea8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002eac:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eb0:	00015497          	auipc	s1,0x15
    80002eb4:	8e848493          	addi	s1,s1,-1816 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002eb8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eba:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ebc:	00005a17          	auipc	s4,0x5
    80002ec0:	67ca0a13          	addi	s4,s4,1660 # 80008538 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002ec4:	2b893783          	ld	a5,696(s2)
    80002ec8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eca:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ece:	85d2                	mv	a1,s4
    80002ed0:	01048513          	addi	a0,s1,16
    80002ed4:	00001097          	auipc	ra,0x1
    80002ed8:	4ac080e7          	jalr	1196(ra) # 80004380 <initsleeplock>
    bcache.head.next->prev = b;
    80002edc:	2b893783          	ld	a5,696(s2)
    80002ee0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ee2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ee6:	45848493          	addi	s1,s1,1112
    80002eea:	fd349de3          	bne	s1,s3,80002ec4 <binit+0x54>
  }
}
    80002eee:	70a2                	ld	ra,40(sp)
    80002ef0:	7402                	ld	s0,32(sp)
    80002ef2:	64e2                	ld	s1,24(sp)
    80002ef4:	6942                	ld	s2,16(sp)
    80002ef6:	69a2                	ld	s3,8(sp)
    80002ef8:	6a02                	ld	s4,0(sp)
    80002efa:	6145                	addi	sp,sp,48
    80002efc:	8082                	ret

0000000080002efe <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002efe:	7179                	addi	sp,sp,-48
    80002f00:	f406                	sd	ra,40(sp)
    80002f02:	f022                	sd	s0,32(sp)
    80002f04:	ec26                	sd	s1,24(sp)
    80002f06:	e84a                	sd	s2,16(sp)
    80002f08:	e44e                	sd	s3,8(sp)
    80002f0a:	1800                	addi	s0,sp,48
    80002f0c:	89aa                	mv	s3,a0
    80002f0e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f10:	00015517          	auipc	a0,0x15
    80002f14:	87050513          	addi	a0,a0,-1936 # 80017780 <bcache>
    80002f18:	ffffe097          	auipc	ra,0xffffe
    80002f1c:	cf8080e7          	jalr	-776(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f20:	0001d497          	auipc	s1,0x1d
    80002f24:	b184b483          	ld	s1,-1256(s1) # 8001fa38 <bcache+0x82b8>
    80002f28:	0001d797          	auipc	a5,0x1d
    80002f2c:	ac078793          	addi	a5,a5,-1344 # 8001f9e8 <bcache+0x8268>
    80002f30:	02f48f63          	beq	s1,a5,80002f6e <bread+0x70>
    80002f34:	873e                	mv	a4,a5
    80002f36:	a021                	j	80002f3e <bread+0x40>
    80002f38:	68a4                	ld	s1,80(s1)
    80002f3a:	02e48a63          	beq	s1,a4,80002f6e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f3e:	449c                	lw	a5,8(s1)
    80002f40:	ff379ce3          	bne	a5,s3,80002f38 <bread+0x3a>
    80002f44:	44dc                	lw	a5,12(s1)
    80002f46:	ff2799e3          	bne	a5,s2,80002f38 <bread+0x3a>
      b->refcnt++;
    80002f4a:	40bc                	lw	a5,64(s1)
    80002f4c:	2785                	addiw	a5,a5,1
    80002f4e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f50:	00015517          	auipc	a0,0x15
    80002f54:	83050513          	addi	a0,a0,-2000 # 80017780 <bcache>
    80002f58:	ffffe097          	auipc	ra,0xffffe
    80002f5c:	d6c080e7          	jalr	-660(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002f60:	01048513          	addi	a0,s1,16
    80002f64:	00001097          	auipc	ra,0x1
    80002f68:	456080e7          	jalr	1110(ra) # 800043ba <acquiresleep>
      return b;
    80002f6c:	a8b9                	j	80002fca <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f6e:	0001d497          	auipc	s1,0x1d
    80002f72:	ac24b483          	ld	s1,-1342(s1) # 8001fa30 <bcache+0x82b0>
    80002f76:	0001d797          	auipc	a5,0x1d
    80002f7a:	a7278793          	addi	a5,a5,-1422 # 8001f9e8 <bcache+0x8268>
    80002f7e:	00f48863          	beq	s1,a5,80002f8e <bread+0x90>
    80002f82:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f84:	40bc                	lw	a5,64(s1)
    80002f86:	cf81                	beqz	a5,80002f9e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f88:	64a4                	ld	s1,72(s1)
    80002f8a:	fee49de3          	bne	s1,a4,80002f84 <bread+0x86>
  panic("bget: no buffers");
    80002f8e:	00005517          	auipc	a0,0x5
    80002f92:	5b250513          	addi	a0,a0,1458 # 80008540 <syscalls+0xc0>
    80002f96:	ffffd097          	auipc	ra,0xffffd
    80002f9a:	5b2080e7          	jalr	1458(ra) # 80000548 <panic>
      b->dev = dev;
    80002f9e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fa2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fa6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002faa:	4785                	li	a5,1
    80002fac:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fae:	00014517          	auipc	a0,0x14
    80002fb2:	7d250513          	addi	a0,a0,2002 # 80017780 <bcache>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	d0e080e7          	jalr	-754(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002fbe:	01048513          	addi	a0,s1,16
    80002fc2:	00001097          	auipc	ra,0x1
    80002fc6:	3f8080e7          	jalr	1016(ra) # 800043ba <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fca:	409c                	lw	a5,0(s1)
    80002fcc:	cb89                	beqz	a5,80002fde <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fce:	8526                	mv	a0,s1
    80002fd0:	70a2                	ld	ra,40(sp)
    80002fd2:	7402                	ld	s0,32(sp)
    80002fd4:	64e2                	ld	s1,24(sp)
    80002fd6:	6942                	ld	s2,16(sp)
    80002fd8:	69a2                	ld	s3,8(sp)
    80002fda:	6145                	addi	sp,sp,48
    80002fdc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fde:	4581                	li	a1,0
    80002fe0:	8526                	mv	a0,s1
    80002fe2:	00003097          	auipc	ra,0x3
    80002fe6:	f4a080e7          	jalr	-182(ra) # 80005f2c <virtio_disk_rw>
    b->valid = 1;
    80002fea:	4785                	li	a5,1
    80002fec:	c09c                	sw	a5,0(s1)
  return b;
    80002fee:	b7c5                	j	80002fce <bread+0xd0>

0000000080002ff0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ff0:	1101                	addi	sp,sp,-32
    80002ff2:	ec06                	sd	ra,24(sp)
    80002ff4:	e822                	sd	s0,16(sp)
    80002ff6:	e426                	sd	s1,8(sp)
    80002ff8:	1000                	addi	s0,sp,32
    80002ffa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ffc:	0541                	addi	a0,a0,16
    80002ffe:	00001097          	auipc	ra,0x1
    80003002:	456080e7          	jalr	1110(ra) # 80004454 <holdingsleep>
    80003006:	cd01                	beqz	a0,8000301e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003008:	4585                	li	a1,1
    8000300a:	8526                	mv	a0,s1
    8000300c:	00003097          	auipc	ra,0x3
    80003010:	f20080e7          	jalr	-224(ra) # 80005f2c <virtio_disk_rw>
}
    80003014:	60e2                	ld	ra,24(sp)
    80003016:	6442                	ld	s0,16(sp)
    80003018:	64a2                	ld	s1,8(sp)
    8000301a:	6105                	addi	sp,sp,32
    8000301c:	8082                	ret
    panic("bwrite");
    8000301e:	00005517          	auipc	a0,0x5
    80003022:	53a50513          	addi	a0,a0,1338 # 80008558 <syscalls+0xd8>
    80003026:	ffffd097          	auipc	ra,0xffffd
    8000302a:	522080e7          	jalr	1314(ra) # 80000548 <panic>

000000008000302e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000302e:	1101                	addi	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	e426                	sd	s1,8(sp)
    80003036:	e04a                	sd	s2,0(sp)
    80003038:	1000                	addi	s0,sp,32
    8000303a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000303c:	01050913          	addi	s2,a0,16
    80003040:	854a                	mv	a0,s2
    80003042:	00001097          	auipc	ra,0x1
    80003046:	412080e7          	jalr	1042(ra) # 80004454 <holdingsleep>
    8000304a:	c92d                	beqz	a0,800030bc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000304c:	854a                	mv	a0,s2
    8000304e:	00001097          	auipc	ra,0x1
    80003052:	3c2080e7          	jalr	962(ra) # 80004410 <releasesleep>

  acquire(&bcache.lock);
    80003056:	00014517          	auipc	a0,0x14
    8000305a:	72a50513          	addi	a0,a0,1834 # 80017780 <bcache>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	bb2080e7          	jalr	-1102(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003066:	40bc                	lw	a5,64(s1)
    80003068:	37fd                	addiw	a5,a5,-1
    8000306a:	0007871b          	sext.w	a4,a5
    8000306e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003070:	eb05                	bnez	a4,800030a0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003072:	68bc                	ld	a5,80(s1)
    80003074:	64b8                	ld	a4,72(s1)
    80003076:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003078:	64bc                	ld	a5,72(s1)
    8000307a:	68b8                	ld	a4,80(s1)
    8000307c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000307e:	0001c797          	auipc	a5,0x1c
    80003082:	70278793          	addi	a5,a5,1794 # 8001f780 <bcache+0x8000>
    80003086:	2b87b703          	ld	a4,696(a5)
    8000308a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000308c:	0001d717          	auipc	a4,0x1d
    80003090:	95c70713          	addi	a4,a4,-1700 # 8001f9e8 <bcache+0x8268>
    80003094:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003096:	2b87b703          	ld	a4,696(a5)
    8000309a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000309c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030a0:	00014517          	auipc	a0,0x14
    800030a4:	6e050513          	addi	a0,a0,1760 # 80017780 <bcache>
    800030a8:	ffffe097          	auipc	ra,0xffffe
    800030ac:	c1c080e7          	jalr	-996(ra) # 80000cc4 <release>
}
    800030b0:	60e2                	ld	ra,24(sp)
    800030b2:	6442                	ld	s0,16(sp)
    800030b4:	64a2                	ld	s1,8(sp)
    800030b6:	6902                	ld	s2,0(sp)
    800030b8:	6105                	addi	sp,sp,32
    800030ba:	8082                	ret
    panic("brelse");
    800030bc:	00005517          	auipc	a0,0x5
    800030c0:	4a450513          	addi	a0,a0,1188 # 80008560 <syscalls+0xe0>
    800030c4:	ffffd097          	auipc	ra,0xffffd
    800030c8:	484080e7          	jalr	1156(ra) # 80000548 <panic>

00000000800030cc <bpin>:

void
bpin(struct buf *b) {
    800030cc:	1101                	addi	sp,sp,-32
    800030ce:	ec06                	sd	ra,24(sp)
    800030d0:	e822                	sd	s0,16(sp)
    800030d2:	e426                	sd	s1,8(sp)
    800030d4:	1000                	addi	s0,sp,32
    800030d6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030d8:	00014517          	auipc	a0,0x14
    800030dc:	6a850513          	addi	a0,a0,1704 # 80017780 <bcache>
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	b30080e7          	jalr	-1232(ra) # 80000c10 <acquire>
  b->refcnt++;
    800030e8:	40bc                	lw	a5,64(s1)
    800030ea:	2785                	addiw	a5,a5,1
    800030ec:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	69250513          	addi	a0,a0,1682 # 80017780 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	bce080e7          	jalr	-1074(ra) # 80000cc4 <release>
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6105                	addi	sp,sp,32
    80003106:	8082                	ret

0000000080003108 <bunpin>:

void
bunpin(struct buf *b) {
    80003108:	1101                	addi	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	e426                	sd	s1,8(sp)
    80003110:	1000                	addi	s0,sp,32
    80003112:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003114:	00014517          	auipc	a0,0x14
    80003118:	66c50513          	addi	a0,a0,1644 # 80017780 <bcache>
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	af4080e7          	jalr	-1292(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003124:	40bc                	lw	a5,64(s1)
    80003126:	37fd                	addiw	a5,a5,-1
    80003128:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000312a:	00014517          	auipc	a0,0x14
    8000312e:	65650513          	addi	a0,a0,1622 # 80017780 <bcache>
    80003132:	ffffe097          	auipc	ra,0xffffe
    80003136:	b92080e7          	jalr	-1134(ra) # 80000cc4 <release>
}
    8000313a:	60e2                	ld	ra,24(sp)
    8000313c:	6442                	ld	s0,16(sp)
    8000313e:	64a2                	ld	s1,8(sp)
    80003140:	6105                	addi	sp,sp,32
    80003142:	8082                	ret

0000000080003144 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003144:	1101                	addi	sp,sp,-32
    80003146:	ec06                	sd	ra,24(sp)
    80003148:	e822                	sd	s0,16(sp)
    8000314a:	e426                	sd	s1,8(sp)
    8000314c:	e04a                	sd	s2,0(sp)
    8000314e:	1000                	addi	s0,sp,32
    80003150:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003152:	00d5d59b          	srliw	a1,a1,0xd
    80003156:	0001d797          	auipc	a5,0x1d
    8000315a:	d067a783          	lw	a5,-762(a5) # 8001fe5c <sb+0x1c>
    8000315e:	9dbd                	addw	a1,a1,a5
    80003160:	00000097          	auipc	ra,0x0
    80003164:	d9e080e7          	jalr	-610(ra) # 80002efe <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003168:	0074f713          	andi	a4,s1,7
    8000316c:	4785                	li	a5,1
    8000316e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003172:	14ce                	slli	s1,s1,0x33
    80003174:	90d9                	srli	s1,s1,0x36
    80003176:	00950733          	add	a4,a0,s1
    8000317a:	05874703          	lbu	a4,88(a4)
    8000317e:	00e7f6b3          	and	a3,a5,a4
    80003182:	c69d                	beqz	a3,800031b0 <bfree+0x6c>
    80003184:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003186:	94aa                	add	s1,s1,a0
    80003188:	fff7c793          	not	a5,a5
    8000318c:	8ff9                	and	a5,a5,a4
    8000318e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003192:	00001097          	auipc	ra,0x1
    80003196:	100080e7          	jalr	256(ra) # 80004292 <log_write>
  brelse(bp);
    8000319a:	854a                	mv	a0,s2
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	e92080e7          	jalr	-366(ra) # 8000302e <brelse>
}
    800031a4:	60e2                	ld	ra,24(sp)
    800031a6:	6442                	ld	s0,16(sp)
    800031a8:	64a2                	ld	s1,8(sp)
    800031aa:	6902                	ld	s2,0(sp)
    800031ac:	6105                	addi	sp,sp,32
    800031ae:	8082                	ret
    panic("freeing free block");
    800031b0:	00005517          	auipc	a0,0x5
    800031b4:	3b850513          	addi	a0,a0,952 # 80008568 <syscalls+0xe8>
    800031b8:	ffffd097          	auipc	ra,0xffffd
    800031bc:	390080e7          	jalr	912(ra) # 80000548 <panic>

00000000800031c0 <balloc>:
{
    800031c0:	711d                	addi	sp,sp,-96
    800031c2:	ec86                	sd	ra,88(sp)
    800031c4:	e8a2                	sd	s0,80(sp)
    800031c6:	e4a6                	sd	s1,72(sp)
    800031c8:	e0ca                	sd	s2,64(sp)
    800031ca:	fc4e                	sd	s3,56(sp)
    800031cc:	f852                	sd	s4,48(sp)
    800031ce:	f456                	sd	s5,40(sp)
    800031d0:	f05a                	sd	s6,32(sp)
    800031d2:	ec5e                	sd	s7,24(sp)
    800031d4:	e862                	sd	s8,16(sp)
    800031d6:	e466                	sd	s9,8(sp)
    800031d8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031da:	0001d797          	auipc	a5,0x1d
    800031de:	c6a7a783          	lw	a5,-918(a5) # 8001fe44 <sb+0x4>
    800031e2:	cbd1                	beqz	a5,80003276 <balloc+0xb6>
    800031e4:	8baa                	mv	s7,a0
    800031e6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031e8:	0001db17          	auipc	s6,0x1d
    800031ec:	c58b0b13          	addi	s6,s6,-936 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031f2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031f6:	6c89                	lui	s9,0x2
    800031f8:	a831                	j	80003214 <balloc+0x54>
    brelse(bp);
    800031fa:	854a                	mv	a0,s2
    800031fc:	00000097          	auipc	ra,0x0
    80003200:	e32080e7          	jalr	-462(ra) # 8000302e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003204:	015c87bb          	addw	a5,s9,s5
    80003208:	00078a9b          	sext.w	s5,a5
    8000320c:	004b2703          	lw	a4,4(s6)
    80003210:	06eaf363          	bgeu	s5,a4,80003276 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003214:	41fad79b          	sraiw	a5,s5,0x1f
    80003218:	0137d79b          	srliw	a5,a5,0x13
    8000321c:	015787bb          	addw	a5,a5,s5
    80003220:	40d7d79b          	sraiw	a5,a5,0xd
    80003224:	01cb2583          	lw	a1,28(s6)
    80003228:	9dbd                	addw	a1,a1,a5
    8000322a:	855e                	mv	a0,s7
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	cd2080e7          	jalr	-814(ra) # 80002efe <bread>
    80003234:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003236:	004b2503          	lw	a0,4(s6)
    8000323a:	000a849b          	sext.w	s1,s5
    8000323e:	8662                	mv	a2,s8
    80003240:	faa4fde3          	bgeu	s1,a0,800031fa <balloc+0x3a>
      m = 1 << (bi % 8);
    80003244:	41f6579b          	sraiw	a5,a2,0x1f
    80003248:	01d7d69b          	srliw	a3,a5,0x1d
    8000324c:	00c6873b          	addw	a4,a3,a2
    80003250:	00777793          	andi	a5,a4,7
    80003254:	9f95                	subw	a5,a5,a3
    80003256:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000325a:	4037571b          	sraiw	a4,a4,0x3
    8000325e:	00e906b3          	add	a3,s2,a4
    80003262:	0586c683          	lbu	a3,88(a3)
    80003266:	00d7f5b3          	and	a1,a5,a3
    8000326a:	cd91                	beqz	a1,80003286 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326c:	2605                	addiw	a2,a2,1
    8000326e:	2485                	addiw	s1,s1,1
    80003270:	fd4618e3          	bne	a2,s4,80003240 <balloc+0x80>
    80003274:	b759                	j	800031fa <balloc+0x3a>
  panic("balloc: out of blocks");
    80003276:	00005517          	auipc	a0,0x5
    8000327a:	30a50513          	addi	a0,a0,778 # 80008580 <syscalls+0x100>
    8000327e:	ffffd097          	auipc	ra,0xffffd
    80003282:	2ca080e7          	jalr	714(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003286:	974a                	add	a4,a4,s2
    80003288:	8fd5                	or	a5,a5,a3
    8000328a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000328e:	854a                	mv	a0,s2
    80003290:	00001097          	auipc	ra,0x1
    80003294:	002080e7          	jalr	2(ra) # 80004292 <log_write>
        brelse(bp);
    80003298:	854a                	mv	a0,s2
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	d94080e7          	jalr	-620(ra) # 8000302e <brelse>
  bp = bread(dev, bno);
    800032a2:	85a6                	mv	a1,s1
    800032a4:	855e                	mv	a0,s7
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	c58080e7          	jalr	-936(ra) # 80002efe <bread>
    800032ae:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032b0:	40000613          	li	a2,1024
    800032b4:	4581                	li	a1,0
    800032b6:	05850513          	addi	a0,a0,88
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	a52080e7          	jalr	-1454(ra) # 80000d0c <memset>
  log_write(bp);
    800032c2:	854a                	mv	a0,s2
    800032c4:	00001097          	auipc	ra,0x1
    800032c8:	fce080e7          	jalr	-50(ra) # 80004292 <log_write>
  brelse(bp);
    800032cc:	854a                	mv	a0,s2
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	d60080e7          	jalr	-672(ra) # 8000302e <brelse>
}
    800032d6:	8526                	mv	a0,s1
    800032d8:	60e6                	ld	ra,88(sp)
    800032da:	6446                	ld	s0,80(sp)
    800032dc:	64a6                	ld	s1,72(sp)
    800032de:	6906                	ld	s2,64(sp)
    800032e0:	79e2                	ld	s3,56(sp)
    800032e2:	7a42                	ld	s4,48(sp)
    800032e4:	7aa2                	ld	s5,40(sp)
    800032e6:	7b02                	ld	s6,32(sp)
    800032e8:	6be2                	ld	s7,24(sp)
    800032ea:	6c42                	ld	s8,16(sp)
    800032ec:	6ca2                	ld	s9,8(sp)
    800032ee:	6125                	addi	sp,sp,96
    800032f0:	8082                	ret

00000000800032f2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032f2:	7179                	addi	sp,sp,-48
    800032f4:	f406                	sd	ra,40(sp)
    800032f6:	f022                	sd	s0,32(sp)
    800032f8:	ec26                	sd	s1,24(sp)
    800032fa:	e84a                	sd	s2,16(sp)
    800032fc:	e44e                	sd	s3,8(sp)
    800032fe:	e052                	sd	s4,0(sp)
    80003300:	1800                	addi	s0,sp,48
    80003302:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003304:	47ad                	li	a5,11
    80003306:	04b7fe63          	bgeu	a5,a1,80003362 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000330a:	ff45849b          	addiw	s1,a1,-12
    8000330e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003312:	0ff00793          	li	a5,255
    80003316:	0ae7e363          	bltu	a5,a4,800033bc <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000331a:	08052583          	lw	a1,128(a0)
    8000331e:	c5ad                	beqz	a1,80003388 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003320:	00092503          	lw	a0,0(s2)
    80003324:	00000097          	auipc	ra,0x0
    80003328:	bda080e7          	jalr	-1062(ra) # 80002efe <bread>
    8000332c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000332e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003332:	02049593          	slli	a1,s1,0x20
    80003336:	9181                	srli	a1,a1,0x20
    80003338:	058a                	slli	a1,a1,0x2
    8000333a:	00b784b3          	add	s1,a5,a1
    8000333e:	0004a983          	lw	s3,0(s1)
    80003342:	04098d63          	beqz	s3,8000339c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003346:	8552                	mv	a0,s4
    80003348:	00000097          	auipc	ra,0x0
    8000334c:	ce6080e7          	jalr	-794(ra) # 8000302e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003350:	854e                	mv	a0,s3
    80003352:	70a2                	ld	ra,40(sp)
    80003354:	7402                	ld	s0,32(sp)
    80003356:	64e2                	ld	s1,24(sp)
    80003358:	6942                	ld	s2,16(sp)
    8000335a:	69a2                	ld	s3,8(sp)
    8000335c:	6a02                	ld	s4,0(sp)
    8000335e:	6145                	addi	sp,sp,48
    80003360:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003362:	02059493          	slli	s1,a1,0x20
    80003366:	9081                	srli	s1,s1,0x20
    80003368:	048a                	slli	s1,s1,0x2
    8000336a:	94aa                	add	s1,s1,a0
    8000336c:	0504a983          	lw	s3,80(s1)
    80003370:	fe0990e3          	bnez	s3,80003350 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003374:	4108                	lw	a0,0(a0)
    80003376:	00000097          	auipc	ra,0x0
    8000337a:	e4a080e7          	jalr	-438(ra) # 800031c0 <balloc>
    8000337e:	0005099b          	sext.w	s3,a0
    80003382:	0534a823          	sw	s3,80(s1)
    80003386:	b7e9                	j	80003350 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003388:	4108                	lw	a0,0(a0)
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	e36080e7          	jalr	-458(ra) # 800031c0 <balloc>
    80003392:	0005059b          	sext.w	a1,a0
    80003396:	08b92023          	sw	a1,128(s2)
    8000339a:	b759                	j	80003320 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000339c:	00092503          	lw	a0,0(s2)
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	e20080e7          	jalr	-480(ra) # 800031c0 <balloc>
    800033a8:	0005099b          	sext.w	s3,a0
    800033ac:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033b0:	8552                	mv	a0,s4
    800033b2:	00001097          	auipc	ra,0x1
    800033b6:	ee0080e7          	jalr	-288(ra) # 80004292 <log_write>
    800033ba:	b771                	j	80003346 <bmap+0x54>
  panic("bmap: out of range");
    800033bc:	00005517          	auipc	a0,0x5
    800033c0:	1dc50513          	addi	a0,a0,476 # 80008598 <syscalls+0x118>
    800033c4:	ffffd097          	auipc	ra,0xffffd
    800033c8:	184080e7          	jalr	388(ra) # 80000548 <panic>

00000000800033cc <iget>:
{
    800033cc:	7179                	addi	sp,sp,-48
    800033ce:	f406                	sd	ra,40(sp)
    800033d0:	f022                	sd	s0,32(sp)
    800033d2:	ec26                	sd	s1,24(sp)
    800033d4:	e84a                	sd	s2,16(sp)
    800033d6:	e44e                	sd	s3,8(sp)
    800033d8:	e052                	sd	s4,0(sp)
    800033da:	1800                	addi	s0,sp,48
    800033dc:	89aa                	mv	s3,a0
    800033de:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800033e0:	0001d517          	auipc	a0,0x1d
    800033e4:	a8050513          	addi	a0,a0,-1408 # 8001fe60 <icache>
    800033e8:	ffffe097          	auipc	ra,0xffffe
    800033ec:	828080e7          	jalr	-2008(ra) # 80000c10 <acquire>
  empty = 0;
    800033f0:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033f2:	0001d497          	auipc	s1,0x1d
    800033f6:	a8648493          	addi	s1,s1,-1402 # 8001fe78 <icache+0x18>
    800033fa:	0001e697          	auipc	a3,0x1e
    800033fe:	50e68693          	addi	a3,a3,1294 # 80021908 <log>
    80003402:	a039                	j	80003410 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003404:	02090b63          	beqz	s2,8000343a <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003408:	08848493          	addi	s1,s1,136
    8000340c:	02d48a63          	beq	s1,a3,80003440 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003410:	449c                	lw	a5,8(s1)
    80003412:	fef059e3          	blez	a5,80003404 <iget+0x38>
    80003416:	4098                	lw	a4,0(s1)
    80003418:	ff3716e3          	bne	a4,s3,80003404 <iget+0x38>
    8000341c:	40d8                	lw	a4,4(s1)
    8000341e:	ff4713e3          	bne	a4,s4,80003404 <iget+0x38>
      ip->ref++;
    80003422:	2785                	addiw	a5,a5,1
    80003424:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003426:	0001d517          	auipc	a0,0x1d
    8000342a:	a3a50513          	addi	a0,a0,-1478 # 8001fe60 <icache>
    8000342e:	ffffe097          	auipc	ra,0xffffe
    80003432:	896080e7          	jalr	-1898(ra) # 80000cc4 <release>
      return ip;
    80003436:	8926                	mv	s2,s1
    80003438:	a03d                	j	80003466 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000343a:	f7f9                	bnez	a5,80003408 <iget+0x3c>
    8000343c:	8926                	mv	s2,s1
    8000343e:	b7e9                	j	80003408 <iget+0x3c>
  if(empty == 0)
    80003440:	02090c63          	beqz	s2,80003478 <iget+0xac>
  ip->dev = dev;
    80003444:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003448:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000344c:	4785                	li	a5,1
    8000344e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003452:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003456:	0001d517          	auipc	a0,0x1d
    8000345a:	a0a50513          	addi	a0,a0,-1526 # 8001fe60 <icache>
    8000345e:	ffffe097          	auipc	ra,0xffffe
    80003462:	866080e7          	jalr	-1946(ra) # 80000cc4 <release>
}
    80003466:	854a                	mv	a0,s2
    80003468:	70a2                	ld	ra,40(sp)
    8000346a:	7402                	ld	s0,32(sp)
    8000346c:	64e2                	ld	s1,24(sp)
    8000346e:	6942                	ld	s2,16(sp)
    80003470:	69a2                	ld	s3,8(sp)
    80003472:	6a02                	ld	s4,0(sp)
    80003474:	6145                	addi	sp,sp,48
    80003476:	8082                	ret
    panic("iget: no inodes");
    80003478:	00005517          	auipc	a0,0x5
    8000347c:	13850513          	addi	a0,a0,312 # 800085b0 <syscalls+0x130>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	0c8080e7          	jalr	200(ra) # 80000548 <panic>

0000000080003488 <fsinit>:
fsinit(int dev) {
    80003488:	7179                	addi	sp,sp,-48
    8000348a:	f406                	sd	ra,40(sp)
    8000348c:	f022                	sd	s0,32(sp)
    8000348e:	ec26                	sd	s1,24(sp)
    80003490:	e84a                	sd	s2,16(sp)
    80003492:	e44e                	sd	s3,8(sp)
    80003494:	1800                	addi	s0,sp,48
    80003496:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003498:	4585                	li	a1,1
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	a64080e7          	jalr	-1436(ra) # 80002efe <bread>
    800034a2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034a4:	0001d997          	auipc	s3,0x1d
    800034a8:	99c98993          	addi	s3,s3,-1636 # 8001fe40 <sb>
    800034ac:	02000613          	li	a2,32
    800034b0:	05850593          	addi	a1,a0,88
    800034b4:	854e                	mv	a0,s3
    800034b6:	ffffe097          	auipc	ra,0xffffe
    800034ba:	8b6080e7          	jalr	-1866(ra) # 80000d6c <memmove>
  brelse(bp);
    800034be:	8526                	mv	a0,s1
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	b6e080e7          	jalr	-1170(ra) # 8000302e <brelse>
  if(sb.magic != FSMAGIC)
    800034c8:	0009a703          	lw	a4,0(s3)
    800034cc:	102037b7          	lui	a5,0x10203
    800034d0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034d4:	02f71263          	bne	a4,a5,800034f8 <fsinit+0x70>
  initlog(dev, &sb);
    800034d8:	0001d597          	auipc	a1,0x1d
    800034dc:	96858593          	addi	a1,a1,-1688 # 8001fe40 <sb>
    800034e0:	854a                	mv	a0,s2
    800034e2:	00001097          	auipc	ra,0x1
    800034e6:	b38080e7          	jalr	-1224(ra) # 8000401a <initlog>
}
    800034ea:	70a2                	ld	ra,40(sp)
    800034ec:	7402                	ld	s0,32(sp)
    800034ee:	64e2                	ld	s1,24(sp)
    800034f0:	6942                	ld	s2,16(sp)
    800034f2:	69a2                	ld	s3,8(sp)
    800034f4:	6145                	addi	sp,sp,48
    800034f6:	8082                	ret
    panic("invalid file system");
    800034f8:	00005517          	auipc	a0,0x5
    800034fc:	0c850513          	addi	a0,a0,200 # 800085c0 <syscalls+0x140>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	048080e7          	jalr	72(ra) # 80000548 <panic>

0000000080003508 <iinit>:
{
    80003508:	7179                	addi	sp,sp,-48
    8000350a:	f406                	sd	ra,40(sp)
    8000350c:	f022                	sd	s0,32(sp)
    8000350e:	ec26                	sd	s1,24(sp)
    80003510:	e84a                	sd	s2,16(sp)
    80003512:	e44e                	sd	s3,8(sp)
    80003514:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003516:	00005597          	auipc	a1,0x5
    8000351a:	0c258593          	addi	a1,a1,194 # 800085d8 <syscalls+0x158>
    8000351e:	0001d517          	auipc	a0,0x1d
    80003522:	94250513          	addi	a0,a0,-1726 # 8001fe60 <icache>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	65a080e7          	jalr	1626(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000352e:	0001d497          	auipc	s1,0x1d
    80003532:	95a48493          	addi	s1,s1,-1702 # 8001fe88 <icache+0x28>
    80003536:	0001e997          	auipc	s3,0x1e
    8000353a:	3e298993          	addi	s3,s3,994 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000353e:	00005917          	auipc	s2,0x5
    80003542:	0a290913          	addi	s2,s2,162 # 800085e0 <syscalls+0x160>
    80003546:	85ca                	mv	a1,s2
    80003548:	8526                	mv	a0,s1
    8000354a:	00001097          	auipc	ra,0x1
    8000354e:	e36080e7          	jalr	-458(ra) # 80004380 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003552:	08848493          	addi	s1,s1,136
    80003556:	ff3498e3          	bne	s1,s3,80003546 <iinit+0x3e>
}
    8000355a:	70a2                	ld	ra,40(sp)
    8000355c:	7402                	ld	s0,32(sp)
    8000355e:	64e2                	ld	s1,24(sp)
    80003560:	6942                	ld	s2,16(sp)
    80003562:	69a2                	ld	s3,8(sp)
    80003564:	6145                	addi	sp,sp,48
    80003566:	8082                	ret

0000000080003568 <ialloc>:
{
    80003568:	715d                	addi	sp,sp,-80
    8000356a:	e486                	sd	ra,72(sp)
    8000356c:	e0a2                	sd	s0,64(sp)
    8000356e:	fc26                	sd	s1,56(sp)
    80003570:	f84a                	sd	s2,48(sp)
    80003572:	f44e                	sd	s3,40(sp)
    80003574:	f052                	sd	s4,32(sp)
    80003576:	ec56                	sd	s5,24(sp)
    80003578:	e85a                	sd	s6,16(sp)
    8000357a:	e45e                	sd	s7,8(sp)
    8000357c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000357e:	0001d717          	auipc	a4,0x1d
    80003582:	8ce72703          	lw	a4,-1842(a4) # 8001fe4c <sb+0xc>
    80003586:	4785                	li	a5,1
    80003588:	04e7fa63          	bgeu	a5,a4,800035dc <ialloc+0x74>
    8000358c:	8aaa                	mv	s5,a0
    8000358e:	8bae                	mv	s7,a1
    80003590:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003592:	0001da17          	auipc	s4,0x1d
    80003596:	8aea0a13          	addi	s4,s4,-1874 # 8001fe40 <sb>
    8000359a:	00048b1b          	sext.w	s6,s1
    8000359e:	0044d593          	srli	a1,s1,0x4
    800035a2:	018a2783          	lw	a5,24(s4)
    800035a6:	9dbd                	addw	a1,a1,a5
    800035a8:	8556                	mv	a0,s5
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	954080e7          	jalr	-1708(ra) # 80002efe <bread>
    800035b2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035b4:	05850993          	addi	s3,a0,88
    800035b8:	00f4f793          	andi	a5,s1,15
    800035bc:	079a                	slli	a5,a5,0x6
    800035be:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035c0:	00099783          	lh	a5,0(s3)
    800035c4:	c785                	beqz	a5,800035ec <ialloc+0x84>
    brelse(bp);
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	a68080e7          	jalr	-1432(ra) # 8000302e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ce:	0485                	addi	s1,s1,1
    800035d0:	00ca2703          	lw	a4,12(s4)
    800035d4:	0004879b          	sext.w	a5,s1
    800035d8:	fce7e1e3          	bltu	a5,a4,8000359a <ialloc+0x32>
  panic("ialloc: no inodes");
    800035dc:	00005517          	auipc	a0,0x5
    800035e0:	00c50513          	addi	a0,a0,12 # 800085e8 <syscalls+0x168>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	f64080e7          	jalr	-156(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800035ec:	04000613          	li	a2,64
    800035f0:	4581                	li	a1,0
    800035f2:	854e                	mv	a0,s3
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	718080e7          	jalr	1816(ra) # 80000d0c <memset>
      dip->type = type;
    800035fc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003600:	854a                	mv	a0,s2
    80003602:	00001097          	auipc	ra,0x1
    80003606:	c90080e7          	jalr	-880(ra) # 80004292 <log_write>
      brelse(bp);
    8000360a:	854a                	mv	a0,s2
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	a22080e7          	jalr	-1502(ra) # 8000302e <brelse>
      return iget(dev, inum);
    80003614:	85da                	mv	a1,s6
    80003616:	8556                	mv	a0,s5
    80003618:	00000097          	auipc	ra,0x0
    8000361c:	db4080e7          	jalr	-588(ra) # 800033cc <iget>
}
    80003620:	60a6                	ld	ra,72(sp)
    80003622:	6406                	ld	s0,64(sp)
    80003624:	74e2                	ld	s1,56(sp)
    80003626:	7942                	ld	s2,48(sp)
    80003628:	79a2                	ld	s3,40(sp)
    8000362a:	7a02                	ld	s4,32(sp)
    8000362c:	6ae2                	ld	s5,24(sp)
    8000362e:	6b42                	ld	s6,16(sp)
    80003630:	6ba2                	ld	s7,8(sp)
    80003632:	6161                	addi	sp,sp,80
    80003634:	8082                	ret

0000000080003636 <iupdate>:
{
    80003636:	1101                	addi	sp,sp,-32
    80003638:	ec06                	sd	ra,24(sp)
    8000363a:	e822                	sd	s0,16(sp)
    8000363c:	e426                	sd	s1,8(sp)
    8000363e:	e04a                	sd	s2,0(sp)
    80003640:	1000                	addi	s0,sp,32
    80003642:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003644:	415c                	lw	a5,4(a0)
    80003646:	0047d79b          	srliw	a5,a5,0x4
    8000364a:	0001d597          	auipc	a1,0x1d
    8000364e:	80e5a583          	lw	a1,-2034(a1) # 8001fe58 <sb+0x18>
    80003652:	9dbd                	addw	a1,a1,a5
    80003654:	4108                	lw	a0,0(a0)
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	8a8080e7          	jalr	-1880(ra) # 80002efe <bread>
    8000365e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003660:	05850793          	addi	a5,a0,88
    80003664:	40c8                	lw	a0,4(s1)
    80003666:	893d                	andi	a0,a0,15
    80003668:	051a                	slli	a0,a0,0x6
    8000366a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000366c:	04449703          	lh	a4,68(s1)
    80003670:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003674:	04649703          	lh	a4,70(s1)
    80003678:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000367c:	04849703          	lh	a4,72(s1)
    80003680:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003684:	04a49703          	lh	a4,74(s1)
    80003688:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000368c:	44f8                	lw	a4,76(s1)
    8000368e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003690:	03400613          	li	a2,52
    80003694:	05048593          	addi	a1,s1,80
    80003698:	0531                	addi	a0,a0,12
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	6d2080e7          	jalr	1746(ra) # 80000d6c <memmove>
  log_write(bp);
    800036a2:	854a                	mv	a0,s2
    800036a4:	00001097          	auipc	ra,0x1
    800036a8:	bee080e7          	jalr	-1042(ra) # 80004292 <log_write>
  brelse(bp);
    800036ac:	854a                	mv	a0,s2
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	980080e7          	jalr	-1664(ra) # 8000302e <brelse>
}
    800036b6:	60e2                	ld	ra,24(sp)
    800036b8:	6442                	ld	s0,16(sp)
    800036ba:	64a2                	ld	s1,8(sp)
    800036bc:	6902                	ld	s2,0(sp)
    800036be:	6105                	addi	sp,sp,32
    800036c0:	8082                	ret

00000000800036c2 <idup>:
{
    800036c2:	1101                	addi	sp,sp,-32
    800036c4:	ec06                	sd	ra,24(sp)
    800036c6:	e822                	sd	s0,16(sp)
    800036c8:	e426                	sd	s1,8(sp)
    800036ca:	1000                	addi	s0,sp,32
    800036cc:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800036ce:	0001c517          	auipc	a0,0x1c
    800036d2:	79250513          	addi	a0,a0,1938 # 8001fe60 <icache>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	53a080e7          	jalr	1338(ra) # 80000c10 <acquire>
  ip->ref++;
    800036de:	449c                	lw	a5,8(s1)
    800036e0:	2785                	addiw	a5,a5,1
    800036e2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800036e4:	0001c517          	auipc	a0,0x1c
    800036e8:	77c50513          	addi	a0,a0,1916 # 8001fe60 <icache>
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	5d8080e7          	jalr	1496(ra) # 80000cc4 <release>
}
    800036f4:	8526                	mv	a0,s1
    800036f6:	60e2                	ld	ra,24(sp)
    800036f8:	6442                	ld	s0,16(sp)
    800036fa:	64a2                	ld	s1,8(sp)
    800036fc:	6105                	addi	sp,sp,32
    800036fe:	8082                	ret

0000000080003700 <ilock>:
{
    80003700:	1101                	addi	sp,sp,-32
    80003702:	ec06                	sd	ra,24(sp)
    80003704:	e822                	sd	s0,16(sp)
    80003706:	e426                	sd	s1,8(sp)
    80003708:	e04a                	sd	s2,0(sp)
    8000370a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000370c:	c115                	beqz	a0,80003730 <ilock+0x30>
    8000370e:	84aa                	mv	s1,a0
    80003710:	451c                	lw	a5,8(a0)
    80003712:	00f05f63          	blez	a5,80003730 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003716:	0541                	addi	a0,a0,16
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	ca2080e7          	jalr	-862(ra) # 800043ba <acquiresleep>
  if(ip->valid == 0){
    80003720:	40bc                	lw	a5,64(s1)
    80003722:	cf99                	beqz	a5,80003740 <ilock+0x40>
}
    80003724:	60e2                	ld	ra,24(sp)
    80003726:	6442                	ld	s0,16(sp)
    80003728:	64a2                	ld	s1,8(sp)
    8000372a:	6902                	ld	s2,0(sp)
    8000372c:	6105                	addi	sp,sp,32
    8000372e:	8082                	ret
    panic("ilock");
    80003730:	00005517          	auipc	a0,0x5
    80003734:	ed050513          	addi	a0,a0,-304 # 80008600 <syscalls+0x180>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	e10080e7          	jalr	-496(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003740:	40dc                	lw	a5,4(s1)
    80003742:	0047d79b          	srliw	a5,a5,0x4
    80003746:	0001c597          	auipc	a1,0x1c
    8000374a:	7125a583          	lw	a1,1810(a1) # 8001fe58 <sb+0x18>
    8000374e:	9dbd                	addw	a1,a1,a5
    80003750:	4088                	lw	a0,0(s1)
    80003752:	fffff097          	auipc	ra,0xfffff
    80003756:	7ac080e7          	jalr	1964(ra) # 80002efe <bread>
    8000375a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000375c:	05850593          	addi	a1,a0,88
    80003760:	40dc                	lw	a5,4(s1)
    80003762:	8bbd                	andi	a5,a5,15
    80003764:	079a                	slli	a5,a5,0x6
    80003766:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003768:	00059783          	lh	a5,0(a1)
    8000376c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003770:	00259783          	lh	a5,2(a1)
    80003774:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003778:	00459783          	lh	a5,4(a1)
    8000377c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003780:	00659783          	lh	a5,6(a1)
    80003784:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003788:	459c                	lw	a5,8(a1)
    8000378a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000378c:	03400613          	li	a2,52
    80003790:	05b1                	addi	a1,a1,12
    80003792:	05048513          	addi	a0,s1,80
    80003796:	ffffd097          	auipc	ra,0xffffd
    8000379a:	5d6080e7          	jalr	1494(ra) # 80000d6c <memmove>
    brelse(bp);
    8000379e:	854a                	mv	a0,s2
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	88e080e7          	jalr	-1906(ra) # 8000302e <brelse>
    ip->valid = 1;
    800037a8:	4785                	li	a5,1
    800037aa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037ac:	04449783          	lh	a5,68(s1)
    800037b0:	fbb5                	bnez	a5,80003724 <ilock+0x24>
      panic("ilock: no type");
    800037b2:	00005517          	auipc	a0,0x5
    800037b6:	e5650513          	addi	a0,a0,-426 # 80008608 <syscalls+0x188>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	d8e080e7          	jalr	-626(ra) # 80000548 <panic>

00000000800037c2 <iunlock>:
{
    800037c2:	1101                	addi	sp,sp,-32
    800037c4:	ec06                	sd	ra,24(sp)
    800037c6:	e822                	sd	s0,16(sp)
    800037c8:	e426                	sd	s1,8(sp)
    800037ca:	e04a                	sd	s2,0(sp)
    800037cc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037ce:	c905                	beqz	a0,800037fe <iunlock+0x3c>
    800037d0:	84aa                	mv	s1,a0
    800037d2:	01050913          	addi	s2,a0,16
    800037d6:	854a                	mv	a0,s2
    800037d8:	00001097          	auipc	ra,0x1
    800037dc:	c7c080e7          	jalr	-900(ra) # 80004454 <holdingsleep>
    800037e0:	cd19                	beqz	a0,800037fe <iunlock+0x3c>
    800037e2:	449c                	lw	a5,8(s1)
    800037e4:	00f05d63          	blez	a5,800037fe <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037e8:	854a                	mv	a0,s2
    800037ea:	00001097          	auipc	ra,0x1
    800037ee:	c26080e7          	jalr	-986(ra) # 80004410 <releasesleep>
}
    800037f2:	60e2                	ld	ra,24(sp)
    800037f4:	6442                	ld	s0,16(sp)
    800037f6:	64a2                	ld	s1,8(sp)
    800037f8:	6902                	ld	s2,0(sp)
    800037fa:	6105                	addi	sp,sp,32
    800037fc:	8082                	ret
    panic("iunlock");
    800037fe:	00005517          	auipc	a0,0x5
    80003802:	e1a50513          	addi	a0,a0,-486 # 80008618 <syscalls+0x198>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	d42080e7          	jalr	-702(ra) # 80000548 <panic>

000000008000380e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000380e:	7179                	addi	sp,sp,-48
    80003810:	f406                	sd	ra,40(sp)
    80003812:	f022                	sd	s0,32(sp)
    80003814:	ec26                	sd	s1,24(sp)
    80003816:	e84a                	sd	s2,16(sp)
    80003818:	e44e                	sd	s3,8(sp)
    8000381a:	e052                	sd	s4,0(sp)
    8000381c:	1800                	addi	s0,sp,48
    8000381e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003820:	05050493          	addi	s1,a0,80
    80003824:	08050913          	addi	s2,a0,128
    80003828:	a021                	j	80003830 <itrunc+0x22>
    8000382a:	0491                	addi	s1,s1,4
    8000382c:	01248d63          	beq	s1,s2,80003846 <itrunc+0x38>
    if(ip->addrs[i]){
    80003830:	408c                	lw	a1,0(s1)
    80003832:	dde5                	beqz	a1,8000382a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003834:	0009a503          	lw	a0,0(s3)
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	90c080e7          	jalr	-1780(ra) # 80003144 <bfree>
      ip->addrs[i] = 0;
    80003840:	0004a023          	sw	zero,0(s1)
    80003844:	b7dd                	j	8000382a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003846:	0809a583          	lw	a1,128(s3)
    8000384a:	e185                	bnez	a1,8000386a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000384c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003850:	854e                	mv	a0,s3
    80003852:	00000097          	auipc	ra,0x0
    80003856:	de4080e7          	jalr	-540(ra) # 80003636 <iupdate>
}
    8000385a:	70a2                	ld	ra,40(sp)
    8000385c:	7402                	ld	s0,32(sp)
    8000385e:	64e2                	ld	s1,24(sp)
    80003860:	6942                	ld	s2,16(sp)
    80003862:	69a2                	ld	s3,8(sp)
    80003864:	6a02                	ld	s4,0(sp)
    80003866:	6145                	addi	sp,sp,48
    80003868:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000386a:	0009a503          	lw	a0,0(s3)
    8000386e:	fffff097          	auipc	ra,0xfffff
    80003872:	690080e7          	jalr	1680(ra) # 80002efe <bread>
    80003876:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003878:	05850493          	addi	s1,a0,88
    8000387c:	45850913          	addi	s2,a0,1112
    80003880:	a811                	j	80003894 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003882:	0009a503          	lw	a0,0(s3)
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	8be080e7          	jalr	-1858(ra) # 80003144 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000388e:	0491                	addi	s1,s1,4
    80003890:	01248563          	beq	s1,s2,8000389a <itrunc+0x8c>
      if(a[j])
    80003894:	408c                	lw	a1,0(s1)
    80003896:	dde5                	beqz	a1,8000388e <itrunc+0x80>
    80003898:	b7ed                	j	80003882 <itrunc+0x74>
    brelse(bp);
    8000389a:	8552                	mv	a0,s4
    8000389c:	fffff097          	auipc	ra,0xfffff
    800038a0:	792080e7          	jalr	1938(ra) # 8000302e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038a4:	0809a583          	lw	a1,128(s3)
    800038a8:	0009a503          	lw	a0,0(s3)
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	898080e7          	jalr	-1896(ra) # 80003144 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038b4:	0809a023          	sw	zero,128(s3)
    800038b8:	bf51                	j	8000384c <itrunc+0x3e>

00000000800038ba <iput>:
{
    800038ba:	1101                	addi	sp,sp,-32
    800038bc:	ec06                	sd	ra,24(sp)
    800038be:	e822                	sd	s0,16(sp)
    800038c0:	e426                	sd	s1,8(sp)
    800038c2:	e04a                	sd	s2,0(sp)
    800038c4:	1000                	addi	s0,sp,32
    800038c6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038c8:	0001c517          	auipc	a0,0x1c
    800038cc:	59850513          	addi	a0,a0,1432 # 8001fe60 <icache>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	340080e7          	jalr	832(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038d8:	4498                	lw	a4,8(s1)
    800038da:	4785                	li	a5,1
    800038dc:	02f70363          	beq	a4,a5,80003902 <iput+0x48>
  ip->ref--;
    800038e0:	449c                	lw	a5,8(s1)
    800038e2:	37fd                	addiw	a5,a5,-1
    800038e4:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038e6:	0001c517          	auipc	a0,0x1c
    800038ea:	57a50513          	addi	a0,a0,1402 # 8001fe60 <icache>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	3d6080e7          	jalr	982(ra) # 80000cc4 <release>
}
    800038f6:	60e2                	ld	ra,24(sp)
    800038f8:	6442                	ld	s0,16(sp)
    800038fa:	64a2                	ld	s1,8(sp)
    800038fc:	6902                	ld	s2,0(sp)
    800038fe:	6105                	addi	sp,sp,32
    80003900:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003902:	40bc                	lw	a5,64(s1)
    80003904:	dff1                	beqz	a5,800038e0 <iput+0x26>
    80003906:	04a49783          	lh	a5,74(s1)
    8000390a:	fbf9                	bnez	a5,800038e0 <iput+0x26>
    acquiresleep(&ip->lock);
    8000390c:	01048913          	addi	s2,s1,16
    80003910:	854a                	mv	a0,s2
    80003912:	00001097          	auipc	ra,0x1
    80003916:	aa8080e7          	jalr	-1368(ra) # 800043ba <acquiresleep>
    release(&icache.lock);
    8000391a:	0001c517          	auipc	a0,0x1c
    8000391e:	54650513          	addi	a0,a0,1350 # 8001fe60 <icache>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	3a2080e7          	jalr	930(ra) # 80000cc4 <release>
    itrunc(ip);
    8000392a:	8526                	mv	a0,s1
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	ee2080e7          	jalr	-286(ra) # 8000380e <itrunc>
    ip->type = 0;
    80003934:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003938:	8526                	mv	a0,s1
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	cfc080e7          	jalr	-772(ra) # 80003636 <iupdate>
    ip->valid = 0;
    80003942:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003946:	854a                	mv	a0,s2
    80003948:	00001097          	auipc	ra,0x1
    8000394c:	ac8080e7          	jalr	-1336(ra) # 80004410 <releasesleep>
    acquire(&icache.lock);
    80003950:	0001c517          	auipc	a0,0x1c
    80003954:	51050513          	addi	a0,a0,1296 # 8001fe60 <icache>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	2b8080e7          	jalr	696(ra) # 80000c10 <acquire>
    80003960:	b741                	j	800038e0 <iput+0x26>

0000000080003962 <iunlockput>:
{
    80003962:	1101                	addi	sp,sp,-32
    80003964:	ec06                	sd	ra,24(sp)
    80003966:	e822                	sd	s0,16(sp)
    80003968:	e426                	sd	s1,8(sp)
    8000396a:	1000                	addi	s0,sp,32
    8000396c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	e54080e7          	jalr	-428(ra) # 800037c2 <iunlock>
  iput(ip);
    80003976:	8526                	mv	a0,s1
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	f42080e7          	jalr	-190(ra) # 800038ba <iput>
}
    80003980:	60e2                	ld	ra,24(sp)
    80003982:	6442                	ld	s0,16(sp)
    80003984:	64a2                	ld	s1,8(sp)
    80003986:	6105                	addi	sp,sp,32
    80003988:	8082                	ret

000000008000398a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000398a:	1141                	addi	sp,sp,-16
    8000398c:	e422                	sd	s0,8(sp)
    8000398e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003990:	411c                	lw	a5,0(a0)
    80003992:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003994:	415c                	lw	a5,4(a0)
    80003996:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003998:	04451783          	lh	a5,68(a0)
    8000399c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039a0:	04a51783          	lh	a5,74(a0)
    800039a4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039a8:	04c56783          	lwu	a5,76(a0)
    800039ac:	e99c                	sd	a5,16(a1)
}
    800039ae:	6422                	ld	s0,8(sp)
    800039b0:	0141                	addi	sp,sp,16
    800039b2:	8082                	ret

00000000800039b4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039b4:	457c                	lw	a5,76(a0)
    800039b6:	0ed7e863          	bltu	a5,a3,80003aa6 <readi+0xf2>
{
    800039ba:	7159                	addi	sp,sp,-112
    800039bc:	f486                	sd	ra,104(sp)
    800039be:	f0a2                	sd	s0,96(sp)
    800039c0:	eca6                	sd	s1,88(sp)
    800039c2:	e8ca                	sd	s2,80(sp)
    800039c4:	e4ce                	sd	s3,72(sp)
    800039c6:	e0d2                	sd	s4,64(sp)
    800039c8:	fc56                	sd	s5,56(sp)
    800039ca:	f85a                	sd	s6,48(sp)
    800039cc:	f45e                	sd	s7,40(sp)
    800039ce:	f062                	sd	s8,32(sp)
    800039d0:	ec66                	sd	s9,24(sp)
    800039d2:	e86a                	sd	s10,16(sp)
    800039d4:	e46e                	sd	s11,8(sp)
    800039d6:	1880                	addi	s0,sp,112
    800039d8:	8baa                	mv	s7,a0
    800039da:	8c2e                	mv	s8,a1
    800039dc:	8ab2                	mv	s5,a2
    800039de:	84b6                	mv	s1,a3
    800039e0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039e2:	9f35                	addw	a4,a4,a3
    return 0;
    800039e4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039e6:	08d76f63          	bltu	a4,a3,80003a84 <readi+0xd0>
  if(off + n > ip->size)
    800039ea:	00e7f463          	bgeu	a5,a4,800039f2 <readi+0x3e>
    n = ip->size - off;
    800039ee:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f2:	0a0b0863          	beqz	s6,80003aa2 <readi+0xee>
    800039f6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039f8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039fc:	5cfd                	li	s9,-1
    800039fe:	a82d                	j	80003a38 <readi+0x84>
    80003a00:	020a1d93          	slli	s11,s4,0x20
    80003a04:	020ddd93          	srli	s11,s11,0x20
    80003a08:	05890613          	addi	a2,s2,88
    80003a0c:	86ee                	mv	a3,s11
    80003a0e:	963a                	add	a2,a2,a4
    80003a10:	85d6                	mv	a1,s5
    80003a12:	8562                	mv	a0,s8
    80003a14:	fffff097          	auipc	ra,0xfffff
    80003a18:	b2e080e7          	jalr	-1234(ra) # 80002542 <either_copyout>
    80003a1c:	05950d63          	beq	a0,s9,80003a76 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a20:	854a                	mv	a0,s2
    80003a22:	fffff097          	auipc	ra,0xfffff
    80003a26:	60c080e7          	jalr	1548(ra) # 8000302e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a2a:	013a09bb          	addw	s3,s4,s3
    80003a2e:	009a04bb          	addw	s1,s4,s1
    80003a32:	9aee                	add	s5,s5,s11
    80003a34:	0569f663          	bgeu	s3,s6,80003a80 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a38:	000ba903          	lw	s2,0(s7)
    80003a3c:	00a4d59b          	srliw	a1,s1,0xa
    80003a40:	855e                	mv	a0,s7
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	8b0080e7          	jalr	-1872(ra) # 800032f2 <bmap>
    80003a4a:	0005059b          	sext.w	a1,a0
    80003a4e:	854a                	mv	a0,s2
    80003a50:	fffff097          	auipc	ra,0xfffff
    80003a54:	4ae080e7          	jalr	1198(ra) # 80002efe <bread>
    80003a58:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a5a:	3ff4f713          	andi	a4,s1,1023
    80003a5e:	40ed07bb          	subw	a5,s10,a4
    80003a62:	413b06bb          	subw	a3,s6,s3
    80003a66:	8a3e                	mv	s4,a5
    80003a68:	2781                	sext.w	a5,a5
    80003a6a:	0006861b          	sext.w	a2,a3
    80003a6e:	f8f679e3          	bgeu	a2,a5,80003a00 <readi+0x4c>
    80003a72:	8a36                	mv	s4,a3
    80003a74:	b771                	j	80003a00 <readi+0x4c>
      brelse(bp);
    80003a76:	854a                	mv	a0,s2
    80003a78:	fffff097          	auipc	ra,0xfffff
    80003a7c:	5b6080e7          	jalr	1462(ra) # 8000302e <brelse>
  }
  return tot;
    80003a80:	0009851b          	sext.w	a0,s3
}
    80003a84:	70a6                	ld	ra,104(sp)
    80003a86:	7406                	ld	s0,96(sp)
    80003a88:	64e6                	ld	s1,88(sp)
    80003a8a:	6946                	ld	s2,80(sp)
    80003a8c:	69a6                	ld	s3,72(sp)
    80003a8e:	6a06                	ld	s4,64(sp)
    80003a90:	7ae2                	ld	s5,56(sp)
    80003a92:	7b42                	ld	s6,48(sp)
    80003a94:	7ba2                	ld	s7,40(sp)
    80003a96:	7c02                	ld	s8,32(sp)
    80003a98:	6ce2                	ld	s9,24(sp)
    80003a9a:	6d42                	ld	s10,16(sp)
    80003a9c:	6da2                	ld	s11,8(sp)
    80003a9e:	6165                	addi	sp,sp,112
    80003aa0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa2:	89da                	mv	s3,s6
    80003aa4:	bff1                	j	80003a80 <readi+0xcc>
    return 0;
    80003aa6:	4501                	li	a0,0
}
    80003aa8:	8082                	ret

0000000080003aaa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aaa:	457c                	lw	a5,76(a0)
    80003aac:	10d7e663          	bltu	a5,a3,80003bb8 <writei+0x10e>
{
    80003ab0:	7159                	addi	sp,sp,-112
    80003ab2:	f486                	sd	ra,104(sp)
    80003ab4:	f0a2                	sd	s0,96(sp)
    80003ab6:	eca6                	sd	s1,88(sp)
    80003ab8:	e8ca                	sd	s2,80(sp)
    80003aba:	e4ce                	sd	s3,72(sp)
    80003abc:	e0d2                	sd	s4,64(sp)
    80003abe:	fc56                	sd	s5,56(sp)
    80003ac0:	f85a                	sd	s6,48(sp)
    80003ac2:	f45e                	sd	s7,40(sp)
    80003ac4:	f062                	sd	s8,32(sp)
    80003ac6:	ec66                	sd	s9,24(sp)
    80003ac8:	e86a                	sd	s10,16(sp)
    80003aca:	e46e                	sd	s11,8(sp)
    80003acc:	1880                	addi	s0,sp,112
    80003ace:	8baa                	mv	s7,a0
    80003ad0:	8c2e                	mv	s8,a1
    80003ad2:	8ab2                	mv	s5,a2
    80003ad4:	8936                	mv	s2,a3
    80003ad6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ad8:	00e687bb          	addw	a5,a3,a4
    80003adc:	0ed7e063          	bltu	a5,a3,80003bbc <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ae0:	00043737          	lui	a4,0x43
    80003ae4:	0cf76e63          	bltu	a4,a5,80003bc0 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ae8:	0a0b0763          	beqz	s6,80003b96 <writei+0xec>
    80003aec:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aee:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003af2:	5cfd                	li	s9,-1
    80003af4:	a091                	j	80003b38 <writei+0x8e>
    80003af6:	02099d93          	slli	s11,s3,0x20
    80003afa:	020ddd93          	srli	s11,s11,0x20
    80003afe:	05848513          	addi	a0,s1,88
    80003b02:	86ee                	mv	a3,s11
    80003b04:	8656                	mv	a2,s5
    80003b06:	85e2                	mv	a1,s8
    80003b08:	953a                	add	a0,a0,a4
    80003b0a:	fffff097          	auipc	ra,0xfffff
    80003b0e:	a8e080e7          	jalr	-1394(ra) # 80002598 <either_copyin>
    80003b12:	07950263          	beq	a0,s9,80003b76 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b16:	8526                	mv	a0,s1
    80003b18:	00000097          	auipc	ra,0x0
    80003b1c:	77a080e7          	jalr	1914(ra) # 80004292 <log_write>
    brelse(bp);
    80003b20:	8526                	mv	a0,s1
    80003b22:	fffff097          	auipc	ra,0xfffff
    80003b26:	50c080e7          	jalr	1292(ra) # 8000302e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b2a:	01498a3b          	addw	s4,s3,s4
    80003b2e:	0129893b          	addw	s2,s3,s2
    80003b32:	9aee                	add	s5,s5,s11
    80003b34:	056a7663          	bgeu	s4,s6,80003b80 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b38:	000ba483          	lw	s1,0(s7)
    80003b3c:	00a9559b          	srliw	a1,s2,0xa
    80003b40:	855e                	mv	a0,s7
    80003b42:	fffff097          	auipc	ra,0xfffff
    80003b46:	7b0080e7          	jalr	1968(ra) # 800032f2 <bmap>
    80003b4a:	0005059b          	sext.w	a1,a0
    80003b4e:	8526                	mv	a0,s1
    80003b50:	fffff097          	auipc	ra,0xfffff
    80003b54:	3ae080e7          	jalr	942(ra) # 80002efe <bread>
    80003b58:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b5a:	3ff97713          	andi	a4,s2,1023
    80003b5e:	40ed07bb          	subw	a5,s10,a4
    80003b62:	414b06bb          	subw	a3,s6,s4
    80003b66:	89be                	mv	s3,a5
    80003b68:	2781                	sext.w	a5,a5
    80003b6a:	0006861b          	sext.w	a2,a3
    80003b6e:	f8f674e3          	bgeu	a2,a5,80003af6 <writei+0x4c>
    80003b72:	89b6                	mv	s3,a3
    80003b74:	b749                	j	80003af6 <writei+0x4c>
      brelse(bp);
    80003b76:	8526                	mv	a0,s1
    80003b78:	fffff097          	auipc	ra,0xfffff
    80003b7c:	4b6080e7          	jalr	1206(ra) # 8000302e <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003b80:	04cba783          	lw	a5,76(s7)
    80003b84:	0127f463          	bgeu	a5,s2,80003b8c <writei+0xe2>
      ip->size = off;
    80003b88:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b8c:	855e                	mv	a0,s7
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	aa8080e7          	jalr	-1368(ra) # 80003636 <iupdate>
  }

  return n;
    80003b96:	000b051b          	sext.w	a0,s6
}
    80003b9a:	70a6                	ld	ra,104(sp)
    80003b9c:	7406                	ld	s0,96(sp)
    80003b9e:	64e6                	ld	s1,88(sp)
    80003ba0:	6946                	ld	s2,80(sp)
    80003ba2:	69a6                	ld	s3,72(sp)
    80003ba4:	6a06                	ld	s4,64(sp)
    80003ba6:	7ae2                	ld	s5,56(sp)
    80003ba8:	7b42                	ld	s6,48(sp)
    80003baa:	7ba2                	ld	s7,40(sp)
    80003bac:	7c02                	ld	s8,32(sp)
    80003bae:	6ce2                	ld	s9,24(sp)
    80003bb0:	6d42                	ld	s10,16(sp)
    80003bb2:	6da2                	ld	s11,8(sp)
    80003bb4:	6165                	addi	sp,sp,112
    80003bb6:	8082                	ret
    return -1;
    80003bb8:	557d                	li	a0,-1
}
    80003bba:	8082                	ret
    return -1;
    80003bbc:	557d                	li	a0,-1
    80003bbe:	bff1                	j	80003b9a <writei+0xf0>
    return -1;
    80003bc0:	557d                	li	a0,-1
    80003bc2:	bfe1                	j	80003b9a <writei+0xf0>

0000000080003bc4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bc4:	1141                	addi	sp,sp,-16
    80003bc6:	e406                	sd	ra,8(sp)
    80003bc8:	e022                	sd	s0,0(sp)
    80003bca:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bcc:	4639                	li	a2,14
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	21a080e7          	jalr	538(ra) # 80000de8 <strncmp>
}
    80003bd6:	60a2                	ld	ra,8(sp)
    80003bd8:	6402                	ld	s0,0(sp)
    80003bda:	0141                	addi	sp,sp,16
    80003bdc:	8082                	ret

0000000080003bde <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bde:	7139                	addi	sp,sp,-64
    80003be0:	fc06                	sd	ra,56(sp)
    80003be2:	f822                	sd	s0,48(sp)
    80003be4:	f426                	sd	s1,40(sp)
    80003be6:	f04a                	sd	s2,32(sp)
    80003be8:	ec4e                	sd	s3,24(sp)
    80003bea:	e852                	sd	s4,16(sp)
    80003bec:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bee:	04451703          	lh	a4,68(a0)
    80003bf2:	4785                	li	a5,1
    80003bf4:	00f71a63          	bne	a4,a5,80003c08 <dirlookup+0x2a>
    80003bf8:	892a                	mv	s2,a0
    80003bfa:	89ae                	mv	s3,a1
    80003bfc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bfe:	457c                	lw	a5,76(a0)
    80003c00:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c02:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c04:	e79d                	bnez	a5,80003c32 <dirlookup+0x54>
    80003c06:	a8a5                	j	80003c7e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c08:	00005517          	auipc	a0,0x5
    80003c0c:	a1850513          	addi	a0,a0,-1512 # 80008620 <syscalls+0x1a0>
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	938080e7          	jalr	-1736(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c18:	00005517          	auipc	a0,0x5
    80003c1c:	a2050513          	addi	a0,a0,-1504 # 80008638 <syscalls+0x1b8>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	928080e7          	jalr	-1752(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c28:	24c1                	addiw	s1,s1,16
    80003c2a:	04c92783          	lw	a5,76(s2)
    80003c2e:	04f4f763          	bgeu	s1,a5,80003c7c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c32:	4741                	li	a4,16
    80003c34:	86a6                	mv	a3,s1
    80003c36:	fc040613          	addi	a2,s0,-64
    80003c3a:	4581                	li	a1,0
    80003c3c:	854a                	mv	a0,s2
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	d76080e7          	jalr	-650(ra) # 800039b4 <readi>
    80003c46:	47c1                	li	a5,16
    80003c48:	fcf518e3          	bne	a0,a5,80003c18 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c4c:	fc045783          	lhu	a5,-64(s0)
    80003c50:	dfe1                	beqz	a5,80003c28 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c52:	fc240593          	addi	a1,s0,-62
    80003c56:	854e                	mv	a0,s3
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	f6c080e7          	jalr	-148(ra) # 80003bc4 <namecmp>
    80003c60:	f561                	bnez	a0,80003c28 <dirlookup+0x4a>
      if(poff)
    80003c62:	000a0463          	beqz	s4,80003c6a <dirlookup+0x8c>
        *poff = off;
    80003c66:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c6a:	fc045583          	lhu	a1,-64(s0)
    80003c6e:	00092503          	lw	a0,0(s2)
    80003c72:	fffff097          	auipc	ra,0xfffff
    80003c76:	75a080e7          	jalr	1882(ra) # 800033cc <iget>
    80003c7a:	a011                	j	80003c7e <dirlookup+0xa0>
  return 0;
    80003c7c:	4501                	li	a0,0
}
    80003c7e:	70e2                	ld	ra,56(sp)
    80003c80:	7442                	ld	s0,48(sp)
    80003c82:	74a2                	ld	s1,40(sp)
    80003c84:	7902                	ld	s2,32(sp)
    80003c86:	69e2                	ld	s3,24(sp)
    80003c88:	6a42                	ld	s4,16(sp)
    80003c8a:	6121                	addi	sp,sp,64
    80003c8c:	8082                	ret

0000000080003c8e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c8e:	711d                	addi	sp,sp,-96
    80003c90:	ec86                	sd	ra,88(sp)
    80003c92:	e8a2                	sd	s0,80(sp)
    80003c94:	e4a6                	sd	s1,72(sp)
    80003c96:	e0ca                	sd	s2,64(sp)
    80003c98:	fc4e                	sd	s3,56(sp)
    80003c9a:	f852                	sd	s4,48(sp)
    80003c9c:	f456                	sd	s5,40(sp)
    80003c9e:	f05a                	sd	s6,32(sp)
    80003ca0:	ec5e                	sd	s7,24(sp)
    80003ca2:	e862                	sd	s8,16(sp)
    80003ca4:	e466                	sd	s9,8(sp)
    80003ca6:	1080                	addi	s0,sp,96
    80003ca8:	84aa                	mv	s1,a0
    80003caa:	8b2e                	mv	s6,a1
    80003cac:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cae:	00054703          	lbu	a4,0(a0)
    80003cb2:	02f00793          	li	a5,47
    80003cb6:	02f70363          	beq	a4,a5,80003cdc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cba:	ffffe097          	auipc	ra,0xffffe
    80003cbe:	e1a080e7          	jalr	-486(ra) # 80001ad4 <myproc>
    80003cc2:	15053503          	ld	a0,336(a0)
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	9fc080e7          	jalr	-1540(ra) # 800036c2 <idup>
    80003cce:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cd0:	02f00913          	li	s2,47
  len = path - s;
    80003cd4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003cd6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cd8:	4c05                	li	s8,1
    80003cda:	a865                	j	80003d92 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cdc:	4585                	li	a1,1
    80003cde:	4505                	li	a0,1
    80003ce0:	fffff097          	auipc	ra,0xfffff
    80003ce4:	6ec080e7          	jalr	1772(ra) # 800033cc <iget>
    80003ce8:	89aa                	mv	s3,a0
    80003cea:	b7dd                	j	80003cd0 <namex+0x42>
      iunlockput(ip);
    80003cec:	854e                	mv	a0,s3
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	c74080e7          	jalr	-908(ra) # 80003962 <iunlockput>
      return 0;
    80003cf6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cf8:	854e                	mv	a0,s3
    80003cfa:	60e6                	ld	ra,88(sp)
    80003cfc:	6446                	ld	s0,80(sp)
    80003cfe:	64a6                	ld	s1,72(sp)
    80003d00:	6906                	ld	s2,64(sp)
    80003d02:	79e2                	ld	s3,56(sp)
    80003d04:	7a42                	ld	s4,48(sp)
    80003d06:	7aa2                	ld	s5,40(sp)
    80003d08:	7b02                	ld	s6,32(sp)
    80003d0a:	6be2                	ld	s7,24(sp)
    80003d0c:	6c42                	ld	s8,16(sp)
    80003d0e:	6ca2                	ld	s9,8(sp)
    80003d10:	6125                	addi	sp,sp,96
    80003d12:	8082                	ret
      iunlock(ip);
    80003d14:	854e                	mv	a0,s3
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	aac080e7          	jalr	-1364(ra) # 800037c2 <iunlock>
      return ip;
    80003d1e:	bfe9                	j	80003cf8 <namex+0x6a>
      iunlockput(ip);
    80003d20:	854e                	mv	a0,s3
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	c40080e7          	jalr	-960(ra) # 80003962 <iunlockput>
      return 0;
    80003d2a:	89d2                	mv	s3,s4
    80003d2c:	b7f1                	j	80003cf8 <namex+0x6a>
  len = path - s;
    80003d2e:	40b48633          	sub	a2,s1,a1
    80003d32:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d36:	094cd463          	bge	s9,s4,80003dbe <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d3a:	4639                	li	a2,14
    80003d3c:	8556                	mv	a0,s5
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	02e080e7          	jalr	46(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003d46:	0004c783          	lbu	a5,0(s1)
    80003d4a:	01279763          	bne	a5,s2,80003d58 <namex+0xca>
    path++;
    80003d4e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d50:	0004c783          	lbu	a5,0(s1)
    80003d54:	ff278de3          	beq	a5,s2,80003d4e <namex+0xc0>
    ilock(ip);
    80003d58:	854e                	mv	a0,s3
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	9a6080e7          	jalr	-1626(ra) # 80003700 <ilock>
    if(ip->type != T_DIR){
    80003d62:	04499783          	lh	a5,68(s3)
    80003d66:	f98793e3          	bne	a5,s8,80003cec <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d6a:	000b0563          	beqz	s6,80003d74 <namex+0xe6>
    80003d6e:	0004c783          	lbu	a5,0(s1)
    80003d72:	d3cd                	beqz	a5,80003d14 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d74:	865e                	mv	a2,s7
    80003d76:	85d6                	mv	a1,s5
    80003d78:	854e                	mv	a0,s3
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	e64080e7          	jalr	-412(ra) # 80003bde <dirlookup>
    80003d82:	8a2a                	mv	s4,a0
    80003d84:	dd51                	beqz	a0,80003d20 <namex+0x92>
    iunlockput(ip);
    80003d86:	854e                	mv	a0,s3
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	bda080e7          	jalr	-1062(ra) # 80003962 <iunlockput>
    ip = next;
    80003d90:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d92:	0004c783          	lbu	a5,0(s1)
    80003d96:	05279763          	bne	a5,s2,80003de4 <namex+0x156>
    path++;
    80003d9a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d9c:	0004c783          	lbu	a5,0(s1)
    80003da0:	ff278de3          	beq	a5,s2,80003d9a <namex+0x10c>
  if(*path == 0)
    80003da4:	c79d                	beqz	a5,80003dd2 <namex+0x144>
    path++;
    80003da6:	85a6                	mv	a1,s1
  len = path - s;
    80003da8:	8a5e                	mv	s4,s7
    80003daa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dac:	01278963          	beq	a5,s2,80003dbe <namex+0x130>
    80003db0:	dfbd                	beqz	a5,80003d2e <namex+0xa0>
    path++;
    80003db2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003db4:	0004c783          	lbu	a5,0(s1)
    80003db8:	ff279ce3          	bne	a5,s2,80003db0 <namex+0x122>
    80003dbc:	bf8d                	j	80003d2e <namex+0xa0>
    memmove(name, s, len);
    80003dbe:	2601                	sext.w	a2,a2
    80003dc0:	8556                	mv	a0,s5
    80003dc2:	ffffd097          	auipc	ra,0xffffd
    80003dc6:	faa080e7          	jalr	-86(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003dca:	9a56                	add	s4,s4,s5
    80003dcc:	000a0023          	sb	zero,0(s4)
    80003dd0:	bf9d                	j	80003d46 <namex+0xb8>
  if(nameiparent){
    80003dd2:	f20b03e3          	beqz	s6,80003cf8 <namex+0x6a>
    iput(ip);
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	ae2080e7          	jalr	-1310(ra) # 800038ba <iput>
    return 0;
    80003de0:	4981                	li	s3,0
    80003de2:	bf19                	j	80003cf8 <namex+0x6a>
  if(*path == 0)
    80003de4:	d7fd                	beqz	a5,80003dd2 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003de6:	0004c783          	lbu	a5,0(s1)
    80003dea:	85a6                	mv	a1,s1
    80003dec:	b7d1                	j	80003db0 <namex+0x122>

0000000080003dee <dirlink>:
{
    80003dee:	7139                	addi	sp,sp,-64
    80003df0:	fc06                	sd	ra,56(sp)
    80003df2:	f822                	sd	s0,48(sp)
    80003df4:	f426                	sd	s1,40(sp)
    80003df6:	f04a                	sd	s2,32(sp)
    80003df8:	ec4e                	sd	s3,24(sp)
    80003dfa:	e852                	sd	s4,16(sp)
    80003dfc:	0080                	addi	s0,sp,64
    80003dfe:	892a                	mv	s2,a0
    80003e00:	8a2e                	mv	s4,a1
    80003e02:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e04:	4601                	li	a2,0
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	dd8080e7          	jalr	-552(ra) # 80003bde <dirlookup>
    80003e0e:	e93d                	bnez	a0,80003e84 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e10:	04c92483          	lw	s1,76(s2)
    80003e14:	c49d                	beqz	s1,80003e42 <dirlink+0x54>
    80003e16:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e18:	4741                	li	a4,16
    80003e1a:	86a6                	mv	a3,s1
    80003e1c:	fc040613          	addi	a2,s0,-64
    80003e20:	4581                	li	a1,0
    80003e22:	854a                	mv	a0,s2
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	b90080e7          	jalr	-1136(ra) # 800039b4 <readi>
    80003e2c:	47c1                	li	a5,16
    80003e2e:	06f51163          	bne	a0,a5,80003e90 <dirlink+0xa2>
    if(de.inum == 0)
    80003e32:	fc045783          	lhu	a5,-64(s0)
    80003e36:	c791                	beqz	a5,80003e42 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e38:	24c1                	addiw	s1,s1,16
    80003e3a:	04c92783          	lw	a5,76(s2)
    80003e3e:	fcf4ede3          	bltu	s1,a5,80003e18 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e42:	4639                	li	a2,14
    80003e44:	85d2                	mv	a1,s4
    80003e46:	fc240513          	addi	a0,s0,-62
    80003e4a:	ffffd097          	auipc	ra,0xffffd
    80003e4e:	fda080e7          	jalr	-38(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003e52:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e56:	4741                	li	a4,16
    80003e58:	86a6                	mv	a3,s1
    80003e5a:	fc040613          	addi	a2,s0,-64
    80003e5e:	4581                	li	a1,0
    80003e60:	854a                	mv	a0,s2
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	c48080e7          	jalr	-952(ra) # 80003aaa <writei>
    80003e6a:	872a                	mv	a4,a0
    80003e6c:	47c1                	li	a5,16
  return 0;
    80003e6e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e70:	02f71863          	bne	a4,a5,80003ea0 <dirlink+0xb2>
}
    80003e74:	70e2                	ld	ra,56(sp)
    80003e76:	7442                	ld	s0,48(sp)
    80003e78:	74a2                	ld	s1,40(sp)
    80003e7a:	7902                	ld	s2,32(sp)
    80003e7c:	69e2                	ld	s3,24(sp)
    80003e7e:	6a42                	ld	s4,16(sp)
    80003e80:	6121                	addi	sp,sp,64
    80003e82:	8082                	ret
    iput(ip);
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	a36080e7          	jalr	-1482(ra) # 800038ba <iput>
    return -1;
    80003e8c:	557d                	li	a0,-1
    80003e8e:	b7dd                	j	80003e74 <dirlink+0x86>
      panic("dirlink read");
    80003e90:	00004517          	auipc	a0,0x4
    80003e94:	7b850513          	addi	a0,a0,1976 # 80008648 <syscalls+0x1c8>
    80003e98:	ffffc097          	auipc	ra,0xffffc
    80003e9c:	6b0080e7          	jalr	1712(ra) # 80000548 <panic>
    panic("dirlink");
    80003ea0:	00005517          	auipc	a0,0x5
    80003ea4:	8c850513          	addi	a0,a0,-1848 # 80008768 <syscalls+0x2e8>
    80003ea8:	ffffc097          	auipc	ra,0xffffc
    80003eac:	6a0080e7          	jalr	1696(ra) # 80000548 <panic>

0000000080003eb0 <namei>:

struct inode*
namei(char *path)
{
    80003eb0:	1101                	addi	sp,sp,-32
    80003eb2:	ec06                	sd	ra,24(sp)
    80003eb4:	e822                	sd	s0,16(sp)
    80003eb6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003eb8:	fe040613          	addi	a2,s0,-32
    80003ebc:	4581                	li	a1,0
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	dd0080e7          	jalr	-560(ra) # 80003c8e <namex>
}
    80003ec6:	60e2                	ld	ra,24(sp)
    80003ec8:	6442                	ld	s0,16(sp)
    80003eca:	6105                	addi	sp,sp,32
    80003ecc:	8082                	ret

0000000080003ece <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ece:	1141                	addi	sp,sp,-16
    80003ed0:	e406                	sd	ra,8(sp)
    80003ed2:	e022                	sd	s0,0(sp)
    80003ed4:	0800                	addi	s0,sp,16
    80003ed6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ed8:	4585                	li	a1,1
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	db4080e7          	jalr	-588(ra) # 80003c8e <namex>
}
    80003ee2:	60a2                	ld	ra,8(sp)
    80003ee4:	6402                	ld	s0,0(sp)
    80003ee6:	0141                	addi	sp,sp,16
    80003ee8:	8082                	ret

0000000080003eea <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003eea:	1101                	addi	sp,sp,-32
    80003eec:	ec06                	sd	ra,24(sp)
    80003eee:	e822                	sd	s0,16(sp)
    80003ef0:	e426                	sd	s1,8(sp)
    80003ef2:	e04a                	sd	s2,0(sp)
    80003ef4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ef6:	0001e917          	auipc	s2,0x1e
    80003efa:	a1290913          	addi	s2,s2,-1518 # 80021908 <log>
    80003efe:	01892583          	lw	a1,24(s2)
    80003f02:	02892503          	lw	a0,40(s2)
    80003f06:	fffff097          	auipc	ra,0xfffff
    80003f0a:	ff8080e7          	jalr	-8(ra) # 80002efe <bread>
    80003f0e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f10:	02c92683          	lw	a3,44(s2)
    80003f14:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f16:	02d05763          	blez	a3,80003f44 <write_head+0x5a>
    80003f1a:	0001e797          	auipc	a5,0x1e
    80003f1e:	a1e78793          	addi	a5,a5,-1506 # 80021938 <log+0x30>
    80003f22:	05c50713          	addi	a4,a0,92
    80003f26:	36fd                	addiw	a3,a3,-1
    80003f28:	1682                	slli	a3,a3,0x20
    80003f2a:	9281                	srli	a3,a3,0x20
    80003f2c:	068a                	slli	a3,a3,0x2
    80003f2e:	0001e617          	auipc	a2,0x1e
    80003f32:	a0e60613          	addi	a2,a2,-1522 # 8002193c <log+0x34>
    80003f36:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f38:	4390                	lw	a2,0(a5)
    80003f3a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f3c:	0791                	addi	a5,a5,4
    80003f3e:	0711                	addi	a4,a4,4
    80003f40:	fed79ce3          	bne	a5,a3,80003f38 <write_head+0x4e>
  }
  bwrite(buf);
    80003f44:	8526                	mv	a0,s1
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	0aa080e7          	jalr	170(ra) # 80002ff0 <bwrite>
  brelse(buf);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	0de080e7          	jalr	222(ra) # 8000302e <brelse>
}
    80003f58:	60e2                	ld	ra,24(sp)
    80003f5a:	6442                	ld	s0,16(sp)
    80003f5c:	64a2                	ld	s1,8(sp)
    80003f5e:	6902                	ld	s2,0(sp)
    80003f60:	6105                	addi	sp,sp,32
    80003f62:	8082                	ret

0000000080003f64 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f64:	0001e797          	auipc	a5,0x1e
    80003f68:	9d07a783          	lw	a5,-1584(a5) # 80021934 <log+0x2c>
    80003f6c:	0af05663          	blez	a5,80004018 <install_trans+0xb4>
{
    80003f70:	7139                	addi	sp,sp,-64
    80003f72:	fc06                	sd	ra,56(sp)
    80003f74:	f822                	sd	s0,48(sp)
    80003f76:	f426                	sd	s1,40(sp)
    80003f78:	f04a                	sd	s2,32(sp)
    80003f7a:	ec4e                	sd	s3,24(sp)
    80003f7c:	e852                	sd	s4,16(sp)
    80003f7e:	e456                	sd	s5,8(sp)
    80003f80:	0080                	addi	s0,sp,64
    80003f82:	0001ea97          	auipc	s5,0x1e
    80003f86:	9b6a8a93          	addi	s5,s5,-1610 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f8a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f8c:	0001e997          	auipc	s3,0x1e
    80003f90:	97c98993          	addi	s3,s3,-1668 # 80021908 <log>
    80003f94:	0189a583          	lw	a1,24(s3)
    80003f98:	014585bb          	addw	a1,a1,s4
    80003f9c:	2585                	addiw	a1,a1,1
    80003f9e:	0289a503          	lw	a0,40(s3)
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	f5c080e7          	jalr	-164(ra) # 80002efe <bread>
    80003faa:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fac:	000aa583          	lw	a1,0(s5)
    80003fb0:	0289a503          	lw	a0,40(s3)
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	f4a080e7          	jalr	-182(ra) # 80002efe <bread>
    80003fbc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fbe:	40000613          	li	a2,1024
    80003fc2:	05890593          	addi	a1,s2,88
    80003fc6:	05850513          	addi	a0,a0,88
    80003fca:	ffffd097          	auipc	ra,0xffffd
    80003fce:	da2080e7          	jalr	-606(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fd2:	8526                	mv	a0,s1
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	01c080e7          	jalr	28(ra) # 80002ff0 <bwrite>
    bunpin(dbuf);
    80003fdc:	8526                	mv	a0,s1
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	12a080e7          	jalr	298(ra) # 80003108 <bunpin>
    brelse(lbuf);
    80003fe6:	854a                	mv	a0,s2
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	046080e7          	jalr	70(ra) # 8000302e <brelse>
    brelse(dbuf);
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	03c080e7          	jalr	60(ra) # 8000302e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ffa:	2a05                	addiw	s4,s4,1
    80003ffc:	0a91                	addi	s5,s5,4
    80003ffe:	02c9a783          	lw	a5,44(s3)
    80004002:	f8fa49e3          	blt	s4,a5,80003f94 <install_trans+0x30>
}
    80004006:	70e2                	ld	ra,56(sp)
    80004008:	7442                	ld	s0,48(sp)
    8000400a:	74a2                	ld	s1,40(sp)
    8000400c:	7902                	ld	s2,32(sp)
    8000400e:	69e2                	ld	s3,24(sp)
    80004010:	6a42                	ld	s4,16(sp)
    80004012:	6aa2                	ld	s5,8(sp)
    80004014:	6121                	addi	sp,sp,64
    80004016:	8082                	ret
    80004018:	8082                	ret

000000008000401a <initlog>:
{
    8000401a:	7179                	addi	sp,sp,-48
    8000401c:	f406                	sd	ra,40(sp)
    8000401e:	f022                	sd	s0,32(sp)
    80004020:	ec26                	sd	s1,24(sp)
    80004022:	e84a                	sd	s2,16(sp)
    80004024:	e44e                	sd	s3,8(sp)
    80004026:	1800                	addi	s0,sp,48
    80004028:	892a                	mv	s2,a0
    8000402a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000402c:	0001e497          	auipc	s1,0x1e
    80004030:	8dc48493          	addi	s1,s1,-1828 # 80021908 <log>
    80004034:	00004597          	auipc	a1,0x4
    80004038:	62458593          	addi	a1,a1,1572 # 80008658 <syscalls+0x1d8>
    8000403c:	8526                	mv	a0,s1
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	b42080e7          	jalr	-1214(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004046:	0149a583          	lw	a1,20(s3)
    8000404a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000404c:	0109a783          	lw	a5,16(s3)
    80004050:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004052:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004056:	854a                	mv	a0,s2
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	ea6080e7          	jalr	-346(ra) # 80002efe <bread>
  log.lh.n = lh->n;
    80004060:	4d3c                	lw	a5,88(a0)
    80004062:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004064:	02f05563          	blez	a5,8000408e <initlog+0x74>
    80004068:	05c50713          	addi	a4,a0,92
    8000406c:	0001e697          	auipc	a3,0x1e
    80004070:	8cc68693          	addi	a3,a3,-1844 # 80021938 <log+0x30>
    80004074:	37fd                	addiw	a5,a5,-1
    80004076:	1782                	slli	a5,a5,0x20
    80004078:	9381                	srli	a5,a5,0x20
    8000407a:	078a                	slli	a5,a5,0x2
    8000407c:	06050613          	addi	a2,a0,96
    80004080:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004082:	4310                	lw	a2,0(a4)
    80004084:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004086:	0711                	addi	a4,a4,4
    80004088:	0691                	addi	a3,a3,4
    8000408a:	fef71ce3          	bne	a4,a5,80004082 <initlog+0x68>
  brelse(buf);
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	fa0080e7          	jalr	-96(ra) # 8000302e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	ece080e7          	jalr	-306(ra) # 80003f64 <install_trans>
  log.lh.n = 0;
    8000409e:	0001e797          	auipc	a5,0x1e
    800040a2:	8807ab23          	sw	zero,-1898(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	e44080e7          	jalr	-444(ra) # 80003eea <write_head>
}
    800040ae:	70a2                	ld	ra,40(sp)
    800040b0:	7402                	ld	s0,32(sp)
    800040b2:	64e2                	ld	s1,24(sp)
    800040b4:	6942                	ld	s2,16(sp)
    800040b6:	69a2                	ld	s3,8(sp)
    800040b8:	6145                	addi	sp,sp,48
    800040ba:	8082                	ret

00000000800040bc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040bc:	1101                	addi	sp,sp,-32
    800040be:	ec06                	sd	ra,24(sp)
    800040c0:	e822                	sd	s0,16(sp)
    800040c2:	e426                	sd	s1,8(sp)
    800040c4:	e04a                	sd	s2,0(sp)
    800040c6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040c8:	0001e517          	auipc	a0,0x1e
    800040cc:	84050513          	addi	a0,a0,-1984 # 80021908 <log>
    800040d0:	ffffd097          	auipc	ra,0xffffd
    800040d4:	b40080e7          	jalr	-1216(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    800040d8:	0001e497          	auipc	s1,0x1e
    800040dc:	83048493          	addi	s1,s1,-2000 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040e0:	4979                	li	s2,30
    800040e2:	a039                	j	800040f0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040e4:	85a6                	mv	a1,s1
    800040e6:	8526                	mv	a0,s1
    800040e8:	ffffe097          	auipc	ra,0xffffe
    800040ec:	1f8080e7          	jalr	504(ra) # 800022e0 <sleep>
    if(log.committing){
    800040f0:	50dc                	lw	a5,36(s1)
    800040f2:	fbed                	bnez	a5,800040e4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040f4:	509c                	lw	a5,32(s1)
    800040f6:	0017871b          	addiw	a4,a5,1
    800040fa:	0007069b          	sext.w	a3,a4
    800040fe:	0027179b          	slliw	a5,a4,0x2
    80004102:	9fb9                	addw	a5,a5,a4
    80004104:	0017979b          	slliw	a5,a5,0x1
    80004108:	54d8                	lw	a4,44(s1)
    8000410a:	9fb9                	addw	a5,a5,a4
    8000410c:	00f95963          	bge	s2,a5,8000411e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004110:	85a6                	mv	a1,s1
    80004112:	8526                	mv	a0,s1
    80004114:	ffffe097          	auipc	ra,0xffffe
    80004118:	1cc080e7          	jalr	460(ra) # 800022e0 <sleep>
    8000411c:	bfd1                	j	800040f0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000411e:	0001d517          	auipc	a0,0x1d
    80004122:	7ea50513          	addi	a0,a0,2026 # 80021908 <log>
    80004126:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004128:	ffffd097          	auipc	ra,0xffffd
    8000412c:	b9c080e7          	jalr	-1124(ra) # 80000cc4 <release>
      break;
    }
  }
}
    80004130:	60e2                	ld	ra,24(sp)
    80004132:	6442                	ld	s0,16(sp)
    80004134:	64a2                	ld	s1,8(sp)
    80004136:	6902                	ld	s2,0(sp)
    80004138:	6105                	addi	sp,sp,32
    8000413a:	8082                	ret

000000008000413c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000413c:	7139                	addi	sp,sp,-64
    8000413e:	fc06                	sd	ra,56(sp)
    80004140:	f822                	sd	s0,48(sp)
    80004142:	f426                	sd	s1,40(sp)
    80004144:	f04a                	sd	s2,32(sp)
    80004146:	ec4e                	sd	s3,24(sp)
    80004148:	e852                	sd	s4,16(sp)
    8000414a:	e456                	sd	s5,8(sp)
    8000414c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000414e:	0001d497          	auipc	s1,0x1d
    80004152:	7ba48493          	addi	s1,s1,1978 # 80021908 <log>
    80004156:	8526                	mv	a0,s1
    80004158:	ffffd097          	auipc	ra,0xffffd
    8000415c:	ab8080e7          	jalr	-1352(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    80004160:	509c                	lw	a5,32(s1)
    80004162:	37fd                	addiw	a5,a5,-1
    80004164:	0007891b          	sext.w	s2,a5
    80004168:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000416a:	50dc                	lw	a5,36(s1)
    8000416c:	efb9                	bnez	a5,800041ca <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000416e:	06091663          	bnez	s2,800041da <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004172:	0001d497          	auipc	s1,0x1d
    80004176:	79648493          	addi	s1,s1,1942 # 80021908 <log>
    8000417a:	4785                	li	a5,1
    8000417c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000417e:	8526                	mv	a0,s1
    80004180:	ffffd097          	auipc	ra,0xffffd
    80004184:	b44080e7          	jalr	-1212(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004188:	54dc                	lw	a5,44(s1)
    8000418a:	06f04763          	bgtz	a5,800041f8 <end_op+0xbc>
    acquire(&log.lock);
    8000418e:	0001d497          	auipc	s1,0x1d
    80004192:	77a48493          	addi	s1,s1,1914 # 80021908 <log>
    80004196:	8526                	mv	a0,s1
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	a78080e7          	jalr	-1416(ra) # 80000c10 <acquire>
    log.committing = 0;
    800041a0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041a4:	8526                	mv	a0,s1
    800041a6:	ffffe097          	auipc	ra,0xffffe
    800041aa:	2c0080e7          	jalr	704(ra) # 80002466 <wakeup>
    release(&log.lock);
    800041ae:	8526                	mv	a0,s1
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	b14080e7          	jalr	-1260(ra) # 80000cc4 <release>
}
    800041b8:	70e2                	ld	ra,56(sp)
    800041ba:	7442                	ld	s0,48(sp)
    800041bc:	74a2                	ld	s1,40(sp)
    800041be:	7902                	ld	s2,32(sp)
    800041c0:	69e2                	ld	s3,24(sp)
    800041c2:	6a42                	ld	s4,16(sp)
    800041c4:	6aa2                	ld	s5,8(sp)
    800041c6:	6121                	addi	sp,sp,64
    800041c8:	8082                	ret
    panic("log.committing");
    800041ca:	00004517          	auipc	a0,0x4
    800041ce:	49650513          	addi	a0,a0,1174 # 80008660 <syscalls+0x1e0>
    800041d2:	ffffc097          	auipc	ra,0xffffc
    800041d6:	376080e7          	jalr	886(ra) # 80000548 <panic>
    wakeup(&log);
    800041da:	0001d497          	auipc	s1,0x1d
    800041de:	72e48493          	addi	s1,s1,1838 # 80021908 <log>
    800041e2:	8526                	mv	a0,s1
    800041e4:	ffffe097          	auipc	ra,0xffffe
    800041e8:	282080e7          	jalr	642(ra) # 80002466 <wakeup>
  release(&log.lock);
    800041ec:	8526                	mv	a0,s1
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	ad6080e7          	jalr	-1322(ra) # 80000cc4 <release>
  if(do_commit){
    800041f6:	b7c9                	j	800041b8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f8:	0001da97          	auipc	s5,0x1d
    800041fc:	740a8a93          	addi	s5,s5,1856 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004200:	0001da17          	auipc	s4,0x1d
    80004204:	708a0a13          	addi	s4,s4,1800 # 80021908 <log>
    80004208:	018a2583          	lw	a1,24(s4)
    8000420c:	012585bb          	addw	a1,a1,s2
    80004210:	2585                	addiw	a1,a1,1
    80004212:	028a2503          	lw	a0,40(s4)
    80004216:	fffff097          	auipc	ra,0xfffff
    8000421a:	ce8080e7          	jalr	-792(ra) # 80002efe <bread>
    8000421e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004220:	000aa583          	lw	a1,0(s5)
    80004224:	028a2503          	lw	a0,40(s4)
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	cd6080e7          	jalr	-810(ra) # 80002efe <bread>
    80004230:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004232:	40000613          	li	a2,1024
    80004236:	05850593          	addi	a1,a0,88
    8000423a:	05848513          	addi	a0,s1,88
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	b2e080e7          	jalr	-1234(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004246:	8526                	mv	a0,s1
    80004248:	fffff097          	auipc	ra,0xfffff
    8000424c:	da8080e7          	jalr	-600(ra) # 80002ff0 <bwrite>
    brelse(from);
    80004250:	854e                	mv	a0,s3
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	ddc080e7          	jalr	-548(ra) # 8000302e <brelse>
    brelse(to);
    8000425a:	8526                	mv	a0,s1
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	dd2080e7          	jalr	-558(ra) # 8000302e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004264:	2905                	addiw	s2,s2,1
    80004266:	0a91                	addi	s5,s5,4
    80004268:	02ca2783          	lw	a5,44(s4)
    8000426c:	f8f94ee3          	blt	s2,a5,80004208 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004270:	00000097          	auipc	ra,0x0
    80004274:	c7a080e7          	jalr	-902(ra) # 80003eea <write_head>
    install_trans(); // Now install writes to home locations
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	cec080e7          	jalr	-788(ra) # 80003f64 <install_trans>
    log.lh.n = 0;
    80004280:	0001d797          	auipc	a5,0x1d
    80004284:	6a07aa23          	sw	zero,1716(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004288:	00000097          	auipc	ra,0x0
    8000428c:	c62080e7          	jalr	-926(ra) # 80003eea <write_head>
    80004290:	bdfd                	j	8000418e <end_op+0x52>

0000000080004292 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004292:	1101                	addi	sp,sp,-32
    80004294:	ec06                	sd	ra,24(sp)
    80004296:	e822                	sd	s0,16(sp)
    80004298:	e426                	sd	s1,8(sp)
    8000429a:	e04a                	sd	s2,0(sp)
    8000429c:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000429e:	0001d717          	auipc	a4,0x1d
    800042a2:	69672703          	lw	a4,1686(a4) # 80021934 <log+0x2c>
    800042a6:	47f5                	li	a5,29
    800042a8:	08e7c063          	blt	a5,a4,80004328 <log_write+0x96>
    800042ac:	84aa                	mv	s1,a0
    800042ae:	0001d797          	auipc	a5,0x1d
    800042b2:	6767a783          	lw	a5,1654(a5) # 80021924 <log+0x1c>
    800042b6:	37fd                	addiw	a5,a5,-1
    800042b8:	06f75863          	bge	a4,a5,80004328 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042bc:	0001d797          	auipc	a5,0x1d
    800042c0:	66c7a783          	lw	a5,1644(a5) # 80021928 <log+0x20>
    800042c4:	06f05a63          	blez	a5,80004338 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800042c8:	0001d917          	auipc	s2,0x1d
    800042cc:	64090913          	addi	s2,s2,1600 # 80021908 <log>
    800042d0:	854a                	mv	a0,s2
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	93e080e7          	jalr	-1730(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800042da:	02c92603          	lw	a2,44(s2)
    800042de:	06c05563          	blez	a2,80004348 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042e2:	44cc                	lw	a1,12(s1)
    800042e4:	0001d717          	auipc	a4,0x1d
    800042e8:	65470713          	addi	a4,a4,1620 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042ec:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042ee:	4314                	lw	a3,0(a4)
    800042f0:	04b68d63          	beq	a3,a1,8000434a <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800042f4:	2785                	addiw	a5,a5,1
    800042f6:	0711                	addi	a4,a4,4
    800042f8:	fec79be3          	bne	a5,a2,800042ee <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042fc:	0621                	addi	a2,a2,8
    800042fe:	060a                	slli	a2,a2,0x2
    80004300:	0001d797          	auipc	a5,0x1d
    80004304:	60878793          	addi	a5,a5,1544 # 80021908 <log>
    80004308:	963e                	add	a2,a2,a5
    8000430a:	44dc                	lw	a5,12(s1)
    8000430c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000430e:	8526                	mv	a0,s1
    80004310:	fffff097          	auipc	ra,0xfffff
    80004314:	dbc080e7          	jalr	-580(ra) # 800030cc <bpin>
    log.lh.n++;
    80004318:	0001d717          	auipc	a4,0x1d
    8000431c:	5f070713          	addi	a4,a4,1520 # 80021908 <log>
    80004320:	575c                	lw	a5,44(a4)
    80004322:	2785                	addiw	a5,a5,1
    80004324:	d75c                	sw	a5,44(a4)
    80004326:	a83d                	j	80004364 <log_write+0xd2>
    panic("too big a transaction");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	34850513          	addi	a0,a0,840 # 80008670 <syscalls+0x1f0>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	218080e7          	jalr	536(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004338:	00004517          	auipc	a0,0x4
    8000433c:	35050513          	addi	a0,a0,848 # 80008688 <syscalls+0x208>
    80004340:	ffffc097          	auipc	ra,0xffffc
    80004344:	208080e7          	jalr	520(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004348:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000434a:	00878713          	addi	a4,a5,8
    8000434e:	00271693          	slli	a3,a4,0x2
    80004352:	0001d717          	auipc	a4,0x1d
    80004356:	5b670713          	addi	a4,a4,1462 # 80021908 <log>
    8000435a:	9736                	add	a4,a4,a3
    8000435c:	44d4                	lw	a3,12(s1)
    8000435e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004360:	faf607e3          	beq	a2,a5,8000430e <log_write+0x7c>
  }
  release(&log.lock);
    80004364:	0001d517          	auipc	a0,0x1d
    80004368:	5a450513          	addi	a0,a0,1444 # 80021908 <log>
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	958080e7          	jalr	-1704(ra) # 80000cc4 <release>
}
    80004374:	60e2                	ld	ra,24(sp)
    80004376:	6442                	ld	s0,16(sp)
    80004378:	64a2                	ld	s1,8(sp)
    8000437a:	6902                	ld	s2,0(sp)
    8000437c:	6105                	addi	sp,sp,32
    8000437e:	8082                	ret

0000000080004380 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004380:	1101                	addi	sp,sp,-32
    80004382:	ec06                	sd	ra,24(sp)
    80004384:	e822                	sd	s0,16(sp)
    80004386:	e426                	sd	s1,8(sp)
    80004388:	e04a                	sd	s2,0(sp)
    8000438a:	1000                	addi	s0,sp,32
    8000438c:	84aa                	mv	s1,a0
    8000438e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004390:	00004597          	auipc	a1,0x4
    80004394:	31858593          	addi	a1,a1,792 # 800086a8 <syscalls+0x228>
    80004398:	0521                	addi	a0,a0,8
    8000439a:	ffffc097          	auipc	ra,0xffffc
    8000439e:	7e6080e7          	jalr	2022(ra) # 80000b80 <initlock>
  lk->name = name;
    800043a2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043aa:	0204a423          	sw	zero,40(s1)
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	64a2                	ld	s1,8(sp)
    800043b4:	6902                	ld	s2,0(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret

00000000800043ba <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043ba:	1101                	addi	sp,sp,-32
    800043bc:	ec06                	sd	ra,24(sp)
    800043be:	e822                	sd	s0,16(sp)
    800043c0:	e426                	sd	s1,8(sp)
    800043c2:	e04a                	sd	s2,0(sp)
    800043c4:	1000                	addi	s0,sp,32
    800043c6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043c8:	00850913          	addi	s2,a0,8
    800043cc:	854a                	mv	a0,s2
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	842080e7          	jalr	-1982(ra) # 80000c10 <acquire>
  while (lk->locked) {
    800043d6:	409c                	lw	a5,0(s1)
    800043d8:	cb89                	beqz	a5,800043ea <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043da:	85ca                	mv	a1,s2
    800043dc:	8526                	mv	a0,s1
    800043de:	ffffe097          	auipc	ra,0xffffe
    800043e2:	f02080e7          	jalr	-254(ra) # 800022e0 <sleep>
  while (lk->locked) {
    800043e6:	409c                	lw	a5,0(s1)
    800043e8:	fbed                	bnez	a5,800043da <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043ea:	4785                	li	a5,1
    800043ec:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	6e6080e7          	jalr	1766(ra) # 80001ad4 <myproc>
    800043f6:	5d1c                	lw	a5,56(a0)
    800043f8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043fa:	854a                	mv	a0,s2
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	8c8080e7          	jalr	-1848(ra) # 80000cc4 <release>
}
    80004404:	60e2                	ld	ra,24(sp)
    80004406:	6442                	ld	s0,16(sp)
    80004408:	64a2                	ld	s1,8(sp)
    8000440a:	6902                	ld	s2,0(sp)
    8000440c:	6105                	addi	sp,sp,32
    8000440e:	8082                	ret

0000000080004410 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004410:	1101                	addi	sp,sp,-32
    80004412:	ec06                	sd	ra,24(sp)
    80004414:	e822                	sd	s0,16(sp)
    80004416:	e426                	sd	s1,8(sp)
    80004418:	e04a                	sd	s2,0(sp)
    8000441a:	1000                	addi	s0,sp,32
    8000441c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000441e:	00850913          	addi	s2,a0,8
    80004422:	854a                	mv	a0,s2
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	7ec080e7          	jalr	2028(ra) # 80000c10 <acquire>
  lk->locked = 0;
    8000442c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004430:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004434:	8526                	mv	a0,s1
    80004436:	ffffe097          	auipc	ra,0xffffe
    8000443a:	030080e7          	jalr	48(ra) # 80002466 <wakeup>
  release(&lk->lk);
    8000443e:	854a                	mv	a0,s2
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	884080e7          	jalr	-1916(ra) # 80000cc4 <release>
}
    80004448:	60e2                	ld	ra,24(sp)
    8000444a:	6442                	ld	s0,16(sp)
    8000444c:	64a2                	ld	s1,8(sp)
    8000444e:	6902                	ld	s2,0(sp)
    80004450:	6105                	addi	sp,sp,32
    80004452:	8082                	ret

0000000080004454 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004454:	7179                	addi	sp,sp,-48
    80004456:	f406                	sd	ra,40(sp)
    80004458:	f022                	sd	s0,32(sp)
    8000445a:	ec26                	sd	s1,24(sp)
    8000445c:	e84a                	sd	s2,16(sp)
    8000445e:	e44e                	sd	s3,8(sp)
    80004460:	1800                	addi	s0,sp,48
    80004462:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004464:	00850913          	addi	s2,a0,8
    80004468:	854a                	mv	a0,s2
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	7a6080e7          	jalr	1958(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004472:	409c                	lw	a5,0(s1)
    80004474:	ef99                	bnez	a5,80004492 <holdingsleep+0x3e>
    80004476:	4481                	li	s1,0
  release(&lk->lk);
    80004478:	854a                	mv	a0,s2
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	84a080e7          	jalr	-1974(ra) # 80000cc4 <release>
  return r;
}
    80004482:	8526                	mv	a0,s1
    80004484:	70a2                	ld	ra,40(sp)
    80004486:	7402                	ld	s0,32(sp)
    80004488:	64e2                	ld	s1,24(sp)
    8000448a:	6942                	ld	s2,16(sp)
    8000448c:	69a2                	ld	s3,8(sp)
    8000448e:	6145                	addi	sp,sp,48
    80004490:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004492:	0284a983          	lw	s3,40(s1)
    80004496:	ffffd097          	auipc	ra,0xffffd
    8000449a:	63e080e7          	jalr	1598(ra) # 80001ad4 <myproc>
    8000449e:	5d04                	lw	s1,56(a0)
    800044a0:	413484b3          	sub	s1,s1,s3
    800044a4:	0014b493          	seqz	s1,s1
    800044a8:	bfc1                	j	80004478 <holdingsleep+0x24>

00000000800044aa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044aa:	1141                	addi	sp,sp,-16
    800044ac:	e406                	sd	ra,8(sp)
    800044ae:	e022                	sd	s0,0(sp)
    800044b0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044b2:	00004597          	auipc	a1,0x4
    800044b6:	20658593          	addi	a1,a1,518 # 800086b8 <syscalls+0x238>
    800044ba:	0001d517          	auipc	a0,0x1d
    800044be:	59650513          	addi	a0,a0,1430 # 80021a50 <ftable>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	6be080e7          	jalr	1726(ra) # 80000b80 <initlock>
}
    800044ca:	60a2                	ld	ra,8(sp)
    800044cc:	6402                	ld	s0,0(sp)
    800044ce:	0141                	addi	sp,sp,16
    800044d0:	8082                	ret

00000000800044d2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044d2:	1101                	addi	sp,sp,-32
    800044d4:	ec06                	sd	ra,24(sp)
    800044d6:	e822                	sd	s0,16(sp)
    800044d8:	e426                	sd	s1,8(sp)
    800044da:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044dc:	0001d517          	auipc	a0,0x1d
    800044e0:	57450513          	addi	a0,a0,1396 # 80021a50 <ftable>
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	72c080e7          	jalr	1836(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ec:	0001d497          	auipc	s1,0x1d
    800044f0:	57c48493          	addi	s1,s1,1404 # 80021a68 <ftable+0x18>
    800044f4:	0001e717          	auipc	a4,0x1e
    800044f8:	51470713          	addi	a4,a4,1300 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    800044fc:	40dc                	lw	a5,4(s1)
    800044fe:	cf99                	beqz	a5,8000451c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004500:	02848493          	addi	s1,s1,40
    80004504:	fee49ce3          	bne	s1,a4,800044fc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004508:	0001d517          	auipc	a0,0x1d
    8000450c:	54850513          	addi	a0,a0,1352 # 80021a50 <ftable>
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	7b4080e7          	jalr	1972(ra) # 80000cc4 <release>
  return 0;
    80004518:	4481                	li	s1,0
    8000451a:	a819                	j	80004530 <filealloc+0x5e>
      f->ref = 1;
    8000451c:	4785                	li	a5,1
    8000451e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004520:	0001d517          	auipc	a0,0x1d
    80004524:	53050513          	addi	a0,a0,1328 # 80021a50 <ftable>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	79c080e7          	jalr	1948(ra) # 80000cc4 <release>
}
    80004530:	8526                	mv	a0,s1
    80004532:	60e2                	ld	ra,24(sp)
    80004534:	6442                	ld	s0,16(sp)
    80004536:	64a2                	ld	s1,8(sp)
    80004538:	6105                	addi	sp,sp,32
    8000453a:	8082                	ret

000000008000453c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000453c:	1101                	addi	sp,sp,-32
    8000453e:	ec06                	sd	ra,24(sp)
    80004540:	e822                	sd	s0,16(sp)
    80004542:	e426                	sd	s1,8(sp)
    80004544:	1000                	addi	s0,sp,32
    80004546:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004548:	0001d517          	auipc	a0,0x1d
    8000454c:	50850513          	addi	a0,a0,1288 # 80021a50 <ftable>
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	6c0080e7          	jalr	1728(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004558:	40dc                	lw	a5,4(s1)
    8000455a:	02f05263          	blez	a5,8000457e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000455e:	2785                	addiw	a5,a5,1
    80004560:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004562:	0001d517          	auipc	a0,0x1d
    80004566:	4ee50513          	addi	a0,a0,1262 # 80021a50 <ftable>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	75a080e7          	jalr	1882(ra) # 80000cc4 <release>
  return f;
}
    80004572:	8526                	mv	a0,s1
    80004574:	60e2                	ld	ra,24(sp)
    80004576:	6442                	ld	s0,16(sp)
    80004578:	64a2                	ld	s1,8(sp)
    8000457a:	6105                	addi	sp,sp,32
    8000457c:	8082                	ret
    panic("filedup");
    8000457e:	00004517          	auipc	a0,0x4
    80004582:	14250513          	addi	a0,a0,322 # 800086c0 <syscalls+0x240>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	fc2080e7          	jalr	-62(ra) # 80000548 <panic>

000000008000458e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000458e:	7139                	addi	sp,sp,-64
    80004590:	fc06                	sd	ra,56(sp)
    80004592:	f822                	sd	s0,48(sp)
    80004594:	f426                	sd	s1,40(sp)
    80004596:	f04a                	sd	s2,32(sp)
    80004598:	ec4e                	sd	s3,24(sp)
    8000459a:	e852                	sd	s4,16(sp)
    8000459c:	e456                	sd	s5,8(sp)
    8000459e:	0080                	addi	s0,sp,64
    800045a0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045a2:	0001d517          	auipc	a0,0x1d
    800045a6:	4ae50513          	addi	a0,a0,1198 # 80021a50 <ftable>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	666080e7          	jalr	1638(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800045b2:	40dc                	lw	a5,4(s1)
    800045b4:	06f05163          	blez	a5,80004616 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045b8:	37fd                	addiw	a5,a5,-1
    800045ba:	0007871b          	sext.w	a4,a5
    800045be:	c0dc                	sw	a5,4(s1)
    800045c0:	06e04363          	bgtz	a4,80004626 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045c4:	0004a903          	lw	s2,0(s1)
    800045c8:	0094ca83          	lbu	s5,9(s1)
    800045cc:	0104ba03          	ld	s4,16(s1)
    800045d0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045d4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045d8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045dc:	0001d517          	auipc	a0,0x1d
    800045e0:	47450513          	addi	a0,a0,1140 # 80021a50 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	6e0080e7          	jalr	1760(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    800045ec:	4785                	li	a5,1
    800045ee:	04f90d63          	beq	s2,a5,80004648 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045f2:	3979                	addiw	s2,s2,-2
    800045f4:	4785                	li	a5,1
    800045f6:	0527e063          	bltu	a5,s2,80004636 <fileclose+0xa8>
    begin_op();
    800045fa:	00000097          	auipc	ra,0x0
    800045fe:	ac2080e7          	jalr	-1342(ra) # 800040bc <begin_op>
    iput(ff.ip);
    80004602:	854e                	mv	a0,s3
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	2b6080e7          	jalr	694(ra) # 800038ba <iput>
    end_op();
    8000460c:	00000097          	auipc	ra,0x0
    80004610:	b30080e7          	jalr	-1232(ra) # 8000413c <end_op>
    80004614:	a00d                	j	80004636 <fileclose+0xa8>
    panic("fileclose");
    80004616:	00004517          	auipc	a0,0x4
    8000461a:	0b250513          	addi	a0,a0,178 # 800086c8 <syscalls+0x248>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	f2a080e7          	jalr	-214(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004626:	0001d517          	auipc	a0,0x1d
    8000462a:	42a50513          	addi	a0,a0,1066 # 80021a50 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	696080e7          	jalr	1686(ra) # 80000cc4 <release>
  }
}
    80004636:	70e2                	ld	ra,56(sp)
    80004638:	7442                	ld	s0,48(sp)
    8000463a:	74a2                	ld	s1,40(sp)
    8000463c:	7902                	ld	s2,32(sp)
    8000463e:	69e2                	ld	s3,24(sp)
    80004640:	6a42                	ld	s4,16(sp)
    80004642:	6aa2                	ld	s5,8(sp)
    80004644:	6121                	addi	sp,sp,64
    80004646:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004648:	85d6                	mv	a1,s5
    8000464a:	8552                	mv	a0,s4
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	372080e7          	jalr	882(ra) # 800049be <pipeclose>
    80004654:	b7cd                	j	80004636 <fileclose+0xa8>

0000000080004656 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004656:	715d                	addi	sp,sp,-80
    80004658:	e486                	sd	ra,72(sp)
    8000465a:	e0a2                	sd	s0,64(sp)
    8000465c:	fc26                	sd	s1,56(sp)
    8000465e:	f84a                	sd	s2,48(sp)
    80004660:	f44e                	sd	s3,40(sp)
    80004662:	0880                	addi	s0,sp,80
    80004664:	84aa                	mv	s1,a0
    80004666:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004668:	ffffd097          	auipc	ra,0xffffd
    8000466c:	46c080e7          	jalr	1132(ra) # 80001ad4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004670:	409c                	lw	a5,0(s1)
    80004672:	37f9                	addiw	a5,a5,-2
    80004674:	4705                	li	a4,1
    80004676:	04f76763          	bltu	a4,a5,800046c4 <filestat+0x6e>
    8000467a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000467c:	6c88                	ld	a0,24(s1)
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	082080e7          	jalr	130(ra) # 80003700 <ilock>
    stati(f->ip, &st);
    80004686:	fb840593          	addi	a1,s0,-72
    8000468a:	6c88                	ld	a0,24(s1)
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	2fe080e7          	jalr	766(ra) # 8000398a <stati>
    iunlock(f->ip);
    80004694:	6c88                	ld	a0,24(s1)
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	12c080e7          	jalr	300(ra) # 800037c2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000469e:	46e1                	li	a3,24
    800046a0:	fb840613          	addi	a2,s0,-72
    800046a4:	85ce                	mv	a1,s3
    800046a6:	05093503          	ld	a0,80(s2)
    800046aa:	ffffd097          	auipc	ra,0xffffd
    800046ae:	030080e7          	jalr	48(ra) # 800016da <copyout>
    800046b2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046b6:	60a6                	ld	ra,72(sp)
    800046b8:	6406                	ld	s0,64(sp)
    800046ba:	74e2                	ld	s1,56(sp)
    800046bc:	7942                	ld	s2,48(sp)
    800046be:	79a2                	ld	s3,40(sp)
    800046c0:	6161                	addi	sp,sp,80
    800046c2:	8082                	ret
  return -1;
    800046c4:	557d                	li	a0,-1
    800046c6:	bfc5                	j	800046b6 <filestat+0x60>

00000000800046c8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046c8:	7179                	addi	sp,sp,-48
    800046ca:	f406                	sd	ra,40(sp)
    800046cc:	f022                	sd	s0,32(sp)
    800046ce:	ec26                	sd	s1,24(sp)
    800046d0:	e84a                	sd	s2,16(sp)
    800046d2:	e44e                	sd	s3,8(sp)
    800046d4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046d6:	00854783          	lbu	a5,8(a0)
    800046da:	c3d5                	beqz	a5,8000477e <fileread+0xb6>
    800046dc:	84aa                	mv	s1,a0
    800046de:	89ae                	mv	s3,a1
    800046e0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046e2:	411c                	lw	a5,0(a0)
    800046e4:	4705                	li	a4,1
    800046e6:	04e78963          	beq	a5,a4,80004738 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046ea:	470d                	li	a4,3
    800046ec:	04e78d63          	beq	a5,a4,80004746 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046f0:	4709                	li	a4,2
    800046f2:	06e79e63          	bne	a5,a4,8000476e <fileread+0xa6>
    ilock(f->ip);
    800046f6:	6d08                	ld	a0,24(a0)
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	008080e7          	jalr	8(ra) # 80003700 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004700:	874a                	mv	a4,s2
    80004702:	5094                	lw	a3,32(s1)
    80004704:	864e                	mv	a2,s3
    80004706:	4585                	li	a1,1
    80004708:	6c88                	ld	a0,24(s1)
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	2aa080e7          	jalr	682(ra) # 800039b4 <readi>
    80004712:	892a                	mv	s2,a0
    80004714:	00a05563          	blez	a0,8000471e <fileread+0x56>
      f->off += r;
    80004718:	509c                	lw	a5,32(s1)
    8000471a:	9fa9                	addw	a5,a5,a0
    8000471c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000471e:	6c88                	ld	a0,24(s1)
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	0a2080e7          	jalr	162(ra) # 800037c2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004728:	854a                	mv	a0,s2
    8000472a:	70a2                	ld	ra,40(sp)
    8000472c:	7402                	ld	s0,32(sp)
    8000472e:	64e2                	ld	s1,24(sp)
    80004730:	6942                	ld	s2,16(sp)
    80004732:	69a2                	ld	s3,8(sp)
    80004734:	6145                	addi	sp,sp,48
    80004736:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004738:	6908                	ld	a0,16(a0)
    8000473a:	00000097          	auipc	ra,0x0
    8000473e:	418080e7          	jalr	1048(ra) # 80004b52 <piperead>
    80004742:	892a                	mv	s2,a0
    80004744:	b7d5                	j	80004728 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004746:	02451783          	lh	a5,36(a0)
    8000474a:	03079693          	slli	a3,a5,0x30
    8000474e:	92c1                	srli	a3,a3,0x30
    80004750:	4725                	li	a4,9
    80004752:	02d76863          	bltu	a4,a3,80004782 <fileread+0xba>
    80004756:	0792                	slli	a5,a5,0x4
    80004758:	0001d717          	auipc	a4,0x1d
    8000475c:	25870713          	addi	a4,a4,600 # 800219b0 <devsw>
    80004760:	97ba                	add	a5,a5,a4
    80004762:	639c                	ld	a5,0(a5)
    80004764:	c38d                	beqz	a5,80004786 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004766:	4505                	li	a0,1
    80004768:	9782                	jalr	a5
    8000476a:	892a                	mv	s2,a0
    8000476c:	bf75                	j	80004728 <fileread+0x60>
    panic("fileread");
    8000476e:	00004517          	auipc	a0,0x4
    80004772:	f6a50513          	addi	a0,a0,-150 # 800086d8 <syscalls+0x258>
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	dd2080e7          	jalr	-558(ra) # 80000548 <panic>
    return -1;
    8000477e:	597d                	li	s2,-1
    80004780:	b765                	j	80004728 <fileread+0x60>
      return -1;
    80004782:	597d                	li	s2,-1
    80004784:	b755                	j	80004728 <fileread+0x60>
    80004786:	597d                	li	s2,-1
    80004788:	b745                	j	80004728 <fileread+0x60>

000000008000478a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000478a:	00954783          	lbu	a5,9(a0)
    8000478e:	14078563          	beqz	a5,800048d8 <filewrite+0x14e>
{
    80004792:	715d                	addi	sp,sp,-80
    80004794:	e486                	sd	ra,72(sp)
    80004796:	e0a2                	sd	s0,64(sp)
    80004798:	fc26                	sd	s1,56(sp)
    8000479a:	f84a                	sd	s2,48(sp)
    8000479c:	f44e                	sd	s3,40(sp)
    8000479e:	f052                	sd	s4,32(sp)
    800047a0:	ec56                	sd	s5,24(sp)
    800047a2:	e85a                	sd	s6,16(sp)
    800047a4:	e45e                	sd	s7,8(sp)
    800047a6:	e062                	sd	s8,0(sp)
    800047a8:	0880                	addi	s0,sp,80
    800047aa:	892a                	mv	s2,a0
    800047ac:	8aae                	mv	s5,a1
    800047ae:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047b0:	411c                	lw	a5,0(a0)
    800047b2:	4705                	li	a4,1
    800047b4:	02e78263          	beq	a5,a4,800047d8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047b8:	470d                	li	a4,3
    800047ba:	02e78563          	beq	a5,a4,800047e4 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047be:	4709                	li	a4,2
    800047c0:	10e79463          	bne	a5,a4,800048c8 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047c4:	0ec05e63          	blez	a2,800048c0 <filewrite+0x136>
    int i = 0;
    800047c8:	4981                	li	s3,0
    800047ca:	6b05                	lui	s6,0x1
    800047cc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047d0:	6b85                	lui	s7,0x1
    800047d2:	c00b8b9b          	addiw	s7,s7,-1024
    800047d6:	a851                	j	8000486a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047d8:	6908                	ld	a0,16(a0)
    800047da:	00000097          	auipc	ra,0x0
    800047de:	254080e7          	jalr	596(ra) # 80004a2e <pipewrite>
    800047e2:	a85d                	j	80004898 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047e4:	02451783          	lh	a5,36(a0)
    800047e8:	03079693          	slli	a3,a5,0x30
    800047ec:	92c1                	srli	a3,a3,0x30
    800047ee:	4725                	li	a4,9
    800047f0:	0ed76663          	bltu	a4,a3,800048dc <filewrite+0x152>
    800047f4:	0792                	slli	a5,a5,0x4
    800047f6:	0001d717          	auipc	a4,0x1d
    800047fa:	1ba70713          	addi	a4,a4,442 # 800219b0 <devsw>
    800047fe:	97ba                	add	a5,a5,a4
    80004800:	679c                	ld	a5,8(a5)
    80004802:	cff9                	beqz	a5,800048e0 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004804:	4505                	li	a0,1
    80004806:	9782                	jalr	a5
    80004808:	a841                	j	80004898 <filewrite+0x10e>
    8000480a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000480e:	00000097          	auipc	ra,0x0
    80004812:	8ae080e7          	jalr	-1874(ra) # 800040bc <begin_op>
      ilock(f->ip);
    80004816:	01893503          	ld	a0,24(s2)
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	ee6080e7          	jalr	-282(ra) # 80003700 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004822:	8762                	mv	a4,s8
    80004824:	02092683          	lw	a3,32(s2)
    80004828:	01598633          	add	a2,s3,s5
    8000482c:	4585                	li	a1,1
    8000482e:	01893503          	ld	a0,24(s2)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	278080e7          	jalr	632(ra) # 80003aaa <writei>
    8000483a:	84aa                	mv	s1,a0
    8000483c:	02a05f63          	blez	a0,8000487a <filewrite+0xf0>
        f->off += r;
    80004840:	02092783          	lw	a5,32(s2)
    80004844:	9fa9                	addw	a5,a5,a0
    80004846:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000484a:	01893503          	ld	a0,24(s2)
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	f74080e7          	jalr	-140(ra) # 800037c2 <iunlock>
      end_op();
    80004856:	00000097          	auipc	ra,0x0
    8000485a:	8e6080e7          	jalr	-1818(ra) # 8000413c <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000485e:	049c1963          	bne	s8,s1,800048b0 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004862:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004866:	0349d663          	bge	s3,s4,80004892 <filewrite+0x108>
      int n1 = n - i;
    8000486a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000486e:	84be                	mv	s1,a5
    80004870:	2781                	sext.w	a5,a5
    80004872:	f8fb5ce3          	bge	s6,a5,8000480a <filewrite+0x80>
    80004876:	84de                	mv	s1,s7
    80004878:	bf49                	j	8000480a <filewrite+0x80>
      iunlock(f->ip);
    8000487a:	01893503          	ld	a0,24(s2)
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	f44080e7          	jalr	-188(ra) # 800037c2 <iunlock>
      end_op();
    80004886:	00000097          	auipc	ra,0x0
    8000488a:	8b6080e7          	jalr	-1866(ra) # 8000413c <end_op>
      if(r < 0)
    8000488e:	fc04d8e3          	bgez	s1,8000485e <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004892:	8552                	mv	a0,s4
    80004894:	033a1863          	bne	s4,s3,800048c4 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004898:	60a6                	ld	ra,72(sp)
    8000489a:	6406                	ld	s0,64(sp)
    8000489c:	74e2                	ld	s1,56(sp)
    8000489e:	7942                	ld	s2,48(sp)
    800048a0:	79a2                	ld	s3,40(sp)
    800048a2:	7a02                	ld	s4,32(sp)
    800048a4:	6ae2                	ld	s5,24(sp)
    800048a6:	6b42                	ld	s6,16(sp)
    800048a8:	6ba2                	ld	s7,8(sp)
    800048aa:	6c02                	ld	s8,0(sp)
    800048ac:	6161                	addi	sp,sp,80
    800048ae:	8082                	ret
        panic("short filewrite");
    800048b0:	00004517          	auipc	a0,0x4
    800048b4:	e3850513          	addi	a0,a0,-456 # 800086e8 <syscalls+0x268>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	c90080e7          	jalr	-880(ra) # 80000548 <panic>
    int i = 0;
    800048c0:	4981                	li	s3,0
    800048c2:	bfc1                	j	80004892 <filewrite+0x108>
    ret = (i == n ? n : -1);
    800048c4:	557d                	li	a0,-1
    800048c6:	bfc9                	j	80004898 <filewrite+0x10e>
    panic("filewrite");
    800048c8:	00004517          	auipc	a0,0x4
    800048cc:	e3050513          	addi	a0,a0,-464 # 800086f8 <syscalls+0x278>
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	c78080e7          	jalr	-904(ra) # 80000548 <panic>
    return -1;
    800048d8:	557d                	li	a0,-1
}
    800048da:	8082                	ret
      return -1;
    800048dc:	557d                	li	a0,-1
    800048de:	bf6d                	j	80004898 <filewrite+0x10e>
    800048e0:	557d                	li	a0,-1
    800048e2:	bf5d                	j	80004898 <filewrite+0x10e>

00000000800048e4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048e4:	7179                	addi	sp,sp,-48
    800048e6:	f406                	sd	ra,40(sp)
    800048e8:	f022                	sd	s0,32(sp)
    800048ea:	ec26                	sd	s1,24(sp)
    800048ec:	e84a                	sd	s2,16(sp)
    800048ee:	e44e                	sd	s3,8(sp)
    800048f0:	e052                	sd	s4,0(sp)
    800048f2:	1800                	addi	s0,sp,48
    800048f4:	84aa                	mv	s1,a0
    800048f6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048f8:	0005b023          	sd	zero,0(a1)
    800048fc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004900:	00000097          	auipc	ra,0x0
    80004904:	bd2080e7          	jalr	-1070(ra) # 800044d2 <filealloc>
    80004908:	e088                	sd	a0,0(s1)
    8000490a:	c551                	beqz	a0,80004996 <pipealloc+0xb2>
    8000490c:	00000097          	auipc	ra,0x0
    80004910:	bc6080e7          	jalr	-1082(ra) # 800044d2 <filealloc>
    80004914:	00aa3023          	sd	a0,0(s4)
    80004918:	c92d                	beqz	a0,8000498a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	206080e7          	jalr	518(ra) # 80000b20 <kalloc>
    80004922:	892a                	mv	s2,a0
    80004924:	c125                	beqz	a0,80004984 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004926:	4985                	li	s3,1
    80004928:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000492c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004930:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004934:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004938:	00004597          	auipc	a1,0x4
    8000493c:	dd058593          	addi	a1,a1,-560 # 80008708 <syscalls+0x288>
    80004940:	ffffc097          	auipc	ra,0xffffc
    80004944:	240080e7          	jalr	576(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004948:	609c                	ld	a5,0(s1)
    8000494a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000494e:	609c                	ld	a5,0(s1)
    80004950:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004954:	609c                	ld	a5,0(s1)
    80004956:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000495a:	609c                	ld	a5,0(s1)
    8000495c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004960:	000a3783          	ld	a5,0(s4)
    80004964:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004968:	000a3783          	ld	a5,0(s4)
    8000496c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004970:	000a3783          	ld	a5,0(s4)
    80004974:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004978:	000a3783          	ld	a5,0(s4)
    8000497c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004980:	4501                	li	a0,0
    80004982:	a025                	j	800049aa <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004984:	6088                	ld	a0,0(s1)
    80004986:	e501                	bnez	a0,8000498e <pipealloc+0xaa>
    80004988:	a039                	j	80004996 <pipealloc+0xb2>
    8000498a:	6088                	ld	a0,0(s1)
    8000498c:	c51d                	beqz	a0,800049ba <pipealloc+0xd6>
    fileclose(*f0);
    8000498e:	00000097          	auipc	ra,0x0
    80004992:	c00080e7          	jalr	-1024(ra) # 8000458e <fileclose>
  if(*f1)
    80004996:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000499a:	557d                	li	a0,-1
  if(*f1)
    8000499c:	c799                	beqz	a5,800049aa <pipealloc+0xc6>
    fileclose(*f1);
    8000499e:	853e                	mv	a0,a5
    800049a0:	00000097          	auipc	ra,0x0
    800049a4:	bee080e7          	jalr	-1042(ra) # 8000458e <fileclose>
  return -1;
    800049a8:	557d                	li	a0,-1
}
    800049aa:	70a2                	ld	ra,40(sp)
    800049ac:	7402                	ld	s0,32(sp)
    800049ae:	64e2                	ld	s1,24(sp)
    800049b0:	6942                	ld	s2,16(sp)
    800049b2:	69a2                	ld	s3,8(sp)
    800049b4:	6a02                	ld	s4,0(sp)
    800049b6:	6145                	addi	sp,sp,48
    800049b8:	8082                	ret
  return -1;
    800049ba:	557d                	li	a0,-1
    800049bc:	b7fd                	j	800049aa <pipealloc+0xc6>

00000000800049be <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049be:	1101                	addi	sp,sp,-32
    800049c0:	ec06                	sd	ra,24(sp)
    800049c2:	e822                	sd	s0,16(sp)
    800049c4:	e426                	sd	s1,8(sp)
    800049c6:	e04a                	sd	s2,0(sp)
    800049c8:	1000                	addi	s0,sp,32
    800049ca:	84aa                	mv	s1,a0
    800049cc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	242080e7          	jalr	578(ra) # 80000c10 <acquire>
  if(writable){
    800049d6:	02090d63          	beqz	s2,80004a10 <pipeclose+0x52>
    pi->writeopen = 0;
    800049da:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049de:	21848513          	addi	a0,s1,536
    800049e2:	ffffe097          	auipc	ra,0xffffe
    800049e6:	a84080e7          	jalr	-1404(ra) # 80002466 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049ea:	2204b783          	ld	a5,544(s1)
    800049ee:	eb95                	bnez	a5,80004a22 <pipeclose+0x64>
    release(&pi->lock);
    800049f0:	8526                	mv	a0,s1
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	2d2080e7          	jalr	722(ra) # 80000cc4 <release>
    kfree((char*)pi);
    800049fa:	8526                	mv	a0,s1
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	028080e7          	jalr	40(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a04:	60e2                	ld	ra,24(sp)
    80004a06:	6442                	ld	s0,16(sp)
    80004a08:	64a2                	ld	s1,8(sp)
    80004a0a:	6902                	ld	s2,0(sp)
    80004a0c:	6105                	addi	sp,sp,32
    80004a0e:	8082                	ret
    pi->readopen = 0;
    80004a10:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a14:	21c48513          	addi	a0,s1,540
    80004a18:	ffffe097          	auipc	ra,0xffffe
    80004a1c:	a4e080e7          	jalr	-1458(ra) # 80002466 <wakeup>
    80004a20:	b7e9                	j	800049ea <pipeclose+0x2c>
    release(&pi->lock);
    80004a22:	8526                	mv	a0,s1
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	2a0080e7          	jalr	672(ra) # 80000cc4 <release>
}
    80004a2c:	bfe1                	j	80004a04 <pipeclose+0x46>

0000000080004a2e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a2e:	7119                	addi	sp,sp,-128
    80004a30:	fc86                	sd	ra,120(sp)
    80004a32:	f8a2                	sd	s0,112(sp)
    80004a34:	f4a6                	sd	s1,104(sp)
    80004a36:	f0ca                	sd	s2,96(sp)
    80004a38:	ecce                	sd	s3,88(sp)
    80004a3a:	e8d2                	sd	s4,80(sp)
    80004a3c:	e4d6                	sd	s5,72(sp)
    80004a3e:	e0da                	sd	s6,64(sp)
    80004a40:	fc5e                	sd	s7,56(sp)
    80004a42:	f862                	sd	s8,48(sp)
    80004a44:	f466                	sd	s9,40(sp)
    80004a46:	f06a                	sd	s10,32(sp)
    80004a48:	ec6e                	sd	s11,24(sp)
    80004a4a:	0100                	addi	s0,sp,128
    80004a4c:	84aa                	mv	s1,a0
    80004a4e:	8cae                	mv	s9,a1
    80004a50:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a52:	ffffd097          	auipc	ra,0xffffd
    80004a56:	082080e7          	jalr	130(ra) # 80001ad4 <myproc>
    80004a5a:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a5c:	8526                	mv	a0,s1
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	1b2080e7          	jalr	434(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004a66:	0d605963          	blez	s6,80004b38 <pipewrite+0x10a>
    80004a6a:	89a6                	mv	s3,s1
    80004a6c:	3b7d                	addiw	s6,s6,-1
    80004a6e:	1b02                	slli	s6,s6,0x20
    80004a70:	020b5b13          	srli	s6,s6,0x20
    80004a74:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a76:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a7a:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a7e:	5dfd                	li	s11,-1
    80004a80:	000b8d1b          	sext.w	s10,s7
    80004a84:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a86:	2184a783          	lw	a5,536(s1)
    80004a8a:	21c4a703          	lw	a4,540(s1)
    80004a8e:	2007879b          	addiw	a5,a5,512
    80004a92:	02f71b63          	bne	a4,a5,80004ac8 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004a96:	2204a783          	lw	a5,544(s1)
    80004a9a:	cbad                	beqz	a5,80004b0c <pipewrite+0xde>
    80004a9c:	03092783          	lw	a5,48(s2)
    80004aa0:	e7b5                	bnez	a5,80004b0c <pipewrite+0xde>
      wakeup(&pi->nread);
    80004aa2:	8556                	mv	a0,s5
    80004aa4:	ffffe097          	auipc	ra,0xffffe
    80004aa8:	9c2080e7          	jalr	-1598(ra) # 80002466 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004aac:	85ce                	mv	a1,s3
    80004aae:	8552                	mv	a0,s4
    80004ab0:	ffffe097          	auipc	ra,0xffffe
    80004ab4:	830080e7          	jalr	-2000(ra) # 800022e0 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ab8:	2184a783          	lw	a5,536(s1)
    80004abc:	21c4a703          	lw	a4,540(s1)
    80004ac0:	2007879b          	addiw	a5,a5,512
    80004ac4:	fcf709e3          	beq	a4,a5,80004a96 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ac8:	4685                	li	a3,1
    80004aca:	019b8633          	add	a2,s7,s9
    80004ace:	f8f40593          	addi	a1,s0,-113
    80004ad2:	05093503          	ld	a0,80(s2)
    80004ad6:	ffffd097          	auipc	ra,0xffffd
    80004ada:	c90080e7          	jalr	-880(ra) # 80001766 <copyin>
    80004ade:	05b50e63          	beq	a0,s11,80004b3a <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ae2:	21c4a783          	lw	a5,540(s1)
    80004ae6:	0017871b          	addiw	a4,a5,1
    80004aea:	20e4ae23          	sw	a4,540(s1)
    80004aee:	1ff7f793          	andi	a5,a5,511
    80004af2:	97a6                	add	a5,a5,s1
    80004af4:	f8f44703          	lbu	a4,-113(s0)
    80004af8:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004afc:	001d0c1b          	addiw	s8,s10,1
    80004b00:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b04:	036b8b63          	beq	s7,s6,80004b3a <pipewrite+0x10c>
    80004b08:	8bbe                	mv	s7,a5
    80004b0a:	bf9d                	j	80004a80 <pipewrite+0x52>
        release(&pi->lock);
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	1b6080e7          	jalr	438(ra) # 80000cc4 <release>
        return -1;
    80004b16:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b18:	8562                	mv	a0,s8
    80004b1a:	70e6                	ld	ra,120(sp)
    80004b1c:	7446                	ld	s0,112(sp)
    80004b1e:	74a6                	ld	s1,104(sp)
    80004b20:	7906                	ld	s2,96(sp)
    80004b22:	69e6                	ld	s3,88(sp)
    80004b24:	6a46                	ld	s4,80(sp)
    80004b26:	6aa6                	ld	s5,72(sp)
    80004b28:	6b06                	ld	s6,64(sp)
    80004b2a:	7be2                	ld	s7,56(sp)
    80004b2c:	7c42                	ld	s8,48(sp)
    80004b2e:	7ca2                	ld	s9,40(sp)
    80004b30:	7d02                	ld	s10,32(sp)
    80004b32:	6de2                	ld	s11,24(sp)
    80004b34:	6109                	addi	sp,sp,128
    80004b36:	8082                	ret
  for(i = 0; i < n; i++){
    80004b38:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b3a:	21848513          	addi	a0,s1,536
    80004b3e:	ffffe097          	auipc	ra,0xffffe
    80004b42:	928080e7          	jalr	-1752(ra) # 80002466 <wakeup>
  release(&pi->lock);
    80004b46:	8526                	mv	a0,s1
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	17c080e7          	jalr	380(ra) # 80000cc4 <release>
  return i;
    80004b50:	b7e1                	j	80004b18 <pipewrite+0xea>

0000000080004b52 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b52:	715d                	addi	sp,sp,-80
    80004b54:	e486                	sd	ra,72(sp)
    80004b56:	e0a2                	sd	s0,64(sp)
    80004b58:	fc26                	sd	s1,56(sp)
    80004b5a:	f84a                	sd	s2,48(sp)
    80004b5c:	f44e                	sd	s3,40(sp)
    80004b5e:	f052                	sd	s4,32(sp)
    80004b60:	ec56                	sd	s5,24(sp)
    80004b62:	e85a                	sd	s6,16(sp)
    80004b64:	0880                	addi	s0,sp,80
    80004b66:	84aa                	mv	s1,a0
    80004b68:	892e                	mv	s2,a1
    80004b6a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b6c:	ffffd097          	auipc	ra,0xffffd
    80004b70:	f68080e7          	jalr	-152(ra) # 80001ad4 <myproc>
    80004b74:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b76:	8b26                	mv	s6,s1
    80004b78:	8526                	mv	a0,s1
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	096080e7          	jalr	150(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b82:	2184a703          	lw	a4,536(s1)
    80004b86:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b8a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b8e:	02f71463          	bne	a4,a5,80004bb6 <piperead+0x64>
    80004b92:	2244a783          	lw	a5,548(s1)
    80004b96:	c385                	beqz	a5,80004bb6 <piperead+0x64>
    if(pr->killed){
    80004b98:	030a2783          	lw	a5,48(s4)
    80004b9c:	ebc1                	bnez	a5,80004c2c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b9e:	85da                	mv	a1,s6
    80004ba0:	854e                	mv	a0,s3
    80004ba2:	ffffd097          	auipc	ra,0xffffd
    80004ba6:	73e080e7          	jalr	1854(ra) # 800022e0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004baa:	2184a703          	lw	a4,536(s1)
    80004bae:	21c4a783          	lw	a5,540(s1)
    80004bb2:	fef700e3          	beq	a4,a5,80004b92 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bb6:	09505263          	blez	s5,80004c3a <piperead+0xe8>
    80004bba:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bbc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bbe:	2184a783          	lw	a5,536(s1)
    80004bc2:	21c4a703          	lw	a4,540(s1)
    80004bc6:	02f70d63          	beq	a4,a5,80004c00 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bca:	0017871b          	addiw	a4,a5,1
    80004bce:	20e4ac23          	sw	a4,536(s1)
    80004bd2:	1ff7f793          	andi	a5,a5,511
    80004bd6:	97a6                	add	a5,a5,s1
    80004bd8:	0187c783          	lbu	a5,24(a5)
    80004bdc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004be0:	4685                	li	a3,1
    80004be2:	fbf40613          	addi	a2,s0,-65
    80004be6:	85ca                	mv	a1,s2
    80004be8:	050a3503          	ld	a0,80(s4)
    80004bec:	ffffd097          	auipc	ra,0xffffd
    80004bf0:	aee080e7          	jalr	-1298(ra) # 800016da <copyout>
    80004bf4:	01650663          	beq	a0,s6,80004c00 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf8:	2985                	addiw	s3,s3,1
    80004bfa:	0905                	addi	s2,s2,1
    80004bfc:	fd3a91e3          	bne	s5,s3,80004bbe <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c00:	21c48513          	addi	a0,s1,540
    80004c04:	ffffe097          	auipc	ra,0xffffe
    80004c08:	862080e7          	jalr	-1950(ra) # 80002466 <wakeup>
  release(&pi->lock);
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	ffffc097          	auipc	ra,0xffffc
    80004c12:	0b6080e7          	jalr	182(ra) # 80000cc4 <release>
  return i;
}
    80004c16:	854e                	mv	a0,s3
    80004c18:	60a6                	ld	ra,72(sp)
    80004c1a:	6406                	ld	s0,64(sp)
    80004c1c:	74e2                	ld	s1,56(sp)
    80004c1e:	7942                	ld	s2,48(sp)
    80004c20:	79a2                	ld	s3,40(sp)
    80004c22:	7a02                	ld	s4,32(sp)
    80004c24:	6ae2                	ld	s5,24(sp)
    80004c26:	6b42                	ld	s6,16(sp)
    80004c28:	6161                	addi	sp,sp,80
    80004c2a:	8082                	ret
      release(&pi->lock);
    80004c2c:	8526                	mv	a0,s1
    80004c2e:	ffffc097          	auipc	ra,0xffffc
    80004c32:	096080e7          	jalr	150(ra) # 80000cc4 <release>
      return -1;
    80004c36:	59fd                	li	s3,-1
    80004c38:	bff9                	j	80004c16 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c3a:	4981                	li	s3,0
    80004c3c:	b7d1                	j	80004c00 <piperead+0xae>

0000000080004c3e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c3e:	df010113          	addi	sp,sp,-528
    80004c42:	20113423          	sd	ra,520(sp)
    80004c46:	20813023          	sd	s0,512(sp)
    80004c4a:	ffa6                	sd	s1,504(sp)
    80004c4c:	fbca                	sd	s2,496(sp)
    80004c4e:	f7ce                	sd	s3,488(sp)
    80004c50:	f3d2                	sd	s4,480(sp)
    80004c52:	efd6                	sd	s5,472(sp)
    80004c54:	ebda                	sd	s6,464(sp)
    80004c56:	e7de                	sd	s7,456(sp)
    80004c58:	e3e2                	sd	s8,448(sp)
    80004c5a:	ff66                	sd	s9,440(sp)
    80004c5c:	fb6a                	sd	s10,432(sp)
    80004c5e:	f76e                	sd	s11,424(sp)
    80004c60:	0c00                	addi	s0,sp,528
    80004c62:	84aa                	mv	s1,a0
    80004c64:	dea43c23          	sd	a0,-520(s0)
    80004c68:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	e68080e7          	jalr	-408(ra) # 80001ad4 <myproc>
    80004c74:	892a                	mv	s2,a0

  begin_op();
    80004c76:	fffff097          	auipc	ra,0xfffff
    80004c7a:	446080e7          	jalr	1094(ra) # 800040bc <begin_op>

  if((ip = namei(path)) == 0){
    80004c7e:	8526                	mv	a0,s1
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	230080e7          	jalr	560(ra) # 80003eb0 <namei>
    80004c88:	c92d                	beqz	a0,80004cfa <exec+0xbc>
    80004c8a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c8c:	fffff097          	auipc	ra,0xfffff
    80004c90:	a74080e7          	jalr	-1420(ra) # 80003700 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c94:	04000713          	li	a4,64
    80004c98:	4681                	li	a3,0
    80004c9a:	e4840613          	addi	a2,s0,-440
    80004c9e:	4581                	li	a1,0
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	fffff097          	auipc	ra,0xfffff
    80004ca6:	d12080e7          	jalr	-750(ra) # 800039b4 <readi>
    80004caa:	04000793          	li	a5,64
    80004cae:	00f51a63          	bne	a0,a5,80004cc2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cb2:	e4842703          	lw	a4,-440(s0)
    80004cb6:	464c47b7          	lui	a5,0x464c4
    80004cba:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cbe:	04f70463          	beq	a4,a5,80004d06 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cc2:	8526                	mv	a0,s1
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	c9e080e7          	jalr	-866(ra) # 80003962 <iunlockput>
    end_op();
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	470080e7          	jalr	1136(ra) # 8000413c <end_op>
  }
  return -1;
    80004cd4:	557d                	li	a0,-1
}
    80004cd6:	20813083          	ld	ra,520(sp)
    80004cda:	20013403          	ld	s0,512(sp)
    80004cde:	74fe                	ld	s1,504(sp)
    80004ce0:	795e                	ld	s2,496(sp)
    80004ce2:	79be                	ld	s3,488(sp)
    80004ce4:	7a1e                	ld	s4,480(sp)
    80004ce6:	6afe                	ld	s5,472(sp)
    80004ce8:	6b5e                	ld	s6,464(sp)
    80004cea:	6bbe                	ld	s7,456(sp)
    80004cec:	6c1e                	ld	s8,448(sp)
    80004cee:	7cfa                	ld	s9,440(sp)
    80004cf0:	7d5a                	ld	s10,432(sp)
    80004cf2:	7dba                	ld	s11,424(sp)
    80004cf4:	21010113          	addi	sp,sp,528
    80004cf8:	8082                	ret
    end_op();
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	442080e7          	jalr	1090(ra) # 8000413c <end_op>
    return -1;
    80004d02:	557d                	li	a0,-1
    80004d04:	bfc9                	j	80004cd6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d06:	854a                	mv	a0,s2
    80004d08:	ffffd097          	auipc	ra,0xffffd
    80004d0c:	e90080e7          	jalr	-368(ra) # 80001b98 <proc_pagetable>
    80004d10:	8baa                	mv	s7,a0
    80004d12:	d945                	beqz	a0,80004cc2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d14:	e6842983          	lw	s3,-408(s0)
    80004d18:	e8045783          	lhu	a5,-384(s0)
    80004d1c:	c7ad                	beqz	a5,80004d86 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d1e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d20:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d22:	6c85                	lui	s9,0x1
    80004d24:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d28:	def43823          	sd	a5,-528(s0)
    80004d2c:	a489                	j	80004f6e <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d2e:	00004517          	auipc	a0,0x4
    80004d32:	9e250513          	addi	a0,a0,-1566 # 80008710 <syscalls+0x290>
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	812080e7          	jalr	-2030(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d3e:	8756                	mv	a4,s5
    80004d40:	012d86bb          	addw	a3,s11,s2
    80004d44:	4581                	li	a1,0
    80004d46:	8526                	mv	a0,s1
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	c6c080e7          	jalr	-916(ra) # 800039b4 <readi>
    80004d50:	2501                	sext.w	a0,a0
    80004d52:	1caa9563          	bne	s5,a0,80004f1c <exec+0x2de>
  for(i = 0; i < sz; i += PGSIZE){
    80004d56:	6785                	lui	a5,0x1
    80004d58:	0127893b          	addw	s2,a5,s2
    80004d5c:	77fd                	lui	a5,0xfffff
    80004d5e:	01478a3b          	addw	s4,a5,s4
    80004d62:	1f897d63          	bgeu	s2,s8,80004f5c <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    80004d66:	02091593          	slli	a1,s2,0x20
    80004d6a:	9181                	srli	a1,a1,0x20
    80004d6c:	95ea                	add	a1,a1,s10
    80004d6e:	855e                	mv	a0,s7
    80004d70:	ffffc097          	auipc	ra,0xffffc
    80004d74:	336080e7          	jalr	822(ra) # 800010a6 <walkaddr>
    80004d78:	862a                	mv	a2,a0
    if(pa == 0)
    80004d7a:	d955                	beqz	a0,80004d2e <exec+0xf0>
      n = PGSIZE;
    80004d7c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d7e:	fd9a70e3          	bgeu	s4,s9,80004d3e <exec+0x100>
      n = sz - i;
    80004d82:	8ad2                	mv	s5,s4
    80004d84:	bf6d                	j	80004d3e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d86:	4901                	li	s2,0
  iunlockput(ip);
    80004d88:	8526                	mv	a0,s1
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	bd8080e7          	jalr	-1064(ra) # 80003962 <iunlockput>
  end_op();
    80004d92:	fffff097          	auipc	ra,0xfffff
    80004d96:	3aa080e7          	jalr	938(ra) # 8000413c <end_op>
  p = myproc();
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	d3a080e7          	jalr	-710(ra) # 80001ad4 <myproc>
    80004da2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004da4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004da8:	6785                	lui	a5,0x1
    80004daa:	17fd                	addi	a5,a5,-1
    80004dac:	993e                	add	s2,s2,a5
    80004dae:	757d                	lui	a0,0xfffff
    80004db0:	00a977b3          	and	a5,s2,a0
    80004db4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004db8:	6609                	lui	a2,0x2
    80004dba:	963e                	add	a2,a2,a5
    80004dbc:	85be                	mv	a1,a5
    80004dbe:	855e                	mv	a0,s7
    80004dc0:	ffffc097          	auipc	ra,0xffffc
    80004dc4:	6ca080e7          	jalr	1738(ra) # 8000148a <uvmalloc>
    80004dc8:	8b2a                	mv	s6,a0
  ip = 0;
    80004dca:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dcc:	14050863          	beqz	a0,80004f1c <exec+0x2de>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dd0:	75f9                	lui	a1,0xffffe
    80004dd2:	95aa                	add	a1,a1,a0
    80004dd4:	855e                	mv	a0,s7
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	8d2080e7          	jalr	-1838(ra) # 800016a8 <uvmclear>
  stackbase = sp - PGSIZE;
    80004dde:	7c7d                	lui	s8,0xfffff
    80004de0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004de2:	e0043783          	ld	a5,-512(s0)
    80004de6:	6388                	ld	a0,0(a5)
    80004de8:	c535                	beqz	a0,80004e54 <exec+0x216>
    80004dea:	e8840993          	addi	s3,s0,-376
    80004dee:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004df2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004df4:	ffffc097          	auipc	ra,0xffffc
    80004df8:	0a0080e7          	jalr	160(ra) # 80000e94 <strlen>
    80004dfc:	2505                	addiw	a0,a0,1
    80004dfe:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e02:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e06:	13896f63          	bltu	s2,s8,80004f44 <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e0a:	e0043d83          	ld	s11,-512(s0)
    80004e0e:	000dba03          	ld	s4,0(s11)
    80004e12:	8552                	mv	a0,s4
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	080080e7          	jalr	128(ra) # 80000e94 <strlen>
    80004e1c:	0015069b          	addiw	a3,a0,1
    80004e20:	8652                	mv	a2,s4
    80004e22:	85ca                	mv	a1,s2
    80004e24:	855e                	mv	a0,s7
    80004e26:	ffffd097          	auipc	ra,0xffffd
    80004e2a:	8b4080e7          	jalr	-1868(ra) # 800016da <copyout>
    80004e2e:	10054f63          	bltz	a0,80004f4c <exec+0x30e>
    ustack[argc] = sp;
    80004e32:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e36:	0485                	addi	s1,s1,1
    80004e38:	008d8793          	addi	a5,s11,8
    80004e3c:	e0f43023          	sd	a5,-512(s0)
    80004e40:	008db503          	ld	a0,8(s11)
    80004e44:	c911                	beqz	a0,80004e58 <exec+0x21a>
    if(argc >= MAXARG)
    80004e46:	09a1                	addi	s3,s3,8
    80004e48:	fb3c96e3          	bne	s9,s3,80004df4 <exec+0x1b6>
  sz = sz1;
    80004e4c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e50:	4481                	li	s1,0
    80004e52:	a0e9                	j	80004f1c <exec+0x2de>
  sp = sz;
    80004e54:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e56:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e58:	00349793          	slli	a5,s1,0x3
    80004e5c:	f9040713          	addi	a4,s0,-112
    80004e60:	97ba                	add	a5,a5,a4
    80004e62:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004e66:	00148693          	addi	a3,s1,1
    80004e6a:	068e                	slli	a3,a3,0x3
    80004e6c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e70:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e74:	01897663          	bgeu	s2,s8,80004e80 <exec+0x242>
  sz = sz1;
    80004e78:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e7c:	4481                	li	s1,0
    80004e7e:	a879                	j	80004f1c <exec+0x2de>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e80:	e8840613          	addi	a2,s0,-376
    80004e84:	85ca                	mv	a1,s2
    80004e86:	855e                	mv	a0,s7
    80004e88:	ffffd097          	auipc	ra,0xffffd
    80004e8c:	852080e7          	jalr	-1966(ra) # 800016da <copyout>
    80004e90:	0c054263          	bltz	a0,80004f54 <exec+0x316>
  p->trapframe->a1 = sp;
    80004e94:	058ab783          	ld	a5,88(s5)
    80004e98:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e9c:	df843783          	ld	a5,-520(s0)
    80004ea0:	0007c703          	lbu	a4,0(a5)
    80004ea4:	cf11                	beqz	a4,80004ec0 <exec+0x282>
    80004ea6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ea8:	02f00693          	li	a3,47
    80004eac:	a029                	j	80004eb6 <exec+0x278>
  for(last=s=path; *s; s++)
    80004eae:	0785                	addi	a5,a5,1
    80004eb0:	fff7c703          	lbu	a4,-1(a5)
    80004eb4:	c711                	beqz	a4,80004ec0 <exec+0x282>
    if(*s == '/')
    80004eb6:	fed71ce3          	bne	a4,a3,80004eae <exec+0x270>
      last = s+1;
    80004eba:	def43c23          	sd	a5,-520(s0)
    80004ebe:	bfc5                	j	80004eae <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ec0:	4641                	li	a2,16
    80004ec2:	df843583          	ld	a1,-520(s0)
    80004ec6:	158a8513          	addi	a0,s5,344
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	f98080e7          	jalr	-104(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ed2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004ed6:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004eda:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ede:	058ab783          	ld	a5,88(s5)
    80004ee2:	e6043703          	ld	a4,-416(s0)
    80004ee6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ee8:	058ab783          	ld	a5,88(s5)
    80004eec:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ef0:	85ea                	mv	a1,s10
    80004ef2:	ffffd097          	auipc	ra,0xffffd
    80004ef6:	d42080e7          	jalr	-702(ra) # 80001c34 <proc_freepagetable>
  if(p->pid==1) vmprint(p->pagetable);
    80004efa:	038aa703          	lw	a4,56(s5)
    80004efe:	4785                	li	a5,1
    80004f00:	00f70563          	beq	a4,a5,80004f0a <exec+0x2cc>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f04:	0004851b          	sext.w	a0,s1
    80004f08:	b3f9                	j	80004cd6 <exec+0x98>
  if(p->pid==1) vmprint(p->pagetable);
    80004f0a:	050ab503          	ld	a0,80(s5)
    80004f0e:	ffffd097          	auipc	ra,0xffffd
    80004f12:	998080e7          	jalr	-1640(ra) # 800018a6 <vmprint>
    80004f16:	b7fd                	j	80004f04 <exec+0x2c6>
    80004f18:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f1c:	e0843583          	ld	a1,-504(s0)
    80004f20:	855e                	mv	a0,s7
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	d12080e7          	jalr	-750(ra) # 80001c34 <proc_freepagetable>
  if(ip){
    80004f2a:	d8049ce3          	bnez	s1,80004cc2 <exec+0x84>
  return -1;
    80004f2e:	557d                	li	a0,-1
    80004f30:	b35d                	j	80004cd6 <exec+0x98>
    80004f32:	e1243423          	sd	s2,-504(s0)
    80004f36:	b7dd                	j	80004f1c <exec+0x2de>
    80004f38:	e1243423          	sd	s2,-504(s0)
    80004f3c:	b7c5                	j	80004f1c <exec+0x2de>
    80004f3e:	e1243423          	sd	s2,-504(s0)
    80004f42:	bfe9                	j	80004f1c <exec+0x2de>
  sz = sz1;
    80004f44:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f48:	4481                	li	s1,0
    80004f4a:	bfc9                	j	80004f1c <exec+0x2de>
  sz = sz1;
    80004f4c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f50:	4481                	li	s1,0
    80004f52:	b7e9                	j	80004f1c <exec+0x2de>
  sz = sz1;
    80004f54:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f58:	4481                	li	s1,0
    80004f5a:	b7c9                	j	80004f1c <exec+0x2de>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f5c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f60:	2b05                	addiw	s6,s6,1
    80004f62:	0389899b          	addiw	s3,s3,56
    80004f66:	e8045783          	lhu	a5,-384(s0)
    80004f6a:	e0fb5fe3          	bge	s6,a5,80004d88 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f6e:	2981                	sext.w	s3,s3
    80004f70:	03800713          	li	a4,56
    80004f74:	86ce                	mv	a3,s3
    80004f76:	e1040613          	addi	a2,s0,-496
    80004f7a:	4581                	li	a1,0
    80004f7c:	8526                	mv	a0,s1
    80004f7e:	fffff097          	auipc	ra,0xfffff
    80004f82:	a36080e7          	jalr	-1482(ra) # 800039b4 <readi>
    80004f86:	03800793          	li	a5,56
    80004f8a:	f8f517e3          	bne	a0,a5,80004f18 <exec+0x2da>
    if(ph.type != ELF_PROG_LOAD)
    80004f8e:	e1042783          	lw	a5,-496(s0)
    80004f92:	4705                	li	a4,1
    80004f94:	fce796e3          	bne	a5,a4,80004f60 <exec+0x322>
    if(ph.memsz < ph.filesz)
    80004f98:	e3843603          	ld	a2,-456(s0)
    80004f9c:	e3043783          	ld	a5,-464(s0)
    80004fa0:	f8f669e3          	bltu	a2,a5,80004f32 <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fa4:	e2043783          	ld	a5,-480(s0)
    80004fa8:	963e                	add	a2,a2,a5
    80004faa:	f8f667e3          	bltu	a2,a5,80004f38 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fae:	85ca                	mv	a1,s2
    80004fb0:	855e                	mv	a0,s7
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	4d8080e7          	jalr	1240(ra) # 8000148a <uvmalloc>
    80004fba:	e0a43423          	sd	a0,-504(s0)
    80004fbe:	d141                	beqz	a0,80004f3e <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    80004fc0:	e2043d03          	ld	s10,-480(s0)
    80004fc4:	df043783          	ld	a5,-528(s0)
    80004fc8:	00fd77b3          	and	a5,s10,a5
    80004fcc:	fba1                	bnez	a5,80004f1c <exec+0x2de>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fce:	e1842d83          	lw	s11,-488(s0)
    80004fd2:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fd6:	f80c03e3          	beqz	s8,80004f5c <exec+0x31e>
    80004fda:	8a62                	mv	s4,s8
    80004fdc:	4901                	li	s2,0
    80004fde:	b361                	j	80004d66 <exec+0x128>

0000000080004fe0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fe0:	7179                	addi	sp,sp,-48
    80004fe2:	f406                	sd	ra,40(sp)
    80004fe4:	f022                	sd	s0,32(sp)
    80004fe6:	ec26                	sd	s1,24(sp)
    80004fe8:	e84a                	sd	s2,16(sp)
    80004fea:	1800                	addi	s0,sp,48
    80004fec:	892e                	mv	s2,a1
    80004fee:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ff0:	fdc40593          	addi	a1,s0,-36
    80004ff4:	ffffe097          	auipc	ra,0xffffe
    80004ff8:	b9a080e7          	jalr	-1126(ra) # 80002b8e <argint>
    80004ffc:	04054063          	bltz	a0,8000503c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005000:	fdc42703          	lw	a4,-36(s0)
    80005004:	47bd                	li	a5,15
    80005006:	02e7ed63          	bltu	a5,a4,80005040 <argfd+0x60>
    8000500a:	ffffd097          	auipc	ra,0xffffd
    8000500e:	aca080e7          	jalr	-1334(ra) # 80001ad4 <myproc>
    80005012:	fdc42703          	lw	a4,-36(s0)
    80005016:	01a70793          	addi	a5,a4,26
    8000501a:	078e                	slli	a5,a5,0x3
    8000501c:	953e                	add	a0,a0,a5
    8000501e:	611c                	ld	a5,0(a0)
    80005020:	c395                	beqz	a5,80005044 <argfd+0x64>
    return -1;
  if(pfd)
    80005022:	00090463          	beqz	s2,8000502a <argfd+0x4a>
    *pfd = fd;
    80005026:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000502a:	4501                	li	a0,0
  if(pf)
    8000502c:	c091                	beqz	s1,80005030 <argfd+0x50>
    *pf = f;
    8000502e:	e09c                	sd	a5,0(s1)
}
    80005030:	70a2                	ld	ra,40(sp)
    80005032:	7402                	ld	s0,32(sp)
    80005034:	64e2                	ld	s1,24(sp)
    80005036:	6942                	ld	s2,16(sp)
    80005038:	6145                	addi	sp,sp,48
    8000503a:	8082                	ret
    return -1;
    8000503c:	557d                	li	a0,-1
    8000503e:	bfcd                	j	80005030 <argfd+0x50>
    return -1;
    80005040:	557d                	li	a0,-1
    80005042:	b7fd                	j	80005030 <argfd+0x50>
    80005044:	557d                	li	a0,-1
    80005046:	b7ed                	j	80005030 <argfd+0x50>

0000000080005048 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005048:	1101                	addi	sp,sp,-32
    8000504a:	ec06                	sd	ra,24(sp)
    8000504c:	e822                	sd	s0,16(sp)
    8000504e:	e426                	sd	s1,8(sp)
    80005050:	1000                	addi	s0,sp,32
    80005052:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005054:	ffffd097          	auipc	ra,0xffffd
    80005058:	a80080e7          	jalr	-1408(ra) # 80001ad4 <myproc>
    8000505c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000505e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80b0>
    80005062:	4501                	li	a0,0
    80005064:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005066:	6398                	ld	a4,0(a5)
    80005068:	cb19                	beqz	a4,8000507e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000506a:	2505                	addiw	a0,a0,1
    8000506c:	07a1                	addi	a5,a5,8
    8000506e:	fed51ce3          	bne	a0,a3,80005066 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005072:	557d                	li	a0,-1
}
    80005074:	60e2                	ld	ra,24(sp)
    80005076:	6442                	ld	s0,16(sp)
    80005078:	64a2                	ld	s1,8(sp)
    8000507a:	6105                	addi	sp,sp,32
    8000507c:	8082                	ret
      p->ofile[fd] = f;
    8000507e:	01a50793          	addi	a5,a0,26
    80005082:	078e                	slli	a5,a5,0x3
    80005084:	963e                	add	a2,a2,a5
    80005086:	e204                	sd	s1,0(a2)
      return fd;
    80005088:	b7f5                	j	80005074 <fdalloc+0x2c>

000000008000508a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000508a:	715d                	addi	sp,sp,-80
    8000508c:	e486                	sd	ra,72(sp)
    8000508e:	e0a2                	sd	s0,64(sp)
    80005090:	fc26                	sd	s1,56(sp)
    80005092:	f84a                	sd	s2,48(sp)
    80005094:	f44e                	sd	s3,40(sp)
    80005096:	f052                	sd	s4,32(sp)
    80005098:	ec56                	sd	s5,24(sp)
    8000509a:	0880                	addi	s0,sp,80
    8000509c:	89ae                	mv	s3,a1
    8000509e:	8ab2                	mv	s5,a2
    800050a0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050a2:	fb040593          	addi	a1,s0,-80
    800050a6:	fffff097          	auipc	ra,0xfffff
    800050aa:	e28080e7          	jalr	-472(ra) # 80003ece <nameiparent>
    800050ae:	892a                	mv	s2,a0
    800050b0:	12050f63          	beqz	a0,800051ee <create+0x164>
    return 0;

  ilock(dp);
    800050b4:	ffffe097          	auipc	ra,0xffffe
    800050b8:	64c080e7          	jalr	1612(ra) # 80003700 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050bc:	4601                	li	a2,0
    800050be:	fb040593          	addi	a1,s0,-80
    800050c2:	854a                	mv	a0,s2
    800050c4:	fffff097          	auipc	ra,0xfffff
    800050c8:	b1a080e7          	jalr	-1254(ra) # 80003bde <dirlookup>
    800050cc:	84aa                	mv	s1,a0
    800050ce:	c921                	beqz	a0,8000511e <create+0x94>
    iunlockput(dp);
    800050d0:	854a                	mv	a0,s2
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	890080e7          	jalr	-1904(ra) # 80003962 <iunlockput>
    ilock(ip);
    800050da:	8526                	mv	a0,s1
    800050dc:	ffffe097          	auipc	ra,0xffffe
    800050e0:	624080e7          	jalr	1572(ra) # 80003700 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050e4:	2981                	sext.w	s3,s3
    800050e6:	4789                	li	a5,2
    800050e8:	02f99463          	bne	s3,a5,80005110 <create+0x86>
    800050ec:	0444d783          	lhu	a5,68(s1)
    800050f0:	37f9                	addiw	a5,a5,-2
    800050f2:	17c2                	slli	a5,a5,0x30
    800050f4:	93c1                	srli	a5,a5,0x30
    800050f6:	4705                	li	a4,1
    800050f8:	00f76c63          	bltu	a4,a5,80005110 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050fc:	8526                	mv	a0,s1
    800050fe:	60a6                	ld	ra,72(sp)
    80005100:	6406                	ld	s0,64(sp)
    80005102:	74e2                	ld	s1,56(sp)
    80005104:	7942                	ld	s2,48(sp)
    80005106:	79a2                	ld	s3,40(sp)
    80005108:	7a02                	ld	s4,32(sp)
    8000510a:	6ae2                	ld	s5,24(sp)
    8000510c:	6161                	addi	sp,sp,80
    8000510e:	8082                	ret
    iunlockput(ip);
    80005110:	8526                	mv	a0,s1
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	850080e7          	jalr	-1968(ra) # 80003962 <iunlockput>
    return 0;
    8000511a:	4481                	li	s1,0
    8000511c:	b7c5                	j	800050fc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000511e:	85ce                	mv	a1,s3
    80005120:	00092503          	lw	a0,0(s2)
    80005124:	ffffe097          	auipc	ra,0xffffe
    80005128:	444080e7          	jalr	1092(ra) # 80003568 <ialloc>
    8000512c:	84aa                	mv	s1,a0
    8000512e:	c529                	beqz	a0,80005178 <create+0xee>
  ilock(ip);
    80005130:	ffffe097          	auipc	ra,0xffffe
    80005134:	5d0080e7          	jalr	1488(ra) # 80003700 <ilock>
  ip->major = major;
    80005138:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000513c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005140:	4785                	li	a5,1
    80005142:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005146:	8526                	mv	a0,s1
    80005148:	ffffe097          	auipc	ra,0xffffe
    8000514c:	4ee080e7          	jalr	1262(ra) # 80003636 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005150:	2981                	sext.w	s3,s3
    80005152:	4785                	li	a5,1
    80005154:	02f98a63          	beq	s3,a5,80005188 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005158:	40d0                	lw	a2,4(s1)
    8000515a:	fb040593          	addi	a1,s0,-80
    8000515e:	854a                	mv	a0,s2
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	c8e080e7          	jalr	-882(ra) # 80003dee <dirlink>
    80005168:	06054b63          	bltz	a0,800051de <create+0x154>
  iunlockput(dp);
    8000516c:	854a                	mv	a0,s2
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	7f4080e7          	jalr	2036(ra) # 80003962 <iunlockput>
  return ip;
    80005176:	b759                	j	800050fc <create+0x72>
    panic("create: ialloc");
    80005178:	00003517          	auipc	a0,0x3
    8000517c:	5b850513          	addi	a0,a0,1464 # 80008730 <syscalls+0x2b0>
    80005180:	ffffb097          	auipc	ra,0xffffb
    80005184:	3c8080e7          	jalr	968(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005188:	04a95783          	lhu	a5,74(s2)
    8000518c:	2785                	addiw	a5,a5,1
    8000518e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005192:	854a                	mv	a0,s2
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	4a2080e7          	jalr	1186(ra) # 80003636 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000519c:	40d0                	lw	a2,4(s1)
    8000519e:	00003597          	auipc	a1,0x3
    800051a2:	5a258593          	addi	a1,a1,1442 # 80008740 <syscalls+0x2c0>
    800051a6:	8526                	mv	a0,s1
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	c46080e7          	jalr	-954(ra) # 80003dee <dirlink>
    800051b0:	00054f63          	bltz	a0,800051ce <create+0x144>
    800051b4:	00492603          	lw	a2,4(s2)
    800051b8:	00003597          	auipc	a1,0x3
    800051bc:	59058593          	addi	a1,a1,1424 # 80008748 <syscalls+0x2c8>
    800051c0:	8526                	mv	a0,s1
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	c2c080e7          	jalr	-980(ra) # 80003dee <dirlink>
    800051ca:	f80557e3          	bgez	a0,80005158 <create+0xce>
      panic("create dots");
    800051ce:	00003517          	auipc	a0,0x3
    800051d2:	58250513          	addi	a0,a0,1410 # 80008750 <syscalls+0x2d0>
    800051d6:	ffffb097          	auipc	ra,0xffffb
    800051da:	372080e7          	jalr	882(ra) # 80000548 <panic>
    panic("create: dirlink");
    800051de:	00003517          	auipc	a0,0x3
    800051e2:	58250513          	addi	a0,a0,1410 # 80008760 <syscalls+0x2e0>
    800051e6:	ffffb097          	auipc	ra,0xffffb
    800051ea:	362080e7          	jalr	866(ra) # 80000548 <panic>
    return 0;
    800051ee:	84aa                	mv	s1,a0
    800051f0:	b731                	j	800050fc <create+0x72>

00000000800051f2 <sys_dup>:
{
    800051f2:	7179                	addi	sp,sp,-48
    800051f4:	f406                	sd	ra,40(sp)
    800051f6:	f022                	sd	s0,32(sp)
    800051f8:	ec26                	sd	s1,24(sp)
    800051fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051fc:	fd840613          	addi	a2,s0,-40
    80005200:	4581                	li	a1,0
    80005202:	4501                	li	a0,0
    80005204:	00000097          	auipc	ra,0x0
    80005208:	ddc080e7          	jalr	-548(ra) # 80004fe0 <argfd>
    return -1;
    8000520c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000520e:	02054363          	bltz	a0,80005234 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005212:	fd843503          	ld	a0,-40(s0)
    80005216:	00000097          	auipc	ra,0x0
    8000521a:	e32080e7          	jalr	-462(ra) # 80005048 <fdalloc>
    8000521e:	84aa                	mv	s1,a0
    return -1;
    80005220:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005222:	00054963          	bltz	a0,80005234 <sys_dup+0x42>
  filedup(f);
    80005226:	fd843503          	ld	a0,-40(s0)
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	312080e7          	jalr	786(ra) # 8000453c <filedup>
  return fd;
    80005232:	87a6                	mv	a5,s1
}
    80005234:	853e                	mv	a0,a5
    80005236:	70a2                	ld	ra,40(sp)
    80005238:	7402                	ld	s0,32(sp)
    8000523a:	64e2                	ld	s1,24(sp)
    8000523c:	6145                	addi	sp,sp,48
    8000523e:	8082                	ret

0000000080005240 <sys_read>:
{
    80005240:	7179                	addi	sp,sp,-48
    80005242:	f406                	sd	ra,40(sp)
    80005244:	f022                	sd	s0,32(sp)
    80005246:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005248:	fe840613          	addi	a2,s0,-24
    8000524c:	4581                	li	a1,0
    8000524e:	4501                	li	a0,0
    80005250:	00000097          	auipc	ra,0x0
    80005254:	d90080e7          	jalr	-624(ra) # 80004fe0 <argfd>
    return -1;
    80005258:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525a:	04054163          	bltz	a0,8000529c <sys_read+0x5c>
    8000525e:	fe440593          	addi	a1,s0,-28
    80005262:	4509                	li	a0,2
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	92a080e7          	jalr	-1750(ra) # 80002b8e <argint>
    return -1;
    8000526c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526e:	02054763          	bltz	a0,8000529c <sys_read+0x5c>
    80005272:	fd840593          	addi	a1,s0,-40
    80005276:	4505                	li	a0,1
    80005278:	ffffe097          	auipc	ra,0xffffe
    8000527c:	938080e7          	jalr	-1736(ra) # 80002bb0 <argaddr>
    return -1;
    80005280:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005282:	00054d63          	bltz	a0,8000529c <sys_read+0x5c>
  return fileread(f, p, n);
    80005286:	fe442603          	lw	a2,-28(s0)
    8000528a:	fd843583          	ld	a1,-40(s0)
    8000528e:	fe843503          	ld	a0,-24(s0)
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	436080e7          	jalr	1078(ra) # 800046c8 <fileread>
    8000529a:	87aa                	mv	a5,a0
}
    8000529c:	853e                	mv	a0,a5
    8000529e:	70a2                	ld	ra,40(sp)
    800052a0:	7402                	ld	s0,32(sp)
    800052a2:	6145                	addi	sp,sp,48
    800052a4:	8082                	ret

00000000800052a6 <sys_write>:
{
    800052a6:	7179                	addi	sp,sp,-48
    800052a8:	f406                	sd	ra,40(sp)
    800052aa:	f022                	sd	s0,32(sp)
    800052ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ae:	fe840613          	addi	a2,s0,-24
    800052b2:	4581                	li	a1,0
    800052b4:	4501                	li	a0,0
    800052b6:	00000097          	auipc	ra,0x0
    800052ba:	d2a080e7          	jalr	-726(ra) # 80004fe0 <argfd>
    return -1;
    800052be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c0:	04054163          	bltz	a0,80005302 <sys_write+0x5c>
    800052c4:	fe440593          	addi	a1,s0,-28
    800052c8:	4509                	li	a0,2
    800052ca:	ffffe097          	auipc	ra,0xffffe
    800052ce:	8c4080e7          	jalr	-1852(ra) # 80002b8e <argint>
    return -1;
    800052d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d4:	02054763          	bltz	a0,80005302 <sys_write+0x5c>
    800052d8:	fd840593          	addi	a1,s0,-40
    800052dc:	4505                	li	a0,1
    800052de:	ffffe097          	auipc	ra,0xffffe
    800052e2:	8d2080e7          	jalr	-1838(ra) # 80002bb0 <argaddr>
    return -1;
    800052e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e8:	00054d63          	bltz	a0,80005302 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052ec:	fe442603          	lw	a2,-28(s0)
    800052f0:	fd843583          	ld	a1,-40(s0)
    800052f4:	fe843503          	ld	a0,-24(s0)
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	492080e7          	jalr	1170(ra) # 8000478a <filewrite>
    80005300:	87aa                	mv	a5,a0
}
    80005302:	853e                	mv	a0,a5
    80005304:	70a2                	ld	ra,40(sp)
    80005306:	7402                	ld	s0,32(sp)
    80005308:	6145                	addi	sp,sp,48
    8000530a:	8082                	ret

000000008000530c <sys_close>:
{
    8000530c:	1101                	addi	sp,sp,-32
    8000530e:	ec06                	sd	ra,24(sp)
    80005310:	e822                	sd	s0,16(sp)
    80005312:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005314:	fe040613          	addi	a2,s0,-32
    80005318:	fec40593          	addi	a1,s0,-20
    8000531c:	4501                	li	a0,0
    8000531e:	00000097          	auipc	ra,0x0
    80005322:	cc2080e7          	jalr	-830(ra) # 80004fe0 <argfd>
    return -1;
    80005326:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005328:	02054463          	bltz	a0,80005350 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000532c:	ffffc097          	auipc	ra,0xffffc
    80005330:	7a8080e7          	jalr	1960(ra) # 80001ad4 <myproc>
    80005334:	fec42783          	lw	a5,-20(s0)
    80005338:	07e9                	addi	a5,a5,26
    8000533a:	078e                	slli	a5,a5,0x3
    8000533c:	97aa                	add	a5,a5,a0
    8000533e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005342:	fe043503          	ld	a0,-32(s0)
    80005346:	fffff097          	auipc	ra,0xfffff
    8000534a:	248080e7          	jalr	584(ra) # 8000458e <fileclose>
  return 0;
    8000534e:	4781                	li	a5,0
}
    80005350:	853e                	mv	a0,a5
    80005352:	60e2                	ld	ra,24(sp)
    80005354:	6442                	ld	s0,16(sp)
    80005356:	6105                	addi	sp,sp,32
    80005358:	8082                	ret

000000008000535a <sys_fstat>:
{
    8000535a:	1101                	addi	sp,sp,-32
    8000535c:	ec06                	sd	ra,24(sp)
    8000535e:	e822                	sd	s0,16(sp)
    80005360:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005362:	fe840613          	addi	a2,s0,-24
    80005366:	4581                	li	a1,0
    80005368:	4501                	li	a0,0
    8000536a:	00000097          	auipc	ra,0x0
    8000536e:	c76080e7          	jalr	-906(ra) # 80004fe0 <argfd>
    return -1;
    80005372:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005374:	02054563          	bltz	a0,8000539e <sys_fstat+0x44>
    80005378:	fe040593          	addi	a1,s0,-32
    8000537c:	4505                	li	a0,1
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	832080e7          	jalr	-1998(ra) # 80002bb0 <argaddr>
    return -1;
    80005386:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005388:	00054b63          	bltz	a0,8000539e <sys_fstat+0x44>
  return filestat(f, st);
    8000538c:	fe043583          	ld	a1,-32(s0)
    80005390:	fe843503          	ld	a0,-24(s0)
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	2c2080e7          	jalr	706(ra) # 80004656 <filestat>
    8000539c:	87aa                	mv	a5,a0
}
    8000539e:	853e                	mv	a0,a5
    800053a0:	60e2                	ld	ra,24(sp)
    800053a2:	6442                	ld	s0,16(sp)
    800053a4:	6105                	addi	sp,sp,32
    800053a6:	8082                	ret

00000000800053a8 <sys_link>:
{
    800053a8:	7169                	addi	sp,sp,-304
    800053aa:	f606                	sd	ra,296(sp)
    800053ac:	f222                	sd	s0,288(sp)
    800053ae:	ee26                	sd	s1,280(sp)
    800053b0:	ea4a                	sd	s2,272(sp)
    800053b2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053b4:	08000613          	li	a2,128
    800053b8:	ed040593          	addi	a1,s0,-304
    800053bc:	4501                	li	a0,0
    800053be:	ffffe097          	auipc	ra,0xffffe
    800053c2:	814080e7          	jalr	-2028(ra) # 80002bd2 <argstr>
    return -1;
    800053c6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c8:	10054e63          	bltz	a0,800054e4 <sys_link+0x13c>
    800053cc:	08000613          	li	a2,128
    800053d0:	f5040593          	addi	a1,s0,-176
    800053d4:	4505                	li	a0,1
    800053d6:	ffffd097          	auipc	ra,0xffffd
    800053da:	7fc080e7          	jalr	2044(ra) # 80002bd2 <argstr>
    return -1;
    800053de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053e0:	10054263          	bltz	a0,800054e4 <sys_link+0x13c>
  begin_op();
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	cd8080e7          	jalr	-808(ra) # 800040bc <begin_op>
  if((ip = namei(old)) == 0){
    800053ec:	ed040513          	addi	a0,s0,-304
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	ac0080e7          	jalr	-1344(ra) # 80003eb0 <namei>
    800053f8:	84aa                	mv	s1,a0
    800053fa:	c551                	beqz	a0,80005486 <sys_link+0xde>
  ilock(ip);
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	304080e7          	jalr	772(ra) # 80003700 <ilock>
  if(ip->type == T_DIR){
    80005404:	04449703          	lh	a4,68(s1)
    80005408:	4785                	li	a5,1
    8000540a:	08f70463          	beq	a4,a5,80005492 <sys_link+0xea>
  ip->nlink++;
    8000540e:	04a4d783          	lhu	a5,74(s1)
    80005412:	2785                	addiw	a5,a5,1
    80005414:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005418:	8526                	mv	a0,s1
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	21c080e7          	jalr	540(ra) # 80003636 <iupdate>
  iunlock(ip);
    80005422:	8526                	mv	a0,s1
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	39e080e7          	jalr	926(ra) # 800037c2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000542c:	fd040593          	addi	a1,s0,-48
    80005430:	f5040513          	addi	a0,s0,-176
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	a9a080e7          	jalr	-1382(ra) # 80003ece <nameiparent>
    8000543c:	892a                	mv	s2,a0
    8000543e:	c935                	beqz	a0,800054b2 <sys_link+0x10a>
  ilock(dp);
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	2c0080e7          	jalr	704(ra) # 80003700 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005448:	00092703          	lw	a4,0(s2)
    8000544c:	409c                	lw	a5,0(s1)
    8000544e:	04f71d63          	bne	a4,a5,800054a8 <sys_link+0x100>
    80005452:	40d0                	lw	a2,4(s1)
    80005454:	fd040593          	addi	a1,s0,-48
    80005458:	854a                	mv	a0,s2
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	994080e7          	jalr	-1644(ra) # 80003dee <dirlink>
    80005462:	04054363          	bltz	a0,800054a8 <sys_link+0x100>
  iunlockput(dp);
    80005466:	854a                	mv	a0,s2
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	4fa080e7          	jalr	1274(ra) # 80003962 <iunlockput>
  iput(ip);
    80005470:	8526                	mv	a0,s1
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	448080e7          	jalr	1096(ra) # 800038ba <iput>
  end_op();
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	cc2080e7          	jalr	-830(ra) # 8000413c <end_op>
  return 0;
    80005482:	4781                	li	a5,0
    80005484:	a085                	j	800054e4 <sys_link+0x13c>
    end_op();
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	cb6080e7          	jalr	-842(ra) # 8000413c <end_op>
    return -1;
    8000548e:	57fd                	li	a5,-1
    80005490:	a891                	j	800054e4 <sys_link+0x13c>
    iunlockput(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	4ce080e7          	jalr	1230(ra) # 80003962 <iunlockput>
    end_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	ca0080e7          	jalr	-864(ra) # 8000413c <end_op>
    return -1;
    800054a4:	57fd                	li	a5,-1
    800054a6:	a83d                	j	800054e4 <sys_link+0x13c>
    iunlockput(dp);
    800054a8:	854a                	mv	a0,s2
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	4b8080e7          	jalr	1208(ra) # 80003962 <iunlockput>
  ilock(ip);
    800054b2:	8526                	mv	a0,s1
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	24c080e7          	jalr	588(ra) # 80003700 <ilock>
  ip->nlink--;
    800054bc:	04a4d783          	lhu	a5,74(s1)
    800054c0:	37fd                	addiw	a5,a5,-1
    800054c2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054c6:	8526                	mv	a0,s1
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	16e080e7          	jalr	366(ra) # 80003636 <iupdate>
  iunlockput(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	490080e7          	jalr	1168(ra) # 80003962 <iunlockput>
  end_op();
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	c62080e7          	jalr	-926(ra) # 8000413c <end_op>
  return -1;
    800054e2:	57fd                	li	a5,-1
}
    800054e4:	853e                	mv	a0,a5
    800054e6:	70b2                	ld	ra,296(sp)
    800054e8:	7412                	ld	s0,288(sp)
    800054ea:	64f2                	ld	s1,280(sp)
    800054ec:	6952                	ld	s2,272(sp)
    800054ee:	6155                	addi	sp,sp,304
    800054f0:	8082                	ret

00000000800054f2 <sys_unlink>:
{
    800054f2:	7151                	addi	sp,sp,-240
    800054f4:	f586                	sd	ra,232(sp)
    800054f6:	f1a2                	sd	s0,224(sp)
    800054f8:	eda6                	sd	s1,216(sp)
    800054fa:	e9ca                	sd	s2,208(sp)
    800054fc:	e5ce                	sd	s3,200(sp)
    800054fe:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005500:	08000613          	li	a2,128
    80005504:	f3040593          	addi	a1,s0,-208
    80005508:	4501                	li	a0,0
    8000550a:	ffffd097          	auipc	ra,0xffffd
    8000550e:	6c8080e7          	jalr	1736(ra) # 80002bd2 <argstr>
    80005512:	18054163          	bltz	a0,80005694 <sys_unlink+0x1a2>
  begin_op();
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	ba6080e7          	jalr	-1114(ra) # 800040bc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000551e:	fb040593          	addi	a1,s0,-80
    80005522:	f3040513          	addi	a0,s0,-208
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	9a8080e7          	jalr	-1624(ra) # 80003ece <nameiparent>
    8000552e:	84aa                	mv	s1,a0
    80005530:	c979                	beqz	a0,80005606 <sys_unlink+0x114>
  ilock(dp);
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	1ce080e7          	jalr	462(ra) # 80003700 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000553a:	00003597          	auipc	a1,0x3
    8000553e:	20658593          	addi	a1,a1,518 # 80008740 <syscalls+0x2c0>
    80005542:	fb040513          	addi	a0,s0,-80
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	67e080e7          	jalr	1662(ra) # 80003bc4 <namecmp>
    8000554e:	14050a63          	beqz	a0,800056a2 <sys_unlink+0x1b0>
    80005552:	00003597          	auipc	a1,0x3
    80005556:	1f658593          	addi	a1,a1,502 # 80008748 <syscalls+0x2c8>
    8000555a:	fb040513          	addi	a0,s0,-80
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	666080e7          	jalr	1638(ra) # 80003bc4 <namecmp>
    80005566:	12050e63          	beqz	a0,800056a2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000556a:	f2c40613          	addi	a2,s0,-212
    8000556e:	fb040593          	addi	a1,s0,-80
    80005572:	8526                	mv	a0,s1
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	66a080e7          	jalr	1642(ra) # 80003bde <dirlookup>
    8000557c:	892a                	mv	s2,a0
    8000557e:	12050263          	beqz	a0,800056a2 <sys_unlink+0x1b0>
  ilock(ip);
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	17e080e7          	jalr	382(ra) # 80003700 <ilock>
  if(ip->nlink < 1)
    8000558a:	04a91783          	lh	a5,74(s2)
    8000558e:	08f05263          	blez	a5,80005612 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005592:	04491703          	lh	a4,68(s2)
    80005596:	4785                	li	a5,1
    80005598:	08f70563          	beq	a4,a5,80005622 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000559c:	4641                	li	a2,16
    8000559e:	4581                	li	a1,0
    800055a0:	fc040513          	addi	a0,s0,-64
    800055a4:	ffffb097          	auipc	ra,0xffffb
    800055a8:	768080e7          	jalr	1896(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ac:	4741                	li	a4,16
    800055ae:	f2c42683          	lw	a3,-212(s0)
    800055b2:	fc040613          	addi	a2,s0,-64
    800055b6:	4581                	li	a1,0
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	4f0080e7          	jalr	1264(ra) # 80003aaa <writei>
    800055c2:	47c1                	li	a5,16
    800055c4:	0af51563          	bne	a0,a5,8000566e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055c8:	04491703          	lh	a4,68(s2)
    800055cc:	4785                	li	a5,1
    800055ce:	0af70863          	beq	a4,a5,8000567e <sys_unlink+0x18c>
  iunlockput(dp);
    800055d2:	8526                	mv	a0,s1
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	38e080e7          	jalr	910(ra) # 80003962 <iunlockput>
  ip->nlink--;
    800055dc:	04a95783          	lhu	a5,74(s2)
    800055e0:	37fd                	addiw	a5,a5,-1
    800055e2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055e6:	854a                	mv	a0,s2
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	04e080e7          	jalr	78(ra) # 80003636 <iupdate>
  iunlockput(ip);
    800055f0:	854a                	mv	a0,s2
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	370080e7          	jalr	880(ra) # 80003962 <iunlockput>
  end_op();
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	b42080e7          	jalr	-1214(ra) # 8000413c <end_op>
  return 0;
    80005602:	4501                	li	a0,0
    80005604:	a84d                	j	800056b6 <sys_unlink+0x1c4>
    end_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	b36080e7          	jalr	-1226(ra) # 8000413c <end_op>
    return -1;
    8000560e:	557d                	li	a0,-1
    80005610:	a05d                	j	800056b6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005612:	00003517          	auipc	a0,0x3
    80005616:	15e50513          	addi	a0,a0,350 # 80008770 <syscalls+0x2f0>
    8000561a:	ffffb097          	auipc	ra,0xffffb
    8000561e:	f2e080e7          	jalr	-210(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005622:	04c92703          	lw	a4,76(s2)
    80005626:	02000793          	li	a5,32
    8000562a:	f6e7f9e3          	bgeu	a5,a4,8000559c <sys_unlink+0xaa>
    8000562e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005632:	4741                	li	a4,16
    80005634:	86ce                	mv	a3,s3
    80005636:	f1840613          	addi	a2,s0,-232
    8000563a:	4581                	li	a1,0
    8000563c:	854a                	mv	a0,s2
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	376080e7          	jalr	886(ra) # 800039b4 <readi>
    80005646:	47c1                	li	a5,16
    80005648:	00f51b63          	bne	a0,a5,8000565e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000564c:	f1845783          	lhu	a5,-232(s0)
    80005650:	e7a1                	bnez	a5,80005698 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005652:	29c1                	addiw	s3,s3,16
    80005654:	04c92783          	lw	a5,76(s2)
    80005658:	fcf9ede3          	bltu	s3,a5,80005632 <sys_unlink+0x140>
    8000565c:	b781                	j	8000559c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000565e:	00003517          	auipc	a0,0x3
    80005662:	12a50513          	addi	a0,a0,298 # 80008788 <syscalls+0x308>
    80005666:	ffffb097          	auipc	ra,0xffffb
    8000566a:	ee2080e7          	jalr	-286(ra) # 80000548 <panic>
    panic("unlink: writei");
    8000566e:	00003517          	auipc	a0,0x3
    80005672:	13250513          	addi	a0,a0,306 # 800087a0 <syscalls+0x320>
    80005676:	ffffb097          	auipc	ra,0xffffb
    8000567a:	ed2080e7          	jalr	-302(ra) # 80000548 <panic>
    dp->nlink--;
    8000567e:	04a4d783          	lhu	a5,74(s1)
    80005682:	37fd                	addiw	a5,a5,-1
    80005684:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005688:	8526                	mv	a0,s1
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	fac080e7          	jalr	-84(ra) # 80003636 <iupdate>
    80005692:	b781                	j	800055d2 <sys_unlink+0xe0>
    return -1;
    80005694:	557d                	li	a0,-1
    80005696:	a005                	j	800056b6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005698:	854a                	mv	a0,s2
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	2c8080e7          	jalr	712(ra) # 80003962 <iunlockput>
  iunlockput(dp);
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	2be080e7          	jalr	702(ra) # 80003962 <iunlockput>
  end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	a90080e7          	jalr	-1392(ra) # 8000413c <end_op>
  return -1;
    800056b4:	557d                	li	a0,-1
}
    800056b6:	70ae                	ld	ra,232(sp)
    800056b8:	740e                	ld	s0,224(sp)
    800056ba:	64ee                	ld	s1,216(sp)
    800056bc:	694e                	ld	s2,208(sp)
    800056be:	69ae                	ld	s3,200(sp)
    800056c0:	616d                	addi	sp,sp,240
    800056c2:	8082                	ret

00000000800056c4 <sys_open>:

uint64
sys_open(void)
{
    800056c4:	7131                	addi	sp,sp,-192
    800056c6:	fd06                	sd	ra,184(sp)
    800056c8:	f922                	sd	s0,176(sp)
    800056ca:	f526                	sd	s1,168(sp)
    800056cc:	f14a                	sd	s2,160(sp)
    800056ce:	ed4e                	sd	s3,152(sp)
    800056d0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056d2:	08000613          	li	a2,128
    800056d6:	f5040593          	addi	a1,s0,-176
    800056da:	4501                	li	a0,0
    800056dc:	ffffd097          	auipc	ra,0xffffd
    800056e0:	4f6080e7          	jalr	1270(ra) # 80002bd2 <argstr>
    return -1;
    800056e4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056e6:	0c054163          	bltz	a0,800057a8 <sys_open+0xe4>
    800056ea:	f4c40593          	addi	a1,s0,-180
    800056ee:	4505                	li	a0,1
    800056f0:	ffffd097          	auipc	ra,0xffffd
    800056f4:	49e080e7          	jalr	1182(ra) # 80002b8e <argint>
    800056f8:	0a054863          	bltz	a0,800057a8 <sys_open+0xe4>

  begin_op();
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	9c0080e7          	jalr	-1600(ra) # 800040bc <begin_op>

  if(omode & O_CREATE){
    80005704:	f4c42783          	lw	a5,-180(s0)
    80005708:	2007f793          	andi	a5,a5,512
    8000570c:	cbdd                	beqz	a5,800057c2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000570e:	4681                	li	a3,0
    80005710:	4601                	li	a2,0
    80005712:	4589                	li	a1,2
    80005714:	f5040513          	addi	a0,s0,-176
    80005718:	00000097          	auipc	ra,0x0
    8000571c:	972080e7          	jalr	-1678(ra) # 8000508a <create>
    80005720:	892a                	mv	s2,a0
    if(ip == 0){
    80005722:	c959                	beqz	a0,800057b8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005724:	04491703          	lh	a4,68(s2)
    80005728:	478d                	li	a5,3
    8000572a:	00f71763          	bne	a4,a5,80005738 <sys_open+0x74>
    8000572e:	04695703          	lhu	a4,70(s2)
    80005732:	47a5                	li	a5,9
    80005734:	0ce7ec63          	bltu	a5,a4,8000580c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	d9a080e7          	jalr	-614(ra) # 800044d2 <filealloc>
    80005740:	89aa                	mv	s3,a0
    80005742:	10050263          	beqz	a0,80005846 <sys_open+0x182>
    80005746:	00000097          	auipc	ra,0x0
    8000574a:	902080e7          	jalr	-1790(ra) # 80005048 <fdalloc>
    8000574e:	84aa                	mv	s1,a0
    80005750:	0e054663          	bltz	a0,8000583c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005754:	04491703          	lh	a4,68(s2)
    80005758:	478d                	li	a5,3
    8000575a:	0cf70463          	beq	a4,a5,80005822 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000575e:	4789                	li	a5,2
    80005760:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005764:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005768:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000576c:	f4c42783          	lw	a5,-180(s0)
    80005770:	0017c713          	xori	a4,a5,1
    80005774:	8b05                	andi	a4,a4,1
    80005776:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000577a:	0037f713          	andi	a4,a5,3
    8000577e:	00e03733          	snez	a4,a4
    80005782:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005786:	4007f793          	andi	a5,a5,1024
    8000578a:	c791                	beqz	a5,80005796 <sys_open+0xd2>
    8000578c:	04491703          	lh	a4,68(s2)
    80005790:	4789                	li	a5,2
    80005792:	08f70f63          	beq	a4,a5,80005830 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005796:	854a                	mv	a0,s2
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	02a080e7          	jalr	42(ra) # 800037c2 <iunlock>
  end_op();
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	99c080e7          	jalr	-1636(ra) # 8000413c <end_op>

  return fd;
}
    800057a8:	8526                	mv	a0,s1
    800057aa:	70ea                	ld	ra,184(sp)
    800057ac:	744a                	ld	s0,176(sp)
    800057ae:	74aa                	ld	s1,168(sp)
    800057b0:	790a                	ld	s2,160(sp)
    800057b2:	69ea                	ld	s3,152(sp)
    800057b4:	6129                	addi	sp,sp,192
    800057b6:	8082                	ret
      end_op();
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	984080e7          	jalr	-1660(ra) # 8000413c <end_op>
      return -1;
    800057c0:	b7e5                	j	800057a8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057c2:	f5040513          	addi	a0,s0,-176
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	6ea080e7          	jalr	1770(ra) # 80003eb0 <namei>
    800057ce:	892a                	mv	s2,a0
    800057d0:	c905                	beqz	a0,80005800 <sys_open+0x13c>
    ilock(ip);
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	f2e080e7          	jalr	-210(ra) # 80003700 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057da:	04491703          	lh	a4,68(s2)
    800057de:	4785                	li	a5,1
    800057e0:	f4f712e3          	bne	a4,a5,80005724 <sys_open+0x60>
    800057e4:	f4c42783          	lw	a5,-180(s0)
    800057e8:	dba1                	beqz	a5,80005738 <sys_open+0x74>
      iunlockput(ip);
    800057ea:	854a                	mv	a0,s2
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	176080e7          	jalr	374(ra) # 80003962 <iunlockput>
      end_op();
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	948080e7          	jalr	-1720(ra) # 8000413c <end_op>
      return -1;
    800057fc:	54fd                	li	s1,-1
    800057fe:	b76d                	j	800057a8 <sys_open+0xe4>
      end_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	93c080e7          	jalr	-1732(ra) # 8000413c <end_op>
      return -1;
    80005808:	54fd                	li	s1,-1
    8000580a:	bf79                	j	800057a8 <sys_open+0xe4>
    iunlockput(ip);
    8000580c:	854a                	mv	a0,s2
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	154080e7          	jalr	340(ra) # 80003962 <iunlockput>
    end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	926080e7          	jalr	-1754(ra) # 8000413c <end_op>
    return -1;
    8000581e:	54fd                	li	s1,-1
    80005820:	b761                	j	800057a8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005822:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005826:	04691783          	lh	a5,70(s2)
    8000582a:	02f99223          	sh	a5,36(s3)
    8000582e:	bf2d                	j	80005768 <sys_open+0xa4>
    itrunc(ip);
    80005830:	854a                	mv	a0,s2
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	fdc080e7          	jalr	-36(ra) # 8000380e <itrunc>
    8000583a:	bfb1                	j	80005796 <sys_open+0xd2>
      fileclose(f);
    8000583c:	854e                	mv	a0,s3
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	d50080e7          	jalr	-688(ra) # 8000458e <fileclose>
    iunlockput(ip);
    80005846:	854a                	mv	a0,s2
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	11a080e7          	jalr	282(ra) # 80003962 <iunlockput>
    end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	8ec080e7          	jalr	-1812(ra) # 8000413c <end_op>
    return -1;
    80005858:	54fd                	li	s1,-1
    8000585a:	b7b9                	j	800057a8 <sys_open+0xe4>

000000008000585c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000585c:	7175                	addi	sp,sp,-144
    8000585e:	e506                	sd	ra,136(sp)
    80005860:	e122                	sd	s0,128(sp)
    80005862:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	858080e7          	jalr	-1960(ra) # 800040bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000586c:	08000613          	li	a2,128
    80005870:	f7040593          	addi	a1,s0,-144
    80005874:	4501                	li	a0,0
    80005876:	ffffd097          	auipc	ra,0xffffd
    8000587a:	35c080e7          	jalr	860(ra) # 80002bd2 <argstr>
    8000587e:	02054963          	bltz	a0,800058b0 <sys_mkdir+0x54>
    80005882:	4681                	li	a3,0
    80005884:	4601                	li	a2,0
    80005886:	4585                	li	a1,1
    80005888:	f7040513          	addi	a0,s0,-144
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	7fe080e7          	jalr	2046(ra) # 8000508a <create>
    80005894:	cd11                	beqz	a0,800058b0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	0cc080e7          	jalr	204(ra) # 80003962 <iunlockput>
  end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	89e080e7          	jalr	-1890(ra) # 8000413c <end_op>
  return 0;
    800058a6:	4501                	li	a0,0
}
    800058a8:	60aa                	ld	ra,136(sp)
    800058aa:	640a                	ld	s0,128(sp)
    800058ac:	6149                	addi	sp,sp,144
    800058ae:	8082                	ret
    end_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	88c080e7          	jalr	-1908(ra) # 8000413c <end_op>
    return -1;
    800058b8:	557d                	li	a0,-1
    800058ba:	b7fd                	j	800058a8 <sys_mkdir+0x4c>

00000000800058bc <sys_mknod>:

uint64
sys_mknod(void)
{
    800058bc:	7135                	addi	sp,sp,-160
    800058be:	ed06                	sd	ra,152(sp)
    800058c0:	e922                	sd	s0,144(sp)
    800058c2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	7f8080e7          	jalr	2040(ra) # 800040bc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058cc:	08000613          	li	a2,128
    800058d0:	f7040593          	addi	a1,s0,-144
    800058d4:	4501                	li	a0,0
    800058d6:	ffffd097          	auipc	ra,0xffffd
    800058da:	2fc080e7          	jalr	764(ra) # 80002bd2 <argstr>
    800058de:	04054a63          	bltz	a0,80005932 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058e2:	f6c40593          	addi	a1,s0,-148
    800058e6:	4505                	li	a0,1
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	2a6080e7          	jalr	678(ra) # 80002b8e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058f0:	04054163          	bltz	a0,80005932 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058f4:	f6840593          	addi	a1,s0,-152
    800058f8:	4509                	li	a0,2
    800058fa:	ffffd097          	auipc	ra,0xffffd
    800058fe:	294080e7          	jalr	660(ra) # 80002b8e <argint>
     argint(1, &major) < 0 ||
    80005902:	02054863          	bltz	a0,80005932 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005906:	f6841683          	lh	a3,-152(s0)
    8000590a:	f6c41603          	lh	a2,-148(s0)
    8000590e:	458d                	li	a1,3
    80005910:	f7040513          	addi	a0,s0,-144
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	776080e7          	jalr	1910(ra) # 8000508a <create>
     argint(2, &minor) < 0 ||
    8000591c:	c919                	beqz	a0,80005932 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	044080e7          	jalr	68(ra) # 80003962 <iunlockput>
  end_op();
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	816080e7          	jalr	-2026(ra) # 8000413c <end_op>
  return 0;
    8000592e:	4501                	li	a0,0
    80005930:	a031                	j	8000593c <sys_mknod+0x80>
    end_op();
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	80a080e7          	jalr	-2038(ra) # 8000413c <end_op>
    return -1;
    8000593a:	557d                	li	a0,-1
}
    8000593c:	60ea                	ld	ra,152(sp)
    8000593e:	644a                	ld	s0,144(sp)
    80005940:	610d                	addi	sp,sp,160
    80005942:	8082                	ret

0000000080005944 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005944:	7135                	addi	sp,sp,-160
    80005946:	ed06                	sd	ra,152(sp)
    80005948:	e922                	sd	s0,144(sp)
    8000594a:	e526                	sd	s1,136(sp)
    8000594c:	e14a                	sd	s2,128(sp)
    8000594e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005950:	ffffc097          	auipc	ra,0xffffc
    80005954:	184080e7          	jalr	388(ra) # 80001ad4 <myproc>
    80005958:	892a                	mv	s2,a0
  
  begin_op();
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	762080e7          	jalr	1890(ra) # 800040bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005962:	08000613          	li	a2,128
    80005966:	f6040593          	addi	a1,s0,-160
    8000596a:	4501                	li	a0,0
    8000596c:	ffffd097          	auipc	ra,0xffffd
    80005970:	266080e7          	jalr	614(ra) # 80002bd2 <argstr>
    80005974:	04054b63          	bltz	a0,800059ca <sys_chdir+0x86>
    80005978:	f6040513          	addi	a0,s0,-160
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	534080e7          	jalr	1332(ra) # 80003eb0 <namei>
    80005984:	84aa                	mv	s1,a0
    80005986:	c131                	beqz	a0,800059ca <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	d78080e7          	jalr	-648(ra) # 80003700 <ilock>
  if(ip->type != T_DIR){
    80005990:	04449703          	lh	a4,68(s1)
    80005994:	4785                	li	a5,1
    80005996:	04f71063          	bne	a4,a5,800059d6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000599a:	8526                	mv	a0,s1
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	e26080e7          	jalr	-474(ra) # 800037c2 <iunlock>
  iput(p->cwd);
    800059a4:	15093503          	ld	a0,336(s2)
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	f12080e7          	jalr	-238(ra) # 800038ba <iput>
  end_op();
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	78c080e7          	jalr	1932(ra) # 8000413c <end_op>
  p->cwd = ip;
    800059b8:	14993823          	sd	s1,336(s2)
  return 0;
    800059bc:	4501                	li	a0,0
}
    800059be:	60ea                	ld	ra,152(sp)
    800059c0:	644a                	ld	s0,144(sp)
    800059c2:	64aa                	ld	s1,136(sp)
    800059c4:	690a                	ld	s2,128(sp)
    800059c6:	610d                	addi	sp,sp,160
    800059c8:	8082                	ret
    end_op();
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	772080e7          	jalr	1906(ra) # 8000413c <end_op>
    return -1;
    800059d2:	557d                	li	a0,-1
    800059d4:	b7ed                	j	800059be <sys_chdir+0x7a>
    iunlockput(ip);
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	f8a080e7          	jalr	-118(ra) # 80003962 <iunlockput>
    end_op();
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	75c080e7          	jalr	1884(ra) # 8000413c <end_op>
    return -1;
    800059e8:	557d                	li	a0,-1
    800059ea:	bfd1                	j	800059be <sys_chdir+0x7a>

00000000800059ec <sys_exec>:

uint64
sys_exec(void)
{
    800059ec:	7145                	addi	sp,sp,-464
    800059ee:	e786                	sd	ra,456(sp)
    800059f0:	e3a2                	sd	s0,448(sp)
    800059f2:	ff26                	sd	s1,440(sp)
    800059f4:	fb4a                	sd	s2,432(sp)
    800059f6:	f74e                	sd	s3,424(sp)
    800059f8:	f352                	sd	s4,416(sp)
    800059fa:	ef56                	sd	s5,408(sp)
    800059fc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059fe:	08000613          	li	a2,128
    80005a02:	f4040593          	addi	a1,s0,-192
    80005a06:	4501                	li	a0,0
    80005a08:	ffffd097          	auipc	ra,0xffffd
    80005a0c:	1ca080e7          	jalr	458(ra) # 80002bd2 <argstr>
    return -1;
    80005a10:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a12:	0c054a63          	bltz	a0,80005ae6 <sys_exec+0xfa>
    80005a16:	e3840593          	addi	a1,s0,-456
    80005a1a:	4505                	li	a0,1
    80005a1c:	ffffd097          	auipc	ra,0xffffd
    80005a20:	194080e7          	jalr	404(ra) # 80002bb0 <argaddr>
    80005a24:	0c054163          	bltz	a0,80005ae6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a28:	10000613          	li	a2,256
    80005a2c:	4581                	li	a1,0
    80005a2e:	e4040513          	addi	a0,s0,-448
    80005a32:	ffffb097          	auipc	ra,0xffffb
    80005a36:	2da080e7          	jalr	730(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a3a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a3e:	89a6                	mv	s3,s1
    80005a40:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a42:	02000a13          	li	s4,32
    80005a46:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a4a:	00391513          	slli	a0,s2,0x3
    80005a4e:	e3040593          	addi	a1,s0,-464
    80005a52:	e3843783          	ld	a5,-456(s0)
    80005a56:	953e                	add	a0,a0,a5
    80005a58:	ffffd097          	auipc	ra,0xffffd
    80005a5c:	09c080e7          	jalr	156(ra) # 80002af4 <fetchaddr>
    80005a60:	02054a63          	bltz	a0,80005a94 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a64:	e3043783          	ld	a5,-464(s0)
    80005a68:	c3b9                	beqz	a5,80005aae <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a6a:	ffffb097          	auipc	ra,0xffffb
    80005a6e:	0b6080e7          	jalr	182(ra) # 80000b20 <kalloc>
    80005a72:	85aa                	mv	a1,a0
    80005a74:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a78:	cd11                	beqz	a0,80005a94 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a7a:	6605                	lui	a2,0x1
    80005a7c:	e3043503          	ld	a0,-464(s0)
    80005a80:	ffffd097          	auipc	ra,0xffffd
    80005a84:	0c6080e7          	jalr	198(ra) # 80002b46 <fetchstr>
    80005a88:	00054663          	bltz	a0,80005a94 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a8c:	0905                	addi	s2,s2,1
    80005a8e:	09a1                	addi	s3,s3,8
    80005a90:	fb491be3          	bne	s2,s4,80005a46 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a94:	10048913          	addi	s2,s1,256
    80005a98:	6088                	ld	a0,0(s1)
    80005a9a:	c529                	beqz	a0,80005ae4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a9c:	ffffb097          	auipc	ra,0xffffb
    80005aa0:	f88080e7          	jalr	-120(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa4:	04a1                	addi	s1,s1,8
    80005aa6:	ff2499e3          	bne	s1,s2,80005a98 <sys_exec+0xac>
  return -1;
    80005aaa:	597d                	li	s2,-1
    80005aac:	a82d                	j	80005ae6 <sys_exec+0xfa>
      argv[i] = 0;
    80005aae:	0a8e                	slli	s5,s5,0x3
    80005ab0:	fc040793          	addi	a5,s0,-64
    80005ab4:	9abe                	add	s5,s5,a5
    80005ab6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005aba:	e4040593          	addi	a1,s0,-448
    80005abe:	f4040513          	addi	a0,s0,-192
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	17c080e7          	jalr	380(ra) # 80004c3e <exec>
    80005aca:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005acc:	10048993          	addi	s3,s1,256
    80005ad0:	6088                	ld	a0,0(s1)
    80005ad2:	c911                	beqz	a0,80005ae6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ad4:	ffffb097          	auipc	ra,0xffffb
    80005ad8:	f50080e7          	jalr	-176(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005adc:	04a1                	addi	s1,s1,8
    80005ade:	ff3499e3          	bne	s1,s3,80005ad0 <sys_exec+0xe4>
    80005ae2:	a011                	j	80005ae6 <sys_exec+0xfa>
  return -1;
    80005ae4:	597d                	li	s2,-1
}
    80005ae6:	854a                	mv	a0,s2
    80005ae8:	60be                	ld	ra,456(sp)
    80005aea:	641e                	ld	s0,448(sp)
    80005aec:	74fa                	ld	s1,440(sp)
    80005aee:	795a                	ld	s2,432(sp)
    80005af0:	79ba                	ld	s3,424(sp)
    80005af2:	7a1a                	ld	s4,416(sp)
    80005af4:	6afa                	ld	s5,408(sp)
    80005af6:	6179                	addi	sp,sp,464
    80005af8:	8082                	ret

0000000080005afa <sys_pipe>:

uint64
sys_pipe(void)
{
    80005afa:	7139                	addi	sp,sp,-64
    80005afc:	fc06                	sd	ra,56(sp)
    80005afe:	f822                	sd	s0,48(sp)
    80005b00:	f426                	sd	s1,40(sp)
    80005b02:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b04:	ffffc097          	auipc	ra,0xffffc
    80005b08:	fd0080e7          	jalr	-48(ra) # 80001ad4 <myproc>
    80005b0c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b0e:	fd840593          	addi	a1,s0,-40
    80005b12:	4501                	li	a0,0
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	09c080e7          	jalr	156(ra) # 80002bb0 <argaddr>
    return -1;
    80005b1c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b1e:	0e054063          	bltz	a0,80005bfe <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b22:	fc840593          	addi	a1,s0,-56
    80005b26:	fd040513          	addi	a0,s0,-48
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	dba080e7          	jalr	-582(ra) # 800048e4 <pipealloc>
    return -1;
    80005b32:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b34:	0c054563          	bltz	a0,80005bfe <sys_pipe+0x104>
  fd0 = -1;
    80005b38:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b3c:	fd043503          	ld	a0,-48(s0)
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	508080e7          	jalr	1288(ra) # 80005048 <fdalloc>
    80005b48:	fca42223          	sw	a0,-60(s0)
    80005b4c:	08054c63          	bltz	a0,80005be4 <sys_pipe+0xea>
    80005b50:	fc843503          	ld	a0,-56(s0)
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	4f4080e7          	jalr	1268(ra) # 80005048 <fdalloc>
    80005b5c:	fca42023          	sw	a0,-64(s0)
    80005b60:	06054863          	bltz	a0,80005bd0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b64:	4691                	li	a3,4
    80005b66:	fc440613          	addi	a2,s0,-60
    80005b6a:	fd843583          	ld	a1,-40(s0)
    80005b6e:	68a8                	ld	a0,80(s1)
    80005b70:	ffffc097          	auipc	ra,0xffffc
    80005b74:	b6a080e7          	jalr	-1174(ra) # 800016da <copyout>
    80005b78:	02054063          	bltz	a0,80005b98 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b7c:	4691                	li	a3,4
    80005b7e:	fc040613          	addi	a2,s0,-64
    80005b82:	fd843583          	ld	a1,-40(s0)
    80005b86:	0591                	addi	a1,a1,4
    80005b88:	68a8                	ld	a0,80(s1)
    80005b8a:	ffffc097          	auipc	ra,0xffffc
    80005b8e:	b50080e7          	jalr	-1200(ra) # 800016da <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b92:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b94:	06055563          	bgez	a0,80005bfe <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b98:	fc442783          	lw	a5,-60(s0)
    80005b9c:	07e9                	addi	a5,a5,26
    80005b9e:	078e                	slli	a5,a5,0x3
    80005ba0:	97a6                	add	a5,a5,s1
    80005ba2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ba6:	fc042503          	lw	a0,-64(s0)
    80005baa:	0569                	addi	a0,a0,26
    80005bac:	050e                	slli	a0,a0,0x3
    80005bae:	9526                	add	a0,a0,s1
    80005bb0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bb4:	fd043503          	ld	a0,-48(s0)
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	9d6080e7          	jalr	-1578(ra) # 8000458e <fileclose>
    fileclose(wf);
    80005bc0:	fc843503          	ld	a0,-56(s0)
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	9ca080e7          	jalr	-1590(ra) # 8000458e <fileclose>
    return -1;
    80005bcc:	57fd                	li	a5,-1
    80005bce:	a805                	j	80005bfe <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bd0:	fc442783          	lw	a5,-60(s0)
    80005bd4:	0007c863          	bltz	a5,80005be4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bd8:	01a78513          	addi	a0,a5,26
    80005bdc:	050e                	slli	a0,a0,0x3
    80005bde:	9526                	add	a0,a0,s1
    80005be0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005be4:	fd043503          	ld	a0,-48(s0)
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	9a6080e7          	jalr	-1626(ra) # 8000458e <fileclose>
    fileclose(wf);
    80005bf0:	fc843503          	ld	a0,-56(s0)
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	99a080e7          	jalr	-1638(ra) # 8000458e <fileclose>
    return -1;
    80005bfc:	57fd                	li	a5,-1
}
    80005bfe:	853e                	mv	a0,a5
    80005c00:	70e2                	ld	ra,56(sp)
    80005c02:	7442                	ld	s0,48(sp)
    80005c04:	74a2                	ld	s1,40(sp)
    80005c06:	6121                	addi	sp,sp,64
    80005c08:	8082                	ret
    80005c0a:	0000                	unimp
    80005c0c:	0000                	unimp
	...

0000000080005c10 <kernelvec>:
    80005c10:	7111                	addi	sp,sp,-256
    80005c12:	e006                	sd	ra,0(sp)
    80005c14:	e40a                	sd	sp,8(sp)
    80005c16:	e80e                	sd	gp,16(sp)
    80005c18:	ec12                	sd	tp,24(sp)
    80005c1a:	f016                	sd	t0,32(sp)
    80005c1c:	f41a                	sd	t1,40(sp)
    80005c1e:	f81e                	sd	t2,48(sp)
    80005c20:	fc22                	sd	s0,56(sp)
    80005c22:	e0a6                	sd	s1,64(sp)
    80005c24:	e4aa                	sd	a0,72(sp)
    80005c26:	e8ae                	sd	a1,80(sp)
    80005c28:	ecb2                	sd	a2,88(sp)
    80005c2a:	f0b6                	sd	a3,96(sp)
    80005c2c:	f4ba                	sd	a4,104(sp)
    80005c2e:	f8be                	sd	a5,112(sp)
    80005c30:	fcc2                	sd	a6,120(sp)
    80005c32:	e146                	sd	a7,128(sp)
    80005c34:	e54a                	sd	s2,136(sp)
    80005c36:	e94e                	sd	s3,144(sp)
    80005c38:	ed52                	sd	s4,152(sp)
    80005c3a:	f156                	sd	s5,160(sp)
    80005c3c:	f55a                	sd	s6,168(sp)
    80005c3e:	f95e                	sd	s7,176(sp)
    80005c40:	fd62                	sd	s8,184(sp)
    80005c42:	e1e6                	sd	s9,192(sp)
    80005c44:	e5ea                	sd	s10,200(sp)
    80005c46:	e9ee                	sd	s11,208(sp)
    80005c48:	edf2                	sd	t3,216(sp)
    80005c4a:	f1f6                	sd	t4,224(sp)
    80005c4c:	f5fa                	sd	t5,232(sp)
    80005c4e:	f9fe                	sd	t6,240(sp)
    80005c50:	d71fc0ef          	jal	ra,800029c0 <kerneltrap>
    80005c54:	6082                	ld	ra,0(sp)
    80005c56:	6122                	ld	sp,8(sp)
    80005c58:	61c2                	ld	gp,16(sp)
    80005c5a:	7282                	ld	t0,32(sp)
    80005c5c:	7322                	ld	t1,40(sp)
    80005c5e:	73c2                	ld	t2,48(sp)
    80005c60:	7462                	ld	s0,56(sp)
    80005c62:	6486                	ld	s1,64(sp)
    80005c64:	6526                	ld	a0,72(sp)
    80005c66:	65c6                	ld	a1,80(sp)
    80005c68:	6666                	ld	a2,88(sp)
    80005c6a:	7686                	ld	a3,96(sp)
    80005c6c:	7726                	ld	a4,104(sp)
    80005c6e:	77c6                	ld	a5,112(sp)
    80005c70:	7866                	ld	a6,120(sp)
    80005c72:	688a                	ld	a7,128(sp)
    80005c74:	692a                	ld	s2,136(sp)
    80005c76:	69ca                	ld	s3,144(sp)
    80005c78:	6a6a                	ld	s4,152(sp)
    80005c7a:	7a8a                	ld	s5,160(sp)
    80005c7c:	7b2a                	ld	s6,168(sp)
    80005c7e:	7bca                	ld	s7,176(sp)
    80005c80:	7c6a                	ld	s8,184(sp)
    80005c82:	6c8e                	ld	s9,192(sp)
    80005c84:	6d2e                	ld	s10,200(sp)
    80005c86:	6dce                	ld	s11,208(sp)
    80005c88:	6e6e                	ld	t3,216(sp)
    80005c8a:	7e8e                	ld	t4,224(sp)
    80005c8c:	7f2e                	ld	t5,232(sp)
    80005c8e:	7fce                	ld	t6,240(sp)
    80005c90:	6111                	addi	sp,sp,256
    80005c92:	10200073          	sret
    80005c96:	00000013          	nop
    80005c9a:	00000013          	nop
    80005c9e:	0001                	nop

0000000080005ca0 <timervec>:
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	e10c                	sd	a1,0(a0)
    80005ca6:	e510                	sd	a2,8(a0)
    80005ca8:	e914                	sd	a3,16(a0)
    80005caa:	710c                	ld	a1,32(a0)
    80005cac:	7510                	ld	a2,40(a0)
    80005cae:	6194                	ld	a3,0(a1)
    80005cb0:	96b2                	add	a3,a3,a2
    80005cb2:	e194                	sd	a3,0(a1)
    80005cb4:	4589                	li	a1,2
    80005cb6:	14459073          	csrw	sip,a1
    80005cba:	6914                	ld	a3,16(a0)
    80005cbc:	6510                	ld	a2,8(a0)
    80005cbe:	610c                	ld	a1,0(a0)
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	30200073          	mret
	...

0000000080005cca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cca:	1141                	addi	sp,sp,-16
    80005ccc:	e422                	sd	s0,8(sp)
    80005cce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cd0:	0c0007b7          	lui	a5,0xc000
    80005cd4:	4705                	li	a4,1
    80005cd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cd8:	c3d8                	sw	a4,4(a5)
}
    80005cda:	6422                	ld	s0,8(sp)
    80005cdc:	0141                	addi	sp,sp,16
    80005cde:	8082                	ret

0000000080005ce0 <plicinithart>:

void
plicinithart(void)
{
    80005ce0:	1141                	addi	sp,sp,-16
    80005ce2:	e406                	sd	ra,8(sp)
    80005ce4:	e022                	sd	s0,0(sp)
    80005ce6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	dc0080e7          	jalr	-576(ra) # 80001aa8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cf0:	0085171b          	slliw	a4,a0,0x8
    80005cf4:	0c0027b7          	lui	a5,0xc002
    80005cf8:	97ba                	add	a5,a5,a4
    80005cfa:	40200713          	li	a4,1026
    80005cfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d02:	00d5151b          	slliw	a0,a0,0xd
    80005d06:	0c2017b7          	lui	a5,0xc201
    80005d0a:	953e                	add	a0,a0,a5
    80005d0c:	00052023          	sw	zero,0(a0)
}
    80005d10:	60a2                	ld	ra,8(sp)
    80005d12:	6402                	ld	s0,0(sp)
    80005d14:	0141                	addi	sp,sp,16
    80005d16:	8082                	ret

0000000080005d18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d18:	1141                	addi	sp,sp,-16
    80005d1a:	e406                	sd	ra,8(sp)
    80005d1c:	e022                	sd	s0,0(sp)
    80005d1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	d88080e7          	jalr	-632(ra) # 80001aa8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d28:	00d5179b          	slliw	a5,a0,0xd
    80005d2c:	0c201537          	lui	a0,0xc201
    80005d30:	953e                	add	a0,a0,a5
  return irq;
}
    80005d32:	4148                	lw	a0,4(a0)
    80005d34:	60a2                	ld	ra,8(sp)
    80005d36:	6402                	ld	s0,0(sp)
    80005d38:	0141                	addi	sp,sp,16
    80005d3a:	8082                	ret

0000000080005d3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d3c:	1101                	addi	sp,sp,-32
    80005d3e:	ec06                	sd	ra,24(sp)
    80005d40:	e822                	sd	s0,16(sp)
    80005d42:	e426                	sd	s1,8(sp)
    80005d44:	1000                	addi	s0,sp,32
    80005d46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	d60080e7          	jalr	-672(ra) # 80001aa8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d50:	00d5151b          	slliw	a0,a0,0xd
    80005d54:	0c2017b7          	lui	a5,0xc201
    80005d58:	97aa                	add	a5,a5,a0
    80005d5a:	c3c4                	sw	s1,4(a5)
}
    80005d5c:	60e2                	ld	ra,24(sp)
    80005d5e:	6442                	ld	s0,16(sp)
    80005d60:	64a2                	ld	s1,8(sp)
    80005d62:	6105                	addi	sp,sp,32
    80005d64:	8082                	ret

0000000080005d66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d66:	1141                	addi	sp,sp,-16
    80005d68:	e406                	sd	ra,8(sp)
    80005d6a:	e022                	sd	s0,0(sp)
    80005d6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d6e:	479d                	li	a5,7
    80005d70:	04a7cc63          	blt	a5,a0,80005dc8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d74:	0001d797          	auipc	a5,0x1d
    80005d78:	28c78793          	addi	a5,a5,652 # 80023000 <disk>
    80005d7c:	00a78733          	add	a4,a5,a0
    80005d80:	6789                	lui	a5,0x2
    80005d82:	97ba                	add	a5,a5,a4
    80005d84:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d88:	eba1                	bnez	a5,80005dd8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d8a:	00451713          	slli	a4,a0,0x4
    80005d8e:	0001f797          	auipc	a5,0x1f
    80005d92:	2727b783          	ld	a5,626(a5) # 80025000 <disk+0x2000>
    80005d96:	97ba                	add	a5,a5,a4
    80005d98:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d9c:	0001d797          	auipc	a5,0x1d
    80005da0:	26478793          	addi	a5,a5,612 # 80023000 <disk>
    80005da4:	97aa                	add	a5,a5,a0
    80005da6:	6509                	lui	a0,0x2
    80005da8:	953e                	add	a0,a0,a5
    80005daa:	4785                	li	a5,1
    80005dac:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005db0:	0001f517          	auipc	a0,0x1f
    80005db4:	26850513          	addi	a0,a0,616 # 80025018 <disk+0x2018>
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	6ae080e7          	jalr	1710(ra) # 80002466 <wakeup>
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005dc8:	00003517          	auipc	a0,0x3
    80005dcc:	9e850513          	addi	a0,a0,-1560 # 800087b0 <syscalls+0x330>
    80005dd0:	ffffa097          	auipc	ra,0xffffa
    80005dd4:	778080e7          	jalr	1912(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	9f050513          	addi	a0,a0,-1552 # 800087c8 <syscalls+0x348>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	768080e7          	jalr	1896(ra) # 80000548 <panic>

0000000080005de8 <virtio_disk_init>:
{
    80005de8:	1101                	addi	sp,sp,-32
    80005dea:	ec06                	sd	ra,24(sp)
    80005dec:	e822                	sd	s0,16(sp)
    80005dee:	e426                	sd	s1,8(sp)
    80005df0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005df2:	00003597          	auipc	a1,0x3
    80005df6:	9ee58593          	addi	a1,a1,-1554 # 800087e0 <syscalls+0x360>
    80005dfa:	0001f517          	auipc	a0,0x1f
    80005dfe:	2ae50513          	addi	a0,a0,686 # 800250a8 <disk+0x20a8>
    80005e02:	ffffb097          	auipc	ra,0xffffb
    80005e06:	d7e080e7          	jalr	-642(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e0a:	100017b7          	lui	a5,0x10001
    80005e0e:	4398                	lw	a4,0(a5)
    80005e10:	2701                	sext.w	a4,a4
    80005e12:	747277b7          	lui	a5,0x74727
    80005e16:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e1a:	0ef71163          	bne	a4,a5,80005efc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e1e:	100017b7          	lui	a5,0x10001
    80005e22:	43dc                	lw	a5,4(a5)
    80005e24:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e26:	4705                	li	a4,1
    80005e28:	0ce79a63          	bne	a5,a4,80005efc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e2c:	100017b7          	lui	a5,0x10001
    80005e30:	479c                	lw	a5,8(a5)
    80005e32:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e34:	4709                	li	a4,2
    80005e36:	0ce79363          	bne	a5,a4,80005efc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e3a:	100017b7          	lui	a5,0x10001
    80005e3e:	47d8                	lw	a4,12(a5)
    80005e40:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e42:	554d47b7          	lui	a5,0x554d4
    80005e46:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e4a:	0af71963          	bne	a4,a5,80005efc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e4e:	100017b7          	lui	a5,0x10001
    80005e52:	4705                	li	a4,1
    80005e54:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e56:	470d                	li	a4,3
    80005e58:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e5a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e5c:	c7ffe737          	lui	a4,0xc7ffe
    80005e60:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80005e64:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e66:	2701                	sext.w	a4,a4
    80005e68:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6a:	472d                	li	a4,11
    80005e6c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	473d                	li	a4,15
    80005e70:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e72:	6705                	lui	a4,0x1
    80005e74:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e76:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e7a:	5bdc                	lw	a5,52(a5)
    80005e7c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e7e:	c7d9                	beqz	a5,80005f0c <virtio_disk_init+0x124>
  if(max < NUM)
    80005e80:	471d                	li	a4,7
    80005e82:	08f77d63          	bgeu	a4,a5,80005f1c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e86:	100014b7          	lui	s1,0x10001
    80005e8a:	47a1                	li	a5,8
    80005e8c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e8e:	6609                	lui	a2,0x2
    80005e90:	4581                	li	a1,0
    80005e92:	0001d517          	auipc	a0,0x1d
    80005e96:	16e50513          	addi	a0,a0,366 # 80023000 <disk>
    80005e9a:	ffffb097          	auipc	ra,0xffffb
    80005e9e:	e72080e7          	jalr	-398(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ea2:	0001d717          	auipc	a4,0x1d
    80005ea6:	15e70713          	addi	a4,a4,350 # 80023000 <disk>
    80005eaa:	00c75793          	srli	a5,a4,0xc
    80005eae:	2781                	sext.w	a5,a5
    80005eb0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005eb2:	0001f797          	auipc	a5,0x1f
    80005eb6:	14e78793          	addi	a5,a5,334 # 80025000 <disk+0x2000>
    80005eba:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005ebc:	0001d717          	auipc	a4,0x1d
    80005ec0:	1c470713          	addi	a4,a4,452 # 80023080 <disk+0x80>
    80005ec4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005ec6:	0001e717          	auipc	a4,0x1e
    80005eca:	13a70713          	addi	a4,a4,314 # 80024000 <disk+0x1000>
    80005ece:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ed0:	4705                	li	a4,1
    80005ed2:	00e78c23          	sb	a4,24(a5)
    80005ed6:	00e78ca3          	sb	a4,25(a5)
    80005eda:	00e78d23          	sb	a4,26(a5)
    80005ede:	00e78da3          	sb	a4,27(a5)
    80005ee2:	00e78e23          	sb	a4,28(a5)
    80005ee6:	00e78ea3          	sb	a4,29(a5)
    80005eea:	00e78f23          	sb	a4,30(a5)
    80005eee:	00e78fa3          	sb	a4,31(a5)
}
    80005ef2:	60e2                	ld	ra,24(sp)
    80005ef4:	6442                	ld	s0,16(sp)
    80005ef6:	64a2                	ld	s1,8(sp)
    80005ef8:	6105                	addi	sp,sp,32
    80005efa:	8082                	ret
    panic("could not find virtio disk");
    80005efc:	00003517          	auipc	a0,0x3
    80005f00:	8f450513          	addi	a0,a0,-1804 # 800087f0 <syscalls+0x370>
    80005f04:	ffffa097          	auipc	ra,0xffffa
    80005f08:	644080e7          	jalr	1604(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f0c:	00003517          	auipc	a0,0x3
    80005f10:	90450513          	addi	a0,a0,-1788 # 80008810 <syscalls+0x390>
    80005f14:	ffffa097          	auipc	ra,0xffffa
    80005f18:	634080e7          	jalr	1588(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f1c:	00003517          	auipc	a0,0x3
    80005f20:	91450513          	addi	a0,a0,-1772 # 80008830 <syscalls+0x3b0>
    80005f24:	ffffa097          	auipc	ra,0xffffa
    80005f28:	624080e7          	jalr	1572(ra) # 80000548 <panic>

0000000080005f2c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f2c:	7119                	addi	sp,sp,-128
    80005f2e:	fc86                	sd	ra,120(sp)
    80005f30:	f8a2                	sd	s0,112(sp)
    80005f32:	f4a6                	sd	s1,104(sp)
    80005f34:	f0ca                	sd	s2,96(sp)
    80005f36:	ecce                	sd	s3,88(sp)
    80005f38:	e8d2                	sd	s4,80(sp)
    80005f3a:	e4d6                	sd	s5,72(sp)
    80005f3c:	e0da                	sd	s6,64(sp)
    80005f3e:	fc5e                	sd	s7,56(sp)
    80005f40:	f862                	sd	s8,48(sp)
    80005f42:	f466                	sd	s9,40(sp)
    80005f44:	f06a                	sd	s10,32(sp)
    80005f46:	0100                	addi	s0,sp,128
    80005f48:	892a                	mv	s2,a0
    80005f4a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f4c:	00c52c83          	lw	s9,12(a0)
    80005f50:	001c9c9b          	slliw	s9,s9,0x1
    80005f54:	1c82                	slli	s9,s9,0x20
    80005f56:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f5a:	0001f517          	auipc	a0,0x1f
    80005f5e:	14e50513          	addi	a0,a0,334 # 800250a8 <disk+0x20a8>
    80005f62:	ffffb097          	auipc	ra,0xffffb
    80005f66:	cae080e7          	jalr	-850(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    80005f6a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f6c:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f6e:	0001db97          	auipc	s7,0x1d
    80005f72:	092b8b93          	addi	s7,s7,146 # 80023000 <disk>
    80005f76:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f78:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f7a:	8a4e                	mv	s4,s3
    80005f7c:	a051                	j	80006000 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f7e:	00fb86b3          	add	a3,s7,a5
    80005f82:	96da                	add	a3,a3,s6
    80005f84:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f88:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f8a:	0207c563          	bltz	a5,80005fb4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f8e:	2485                	addiw	s1,s1,1
    80005f90:	0711                	addi	a4,a4,4
    80005f92:	23548d63          	beq	s1,s5,800061cc <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005f96:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f98:	0001f697          	auipc	a3,0x1f
    80005f9c:	08068693          	addi	a3,a3,128 # 80025018 <disk+0x2018>
    80005fa0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fa2:	0006c583          	lbu	a1,0(a3)
    80005fa6:	fde1                	bnez	a1,80005f7e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fa8:	2785                	addiw	a5,a5,1
    80005faa:	0685                	addi	a3,a3,1
    80005fac:	ff879be3          	bne	a5,s8,80005fa2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fb0:	57fd                	li	a5,-1
    80005fb2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fb4:	02905a63          	blez	s1,80005fe8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fb8:	f9042503          	lw	a0,-112(s0)
    80005fbc:	00000097          	auipc	ra,0x0
    80005fc0:	daa080e7          	jalr	-598(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80005fc4:	4785                	li	a5,1
    80005fc6:	0297d163          	bge	a5,s1,80005fe8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fca:	f9442503          	lw	a0,-108(s0)
    80005fce:	00000097          	auipc	ra,0x0
    80005fd2:	d98080e7          	jalr	-616(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80005fd6:	4789                	li	a5,2
    80005fd8:	0097d863          	bge	a5,s1,80005fe8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fdc:	f9842503          	lw	a0,-104(s0)
    80005fe0:	00000097          	auipc	ra,0x0
    80005fe4:	d86080e7          	jalr	-634(ra) # 80005d66 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fe8:	0001f597          	auipc	a1,0x1f
    80005fec:	0c058593          	addi	a1,a1,192 # 800250a8 <disk+0x20a8>
    80005ff0:	0001f517          	auipc	a0,0x1f
    80005ff4:	02850513          	addi	a0,a0,40 # 80025018 <disk+0x2018>
    80005ff8:	ffffc097          	auipc	ra,0xffffc
    80005ffc:	2e8080e7          	jalr	744(ra) # 800022e0 <sleep>
  for(int i = 0; i < 3; i++){
    80006000:	f9040713          	addi	a4,s0,-112
    80006004:	84ce                	mv	s1,s3
    80006006:	bf41                	j	80005f96 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006008:	4785                	li	a5,1
    8000600a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000600e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006012:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006016:	f9042983          	lw	s3,-112(s0)
    8000601a:	00499493          	slli	s1,s3,0x4
    8000601e:	0001fa17          	auipc	s4,0x1f
    80006022:	fe2a0a13          	addi	s4,s4,-30 # 80025000 <disk+0x2000>
    80006026:	000a3a83          	ld	s5,0(s4)
    8000602a:	9aa6                	add	s5,s5,s1
    8000602c:	f8040513          	addi	a0,s0,-128
    80006030:	ffffb097          	auipc	ra,0xffffb
    80006034:	0b8080e7          	jalr	184(ra) # 800010e8 <kvmpa>
    80006038:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000603c:	000a3783          	ld	a5,0(s4)
    80006040:	97a6                	add	a5,a5,s1
    80006042:	4741                	li	a4,16
    80006044:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006046:	000a3783          	ld	a5,0(s4)
    8000604a:	97a6                	add	a5,a5,s1
    8000604c:	4705                	li	a4,1
    8000604e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006052:	f9442703          	lw	a4,-108(s0)
    80006056:	000a3783          	ld	a5,0(s4)
    8000605a:	97a6                	add	a5,a5,s1
    8000605c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006060:	0712                	slli	a4,a4,0x4
    80006062:	000a3783          	ld	a5,0(s4)
    80006066:	97ba                	add	a5,a5,a4
    80006068:	05890693          	addi	a3,s2,88
    8000606c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000606e:	000a3783          	ld	a5,0(s4)
    80006072:	97ba                	add	a5,a5,a4
    80006074:	40000693          	li	a3,1024
    80006078:	c794                	sw	a3,8(a5)
  if(write)
    8000607a:	100d0a63          	beqz	s10,8000618e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000607e:	0001f797          	auipc	a5,0x1f
    80006082:	f827b783          	ld	a5,-126(a5) # 80025000 <disk+0x2000>
    80006086:	97ba                	add	a5,a5,a4
    80006088:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000608c:	0001d517          	auipc	a0,0x1d
    80006090:	f7450513          	addi	a0,a0,-140 # 80023000 <disk>
    80006094:	0001f797          	auipc	a5,0x1f
    80006098:	f6c78793          	addi	a5,a5,-148 # 80025000 <disk+0x2000>
    8000609c:	6394                	ld	a3,0(a5)
    8000609e:	96ba                	add	a3,a3,a4
    800060a0:	00c6d603          	lhu	a2,12(a3)
    800060a4:	00166613          	ori	a2,a2,1
    800060a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060ac:	f9842683          	lw	a3,-104(s0)
    800060b0:	6390                	ld	a2,0(a5)
    800060b2:	9732                	add	a4,a4,a2
    800060b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800060b8:	20098613          	addi	a2,s3,512
    800060bc:	0612                	slli	a2,a2,0x4
    800060be:	962a                	add	a2,a2,a0
    800060c0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060c4:	00469713          	slli	a4,a3,0x4
    800060c8:	6394                	ld	a3,0(a5)
    800060ca:	96ba                	add	a3,a3,a4
    800060cc:	6589                	lui	a1,0x2
    800060ce:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800060d2:	94ae                	add	s1,s1,a1
    800060d4:	94aa                	add	s1,s1,a0
    800060d6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800060d8:	6394                	ld	a3,0(a5)
    800060da:	96ba                	add	a3,a3,a4
    800060dc:	4585                	li	a1,1
    800060de:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060e0:	6394                	ld	a3,0(a5)
    800060e2:	96ba                	add	a3,a3,a4
    800060e4:	4509                	li	a0,2
    800060e6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800060ea:	6394                	ld	a3,0(a5)
    800060ec:	9736                	add	a4,a4,a3
    800060ee:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060f2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800060f6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800060fa:	6794                	ld	a3,8(a5)
    800060fc:	0026d703          	lhu	a4,2(a3)
    80006100:	8b1d                	andi	a4,a4,7
    80006102:	2709                	addiw	a4,a4,2
    80006104:	0706                	slli	a4,a4,0x1
    80006106:	9736                	add	a4,a4,a3
    80006108:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000610c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006110:	6798                	ld	a4,8(a5)
    80006112:	00275783          	lhu	a5,2(a4)
    80006116:	2785                	addiw	a5,a5,1
    80006118:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000611c:	100017b7          	lui	a5,0x10001
    80006120:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006124:	00492703          	lw	a4,4(s2)
    80006128:	4785                	li	a5,1
    8000612a:	02f71163          	bne	a4,a5,8000614c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000612e:	0001f997          	auipc	s3,0x1f
    80006132:	f7a98993          	addi	s3,s3,-134 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006136:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006138:	85ce                	mv	a1,s3
    8000613a:	854a                	mv	a0,s2
    8000613c:	ffffc097          	auipc	ra,0xffffc
    80006140:	1a4080e7          	jalr	420(ra) # 800022e0 <sleep>
  while(b->disk == 1) {
    80006144:	00492783          	lw	a5,4(s2)
    80006148:	fe9788e3          	beq	a5,s1,80006138 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000614c:	f9042483          	lw	s1,-112(s0)
    80006150:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006154:	00479713          	slli	a4,a5,0x4
    80006158:	0001d797          	auipc	a5,0x1d
    8000615c:	ea878793          	addi	a5,a5,-344 # 80023000 <disk>
    80006160:	97ba                	add	a5,a5,a4
    80006162:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006166:	0001f917          	auipc	s2,0x1f
    8000616a:	e9a90913          	addi	s2,s2,-358 # 80025000 <disk+0x2000>
    free_desc(i);
    8000616e:	8526                	mv	a0,s1
    80006170:	00000097          	auipc	ra,0x0
    80006174:	bf6080e7          	jalr	-1034(ra) # 80005d66 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006178:	0492                	slli	s1,s1,0x4
    8000617a:	00093783          	ld	a5,0(s2)
    8000617e:	94be                	add	s1,s1,a5
    80006180:	00c4d783          	lhu	a5,12(s1)
    80006184:	8b85                	andi	a5,a5,1
    80006186:	cf89                	beqz	a5,800061a0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006188:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000618c:	b7cd                	j	8000616e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000618e:	0001f797          	auipc	a5,0x1f
    80006192:	e727b783          	ld	a5,-398(a5) # 80025000 <disk+0x2000>
    80006196:	97ba                	add	a5,a5,a4
    80006198:	4689                	li	a3,2
    8000619a:	00d79623          	sh	a3,12(a5)
    8000619e:	b5fd                	j	8000608c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061a0:	0001f517          	auipc	a0,0x1f
    800061a4:	f0850513          	addi	a0,a0,-248 # 800250a8 <disk+0x20a8>
    800061a8:	ffffb097          	auipc	ra,0xffffb
    800061ac:	b1c080e7          	jalr	-1252(ra) # 80000cc4 <release>
}
    800061b0:	70e6                	ld	ra,120(sp)
    800061b2:	7446                	ld	s0,112(sp)
    800061b4:	74a6                	ld	s1,104(sp)
    800061b6:	7906                	ld	s2,96(sp)
    800061b8:	69e6                	ld	s3,88(sp)
    800061ba:	6a46                	ld	s4,80(sp)
    800061bc:	6aa6                	ld	s5,72(sp)
    800061be:	6b06                	ld	s6,64(sp)
    800061c0:	7be2                	ld	s7,56(sp)
    800061c2:	7c42                	ld	s8,48(sp)
    800061c4:	7ca2                	ld	s9,40(sp)
    800061c6:	7d02                	ld	s10,32(sp)
    800061c8:	6109                	addi	sp,sp,128
    800061ca:	8082                	ret
  if(write)
    800061cc:	e20d1ee3          	bnez	s10,80006008 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800061d0:	f8042023          	sw	zero,-128(s0)
    800061d4:	bd2d                	j	8000600e <virtio_disk_rw+0xe2>

00000000800061d6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061d6:	1101                	addi	sp,sp,-32
    800061d8:	ec06                	sd	ra,24(sp)
    800061da:	e822                	sd	s0,16(sp)
    800061dc:	e426                	sd	s1,8(sp)
    800061de:	e04a                	sd	s2,0(sp)
    800061e0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061e2:	0001f517          	auipc	a0,0x1f
    800061e6:	ec650513          	addi	a0,a0,-314 # 800250a8 <disk+0x20a8>
    800061ea:	ffffb097          	auipc	ra,0xffffb
    800061ee:	a26080e7          	jalr	-1498(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061f2:	0001f717          	auipc	a4,0x1f
    800061f6:	e0e70713          	addi	a4,a4,-498 # 80025000 <disk+0x2000>
    800061fa:	02075783          	lhu	a5,32(a4)
    800061fe:	6b18                	ld	a4,16(a4)
    80006200:	00275683          	lhu	a3,2(a4)
    80006204:	8ebd                	xor	a3,a3,a5
    80006206:	8a9d                	andi	a3,a3,7
    80006208:	cab9                	beqz	a3,8000625e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000620a:	0001d917          	auipc	s2,0x1d
    8000620e:	df690913          	addi	s2,s2,-522 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006212:	0001f497          	auipc	s1,0x1f
    80006216:	dee48493          	addi	s1,s1,-530 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000621a:	078e                	slli	a5,a5,0x3
    8000621c:	97ba                	add	a5,a5,a4
    8000621e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006220:	20078713          	addi	a4,a5,512
    80006224:	0712                	slli	a4,a4,0x4
    80006226:	974a                	add	a4,a4,s2
    80006228:	03074703          	lbu	a4,48(a4)
    8000622c:	ef21                	bnez	a4,80006284 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000622e:	20078793          	addi	a5,a5,512
    80006232:	0792                	slli	a5,a5,0x4
    80006234:	97ca                	add	a5,a5,s2
    80006236:	7798                	ld	a4,40(a5)
    80006238:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000623c:	7788                	ld	a0,40(a5)
    8000623e:	ffffc097          	auipc	ra,0xffffc
    80006242:	228080e7          	jalr	552(ra) # 80002466 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006246:	0204d783          	lhu	a5,32(s1)
    8000624a:	2785                	addiw	a5,a5,1
    8000624c:	8b9d                	andi	a5,a5,7
    8000624e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006252:	6898                	ld	a4,16(s1)
    80006254:	00275683          	lhu	a3,2(a4)
    80006258:	8a9d                	andi	a3,a3,7
    8000625a:	fcf690e3          	bne	a3,a5,8000621a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000625e:	10001737          	lui	a4,0x10001
    80006262:	533c                	lw	a5,96(a4)
    80006264:	8b8d                	andi	a5,a5,3
    80006266:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006268:	0001f517          	auipc	a0,0x1f
    8000626c:	e4050513          	addi	a0,a0,-448 # 800250a8 <disk+0x20a8>
    80006270:	ffffb097          	auipc	ra,0xffffb
    80006274:	a54080e7          	jalr	-1452(ra) # 80000cc4 <release>
}
    80006278:	60e2                	ld	ra,24(sp)
    8000627a:	6442                	ld	s0,16(sp)
    8000627c:	64a2                	ld	s1,8(sp)
    8000627e:	6902                	ld	s2,0(sp)
    80006280:	6105                	addi	sp,sp,32
    80006282:	8082                	ret
      panic("virtio_disk_intr status");
    80006284:	00002517          	auipc	a0,0x2
    80006288:	5cc50513          	addi	a0,a0,1484 # 80008850 <syscalls+0x3d0>
    8000628c:	ffffa097          	auipc	ra,0xffffa
    80006290:	2bc080e7          	jalr	700(ra) # 80000548 <panic>

0000000080006294 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006294:	7179                	addi	sp,sp,-48
    80006296:	f406                	sd	ra,40(sp)
    80006298:	f022                	sd	s0,32(sp)
    8000629a:	ec26                	sd	s1,24(sp)
    8000629c:	e84a                	sd	s2,16(sp)
    8000629e:	e44e                	sd	s3,8(sp)
    800062a0:	e052                	sd	s4,0(sp)
    800062a2:	1800                	addi	s0,sp,48
    800062a4:	892a                	mv	s2,a0
    800062a6:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    800062a8:	00003a17          	auipc	s4,0x3
    800062ac:	d80a0a13          	addi	s4,s4,-640 # 80009028 <stats>
    800062b0:	000a2683          	lw	a3,0(s4)
    800062b4:	00002617          	auipc	a2,0x2
    800062b8:	5b460613          	addi	a2,a2,1460 # 80008868 <syscalls+0x3e8>
    800062bc:	00000097          	auipc	ra,0x0
    800062c0:	2c2080e7          	jalr	706(ra) # 8000657e <snprintf>
    800062c4:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    800062c6:	004a2683          	lw	a3,4(s4)
    800062ca:	00002617          	auipc	a2,0x2
    800062ce:	5ae60613          	addi	a2,a2,1454 # 80008878 <syscalls+0x3f8>
    800062d2:	85ce                	mv	a1,s3
    800062d4:	954a                	add	a0,a0,s2
    800062d6:	00000097          	auipc	ra,0x0
    800062da:	2a8080e7          	jalr	680(ra) # 8000657e <snprintf>
  return n;
}
    800062de:	9d25                	addw	a0,a0,s1
    800062e0:	70a2                	ld	ra,40(sp)
    800062e2:	7402                	ld	s0,32(sp)
    800062e4:	64e2                	ld	s1,24(sp)
    800062e6:	6942                	ld	s2,16(sp)
    800062e8:	69a2                	ld	s3,8(sp)
    800062ea:	6a02                	ld	s4,0(sp)
    800062ec:	6145                	addi	sp,sp,48
    800062ee:	8082                	ret

00000000800062f0 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800062f0:	7179                	addi	sp,sp,-48
    800062f2:	f406                	sd	ra,40(sp)
    800062f4:	f022                	sd	s0,32(sp)
    800062f6:	ec26                	sd	s1,24(sp)
    800062f8:	e84a                	sd	s2,16(sp)
    800062fa:	e44e                	sd	s3,8(sp)
    800062fc:	1800                	addi	s0,sp,48
    800062fe:	89ae                	mv	s3,a1
    80006300:	84b2                	mv	s1,a2
    80006302:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006304:	ffffb097          	auipc	ra,0xffffb
    80006308:	7d0080e7          	jalr	2000(ra) # 80001ad4 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000630c:	653c                	ld	a5,72(a0)
    8000630e:	02f4ff63          	bgeu	s1,a5,8000634c <copyin_new+0x5c>
    80006312:	01248733          	add	a4,s1,s2
    80006316:	02f77d63          	bgeu	a4,a5,80006350 <copyin_new+0x60>
    8000631a:	02976d63          	bltu	a4,s1,80006354 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000631e:	0009061b          	sext.w	a2,s2
    80006322:	85a6                	mv	a1,s1
    80006324:	854e                	mv	a0,s3
    80006326:	ffffb097          	auipc	ra,0xffffb
    8000632a:	a46080e7          	jalr	-1466(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    8000632e:	00003717          	auipc	a4,0x3
    80006332:	cfa70713          	addi	a4,a4,-774 # 80009028 <stats>
    80006336:	431c                	lw	a5,0(a4)
    80006338:	2785                	addiw	a5,a5,1
    8000633a:	c31c                	sw	a5,0(a4)
  return 0;
    8000633c:	4501                	li	a0,0
}
    8000633e:	70a2                	ld	ra,40(sp)
    80006340:	7402                	ld	s0,32(sp)
    80006342:	64e2                	ld	s1,24(sp)
    80006344:	6942                	ld	s2,16(sp)
    80006346:	69a2                	ld	s3,8(sp)
    80006348:	6145                	addi	sp,sp,48
    8000634a:	8082                	ret
    return -1;
    8000634c:	557d                	li	a0,-1
    8000634e:	bfc5                	j	8000633e <copyin_new+0x4e>
    80006350:	557d                	li	a0,-1
    80006352:	b7f5                	j	8000633e <copyin_new+0x4e>
    80006354:	557d                	li	a0,-1
    80006356:	b7e5                	j	8000633e <copyin_new+0x4e>

0000000080006358 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006358:	7179                	addi	sp,sp,-48
    8000635a:	f406                	sd	ra,40(sp)
    8000635c:	f022                	sd	s0,32(sp)
    8000635e:	ec26                	sd	s1,24(sp)
    80006360:	e84a                	sd	s2,16(sp)
    80006362:	e44e                	sd	s3,8(sp)
    80006364:	1800                	addi	s0,sp,48
    80006366:	89ae                	mv	s3,a1
    80006368:	8932                	mv	s2,a2
    8000636a:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    8000636c:	ffffb097          	auipc	ra,0xffffb
    80006370:	768080e7          	jalr	1896(ra) # 80001ad4 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006374:	00003717          	auipc	a4,0x3
    80006378:	cb470713          	addi	a4,a4,-844 # 80009028 <stats>
    8000637c:	435c                	lw	a5,4(a4)
    8000637e:	2785                	addiw	a5,a5,1
    80006380:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006382:	cc85                	beqz	s1,800063ba <copyinstr_new+0x62>
    80006384:	00990833          	add	a6,s2,s1
    80006388:	87ca                	mv	a5,s2
    8000638a:	6538                	ld	a4,72(a0)
    8000638c:	00e7ff63          	bgeu	a5,a4,800063aa <copyinstr_new+0x52>
    dst[i] = s[i];
    80006390:	0007c683          	lbu	a3,0(a5)
    80006394:	41278733          	sub	a4,a5,s2
    80006398:	974e                	add	a4,a4,s3
    8000639a:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000639e:	c285                	beqz	a3,800063be <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800063a0:	0785                	addi	a5,a5,1
    800063a2:	ff0794e3          	bne	a5,a6,8000638a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    800063a6:	557d                	li	a0,-1
    800063a8:	a011                	j	800063ac <copyinstr_new+0x54>
    800063aa:	557d                	li	a0,-1
}
    800063ac:	70a2                	ld	ra,40(sp)
    800063ae:	7402                	ld	s0,32(sp)
    800063b0:	64e2                	ld	s1,24(sp)
    800063b2:	6942                	ld	s2,16(sp)
    800063b4:	69a2                	ld	s3,8(sp)
    800063b6:	6145                	addi	sp,sp,48
    800063b8:	8082                	ret
  return -1;
    800063ba:	557d                	li	a0,-1
    800063bc:	bfc5                	j	800063ac <copyinstr_new+0x54>
      return 0;
    800063be:	4501                	li	a0,0
    800063c0:	b7f5                	j	800063ac <copyinstr_new+0x54>

00000000800063c2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800063c2:	1141                	addi	sp,sp,-16
    800063c4:	e422                	sd	s0,8(sp)
    800063c6:	0800                	addi	s0,sp,16
  return -1;
}
    800063c8:	557d                	li	a0,-1
    800063ca:	6422                	ld	s0,8(sp)
    800063cc:	0141                	addi	sp,sp,16
    800063ce:	8082                	ret

00000000800063d0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800063d0:	7179                	addi	sp,sp,-48
    800063d2:	f406                	sd	ra,40(sp)
    800063d4:	f022                	sd	s0,32(sp)
    800063d6:	ec26                	sd	s1,24(sp)
    800063d8:	e84a                	sd	s2,16(sp)
    800063da:	e44e                	sd	s3,8(sp)
    800063dc:	e052                	sd	s4,0(sp)
    800063de:	1800                	addi	s0,sp,48
    800063e0:	892a                	mv	s2,a0
    800063e2:	89ae                	mv	s3,a1
    800063e4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800063e6:	00020517          	auipc	a0,0x20
    800063ea:	c1a50513          	addi	a0,a0,-998 # 80026000 <stats>
    800063ee:	ffffb097          	auipc	ra,0xffffb
    800063f2:	822080e7          	jalr	-2014(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    800063f6:	00021797          	auipc	a5,0x21
    800063fa:	c227a783          	lw	a5,-990(a5) # 80027018 <stats+0x1018>
    800063fe:	cbb5                	beqz	a5,80006472 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006400:	00021797          	auipc	a5,0x21
    80006404:	c0078793          	addi	a5,a5,-1024 # 80027000 <stats+0x1000>
    80006408:	4fd8                	lw	a4,28(a5)
    8000640a:	4f9c                	lw	a5,24(a5)
    8000640c:	9f99                	subw	a5,a5,a4
    8000640e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006412:	06d05e63          	blez	a3,8000648e <statsread+0xbe>
    if(m > n)
    80006416:	8a3e                	mv	s4,a5
    80006418:	00d4d363          	bge	s1,a3,8000641e <statsread+0x4e>
    8000641c:	8a26                	mv	s4,s1
    8000641e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006422:	86a6                	mv	a3,s1
    80006424:	00020617          	auipc	a2,0x20
    80006428:	bf460613          	addi	a2,a2,-1036 # 80026018 <stats+0x18>
    8000642c:	963a                	add	a2,a2,a4
    8000642e:	85ce                	mv	a1,s3
    80006430:	854a                	mv	a0,s2
    80006432:	ffffc097          	auipc	ra,0xffffc
    80006436:	110080e7          	jalr	272(ra) # 80002542 <either_copyout>
    8000643a:	57fd                	li	a5,-1
    8000643c:	00f50a63          	beq	a0,a5,80006450 <statsread+0x80>
      stats.off += m;
    80006440:	00021717          	auipc	a4,0x21
    80006444:	bc070713          	addi	a4,a4,-1088 # 80027000 <stats+0x1000>
    80006448:	4f5c                	lw	a5,28(a4)
    8000644a:	014787bb          	addw	a5,a5,s4
    8000644e:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006450:	00020517          	auipc	a0,0x20
    80006454:	bb050513          	addi	a0,a0,-1104 # 80026000 <stats>
    80006458:	ffffb097          	auipc	ra,0xffffb
    8000645c:	86c080e7          	jalr	-1940(ra) # 80000cc4 <release>
  return m;
}
    80006460:	8526                	mv	a0,s1
    80006462:	70a2                	ld	ra,40(sp)
    80006464:	7402                	ld	s0,32(sp)
    80006466:	64e2                	ld	s1,24(sp)
    80006468:	6942                	ld	s2,16(sp)
    8000646a:	69a2                	ld	s3,8(sp)
    8000646c:	6a02                	ld	s4,0(sp)
    8000646e:	6145                	addi	sp,sp,48
    80006470:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006472:	6585                	lui	a1,0x1
    80006474:	00020517          	auipc	a0,0x20
    80006478:	ba450513          	addi	a0,a0,-1116 # 80026018 <stats+0x18>
    8000647c:	00000097          	auipc	ra,0x0
    80006480:	e18080e7          	jalr	-488(ra) # 80006294 <statscopyin>
    80006484:	00021797          	auipc	a5,0x21
    80006488:	b8a7aa23          	sw	a0,-1132(a5) # 80027018 <stats+0x1018>
    8000648c:	bf95                	j	80006400 <statsread+0x30>
    stats.sz = 0;
    8000648e:	00021797          	auipc	a5,0x21
    80006492:	b7278793          	addi	a5,a5,-1166 # 80027000 <stats+0x1000>
    80006496:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    8000649a:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000649e:	54fd                	li	s1,-1
    800064a0:	bf45                	j	80006450 <statsread+0x80>

00000000800064a2 <statsinit>:

void
statsinit(void)
{
    800064a2:	1141                	addi	sp,sp,-16
    800064a4:	e406                	sd	ra,8(sp)
    800064a6:	e022                	sd	s0,0(sp)
    800064a8:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800064aa:	00002597          	auipc	a1,0x2
    800064ae:	3de58593          	addi	a1,a1,990 # 80008888 <syscalls+0x408>
    800064b2:	00020517          	auipc	a0,0x20
    800064b6:	b4e50513          	addi	a0,a0,-1202 # 80026000 <stats>
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	6c6080e7          	jalr	1734(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    800064c2:	0001b797          	auipc	a5,0x1b
    800064c6:	4ee78793          	addi	a5,a5,1262 # 800219b0 <devsw>
    800064ca:	00000717          	auipc	a4,0x0
    800064ce:	f0670713          	addi	a4,a4,-250 # 800063d0 <statsread>
    800064d2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800064d4:	00000717          	auipc	a4,0x0
    800064d8:	eee70713          	addi	a4,a4,-274 # 800063c2 <statswrite>
    800064dc:	f798                	sd	a4,40(a5)
}
    800064de:	60a2                	ld	ra,8(sp)
    800064e0:	6402                	ld	s0,0(sp)
    800064e2:	0141                	addi	sp,sp,16
    800064e4:	8082                	ret

00000000800064e6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800064e6:	1101                	addi	sp,sp,-32
    800064e8:	ec22                	sd	s0,24(sp)
    800064ea:	1000                	addi	s0,sp,32
    800064ec:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800064ee:	c299                	beqz	a3,800064f4 <sprintint+0xe>
    800064f0:	0805c163          	bltz	a1,80006572 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    800064f4:	2581                	sext.w	a1,a1
    800064f6:	4301                	li	t1,0

  i = 0;
    800064f8:	fe040713          	addi	a4,s0,-32
    800064fc:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800064fe:	2601                	sext.w	a2,a2
    80006500:	00002697          	auipc	a3,0x2
    80006504:	39068693          	addi	a3,a3,912 # 80008890 <digits>
    80006508:	88aa                	mv	a7,a0
    8000650a:	2505                	addiw	a0,a0,1
    8000650c:	02c5f7bb          	remuw	a5,a1,a2
    80006510:	1782                	slli	a5,a5,0x20
    80006512:	9381                	srli	a5,a5,0x20
    80006514:	97b6                	add	a5,a5,a3
    80006516:	0007c783          	lbu	a5,0(a5)
    8000651a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000651e:	0005879b          	sext.w	a5,a1
    80006522:	02c5d5bb          	divuw	a1,a1,a2
    80006526:	0705                	addi	a4,a4,1
    80006528:	fec7f0e3          	bgeu	a5,a2,80006508 <sprintint+0x22>

  if(sign)
    8000652c:	00030b63          	beqz	t1,80006542 <sprintint+0x5c>
    buf[i++] = '-';
    80006530:	ff040793          	addi	a5,s0,-16
    80006534:	97aa                	add	a5,a5,a0
    80006536:	02d00713          	li	a4,45
    8000653a:	fee78823          	sb	a4,-16(a5)
    8000653e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006542:	02a05c63          	blez	a0,8000657a <sprintint+0x94>
    80006546:	fe040793          	addi	a5,s0,-32
    8000654a:	00a78733          	add	a4,a5,a0
    8000654e:	87c2                	mv	a5,a6
    80006550:	0805                	addi	a6,a6,1
    80006552:	fff5061b          	addiw	a2,a0,-1
    80006556:	1602                	slli	a2,a2,0x20
    80006558:	9201                	srli	a2,a2,0x20
    8000655a:	9642                	add	a2,a2,a6
  *s = c;
    8000655c:	fff74683          	lbu	a3,-1(a4)
    80006560:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006564:	177d                	addi	a4,a4,-1
    80006566:	0785                	addi	a5,a5,1
    80006568:	fec79ae3          	bne	a5,a2,8000655c <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000656c:	6462                	ld	s0,24(sp)
    8000656e:	6105                	addi	sp,sp,32
    80006570:	8082                	ret
    x = -xx;
    80006572:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006576:	4305                	li	t1,1
    x = -xx;
    80006578:	b741                	j	800064f8 <sprintint+0x12>
  while(--i >= 0)
    8000657a:	4501                	li	a0,0
    8000657c:	bfc5                	j	8000656c <sprintint+0x86>

000000008000657e <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000657e:	7171                	addi	sp,sp,-176
    80006580:	fc86                	sd	ra,120(sp)
    80006582:	f8a2                	sd	s0,112(sp)
    80006584:	f4a6                	sd	s1,104(sp)
    80006586:	f0ca                	sd	s2,96(sp)
    80006588:	ecce                	sd	s3,88(sp)
    8000658a:	e8d2                	sd	s4,80(sp)
    8000658c:	e4d6                	sd	s5,72(sp)
    8000658e:	e0da                	sd	s6,64(sp)
    80006590:	fc5e                	sd	s7,56(sp)
    80006592:	f862                	sd	s8,48(sp)
    80006594:	f466                	sd	s9,40(sp)
    80006596:	f06a                	sd	s10,32(sp)
    80006598:	ec6e                	sd	s11,24(sp)
    8000659a:	0100                	addi	s0,sp,128
    8000659c:	e414                	sd	a3,8(s0)
    8000659e:	e818                	sd	a4,16(s0)
    800065a0:	ec1c                	sd	a5,24(s0)
    800065a2:	03043023          	sd	a6,32(s0)
    800065a6:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800065aa:	ca0d                	beqz	a2,800065dc <snprintf+0x5e>
    800065ac:	8baa                	mv	s7,a0
    800065ae:	89ae                	mv	s3,a1
    800065b0:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    800065b2:	00840793          	addi	a5,s0,8
    800065b6:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    800065ba:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800065bc:	4901                	li	s2,0
    800065be:	02b05763          	blez	a1,800065ec <snprintf+0x6e>
    if(c != '%'){
    800065c2:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800065c6:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800065ca:	02800d93          	li	s11,40
  *s = c;
    800065ce:	02500d13          	li	s10,37
    switch(c){
    800065d2:	07800c93          	li	s9,120
    800065d6:	06400c13          	li	s8,100
    800065da:	a01d                	j	80006600 <snprintf+0x82>
    panic("null fmt");
    800065dc:	00002517          	auipc	a0,0x2
    800065e0:	a4c50513          	addi	a0,a0,-1460 # 80008028 <etext+0x28>
    800065e4:	ffffa097          	auipc	ra,0xffffa
    800065e8:	f64080e7          	jalr	-156(ra) # 80000548 <panic>
  int off = 0;
    800065ec:	4481                	li	s1,0
    800065ee:	a86d                	j	800066a8 <snprintf+0x12a>
  *s = c;
    800065f0:	009b8733          	add	a4,s7,s1
    800065f4:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800065f8:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800065fa:	2905                	addiw	s2,s2,1
    800065fc:	0b34d663          	bge	s1,s3,800066a8 <snprintf+0x12a>
    80006600:	012a07b3          	add	a5,s4,s2
    80006604:	0007c783          	lbu	a5,0(a5)
    80006608:	0007871b          	sext.w	a4,a5
    8000660c:	cfd1                	beqz	a5,800066a8 <snprintf+0x12a>
    if(c != '%'){
    8000660e:	ff5711e3          	bne	a4,s5,800065f0 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006612:	2905                	addiw	s2,s2,1
    80006614:	012a07b3          	add	a5,s4,s2
    80006618:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000661c:	c7d1                	beqz	a5,800066a8 <snprintf+0x12a>
    switch(c){
    8000661e:	05678c63          	beq	a5,s6,80006676 <snprintf+0xf8>
    80006622:	02fb6763          	bltu	s6,a5,80006650 <snprintf+0xd2>
    80006626:	0b578763          	beq	a5,s5,800066d4 <snprintf+0x156>
    8000662a:	0b879b63          	bne	a5,s8,800066e0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000662e:	f8843783          	ld	a5,-120(s0)
    80006632:	00878713          	addi	a4,a5,8
    80006636:	f8e43423          	sd	a4,-120(s0)
    8000663a:	4685                	li	a3,1
    8000663c:	4629                	li	a2,10
    8000663e:	438c                	lw	a1,0(a5)
    80006640:	009b8533          	add	a0,s7,s1
    80006644:	00000097          	auipc	ra,0x0
    80006648:	ea2080e7          	jalr	-350(ra) # 800064e6 <sprintint>
    8000664c:	9ca9                	addw	s1,s1,a0
      break;
    8000664e:	b775                	j	800065fa <snprintf+0x7c>
    switch(c){
    80006650:	09979863          	bne	a5,s9,800066e0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006654:	f8843783          	ld	a5,-120(s0)
    80006658:	00878713          	addi	a4,a5,8
    8000665c:	f8e43423          	sd	a4,-120(s0)
    80006660:	4685                	li	a3,1
    80006662:	4641                	li	a2,16
    80006664:	438c                	lw	a1,0(a5)
    80006666:	009b8533          	add	a0,s7,s1
    8000666a:	00000097          	auipc	ra,0x0
    8000666e:	e7c080e7          	jalr	-388(ra) # 800064e6 <sprintint>
    80006672:	9ca9                	addw	s1,s1,a0
      break;
    80006674:	b759                	j	800065fa <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006676:	f8843783          	ld	a5,-120(s0)
    8000667a:	00878713          	addi	a4,a5,8
    8000667e:	f8e43423          	sd	a4,-120(s0)
    80006682:	639c                	ld	a5,0(a5)
    80006684:	c3b1                	beqz	a5,800066c8 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006686:	0007c703          	lbu	a4,0(a5)
    8000668a:	db25                	beqz	a4,800065fa <snprintf+0x7c>
    8000668c:	0134de63          	bge	s1,s3,800066a8 <snprintf+0x12a>
    80006690:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006694:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006698:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000669a:	0785                	addi	a5,a5,1
    8000669c:	0007c703          	lbu	a4,0(a5)
    800066a0:	df29                	beqz	a4,800065fa <snprintf+0x7c>
    800066a2:	0685                	addi	a3,a3,1
    800066a4:	fe9998e3          	bne	s3,s1,80006694 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    800066a8:	8526                	mv	a0,s1
    800066aa:	70e6                	ld	ra,120(sp)
    800066ac:	7446                	ld	s0,112(sp)
    800066ae:	74a6                	ld	s1,104(sp)
    800066b0:	7906                	ld	s2,96(sp)
    800066b2:	69e6                	ld	s3,88(sp)
    800066b4:	6a46                	ld	s4,80(sp)
    800066b6:	6aa6                	ld	s5,72(sp)
    800066b8:	6b06                	ld	s6,64(sp)
    800066ba:	7be2                	ld	s7,56(sp)
    800066bc:	7c42                	ld	s8,48(sp)
    800066be:	7ca2                	ld	s9,40(sp)
    800066c0:	7d02                	ld	s10,32(sp)
    800066c2:	6de2                	ld	s11,24(sp)
    800066c4:	614d                	addi	sp,sp,176
    800066c6:	8082                	ret
        s = "(null)";
    800066c8:	00002797          	auipc	a5,0x2
    800066cc:	95878793          	addi	a5,a5,-1704 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    800066d0:	876e                	mv	a4,s11
    800066d2:	bf6d                	j	8000668c <snprintf+0x10e>
  *s = c;
    800066d4:	009b87b3          	add	a5,s7,s1
    800066d8:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    800066dc:	2485                	addiw	s1,s1,1
      break;
    800066de:	bf31                	j	800065fa <snprintf+0x7c>
  *s = c;
    800066e0:	009b8733          	add	a4,s7,s1
    800066e4:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    800066e8:	0014871b          	addiw	a4,s1,1
  *s = c;
    800066ec:	975e                	add	a4,a4,s7
    800066ee:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800066f2:	2489                	addiw	s1,s1,2
      break;
    800066f4:	b719                	j	800065fa <snprintf+0x7c>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
