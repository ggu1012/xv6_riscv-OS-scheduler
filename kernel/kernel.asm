
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
    80000060:	e2478793          	addi	a5,a5,-476 # 80005e80 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e0278793          	addi	a5,a5,-510 # 80000ea8 <main>
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
    80000110:	af2080e7          	jalr	-1294(ra) # 80000bfe <acquire>
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
    8000012a:	66c080e7          	jalr	1644(ra) # 80002792 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	796080e7          	jalr	1942(ra) # 800008cc <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b64080e7          	jalr	-1180(ra) # 80000cb2 <release>

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
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	a62080e7          	jalr	-1438(ra) # 80000bfe <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	90a080e7          	jalr	-1782(ra) # 80001ad4 <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	284080e7          	jalr	644(ra) # 8000245e <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	526080e7          	jalr	1318(ra) # 8000273c <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a80080e7          	jalr	-1408(ra) # 80000cb2 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a6a080e7          	jalr	-1430(ra) # 80000cb2 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	55e080e7          	jalr	1374(ra) # 800007ee <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	54c080e7          	jalr	1356(ra) # 800007ee <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	540080e7          	jalr	1344(ra) # 800007ee <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	536080e7          	jalr	1334(ra) # 800007ee <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	926080e7          	jalr	-1754(ra) # 80000bfe <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	4f2080e7          	jalr	1266(ra) # 800027e8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	9ac080e7          	jalr	-1620(ra) # 80000cb2 <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	1c6080e7          	jalr	454(ra) # 80002610 <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	702080e7          	jalr	1794(ra) # 80000b6e <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	32a080e7          	jalr	810(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00022797          	auipc	a5,0x22
    80000480:	b7c78793          	addi	a5,a5,-1156 # 80021ff8 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b8260613          	addi	a2,a2,-1150 # 80008040 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ac250513          	addi	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b7850513          	addi	a0,a0,-1160 # 800080e8 <digits+0xa8>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	addi	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	addi	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	addi	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a56b0b13          	addi	s6,s6,-1450 # 80008040 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	5fa080e7          	jalr	1530(ra) # 80000bfe <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	addi	a0,a0,-1510 # 80008028 <etext+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c62080e7          	jalr	-926(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addiw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addiw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e32080e7          	jalr	-462(ra) # 800004a0 <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	addi	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0e080e7          	jalr	-498(ra) # 800004a0 <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	addi	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bd0080e7          	jalr	-1072(ra) # 80000280 <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc4080e7          	jalr	-1084(ra) # 80000280 <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srli	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb0080e7          	jalr	-1104(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	slli	s2,s2,0x4
    800006da:	34fd                	addiw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b8a080e7          	jalr	-1142(ra) # 80000280 <consputc>
      for(; *s; s++)
    800006fe:	0485                	addi	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	91848493          	addi	s1,s1,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b68080e7          	jalr	-1176(ra) # 80000280 <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5c080e7          	jalr	-1188(ra) # 80000280 <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b52080e7          	jalr	-1198(ra) # 80000280 <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	550080e7          	jalr	1360(ra) # 80000cb2 <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	3e6080e7          	jalr	998(ra) # 80000b6e <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079e:	1141                	addi	sp,sp,-16
    800007a0:	e406                	sd	ra,8(sp)
    800007a2:	e022                	sd	s0,0(sp)
    800007a4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a6:	100007b7          	lui	a5,0x10000
    800007aa:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ae:	f8000713          	li	a4,-128
    800007b2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b6:	470d                	li	a4,3
    800007b8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007bc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c4:	469d                	li	a3,7
    800007c6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ca:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ce:	00008597          	auipc	a1,0x8
    800007d2:	88a58593          	addi	a1,a1,-1910 # 80008058 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	addi	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	390080e7          	jalr	912(ra) # 80000b6e <initlock>
}
    800007e6:	60a2                	ld	ra,8(sp)
    800007e8:	6402                	ld	s0,0(sp)
    800007ea:	0141                	addi	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ee:	1101                	addi	sp,sp,-32
    800007f0:	ec06                	sd	ra,24(sp)
    800007f2:	e822                	sd	s0,16(sp)
    800007f4:	e426                	sd	s1,8(sp)
    800007f6:	1000                	addi	s0,sp,32
    800007f8:	84aa                	mv	s1,a0
  push_off();
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	3b8080e7          	jalr	952(ra) # 80000bb2 <push_off>

  if(panicked){
    80000802:	00008797          	auipc	a5,0x8
    80000806:	7fe7a783          	lw	a5,2046(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080e:	c391                	beqz	a5,80000812 <uartputc_sync+0x24>
    for(;;)
    80000810:	a001                	j	80000810 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000816:	0207f793          	andi	a5,a5,32
    8000081a:	dfe5                	beqz	a5,80000812 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081c:	0ff4f513          	andi	a0,s1,255
    80000820:	100007b7          	lui	a5,0x10000
    80000824:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	42a080e7          	jalr	1066(ra) # 80000c52 <pop_off>
}
    80000830:	60e2                	ld	ra,24(sp)
    80000832:	6442                	ld	s0,16(sp)
    80000834:	64a2                	ld	s1,8(sp)
    80000836:	6105                	addi	sp,sp,32
    80000838:	8082                	ret

000000008000083a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7ca7a783          	lw	a5,1994(a5) # 80009004 <uart_tx_r>
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c672703          	lw	a4,1990(a4) # 80009008 <uart_tx_w>
    8000084a:	08f70063          	beq	a4,a5,800008ca <uartstart+0x90>
{
    8000084e:	7139                	addi	sp,sp,-64
    80000850:	fc06                	sd	ra,56(sp)
    80000852:	f822                	sd	s0,48(sp)
    80000854:	f426                	sd	s1,40(sp)
    80000856:	f04a                	sd	s2,32(sp)
    80000858:	ec4e                	sd	s3,24(sp)
    8000085a:	e852                	sd	s4,16(sp)
    8000085c:	e456                	sd	s5,8(sp)
    8000085e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000860:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000864:	00011a97          	auipc	s5,0x11
    80000868:	094a8a93          	addi	s5,s5,148 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086c:	00008497          	auipc	s1,0x8
    80000870:	79848493          	addi	s1,s1,1944 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000874:	00008a17          	auipc	s4,0x8
    80000878:	794a0a13          	addi	s4,s4,1940 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000880:	02077713          	andi	a4,a4,32
    80000884:	cb15                	beqz	a4,800008b8 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000886:	00fa8733          	add	a4,s5,a5
    8000088a:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088e:	2785                	addiw	a5,a5,1
    80000890:	41f7d71b          	sraiw	a4,a5,0x1f
    80000894:	01b7571b          	srliw	a4,a4,0x1b
    80000898:	9fb9                	addw	a5,a5,a4
    8000089a:	8bfd                	andi	a5,a5,31
    8000089c:	9f99                	subw	a5,a5,a4
    8000089e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	d6e080e7          	jalr	-658(ra) # 80002610 <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	409c                	lw	a5,0(s1)
    800008b0:	000a2703          	lw	a4,0(s4)
    800008b4:	fcf714e3          	bne	a4,a5,8000087c <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	01a50513          	addi	a0,a0,26 # 800118f8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	318080e7          	jalr	792(ra) # 80000bfe <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fa:	00008697          	auipc	a3,0x8
    800008fe:	70e6a683          	lw	a3,1806(a3) # 80009008 <uart_tx_w>
    80000902:	0016879b          	addiw	a5,a3,1
    80000906:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090a:	01b7571b          	srliw	a4,a4,0x1b
    8000090e:	9fb9                	addw	a5,a5,a4
    80000910:	8bfd                	andi	a5,a5,31
    80000912:	9f99                	subw	a5,a5,a4
    80000914:	00008717          	auipc	a4,0x8
    80000918:	6f072703          	lw	a4,1776(a4) # 80009004 <uart_tx_r>
    8000091c:	04f71363          	bne	a4,a5,80000962 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000920:	00011a17          	auipc	s4,0x11
    80000924:	fd8a0a13          	addi	s4,s4,-40 # 800118f8 <uart_tx_lock>
    80000928:	00008917          	auipc	s2,0x8
    8000092c:	6dc90913          	addi	s2,s2,1756 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000930:	00008997          	auipc	s3,0x8
    80000934:	6d898993          	addi	s3,s3,1752 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000938:	85d2                	mv	a1,s4
    8000093a:	854a                	mv	a0,s2
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	b22080e7          	jalr	-1246(ra) # 8000245e <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	0009a683          	lw	a3,0(s3)
    80000948:	0016879b          	addiw	a5,a3,1
    8000094c:	41f7d71b          	sraiw	a4,a5,0x1f
    80000950:	01b7571b          	srliw	a4,a4,0x1b
    80000954:	9fb9                	addw	a5,a5,a4
    80000956:	8bfd                	andi	a5,a5,31
    80000958:	9f99                	subw	a5,a5,a4
    8000095a:	00092703          	lw	a4,0(s2)
    8000095e:	fcf70de3          	beq	a4,a5,80000938 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000962:	00011917          	auipc	s2,0x11
    80000966:	f9690913          	addi	s2,s2,-106 # 800118f8 <uart_tx_lock>
    8000096a:	96ca                	add	a3,a3,s2
    8000096c:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000970:	00008717          	auipc	a4,0x8
    80000974:	68f72c23          	sw	a5,1688(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	ec2080e7          	jalr	-318(ra) # 8000083a <uartstart>
      release(&uart_tx_lock);
    80000980:	854a                	mv	a0,s2
    80000982:	00000097          	auipc	ra,0x0
    80000986:	330080e7          	jalr	816(ra) # 80000cb2 <release>
}
    8000098a:	70a2                	ld	ra,40(sp)
    8000098c:	7402                	ld	s0,32(sp)
    8000098e:	64e2                	ld	s1,24(sp)
    80000990:	6942                	ld	s2,16(sp)
    80000992:	69a2                	ld	s3,8(sp)
    80000994:	6a02                	ld	s4,0(sp)
    80000996:	6145                	addi	sp,sp,48
    80000998:	8082                	ret

000000008000099a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099a:	1141                	addi	sp,sp,-16
    8000099c:	e422                	sd	s0,8(sp)
    8000099e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a8:	8b85                	andi	a5,a5,1
    800009aa:	cb91                	beqz	a5,800009be <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009ac:	100007b7          	lui	a5,0x10000
    800009b0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1e>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f2080e7          	jalr	-1806(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc2080e7          	jalr	-62(ra) # 8000099a <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	210080e7          	jalr	528(ra) # 80000bfe <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e44080e7          	jalr	-444(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2b2080e7          	jalr	690(ra) # 80000cb2 <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	ebb9                	bnez	a5,80000a78 <kfree+0x66>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00026797          	auipc	a5,0x26
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80027000 <end>
    80000a2e:	04f56563          	bltu	a0,a5,80000a78 <kfree+0x66>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	04f57163          	bgeu	a0,a5,80000a78 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a3a:	6605                	lui	a2,0x1
    80000a3c:	4585                	li	a1,1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	2bc080e7          	jalr	700(ra) # 80000cfa <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	1ae080e7          	jalr	430(ra) # 80000bfe <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	24e080e7          	jalr	590(ra) # 80000cb2 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
    panic("kfree");
    80000a78:	00007517          	auipc	a0,0x7
    80000a7c:	5e850513          	addi	a0,a0,1512 # 80008060 <digits+0x20>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	ac2080e7          	jalr	-1342(ra) # 80000542 <panic>

0000000080000a88 <freerange>:
{
    80000a88:	7179                	addi	sp,sp,-48
    80000a8a:	f406                	sd	ra,40(sp)
    80000a8c:	f022                	sd	s0,32(sp)
    80000a8e:	ec26                	sd	s1,24(sp)
    80000a90:	e84a                	sd	s2,16(sp)
    80000a92:	e44e                	sd	s3,8(sp)
    80000a94:	e052                	sd	s4,0(sp)
    80000a96:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a98:	6785                	lui	a5,0x1
    80000a9a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9e:	94aa                	add	s1,s1,a0
    80000aa0:	757d                	lui	a0,0xfffff
    80000aa2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa4:	94be                	add	s1,s1,a5
    80000aa6:	0095ee63          	bltu	a1,s1,80000ac2 <freerange+0x3a>
    80000aaa:	892e                	mv	s2,a1
    kfree(p);
    80000aac:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aae:	6985                	lui	s3,0x1
    kfree(p);
    80000ab0:	01448533          	add	a0,s1,s4
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	f5e080e7          	jalr	-162(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abc:	94ce                	add	s1,s1,s3
    80000abe:	fe9979e3          	bgeu	s2,s1,80000ab0 <freerange+0x28>
}
    80000ac2:	70a2                	ld	ra,40(sp)
    80000ac4:	7402                	ld	s0,32(sp)
    80000ac6:	64e2                	ld	s1,24(sp)
    80000ac8:	6942                	ld	s2,16(sp)
    80000aca:	69a2                	ld	s3,8(sp)
    80000acc:	6a02                	ld	s4,0(sp)
    80000ace:	6145                	addi	sp,sp,48
    80000ad0:	8082                	ret

0000000080000ad2 <kinit>:
{
    80000ad2:	1141                	addi	sp,sp,-16
    80000ad4:	e406                	sd	ra,8(sp)
    80000ad6:	e022                	sd	s0,0(sp)
    80000ad8:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ada:	00007597          	auipc	a1,0x7
    80000ade:	58e58593          	addi	a1,a1,1422 # 80008068 <digits+0x28>
    80000ae2:	00011517          	auipc	a0,0x11
    80000ae6:	e4e50513          	addi	a0,a0,-434 # 80011930 <kmem>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	084080e7          	jalr	132(ra) # 80000b6e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af2:	45c5                	li	a1,17
    80000af4:	05ee                	slli	a1,a1,0x1b
    80000af6:	00026517          	auipc	a0,0x26
    80000afa:	50a50513          	addi	a0,a0,1290 # 80027000 <end>
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f8a080e7          	jalr	-118(ra) # 80000a88 <freerange>
}
    80000b06:	60a2                	ld	ra,8(sp)
    80000b08:	6402                	ld	s0,0(sp)
    80000b0a:	0141                	addi	sp,sp,16
    80000b0c:	8082                	ret

0000000080000b0e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0e:	1101                	addi	sp,sp,-32
    80000b10:	ec06                	sd	ra,24(sp)
    80000b12:	e822                	sd	s0,16(sp)
    80000b14:	e426                	sd	s1,8(sp)
    80000b16:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b18:	00011497          	auipc	s1,0x11
    80000b1c:	e1848493          	addi	s1,s1,-488 # 80011930 <kmem>
    80000b20:	8526                	mv	a0,s1
    80000b22:	00000097          	auipc	ra,0x0
    80000b26:	0dc080e7          	jalr	220(ra) # 80000bfe <acquire>
  r = kmem.freelist;
    80000b2a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2c:	c885                	beqz	s1,80000b5c <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2e:	609c                	ld	a5,0(s1)
    80000b30:	00011517          	auipc	a0,0x11
    80000b34:	e0050513          	addi	a0,a0,-512 # 80011930 <kmem>
    80000b38:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	178080e7          	jalr	376(ra) # 80000cb2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b42:	6605                	lui	a2,0x1
    80000b44:	4595                	li	a1,5
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	1b2080e7          	jalr	434(ra) # 80000cfa <memset>
  return (void*)r;
}
    80000b50:	8526                	mv	a0,s1
    80000b52:	60e2                	ld	ra,24(sp)
    80000b54:	6442                	ld	s0,16(sp)
    80000b56:	64a2                	ld	s1,8(sp)
    80000b58:	6105                	addi	sp,sp,32
    80000b5a:	8082                	ret
  release(&kmem.lock);
    80000b5c:	00011517          	auipc	a0,0x11
    80000b60:	dd450513          	addi	a0,a0,-556 # 80011930 <kmem>
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	14e080e7          	jalr	334(ra) # 80000cb2 <release>
  if(r)
    80000b6c:	b7d5                	j	80000b50 <kalloc+0x42>

0000000080000b6e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6e:	1141                	addi	sp,sp,-16
    80000b70:	e422                	sd	s0,8(sp)
    80000b72:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b74:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b76:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b7a:	00053823          	sd	zero,16(a0)
}
    80000b7e:	6422                	ld	s0,8(sp)
    80000b80:	0141                	addi	sp,sp,16
    80000b82:	8082                	ret

0000000080000b84 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b84:	411c                	lw	a5,0(a0)
    80000b86:	e399                	bnez	a5,80000b8c <holding+0x8>
    80000b88:	4501                	li	a0,0
  return r;
}
    80000b8a:	8082                	ret
{
    80000b8c:	1101                	addi	sp,sp,-32
    80000b8e:	ec06                	sd	ra,24(sp)
    80000b90:	e822                	sd	s0,16(sp)
    80000b92:	e426                	sd	s1,8(sp)
    80000b94:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	6904                	ld	s1,16(a0)
    80000b98:	00001097          	auipc	ra,0x1
    80000b9c:	f20080e7          	jalr	-224(ra) # 80001ab8 <mycpu>
    80000ba0:	40a48533          	sub	a0,s1,a0
    80000ba4:	00153513          	seqz	a0,a0
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret

0000000080000bb2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb2:	1101                	addi	sp,sp,-32
    80000bb4:	ec06                	sd	ra,24(sp)
    80000bb6:	e822                	sd	s0,16(sp)
    80000bb8:	e426                	sd	s1,8(sp)
    80000bba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bbc:	100024f3          	csrr	s1,sstatus
    80000bc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bca:	00001097          	auipc	ra,0x1
    80000bce:	eee080e7          	jalr	-274(ra) # 80001ab8 <mycpu>
    80000bd2:	5d3c                	lw	a5,120(a0)
    80000bd4:	cf89                	beqz	a5,80000bee <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd6:	00001097          	auipc	ra,0x1
    80000bda:	ee2080e7          	jalr	-286(ra) # 80001ab8 <mycpu>
    80000bde:	5d3c                	lw	a5,120(a0)
    80000be0:	2785                	addiw	a5,a5,1
    80000be2:	dd3c                	sw	a5,120(a0)
}
    80000be4:	60e2                	ld	ra,24(sp)
    80000be6:	6442                	ld	s0,16(sp)
    80000be8:	64a2                	ld	s1,8(sp)
    80000bea:	6105                	addi	sp,sp,32
    80000bec:	8082                	ret
    mycpu()->intena = old;
    80000bee:	00001097          	auipc	ra,0x1
    80000bf2:	eca080e7          	jalr	-310(ra) # 80001ab8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf6:	8085                	srli	s1,s1,0x1
    80000bf8:	8885                	andi	s1,s1,1
    80000bfa:	dd64                	sw	s1,124(a0)
    80000bfc:	bfe9                	j	80000bd6 <push_off+0x24>

0000000080000bfe <acquire>:
{
    80000bfe:	1101                	addi	sp,sp,-32
    80000c00:	ec06                	sd	ra,24(sp)
    80000c02:	e822                	sd	s0,16(sp)
    80000c04:	e426                	sd	s1,8(sp)
    80000c06:	1000                	addi	s0,sp,32
    80000c08:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c0a:	00000097          	auipc	ra,0x0
    80000c0e:	fa8080e7          	jalr	-88(ra) # 80000bb2 <push_off>
  if(holding(lk))
    80000c12:	8526                	mv	a0,s1
    80000c14:	00000097          	auipc	ra,0x0
    80000c18:	f70080e7          	jalr	-144(ra) # 80000b84 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1c:	4705                	li	a4,1
  if(holding(lk))
    80000c1e:	e115                	bnez	a0,80000c42 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c20:	87ba                	mv	a5,a4
    80000c22:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c26:	2781                	sext.w	a5,a5
    80000c28:	ffe5                	bnez	a5,80000c20 <acquire+0x22>
  __sync_synchronize();
    80000c2a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	e8a080e7          	jalr	-374(ra) # 80001ab8 <mycpu>
    80000c36:	e888                	sd	a0,16(s1)
}
    80000c38:	60e2                	ld	ra,24(sp)
    80000c3a:	6442                	ld	s0,16(sp)
    80000c3c:	64a2                	ld	s1,8(sp)
    80000c3e:	6105                	addi	sp,sp,32
    80000c40:	8082                	ret
    panic("acquire");
    80000c42:	00007517          	auipc	a0,0x7
    80000c46:	42e50513          	addi	a0,a0,1070 # 80008070 <digits+0x30>
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	8f8080e7          	jalr	-1800(ra) # 80000542 <panic>

0000000080000c52 <pop_off>:

void
pop_off(void)
{
    80000c52:	1141                	addi	sp,sp,-16
    80000c54:	e406                	sd	ra,8(sp)
    80000c56:	e022                	sd	s0,0(sp)
    80000c58:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c5a:	00001097          	auipc	ra,0x1
    80000c5e:	e5e080e7          	jalr	-418(ra) # 80001ab8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c66:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c68:	e78d                	bnez	a5,80000c92 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c6a:	5d3c                	lw	a5,120(a0)
    80000c6c:	02f05b63          	blez	a5,80000ca2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c70:	37fd                	addiw	a5,a5,-1
    80000c72:	0007871b          	sext.w	a4,a5
    80000c76:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c78:	eb09                	bnez	a4,80000c8a <pop_off+0x38>
    80000c7a:	5d7c                	lw	a5,124(a0)
    80000c7c:	c799                	beqz	a5,80000c8a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c86:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c8a:	60a2                	ld	ra,8(sp)
    80000c8c:	6402                	ld	s0,0(sp)
    80000c8e:	0141                	addi	sp,sp,16
    80000c90:	8082                	ret
    panic("pop_off - interruptible");
    80000c92:	00007517          	auipc	a0,0x7
    80000c96:	3e650513          	addi	a0,a0,998 # 80008078 <digits+0x38>
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	8a8080e7          	jalr	-1880(ra) # 80000542 <panic>
    panic("pop_off");
    80000ca2:	00007517          	auipc	a0,0x7
    80000ca6:	3ee50513          	addi	a0,a0,1006 # 80008090 <digits+0x50>
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	898080e7          	jalr	-1896(ra) # 80000542 <panic>

0000000080000cb2 <release>:
{
    80000cb2:	1101                	addi	sp,sp,-32
    80000cb4:	ec06                	sd	ra,24(sp)
    80000cb6:	e822                	sd	s0,16(sp)
    80000cb8:	e426                	sd	s1,8(sp)
    80000cba:	1000                	addi	s0,sp,32
    80000cbc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	ec6080e7          	jalr	-314(ra) # 80000b84 <holding>
    80000cc6:	c115                	beqz	a0,80000cea <release+0x38>
  lk->cpu = 0;
    80000cc8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ccc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cd0:	0f50000f          	fence	iorw,ow
    80000cd4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	f7a080e7          	jalr	-134(ra) # 80000c52 <pop_off>
}
    80000ce0:	60e2                	ld	ra,24(sp)
    80000ce2:	6442                	ld	s0,16(sp)
    80000ce4:	64a2                	ld	s1,8(sp)
    80000ce6:	6105                	addi	sp,sp,32
    80000ce8:	8082                	ret
    panic("release");
    80000cea:	00007517          	auipc	a0,0x7
    80000cee:	3ae50513          	addi	a0,a0,942 # 80008098 <digits+0x58>
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	850080e7          	jalr	-1968(ra) # 80000542 <panic>

0000000080000cfa <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cfa:	1141                	addi	sp,sp,-16
    80000cfc:	e422                	sd	s0,8(sp)
    80000cfe:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d00:	ca19                	beqz	a2,80000d16 <memset+0x1c>
    80000d02:	87aa                	mv	a5,a0
    80000d04:	1602                	slli	a2,a2,0x20
    80000d06:	9201                	srli	a2,a2,0x20
    80000d08:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d10:	0785                	addi	a5,a5,1
    80000d12:	fee79de3          	bne	a5,a4,80000d0c <memset+0x12>
  }
  return dst;
}
    80000d16:	6422                	ld	s0,8(sp)
    80000d18:	0141                	addi	sp,sp,16
    80000d1a:	8082                	ret

0000000080000d1c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1c:	1141                	addi	sp,sp,-16
    80000d1e:	e422                	sd	s0,8(sp)
    80000d20:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d22:	ca05                	beqz	a2,80000d52 <memcmp+0x36>
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	1682                	slli	a3,a3,0x20
    80000d2a:	9281                	srli	a3,a3,0x20
    80000d2c:	0685                	addi	a3,a3,1
    80000d2e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d30:	00054783          	lbu	a5,0(a0)
    80000d34:	0005c703          	lbu	a4,0(a1)
    80000d38:	00e79863          	bne	a5,a4,80000d48 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3c:	0505                	addi	a0,a0,1
    80000d3e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d40:	fed518e3          	bne	a0,a3,80000d30 <memcmp+0x14>
  }

  return 0;
    80000d44:	4501                	li	a0,0
    80000d46:	a019                	j	80000d4c <memcmp+0x30>
      return *s1 - *s2;
    80000d48:	40e7853b          	subw	a0,a5,a4
}
    80000d4c:	6422                	ld	s0,8(sp)
    80000d4e:	0141                	addi	sp,sp,16
    80000d50:	8082                	ret
  return 0;
    80000d52:	4501                	li	a0,0
    80000d54:	bfe5                	j	80000d4c <memcmp+0x30>

0000000080000d56 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5c:	02a5e563          	bltu	a1,a0,80000d86 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6069b          	addiw	a3,a2,-1
    80000d64:	ce11                	beqz	a2,80000d80 <memmove+0x2a>
    80000d66:	1682                	slli	a3,a3,0x20
    80000d68:	9281                	srli	a3,a3,0x20
    80000d6a:	0685                	addi	a3,a3,1
    80000d6c:	96ae                	add	a3,a3,a1
    80000d6e:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d70:	0585                	addi	a1,a1,1
    80000d72:	0785                	addi	a5,a5,1
    80000d74:	fff5c703          	lbu	a4,-1(a1)
    80000d78:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7c:	fed59ae3          	bne	a1,a3,80000d70 <memmove+0x1a>

  return dst;
}
    80000d80:	6422                	ld	s0,8(sp)
    80000d82:	0141                	addi	sp,sp,16
    80000d84:	8082                	ret
  if(s < d && s + n > d){
    80000d86:	02061713          	slli	a4,a2,0x20
    80000d8a:	9301                	srli	a4,a4,0x20
    80000d8c:	00e587b3          	add	a5,a1,a4
    80000d90:	fcf578e3          	bgeu	a0,a5,80000d60 <memmove+0xa>
    d += n;
    80000d94:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d96:	fff6069b          	addiw	a3,a2,-1
    80000d9a:	d27d                	beqz	a2,80000d80 <memmove+0x2a>
    80000d9c:	02069613          	slli	a2,a3,0x20
    80000da0:	9201                	srli	a2,a2,0x20
    80000da2:	fff64613          	not	a2,a2
    80000da6:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da8:	17fd                	addi	a5,a5,-1
    80000daa:	177d                	addi	a4,a4,-1
    80000dac:	0007c683          	lbu	a3,0(a5)
    80000db0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db4:	fef61ae3          	bne	a2,a5,80000da8 <memmove+0x52>
    80000db8:	b7e1                	j	80000d80 <memmove+0x2a>

0000000080000dba <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dba:	1141                	addi	sp,sp,-16
    80000dbc:	e406                	sd	ra,8(sp)
    80000dbe:	e022                	sd	s0,0(sp)
    80000dc0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc2:	00000097          	auipc	ra,0x0
    80000dc6:	f94080e7          	jalr	-108(ra) # 80000d56 <memmove>
}
    80000dca:	60a2                	ld	ra,8(sp)
    80000dcc:	6402                	ld	s0,0(sp)
    80000dce:	0141                	addi	sp,sp,16
    80000dd0:	8082                	ret

0000000080000dd2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd8:	ce11                	beqz	a2,80000df4 <strncmp+0x22>
    80000dda:	00054783          	lbu	a5,0(a0)
    80000dde:	cf89                	beqz	a5,80000df8 <strncmp+0x26>
    80000de0:	0005c703          	lbu	a4,0(a1)
    80000de4:	00f71a63          	bne	a4,a5,80000df8 <strncmp+0x26>
    n--, p++, q++;
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	0505                	addi	a0,a0,1
    80000dec:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dee:	f675                	bnez	a2,80000dda <strncmp+0x8>
  if(n == 0)
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	a809                	j	80000e04 <strncmp+0x32>
    80000df4:	4501                	li	a0,0
    80000df6:	a039                	j	80000e04 <strncmp+0x32>
  if(n == 0)
    80000df8:	ca09                	beqz	a2,80000e0a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dfa:	00054503          	lbu	a0,0(a0)
    80000dfe:	0005c783          	lbu	a5,0(a1)
    80000e02:	9d1d                	subw	a0,a0,a5
}
    80000e04:	6422                	ld	s0,8(sp)
    80000e06:	0141                	addi	sp,sp,16
    80000e08:	8082                	ret
    return 0;
    80000e0a:	4501                	li	a0,0
    80000e0c:	bfe5                	j	80000e04 <strncmp+0x32>

0000000080000e0e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0e:	1141                	addi	sp,sp,-16
    80000e10:	e422                	sd	s0,8(sp)
    80000e12:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e14:	872a                	mv	a4,a0
    80000e16:	8832                	mv	a6,a2
    80000e18:	367d                	addiw	a2,a2,-1
    80000e1a:	01005963          	blez	a6,80000e2c <strncpy+0x1e>
    80000e1e:	0705                	addi	a4,a4,1
    80000e20:	0005c783          	lbu	a5,0(a1)
    80000e24:	fef70fa3          	sb	a5,-1(a4)
    80000e28:	0585                	addi	a1,a1,1
    80000e2a:	f7f5                	bnez	a5,80000e16 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2c:	86ba                	mv	a3,a4
    80000e2e:	00c05c63          	blez	a2,80000e46 <strncpy+0x38>
    *s++ = 0;
    80000e32:	0685                	addi	a3,a3,1
    80000e34:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e38:	fff6c793          	not	a5,a3
    80000e3c:	9fb9                	addw	a5,a5,a4
    80000e3e:	010787bb          	addw	a5,a5,a6
    80000e42:	fef048e3          	bgtz	a5,80000e32 <strncpy+0x24>
  return os;
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e52:	02c05363          	blez	a2,80000e78 <safestrcpy+0x2c>
    80000e56:	fff6069b          	addiw	a3,a2,-1
    80000e5a:	1682                	slli	a3,a3,0x20
    80000e5c:	9281                	srli	a3,a3,0x20
    80000e5e:	96ae                	add	a3,a3,a1
    80000e60:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e62:	00d58963          	beq	a1,a3,80000e74 <safestrcpy+0x28>
    80000e66:	0585                	addi	a1,a1,1
    80000e68:	0785                	addi	a5,a5,1
    80000e6a:	fff5c703          	lbu	a4,-1(a1)
    80000e6e:	fee78fa3          	sb	a4,-1(a5)
    80000e72:	fb65                	bnez	a4,80000e62 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e74:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e78:	6422                	ld	s0,8(sp)
    80000e7a:	0141                	addi	sp,sp,16
    80000e7c:	8082                	ret

0000000080000e7e <strlen>:

int
strlen(const char *s)
{
    80000e7e:	1141                	addi	sp,sp,-16
    80000e80:	e422                	sd	s0,8(sp)
    80000e82:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e84:	00054783          	lbu	a5,0(a0)
    80000e88:	cf91                	beqz	a5,80000ea4 <strlen+0x26>
    80000e8a:	0505                	addi	a0,a0,1
    80000e8c:	87aa                	mv	a5,a0
    80000e8e:	4685                	li	a3,1
    80000e90:	9e89                	subw	a3,a3,a0
    80000e92:	00f6853b          	addw	a0,a3,a5
    80000e96:	0785                	addi	a5,a5,1
    80000e98:	fff7c703          	lbu	a4,-1(a5)
    80000e9c:	fb7d                	bnez	a4,80000e92 <strlen+0x14>
    ;
  return n;
}
    80000e9e:	6422                	ld	s0,8(sp)
    80000ea0:	0141                	addi	sp,sp,16
    80000ea2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea4:	4501                	li	a0,0
    80000ea6:	bfe5                	j	80000e9e <strlen+0x20>

0000000080000ea8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e406                	sd	ra,8(sp)
    80000eac:	e022                	sd	s0,0(sp)
    80000eae:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	bf8080e7          	jalr	-1032(ra) # 80001aa8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb8:	00008717          	auipc	a4,0x8
    80000ebc:	15470713          	addi	a4,a4,340 # 8000900c <started>
  if(cpuid() == 0){
    80000ec0:	c139                	beqz	a0,80000f06 <main+0x5e>
    while(started == 0)
    80000ec2:	431c                	lw	a5,0(a4)
    80000ec4:	2781                	sext.w	a5,a5
    80000ec6:	dff5                	beqz	a5,80000ec2 <main+0x1a>
      ;
    __sync_synchronize();
    80000ec8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ecc:	00001097          	auipc	ra,0x1
    80000ed0:	bdc080e7          	jalr	-1060(ra) # 80001aa8 <cpuid>
    80000ed4:	85aa                	mv	a1,a0
    80000ed6:	00007517          	auipc	a0,0x7
    80000eda:	20250513          	addi	a0,a0,514 # 800080d8 <digits+0x98>
    80000ede:	fffff097          	auipc	ra,0xfffff
    80000ee2:	6ae080e7          	jalr	1710(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000ee6:	00000097          	auipc	ra,0x0
    80000eea:	0c8080e7          	jalr	200(ra) # 80000fae <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eee:	00002097          	auipc	ra,0x2
    80000ef2:	a3c080e7          	jalr	-1476(ra) # 8000292a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef6:	00005097          	auipc	ra,0x5
    80000efa:	fca080e7          	jalr	-54(ra) # 80005ec0 <plicinithart>
  }

  scheduler();        
    80000efe:	00001097          	auipc	ra,0x1
    80000f02:	1a4080e7          	jalr	420(ra) # 800020a2 <scheduler>
    consoleinit();
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	54e080e7          	jalr	1358(ra) # 80000454 <consoleinit>
    printfinit();
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	85e080e7          	jalr	-1954(ra) # 8000076c <printfinit>
    printf("\n");
    80000f16:	00007517          	auipc	a0,0x7
    80000f1a:	1d250513          	addi	a0,a0,466 # 800080e8 <digits+0xa8>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66e080e7          	jalr	1646(ra) # 8000058c <printf>
    printf("EEE3535 Operating Systems: booting xv6-riscv kernel\n");
    80000f26:	00007517          	auipc	a0,0x7
    80000f2a:	17a50513          	addi	a0,a0,378 # 800080a0 <digits+0x60>
    80000f2e:	fffff097          	auipc	ra,0xfffff
    80000f32:	65e080e7          	jalr	1630(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000f36:	00000097          	auipc	ra,0x0
    80000f3a:	b9c080e7          	jalr	-1124(ra) # 80000ad2 <kinit>
    kvminit();       // create kernel page table
    80000f3e:	00000097          	auipc	ra,0x0
    80000f42:	2a0080e7          	jalr	672(ra) # 800011de <kvminit>
    kvminithart();   // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	068080e7          	jalr	104(ra) # 80000fae <kvminithart>
    procinit();      // process table
    80000f4e:	00001097          	auipc	ra,0x1
    80000f52:	a8a080e7          	jalr	-1398(ra) # 800019d8 <procinit>
    trapinit();      // trap vectors
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	9ac080e7          	jalr	-1620(ra) # 80002902 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	9cc080e7          	jalr	-1588(ra) # 8000292a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f66:	00005097          	auipc	ra,0x5
    80000f6a:	f44080e7          	jalr	-188(ra) # 80005eaa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	f52080e7          	jalr	-174(ra) # 80005ec0 <plicinithart>
    binit();         // buffer cache
    80000f76:	00002097          	auipc	ra,0x2
    80000f7a:	0f4080e7          	jalr	244(ra) # 8000306a <binit>
    iinit();         // inode cache
    80000f7e:	00002097          	auipc	ra,0x2
    80000f82:	786080e7          	jalr	1926(ra) # 80003704 <iinit>
    fileinit();      // file table
    80000f86:	00003097          	auipc	ra,0x3
    80000f8a:	724080e7          	jalr	1828(ra) # 800046aa <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8e:	00005097          	auipc	ra,0x5
    80000f92:	03a080e7          	jalr	58(ra) # 80005fc8 <virtio_disk_init>
    userinit();      // first user process
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	e60080e7          	jalr	-416(ra) # 80001df6 <userinit>
    __sync_synchronize();
    80000f9e:	0ff0000f          	fence
    started = 1;
    80000fa2:	4785                	li	a5,1
    80000fa4:	00008717          	auipc	a4,0x8
    80000fa8:	06f72423          	sw	a5,104(a4) # 8000900c <started>
    80000fac:	bf89                	j	80000efe <main+0x56>

0000000080000fae <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fae:	1141                	addi	sp,sp,-16
    80000fb0:	e422                	sd	s0,8(sp)
    80000fb2:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	05c7b783          	ld	a5,92(a5) # 80009010 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0f850513          	addi	a0,a0,248 # 800080f0 <digits+0xb0>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	542080e7          	jalr	1346(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	b02080e7          	jalr	-1278(ra) # 80000b0e <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cde080e7          	jalr	-802(ra) # 80000cfa <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010ba:	1101                	addi	sp,sp,-32
    800010bc:	ec06                	sd	ra,24(sp)
    800010be:	e822                	sd	s0,16(sp)
    800010c0:	e426                	sd	s1,8(sp)
    800010c2:	1000                	addi	s0,sp,32
    800010c4:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010c6:	1552                	slli	a0,a0,0x34
    800010c8:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010cc:	4601                	li	a2,0
    800010ce:	00008517          	auipc	a0,0x8
    800010d2:	f4253503          	ld	a0,-190(a0) # 80009010 <kernel_pagetable>
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	efc080e7          	jalr	-260(ra) # 80000fd2 <walk>
  if(pte == 0)
    800010de:	cd09                	beqz	a0,800010f8 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010e0:	6108                	ld	a0,0(a0)
    800010e2:	00157793          	andi	a5,a0,1
    800010e6:	c38d                	beqz	a5,80001108 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010e8:	8129                	srli	a0,a0,0xa
    800010ea:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010ec:	9526                	add	a0,a0,s1
    800010ee:	60e2                	ld	ra,24(sp)
    800010f0:	6442                	ld	s0,16(sp)
    800010f2:	64a2                	ld	s1,8(sp)
    800010f4:	6105                	addi	sp,sp,32
    800010f6:	8082                	ret
    panic("kvmpa");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	00050513          	mv	a0,a0
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	442080e7          	jalr	1090(ra) # 80000542 <panic>
    panic("kvmpa");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	ff050513          	addi	a0,a0,-16 # 800080f8 <digits+0xb8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	432080e7          	jalr	1074(ra) # 80000542 <panic>

0000000080001118 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001118:	715d                	addi	sp,sp,-80
    8000111a:	e486                	sd	ra,72(sp)
    8000111c:	e0a2                	sd	s0,64(sp)
    8000111e:	fc26                	sd	s1,56(sp)
    80001120:	f84a                	sd	s2,48(sp)
    80001122:	f44e                	sd	s3,40(sp)
    80001124:	f052                	sd	s4,32(sp)
    80001126:	ec56                	sd	s5,24(sp)
    80001128:	e85a                	sd	s6,16(sp)
    8000112a:	e45e                	sd	s7,8(sp)
    8000112c:	0880                	addi	s0,sp,80
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001132:	777d                	lui	a4,0xfffff
    80001134:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001138:	167d                	addi	a2,a2,-1
    8000113a:	00b609b3          	add	s3,a2,a1
    8000113e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001142:	893e                	mv	s2,a5
    80001144:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001148:	6b85                	lui	s7,0x1
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	e7e080e7          	jalr	-386(ra) # 80000fd2 <walk>
    8000115c:	c51d                	beqz	a0,8000118a <mappages+0x72>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	andi	a5,a5,1
    80001162:	ef81                	bnez	a5,8000117a <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b1                	srli	s1,s1,0xc
    80001166:	04aa                	slli	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	ori	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	03390863          	beq	s2,s3,800011a2 <mappages+0x8a>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	bfc9                	j	8000114a <mappages+0x32>
      panic("remap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f8650513          	addi	a0,a0,-122 # 80008100 <digits+0xc0>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c0080e7          	jalr	960(ra) # 80000542 <panic>
      return -1;
    8000118a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000118c:	60a6                	ld	ra,72(sp)
    8000118e:	6406                	ld	s0,64(sp)
    80001190:	74e2                	ld	s1,56(sp)
    80001192:	7942                	ld	s2,48(sp)
    80001194:	79a2                	ld	s3,40(sp)
    80001196:	7a02                	ld	s4,32(sp)
    80001198:	6ae2                	ld	s5,24(sp)
    8000119a:	6b42                	ld	s6,16(sp)
    8000119c:	6ba2                	ld	s7,8(sp)
    8000119e:	6161                	addi	sp,sp,80
    800011a0:	8082                	ret
  return 0;
    800011a2:	4501                	li	a0,0
    800011a4:	b7e5                	j	8000118c <mappages+0x74>

00000000800011a6 <kvmmap>:
{
    800011a6:	1141                	addi	sp,sp,-16
    800011a8:	e406                	sd	ra,8(sp)
    800011aa:	e022                	sd	s0,0(sp)
    800011ac:	0800                	addi	s0,sp,16
    800011ae:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011b0:	86ae                	mv	a3,a1
    800011b2:	85aa                	mv	a1,a0
    800011b4:	00008517          	auipc	a0,0x8
    800011b8:	e5c53503          	ld	a0,-420(a0) # 80009010 <kernel_pagetable>
    800011bc:	00000097          	auipc	ra,0x0
    800011c0:	f5c080e7          	jalr	-164(ra) # 80001118 <mappages>
    800011c4:	e509                	bnez	a0,800011ce <kvmmap+0x28>
}
    800011c6:	60a2                	ld	ra,8(sp)
    800011c8:	6402                	ld	s0,0(sp)
    800011ca:	0141                	addi	sp,sp,16
    800011cc:	8082                	ret
    panic("kvmmap");
    800011ce:	00007517          	auipc	a0,0x7
    800011d2:	f3a50513          	addi	a0,a0,-198 # 80008108 <digits+0xc8>
    800011d6:	fffff097          	auipc	ra,0xfffff
    800011da:	36c080e7          	jalr	876(ra) # 80000542 <panic>

00000000800011de <kvminit>:
{
    800011de:	1101                	addi	sp,sp,-32
    800011e0:	ec06                	sd	ra,24(sp)
    800011e2:	e822                	sd	s0,16(sp)
    800011e4:	e426                	sd	s1,8(sp)
    800011e6:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	926080e7          	jalr	-1754(ra) # 80000b0e <kalloc>
    800011f0:	00008797          	auipc	a5,0x8
    800011f4:	e2a7b023          	sd	a0,-480(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800011f8:	6605                	lui	a2,0x1
    800011fa:	4581                	li	a1,0
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	afe080e7          	jalr	-1282(ra) # 80000cfa <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001204:	4699                	li	a3,6
    80001206:	6605                	lui	a2,0x1
    80001208:	100005b7          	lui	a1,0x10000
    8000120c:	10000537          	lui	a0,0x10000
    80001210:	00000097          	auipc	ra,0x0
    80001214:	f96080e7          	jalr	-106(ra) # 800011a6 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001218:	4699                	li	a3,6
    8000121a:	6605                	lui	a2,0x1
    8000121c:	100015b7          	lui	a1,0x10001
    80001220:	10001537          	lui	a0,0x10001
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f82080e7          	jalr	-126(ra) # 800011a6 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000122c:	4699                	li	a3,6
    8000122e:	6641                	lui	a2,0x10
    80001230:	020005b7          	lui	a1,0x2000
    80001234:	02000537          	lui	a0,0x2000
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	f6e080e7          	jalr	-146(ra) # 800011a6 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001240:	4699                	li	a3,6
    80001242:	00400637          	lui	a2,0x400
    80001246:	0c0005b7          	lui	a1,0xc000
    8000124a:	0c000537          	lui	a0,0xc000
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	f58080e7          	jalr	-168(ra) # 800011a6 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001256:	00007497          	auipc	s1,0x7
    8000125a:	daa48493          	addi	s1,s1,-598 # 80008000 <etext>
    8000125e:	46a9                	li	a3,10
    80001260:	80007617          	auipc	a2,0x80007
    80001264:	da060613          	addi	a2,a2,-608 # 8000 <_entry-0x7fff8000>
    80001268:	4585                	li	a1,1
    8000126a:	05fe                	slli	a1,a1,0x1f
    8000126c:	852e                	mv	a0,a1
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f38080e7          	jalr	-200(ra) # 800011a6 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001276:	4699                	li	a3,6
    80001278:	4645                	li	a2,17
    8000127a:	066e                	slli	a2,a2,0x1b
    8000127c:	8e05                	sub	a2,a2,s1
    8000127e:	85a6                	mv	a1,s1
    80001280:	8526                	mv	a0,s1
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f24080e7          	jalr	-220(ra) # 800011a6 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000128a:	46a9                	li	a3,10
    8000128c:	6605                	lui	a2,0x1
    8000128e:	00006597          	auipc	a1,0x6
    80001292:	d7258593          	addi	a1,a1,-654 # 80007000 <_trampoline>
    80001296:	04000537          	lui	a0,0x4000
    8000129a:	157d                	addi	a0,a0,-1
    8000129c:	0532                	slli	a0,a0,0xc
    8000129e:	00000097          	auipc	ra,0x0
    800012a2:	f08080e7          	jalr	-248(ra) # 800011a6 <kvmmap>
}
    800012a6:	60e2                	ld	ra,24(sp)
    800012a8:	6442                	ld	s0,16(sp)
    800012aa:	64a2                	ld	s1,8(sp)
    800012ac:	6105                	addi	sp,sp,32
    800012ae:	8082                	ret

00000000800012b0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012b0:	715d                	addi	sp,sp,-80
    800012b2:	e486                	sd	ra,72(sp)
    800012b4:	e0a2                	sd	s0,64(sp)
    800012b6:	fc26                	sd	s1,56(sp)
    800012b8:	f84a                	sd	s2,48(sp)
    800012ba:	f44e                	sd	s3,40(sp)
    800012bc:	f052                	sd	s4,32(sp)
    800012be:	ec56                	sd	s5,24(sp)
    800012c0:	e85a                	sd	s6,16(sp)
    800012c2:	e45e                	sd	s7,8(sp)
    800012c4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c6:	03459793          	slli	a5,a1,0x34
    800012ca:	e795                	bnez	a5,800012f6 <uvmunmap+0x46>
    800012cc:	8a2a                	mv	s4,a0
    800012ce:	892e                	mv	s2,a1
    800012d0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d2:	0632                	slli	a2,a2,0xc
    800012d4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012da:	6b05                	lui	s6,0x1
    800012dc:	0735e263          	bltu	a1,s3,80001340 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012e0:	60a6                	ld	ra,72(sp)
    800012e2:	6406                	ld	s0,64(sp)
    800012e4:	74e2                	ld	s1,56(sp)
    800012e6:	7942                	ld	s2,48(sp)
    800012e8:	79a2                	ld	s3,40(sp)
    800012ea:	7a02                	ld	s4,32(sp)
    800012ec:	6ae2                	ld	s5,24(sp)
    800012ee:	6b42                	ld	s6,16(sp)
    800012f0:	6ba2                	ld	s7,8(sp)
    800012f2:	6161                	addi	sp,sp,80
    800012f4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e1a50513          	addi	a0,a0,-486 # 80008110 <digits+0xd0>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	244080e7          	jalr	580(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    80001306:	00007517          	auipc	a0,0x7
    8000130a:	e2250513          	addi	a0,a0,-478 # 80008128 <digits+0xe8>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	234080e7          	jalr	564(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    80001316:	00007517          	auipc	a0,0x7
    8000131a:	e2250513          	addi	a0,a0,-478 # 80008138 <digits+0xf8>
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	224080e7          	jalr	548(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    80001326:	00007517          	auipc	a0,0x7
    8000132a:	e2a50513          	addi	a0,a0,-470 # 80008150 <digits+0x110>
    8000132e:	fffff097          	auipc	ra,0xfffff
    80001332:	214080e7          	jalr	532(ra) # 80000542 <panic>
    *pte = 0;
    80001336:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133a:	995a                	add	s2,s2,s6
    8000133c:	fb3972e3          	bgeu	s2,s3,800012e0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001340:	4601                	li	a2,0
    80001342:	85ca                	mv	a1,s2
    80001344:	8552                	mv	a0,s4
    80001346:	00000097          	auipc	ra,0x0
    8000134a:	c8c080e7          	jalr	-884(ra) # 80000fd2 <walk>
    8000134e:	84aa                	mv	s1,a0
    80001350:	d95d                	beqz	a0,80001306 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001352:	6108                	ld	a0,0(a0)
    80001354:	00157793          	andi	a5,a0,1
    80001358:	dfdd                	beqz	a5,80001316 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000135a:	3ff57793          	andi	a5,a0,1023
    8000135e:	fd7784e3          	beq	a5,s7,80001326 <uvmunmap+0x76>
    if(do_free){
    80001362:	fc0a8ae3          	beqz	s5,80001336 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001366:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001368:	0532                	slli	a0,a0,0xc
    8000136a:	fffff097          	auipc	ra,0xfffff
    8000136e:	6a8080e7          	jalr	1704(ra) # 80000a12 <kfree>
    80001372:	b7d1                	j	80001336 <uvmunmap+0x86>

0000000080001374 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001374:	1101                	addi	sp,sp,-32
    80001376:	ec06                	sd	ra,24(sp)
    80001378:	e822                	sd	s0,16(sp)
    8000137a:	e426                	sd	s1,8(sp)
    8000137c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	790080e7          	jalr	1936(ra) # 80000b0e <kalloc>
    80001386:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001388:	c519                	beqz	a0,80001396 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000138a:	6605                	lui	a2,0x1
    8000138c:	4581                	li	a1,0
    8000138e:	00000097          	auipc	ra,0x0
    80001392:	96c080e7          	jalr	-1684(ra) # 80000cfa <memset>
  return pagetable;
}
    80001396:	8526                	mv	a0,s1
    80001398:	60e2                	ld	ra,24(sp)
    8000139a:	6442                	ld	s0,16(sp)
    8000139c:	64a2                	ld	s1,8(sp)
    8000139e:	6105                	addi	sp,sp,32
    800013a0:	8082                	ret

00000000800013a2 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013a2:	7179                	addi	sp,sp,-48
    800013a4:	f406                	sd	ra,40(sp)
    800013a6:	f022                	sd	s0,32(sp)
    800013a8:	ec26                	sd	s1,24(sp)
    800013aa:	e84a                	sd	s2,16(sp)
    800013ac:	e44e                	sd	s3,8(sp)
    800013ae:	e052                	sd	s4,0(sp)
    800013b0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013b2:	6785                	lui	a5,0x1
    800013b4:	04f67863          	bgeu	a2,a5,80001404 <uvminit+0x62>
    800013b8:	8a2a                	mv	s4,a0
    800013ba:	89ae                	mv	s3,a1
    800013bc:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013be:	fffff097          	auipc	ra,0xfffff
    800013c2:	750080e7          	jalr	1872(ra) # 80000b0e <kalloc>
    800013c6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013c8:	6605                	lui	a2,0x1
    800013ca:	4581                	li	a1,0
    800013cc:	00000097          	auipc	ra,0x0
    800013d0:	92e080e7          	jalr	-1746(ra) # 80000cfa <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013d4:	4779                	li	a4,30
    800013d6:	86ca                	mv	a3,s2
    800013d8:	6605                	lui	a2,0x1
    800013da:	4581                	li	a1,0
    800013dc:	8552                	mv	a0,s4
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	d3a080e7          	jalr	-710(ra) # 80001118 <mappages>
  memmove(mem, src, sz);
    800013e6:	8626                	mv	a2,s1
    800013e8:	85ce                	mv	a1,s3
    800013ea:	854a                	mv	a0,s2
    800013ec:	00000097          	auipc	ra,0x0
    800013f0:	96a080e7          	jalr	-1686(ra) # 80000d56 <memmove>
}
    800013f4:	70a2                	ld	ra,40(sp)
    800013f6:	7402                	ld	s0,32(sp)
    800013f8:	64e2                	ld	s1,24(sp)
    800013fa:	6942                	ld	s2,16(sp)
    800013fc:	69a2                	ld	s3,8(sp)
    800013fe:	6a02                	ld	s4,0(sp)
    80001400:	6145                	addi	sp,sp,48
    80001402:	8082                	ret
    panic("inituvm: more than a page");
    80001404:	00007517          	auipc	a0,0x7
    80001408:	d6450513          	addi	a0,a0,-668 # 80008168 <digits+0x128>
    8000140c:	fffff097          	auipc	ra,0xfffff
    80001410:	136080e7          	jalr	310(ra) # 80000542 <panic>

0000000080001414 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001414:	1101                	addi	sp,sp,-32
    80001416:	ec06                	sd	ra,24(sp)
    80001418:	e822                	sd	s0,16(sp)
    8000141a:	e426                	sd	s1,8(sp)
    8000141c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000141e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001420:	00b67d63          	bgeu	a2,a1,8000143a <uvmdealloc+0x26>
    80001424:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001426:	6785                	lui	a5,0x1
    80001428:	17fd                	addi	a5,a5,-1
    8000142a:	00f60733          	add	a4,a2,a5
    8000142e:	767d                	lui	a2,0xfffff
    80001430:	8f71                	and	a4,a4,a2
    80001432:	97ae                	add	a5,a5,a1
    80001434:	8ff1                	and	a5,a5,a2
    80001436:	00f76863          	bltu	a4,a5,80001446 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000143a:	8526                	mv	a0,s1
    8000143c:	60e2                	ld	ra,24(sp)
    8000143e:	6442                	ld	s0,16(sp)
    80001440:	64a2                	ld	s1,8(sp)
    80001442:	6105                	addi	sp,sp,32
    80001444:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001446:	8f99                	sub	a5,a5,a4
    80001448:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000144a:	4685                	li	a3,1
    8000144c:	0007861b          	sext.w	a2,a5
    80001450:	85ba                	mv	a1,a4
    80001452:	00000097          	auipc	ra,0x0
    80001456:	e5e080e7          	jalr	-418(ra) # 800012b0 <uvmunmap>
    8000145a:	b7c5                	j	8000143a <uvmdealloc+0x26>

000000008000145c <uvmalloc>:
  if(newsz < oldsz)
    8000145c:	0ab66163          	bltu	a2,a1,800014fe <uvmalloc+0xa2>
{
    80001460:	7139                	addi	sp,sp,-64
    80001462:	fc06                	sd	ra,56(sp)
    80001464:	f822                	sd	s0,48(sp)
    80001466:	f426                	sd	s1,40(sp)
    80001468:	f04a                	sd	s2,32(sp)
    8000146a:	ec4e                	sd	s3,24(sp)
    8000146c:	e852                	sd	s4,16(sp)
    8000146e:	e456                	sd	s5,8(sp)
    80001470:	0080                	addi	s0,sp,64
    80001472:	8aaa                	mv	s5,a0
    80001474:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001476:	6985                	lui	s3,0x1
    80001478:	19fd                	addi	s3,s3,-1
    8000147a:	95ce                	add	a1,a1,s3
    8000147c:	79fd                	lui	s3,0xfffff
    8000147e:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	08c9f063          	bgeu	s3,a2,80001502 <uvmalloc+0xa6>
    80001486:	894e                	mv	s2,s3
    mem = kalloc();
    80001488:	fffff097          	auipc	ra,0xfffff
    8000148c:	686080e7          	jalr	1670(ra) # 80000b0e <kalloc>
    80001490:	84aa                	mv	s1,a0
    if(mem == 0){
    80001492:	c51d                	beqz	a0,800014c0 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001494:	6605                	lui	a2,0x1
    80001496:	4581                	li	a1,0
    80001498:	00000097          	auipc	ra,0x0
    8000149c:	862080e7          	jalr	-1950(ra) # 80000cfa <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014a0:	4779                	li	a4,30
    800014a2:	86a6                	mv	a3,s1
    800014a4:	6605                	lui	a2,0x1
    800014a6:	85ca                	mv	a1,s2
    800014a8:	8556                	mv	a0,s5
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	c6e080e7          	jalr	-914(ra) # 80001118 <mappages>
    800014b2:	e905                	bnez	a0,800014e2 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b4:	6785                	lui	a5,0x1
    800014b6:	993e                	add	s2,s2,a5
    800014b8:	fd4968e3          	bltu	s2,s4,80001488 <uvmalloc+0x2c>
  return newsz;
    800014bc:	8552                	mv	a0,s4
    800014be:	a809                	j	800014d0 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014c0:	864e                	mv	a2,s3
    800014c2:	85ca                	mv	a1,s2
    800014c4:	8556                	mv	a0,s5
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	f4e080e7          	jalr	-178(ra) # 80001414 <uvmdealloc>
      return 0;
    800014ce:	4501                	li	a0,0
}
    800014d0:	70e2                	ld	ra,56(sp)
    800014d2:	7442                	ld	s0,48(sp)
    800014d4:	74a2                	ld	s1,40(sp)
    800014d6:	7902                	ld	s2,32(sp)
    800014d8:	69e2                	ld	s3,24(sp)
    800014da:	6a42                	ld	s4,16(sp)
    800014dc:	6aa2                	ld	s5,8(sp)
    800014de:	6121                	addi	sp,sp,64
    800014e0:	8082                	ret
      kfree(mem);
    800014e2:	8526                	mv	a0,s1
    800014e4:	fffff097          	auipc	ra,0xfffff
    800014e8:	52e080e7          	jalr	1326(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ec:	864e                	mv	a2,s3
    800014ee:	85ca                	mv	a1,s2
    800014f0:	8556                	mv	a0,s5
    800014f2:	00000097          	auipc	ra,0x0
    800014f6:	f22080e7          	jalr	-222(ra) # 80001414 <uvmdealloc>
      return 0;
    800014fa:	4501                	li	a0,0
    800014fc:	bfd1                	j	800014d0 <uvmalloc+0x74>
    return oldsz;
    800014fe:	852e                	mv	a0,a1
}
    80001500:	8082                	ret
  return newsz;
    80001502:	8532                	mv	a0,a2
    80001504:	b7f1                	j	800014d0 <uvmalloc+0x74>

0000000080001506 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001506:	7179                	addi	sp,sp,-48
    80001508:	f406                	sd	ra,40(sp)
    8000150a:	f022                	sd	s0,32(sp)
    8000150c:	ec26                	sd	s1,24(sp)
    8000150e:	e84a                	sd	s2,16(sp)
    80001510:	e44e                	sd	s3,8(sp)
    80001512:	e052                	sd	s4,0(sp)
    80001514:	1800                	addi	s0,sp,48
    80001516:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001518:	84aa                	mv	s1,a0
    8000151a:	6905                	lui	s2,0x1
    8000151c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000151e:	4985                	li	s3,1
    80001520:	a821                	j	80001538 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001522:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001524:	0532                	slli	a0,a0,0xc
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	fe0080e7          	jalr	-32(ra) # 80001506 <freewalk>
      pagetable[i] = 0;
    8000152e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001532:	04a1                	addi	s1,s1,8
    80001534:	03248163          	beq	s1,s2,80001556 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001538:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000153a:	00f57793          	andi	a5,a0,15
    8000153e:	ff3782e3          	beq	a5,s3,80001522 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001542:	8905                	andi	a0,a0,1
    80001544:	d57d                	beqz	a0,80001532 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001546:	00007517          	auipc	a0,0x7
    8000154a:	c4250513          	addi	a0,a0,-958 # 80008188 <digits+0x148>
    8000154e:	fffff097          	auipc	ra,0xfffff
    80001552:	ff4080e7          	jalr	-12(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    80001556:	8552                	mv	a0,s4
    80001558:	fffff097          	auipc	ra,0xfffff
    8000155c:	4ba080e7          	jalr	1210(ra) # 80000a12 <kfree>
}
    80001560:	70a2                	ld	ra,40(sp)
    80001562:	7402                	ld	s0,32(sp)
    80001564:	64e2                	ld	s1,24(sp)
    80001566:	6942                	ld	s2,16(sp)
    80001568:	69a2                	ld	s3,8(sp)
    8000156a:	6a02                	ld	s4,0(sp)
    8000156c:	6145                	addi	sp,sp,48
    8000156e:	8082                	ret

0000000080001570 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001570:	1101                	addi	sp,sp,-32
    80001572:	ec06                	sd	ra,24(sp)
    80001574:	e822                	sd	s0,16(sp)
    80001576:	e426                	sd	s1,8(sp)
    80001578:	1000                	addi	s0,sp,32
    8000157a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000157c:	e999                	bnez	a1,80001592 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000157e:	8526                	mv	a0,s1
    80001580:	00000097          	auipc	ra,0x0
    80001584:	f86080e7          	jalr	-122(ra) # 80001506 <freewalk>
}
    80001588:	60e2                	ld	ra,24(sp)
    8000158a:	6442                	ld	s0,16(sp)
    8000158c:	64a2                	ld	s1,8(sp)
    8000158e:	6105                	addi	sp,sp,32
    80001590:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001592:	6605                	lui	a2,0x1
    80001594:	167d                	addi	a2,a2,-1
    80001596:	962e                	add	a2,a2,a1
    80001598:	4685                	li	a3,1
    8000159a:	8231                	srli	a2,a2,0xc
    8000159c:	4581                	li	a1,0
    8000159e:	00000097          	auipc	ra,0x0
    800015a2:	d12080e7          	jalr	-750(ra) # 800012b0 <uvmunmap>
    800015a6:	bfe1                	j	8000157e <uvmfree+0xe>

00000000800015a8 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015a8:	c679                	beqz	a2,80001676 <uvmcopy+0xce>
{
    800015aa:	715d                	addi	sp,sp,-80
    800015ac:	e486                	sd	ra,72(sp)
    800015ae:	e0a2                	sd	s0,64(sp)
    800015b0:	fc26                	sd	s1,56(sp)
    800015b2:	f84a                	sd	s2,48(sp)
    800015b4:	f44e                	sd	s3,40(sp)
    800015b6:	f052                	sd	s4,32(sp)
    800015b8:	ec56                	sd	s5,24(sp)
    800015ba:	e85a                	sd	s6,16(sp)
    800015bc:	e45e                	sd	s7,8(sp)
    800015be:	0880                	addi	s0,sp,80
    800015c0:	8b2a                	mv	s6,a0
    800015c2:	8aae                	mv	s5,a1
    800015c4:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015c8:	4601                	li	a2,0
    800015ca:	85ce                	mv	a1,s3
    800015cc:	855a                	mv	a0,s6
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	a04080e7          	jalr	-1532(ra) # 80000fd2 <walk>
    800015d6:	c531                	beqz	a0,80001622 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015d8:	6118                	ld	a4,0(a0)
    800015da:	00177793          	andi	a5,a4,1
    800015de:	cbb1                	beqz	a5,80001632 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015e0:	00a75593          	srli	a1,a4,0xa
    800015e4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015e8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ec:	fffff097          	auipc	ra,0xfffff
    800015f0:	522080e7          	jalr	1314(ra) # 80000b0e <kalloc>
    800015f4:	892a                	mv	s2,a0
    800015f6:	c939                	beqz	a0,8000164c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015f8:	6605                	lui	a2,0x1
    800015fa:	85de                	mv	a1,s7
    800015fc:	fffff097          	auipc	ra,0xfffff
    80001600:	75a080e7          	jalr	1882(ra) # 80000d56 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001604:	8726                	mv	a4,s1
    80001606:	86ca                	mv	a3,s2
    80001608:	6605                	lui	a2,0x1
    8000160a:	85ce                	mv	a1,s3
    8000160c:	8556                	mv	a0,s5
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	b0a080e7          	jalr	-1270(ra) # 80001118 <mappages>
    80001616:	e515                	bnez	a0,80001642 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001618:	6785                	lui	a5,0x1
    8000161a:	99be                	add	s3,s3,a5
    8000161c:	fb49e6e3          	bltu	s3,s4,800015c8 <uvmcopy+0x20>
    80001620:	a081                	j	80001660 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001622:	00007517          	auipc	a0,0x7
    80001626:	b7650513          	addi	a0,a0,-1162 # 80008198 <digits+0x158>
    8000162a:	fffff097          	auipc	ra,0xfffff
    8000162e:	f18080e7          	jalr	-232(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    80001632:	00007517          	auipc	a0,0x7
    80001636:	b8650513          	addi	a0,a0,-1146 # 800081b8 <digits+0x178>
    8000163a:	fffff097          	auipc	ra,0xfffff
    8000163e:	f08080e7          	jalr	-248(ra) # 80000542 <panic>
      kfree(mem);
    80001642:	854a                	mv	a0,s2
    80001644:	fffff097          	auipc	ra,0xfffff
    80001648:	3ce080e7          	jalr	974(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000164c:	4685                	li	a3,1
    8000164e:	00c9d613          	srli	a2,s3,0xc
    80001652:	4581                	li	a1,0
    80001654:	8556                	mv	a0,s5
    80001656:	00000097          	auipc	ra,0x0
    8000165a:	c5a080e7          	jalr	-934(ra) # 800012b0 <uvmunmap>
  return -1;
    8000165e:	557d                	li	a0,-1
}
    80001660:	60a6                	ld	ra,72(sp)
    80001662:	6406                	ld	s0,64(sp)
    80001664:	74e2                	ld	s1,56(sp)
    80001666:	7942                	ld	s2,48(sp)
    80001668:	79a2                	ld	s3,40(sp)
    8000166a:	7a02                	ld	s4,32(sp)
    8000166c:	6ae2                	ld	s5,24(sp)
    8000166e:	6b42                	ld	s6,16(sp)
    80001670:	6ba2                	ld	s7,8(sp)
    80001672:	6161                	addi	sp,sp,80
    80001674:	8082                	ret
  return 0;
    80001676:	4501                	li	a0,0
}
    80001678:	8082                	ret

000000008000167a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000167a:	1141                	addi	sp,sp,-16
    8000167c:	e406                	sd	ra,8(sp)
    8000167e:	e022                	sd	s0,0(sp)
    80001680:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001682:	4601                	li	a2,0
    80001684:	00000097          	auipc	ra,0x0
    80001688:	94e080e7          	jalr	-1714(ra) # 80000fd2 <walk>
  if(pte == 0)
    8000168c:	c901                	beqz	a0,8000169c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000168e:	611c                	ld	a5,0(a0)
    80001690:	9bbd                	andi	a5,a5,-17
    80001692:	e11c                	sd	a5,0(a0)
}
    80001694:	60a2                	ld	ra,8(sp)
    80001696:	6402                	ld	s0,0(sp)
    80001698:	0141                	addi	sp,sp,16
    8000169a:	8082                	ret
    panic("uvmclear");
    8000169c:	00007517          	auipc	a0,0x7
    800016a0:	b3c50513          	addi	a0,a0,-1220 # 800081d8 <digits+0x198>
    800016a4:	fffff097          	auipc	ra,0xfffff
    800016a8:	e9e080e7          	jalr	-354(ra) # 80000542 <panic>

00000000800016ac <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ac:	c6bd                	beqz	a3,8000171a <copyout+0x6e>
{
    800016ae:	715d                	addi	sp,sp,-80
    800016b0:	e486                	sd	ra,72(sp)
    800016b2:	e0a2                	sd	s0,64(sp)
    800016b4:	fc26                	sd	s1,56(sp)
    800016b6:	f84a                	sd	s2,48(sp)
    800016b8:	f44e                	sd	s3,40(sp)
    800016ba:	f052                	sd	s4,32(sp)
    800016bc:	ec56                	sd	s5,24(sp)
    800016be:	e85a                	sd	s6,16(sp)
    800016c0:	e45e                	sd	s7,8(sp)
    800016c2:	e062                	sd	s8,0(sp)
    800016c4:	0880                	addi	s0,sp,80
    800016c6:	8b2a                	mv	s6,a0
    800016c8:	8c2e                	mv	s8,a1
    800016ca:	8a32                	mv	s4,a2
    800016cc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016ce:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016d0:	6a85                	lui	s5,0x1
    800016d2:	a015                	j	800016f6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016d4:	9562                	add	a0,a0,s8
    800016d6:	0004861b          	sext.w	a2,s1
    800016da:	85d2                	mv	a1,s4
    800016dc:	41250533          	sub	a0,a0,s2
    800016e0:	fffff097          	auipc	ra,0xfffff
    800016e4:	676080e7          	jalr	1654(ra) # 80000d56 <memmove>

    len -= n;
    800016e8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ec:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ee:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016f2:	02098263          	beqz	s3,80001716 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016f6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016fa:	85ca                	mv	a1,s2
    800016fc:	855a                	mv	a0,s6
    800016fe:	00000097          	auipc	ra,0x0
    80001702:	97a080e7          	jalr	-1670(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    80001706:	cd01                	beqz	a0,8000171e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001708:	418904b3          	sub	s1,s2,s8
    8000170c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000170e:	fc99f3e3          	bgeu	s3,s1,800016d4 <copyout+0x28>
    80001712:	84ce                	mv	s1,s3
    80001714:	b7c1                	j	800016d4 <copyout+0x28>
  }
  return 0;
    80001716:	4501                	li	a0,0
    80001718:	a021                	j	80001720 <copyout+0x74>
    8000171a:	4501                	li	a0,0
}
    8000171c:	8082                	ret
      return -1;
    8000171e:	557d                	li	a0,-1
}
    80001720:	60a6                	ld	ra,72(sp)
    80001722:	6406                	ld	s0,64(sp)
    80001724:	74e2                	ld	s1,56(sp)
    80001726:	7942                	ld	s2,48(sp)
    80001728:	79a2                	ld	s3,40(sp)
    8000172a:	7a02                	ld	s4,32(sp)
    8000172c:	6ae2                	ld	s5,24(sp)
    8000172e:	6b42                	ld	s6,16(sp)
    80001730:	6ba2                	ld	s7,8(sp)
    80001732:	6c02                	ld	s8,0(sp)
    80001734:	6161                	addi	sp,sp,80
    80001736:	8082                	ret

0000000080001738 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001738:	caa5                	beqz	a3,800017a8 <copyin+0x70>
{
    8000173a:	715d                	addi	sp,sp,-80
    8000173c:	e486                	sd	ra,72(sp)
    8000173e:	e0a2                	sd	s0,64(sp)
    80001740:	fc26                	sd	s1,56(sp)
    80001742:	f84a                	sd	s2,48(sp)
    80001744:	f44e                	sd	s3,40(sp)
    80001746:	f052                	sd	s4,32(sp)
    80001748:	ec56                	sd	s5,24(sp)
    8000174a:	e85a                	sd	s6,16(sp)
    8000174c:	e45e                	sd	s7,8(sp)
    8000174e:	e062                	sd	s8,0(sp)
    80001750:	0880                	addi	s0,sp,80
    80001752:	8b2a                	mv	s6,a0
    80001754:	8a2e                	mv	s4,a1
    80001756:	8c32                	mv	s8,a2
    80001758:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000175a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000175c:	6a85                	lui	s5,0x1
    8000175e:	a01d                	j	80001784 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001760:	018505b3          	add	a1,a0,s8
    80001764:	0004861b          	sext.w	a2,s1
    80001768:	412585b3          	sub	a1,a1,s2
    8000176c:	8552                	mv	a0,s4
    8000176e:	fffff097          	auipc	ra,0xfffff
    80001772:	5e8080e7          	jalr	1512(ra) # 80000d56 <memmove>

    len -= n;
    80001776:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000177a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000177c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001780:	02098263          	beqz	s3,800017a4 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001784:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001788:	85ca                	mv	a1,s2
    8000178a:	855a                	mv	a0,s6
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	8ec080e7          	jalr	-1812(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    80001794:	cd01                	beqz	a0,800017ac <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001796:	418904b3          	sub	s1,s2,s8
    8000179a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000179c:	fc99f2e3          	bgeu	s3,s1,80001760 <copyin+0x28>
    800017a0:	84ce                	mv	s1,s3
    800017a2:	bf7d                	j	80001760 <copyin+0x28>
  }
  return 0;
    800017a4:	4501                	li	a0,0
    800017a6:	a021                	j	800017ae <copyin+0x76>
    800017a8:	4501                	li	a0,0
}
    800017aa:	8082                	ret
      return -1;
    800017ac:	557d                	li	a0,-1
}
    800017ae:	60a6                	ld	ra,72(sp)
    800017b0:	6406                	ld	s0,64(sp)
    800017b2:	74e2                	ld	s1,56(sp)
    800017b4:	7942                	ld	s2,48(sp)
    800017b6:	79a2                	ld	s3,40(sp)
    800017b8:	7a02                	ld	s4,32(sp)
    800017ba:	6ae2                	ld	s5,24(sp)
    800017bc:	6b42                	ld	s6,16(sp)
    800017be:	6ba2                	ld	s7,8(sp)
    800017c0:	6c02                	ld	s8,0(sp)
    800017c2:	6161                	addi	sp,sp,80
    800017c4:	8082                	ret

00000000800017c6 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017c6:	c6c5                	beqz	a3,8000186e <copyinstr+0xa8>
{
    800017c8:	715d                	addi	sp,sp,-80
    800017ca:	e486                	sd	ra,72(sp)
    800017cc:	e0a2                	sd	s0,64(sp)
    800017ce:	fc26                	sd	s1,56(sp)
    800017d0:	f84a                	sd	s2,48(sp)
    800017d2:	f44e                	sd	s3,40(sp)
    800017d4:	f052                	sd	s4,32(sp)
    800017d6:	ec56                	sd	s5,24(sp)
    800017d8:	e85a                	sd	s6,16(sp)
    800017da:	e45e                	sd	s7,8(sp)
    800017dc:	0880                	addi	s0,sp,80
    800017de:	8a2a                	mv	s4,a0
    800017e0:	8b2e                	mv	s6,a1
    800017e2:	8bb2                	mv	s7,a2
    800017e4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017e6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e8:	6985                	lui	s3,0x1
    800017ea:	a035                	j	80001816 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ec:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017f0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017f2:	0017b793          	seqz	a5,a5
    800017f6:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017fa:	60a6                	ld	ra,72(sp)
    800017fc:	6406                	ld	s0,64(sp)
    800017fe:	74e2                	ld	s1,56(sp)
    80001800:	7942                	ld	s2,48(sp)
    80001802:	79a2                	ld	s3,40(sp)
    80001804:	7a02                	ld	s4,32(sp)
    80001806:	6ae2                	ld	s5,24(sp)
    80001808:	6b42                	ld	s6,16(sp)
    8000180a:	6ba2                	ld	s7,8(sp)
    8000180c:	6161                	addi	sp,sp,80
    8000180e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001810:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001814:	c8a9                	beqz	s1,80001866 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001816:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000181a:	85ca                	mv	a1,s2
    8000181c:	8552                	mv	a0,s4
    8000181e:	00000097          	auipc	ra,0x0
    80001822:	85a080e7          	jalr	-1958(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    80001826:	c131                	beqz	a0,8000186a <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001828:	41790833          	sub	a6,s2,s7
    8000182c:	984e                	add	a6,a6,s3
    if(n > max)
    8000182e:	0104f363          	bgeu	s1,a6,80001834 <copyinstr+0x6e>
    80001832:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001834:	955e                	add	a0,a0,s7
    80001836:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000183a:	fc080be3          	beqz	a6,80001810 <copyinstr+0x4a>
    8000183e:	985a                	add	a6,a6,s6
    80001840:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001842:	41650633          	sub	a2,a0,s6
    80001846:	14fd                	addi	s1,s1,-1
    80001848:	9b26                	add	s6,s6,s1
    8000184a:	00f60733          	add	a4,a2,a5
    8000184e:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    80001852:	df49                	beqz	a4,800017ec <copyinstr+0x26>
        *dst = *p;
    80001854:	00e78023          	sb	a4,0(a5)
      --max;
    80001858:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000185c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000185e:	ff0796e3          	bne	a5,a6,8000184a <copyinstr+0x84>
      dst++;
    80001862:	8b42                	mv	s6,a6
    80001864:	b775                	j	80001810 <copyinstr+0x4a>
    80001866:	4781                	li	a5,0
    80001868:	b769                	j	800017f2 <copyinstr+0x2c>
      return -1;
    8000186a:	557d                	li	a0,-1
    8000186c:	b779                	j	800017fa <copyinstr+0x34>
  int got_null = 0;
    8000186e:	4781                	li	a5,0
  if(got_null){
    80001870:	0017b793          	seqz	a5,a5
    80001874:	40f00533          	neg	a0,a5
}
    80001878:	8082                	ret

000000008000187a <prevproc>:
extern void deleteproc(struct proc *p, int level);
extern struct proc* prevproc(struct proc *p, int level);
static void getportion(struct proc *p);

struct proc* prevproc(struct proc *p, int level)
{
    8000187a:	1141                	addi	sp,sp,-16
    8000187c:	e422                	sd	s0,8(sp)
    8000187e:	0800                	addi	s0,sp,16
    80001880:	872a                	mv	a4,a0
  struct proc *tmp = q[level].head;
    80001882:	00159793          	slli	a5,a1,0x1
    80001886:	97ae                	add	a5,a5,a1
    80001888:	078e                	slli	a5,a5,0x3
    8000188a:	00010697          	auipc	a3,0x10
    8000188e:	0c668693          	addi	a3,a3,198 # 80011950 <q>
    80001892:	97b6                	add	a5,a5,a3
    80001894:	639c                	ld	a5,0(a5)
  while (tmp->next != p)
    80001896:	853e                	mv	a0,a5
    80001898:	1787b783          	ld	a5,376(a5)
    8000189c:	fee79de3          	bne	a5,a4,80001896 <prevproc+0x1c>
    tmp = tmp->next;
  return tmp;
}
    800018a0:	6422                	ld	s0,8(sp)
    800018a2:	0141                	addi	sp,sp,16
    800018a4:	8082                	ret

00000000800018a6 <insertproc>:

void insertproc(struct proc *p, int level)
{
    800018a6:	1101                	addi	sp,sp,-32
    800018a8:	ec06                	sd	ra,24(sp)
    800018aa:	e822                	sd	s0,16(sp)
    800018ac:	e426                	sd	s1,8(sp)
    800018ae:	e04a                	sd	s2,0(sp)
    800018b0:	1000                	addi	s0,sp,32
    800018b2:	84aa                	mv	s1,a0
  // if queue was empty, set p as head
  if (q[level].head == 0)
    800018b4:	00159793          	slli	a5,a1,0x1
    800018b8:	97ae                	add	a5,a5,a1
    800018ba:	078e                	slli	a5,a5,0x3
    800018bc:	00010717          	auipc	a4,0x10
    800018c0:	09470713          	addi	a4,a4,148 # 80011950 <q>
    800018c4:	97ba                	add	a5,a5,a4
    800018c6:	639c                	ld	a5,0(a5)
    800018c8:	cb9d                	beqz	a5,800018fe <insertproc+0x58>
  }

  else
  {
    // tail indicates the VALID tail, not dummy tail
    struct proc* tail = prevproc(q[level].tail, level);
    800018ca:	00159793          	slli	a5,a1,0x1
    800018ce:	97ae                	add	a5,a5,a1
    800018d0:	078e                	slli	a5,a5,0x3
    800018d2:	00010717          	auipc	a4,0x10
    800018d6:	07e70713          	addi	a4,a4,126 # 80011950 <q>
    800018da:	97ba                	add	a5,a5,a4
    800018dc:	0107b903          	ld	s2,16(a5)
    800018e0:	854a                	mv	a0,s2
    800018e2:	00000097          	auipc	ra,0x0
    800018e6:	f98080e7          	jalr	-104(ra) # 8000187a <prevproc>
    tail->next = p;
    800018ea:	16953c23          	sd	s1,376(a0)
    p->next = q[level].tail;
    800018ee:	1724bc23          	sd	s2,376(s1)
  }
}
    800018f2:	60e2                	ld	ra,24(sp)
    800018f4:	6442                	ld	s0,16(sp)
    800018f6:	64a2                	ld	s1,8(sp)
    800018f8:	6902                	ld	s2,0(sp)
    800018fa:	6105                	addi	sp,sp,32
    800018fc:	8082                	ret
    q[level].head = p;
    800018fe:	86ba                	mv	a3,a4
    80001900:	00159793          	slli	a5,a1,0x1
    80001904:	00b78733          	add	a4,a5,a1
    80001908:	070e                	slli	a4,a4,0x3
    8000190a:	9736                	add	a4,a4,a3
    8000190c:	e308                	sd	a0,0(a4)
    q[level].tail = p->next;
    8000190e:	17853603          	ld	a2,376(a0)
    80001912:	eb10                	sd	a2,16(a4)
    q[level].tail->next = q[level].head;
    80001914:	16a63c23          	sd	a0,376(a2) # 1178 <_entry-0x7fffee88>
    q[level].now = q[level].head;
    80001918:	e708                	sd	a0,8(a4)
    8000191a:	bfe1                	j	800018f2 <insertproc+0x4c>

000000008000191c <deleteproc>:

void deleteproc(struct proc *p, int level)
{
    8000191c:	1101                	addi	sp,sp,-32
    8000191e:	ec06                	sd	ra,24(sp)
    80001920:	e822                	sd	s0,16(sp)
    80001922:	e426                	sd	s1,8(sp)
    80001924:	1000                	addi	s0,sp,32
    80001926:	84aa                	mv	s1,a0
  // if p is head of queue
  if(p==q[level].head)
    80001928:	00159793          	slli	a5,a1,0x1
    8000192c:	97ae                	add	a5,a5,a1
    8000192e:	078e                	slli	a5,a5,0x3
    80001930:	00010717          	auipc	a4,0x10
    80001934:	02070713          	addi	a4,a4,32 # 80011950 <q>
    80001938:	97ba                	add	a5,a5,a4
    8000193a:	639c                	ld	a5,0(a5)
    8000193c:	02a78163          	beq	a5,a0,8000195e <deleteproc+0x42>
    q[level].tail->next = q[level].head;
  }

  else
  {
    struct proc* _prev = prevproc(p, level);
    80001940:	00000097          	auipc	ra,0x0
    80001944:	f3a080e7          	jalr	-198(ra) # 8000187a <prevproc>
    _prev->next = p->next;
    80001948:	1784b783          	ld	a5,376(s1)
    8000194c:	16f53c23          	sd	a5,376(a0)
  }

  //reset proc
  p->next = 0;
    80001950:	1604bc23          	sd	zero,376(s1)
}
    80001954:	60e2                	ld	ra,24(sp)
    80001956:	6442                	ld	s0,16(sp)
    80001958:	64a2                	ld	s1,8(sp)
    8000195a:	6105                	addi	sp,sp,32
    8000195c:	8082                	ret
    q[level].head = q[level].head->next;
    8000195e:	17853603          	ld	a2,376(a0)
    80001962:	86ba                	mv	a3,a4
    80001964:	00159793          	slli	a5,a1,0x1
    80001968:	00b78733          	add	a4,a5,a1
    8000196c:	070e                	slli	a4,a4,0x3
    8000196e:	9736                	add	a4,a4,a3
    80001970:	e310                	sd	a2,0(a4)
    q[level].tail->next = q[level].head;
    80001972:	6b1c                	ld	a5,16(a4)
    80001974:	16c7bc23          	sd	a2,376(a5)
    80001978:	bfe1                	j	80001950 <deleteproc+0x34>

000000008000197a <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000197a:	1101                	addi	sp,sp,-32
    8000197c:	ec06                	sd	ra,24(sp)
    8000197e:	e822                	sd	s0,16(sp)
    80001980:	e426                	sd	s1,8(sp)
    80001982:	1000                	addi	s0,sp,32
    80001984:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	1fe080e7          	jalr	510(ra) # 80000b84 <holding>
    8000198e:	c909                	beqz	a0,800019a0 <wakeup1+0x26>
    panic("wakeup1");
  if (p->chan == p && p->state == SLEEPING)
    80001990:	749c                	ld	a5,40(s1)
    80001992:	00978f63          	beq	a5,s1,800019b0 <wakeup1+0x36>
  {
    p->state = RUNNABLE;
    deleteproc(p, p->priority);
    insertproc(p, 2);
  }
}
    80001996:	60e2                	ld	ra,24(sp)
    80001998:	6442                	ld	s0,16(sp)
    8000199a:	64a2                	ld	s1,8(sp)
    8000199c:	6105                	addi	sp,sp,32
    8000199e:	8082                	ret
    panic("wakeup1");
    800019a0:	00007517          	auipc	a0,0x7
    800019a4:	84850513          	addi	a0,a0,-1976 # 800081e8 <digits+0x1a8>
    800019a8:	fffff097          	auipc	ra,0xfffff
    800019ac:	b9a080e7          	jalr	-1126(ra) # 80000542 <panic>
  if (p->chan == p && p->state == SLEEPING)
    800019b0:	4c98                	lw	a4,24(s1)
    800019b2:	4785                	li	a5,1
    800019b4:	fef711e3          	bne	a4,a5,80001996 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019b8:	4789                	li	a5,2
    800019ba:	cc9c                	sw	a5,24(s1)
    deleteproc(p, p->priority);
    800019bc:	1744a583          	lw	a1,372(s1)
    800019c0:	8526                	mv	a0,s1
    800019c2:	00000097          	auipc	ra,0x0
    800019c6:	f5a080e7          	jalr	-166(ra) # 8000191c <deleteproc>
    insertproc(p, 2);
    800019ca:	4589                	li	a1,2
    800019cc:	8526                	mv	a0,s1
    800019ce:	00000097          	auipc	ra,0x0
    800019d2:	ed8080e7          	jalr	-296(ra) # 800018a6 <insertproc>
}
    800019d6:	b7c1                	j	80001996 <wakeup1+0x1c>

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
    800019f2:	80258593          	addi	a1,a1,-2046 # 800081f0 <digits+0x1b0>
    800019f6:	00010517          	auipc	a0,0x10
    800019fa:	fa250513          	addi	a0,a0,-94 # 80011998 <pid_lock>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	170080e7          	jalr	368(ra) # 80000b6e <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a06:	00010917          	auipc	s2,0x10
    80001a0a:	3aa90913          	addi	s2,s2,938 # 80011db0 <proc>
    initlock(&p->lock, "proc");
    80001a0e:	00006b97          	auipc	s7,0x6
    80001a12:	7eab8b93          	addi	s7,s7,2026 # 800081f8 <digits+0x1b8>
    uint64 va = KSTACK((int)(p - proc));
    80001a16:	8b4a                	mv	s6,s2
    80001a18:	00006a97          	auipc	s5,0x6
    80001a1c:	5e8a8a93          	addi	s5,s5,1512 # 80008000 <etext>
    80001a20:	040009b7          	lui	s3,0x4000
    80001a24:	19fd                	addi	s3,s3,-1
    80001a26:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a28:	00016a17          	auipc	s4,0x16
    80001a2c:	388a0a13          	addi	s4,s4,904 # 80017db0 <tickslock>
    initlock(&p->lock, "proc");
    80001a30:	85de                	mv	a1,s7
    80001a32:	854a                	mv	a0,s2
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	13a080e7          	jalr	314(ra) # 80000b6e <initlock>
    char *pa = kalloc();
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	0d2080e7          	jalr	210(ra) # 80000b0e <kalloc>
    80001a44:	85aa                	mv	a1,a0
    if (pa == 0)
    80001a46:	c929                	beqz	a0,80001a98 <procinit+0xc0>
    uint64 va = KSTACK((int)(p - proc));
    80001a48:	416904b3          	sub	s1,s2,s6
    80001a4c:	849d                	srai	s1,s1,0x7
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
    80001a6a:	740080e7          	jalr	1856(ra) # 800011a6 <kvmmap>
    p->kstack = va;
    80001a6e:	04993023          	sd	s1,64(s2)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a72:	18090913          	addi	s2,s2,384
    80001a76:	fb491de3          	bne	s2,s4,80001a30 <procinit+0x58>
  kvminithart();
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	534080e7          	jalr	1332(ra) # 80000fae <kvminithart>
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
    80001a9c:	76850513          	addi	a0,a0,1896 # 80008200 <digits+0x1c0>
    80001aa0:	fffff097          	auipc	ra,0xfffff
    80001aa4:	aa2080e7          	jalr	-1374(ra) # 80000542 <panic>

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
{
    80001ab8:	1141                	addi	sp,sp,-16
    80001aba:	e422                	sd	s0,8(sp)
    80001abc:	0800                	addi	s0,sp,16
    80001abe:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ac0:	2781                	sext.w	a5,a5
    80001ac2:	079e                	slli	a5,a5,0x7
}
    80001ac4:	00010517          	auipc	a0,0x10
    80001ac8:	eec50513          	addi	a0,a0,-276 # 800119b0 <cpus>
    80001acc:	953e                	add	a0,a0,a5
    80001ace:	6422                	ld	s0,8(sp)
    80001ad0:	0141                	addi	sp,sp,16
    80001ad2:	8082                	ret

0000000080001ad4 <myproc>:
{
    80001ad4:	1101                	addi	sp,sp,-32
    80001ad6:	ec06                	sd	ra,24(sp)
    80001ad8:	e822                	sd	s0,16(sp)
    80001ada:	e426                	sd	s1,8(sp)
    80001adc:	1000                	addi	s0,sp,32
  push_off();
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	0d4080e7          	jalr	212(ra) # 80000bb2 <push_off>
    80001ae6:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001ae8:	2781                	sext.w	a5,a5
    80001aea:	079e                	slli	a5,a5,0x7
    80001aec:	00010717          	auipc	a4,0x10
    80001af0:	e6470713          	addi	a4,a4,-412 # 80011950 <q>
    80001af4:	97ba                	add	a5,a5,a4
    80001af6:	73a4                	ld	s1,96(a5)
  pop_off();
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	15a080e7          	jalr	346(ra) # 80000c52 <pop_off>
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
    80001b20:	196080e7          	jalr	406(ra) # 80000cb2 <release>
  if (first)
    80001b24:	00007797          	auipc	a5,0x7
    80001b28:	dac7a783          	lw	a5,-596(a5) # 800088d0 <first.1>
    80001b2c:	eb89                	bnez	a5,80001b3e <forkret+0x32>
  usertrapret();
    80001b2e:	00001097          	auipc	ra,0x1
    80001b32:	e14080e7          	jalr	-492(ra) # 80002942 <usertrapret>
}
    80001b36:	60a2                	ld	ra,8(sp)
    80001b38:	6402                	ld	s0,0(sp)
    80001b3a:	0141                	addi	sp,sp,16
    80001b3c:	8082                	ret
    first = 0;
    80001b3e:	00007797          	auipc	a5,0x7
    80001b42:	d807a923          	sw	zero,-622(a5) # 800088d0 <first.1>
    fsinit(ROOTDEV);
    80001b46:	4505                	li	a0,1
    80001b48:	00002097          	auipc	ra,0x2
    80001b4c:	b3c080e7          	jalr	-1220(ra) # 80003684 <fsinit>
    80001b50:	bff9                	j	80001b2e <forkret+0x22>

0000000080001b52 <allocpid>:
{
    80001b52:	1101                	addi	sp,sp,-32
    80001b54:	ec06                	sd	ra,24(sp)
    80001b56:	e822                	sd	s0,16(sp)
    80001b58:	e426                	sd	s1,8(sp)
    80001b5a:	e04a                	sd	s2,0(sp)
    80001b5c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b5e:	00010917          	auipc	s2,0x10
    80001b62:	e3a90913          	addi	s2,s2,-454 # 80011998 <pid_lock>
    80001b66:	854a                	mv	a0,s2
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	096080e7          	jalr	150(ra) # 80000bfe <acquire>
  pid = nextpid;
    80001b70:	00007797          	auipc	a5,0x7
    80001b74:	d6478793          	addi	a5,a5,-668 # 800088d4 <nextpid>
    80001b78:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b7a:	0014871b          	addiw	a4,s1,1
    80001b7e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b80:	854a                	mv	a0,s2
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	130080e7          	jalr	304(ra) # 80000cb2 <release>
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
    80001baa:	7ce080e7          	jalr	1998(ra) # 80001374 <uvmcreate>
    80001bae:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bb0:	c121                	beqz	a0,80001bf0 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bb2:	4729                	li	a4,10
    80001bb4:	00005697          	auipc	a3,0x5
    80001bb8:	44c68693          	addi	a3,a3,1100 # 80007000 <_trampoline>
    80001bbc:	6605                	lui	a2,0x1
    80001bbe:	040005b7          	lui	a1,0x4000
    80001bc2:	15fd                	addi	a1,a1,-1
    80001bc4:	05b2                	slli	a1,a1,0xc
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	552080e7          	jalr	1362(ra) # 80001118 <mappages>
    80001bce:	02054863          	bltz	a0,80001bfe <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bd2:	4719                	li	a4,6
    80001bd4:	05893683          	ld	a3,88(s2)
    80001bd8:	6605                	lui	a2,0x1
    80001bda:	020005b7          	lui	a1,0x2000
    80001bde:	15fd                	addi	a1,a1,-1
    80001be0:	05b6                	slli	a1,a1,0xd
    80001be2:	8526                	mv	a0,s1
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	534080e7          	jalr	1332(ra) # 80001118 <mappages>
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
    80001c06:	96e080e7          	jalr	-1682(ra) # 80001570 <uvmfree>
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
    80001c20:	694080e7          	jalr	1684(ra) # 800012b0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c24:	4581                	li	a1,0
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	948080e7          	jalr	-1720(ra) # 80001570 <uvmfree>
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
    80001c54:	660080e7          	jalr	1632(ra) # 800012b0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c58:	4681                	li	a3,0
    80001c5a:	4605                	li	a2,1
    80001c5c:	020005b7          	lui	a1,0x2000
    80001c60:	15fd                	addi	a1,a1,-1
    80001c62:	05b6                	slli	a1,a1,0xd
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	64a080e7          	jalr	1610(ra) # 800012b0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c6e:	85ca                	mv	a1,s2
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	8fe080e7          	jalr	-1794(ra) # 80001570 <uvmfree>
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
  int total = p->Qtime[2] + p->Qtime[1] + p->Qtime[0];
    80001c92:	17052683          	lw	a3,368(a0)
    80001c96:	16c52583          	lw	a1,364(a0)
    80001c9a:	16852783          	lw	a5,360(a0)
    80001c9e:	00b6853b          	addw	a0,a3,a1
    80001ca2:	9d3d                	addw	a0,a0,a5
  p->Qtime[2] = p->Qtime[2] * 100 / total;
    80001ca4:	06400613          	li	a2,100
    80001ca8:	02d606bb          	mulw	a3,a2,a3
    80001cac:	02a6c6bb          	divw	a3,a3,a0
    80001cb0:	16d4a823          	sw	a3,368(s1)
  p->Qtime[1] = p->Qtime[1] * 100 / total;
    80001cb4:	02b605bb          	mulw	a1,a2,a1
    80001cb8:	02a5c5bb          	divw	a1,a1,a0
    80001cbc:	0005871b          	sext.w	a4,a1
    80001cc0:	16b4a623          	sw	a1,364(s1)
  p->Qtime[0] = p->Qtime[0] * 100 / total;
    80001cc4:	02f6063b          	mulw	a2,a2,a5
    80001cc8:	02a6463b          	divw	a2,a2,a0
    80001ccc:	16c4a423          	sw	a2,360(s1)
  printf("%s (pid=%d): Q2(%d%%), Q1(%d%%), Q0(%d%%)\n",
    80001cd0:	87ba                	mv	a5,a4
    80001cd2:	2681                	sext.w	a3,a3
    80001cd4:	5c90                	lw	a2,56(s1)
    80001cd6:	15848593          	addi	a1,s1,344
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	52e50513          	addi	a0,a0,1326 # 80008208 <digits+0x1c8>
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	8aa080e7          	jalr	-1878(ra) # 8000058c <printf>
  if (p->trapframe)
    80001cea:	6ca8                	ld	a0,88(s1)
    80001cec:	c509                	beqz	a0,80001cf6 <freeproc+0x70>
    kfree((void *)p->trapframe);
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	d24080e7          	jalr	-732(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001cf6:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001cfa:	68a8                	ld	a0,80(s1)
    80001cfc:	c511                	beqz	a0,80001d08 <freeproc+0x82>
    proc_freepagetable(p->pagetable, p->sz);
    80001cfe:	64ac                	ld	a1,72(s1)
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	f34080e7          	jalr	-204(ra) # 80001c34 <proc_freepagetable>
  p->pagetable = 0;
    80001d08:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d0c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d10:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d14:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d18:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d1c:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d20:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d24:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d28:	0004ac23          	sw	zero,24(s1)
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6105                	addi	sp,sp,32
    80001d34:	8082                	ret

0000000080001d36 <allocproc>:
{
    80001d36:	1101                	addi	sp,sp,-32
    80001d38:	ec06                	sd	ra,24(sp)
    80001d3a:	e822                	sd	s0,16(sp)
    80001d3c:	e426                	sd	s1,8(sp)
    80001d3e:	e04a                	sd	s2,0(sp)
    80001d40:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d42:	00010497          	auipc	s1,0x10
    80001d46:	06e48493          	addi	s1,s1,110 # 80011db0 <proc>
    80001d4a:	00016917          	auipc	s2,0x16
    80001d4e:	06690913          	addi	s2,s2,102 # 80017db0 <tickslock>
    acquire(&p->lock);
    80001d52:	8526                	mv	a0,s1
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	eaa080e7          	jalr	-342(ra) # 80000bfe <acquire>
    if (p->state == UNUSED)
    80001d5c:	4c9c                	lw	a5,24(s1)
    80001d5e:	cf81                	beqz	a5,80001d76 <allocproc+0x40>
      release(&p->lock);
    80001d60:	8526                	mv	a0,s1
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	f50080e7          	jalr	-176(ra) # 80000cb2 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d6a:	18048493          	addi	s1,s1,384
    80001d6e:	ff2492e3          	bne	s1,s2,80001d52 <allocproc+0x1c>
  return 0;
    80001d72:	4481                	li	s1,0
    80001d74:	a0b9                	j	80001dc2 <allocproc+0x8c>
  p->pid = allocpid();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	ddc080e7          	jalr	-548(ra) # 80001b52 <allocpid>
    80001d7e:	dc88                	sw	a0,56(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	d8e080e7          	jalr	-626(ra) # 80000b0e <kalloc>
    80001d88:	892a                	mv	s2,a0
    80001d8a:	eca8                	sd	a0,88(s1)
    80001d8c:	c131                	beqz	a0,80001dd0 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d8e:	8526                	mv	a0,s1
    80001d90:	00000097          	auipc	ra,0x0
    80001d94:	e08080e7          	jalr	-504(ra) # 80001b98 <proc_pagetable>
    80001d98:	892a                	mv	s2,a0
    80001d9a:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d9c:	c129                	beqz	a0,80001dde <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d9e:	07000613          	li	a2,112
    80001da2:	4581                	li	a1,0
    80001da4:	06048513          	addi	a0,s1,96
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	f52080e7          	jalr	-174(ra) # 80000cfa <memset>
  p->context.ra = (uint64)forkret;
    80001db0:	00000797          	auipc	a5,0x0
    80001db4:	d5c78793          	addi	a5,a5,-676 # 80001b0c <forkret>
    80001db8:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dba:	60bc                	ld	a5,64(s1)
    80001dbc:	6705                	lui	a4,0x1
    80001dbe:	97ba                	add	a5,a5,a4
    80001dc0:	f4bc                	sd	a5,104(s1)
}
    80001dc2:	8526                	mv	a0,s1
    80001dc4:	60e2                	ld	ra,24(sp)
    80001dc6:	6442                	ld	s0,16(sp)
    80001dc8:	64a2                	ld	s1,8(sp)
    80001dca:	6902                	ld	s2,0(sp)
    80001dcc:	6105                	addi	sp,sp,32
    80001dce:	8082                	ret
    release(&p->lock);
    80001dd0:	8526                	mv	a0,s1
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	ee0080e7          	jalr	-288(ra) # 80000cb2 <release>
    return 0;
    80001dda:	84ca                	mv	s1,s2
    80001ddc:	b7dd                	j	80001dc2 <allocproc+0x8c>
    freeproc(p);
    80001dde:	8526                	mv	a0,s1
    80001de0:	00000097          	auipc	ra,0x0
    80001de4:	ea6080e7          	jalr	-346(ra) # 80001c86 <freeproc>
    release(&p->lock);
    80001de8:	8526                	mv	a0,s1
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	ec8080e7          	jalr	-312(ra) # 80000cb2 <release>
    return 0;
    80001df2:	84ca                	mv	s1,s2
    80001df4:	b7f9                	j	80001dc2 <allocproc+0x8c>

0000000080001df6 <userinit>:
{
    80001df6:	1101                	addi	sp,sp,-32
    80001df8:	ec06                	sd	ra,24(sp)
    80001dfa:	e822                	sd	s0,16(sp)
    80001dfc:	e426                	sd	s1,8(sp)
    80001dfe:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e00:	00000097          	auipc	ra,0x0
    80001e04:	f36080e7          	jalr	-202(ra) # 80001d36 <allocproc>
    80001e08:	84aa                	mv	s1,a0
  initproc = p;
    80001e0a:	00007797          	auipc	a5,0x7
    80001e0e:	20a7b723          	sd	a0,526(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e12:	03400613          	li	a2,52
    80001e16:	00007597          	auipc	a1,0x7
    80001e1a:	aca58593          	addi	a1,a1,-1334 # 800088e0 <initcode>
    80001e1e:	6928                	ld	a0,80(a0)
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	582080e7          	jalr	1410(ra) # 800013a2 <uvminit>
  p->sz = PGSIZE;
    80001e28:	6785                	lui	a5,0x1
    80001e2a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e2c:	6cb8                	ld	a4,88(s1)
    80001e2e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e32:	6cb8                	ld	a4,88(s1)
    80001e34:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e36:	4641                	li	a2,16
    80001e38:	00006597          	auipc	a1,0x6
    80001e3c:	40058593          	addi	a1,a1,1024 # 80008238 <digits+0x1f8>
    80001e40:	15848513          	addi	a0,s1,344
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	008080e7          	jalr	8(ra) # 80000e4c <safestrcpy>
  p->cwd = namei("/");
    80001e4c:	00006517          	auipc	a0,0x6
    80001e50:	3fc50513          	addi	a0,a0,1020 # 80008248 <digits+0x208>
    80001e54:	00002097          	auipc	ra,0x2
    80001e58:	258080e7          	jalr	600(ra) # 800040ac <namei>
    80001e5c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e60:	4789                	li	a5,2
    80001e62:	cc9c                	sw	a5,24(s1)
  insertproc(p, 2);
    80001e64:	4589                	li	a1,2
    80001e66:	8526                	mv	a0,s1
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	a3e080e7          	jalr	-1474(ra) # 800018a6 <insertproc>
  p->Qtime[2] = 0;
    80001e70:	1604a823          	sw	zero,368(s1)
  p->Qtime[1] = 0;
    80001e74:	1604a623          	sw	zero,364(s1)
  p->Qtime[0] = 0;
    80001e78:	1604a423          	sw	zero,360(s1)
  release(&p->lock);
    80001e7c:	8526                	mv	a0,s1
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	e34080e7          	jalr	-460(ra) # 80000cb2 <release>
}
    80001e86:	60e2                	ld	ra,24(sp)
    80001e88:	6442                	ld	s0,16(sp)
    80001e8a:	64a2                	ld	s1,8(sp)
    80001e8c:	6105                	addi	sp,sp,32
    80001e8e:	8082                	ret

0000000080001e90 <growproc>:
{
    80001e90:	1101                	addi	sp,sp,-32
    80001e92:	ec06                	sd	ra,24(sp)
    80001e94:	e822                	sd	s0,16(sp)
    80001e96:	e426                	sd	s1,8(sp)
    80001e98:	e04a                	sd	s2,0(sp)
    80001e9a:	1000                	addi	s0,sp,32
    80001e9c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	c36080e7          	jalr	-970(ra) # 80001ad4 <myproc>
    80001ea6:	892a                	mv	s2,a0
  sz = p->sz;
    80001ea8:	652c                	ld	a1,72(a0)
    80001eaa:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001eae:	00904f63          	bgtz	s1,80001ecc <growproc+0x3c>
  else if (n < 0)
    80001eb2:	0204cc63          	bltz	s1,80001eea <growproc+0x5a>
  p->sz = sz;
    80001eb6:	1602                	slli	a2,a2,0x20
    80001eb8:	9201                	srli	a2,a2,0x20
    80001eba:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ebe:	4501                	li	a0,0
}
    80001ec0:	60e2                	ld	ra,24(sp)
    80001ec2:	6442                	ld	s0,16(sp)
    80001ec4:	64a2                	ld	s1,8(sp)
    80001ec6:	6902                	ld	s2,0(sp)
    80001ec8:	6105                	addi	sp,sp,32
    80001eca:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001ecc:	9e25                	addw	a2,a2,s1
    80001ece:	1602                	slli	a2,a2,0x20
    80001ed0:	9201                	srli	a2,a2,0x20
    80001ed2:	1582                	slli	a1,a1,0x20
    80001ed4:	9181                	srli	a1,a1,0x20
    80001ed6:	6928                	ld	a0,80(a0)
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	584080e7          	jalr	1412(ra) # 8000145c <uvmalloc>
    80001ee0:	0005061b          	sext.w	a2,a0
    80001ee4:	fa69                	bnez	a2,80001eb6 <growproc+0x26>
      return -1;
    80001ee6:	557d                	li	a0,-1
    80001ee8:	bfe1                	j	80001ec0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001eea:	9e25                	addw	a2,a2,s1
    80001eec:	1602                	slli	a2,a2,0x20
    80001eee:	9201                	srli	a2,a2,0x20
    80001ef0:	1582                	slli	a1,a1,0x20
    80001ef2:	9181                	srli	a1,a1,0x20
    80001ef4:	6928                	ld	a0,80(a0)
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	51e080e7          	jalr	1310(ra) # 80001414 <uvmdealloc>
    80001efe:	0005061b          	sext.w	a2,a0
    80001f02:	bf55                	j	80001eb6 <growproc+0x26>

0000000080001f04 <fork>:
{
    80001f04:	7139                	addi	sp,sp,-64
    80001f06:	fc06                	sd	ra,56(sp)
    80001f08:	f822                	sd	s0,48(sp)
    80001f0a:	f426                	sd	s1,40(sp)
    80001f0c:	f04a                	sd	s2,32(sp)
    80001f0e:	ec4e                	sd	s3,24(sp)
    80001f10:	e852                	sd	s4,16(sp)
    80001f12:	e456                	sd	s5,8(sp)
    80001f14:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f16:	00000097          	auipc	ra,0x0
    80001f1a:	bbe080e7          	jalr	-1090(ra) # 80001ad4 <myproc>
    80001f1e:	8aaa                	mv	s5,a0
  printf("New Process....\n");
    80001f20:	00006517          	auipc	a0,0x6
    80001f24:	33050513          	addi	a0,a0,816 # 80008250 <digits+0x210>
    80001f28:	ffffe097          	auipc	ra,0xffffe
    80001f2c:	664080e7          	jalr	1636(ra) # 8000058c <printf>
  if ((np = allocproc()) == 0)
    80001f30:	00000097          	auipc	ra,0x0
    80001f34:	e06080e7          	jalr	-506(ra) # 80001d36 <allocproc>
    80001f38:	10050063          	beqz	a0,80002038 <fork+0x134>
    80001f3c:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f3e:	048ab603          	ld	a2,72(s5)
    80001f42:	692c                	ld	a1,80(a0)
    80001f44:	050ab503          	ld	a0,80(s5)
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	660080e7          	jalr	1632(ra) # 800015a8 <uvmcopy>
    80001f50:	04054a63          	bltz	a0,80001fa4 <fork+0xa0>
  np->sz = p->sz;
    80001f54:	048ab783          	ld	a5,72(s5)
    80001f58:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f5c:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f60:	058ab683          	ld	a3,88(s5)
    80001f64:	87b6                	mv	a5,a3
    80001f66:	0589b703          	ld	a4,88(s3)
    80001f6a:	12068693          	addi	a3,a3,288
    80001f6e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f72:	6788                	ld	a0,8(a5)
    80001f74:	6b8c                	ld	a1,16(a5)
    80001f76:	6f90                	ld	a2,24(a5)
    80001f78:	01073023          	sd	a6,0(a4)
    80001f7c:	e708                	sd	a0,8(a4)
    80001f7e:	eb0c                	sd	a1,16(a4)
    80001f80:	ef10                	sd	a2,24(a4)
    80001f82:	02078793          	addi	a5,a5,32
    80001f86:	02070713          	addi	a4,a4,32
    80001f8a:	fed792e3          	bne	a5,a3,80001f6e <fork+0x6a>
  np->trapframe->a0 = 0;
    80001f8e:	0589b783          	ld	a5,88(s3)
    80001f92:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f96:	0d0a8493          	addi	s1,s5,208
    80001f9a:	0d098913          	addi	s2,s3,208
    80001f9e:	150a8a13          	addi	s4,s5,336
    80001fa2:	a00d                	j	80001fc4 <fork+0xc0>
    freeproc(np);
    80001fa4:	854e                	mv	a0,s3
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	ce0080e7          	jalr	-800(ra) # 80001c86 <freeproc>
    release(&np->lock);
    80001fae:	854e                	mv	a0,s3
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	d02080e7          	jalr	-766(ra) # 80000cb2 <release>
    return -1;
    80001fb8:	54fd                	li	s1,-1
    80001fba:	a0ad                	j	80002024 <fork+0x120>
  for (i = 0; i < NOFILE; i++)
    80001fbc:	04a1                	addi	s1,s1,8
    80001fbe:	0921                	addi	s2,s2,8
    80001fc0:	01448b63          	beq	s1,s4,80001fd6 <fork+0xd2>
    if (p->ofile[i])
    80001fc4:	6088                	ld	a0,0(s1)
    80001fc6:	d97d                	beqz	a0,80001fbc <fork+0xb8>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fc8:	00002097          	auipc	ra,0x2
    80001fcc:	774080e7          	jalr	1908(ra) # 8000473c <filedup>
    80001fd0:	00a93023          	sd	a0,0(s2)
    80001fd4:	b7e5                	j	80001fbc <fork+0xb8>
  np->cwd = idup(p->cwd);
    80001fd6:	150ab503          	ld	a0,336(s5)
    80001fda:	00002097          	auipc	ra,0x2
    80001fde:	8e4080e7          	jalr	-1820(ra) # 800038be <idup>
    80001fe2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fe6:	4641                	li	a2,16
    80001fe8:	158a8593          	addi	a1,s5,344
    80001fec:	15898513          	addi	a0,s3,344
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	e5c080e7          	jalr	-420(ra) # 80000e4c <safestrcpy>
  pid = np->pid;
    80001ff8:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ffc:	4789                	li	a5,2
    80001ffe:	00f9ac23          	sw	a5,24(s3)
  insertproc(np, 2);
    80002002:	4589                	li	a1,2
    80002004:	854e                	mv	a0,s3
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	8a0080e7          	jalr	-1888(ra) # 800018a6 <insertproc>
  np->Qtime[2] = 0;
    8000200e:	1609a823          	sw	zero,368(s3)
  np->Qtime[1] = 0;
    80002012:	1609a623          	sw	zero,364(s3)
  np->Qtime[0] = 0;
    80002016:	1609a423          	sw	zero,360(s3)
  release(&np->lock);
    8000201a:	854e                	mv	a0,s3
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	c96080e7          	jalr	-874(ra) # 80000cb2 <release>
}
    80002024:	8526                	mv	a0,s1
    80002026:	70e2                	ld	ra,56(sp)
    80002028:	7442                	ld	s0,48(sp)
    8000202a:	74a2                	ld	s1,40(sp)
    8000202c:	7902                	ld	s2,32(sp)
    8000202e:	69e2                	ld	s3,24(sp)
    80002030:	6a42                	ld	s4,16(sp)
    80002032:	6aa2                	ld	s5,8(sp)
    80002034:	6121                	addi	sp,sp,64
    80002036:	8082                	ret
    return -1;
    80002038:	54fd                	li	s1,-1
    8000203a:	b7ed                	j	80002024 <fork+0x120>

000000008000203c <reparent>:
{
    8000203c:	7179                	addi	sp,sp,-48
    8000203e:	f406                	sd	ra,40(sp)
    80002040:	f022                	sd	s0,32(sp)
    80002042:	ec26                	sd	s1,24(sp)
    80002044:	e84a                	sd	s2,16(sp)
    80002046:	e44e                	sd	s3,8(sp)
    80002048:	e052                	sd	s4,0(sp)
    8000204a:	1800                	addi	s0,sp,48
    8000204c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000204e:	00010497          	auipc	s1,0x10
    80002052:	d6248493          	addi	s1,s1,-670 # 80011db0 <proc>
      pp->parent = initproc;
    80002056:	00007a17          	auipc	s4,0x7
    8000205a:	fc2a0a13          	addi	s4,s4,-62 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000205e:	00016997          	auipc	s3,0x16
    80002062:	d5298993          	addi	s3,s3,-686 # 80017db0 <tickslock>
    80002066:	a029                	j	80002070 <reparent+0x34>
    80002068:	18048493          	addi	s1,s1,384
    8000206c:	03348363          	beq	s1,s3,80002092 <reparent+0x56>
    if (pp->parent == p)
    80002070:	709c                	ld	a5,32(s1)
    80002072:	ff279be3          	bne	a5,s2,80002068 <reparent+0x2c>
      acquire(&pp->lock);
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	b86080e7          	jalr	-1146(ra) # 80000bfe <acquire>
      pp->parent = initproc;
    80002080:	000a3783          	ld	a5,0(s4)
    80002084:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002086:	8526                	mv	a0,s1
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	c2a080e7          	jalr	-982(ra) # 80000cb2 <release>
    80002090:	bfe1                	j	80002068 <reparent+0x2c>
}
    80002092:	70a2                	ld	ra,40(sp)
    80002094:	7402                	ld	s0,32(sp)
    80002096:	64e2                	ld	s1,24(sp)
    80002098:	6942                	ld	s2,16(sp)
    8000209a:	69a2                	ld	s3,8(sp)
    8000209c:	6a02                	ld	s4,0(sp)
    8000209e:	6145                	addi	sp,sp,48
    800020a0:	8082                	ret

00000000800020a2 <scheduler>:
{
    800020a2:	715d                	addi	sp,sp,-80
    800020a4:	e486                	sd	ra,72(sp)
    800020a6:	e0a2                	sd	s0,64(sp)
    800020a8:	fc26                	sd	s1,56(sp)
    800020aa:	f84a                	sd	s2,48(sp)
    800020ac:	f44e                	sd	s3,40(sp)
    800020ae:	f052                	sd	s4,32(sp)
    800020b0:	ec56                	sd	s5,24(sp)
    800020b2:	e85a                	sd	s6,16(sp)
    800020b4:	e45e                	sd	s7,8(sp)
    800020b6:	e062                	sd	s8,0(sp)
    800020b8:	0880                	addi	s0,sp,80
    800020ba:	8492                	mv	s1,tp
  int id = r_tp();
    800020bc:	2481                	sext.w	s1,s1
  printf("Entered Scheduler\n");
    800020be:	00006517          	auipc	a0,0x6
    800020c2:	1aa50513          	addi	a0,a0,426 # 80008268 <digits+0x228>
    800020c6:	ffffe097          	auipc	ra,0xffffe
    800020ca:	4c6080e7          	jalr	1222(ra) # 8000058c <printf>
        swtch(&c->context, &p->context);
    800020ce:	00749b93          	slli	s7,s1,0x7
    800020d2:	00010797          	auipc	a5,0x10
    800020d6:	8e678793          	addi	a5,a5,-1818 # 800119b8 <cpus+0x8>
    800020da:	9bbe                	add	s7,s7,a5
    while (q[2].now != 0)
    800020dc:	00010917          	auipc	s2,0x10
    800020e0:	87490913          	addi	s2,s2,-1932 # 80011950 <q>
      printf("Q2\n");
    800020e4:	00006a97          	auipc	s5,0x6
    800020e8:	19ca8a93          	addi	s5,s5,412 # 80008280 <digits+0x240>
      printf("p : %p\n", p);
    800020ec:	00006a17          	auipc	s4,0x6
    800020f0:	19ca0a13          	addi	s4,s4,412 # 80008288 <digits+0x248>
        p->state = RUNNING;
    800020f4:	4c0d                	li	s8,3
        c->proc = p;
    800020f6:	049e                	slli	s1,s1,0x7
    800020f8:	00990b33          	add	s6,s2,s1
    800020fc:	a859                	j	80002192 <scheduler+0xf0>
      release(&p->lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	bb2080e7          	jalr	-1102(ra) # 80000cb2 <release>
      q[2].now = q[2].now->next;
    80002108:	03893783          	ld	a5,56(s2)
    8000210c:	1787b783          	ld	a5,376(a5)
    80002110:	02f93c23          	sd	a5,56(s2)
    while (q[2].now != 0)
    80002114:	c7a1                	beqz	a5,8000215c <scheduler+0xba>
      printf("Q2\n");
    80002116:	8556                	mv	a0,s5
    80002118:	ffffe097          	auipc	ra,0xffffe
    8000211c:	474080e7          	jalr	1140(ra) # 8000058c <printf>
      p = q[2].now;
    80002120:	03893483          	ld	s1,56(s2)
      printf("p : %p\n", p);
    80002124:	85a6                	mv	a1,s1
    80002126:	8552                	mv	a0,s4
    80002128:	ffffe097          	auipc	ra,0xffffe
    8000212c:	464080e7          	jalr	1124(ra) # 8000058c <printf>
      acquire(&p->lock);
    80002130:	8526                	mv	a0,s1
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	acc080e7          	jalr	-1332(ra) # 80000bfe <acquire>
      if (p->state == RUNNABLE)
    8000213a:	4c9c                	lw	a5,24(s1)
    8000213c:	fd3791e3          	bne	a5,s3,800020fe <scheduler+0x5c>
        p->state = RUNNING;
    80002140:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002144:	069b3023          	sd	s1,96(s6) # 1060 <_entry-0x7fffefa0>
        swtch(&c->context, &p->context);
    80002148:	06048593          	addi	a1,s1,96
    8000214c:	855e                	mv	a0,s7
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	74a080e7          	jalr	1866(ra) # 80002898 <swtch>
        c->proc = 0;
    80002156:	060b3023          	sd	zero,96(s6)
    8000215a:	b755                	j	800020fe <scheduler+0x5c>
    q[2].now = q[2].head;
    8000215c:	03093783          	ld	a5,48(s2)
    80002160:	02f93c23          	sd	a5,56(s2)
    p = q[1].now;
    80002164:	02093483          	ld	s1,32(s2)
    if (q[1].now != 0)
    80002168:	ccb1                	beqz	s1,800021c4 <scheduler+0x122>
      acquire(&p->lock);
    8000216a:	8526                	mv	a0,s1
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	a92080e7          	jalr	-1390(ra) # 80000bfe <acquire>
      if (p->state == RUNNABLE)
    80002174:	4c98                	lw	a4,24(s1)
    80002176:	4789                	li	a5,2
    80002178:	02f70863          	beq	a4,a5,800021a8 <scheduler+0x106>
      release(&p->lock);
    8000217c:	8526                	mv	a0,s1
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	b34080e7          	jalr	-1228(ra) # 80000cb2 <release>
      q[1].now = q[1].now->next;
    80002186:	02093783          	ld	a5,32(s2)
    8000218a:	1787b783          	ld	a5,376(a5)
    8000218e:	02f93023          	sd	a5,32(s2)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002192:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002196:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000219a:	10079073          	csrw	sstatus,a5
    while (q[2].now != 0)
    8000219e:	03893783          	ld	a5,56(s2)
    800021a2:	dfcd                	beqz	a5,8000215c <scheduler+0xba>
      if (p->state == RUNNABLE)
    800021a4:	4989                	li	s3,2
    800021a6:	bf85                	j	80002116 <scheduler+0x74>
        p->state = RUNNING;
    800021a8:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    800021ac:	069b3023          	sd	s1,96(s6)
        swtch(&c->context, &p->context);
    800021b0:	06048593          	addi	a1,s1,96
    800021b4:	855e                	mv	a0,s7
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	6e2080e7          	jalr	1762(ra) # 80002898 <swtch>
        c->proc = 0;
    800021be:	060b3023          	sd	zero,96(s6)
    800021c2:	bf6d                	j	8000217c <scheduler+0xda>
      q[1].now = q[1].head;
    800021c4:	01893783          	ld	a5,24(s2)
    800021c8:	02f93023          	sd	a5,32(s2)
    800021cc:	b7d9                	j	80002192 <scheduler+0xf0>

00000000800021ce <sched>:
{
    800021ce:	7179                	addi	sp,sp,-48
    800021d0:	f406                	sd	ra,40(sp)
    800021d2:	f022                	sd	s0,32(sp)
    800021d4:	ec26                	sd	s1,24(sp)
    800021d6:	e84a                	sd	s2,16(sp)
    800021d8:	e44e                	sd	s3,8(sp)
    800021da:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021dc:	00000097          	auipc	ra,0x0
    800021e0:	8f8080e7          	jalr	-1800(ra) # 80001ad4 <myproc>
    800021e4:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	99e080e7          	jalr	-1634(ra) # 80000b84 <holding>
    800021ee:	c93d                	beqz	a0,80002264 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021f0:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800021f2:	2781                	sext.w	a5,a5
    800021f4:	079e                	slli	a5,a5,0x7
    800021f6:	0000f717          	auipc	a4,0xf
    800021fa:	75a70713          	addi	a4,a4,1882 # 80011950 <q>
    800021fe:	97ba                	add	a5,a5,a4
    80002200:	0d87a703          	lw	a4,216(a5)
    80002204:	4785                	li	a5,1
    80002206:	06f71763          	bne	a4,a5,80002274 <sched+0xa6>
  if (p->state == RUNNING)
    8000220a:	4c98                	lw	a4,24(s1)
    8000220c:	478d                	li	a5,3
    8000220e:	06f70b63          	beq	a4,a5,80002284 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002212:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002216:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002218:	efb5                	bnez	a5,80002294 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000221a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000221c:	0000f917          	auipc	s2,0xf
    80002220:	73490913          	addi	s2,s2,1844 # 80011950 <q>
    80002224:	2781                	sext.w	a5,a5
    80002226:	079e                	slli	a5,a5,0x7
    80002228:	97ca                	add	a5,a5,s2
    8000222a:	0dc7a983          	lw	s3,220(a5)
    8000222e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002230:	2781                	sext.w	a5,a5
    80002232:	079e                	slli	a5,a5,0x7
    80002234:	0000f597          	auipc	a1,0xf
    80002238:	78458593          	addi	a1,a1,1924 # 800119b8 <cpus+0x8>
    8000223c:	95be                	add	a1,a1,a5
    8000223e:	06048513          	addi	a0,s1,96
    80002242:	00000097          	auipc	ra,0x0
    80002246:	656080e7          	jalr	1622(ra) # 80002898 <swtch>
    8000224a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000224c:	2781                	sext.w	a5,a5
    8000224e:	079e                	slli	a5,a5,0x7
    80002250:	97ca                	add	a5,a5,s2
    80002252:	0d37ae23          	sw	s3,220(a5)
}
    80002256:	70a2                	ld	ra,40(sp)
    80002258:	7402                	ld	s0,32(sp)
    8000225a:	64e2                	ld	s1,24(sp)
    8000225c:	6942                	ld	s2,16(sp)
    8000225e:	69a2                	ld	s3,8(sp)
    80002260:	6145                	addi	sp,sp,48
    80002262:	8082                	ret
    panic("sched p->lock");
    80002264:	00006517          	auipc	a0,0x6
    80002268:	02c50513          	addi	a0,a0,44 # 80008290 <digits+0x250>
    8000226c:	ffffe097          	auipc	ra,0xffffe
    80002270:	2d6080e7          	jalr	726(ra) # 80000542 <panic>
    panic("sched locks");
    80002274:	00006517          	auipc	a0,0x6
    80002278:	02c50513          	addi	a0,a0,44 # 800082a0 <digits+0x260>
    8000227c:	ffffe097          	auipc	ra,0xffffe
    80002280:	2c6080e7          	jalr	710(ra) # 80000542 <panic>
    panic("sched running");
    80002284:	00006517          	auipc	a0,0x6
    80002288:	02c50513          	addi	a0,a0,44 # 800082b0 <digits+0x270>
    8000228c:	ffffe097          	auipc	ra,0xffffe
    80002290:	2b6080e7          	jalr	694(ra) # 80000542 <panic>
    panic("sched interruptible");
    80002294:	00006517          	auipc	a0,0x6
    80002298:	02c50513          	addi	a0,a0,44 # 800082c0 <digits+0x280>
    8000229c:	ffffe097          	auipc	ra,0xffffe
    800022a0:	2a6080e7          	jalr	678(ra) # 80000542 <panic>

00000000800022a4 <exit>:
{
    800022a4:	7179                	addi	sp,sp,-48
    800022a6:	f406                	sd	ra,40(sp)
    800022a8:	f022                	sd	s0,32(sp)
    800022aa:	ec26                	sd	s1,24(sp)
    800022ac:	e84a                	sd	s2,16(sp)
    800022ae:	e44e                	sd	s3,8(sp)
    800022b0:	e052                	sd	s4,0(sp)
    800022b2:	1800                	addi	s0,sp,48
    800022b4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022b6:	00000097          	auipc	ra,0x0
    800022ba:	81e080e7          	jalr	-2018(ra) # 80001ad4 <myproc>
    800022be:	892a                	mv	s2,a0
  if (p == initproc)
    800022c0:	00007797          	auipc	a5,0x7
    800022c4:	d587b783          	ld	a5,-680(a5) # 80009018 <initproc>
    800022c8:	0d050493          	addi	s1,a0,208
    800022cc:	15050993          	addi	s3,a0,336
    800022d0:	02a79363          	bne	a5,a0,800022f6 <exit+0x52>
    panic("init exiting");
    800022d4:	00006517          	auipc	a0,0x6
    800022d8:	00450513          	addi	a0,a0,4 # 800082d8 <digits+0x298>
    800022dc:	ffffe097          	auipc	ra,0xffffe
    800022e0:	266080e7          	jalr	614(ra) # 80000542 <panic>
      fileclose(f);
    800022e4:	00002097          	auipc	ra,0x2
    800022e8:	4aa080e7          	jalr	1194(ra) # 8000478e <fileclose>
      p->ofile[fd] = 0;
    800022ec:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800022f0:	04a1                	addi	s1,s1,8
    800022f2:	01348563          	beq	s1,s3,800022fc <exit+0x58>
    if (p->ofile[fd])
    800022f6:	6088                	ld	a0,0(s1)
    800022f8:	f575                	bnez	a0,800022e4 <exit+0x40>
    800022fa:	bfdd                	j	800022f0 <exit+0x4c>
  begin_op();
    800022fc:	00002097          	auipc	ra,0x2
    80002300:	fc0080e7          	jalr	-64(ra) # 800042bc <begin_op>
  iput(p->cwd);
    80002304:	15093503          	ld	a0,336(s2)
    80002308:	00001097          	auipc	ra,0x1
    8000230c:	7ae080e7          	jalr	1966(ra) # 80003ab6 <iput>
  end_op();
    80002310:	00002097          	auipc	ra,0x2
    80002314:	02c080e7          	jalr	44(ra) # 8000433c <end_op>
  p->cwd = 0;
    80002318:	14093823          	sd	zero,336(s2)
  acquire(&initproc->lock);
    8000231c:	00007497          	auipc	s1,0x7
    80002320:	cfc48493          	addi	s1,s1,-772 # 80009018 <initproc>
    80002324:	6088                	ld	a0,0(s1)
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	8d8080e7          	jalr	-1832(ra) # 80000bfe <acquire>
  wakeup1(initproc);
    8000232e:	6088                	ld	a0,0(s1)
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	64a080e7          	jalr	1610(ra) # 8000197a <wakeup1>
  release(&initproc->lock);
    80002338:	6088                	ld	a0,0(s1)
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	978080e7          	jalr	-1672(ra) # 80000cb2 <release>
  acquire(&p->lock);
    80002342:	854a                	mv	a0,s2
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	8ba080e7          	jalr	-1862(ra) # 80000bfe <acquire>
  struct proc *original_parent = p->parent;
    8000234c:	02093483          	ld	s1,32(s2)
  release(&p->lock);
    80002350:	854a                	mv	a0,s2
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	960080e7          	jalr	-1696(ra) # 80000cb2 <release>
  acquire(&original_parent->lock);
    8000235a:	8526                	mv	a0,s1
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	8a2080e7          	jalr	-1886(ra) # 80000bfe <acquire>
  acquire(&p->lock);
    80002364:	854a                	mv	a0,s2
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	898080e7          	jalr	-1896(ra) # 80000bfe <acquire>
  reparent(p);
    8000236e:	854a                	mv	a0,s2
    80002370:	00000097          	auipc	ra,0x0
    80002374:	ccc080e7          	jalr	-820(ra) # 8000203c <reparent>
  wakeup1(original_parent);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	600080e7          	jalr	1536(ra) # 8000197a <wakeup1>
  p->xstate = status;
    80002382:	03492a23          	sw	s4,52(s2)
  p->state = ZOMBIE;
    80002386:	4791                	li	a5,4
    80002388:	00f92c23          	sw	a5,24(s2)
  printf("Q0\n");
    8000238c:	00006517          	auipc	a0,0x6
    80002390:	f5c50513          	addi	a0,a0,-164 # 800082e8 <digits+0x2a8>
    80002394:	ffffe097          	auipc	ra,0xffffe
    80002398:	1f8080e7          	jalr	504(ra) # 8000058c <printf>
  deleteproc(p, p->priority);
    8000239c:	17492583          	lw	a1,372(s2)
    800023a0:	854a                	mv	a0,s2
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	57a080e7          	jalr	1402(ra) # 8000191c <deleteproc>
  insertproc(p, 0);
    800023aa:	4581                	li	a1,0
    800023ac:	854a                	mv	a0,s2
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	4f8080e7          	jalr	1272(ra) # 800018a6 <insertproc>
  release(&original_parent->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	8fa080e7          	jalr	-1798(ra) # 80000cb2 <release>
  sched();
    800023c0:	00000097          	auipc	ra,0x0
    800023c4:	e0e080e7          	jalr	-498(ra) # 800021ce <sched>
  panic("zombie exit");
    800023c8:	00006517          	auipc	a0,0x6
    800023cc:	f2850513          	addi	a0,a0,-216 # 800082f0 <digits+0x2b0>
    800023d0:	ffffe097          	auipc	ra,0xffffe
    800023d4:	172080e7          	jalr	370(ra) # 80000542 <panic>

00000000800023d8 <yield>:
{
    800023d8:	1101                	addi	sp,sp,-32
    800023da:	ec06                	sd	ra,24(sp)
    800023dc:	e822                	sd	s0,16(sp)
    800023de:	e426                	sd	s1,8(sp)
    800023e0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	6f2080e7          	jalr	1778(ra) # 80001ad4 <myproc>
    800023ea:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	812080e7          	jalr	-2030(ra) # 80000bfe <acquire>
  p->state = RUNNABLE;
    800023f4:	4709                	li	a4,2
    800023f6:	cc98                	sw	a4,24(s1)
  if (p->priority == 2)
    800023f8:	1744a783          	lw	a5,372(s1)
    800023fc:	00e78c63          	beq	a5,a4,80002414 <yield+0x3c>
  else if (p->priority == 1)
    80002400:	4705                	li	a4,1
    80002402:	02e78b63          	beq	a5,a4,80002438 <yield+0x60>
  else if (p->priority == 0)
    80002406:	ef95                	bnez	a5,80002442 <yield+0x6a>
    (p->Qtime[0]++);
    80002408:	1684a783          	lw	a5,360(s1)
    8000240c:	2785                	addiw	a5,a5,1
    8000240e:	16f4a423          	sw	a5,360(s1)
    80002412:	a805                	j	80002442 <yield+0x6a>
    deleteproc(p, 2);
    80002414:	4589                	li	a1,2
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	504080e7          	jalr	1284(ra) # 8000191c <deleteproc>
    insertproc(p, 1);
    80002420:	4585                	li	a1,1
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	482080e7          	jalr	1154(ra) # 800018a6 <insertproc>
    (p->Qtime[2])++;
    8000242c:	1704a783          	lw	a5,368(s1)
    80002430:	2785                	addiw	a5,a5,1
    80002432:	16f4a823          	sw	a5,368(s1)
    80002436:	a031                	j	80002442 <yield+0x6a>
    (p->Qtime[1])++;
    80002438:	16c4a783          	lw	a5,364(s1)
    8000243c:	2785                	addiw	a5,a5,1
    8000243e:	16f4a623          	sw	a5,364(s1)
  sched();
    80002442:	00000097          	auipc	ra,0x0
    80002446:	d8c080e7          	jalr	-628(ra) # 800021ce <sched>
  release(&p->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	866080e7          	jalr	-1946(ra) # 80000cb2 <release>
}
    80002454:	60e2                	ld	ra,24(sp)
    80002456:	6442                	ld	s0,16(sp)
    80002458:	64a2                	ld	s1,8(sp)
    8000245a:	6105                	addi	sp,sp,32
    8000245c:	8082                	ret

000000008000245e <sleep>:
{
    8000245e:	7179                	addi	sp,sp,-48
    80002460:	f406                	sd	ra,40(sp)
    80002462:	f022                	sd	s0,32(sp)
    80002464:	ec26                	sd	s1,24(sp)
    80002466:	e84a                	sd	s2,16(sp)
    80002468:	e44e                	sd	s3,8(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	89aa                	mv	s3,a0
    8000246e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	664080e7          	jalr	1636(ra) # 80001ad4 <myproc>
    80002478:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    8000247a:	07250f63          	beq	a0,s2,800024f8 <sleep+0x9a>
    acquire(&p->lock); //DOC: sleeplock1
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	780080e7          	jalr	1920(ra) # 80000bfe <acquire>
    release(lk);
    80002486:	854a                	mv	a0,s2
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	82a080e7          	jalr	-2006(ra) # 80000cb2 <release>
  p->chan = chan;
    80002490:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002494:	4785                	li	a5,1
    80002496:	cc9c                	sw	a5,24(s1)
  sched();
    80002498:	00000097          	auipc	ra,0x0
    8000249c:	d36080e7          	jalr	-714(ra) # 800021ce <sched>
  p->chan = 0;
    800024a0:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800024a4:	8526                	mv	a0,s1
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	80c080e7          	jalr	-2036(ra) # 80000cb2 <release>
    acquire(lk);
    800024ae:	854a                	mv	a0,s2
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	74e080e7          	jalr	1870(ra) # 80000bfe <acquire>
  printf("Sleep %s %d\n", p->name, p->priority);
    800024b8:	1744a603          	lw	a2,372(s1)
    800024bc:	15848593          	addi	a1,s1,344
    800024c0:	00006517          	auipc	a0,0x6
    800024c4:	e4050513          	addi	a0,a0,-448 # 80008300 <digits+0x2c0>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	0c4080e7          	jalr	196(ra) # 8000058c <printf>
  deleteproc(p, p->priority);
    800024d0:	1744a583          	lw	a1,372(s1)
    800024d4:	8526                	mv	a0,s1
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	446080e7          	jalr	1094(ra) # 8000191c <deleteproc>
  insertproc(p, 0);
    800024de:	4581                	li	a1,0
    800024e0:	8526                	mv	a0,s1
    800024e2:	fffff097          	auipc	ra,0xfffff
    800024e6:	3c4080e7          	jalr	964(ra) # 800018a6 <insertproc>
}
    800024ea:	70a2                	ld	ra,40(sp)
    800024ec:	7402                	ld	s0,32(sp)
    800024ee:	64e2                	ld	s1,24(sp)
    800024f0:	6942                	ld	s2,16(sp)
    800024f2:	69a2                	ld	s3,8(sp)
    800024f4:	6145                	addi	sp,sp,48
    800024f6:	8082                	ret
  p->chan = chan;
    800024f8:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800024fc:	4785                	li	a5,1
    800024fe:	cd1c                	sw	a5,24(a0)
  sched();
    80002500:	00000097          	auipc	ra,0x0
    80002504:	cce080e7          	jalr	-818(ra) # 800021ce <sched>
  p->chan = 0;
    80002508:	0204b423          	sd	zero,40(s1)
  if (lk != &p->lock)
    8000250c:	b775                	j	800024b8 <sleep+0x5a>

000000008000250e <wait>:
{
    8000250e:	715d                	addi	sp,sp,-80
    80002510:	e486                	sd	ra,72(sp)
    80002512:	e0a2                	sd	s0,64(sp)
    80002514:	fc26                	sd	s1,56(sp)
    80002516:	f84a                	sd	s2,48(sp)
    80002518:	f44e                	sd	s3,40(sp)
    8000251a:	f052                	sd	s4,32(sp)
    8000251c:	ec56                	sd	s5,24(sp)
    8000251e:	e85a                	sd	s6,16(sp)
    80002520:	e45e                	sd	s7,8(sp)
    80002522:	0880                	addi	s0,sp,80
    80002524:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	5ae080e7          	jalr	1454(ra) # 80001ad4 <myproc>
    8000252e:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	6ce080e7          	jalr	1742(ra) # 80000bfe <acquire>
    havekids = 0;
    80002538:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000253a:	4a11                	li	s4,4
        havekids = 1;
    8000253c:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000253e:	00016997          	auipc	s3,0x16
    80002542:	87298993          	addi	s3,s3,-1934 # 80017db0 <tickslock>
    havekids = 0;
    80002546:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002548:	00010497          	auipc	s1,0x10
    8000254c:	86848493          	addi	s1,s1,-1944 # 80011db0 <proc>
    80002550:	a08d                	j	800025b2 <wait+0xa4>
          pid = np->pid;
    80002552:	0384a983          	lw	s3,56(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002556:	000b0e63          	beqz	s6,80002572 <wait+0x64>
    8000255a:	4691                	li	a3,4
    8000255c:	03448613          	addi	a2,s1,52
    80002560:	85da                	mv	a1,s6
    80002562:	05093503          	ld	a0,80(s2)
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	146080e7          	jalr	326(ra) # 800016ac <copyout>
    8000256e:	02054263          	bltz	a0,80002592 <wait+0x84>
          freeproc(np);
    80002572:	8526                	mv	a0,s1
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	712080e7          	jalr	1810(ra) # 80001c86 <freeproc>
          release(&np->lock);
    8000257c:	8526                	mv	a0,s1
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	734080e7          	jalr	1844(ra) # 80000cb2 <release>
          release(&p->lock);
    80002586:	854a                	mv	a0,s2
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	72a080e7          	jalr	1834(ra) # 80000cb2 <release>
          return pid;
    80002590:	a8a9                	j	800025ea <wait+0xdc>
            release(&np->lock);
    80002592:	8526                	mv	a0,s1
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	71e080e7          	jalr	1822(ra) # 80000cb2 <release>
            release(&p->lock);
    8000259c:	854a                	mv	a0,s2
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	714080e7          	jalr	1812(ra) # 80000cb2 <release>
            return -1;
    800025a6:	59fd                	li	s3,-1
    800025a8:	a089                	j	800025ea <wait+0xdc>
    for (np = proc; np < &proc[NPROC]; np++)
    800025aa:	18048493          	addi	s1,s1,384
    800025ae:	03348463          	beq	s1,s3,800025d6 <wait+0xc8>
      if (np->parent == p)
    800025b2:	709c                	ld	a5,32(s1)
    800025b4:	ff279be3          	bne	a5,s2,800025aa <wait+0x9c>
        acquire(&np->lock);
    800025b8:	8526                	mv	a0,s1
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	644080e7          	jalr	1604(ra) # 80000bfe <acquire>
        if (np->state == ZOMBIE)
    800025c2:	4c9c                	lw	a5,24(s1)
    800025c4:	f94787e3          	beq	a5,s4,80002552 <wait+0x44>
        release(&np->lock);
    800025c8:	8526                	mv	a0,s1
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	6e8080e7          	jalr	1768(ra) # 80000cb2 <release>
        havekids = 1;
    800025d2:	8756                	mv	a4,s5
    800025d4:	bfd9                	j	800025aa <wait+0x9c>
    if (!havekids || p->killed)
    800025d6:	c701                	beqz	a4,800025de <wait+0xd0>
    800025d8:	03092783          	lw	a5,48(s2)
    800025dc:	c39d                	beqz	a5,80002602 <wait+0xf4>
      release(&p->lock);
    800025de:	854a                	mv	a0,s2
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	6d2080e7          	jalr	1746(ra) # 80000cb2 <release>
      return -1;
    800025e8:	59fd                	li	s3,-1
}
    800025ea:	854e                	mv	a0,s3
    800025ec:	60a6                	ld	ra,72(sp)
    800025ee:	6406                	ld	s0,64(sp)
    800025f0:	74e2                	ld	s1,56(sp)
    800025f2:	7942                	ld	s2,48(sp)
    800025f4:	79a2                	ld	s3,40(sp)
    800025f6:	7a02                	ld	s4,32(sp)
    800025f8:	6ae2                	ld	s5,24(sp)
    800025fa:	6b42                	ld	s6,16(sp)
    800025fc:	6ba2                	ld	s7,8(sp)
    800025fe:	6161                	addi	sp,sp,80
    80002600:	8082                	ret
    sleep(p, &p->lock); //DOC: wait-sleep
    80002602:	85ca                	mv	a1,s2
    80002604:	854a                	mv	a0,s2
    80002606:	00000097          	auipc	ra,0x0
    8000260a:	e58080e7          	jalr	-424(ra) # 8000245e <sleep>
    havekids = 0;
    8000260e:	bf25                	j	80002546 <wait+0x38>

0000000080002610 <wakeup>:
{
    80002610:	715d                	addi	sp,sp,-80
    80002612:	e486                	sd	ra,72(sp)
    80002614:	e0a2                	sd	s0,64(sp)
    80002616:	fc26                	sd	s1,56(sp)
    80002618:	f84a                	sd	s2,48(sp)
    8000261a:	f44e                	sd	s3,40(sp)
    8000261c:	f052                	sd	s4,32(sp)
    8000261e:	ec56                	sd	s5,24(sp)
    80002620:	e85a                	sd	s6,16(sp)
    80002622:	e45e                	sd	s7,8(sp)
    80002624:	0880                	addi	s0,sp,80
    80002626:	8aaa                	mv	s5,a0
  for (p = proc; p < &proc[NPROC]; p++)
    80002628:	0000f497          	auipc	s1,0xf
    8000262c:	78848493          	addi	s1,s1,1928 # 80011db0 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    80002630:	4a05                	li	s4,1
      printf("WakeUp %s\n", p->name);
    80002632:	00006b97          	auipc	s7,0x6
    80002636:	cdeb8b93          	addi	s7,s7,-802 # 80008310 <digits+0x2d0>
      p->state = RUNNABLE;
    8000263a:	4b09                	li	s6,2
  for (p = proc; p < &proc[NPROC]; p++)
    8000263c:	00015997          	auipc	s3,0x15
    80002640:	77498993          	addi	s3,s3,1908 # 80017db0 <tickslock>
    80002644:	a811                	j	80002658 <wakeup+0x48>
    release(&p->lock);
    80002646:	8526                	mv	a0,s1
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	66a080e7          	jalr	1642(ra) # 80000cb2 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002650:	18048493          	addi	s1,s1,384
    80002654:	05348463          	beq	s1,s3,8000269c <wakeup+0x8c>
    acquire(&p->lock);
    80002658:	8526                	mv	a0,s1
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	5a4080e7          	jalr	1444(ra) # 80000bfe <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    80002662:	4c9c                	lw	a5,24(s1)
    80002664:	ff4791e3          	bne	a5,s4,80002646 <wakeup+0x36>
    80002668:	749c                	ld	a5,40(s1)
    8000266a:	fd579ee3          	bne	a5,s5,80002646 <wakeup+0x36>
      printf("WakeUp %s\n", p->name);
    8000266e:	15848593          	addi	a1,s1,344
    80002672:	855e                	mv	a0,s7
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	f18080e7          	jalr	-232(ra) # 8000058c <printf>
      p->state = RUNNABLE;
    8000267c:	0164ac23          	sw	s6,24(s1)
      deleteproc(p, p->priority);
    80002680:	1744a583          	lw	a1,372(s1)
    80002684:	8526                	mv	a0,s1
    80002686:	fffff097          	auipc	ra,0xfffff
    8000268a:	296080e7          	jalr	662(ra) # 8000191c <deleteproc>
      insertproc(p, 2);
    8000268e:	85da                	mv	a1,s6
    80002690:	8526                	mv	a0,s1
    80002692:	fffff097          	auipc	ra,0xfffff
    80002696:	214080e7          	jalr	532(ra) # 800018a6 <insertproc>
    8000269a:	b775                	j	80002646 <wakeup+0x36>
}
    8000269c:	60a6                	ld	ra,72(sp)
    8000269e:	6406                	ld	s0,64(sp)
    800026a0:	74e2                	ld	s1,56(sp)
    800026a2:	7942                	ld	s2,48(sp)
    800026a4:	79a2                	ld	s3,40(sp)
    800026a6:	7a02                	ld	s4,32(sp)
    800026a8:	6ae2                	ld	s5,24(sp)
    800026aa:	6b42                	ld	s6,16(sp)
    800026ac:	6ba2                	ld	s7,8(sp)
    800026ae:	6161                	addi	sp,sp,80
    800026b0:	8082                	ret

00000000800026b2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026b2:	7179                	addi	sp,sp,-48
    800026b4:	f406                	sd	ra,40(sp)
    800026b6:	f022                	sd	s0,32(sp)
    800026b8:	ec26                	sd	s1,24(sp)
    800026ba:	e84a                	sd	s2,16(sp)
    800026bc:	e44e                	sd	s3,8(sp)
    800026be:	1800                	addi	s0,sp,48
    800026c0:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800026c2:	0000f497          	auipc	s1,0xf
    800026c6:	6ee48493          	addi	s1,s1,1774 # 80011db0 <proc>
    800026ca:	00015997          	auipc	s3,0x15
    800026ce:	6e698993          	addi	s3,s3,1766 # 80017db0 <tickslock>
  {
    acquire(&p->lock);
    800026d2:	8526                	mv	a0,s1
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	52a080e7          	jalr	1322(ra) # 80000bfe <acquire>
    if (p->pid == pid)
    800026dc:	5c9c                	lw	a5,56(s1)
    800026de:	01278d63          	beq	a5,s2,800026f8 <kill+0x46>
        insertproc(p, 2);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026e2:	8526                	mv	a0,s1
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	5ce080e7          	jalr	1486(ra) # 80000cb2 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026ec:	18048493          	addi	s1,s1,384
    800026f0:	ff3491e3          	bne	s1,s3,800026d2 <kill+0x20>
  }
  return -1;
    800026f4:	557d                	li	a0,-1
    800026f6:	a821                	j	8000270e <kill+0x5c>
      p->killed = 1;
    800026f8:	4785                	li	a5,1
    800026fa:	d89c                	sw	a5,48(s1)
      if (p->state == SLEEPING)
    800026fc:	4c98                	lw	a4,24(s1)
    800026fe:	00f70f63          	beq	a4,a5,8000271c <kill+0x6a>
      release(&p->lock);
    80002702:	8526                	mv	a0,s1
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	5ae080e7          	jalr	1454(ra) # 80000cb2 <release>
      return 0;
    8000270c:	4501                	li	a0,0
}
    8000270e:	70a2                	ld	ra,40(sp)
    80002710:	7402                	ld	s0,32(sp)
    80002712:	64e2                	ld	s1,24(sp)
    80002714:	6942                	ld	s2,16(sp)
    80002716:	69a2                	ld	s3,8(sp)
    80002718:	6145                	addi	sp,sp,48
    8000271a:	8082                	ret
        p->state = RUNNABLE;
    8000271c:	4789                	li	a5,2
    8000271e:	cc9c                	sw	a5,24(s1)
        deleteproc(p, p->priority);
    80002720:	1744a583          	lw	a1,372(s1)
    80002724:	8526                	mv	a0,s1
    80002726:	fffff097          	auipc	ra,0xfffff
    8000272a:	1f6080e7          	jalr	502(ra) # 8000191c <deleteproc>
        insertproc(p, 2);
    8000272e:	4589                	li	a1,2
    80002730:	8526                	mv	a0,s1
    80002732:	fffff097          	auipc	ra,0xfffff
    80002736:	174080e7          	jalr	372(ra) # 800018a6 <insertproc>
    8000273a:	b7e1                	j	80002702 <kill+0x50>

000000008000273c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000273c:	7179                	addi	sp,sp,-48
    8000273e:	f406                	sd	ra,40(sp)
    80002740:	f022                	sd	s0,32(sp)
    80002742:	ec26                	sd	s1,24(sp)
    80002744:	e84a                	sd	s2,16(sp)
    80002746:	e44e                	sd	s3,8(sp)
    80002748:	e052                	sd	s4,0(sp)
    8000274a:	1800                	addi	s0,sp,48
    8000274c:	84aa                	mv	s1,a0
    8000274e:	892e                	mv	s2,a1
    80002750:	89b2                	mv	s3,a2
    80002752:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	380080e7          	jalr	896(ra) # 80001ad4 <myproc>
  if (user_dst)
    8000275c:	c08d                	beqz	s1,8000277e <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000275e:	86d2                	mv	a3,s4
    80002760:	864e                	mv	a2,s3
    80002762:	85ca                	mv	a1,s2
    80002764:	6928                	ld	a0,80(a0)
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	f46080e7          	jalr	-186(ra) # 800016ac <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000276e:	70a2                	ld	ra,40(sp)
    80002770:	7402                	ld	s0,32(sp)
    80002772:	64e2                	ld	s1,24(sp)
    80002774:	6942                	ld	s2,16(sp)
    80002776:	69a2                	ld	s3,8(sp)
    80002778:	6a02                	ld	s4,0(sp)
    8000277a:	6145                	addi	sp,sp,48
    8000277c:	8082                	ret
    memmove((char *)dst, src, len);
    8000277e:	000a061b          	sext.w	a2,s4
    80002782:	85ce                	mv	a1,s3
    80002784:	854a                	mv	a0,s2
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	5d0080e7          	jalr	1488(ra) # 80000d56 <memmove>
    return 0;
    8000278e:	8526                	mv	a0,s1
    80002790:	bff9                	j	8000276e <either_copyout+0x32>

0000000080002792 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002792:	7179                	addi	sp,sp,-48
    80002794:	f406                	sd	ra,40(sp)
    80002796:	f022                	sd	s0,32(sp)
    80002798:	ec26                	sd	s1,24(sp)
    8000279a:	e84a                	sd	s2,16(sp)
    8000279c:	e44e                	sd	s3,8(sp)
    8000279e:	e052                	sd	s4,0(sp)
    800027a0:	1800                	addi	s0,sp,48
    800027a2:	892a                	mv	s2,a0
    800027a4:	84ae                	mv	s1,a1
    800027a6:	89b2                	mv	s3,a2
    800027a8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	32a080e7          	jalr	810(ra) # 80001ad4 <myproc>
  if (user_src)
    800027b2:	c08d                	beqz	s1,800027d4 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027b4:	86d2                	mv	a3,s4
    800027b6:	864e                	mv	a2,s3
    800027b8:	85ca                	mv	a1,s2
    800027ba:	6928                	ld	a0,80(a0)
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	f7c080e7          	jalr	-132(ra) # 80001738 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800027c4:	70a2                	ld	ra,40(sp)
    800027c6:	7402                	ld	s0,32(sp)
    800027c8:	64e2                	ld	s1,24(sp)
    800027ca:	6942                	ld	s2,16(sp)
    800027cc:	69a2                	ld	s3,8(sp)
    800027ce:	6a02                	ld	s4,0(sp)
    800027d0:	6145                	addi	sp,sp,48
    800027d2:	8082                	ret
    memmove(dst, (char *)src, len);
    800027d4:	000a061b          	sext.w	a2,s4
    800027d8:	85ce                	mv	a1,s3
    800027da:	854a                	mv	a0,s2
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	57a080e7          	jalr	1402(ra) # 80000d56 <memmove>
    return 0;
    800027e4:	8526                	mv	a0,s1
    800027e6:	bff9                	j	800027c4 <either_copyin+0x32>

00000000800027e8 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027e8:	715d                	addi	sp,sp,-80
    800027ea:	e486                	sd	ra,72(sp)
    800027ec:	e0a2                	sd	s0,64(sp)
    800027ee:	fc26                	sd	s1,56(sp)
    800027f0:	f84a                	sd	s2,48(sp)
    800027f2:	f44e                	sd	s3,40(sp)
    800027f4:	f052                	sd	s4,32(sp)
    800027f6:	ec56                	sd	s5,24(sp)
    800027f8:	e85a                	sd	s6,16(sp)
    800027fa:	e45e                	sd	s7,8(sp)
    800027fc:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800027fe:	00006517          	auipc	a0,0x6
    80002802:	8ea50513          	addi	a0,a0,-1814 # 800080e8 <digits+0xa8>
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	d86080e7          	jalr	-634(ra) # 8000058c <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000280e:	0000f497          	auipc	s1,0xf
    80002812:	6fa48493          	addi	s1,s1,1786 # 80011f08 <proc+0x158>
    80002816:	00015917          	auipc	s2,0x15
    8000281a:	6f290913          	addi	s2,s2,1778 # 80017f08 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000281e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002820:	00006997          	auipc	s3,0x6
    80002824:	b0098993          	addi	s3,s3,-1280 # 80008320 <digits+0x2e0>
    printf("%d %s %s", p->pid, state, p->name);
    80002828:	00006a97          	auipc	s5,0x6
    8000282c:	b00a8a93          	addi	s5,s5,-1280 # 80008328 <digits+0x2e8>
    printf("\n");
    80002830:	00006a17          	auipc	s4,0x6
    80002834:	8b8a0a13          	addi	s4,s4,-1864 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002838:	00006b97          	auipc	s7,0x6
    8000283c:	b28b8b93          	addi	s7,s7,-1240 # 80008360 <states.0>
    80002840:	a00d                	j	80002862 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002842:	ee06a583          	lw	a1,-288(a3)
    80002846:	8556                	mv	a0,s5
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d44080e7          	jalr	-700(ra) # 8000058c <printf>
    printf("\n");
    80002850:	8552                	mv	a0,s4
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	d3a080e7          	jalr	-710(ra) # 8000058c <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000285a:	18048493          	addi	s1,s1,384
    8000285e:	03248263          	beq	s1,s2,80002882 <procdump+0x9a>
    if (p->state == UNUSED)
    80002862:	86a6                	mv	a3,s1
    80002864:	ec04a783          	lw	a5,-320(s1)
    80002868:	dbed                	beqz	a5,8000285a <procdump+0x72>
      state = "???";
    8000286a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000286c:	fcfb6be3          	bltu	s6,a5,80002842 <procdump+0x5a>
    80002870:	02079713          	slli	a4,a5,0x20
    80002874:	01d75793          	srli	a5,a4,0x1d
    80002878:	97de                	add	a5,a5,s7
    8000287a:	6390                	ld	a2,0(a5)
    8000287c:	f279                	bnez	a2,80002842 <procdump+0x5a>
      state = "???";
    8000287e:	864e                	mv	a2,s3
    80002880:	b7c9                	j	80002842 <procdump+0x5a>
  }
}
    80002882:	60a6                	ld	ra,72(sp)
    80002884:	6406                	ld	s0,64(sp)
    80002886:	74e2                	ld	s1,56(sp)
    80002888:	7942                	ld	s2,48(sp)
    8000288a:	79a2                	ld	s3,40(sp)
    8000288c:	7a02                	ld	s4,32(sp)
    8000288e:	6ae2                	ld	s5,24(sp)
    80002890:	6b42                	ld	s6,16(sp)
    80002892:	6ba2                	ld	s7,8(sp)
    80002894:	6161                	addi	sp,sp,80
    80002896:	8082                	ret

0000000080002898 <swtch>:
    80002898:	00153023          	sd	ra,0(a0)
    8000289c:	00253423          	sd	sp,8(a0)
    800028a0:	e900                	sd	s0,16(a0)
    800028a2:	ed04                	sd	s1,24(a0)
    800028a4:	03253023          	sd	s2,32(a0)
    800028a8:	03353423          	sd	s3,40(a0)
    800028ac:	03453823          	sd	s4,48(a0)
    800028b0:	03553c23          	sd	s5,56(a0)
    800028b4:	05653023          	sd	s6,64(a0)
    800028b8:	05753423          	sd	s7,72(a0)
    800028bc:	05853823          	sd	s8,80(a0)
    800028c0:	05953c23          	sd	s9,88(a0)
    800028c4:	07a53023          	sd	s10,96(a0)
    800028c8:	07b53423          	sd	s11,104(a0)
    800028cc:	0005b083          	ld	ra,0(a1)
    800028d0:	0085b103          	ld	sp,8(a1)
    800028d4:	6980                	ld	s0,16(a1)
    800028d6:	6d84                	ld	s1,24(a1)
    800028d8:	0205b903          	ld	s2,32(a1)
    800028dc:	0285b983          	ld	s3,40(a1)
    800028e0:	0305ba03          	ld	s4,48(a1)
    800028e4:	0385ba83          	ld	s5,56(a1)
    800028e8:	0405bb03          	ld	s6,64(a1)
    800028ec:	0485bb83          	ld	s7,72(a1)
    800028f0:	0505bc03          	ld	s8,80(a1)
    800028f4:	0585bc83          	ld	s9,88(a1)
    800028f8:	0605bd03          	ld	s10,96(a1)
    800028fc:	0685bd83          	ld	s11,104(a1)
    80002900:	8082                	ret

0000000080002902 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002902:	1141                	addi	sp,sp,-16
    80002904:	e406                	sd	ra,8(sp)
    80002906:	e022                	sd	s0,0(sp)
    80002908:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000290a:	00006597          	auipc	a1,0x6
    8000290e:	a7e58593          	addi	a1,a1,-1410 # 80008388 <states.0+0x28>
    80002912:	00015517          	auipc	a0,0x15
    80002916:	49e50513          	addi	a0,a0,1182 # 80017db0 <tickslock>
    8000291a:	ffffe097          	auipc	ra,0xffffe
    8000291e:	254080e7          	jalr	596(ra) # 80000b6e <initlock>
}
    80002922:	60a2                	ld	ra,8(sp)
    80002924:	6402                	ld	s0,0(sp)
    80002926:	0141                	addi	sp,sp,16
    80002928:	8082                	ret

000000008000292a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000292a:	1141                	addi	sp,sp,-16
    8000292c:	e422                	sd	s0,8(sp)
    8000292e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002930:	00003797          	auipc	a5,0x3
    80002934:	4c078793          	addi	a5,a5,1216 # 80005df0 <kernelvec>
    80002938:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000293c:	6422                	ld	s0,8(sp)
    8000293e:	0141                	addi	sp,sp,16
    80002940:	8082                	ret

0000000080002942 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002942:	1141                	addi	sp,sp,-16
    80002944:	e406                	sd	ra,8(sp)
    80002946:	e022                	sd	s0,0(sp)
    80002948:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000294a:	fffff097          	auipc	ra,0xfffff
    8000294e:	18a080e7          	jalr	394(ra) # 80001ad4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002952:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002956:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002958:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000295c:	00004617          	auipc	a2,0x4
    80002960:	6a460613          	addi	a2,a2,1700 # 80007000 <_trampoline>
    80002964:	00004697          	auipc	a3,0x4
    80002968:	69c68693          	addi	a3,a3,1692 # 80007000 <_trampoline>
    8000296c:	8e91                	sub	a3,a3,a2
    8000296e:	040007b7          	lui	a5,0x4000
    80002972:	17fd                	addi	a5,a5,-1
    80002974:	07b2                	slli	a5,a5,0xc
    80002976:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002978:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000297c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000297e:	180026f3          	csrr	a3,satp
    80002982:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002984:	6d38                	ld	a4,88(a0)
    80002986:	6134                	ld	a3,64(a0)
    80002988:	6585                	lui	a1,0x1
    8000298a:	96ae                	add	a3,a3,a1
    8000298c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000298e:	6d38                	ld	a4,88(a0)
    80002990:	00000697          	auipc	a3,0x0
    80002994:	13868693          	addi	a3,a3,312 # 80002ac8 <usertrap>
    80002998:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000299a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000299c:	8692                	mv	a3,tp
    8000299e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029a4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029a8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ac:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029b0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029b2:	6f18                	ld	a4,24(a4)
    800029b4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029b8:	692c                	ld	a1,80(a0)
    800029ba:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029bc:	00004717          	auipc	a4,0x4
    800029c0:	6d470713          	addi	a4,a4,1748 # 80007090 <userret>
    800029c4:	8f11                	sub	a4,a4,a2
    800029c6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029c8:	577d                	li	a4,-1
    800029ca:	177e                	slli	a4,a4,0x3f
    800029cc:	8dd9                	or	a1,a1,a4
    800029ce:	02000537          	lui	a0,0x2000
    800029d2:	157d                	addi	a0,a0,-1
    800029d4:	0536                	slli	a0,a0,0xd
    800029d6:	9782                	jalr	a5
}
    800029d8:	60a2                	ld	ra,8(sp)
    800029da:	6402                	ld	s0,0(sp)
    800029dc:	0141                	addi	sp,sp,16
    800029de:	8082                	ret

00000000800029e0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029e0:	1101                	addi	sp,sp,-32
    800029e2:	ec06                	sd	ra,24(sp)
    800029e4:	e822                	sd	s0,16(sp)
    800029e6:	e426                	sd	s1,8(sp)
    800029e8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029ea:	00015497          	auipc	s1,0x15
    800029ee:	3c648493          	addi	s1,s1,966 # 80017db0 <tickslock>
    800029f2:	8526                	mv	a0,s1
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	20a080e7          	jalr	522(ra) # 80000bfe <acquire>
  ticks++;
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	62450513          	addi	a0,a0,1572 # 80009020 <ticks>
    80002a04:	411c                	lw	a5,0(a0)
    80002a06:	2785                	addiw	a5,a5,1
    80002a08:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	c06080e7          	jalr	-1018(ra) # 80002610 <wakeup>
  release(&tickslock);
    80002a12:	8526                	mv	a0,s1
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	29e080e7          	jalr	670(ra) # 80000cb2 <release>
}
    80002a1c:	60e2                	ld	ra,24(sp)
    80002a1e:	6442                	ld	s0,16(sp)
    80002a20:	64a2                	ld	s1,8(sp)
    80002a22:	6105                	addi	sp,sp,32
    80002a24:	8082                	ret

0000000080002a26 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a26:	1101                	addi	sp,sp,-32
    80002a28:	ec06                	sd	ra,24(sp)
    80002a2a:	e822                	sd	s0,16(sp)
    80002a2c:	e426                	sd	s1,8(sp)
    80002a2e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a30:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a34:	00074d63          	bltz	a4,80002a4e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a38:	57fd                	li	a5,-1
    80002a3a:	17fe                	slli	a5,a5,0x3f
    80002a3c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a3e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a40:	06f70363          	beq	a4,a5,80002aa6 <devintr+0x80>
  }
}
    80002a44:	60e2                	ld	ra,24(sp)
    80002a46:	6442                	ld	s0,16(sp)
    80002a48:	64a2                	ld	s1,8(sp)
    80002a4a:	6105                	addi	sp,sp,32
    80002a4c:	8082                	ret
     (scause & 0xff) == 9){
    80002a4e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a52:	46a5                	li	a3,9
    80002a54:	fed792e3          	bne	a5,a3,80002a38 <devintr+0x12>
    int irq = plic_claim();
    80002a58:	00003097          	auipc	ra,0x3
    80002a5c:	4a0080e7          	jalr	1184(ra) # 80005ef8 <plic_claim>
    80002a60:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a62:	47a9                	li	a5,10
    80002a64:	02f50763          	beq	a0,a5,80002a92 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a68:	4785                	li	a5,1
    80002a6a:	02f50963          	beq	a0,a5,80002a9c <devintr+0x76>
    return 1;
    80002a6e:	4505                	li	a0,1
    } else if(irq){
    80002a70:	d8f1                	beqz	s1,80002a44 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a72:	85a6                	mv	a1,s1
    80002a74:	00006517          	auipc	a0,0x6
    80002a78:	91c50513          	addi	a0,a0,-1764 # 80008390 <states.0+0x30>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	b10080e7          	jalr	-1264(ra) # 8000058c <printf>
      plic_complete(irq);
    80002a84:	8526                	mv	a0,s1
    80002a86:	00003097          	auipc	ra,0x3
    80002a8a:	496080e7          	jalr	1174(ra) # 80005f1c <plic_complete>
    return 1;
    80002a8e:	4505                	li	a0,1
    80002a90:	bf55                	j	80002a44 <devintr+0x1e>
      uartintr();
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	f30080e7          	jalr	-208(ra) # 800009c2 <uartintr>
    80002a9a:	b7ed                	j	80002a84 <devintr+0x5e>
      virtio_disk_intr();
    80002a9c:	00004097          	auipc	ra,0x4
    80002aa0:	8fa080e7          	jalr	-1798(ra) # 80006396 <virtio_disk_intr>
    80002aa4:	b7c5                	j	80002a84 <devintr+0x5e>
    if(cpuid() == 0){
    80002aa6:	fffff097          	auipc	ra,0xfffff
    80002aaa:	002080e7          	jalr	2(ra) # 80001aa8 <cpuid>
    80002aae:	c901                	beqz	a0,80002abe <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ab0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ab4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ab6:	14479073          	csrw	sip,a5
    return 2;
    80002aba:	4509                	li	a0,2
    80002abc:	b761                	j	80002a44 <devintr+0x1e>
      clockintr();
    80002abe:	00000097          	auipc	ra,0x0
    80002ac2:	f22080e7          	jalr	-222(ra) # 800029e0 <clockintr>
    80002ac6:	b7ed                	j	80002ab0 <devintr+0x8a>

0000000080002ac8 <usertrap>:
{
    80002ac8:	1101                	addi	sp,sp,-32
    80002aca:	ec06                	sd	ra,24(sp)
    80002acc:	e822                	sd	s0,16(sp)
    80002ace:	e426                	sd	s1,8(sp)
    80002ad0:	e04a                	sd	s2,0(sp)
    80002ad2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ad8:	1007f793          	andi	a5,a5,256
    80002adc:	e3ad                	bnez	a5,80002b3e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ade:	00003797          	auipc	a5,0x3
    80002ae2:	31278793          	addi	a5,a5,786 # 80005df0 <kernelvec>
    80002ae6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002aea:	fffff097          	auipc	ra,0xfffff
    80002aee:	fea080e7          	jalr	-22(ra) # 80001ad4 <myproc>
    80002af2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002af4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af6:	14102773          	csrr	a4,sepc
    80002afa:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b00:	47a1                	li	a5,8
    80002b02:	04f71c63          	bne	a4,a5,80002b5a <usertrap+0x92>
    if(p->killed)
    80002b06:	591c                	lw	a5,48(a0)
    80002b08:	e3b9                	bnez	a5,80002b4e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b0a:	6cb8                	ld	a4,88(s1)
    80002b0c:	6f1c                	ld	a5,24(a4)
    80002b0e:	0791                	addi	a5,a5,4
    80002b10:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b12:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b16:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b1a:	10079073          	csrw	sstatus,a5
    syscall();
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	2e0080e7          	jalr	736(ra) # 80002dfe <syscall>
  if(p->killed)
    80002b26:	589c                	lw	a5,48(s1)
    80002b28:	ebc1                	bnez	a5,80002bb8 <usertrap+0xf0>
  usertrapret();
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	e18080e7          	jalr	-488(ra) # 80002942 <usertrapret>
}
    80002b32:	60e2                	ld	ra,24(sp)
    80002b34:	6442                	ld	s0,16(sp)
    80002b36:	64a2                	ld	s1,8(sp)
    80002b38:	6902                	ld	s2,0(sp)
    80002b3a:	6105                	addi	sp,sp,32
    80002b3c:	8082                	ret
    panic("usertrap: not from user mode");
    80002b3e:	00006517          	auipc	a0,0x6
    80002b42:	87250513          	addi	a0,a0,-1934 # 800083b0 <states.0+0x50>
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	9fc080e7          	jalr	-1540(ra) # 80000542 <panic>
      exit(-1);
    80002b4e:	557d                	li	a0,-1
    80002b50:	fffff097          	auipc	ra,0xfffff
    80002b54:	754080e7          	jalr	1876(ra) # 800022a4 <exit>
    80002b58:	bf4d                	j	80002b0a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b5a:	00000097          	auipc	ra,0x0
    80002b5e:	ecc080e7          	jalr	-308(ra) # 80002a26 <devintr>
    80002b62:	892a                	mv	s2,a0
    80002b64:	c501                	beqz	a0,80002b6c <usertrap+0xa4>
  if(p->killed)
    80002b66:	589c                	lw	a5,48(s1)
    80002b68:	c3a1                	beqz	a5,80002ba8 <usertrap+0xe0>
    80002b6a:	a815                	j	80002b9e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b70:	5c90                	lw	a2,56(s1)
    80002b72:	00006517          	auipc	a0,0x6
    80002b76:	85e50513          	addi	a0,a0,-1954 # 800083d0 <states.0+0x70>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	a12080e7          	jalr	-1518(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b82:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b86:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b8a:	00006517          	auipc	a0,0x6
    80002b8e:	87650513          	addi	a0,a0,-1930 # 80008400 <states.0+0xa0>
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	9fa080e7          	jalr	-1542(ra) # 8000058c <printf>
    p->killed = 1;
    80002b9a:	4785                	li	a5,1
    80002b9c:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002b9e:	557d                	li	a0,-1
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	704080e7          	jalr	1796(ra) # 800022a4 <exit>
  if(which_dev == 2)
    80002ba8:	4789                	li	a5,2
    80002baa:	f8f910e3          	bne	s2,a5,80002b2a <usertrap+0x62>
    yield();
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	82a080e7          	jalr	-2006(ra) # 800023d8 <yield>
    80002bb6:	bf95                	j	80002b2a <usertrap+0x62>
  int which_dev = 0;
    80002bb8:	4901                	li	s2,0
    80002bba:	b7d5                	j	80002b9e <usertrap+0xd6>

0000000080002bbc <kerneltrap>:
{
    80002bbc:	7179                	addi	sp,sp,-48
    80002bbe:	f406                	sd	ra,40(sp)
    80002bc0:	f022                	sd	s0,32(sp)
    80002bc2:	ec26                	sd	s1,24(sp)
    80002bc4:	e84a                	sd	s2,16(sp)
    80002bc6:	e44e                	sd	s3,8(sp)
    80002bc8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bca:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bce:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bd6:	1004f793          	andi	a5,s1,256
    80002bda:	cb85                	beqz	a5,80002c0a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bdc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002be0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002be2:	ef85                	bnez	a5,80002c1a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	e42080e7          	jalr	-446(ra) # 80002a26 <devintr>
    80002bec:	cd1d                	beqz	a0,80002c2a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bee:	4789                	li	a5,2
    80002bf0:	06f50a63          	beq	a0,a5,80002c64 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bf4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bf8:	10049073          	csrw	sstatus,s1
}
    80002bfc:	70a2                	ld	ra,40(sp)
    80002bfe:	7402                	ld	s0,32(sp)
    80002c00:	64e2                	ld	s1,24(sp)
    80002c02:	6942                	ld	s2,16(sp)
    80002c04:	69a2                	ld	s3,8(sp)
    80002c06:	6145                	addi	sp,sp,48
    80002c08:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c0a:	00006517          	auipc	a0,0x6
    80002c0e:	81650513          	addi	a0,a0,-2026 # 80008420 <states.0+0xc0>
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	930080e7          	jalr	-1744(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c1a:	00006517          	auipc	a0,0x6
    80002c1e:	82e50513          	addi	a0,a0,-2002 # 80008448 <states.0+0xe8>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	920080e7          	jalr	-1760(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002c2a:	85ce                	mv	a1,s3
    80002c2c:	00006517          	auipc	a0,0x6
    80002c30:	83c50513          	addi	a0,a0,-1988 # 80008468 <states.0+0x108>
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	958080e7          	jalr	-1704(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c40:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c44:	00006517          	auipc	a0,0x6
    80002c48:	83450513          	addi	a0,a0,-1996 # 80008478 <states.0+0x118>
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	940080e7          	jalr	-1728(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002c54:	00006517          	auipc	a0,0x6
    80002c58:	83c50513          	addi	a0,a0,-1988 # 80008490 <states.0+0x130>
    80002c5c:	ffffe097          	auipc	ra,0xffffe
    80002c60:	8e6080e7          	jalr	-1818(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	e70080e7          	jalr	-400(ra) # 80001ad4 <myproc>
    80002c6c:	d541                	beqz	a0,80002bf4 <kerneltrap+0x38>
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	e66080e7          	jalr	-410(ra) # 80001ad4 <myproc>
    80002c76:	4d18                	lw	a4,24(a0)
    80002c78:	478d                	li	a5,3
    80002c7a:	f6f71de3          	bne	a4,a5,80002bf4 <kerneltrap+0x38>
    yield();
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	75a080e7          	jalr	1882(ra) # 800023d8 <yield>
    80002c86:	b7bd                	j	80002bf4 <kerneltrap+0x38>

0000000080002c88 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c88:	1101                	addi	sp,sp,-32
    80002c8a:	ec06                	sd	ra,24(sp)
    80002c8c:	e822                	sd	s0,16(sp)
    80002c8e:	e426                	sd	s1,8(sp)
    80002c90:	1000                	addi	s0,sp,32
    80002c92:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	e40080e7          	jalr	-448(ra) # 80001ad4 <myproc>
  switch (n)
    80002c9c:	4795                	li	a5,5
    80002c9e:	0497e163          	bltu	a5,s1,80002ce0 <argraw+0x58>
    80002ca2:	048a                	slli	s1,s1,0x2
    80002ca4:	00006717          	auipc	a4,0x6
    80002ca8:	82470713          	addi	a4,a4,-2012 # 800084c8 <states.0+0x168>
    80002cac:	94ba                	add	s1,s1,a4
    80002cae:	409c                	lw	a5,0(s1)
    80002cb0:	97ba                	add	a5,a5,a4
    80002cb2:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002cb4:	6d3c                	ld	a5,88(a0)
    80002cb6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cb8:	60e2                	ld	ra,24(sp)
    80002cba:	6442                	ld	s0,16(sp)
    80002cbc:	64a2                	ld	s1,8(sp)
    80002cbe:	6105                	addi	sp,sp,32
    80002cc0:	8082                	ret
    return p->trapframe->a1;
    80002cc2:	6d3c                	ld	a5,88(a0)
    80002cc4:	7fa8                	ld	a0,120(a5)
    80002cc6:	bfcd                	j	80002cb8 <argraw+0x30>
    return p->trapframe->a2;
    80002cc8:	6d3c                	ld	a5,88(a0)
    80002cca:	63c8                	ld	a0,128(a5)
    80002ccc:	b7f5                	j	80002cb8 <argraw+0x30>
    return p->trapframe->a3;
    80002cce:	6d3c                	ld	a5,88(a0)
    80002cd0:	67c8                	ld	a0,136(a5)
    80002cd2:	b7dd                	j	80002cb8 <argraw+0x30>
    return p->trapframe->a4;
    80002cd4:	6d3c                	ld	a5,88(a0)
    80002cd6:	6bc8                	ld	a0,144(a5)
    80002cd8:	b7c5                	j	80002cb8 <argraw+0x30>
    return p->trapframe->a5;
    80002cda:	6d3c                	ld	a5,88(a0)
    80002cdc:	6fc8                	ld	a0,152(a5)
    80002cde:	bfe9                	j	80002cb8 <argraw+0x30>
  panic("argraw");
    80002ce0:	00005517          	auipc	a0,0x5
    80002ce4:	7c050513          	addi	a0,a0,1984 # 800084a0 <states.0+0x140>
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	85a080e7          	jalr	-1958(ra) # 80000542 <panic>

0000000080002cf0 <fetchaddr>:
{
    80002cf0:	1101                	addi	sp,sp,-32
    80002cf2:	ec06                	sd	ra,24(sp)
    80002cf4:	e822                	sd	s0,16(sp)
    80002cf6:	e426                	sd	s1,8(sp)
    80002cf8:	e04a                	sd	s2,0(sp)
    80002cfa:	1000                	addi	s0,sp,32
    80002cfc:	84aa                	mv	s1,a0
    80002cfe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	dd4080e7          	jalr	-556(ra) # 80001ad4 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002d08:	653c                	ld	a5,72(a0)
    80002d0a:	02f4f863          	bgeu	s1,a5,80002d3a <fetchaddr+0x4a>
    80002d0e:	00848713          	addi	a4,s1,8
    80002d12:	02e7e663          	bltu	a5,a4,80002d3e <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d16:	46a1                	li	a3,8
    80002d18:	8626                	mv	a2,s1
    80002d1a:	85ca                	mv	a1,s2
    80002d1c:	6928                	ld	a0,80(a0)
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	a1a080e7          	jalr	-1510(ra) # 80001738 <copyin>
    80002d26:	00a03533          	snez	a0,a0
    80002d2a:	40a00533          	neg	a0,a0
}
    80002d2e:	60e2                	ld	ra,24(sp)
    80002d30:	6442                	ld	s0,16(sp)
    80002d32:	64a2                	ld	s1,8(sp)
    80002d34:	6902                	ld	s2,0(sp)
    80002d36:	6105                	addi	sp,sp,32
    80002d38:	8082                	ret
    return -1;
    80002d3a:	557d                	li	a0,-1
    80002d3c:	bfcd                	j	80002d2e <fetchaddr+0x3e>
    80002d3e:	557d                	li	a0,-1
    80002d40:	b7fd                	j	80002d2e <fetchaddr+0x3e>

0000000080002d42 <fetchstr>:
{
    80002d42:	7179                	addi	sp,sp,-48
    80002d44:	f406                	sd	ra,40(sp)
    80002d46:	f022                	sd	s0,32(sp)
    80002d48:	ec26                	sd	s1,24(sp)
    80002d4a:	e84a                	sd	s2,16(sp)
    80002d4c:	e44e                	sd	s3,8(sp)
    80002d4e:	1800                	addi	s0,sp,48
    80002d50:	892a                	mv	s2,a0
    80002d52:	84ae                	mv	s1,a1
    80002d54:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	d7e080e7          	jalr	-642(ra) # 80001ad4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d5e:	86ce                	mv	a3,s3
    80002d60:	864a                	mv	a2,s2
    80002d62:	85a6                	mv	a1,s1
    80002d64:	6928                	ld	a0,80(a0)
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	a60080e7          	jalr	-1440(ra) # 800017c6 <copyinstr>
  if (err < 0)
    80002d6e:	00054763          	bltz	a0,80002d7c <fetchstr+0x3a>
  return strlen(buf);
    80002d72:	8526                	mv	a0,s1
    80002d74:	ffffe097          	auipc	ra,0xffffe
    80002d78:	10a080e7          	jalr	266(ra) # 80000e7e <strlen>
}
    80002d7c:	70a2                	ld	ra,40(sp)
    80002d7e:	7402                	ld	s0,32(sp)
    80002d80:	64e2                	ld	s1,24(sp)
    80002d82:	6942                	ld	s2,16(sp)
    80002d84:	69a2                	ld	s3,8(sp)
    80002d86:	6145                	addi	sp,sp,48
    80002d88:	8082                	ret

0000000080002d8a <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002d8a:	1101                	addi	sp,sp,-32
    80002d8c:	ec06                	sd	ra,24(sp)
    80002d8e:	e822                	sd	s0,16(sp)
    80002d90:	e426                	sd	s1,8(sp)
    80002d92:	1000                	addi	s0,sp,32
    80002d94:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	ef2080e7          	jalr	-270(ra) # 80002c88 <argraw>
    80002d9e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002da0:	4501                	li	a0,0
    80002da2:	60e2                	ld	ra,24(sp)
    80002da4:	6442                	ld	s0,16(sp)
    80002da6:	64a2                	ld	s1,8(sp)
    80002da8:	6105                	addi	sp,sp,32
    80002daa:	8082                	ret

0000000080002dac <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002dac:	1101                	addi	sp,sp,-32
    80002dae:	ec06                	sd	ra,24(sp)
    80002db0:	e822                	sd	s0,16(sp)
    80002db2:	e426                	sd	s1,8(sp)
    80002db4:	1000                	addi	s0,sp,32
    80002db6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002db8:	00000097          	auipc	ra,0x0
    80002dbc:	ed0080e7          	jalr	-304(ra) # 80002c88 <argraw>
    80002dc0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dc2:	4501                	li	a0,0
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	64a2                	ld	s1,8(sp)
    80002dca:	6105                	addi	sp,sp,32
    80002dcc:	8082                	ret

0000000080002dce <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002dce:	1101                	addi	sp,sp,-32
    80002dd0:	ec06                	sd	ra,24(sp)
    80002dd2:	e822                	sd	s0,16(sp)
    80002dd4:	e426                	sd	s1,8(sp)
    80002dd6:	e04a                	sd	s2,0(sp)
    80002dd8:	1000                	addi	s0,sp,32
    80002dda:	84ae                	mv	s1,a1
    80002ddc:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002dde:	00000097          	auipc	ra,0x0
    80002de2:	eaa080e7          	jalr	-342(ra) # 80002c88 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002de6:	864a                	mv	a2,s2
    80002de8:	85a6                	mv	a1,s1
    80002dea:	00000097          	auipc	ra,0x0
    80002dee:	f58080e7          	jalr	-168(ra) # 80002d42 <fetchstr>
}
    80002df2:	60e2                	ld	ra,24(sp)
    80002df4:	6442                	ld	s0,16(sp)
    80002df6:	64a2                	ld	s1,8(sp)
    80002df8:	6902                	ld	s2,0(sp)
    80002dfa:	6105                	addi	sp,sp,32
    80002dfc:	8082                	ret

0000000080002dfe <syscall>:
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
};

void syscall(void)
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	e426                	sd	s1,8(sp)
    80002e06:	e04a                	sd	s2,0(sp)
    80002e08:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	cca080e7          	jalr	-822(ra) # 80001ad4 <myproc>
    80002e12:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e14:	05853903          	ld	s2,88(a0)
    80002e18:	0a893783          	ld	a5,168(s2)
    80002e1c:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002e20:	37fd                	addiw	a5,a5,-1
    80002e22:	4751                	li	a4,20
    80002e24:	00f76f63          	bltu	a4,a5,80002e42 <syscall+0x44>
    80002e28:	00369713          	slli	a4,a3,0x3
    80002e2c:	00005797          	auipc	a5,0x5
    80002e30:	6b478793          	addi	a5,a5,1716 # 800084e0 <syscalls>
    80002e34:	97ba                	add	a5,a5,a4
    80002e36:	639c                	ld	a5,0(a5)
    80002e38:	c789                	beqz	a5,80002e42 <syscall+0x44>
  {
    p->trapframe->a0 = syscalls[num]();
    80002e3a:	9782                	jalr	a5
    80002e3c:	06a93823          	sd	a0,112(s2)
    80002e40:	a839                	j	80002e5e <syscall+0x60>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002e42:	15848613          	addi	a2,s1,344
    80002e46:	5c8c                	lw	a1,56(s1)
    80002e48:	00005517          	auipc	a0,0x5
    80002e4c:	66050513          	addi	a0,a0,1632 # 800084a8 <states.0+0x148>
    80002e50:	ffffd097          	auipc	ra,0xffffd
    80002e54:	73c080e7          	jalr	1852(ra) # 8000058c <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e58:	6cbc                	ld	a5,88(s1)
    80002e5a:	577d                	li	a4,-1
    80002e5c:	fbb8                	sd	a4,112(a5)
  }
}
    80002e5e:	60e2                	ld	ra,24(sp)
    80002e60:	6442                	ld	s0,16(sp)
    80002e62:	64a2                	ld	s1,8(sp)
    80002e64:	6902                	ld	s2,0(sp)
    80002e66:	6105                	addi	sp,sp,32
    80002e68:	8082                	ret

0000000080002e6a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e6a:	1101                	addi	sp,sp,-32
    80002e6c:	ec06                	sd	ra,24(sp)
    80002e6e:	e822                	sd	s0,16(sp)
    80002e70:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e72:	fec40593          	addi	a1,s0,-20
    80002e76:	4501                	li	a0,0
    80002e78:	00000097          	auipc	ra,0x0
    80002e7c:	f12080e7          	jalr	-238(ra) # 80002d8a <argint>
    return -1;
    80002e80:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e82:	00054963          	bltz	a0,80002e94 <sys_exit+0x2a>
  exit(n);
    80002e86:	fec42503          	lw	a0,-20(s0)
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	41a080e7          	jalr	1050(ra) # 800022a4 <exit>
  return 0;  // not reached
    80002e92:	4781                	li	a5,0
}
    80002e94:	853e                	mv	a0,a5
    80002e96:	60e2                	ld	ra,24(sp)
    80002e98:	6442                	ld	s0,16(sp)
    80002e9a:	6105                	addi	sp,sp,32
    80002e9c:	8082                	ret

0000000080002e9e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e9e:	1141                	addi	sp,sp,-16
    80002ea0:	e406                	sd	ra,8(sp)
    80002ea2:	e022                	sd	s0,0(sp)
    80002ea4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	c2e080e7          	jalr	-978(ra) # 80001ad4 <myproc>
}
    80002eae:	5d08                	lw	a0,56(a0)
    80002eb0:	60a2                	ld	ra,8(sp)
    80002eb2:	6402                	ld	s0,0(sp)
    80002eb4:	0141                	addi	sp,sp,16
    80002eb6:	8082                	ret

0000000080002eb8 <sys_fork>:

uint64
sys_fork(void)
{
    80002eb8:	1141                	addi	sp,sp,-16
    80002eba:	e406                	sd	ra,8(sp)
    80002ebc:	e022                	sd	s0,0(sp)
    80002ebe:	0800                	addi	s0,sp,16
  return fork();
    80002ec0:	fffff097          	auipc	ra,0xfffff
    80002ec4:	044080e7          	jalr	68(ra) # 80001f04 <fork>
}
    80002ec8:	60a2                	ld	ra,8(sp)
    80002eca:	6402                	ld	s0,0(sp)
    80002ecc:	0141                	addi	sp,sp,16
    80002ece:	8082                	ret

0000000080002ed0 <sys_wait>:

uint64
sys_wait(void)
{
    80002ed0:	1101                	addi	sp,sp,-32
    80002ed2:	ec06                	sd	ra,24(sp)
    80002ed4:	e822                	sd	s0,16(sp)
    80002ed6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ed8:	fe840593          	addi	a1,s0,-24
    80002edc:	4501                	li	a0,0
    80002ede:	00000097          	auipc	ra,0x0
    80002ee2:	ece080e7          	jalr	-306(ra) # 80002dac <argaddr>
    80002ee6:	87aa                	mv	a5,a0
    return -1;
    80002ee8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002eea:	0007c863          	bltz	a5,80002efa <sys_wait+0x2a>
  return wait(p);
    80002eee:	fe843503          	ld	a0,-24(s0)
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	61c080e7          	jalr	1564(ra) # 8000250e <wait>
}
    80002efa:	60e2                	ld	ra,24(sp)
    80002efc:	6442                	ld	s0,16(sp)
    80002efe:	6105                	addi	sp,sp,32
    80002f00:	8082                	ret

0000000080002f02 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f02:	7179                	addi	sp,sp,-48
    80002f04:	f406                	sd	ra,40(sp)
    80002f06:	f022                	sd	s0,32(sp)
    80002f08:	ec26                	sd	s1,24(sp)
    80002f0a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f0c:	fdc40593          	addi	a1,s0,-36
    80002f10:	4501                	li	a0,0
    80002f12:	00000097          	auipc	ra,0x0
    80002f16:	e78080e7          	jalr	-392(ra) # 80002d8a <argint>
    return -1;
    80002f1a:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002f1c:	00054f63          	bltz	a0,80002f3a <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	bb4080e7          	jalr	-1100(ra) # 80001ad4 <myproc>
    80002f28:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f2a:	fdc42503          	lw	a0,-36(s0)
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	f62080e7          	jalr	-158(ra) # 80001e90 <growproc>
    80002f36:	00054863          	bltz	a0,80002f46 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002f3a:	8526                	mv	a0,s1
    80002f3c:	70a2                	ld	ra,40(sp)
    80002f3e:	7402                	ld	s0,32(sp)
    80002f40:	64e2                	ld	s1,24(sp)
    80002f42:	6145                	addi	sp,sp,48
    80002f44:	8082                	ret
    return -1;
    80002f46:	54fd                	li	s1,-1
    80002f48:	bfcd                	j	80002f3a <sys_sbrk+0x38>

0000000080002f4a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f4a:	7139                	addi	sp,sp,-64
    80002f4c:	fc06                	sd	ra,56(sp)
    80002f4e:	f822                	sd	s0,48(sp)
    80002f50:	f426                	sd	s1,40(sp)
    80002f52:	f04a                	sd	s2,32(sp)
    80002f54:	ec4e                	sd	s3,24(sp)
    80002f56:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f58:	fcc40593          	addi	a1,s0,-52
    80002f5c:	4501                	li	a0,0
    80002f5e:	00000097          	auipc	ra,0x0
    80002f62:	e2c080e7          	jalr	-468(ra) # 80002d8a <argint>
    return -1;
    80002f66:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f68:	06054563          	bltz	a0,80002fd2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f6c:	00015517          	auipc	a0,0x15
    80002f70:	e4450513          	addi	a0,a0,-444 # 80017db0 <tickslock>
    80002f74:	ffffe097          	auipc	ra,0xffffe
    80002f78:	c8a080e7          	jalr	-886(ra) # 80000bfe <acquire>
  ticks0 = ticks;
    80002f7c:	00006917          	auipc	s2,0x6
    80002f80:	0a492903          	lw	s2,164(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f84:	fcc42783          	lw	a5,-52(s0)
    80002f88:	cf85                	beqz	a5,80002fc0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f8a:	00015997          	auipc	s3,0x15
    80002f8e:	e2698993          	addi	s3,s3,-474 # 80017db0 <tickslock>
    80002f92:	00006497          	auipc	s1,0x6
    80002f96:	08e48493          	addi	s1,s1,142 # 80009020 <ticks>
    if(myproc()->killed){
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	b3a080e7          	jalr	-1222(ra) # 80001ad4 <myproc>
    80002fa2:	591c                	lw	a5,48(a0)
    80002fa4:	ef9d                	bnez	a5,80002fe2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fa6:	85ce                	mv	a1,s3
    80002fa8:	8526                	mv	a0,s1
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	4b4080e7          	jalr	1204(ra) # 8000245e <sleep>
  while(ticks - ticks0 < n){
    80002fb2:	409c                	lw	a5,0(s1)
    80002fb4:	412787bb          	subw	a5,a5,s2
    80002fb8:	fcc42703          	lw	a4,-52(s0)
    80002fbc:	fce7efe3          	bltu	a5,a4,80002f9a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fc0:	00015517          	auipc	a0,0x15
    80002fc4:	df050513          	addi	a0,a0,-528 # 80017db0 <tickslock>
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	cea080e7          	jalr	-790(ra) # 80000cb2 <release>
  return 0;
    80002fd0:	4781                	li	a5,0
}
    80002fd2:	853e                	mv	a0,a5
    80002fd4:	70e2                	ld	ra,56(sp)
    80002fd6:	7442                	ld	s0,48(sp)
    80002fd8:	74a2                	ld	s1,40(sp)
    80002fda:	7902                	ld	s2,32(sp)
    80002fdc:	69e2                	ld	s3,24(sp)
    80002fde:	6121                	addi	sp,sp,64
    80002fe0:	8082                	ret
      release(&tickslock);
    80002fe2:	00015517          	auipc	a0,0x15
    80002fe6:	dce50513          	addi	a0,a0,-562 # 80017db0 <tickslock>
    80002fea:	ffffe097          	auipc	ra,0xffffe
    80002fee:	cc8080e7          	jalr	-824(ra) # 80000cb2 <release>
      return -1;
    80002ff2:	57fd                	li	a5,-1
    80002ff4:	bff9                	j	80002fd2 <sys_sleep+0x88>

0000000080002ff6 <sys_kill>:

uint64
sys_kill(void)
{
    80002ff6:	1101                	addi	sp,sp,-32
    80002ff8:	ec06                	sd	ra,24(sp)
    80002ffa:	e822                	sd	s0,16(sp)
    80002ffc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ffe:	fec40593          	addi	a1,s0,-20
    80003002:	4501                	li	a0,0
    80003004:	00000097          	auipc	ra,0x0
    80003008:	d86080e7          	jalr	-634(ra) # 80002d8a <argint>
    8000300c:	87aa                	mv	a5,a0
    return -1;
    8000300e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003010:	0007c863          	bltz	a5,80003020 <sys_kill+0x2a>
  return kill(pid);
    80003014:	fec42503          	lw	a0,-20(s0)
    80003018:	fffff097          	auipc	ra,0xfffff
    8000301c:	69a080e7          	jalr	1690(ra) # 800026b2 <kill>
}
    80003020:	60e2                	ld	ra,24(sp)
    80003022:	6442                	ld	s0,16(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret

0000000080003028 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	e426                	sd	s1,8(sp)
    80003030:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003032:	00015517          	auipc	a0,0x15
    80003036:	d7e50513          	addi	a0,a0,-642 # 80017db0 <tickslock>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	bc4080e7          	jalr	-1084(ra) # 80000bfe <acquire>
  xticks = ticks;
    80003042:	00006497          	auipc	s1,0x6
    80003046:	fde4a483          	lw	s1,-34(s1) # 80009020 <ticks>
  release(&tickslock);
    8000304a:	00015517          	auipc	a0,0x15
    8000304e:	d6650513          	addi	a0,a0,-666 # 80017db0 <tickslock>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	c60080e7          	jalr	-928(ra) # 80000cb2 <release>
  return xticks;
}
    8000305a:	02049513          	slli	a0,s1,0x20
    8000305e:	9101                	srli	a0,a0,0x20
    80003060:	60e2                	ld	ra,24(sp)
    80003062:	6442                	ld	s0,16(sp)
    80003064:	64a2                	ld	s1,8(sp)
    80003066:	6105                	addi	sp,sp,32
    80003068:	8082                	ret

000000008000306a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000306a:	7179                	addi	sp,sp,-48
    8000306c:	f406                	sd	ra,40(sp)
    8000306e:	f022                	sd	s0,32(sp)
    80003070:	ec26                	sd	s1,24(sp)
    80003072:	e84a                	sd	s2,16(sp)
    80003074:	e44e                	sd	s3,8(sp)
    80003076:	e052                	sd	s4,0(sp)
    80003078:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000307a:	00005597          	auipc	a1,0x5
    8000307e:	51658593          	addi	a1,a1,1302 # 80008590 <syscalls+0xb0>
    80003082:	00015517          	auipc	a0,0x15
    80003086:	d4650513          	addi	a0,a0,-698 # 80017dc8 <bcache>
    8000308a:	ffffe097          	auipc	ra,0xffffe
    8000308e:	ae4080e7          	jalr	-1308(ra) # 80000b6e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003092:	0001d797          	auipc	a5,0x1d
    80003096:	d3678793          	addi	a5,a5,-714 # 8001fdc8 <bcache+0x8000>
    8000309a:	0001d717          	auipc	a4,0x1d
    8000309e:	f9670713          	addi	a4,a4,-106 # 80020030 <bcache+0x8268>
    800030a2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030a6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030aa:	00015497          	auipc	s1,0x15
    800030ae:	d3648493          	addi	s1,s1,-714 # 80017de0 <bcache+0x18>
    b->next = bcache.head.next;
    800030b2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030b4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030b6:	00005a17          	auipc	s4,0x5
    800030ba:	4e2a0a13          	addi	s4,s4,1250 # 80008598 <syscalls+0xb8>
    b->next = bcache.head.next;
    800030be:	2b893783          	ld	a5,696(s2)
    800030c2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030c4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030c8:	85d2                	mv	a1,s4
    800030ca:	01048513          	addi	a0,s1,16
    800030ce:	00001097          	auipc	ra,0x1
    800030d2:	4b2080e7          	jalr	1202(ra) # 80004580 <initsleeplock>
    bcache.head.next->prev = b;
    800030d6:	2b893783          	ld	a5,696(s2)
    800030da:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030dc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030e0:	45848493          	addi	s1,s1,1112
    800030e4:	fd349de3          	bne	s1,s3,800030be <binit+0x54>
  }
}
    800030e8:	70a2                	ld	ra,40(sp)
    800030ea:	7402                	ld	s0,32(sp)
    800030ec:	64e2                	ld	s1,24(sp)
    800030ee:	6942                	ld	s2,16(sp)
    800030f0:	69a2                	ld	s3,8(sp)
    800030f2:	6a02                	ld	s4,0(sp)
    800030f4:	6145                	addi	sp,sp,48
    800030f6:	8082                	ret

00000000800030f8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030f8:	7179                	addi	sp,sp,-48
    800030fa:	f406                	sd	ra,40(sp)
    800030fc:	f022                	sd	s0,32(sp)
    800030fe:	ec26                	sd	s1,24(sp)
    80003100:	e84a                	sd	s2,16(sp)
    80003102:	e44e                	sd	s3,8(sp)
    80003104:	1800                	addi	s0,sp,48
    80003106:	892a                	mv	s2,a0
    80003108:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000310a:	00015517          	auipc	a0,0x15
    8000310e:	cbe50513          	addi	a0,a0,-834 # 80017dc8 <bcache>
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	aec080e7          	jalr	-1300(ra) # 80000bfe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000311a:	0001d497          	auipc	s1,0x1d
    8000311e:	f664b483          	ld	s1,-154(s1) # 80020080 <bcache+0x82b8>
    80003122:	0001d797          	auipc	a5,0x1d
    80003126:	f0e78793          	addi	a5,a5,-242 # 80020030 <bcache+0x8268>
    8000312a:	02f48f63          	beq	s1,a5,80003168 <bread+0x70>
    8000312e:	873e                	mv	a4,a5
    80003130:	a021                	j	80003138 <bread+0x40>
    80003132:	68a4                	ld	s1,80(s1)
    80003134:	02e48a63          	beq	s1,a4,80003168 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003138:	449c                	lw	a5,8(s1)
    8000313a:	ff279ce3          	bne	a5,s2,80003132 <bread+0x3a>
    8000313e:	44dc                	lw	a5,12(s1)
    80003140:	ff3799e3          	bne	a5,s3,80003132 <bread+0x3a>
      b->refcnt++;
    80003144:	40bc                	lw	a5,64(s1)
    80003146:	2785                	addiw	a5,a5,1
    80003148:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000314a:	00015517          	auipc	a0,0x15
    8000314e:	c7e50513          	addi	a0,a0,-898 # 80017dc8 <bcache>
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	b60080e7          	jalr	-1184(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    8000315a:	01048513          	addi	a0,s1,16
    8000315e:	00001097          	auipc	ra,0x1
    80003162:	45c080e7          	jalr	1116(ra) # 800045ba <acquiresleep>
      return b;
    80003166:	a8b9                	j	800031c4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003168:	0001d497          	auipc	s1,0x1d
    8000316c:	f104b483          	ld	s1,-240(s1) # 80020078 <bcache+0x82b0>
    80003170:	0001d797          	auipc	a5,0x1d
    80003174:	ec078793          	addi	a5,a5,-320 # 80020030 <bcache+0x8268>
    80003178:	00f48863          	beq	s1,a5,80003188 <bread+0x90>
    8000317c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000317e:	40bc                	lw	a5,64(s1)
    80003180:	cf81                	beqz	a5,80003198 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003182:	64a4                	ld	s1,72(s1)
    80003184:	fee49de3          	bne	s1,a4,8000317e <bread+0x86>
  panic("bget: no buffers");
    80003188:	00005517          	auipc	a0,0x5
    8000318c:	41850513          	addi	a0,a0,1048 # 800085a0 <syscalls+0xc0>
    80003190:	ffffd097          	auipc	ra,0xffffd
    80003194:	3b2080e7          	jalr	946(ra) # 80000542 <panic>
      b->dev = dev;
    80003198:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000319c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031a0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031a4:	4785                	li	a5,1
    800031a6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031a8:	00015517          	auipc	a0,0x15
    800031ac:	c2050513          	addi	a0,a0,-992 # 80017dc8 <bcache>
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	b02080e7          	jalr	-1278(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    800031b8:	01048513          	addi	a0,s1,16
    800031bc:	00001097          	auipc	ra,0x1
    800031c0:	3fe080e7          	jalr	1022(ra) # 800045ba <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031c4:	409c                	lw	a5,0(s1)
    800031c6:	cb89                	beqz	a5,800031d8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031c8:	8526                	mv	a0,s1
    800031ca:	70a2                	ld	ra,40(sp)
    800031cc:	7402                	ld	s0,32(sp)
    800031ce:	64e2                	ld	s1,24(sp)
    800031d0:	6942                	ld	s2,16(sp)
    800031d2:	69a2                	ld	s3,8(sp)
    800031d4:	6145                	addi	sp,sp,48
    800031d6:	8082                	ret
    virtio_disk_rw(b, 0);
    800031d8:	4581                	li	a1,0
    800031da:	8526                	mv	a0,s1
    800031dc:	00003097          	auipc	ra,0x3
    800031e0:	f30080e7          	jalr	-208(ra) # 8000610c <virtio_disk_rw>
    b->valid = 1;
    800031e4:	4785                	li	a5,1
    800031e6:	c09c                	sw	a5,0(s1)
  return b;
    800031e8:	b7c5                	j	800031c8 <bread+0xd0>

00000000800031ea <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	e426                	sd	s1,8(sp)
    800031f2:	1000                	addi	s0,sp,32
    800031f4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031f6:	0541                	addi	a0,a0,16
    800031f8:	00001097          	auipc	ra,0x1
    800031fc:	45c080e7          	jalr	1116(ra) # 80004654 <holdingsleep>
    80003200:	cd01                	beqz	a0,80003218 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003202:	4585                	li	a1,1
    80003204:	8526                	mv	a0,s1
    80003206:	00003097          	auipc	ra,0x3
    8000320a:	f06080e7          	jalr	-250(ra) # 8000610c <virtio_disk_rw>
}
    8000320e:	60e2                	ld	ra,24(sp)
    80003210:	6442                	ld	s0,16(sp)
    80003212:	64a2                	ld	s1,8(sp)
    80003214:	6105                	addi	sp,sp,32
    80003216:	8082                	ret
    panic("bwrite");
    80003218:	00005517          	auipc	a0,0x5
    8000321c:	3a050513          	addi	a0,a0,928 # 800085b8 <syscalls+0xd8>
    80003220:	ffffd097          	auipc	ra,0xffffd
    80003224:	322080e7          	jalr	802(ra) # 80000542 <panic>

0000000080003228 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003228:	1101                	addi	sp,sp,-32
    8000322a:	ec06                	sd	ra,24(sp)
    8000322c:	e822                	sd	s0,16(sp)
    8000322e:	e426                	sd	s1,8(sp)
    80003230:	e04a                	sd	s2,0(sp)
    80003232:	1000                	addi	s0,sp,32
    80003234:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003236:	01050913          	addi	s2,a0,16
    8000323a:	854a                	mv	a0,s2
    8000323c:	00001097          	auipc	ra,0x1
    80003240:	418080e7          	jalr	1048(ra) # 80004654 <holdingsleep>
    80003244:	c92d                	beqz	a0,800032b6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003246:	854a                	mv	a0,s2
    80003248:	00001097          	auipc	ra,0x1
    8000324c:	3c8080e7          	jalr	968(ra) # 80004610 <releasesleep>

  acquire(&bcache.lock);
    80003250:	00015517          	auipc	a0,0x15
    80003254:	b7850513          	addi	a0,a0,-1160 # 80017dc8 <bcache>
    80003258:	ffffe097          	auipc	ra,0xffffe
    8000325c:	9a6080e7          	jalr	-1626(ra) # 80000bfe <acquire>
  b->refcnt--;
    80003260:	40bc                	lw	a5,64(s1)
    80003262:	37fd                	addiw	a5,a5,-1
    80003264:	0007871b          	sext.w	a4,a5
    80003268:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000326a:	eb05                	bnez	a4,8000329a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000326c:	68bc                	ld	a5,80(s1)
    8000326e:	64b8                	ld	a4,72(s1)
    80003270:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003272:	64bc                	ld	a5,72(s1)
    80003274:	68b8                	ld	a4,80(s1)
    80003276:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003278:	0001d797          	auipc	a5,0x1d
    8000327c:	b5078793          	addi	a5,a5,-1200 # 8001fdc8 <bcache+0x8000>
    80003280:	2b87b703          	ld	a4,696(a5)
    80003284:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003286:	0001d717          	auipc	a4,0x1d
    8000328a:	daa70713          	addi	a4,a4,-598 # 80020030 <bcache+0x8268>
    8000328e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003290:	2b87b703          	ld	a4,696(a5)
    80003294:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003296:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000329a:	00015517          	auipc	a0,0x15
    8000329e:	b2e50513          	addi	a0,a0,-1234 # 80017dc8 <bcache>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	a10080e7          	jalr	-1520(ra) # 80000cb2 <release>
}
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	64a2                	ld	s1,8(sp)
    800032b0:	6902                	ld	s2,0(sp)
    800032b2:	6105                	addi	sp,sp,32
    800032b4:	8082                	ret
    panic("brelse");
    800032b6:	00005517          	auipc	a0,0x5
    800032ba:	30a50513          	addi	a0,a0,778 # 800085c0 <syscalls+0xe0>
    800032be:	ffffd097          	auipc	ra,0xffffd
    800032c2:	284080e7          	jalr	644(ra) # 80000542 <panic>

00000000800032c6 <bpin>:

void
bpin(struct buf *b) {
    800032c6:	1101                	addi	sp,sp,-32
    800032c8:	ec06                	sd	ra,24(sp)
    800032ca:	e822                	sd	s0,16(sp)
    800032cc:	e426                	sd	s1,8(sp)
    800032ce:	1000                	addi	s0,sp,32
    800032d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032d2:	00015517          	auipc	a0,0x15
    800032d6:	af650513          	addi	a0,a0,-1290 # 80017dc8 <bcache>
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	924080e7          	jalr	-1756(ra) # 80000bfe <acquire>
  b->refcnt++;
    800032e2:	40bc                	lw	a5,64(s1)
    800032e4:	2785                	addiw	a5,a5,1
    800032e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032e8:	00015517          	auipc	a0,0x15
    800032ec:	ae050513          	addi	a0,a0,-1312 # 80017dc8 <bcache>
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	9c2080e7          	jalr	-1598(ra) # 80000cb2 <release>
}
    800032f8:	60e2                	ld	ra,24(sp)
    800032fa:	6442                	ld	s0,16(sp)
    800032fc:	64a2                	ld	s1,8(sp)
    800032fe:	6105                	addi	sp,sp,32
    80003300:	8082                	ret

0000000080003302 <bunpin>:

void
bunpin(struct buf *b) {
    80003302:	1101                	addi	sp,sp,-32
    80003304:	ec06                	sd	ra,24(sp)
    80003306:	e822                	sd	s0,16(sp)
    80003308:	e426                	sd	s1,8(sp)
    8000330a:	1000                	addi	s0,sp,32
    8000330c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000330e:	00015517          	auipc	a0,0x15
    80003312:	aba50513          	addi	a0,a0,-1350 # 80017dc8 <bcache>
    80003316:	ffffe097          	auipc	ra,0xffffe
    8000331a:	8e8080e7          	jalr	-1816(ra) # 80000bfe <acquire>
  b->refcnt--;
    8000331e:	40bc                	lw	a5,64(s1)
    80003320:	37fd                	addiw	a5,a5,-1
    80003322:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003324:	00015517          	auipc	a0,0x15
    80003328:	aa450513          	addi	a0,a0,-1372 # 80017dc8 <bcache>
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	986080e7          	jalr	-1658(ra) # 80000cb2 <release>
}
    80003334:	60e2                	ld	ra,24(sp)
    80003336:	6442                	ld	s0,16(sp)
    80003338:	64a2                	ld	s1,8(sp)
    8000333a:	6105                	addi	sp,sp,32
    8000333c:	8082                	ret

000000008000333e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000333e:	1101                	addi	sp,sp,-32
    80003340:	ec06                	sd	ra,24(sp)
    80003342:	e822                	sd	s0,16(sp)
    80003344:	e426                	sd	s1,8(sp)
    80003346:	e04a                	sd	s2,0(sp)
    80003348:	1000                	addi	s0,sp,32
    8000334a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000334c:	00d5d59b          	srliw	a1,a1,0xd
    80003350:	0001d797          	auipc	a5,0x1d
    80003354:	1547a783          	lw	a5,340(a5) # 800204a4 <sb+0x1c>
    80003358:	9dbd                	addw	a1,a1,a5
    8000335a:	00000097          	auipc	ra,0x0
    8000335e:	d9e080e7          	jalr	-610(ra) # 800030f8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003362:	0074f713          	andi	a4,s1,7
    80003366:	4785                	li	a5,1
    80003368:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000336c:	14ce                	slli	s1,s1,0x33
    8000336e:	90d9                	srli	s1,s1,0x36
    80003370:	00950733          	add	a4,a0,s1
    80003374:	05874703          	lbu	a4,88(a4)
    80003378:	00e7f6b3          	and	a3,a5,a4
    8000337c:	c69d                	beqz	a3,800033aa <bfree+0x6c>
    8000337e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003380:	94aa                	add	s1,s1,a0
    80003382:	fff7c793          	not	a5,a5
    80003386:	8ff9                	and	a5,a5,a4
    80003388:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000338c:	00001097          	auipc	ra,0x1
    80003390:	106080e7          	jalr	262(ra) # 80004492 <log_write>
  brelse(bp);
    80003394:	854a                	mv	a0,s2
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	e92080e7          	jalr	-366(ra) # 80003228 <brelse>
}
    8000339e:	60e2                	ld	ra,24(sp)
    800033a0:	6442                	ld	s0,16(sp)
    800033a2:	64a2                	ld	s1,8(sp)
    800033a4:	6902                	ld	s2,0(sp)
    800033a6:	6105                	addi	sp,sp,32
    800033a8:	8082                	ret
    panic("freeing free block");
    800033aa:	00005517          	auipc	a0,0x5
    800033ae:	21e50513          	addi	a0,a0,542 # 800085c8 <syscalls+0xe8>
    800033b2:	ffffd097          	auipc	ra,0xffffd
    800033b6:	190080e7          	jalr	400(ra) # 80000542 <panic>

00000000800033ba <balloc>:
{
    800033ba:	711d                	addi	sp,sp,-96
    800033bc:	ec86                	sd	ra,88(sp)
    800033be:	e8a2                	sd	s0,80(sp)
    800033c0:	e4a6                	sd	s1,72(sp)
    800033c2:	e0ca                	sd	s2,64(sp)
    800033c4:	fc4e                	sd	s3,56(sp)
    800033c6:	f852                	sd	s4,48(sp)
    800033c8:	f456                	sd	s5,40(sp)
    800033ca:	f05a                	sd	s6,32(sp)
    800033cc:	ec5e                	sd	s7,24(sp)
    800033ce:	e862                	sd	s8,16(sp)
    800033d0:	e466                	sd	s9,8(sp)
    800033d2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033d4:	0001d797          	auipc	a5,0x1d
    800033d8:	0b87a783          	lw	a5,184(a5) # 8002048c <sb+0x4>
    800033dc:	cbd1                	beqz	a5,80003470 <balloc+0xb6>
    800033de:	8baa                	mv	s7,a0
    800033e0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033e2:	0001db17          	auipc	s6,0x1d
    800033e6:	0a6b0b13          	addi	s6,s6,166 # 80020488 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ea:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033ec:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ee:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033f0:	6c89                	lui	s9,0x2
    800033f2:	a831                	j	8000340e <balloc+0x54>
    brelse(bp);
    800033f4:	854a                	mv	a0,s2
    800033f6:	00000097          	auipc	ra,0x0
    800033fa:	e32080e7          	jalr	-462(ra) # 80003228 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033fe:	015c87bb          	addw	a5,s9,s5
    80003402:	00078a9b          	sext.w	s5,a5
    80003406:	004b2703          	lw	a4,4(s6)
    8000340a:	06eaf363          	bgeu	s5,a4,80003470 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000340e:	41fad79b          	sraiw	a5,s5,0x1f
    80003412:	0137d79b          	srliw	a5,a5,0x13
    80003416:	015787bb          	addw	a5,a5,s5
    8000341a:	40d7d79b          	sraiw	a5,a5,0xd
    8000341e:	01cb2583          	lw	a1,28(s6)
    80003422:	9dbd                	addw	a1,a1,a5
    80003424:	855e                	mv	a0,s7
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	cd2080e7          	jalr	-814(ra) # 800030f8 <bread>
    8000342e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003430:	004b2503          	lw	a0,4(s6)
    80003434:	000a849b          	sext.w	s1,s5
    80003438:	8662                	mv	a2,s8
    8000343a:	faa4fde3          	bgeu	s1,a0,800033f4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000343e:	41f6579b          	sraiw	a5,a2,0x1f
    80003442:	01d7d69b          	srliw	a3,a5,0x1d
    80003446:	00c6873b          	addw	a4,a3,a2
    8000344a:	00777793          	andi	a5,a4,7
    8000344e:	9f95                	subw	a5,a5,a3
    80003450:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003454:	4037571b          	sraiw	a4,a4,0x3
    80003458:	00e906b3          	add	a3,s2,a4
    8000345c:	0586c683          	lbu	a3,88(a3)
    80003460:	00d7f5b3          	and	a1,a5,a3
    80003464:	cd91                	beqz	a1,80003480 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003466:	2605                	addiw	a2,a2,1
    80003468:	2485                	addiw	s1,s1,1
    8000346a:	fd4618e3          	bne	a2,s4,8000343a <balloc+0x80>
    8000346e:	b759                	j	800033f4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003470:	00005517          	auipc	a0,0x5
    80003474:	17050513          	addi	a0,a0,368 # 800085e0 <syscalls+0x100>
    80003478:	ffffd097          	auipc	ra,0xffffd
    8000347c:	0ca080e7          	jalr	202(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003480:	974a                	add	a4,a4,s2
    80003482:	8fd5                	or	a5,a5,a3
    80003484:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003488:	854a                	mv	a0,s2
    8000348a:	00001097          	auipc	ra,0x1
    8000348e:	008080e7          	jalr	8(ra) # 80004492 <log_write>
        brelse(bp);
    80003492:	854a                	mv	a0,s2
    80003494:	00000097          	auipc	ra,0x0
    80003498:	d94080e7          	jalr	-620(ra) # 80003228 <brelse>
  bp = bread(dev, bno);
    8000349c:	85a6                	mv	a1,s1
    8000349e:	855e                	mv	a0,s7
    800034a0:	00000097          	auipc	ra,0x0
    800034a4:	c58080e7          	jalr	-936(ra) # 800030f8 <bread>
    800034a8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034aa:	40000613          	li	a2,1024
    800034ae:	4581                	li	a1,0
    800034b0:	05850513          	addi	a0,a0,88
    800034b4:	ffffe097          	auipc	ra,0xffffe
    800034b8:	846080e7          	jalr	-1978(ra) # 80000cfa <memset>
  log_write(bp);
    800034bc:	854a                	mv	a0,s2
    800034be:	00001097          	auipc	ra,0x1
    800034c2:	fd4080e7          	jalr	-44(ra) # 80004492 <log_write>
  brelse(bp);
    800034c6:	854a                	mv	a0,s2
    800034c8:	00000097          	auipc	ra,0x0
    800034cc:	d60080e7          	jalr	-672(ra) # 80003228 <brelse>
}
    800034d0:	8526                	mv	a0,s1
    800034d2:	60e6                	ld	ra,88(sp)
    800034d4:	6446                	ld	s0,80(sp)
    800034d6:	64a6                	ld	s1,72(sp)
    800034d8:	6906                	ld	s2,64(sp)
    800034da:	79e2                	ld	s3,56(sp)
    800034dc:	7a42                	ld	s4,48(sp)
    800034de:	7aa2                	ld	s5,40(sp)
    800034e0:	7b02                	ld	s6,32(sp)
    800034e2:	6be2                	ld	s7,24(sp)
    800034e4:	6c42                	ld	s8,16(sp)
    800034e6:	6ca2                	ld	s9,8(sp)
    800034e8:	6125                	addi	sp,sp,96
    800034ea:	8082                	ret

00000000800034ec <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034ec:	7179                	addi	sp,sp,-48
    800034ee:	f406                	sd	ra,40(sp)
    800034f0:	f022                	sd	s0,32(sp)
    800034f2:	ec26                	sd	s1,24(sp)
    800034f4:	e84a                	sd	s2,16(sp)
    800034f6:	e44e                	sd	s3,8(sp)
    800034f8:	e052                	sd	s4,0(sp)
    800034fa:	1800                	addi	s0,sp,48
    800034fc:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034fe:	47ad                	li	a5,11
    80003500:	04b7fe63          	bgeu	a5,a1,8000355c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003504:	ff45849b          	addiw	s1,a1,-12
    80003508:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000350c:	0ff00793          	li	a5,255
    80003510:	0ae7e463          	bltu	a5,a4,800035b8 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003514:	08052583          	lw	a1,128(a0)
    80003518:	c5b5                	beqz	a1,80003584 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000351a:	00092503          	lw	a0,0(s2)
    8000351e:	00000097          	auipc	ra,0x0
    80003522:	bda080e7          	jalr	-1062(ra) # 800030f8 <bread>
    80003526:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003528:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000352c:	02049713          	slli	a4,s1,0x20
    80003530:	01e75593          	srli	a1,a4,0x1e
    80003534:	00b784b3          	add	s1,a5,a1
    80003538:	0004a983          	lw	s3,0(s1)
    8000353c:	04098e63          	beqz	s3,80003598 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003540:	8552                	mv	a0,s4
    80003542:	00000097          	auipc	ra,0x0
    80003546:	ce6080e7          	jalr	-794(ra) # 80003228 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000354a:	854e                	mv	a0,s3
    8000354c:	70a2                	ld	ra,40(sp)
    8000354e:	7402                	ld	s0,32(sp)
    80003550:	64e2                	ld	s1,24(sp)
    80003552:	6942                	ld	s2,16(sp)
    80003554:	69a2                	ld	s3,8(sp)
    80003556:	6a02                	ld	s4,0(sp)
    80003558:	6145                	addi	sp,sp,48
    8000355a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000355c:	02059793          	slli	a5,a1,0x20
    80003560:	01e7d593          	srli	a1,a5,0x1e
    80003564:	00b504b3          	add	s1,a0,a1
    80003568:	0504a983          	lw	s3,80(s1)
    8000356c:	fc099fe3          	bnez	s3,8000354a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003570:	4108                	lw	a0,0(a0)
    80003572:	00000097          	auipc	ra,0x0
    80003576:	e48080e7          	jalr	-440(ra) # 800033ba <balloc>
    8000357a:	0005099b          	sext.w	s3,a0
    8000357e:	0534a823          	sw	s3,80(s1)
    80003582:	b7e1                	j	8000354a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003584:	4108                	lw	a0,0(a0)
    80003586:	00000097          	auipc	ra,0x0
    8000358a:	e34080e7          	jalr	-460(ra) # 800033ba <balloc>
    8000358e:	0005059b          	sext.w	a1,a0
    80003592:	08b92023          	sw	a1,128(s2)
    80003596:	b751                	j	8000351a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003598:	00092503          	lw	a0,0(s2)
    8000359c:	00000097          	auipc	ra,0x0
    800035a0:	e1e080e7          	jalr	-482(ra) # 800033ba <balloc>
    800035a4:	0005099b          	sext.w	s3,a0
    800035a8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035ac:	8552                	mv	a0,s4
    800035ae:	00001097          	auipc	ra,0x1
    800035b2:	ee4080e7          	jalr	-284(ra) # 80004492 <log_write>
    800035b6:	b769                	j	80003540 <bmap+0x54>
  panic("bmap: out of range");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	04050513          	addi	a0,a0,64 # 800085f8 <syscalls+0x118>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	f82080e7          	jalr	-126(ra) # 80000542 <panic>

00000000800035c8 <iget>:
{
    800035c8:	7179                	addi	sp,sp,-48
    800035ca:	f406                	sd	ra,40(sp)
    800035cc:	f022                	sd	s0,32(sp)
    800035ce:	ec26                	sd	s1,24(sp)
    800035d0:	e84a                	sd	s2,16(sp)
    800035d2:	e44e                	sd	s3,8(sp)
    800035d4:	e052                	sd	s4,0(sp)
    800035d6:	1800                	addi	s0,sp,48
    800035d8:	89aa                	mv	s3,a0
    800035da:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800035dc:	0001d517          	auipc	a0,0x1d
    800035e0:	ecc50513          	addi	a0,a0,-308 # 800204a8 <icache>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	61a080e7          	jalr	1562(ra) # 80000bfe <acquire>
  empty = 0;
    800035ec:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035ee:	0001d497          	auipc	s1,0x1d
    800035f2:	ed248493          	addi	s1,s1,-302 # 800204c0 <icache+0x18>
    800035f6:	0001f697          	auipc	a3,0x1f
    800035fa:	95a68693          	addi	a3,a3,-1702 # 80021f50 <log>
    800035fe:	a039                	j	8000360c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003600:	02090b63          	beqz	s2,80003636 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003604:	08848493          	addi	s1,s1,136
    80003608:	02d48a63          	beq	s1,a3,8000363c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000360c:	449c                	lw	a5,8(s1)
    8000360e:	fef059e3          	blez	a5,80003600 <iget+0x38>
    80003612:	4098                	lw	a4,0(s1)
    80003614:	ff3716e3          	bne	a4,s3,80003600 <iget+0x38>
    80003618:	40d8                	lw	a4,4(s1)
    8000361a:	ff4713e3          	bne	a4,s4,80003600 <iget+0x38>
      ip->ref++;
    8000361e:	2785                	addiw	a5,a5,1
    80003620:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003622:	0001d517          	auipc	a0,0x1d
    80003626:	e8650513          	addi	a0,a0,-378 # 800204a8 <icache>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	688080e7          	jalr	1672(ra) # 80000cb2 <release>
      return ip;
    80003632:	8926                	mv	s2,s1
    80003634:	a03d                	j	80003662 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003636:	f7f9                	bnez	a5,80003604 <iget+0x3c>
    80003638:	8926                	mv	s2,s1
    8000363a:	b7e9                	j	80003604 <iget+0x3c>
  if(empty == 0)
    8000363c:	02090c63          	beqz	s2,80003674 <iget+0xac>
  ip->dev = dev;
    80003640:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003644:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003648:	4785                	li	a5,1
    8000364a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000364e:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003652:	0001d517          	auipc	a0,0x1d
    80003656:	e5650513          	addi	a0,a0,-426 # 800204a8 <icache>
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	658080e7          	jalr	1624(ra) # 80000cb2 <release>
}
    80003662:	854a                	mv	a0,s2
    80003664:	70a2                	ld	ra,40(sp)
    80003666:	7402                	ld	s0,32(sp)
    80003668:	64e2                	ld	s1,24(sp)
    8000366a:	6942                	ld	s2,16(sp)
    8000366c:	69a2                	ld	s3,8(sp)
    8000366e:	6a02                	ld	s4,0(sp)
    80003670:	6145                	addi	sp,sp,48
    80003672:	8082                	ret
    panic("iget: no inodes");
    80003674:	00005517          	auipc	a0,0x5
    80003678:	f9c50513          	addi	a0,a0,-100 # 80008610 <syscalls+0x130>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	ec6080e7          	jalr	-314(ra) # 80000542 <panic>

0000000080003684 <fsinit>:
fsinit(int dev) {
    80003684:	7179                	addi	sp,sp,-48
    80003686:	f406                	sd	ra,40(sp)
    80003688:	f022                	sd	s0,32(sp)
    8000368a:	ec26                	sd	s1,24(sp)
    8000368c:	e84a                	sd	s2,16(sp)
    8000368e:	e44e                	sd	s3,8(sp)
    80003690:	1800                	addi	s0,sp,48
    80003692:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003694:	4585                	li	a1,1
    80003696:	00000097          	auipc	ra,0x0
    8000369a:	a62080e7          	jalr	-1438(ra) # 800030f8 <bread>
    8000369e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036a0:	0001d997          	auipc	s3,0x1d
    800036a4:	de898993          	addi	s3,s3,-536 # 80020488 <sb>
    800036a8:	02000613          	li	a2,32
    800036ac:	05850593          	addi	a1,a0,88
    800036b0:	854e                	mv	a0,s3
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	6a4080e7          	jalr	1700(ra) # 80000d56 <memmove>
  brelse(bp);
    800036ba:	8526                	mv	a0,s1
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	b6c080e7          	jalr	-1172(ra) # 80003228 <brelse>
  if(sb.magic != FSMAGIC)
    800036c4:	0009a703          	lw	a4,0(s3)
    800036c8:	102037b7          	lui	a5,0x10203
    800036cc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036d0:	02f71263          	bne	a4,a5,800036f4 <fsinit+0x70>
  initlog(dev, &sb);
    800036d4:	0001d597          	auipc	a1,0x1d
    800036d8:	db458593          	addi	a1,a1,-588 # 80020488 <sb>
    800036dc:	854a                	mv	a0,s2
    800036de:	00001097          	auipc	ra,0x1
    800036e2:	b3a080e7          	jalr	-1222(ra) # 80004218 <initlog>
}
    800036e6:	70a2                	ld	ra,40(sp)
    800036e8:	7402                	ld	s0,32(sp)
    800036ea:	64e2                	ld	s1,24(sp)
    800036ec:	6942                	ld	s2,16(sp)
    800036ee:	69a2                	ld	s3,8(sp)
    800036f0:	6145                	addi	sp,sp,48
    800036f2:	8082                	ret
    panic("invalid file system");
    800036f4:	00005517          	auipc	a0,0x5
    800036f8:	f2c50513          	addi	a0,a0,-212 # 80008620 <syscalls+0x140>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	e46080e7          	jalr	-442(ra) # 80000542 <panic>

0000000080003704 <iinit>:
{
    80003704:	7179                	addi	sp,sp,-48
    80003706:	f406                	sd	ra,40(sp)
    80003708:	f022                	sd	s0,32(sp)
    8000370a:	ec26                	sd	s1,24(sp)
    8000370c:	e84a                	sd	s2,16(sp)
    8000370e:	e44e                	sd	s3,8(sp)
    80003710:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003712:	00005597          	auipc	a1,0x5
    80003716:	f2658593          	addi	a1,a1,-218 # 80008638 <syscalls+0x158>
    8000371a:	0001d517          	auipc	a0,0x1d
    8000371e:	d8e50513          	addi	a0,a0,-626 # 800204a8 <icache>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	44c080e7          	jalr	1100(ra) # 80000b6e <initlock>
  for(i = 0; i < NINODE; i++) {
    8000372a:	0001d497          	auipc	s1,0x1d
    8000372e:	da648493          	addi	s1,s1,-602 # 800204d0 <icache+0x28>
    80003732:	0001f997          	auipc	s3,0x1f
    80003736:	82e98993          	addi	s3,s3,-2002 # 80021f60 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000373a:	00005917          	auipc	s2,0x5
    8000373e:	f0690913          	addi	s2,s2,-250 # 80008640 <syscalls+0x160>
    80003742:	85ca                	mv	a1,s2
    80003744:	8526                	mv	a0,s1
    80003746:	00001097          	auipc	ra,0x1
    8000374a:	e3a080e7          	jalr	-454(ra) # 80004580 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000374e:	08848493          	addi	s1,s1,136
    80003752:	ff3498e3          	bne	s1,s3,80003742 <iinit+0x3e>
}
    80003756:	70a2                	ld	ra,40(sp)
    80003758:	7402                	ld	s0,32(sp)
    8000375a:	64e2                	ld	s1,24(sp)
    8000375c:	6942                	ld	s2,16(sp)
    8000375e:	69a2                	ld	s3,8(sp)
    80003760:	6145                	addi	sp,sp,48
    80003762:	8082                	ret

0000000080003764 <ialloc>:
{
    80003764:	715d                	addi	sp,sp,-80
    80003766:	e486                	sd	ra,72(sp)
    80003768:	e0a2                	sd	s0,64(sp)
    8000376a:	fc26                	sd	s1,56(sp)
    8000376c:	f84a                	sd	s2,48(sp)
    8000376e:	f44e                	sd	s3,40(sp)
    80003770:	f052                	sd	s4,32(sp)
    80003772:	ec56                	sd	s5,24(sp)
    80003774:	e85a                	sd	s6,16(sp)
    80003776:	e45e                	sd	s7,8(sp)
    80003778:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000377a:	0001d717          	auipc	a4,0x1d
    8000377e:	d1a72703          	lw	a4,-742(a4) # 80020494 <sb+0xc>
    80003782:	4785                	li	a5,1
    80003784:	04e7fa63          	bgeu	a5,a4,800037d8 <ialloc+0x74>
    80003788:	8aaa                	mv	s5,a0
    8000378a:	8bae                	mv	s7,a1
    8000378c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000378e:	0001da17          	auipc	s4,0x1d
    80003792:	cfaa0a13          	addi	s4,s4,-774 # 80020488 <sb>
    80003796:	00048b1b          	sext.w	s6,s1
    8000379a:	0044d793          	srli	a5,s1,0x4
    8000379e:	018a2583          	lw	a1,24(s4)
    800037a2:	9dbd                	addw	a1,a1,a5
    800037a4:	8556                	mv	a0,s5
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	952080e7          	jalr	-1710(ra) # 800030f8 <bread>
    800037ae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037b0:	05850993          	addi	s3,a0,88
    800037b4:	00f4f793          	andi	a5,s1,15
    800037b8:	079a                	slli	a5,a5,0x6
    800037ba:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037bc:	00099783          	lh	a5,0(s3)
    800037c0:	c785                	beqz	a5,800037e8 <ialloc+0x84>
    brelse(bp);
    800037c2:	00000097          	auipc	ra,0x0
    800037c6:	a66080e7          	jalr	-1434(ra) # 80003228 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ca:	0485                	addi	s1,s1,1
    800037cc:	00ca2703          	lw	a4,12(s4)
    800037d0:	0004879b          	sext.w	a5,s1
    800037d4:	fce7e1e3          	bltu	a5,a4,80003796 <ialloc+0x32>
  panic("ialloc: no inodes");
    800037d8:	00005517          	auipc	a0,0x5
    800037dc:	e7050513          	addi	a0,a0,-400 # 80008648 <syscalls+0x168>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	d62080e7          	jalr	-670(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    800037e8:	04000613          	li	a2,64
    800037ec:	4581                	li	a1,0
    800037ee:	854e                	mv	a0,s3
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	50a080e7          	jalr	1290(ra) # 80000cfa <memset>
      dip->type = type;
    800037f8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037fc:	854a                	mv	a0,s2
    800037fe:	00001097          	auipc	ra,0x1
    80003802:	c94080e7          	jalr	-876(ra) # 80004492 <log_write>
      brelse(bp);
    80003806:	854a                	mv	a0,s2
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	a20080e7          	jalr	-1504(ra) # 80003228 <brelse>
      return iget(dev, inum);
    80003810:	85da                	mv	a1,s6
    80003812:	8556                	mv	a0,s5
    80003814:	00000097          	auipc	ra,0x0
    80003818:	db4080e7          	jalr	-588(ra) # 800035c8 <iget>
}
    8000381c:	60a6                	ld	ra,72(sp)
    8000381e:	6406                	ld	s0,64(sp)
    80003820:	74e2                	ld	s1,56(sp)
    80003822:	7942                	ld	s2,48(sp)
    80003824:	79a2                	ld	s3,40(sp)
    80003826:	7a02                	ld	s4,32(sp)
    80003828:	6ae2                	ld	s5,24(sp)
    8000382a:	6b42                	ld	s6,16(sp)
    8000382c:	6ba2                	ld	s7,8(sp)
    8000382e:	6161                	addi	sp,sp,80
    80003830:	8082                	ret

0000000080003832 <iupdate>:
{
    80003832:	1101                	addi	sp,sp,-32
    80003834:	ec06                	sd	ra,24(sp)
    80003836:	e822                	sd	s0,16(sp)
    80003838:	e426                	sd	s1,8(sp)
    8000383a:	e04a                	sd	s2,0(sp)
    8000383c:	1000                	addi	s0,sp,32
    8000383e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003840:	415c                	lw	a5,4(a0)
    80003842:	0047d79b          	srliw	a5,a5,0x4
    80003846:	0001d597          	auipc	a1,0x1d
    8000384a:	c5a5a583          	lw	a1,-934(a1) # 800204a0 <sb+0x18>
    8000384e:	9dbd                	addw	a1,a1,a5
    80003850:	4108                	lw	a0,0(a0)
    80003852:	00000097          	auipc	ra,0x0
    80003856:	8a6080e7          	jalr	-1882(ra) # 800030f8 <bread>
    8000385a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000385c:	05850793          	addi	a5,a0,88
    80003860:	40c8                	lw	a0,4(s1)
    80003862:	893d                	andi	a0,a0,15
    80003864:	051a                	slli	a0,a0,0x6
    80003866:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003868:	04449703          	lh	a4,68(s1)
    8000386c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003870:	04649703          	lh	a4,70(s1)
    80003874:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003878:	04849703          	lh	a4,72(s1)
    8000387c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003880:	04a49703          	lh	a4,74(s1)
    80003884:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003888:	44f8                	lw	a4,76(s1)
    8000388a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000388c:	03400613          	li	a2,52
    80003890:	05048593          	addi	a1,s1,80
    80003894:	0531                	addi	a0,a0,12
    80003896:	ffffd097          	auipc	ra,0xffffd
    8000389a:	4c0080e7          	jalr	1216(ra) # 80000d56 <memmove>
  log_write(bp);
    8000389e:	854a                	mv	a0,s2
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	bf2080e7          	jalr	-1038(ra) # 80004492 <log_write>
  brelse(bp);
    800038a8:	854a                	mv	a0,s2
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	97e080e7          	jalr	-1666(ra) # 80003228 <brelse>
}
    800038b2:	60e2                	ld	ra,24(sp)
    800038b4:	6442                	ld	s0,16(sp)
    800038b6:	64a2                	ld	s1,8(sp)
    800038b8:	6902                	ld	s2,0(sp)
    800038ba:	6105                	addi	sp,sp,32
    800038bc:	8082                	ret

00000000800038be <idup>:
{
    800038be:	1101                	addi	sp,sp,-32
    800038c0:	ec06                	sd	ra,24(sp)
    800038c2:	e822                	sd	s0,16(sp)
    800038c4:	e426                	sd	s1,8(sp)
    800038c6:	1000                	addi	s0,sp,32
    800038c8:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038ca:	0001d517          	auipc	a0,0x1d
    800038ce:	bde50513          	addi	a0,a0,-1058 # 800204a8 <icache>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	32c080e7          	jalr	812(ra) # 80000bfe <acquire>
  ip->ref++;
    800038da:	449c                	lw	a5,8(s1)
    800038dc:	2785                	addiw	a5,a5,1
    800038de:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038e0:	0001d517          	auipc	a0,0x1d
    800038e4:	bc850513          	addi	a0,a0,-1080 # 800204a8 <icache>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	3ca080e7          	jalr	970(ra) # 80000cb2 <release>
}
    800038f0:	8526                	mv	a0,s1
    800038f2:	60e2                	ld	ra,24(sp)
    800038f4:	6442                	ld	s0,16(sp)
    800038f6:	64a2                	ld	s1,8(sp)
    800038f8:	6105                	addi	sp,sp,32
    800038fa:	8082                	ret

00000000800038fc <ilock>:
{
    800038fc:	1101                	addi	sp,sp,-32
    800038fe:	ec06                	sd	ra,24(sp)
    80003900:	e822                	sd	s0,16(sp)
    80003902:	e426                	sd	s1,8(sp)
    80003904:	e04a                	sd	s2,0(sp)
    80003906:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003908:	c115                	beqz	a0,8000392c <ilock+0x30>
    8000390a:	84aa                	mv	s1,a0
    8000390c:	451c                	lw	a5,8(a0)
    8000390e:	00f05f63          	blez	a5,8000392c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003912:	0541                	addi	a0,a0,16
    80003914:	00001097          	auipc	ra,0x1
    80003918:	ca6080e7          	jalr	-858(ra) # 800045ba <acquiresleep>
  if(ip->valid == 0){
    8000391c:	40bc                	lw	a5,64(s1)
    8000391e:	cf99                	beqz	a5,8000393c <ilock+0x40>
}
    80003920:	60e2                	ld	ra,24(sp)
    80003922:	6442                	ld	s0,16(sp)
    80003924:	64a2                	ld	s1,8(sp)
    80003926:	6902                	ld	s2,0(sp)
    80003928:	6105                	addi	sp,sp,32
    8000392a:	8082                	ret
    panic("ilock");
    8000392c:	00005517          	auipc	a0,0x5
    80003930:	d3450513          	addi	a0,a0,-716 # 80008660 <syscalls+0x180>
    80003934:	ffffd097          	auipc	ra,0xffffd
    80003938:	c0e080e7          	jalr	-1010(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000393c:	40dc                	lw	a5,4(s1)
    8000393e:	0047d79b          	srliw	a5,a5,0x4
    80003942:	0001d597          	auipc	a1,0x1d
    80003946:	b5e5a583          	lw	a1,-1186(a1) # 800204a0 <sb+0x18>
    8000394a:	9dbd                	addw	a1,a1,a5
    8000394c:	4088                	lw	a0,0(s1)
    8000394e:	fffff097          	auipc	ra,0xfffff
    80003952:	7aa080e7          	jalr	1962(ra) # 800030f8 <bread>
    80003956:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003958:	05850593          	addi	a1,a0,88
    8000395c:	40dc                	lw	a5,4(s1)
    8000395e:	8bbd                	andi	a5,a5,15
    80003960:	079a                	slli	a5,a5,0x6
    80003962:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003964:	00059783          	lh	a5,0(a1)
    80003968:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000396c:	00259783          	lh	a5,2(a1)
    80003970:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003974:	00459783          	lh	a5,4(a1)
    80003978:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000397c:	00659783          	lh	a5,6(a1)
    80003980:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003984:	459c                	lw	a5,8(a1)
    80003986:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003988:	03400613          	li	a2,52
    8000398c:	05b1                	addi	a1,a1,12
    8000398e:	05048513          	addi	a0,s1,80
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	3c4080e7          	jalr	964(ra) # 80000d56 <memmove>
    brelse(bp);
    8000399a:	854a                	mv	a0,s2
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	88c080e7          	jalr	-1908(ra) # 80003228 <brelse>
    ip->valid = 1;
    800039a4:	4785                	li	a5,1
    800039a6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039a8:	04449783          	lh	a5,68(s1)
    800039ac:	fbb5                	bnez	a5,80003920 <ilock+0x24>
      panic("ilock: no type");
    800039ae:	00005517          	auipc	a0,0x5
    800039b2:	cba50513          	addi	a0,a0,-838 # 80008668 <syscalls+0x188>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	b8c080e7          	jalr	-1140(ra) # 80000542 <panic>

00000000800039be <iunlock>:
{
    800039be:	1101                	addi	sp,sp,-32
    800039c0:	ec06                	sd	ra,24(sp)
    800039c2:	e822                	sd	s0,16(sp)
    800039c4:	e426                	sd	s1,8(sp)
    800039c6:	e04a                	sd	s2,0(sp)
    800039c8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039ca:	c905                	beqz	a0,800039fa <iunlock+0x3c>
    800039cc:	84aa                	mv	s1,a0
    800039ce:	01050913          	addi	s2,a0,16
    800039d2:	854a                	mv	a0,s2
    800039d4:	00001097          	auipc	ra,0x1
    800039d8:	c80080e7          	jalr	-896(ra) # 80004654 <holdingsleep>
    800039dc:	cd19                	beqz	a0,800039fa <iunlock+0x3c>
    800039de:	449c                	lw	a5,8(s1)
    800039e0:	00f05d63          	blez	a5,800039fa <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039e4:	854a                	mv	a0,s2
    800039e6:	00001097          	auipc	ra,0x1
    800039ea:	c2a080e7          	jalr	-982(ra) # 80004610 <releasesleep>
}
    800039ee:	60e2                	ld	ra,24(sp)
    800039f0:	6442                	ld	s0,16(sp)
    800039f2:	64a2                	ld	s1,8(sp)
    800039f4:	6902                	ld	s2,0(sp)
    800039f6:	6105                	addi	sp,sp,32
    800039f8:	8082                	ret
    panic("iunlock");
    800039fa:	00005517          	auipc	a0,0x5
    800039fe:	c7e50513          	addi	a0,a0,-898 # 80008678 <syscalls+0x198>
    80003a02:	ffffd097          	auipc	ra,0xffffd
    80003a06:	b40080e7          	jalr	-1216(ra) # 80000542 <panic>

0000000080003a0a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a0a:	7179                	addi	sp,sp,-48
    80003a0c:	f406                	sd	ra,40(sp)
    80003a0e:	f022                	sd	s0,32(sp)
    80003a10:	ec26                	sd	s1,24(sp)
    80003a12:	e84a                	sd	s2,16(sp)
    80003a14:	e44e                	sd	s3,8(sp)
    80003a16:	e052                	sd	s4,0(sp)
    80003a18:	1800                	addi	s0,sp,48
    80003a1a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a1c:	05050493          	addi	s1,a0,80
    80003a20:	08050913          	addi	s2,a0,128
    80003a24:	a021                	j	80003a2c <itrunc+0x22>
    80003a26:	0491                	addi	s1,s1,4
    80003a28:	01248d63          	beq	s1,s2,80003a42 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a2c:	408c                	lw	a1,0(s1)
    80003a2e:	dde5                	beqz	a1,80003a26 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a30:	0009a503          	lw	a0,0(s3)
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	90a080e7          	jalr	-1782(ra) # 8000333e <bfree>
      ip->addrs[i] = 0;
    80003a3c:	0004a023          	sw	zero,0(s1)
    80003a40:	b7dd                	j	80003a26 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a42:	0809a583          	lw	a1,128(s3)
    80003a46:	e185                	bnez	a1,80003a66 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a48:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a4c:	854e                	mv	a0,s3
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	de4080e7          	jalr	-540(ra) # 80003832 <iupdate>
}
    80003a56:	70a2                	ld	ra,40(sp)
    80003a58:	7402                	ld	s0,32(sp)
    80003a5a:	64e2                	ld	s1,24(sp)
    80003a5c:	6942                	ld	s2,16(sp)
    80003a5e:	69a2                	ld	s3,8(sp)
    80003a60:	6a02                	ld	s4,0(sp)
    80003a62:	6145                	addi	sp,sp,48
    80003a64:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a66:	0009a503          	lw	a0,0(s3)
    80003a6a:	fffff097          	auipc	ra,0xfffff
    80003a6e:	68e080e7          	jalr	1678(ra) # 800030f8 <bread>
    80003a72:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a74:	05850493          	addi	s1,a0,88
    80003a78:	45850913          	addi	s2,a0,1112
    80003a7c:	a021                	j	80003a84 <itrunc+0x7a>
    80003a7e:	0491                	addi	s1,s1,4
    80003a80:	01248b63          	beq	s1,s2,80003a96 <itrunc+0x8c>
      if(a[j])
    80003a84:	408c                	lw	a1,0(s1)
    80003a86:	dde5                	beqz	a1,80003a7e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a88:	0009a503          	lw	a0,0(s3)
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	8b2080e7          	jalr	-1870(ra) # 8000333e <bfree>
    80003a94:	b7ed                	j	80003a7e <itrunc+0x74>
    brelse(bp);
    80003a96:	8552                	mv	a0,s4
    80003a98:	fffff097          	auipc	ra,0xfffff
    80003a9c:	790080e7          	jalr	1936(ra) # 80003228 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003aa0:	0809a583          	lw	a1,128(s3)
    80003aa4:	0009a503          	lw	a0,0(s3)
    80003aa8:	00000097          	auipc	ra,0x0
    80003aac:	896080e7          	jalr	-1898(ra) # 8000333e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ab0:	0809a023          	sw	zero,128(s3)
    80003ab4:	bf51                	j	80003a48 <itrunc+0x3e>

0000000080003ab6 <iput>:
{
    80003ab6:	1101                	addi	sp,sp,-32
    80003ab8:	ec06                	sd	ra,24(sp)
    80003aba:	e822                	sd	s0,16(sp)
    80003abc:	e426                	sd	s1,8(sp)
    80003abe:	e04a                	sd	s2,0(sp)
    80003ac0:	1000                	addi	s0,sp,32
    80003ac2:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003ac4:	0001d517          	auipc	a0,0x1d
    80003ac8:	9e450513          	addi	a0,a0,-1564 # 800204a8 <icache>
    80003acc:	ffffd097          	auipc	ra,0xffffd
    80003ad0:	132080e7          	jalr	306(ra) # 80000bfe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ad4:	4498                	lw	a4,8(s1)
    80003ad6:	4785                	li	a5,1
    80003ad8:	02f70363          	beq	a4,a5,80003afe <iput+0x48>
  ip->ref--;
    80003adc:	449c                	lw	a5,8(s1)
    80003ade:	37fd                	addiw	a5,a5,-1
    80003ae0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003ae2:	0001d517          	auipc	a0,0x1d
    80003ae6:	9c650513          	addi	a0,a0,-1594 # 800204a8 <icache>
    80003aea:	ffffd097          	auipc	ra,0xffffd
    80003aee:	1c8080e7          	jalr	456(ra) # 80000cb2 <release>
}
    80003af2:	60e2                	ld	ra,24(sp)
    80003af4:	6442                	ld	s0,16(sp)
    80003af6:	64a2                	ld	s1,8(sp)
    80003af8:	6902                	ld	s2,0(sp)
    80003afa:	6105                	addi	sp,sp,32
    80003afc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003afe:	40bc                	lw	a5,64(s1)
    80003b00:	dff1                	beqz	a5,80003adc <iput+0x26>
    80003b02:	04a49783          	lh	a5,74(s1)
    80003b06:	fbf9                	bnez	a5,80003adc <iput+0x26>
    acquiresleep(&ip->lock);
    80003b08:	01048913          	addi	s2,s1,16
    80003b0c:	854a                	mv	a0,s2
    80003b0e:	00001097          	auipc	ra,0x1
    80003b12:	aac080e7          	jalr	-1364(ra) # 800045ba <acquiresleep>
    release(&icache.lock);
    80003b16:	0001d517          	auipc	a0,0x1d
    80003b1a:	99250513          	addi	a0,a0,-1646 # 800204a8 <icache>
    80003b1e:	ffffd097          	auipc	ra,0xffffd
    80003b22:	194080e7          	jalr	404(ra) # 80000cb2 <release>
    itrunc(ip);
    80003b26:	8526                	mv	a0,s1
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	ee2080e7          	jalr	-286(ra) # 80003a0a <itrunc>
    ip->type = 0;
    80003b30:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b34:	8526                	mv	a0,s1
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	cfc080e7          	jalr	-772(ra) # 80003832 <iupdate>
    ip->valid = 0;
    80003b3e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b42:	854a                	mv	a0,s2
    80003b44:	00001097          	auipc	ra,0x1
    80003b48:	acc080e7          	jalr	-1332(ra) # 80004610 <releasesleep>
    acquire(&icache.lock);
    80003b4c:	0001d517          	auipc	a0,0x1d
    80003b50:	95c50513          	addi	a0,a0,-1700 # 800204a8 <icache>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	0aa080e7          	jalr	170(ra) # 80000bfe <acquire>
    80003b5c:	b741                	j	80003adc <iput+0x26>

0000000080003b5e <iunlockput>:
{
    80003b5e:	1101                	addi	sp,sp,-32
    80003b60:	ec06                	sd	ra,24(sp)
    80003b62:	e822                	sd	s0,16(sp)
    80003b64:	e426                	sd	s1,8(sp)
    80003b66:	1000                	addi	s0,sp,32
    80003b68:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	e54080e7          	jalr	-428(ra) # 800039be <iunlock>
  iput(ip);
    80003b72:	8526                	mv	a0,s1
    80003b74:	00000097          	auipc	ra,0x0
    80003b78:	f42080e7          	jalr	-190(ra) # 80003ab6 <iput>
}
    80003b7c:	60e2                	ld	ra,24(sp)
    80003b7e:	6442                	ld	s0,16(sp)
    80003b80:	64a2                	ld	s1,8(sp)
    80003b82:	6105                	addi	sp,sp,32
    80003b84:	8082                	ret

0000000080003b86 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b86:	1141                	addi	sp,sp,-16
    80003b88:	e422                	sd	s0,8(sp)
    80003b8a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b8c:	411c                	lw	a5,0(a0)
    80003b8e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b90:	415c                	lw	a5,4(a0)
    80003b92:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b94:	04451783          	lh	a5,68(a0)
    80003b98:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b9c:	04a51783          	lh	a5,74(a0)
    80003ba0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ba4:	04c56783          	lwu	a5,76(a0)
    80003ba8:	e99c                	sd	a5,16(a1)
}
    80003baa:	6422                	ld	s0,8(sp)
    80003bac:	0141                	addi	sp,sp,16
    80003bae:	8082                	ret

0000000080003bb0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bb0:	457c                	lw	a5,76(a0)
    80003bb2:	0ed7e863          	bltu	a5,a3,80003ca2 <readi+0xf2>
{
    80003bb6:	7159                	addi	sp,sp,-112
    80003bb8:	f486                	sd	ra,104(sp)
    80003bba:	f0a2                	sd	s0,96(sp)
    80003bbc:	eca6                	sd	s1,88(sp)
    80003bbe:	e8ca                	sd	s2,80(sp)
    80003bc0:	e4ce                	sd	s3,72(sp)
    80003bc2:	e0d2                	sd	s4,64(sp)
    80003bc4:	fc56                	sd	s5,56(sp)
    80003bc6:	f85a                	sd	s6,48(sp)
    80003bc8:	f45e                	sd	s7,40(sp)
    80003bca:	f062                	sd	s8,32(sp)
    80003bcc:	ec66                	sd	s9,24(sp)
    80003bce:	e86a                	sd	s10,16(sp)
    80003bd0:	e46e                	sd	s11,8(sp)
    80003bd2:	1880                	addi	s0,sp,112
    80003bd4:	8baa                	mv	s7,a0
    80003bd6:	8c2e                	mv	s8,a1
    80003bd8:	8ab2                	mv	s5,a2
    80003bda:	84b6                	mv	s1,a3
    80003bdc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bde:	9f35                	addw	a4,a4,a3
    return 0;
    80003be0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003be2:	08d76f63          	bltu	a4,a3,80003c80 <readi+0xd0>
  if(off + n > ip->size)
    80003be6:	00e7f463          	bgeu	a5,a4,80003bee <readi+0x3e>
    n = ip->size - off;
    80003bea:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bee:	0a0b0863          	beqz	s6,80003c9e <readi+0xee>
    80003bf2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bf8:	5cfd                	li	s9,-1
    80003bfa:	a82d                	j	80003c34 <readi+0x84>
    80003bfc:	020a1d93          	slli	s11,s4,0x20
    80003c00:	020ddd93          	srli	s11,s11,0x20
    80003c04:	05890793          	addi	a5,s2,88
    80003c08:	86ee                	mv	a3,s11
    80003c0a:	963e                	add	a2,a2,a5
    80003c0c:	85d6                	mv	a1,s5
    80003c0e:	8562                	mv	a0,s8
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	b2c080e7          	jalr	-1236(ra) # 8000273c <either_copyout>
    80003c18:	05950d63          	beq	a0,s9,80003c72 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c1c:	854a                	mv	a0,s2
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	60a080e7          	jalr	1546(ra) # 80003228 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c26:	013a09bb          	addw	s3,s4,s3
    80003c2a:	009a04bb          	addw	s1,s4,s1
    80003c2e:	9aee                	add	s5,s5,s11
    80003c30:	0569f663          	bgeu	s3,s6,80003c7c <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c34:	000ba903          	lw	s2,0(s7)
    80003c38:	00a4d59b          	srliw	a1,s1,0xa
    80003c3c:	855e                	mv	a0,s7
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	8ae080e7          	jalr	-1874(ra) # 800034ec <bmap>
    80003c46:	0005059b          	sext.w	a1,a0
    80003c4a:	854a                	mv	a0,s2
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	4ac080e7          	jalr	1196(ra) # 800030f8 <bread>
    80003c54:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c56:	3ff4f613          	andi	a2,s1,1023
    80003c5a:	40cd07bb          	subw	a5,s10,a2
    80003c5e:	413b073b          	subw	a4,s6,s3
    80003c62:	8a3e                	mv	s4,a5
    80003c64:	2781                	sext.w	a5,a5
    80003c66:	0007069b          	sext.w	a3,a4
    80003c6a:	f8f6f9e3          	bgeu	a3,a5,80003bfc <readi+0x4c>
    80003c6e:	8a3a                	mv	s4,a4
    80003c70:	b771                	j	80003bfc <readi+0x4c>
      brelse(bp);
    80003c72:	854a                	mv	a0,s2
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	5b4080e7          	jalr	1460(ra) # 80003228 <brelse>
  }
  return tot;
    80003c7c:	0009851b          	sext.w	a0,s3
}
    80003c80:	70a6                	ld	ra,104(sp)
    80003c82:	7406                	ld	s0,96(sp)
    80003c84:	64e6                	ld	s1,88(sp)
    80003c86:	6946                	ld	s2,80(sp)
    80003c88:	69a6                	ld	s3,72(sp)
    80003c8a:	6a06                	ld	s4,64(sp)
    80003c8c:	7ae2                	ld	s5,56(sp)
    80003c8e:	7b42                	ld	s6,48(sp)
    80003c90:	7ba2                	ld	s7,40(sp)
    80003c92:	7c02                	ld	s8,32(sp)
    80003c94:	6ce2                	ld	s9,24(sp)
    80003c96:	6d42                	ld	s10,16(sp)
    80003c98:	6da2                	ld	s11,8(sp)
    80003c9a:	6165                	addi	sp,sp,112
    80003c9c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c9e:	89da                	mv	s3,s6
    80003ca0:	bff1                	j	80003c7c <readi+0xcc>
    return 0;
    80003ca2:	4501                	li	a0,0
}
    80003ca4:	8082                	ret

0000000080003ca6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ca6:	457c                	lw	a5,76(a0)
    80003ca8:	10d7e663          	bltu	a5,a3,80003db4 <writei+0x10e>
{
    80003cac:	7159                	addi	sp,sp,-112
    80003cae:	f486                	sd	ra,104(sp)
    80003cb0:	f0a2                	sd	s0,96(sp)
    80003cb2:	eca6                	sd	s1,88(sp)
    80003cb4:	e8ca                	sd	s2,80(sp)
    80003cb6:	e4ce                	sd	s3,72(sp)
    80003cb8:	e0d2                	sd	s4,64(sp)
    80003cba:	fc56                	sd	s5,56(sp)
    80003cbc:	f85a                	sd	s6,48(sp)
    80003cbe:	f45e                	sd	s7,40(sp)
    80003cc0:	f062                	sd	s8,32(sp)
    80003cc2:	ec66                	sd	s9,24(sp)
    80003cc4:	e86a                	sd	s10,16(sp)
    80003cc6:	e46e                	sd	s11,8(sp)
    80003cc8:	1880                	addi	s0,sp,112
    80003cca:	8baa                	mv	s7,a0
    80003ccc:	8c2e                	mv	s8,a1
    80003cce:	8ab2                	mv	s5,a2
    80003cd0:	8936                	mv	s2,a3
    80003cd2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cd4:	00e687bb          	addw	a5,a3,a4
    80003cd8:	0ed7e063          	bltu	a5,a3,80003db8 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cdc:	00043737          	lui	a4,0x43
    80003ce0:	0cf76e63          	bltu	a4,a5,80003dbc <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ce4:	0a0b0763          	beqz	s6,80003d92 <writei+0xec>
    80003ce8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cea:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cee:	5cfd                	li	s9,-1
    80003cf0:	a091                	j	80003d34 <writei+0x8e>
    80003cf2:	02099d93          	slli	s11,s3,0x20
    80003cf6:	020ddd93          	srli	s11,s11,0x20
    80003cfa:	05848793          	addi	a5,s1,88
    80003cfe:	86ee                	mv	a3,s11
    80003d00:	8656                	mv	a2,s5
    80003d02:	85e2                	mv	a1,s8
    80003d04:	953e                	add	a0,a0,a5
    80003d06:	fffff097          	auipc	ra,0xfffff
    80003d0a:	a8c080e7          	jalr	-1396(ra) # 80002792 <either_copyin>
    80003d0e:	07950263          	beq	a0,s9,80003d72 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d12:	8526                	mv	a0,s1
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	77e080e7          	jalr	1918(ra) # 80004492 <log_write>
    brelse(bp);
    80003d1c:	8526                	mv	a0,s1
    80003d1e:	fffff097          	auipc	ra,0xfffff
    80003d22:	50a080e7          	jalr	1290(ra) # 80003228 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d26:	01498a3b          	addw	s4,s3,s4
    80003d2a:	0129893b          	addw	s2,s3,s2
    80003d2e:	9aee                	add	s5,s5,s11
    80003d30:	056a7663          	bgeu	s4,s6,80003d7c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d34:	000ba483          	lw	s1,0(s7)
    80003d38:	00a9559b          	srliw	a1,s2,0xa
    80003d3c:	855e                	mv	a0,s7
    80003d3e:	fffff097          	auipc	ra,0xfffff
    80003d42:	7ae080e7          	jalr	1966(ra) # 800034ec <bmap>
    80003d46:	0005059b          	sext.w	a1,a0
    80003d4a:	8526                	mv	a0,s1
    80003d4c:	fffff097          	auipc	ra,0xfffff
    80003d50:	3ac080e7          	jalr	940(ra) # 800030f8 <bread>
    80003d54:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d56:	3ff97513          	andi	a0,s2,1023
    80003d5a:	40ad07bb          	subw	a5,s10,a0
    80003d5e:	414b073b          	subw	a4,s6,s4
    80003d62:	89be                	mv	s3,a5
    80003d64:	2781                	sext.w	a5,a5
    80003d66:	0007069b          	sext.w	a3,a4
    80003d6a:	f8f6f4e3          	bgeu	a3,a5,80003cf2 <writei+0x4c>
    80003d6e:	89ba                	mv	s3,a4
    80003d70:	b749                	j	80003cf2 <writei+0x4c>
      brelse(bp);
    80003d72:	8526                	mv	a0,s1
    80003d74:	fffff097          	auipc	ra,0xfffff
    80003d78:	4b4080e7          	jalr	1204(ra) # 80003228 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003d7c:	04cba783          	lw	a5,76(s7)
    80003d80:	0127f463          	bgeu	a5,s2,80003d88 <writei+0xe2>
      ip->size = off;
    80003d84:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d88:	855e                	mv	a0,s7
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	aa8080e7          	jalr	-1368(ra) # 80003832 <iupdate>
  }

  return n;
    80003d92:	000b051b          	sext.w	a0,s6
}
    80003d96:	70a6                	ld	ra,104(sp)
    80003d98:	7406                	ld	s0,96(sp)
    80003d9a:	64e6                	ld	s1,88(sp)
    80003d9c:	6946                	ld	s2,80(sp)
    80003d9e:	69a6                	ld	s3,72(sp)
    80003da0:	6a06                	ld	s4,64(sp)
    80003da2:	7ae2                	ld	s5,56(sp)
    80003da4:	7b42                	ld	s6,48(sp)
    80003da6:	7ba2                	ld	s7,40(sp)
    80003da8:	7c02                	ld	s8,32(sp)
    80003daa:	6ce2                	ld	s9,24(sp)
    80003dac:	6d42                	ld	s10,16(sp)
    80003dae:	6da2                	ld	s11,8(sp)
    80003db0:	6165                	addi	sp,sp,112
    80003db2:	8082                	ret
    return -1;
    80003db4:	557d                	li	a0,-1
}
    80003db6:	8082                	ret
    return -1;
    80003db8:	557d                	li	a0,-1
    80003dba:	bff1                	j	80003d96 <writei+0xf0>
    return -1;
    80003dbc:	557d                	li	a0,-1
    80003dbe:	bfe1                	j	80003d96 <writei+0xf0>

0000000080003dc0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dc0:	1141                	addi	sp,sp,-16
    80003dc2:	e406                	sd	ra,8(sp)
    80003dc4:	e022                	sd	s0,0(sp)
    80003dc6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dc8:	4639                	li	a2,14
    80003dca:	ffffd097          	auipc	ra,0xffffd
    80003dce:	008080e7          	jalr	8(ra) # 80000dd2 <strncmp>
}
    80003dd2:	60a2                	ld	ra,8(sp)
    80003dd4:	6402                	ld	s0,0(sp)
    80003dd6:	0141                	addi	sp,sp,16
    80003dd8:	8082                	ret

0000000080003dda <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dda:	7139                	addi	sp,sp,-64
    80003ddc:	fc06                	sd	ra,56(sp)
    80003dde:	f822                	sd	s0,48(sp)
    80003de0:	f426                	sd	s1,40(sp)
    80003de2:	f04a                	sd	s2,32(sp)
    80003de4:	ec4e                	sd	s3,24(sp)
    80003de6:	e852                	sd	s4,16(sp)
    80003de8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dea:	04451703          	lh	a4,68(a0)
    80003dee:	4785                	li	a5,1
    80003df0:	00f71a63          	bne	a4,a5,80003e04 <dirlookup+0x2a>
    80003df4:	892a                	mv	s2,a0
    80003df6:	89ae                	mv	s3,a1
    80003df8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfa:	457c                	lw	a5,76(a0)
    80003dfc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dfe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e00:	e79d                	bnez	a5,80003e2e <dirlookup+0x54>
    80003e02:	a8a5                	j	80003e7a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e04:	00005517          	auipc	a0,0x5
    80003e08:	87c50513          	addi	a0,a0,-1924 # 80008680 <syscalls+0x1a0>
    80003e0c:	ffffc097          	auipc	ra,0xffffc
    80003e10:	736080e7          	jalr	1846(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003e14:	00005517          	auipc	a0,0x5
    80003e18:	88450513          	addi	a0,a0,-1916 # 80008698 <syscalls+0x1b8>
    80003e1c:	ffffc097          	auipc	ra,0xffffc
    80003e20:	726080e7          	jalr	1830(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e24:	24c1                	addiw	s1,s1,16
    80003e26:	04c92783          	lw	a5,76(s2)
    80003e2a:	04f4f763          	bgeu	s1,a5,80003e78 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e2e:	4741                	li	a4,16
    80003e30:	86a6                	mv	a3,s1
    80003e32:	fc040613          	addi	a2,s0,-64
    80003e36:	4581                	li	a1,0
    80003e38:	854a                	mv	a0,s2
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	d76080e7          	jalr	-650(ra) # 80003bb0 <readi>
    80003e42:	47c1                	li	a5,16
    80003e44:	fcf518e3          	bne	a0,a5,80003e14 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e48:	fc045783          	lhu	a5,-64(s0)
    80003e4c:	dfe1                	beqz	a5,80003e24 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e4e:	fc240593          	addi	a1,s0,-62
    80003e52:	854e                	mv	a0,s3
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	f6c080e7          	jalr	-148(ra) # 80003dc0 <namecmp>
    80003e5c:	f561                	bnez	a0,80003e24 <dirlookup+0x4a>
      if(poff)
    80003e5e:	000a0463          	beqz	s4,80003e66 <dirlookup+0x8c>
        *poff = off;
    80003e62:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e66:	fc045583          	lhu	a1,-64(s0)
    80003e6a:	00092503          	lw	a0,0(s2)
    80003e6e:	fffff097          	auipc	ra,0xfffff
    80003e72:	75a080e7          	jalr	1882(ra) # 800035c8 <iget>
    80003e76:	a011                	j	80003e7a <dirlookup+0xa0>
  return 0;
    80003e78:	4501                	li	a0,0
}
    80003e7a:	70e2                	ld	ra,56(sp)
    80003e7c:	7442                	ld	s0,48(sp)
    80003e7e:	74a2                	ld	s1,40(sp)
    80003e80:	7902                	ld	s2,32(sp)
    80003e82:	69e2                	ld	s3,24(sp)
    80003e84:	6a42                	ld	s4,16(sp)
    80003e86:	6121                	addi	sp,sp,64
    80003e88:	8082                	ret

0000000080003e8a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e8a:	711d                	addi	sp,sp,-96
    80003e8c:	ec86                	sd	ra,88(sp)
    80003e8e:	e8a2                	sd	s0,80(sp)
    80003e90:	e4a6                	sd	s1,72(sp)
    80003e92:	e0ca                	sd	s2,64(sp)
    80003e94:	fc4e                	sd	s3,56(sp)
    80003e96:	f852                	sd	s4,48(sp)
    80003e98:	f456                	sd	s5,40(sp)
    80003e9a:	f05a                	sd	s6,32(sp)
    80003e9c:	ec5e                	sd	s7,24(sp)
    80003e9e:	e862                	sd	s8,16(sp)
    80003ea0:	e466                	sd	s9,8(sp)
    80003ea2:	1080                	addi	s0,sp,96
    80003ea4:	84aa                	mv	s1,a0
    80003ea6:	8aae                	mv	s5,a1
    80003ea8:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003eaa:	00054703          	lbu	a4,0(a0)
    80003eae:	02f00793          	li	a5,47
    80003eb2:	02f70363          	beq	a4,a5,80003ed8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003eb6:	ffffe097          	auipc	ra,0xffffe
    80003eba:	c1e080e7          	jalr	-994(ra) # 80001ad4 <myproc>
    80003ebe:	15053503          	ld	a0,336(a0)
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	9fc080e7          	jalr	-1540(ra) # 800038be <idup>
    80003eca:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ecc:	02f00913          	li	s2,47
  len = path - s;
    80003ed0:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003ed2:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ed4:	4b85                	li	s7,1
    80003ed6:	a865                	j	80003f8e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ed8:	4585                	li	a1,1
    80003eda:	4505                	li	a0,1
    80003edc:	fffff097          	auipc	ra,0xfffff
    80003ee0:	6ec080e7          	jalr	1772(ra) # 800035c8 <iget>
    80003ee4:	89aa                	mv	s3,a0
    80003ee6:	b7dd                	j	80003ecc <namex+0x42>
      iunlockput(ip);
    80003ee8:	854e                	mv	a0,s3
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	c74080e7          	jalr	-908(ra) # 80003b5e <iunlockput>
      return 0;
    80003ef2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ef4:	854e                	mv	a0,s3
    80003ef6:	60e6                	ld	ra,88(sp)
    80003ef8:	6446                	ld	s0,80(sp)
    80003efa:	64a6                	ld	s1,72(sp)
    80003efc:	6906                	ld	s2,64(sp)
    80003efe:	79e2                	ld	s3,56(sp)
    80003f00:	7a42                	ld	s4,48(sp)
    80003f02:	7aa2                	ld	s5,40(sp)
    80003f04:	7b02                	ld	s6,32(sp)
    80003f06:	6be2                	ld	s7,24(sp)
    80003f08:	6c42                	ld	s8,16(sp)
    80003f0a:	6ca2                	ld	s9,8(sp)
    80003f0c:	6125                	addi	sp,sp,96
    80003f0e:	8082                	ret
      iunlock(ip);
    80003f10:	854e                	mv	a0,s3
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	aac080e7          	jalr	-1364(ra) # 800039be <iunlock>
      return ip;
    80003f1a:	bfe9                	j	80003ef4 <namex+0x6a>
      iunlockput(ip);
    80003f1c:	854e                	mv	a0,s3
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	c40080e7          	jalr	-960(ra) # 80003b5e <iunlockput>
      return 0;
    80003f26:	89e6                	mv	s3,s9
    80003f28:	b7f1                	j	80003ef4 <namex+0x6a>
  len = path - s;
    80003f2a:	40b48633          	sub	a2,s1,a1
    80003f2e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f32:	099c5463          	bge	s8,s9,80003fba <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f36:	4639                	li	a2,14
    80003f38:	8552                	mv	a0,s4
    80003f3a:	ffffd097          	auipc	ra,0xffffd
    80003f3e:	e1c080e7          	jalr	-484(ra) # 80000d56 <memmove>
  while(*path == '/')
    80003f42:	0004c783          	lbu	a5,0(s1)
    80003f46:	01279763          	bne	a5,s2,80003f54 <namex+0xca>
    path++;
    80003f4a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f4c:	0004c783          	lbu	a5,0(s1)
    80003f50:	ff278de3          	beq	a5,s2,80003f4a <namex+0xc0>
    ilock(ip);
    80003f54:	854e                	mv	a0,s3
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	9a6080e7          	jalr	-1626(ra) # 800038fc <ilock>
    if(ip->type != T_DIR){
    80003f5e:	04499783          	lh	a5,68(s3)
    80003f62:	f97793e3          	bne	a5,s7,80003ee8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f66:	000a8563          	beqz	s5,80003f70 <namex+0xe6>
    80003f6a:	0004c783          	lbu	a5,0(s1)
    80003f6e:	d3cd                	beqz	a5,80003f10 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f70:	865a                	mv	a2,s6
    80003f72:	85d2                	mv	a1,s4
    80003f74:	854e                	mv	a0,s3
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	e64080e7          	jalr	-412(ra) # 80003dda <dirlookup>
    80003f7e:	8caa                	mv	s9,a0
    80003f80:	dd51                	beqz	a0,80003f1c <namex+0x92>
    iunlockput(ip);
    80003f82:	854e                	mv	a0,s3
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	bda080e7          	jalr	-1062(ra) # 80003b5e <iunlockput>
    ip = next;
    80003f8c:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f8e:	0004c783          	lbu	a5,0(s1)
    80003f92:	05279763          	bne	a5,s2,80003fe0 <namex+0x156>
    path++;
    80003f96:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f98:	0004c783          	lbu	a5,0(s1)
    80003f9c:	ff278de3          	beq	a5,s2,80003f96 <namex+0x10c>
  if(*path == 0)
    80003fa0:	c79d                	beqz	a5,80003fce <namex+0x144>
    path++;
    80003fa2:	85a6                	mv	a1,s1
  len = path - s;
    80003fa4:	8cda                	mv	s9,s6
    80003fa6:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003fa8:	01278963          	beq	a5,s2,80003fba <namex+0x130>
    80003fac:	dfbd                	beqz	a5,80003f2a <namex+0xa0>
    path++;
    80003fae:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fb0:	0004c783          	lbu	a5,0(s1)
    80003fb4:	ff279ce3          	bne	a5,s2,80003fac <namex+0x122>
    80003fb8:	bf8d                	j	80003f2a <namex+0xa0>
    memmove(name, s, len);
    80003fba:	2601                	sext.w	a2,a2
    80003fbc:	8552                	mv	a0,s4
    80003fbe:	ffffd097          	auipc	ra,0xffffd
    80003fc2:	d98080e7          	jalr	-616(ra) # 80000d56 <memmove>
    name[len] = 0;
    80003fc6:	9cd2                	add	s9,s9,s4
    80003fc8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fcc:	bf9d                	j	80003f42 <namex+0xb8>
  if(nameiparent){
    80003fce:	f20a83e3          	beqz	s5,80003ef4 <namex+0x6a>
    iput(ip);
    80003fd2:	854e                	mv	a0,s3
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	ae2080e7          	jalr	-1310(ra) # 80003ab6 <iput>
    return 0;
    80003fdc:	4981                	li	s3,0
    80003fde:	bf19                	j	80003ef4 <namex+0x6a>
  if(*path == 0)
    80003fe0:	d7fd                	beqz	a5,80003fce <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fe2:	0004c783          	lbu	a5,0(s1)
    80003fe6:	85a6                	mv	a1,s1
    80003fe8:	b7d1                	j	80003fac <namex+0x122>

0000000080003fea <dirlink>:
{
    80003fea:	7139                	addi	sp,sp,-64
    80003fec:	fc06                	sd	ra,56(sp)
    80003fee:	f822                	sd	s0,48(sp)
    80003ff0:	f426                	sd	s1,40(sp)
    80003ff2:	f04a                	sd	s2,32(sp)
    80003ff4:	ec4e                	sd	s3,24(sp)
    80003ff6:	e852                	sd	s4,16(sp)
    80003ff8:	0080                	addi	s0,sp,64
    80003ffa:	892a                	mv	s2,a0
    80003ffc:	8a2e                	mv	s4,a1
    80003ffe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004000:	4601                	li	a2,0
    80004002:	00000097          	auipc	ra,0x0
    80004006:	dd8080e7          	jalr	-552(ra) # 80003dda <dirlookup>
    8000400a:	e93d                	bnez	a0,80004080 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400c:	04c92483          	lw	s1,76(s2)
    80004010:	c49d                	beqz	s1,8000403e <dirlink+0x54>
    80004012:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004014:	4741                	li	a4,16
    80004016:	86a6                	mv	a3,s1
    80004018:	fc040613          	addi	a2,s0,-64
    8000401c:	4581                	li	a1,0
    8000401e:	854a                	mv	a0,s2
    80004020:	00000097          	auipc	ra,0x0
    80004024:	b90080e7          	jalr	-1136(ra) # 80003bb0 <readi>
    80004028:	47c1                	li	a5,16
    8000402a:	06f51163          	bne	a0,a5,8000408c <dirlink+0xa2>
    if(de.inum == 0)
    8000402e:	fc045783          	lhu	a5,-64(s0)
    80004032:	c791                	beqz	a5,8000403e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004034:	24c1                	addiw	s1,s1,16
    80004036:	04c92783          	lw	a5,76(s2)
    8000403a:	fcf4ede3          	bltu	s1,a5,80004014 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000403e:	4639                	li	a2,14
    80004040:	85d2                	mv	a1,s4
    80004042:	fc240513          	addi	a0,s0,-62
    80004046:	ffffd097          	auipc	ra,0xffffd
    8000404a:	dc8080e7          	jalr	-568(ra) # 80000e0e <strncpy>
  de.inum = inum;
    8000404e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004052:	4741                	li	a4,16
    80004054:	86a6                	mv	a3,s1
    80004056:	fc040613          	addi	a2,s0,-64
    8000405a:	4581                	li	a1,0
    8000405c:	854a                	mv	a0,s2
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	c48080e7          	jalr	-952(ra) # 80003ca6 <writei>
    80004066:	872a                	mv	a4,a0
    80004068:	47c1                	li	a5,16
  return 0;
    8000406a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000406c:	02f71863          	bne	a4,a5,8000409c <dirlink+0xb2>
}
    80004070:	70e2                	ld	ra,56(sp)
    80004072:	7442                	ld	s0,48(sp)
    80004074:	74a2                	ld	s1,40(sp)
    80004076:	7902                	ld	s2,32(sp)
    80004078:	69e2                	ld	s3,24(sp)
    8000407a:	6a42                	ld	s4,16(sp)
    8000407c:	6121                	addi	sp,sp,64
    8000407e:	8082                	ret
    iput(ip);
    80004080:	00000097          	auipc	ra,0x0
    80004084:	a36080e7          	jalr	-1482(ra) # 80003ab6 <iput>
    return -1;
    80004088:	557d                	li	a0,-1
    8000408a:	b7dd                	j	80004070 <dirlink+0x86>
      panic("dirlink read");
    8000408c:	00004517          	auipc	a0,0x4
    80004090:	61c50513          	addi	a0,a0,1564 # 800086a8 <syscalls+0x1c8>
    80004094:	ffffc097          	auipc	ra,0xffffc
    80004098:	4ae080e7          	jalr	1198(ra) # 80000542 <panic>
    panic("dirlink");
    8000409c:	00004517          	auipc	a0,0x4
    800040a0:	72c50513          	addi	a0,a0,1836 # 800087c8 <syscalls+0x2e8>
    800040a4:	ffffc097          	auipc	ra,0xffffc
    800040a8:	49e080e7          	jalr	1182(ra) # 80000542 <panic>

00000000800040ac <namei>:

struct inode*
namei(char *path)
{
    800040ac:	1101                	addi	sp,sp,-32
    800040ae:	ec06                	sd	ra,24(sp)
    800040b0:	e822                	sd	s0,16(sp)
    800040b2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040b4:	fe040613          	addi	a2,s0,-32
    800040b8:	4581                	li	a1,0
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	dd0080e7          	jalr	-560(ra) # 80003e8a <namex>
}
    800040c2:	60e2                	ld	ra,24(sp)
    800040c4:	6442                	ld	s0,16(sp)
    800040c6:	6105                	addi	sp,sp,32
    800040c8:	8082                	ret

00000000800040ca <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040ca:	1141                	addi	sp,sp,-16
    800040cc:	e406                	sd	ra,8(sp)
    800040ce:	e022                	sd	s0,0(sp)
    800040d0:	0800                	addi	s0,sp,16
    800040d2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040d4:	4585                	li	a1,1
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	db4080e7          	jalr	-588(ra) # 80003e8a <namex>
}
    800040de:	60a2                	ld	ra,8(sp)
    800040e0:	6402                	ld	s0,0(sp)
    800040e2:	0141                	addi	sp,sp,16
    800040e4:	8082                	ret

00000000800040e6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040e6:	1101                	addi	sp,sp,-32
    800040e8:	ec06                	sd	ra,24(sp)
    800040ea:	e822                	sd	s0,16(sp)
    800040ec:	e426                	sd	s1,8(sp)
    800040ee:	e04a                	sd	s2,0(sp)
    800040f0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040f2:	0001e917          	auipc	s2,0x1e
    800040f6:	e5e90913          	addi	s2,s2,-418 # 80021f50 <log>
    800040fa:	01892583          	lw	a1,24(s2)
    800040fe:	02892503          	lw	a0,40(s2)
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	ff6080e7          	jalr	-10(ra) # 800030f8 <bread>
    8000410a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000410c:	02c92683          	lw	a3,44(s2)
    80004110:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004112:	02d05863          	blez	a3,80004142 <write_head+0x5c>
    80004116:	0001e797          	auipc	a5,0x1e
    8000411a:	e6a78793          	addi	a5,a5,-406 # 80021f80 <log+0x30>
    8000411e:	05c50713          	addi	a4,a0,92
    80004122:	36fd                	addiw	a3,a3,-1
    80004124:	02069613          	slli	a2,a3,0x20
    80004128:	01e65693          	srli	a3,a2,0x1e
    8000412c:	0001e617          	auipc	a2,0x1e
    80004130:	e5860613          	addi	a2,a2,-424 # 80021f84 <log+0x34>
    80004134:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004136:	4390                	lw	a2,0(a5)
    80004138:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000413a:	0791                	addi	a5,a5,4
    8000413c:	0711                	addi	a4,a4,4
    8000413e:	fed79ce3          	bne	a5,a3,80004136 <write_head+0x50>
  }
  bwrite(buf);
    80004142:	8526                	mv	a0,s1
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	0a6080e7          	jalr	166(ra) # 800031ea <bwrite>
  brelse(buf);
    8000414c:	8526                	mv	a0,s1
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	0da080e7          	jalr	218(ra) # 80003228 <brelse>
}
    80004156:	60e2                	ld	ra,24(sp)
    80004158:	6442                	ld	s0,16(sp)
    8000415a:	64a2                	ld	s1,8(sp)
    8000415c:	6902                	ld	s2,0(sp)
    8000415e:	6105                	addi	sp,sp,32
    80004160:	8082                	ret

0000000080004162 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004162:	0001e797          	auipc	a5,0x1e
    80004166:	e1a7a783          	lw	a5,-486(a5) # 80021f7c <log+0x2c>
    8000416a:	0af05663          	blez	a5,80004216 <install_trans+0xb4>
{
    8000416e:	7139                	addi	sp,sp,-64
    80004170:	fc06                	sd	ra,56(sp)
    80004172:	f822                	sd	s0,48(sp)
    80004174:	f426                	sd	s1,40(sp)
    80004176:	f04a                	sd	s2,32(sp)
    80004178:	ec4e                	sd	s3,24(sp)
    8000417a:	e852                	sd	s4,16(sp)
    8000417c:	e456                	sd	s5,8(sp)
    8000417e:	0080                	addi	s0,sp,64
    80004180:	0001ea97          	auipc	s5,0x1e
    80004184:	e00a8a93          	addi	s5,s5,-512 # 80021f80 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004188:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000418a:	0001e997          	auipc	s3,0x1e
    8000418e:	dc698993          	addi	s3,s3,-570 # 80021f50 <log>
    80004192:	0189a583          	lw	a1,24(s3)
    80004196:	014585bb          	addw	a1,a1,s4
    8000419a:	2585                	addiw	a1,a1,1
    8000419c:	0289a503          	lw	a0,40(s3)
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	f58080e7          	jalr	-168(ra) # 800030f8 <bread>
    800041a8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041aa:	000aa583          	lw	a1,0(s5)
    800041ae:	0289a503          	lw	a0,40(s3)
    800041b2:	fffff097          	auipc	ra,0xfffff
    800041b6:	f46080e7          	jalr	-186(ra) # 800030f8 <bread>
    800041ba:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041bc:	40000613          	li	a2,1024
    800041c0:	05890593          	addi	a1,s2,88
    800041c4:	05850513          	addi	a0,a0,88
    800041c8:	ffffd097          	auipc	ra,0xffffd
    800041cc:	b8e080e7          	jalr	-1138(ra) # 80000d56 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041d0:	8526                	mv	a0,s1
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	018080e7          	jalr	24(ra) # 800031ea <bwrite>
    bunpin(dbuf);
    800041da:	8526                	mv	a0,s1
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	126080e7          	jalr	294(ra) # 80003302 <bunpin>
    brelse(lbuf);
    800041e4:	854a                	mv	a0,s2
    800041e6:	fffff097          	auipc	ra,0xfffff
    800041ea:	042080e7          	jalr	66(ra) # 80003228 <brelse>
    brelse(dbuf);
    800041ee:	8526                	mv	a0,s1
    800041f0:	fffff097          	auipc	ra,0xfffff
    800041f4:	038080e7          	jalr	56(ra) # 80003228 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f8:	2a05                	addiw	s4,s4,1
    800041fa:	0a91                	addi	s5,s5,4
    800041fc:	02c9a783          	lw	a5,44(s3)
    80004200:	f8fa49e3          	blt	s4,a5,80004192 <install_trans+0x30>
}
    80004204:	70e2                	ld	ra,56(sp)
    80004206:	7442                	ld	s0,48(sp)
    80004208:	74a2                	ld	s1,40(sp)
    8000420a:	7902                	ld	s2,32(sp)
    8000420c:	69e2                	ld	s3,24(sp)
    8000420e:	6a42                	ld	s4,16(sp)
    80004210:	6aa2                	ld	s5,8(sp)
    80004212:	6121                	addi	sp,sp,64
    80004214:	8082                	ret
    80004216:	8082                	ret

0000000080004218 <initlog>:
{
    80004218:	7179                	addi	sp,sp,-48
    8000421a:	f406                	sd	ra,40(sp)
    8000421c:	f022                	sd	s0,32(sp)
    8000421e:	ec26                	sd	s1,24(sp)
    80004220:	e84a                	sd	s2,16(sp)
    80004222:	e44e                	sd	s3,8(sp)
    80004224:	1800                	addi	s0,sp,48
    80004226:	892a                	mv	s2,a0
    80004228:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000422a:	0001e497          	auipc	s1,0x1e
    8000422e:	d2648493          	addi	s1,s1,-730 # 80021f50 <log>
    80004232:	00004597          	auipc	a1,0x4
    80004236:	48658593          	addi	a1,a1,1158 # 800086b8 <syscalls+0x1d8>
    8000423a:	8526                	mv	a0,s1
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	932080e7          	jalr	-1742(ra) # 80000b6e <initlock>
  log.start = sb->logstart;
    80004244:	0149a583          	lw	a1,20(s3)
    80004248:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000424a:	0109a783          	lw	a5,16(s3)
    8000424e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004250:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004254:	854a                	mv	a0,s2
    80004256:	fffff097          	auipc	ra,0xfffff
    8000425a:	ea2080e7          	jalr	-350(ra) # 800030f8 <bread>
  log.lh.n = lh->n;
    8000425e:	4d34                	lw	a3,88(a0)
    80004260:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004262:	02d05663          	blez	a3,8000428e <initlog+0x76>
    80004266:	05c50793          	addi	a5,a0,92
    8000426a:	0001e717          	auipc	a4,0x1e
    8000426e:	d1670713          	addi	a4,a4,-746 # 80021f80 <log+0x30>
    80004272:	36fd                	addiw	a3,a3,-1
    80004274:	02069613          	slli	a2,a3,0x20
    80004278:	01e65693          	srli	a3,a2,0x1e
    8000427c:	06050613          	addi	a2,a0,96
    80004280:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004282:	4390                	lw	a2,0(a5)
    80004284:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004286:	0791                	addi	a5,a5,4
    80004288:	0711                	addi	a4,a4,4
    8000428a:	fed79ce3          	bne	a5,a3,80004282 <initlog+0x6a>
  brelse(buf);
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	f9a080e7          	jalr	-102(ra) # 80003228 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	ecc080e7          	jalr	-308(ra) # 80004162 <install_trans>
  log.lh.n = 0;
    8000429e:	0001e797          	auipc	a5,0x1e
    800042a2:	cc07af23          	sw	zero,-802(a5) # 80021f7c <log+0x2c>
  write_head(); // clear the log
    800042a6:	00000097          	auipc	ra,0x0
    800042aa:	e40080e7          	jalr	-448(ra) # 800040e6 <write_head>
}
    800042ae:	70a2                	ld	ra,40(sp)
    800042b0:	7402                	ld	s0,32(sp)
    800042b2:	64e2                	ld	s1,24(sp)
    800042b4:	6942                	ld	s2,16(sp)
    800042b6:	69a2                	ld	s3,8(sp)
    800042b8:	6145                	addi	sp,sp,48
    800042ba:	8082                	ret

00000000800042bc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042bc:	1101                	addi	sp,sp,-32
    800042be:	ec06                	sd	ra,24(sp)
    800042c0:	e822                	sd	s0,16(sp)
    800042c2:	e426                	sd	s1,8(sp)
    800042c4:	e04a                	sd	s2,0(sp)
    800042c6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042c8:	0001e517          	auipc	a0,0x1e
    800042cc:	c8850513          	addi	a0,a0,-888 # 80021f50 <log>
    800042d0:	ffffd097          	auipc	ra,0xffffd
    800042d4:	92e080e7          	jalr	-1746(ra) # 80000bfe <acquire>
  while(1){
    if(log.committing){
    800042d8:	0001e497          	auipc	s1,0x1e
    800042dc:	c7848493          	addi	s1,s1,-904 # 80021f50 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042e0:	4979                	li	s2,30
    800042e2:	a039                	j	800042f0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042e4:	85a6                	mv	a1,s1
    800042e6:	8526                	mv	a0,s1
    800042e8:	ffffe097          	auipc	ra,0xffffe
    800042ec:	176080e7          	jalr	374(ra) # 8000245e <sleep>
    if(log.committing){
    800042f0:	50dc                	lw	a5,36(s1)
    800042f2:	fbed                	bnez	a5,800042e4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042f4:	509c                	lw	a5,32(s1)
    800042f6:	0017871b          	addiw	a4,a5,1
    800042fa:	0007069b          	sext.w	a3,a4
    800042fe:	0027179b          	slliw	a5,a4,0x2
    80004302:	9fb9                	addw	a5,a5,a4
    80004304:	0017979b          	slliw	a5,a5,0x1
    80004308:	54d8                	lw	a4,44(s1)
    8000430a:	9fb9                	addw	a5,a5,a4
    8000430c:	00f95963          	bge	s2,a5,8000431e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004310:	85a6                	mv	a1,s1
    80004312:	8526                	mv	a0,s1
    80004314:	ffffe097          	auipc	ra,0xffffe
    80004318:	14a080e7          	jalr	330(ra) # 8000245e <sleep>
    8000431c:	bfd1                	j	800042f0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000431e:	0001e517          	auipc	a0,0x1e
    80004322:	c3250513          	addi	a0,a0,-974 # 80021f50 <log>
    80004326:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	98a080e7          	jalr	-1654(ra) # 80000cb2 <release>
      break;
    }
  }
}
    80004330:	60e2                	ld	ra,24(sp)
    80004332:	6442                	ld	s0,16(sp)
    80004334:	64a2                	ld	s1,8(sp)
    80004336:	6902                	ld	s2,0(sp)
    80004338:	6105                	addi	sp,sp,32
    8000433a:	8082                	ret

000000008000433c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000433c:	7139                	addi	sp,sp,-64
    8000433e:	fc06                	sd	ra,56(sp)
    80004340:	f822                	sd	s0,48(sp)
    80004342:	f426                	sd	s1,40(sp)
    80004344:	f04a                	sd	s2,32(sp)
    80004346:	ec4e                	sd	s3,24(sp)
    80004348:	e852                	sd	s4,16(sp)
    8000434a:	e456                	sd	s5,8(sp)
    8000434c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000434e:	0001e497          	auipc	s1,0x1e
    80004352:	c0248493          	addi	s1,s1,-1022 # 80021f50 <log>
    80004356:	8526                	mv	a0,s1
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	8a6080e7          	jalr	-1882(ra) # 80000bfe <acquire>
  log.outstanding -= 1;
    80004360:	509c                	lw	a5,32(s1)
    80004362:	37fd                	addiw	a5,a5,-1
    80004364:	0007891b          	sext.w	s2,a5
    80004368:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000436a:	50dc                	lw	a5,36(s1)
    8000436c:	e7b9                	bnez	a5,800043ba <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000436e:	04091e63          	bnez	s2,800043ca <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004372:	0001e497          	auipc	s1,0x1e
    80004376:	bde48493          	addi	s1,s1,-1058 # 80021f50 <log>
    8000437a:	4785                	li	a5,1
    8000437c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000437e:	8526                	mv	a0,s1
    80004380:	ffffd097          	auipc	ra,0xffffd
    80004384:	932080e7          	jalr	-1742(ra) # 80000cb2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004388:	54dc                	lw	a5,44(s1)
    8000438a:	06f04763          	bgtz	a5,800043f8 <end_op+0xbc>
    acquire(&log.lock);
    8000438e:	0001e497          	auipc	s1,0x1e
    80004392:	bc248493          	addi	s1,s1,-1086 # 80021f50 <log>
    80004396:	8526                	mv	a0,s1
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	866080e7          	jalr	-1946(ra) # 80000bfe <acquire>
    log.committing = 0;
    800043a0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043a4:	8526                	mv	a0,s1
    800043a6:	ffffe097          	auipc	ra,0xffffe
    800043aa:	26a080e7          	jalr	618(ra) # 80002610 <wakeup>
    release(&log.lock);
    800043ae:	8526                	mv	a0,s1
    800043b0:	ffffd097          	auipc	ra,0xffffd
    800043b4:	902080e7          	jalr	-1790(ra) # 80000cb2 <release>
}
    800043b8:	a03d                	j	800043e6 <end_op+0xaa>
    panic("log.committing");
    800043ba:	00004517          	auipc	a0,0x4
    800043be:	30650513          	addi	a0,a0,774 # 800086c0 <syscalls+0x1e0>
    800043c2:	ffffc097          	auipc	ra,0xffffc
    800043c6:	180080e7          	jalr	384(ra) # 80000542 <panic>
    wakeup(&log);
    800043ca:	0001e497          	auipc	s1,0x1e
    800043ce:	b8648493          	addi	s1,s1,-1146 # 80021f50 <log>
    800043d2:	8526                	mv	a0,s1
    800043d4:	ffffe097          	auipc	ra,0xffffe
    800043d8:	23c080e7          	jalr	572(ra) # 80002610 <wakeup>
  release(&log.lock);
    800043dc:	8526                	mv	a0,s1
    800043de:	ffffd097          	auipc	ra,0xffffd
    800043e2:	8d4080e7          	jalr	-1836(ra) # 80000cb2 <release>
}
    800043e6:	70e2                	ld	ra,56(sp)
    800043e8:	7442                	ld	s0,48(sp)
    800043ea:	74a2                	ld	s1,40(sp)
    800043ec:	7902                	ld	s2,32(sp)
    800043ee:	69e2                	ld	s3,24(sp)
    800043f0:	6a42                	ld	s4,16(sp)
    800043f2:	6aa2                	ld	s5,8(sp)
    800043f4:	6121                	addi	sp,sp,64
    800043f6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043f8:	0001ea97          	auipc	s5,0x1e
    800043fc:	b88a8a93          	addi	s5,s5,-1144 # 80021f80 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004400:	0001ea17          	auipc	s4,0x1e
    80004404:	b50a0a13          	addi	s4,s4,-1200 # 80021f50 <log>
    80004408:	018a2583          	lw	a1,24(s4)
    8000440c:	012585bb          	addw	a1,a1,s2
    80004410:	2585                	addiw	a1,a1,1
    80004412:	028a2503          	lw	a0,40(s4)
    80004416:	fffff097          	auipc	ra,0xfffff
    8000441a:	ce2080e7          	jalr	-798(ra) # 800030f8 <bread>
    8000441e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004420:	000aa583          	lw	a1,0(s5)
    80004424:	028a2503          	lw	a0,40(s4)
    80004428:	fffff097          	auipc	ra,0xfffff
    8000442c:	cd0080e7          	jalr	-816(ra) # 800030f8 <bread>
    80004430:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004432:	40000613          	li	a2,1024
    80004436:	05850593          	addi	a1,a0,88
    8000443a:	05848513          	addi	a0,s1,88
    8000443e:	ffffd097          	auipc	ra,0xffffd
    80004442:	918080e7          	jalr	-1768(ra) # 80000d56 <memmove>
    bwrite(to);  // write the log
    80004446:	8526                	mv	a0,s1
    80004448:	fffff097          	auipc	ra,0xfffff
    8000444c:	da2080e7          	jalr	-606(ra) # 800031ea <bwrite>
    brelse(from);
    80004450:	854e                	mv	a0,s3
    80004452:	fffff097          	auipc	ra,0xfffff
    80004456:	dd6080e7          	jalr	-554(ra) # 80003228 <brelse>
    brelse(to);
    8000445a:	8526                	mv	a0,s1
    8000445c:	fffff097          	auipc	ra,0xfffff
    80004460:	dcc080e7          	jalr	-564(ra) # 80003228 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004464:	2905                	addiw	s2,s2,1
    80004466:	0a91                	addi	s5,s5,4
    80004468:	02ca2783          	lw	a5,44(s4)
    8000446c:	f8f94ee3          	blt	s2,a5,80004408 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004470:	00000097          	auipc	ra,0x0
    80004474:	c76080e7          	jalr	-906(ra) # 800040e6 <write_head>
    install_trans(); // Now install writes to home locations
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	cea080e7          	jalr	-790(ra) # 80004162 <install_trans>
    log.lh.n = 0;
    80004480:	0001e797          	auipc	a5,0x1e
    80004484:	ae07ae23          	sw	zero,-1284(a5) # 80021f7c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	c5e080e7          	jalr	-930(ra) # 800040e6 <write_head>
    80004490:	bdfd                	j	8000438e <end_op+0x52>

0000000080004492 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004492:	1101                	addi	sp,sp,-32
    80004494:	ec06                	sd	ra,24(sp)
    80004496:	e822                	sd	s0,16(sp)
    80004498:	e426                	sd	s1,8(sp)
    8000449a:	e04a                	sd	s2,0(sp)
    8000449c:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000449e:	0001e717          	auipc	a4,0x1e
    800044a2:	ade72703          	lw	a4,-1314(a4) # 80021f7c <log+0x2c>
    800044a6:	47f5                	li	a5,29
    800044a8:	08e7c063          	blt	a5,a4,80004528 <log_write+0x96>
    800044ac:	84aa                	mv	s1,a0
    800044ae:	0001e797          	auipc	a5,0x1e
    800044b2:	abe7a783          	lw	a5,-1346(a5) # 80021f6c <log+0x1c>
    800044b6:	37fd                	addiw	a5,a5,-1
    800044b8:	06f75863          	bge	a4,a5,80004528 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044bc:	0001e797          	auipc	a5,0x1e
    800044c0:	ab47a783          	lw	a5,-1356(a5) # 80021f70 <log+0x20>
    800044c4:	06f05a63          	blez	a5,80004538 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800044c8:	0001e917          	auipc	s2,0x1e
    800044cc:	a8890913          	addi	s2,s2,-1400 # 80021f50 <log>
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	72c080e7          	jalr	1836(ra) # 80000bfe <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800044da:	02c92603          	lw	a2,44(s2)
    800044de:	06c05563          	blez	a2,80004548 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044e2:	44cc                	lw	a1,12(s1)
    800044e4:	0001e717          	auipc	a4,0x1e
    800044e8:	a9c70713          	addi	a4,a4,-1380 # 80021f80 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044ec:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044ee:	4314                	lw	a3,0(a4)
    800044f0:	04b68d63          	beq	a3,a1,8000454a <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800044f4:	2785                	addiw	a5,a5,1
    800044f6:	0711                	addi	a4,a4,4
    800044f8:	fec79be3          	bne	a5,a2,800044ee <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044fc:	0621                	addi	a2,a2,8
    800044fe:	060a                	slli	a2,a2,0x2
    80004500:	0001e797          	auipc	a5,0x1e
    80004504:	a5078793          	addi	a5,a5,-1456 # 80021f50 <log>
    80004508:	963e                	add	a2,a2,a5
    8000450a:	44dc                	lw	a5,12(s1)
    8000450c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000450e:	8526                	mv	a0,s1
    80004510:	fffff097          	auipc	ra,0xfffff
    80004514:	db6080e7          	jalr	-586(ra) # 800032c6 <bpin>
    log.lh.n++;
    80004518:	0001e717          	auipc	a4,0x1e
    8000451c:	a3870713          	addi	a4,a4,-1480 # 80021f50 <log>
    80004520:	575c                	lw	a5,44(a4)
    80004522:	2785                	addiw	a5,a5,1
    80004524:	d75c                	sw	a5,44(a4)
    80004526:	a83d                	j	80004564 <log_write+0xd2>
    panic("too big a transaction");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	1a850513          	addi	a0,a0,424 # 800086d0 <syscalls+0x1f0>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	012080e7          	jalr	18(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    80004538:	00004517          	auipc	a0,0x4
    8000453c:	1b050513          	addi	a0,a0,432 # 800086e8 <syscalls+0x208>
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	002080e7          	jalr	2(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004548:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000454a:	00878713          	addi	a4,a5,8
    8000454e:	00271693          	slli	a3,a4,0x2
    80004552:	0001e717          	auipc	a4,0x1e
    80004556:	9fe70713          	addi	a4,a4,-1538 # 80021f50 <log>
    8000455a:	9736                	add	a4,a4,a3
    8000455c:	44d4                	lw	a3,12(s1)
    8000455e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004560:	faf607e3          	beq	a2,a5,8000450e <log_write+0x7c>
  }
  release(&log.lock);
    80004564:	0001e517          	auipc	a0,0x1e
    80004568:	9ec50513          	addi	a0,a0,-1556 # 80021f50 <log>
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	746080e7          	jalr	1862(ra) # 80000cb2 <release>
}
    80004574:	60e2                	ld	ra,24(sp)
    80004576:	6442                	ld	s0,16(sp)
    80004578:	64a2                	ld	s1,8(sp)
    8000457a:	6902                	ld	s2,0(sp)
    8000457c:	6105                	addi	sp,sp,32
    8000457e:	8082                	ret

0000000080004580 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004580:	1101                	addi	sp,sp,-32
    80004582:	ec06                	sd	ra,24(sp)
    80004584:	e822                	sd	s0,16(sp)
    80004586:	e426                	sd	s1,8(sp)
    80004588:	e04a                	sd	s2,0(sp)
    8000458a:	1000                	addi	s0,sp,32
    8000458c:	84aa                	mv	s1,a0
    8000458e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004590:	00004597          	auipc	a1,0x4
    80004594:	17858593          	addi	a1,a1,376 # 80008708 <syscalls+0x228>
    80004598:	0521                	addi	a0,a0,8
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	5d4080e7          	jalr	1492(ra) # 80000b6e <initlock>
  lk->name = name;
    800045a2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045aa:	0204a423          	sw	zero,40(s1)
}
    800045ae:	60e2                	ld	ra,24(sp)
    800045b0:	6442                	ld	s0,16(sp)
    800045b2:	64a2                	ld	s1,8(sp)
    800045b4:	6902                	ld	s2,0(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret

00000000800045ba <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045ba:	1101                	addi	sp,sp,-32
    800045bc:	ec06                	sd	ra,24(sp)
    800045be:	e822                	sd	s0,16(sp)
    800045c0:	e426                	sd	s1,8(sp)
    800045c2:	e04a                	sd	s2,0(sp)
    800045c4:	1000                	addi	s0,sp,32
    800045c6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045c8:	00850913          	addi	s2,a0,8
    800045cc:	854a                	mv	a0,s2
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	630080e7          	jalr	1584(ra) # 80000bfe <acquire>
  while (lk->locked) {
    800045d6:	409c                	lw	a5,0(s1)
    800045d8:	cb89                	beqz	a5,800045ea <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045da:	85ca                	mv	a1,s2
    800045dc:	8526                	mv	a0,s1
    800045de:	ffffe097          	auipc	ra,0xffffe
    800045e2:	e80080e7          	jalr	-384(ra) # 8000245e <sleep>
  while (lk->locked) {
    800045e6:	409c                	lw	a5,0(s1)
    800045e8:	fbed                	bnez	a5,800045da <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045ea:	4785                	li	a5,1
    800045ec:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045ee:	ffffd097          	auipc	ra,0xffffd
    800045f2:	4e6080e7          	jalr	1254(ra) # 80001ad4 <myproc>
    800045f6:	5d1c                	lw	a5,56(a0)
    800045f8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045fa:	854a                	mv	a0,s2
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	6b6080e7          	jalr	1718(ra) # 80000cb2 <release>
}
    80004604:	60e2                	ld	ra,24(sp)
    80004606:	6442                	ld	s0,16(sp)
    80004608:	64a2                	ld	s1,8(sp)
    8000460a:	6902                	ld	s2,0(sp)
    8000460c:	6105                	addi	sp,sp,32
    8000460e:	8082                	ret

0000000080004610 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004610:	1101                	addi	sp,sp,-32
    80004612:	ec06                	sd	ra,24(sp)
    80004614:	e822                	sd	s0,16(sp)
    80004616:	e426                	sd	s1,8(sp)
    80004618:	e04a                	sd	s2,0(sp)
    8000461a:	1000                	addi	s0,sp,32
    8000461c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000461e:	00850913          	addi	s2,a0,8
    80004622:	854a                	mv	a0,s2
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	5da080e7          	jalr	1498(ra) # 80000bfe <acquire>
  lk->locked = 0;
    8000462c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004630:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004634:	8526                	mv	a0,s1
    80004636:	ffffe097          	auipc	ra,0xffffe
    8000463a:	fda080e7          	jalr	-38(ra) # 80002610 <wakeup>
  release(&lk->lk);
    8000463e:	854a                	mv	a0,s2
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	672080e7          	jalr	1650(ra) # 80000cb2 <release>
}
    80004648:	60e2                	ld	ra,24(sp)
    8000464a:	6442                	ld	s0,16(sp)
    8000464c:	64a2                	ld	s1,8(sp)
    8000464e:	6902                	ld	s2,0(sp)
    80004650:	6105                	addi	sp,sp,32
    80004652:	8082                	ret

0000000080004654 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004654:	7179                	addi	sp,sp,-48
    80004656:	f406                	sd	ra,40(sp)
    80004658:	f022                	sd	s0,32(sp)
    8000465a:	ec26                	sd	s1,24(sp)
    8000465c:	e84a                	sd	s2,16(sp)
    8000465e:	e44e                	sd	s3,8(sp)
    80004660:	1800                	addi	s0,sp,48
    80004662:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004664:	00850913          	addi	s2,a0,8
    80004668:	854a                	mv	a0,s2
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	594080e7          	jalr	1428(ra) # 80000bfe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004672:	409c                	lw	a5,0(s1)
    80004674:	ef99                	bnez	a5,80004692 <holdingsleep+0x3e>
    80004676:	4481                	li	s1,0
  release(&lk->lk);
    80004678:	854a                	mv	a0,s2
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	638080e7          	jalr	1592(ra) # 80000cb2 <release>
  return r;
}
    80004682:	8526                	mv	a0,s1
    80004684:	70a2                	ld	ra,40(sp)
    80004686:	7402                	ld	s0,32(sp)
    80004688:	64e2                	ld	s1,24(sp)
    8000468a:	6942                	ld	s2,16(sp)
    8000468c:	69a2                	ld	s3,8(sp)
    8000468e:	6145                	addi	sp,sp,48
    80004690:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004692:	0284a983          	lw	s3,40(s1)
    80004696:	ffffd097          	auipc	ra,0xffffd
    8000469a:	43e080e7          	jalr	1086(ra) # 80001ad4 <myproc>
    8000469e:	5d04                	lw	s1,56(a0)
    800046a0:	413484b3          	sub	s1,s1,s3
    800046a4:	0014b493          	seqz	s1,s1
    800046a8:	bfc1                	j	80004678 <holdingsleep+0x24>

00000000800046aa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046aa:	1141                	addi	sp,sp,-16
    800046ac:	e406                	sd	ra,8(sp)
    800046ae:	e022                	sd	s0,0(sp)
    800046b0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046b2:	00004597          	auipc	a1,0x4
    800046b6:	06658593          	addi	a1,a1,102 # 80008718 <syscalls+0x238>
    800046ba:	0001e517          	auipc	a0,0x1e
    800046be:	9de50513          	addi	a0,a0,-1570 # 80022098 <ftable>
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	4ac080e7          	jalr	1196(ra) # 80000b6e <initlock>
}
    800046ca:	60a2                	ld	ra,8(sp)
    800046cc:	6402                	ld	s0,0(sp)
    800046ce:	0141                	addi	sp,sp,16
    800046d0:	8082                	ret

00000000800046d2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046d2:	1101                	addi	sp,sp,-32
    800046d4:	ec06                	sd	ra,24(sp)
    800046d6:	e822                	sd	s0,16(sp)
    800046d8:	e426                	sd	s1,8(sp)
    800046da:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046dc:	0001e517          	auipc	a0,0x1e
    800046e0:	9bc50513          	addi	a0,a0,-1604 # 80022098 <ftable>
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	51a080e7          	jalr	1306(ra) # 80000bfe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ec:	0001e497          	auipc	s1,0x1e
    800046f0:	9c448493          	addi	s1,s1,-1596 # 800220b0 <ftable+0x18>
    800046f4:	0001f717          	auipc	a4,0x1f
    800046f8:	95c70713          	addi	a4,a4,-1700 # 80023050 <ftable+0xfb8>
    if(f->ref == 0){
    800046fc:	40dc                	lw	a5,4(s1)
    800046fe:	cf99                	beqz	a5,8000471c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004700:	02848493          	addi	s1,s1,40
    80004704:	fee49ce3          	bne	s1,a4,800046fc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004708:	0001e517          	auipc	a0,0x1e
    8000470c:	99050513          	addi	a0,a0,-1648 # 80022098 <ftable>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	5a2080e7          	jalr	1442(ra) # 80000cb2 <release>
  return 0;
    80004718:	4481                	li	s1,0
    8000471a:	a819                	j	80004730 <filealloc+0x5e>
      f->ref = 1;
    8000471c:	4785                	li	a5,1
    8000471e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004720:	0001e517          	auipc	a0,0x1e
    80004724:	97850513          	addi	a0,a0,-1672 # 80022098 <ftable>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	58a080e7          	jalr	1418(ra) # 80000cb2 <release>
}
    80004730:	8526                	mv	a0,s1
    80004732:	60e2                	ld	ra,24(sp)
    80004734:	6442                	ld	s0,16(sp)
    80004736:	64a2                	ld	s1,8(sp)
    80004738:	6105                	addi	sp,sp,32
    8000473a:	8082                	ret

000000008000473c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000473c:	1101                	addi	sp,sp,-32
    8000473e:	ec06                	sd	ra,24(sp)
    80004740:	e822                	sd	s0,16(sp)
    80004742:	e426                	sd	s1,8(sp)
    80004744:	1000                	addi	s0,sp,32
    80004746:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004748:	0001e517          	auipc	a0,0x1e
    8000474c:	95050513          	addi	a0,a0,-1712 # 80022098 <ftable>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	4ae080e7          	jalr	1198(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    80004758:	40dc                	lw	a5,4(s1)
    8000475a:	02f05263          	blez	a5,8000477e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000475e:	2785                	addiw	a5,a5,1
    80004760:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004762:	0001e517          	auipc	a0,0x1e
    80004766:	93650513          	addi	a0,a0,-1738 # 80022098 <ftable>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	548080e7          	jalr	1352(ra) # 80000cb2 <release>
  return f;
}
    80004772:	8526                	mv	a0,s1
    80004774:	60e2                	ld	ra,24(sp)
    80004776:	6442                	ld	s0,16(sp)
    80004778:	64a2                	ld	s1,8(sp)
    8000477a:	6105                	addi	sp,sp,32
    8000477c:	8082                	ret
    panic("filedup");
    8000477e:	00004517          	auipc	a0,0x4
    80004782:	fa250513          	addi	a0,a0,-94 # 80008720 <syscalls+0x240>
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	dbc080e7          	jalr	-580(ra) # 80000542 <panic>

000000008000478e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000478e:	7139                	addi	sp,sp,-64
    80004790:	fc06                	sd	ra,56(sp)
    80004792:	f822                	sd	s0,48(sp)
    80004794:	f426                	sd	s1,40(sp)
    80004796:	f04a                	sd	s2,32(sp)
    80004798:	ec4e                	sd	s3,24(sp)
    8000479a:	e852                	sd	s4,16(sp)
    8000479c:	e456                	sd	s5,8(sp)
    8000479e:	0080                	addi	s0,sp,64
    800047a0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047a2:	0001e517          	auipc	a0,0x1e
    800047a6:	8f650513          	addi	a0,a0,-1802 # 80022098 <ftable>
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	454080e7          	jalr	1108(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    800047b2:	40dc                	lw	a5,4(s1)
    800047b4:	06f05163          	blez	a5,80004816 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047b8:	37fd                	addiw	a5,a5,-1
    800047ba:	0007871b          	sext.w	a4,a5
    800047be:	c0dc                	sw	a5,4(s1)
    800047c0:	06e04363          	bgtz	a4,80004826 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047c4:	0004a903          	lw	s2,0(s1)
    800047c8:	0094ca83          	lbu	s5,9(s1)
    800047cc:	0104ba03          	ld	s4,16(s1)
    800047d0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047d4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047d8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047dc:	0001e517          	auipc	a0,0x1e
    800047e0:	8bc50513          	addi	a0,a0,-1860 # 80022098 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4ce080e7          	jalr	1230(ra) # 80000cb2 <release>

  if(ff.type == FD_PIPE){
    800047ec:	4785                	li	a5,1
    800047ee:	04f90d63          	beq	s2,a5,80004848 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047f2:	3979                	addiw	s2,s2,-2
    800047f4:	4785                	li	a5,1
    800047f6:	0527e063          	bltu	a5,s2,80004836 <fileclose+0xa8>
    begin_op();
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	ac2080e7          	jalr	-1342(ra) # 800042bc <begin_op>
    iput(ff.ip);
    80004802:	854e                	mv	a0,s3
    80004804:	fffff097          	auipc	ra,0xfffff
    80004808:	2b2080e7          	jalr	690(ra) # 80003ab6 <iput>
    end_op();
    8000480c:	00000097          	auipc	ra,0x0
    80004810:	b30080e7          	jalr	-1232(ra) # 8000433c <end_op>
    80004814:	a00d                	j	80004836 <fileclose+0xa8>
    panic("fileclose");
    80004816:	00004517          	auipc	a0,0x4
    8000481a:	f1250513          	addi	a0,a0,-238 # 80008728 <syscalls+0x248>
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	d24080e7          	jalr	-732(ra) # 80000542 <panic>
    release(&ftable.lock);
    80004826:	0001e517          	auipc	a0,0x1e
    8000482a:	87250513          	addi	a0,a0,-1934 # 80022098 <ftable>
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	484080e7          	jalr	1156(ra) # 80000cb2 <release>
  }
}
    80004836:	70e2                	ld	ra,56(sp)
    80004838:	7442                	ld	s0,48(sp)
    8000483a:	74a2                	ld	s1,40(sp)
    8000483c:	7902                	ld	s2,32(sp)
    8000483e:	69e2                	ld	s3,24(sp)
    80004840:	6a42                	ld	s4,16(sp)
    80004842:	6aa2                	ld	s5,8(sp)
    80004844:	6121                	addi	sp,sp,64
    80004846:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004848:	85d6                	mv	a1,s5
    8000484a:	8552                	mv	a0,s4
    8000484c:	00000097          	auipc	ra,0x0
    80004850:	372080e7          	jalr	882(ra) # 80004bbe <pipeclose>
    80004854:	b7cd                	j	80004836 <fileclose+0xa8>

0000000080004856 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004856:	715d                	addi	sp,sp,-80
    80004858:	e486                	sd	ra,72(sp)
    8000485a:	e0a2                	sd	s0,64(sp)
    8000485c:	fc26                	sd	s1,56(sp)
    8000485e:	f84a                	sd	s2,48(sp)
    80004860:	f44e                	sd	s3,40(sp)
    80004862:	0880                	addi	s0,sp,80
    80004864:	84aa                	mv	s1,a0
    80004866:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004868:	ffffd097          	auipc	ra,0xffffd
    8000486c:	26c080e7          	jalr	620(ra) # 80001ad4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004870:	409c                	lw	a5,0(s1)
    80004872:	37f9                	addiw	a5,a5,-2
    80004874:	4705                	li	a4,1
    80004876:	04f76763          	bltu	a4,a5,800048c4 <filestat+0x6e>
    8000487a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000487c:	6c88                	ld	a0,24(s1)
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	07e080e7          	jalr	126(ra) # 800038fc <ilock>
    stati(f->ip, &st);
    80004886:	fb840593          	addi	a1,s0,-72
    8000488a:	6c88                	ld	a0,24(s1)
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	2fa080e7          	jalr	762(ra) # 80003b86 <stati>
    iunlock(f->ip);
    80004894:	6c88                	ld	a0,24(s1)
    80004896:	fffff097          	auipc	ra,0xfffff
    8000489a:	128080e7          	jalr	296(ra) # 800039be <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000489e:	46e1                	li	a3,24
    800048a0:	fb840613          	addi	a2,s0,-72
    800048a4:	85ce                	mv	a1,s3
    800048a6:	05093503          	ld	a0,80(s2)
    800048aa:	ffffd097          	auipc	ra,0xffffd
    800048ae:	e02080e7          	jalr	-510(ra) # 800016ac <copyout>
    800048b2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048b6:	60a6                	ld	ra,72(sp)
    800048b8:	6406                	ld	s0,64(sp)
    800048ba:	74e2                	ld	s1,56(sp)
    800048bc:	7942                	ld	s2,48(sp)
    800048be:	79a2                	ld	s3,40(sp)
    800048c0:	6161                	addi	sp,sp,80
    800048c2:	8082                	ret
  return -1;
    800048c4:	557d                	li	a0,-1
    800048c6:	bfc5                	j	800048b6 <filestat+0x60>

00000000800048c8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048c8:	7179                	addi	sp,sp,-48
    800048ca:	f406                	sd	ra,40(sp)
    800048cc:	f022                	sd	s0,32(sp)
    800048ce:	ec26                	sd	s1,24(sp)
    800048d0:	e84a                	sd	s2,16(sp)
    800048d2:	e44e                	sd	s3,8(sp)
    800048d4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048d6:	00854783          	lbu	a5,8(a0)
    800048da:	c3d5                	beqz	a5,8000497e <fileread+0xb6>
    800048dc:	84aa                	mv	s1,a0
    800048de:	89ae                	mv	s3,a1
    800048e0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048e2:	411c                	lw	a5,0(a0)
    800048e4:	4705                	li	a4,1
    800048e6:	04e78963          	beq	a5,a4,80004938 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ea:	470d                	li	a4,3
    800048ec:	04e78d63          	beq	a5,a4,80004946 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048f0:	4709                	li	a4,2
    800048f2:	06e79e63          	bne	a5,a4,8000496e <fileread+0xa6>
    ilock(f->ip);
    800048f6:	6d08                	ld	a0,24(a0)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	004080e7          	jalr	4(ra) # 800038fc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004900:	874a                	mv	a4,s2
    80004902:	5094                	lw	a3,32(s1)
    80004904:	864e                	mv	a2,s3
    80004906:	4585                	li	a1,1
    80004908:	6c88                	ld	a0,24(s1)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	2a6080e7          	jalr	678(ra) # 80003bb0 <readi>
    80004912:	892a                	mv	s2,a0
    80004914:	00a05563          	blez	a0,8000491e <fileread+0x56>
      f->off += r;
    80004918:	509c                	lw	a5,32(s1)
    8000491a:	9fa9                	addw	a5,a5,a0
    8000491c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000491e:	6c88                	ld	a0,24(s1)
    80004920:	fffff097          	auipc	ra,0xfffff
    80004924:	09e080e7          	jalr	158(ra) # 800039be <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004928:	854a                	mv	a0,s2
    8000492a:	70a2                	ld	ra,40(sp)
    8000492c:	7402                	ld	s0,32(sp)
    8000492e:	64e2                	ld	s1,24(sp)
    80004930:	6942                	ld	s2,16(sp)
    80004932:	69a2                	ld	s3,8(sp)
    80004934:	6145                	addi	sp,sp,48
    80004936:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004938:	6908                	ld	a0,16(a0)
    8000493a:	00000097          	auipc	ra,0x0
    8000493e:	3f4080e7          	jalr	1012(ra) # 80004d2e <piperead>
    80004942:	892a                	mv	s2,a0
    80004944:	b7d5                	j	80004928 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004946:	02451783          	lh	a5,36(a0)
    8000494a:	03079693          	slli	a3,a5,0x30
    8000494e:	92c1                	srli	a3,a3,0x30
    80004950:	4725                	li	a4,9
    80004952:	02d76863          	bltu	a4,a3,80004982 <fileread+0xba>
    80004956:	0792                	slli	a5,a5,0x4
    80004958:	0001d717          	auipc	a4,0x1d
    8000495c:	6a070713          	addi	a4,a4,1696 # 80021ff8 <devsw>
    80004960:	97ba                	add	a5,a5,a4
    80004962:	639c                	ld	a5,0(a5)
    80004964:	c38d                	beqz	a5,80004986 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004966:	4505                	li	a0,1
    80004968:	9782                	jalr	a5
    8000496a:	892a                	mv	s2,a0
    8000496c:	bf75                	j	80004928 <fileread+0x60>
    panic("fileread");
    8000496e:	00004517          	auipc	a0,0x4
    80004972:	dca50513          	addi	a0,a0,-566 # 80008738 <syscalls+0x258>
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	bcc080e7          	jalr	-1076(ra) # 80000542 <panic>
    return -1;
    8000497e:	597d                	li	s2,-1
    80004980:	b765                	j	80004928 <fileread+0x60>
      return -1;
    80004982:	597d                	li	s2,-1
    80004984:	b755                	j	80004928 <fileread+0x60>
    80004986:	597d                	li	s2,-1
    80004988:	b745                	j	80004928 <fileread+0x60>

000000008000498a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000498a:	00954783          	lbu	a5,9(a0)
    8000498e:	14078563          	beqz	a5,80004ad8 <filewrite+0x14e>
{
    80004992:	715d                	addi	sp,sp,-80
    80004994:	e486                	sd	ra,72(sp)
    80004996:	e0a2                	sd	s0,64(sp)
    80004998:	fc26                	sd	s1,56(sp)
    8000499a:	f84a                	sd	s2,48(sp)
    8000499c:	f44e                	sd	s3,40(sp)
    8000499e:	f052                	sd	s4,32(sp)
    800049a0:	ec56                	sd	s5,24(sp)
    800049a2:	e85a                	sd	s6,16(sp)
    800049a4:	e45e                	sd	s7,8(sp)
    800049a6:	e062                	sd	s8,0(sp)
    800049a8:	0880                	addi	s0,sp,80
    800049aa:	892a                	mv	s2,a0
    800049ac:	8aae                	mv	s5,a1
    800049ae:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049b0:	411c                	lw	a5,0(a0)
    800049b2:	4705                	li	a4,1
    800049b4:	02e78263          	beq	a5,a4,800049d8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049b8:	470d                	li	a4,3
    800049ba:	02e78563          	beq	a5,a4,800049e4 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049be:	4709                	li	a4,2
    800049c0:	10e79463          	bne	a5,a4,80004ac8 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049c4:	0ec05e63          	blez	a2,80004ac0 <filewrite+0x136>
    int i = 0;
    800049c8:	4981                	li	s3,0
    800049ca:	6b05                	lui	s6,0x1
    800049cc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049d0:	6b85                	lui	s7,0x1
    800049d2:	c00b8b9b          	addiw	s7,s7,-1024
    800049d6:	a851                	j	80004a6a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800049d8:	6908                	ld	a0,16(a0)
    800049da:	00000097          	auipc	ra,0x0
    800049de:	254080e7          	jalr	596(ra) # 80004c2e <pipewrite>
    800049e2:	a85d                	j	80004a98 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049e4:	02451783          	lh	a5,36(a0)
    800049e8:	03079693          	slli	a3,a5,0x30
    800049ec:	92c1                	srli	a3,a3,0x30
    800049ee:	4725                	li	a4,9
    800049f0:	0ed76663          	bltu	a4,a3,80004adc <filewrite+0x152>
    800049f4:	0792                	slli	a5,a5,0x4
    800049f6:	0001d717          	auipc	a4,0x1d
    800049fa:	60270713          	addi	a4,a4,1538 # 80021ff8 <devsw>
    800049fe:	97ba                	add	a5,a5,a4
    80004a00:	679c                	ld	a5,8(a5)
    80004a02:	cff9                	beqz	a5,80004ae0 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a04:	4505                	li	a0,1
    80004a06:	9782                	jalr	a5
    80004a08:	a841                	j	80004a98 <filewrite+0x10e>
    80004a0a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a0e:	00000097          	auipc	ra,0x0
    80004a12:	8ae080e7          	jalr	-1874(ra) # 800042bc <begin_op>
      ilock(f->ip);
    80004a16:	01893503          	ld	a0,24(s2)
    80004a1a:	fffff097          	auipc	ra,0xfffff
    80004a1e:	ee2080e7          	jalr	-286(ra) # 800038fc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a22:	8762                	mv	a4,s8
    80004a24:	02092683          	lw	a3,32(s2)
    80004a28:	01598633          	add	a2,s3,s5
    80004a2c:	4585                	li	a1,1
    80004a2e:	01893503          	ld	a0,24(s2)
    80004a32:	fffff097          	auipc	ra,0xfffff
    80004a36:	274080e7          	jalr	628(ra) # 80003ca6 <writei>
    80004a3a:	84aa                	mv	s1,a0
    80004a3c:	02a05f63          	blez	a0,80004a7a <filewrite+0xf0>
        f->off += r;
    80004a40:	02092783          	lw	a5,32(s2)
    80004a44:	9fa9                	addw	a5,a5,a0
    80004a46:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a4a:	01893503          	ld	a0,24(s2)
    80004a4e:	fffff097          	auipc	ra,0xfffff
    80004a52:	f70080e7          	jalr	-144(ra) # 800039be <iunlock>
      end_op();
    80004a56:	00000097          	auipc	ra,0x0
    80004a5a:	8e6080e7          	jalr	-1818(ra) # 8000433c <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a5e:	049c1963          	bne	s8,s1,80004ab0 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a62:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a66:	0349d663          	bge	s3,s4,80004a92 <filewrite+0x108>
      int n1 = n - i;
    80004a6a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a6e:	84be                	mv	s1,a5
    80004a70:	2781                	sext.w	a5,a5
    80004a72:	f8fb5ce3          	bge	s6,a5,80004a0a <filewrite+0x80>
    80004a76:	84de                	mv	s1,s7
    80004a78:	bf49                	j	80004a0a <filewrite+0x80>
      iunlock(f->ip);
    80004a7a:	01893503          	ld	a0,24(s2)
    80004a7e:	fffff097          	auipc	ra,0xfffff
    80004a82:	f40080e7          	jalr	-192(ra) # 800039be <iunlock>
      end_op();
    80004a86:	00000097          	auipc	ra,0x0
    80004a8a:	8b6080e7          	jalr	-1866(ra) # 8000433c <end_op>
      if(r < 0)
    80004a8e:	fc04d8e3          	bgez	s1,80004a5e <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a92:	8552                	mv	a0,s4
    80004a94:	033a1863          	bne	s4,s3,80004ac4 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a98:	60a6                	ld	ra,72(sp)
    80004a9a:	6406                	ld	s0,64(sp)
    80004a9c:	74e2                	ld	s1,56(sp)
    80004a9e:	7942                	ld	s2,48(sp)
    80004aa0:	79a2                	ld	s3,40(sp)
    80004aa2:	7a02                	ld	s4,32(sp)
    80004aa4:	6ae2                	ld	s5,24(sp)
    80004aa6:	6b42                	ld	s6,16(sp)
    80004aa8:	6ba2                	ld	s7,8(sp)
    80004aaa:	6c02                	ld	s8,0(sp)
    80004aac:	6161                	addi	sp,sp,80
    80004aae:	8082                	ret
        panic("short filewrite");
    80004ab0:	00004517          	auipc	a0,0x4
    80004ab4:	c9850513          	addi	a0,a0,-872 # 80008748 <syscalls+0x268>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	a8a080e7          	jalr	-1398(ra) # 80000542 <panic>
    int i = 0;
    80004ac0:	4981                	li	s3,0
    80004ac2:	bfc1                	j	80004a92 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004ac4:	557d                	li	a0,-1
    80004ac6:	bfc9                	j	80004a98 <filewrite+0x10e>
    panic("filewrite");
    80004ac8:	00004517          	auipc	a0,0x4
    80004acc:	c9050513          	addi	a0,a0,-880 # 80008758 <syscalls+0x278>
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	a72080e7          	jalr	-1422(ra) # 80000542 <panic>
    return -1;
    80004ad8:	557d                	li	a0,-1
}
    80004ada:	8082                	ret
      return -1;
    80004adc:	557d                	li	a0,-1
    80004ade:	bf6d                	j	80004a98 <filewrite+0x10e>
    80004ae0:	557d                	li	a0,-1
    80004ae2:	bf5d                	j	80004a98 <filewrite+0x10e>

0000000080004ae4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ae4:	7179                	addi	sp,sp,-48
    80004ae6:	f406                	sd	ra,40(sp)
    80004ae8:	f022                	sd	s0,32(sp)
    80004aea:	ec26                	sd	s1,24(sp)
    80004aec:	e84a                	sd	s2,16(sp)
    80004aee:	e44e                	sd	s3,8(sp)
    80004af0:	e052                	sd	s4,0(sp)
    80004af2:	1800                	addi	s0,sp,48
    80004af4:	84aa                	mv	s1,a0
    80004af6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004af8:	0005b023          	sd	zero,0(a1)
    80004afc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b00:	00000097          	auipc	ra,0x0
    80004b04:	bd2080e7          	jalr	-1070(ra) # 800046d2 <filealloc>
    80004b08:	e088                	sd	a0,0(s1)
    80004b0a:	c551                	beqz	a0,80004b96 <pipealloc+0xb2>
    80004b0c:	00000097          	auipc	ra,0x0
    80004b10:	bc6080e7          	jalr	-1082(ra) # 800046d2 <filealloc>
    80004b14:	00aa3023          	sd	a0,0(s4)
    80004b18:	c92d                	beqz	a0,80004b8a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	ff4080e7          	jalr	-12(ra) # 80000b0e <kalloc>
    80004b22:	892a                	mv	s2,a0
    80004b24:	c125                	beqz	a0,80004b84 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b26:	4985                	li	s3,1
    80004b28:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b2c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b30:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b34:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b38:	00004597          	auipc	a1,0x4
    80004b3c:	c3058593          	addi	a1,a1,-976 # 80008768 <syscalls+0x288>
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	02e080e7          	jalr	46(ra) # 80000b6e <initlock>
  (*f0)->type = FD_PIPE;
    80004b48:	609c                	ld	a5,0(s1)
    80004b4a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b4e:	609c                	ld	a5,0(s1)
    80004b50:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b54:	609c                	ld	a5,0(s1)
    80004b56:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b5a:	609c                	ld	a5,0(s1)
    80004b5c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b60:	000a3783          	ld	a5,0(s4)
    80004b64:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b68:	000a3783          	ld	a5,0(s4)
    80004b6c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b70:	000a3783          	ld	a5,0(s4)
    80004b74:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b78:	000a3783          	ld	a5,0(s4)
    80004b7c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b80:	4501                	li	a0,0
    80004b82:	a025                	j	80004baa <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b84:	6088                	ld	a0,0(s1)
    80004b86:	e501                	bnez	a0,80004b8e <pipealloc+0xaa>
    80004b88:	a039                	j	80004b96 <pipealloc+0xb2>
    80004b8a:	6088                	ld	a0,0(s1)
    80004b8c:	c51d                	beqz	a0,80004bba <pipealloc+0xd6>
    fileclose(*f0);
    80004b8e:	00000097          	auipc	ra,0x0
    80004b92:	c00080e7          	jalr	-1024(ra) # 8000478e <fileclose>
  if(*f1)
    80004b96:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b9a:	557d                	li	a0,-1
  if(*f1)
    80004b9c:	c799                	beqz	a5,80004baa <pipealloc+0xc6>
    fileclose(*f1);
    80004b9e:	853e                	mv	a0,a5
    80004ba0:	00000097          	auipc	ra,0x0
    80004ba4:	bee080e7          	jalr	-1042(ra) # 8000478e <fileclose>
  return -1;
    80004ba8:	557d                	li	a0,-1
}
    80004baa:	70a2                	ld	ra,40(sp)
    80004bac:	7402                	ld	s0,32(sp)
    80004bae:	64e2                	ld	s1,24(sp)
    80004bb0:	6942                	ld	s2,16(sp)
    80004bb2:	69a2                	ld	s3,8(sp)
    80004bb4:	6a02                	ld	s4,0(sp)
    80004bb6:	6145                	addi	sp,sp,48
    80004bb8:	8082                	ret
  return -1;
    80004bba:	557d                	li	a0,-1
    80004bbc:	b7fd                	j	80004baa <pipealloc+0xc6>

0000000080004bbe <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bbe:	1101                	addi	sp,sp,-32
    80004bc0:	ec06                	sd	ra,24(sp)
    80004bc2:	e822                	sd	s0,16(sp)
    80004bc4:	e426                	sd	s1,8(sp)
    80004bc6:	e04a                	sd	s2,0(sp)
    80004bc8:	1000                	addi	s0,sp,32
    80004bca:	84aa                	mv	s1,a0
    80004bcc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	030080e7          	jalr	48(ra) # 80000bfe <acquire>
  if(writable){
    80004bd6:	02090d63          	beqz	s2,80004c10 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bda:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bde:	21848513          	addi	a0,s1,536
    80004be2:	ffffe097          	auipc	ra,0xffffe
    80004be6:	a2e080e7          	jalr	-1490(ra) # 80002610 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bea:	2204b783          	ld	a5,544(s1)
    80004bee:	eb95                	bnez	a5,80004c22 <pipeclose+0x64>
    release(&pi->lock);
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	0c0080e7          	jalr	192(ra) # 80000cb2 <release>
    kfree((char*)pi);
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	e16080e7          	jalr	-490(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004c04:	60e2                	ld	ra,24(sp)
    80004c06:	6442                	ld	s0,16(sp)
    80004c08:	64a2                	ld	s1,8(sp)
    80004c0a:	6902                	ld	s2,0(sp)
    80004c0c:	6105                	addi	sp,sp,32
    80004c0e:	8082                	ret
    pi->readopen = 0;
    80004c10:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c14:	21c48513          	addi	a0,s1,540
    80004c18:	ffffe097          	auipc	ra,0xffffe
    80004c1c:	9f8080e7          	jalr	-1544(ra) # 80002610 <wakeup>
    80004c20:	b7e9                	j	80004bea <pipeclose+0x2c>
    release(&pi->lock);
    80004c22:	8526                	mv	a0,s1
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	08e080e7          	jalr	142(ra) # 80000cb2 <release>
}
    80004c2c:	bfe1                	j	80004c04 <pipeclose+0x46>

0000000080004c2e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c2e:	711d                	addi	sp,sp,-96
    80004c30:	ec86                	sd	ra,88(sp)
    80004c32:	e8a2                	sd	s0,80(sp)
    80004c34:	e4a6                	sd	s1,72(sp)
    80004c36:	e0ca                	sd	s2,64(sp)
    80004c38:	fc4e                	sd	s3,56(sp)
    80004c3a:	f852                	sd	s4,48(sp)
    80004c3c:	f456                	sd	s5,40(sp)
    80004c3e:	f05a                	sd	s6,32(sp)
    80004c40:	ec5e                	sd	s7,24(sp)
    80004c42:	e862                	sd	s8,16(sp)
    80004c44:	1080                	addi	s0,sp,96
    80004c46:	84aa                	mv	s1,a0
    80004c48:	8b2e                	mv	s6,a1
    80004c4a:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c4c:	ffffd097          	auipc	ra,0xffffd
    80004c50:	e88080e7          	jalr	-376(ra) # 80001ad4 <myproc>
    80004c54:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c56:	8526                	mv	a0,s1
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	fa6080e7          	jalr	-90(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80004c60:	09505763          	blez	s5,80004cee <pipewrite+0xc0>
    80004c64:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c66:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c6a:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c6e:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c70:	2184a783          	lw	a5,536(s1)
    80004c74:	21c4a703          	lw	a4,540(s1)
    80004c78:	2007879b          	addiw	a5,a5,512
    80004c7c:	02f71b63          	bne	a4,a5,80004cb2 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004c80:	2204a783          	lw	a5,544(s1)
    80004c84:	c3d1                	beqz	a5,80004d08 <pipewrite+0xda>
    80004c86:	03092783          	lw	a5,48(s2)
    80004c8a:	efbd                	bnez	a5,80004d08 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004c8c:	8552                	mv	a0,s4
    80004c8e:	ffffe097          	auipc	ra,0xffffe
    80004c92:	982080e7          	jalr	-1662(ra) # 80002610 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c96:	85a6                	mv	a1,s1
    80004c98:	854e                	mv	a0,s3
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	7c4080e7          	jalr	1988(ra) # 8000245e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ca2:	2184a783          	lw	a5,536(s1)
    80004ca6:	21c4a703          	lw	a4,540(s1)
    80004caa:	2007879b          	addiw	a5,a5,512
    80004cae:	fcf709e3          	beq	a4,a5,80004c80 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cb2:	4685                	li	a3,1
    80004cb4:	865a                	mv	a2,s6
    80004cb6:	faf40593          	addi	a1,s0,-81
    80004cba:	05093503          	ld	a0,80(s2)
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	a7a080e7          	jalr	-1414(ra) # 80001738 <copyin>
    80004cc6:	03850563          	beq	a0,s8,80004cf0 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cca:	21c4a783          	lw	a5,540(s1)
    80004cce:	0017871b          	addiw	a4,a5,1
    80004cd2:	20e4ae23          	sw	a4,540(s1)
    80004cd6:	1ff7f793          	andi	a5,a5,511
    80004cda:	97a6                	add	a5,a5,s1
    80004cdc:	faf44703          	lbu	a4,-81(s0)
    80004ce0:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004ce4:	2b85                	addiw	s7,s7,1
    80004ce6:	0b05                	addi	s6,s6,1
    80004ce8:	f97a94e3          	bne	s5,s7,80004c70 <pipewrite+0x42>
    80004cec:	a011                	j	80004cf0 <pipewrite+0xc2>
    80004cee:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004cf0:	21848513          	addi	a0,s1,536
    80004cf4:	ffffe097          	auipc	ra,0xffffe
    80004cf8:	91c080e7          	jalr	-1764(ra) # 80002610 <wakeup>
  release(&pi->lock);
    80004cfc:	8526                	mv	a0,s1
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	fb4080e7          	jalr	-76(ra) # 80000cb2 <release>
  return i;
    80004d06:	a039                	j	80004d14 <pipewrite+0xe6>
        release(&pi->lock);
    80004d08:	8526                	mv	a0,s1
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	fa8080e7          	jalr	-88(ra) # 80000cb2 <release>
        return -1;
    80004d12:	5bfd                	li	s7,-1
}
    80004d14:	855e                	mv	a0,s7
    80004d16:	60e6                	ld	ra,88(sp)
    80004d18:	6446                	ld	s0,80(sp)
    80004d1a:	64a6                	ld	s1,72(sp)
    80004d1c:	6906                	ld	s2,64(sp)
    80004d1e:	79e2                	ld	s3,56(sp)
    80004d20:	7a42                	ld	s4,48(sp)
    80004d22:	7aa2                	ld	s5,40(sp)
    80004d24:	7b02                	ld	s6,32(sp)
    80004d26:	6be2                	ld	s7,24(sp)
    80004d28:	6c42                	ld	s8,16(sp)
    80004d2a:	6125                	addi	sp,sp,96
    80004d2c:	8082                	ret

0000000080004d2e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d2e:	715d                	addi	sp,sp,-80
    80004d30:	e486                	sd	ra,72(sp)
    80004d32:	e0a2                	sd	s0,64(sp)
    80004d34:	fc26                	sd	s1,56(sp)
    80004d36:	f84a                	sd	s2,48(sp)
    80004d38:	f44e                	sd	s3,40(sp)
    80004d3a:	f052                	sd	s4,32(sp)
    80004d3c:	ec56                	sd	s5,24(sp)
    80004d3e:	e85a                	sd	s6,16(sp)
    80004d40:	0880                	addi	s0,sp,80
    80004d42:	84aa                	mv	s1,a0
    80004d44:	892e                	mv	s2,a1
    80004d46:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d48:	ffffd097          	auipc	ra,0xffffd
    80004d4c:	d8c080e7          	jalr	-628(ra) # 80001ad4 <myproc>
    80004d50:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	eaa080e7          	jalr	-342(ra) # 80000bfe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d5c:	2184a703          	lw	a4,536(s1)
    80004d60:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d64:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d68:	02f71463          	bne	a4,a5,80004d90 <piperead+0x62>
    80004d6c:	2244a783          	lw	a5,548(s1)
    80004d70:	c385                	beqz	a5,80004d90 <piperead+0x62>
    if(pr->killed){
    80004d72:	030a2783          	lw	a5,48(s4)
    80004d76:	ebc1                	bnez	a5,80004e06 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d78:	85a6                	mv	a1,s1
    80004d7a:	854e                	mv	a0,s3
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	6e2080e7          	jalr	1762(ra) # 8000245e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d84:	2184a703          	lw	a4,536(s1)
    80004d88:	21c4a783          	lw	a5,540(s1)
    80004d8c:	fef700e3          	beq	a4,a5,80004d6c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d90:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d92:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d94:	05505363          	blez	s5,80004dda <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004d98:	2184a783          	lw	a5,536(s1)
    80004d9c:	21c4a703          	lw	a4,540(s1)
    80004da0:	02f70d63          	beq	a4,a5,80004dda <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004da4:	0017871b          	addiw	a4,a5,1
    80004da8:	20e4ac23          	sw	a4,536(s1)
    80004dac:	1ff7f793          	andi	a5,a5,511
    80004db0:	97a6                	add	a5,a5,s1
    80004db2:	0187c783          	lbu	a5,24(a5)
    80004db6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dba:	4685                	li	a3,1
    80004dbc:	fbf40613          	addi	a2,s0,-65
    80004dc0:	85ca                	mv	a1,s2
    80004dc2:	050a3503          	ld	a0,80(s4)
    80004dc6:	ffffd097          	auipc	ra,0xffffd
    80004dca:	8e6080e7          	jalr	-1818(ra) # 800016ac <copyout>
    80004dce:	01650663          	beq	a0,s6,80004dda <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd2:	2985                	addiw	s3,s3,1
    80004dd4:	0905                	addi	s2,s2,1
    80004dd6:	fd3a91e3          	bne	s5,s3,80004d98 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dda:	21c48513          	addi	a0,s1,540
    80004dde:	ffffe097          	auipc	ra,0xffffe
    80004de2:	832080e7          	jalr	-1998(ra) # 80002610 <wakeup>
  release(&pi->lock);
    80004de6:	8526                	mv	a0,s1
    80004de8:	ffffc097          	auipc	ra,0xffffc
    80004dec:	eca080e7          	jalr	-310(ra) # 80000cb2 <release>
  return i;
}
    80004df0:	854e                	mv	a0,s3
    80004df2:	60a6                	ld	ra,72(sp)
    80004df4:	6406                	ld	s0,64(sp)
    80004df6:	74e2                	ld	s1,56(sp)
    80004df8:	7942                	ld	s2,48(sp)
    80004dfa:	79a2                	ld	s3,40(sp)
    80004dfc:	7a02                	ld	s4,32(sp)
    80004dfe:	6ae2                	ld	s5,24(sp)
    80004e00:	6b42                	ld	s6,16(sp)
    80004e02:	6161                	addi	sp,sp,80
    80004e04:	8082                	ret
      release(&pi->lock);
    80004e06:	8526                	mv	a0,s1
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	eaa080e7          	jalr	-342(ra) # 80000cb2 <release>
      return -1;
    80004e10:	59fd                	li	s3,-1
    80004e12:	bff9                	j	80004df0 <piperead+0xc2>

0000000080004e14 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e14:	de010113          	addi	sp,sp,-544
    80004e18:	20113c23          	sd	ra,536(sp)
    80004e1c:	20813823          	sd	s0,528(sp)
    80004e20:	20913423          	sd	s1,520(sp)
    80004e24:	21213023          	sd	s2,512(sp)
    80004e28:	ffce                	sd	s3,504(sp)
    80004e2a:	fbd2                	sd	s4,496(sp)
    80004e2c:	f7d6                	sd	s5,488(sp)
    80004e2e:	f3da                	sd	s6,480(sp)
    80004e30:	efde                	sd	s7,472(sp)
    80004e32:	ebe2                	sd	s8,464(sp)
    80004e34:	e7e6                	sd	s9,456(sp)
    80004e36:	e3ea                	sd	s10,448(sp)
    80004e38:	ff6e                	sd	s11,440(sp)
    80004e3a:	1400                	addi	s0,sp,544
    80004e3c:	892a                	mv	s2,a0
    80004e3e:	dea43423          	sd	a0,-536(s0)
    80004e42:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e46:	ffffd097          	auipc	ra,0xffffd
    80004e4a:	c8e080e7          	jalr	-882(ra) # 80001ad4 <myproc>
    80004e4e:	84aa                	mv	s1,a0

  begin_op();
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	46c080e7          	jalr	1132(ra) # 800042bc <begin_op>

  if((ip = namei(path)) == 0){
    80004e58:	854a                	mv	a0,s2
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	252080e7          	jalr	594(ra) # 800040ac <namei>
    80004e62:	c93d                	beqz	a0,80004ed8 <exec+0xc4>
    80004e64:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e66:	fffff097          	auipc	ra,0xfffff
    80004e6a:	a96080e7          	jalr	-1386(ra) # 800038fc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e6e:	04000713          	li	a4,64
    80004e72:	4681                	li	a3,0
    80004e74:	e4840613          	addi	a2,s0,-440
    80004e78:	4581                	li	a1,0
    80004e7a:	8556                	mv	a0,s5
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	d34080e7          	jalr	-716(ra) # 80003bb0 <readi>
    80004e84:	04000793          	li	a5,64
    80004e88:	00f51a63          	bne	a0,a5,80004e9c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e8c:	e4842703          	lw	a4,-440(s0)
    80004e90:	464c47b7          	lui	a5,0x464c4
    80004e94:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e98:	04f70663          	beq	a4,a5,80004ee4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e9c:	8556                	mv	a0,s5
    80004e9e:	fffff097          	auipc	ra,0xfffff
    80004ea2:	cc0080e7          	jalr	-832(ra) # 80003b5e <iunlockput>
    end_op();
    80004ea6:	fffff097          	auipc	ra,0xfffff
    80004eaa:	496080e7          	jalr	1174(ra) # 8000433c <end_op>
  }
  return -1;
    80004eae:	557d                	li	a0,-1
}
    80004eb0:	21813083          	ld	ra,536(sp)
    80004eb4:	21013403          	ld	s0,528(sp)
    80004eb8:	20813483          	ld	s1,520(sp)
    80004ebc:	20013903          	ld	s2,512(sp)
    80004ec0:	79fe                	ld	s3,504(sp)
    80004ec2:	7a5e                	ld	s4,496(sp)
    80004ec4:	7abe                	ld	s5,488(sp)
    80004ec6:	7b1e                	ld	s6,480(sp)
    80004ec8:	6bfe                	ld	s7,472(sp)
    80004eca:	6c5e                	ld	s8,464(sp)
    80004ecc:	6cbe                	ld	s9,456(sp)
    80004ece:	6d1e                	ld	s10,448(sp)
    80004ed0:	7dfa                	ld	s11,440(sp)
    80004ed2:	22010113          	addi	sp,sp,544
    80004ed6:	8082                	ret
    end_op();
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	464080e7          	jalr	1124(ra) # 8000433c <end_op>
    return -1;
    80004ee0:	557d                	li	a0,-1
    80004ee2:	b7f9                	j	80004eb0 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ee4:	8526                	mv	a0,s1
    80004ee6:	ffffd097          	auipc	ra,0xffffd
    80004eea:	cb2080e7          	jalr	-846(ra) # 80001b98 <proc_pagetable>
    80004eee:	8b2a                	mv	s6,a0
    80004ef0:	d555                	beqz	a0,80004e9c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ef2:	e6842783          	lw	a5,-408(s0)
    80004ef6:	e8045703          	lhu	a4,-384(s0)
    80004efa:	c735                	beqz	a4,80004f66 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004efc:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004efe:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f02:	6a05                	lui	s4,0x1
    80004f04:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f08:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f0c:	6d85                	lui	s11,0x1
    80004f0e:	7d7d                	lui	s10,0xfffff
    80004f10:	ac1d                	j	80005146 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f12:	00004517          	auipc	a0,0x4
    80004f16:	85e50513          	addi	a0,a0,-1954 # 80008770 <syscalls+0x290>
    80004f1a:	ffffb097          	auipc	ra,0xffffb
    80004f1e:	628080e7          	jalr	1576(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f22:	874a                	mv	a4,s2
    80004f24:	009c86bb          	addw	a3,s9,s1
    80004f28:	4581                	li	a1,0
    80004f2a:	8556                	mv	a0,s5
    80004f2c:	fffff097          	auipc	ra,0xfffff
    80004f30:	c84080e7          	jalr	-892(ra) # 80003bb0 <readi>
    80004f34:	2501                	sext.w	a0,a0
    80004f36:	1aa91863          	bne	s2,a0,800050e6 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004f3a:	009d84bb          	addw	s1,s11,s1
    80004f3e:	013d09bb          	addw	s3,s10,s3
    80004f42:	1f74f263          	bgeu	s1,s7,80005126 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004f46:	02049593          	slli	a1,s1,0x20
    80004f4a:	9181                	srli	a1,a1,0x20
    80004f4c:	95e2                	add	a1,a1,s8
    80004f4e:	855a                	mv	a0,s6
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	128080e7          	jalr	296(ra) # 80001078 <walkaddr>
    80004f58:	862a                	mv	a2,a0
    if(pa == 0)
    80004f5a:	dd45                	beqz	a0,80004f12 <exec+0xfe>
      n = PGSIZE;
    80004f5c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f5e:	fd49f2e3          	bgeu	s3,s4,80004f22 <exec+0x10e>
      n = sz - i;
    80004f62:	894e                	mv	s2,s3
    80004f64:	bf7d                	j	80004f22 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f66:	4481                	li	s1,0
  iunlockput(ip);
    80004f68:	8556                	mv	a0,s5
    80004f6a:	fffff097          	auipc	ra,0xfffff
    80004f6e:	bf4080e7          	jalr	-1036(ra) # 80003b5e <iunlockput>
  end_op();
    80004f72:	fffff097          	auipc	ra,0xfffff
    80004f76:	3ca080e7          	jalr	970(ra) # 8000433c <end_op>
  p = myproc();
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	b5a080e7          	jalr	-1190(ra) # 80001ad4 <myproc>
    80004f82:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f84:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f88:	6785                	lui	a5,0x1
    80004f8a:	17fd                	addi	a5,a5,-1
    80004f8c:	94be                	add	s1,s1,a5
    80004f8e:	77fd                	lui	a5,0xfffff
    80004f90:	8fe5                	and	a5,a5,s1
    80004f92:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f96:	6609                	lui	a2,0x2
    80004f98:	963e                	add	a2,a2,a5
    80004f9a:	85be                	mv	a1,a5
    80004f9c:	855a                	mv	a0,s6
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	4be080e7          	jalr	1214(ra) # 8000145c <uvmalloc>
    80004fa6:	8c2a                	mv	s8,a0
  ip = 0;
    80004fa8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004faa:	12050e63          	beqz	a0,800050e6 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fae:	75f9                	lui	a1,0xffffe
    80004fb0:	95aa                	add	a1,a1,a0
    80004fb2:	855a                	mv	a0,s6
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	6c6080e7          	jalr	1734(ra) # 8000167a <uvmclear>
  stackbase = sp - PGSIZE;
    80004fbc:	7afd                	lui	s5,0xfffff
    80004fbe:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fc0:	df043783          	ld	a5,-528(s0)
    80004fc4:	6388                	ld	a0,0(a5)
    80004fc6:	c925                	beqz	a0,80005036 <exec+0x222>
    80004fc8:	e8840993          	addi	s3,s0,-376
    80004fcc:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004fd0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fd2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	eaa080e7          	jalr	-342(ra) # 80000e7e <strlen>
    80004fdc:	0015079b          	addiw	a5,a0,1
    80004fe0:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fe4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fe8:	13596363          	bltu	s2,s5,8000510e <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fec:	df043d83          	ld	s11,-528(s0)
    80004ff0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ff4:	8552                	mv	a0,s4
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	e88080e7          	jalr	-376(ra) # 80000e7e <strlen>
    80004ffe:	0015069b          	addiw	a3,a0,1
    80005002:	8652                	mv	a2,s4
    80005004:	85ca                	mv	a1,s2
    80005006:	855a                	mv	a0,s6
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	6a4080e7          	jalr	1700(ra) # 800016ac <copyout>
    80005010:	10054363          	bltz	a0,80005116 <exec+0x302>
    ustack[argc] = sp;
    80005014:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005018:	0485                	addi	s1,s1,1
    8000501a:	008d8793          	addi	a5,s11,8
    8000501e:	def43823          	sd	a5,-528(s0)
    80005022:	008db503          	ld	a0,8(s11)
    80005026:	c911                	beqz	a0,8000503a <exec+0x226>
    if(argc >= MAXARG)
    80005028:	09a1                	addi	s3,s3,8
    8000502a:	fb3c95e3          	bne	s9,s3,80004fd4 <exec+0x1c0>
  sz = sz1;
    8000502e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005032:	4a81                	li	s5,0
    80005034:	a84d                	j	800050e6 <exec+0x2d2>
  sp = sz;
    80005036:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005038:	4481                	li	s1,0
  ustack[argc] = 0;
    8000503a:	00349793          	slli	a5,s1,0x3
    8000503e:	f9040713          	addi	a4,s0,-112
    80005042:	97ba                	add	a5,a5,a4
    80005044:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005048:	00148693          	addi	a3,s1,1
    8000504c:	068e                	slli	a3,a3,0x3
    8000504e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005052:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005056:	01597663          	bgeu	s2,s5,80005062 <exec+0x24e>
  sz = sz1;
    8000505a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000505e:	4a81                	li	s5,0
    80005060:	a059                	j	800050e6 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005062:	e8840613          	addi	a2,s0,-376
    80005066:	85ca                	mv	a1,s2
    80005068:	855a                	mv	a0,s6
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	642080e7          	jalr	1602(ra) # 800016ac <copyout>
    80005072:	0a054663          	bltz	a0,8000511e <exec+0x30a>
  p->trapframe->a1 = sp;
    80005076:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000507a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000507e:	de843783          	ld	a5,-536(s0)
    80005082:	0007c703          	lbu	a4,0(a5)
    80005086:	cf11                	beqz	a4,800050a2 <exec+0x28e>
    80005088:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000508a:	02f00693          	li	a3,47
    8000508e:	a039                	j	8000509c <exec+0x288>
      last = s+1;
    80005090:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005094:	0785                	addi	a5,a5,1
    80005096:	fff7c703          	lbu	a4,-1(a5)
    8000509a:	c701                	beqz	a4,800050a2 <exec+0x28e>
    if(*s == '/')
    8000509c:	fed71ce3          	bne	a4,a3,80005094 <exec+0x280>
    800050a0:	bfc5                	j	80005090 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800050a2:	4641                	li	a2,16
    800050a4:	de843583          	ld	a1,-536(s0)
    800050a8:	158b8513          	addi	a0,s7,344
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	da0080e7          	jalr	-608(ra) # 80000e4c <safestrcpy>
  oldpagetable = p->pagetable;
    800050b4:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050b8:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050bc:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050c0:	058bb783          	ld	a5,88(s7)
    800050c4:	e6043703          	ld	a4,-416(s0)
    800050c8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050ca:	058bb783          	ld	a5,88(s7)
    800050ce:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050d2:	85ea                	mv	a1,s10
    800050d4:	ffffd097          	auipc	ra,0xffffd
    800050d8:	b60080e7          	jalr	-1184(ra) # 80001c34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050dc:	0004851b          	sext.w	a0,s1
    800050e0:	bbc1                	j	80004eb0 <exec+0x9c>
    800050e2:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050e6:	df843583          	ld	a1,-520(s0)
    800050ea:	855a                	mv	a0,s6
    800050ec:	ffffd097          	auipc	ra,0xffffd
    800050f0:	b48080e7          	jalr	-1208(ra) # 80001c34 <proc_freepagetable>
  if(ip){
    800050f4:	da0a94e3          	bnez	s5,80004e9c <exec+0x88>
  return -1;
    800050f8:	557d                	li	a0,-1
    800050fa:	bb5d                	j	80004eb0 <exec+0x9c>
    800050fc:	de943c23          	sd	s1,-520(s0)
    80005100:	b7dd                	j	800050e6 <exec+0x2d2>
    80005102:	de943c23          	sd	s1,-520(s0)
    80005106:	b7c5                	j	800050e6 <exec+0x2d2>
    80005108:	de943c23          	sd	s1,-520(s0)
    8000510c:	bfe9                	j	800050e6 <exec+0x2d2>
  sz = sz1;
    8000510e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005112:	4a81                	li	s5,0
    80005114:	bfc9                	j	800050e6 <exec+0x2d2>
  sz = sz1;
    80005116:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000511a:	4a81                	li	s5,0
    8000511c:	b7e9                	j	800050e6 <exec+0x2d2>
  sz = sz1;
    8000511e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005122:	4a81                	li	s5,0
    80005124:	b7c9                	j	800050e6 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005126:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000512a:	e0843783          	ld	a5,-504(s0)
    8000512e:	0017869b          	addiw	a3,a5,1
    80005132:	e0d43423          	sd	a3,-504(s0)
    80005136:	e0043783          	ld	a5,-512(s0)
    8000513a:	0387879b          	addiw	a5,a5,56
    8000513e:	e8045703          	lhu	a4,-384(s0)
    80005142:	e2e6d3e3          	bge	a3,a4,80004f68 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005146:	2781                	sext.w	a5,a5
    80005148:	e0f43023          	sd	a5,-512(s0)
    8000514c:	03800713          	li	a4,56
    80005150:	86be                	mv	a3,a5
    80005152:	e1040613          	addi	a2,s0,-496
    80005156:	4581                	li	a1,0
    80005158:	8556                	mv	a0,s5
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	a56080e7          	jalr	-1450(ra) # 80003bb0 <readi>
    80005162:	03800793          	li	a5,56
    80005166:	f6f51ee3          	bne	a0,a5,800050e2 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000516a:	e1042783          	lw	a5,-496(s0)
    8000516e:	4705                	li	a4,1
    80005170:	fae79de3          	bne	a5,a4,8000512a <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005174:	e3843603          	ld	a2,-456(s0)
    80005178:	e3043783          	ld	a5,-464(s0)
    8000517c:	f8f660e3          	bltu	a2,a5,800050fc <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005180:	e2043783          	ld	a5,-480(s0)
    80005184:	963e                	add	a2,a2,a5
    80005186:	f6f66ee3          	bltu	a2,a5,80005102 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000518a:	85a6                	mv	a1,s1
    8000518c:	855a                	mv	a0,s6
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	2ce080e7          	jalr	718(ra) # 8000145c <uvmalloc>
    80005196:	dea43c23          	sd	a0,-520(s0)
    8000519a:	d53d                	beqz	a0,80005108 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000519c:	e2043c03          	ld	s8,-480(s0)
    800051a0:	de043783          	ld	a5,-544(s0)
    800051a4:	00fc77b3          	and	a5,s8,a5
    800051a8:	ff9d                	bnez	a5,800050e6 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051aa:	e1842c83          	lw	s9,-488(s0)
    800051ae:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051b2:	f60b8ae3          	beqz	s7,80005126 <exec+0x312>
    800051b6:	89de                	mv	s3,s7
    800051b8:	4481                	li	s1,0
    800051ba:	b371                	j	80004f46 <exec+0x132>

00000000800051bc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051bc:	7179                	addi	sp,sp,-48
    800051be:	f406                	sd	ra,40(sp)
    800051c0:	f022                	sd	s0,32(sp)
    800051c2:	ec26                	sd	s1,24(sp)
    800051c4:	e84a                	sd	s2,16(sp)
    800051c6:	1800                	addi	s0,sp,48
    800051c8:	892e                	mv	s2,a1
    800051ca:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051cc:	fdc40593          	addi	a1,s0,-36
    800051d0:	ffffe097          	auipc	ra,0xffffe
    800051d4:	bba080e7          	jalr	-1094(ra) # 80002d8a <argint>
    800051d8:	04054063          	bltz	a0,80005218 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051dc:	fdc42703          	lw	a4,-36(s0)
    800051e0:	47bd                	li	a5,15
    800051e2:	02e7ed63          	bltu	a5,a4,8000521c <argfd+0x60>
    800051e6:	ffffd097          	auipc	ra,0xffffd
    800051ea:	8ee080e7          	jalr	-1810(ra) # 80001ad4 <myproc>
    800051ee:	fdc42703          	lw	a4,-36(s0)
    800051f2:	01a70793          	addi	a5,a4,26
    800051f6:	078e                	slli	a5,a5,0x3
    800051f8:	953e                	add	a0,a0,a5
    800051fa:	611c                	ld	a5,0(a0)
    800051fc:	c395                	beqz	a5,80005220 <argfd+0x64>
    return -1;
  if(pfd)
    800051fe:	00090463          	beqz	s2,80005206 <argfd+0x4a>
    *pfd = fd;
    80005202:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005206:	4501                	li	a0,0
  if(pf)
    80005208:	c091                	beqz	s1,8000520c <argfd+0x50>
    *pf = f;
    8000520a:	e09c                	sd	a5,0(s1)
}
    8000520c:	70a2                	ld	ra,40(sp)
    8000520e:	7402                	ld	s0,32(sp)
    80005210:	64e2                	ld	s1,24(sp)
    80005212:	6942                	ld	s2,16(sp)
    80005214:	6145                	addi	sp,sp,48
    80005216:	8082                	ret
    return -1;
    80005218:	557d                	li	a0,-1
    8000521a:	bfcd                	j	8000520c <argfd+0x50>
    return -1;
    8000521c:	557d                	li	a0,-1
    8000521e:	b7fd                	j	8000520c <argfd+0x50>
    80005220:	557d                	li	a0,-1
    80005222:	b7ed                	j	8000520c <argfd+0x50>

0000000080005224 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005224:	1101                	addi	sp,sp,-32
    80005226:	ec06                	sd	ra,24(sp)
    80005228:	e822                	sd	s0,16(sp)
    8000522a:	e426                	sd	s1,8(sp)
    8000522c:	1000                	addi	s0,sp,32
    8000522e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005230:	ffffd097          	auipc	ra,0xffffd
    80005234:	8a4080e7          	jalr	-1884(ra) # 80001ad4 <myproc>
    80005238:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000523a:	0d050793          	addi	a5,a0,208
    8000523e:	4501                	li	a0,0
    80005240:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005242:	6398                	ld	a4,0(a5)
    80005244:	cb19                	beqz	a4,8000525a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005246:	2505                	addiw	a0,a0,1
    80005248:	07a1                	addi	a5,a5,8
    8000524a:	fed51ce3          	bne	a0,a3,80005242 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000524e:	557d                	li	a0,-1
}
    80005250:	60e2                	ld	ra,24(sp)
    80005252:	6442                	ld	s0,16(sp)
    80005254:	64a2                	ld	s1,8(sp)
    80005256:	6105                	addi	sp,sp,32
    80005258:	8082                	ret
      p->ofile[fd] = f;
    8000525a:	01a50793          	addi	a5,a0,26
    8000525e:	078e                	slli	a5,a5,0x3
    80005260:	963e                	add	a2,a2,a5
    80005262:	e204                	sd	s1,0(a2)
      return fd;
    80005264:	b7f5                	j	80005250 <fdalloc+0x2c>

0000000080005266 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005266:	715d                	addi	sp,sp,-80
    80005268:	e486                	sd	ra,72(sp)
    8000526a:	e0a2                	sd	s0,64(sp)
    8000526c:	fc26                	sd	s1,56(sp)
    8000526e:	f84a                	sd	s2,48(sp)
    80005270:	f44e                	sd	s3,40(sp)
    80005272:	f052                	sd	s4,32(sp)
    80005274:	ec56                	sd	s5,24(sp)
    80005276:	0880                	addi	s0,sp,80
    80005278:	89ae                	mv	s3,a1
    8000527a:	8ab2                	mv	s5,a2
    8000527c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000527e:	fb040593          	addi	a1,s0,-80
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	e48080e7          	jalr	-440(ra) # 800040ca <nameiparent>
    8000528a:	892a                	mv	s2,a0
    8000528c:	12050e63          	beqz	a0,800053c8 <create+0x162>
    return 0;

  ilock(dp);
    80005290:	ffffe097          	auipc	ra,0xffffe
    80005294:	66c080e7          	jalr	1644(ra) # 800038fc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005298:	4601                	li	a2,0
    8000529a:	fb040593          	addi	a1,s0,-80
    8000529e:	854a                	mv	a0,s2
    800052a0:	fffff097          	auipc	ra,0xfffff
    800052a4:	b3a080e7          	jalr	-1222(ra) # 80003dda <dirlookup>
    800052a8:	84aa                	mv	s1,a0
    800052aa:	c921                	beqz	a0,800052fa <create+0x94>
    iunlockput(dp);
    800052ac:	854a                	mv	a0,s2
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	8b0080e7          	jalr	-1872(ra) # 80003b5e <iunlockput>
    ilock(ip);
    800052b6:	8526                	mv	a0,s1
    800052b8:	ffffe097          	auipc	ra,0xffffe
    800052bc:	644080e7          	jalr	1604(ra) # 800038fc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052c0:	2981                	sext.w	s3,s3
    800052c2:	4789                	li	a5,2
    800052c4:	02f99463          	bne	s3,a5,800052ec <create+0x86>
    800052c8:	0444d783          	lhu	a5,68(s1)
    800052cc:	37f9                	addiw	a5,a5,-2
    800052ce:	17c2                	slli	a5,a5,0x30
    800052d0:	93c1                	srli	a5,a5,0x30
    800052d2:	4705                	li	a4,1
    800052d4:	00f76c63          	bltu	a4,a5,800052ec <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052d8:	8526                	mv	a0,s1
    800052da:	60a6                	ld	ra,72(sp)
    800052dc:	6406                	ld	s0,64(sp)
    800052de:	74e2                	ld	s1,56(sp)
    800052e0:	7942                	ld	s2,48(sp)
    800052e2:	79a2                	ld	s3,40(sp)
    800052e4:	7a02                	ld	s4,32(sp)
    800052e6:	6ae2                	ld	s5,24(sp)
    800052e8:	6161                	addi	sp,sp,80
    800052ea:	8082                	ret
    iunlockput(ip);
    800052ec:	8526                	mv	a0,s1
    800052ee:	fffff097          	auipc	ra,0xfffff
    800052f2:	870080e7          	jalr	-1936(ra) # 80003b5e <iunlockput>
    return 0;
    800052f6:	4481                	li	s1,0
    800052f8:	b7c5                	j	800052d8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052fa:	85ce                	mv	a1,s3
    800052fc:	00092503          	lw	a0,0(s2)
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	464080e7          	jalr	1124(ra) # 80003764 <ialloc>
    80005308:	84aa                	mv	s1,a0
    8000530a:	c521                	beqz	a0,80005352 <create+0xec>
  ilock(ip);
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	5f0080e7          	jalr	1520(ra) # 800038fc <ilock>
  ip->major = major;
    80005314:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005318:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000531c:	4a05                	li	s4,1
    8000531e:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005322:	8526                	mv	a0,s1
    80005324:	ffffe097          	auipc	ra,0xffffe
    80005328:	50e080e7          	jalr	1294(ra) # 80003832 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000532c:	2981                	sext.w	s3,s3
    8000532e:	03498a63          	beq	s3,s4,80005362 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005332:	40d0                	lw	a2,4(s1)
    80005334:	fb040593          	addi	a1,s0,-80
    80005338:	854a                	mv	a0,s2
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	cb0080e7          	jalr	-848(ra) # 80003fea <dirlink>
    80005342:	06054b63          	bltz	a0,800053b8 <create+0x152>
  iunlockput(dp);
    80005346:	854a                	mv	a0,s2
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	816080e7          	jalr	-2026(ra) # 80003b5e <iunlockput>
  return ip;
    80005350:	b761                	j	800052d8 <create+0x72>
    panic("create: ialloc");
    80005352:	00003517          	auipc	a0,0x3
    80005356:	43e50513          	addi	a0,a0,1086 # 80008790 <syscalls+0x2b0>
    8000535a:	ffffb097          	auipc	ra,0xffffb
    8000535e:	1e8080e7          	jalr	488(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    80005362:	04a95783          	lhu	a5,74(s2)
    80005366:	2785                	addiw	a5,a5,1
    80005368:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000536c:	854a                	mv	a0,s2
    8000536e:	ffffe097          	auipc	ra,0xffffe
    80005372:	4c4080e7          	jalr	1220(ra) # 80003832 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005376:	40d0                	lw	a2,4(s1)
    80005378:	00003597          	auipc	a1,0x3
    8000537c:	42858593          	addi	a1,a1,1064 # 800087a0 <syscalls+0x2c0>
    80005380:	8526                	mv	a0,s1
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	c68080e7          	jalr	-920(ra) # 80003fea <dirlink>
    8000538a:	00054f63          	bltz	a0,800053a8 <create+0x142>
    8000538e:	00492603          	lw	a2,4(s2)
    80005392:	00003597          	auipc	a1,0x3
    80005396:	41658593          	addi	a1,a1,1046 # 800087a8 <syscalls+0x2c8>
    8000539a:	8526                	mv	a0,s1
    8000539c:	fffff097          	auipc	ra,0xfffff
    800053a0:	c4e080e7          	jalr	-946(ra) # 80003fea <dirlink>
    800053a4:	f80557e3          	bgez	a0,80005332 <create+0xcc>
      panic("create dots");
    800053a8:	00003517          	auipc	a0,0x3
    800053ac:	40850513          	addi	a0,a0,1032 # 800087b0 <syscalls+0x2d0>
    800053b0:	ffffb097          	auipc	ra,0xffffb
    800053b4:	192080e7          	jalr	402(ra) # 80000542 <panic>
    panic("create: dirlink");
    800053b8:	00003517          	auipc	a0,0x3
    800053bc:	40850513          	addi	a0,a0,1032 # 800087c0 <syscalls+0x2e0>
    800053c0:	ffffb097          	auipc	ra,0xffffb
    800053c4:	182080e7          	jalr	386(ra) # 80000542 <panic>
    return 0;
    800053c8:	84aa                	mv	s1,a0
    800053ca:	b739                	j	800052d8 <create+0x72>

00000000800053cc <sys_dup>:
{
    800053cc:	7179                	addi	sp,sp,-48
    800053ce:	f406                	sd	ra,40(sp)
    800053d0:	f022                	sd	s0,32(sp)
    800053d2:	ec26                	sd	s1,24(sp)
    800053d4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053d6:	fd840613          	addi	a2,s0,-40
    800053da:	4581                	li	a1,0
    800053dc:	4501                	li	a0,0
    800053de:	00000097          	auipc	ra,0x0
    800053e2:	dde080e7          	jalr	-546(ra) # 800051bc <argfd>
    return -1;
    800053e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053e8:	02054363          	bltz	a0,8000540e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053ec:	fd843503          	ld	a0,-40(s0)
    800053f0:	00000097          	auipc	ra,0x0
    800053f4:	e34080e7          	jalr	-460(ra) # 80005224 <fdalloc>
    800053f8:	84aa                	mv	s1,a0
    return -1;
    800053fa:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053fc:	00054963          	bltz	a0,8000540e <sys_dup+0x42>
  filedup(f);
    80005400:	fd843503          	ld	a0,-40(s0)
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	338080e7          	jalr	824(ra) # 8000473c <filedup>
  return fd;
    8000540c:	87a6                	mv	a5,s1
}
    8000540e:	853e                	mv	a0,a5
    80005410:	70a2                	ld	ra,40(sp)
    80005412:	7402                	ld	s0,32(sp)
    80005414:	64e2                	ld	s1,24(sp)
    80005416:	6145                	addi	sp,sp,48
    80005418:	8082                	ret

000000008000541a <sys_read>:
{
    8000541a:	7179                	addi	sp,sp,-48
    8000541c:	f406                	sd	ra,40(sp)
    8000541e:	f022                	sd	s0,32(sp)
    80005420:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005422:	fe840613          	addi	a2,s0,-24
    80005426:	4581                	li	a1,0
    80005428:	4501                	li	a0,0
    8000542a:	00000097          	auipc	ra,0x0
    8000542e:	d92080e7          	jalr	-622(ra) # 800051bc <argfd>
    return -1;
    80005432:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005434:	04054163          	bltz	a0,80005476 <sys_read+0x5c>
    80005438:	fe440593          	addi	a1,s0,-28
    8000543c:	4509                	li	a0,2
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	94c080e7          	jalr	-1716(ra) # 80002d8a <argint>
    return -1;
    80005446:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005448:	02054763          	bltz	a0,80005476 <sys_read+0x5c>
    8000544c:	fd840593          	addi	a1,s0,-40
    80005450:	4505                	li	a0,1
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	95a080e7          	jalr	-1702(ra) # 80002dac <argaddr>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545c:	00054d63          	bltz	a0,80005476 <sys_read+0x5c>
  return fileread(f, p, n);
    80005460:	fe442603          	lw	a2,-28(s0)
    80005464:	fd843583          	ld	a1,-40(s0)
    80005468:	fe843503          	ld	a0,-24(s0)
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	45c080e7          	jalr	1116(ra) # 800048c8 <fileread>
    80005474:	87aa                	mv	a5,a0
}
    80005476:	853e                	mv	a0,a5
    80005478:	70a2                	ld	ra,40(sp)
    8000547a:	7402                	ld	s0,32(sp)
    8000547c:	6145                	addi	sp,sp,48
    8000547e:	8082                	ret

0000000080005480 <sys_write>:
{
    80005480:	7179                	addi	sp,sp,-48
    80005482:	f406                	sd	ra,40(sp)
    80005484:	f022                	sd	s0,32(sp)
    80005486:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005488:	fe840613          	addi	a2,s0,-24
    8000548c:	4581                	li	a1,0
    8000548e:	4501                	li	a0,0
    80005490:	00000097          	auipc	ra,0x0
    80005494:	d2c080e7          	jalr	-724(ra) # 800051bc <argfd>
    return -1;
    80005498:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000549a:	04054163          	bltz	a0,800054dc <sys_write+0x5c>
    8000549e:	fe440593          	addi	a1,s0,-28
    800054a2:	4509                	li	a0,2
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	8e6080e7          	jalr	-1818(ra) # 80002d8a <argint>
    return -1;
    800054ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ae:	02054763          	bltz	a0,800054dc <sys_write+0x5c>
    800054b2:	fd840593          	addi	a1,s0,-40
    800054b6:	4505                	li	a0,1
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	8f4080e7          	jalr	-1804(ra) # 80002dac <argaddr>
    return -1;
    800054c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c2:	00054d63          	bltz	a0,800054dc <sys_write+0x5c>
  return filewrite(f, p, n);
    800054c6:	fe442603          	lw	a2,-28(s0)
    800054ca:	fd843583          	ld	a1,-40(s0)
    800054ce:	fe843503          	ld	a0,-24(s0)
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	4b8080e7          	jalr	1208(ra) # 8000498a <filewrite>
    800054da:	87aa                	mv	a5,a0
}
    800054dc:	853e                	mv	a0,a5
    800054de:	70a2                	ld	ra,40(sp)
    800054e0:	7402                	ld	s0,32(sp)
    800054e2:	6145                	addi	sp,sp,48
    800054e4:	8082                	ret

00000000800054e6 <sys_close>:
{
    800054e6:	1101                	addi	sp,sp,-32
    800054e8:	ec06                	sd	ra,24(sp)
    800054ea:	e822                	sd	s0,16(sp)
    800054ec:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054ee:	fe040613          	addi	a2,s0,-32
    800054f2:	fec40593          	addi	a1,s0,-20
    800054f6:	4501                	li	a0,0
    800054f8:	00000097          	auipc	ra,0x0
    800054fc:	cc4080e7          	jalr	-828(ra) # 800051bc <argfd>
    return -1;
    80005500:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005502:	02054463          	bltz	a0,8000552a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005506:	ffffc097          	auipc	ra,0xffffc
    8000550a:	5ce080e7          	jalr	1486(ra) # 80001ad4 <myproc>
    8000550e:	fec42783          	lw	a5,-20(s0)
    80005512:	07e9                	addi	a5,a5,26
    80005514:	078e                	slli	a5,a5,0x3
    80005516:	97aa                	add	a5,a5,a0
    80005518:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000551c:	fe043503          	ld	a0,-32(s0)
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	26e080e7          	jalr	622(ra) # 8000478e <fileclose>
  return 0;
    80005528:	4781                	li	a5,0
}
    8000552a:	853e                	mv	a0,a5
    8000552c:	60e2                	ld	ra,24(sp)
    8000552e:	6442                	ld	s0,16(sp)
    80005530:	6105                	addi	sp,sp,32
    80005532:	8082                	ret

0000000080005534 <sys_fstat>:
{
    80005534:	1101                	addi	sp,sp,-32
    80005536:	ec06                	sd	ra,24(sp)
    80005538:	e822                	sd	s0,16(sp)
    8000553a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000553c:	fe840613          	addi	a2,s0,-24
    80005540:	4581                	li	a1,0
    80005542:	4501                	li	a0,0
    80005544:	00000097          	auipc	ra,0x0
    80005548:	c78080e7          	jalr	-904(ra) # 800051bc <argfd>
    return -1;
    8000554c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000554e:	02054563          	bltz	a0,80005578 <sys_fstat+0x44>
    80005552:	fe040593          	addi	a1,s0,-32
    80005556:	4505                	li	a0,1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	854080e7          	jalr	-1964(ra) # 80002dac <argaddr>
    return -1;
    80005560:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005562:	00054b63          	bltz	a0,80005578 <sys_fstat+0x44>
  return filestat(f, st);
    80005566:	fe043583          	ld	a1,-32(s0)
    8000556a:	fe843503          	ld	a0,-24(s0)
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	2e8080e7          	jalr	744(ra) # 80004856 <filestat>
    80005576:	87aa                	mv	a5,a0
}
    80005578:	853e                	mv	a0,a5
    8000557a:	60e2                	ld	ra,24(sp)
    8000557c:	6442                	ld	s0,16(sp)
    8000557e:	6105                	addi	sp,sp,32
    80005580:	8082                	ret

0000000080005582 <sys_link>:
{
    80005582:	7169                	addi	sp,sp,-304
    80005584:	f606                	sd	ra,296(sp)
    80005586:	f222                	sd	s0,288(sp)
    80005588:	ee26                	sd	s1,280(sp)
    8000558a:	ea4a                	sd	s2,272(sp)
    8000558c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000558e:	08000613          	li	a2,128
    80005592:	ed040593          	addi	a1,s0,-304
    80005596:	4501                	li	a0,0
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	836080e7          	jalr	-1994(ra) # 80002dce <argstr>
    return -1;
    800055a0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055a2:	10054e63          	bltz	a0,800056be <sys_link+0x13c>
    800055a6:	08000613          	li	a2,128
    800055aa:	f5040593          	addi	a1,s0,-176
    800055ae:	4505                	li	a0,1
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	81e080e7          	jalr	-2018(ra) # 80002dce <argstr>
    return -1;
    800055b8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ba:	10054263          	bltz	a0,800056be <sys_link+0x13c>
  begin_op();
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	cfe080e7          	jalr	-770(ra) # 800042bc <begin_op>
  if((ip = namei(old)) == 0){
    800055c6:	ed040513          	addi	a0,s0,-304
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	ae2080e7          	jalr	-1310(ra) # 800040ac <namei>
    800055d2:	84aa                	mv	s1,a0
    800055d4:	c551                	beqz	a0,80005660 <sys_link+0xde>
  ilock(ip);
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	326080e7          	jalr	806(ra) # 800038fc <ilock>
  if(ip->type == T_DIR){
    800055de:	04449703          	lh	a4,68(s1)
    800055e2:	4785                	li	a5,1
    800055e4:	08f70463          	beq	a4,a5,8000566c <sys_link+0xea>
  ip->nlink++;
    800055e8:	04a4d783          	lhu	a5,74(s1)
    800055ec:	2785                	addiw	a5,a5,1
    800055ee:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	23e080e7          	jalr	574(ra) # 80003832 <iupdate>
  iunlock(ip);
    800055fc:	8526                	mv	a0,s1
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	3c0080e7          	jalr	960(ra) # 800039be <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005606:	fd040593          	addi	a1,s0,-48
    8000560a:	f5040513          	addi	a0,s0,-176
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	abc080e7          	jalr	-1348(ra) # 800040ca <nameiparent>
    80005616:	892a                	mv	s2,a0
    80005618:	c935                	beqz	a0,8000568c <sys_link+0x10a>
  ilock(dp);
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	2e2080e7          	jalr	738(ra) # 800038fc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005622:	00092703          	lw	a4,0(s2)
    80005626:	409c                	lw	a5,0(s1)
    80005628:	04f71d63          	bne	a4,a5,80005682 <sys_link+0x100>
    8000562c:	40d0                	lw	a2,4(s1)
    8000562e:	fd040593          	addi	a1,s0,-48
    80005632:	854a                	mv	a0,s2
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	9b6080e7          	jalr	-1610(ra) # 80003fea <dirlink>
    8000563c:	04054363          	bltz	a0,80005682 <sys_link+0x100>
  iunlockput(dp);
    80005640:	854a                	mv	a0,s2
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	51c080e7          	jalr	1308(ra) # 80003b5e <iunlockput>
  iput(ip);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	46a080e7          	jalr	1130(ra) # 80003ab6 <iput>
  end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	ce8080e7          	jalr	-792(ra) # 8000433c <end_op>
  return 0;
    8000565c:	4781                	li	a5,0
    8000565e:	a085                	j	800056be <sys_link+0x13c>
    end_op();
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	cdc080e7          	jalr	-804(ra) # 8000433c <end_op>
    return -1;
    80005668:	57fd                	li	a5,-1
    8000566a:	a891                	j	800056be <sys_link+0x13c>
    iunlockput(ip);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	4f0080e7          	jalr	1264(ra) # 80003b5e <iunlockput>
    end_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	cc6080e7          	jalr	-826(ra) # 8000433c <end_op>
    return -1;
    8000567e:	57fd                	li	a5,-1
    80005680:	a83d                	j	800056be <sys_link+0x13c>
    iunlockput(dp);
    80005682:	854a                	mv	a0,s2
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	4da080e7          	jalr	1242(ra) # 80003b5e <iunlockput>
  ilock(ip);
    8000568c:	8526                	mv	a0,s1
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	26e080e7          	jalr	622(ra) # 800038fc <ilock>
  ip->nlink--;
    80005696:	04a4d783          	lhu	a5,74(s1)
    8000569a:	37fd                	addiw	a5,a5,-1
    8000569c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	190080e7          	jalr	400(ra) # 80003832 <iupdate>
  iunlockput(ip);
    800056aa:	8526                	mv	a0,s1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	4b2080e7          	jalr	1202(ra) # 80003b5e <iunlockput>
  end_op();
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	c88080e7          	jalr	-888(ra) # 8000433c <end_op>
  return -1;
    800056bc:	57fd                	li	a5,-1
}
    800056be:	853e                	mv	a0,a5
    800056c0:	70b2                	ld	ra,296(sp)
    800056c2:	7412                	ld	s0,288(sp)
    800056c4:	64f2                	ld	s1,280(sp)
    800056c6:	6952                	ld	s2,272(sp)
    800056c8:	6155                	addi	sp,sp,304
    800056ca:	8082                	ret

00000000800056cc <sys_unlink>:
{
    800056cc:	7151                	addi	sp,sp,-240
    800056ce:	f586                	sd	ra,232(sp)
    800056d0:	f1a2                	sd	s0,224(sp)
    800056d2:	eda6                	sd	s1,216(sp)
    800056d4:	e9ca                	sd	s2,208(sp)
    800056d6:	e5ce                	sd	s3,200(sp)
    800056d8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056da:	08000613          	li	a2,128
    800056de:	f3040593          	addi	a1,s0,-208
    800056e2:	4501                	li	a0,0
    800056e4:	ffffd097          	auipc	ra,0xffffd
    800056e8:	6ea080e7          	jalr	1770(ra) # 80002dce <argstr>
    800056ec:	18054163          	bltz	a0,8000586e <sys_unlink+0x1a2>
  begin_op();
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	bcc080e7          	jalr	-1076(ra) # 800042bc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056f8:	fb040593          	addi	a1,s0,-80
    800056fc:	f3040513          	addi	a0,s0,-208
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	9ca080e7          	jalr	-1590(ra) # 800040ca <nameiparent>
    80005708:	84aa                	mv	s1,a0
    8000570a:	c979                	beqz	a0,800057e0 <sys_unlink+0x114>
  ilock(dp);
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	1f0080e7          	jalr	496(ra) # 800038fc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005714:	00003597          	auipc	a1,0x3
    80005718:	08c58593          	addi	a1,a1,140 # 800087a0 <syscalls+0x2c0>
    8000571c:	fb040513          	addi	a0,s0,-80
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	6a0080e7          	jalr	1696(ra) # 80003dc0 <namecmp>
    80005728:	14050a63          	beqz	a0,8000587c <sys_unlink+0x1b0>
    8000572c:	00003597          	auipc	a1,0x3
    80005730:	07c58593          	addi	a1,a1,124 # 800087a8 <syscalls+0x2c8>
    80005734:	fb040513          	addi	a0,s0,-80
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	688080e7          	jalr	1672(ra) # 80003dc0 <namecmp>
    80005740:	12050e63          	beqz	a0,8000587c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005744:	f2c40613          	addi	a2,s0,-212
    80005748:	fb040593          	addi	a1,s0,-80
    8000574c:	8526                	mv	a0,s1
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	68c080e7          	jalr	1676(ra) # 80003dda <dirlookup>
    80005756:	892a                	mv	s2,a0
    80005758:	12050263          	beqz	a0,8000587c <sys_unlink+0x1b0>
  ilock(ip);
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	1a0080e7          	jalr	416(ra) # 800038fc <ilock>
  if(ip->nlink < 1)
    80005764:	04a91783          	lh	a5,74(s2)
    80005768:	08f05263          	blez	a5,800057ec <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000576c:	04491703          	lh	a4,68(s2)
    80005770:	4785                	li	a5,1
    80005772:	08f70563          	beq	a4,a5,800057fc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005776:	4641                	li	a2,16
    80005778:	4581                	li	a1,0
    8000577a:	fc040513          	addi	a0,s0,-64
    8000577e:	ffffb097          	auipc	ra,0xffffb
    80005782:	57c080e7          	jalr	1404(ra) # 80000cfa <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005786:	4741                	li	a4,16
    80005788:	f2c42683          	lw	a3,-212(s0)
    8000578c:	fc040613          	addi	a2,s0,-64
    80005790:	4581                	li	a1,0
    80005792:	8526                	mv	a0,s1
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	512080e7          	jalr	1298(ra) # 80003ca6 <writei>
    8000579c:	47c1                	li	a5,16
    8000579e:	0af51563          	bne	a0,a5,80005848 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057a2:	04491703          	lh	a4,68(s2)
    800057a6:	4785                	li	a5,1
    800057a8:	0af70863          	beq	a4,a5,80005858 <sys_unlink+0x18c>
  iunlockput(dp);
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	3b0080e7          	jalr	944(ra) # 80003b5e <iunlockput>
  ip->nlink--;
    800057b6:	04a95783          	lhu	a5,74(s2)
    800057ba:	37fd                	addiw	a5,a5,-1
    800057bc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057c0:	854a                	mv	a0,s2
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	070080e7          	jalr	112(ra) # 80003832 <iupdate>
  iunlockput(ip);
    800057ca:	854a                	mv	a0,s2
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	392080e7          	jalr	914(ra) # 80003b5e <iunlockput>
  end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	b68080e7          	jalr	-1176(ra) # 8000433c <end_op>
  return 0;
    800057dc:	4501                	li	a0,0
    800057de:	a84d                	j	80005890 <sys_unlink+0x1c4>
    end_op();
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	b5c080e7          	jalr	-1188(ra) # 8000433c <end_op>
    return -1;
    800057e8:	557d                	li	a0,-1
    800057ea:	a05d                	j	80005890 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057ec:	00003517          	auipc	a0,0x3
    800057f0:	fe450513          	addi	a0,a0,-28 # 800087d0 <syscalls+0x2f0>
    800057f4:	ffffb097          	auipc	ra,0xffffb
    800057f8:	d4e080e7          	jalr	-690(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057fc:	04c92703          	lw	a4,76(s2)
    80005800:	02000793          	li	a5,32
    80005804:	f6e7f9e3          	bgeu	a5,a4,80005776 <sys_unlink+0xaa>
    80005808:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000580c:	4741                	li	a4,16
    8000580e:	86ce                	mv	a3,s3
    80005810:	f1840613          	addi	a2,s0,-232
    80005814:	4581                	li	a1,0
    80005816:	854a                	mv	a0,s2
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	398080e7          	jalr	920(ra) # 80003bb0 <readi>
    80005820:	47c1                	li	a5,16
    80005822:	00f51b63          	bne	a0,a5,80005838 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005826:	f1845783          	lhu	a5,-232(s0)
    8000582a:	e7a1                	bnez	a5,80005872 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000582c:	29c1                	addiw	s3,s3,16
    8000582e:	04c92783          	lw	a5,76(s2)
    80005832:	fcf9ede3          	bltu	s3,a5,8000580c <sys_unlink+0x140>
    80005836:	b781                	j	80005776 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005838:	00003517          	auipc	a0,0x3
    8000583c:	fb050513          	addi	a0,a0,-80 # 800087e8 <syscalls+0x308>
    80005840:	ffffb097          	auipc	ra,0xffffb
    80005844:	d02080e7          	jalr	-766(ra) # 80000542 <panic>
    panic("unlink: writei");
    80005848:	00003517          	auipc	a0,0x3
    8000584c:	fb850513          	addi	a0,a0,-72 # 80008800 <syscalls+0x320>
    80005850:	ffffb097          	auipc	ra,0xffffb
    80005854:	cf2080e7          	jalr	-782(ra) # 80000542 <panic>
    dp->nlink--;
    80005858:	04a4d783          	lhu	a5,74(s1)
    8000585c:	37fd                	addiw	a5,a5,-1
    8000585e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005862:	8526                	mv	a0,s1
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	fce080e7          	jalr	-50(ra) # 80003832 <iupdate>
    8000586c:	b781                	j	800057ac <sys_unlink+0xe0>
    return -1;
    8000586e:	557d                	li	a0,-1
    80005870:	a005                	j	80005890 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005872:	854a                	mv	a0,s2
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	2ea080e7          	jalr	746(ra) # 80003b5e <iunlockput>
  iunlockput(dp);
    8000587c:	8526                	mv	a0,s1
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	2e0080e7          	jalr	736(ra) # 80003b5e <iunlockput>
  end_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	ab6080e7          	jalr	-1354(ra) # 8000433c <end_op>
  return -1;
    8000588e:	557d                	li	a0,-1
}
    80005890:	70ae                	ld	ra,232(sp)
    80005892:	740e                	ld	s0,224(sp)
    80005894:	64ee                	ld	s1,216(sp)
    80005896:	694e                	ld	s2,208(sp)
    80005898:	69ae                	ld	s3,200(sp)
    8000589a:	616d                	addi	sp,sp,240
    8000589c:	8082                	ret

000000008000589e <sys_open>:

uint64
sys_open(void)
{
    8000589e:	7131                	addi	sp,sp,-192
    800058a0:	fd06                	sd	ra,184(sp)
    800058a2:	f922                	sd	s0,176(sp)
    800058a4:	f526                	sd	s1,168(sp)
    800058a6:	f14a                	sd	s2,160(sp)
    800058a8:	ed4e                	sd	s3,152(sp)
    800058aa:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058ac:	08000613          	li	a2,128
    800058b0:	f5040593          	addi	a1,s0,-176
    800058b4:	4501                	li	a0,0
    800058b6:	ffffd097          	auipc	ra,0xffffd
    800058ba:	518080e7          	jalr	1304(ra) # 80002dce <argstr>
    return -1;
    800058be:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058c0:	0c054163          	bltz	a0,80005982 <sys_open+0xe4>
    800058c4:	f4c40593          	addi	a1,s0,-180
    800058c8:	4505                	li	a0,1
    800058ca:	ffffd097          	auipc	ra,0xffffd
    800058ce:	4c0080e7          	jalr	1216(ra) # 80002d8a <argint>
    800058d2:	0a054863          	bltz	a0,80005982 <sys_open+0xe4>

  begin_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	9e6080e7          	jalr	-1562(ra) # 800042bc <begin_op>

  if(omode & O_CREATE){
    800058de:	f4c42783          	lw	a5,-180(s0)
    800058e2:	2007f793          	andi	a5,a5,512
    800058e6:	cbdd                	beqz	a5,8000599c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058e8:	4681                	li	a3,0
    800058ea:	4601                	li	a2,0
    800058ec:	4589                	li	a1,2
    800058ee:	f5040513          	addi	a0,s0,-176
    800058f2:	00000097          	auipc	ra,0x0
    800058f6:	974080e7          	jalr	-1676(ra) # 80005266 <create>
    800058fa:	892a                	mv	s2,a0
    if(ip == 0){
    800058fc:	c959                	beqz	a0,80005992 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058fe:	04491703          	lh	a4,68(s2)
    80005902:	478d                	li	a5,3
    80005904:	00f71763          	bne	a4,a5,80005912 <sys_open+0x74>
    80005908:	04695703          	lhu	a4,70(s2)
    8000590c:	47a5                	li	a5,9
    8000590e:	0ce7ec63          	bltu	a5,a4,800059e6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	dc0080e7          	jalr	-576(ra) # 800046d2 <filealloc>
    8000591a:	89aa                	mv	s3,a0
    8000591c:	10050263          	beqz	a0,80005a20 <sys_open+0x182>
    80005920:	00000097          	auipc	ra,0x0
    80005924:	904080e7          	jalr	-1788(ra) # 80005224 <fdalloc>
    80005928:	84aa                	mv	s1,a0
    8000592a:	0e054663          	bltz	a0,80005a16 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000592e:	04491703          	lh	a4,68(s2)
    80005932:	478d                	li	a5,3
    80005934:	0cf70463          	beq	a4,a5,800059fc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005938:	4789                	li	a5,2
    8000593a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000593e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005942:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005946:	f4c42783          	lw	a5,-180(s0)
    8000594a:	0017c713          	xori	a4,a5,1
    8000594e:	8b05                	andi	a4,a4,1
    80005950:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005954:	0037f713          	andi	a4,a5,3
    80005958:	00e03733          	snez	a4,a4
    8000595c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005960:	4007f793          	andi	a5,a5,1024
    80005964:	c791                	beqz	a5,80005970 <sys_open+0xd2>
    80005966:	04491703          	lh	a4,68(s2)
    8000596a:	4789                	li	a5,2
    8000596c:	08f70f63          	beq	a4,a5,80005a0a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005970:	854a                	mv	a0,s2
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	04c080e7          	jalr	76(ra) # 800039be <iunlock>
  end_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	9c2080e7          	jalr	-1598(ra) # 8000433c <end_op>

  return fd;
}
    80005982:	8526                	mv	a0,s1
    80005984:	70ea                	ld	ra,184(sp)
    80005986:	744a                	ld	s0,176(sp)
    80005988:	74aa                	ld	s1,168(sp)
    8000598a:	790a                	ld	s2,160(sp)
    8000598c:	69ea                	ld	s3,152(sp)
    8000598e:	6129                	addi	sp,sp,192
    80005990:	8082                	ret
      end_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	9aa080e7          	jalr	-1622(ra) # 8000433c <end_op>
      return -1;
    8000599a:	b7e5                	j	80005982 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000599c:	f5040513          	addi	a0,s0,-176
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	70c080e7          	jalr	1804(ra) # 800040ac <namei>
    800059a8:	892a                	mv	s2,a0
    800059aa:	c905                	beqz	a0,800059da <sys_open+0x13c>
    ilock(ip);
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	f50080e7          	jalr	-176(ra) # 800038fc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059b4:	04491703          	lh	a4,68(s2)
    800059b8:	4785                	li	a5,1
    800059ba:	f4f712e3          	bne	a4,a5,800058fe <sys_open+0x60>
    800059be:	f4c42783          	lw	a5,-180(s0)
    800059c2:	dba1                	beqz	a5,80005912 <sys_open+0x74>
      iunlockput(ip);
    800059c4:	854a                	mv	a0,s2
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	198080e7          	jalr	408(ra) # 80003b5e <iunlockput>
      end_op();
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	96e080e7          	jalr	-1682(ra) # 8000433c <end_op>
      return -1;
    800059d6:	54fd                	li	s1,-1
    800059d8:	b76d                	j	80005982 <sys_open+0xe4>
      end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	962080e7          	jalr	-1694(ra) # 8000433c <end_op>
      return -1;
    800059e2:	54fd                	li	s1,-1
    800059e4:	bf79                	j	80005982 <sys_open+0xe4>
    iunlockput(ip);
    800059e6:	854a                	mv	a0,s2
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	176080e7          	jalr	374(ra) # 80003b5e <iunlockput>
    end_op();
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	94c080e7          	jalr	-1716(ra) # 8000433c <end_op>
    return -1;
    800059f8:	54fd                	li	s1,-1
    800059fa:	b761                	j	80005982 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059fc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a00:	04691783          	lh	a5,70(s2)
    80005a04:	02f99223          	sh	a5,36(s3)
    80005a08:	bf2d                	j	80005942 <sys_open+0xa4>
    itrunc(ip);
    80005a0a:	854a                	mv	a0,s2
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	ffe080e7          	jalr	-2(ra) # 80003a0a <itrunc>
    80005a14:	bfb1                	j	80005970 <sys_open+0xd2>
      fileclose(f);
    80005a16:	854e                	mv	a0,s3
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	d76080e7          	jalr	-650(ra) # 8000478e <fileclose>
    iunlockput(ip);
    80005a20:	854a                	mv	a0,s2
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	13c080e7          	jalr	316(ra) # 80003b5e <iunlockput>
    end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	912080e7          	jalr	-1774(ra) # 8000433c <end_op>
    return -1;
    80005a32:	54fd                	li	s1,-1
    80005a34:	b7b9                	j	80005982 <sys_open+0xe4>

0000000080005a36 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a36:	7175                	addi	sp,sp,-144
    80005a38:	e506                	sd	ra,136(sp)
    80005a3a:	e122                	sd	s0,128(sp)
    80005a3c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	87e080e7          	jalr	-1922(ra) # 800042bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a46:	08000613          	li	a2,128
    80005a4a:	f7040593          	addi	a1,s0,-144
    80005a4e:	4501                	li	a0,0
    80005a50:	ffffd097          	auipc	ra,0xffffd
    80005a54:	37e080e7          	jalr	894(ra) # 80002dce <argstr>
    80005a58:	02054963          	bltz	a0,80005a8a <sys_mkdir+0x54>
    80005a5c:	4681                	li	a3,0
    80005a5e:	4601                	li	a2,0
    80005a60:	4585                	li	a1,1
    80005a62:	f7040513          	addi	a0,s0,-144
    80005a66:	00000097          	auipc	ra,0x0
    80005a6a:	800080e7          	jalr	-2048(ra) # 80005266 <create>
    80005a6e:	cd11                	beqz	a0,80005a8a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	0ee080e7          	jalr	238(ra) # 80003b5e <iunlockput>
  end_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	8c4080e7          	jalr	-1852(ra) # 8000433c <end_op>
  return 0;
    80005a80:	4501                	li	a0,0
}
    80005a82:	60aa                	ld	ra,136(sp)
    80005a84:	640a                	ld	s0,128(sp)
    80005a86:	6149                	addi	sp,sp,144
    80005a88:	8082                	ret
    end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	8b2080e7          	jalr	-1870(ra) # 8000433c <end_op>
    return -1;
    80005a92:	557d                	li	a0,-1
    80005a94:	b7fd                	j	80005a82 <sys_mkdir+0x4c>

0000000080005a96 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a96:	7135                	addi	sp,sp,-160
    80005a98:	ed06                	sd	ra,152(sp)
    80005a9a:	e922                	sd	s0,144(sp)
    80005a9c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	81e080e7          	jalr	-2018(ra) # 800042bc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aa6:	08000613          	li	a2,128
    80005aaa:	f7040593          	addi	a1,s0,-144
    80005aae:	4501                	li	a0,0
    80005ab0:	ffffd097          	auipc	ra,0xffffd
    80005ab4:	31e080e7          	jalr	798(ra) # 80002dce <argstr>
    80005ab8:	04054a63          	bltz	a0,80005b0c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005abc:	f6c40593          	addi	a1,s0,-148
    80005ac0:	4505                	li	a0,1
    80005ac2:	ffffd097          	auipc	ra,0xffffd
    80005ac6:	2c8080e7          	jalr	712(ra) # 80002d8a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aca:	04054163          	bltz	a0,80005b0c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ace:	f6840593          	addi	a1,s0,-152
    80005ad2:	4509                	li	a0,2
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	2b6080e7          	jalr	694(ra) # 80002d8a <argint>
     argint(1, &major) < 0 ||
    80005adc:	02054863          	bltz	a0,80005b0c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ae0:	f6841683          	lh	a3,-152(s0)
    80005ae4:	f6c41603          	lh	a2,-148(s0)
    80005ae8:	458d                	li	a1,3
    80005aea:	f7040513          	addi	a0,s0,-144
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	778080e7          	jalr	1912(ra) # 80005266 <create>
     argint(2, &minor) < 0 ||
    80005af6:	c919                	beqz	a0,80005b0c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	066080e7          	jalr	102(ra) # 80003b5e <iunlockput>
  end_op();
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	83c080e7          	jalr	-1988(ra) # 8000433c <end_op>
  return 0;
    80005b08:	4501                	li	a0,0
    80005b0a:	a031                	j	80005b16 <sys_mknod+0x80>
    end_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	830080e7          	jalr	-2000(ra) # 8000433c <end_op>
    return -1;
    80005b14:	557d                	li	a0,-1
}
    80005b16:	60ea                	ld	ra,152(sp)
    80005b18:	644a                	ld	s0,144(sp)
    80005b1a:	610d                	addi	sp,sp,160
    80005b1c:	8082                	ret

0000000080005b1e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b1e:	7135                	addi	sp,sp,-160
    80005b20:	ed06                	sd	ra,152(sp)
    80005b22:	e922                	sd	s0,144(sp)
    80005b24:	e526                	sd	s1,136(sp)
    80005b26:	e14a                	sd	s2,128(sp)
    80005b28:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b2a:	ffffc097          	auipc	ra,0xffffc
    80005b2e:	faa080e7          	jalr	-86(ra) # 80001ad4 <myproc>
    80005b32:	892a                	mv	s2,a0
  
  begin_op();
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	788080e7          	jalr	1928(ra) # 800042bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b3c:	08000613          	li	a2,128
    80005b40:	f6040593          	addi	a1,s0,-160
    80005b44:	4501                	li	a0,0
    80005b46:	ffffd097          	auipc	ra,0xffffd
    80005b4a:	288080e7          	jalr	648(ra) # 80002dce <argstr>
    80005b4e:	04054b63          	bltz	a0,80005ba4 <sys_chdir+0x86>
    80005b52:	f6040513          	addi	a0,s0,-160
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	556080e7          	jalr	1366(ra) # 800040ac <namei>
    80005b5e:	84aa                	mv	s1,a0
    80005b60:	c131                	beqz	a0,80005ba4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	d9a080e7          	jalr	-614(ra) # 800038fc <ilock>
  if(ip->type != T_DIR){
    80005b6a:	04449703          	lh	a4,68(s1)
    80005b6e:	4785                	li	a5,1
    80005b70:	04f71063          	bne	a4,a5,80005bb0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b74:	8526                	mv	a0,s1
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	e48080e7          	jalr	-440(ra) # 800039be <iunlock>
  iput(p->cwd);
    80005b7e:	15093503          	ld	a0,336(s2)
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	f34080e7          	jalr	-204(ra) # 80003ab6 <iput>
  end_op();
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	7b2080e7          	jalr	1970(ra) # 8000433c <end_op>
  p->cwd = ip;
    80005b92:	14993823          	sd	s1,336(s2)
  return 0;
    80005b96:	4501                	li	a0,0
}
    80005b98:	60ea                	ld	ra,152(sp)
    80005b9a:	644a                	ld	s0,144(sp)
    80005b9c:	64aa                	ld	s1,136(sp)
    80005b9e:	690a                	ld	s2,128(sp)
    80005ba0:	610d                	addi	sp,sp,160
    80005ba2:	8082                	ret
    end_op();
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	798080e7          	jalr	1944(ra) # 8000433c <end_op>
    return -1;
    80005bac:	557d                	li	a0,-1
    80005bae:	b7ed                	j	80005b98 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bb0:	8526                	mv	a0,s1
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	fac080e7          	jalr	-84(ra) # 80003b5e <iunlockput>
    end_op();
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	782080e7          	jalr	1922(ra) # 8000433c <end_op>
    return -1;
    80005bc2:	557d                	li	a0,-1
    80005bc4:	bfd1                	j	80005b98 <sys_chdir+0x7a>

0000000080005bc6 <sys_exec>:

uint64
sys_exec(void)
{
    80005bc6:	7145                	addi	sp,sp,-464
    80005bc8:	e786                	sd	ra,456(sp)
    80005bca:	e3a2                	sd	s0,448(sp)
    80005bcc:	ff26                	sd	s1,440(sp)
    80005bce:	fb4a                	sd	s2,432(sp)
    80005bd0:	f74e                	sd	s3,424(sp)
    80005bd2:	f352                	sd	s4,416(sp)
    80005bd4:	ef56                	sd	s5,408(sp)
    80005bd6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bd8:	08000613          	li	a2,128
    80005bdc:	f4040593          	addi	a1,s0,-192
    80005be0:	4501                	li	a0,0
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	1ec080e7          	jalr	492(ra) # 80002dce <argstr>
    return -1;
    80005bea:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bec:	0c054a63          	bltz	a0,80005cc0 <sys_exec+0xfa>
    80005bf0:	e3840593          	addi	a1,s0,-456
    80005bf4:	4505                	li	a0,1
    80005bf6:	ffffd097          	auipc	ra,0xffffd
    80005bfa:	1b6080e7          	jalr	438(ra) # 80002dac <argaddr>
    80005bfe:	0c054163          	bltz	a0,80005cc0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c02:	10000613          	li	a2,256
    80005c06:	4581                	li	a1,0
    80005c08:	e4040513          	addi	a0,s0,-448
    80005c0c:	ffffb097          	auipc	ra,0xffffb
    80005c10:	0ee080e7          	jalr	238(ra) # 80000cfa <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c14:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c18:	89a6                	mv	s3,s1
    80005c1a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c1c:	02000a13          	li	s4,32
    80005c20:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c24:	00391793          	slli	a5,s2,0x3
    80005c28:	e3040593          	addi	a1,s0,-464
    80005c2c:	e3843503          	ld	a0,-456(s0)
    80005c30:	953e                	add	a0,a0,a5
    80005c32:	ffffd097          	auipc	ra,0xffffd
    80005c36:	0be080e7          	jalr	190(ra) # 80002cf0 <fetchaddr>
    80005c3a:	02054a63          	bltz	a0,80005c6e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c3e:	e3043783          	ld	a5,-464(s0)
    80005c42:	c3b9                	beqz	a5,80005c88 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c44:	ffffb097          	auipc	ra,0xffffb
    80005c48:	eca080e7          	jalr	-310(ra) # 80000b0e <kalloc>
    80005c4c:	85aa                	mv	a1,a0
    80005c4e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c52:	cd11                	beqz	a0,80005c6e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c54:	6605                	lui	a2,0x1
    80005c56:	e3043503          	ld	a0,-464(s0)
    80005c5a:	ffffd097          	auipc	ra,0xffffd
    80005c5e:	0e8080e7          	jalr	232(ra) # 80002d42 <fetchstr>
    80005c62:	00054663          	bltz	a0,80005c6e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c66:	0905                	addi	s2,s2,1
    80005c68:	09a1                	addi	s3,s3,8
    80005c6a:	fb491be3          	bne	s2,s4,80005c20 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c6e:	10048913          	addi	s2,s1,256
    80005c72:	6088                	ld	a0,0(s1)
    80005c74:	c529                	beqz	a0,80005cbe <sys_exec+0xf8>
    kfree(argv[i]);
    80005c76:	ffffb097          	auipc	ra,0xffffb
    80005c7a:	d9c080e7          	jalr	-612(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c7e:	04a1                	addi	s1,s1,8
    80005c80:	ff2499e3          	bne	s1,s2,80005c72 <sys_exec+0xac>
  return -1;
    80005c84:	597d                	li	s2,-1
    80005c86:	a82d                	j	80005cc0 <sys_exec+0xfa>
      argv[i] = 0;
    80005c88:	0a8e                	slli	s5,s5,0x3
    80005c8a:	fc040793          	addi	a5,s0,-64
    80005c8e:	9abe                	add	s5,s5,a5
    80005c90:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005c94:	e4040593          	addi	a1,s0,-448
    80005c98:	f4040513          	addi	a0,s0,-192
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	178080e7          	jalr	376(ra) # 80004e14 <exec>
    80005ca4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca6:	10048993          	addi	s3,s1,256
    80005caa:	6088                	ld	a0,0(s1)
    80005cac:	c911                	beqz	a0,80005cc0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005cae:	ffffb097          	auipc	ra,0xffffb
    80005cb2:	d64080e7          	jalr	-668(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb6:	04a1                	addi	s1,s1,8
    80005cb8:	ff3499e3          	bne	s1,s3,80005caa <sys_exec+0xe4>
    80005cbc:	a011                	j	80005cc0 <sys_exec+0xfa>
  return -1;
    80005cbe:	597d                	li	s2,-1
}
    80005cc0:	854a                	mv	a0,s2
    80005cc2:	60be                	ld	ra,456(sp)
    80005cc4:	641e                	ld	s0,448(sp)
    80005cc6:	74fa                	ld	s1,440(sp)
    80005cc8:	795a                	ld	s2,432(sp)
    80005cca:	79ba                	ld	s3,424(sp)
    80005ccc:	7a1a                	ld	s4,416(sp)
    80005cce:	6afa                	ld	s5,408(sp)
    80005cd0:	6179                	addi	sp,sp,464
    80005cd2:	8082                	ret

0000000080005cd4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cd4:	7139                	addi	sp,sp,-64
    80005cd6:	fc06                	sd	ra,56(sp)
    80005cd8:	f822                	sd	s0,48(sp)
    80005cda:	f426                	sd	s1,40(sp)
    80005cdc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cde:	ffffc097          	auipc	ra,0xffffc
    80005ce2:	df6080e7          	jalr	-522(ra) # 80001ad4 <myproc>
    80005ce6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ce8:	fd840593          	addi	a1,s0,-40
    80005cec:	4501                	li	a0,0
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	0be080e7          	jalr	190(ra) # 80002dac <argaddr>
    return -1;
    80005cf6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cf8:	0e054063          	bltz	a0,80005dd8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cfc:	fc840593          	addi	a1,s0,-56
    80005d00:	fd040513          	addi	a0,s0,-48
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	de0080e7          	jalr	-544(ra) # 80004ae4 <pipealloc>
    return -1;
    80005d0c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d0e:	0c054563          	bltz	a0,80005dd8 <sys_pipe+0x104>
  fd0 = -1;
    80005d12:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d16:	fd043503          	ld	a0,-48(s0)
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	50a080e7          	jalr	1290(ra) # 80005224 <fdalloc>
    80005d22:	fca42223          	sw	a0,-60(s0)
    80005d26:	08054c63          	bltz	a0,80005dbe <sys_pipe+0xea>
    80005d2a:	fc843503          	ld	a0,-56(s0)
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	4f6080e7          	jalr	1270(ra) # 80005224 <fdalloc>
    80005d36:	fca42023          	sw	a0,-64(s0)
    80005d3a:	06054863          	bltz	a0,80005daa <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d3e:	4691                	li	a3,4
    80005d40:	fc440613          	addi	a2,s0,-60
    80005d44:	fd843583          	ld	a1,-40(s0)
    80005d48:	68a8                	ld	a0,80(s1)
    80005d4a:	ffffc097          	auipc	ra,0xffffc
    80005d4e:	962080e7          	jalr	-1694(ra) # 800016ac <copyout>
    80005d52:	02054063          	bltz	a0,80005d72 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d56:	4691                	li	a3,4
    80005d58:	fc040613          	addi	a2,s0,-64
    80005d5c:	fd843583          	ld	a1,-40(s0)
    80005d60:	0591                	addi	a1,a1,4
    80005d62:	68a8                	ld	a0,80(s1)
    80005d64:	ffffc097          	auipc	ra,0xffffc
    80005d68:	948080e7          	jalr	-1720(ra) # 800016ac <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d6c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d6e:	06055563          	bgez	a0,80005dd8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d72:	fc442783          	lw	a5,-60(s0)
    80005d76:	07e9                	addi	a5,a5,26
    80005d78:	078e                	slli	a5,a5,0x3
    80005d7a:	97a6                	add	a5,a5,s1
    80005d7c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d80:	fc042503          	lw	a0,-64(s0)
    80005d84:	0569                	addi	a0,a0,26
    80005d86:	050e                	slli	a0,a0,0x3
    80005d88:	9526                	add	a0,a0,s1
    80005d8a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d8e:	fd043503          	ld	a0,-48(s0)
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	9fc080e7          	jalr	-1540(ra) # 8000478e <fileclose>
    fileclose(wf);
    80005d9a:	fc843503          	ld	a0,-56(s0)
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	9f0080e7          	jalr	-1552(ra) # 8000478e <fileclose>
    return -1;
    80005da6:	57fd                	li	a5,-1
    80005da8:	a805                	j	80005dd8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005daa:	fc442783          	lw	a5,-60(s0)
    80005dae:	0007c863          	bltz	a5,80005dbe <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005db2:	01a78513          	addi	a0,a5,26
    80005db6:	050e                	slli	a0,a0,0x3
    80005db8:	9526                	add	a0,a0,s1
    80005dba:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005dbe:	fd043503          	ld	a0,-48(s0)
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	9cc080e7          	jalr	-1588(ra) # 8000478e <fileclose>
    fileclose(wf);
    80005dca:	fc843503          	ld	a0,-56(s0)
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	9c0080e7          	jalr	-1600(ra) # 8000478e <fileclose>
    return -1;
    80005dd6:	57fd                	li	a5,-1
}
    80005dd8:	853e                	mv	a0,a5
    80005dda:	70e2                	ld	ra,56(sp)
    80005ddc:	7442                	ld	s0,48(sp)
    80005dde:	74a2                	ld	s1,40(sp)
    80005de0:	6121                	addi	sp,sp,64
    80005de2:	8082                	ret
	...

0000000080005df0 <kernelvec>:
    80005df0:	7111                	addi	sp,sp,-256
    80005df2:	e006                	sd	ra,0(sp)
    80005df4:	e40a                	sd	sp,8(sp)
    80005df6:	e80e                	sd	gp,16(sp)
    80005df8:	ec12                	sd	tp,24(sp)
    80005dfa:	f016                	sd	t0,32(sp)
    80005dfc:	f41a                	sd	t1,40(sp)
    80005dfe:	f81e                	sd	t2,48(sp)
    80005e00:	fc22                	sd	s0,56(sp)
    80005e02:	e0a6                	sd	s1,64(sp)
    80005e04:	e4aa                	sd	a0,72(sp)
    80005e06:	e8ae                	sd	a1,80(sp)
    80005e08:	ecb2                	sd	a2,88(sp)
    80005e0a:	f0b6                	sd	a3,96(sp)
    80005e0c:	f4ba                	sd	a4,104(sp)
    80005e0e:	f8be                	sd	a5,112(sp)
    80005e10:	fcc2                	sd	a6,120(sp)
    80005e12:	e146                	sd	a7,128(sp)
    80005e14:	e54a                	sd	s2,136(sp)
    80005e16:	e94e                	sd	s3,144(sp)
    80005e18:	ed52                	sd	s4,152(sp)
    80005e1a:	f156                	sd	s5,160(sp)
    80005e1c:	f55a                	sd	s6,168(sp)
    80005e1e:	f95e                	sd	s7,176(sp)
    80005e20:	fd62                	sd	s8,184(sp)
    80005e22:	e1e6                	sd	s9,192(sp)
    80005e24:	e5ea                	sd	s10,200(sp)
    80005e26:	e9ee                	sd	s11,208(sp)
    80005e28:	edf2                	sd	t3,216(sp)
    80005e2a:	f1f6                	sd	t4,224(sp)
    80005e2c:	f5fa                	sd	t5,232(sp)
    80005e2e:	f9fe                	sd	t6,240(sp)
    80005e30:	d8dfc0ef          	jal	ra,80002bbc <kerneltrap>
    80005e34:	6082                	ld	ra,0(sp)
    80005e36:	6122                	ld	sp,8(sp)
    80005e38:	61c2                	ld	gp,16(sp)
    80005e3a:	7282                	ld	t0,32(sp)
    80005e3c:	7322                	ld	t1,40(sp)
    80005e3e:	73c2                	ld	t2,48(sp)
    80005e40:	7462                	ld	s0,56(sp)
    80005e42:	6486                	ld	s1,64(sp)
    80005e44:	6526                	ld	a0,72(sp)
    80005e46:	65c6                	ld	a1,80(sp)
    80005e48:	6666                	ld	a2,88(sp)
    80005e4a:	7686                	ld	a3,96(sp)
    80005e4c:	7726                	ld	a4,104(sp)
    80005e4e:	77c6                	ld	a5,112(sp)
    80005e50:	7866                	ld	a6,120(sp)
    80005e52:	688a                	ld	a7,128(sp)
    80005e54:	692a                	ld	s2,136(sp)
    80005e56:	69ca                	ld	s3,144(sp)
    80005e58:	6a6a                	ld	s4,152(sp)
    80005e5a:	7a8a                	ld	s5,160(sp)
    80005e5c:	7b2a                	ld	s6,168(sp)
    80005e5e:	7bca                	ld	s7,176(sp)
    80005e60:	7c6a                	ld	s8,184(sp)
    80005e62:	6c8e                	ld	s9,192(sp)
    80005e64:	6d2e                	ld	s10,200(sp)
    80005e66:	6dce                	ld	s11,208(sp)
    80005e68:	6e6e                	ld	t3,216(sp)
    80005e6a:	7e8e                	ld	t4,224(sp)
    80005e6c:	7f2e                	ld	t5,232(sp)
    80005e6e:	7fce                	ld	t6,240(sp)
    80005e70:	6111                	addi	sp,sp,256
    80005e72:	10200073          	sret
    80005e76:	00000013          	nop
    80005e7a:	00000013          	nop
    80005e7e:	0001                	nop

0000000080005e80 <timervec>:
    80005e80:	34051573          	csrrw	a0,mscratch,a0
    80005e84:	e10c                	sd	a1,0(a0)
    80005e86:	e510                	sd	a2,8(a0)
    80005e88:	e914                	sd	a3,16(a0)
    80005e8a:	710c                	ld	a1,32(a0)
    80005e8c:	7510                	ld	a2,40(a0)
    80005e8e:	6194                	ld	a3,0(a1)
    80005e90:	96b2                	add	a3,a3,a2
    80005e92:	e194                	sd	a3,0(a1)
    80005e94:	4589                	li	a1,2
    80005e96:	14459073          	csrw	sip,a1
    80005e9a:	6914                	ld	a3,16(a0)
    80005e9c:	6510                	ld	a2,8(a0)
    80005e9e:	610c                	ld	a1,0(a0)
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	30200073          	mret
	...

0000000080005eaa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eaa:	1141                	addi	sp,sp,-16
    80005eac:	e422                	sd	s0,8(sp)
    80005eae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005eb0:	0c0007b7          	lui	a5,0xc000
    80005eb4:	4705                	li	a4,1
    80005eb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005eb8:	c3d8                	sw	a4,4(a5)
}
    80005eba:	6422                	ld	s0,8(sp)
    80005ebc:	0141                	addi	sp,sp,16
    80005ebe:	8082                	ret

0000000080005ec0 <plicinithart>:

void
plicinithart(void)
{
    80005ec0:	1141                	addi	sp,sp,-16
    80005ec2:	e406                	sd	ra,8(sp)
    80005ec4:	e022                	sd	s0,0(sp)
    80005ec6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	be0080e7          	jalr	-1056(ra) # 80001aa8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ed0:	0085171b          	slliw	a4,a0,0x8
    80005ed4:	0c0027b7          	lui	a5,0xc002
    80005ed8:	97ba                	add	a5,a5,a4
    80005eda:	40200713          	li	a4,1026
    80005ede:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ee2:	00d5151b          	slliw	a0,a0,0xd
    80005ee6:	0c2017b7          	lui	a5,0xc201
    80005eea:	953e                	add	a0,a0,a5
    80005eec:	00052023          	sw	zero,0(a0)
}
    80005ef0:	60a2                	ld	ra,8(sp)
    80005ef2:	6402                	ld	s0,0(sp)
    80005ef4:	0141                	addi	sp,sp,16
    80005ef6:	8082                	ret

0000000080005ef8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ef8:	1141                	addi	sp,sp,-16
    80005efa:	e406                	sd	ra,8(sp)
    80005efc:	e022                	sd	s0,0(sp)
    80005efe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f00:	ffffc097          	auipc	ra,0xffffc
    80005f04:	ba8080e7          	jalr	-1112(ra) # 80001aa8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f08:	00d5179b          	slliw	a5,a0,0xd
    80005f0c:	0c201537          	lui	a0,0xc201
    80005f10:	953e                	add	a0,a0,a5
  return irq;
}
    80005f12:	4148                	lw	a0,4(a0)
    80005f14:	60a2                	ld	ra,8(sp)
    80005f16:	6402                	ld	s0,0(sp)
    80005f18:	0141                	addi	sp,sp,16
    80005f1a:	8082                	ret

0000000080005f1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f1c:	1101                	addi	sp,sp,-32
    80005f1e:	ec06                	sd	ra,24(sp)
    80005f20:	e822                	sd	s0,16(sp)
    80005f22:	e426                	sd	s1,8(sp)
    80005f24:	1000                	addi	s0,sp,32
    80005f26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	b80080e7          	jalr	-1152(ra) # 80001aa8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f30:	00d5151b          	slliw	a0,a0,0xd
    80005f34:	0c2017b7          	lui	a5,0xc201
    80005f38:	97aa                	add	a5,a5,a0
    80005f3a:	c3c4                	sw	s1,4(a5)
}
    80005f3c:	60e2                	ld	ra,24(sp)
    80005f3e:	6442                	ld	s0,16(sp)
    80005f40:	64a2                	ld	s1,8(sp)
    80005f42:	6105                	addi	sp,sp,32
    80005f44:	8082                	ret

0000000080005f46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f46:	1141                	addi	sp,sp,-16
    80005f48:	e406                	sd	ra,8(sp)
    80005f4a:	e022                	sd	s0,0(sp)
    80005f4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f4e:	479d                	li	a5,7
    80005f50:	04a7cc63          	blt	a5,a0,80005fa8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f54:	0001e797          	auipc	a5,0x1e
    80005f58:	0ac78793          	addi	a5,a5,172 # 80024000 <disk>
    80005f5c:	00a78733          	add	a4,a5,a0
    80005f60:	6789                	lui	a5,0x2
    80005f62:	97ba                	add	a5,a5,a4
    80005f64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f68:	eba1                	bnez	a5,80005fb8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f6a:	00451713          	slli	a4,a0,0x4
    80005f6e:	00020797          	auipc	a5,0x20
    80005f72:	0927b783          	ld	a5,146(a5) # 80026000 <disk+0x2000>
    80005f76:	97ba                	add	a5,a5,a4
    80005f78:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f7c:	0001e797          	auipc	a5,0x1e
    80005f80:	08478793          	addi	a5,a5,132 # 80024000 <disk>
    80005f84:	97aa                	add	a5,a5,a0
    80005f86:	6509                	lui	a0,0x2
    80005f88:	953e                	add	a0,a0,a5
    80005f8a:	4785                	li	a5,1
    80005f8c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f90:	00020517          	auipc	a0,0x20
    80005f94:	08850513          	addi	a0,a0,136 # 80026018 <disk+0x2018>
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	678080e7          	jalr	1656(ra) # 80002610 <wakeup>
}
    80005fa0:	60a2                	ld	ra,8(sp)
    80005fa2:	6402                	ld	s0,0(sp)
    80005fa4:	0141                	addi	sp,sp,16
    80005fa6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005fa8:	00003517          	auipc	a0,0x3
    80005fac:	86850513          	addi	a0,a0,-1944 # 80008810 <syscalls+0x330>
    80005fb0:	ffffa097          	auipc	ra,0xffffa
    80005fb4:	592080e7          	jalr	1426(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005fb8:	00003517          	auipc	a0,0x3
    80005fbc:	87050513          	addi	a0,a0,-1936 # 80008828 <syscalls+0x348>
    80005fc0:	ffffa097          	auipc	ra,0xffffa
    80005fc4:	582080e7          	jalr	1410(ra) # 80000542 <panic>

0000000080005fc8 <virtio_disk_init>:
{
    80005fc8:	1101                	addi	sp,sp,-32
    80005fca:	ec06                	sd	ra,24(sp)
    80005fcc:	e822                	sd	s0,16(sp)
    80005fce:	e426                	sd	s1,8(sp)
    80005fd0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fd2:	00003597          	auipc	a1,0x3
    80005fd6:	86e58593          	addi	a1,a1,-1938 # 80008840 <syscalls+0x360>
    80005fda:	00020517          	auipc	a0,0x20
    80005fde:	0ce50513          	addi	a0,a0,206 # 800260a8 <disk+0x20a8>
    80005fe2:	ffffb097          	auipc	ra,0xffffb
    80005fe6:	b8c080e7          	jalr	-1140(ra) # 80000b6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fea:	100017b7          	lui	a5,0x10001
    80005fee:	4398                	lw	a4,0(a5)
    80005ff0:	2701                	sext.w	a4,a4
    80005ff2:	747277b7          	lui	a5,0x74727
    80005ff6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ffa:	0ef71163          	bne	a4,a5,800060dc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ffe:	100017b7          	lui	a5,0x10001
    80006002:	43dc                	lw	a5,4(a5)
    80006004:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006006:	4705                	li	a4,1
    80006008:	0ce79a63          	bne	a5,a4,800060dc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000600c:	100017b7          	lui	a5,0x10001
    80006010:	479c                	lw	a5,8(a5)
    80006012:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006014:	4709                	li	a4,2
    80006016:	0ce79363          	bne	a5,a4,800060dc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	47d8                	lw	a4,12(a5)
    80006020:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006022:	554d47b7          	lui	a5,0x554d4
    80006026:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000602a:	0af71963          	bne	a4,a5,800060dc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	4705                	li	a4,1
    80006034:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006036:	470d                	li	a4,3
    80006038:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000603a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000603c:	c7ffe737          	lui	a4,0xc7ffe
    80006040:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80006044:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006046:	2701                	sext.w	a4,a4
    80006048:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604a:	472d                	li	a4,11
    8000604c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604e:	473d                	li	a4,15
    80006050:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006052:	6705                	lui	a4,0x1
    80006054:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006056:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000605a:	5bdc                	lw	a5,52(a5)
    8000605c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000605e:	c7d9                	beqz	a5,800060ec <virtio_disk_init+0x124>
  if(max < NUM)
    80006060:	471d                	li	a4,7
    80006062:	08f77d63          	bgeu	a4,a5,800060fc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006066:	100014b7          	lui	s1,0x10001
    8000606a:	47a1                	li	a5,8
    8000606c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000606e:	6609                	lui	a2,0x2
    80006070:	4581                	li	a1,0
    80006072:	0001e517          	auipc	a0,0x1e
    80006076:	f8e50513          	addi	a0,a0,-114 # 80024000 <disk>
    8000607a:	ffffb097          	auipc	ra,0xffffb
    8000607e:	c80080e7          	jalr	-896(ra) # 80000cfa <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006082:	0001e717          	auipc	a4,0x1e
    80006086:	f7e70713          	addi	a4,a4,-130 # 80024000 <disk>
    8000608a:	00c75793          	srli	a5,a4,0xc
    8000608e:	2781                	sext.w	a5,a5
    80006090:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006092:	00020797          	auipc	a5,0x20
    80006096:	f6e78793          	addi	a5,a5,-146 # 80026000 <disk+0x2000>
    8000609a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000609c:	0001e717          	auipc	a4,0x1e
    800060a0:	fe470713          	addi	a4,a4,-28 # 80024080 <disk+0x80>
    800060a4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800060a6:	0001f717          	auipc	a4,0x1f
    800060aa:	f5a70713          	addi	a4,a4,-166 # 80025000 <disk+0x1000>
    800060ae:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060b0:	4705                	li	a4,1
    800060b2:	00e78c23          	sb	a4,24(a5)
    800060b6:	00e78ca3          	sb	a4,25(a5)
    800060ba:	00e78d23          	sb	a4,26(a5)
    800060be:	00e78da3          	sb	a4,27(a5)
    800060c2:	00e78e23          	sb	a4,28(a5)
    800060c6:	00e78ea3          	sb	a4,29(a5)
    800060ca:	00e78f23          	sb	a4,30(a5)
    800060ce:	00e78fa3          	sb	a4,31(a5)
}
    800060d2:	60e2                	ld	ra,24(sp)
    800060d4:	6442                	ld	s0,16(sp)
    800060d6:	64a2                	ld	s1,8(sp)
    800060d8:	6105                	addi	sp,sp,32
    800060da:	8082                	ret
    panic("could not find virtio disk");
    800060dc:	00002517          	auipc	a0,0x2
    800060e0:	77450513          	addi	a0,a0,1908 # 80008850 <syscalls+0x370>
    800060e4:	ffffa097          	auipc	ra,0xffffa
    800060e8:	45e080e7          	jalr	1118(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    800060ec:	00002517          	auipc	a0,0x2
    800060f0:	78450513          	addi	a0,a0,1924 # 80008870 <syscalls+0x390>
    800060f4:	ffffa097          	auipc	ra,0xffffa
    800060f8:	44e080e7          	jalr	1102(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    800060fc:	00002517          	auipc	a0,0x2
    80006100:	79450513          	addi	a0,a0,1940 # 80008890 <syscalls+0x3b0>
    80006104:	ffffa097          	auipc	ra,0xffffa
    80006108:	43e080e7          	jalr	1086(ra) # 80000542 <panic>

000000008000610c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000610c:	7175                	addi	sp,sp,-144
    8000610e:	e506                	sd	ra,136(sp)
    80006110:	e122                	sd	s0,128(sp)
    80006112:	fca6                	sd	s1,120(sp)
    80006114:	f8ca                	sd	s2,112(sp)
    80006116:	f4ce                	sd	s3,104(sp)
    80006118:	f0d2                	sd	s4,96(sp)
    8000611a:	ecd6                	sd	s5,88(sp)
    8000611c:	e8da                	sd	s6,80(sp)
    8000611e:	e4de                	sd	s7,72(sp)
    80006120:	e0e2                	sd	s8,64(sp)
    80006122:	fc66                	sd	s9,56(sp)
    80006124:	f86a                	sd	s10,48(sp)
    80006126:	f46e                	sd	s11,40(sp)
    80006128:	0900                	addi	s0,sp,144
    8000612a:	8aaa                	mv	s5,a0
    8000612c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000612e:	00c52c83          	lw	s9,12(a0)
    80006132:	001c9c9b          	slliw	s9,s9,0x1
    80006136:	1c82                	slli	s9,s9,0x20
    80006138:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000613c:	00020517          	auipc	a0,0x20
    80006140:	f6c50513          	addi	a0,a0,-148 # 800260a8 <disk+0x20a8>
    80006144:	ffffb097          	auipc	ra,0xffffb
    80006148:	aba080e7          	jalr	-1350(ra) # 80000bfe <acquire>
  for(int i = 0; i < 3; i++){
    8000614c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000614e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006150:	0001ec17          	auipc	s8,0x1e
    80006154:	eb0c0c13          	addi	s8,s8,-336 # 80024000 <disk>
    80006158:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    8000615a:	4b0d                	li	s6,3
    8000615c:	a0ad                	j	800061c6 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000615e:	00fc0733          	add	a4,s8,a5
    80006162:	975e                	add	a4,a4,s7
    80006164:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006168:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000616a:	0207c563          	bltz	a5,80006194 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000616e:	2905                	addiw	s2,s2,1
    80006170:	0611                	addi	a2,a2,4
    80006172:	19690d63          	beq	s2,s6,8000630c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006176:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006178:	00020717          	auipc	a4,0x20
    8000617c:	ea070713          	addi	a4,a4,-352 # 80026018 <disk+0x2018>
    80006180:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006182:	00074683          	lbu	a3,0(a4)
    80006186:	fee1                	bnez	a3,8000615e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006188:	2785                	addiw	a5,a5,1
    8000618a:	0705                	addi	a4,a4,1
    8000618c:	fe979be3          	bne	a5,s1,80006182 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006190:	57fd                	li	a5,-1
    80006192:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006194:	01205d63          	blez	s2,800061ae <virtio_disk_rw+0xa2>
    80006198:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000619a:	000a2503          	lw	a0,0(s4)
    8000619e:	00000097          	auipc	ra,0x0
    800061a2:	da8080e7          	jalr	-600(ra) # 80005f46 <free_desc>
      for(int j = 0; j < i; j++)
    800061a6:	2d85                	addiw	s11,s11,1
    800061a8:	0a11                	addi	s4,s4,4
    800061aa:	ffb918e3          	bne	s2,s11,8000619a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061ae:	00020597          	auipc	a1,0x20
    800061b2:	efa58593          	addi	a1,a1,-262 # 800260a8 <disk+0x20a8>
    800061b6:	00020517          	auipc	a0,0x20
    800061ba:	e6250513          	addi	a0,a0,-414 # 80026018 <disk+0x2018>
    800061be:	ffffc097          	auipc	ra,0xffffc
    800061c2:	2a0080e7          	jalr	672(ra) # 8000245e <sleep>
  for(int i = 0; i < 3; i++){
    800061c6:	f8040a13          	addi	s4,s0,-128
{
    800061ca:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061cc:	894e                	mv	s2,s3
    800061ce:	b765                	j	80006176 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061d0:	00020717          	auipc	a4,0x20
    800061d4:	e3073703          	ld	a4,-464(a4) # 80026000 <disk+0x2000>
    800061d8:	973e                	add	a4,a4,a5
    800061da:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061de:	0001e517          	auipc	a0,0x1e
    800061e2:	e2250513          	addi	a0,a0,-478 # 80024000 <disk>
    800061e6:	00020717          	auipc	a4,0x20
    800061ea:	e1a70713          	addi	a4,a4,-486 # 80026000 <disk+0x2000>
    800061ee:	6314                	ld	a3,0(a4)
    800061f0:	96be                	add	a3,a3,a5
    800061f2:	00c6d603          	lhu	a2,12(a3)
    800061f6:	00166613          	ori	a2,a2,1
    800061fa:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061fe:	f8842683          	lw	a3,-120(s0)
    80006202:	6310                	ld	a2,0(a4)
    80006204:	97b2                	add	a5,a5,a2
    80006206:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000620a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000620e:	0612                	slli	a2,a2,0x4
    80006210:	962a                	add	a2,a2,a0
    80006212:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006216:	00469793          	slli	a5,a3,0x4
    8000621a:	630c                	ld	a1,0(a4)
    8000621c:	95be                	add	a1,a1,a5
    8000621e:	6689                	lui	a3,0x2
    80006220:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006224:	96ca                	add	a3,a3,s2
    80006226:	96aa                	add	a3,a3,a0
    80006228:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    8000622a:	6314                	ld	a3,0(a4)
    8000622c:	96be                	add	a3,a3,a5
    8000622e:	4585                	li	a1,1
    80006230:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006232:	6314                	ld	a3,0(a4)
    80006234:	96be                	add	a3,a3,a5
    80006236:	4509                	li	a0,2
    80006238:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000623c:	6314                	ld	a3,0(a4)
    8000623e:	97b6                	add	a5,a5,a3
    80006240:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006244:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006248:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000624c:	6714                	ld	a3,8(a4)
    8000624e:	0026d783          	lhu	a5,2(a3)
    80006252:	8b9d                	andi	a5,a5,7
    80006254:	0789                	addi	a5,a5,2
    80006256:	0786                	slli	a5,a5,0x1
    80006258:	97b6                	add	a5,a5,a3
    8000625a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000625e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006262:	6718                	ld	a4,8(a4)
    80006264:	00275783          	lhu	a5,2(a4)
    80006268:	2785                	addiw	a5,a5,1
    8000626a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000626e:	100017b7          	lui	a5,0x10001
    80006272:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006276:	004aa783          	lw	a5,4(s5)
    8000627a:	02b79163          	bne	a5,a1,8000629c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000627e:	00020917          	auipc	s2,0x20
    80006282:	e2a90913          	addi	s2,s2,-470 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006286:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006288:	85ca                	mv	a1,s2
    8000628a:	8556                	mv	a0,s5
    8000628c:	ffffc097          	auipc	ra,0xffffc
    80006290:	1d2080e7          	jalr	466(ra) # 8000245e <sleep>
  while(b->disk == 1) {
    80006294:	004aa783          	lw	a5,4(s5)
    80006298:	fe9788e3          	beq	a5,s1,80006288 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000629c:	f8042483          	lw	s1,-128(s0)
    800062a0:	20048793          	addi	a5,s1,512
    800062a4:	00479713          	slli	a4,a5,0x4
    800062a8:	0001e797          	auipc	a5,0x1e
    800062ac:	d5878793          	addi	a5,a5,-680 # 80024000 <disk>
    800062b0:	97ba                	add	a5,a5,a4
    800062b2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062b6:	00020917          	auipc	s2,0x20
    800062ba:	d4a90913          	addi	s2,s2,-694 # 80026000 <disk+0x2000>
    800062be:	a019                	j	800062c4 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    800062c0:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800062c4:	8526                	mv	a0,s1
    800062c6:	00000097          	auipc	ra,0x0
    800062ca:	c80080e7          	jalr	-896(ra) # 80005f46 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062ce:	0492                	slli	s1,s1,0x4
    800062d0:	00093783          	ld	a5,0(s2)
    800062d4:	94be                	add	s1,s1,a5
    800062d6:	00c4d783          	lhu	a5,12(s1)
    800062da:	8b85                	andi	a5,a5,1
    800062dc:	f3f5                	bnez	a5,800062c0 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062de:	00020517          	auipc	a0,0x20
    800062e2:	dca50513          	addi	a0,a0,-566 # 800260a8 <disk+0x20a8>
    800062e6:	ffffb097          	auipc	ra,0xffffb
    800062ea:	9cc080e7          	jalr	-1588(ra) # 80000cb2 <release>
}
    800062ee:	60aa                	ld	ra,136(sp)
    800062f0:	640a                	ld	s0,128(sp)
    800062f2:	74e6                	ld	s1,120(sp)
    800062f4:	7946                	ld	s2,112(sp)
    800062f6:	79a6                	ld	s3,104(sp)
    800062f8:	7a06                	ld	s4,96(sp)
    800062fa:	6ae6                	ld	s5,88(sp)
    800062fc:	6b46                	ld	s6,80(sp)
    800062fe:	6ba6                	ld	s7,72(sp)
    80006300:	6c06                	ld	s8,64(sp)
    80006302:	7ce2                	ld	s9,56(sp)
    80006304:	7d42                	ld	s10,48(sp)
    80006306:	7da2                	ld	s11,40(sp)
    80006308:	6149                	addi	sp,sp,144
    8000630a:	8082                	ret
  if(write)
    8000630c:	01a037b3          	snez	a5,s10
    80006310:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006314:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006318:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000631c:	f8042483          	lw	s1,-128(s0)
    80006320:	00449913          	slli	s2,s1,0x4
    80006324:	00020997          	auipc	s3,0x20
    80006328:	cdc98993          	addi	s3,s3,-804 # 80026000 <disk+0x2000>
    8000632c:	0009ba03          	ld	s4,0(s3)
    80006330:	9a4a                	add	s4,s4,s2
    80006332:	f7040513          	addi	a0,s0,-144
    80006336:	ffffb097          	auipc	ra,0xffffb
    8000633a:	d84080e7          	jalr	-636(ra) # 800010ba <kvmpa>
    8000633e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006342:	0009b783          	ld	a5,0(s3)
    80006346:	97ca                	add	a5,a5,s2
    80006348:	4741                	li	a4,16
    8000634a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000634c:	0009b783          	ld	a5,0(s3)
    80006350:	97ca                	add	a5,a5,s2
    80006352:	4705                	li	a4,1
    80006354:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006358:	f8442783          	lw	a5,-124(s0)
    8000635c:	0009b703          	ld	a4,0(s3)
    80006360:	974a                	add	a4,a4,s2
    80006362:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006366:	0792                	slli	a5,a5,0x4
    80006368:	0009b703          	ld	a4,0(s3)
    8000636c:	973e                	add	a4,a4,a5
    8000636e:	058a8693          	addi	a3,s5,88
    80006372:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006374:	0009b703          	ld	a4,0(s3)
    80006378:	973e                	add	a4,a4,a5
    8000637a:	40000693          	li	a3,1024
    8000637e:	c714                	sw	a3,8(a4)
  if(write)
    80006380:	e40d18e3          	bnez	s10,800061d0 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006384:	00020717          	auipc	a4,0x20
    80006388:	c7c73703          	ld	a4,-900(a4) # 80026000 <disk+0x2000>
    8000638c:	973e                	add	a4,a4,a5
    8000638e:	4689                	li	a3,2
    80006390:	00d71623          	sh	a3,12(a4)
    80006394:	b5a9                	j	800061de <virtio_disk_rw+0xd2>

0000000080006396 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006396:	1101                	addi	sp,sp,-32
    80006398:	ec06                	sd	ra,24(sp)
    8000639a:	e822                	sd	s0,16(sp)
    8000639c:	e426                	sd	s1,8(sp)
    8000639e:	e04a                	sd	s2,0(sp)
    800063a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063a2:	00020517          	auipc	a0,0x20
    800063a6:	d0650513          	addi	a0,a0,-762 # 800260a8 <disk+0x20a8>
    800063aa:	ffffb097          	auipc	ra,0xffffb
    800063ae:	854080e7          	jalr	-1964(ra) # 80000bfe <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063b2:	00020717          	auipc	a4,0x20
    800063b6:	c4e70713          	addi	a4,a4,-946 # 80026000 <disk+0x2000>
    800063ba:	02075783          	lhu	a5,32(a4)
    800063be:	6b18                	ld	a4,16(a4)
    800063c0:	00275683          	lhu	a3,2(a4)
    800063c4:	8ebd                	xor	a3,a3,a5
    800063c6:	8a9d                	andi	a3,a3,7
    800063c8:	cab9                	beqz	a3,8000641e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800063ca:	0001e917          	auipc	s2,0x1e
    800063ce:	c3690913          	addi	s2,s2,-970 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063d2:	00020497          	auipc	s1,0x20
    800063d6:	c2e48493          	addi	s1,s1,-978 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800063da:	078e                	slli	a5,a5,0x3
    800063dc:	97ba                	add	a5,a5,a4
    800063de:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800063e0:	20078713          	addi	a4,a5,512
    800063e4:	0712                	slli	a4,a4,0x4
    800063e6:	974a                	add	a4,a4,s2
    800063e8:	03074703          	lbu	a4,48(a4)
    800063ec:	ef21                	bnez	a4,80006444 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800063ee:	20078793          	addi	a5,a5,512
    800063f2:	0792                	slli	a5,a5,0x4
    800063f4:	97ca                	add	a5,a5,s2
    800063f6:	7798                	ld	a4,40(a5)
    800063f8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800063fc:	7788                	ld	a0,40(a5)
    800063fe:	ffffc097          	auipc	ra,0xffffc
    80006402:	212080e7          	jalr	530(ra) # 80002610 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006406:	0204d783          	lhu	a5,32(s1)
    8000640a:	2785                	addiw	a5,a5,1
    8000640c:	8b9d                	andi	a5,a5,7
    8000640e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006412:	6898                	ld	a4,16(s1)
    80006414:	00275683          	lhu	a3,2(a4)
    80006418:	8a9d                	andi	a3,a3,7
    8000641a:	fcf690e3          	bne	a3,a5,800063da <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000641e:	10001737          	lui	a4,0x10001
    80006422:	533c                	lw	a5,96(a4)
    80006424:	8b8d                	andi	a5,a5,3
    80006426:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006428:	00020517          	auipc	a0,0x20
    8000642c:	c8050513          	addi	a0,a0,-896 # 800260a8 <disk+0x20a8>
    80006430:	ffffb097          	auipc	ra,0xffffb
    80006434:	882080e7          	jalr	-1918(ra) # 80000cb2 <release>
}
    80006438:	60e2                	ld	ra,24(sp)
    8000643a:	6442                	ld	s0,16(sp)
    8000643c:	64a2                	ld	s1,8(sp)
    8000643e:	6902                	ld	s2,0(sp)
    80006440:	6105                	addi	sp,sp,32
    80006442:	8082                	ret
      panic("virtio_disk_intr status");
    80006444:	00002517          	auipc	a0,0x2
    80006448:	46c50513          	addi	a0,a0,1132 # 800088b0 <syscalls+0x3d0>
    8000644c:	ffffa097          	auipc	ra,0xffffa
    80006450:	0f6080e7          	jalr	246(ra) # 80000542 <panic>
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
