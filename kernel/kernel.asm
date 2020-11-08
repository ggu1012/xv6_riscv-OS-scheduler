
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
    80000060:	b0478793          	addi	a5,a5,-1276 # 80005b60 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
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
    8000012a:	350080e7          	jalr	848(ra) # 80002476 <either_copyin>
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
    800001ca:	00001097          	auipc	ra,0x1
    800001ce:	7f0080e7          	jalr	2032(ra) # 800019ba <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	fec080e7          	jalr	-20(ra) # 800021c6 <sleep>
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
    8000021a:	20a080e7          	jalr	522(ra) # 80002420 <either_copyout>
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
    800002fa:	1d6080e7          	jalr	470(ra) # 800024cc <procdump>
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
    8000044e:	efc080e7          	jalr	-260(ra) # 80002346 <wakeup>
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
    8000047c:	00021797          	auipc	a5,0x21
    80000480:	53478793          	addi	a5,a5,1332 # 800219b0 <devsw>
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
    800008a6:	aa4080e7          	jalr	-1372(ra) # 80002346 <wakeup>
    
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
    80000940:	88a080e7          	jalr	-1910(ra) # 800021c6 <sleep>
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
    80000a26:	00025797          	auipc	a5,0x25
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80026000 <end>
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
    80000af6:	00025517          	auipc	a0,0x25
    80000afa:	50a50513          	addi	a0,a0,1290 # 80026000 <end>
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
    80000b9c:	e06080e7          	jalr	-506(ra) # 8000199e <mycpu>
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
    80000bce:	dd4080e7          	jalr	-556(ra) # 8000199e <mycpu>
    80000bd2:	5d3c                	lw	a5,120(a0)
    80000bd4:	cf89                	beqz	a5,80000bee <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd6:	00001097          	auipc	ra,0x1
    80000bda:	dc8080e7          	jalr	-568(ra) # 8000199e <mycpu>
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
    80000bf2:	db0080e7          	jalr	-592(ra) # 8000199e <mycpu>
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
    80000c32:	d70080e7          	jalr	-656(ra) # 8000199e <mycpu>
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
    80000c5e:	d44080e7          	jalr	-700(ra) # 8000199e <mycpu>
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
    80000eb4:	ade080e7          	jalr	-1314(ra) # 8000198e <cpuid>
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
    80000ed0:	ac2080e7          	jalr	-1342(ra) # 8000198e <cpuid>
    80000ed4:	85aa                	mv	a1,a0
    80000ed6:	00007517          	auipc	a0,0x7
    80000eda:	20250513          	addi	a0,a0,514 # 800080d8 <digits+0x98>
    80000ede:	fffff097          	auipc	ra,0xfffff
    80000ee2:	6ae080e7          	jalr	1710(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000ee6:	00000097          	auipc	ra,0x0
    80000eea:	0c8080e7          	jalr	200(ra) # 80000fae <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eee:	00001097          	auipc	ra,0x1
    80000ef2:	720080e7          	jalr	1824(ra) # 8000260e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef6:	00005097          	auipc	ra,0x5
    80000efa:	caa080e7          	jalr	-854(ra) # 80005ba0 <plicinithart>
  }

  scheduler();        
    80000efe:	00001097          	auipc	ra,0x1
    80000f02:	00c080e7          	jalr	12(ra) # 80001f0a <scheduler>
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
    80000f52:	970080e7          	jalr	-1680(ra) # 800018be <procinit>
    trapinit();      // trap vectors
    80000f56:	00001097          	auipc	ra,0x1
    80000f5a:	690080e7          	jalr	1680(ra) # 800025e6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	6b0080e7          	jalr	1712(ra) # 8000260e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f66:	00005097          	auipc	ra,0x5
    80000f6a:	c24080e7          	jalr	-988(ra) # 80005b8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	c32080e7          	jalr	-974(ra) # 80005ba0 <plicinithart>
    binit();         // buffer cache
    80000f76:	00002097          	auipc	ra,0x2
    80000f7a:	dd8080e7          	jalr	-552(ra) # 80002d4e <binit>
    iinit();         // inode cache
    80000f7e:	00002097          	auipc	ra,0x2
    80000f82:	46a080e7          	jalr	1130(ra) # 800033e8 <iinit>
    fileinit();      // file table
    80000f86:	00003097          	auipc	ra,0x3
    80000f8a:	408080e7          	jalr	1032(ra) # 8000438e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8e:	00005097          	auipc	ra,0x5
    80000f92:	d1a080e7          	jalr	-742(ra) # 80005ca8 <virtio_disk_init>
    userinit();      // first user process
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	d0a080e7          	jalr	-758(ra) # 80001ca0 <userinit>
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
    8000184e:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
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

000000008000187a <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000187a:	1101                	addi	sp,sp,-32
    8000187c:	ec06                	sd	ra,24(sp)
    8000187e:	e822                	sd	s0,16(sp)
    80001880:	e426                	sd	s1,8(sp)
    80001882:	1000                	addi	s0,sp,32
    80001884:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	2fe080e7          	jalr	766(ra) # 80000b84 <holding>
    8000188e:	c909                	beqz	a0,800018a0 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001890:	749c                	ld	a5,40(s1)
    80001892:	00978f63          	beq	a5,s1,800018b0 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001896:	60e2                	ld	ra,24(sp)
    80001898:	6442                	ld	s0,16(sp)
    8000189a:	64a2                	ld	s1,8(sp)
    8000189c:	6105                	addi	sp,sp,32
    8000189e:	8082                	ret
    panic("wakeup1");
    800018a0:	00007517          	auipc	a0,0x7
    800018a4:	94850513          	addi	a0,a0,-1720 # 800081e8 <digits+0x1a8>
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	c9a080e7          	jalr	-870(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018b0:	4c98                	lw	a4,24(s1)
    800018b2:	4785                	li	a5,1
    800018b4:	fef711e3          	bne	a4,a5,80001896 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018b8:	4789                	li	a5,2
    800018ba:	cc9c                	sw	a5,24(s1)
}
    800018bc:	bfe9                	j	80001896 <wakeup1+0x1c>

00000000800018be <procinit>:
{
    800018be:	715d                	addi	sp,sp,-80
    800018c0:	e486                	sd	ra,72(sp)
    800018c2:	e0a2                	sd	s0,64(sp)
    800018c4:	fc26                	sd	s1,56(sp)
    800018c6:	f84a                	sd	s2,48(sp)
    800018c8:	f44e                	sd	s3,40(sp)
    800018ca:	f052                	sd	s4,32(sp)
    800018cc:	ec56                	sd	s5,24(sp)
    800018ce:	e85a                	sd	s6,16(sp)
    800018d0:	e45e                	sd	s7,8(sp)
    800018d2:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800018d4:	00007597          	auipc	a1,0x7
    800018d8:	91c58593          	addi	a1,a1,-1764 # 800081f0 <digits+0x1b0>
    800018dc:	00010517          	auipc	a0,0x10
    800018e0:	07450513          	addi	a0,a0,116 # 80011950 <pid_lock>
    800018e4:	fffff097          	auipc	ra,0xfffff
    800018e8:	28a080e7          	jalr	650(ra) # 80000b6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ec:	00010917          	auipc	s2,0x10
    800018f0:	47c90913          	addi	s2,s2,1148 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    800018f4:	00007b97          	auipc	s7,0x7
    800018f8:	904b8b93          	addi	s7,s7,-1788 # 800081f8 <digits+0x1b8>
      uint64 va = KSTACK((int) (p - proc));
    800018fc:	8b4a                	mv	s6,s2
    800018fe:	00006a97          	auipc	s5,0x6
    80001902:	702a8a93          	addi	s5,s5,1794 # 80008000 <etext>
    80001906:	040009b7          	lui	s3,0x4000
    8000190a:	19fd                	addi	s3,s3,-1
    8000190c:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190e:	00016a17          	auipc	s4,0x16
    80001912:	e5aa0a13          	addi	s4,s4,-422 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001916:	85de                	mv	a1,s7
    80001918:	854a                	mv	a0,s2
    8000191a:	fffff097          	auipc	ra,0xfffff
    8000191e:	254080e7          	jalr	596(ra) # 80000b6e <initlock>
      char *pa = kalloc();
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	1ec080e7          	jalr	492(ra) # 80000b0e <kalloc>
    8000192a:	85aa                	mv	a1,a0
      if(pa == 0)
    8000192c:	c929                	beqz	a0,8000197e <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000192e:	416904b3          	sub	s1,s2,s6
    80001932:	848d                	srai	s1,s1,0x3
    80001934:	000ab783          	ld	a5,0(s5)
    80001938:	02f484b3          	mul	s1,s1,a5
    8000193c:	2485                	addiw	s1,s1,1
    8000193e:	00d4949b          	slliw	s1,s1,0xd
    80001942:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001946:	4699                	li	a3,6
    80001948:	6605                	lui	a2,0x1
    8000194a:	8526                	mv	a0,s1
    8000194c:	00000097          	auipc	ra,0x0
    80001950:	85a080e7          	jalr	-1958(ra) # 800011a6 <kvmmap>
      p->kstack = va;
    80001954:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001958:	16890913          	addi	s2,s2,360
    8000195c:	fb491de3          	bne	s2,s4,80001916 <procinit+0x58>
  kvminithart();
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	64e080e7          	jalr	1614(ra) # 80000fae <kvminithart>
}
    80001968:	60a6                	ld	ra,72(sp)
    8000196a:	6406                	ld	s0,64(sp)
    8000196c:	74e2                	ld	s1,56(sp)
    8000196e:	7942                	ld	s2,48(sp)
    80001970:	79a2                	ld	s3,40(sp)
    80001972:	7a02                	ld	s4,32(sp)
    80001974:	6ae2                	ld	s5,24(sp)
    80001976:	6b42                	ld	s6,16(sp)
    80001978:	6ba2                	ld	s7,8(sp)
    8000197a:	6161                	addi	sp,sp,80
    8000197c:	8082                	ret
        panic("kalloc");
    8000197e:	00007517          	auipc	a0,0x7
    80001982:	88250513          	addi	a0,a0,-1918 # 80008200 <digits+0x1c0>
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	bbc080e7          	jalr	-1092(ra) # 80000542 <panic>

000000008000198e <cpuid>:
{
    8000198e:	1141                	addi	sp,sp,-16
    80001990:	e422                	sd	s0,8(sp)
    80001992:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001994:	8512                	mv	a0,tp
}
    80001996:	2501                	sext.w	a0,a0
    80001998:	6422                	ld	s0,8(sp)
    8000199a:	0141                	addi	sp,sp,16
    8000199c:	8082                	ret

000000008000199e <mycpu>:
mycpu(void) {
    8000199e:	1141                	addi	sp,sp,-16
    800019a0:	e422                	sd	s0,8(sp)
    800019a2:	0800                	addi	s0,sp,16
    800019a4:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019a6:	2781                	sext.w	a5,a5
    800019a8:	079e                	slli	a5,a5,0x7
}
    800019aa:	00010517          	auipc	a0,0x10
    800019ae:	fbe50513          	addi	a0,a0,-66 # 80011968 <cpus>
    800019b2:	953e                	add	a0,a0,a5
    800019b4:	6422                	ld	s0,8(sp)
    800019b6:	0141                	addi	sp,sp,16
    800019b8:	8082                	ret

00000000800019ba <myproc>:
myproc(void) {
    800019ba:	1101                	addi	sp,sp,-32
    800019bc:	ec06                	sd	ra,24(sp)
    800019be:	e822                	sd	s0,16(sp)
    800019c0:	e426                	sd	s1,8(sp)
    800019c2:	1000                	addi	s0,sp,32
  push_off();
    800019c4:	fffff097          	auipc	ra,0xfffff
    800019c8:	1ee080e7          	jalr	494(ra) # 80000bb2 <push_off>
    800019cc:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019ce:	2781                	sext.w	a5,a5
    800019d0:	079e                	slli	a5,a5,0x7
    800019d2:	00010717          	auipc	a4,0x10
    800019d6:	f7e70713          	addi	a4,a4,-130 # 80011950 <pid_lock>
    800019da:	97ba                	add	a5,a5,a4
    800019dc:	6f84                	ld	s1,24(a5)
  pop_off();
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	274080e7          	jalr	628(ra) # 80000c52 <pop_off>
}
    800019e6:	8526                	mv	a0,s1
    800019e8:	60e2                	ld	ra,24(sp)
    800019ea:	6442                	ld	s0,16(sp)
    800019ec:	64a2                	ld	s1,8(sp)
    800019ee:	6105                	addi	sp,sp,32
    800019f0:	8082                	ret

00000000800019f2 <forkret>:
{
    800019f2:	1141                	addi	sp,sp,-16
    800019f4:	e406                	sd	ra,8(sp)
    800019f6:	e022                	sd	s0,0(sp)
    800019f8:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    800019fa:	00000097          	auipc	ra,0x0
    800019fe:	fc0080e7          	jalr	-64(ra) # 800019ba <myproc>
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	2b0080e7          	jalr	688(ra) # 80000cb2 <release>
  if (first) {
    80001a0a:	00007797          	auipc	a5,0x7
    80001a0e:	e567a783          	lw	a5,-426(a5) # 80008860 <first.1>
    80001a12:	eb89                	bnez	a5,80001a24 <forkret+0x32>
  usertrapret();
    80001a14:	00001097          	auipc	ra,0x1
    80001a18:	c12080e7          	jalr	-1006(ra) # 80002626 <usertrapret>
}
    80001a1c:	60a2                	ld	ra,8(sp)
    80001a1e:	6402                	ld	s0,0(sp)
    80001a20:	0141                	addi	sp,sp,16
    80001a22:	8082                	ret
    first = 0;
    80001a24:	00007797          	auipc	a5,0x7
    80001a28:	e207ae23          	sw	zero,-452(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a2c:	4505                	li	a0,1
    80001a2e:	00002097          	auipc	ra,0x2
    80001a32:	93a080e7          	jalr	-1734(ra) # 80003368 <fsinit>
    80001a36:	bff9                	j	80001a14 <forkret+0x22>

0000000080001a38 <allocpid>:
allocpid() {
    80001a38:	1101                	addi	sp,sp,-32
    80001a3a:	ec06                	sd	ra,24(sp)
    80001a3c:	e822                	sd	s0,16(sp)
    80001a3e:	e426                	sd	s1,8(sp)
    80001a40:	e04a                	sd	s2,0(sp)
    80001a42:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a44:	00010917          	auipc	s2,0x10
    80001a48:	f0c90913          	addi	s2,s2,-244 # 80011950 <pid_lock>
    80001a4c:	854a                	mv	a0,s2
    80001a4e:	fffff097          	auipc	ra,0xfffff
    80001a52:	1b0080e7          	jalr	432(ra) # 80000bfe <acquire>
  pid = nextpid;
    80001a56:	00007797          	auipc	a5,0x7
    80001a5a:	e0e78793          	addi	a5,a5,-498 # 80008864 <nextpid>
    80001a5e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a60:	0014871b          	addiw	a4,s1,1
    80001a64:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a66:	854a                	mv	a0,s2
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	24a080e7          	jalr	586(ra) # 80000cb2 <release>
}
    80001a70:	8526                	mv	a0,s1
    80001a72:	60e2                	ld	ra,24(sp)
    80001a74:	6442                	ld	s0,16(sp)
    80001a76:	64a2                	ld	s1,8(sp)
    80001a78:	6902                	ld	s2,0(sp)
    80001a7a:	6105                	addi	sp,sp,32
    80001a7c:	8082                	ret

0000000080001a7e <proc_pagetable>:
{
    80001a7e:	1101                	addi	sp,sp,-32
    80001a80:	ec06                	sd	ra,24(sp)
    80001a82:	e822                	sd	s0,16(sp)
    80001a84:	e426                	sd	s1,8(sp)
    80001a86:	e04a                	sd	s2,0(sp)
    80001a88:	1000                	addi	s0,sp,32
    80001a8a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a8c:	00000097          	auipc	ra,0x0
    80001a90:	8e8080e7          	jalr	-1816(ra) # 80001374 <uvmcreate>
    80001a94:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a96:	c121                	beqz	a0,80001ad6 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a98:	4729                	li	a4,10
    80001a9a:	00005697          	auipc	a3,0x5
    80001a9e:	56668693          	addi	a3,a3,1382 # 80007000 <_trampoline>
    80001aa2:	6605                	lui	a2,0x1
    80001aa4:	040005b7          	lui	a1,0x4000
    80001aa8:	15fd                	addi	a1,a1,-1
    80001aaa:	05b2                	slli	a1,a1,0xc
    80001aac:	fffff097          	auipc	ra,0xfffff
    80001ab0:	66c080e7          	jalr	1644(ra) # 80001118 <mappages>
    80001ab4:	02054863          	bltz	a0,80001ae4 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab8:	4719                	li	a4,6
    80001aba:	05893683          	ld	a3,88(s2)
    80001abe:	6605                	lui	a2,0x1
    80001ac0:	020005b7          	lui	a1,0x2000
    80001ac4:	15fd                	addi	a1,a1,-1
    80001ac6:	05b6                	slli	a1,a1,0xd
    80001ac8:	8526                	mv	a0,s1
    80001aca:	fffff097          	auipc	ra,0xfffff
    80001ace:	64e080e7          	jalr	1614(ra) # 80001118 <mappages>
    80001ad2:	02054163          	bltz	a0,80001af4 <proc_pagetable+0x76>
}
    80001ad6:	8526                	mv	a0,s1
    80001ad8:	60e2                	ld	ra,24(sp)
    80001ada:	6442                	ld	s0,16(sp)
    80001adc:	64a2                	ld	s1,8(sp)
    80001ade:	6902                	ld	s2,0(sp)
    80001ae0:	6105                	addi	sp,sp,32
    80001ae2:	8082                	ret
    uvmfree(pagetable, 0);
    80001ae4:	4581                	li	a1,0
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	00000097          	auipc	ra,0x0
    80001aec:	a88080e7          	jalr	-1400(ra) # 80001570 <uvmfree>
    return 0;
    80001af0:	4481                	li	s1,0
    80001af2:	b7d5                	j	80001ad6 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af4:	4681                	li	a3,0
    80001af6:	4605                	li	a2,1
    80001af8:	040005b7          	lui	a1,0x4000
    80001afc:	15fd                	addi	a1,a1,-1
    80001afe:	05b2                	slli	a1,a1,0xc
    80001b00:	8526                	mv	a0,s1
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	7ae080e7          	jalr	1966(ra) # 800012b0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b0a:	4581                	li	a1,0
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	00000097          	auipc	ra,0x0
    80001b12:	a62080e7          	jalr	-1438(ra) # 80001570 <uvmfree>
    return 0;
    80001b16:	4481                	li	s1,0
    80001b18:	bf7d                	j	80001ad6 <proc_pagetable+0x58>

0000000080001b1a <proc_freepagetable>:
{
    80001b1a:	1101                	addi	sp,sp,-32
    80001b1c:	ec06                	sd	ra,24(sp)
    80001b1e:	e822                	sd	s0,16(sp)
    80001b20:	e426                	sd	s1,8(sp)
    80001b22:	e04a                	sd	s2,0(sp)
    80001b24:	1000                	addi	s0,sp,32
    80001b26:	84aa                	mv	s1,a0
    80001b28:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b2a:	4681                	li	a3,0
    80001b2c:	4605                	li	a2,1
    80001b2e:	040005b7          	lui	a1,0x4000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b2                	slli	a1,a1,0xc
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	77a080e7          	jalr	1914(ra) # 800012b0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b3e:	4681                	li	a3,0
    80001b40:	4605                	li	a2,1
    80001b42:	020005b7          	lui	a1,0x2000
    80001b46:	15fd                	addi	a1,a1,-1
    80001b48:	05b6                	slli	a1,a1,0xd
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	fffff097          	auipc	ra,0xfffff
    80001b50:	764080e7          	jalr	1892(ra) # 800012b0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b54:	85ca                	mv	a1,s2
    80001b56:	8526                	mv	a0,s1
    80001b58:	00000097          	auipc	ra,0x0
    80001b5c:	a18080e7          	jalr	-1512(ra) # 80001570 <uvmfree>
}
    80001b60:	60e2                	ld	ra,24(sp)
    80001b62:	6442                	ld	s0,16(sp)
    80001b64:	64a2                	ld	s1,8(sp)
    80001b66:	6902                	ld	s2,0(sp)
    80001b68:	6105                	addi	sp,sp,32
    80001b6a:	8082                	ret

0000000080001b6c <freeproc>:
{
    80001b6c:	1101                	addi	sp,sp,-32
    80001b6e:	ec06                	sd	ra,24(sp)
    80001b70:	e822                	sd	s0,16(sp)
    80001b72:	e426                	sd	s1,8(sp)
    80001b74:	1000                	addi	s0,sp,32
    80001b76:	84aa                	mv	s1,a0
  printf("%s (pid=%d): Q2(%d%%), Q1(%d%%), Q0(%d%%)\n",
    80001b78:	4781                	li	a5,0
    80001b7a:	4701                	li	a4,0
    80001b7c:	4681                	li	a3,0
    80001b7e:	5d10                	lw	a2,56(a0)
    80001b80:	15850593          	addi	a1,a0,344
    80001b84:	00006517          	auipc	a0,0x6
    80001b88:	68450513          	addi	a0,a0,1668 # 80008208 <digits+0x1c8>
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	a00080e7          	jalr	-1536(ra) # 8000058c <printf>
  if(p->trapframe)
    80001b94:	6ca8                	ld	a0,88(s1)
    80001b96:	c509                	beqz	a0,80001ba0 <freeproc+0x34>
    kfree((void*)p->trapframe);
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	e7a080e7          	jalr	-390(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001ba0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ba4:	68a8                	ld	a0,80(s1)
    80001ba6:	c511                	beqz	a0,80001bb2 <freeproc+0x46>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba8:	64ac                	ld	a1,72(s1)
    80001baa:	00000097          	auipc	ra,0x0
    80001bae:	f70080e7          	jalr	-144(ra) # 80001b1a <proc_freepagetable>
  p->pagetable = 0;
    80001bb2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bb6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bba:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bbe:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bc2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bc6:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bca:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bce:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bd2:	0004ac23          	sw	zero,24(s1)
}
    80001bd6:	60e2                	ld	ra,24(sp)
    80001bd8:	6442                	ld	s0,16(sp)
    80001bda:	64a2                	ld	s1,8(sp)
    80001bdc:	6105                	addi	sp,sp,32
    80001bde:	8082                	ret

0000000080001be0 <allocproc>:
{
    80001be0:	1101                	addi	sp,sp,-32
    80001be2:	ec06                	sd	ra,24(sp)
    80001be4:	e822                	sd	s0,16(sp)
    80001be6:	e426                	sd	s1,8(sp)
    80001be8:	e04a                	sd	s2,0(sp)
    80001bea:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bec:	00010497          	auipc	s1,0x10
    80001bf0:	17c48493          	addi	s1,s1,380 # 80011d68 <proc>
    80001bf4:	00016917          	auipc	s2,0x16
    80001bf8:	b7490913          	addi	s2,s2,-1164 # 80017768 <tickslock>
    acquire(&p->lock);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	000080e7          	jalr	ra # 80000bfe <acquire>
    if(p->state == UNUSED) {
    80001c06:	4c9c                	lw	a5,24(s1)
    80001c08:	cf81                	beqz	a5,80001c20 <allocproc+0x40>
      release(&p->lock);
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	0a6080e7          	jalr	166(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c14:	16848493          	addi	s1,s1,360
    80001c18:	ff2492e3          	bne	s1,s2,80001bfc <allocproc+0x1c>
  return 0;
    80001c1c:	4481                	li	s1,0
    80001c1e:	a0b9                	j	80001c6c <allocproc+0x8c>
  p->pid = allocpid();
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	e18080e7          	jalr	-488(ra) # 80001a38 <allocpid>
    80001c28:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	ee4080e7          	jalr	-284(ra) # 80000b0e <kalloc>
    80001c32:	892a                	mv	s2,a0
    80001c34:	eca8                	sd	a0,88(s1)
    80001c36:	c131                	beqz	a0,80001c7a <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	e44080e7          	jalr	-444(ra) # 80001a7e <proc_pagetable>
    80001c42:	892a                	mv	s2,a0
    80001c44:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c46:	c129                	beqz	a0,80001c88 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c48:	07000613          	li	a2,112
    80001c4c:	4581                	li	a1,0
    80001c4e:	06048513          	addi	a0,s1,96
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	0a8080e7          	jalr	168(ra) # 80000cfa <memset>
  p->context.ra = (uint64)forkret;
    80001c5a:	00000797          	auipc	a5,0x0
    80001c5e:	d9878793          	addi	a5,a5,-616 # 800019f2 <forkret>
    80001c62:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c64:	60bc                	ld	a5,64(s1)
    80001c66:	6705                	lui	a4,0x1
    80001c68:	97ba                	add	a5,a5,a4
    80001c6a:	f4bc                	sd	a5,104(s1)
}
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	60e2                	ld	ra,24(sp)
    80001c70:	6442                	ld	s0,16(sp)
    80001c72:	64a2                	ld	s1,8(sp)
    80001c74:	6902                	ld	s2,0(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	036080e7          	jalr	54(ra) # 80000cb2 <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7dd                	j	80001c6c <allocproc+0x8c>
    freeproc(p);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	ee2080e7          	jalr	-286(ra) # 80001b6c <freeproc>
    release(&p->lock);
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	01e080e7          	jalr	30(ra) # 80000cb2 <release>
    return 0;
    80001c9c:	84ca                	mv	s1,s2
    80001c9e:	b7f9                	j	80001c6c <allocproc+0x8c>

0000000080001ca0 <userinit>:
{
    80001ca0:	1101                	addi	sp,sp,-32
    80001ca2:	ec06                	sd	ra,24(sp)
    80001ca4:	e822                	sd	s0,16(sp)
    80001ca6:	e426                	sd	s1,8(sp)
    80001ca8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001caa:	00000097          	auipc	ra,0x0
    80001cae:	f36080e7          	jalr	-202(ra) # 80001be0 <allocproc>
    80001cb2:	84aa                	mv	s1,a0
  initproc = p;
    80001cb4:	00007797          	auipc	a5,0x7
    80001cb8:	36a7b223          	sd	a0,868(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cbc:	03400613          	li	a2,52
    80001cc0:	00007597          	auipc	a1,0x7
    80001cc4:	bb058593          	addi	a1,a1,-1104 # 80008870 <initcode>
    80001cc8:	6928                	ld	a0,80(a0)
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	6d8080e7          	jalr	1752(ra) # 800013a2 <uvminit>
  p->sz = PGSIZE;
    80001cd2:	6785                	lui	a5,0x1
    80001cd4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd6:	6cb8                	ld	a4,88(s1)
    80001cd8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cdc:	6cb8                	ld	a4,88(s1)
    80001cde:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce0:	4641                	li	a2,16
    80001ce2:	00006597          	auipc	a1,0x6
    80001ce6:	55658593          	addi	a1,a1,1366 # 80008238 <digits+0x1f8>
    80001cea:	15848513          	addi	a0,s1,344
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	15e080e7          	jalr	350(ra) # 80000e4c <safestrcpy>
  p->cwd = namei("/");
    80001cf6:	00006517          	auipc	a0,0x6
    80001cfa:	55250513          	addi	a0,a0,1362 # 80008248 <digits+0x208>
    80001cfe:	00002097          	auipc	ra,0x2
    80001d02:	092080e7          	jalr	146(ra) # 80003d90 <namei>
    80001d06:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d0a:	4789                	li	a5,2
    80001d0c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0e:	8526                	mv	a0,s1
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	fa2080e7          	jalr	-94(ra) # 80000cb2 <release>
}
    80001d18:	60e2                	ld	ra,24(sp)
    80001d1a:	6442                	ld	s0,16(sp)
    80001d1c:	64a2                	ld	s1,8(sp)
    80001d1e:	6105                	addi	sp,sp,32
    80001d20:	8082                	ret

0000000080001d22 <growproc>:
{
    80001d22:	1101                	addi	sp,sp,-32
    80001d24:	ec06                	sd	ra,24(sp)
    80001d26:	e822                	sd	s0,16(sp)
    80001d28:	e426                	sd	s1,8(sp)
    80001d2a:	e04a                	sd	s2,0(sp)
    80001d2c:	1000                	addi	s0,sp,32
    80001d2e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d30:	00000097          	auipc	ra,0x0
    80001d34:	c8a080e7          	jalr	-886(ra) # 800019ba <myproc>
    80001d38:	892a                	mv	s2,a0
  sz = p->sz;
    80001d3a:	652c                	ld	a1,72(a0)
    80001d3c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d40:	00904f63          	bgtz	s1,80001d5e <growproc+0x3c>
  } else if(n < 0){
    80001d44:	0204cc63          	bltz	s1,80001d7c <growproc+0x5a>
  p->sz = sz;
    80001d48:	1602                	slli	a2,a2,0x20
    80001d4a:	9201                	srli	a2,a2,0x20
    80001d4c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d50:	4501                	li	a0,0
}
    80001d52:	60e2                	ld	ra,24(sp)
    80001d54:	6442                	ld	s0,16(sp)
    80001d56:	64a2                	ld	s1,8(sp)
    80001d58:	6902                	ld	s2,0(sp)
    80001d5a:	6105                	addi	sp,sp,32
    80001d5c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d5e:	9e25                	addw	a2,a2,s1
    80001d60:	1602                	slli	a2,a2,0x20
    80001d62:	9201                	srli	a2,a2,0x20
    80001d64:	1582                	slli	a1,a1,0x20
    80001d66:	9181                	srli	a1,a1,0x20
    80001d68:	6928                	ld	a0,80(a0)
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	6f2080e7          	jalr	1778(ra) # 8000145c <uvmalloc>
    80001d72:	0005061b          	sext.w	a2,a0
    80001d76:	fa69                	bnez	a2,80001d48 <growproc+0x26>
      return -1;
    80001d78:	557d                	li	a0,-1
    80001d7a:	bfe1                	j	80001d52 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d7c:	9e25                	addw	a2,a2,s1
    80001d7e:	1602                	slli	a2,a2,0x20
    80001d80:	9201                	srli	a2,a2,0x20
    80001d82:	1582                	slli	a1,a1,0x20
    80001d84:	9181                	srli	a1,a1,0x20
    80001d86:	6928                	ld	a0,80(a0)
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	68c080e7          	jalr	1676(ra) # 80001414 <uvmdealloc>
    80001d90:	0005061b          	sext.w	a2,a0
    80001d94:	bf55                	j	80001d48 <growproc+0x26>

0000000080001d96 <fork>:
{
    80001d96:	7139                	addi	sp,sp,-64
    80001d98:	fc06                	sd	ra,56(sp)
    80001d9a:	f822                	sd	s0,48(sp)
    80001d9c:	f426                	sd	s1,40(sp)
    80001d9e:	f04a                	sd	s2,32(sp)
    80001da0:	ec4e                	sd	s3,24(sp)
    80001da2:	e852                	sd	s4,16(sp)
    80001da4:	e456                	sd	s5,8(sp)
    80001da6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	c12080e7          	jalr	-1006(ra) # 800019ba <myproc>
    80001db0:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	e2e080e7          	jalr	-466(ra) # 80001be0 <allocproc>
    80001dba:	c17d                	beqz	a0,80001ea0 <fork+0x10a>
    80001dbc:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dbe:	048ab603          	ld	a2,72(s5)
    80001dc2:	692c                	ld	a1,80(a0)
    80001dc4:	050ab503          	ld	a0,80(s5)
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	7e0080e7          	jalr	2016(ra) # 800015a8 <uvmcopy>
    80001dd0:	04054a63          	bltz	a0,80001e24 <fork+0x8e>
  np->sz = p->sz;
    80001dd4:	048ab783          	ld	a5,72(s5)
    80001dd8:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001ddc:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001de0:	058ab683          	ld	a3,88(s5)
    80001de4:	87b6                	mv	a5,a3
    80001de6:	058a3703          	ld	a4,88(s4)
    80001dea:	12068693          	addi	a3,a3,288
    80001dee:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df2:	6788                	ld	a0,8(a5)
    80001df4:	6b8c                	ld	a1,16(a5)
    80001df6:	6f90                	ld	a2,24(a5)
    80001df8:	01073023          	sd	a6,0(a4)
    80001dfc:	e708                	sd	a0,8(a4)
    80001dfe:	eb0c                	sd	a1,16(a4)
    80001e00:	ef10                	sd	a2,24(a4)
    80001e02:	02078793          	addi	a5,a5,32
    80001e06:	02070713          	addi	a4,a4,32
    80001e0a:	fed792e3          	bne	a5,a3,80001dee <fork+0x58>
  np->trapframe->a0 = 0;
    80001e0e:	058a3783          	ld	a5,88(s4)
    80001e12:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e16:	0d0a8493          	addi	s1,s5,208
    80001e1a:	0d0a0913          	addi	s2,s4,208
    80001e1e:	150a8993          	addi	s3,s5,336
    80001e22:	a00d                	j	80001e44 <fork+0xae>
    freeproc(np);
    80001e24:	8552                	mv	a0,s4
    80001e26:	00000097          	auipc	ra,0x0
    80001e2a:	d46080e7          	jalr	-698(ra) # 80001b6c <freeproc>
    release(&np->lock);
    80001e2e:	8552                	mv	a0,s4
    80001e30:	fffff097          	auipc	ra,0xfffff
    80001e34:	e82080e7          	jalr	-382(ra) # 80000cb2 <release>
    return -1;
    80001e38:	54fd                	li	s1,-1
    80001e3a:	a889                	j	80001e8c <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001e3c:	04a1                	addi	s1,s1,8
    80001e3e:	0921                	addi	s2,s2,8
    80001e40:	01348b63          	beq	s1,s3,80001e56 <fork+0xc0>
    if(p->ofile[i])
    80001e44:	6088                	ld	a0,0(s1)
    80001e46:	d97d                	beqz	a0,80001e3c <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e48:	00002097          	auipc	ra,0x2
    80001e4c:	5d8080e7          	jalr	1496(ra) # 80004420 <filedup>
    80001e50:	00a93023          	sd	a0,0(s2)
    80001e54:	b7e5                	j	80001e3c <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e56:	150ab503          	ld	a0,336(s5)
    80001e5a:	00001097          	auipc	ra,0x1
    80001e5e:	748080e7          	jalr	1864(ra) # 800035a2 <idup>
    80001e62:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e66:	4641                	li	a2,16
    80001e68:	158a8593          	addi	a1,s5,344
    80001e6c:	158a0513          	addi	a0,s4,344
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	fdc080e7          	jalr	-36(ra) # 80000e4c <safestrcpy>
  pid = np->pid;
    80001e78:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001e7c:	4789                	li	a5,2
    80001e7e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e82:	8552                	mv	a0,s4
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e2e080e7          	jalr	-466(ra) # 80000cb2 <release>
}
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	70e2                	ld	ra,56(sp)
    80001e90:	7442                	ld	s0,48(sp)
    80001e92:	74a2                	ld	s1,40(sp)
    80001e94:	7902                	ld	s2,32(sp)
    80001e96:	69e2                	ld	s3,24(sp)
    80001e98:	6a42                	ld	s4,16(sp)
    80001e9a:	6aa2                	ld	s5,8(sp)
    80001e9c:	6121                	addi	sp,sp,64
    80001e9e:	8082                	ret
    return -1;
    80001ea0:	54fd                	li	s1,-1
    80001ea2:	b7ed                	j	80001e8c <fork+0xf6>

0000000080001ea4 <reparent>:
{
    80001ea4:	7179                	addi	sp,sp,-48
    80001ea6:	f406                	sd	ra,40(sp)
    80001ea8:	f022                	sd	s0,32(sp)
    80001eaa:	ec26                	sd	s1,24(sp)
    80001eac:	e84a                	sd	s2,16(sp)
    80001eae:	e44e                	sd	s3,8(sp)
    80001eb0:	e052                	sd	s4,0(sp)
    80001eb2:	1800                	addi	s0,sp,48
    80001eb4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eb6:	00010497          	auipc	s1,0x10
    80001eba:	eb248493          	addi	s1,s1,-334 # 80011d68 <proc>
      pp->parent = initproc;
    80001ebe:	00007a17          	auipc	s4,0x7
    80001ec2:	15aa0a13          	addi	s4,s4,346 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ec6:	00016997          	auipc	s3,0x16
    80001eca:	8a298993          	addi	s3,s3,-1886 # 80017768 <tickslock>
    80001ece:	a029                	j	80001ed8 <reparent+0x34>
    80001ed0:	16848493          	addi	s1,s1,360
    80001ed4:	03348363          	beq	s1,s3,80001efa <reparent+0x56>
    if(pp->parent == p){
    80001ed8:	709c                	ld	a5,32(s1)
    80001eda:	ff279be3          	bne	a5,s2,80001ed0 <reparent+0x2c>
      acquire(&pp->lock);
    80001ede:	8526                	mv	a0,s1
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	d1e080e7          	jalr	-738(ra) # 80000bfe <acquire>
      pp->parent = initproc;
    80001ee8:	000a3783          	ld	a5,0(s4)
    80001eec:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	dc2080e7          	jalr	-574(ra) # 80000cb2 <release>
    80001ef8:	bfe1                	j	80001ed0 <reparent+0x2c>
}
    80001efa:	70a2                	ld	ra,40(sp)
    80001efc:	7402                	ld	s0,32(sp)
    80001efe:	64e2                	ld	s1,24(sp)
    80001f00:	6942                	ld	s2,16(sp)
    80001f02:	69a2                	ld	s3,8(sp)
    80001f04:	6a02                	ld	s4,0(sp)
    80001f06:	6145                	addi	sp,sp,48
    80001f08:	8082                	ret

0000000080001f0a <scheduler>:
{
    80001f0a:	7139                	addi	sp,sp,-64
    80001f0c:	fc06                	sd	ra,56(sp)
    80001f0e:	f822                	sd	s0,48(sp)
    80001f10:	f426                	sd	s1,40(sp)
    80001f12:	f04a                	sd	s2,32(sp)
    80001f14:	ec4e                	sd	s3,24(sp)
    80001f16:	e852                	sd	s4,16(sp)
    80001f18:	e456                	sd	s5,8(sp)
    80001f1a:	e05a                	sd	s6,0(sp)
    80001f1c:	0080                	addi	s0,sp,64
    80001f1e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f20:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f22:	00779a93          	slli	s5,a5,0x7
    80001f26:	00010717          	auipc	a4,0x10
    80001f2a:	a2a70713          	addi	a4,a4,-1494 # 80011950 <pid_lock>
    80001f2e:	9756                	add	a4,a4,s5
    80001f30:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f34:	00010717          	auipc	a4,0x10
    80001f38:	a3c70713          	addi	a4,a4,-1476 # 80011970 <cpus+0x8>
    80001f3c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f3e:	4989                	li	s3,2
        p->state = RUNNING;
    80001f40:	4b0d                	li	s6,3
        c->proc = p;
    80001f42:	079e                	slli	a5,a5,0x7
    80001f44:	00010a17          	auipc	s4,0x10
    80001f48:	a0ca0a13          	addi	s4,s4,-1524 # 80011950 <pid_lock>
    80001f4c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4e:	00016917          	auipc	s2,0x16
    80001f52:	81a90913          	addi	s2,s2,-2022 # 80017768 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f5e:	10079073          	csrw	sstatus,a5
    80001f62:	00010497          	auipc	s1,0x10
    80001f66:	e0648493          	addi	s1,s1,-506 # 80011d68 <proc>
    80001f6a:	a811                	j	80001f7e <scheduler+0x74>
      release(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d44080e7          	jalr	-700(ra) # 80000cb2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f76:	16848493          	addi	s1,s1,360
    80001f7a:	fd248ee3          	beq	s1,s2,80001f56 <scheduler+0x4c>
      acquire(&p->lock);
    80001f7e:	8526                	mv	a0,s1
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	c7e080e7          	jalr	-898(ra) # 80000bfe <acquire>
      if(p->state == RUNNABLE) {
    80001f88:	4c9c                	lw	a5,24(s1)
    80001f8a:	ff3791e3          	bne	a5,s3,80001f6c <scheduler+0x62>
        p->state = RUNNING;
    80001f8e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f92:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001f96:	06048593          	addi	a1,s1,96
    80001f9a:	8556                	mv	a0,s5
    80001f9c:	00000097          	auipc	ra,0x0
    80001fa0:	5e0080e7          	jalr	1504(ra) # 8000257c <swtch>
        c->proc = 0;
    80001fa4:	000a3c23          	sd	zero,24(s4)
    80001fa8:	b7d1                	j	80001f6c <scheduler+0x62>

0000000080001faa <sched>:
{
    80001faa:	7179                	addi	sp,sp,-48
    80001fac:	f406                	sd	ra,40(sp)
    80001fae:	f022                	sd	s0,32(sp)
    80001fb0:	ec26                	sd	s1,24(sp)
    80001fb2:	e84a                	sd	s2,16(sp)
    80001fb4:	e44e                	sd	s3,8(sp)
    80001fb6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	a02080e7          	jalr	-1534(ra) # 800019ba <myproc>
    80001fc0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	bc2080e7          	jalr	-1086(ra) # 80000b84 <holding>
    80001fca:	c93d                	beqz	a0,80002040 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fcc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fce:	2781                	sext.w	a5,a5
    80001fd0:	079e                	slli	a5,a5,0x7
    80001fd2:	00010717          	auipc	a4,0x10
    80001fd6:	97e70713          	addi	a4,a4,-1666 # 80011950 <pid_lock>
    80001fda:	97ba                	add	a5,a5,a4
    80001fdc:	0907a703          	lw	a4,144(a5)
    80001fe0:	4785                	li	a5,1
    80001fe2:	06f71763          	bne	a4,a5,80002050 <sched+0xa6>
  if(p->state == RUNNING)
    80001fe6:	4c98                	lw	a4,24(s1)
    80001fe8:	478d                	li	a5,3
    80001fea:	06f70b63          	beq	a4,a5,80002060 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ff2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001ff4:	efb5                	bnez	a5,80002070 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ff8:	00010917          	auipc	s2,0x10
    80001ffc:	95890913          	addi	s2,s2,-1704 # 80011950 <pid_lock>
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	97ca                	add	a5,a5,s2
    80002006:	0947a983          	lw	s3,148(a5)
    8000200a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	00010597          	auipc	a1,0x10
    80002014:	96058593          	addi	a1,a1,-1696 # 80011970 <cpus+0x8>
    80002018:	95be                	add	a1,a1,a5
    8000201a:	06048513          	addi	a0,s1,96
    8000201e:	00000097          	auipc	ra,0x0
    80002022:	55e080e7          	jalr	1374(ra) # 8000257c <swtch>
    80002026:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002028:	2781                	sext.w	a5,a5
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	97ca                	add	a5,a5,s2
    8000202e:	0937aa23          	sw	s3,148(a5)
}
    80002032:	70a2                	ld	ra,40(sp)
    80002034:	7402                	ld	s0,32(sp)
    80002036:	64e2                	ld	s1,24(sp)
    80002038:	6942                	ld	s2,16(sp)
    8000203a:	69a2                	ld	s3,8(sp)
    8000203c:	6145                	addi	sp,sp,48
    8000203e:	8082                	ret
    panic("sched p->lock");
    80002040:	00006517          	auipc	a0,0x6
    80002044:	21050513          	addi	a0,a0,528 # 80008250 <digits+0x210>
    80002048:	ffffe097          	auipc	ra,0xffffe
    8000204c:	4fa080e7          	jalr	1274(ra) # 80000542 <panic>
    panic("sched locks");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	21050513          	addi	a0,a0,528 # 80008260 <digits+0x220>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4ea080e7          	jalr	1258(ra) # 80000542 <panic>
    panic("sched running");
    80002060:	00006517          	auipc	a0,0x6
    80002064:	21050513          	addi	a0,a0,528 # 80008270 <digits+0x230>
    80002068:	ffffe097          	auipc	ra,0xffffe
    8000206c:	4da080e7          	jalr	1242(ra) # 80000542 <panic>
    panic("sched interruptible");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	21050513          	addi	a0,a0,528 # 80008280 <digits+0x240>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4ca080e7          	jalr	1226(ra) # 80000542 <panic>

0000000080002080 <exit>:
{
    80002080:	7179                	addi	sp,sp,-48
    80002082:	f406                	sd	ra,40(sp)
    80002084:	f022                	sd	s0,32(sp)
    80002086:	ec26                	sd	s1,24(sp)
    80002088:	e84a                	sd	s2,16(sp)
    8000208a:	e44e                	sd	s3,8(sp)
    8000208c:	e052                	sd	s4,0(sp)
    8000208e:	1800                	addi	s0,sp,48
    80002090:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002092:	00000097          	auipc	ra,0x0
    80002096:	928080e7          	jalr	-1752(ra) # 800019ba <myproc>
    8000209a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000209c:	00007797          	auipc	a5,0x7
    800020a0:	f7c7b783          	ld	a5,-132(a5) # 80009018 <initproc>
    800020a4:	0d050493          	addi	s1,a0,208
    800020a8:	15050913          	addi	s2,a0,336
    800020ac:	02a79363          	bne	a5,a0,800020d2 <exit+0x52>
    panic("init exiting");
    800020b0:	00006517          	auipc	a0,0x6
    800020b4:	1e850513          	addi	a0,a0,488 # 80008298 <digits+0x258>
    800020b8:	ffffe097          	auipc	ra,0xffffe
    800020bc:	48a080e7          	jalr	1162(ra) # 80000542 <panic>
      fileclose(f);
    800020c0:	00002097          	auipc	ra,0x2
    800020c4:	3b2080e7          	jalr	946(ra) # 80004472 <fileclose>
      p->ofile[fd] = 0;
    800020c8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020cc:	04a1                	addi	s1,s1,8
    800020ce:	01248563          	beq	s1,s2,800020d8 <exit+0x58>
    if(p->ofile[fd]){
    800020d2:	6088                	ld	a0,0(s1)
    800020d4:	f575                	bnez	a0,800020c0 <exit+0x40>
    800020d6:	bfdd                	j	800020cc <exit+0x4c>
  begin_op();
    800020d8:	00002097          	auipc	ra,0x2
    800020dc:	ec8080e7          	jalr	-312(ra) # 80003fa0 <begin_op>
  iput(p->cwd);
    800020e0:	1509b503          	ld	a0,336(s3)
    800020e4:	00001097          	auipc	ra,0x1
    800020e8:	6b6080e7          	jalr	1718(ra) # 8000379a <iput>
  end_op();
    800020ec:	00002097          	auipc	ra,0x2
    800020f0:	f34080e7          	jalr	-204(ra) # 80004020 <end_op>
  p->cwd = 0;
    800020f4:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800020f8:	00007497          	auipc	s1,0x7
    800020fc:	f2048493          	addi	s1,s1,-224 # 80009018 <initproc>
    80002100:	6088                	ld	a0,0(s1)
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	afc080e7          	jalr	-1284(ra) # 80000bfe <acquire>
  wakeup1(initproc);
    8000210a:	6088                	ld	a0,0(s1)
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	76e080e7          	jalr	1902(ra) # 8000187a <wakeup1>
  release(&initproc->lock);
    80002114:	6088                	ld	a0,0(s1)
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b9c080e7          	jalr	-1124(ra) # 80000cb2 <release>
  acquire(&p->lock);
    8000211e:	854e                	mv	a0,s3
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	ade080e7          	jalr	-1314(ra) # 80000bfe <acquire>
  struct proc *original_parent = p->parent;
    80002128:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000212c:	854e                	mv	a0,s3
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	b84080e7          	jalr	-1148(ra) # 80000cb2 <release>
  acquire(&original_parent->lock);
    80002136:	8526                	mv	a0,s1
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	ac6080e7          	jalr	-1338(ra) # 80000bfe <acquire>
  acquire(&p->lock);
    80002140:	854e                	mv	a0,s3
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	abc080e7          	jalr	-1348(ra) # 80000bfe <acquire>
  reparent(p);
    8000214a:	854e                	mv	a0,s3
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	d58080e7          	jalr	-680(ra) # 80001ea4 <reparent>
  wakeup1(original_parent);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	724080e7          	jalr	1828(ra) # 8000187a <wakeup1>
  p->xstate = status;
    8000215e:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002162:	4791                	li	a5,4
    80002164:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002168:	8526                	mv	a0,s1
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	b48080e7          	jalr	-1208(ra) # 80000cb2 <release>
  sched();
    80002172:	00000097          	auipc	ra,0x0
    80002176:	e38080e7          	jalr	-456(ra) # 80001faa <sched>
  panic("zombie exit");
    8000217a:	00006517          	auipc	a0,0x6
    8000217e:	12e50513          	addi	a0,a0,302 # 800082a8 <digits+0x268>
    80002182:	ffffe097          	auipc	ra,0xffffe
    80002186:	3c0080e7          	jalr	960(ra) # 80000542 <panic>

000000008000218a <yield>:
{
    8000218a:	1101                	addi	sp,sp,-32
    8000218c:	ec06                	sd	ra,24(sp)
    8000218e:	e822                	sd	s0,16(sp)
    80002190:	e426                	sd	s1,8(sp)
    80002192:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002194:	00000097          	auipc	ra,0x0
    80002198:	826080e7          	jalr	-2010(ra) # 800019ba <myproc>
    8000219c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	a60080e7          	jalr	-1440(ra) # 80000bfe <acquire>
  p->state = RUNNABLE;
    800021a6:	4789                	li	a5,2
    800021a8:	cc9c                	sw	a5,24(s1)
  sched();
    800021aa:	00000097          	auipc	ra,0x0
    800021ae:	e00080e7          	jalr	-512(ra) # 80001faa <sched>
  release(&p->lock);
    800021b2:	8526                	mv	a0,s1
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	afe080e7          	jalr	-1282(ra) # 80000cb2 <release>
}
    800021bc:	60e2                	ld	ra,24(sp)
    800021be:	6442                	ld	s0,16(sp)
    800021c0:	64a2                	ld	s1,8(sp)
    800021c2:	6105                	addi	sp,sp,32
    800021c4:	8082                	ret

00000000800021c6 <sleep>:
{
    800021c6:	7179                	addi	sp,sp,-48
    800021c8:	f406                	sd	ra,40(sp)
    800021ca:	f022                	sd	s0,32(sp)
    800021cc:	ec26                	sd	s1,24(sp)
    800021ce:	e84a                	sd	s2,16(sp)
    800021d0:	e44e                	sd	s3,8(sp)
    800021d2:	1800                	addi	s0,sp,48
    800021d4:	89aa                	mv	s3,a0
    800021d6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	7e2080e7          	jalr	2018(ra) # 800019ba <myproc>
    800021e0:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800021e2:	05250663          	beq	a0,s2,8000222e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	a18080e7          	jalr	-1512(ra) # 80000bfe <acquire>
    release(lk);
    800021ee:	854a                	mv	a0,s2
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	ac2080e7          	jalr	-1342(ra) # 80000cb2 <release>
  p->chan = chan;
    800021f8:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800021fc:	4785                	li	a5,1
    800021fe:	cc9c                	sw	a5,24(s1)
  sched();
    80002200:	00000097          	auipc	ra,0x0
    80002204:	daa080e7          	jalr	-598(ra) # 80001faa <sched>
  p->chan = 0;
    80002208:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	aa4080e7          	jalr	-1372(ra) # 80000cb2 <release>
    acquire(lk);
    80002216:	854a                	mv	a0,s2
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	9e6080e7          	jalr	-1562(ra) # 80000bfe <acquire>
}
    80002220:	70a2                	ld	ra,40(sp)
    80002222:	7402                	ld	s0,32(sp)
    80002224:	64e2                	ld	s1,24(sp)
    80002226:	6942                	ld	s2,16(sp)
    80002228:	69a2                	ld	s3,8(sp)
    8000222a:	6145                	addi	sp,sp,48
    8000222c:	8082                	ret
  p->chan = chan;
    8000222e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002232:	4785                	li	a5,1
    80002234:	cd1c                	sw	a5,24(a0)
  sched();
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	d74080e7          	jalr	-652(ra) # 80001faa <sched>
  p->chan = 0;
    8000223e:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002242:	bff9                	j	80002220 <sleep+0x5a>

0000000080002244 <wait>:
{
    80002244:	715d                	addi	sp,sp,-80
    80002246:	e486                	sd	ra,72(sp)
    80002248:	e0a2                	sd	s0,64(sp)
    8000224a:	fc26                	sd	s1,56(sp)
    8000224c:	f84a                	sd	s2,48(sp)
    8000224e:	f44e                	sd	s3,40(sp)
    80002250:	f052                	sd	s4,32(sp)
    80002252:	ec56                	sd	s5,24(sp)
    80002254:	e85a                	sd	s6,16(sp)
    80002256:	e45e                	sd	s7,8(sp)
    80002258:	0880                	addi	s0,sp,80
    8000225a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	75e080e7          	jalr	1886(ra) # 800019ba <myproc>
    80002264:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	998080e7          	jalr	-1640(ra) # 80000bfe <acquire>
    havekids = 0;
    8000226e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002270:	4a11                	li	s4,4
        havekids = 1;
    80002272:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002274:	00015997          	auipc	s3,0x15
    80002278:	4f498993          	addi	s3,s3,1268 # 80017768 <tickslock>
    havekids = 0;
    8000227c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000227e:	00010497          	auipc	s1,0x10
    80002282:	aea48493          	addi	s1,s1,-1302 # 80011d68 <proc>
    80002286:	a08d                	j	800022e8 <wait+0xa4>
          pid = np->pid;
    80002288:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000228c:	000b0e63          	beqz	s6,800022a8 <wait+0x64>
    80002290:	4691                	li	a3,4
    80002292:	03448613          	addi	a2,s1,52
    80002296:	85da                	mv	a1,s6
    80002298:	05093503          	ld	a0,80(s2)
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	410080e7          	jalr	1040(ra) # 800016ac <copyout>
    800022a4:	02054263          	bltz	a0,800022c8 <wait+0x84>
          freeproc(np);
    800022a8:	8526                	mv	a0,s1
    800022aa:	00000097          	auipc	ra,0x0
    800022ae:	8c2080e7          	jalr	-1854(ra) # 80001b6c <freeproc>
          release(&np->lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	9fe080e7          	jalr	-1538(ra) # 80000cb2 <release>
          release(&p->lock);
    800022bc:	854a                	mv	a0,s2
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	9f4080e7          	jalr	-1548(ra) # 80000cb2 <release>
          return pid;
    800022c6:	a8a9                	j	80002320 <wait+0xdc>
            release(&np->lock);
    800022c8:	8526                	mv	a0,s1
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	9e8080e7          	jalr	-1560(ra) # 80000cb2 <release>
            release(&p->lock);
    800022d2:	854a                	mv	a0,s2
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	9de080e7          	jalr	-1570(ra) # 80000cb2 <release>
            return -1;
    800022dc:	59fd                	li	s3,-1
    800022de:	a089                	j	80002320 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    800022e0:	16848493          	addi	s1,s1,360
    800022e4:	03348463          	beq	s1,s3,8000230c <wait+0xc8>
      if(np->parent == p){
    800022e8:	709c                	ld	a5,32(s1)
    800022ea:	ff279be3          	bne	a5,s2,800022e0 <wait+0x9c>
        acquire(&np->lock);
    800022ee:	8526                	mv	a0,s1
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	90e080e7          	jalr	-1778(ra) # 80000bfe <acquire>
        if(np->state == ZOMBIE){
    800022f8:	4c9c                	lw	a5,24(s1)
    800022fa:	f94787e3          	beq	a5,s4,80002288 <wait+0x44>
        release(&np->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	9b2080e7          	jalr	-1614(ra) # 80000cb2 <release>
        havekids = 1;
    80002308:	8756                	mv	a4,s5
    8000230a:	bfd9                	j	800022e0 <wait+0x9c>
    if(!havekids || p->killed){
    8000230c:	c701                	beqz	a4,80002314 <wait+0xd0>
    8000230e:	03092783          	lw	a5,48(s2)
    80002312:	c39d                	beqz	a5,80002338 <wait+0xf4>
      release(&p->lock);
    80002314:	854a                	mv	a0,s2
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	99c080e7          	jalr	-1636(ra) # 80000cb2 <release>
      return -1;
    8000231e:	59fd                	li	s3,-1
}
    80002320:	854e                	mv	a0,s3
    80002322:	60a6                	ld	ra,72(sp)
    80002324:	6406                	ld	s0,64(sp)
    80002326:	74e2                	ld	s1,56(sp)
    80002328:	7942                	ld	s2,48(sp)
    8000232a:	79a2                	ld	s3,40(sp)
    8000232c:	7a02                	ld	s4,32(sp)
    8000232e:	6ae2                	ld	s5,24(sp)
    80002330:	6b42                	ld	s6,16(sp)
    80002332:	6ba2                	ld	s7,8(sp)
    80002334:	6161                	addi	sp,sp,80
    80002336:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002338:	85ca                	mv	a1,s2
    8000233a:	854a                	mv	a0,s2
    8000233c:	00000097          	auipc	ra,0x0
    80002340:	e8a080e7          	jalr	-374(ra) # 800021c6 <sleep>
    havekids = 0;
    80002344:	bf25                	j	8000227c <wait+0x38>

0000000080002346 <wakeup>:
{
    80002346:	7139                	addi	sp,sp,-64
    80002348:	fc06                	sd	ra,56(sp)
    8000234a:	f822                	sd	s0,48(sp)
    8000234c:	f426                	sd	s1,40(sp)
    8000234e:	f04a                	sd	s2,32(sp)
    80002350:	ec4e                	sd	s3,24(sp)
    80002352:	e852                	sd	s4,16(sp)
    80002354:	e456                	sd	s5,8(sp)
    80002356:	0080                	addi	s0,sp,64
    80002358:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000235a:	00010497          	auipc	s1,0x10
    8000235e:	a0e48493          	addi	s1,s1,-1522 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002362:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002364:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002366:	00015917          	auipc	s2,0x15
    8000236a:	40290913          	addi	s2,s2,1026 # 80017768 <tickslock>
    8000236e:	a811                	j	80002382 <wakeup+0x3c>
    release(&p->lock);
    80002370:	8526                	mv	a0,s1
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	940080e7          	jalr	-1728(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000237a:	16848493          	addi	s1,s1,360
    8000237e:	03248063          	beq	s1,s2,8000239e <wakeup+0x58>
    acquire(&p->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	87a080e7          	jalr	-1926(ra) # 80000bfe <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000238c:	4c9c                	lw	a5,24(s1)
    8000238e:	ff3791e3          	bne	a5,s3,80002370 <wakeup+0x2a>
    80002392:	749c                	ld	a5,40(s1)
    80002394:	fd479ee3          	bne	a5,s4,80002370 <wakeup+0x2a>
      p->state = RUNNABLE;
    80002398:	0154ac23          	sw	s5,24(s1)
    8000239c:	bfd1                	j	80002370 <wakeup+0x2a>
}
    8000239e:	70e2                	ld	ra,56(sp)
    800023a0:	7442                	ld	s0,48(sp)
    800023a2:	74a2                	ld	s1,40(sp)
    800023a4:	7902                	ld	s2,32(sp)
    800023a6:	69e2                	ld	s3,24(sp)
    800023a8:	6a42                	ld	s4,16(sp)
    800023aa:	6aa2                	ld	s5,8(sp)
    800023ac:	6121                	addi	sp,sp,64
    800023ae:	8082                	ret

00000000800023b0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023b0:	7179                	addi	sp,sp,-48
    800023b2:	f406                	sd	ra,40(sp)
    800023b4:	f022                	sd	s0,32(sp)
    800023b6:	ec26                	sd	s1,24(sp)
    800023b8:	e84a                	sd	s2,16(sp)
    800023ba:	e44e                	sd	s3,8(sp)
    800023bc:	1800                	addi	s0,sp,48
    800023be:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023c0:	00010497          	auipc	s1,0x10
    800023c4:	9a848493          	addi	s1,s1,-1624 # 80011d68 <proc>
    800023c8:	00015997          	auipc	s3,0x15
    800023cc:	3a098993          	addi	s3,s3,928 # 80017768 <tickslock>
    acquire(&p->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	82c080e7          	jalr	-2004(ra) # 80000bfe <acquire>
    if(p->pid == pid){
    800023da:	5c9c                	lw	a5,56(s1)
    800023dc:	01278d63          	beq	a5,s2,800023f6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8d0080e7          	jalr	-1840(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023ea:	16848493          	addi	s1,s1,360
    800023ee:	ff3491e3          	bne	s1,s3,800023d0 <kill+0x20>
  }
  return -1;
    800023f2:	557d                	li	a0,-1
    800023f4:	a821                	j	8000240c <kill+0x5c>
      p->killed = 1;
    800023f6:	4785                	li	a5,1
    800023f8:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800023fa:	4c98                	lw	a4,24(s1)
    800023fc:	00f70f63          	beq	a4,a5,8000241a <kill+0x6a>
      release(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	8b0080e7          	jalr	-1872(ra) # 80000cb2 <release>
      return 0;
    8000240a:	4501                	li	a0,0
}
    8000240c:	70a2                	ld	ra,40(sp)
    8000240e:	7402                	ld	s0,32(sp)
    80002410:	64e2                	ld	s1,24(sp)
    80002412:	6942                	ld	s2,16(sp)
    80002414:	69a2                	ld	s3,8(sp)
    80002416:	6145                	addi	sp,sp,48
    80002418:	8082                	ret
        p->state = RUNNABLE;
    8000241a:	4789                	li	a5,2
    8000241c:	cc9c                	sw	a5,24(s1)
    8000241e:	b7cd                	j	80002400 <kill+0x50>

0000000080002420 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002420:	7179                	addi	sp,sp,-48
    80002422:	f406                	sd	ra,40(sp)
    80002424:	f022                	sd	s0,32(sp)
    80002426:	ec26                	sd	s1,24(sp)
    80002428:	e84a                	sd	s2,16(sp)
    8000242a:	e44e                	sd	s3,8(sp)
    8000242c:	e052                	sd	s4,0(sp)
    8000242e:	1800                	addi	s0,sp,48
    80002430:	84aa                	mv	s1,a0
    80002432:	892e                	mv	s2,a1
    80002434:	89b2                	mv	s3,a2
    80002436:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	582080e7          	jalr	1410(ra) # 800019ba <myproc>
  if(user_dst){
    80002440:	c08d                	beqz	s1,80002462 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002442:	86d2                	mv	a3,s4
    80002444:	864e                	mv	a2,s3
    80002446:	85ca                	mv	a1,s2
    80002448:	6928                	ld	a0,80(a0)
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	262080e7          	jalr	610(ra) # 800016ac <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002452:	70a2                	ld	ra,40(sp)
    80002454:	7402                	ld	s0,32(sp)
    80002456:	64e2                	ld	s1,24(sp)
    80002458:	6942                	ld	s2,16(sp)
    8000245a:	69a2                	ld	s3,8(sp)
    8000245c:	6a02                	ld	s4,0(sp)
    8000245e:	6145                	addi	sp,sp,48
    80002460:	8082                	ret
    memmove((char *)dst, src, len);
    80002462:	000a061b          	sext.w	a2,s4
    80002466:	85ce                	mv	a1,s3
    80002468:	854a                	mv	a0,s2
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	8ec080e7          	jalr	-1812(ra) # 80000d56 <memmove>
    return 0;
    80002472:	8526                	mv	a0,s1
    80002474:	bff9                	j	80002452 <either_copyout+0x32>

0000000080002476 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002476:	7179                	addi	sp,sp,-48
    80002478:	f406                	sd	ra,40(sp)
    8000247a:	f022                	sd	s0,32(sp)
    8000247c:	ec26                	sd	s1,24(sp)
    8000247e:	e84a                	sd	s2,16(sp)
    80002480:	e44e                	sd	s3,8(sp)
    80002482:	e052                	sd	s4,0(sp)
    80002484:	1800                	addi	s0,sp,48
    80002486:	892a                	mv	s2,a0
    80002488:	84ae                	mv	s1,a1
    8000248a:	89b2                	mv	s3,a2
    8000248c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	52c080e7          	jalr	1324(ra) # 800019ba <myproc>
  if(user_src){
    80002496:	c08d                	beqz	s1,800024b8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002498:	86d2                	mv	a3,s4
    8000249a:	864e                	mv	a2,s3
    8000249c:	85ca                	mv	a1,s2
    8000249e:	6928                	ld	a0,80(a0)
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	298080e7          	jalr	664(ra) # 80001738 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024a8:	70a2                	ld	ra,40(sp)
    800024aa:	7402                	ld	s0,32(sp)
    800024ac:	64e2                	ld	s1,24(sp)
    800024ae:	6942                	ld	s2,16(sp)
    800024b0:	69a2                	ld	s3,8(sp)
    800024b2:	6a02                	ld	s4,0(sp)
    800024b4:	6145                	addi	sp,sp,48
    800024b6:	8082                	ret
    memmove(dst, (char*)src, len);
    800024b8:	000a061b          	sext.w	a2,s4
    800024bc:	85ce                	mv	a1,s3
    800024be:	854a                	mv	a0,s2
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	896080e7          	jalr	-1898(ra) # 80000d56 <memmove>
    return 0;
    800024c8:	8526                	mv	a0,s1
    800024ca:	bff9                	j	800024a8 <either_copyin+0x32>

00000000800024cc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024cc:	715d                	addi	sp,sp,-80
    800024ce:	e486                	sd	ra,72(sp)
    800024d0:	e0a2                	sd	s0,64(sp)
    800024d2:	fc26                	sd	s1,56(sp)
    800024d4:	f84a                	sd	s2,48(sp)
    800024d6:	f44e                	sd	s3,40(sp)
    800024d8:	f052                	sd	s4,32(sp)
    800024da:	ec56                	sd	s5,24(sp)
    800024dc:	e85a                	sd	s6,16(sp)
    800024de:	e45e                	sd	s7,8(sp)
    800024e0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024e2:	00006517          	auipc	a0,0x6
    800024e6:	c0650513          	addi	a0,a0,-1018 # 800080e8 <digits+0xa8>
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	0a2080e7          	jalr	162(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024f2:	00010497          	auipc	s1,0x10
    800024f6:	9ce48493          	addi	s1,s1,-1586 # 80011ec0 <proc+0x158>
    800024fa:	00015917          	auipc	s2,0x15
    800024fe:	3c690913          	addi	s2,s2,966 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002502:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002504:	00006997          	auipc	s3,0x6
    80002508:	db498993          	addi	s3,s3,-588 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    8000250c:	00006a97          	auipc	s5,0x6
    80002510:	db4a8a93          	addi	s5,s5,-588 # 800082c0 <digits+0x280>
    printf("\n");
    80002514:	00006a17          	auipc	s4,0x6
    80002518:	bd4a0a13          	addi	s4,s4,-1068 # 800080e8 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000251c:	00006b97          	auipc	s7,0x6
    80002520:	ddcb8b93          	addi	s7,s7,-548 # 800082f8 <states.0>
    80002524:	a00d                	j	80002546 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002526:	ee06a583          	lw	a1,-288(a3)
    8000252a:	8556                	mv	a0,s5
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	060080e7          	jalr	96(ra) # 8000058c <printf>
    printf("\n");
    80002534:	8552                	mv	a0,s4
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	056080e7          	jalr	86(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000253e:	16848493          	addi	s1,s1,360
    80002542:	03248263          	beq	s1,s2,80002566 <procdump+0x9a>
    if(p->state == UNUSED)
    80002546:	86a6                	mv	a3,s1
    80002548:	ec04a783          	lw	a5,-320(s1)
    8000254c:	dbed                	beqz	a5,8000253e <procdump+0x72>
      state = "???";
    8000254e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002550:	fcfb6be3          	bltu	s6,a5,80002526 <procdump+0x5a>
    80002554:	02079713          	slli	a4,a5,0x20
    80002558:	01d75793          	srli	a5,a4,0x1d
    8000255c:	97de                	add	a5,a5,s7
    8000255e:	6390                	ld	a2,0(a5)
    80002560:	f279                	bnez	a2,80002526 <procdump+0x5a>
      state = "???";
    80002562:	864e                	mv	a2,s3
    80002564:	b7c9                	j	80002526 <procdump+0x5a>
  }
}
    80002566:	60a6                	ld	ra,72(sp)
    80002568:	6406                	ld	s0,64(sp)
    8000256a:	74e2                	ld	s1,56(sp)
    8000256c:	7942                	ld	s2,48(sp)
    8000256e:	79a2                	ld	s3,40(sp)
    80002570:	7a02                	ld	s4,32(sp)
    80002572:	6ae2                	ld	s5,24(sp)
    80002574:	6b42                	ld	s6,16(sp)
    80002576:	6ba2                	ld	s7,8(sp)
    80002578:	6161                	addi	sp,sp,80
    8000257a:	8082                	ret

000000008000257c <swtch>:
    8000257c:	00153023          	sd	ra,0(a0)
    80002580:	00253423          	sd	sp,8(a0)
    80002584:	e900                	sd	s0,16(a0)
    80002586:	ed04                	sd	s1,24(a0)
    80002588:	03253023          	sd	s2,32(a0)
    8000258c:	03353423          	sd	s3,40(a0)
    80002590:	03453823          	sd	s4,48(a0)
    80002594:	03553c23          	sd	s5,56(a0)
    80002598:	05653023          	sd	s6,64(a0)
    8000259c:	05753423          	sd	s7,72(a0)
    800025a0:	05853823          	sd	s8,80(a0)
    800025a4:	05953c23          	sd	s9,88(a0)
    800025a8:	07a53023          	sd	s10,96(a0)
    800025ac:	07b53423          	sd	s11,104(a0)
    800025b0:	0005b083          	ld	ra,0(a1)
    800025b4:	0085b103          	ld	sp,8(a1)
    800025b8:	6980                	ld	s0,16(a1)
    800025ba:	6d84                	ld	s1,24(a1)
    800025bc:	0205b903          	ld	s2,32(a1)
    800025c0:	0285b983          	ld	s3,40(a1)
    800025c4:	0305ba03          	ld	s4,48(a1)
    800025c8:	0385ba83          	ld	s5,56(a1)
    800025cc:	0405bb03          	ld	s6,64(a1)
    800025d0:	0485bb83          	ld	s7,72(a1)
    800025d4:	0505bc03          	ld	s8,80(a1)
    800025d8:	0585bc83          	ld	s9,88(a1)
    800025dc:	0605bd03          	ld	s10,96(a1)
    800025e0:	0685bd83          	ld	s11,104(a1)
    800025e4:	8082                	ret

00000000800025e6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025e6:	1141                	addi	sp,sp,-16
    800025e8:	e406                	sd	ra,8(sp)
    800025ea:	e022                	sd	s0,0(sp)
    800025ec:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025ee:	00006597          	auipc	a1,0x6
    800025f2:	d3258593          	addi	a1,a1,-718 # 80008320 <states.0+0x28>
    800025f6:	00015517          	auipc	a0,0x15
    800025fa:	17250513          	addi	a0,a0,370 # 80017768 <tickslock>
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	570080e7          	jalr	1392(ra) # 80000b6e <initlock>
}
    80002606:	60a2                	ld	ra,8(sp)
    80002608:	6402                	ld	s0,0(sp)
    8000260a:	0141                	addi	sp,sp,16
    8000260c:	8082                	ret

000000008000260e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000260e:	1141                	addi	sp,sp,-16
    80002610:	e422                	sd	s0,8(sp)
    80002612:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002614:	00003797          	auipc	a5,0x3
    80002618:	4bc78793          	addi	a5,a5,1212 # 80005ad0 <kernelvec>
    8000261c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002620:	6422                	ld	s0,8(sp)
    80002622:	0141                	addi	sp,sp,16
    80002624:	8082                	ret

0000000080002626 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002626:	1141                	addi	sp,sp,-16
    80002628:	e406                	sd	ra,8(sp)
    8000262a:	e022                	sd	s0,0(sp)
    8000262c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000262e:	fffff097          	auipc	ra,0xfffff
    80002632:	38c080e7          	jalr	908(ra) # 800019ba <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002636:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000263a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000263c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002640:	00005617          	auipc	a2,0x5
    80002644:	9c060613          	addi	a2,a2,-1600 # 80007000 <_trampoline>
    80002648:	00005697          	auipc	a3,0x5
    8000264c:	9b868693          	addi	a3,a3,-1608 # 80007000 <_trampoline>
    80002650:	8e91                	sub	a3,a3,a2
    80002652:	040007b7          	lui	a5,0x4000
    80002656:	17fd                	addi	a5,a5,-1
    80002658:	07b2                	slli	a5,a5,0xc
    8000265a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000265c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002660:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002662:	180026f3          	csrr	a3,satp
    80002666:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002668:	6d38                	ld	a4,88(a0)
    8000266a:	6134                	ld	a3,64(a0)
    8000266c:	6585                	lui	a1,0x1
    8000266e:	96ae                	add	a3,a3,a1
    80002670:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002672:	6d38                	ld	a4,88(a0)
    80002674:	00000697          	auipc	a3,0x0
    80002678:	13868693          	addi	a3,a3,312 # 800027ac <usertrap>
    8000267c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000267e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002680:	8692                	mv	a3,tp
    80002682:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002684:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002688:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000268c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002690:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002694:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002696:	6f18                	ld	a4,24(a4)
    80002698:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000269c:	692c                	ld	a1,80(a0)
    8000269e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026a0:	00005717          	auipc	a4,0x5
    800026a4:	9f070713          	addi	a4,a4,-1552 # 80007090 <userret>
    800026a8:	8f11                	sub	a4,a4,a2
    800026aa:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026ac:	577d                	li	a4,-1
    800026ae:	177e                	slli	a4,a4,0x3f
    800026b0:	8dd9                	or	a1,a1,a4
    800026b2:	02000537          	lui	a0,0x2000
    800026b6:	157d                	addi	a0,a0,-1
    800026b8:	0536                	slli	a0,a0,0xd
    800026ba:	9782                	jalr	a5
}
    800026bc:	60a2                	ld	ra,8(sp)
    800026be:	6402                	ld	s0,0(sp)
    800026c0:	0141                	addi	sp,sp,16
    800026c2:	8082                	ret

00000000800026c4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026c4:	1101                	addi	sp,sp,-32
    800026c6:	ec06                	sd	ra,24(sp)
    800026c8:	e822                	sd	s0,16(sp)
    800026ca:	e426                	sd	s1,8(sp)
    800026cc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026ce:	00015497          	auipc	s1,0x15
    800026d2:	09a48493          	addi	s1,s1,154 # 80017768 <tickslock>
    800026d6:	8526                	mv	a0,s1
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	526080e7          	jalr	1318(ra) # 80000bfe <acquire>
  ticks++;
    800026e0:	00007517          	auipc	a0,0x7
    800026e4:	94050513          	addi	a0,a0,-1728 # 80009020 <ticks>
    800026e8:	411c                	lw	a5,0(a0)
    800026ea:	2785                	addiw	a5,a5,1
    800026ec:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026ee:	00000097          	auipc	ra,0x0
    800026f2:	c58080e7          	jalr	-936(ra) # 80002346 <wakeup>
  release(&tickslock);
    800026f6:	8526                	mv	a0,s1
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	5ba080e7          	jalr	1466(ra) # 80000cb2 <release>
}
    80002700:	60e2                	ld	ra,24(sp)
    80002702:	6442                	ld	s0,16(sp)
    80002704:	64a2                	ld	s1,8(sp)
    80002706:	6105                	addi	sp,sp,32
    80002708:	8082                	ret

000000008000270a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000270a:	1101                	addi	sp,sp,-32
    8000270c:	ec06                	sd	ra,24(sp)
    8000270e:	e822                	sd	s0,16(sp)
    80002710:	e426                	sd	s1,8(sp)
    80002712:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002714:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002718:	00074d63          	bltz	a4,80002732 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000271c:	57fd                	li	a5,-1
    8000271e:	17fe                	slli	a5,a5,0x3f
    80002720:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002722:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002724:	06f70363          	beq	a4,a5,8000278a <devintr+0x80>
  }
}
    80002728:	60e2                	ld	ra,24(sp)
    8000272a:	6442                	ld	s0,16(sp)
    8000272c:	64a2                	ld	s1,8(sp)
    8000272e:	6105                	addi	sp,sp,32
    80002730:	8082                	ret
     (scause & 0xff) == 9){
    80002732:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002736:	46a5                	li	a3,9
    80002738:	fed792e3          	bne	a5,a3,8000271c <devintr+0x12>
    int irq = plic_claim();
    8000273c:	00003097          	auipc	ra,0x3
    80002740:	49c080e7          	jalr	1180(ra) # 80005bd8 <plic_claim>
    80002744:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002746:	47a9                	li	a5,10
    80002748:	02f50763          	beq	a0,a5,80002776 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000274c:	4785                	li	a5,1
    8000274e:	02f50963          	beq	a0,a5,80002780 <devintr+0x76>
    return 1;
    80002752:	4505                	li	a0,1
    } else if(irq){
    80002754:	d8f1                	beqz	s1,80002728 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002756:	85a6                	mv	a1,s1
    80002758:	00006517          	auipc	a0,0x6
    8000275c:	bd050513          	addi	a0,a0,-1072 # 80008328 <states.0+0x30>
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	e2c080e7          	jalr	-468(ra) # 8000058c <printf>
      plic_complete(irq);
    80002768:	8526                	mv	a0,s1
    8000276a:	00003097          	auipc	ra,0x3
    8000276e:	492080e7          	jalr	1170(ra) # 80005bfc <plic_complete>
    return 1;
    80002772:	4505                	li	a0,1
    80002774:	bf55                	j	80002728 <devintr+0x1e>
      uartintr();
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	24c080e7          	jalr	588(ra) # 800009c2 <uartintr>
    8000277e:	b7ed                	j	80002768 <devintr+0x5e>
      virtio_disk_intr();
    80002780:	00004097          	auipc	ra,0x4
    80002784:	8f6080e7          	jalr	-1802(ra) # 80006076 <virtio_disk_intr>
    80002788:	b7c5                	j	80002768 <devintr+0x5e>
    if(cpuid() == 0){
    8000278a:	fffff097          	auipc	ra,0xfffff
    8000278e:	204080e7          	jalr	516(ra) # 8000198e <cpuid>
    80002792:	c901                	beqz	a0,800027a2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002794:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002798:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000279a:	14479073          	csrw	sip,a5
    return 2;
    8000279e:	4509                	li	a0,2
    800027a0:	b761                	j	80002728 <devintr+0x1e>
      clockintr();
    800027a2:	00000097          	auipc	ra,0x0
    800027a6:	f22080e7          	jalr	-222(ra) # 800026c4 <clockintr>
    800027aa:	b7ed                	j	80002794 <devintr+0x8a>

00000000800027ac <usertrap>:
{
    800027ac:	1101                	addi	sp,sp,-32
    800027ae:	ec06                	sd	ra,24(sp)
    800027b0:	e822                	sd	s0,16(sp)
    800027b2:	e426                	sd	s1,8(sp)
    800027b4:	e04a                	sd	s2,0(sp)
    800027b6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027b8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027bc:	1007f793          	andi	a5,a5,256
    800027c0:	e3ad                	bnez	a5,80002822 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027c2:	00003797          	auipc	a5,0x3
    800027c6:	30e78793          	addi	a5,a5,782 # 80005ad0 <kernelvec>
    800027ca:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027ce:	fffff097          	auipc	ra,0xfffff
    800027d2:	1ec080e7          	jalr	492(ra) # 800019ba <myproc>
    800027d6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027d8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027da:	14102773          	csrr	a4,sepc
    800027de:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027e4:	47a1                	li	a5,8
    800027e6:	04f71c63          	bne	a4,a5,8000283e <usertrap+0x92>
    if(p->killed)
    800027ea:	591c                	lw	a5,48(a0)
    800027ec:	e3b9                	bnez	a5,80002832 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027ee:	6cb8                	ld	a4,88(s1)
    800027f0:	6f1c                	ld	a5,24(a4)
    800027f2:	0791                	addi	a5,a5,4
    800027f4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027fa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027fe:	10079073          	csrw	sstatus,a5
    syscall();
    80002802:	00000097          	auipc	ra,0x0
    80002806:	2e0080e7          	jalr	736(ra) # 80002ae2 <syscall>
  if(p->killed)
    8000280a:	589c                	lw	a5,48(s1)
    8000280c:	ebc1                	bnez	a5,8000289c <usertrap+0xf0>
  usertrapret();
    8000280e:	00000097          	auipc	ra,0x0
    80002812:	e18080e7          	jalr	-488(ra) # 80002626 <usertrapret>
}
    80002816:	60e2                	ld	ra,24(sp)
    80002818:	6442                	ld	s0,16(sp)
    8000281a:	64a2                	ld	s1,8(sp)
    8000281c:	6902                	ld	s2,0(sp)
    8000281e:	6105                	addi	sp,sp,32
    80002820:	8082                	ret
    panic("usertrap: not from user mode");
    80002822:	00006517          	auipc	a0,0x6
    80002826:	b2650513          	addi	a0,a0,-1242 # 80008348 <states.0+0x50>
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	d18080e7          	jalr	-744(ra) # 80000542 <panic>
      exit(-1);
    80002832:	557d                	li	a0,-1
    80002834:	00000097          	auipc	ra,0x0
    80002838:	84c080e7          	jalr	-1972(ra) # 80002080 <exit>
    8000283c:	bf4d                	j	800027ee <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000283e:	00000097          	auipc	ra,0x0
    80002842:	ecc080e7          	jalr	-308(ra) # 8000270a <devintr>
    80002846:	892a                	mv	s2,a0
    80002848:	c501                	beqz	a0,80002850 <usertrap+0xa4>
  if(p->killed)
    8000284a:	589c                	lw	a5,48(s1)
    8000284c:	c3a1                	beqz	a5,8000288c <usertrap+0xe0>
    8000284e:	a815                	j	80002882 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002850:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002854:	5c90                	lw	a2,56(s1)
    80002856:	00006517          	auipc	a0,0x6
    8000285a:	b1250513          	addi	a0,a0,-1262 # 80008368 <states.0+0x70>
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	d2e080e7          	jalr	-722(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002866:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000286a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000286e:	00006517          	auipc	a0,0x6
    80002872:	b2a50513          	addi	a0,a0,-1238 # 80008398 <states.0+0xa0>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	d16080e7          	jalr	-746(ra) # 8000058c <printf>
    p->killed = 1;
    8000287e:	4785                	li	a5,1
    80002880:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002882:	557d                	li	a0,-1
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	7fc080e7          	jalr	2044(ra) # 80002080 <exit>
  if(which_dev == 2)
    8000288c:	4789                	li	a5,2
    8000288e:	f8f910e3          	bne	s2,a5,8000280e <usertrap+0x62>
    yield();
    80002892:	00000097          	auipc	ra,0x0
    80002896:	8f8080e7          	jalr	-1800(ra) # 8000218a <yield>
    8000289a:	bf95                	j	8000280e <usertrap+0x62>
  int which_dev = 0;
    8000289c:	4901                	li	s2,0
    8000289e:	b7d5                	j	80002882 <usertrap+0xd6>

00000000800028a0 <kerneltrap>:
{
    800028a0:	7179                	addi	sp,sp,-48
    800028a2:	f406                	sd	ra,40(sp)
    800028a4:	f022                	sd	s0,32(sp)
    800028a6:	ec26                	sd	s1,24(sp)
    800028a8:	e84a                	sd	s2,16(sp)
    800028aa:	e44e                	sd	s3,8(sp)
    800028ac:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ae:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028ba:	1004f793          	andi	a5,s1,256
    800028be:	cb85                	beqz	a5,800028ee <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028c4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028c6:	ef85                	bnez	a5,800028fe <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	e42080e7          	jalr	-446(ra) # 8000270a <devintr>
    800028d0:	cd1d                	beqz	a0,8000290e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028d2:	4789                	li	a5,2
    800028d4:	06f50a63          	beq	a0,a5,80002948 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028d8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028dc:	10049073          	csrw	sstatus,s1
}
    800028e0:	70a2                	ld	ra,40(sp)
    800028e2:	7402                	ld	s0,32(sp)
    800028e4:	64e2                	ld	s1,24(sp)
    800028e6:	6942                	ld	s2,16(sp)
    800028e8:	69a2                	ld	s3,8(sp)
    800028ea:	6145                	addi	sp,sp,48
    800028ec:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028ee:	00006517          	auipc	a0,0x6
    800028f2:	aca50513          	addi	a0,a0,-1334 # 800083b8 <states.0+0xc0>
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	c4c080e7          	jalr	-948(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	ae250513          	addi	a0,a0,-1310 # 800083e0 <states.0+0xe8>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c3c080e7          	jalr	-964(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    8000290e:	85ce                	mv	a1,s3
    80002910:	00006517          	auipc	a0,0x6
    80002914:	af050513          	addi	a0,a0,-1296 # 80008400 <states.0+0x108>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	c74080e7          	jalr	-908(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002920:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002924:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002928:	00006517          	auipc	a0,0x6
    8000292c:	ae850513          	addi	a0,a0,-1304 # 80008410 <states.0+0x118>
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	c5c080e7          	jalr	-932(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002938:	00006517          	auipc	a0,0x6
    8000293c:	af050513          	addi	a0,a0,-1296 # 80008428 <states.0+0x130>
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	c02080e7          	jalr	-1022(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	072080e7          	jalr	114(ra) # 800019ba <myproc>
    80002950:	d541                	beqz	a0,800028d8 <kerneltrap+0x38>
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	068080e7          	jalr	104(ra) # 800019ba <myproc>
    8000295a:	4d18                	lw	a4,24(a0)
    8000295c:	478d                	li	a5,3
    8000295e:	f6f71de3          	bne	a4,a5,800028d8 <kerneltrap+0x38>
    yield();
    80002962:	00000097          	auipc	ra,0x0
    80002966:	828080e7          	jalr	-2008(ra) # 8000218a <yield>
    8000296a:	b7bd                	j	800028d8 <kerneltrap+0x38>

000000008000296c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000296c:	1101                	addi	sp,sp,-32
    8000296e:	ec06                	sd	ra,24(sp)
    80002970:	e822                	sd	s0,16(sp)
    80002972:	e426                	sd	s1,8(sp)
    80002974:	1000                	addi	s0,sp,32
    80002976:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002978:	fffff097          	auipc	ra,0xfffff
    8000297c:	042080e7          	jalr	66(ra) # 800019ba <myproc>
  switch (n) {
    80002980:	4795                	li	a5,5
    80002982:	0497e163          	bltu	a5,s1,800029c4 <argraw+0x58>
    80002986:	048a                	slli	s1,s1,0x2
    80002988:	00006717          	auipc	a4,0x6
    8000298c:	ad870713          	addi	a4,a4,-1320 # 80008460 <states.0+0x168>
    80002990:	94ba                	add	s1,s1,a4
    80002992:	409c                	lw	a5,0(s1)
    80002994:	97ba                	add	a5,a5,a4
    80002996:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002998:	6d3c                	ld	a5,88(a0)
    8000299a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000299c:	60e2                	ld	ra,24(sp)
    8000299e:	6442                	ld	s0,16(sp)
    800029a0:	64a2                	ld	s1,8(sp)
    800029a2:	6105                	addi	sp,sp,32
    800029a4:	8082                	ret
    return p->trapframe->a1;
    800029a6:	6d3c                	ld	a5,88(a0)
    800029a8:	7fa8                	ld	a0,120(a5)
    800029aa:	bfcd                	j	8000299c <argraw+0x30>
    return p->trapframe->a2;
    800029ac:	6d3c                	ld	a5,88(a0)
    800029ae:	63c8                	ld	a0,128(a5)
    800029b0:	b7f5                	j	8000299c <argraw+0x30>
    return p->trapframe->a3;
    800029b2:	6d3c                	ld	a5,88(a0)
    800029b4:	67c8                	ld	a0,136(a5)
    800029b6:	b7dd                	j	8000299c <argraw+0x30>
    return p->trapframe->a4;
    800029b8:	6d3c                	ld	a5,88(a0)
    800029ba:	6bc8                	ld	a0,144(a5)
    800029bc:	b7c5                	j	8000299c <argraw+0x30>
    return p->trapframe->a5;
    800029be:	6d3c                	ld	a5,88(a0)
    800029c0:	6fc8                	ld	a0,152(a5)
    800029c2:	bfe9                	j	8000299c <argraw+0x30>
  panic("argraw");
    800029c4:	00006517          	auipc	a0,0x6
    800029c8:	a7450513          	addi	a0,a0,-1420 # 80008438 <states.0+0x140>
    800029cc:	ffffe097          	auipc	ra,0xffffe
    800029d0:	b76080e7          	jalr	-1162(ra) # 80000542 <panic>

00000000800029d4 <fetchaddr>:
{
    800029d4:	1101                	addi	sp,sp,-32
    800029d6:	ec06                	sd	ra,24(sp)
    800029d8:	e822                	sd	s0,16(sp)
    800029da:	e426                	sd	s1,8(sp)
    800029dc:	e04a                	sd	s2,0(sp)
    800029de:	1000                	addi	s0,sp,32
    800029e0:	84aa                	mv	s1,a0
    800029e2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029e4:	fffff097          	auipc	ra,0xfffff
    800029e8:	fd6080e7          	jalr	-42(ra) # 800019ba <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029ec:	653c                	ld	a5,72(a0)
    800029ee:	02f4f863          	bgeu	s1,a5,80002a1e <fetchaddr+0x4a>
    800029f2:	00848713          	addi	a4,s1,8
    800029f6:	02e7e663          	bltu	a5,a4,80002a22 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029fa:	46a1                	li	a3,8
    800029fc:	8626                	mv	a2,s1
    800029fe:	85ca                	mv	a1,s2
    80002a00:	6928                	ld	a0,80(a0)
    80002a02:	fffff097          	auipc	ra,0xfffff
    80002a06:	d36080e7          	jalr	-714(ra) # 80001738 <copyin>
    80002a0a:	00a03533          	snez	a0,a0
    80002a0e:	40a00533          	neg	a0,a0
}
    80002a12:	60e2                	ld	ra,24(sp)
    80002a14:	6442                	ld	s0,16(sp)
    80002a16:	64a2                	ld	s1,8(sp)
    80002a18:	6902                	ld	s2,0(sp)
    80002a1a:	6105                	addi	sp,sp,32
    80002a1c:	8082                	ret
    return -1;
    80002a1e:	557d                	li	a0,-1
    80002a20:	bfcd                	j	80002a12 <fetchaddr+0x3e>
    80002a22:	557d                	li	a0,-1
    80002a24:	b7fd                	j	80002a12 <fetchaddr+0x3e>

0000000080002a26 <fetchstr>:
{
    80002a26:	7179                	addi	sp,sp,-48
    80002a28:	f406                	sd	ra,40(sp)
    80002a2a:	f022                	sd	s0,32(sp)
    80002a2c:	ec26                	sd	s1,24(sp)
    80002a2e:	e84a                	sd	s2,16(sp)
    80002a30:	e44e                	sd	s3,8(sp)
    80002a32:	1800                	addi	s0,sp,48
    80002a34:	892a                	mv	s2,a0
    80002a36:	84ae                	mv	s1,a1
    80002a38:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a3a:	fffff097          	auipc	ra,0xfffff
    80002a3e:	f80080e7          	jalr	-128(ra) # 800019ba <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a42:	86ce                	mv	a3,s3
    80002a44:	864a                	mv	a2,s2
    80002a46:	85a6                	mv	a1,s1
    80002a48:	6928                	ld	a0,80(a0)
    80002a4a:	fffff097          	auipc	ra,0xfffff
    80002a4e:	d7c080e7          	jalr	-644(ra) # 800017c6 <copyinstr>
  if(err < 0)
    80002a52:	00054763          	bltz	a0,80002a60 <fetchstr+0x3a>
  return strlen(buf);
    80002a56:	8526                	mv	a0,s1
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	426080e7          	jalr	1062(ra) # 80000e7e <strlen>
}
    80002a60:	70a2                	ld	ra,40(sp)
    80002a62:	7402                	ld	s0,32(sp)
    80002a64:	64e2                	ld	s1,24(sp)
    80002a66:	6942                	ld	s2,16(sp)
    80002a68:	69a2                	ld	s3,8(sp)
    80002a6a:	6145                	addi	sp,sp,48
    80002a6c:	8082                	ret

0000000080002a6e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a6e:	1101                	addi	sp,sp,-32
    80002a70:	ec06                	sd	ra,24(sp)
    80002a72:	e822                	sd	s0,16(sp)
    80002a74:	e426                	sd	s1,8(sp)
    80002a76:	1000                	addi	s0,sp,32
    80002a78:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	ef2080e7          	jalr	-270(ra) # 8000296c <argraw>
    80002a82:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a84:	4501                	li	a0,0
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	64a2                	ld	s1,8(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret

0000000080002a90 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a90:	1101                	addi	sp,sp,-32
    80002a92:	ec06                	sd	ra,24(sp)
    80002a94:	e822                	sd	s0,16(sp)
    80002a96:	e426                	sd	s1,8(sp)
    80002a98:	1000                	addi	s0,sp,32
    80002a9a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a9c:	00000097          	auipc	ra,0x0
    80002aa0:	ed0080e7          	jalr	-304(ra) # 8000296c <argraw>
    80002aa4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002aa6:	4501                	li	a0,0
    80002aa8:	60e2                	ld	ra,24(sp)
    80002aaa:	6442                	ld	s0,16(sp)
    80002aac:	64a2                	ld	s1,8(sp)
    80002aae:	6105                	addi	sp,sp,32
    80002ab0:	8082                	ret

0000000080002ab2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ab2:	1101                	addi	sp,sp,-32
    80002ab4:	ec06                	sd	ra,24(sp)
    80002ab6:	e822                	sd	s0,16(sp)
    80002ab8:	e426                	sd	s1,8(sp)
    80002aba:	e04a                	sd	s2,0(sp)
    80002abc:	1000                	addi	s0,sp,32
    80002abe:	84ae                	mv	s1,a1
    80002ac0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ac2:	00000097          	auipc	ra,0x0
    80002ac6:	eaa080e7          	jalr	-342(ra) # 8000296c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002aca:	864a                	mv	a2,s2
    80002acc:	85a6                	mv	a1,s1
    80002ace:	00000097          	auipc	ra,0x0
    80002ad2:	f58080e7          	jalr	-168(ra) # 80002a26 <fetchstr>
}
    80002ad6:	60e2                	ld	ra,24(sp)
    80002ad8:	6442                	ld	s0,16(sp)
    80002ada:	64a2                	ld	s1,8(sp)
    80002adc:	6902                	ld	s2,0(sp)
    80002ade:	6105                	addi	sp,sp,32
    80002ae0:	8082                	ret

0000000080002ae2 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ae2:	1101                	addi	sp,sp,-32
    80002ae4:	ec06                	sd	ra,24(sp)
    80002ae6:	e822                	sd	s0,16(sp)
    80002ae8:	e426                	sd	s1,8(sp)
    80002aea:	e04a                	sd	s2,0(sp)
    80002aec:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002aee:	fffff097          	auipc	ra,0xfffff
    80002af2:	ecc080e7          	jalr	-308(ra) # 800019ba <myproc>
    80002af6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002af8:	05853903          	ld	s2,88(a0)
    80002afc:	0a893783          	ld	a5,168(s2)
    80002b00:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b04:	37fd                	addiw	a5,a5,-1
    80002b06:	4751                	li	a4,20
    80002b08:	00f76f63          	bltu	a4,a5,80002b26 <syscall+0x44>
    80002b0c:	00369713          	slli	a4,a3,0x3
    80002b10:	00006797          	auipc	a5,0x6
    80002b14:	96878793          	addi	a5,a5,-1688 # 80008478 <syscalls>
    80002b18:	97ba                	add	a5,a5,a4
    80002b1a:	639c                	ld	a5,0(a5)
    80002b1c:	c789                	beqz	a5,80002b26 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b1e:	9782                	jalr	a5
    80002b20:	06a93823          	sd	a0,112(s2)
    80002b24:	a839                	j	80002b42 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b26:	15848613          	addi	a2,s1,344
    80002b2a:	5c8c                	lw	a1,56(s1)
    80002b2c:	00006517          	auipc	a0,0x6
    80002b30:	91450513          	addi	a0,a0,-1772 # 80008440 <states.0+0x148>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	a58080e7          	jalr	-1448(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b3c:	6cbc                	ld	a5,88(s1)
    80002b3e:	577d                	li	a4,-1
    80002b40:	fbb8                	sd	a4,112(a5)
  }
}
    80002b42:	60e2                	ld	ra,24(sp)
    80002b44:	6442                	ld	s0,16(sp)
    80002b46:	64a2                	ld	s1,8(sp)
    80002b48:	6902                	ld	s2,0(sp)
    80002b4a:	6105                	addi	sp,sp,32
    80002b4c:	8082                	ret

0000000080002b4e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b4e:	1101                	addi	sp,sp,-32
    80002b50:	ec06                	sd	ra,24(sp)
    80002b52:	e822                	sd	s0,16(sp)
    80002b54:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b56:	fec40593          	addi	a1,s0,-20
    80002b5a:	4501                	li	a0,0
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	f12080e7          	jalr	-238(ra) # 80002a6e <argint>
    return -1;
    80002b64:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b66:	00054963          	bltz	a0,80002b78 <sys_exit+0x2a>
  exit(n);
    80002b6a:	fec42503          	lw	a0,-20(s0)
    80002b6e:	fffff097          	auipc	ra,0xfffff
    80002b72:	512080e7          	jalr	1298(ra) # 80002080 <exit>
  return 0;  // not reached
    80002b76:	4781                	li	a5,0
}
    80002b78:	853e                	mv	a0,a5
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	6105                	addi	sp,sp,32
    80002b80:	8082                	ret

0000000080002b82 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b82:	1141                	addi	sp,sp,-16
    80002b84:	e406                	sd	ra,8(sp)
    80002b86:	e022                	sd	s0,0(sp)
    80002b88:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b8a:	fffff097          	auipc	ra,0xfffff
    80002b8e:	e30080e7          	jalr	-464(ra) # 800019ba <myproc>
}
    80002b92:	5d08                	lw	a0,56(a0)
    80002b94:	60a2                	ld	ra,8(sp)
    80002b96:	6402                	ld	s0,0(sp)
    80002b98:	0141                	addi	sp,sp,16
    80002b9a:	8082                	ret

0000000080002b9c <sys_fork>:

uint64
sys_fork(void)
{
    80002b9c:	1141                	addi	sp,sp,-16
    80002b9e:	e406                	sd	ra,8(sp)
    80002ba0:	e022                	sd	s0,0(sp)
    80002ba2:	0800                	addi	s0,sp,16
  return fork();
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	1f2080e7          	jalr	498(ra) # 80001d96 <fork>
}
    80002bac:	60a2                	ld	ra,8(sp)
    80002bae:	6402                	ld	s0,0(sp)
    80002bb0:	0141                	addi	sp,sp,16
    80002bb2:	8082                	ret

0000000080002bb4 <sys_wait>:

uint64
sys_wait(void)
{
    80002bb4:	1101                	addi	sp,sp,-32
    80002bb6:	ec06                	sd	ra,24(sp)
    80002bb8:	e822                	sd	s0,16(sp)
    80002bba:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bbc:	fe840593          	addi	a1,s0,-24
    80002bc0:	4501                	li	a0,0
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	ece080e7          	jalr	-306(ra) # 80002a90 <argaddr>
    80002bca:	87aa                	mv	a5,a0
    return -1;
    80002bcc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bce:	0007c863          	bltz	a5,80002bde <sys_wait+0x2a>
  return wait(p);
    80002bd2:	fe843503          	ld	a0,-24(s0)
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	66e080e7          	jalr	1646(ra) # 80002244 <wait>
}
    80002bde:	60e2                	ld	ra,24(sp)
    80002be0:	6442                	ld	s0,16(sp)
    80002be2:	6105                	addi	sp,sp,32
    80002be4:	8082                	ret

0000000080002be6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002be6:	7179                	addi	sp,sp,-48
    80002be8:	f406                	sd	ra,40(sp)
    80002bea:	f022                	sd	s0,32(sp)
    80002bec:	ec26                	sd	s1,24(sp)
    80002bee:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bf0:	fdc40593          	addi	a1,s0,-36
    80002bf4:	4501                	li	a0,0
    80002bf6:	00000097          	auipc	ra,0x0
    80002bfa:	e78080e7          	jalr	-392(ra) # 80002a6e <argint>
    return -1;
    80002bfe:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002c00:	00054f63          	bltz	a0,80002c1e <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	db6080e7          	jalr	-586(ra) # 800019ba <myproc>
    80002c0c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c0e:	fdc42503          	lw	a0,-36(s0)
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	110080e7          	jalr	272(ra) # 80001d22 <growproc>
    80002c1a:	00054863          	bltz	a0,80002c2a <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002c1e:	8526                	mv	a0,s1
    80002c20:	70a2                	ld	ra,40(sp)
    80002c22:	7402                	ld	s0,32(sp)
    80002c24:	64e2                	ld	s1,24(sp)
    80002c26:	6145                	addi	sp,sp,48
    80002c28:	8082                	ret
    return -1;
    80002c2a:	54fd                	li	s1,-1
    80002c2c:	bfcd                	j	80002c1e <sys_sbrk+0x38>

0000000080002c2e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c2e:	7139                	addi	sp,sp,-64
    80002c30:	fc06                	sd	ra,56(sp)
    80002c32:	f822                	sd	s0,48(sp)
    80002c34:	f426                	sd	s1,40(sp)
    80002c36:	f04a                	sd	s2,32(sp)
    80002c38:	ec4e                	sd	s3,24(sp)
    80002c3a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c3c:	fcc40593          	addi	a1,s0,-52
    80002c40:	4501                	li	a0,0
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	e2c080e7          	jalr	-468(ra) # 80002a6e <argint>
    return -1;
    80002c4a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c4c:	06054563          	bltz	a0,80002cb6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c50:	00015517          	auipc	a0,0x15
    80002c54:	b1850513          	addi	a0,a0,-1256 # 80017768 <tickslock>
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	fa6080e7          	jalr	-90(ra) # 80000bfe <acquire>
  ticks0 = ticks;
    80002c60:	00006917          	auipc	s2,0x6
    80002c64:	3c092903          	lw	s2,960(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002c68:	fcc42783          	lw	a5,-52(s0)
    80002c6c:	cf85                	beqz	a5,80002ca4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c6e:	00015997          	auipc	s3,0x15
    80002c72:	afa98993          	addi	s3,s3,-1286 # 80017768 <tickslock>
    80002c76:	00006497          	auipc	s1,0x6
    80002c7a:	3aa48493          	addi	s1,s1,938 # 80009020 <ticks>
    if(myproc()->killed){
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	d3c080e7          	jalr	-708(ra) # 800019ba <myproc>
    80002c86:	591c                	lw	a5,48(a0)
    80002c88:	ef9d                	bnez	a5,80002cc6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c8a:	85ce                	mv	a1,s3
    80002c8c:	8526                	mv	a0,s1
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	538080e7          	jalr	1336(ra) # 800021c6 <sleep>
  while(ticks - ticks0 < n){
    80002c96:	409c                	lw	a5,0(s1)
    80002c98:	412787bb          	subw	a5,a5,s2
    80002c9c:	fcc42703          	lw	a4,-52(s0)
    80002ca0:	fce7efe3          	bltu	a5,a4,80002c7e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ca4:	00015517          	auipc	a0,0x15
    80002ca8:	ac450513          	addi	a0,a0,-1340 # 80017768 <tickslock>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	006080e7          	jalr	6(ra) # 80000cb2 <release>
  return 0;
    80002cb4:	4781                	li	a5,0
}
    80002cb6:	853e                	mv	a0,a5
    80002cb8:	70e2                	ld	ra,56(sp)
    80002cba:	7442                	ld	s0,48(sp)
    80002cbc:	74a2                	ld	s1,40(sp)
    80002cbe:	7902                	ld	s2,32(sp)
    80002cc0:	69e2                	ld	s3,24(sp)
    80002cc2:	6121                	addi	sp,sp,64
    80002cc4:	8082                	ret
      release(&tickslock);
    80002cc6:	00015517          	auipc	a0,0x15
    80002cca:	aa250513          	addi	a0,a0,-1374 # 80017768 <tickslock>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	fe4080e7          	jalr	-28(ra) # 80000cb2 <release>
      return -1;
    80002cd6:	57fd                	li	a5,-1
    80002cd8:	bff9                	j	80002cb6 <sys_sleep+0x88>

0000000080002cda <sys_kill>:

uint64
sys_kill(void)
{
    80002cda:	1101                	addi	sp,sp,-32
    80002cdc:	ec06                	sd	ra,24(sp)
    80002cde:	e822                	sd	s0,16(sp)
    80002ce0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ce2:	fec40593          	addi	a1,s0,-20
    80002ce6:	4501                	li	a0,0
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	d86080e7          	jalr	-634(ra) # 80002a6e <argint>
    80002cf0:	87aa                	mv	a5,a0
    return -1;
    80002cf2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002cf4:	0007c863          	bltz	a5,80002d04 <sys_kill+0x2a>
  return kill(pid);
    80002cf8:	fec42503          	lw	a0,-20(s0)
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	6b4080e7          	jalr	1716(ra) # 800023b0 <kill>
}
    80002d04:	60e2                	ld	ra,24(sp)
    80002d06:	6442                	ld	s0,16(sp)
    80002d08:	6105                	addi	sp,sp,32
    80002d0a:	8082                	ret

0000000080002d0c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d0c:	1101                	addi	sp,sp,-32
    80002d0e:	ec06                	sd	ra,24(sp)
    80002d10:	e822                	sd	s0,16(sp)
    80002d12:	e426                	sd	s1,8(sp)
    80002d14:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d16:	00015517          	auipc	a0,0x15
    80002d1a:	a5250513          	addi	a0,a0,-1454 # 80017768 <tickslock>
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	ee0080e7          	jalr	-288(ra) # 80000bfe <acquire>
  xticks = ticks;
    80002d26:	00006497          	auipc	s1,0x6
    80002d2a:	2fa4a483          	lw	s1,762(s1) # 80009020 <ticks>
  release(&tickslock);
    80002d2e:	00015517          	auipc	a0,0x15
    80002d32:	a3a50513          	addi	a0,a0,-1478 # 80017768 <tickslock>
    80002d36:	ffffe097          	auipc	ra,0xffffe
    80002d3a:	f7c080e7          	jalr	-132(ra) # 80000cb2 <release>
  return xticks;
}
    80002d3e:	02049513          	slli	a0,s1,0x20
    80002d42:	9101                	srli	a0,a0,0x20
    80002d44:	60e2                	ld	ra,24(sp)
    80002d46:	6442                	ld	s0,16(sp)
    80002d48:	64a2                	ld	s1,8(sp)
    80002d4a:	6105                	addi	sp,sp,32
    80002d4c:	8082                	ret

0000000080002d4e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d4e:	7179                	addi	sp,sp,-48
    80002d50:	f406                	sd	ra,40(sp)
    80002d52:	f022                	sd	s0,32(sp)
    80002d54:	ec26                	sd	s1,24(sp)
    80002d56:	e84a                	sd	s2,16(sp)
    80002d58:	e44e                	sd	s3,8(sp)
    80002d5a:	e052                	sd	s4,0(sp)
    80002d5c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d5e:	00005597          	auipc	a1,0x5
    80002d62:	7ca58593          	addi	a1,a1,1994 # 80008528 <syscalls+0xb0>
    80002d66:	00015517          	auipc	a0,0x15
    80002d6a:	a1a50513          	addi	a0,a0,-1510 # 80017780 <bcache>
    80002d6e:	ffffe097          	auipc	ra,0xffffe
    80002d72:	e00080e7          	jalr	-512(ra) # 80000b6e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d76:	0001d797          	auipc	a5,0x1d
    80002d7a:	a0a78793          	addi	a5,a5,-1526 # 8001f780 <bcache+0x8000>
    80002d7e:	0001d717          	auipc	a4,0x1d
    80002d82:	c6a70713          	addi	a4,a4,-918 # 8001f9e8 <bcache+0x8268>
    80002d86:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d8a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d8e:	00015497          	auipc	s1,0x15
    80002d92:	a0a48493          	addi	s1,s1,-1526 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002d96:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002d98:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002d9a:	00005a17          	auipc	s4,0x5
    80002d9e:	796a0a13          	addi	s4,s4,1942 # 80008530 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002da2:	2b893783          	ld	a5,696(s2)
    80002da6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002da8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002dac:	85d2                	mv	a1,s4
    80002dae:	01048513          	addi	a0,s1,16
    80002db2:	00001097          	auipc	ra,0x1
    80002db6:	4b2080e7          	jalr	1202(ra) # 80004264 <initsleeplock>
    bcache.head.next->prev = b;
    80002dba:	2b893783          	ld	a5,696(s2)
    80002dbe:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dc0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dc4:	45848493          	addi	s1,s1,1112
    80002dc8:	fd349de3          	bne	s1,s3,80002da2 <binit+0x54>
  }
}
    80002dcc:	70a2                	ld	ra,40(sp)
    80002dce:	7402                	ld	s0,32(sp)
    80002dd0:	64e2                	ld	s1,24(sp)
    80002dd2:	6942                	ld	s2,16(sp)
    80002dd4:	69a2                	ld	s3,8(sp)
    80002dd6:	6a02                	ld	s4,0(sp)
    80002dd8:	6145                	addi	sp,sp,48
    80002dda:	8082                	ret

0000000080002ddc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ddc:	7179                	addi	sp,sp,-48
    80002dde:	f406                	sd	ra,40(sp)
    80002de0:	f022                	sd	s0,32(sp)
    80002de2:	ec26                	sd	s1,24(sp)
    80002de4:	e84a                	sd	s2,16(sp)
    80002de6:	e44e                	sd	s3,8(sp)
    80002de8:	1800                	addi	s0,sp,48
    80002dea:	892a                	mv	s2,a0
    80002dec:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002dee:	00015517          	auipc	a0,0x15
    80002df2:	99250513          	addi	a0,a0,-1646 # 80017780 <bcache>
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	e08080e7          	jalr	-504(ra) # 80000bfe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002dfe:	0001d497          	auipc	s1,0x1d
    80002e02:	c3a4b483          	ld	s1,-966(s1) # 8001fa38 <bcache+0x82b8>
    80002e06:	0001d797          	auipc	a5,0x1d
    80002e0a:	be278793          	addi	a5,a5,-1054 # 8001f9e8 <bcache+0x8268>
    80002e0e:	02f48f63          	beq	s1,a5,80002e4c <bread+0x70>
    80002e12:	873e                	mv	a4,a5
    80002e14:	a021                	j	80002e1c <bread+0x40>
    80002e16:	68a4                	ld	s1,80(s1)
    80002e18:	02e48a63          	beq	s1,a4,80002e4c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e1c:	449c                	lw	a5,8(s1)
    80002e1e:	ff279ce3          	bne	a5,s2,80002e16 <bread+0x3a>
    80002e22:	44dc                	lw	a5,12(s1)
    80002e24:	ff3799e3          	bne	a5,s3,80002e16 <bread+0x3a>
      b->refcnt++;
    80002e28:	40bc                	lw	a5,64(s1)
    80002e2a:	2785                	addiw	a5,a5,1
    80002e2c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e2e:	00015517          	auipc	a0,0x15
    80002e32:	95250513          	addi	a0,a0,-1710 # 80017780 <bcache>
    80002e36:	ffffe097          	auipc	ra,0xffffe
    80002e3a:	e7c080e7          	jalr	-388(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    80002e3e:	01048513          	addi	a0,s1,16
    80002e42:	00001097          	auipc	ra,0x1
    80002e46:	45c080e7          	jalr	1116(ra) # 8000429e <acquiresleep>
      return b;
    80002e4a:	a8b9                	j	80002ea8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e4c:	0001d497          	auipc	s1,0x1d
    80002e50:	be44b483          	ld	s1,-1052(s1) # 8001fa30 <bcache+0x82b0>
    80002e54:	0001d797          	auipc	a5,0x1d
    80002e58:	b9478793          	addi	a5,a5,-1132 # 8001f9e8 <bcache+0x8268>
    80002e5c:	00f48863          	beq	s1,a5,80002e6c <bread+0x90>
    80002e60:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e62:	40bc                	lw	a5,64(s1)
    80002e64:	cf81                	beqz	a5,80002e7c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e66:	64a4                	ld	s1,72(s1)
    80002e68:	fee49de3          	bne	s1,a4,80002e62 <bread+0x86>
  panic("bget: no buffers");
    80002e6c:	00005517          	auipc	a0,0x5
    80002e70:	6cc50513          	addi	a0,a0,1740 # 80008538 <syscalls+0xc0>
    80002e74:	ffffd097          	auipc	ra,0xffffd
    80002e78:	6ce080e7          	jalr	1742(ra) # 80000542 <panic>
      b->dev = dev;
    80002e7c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002e80:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002e84:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e88:	4785                	li	a5,1
    80002e8a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e8c:	00015517          	auipc	a0,0x15
    80002e90:	8f450513          	addi	a0,a0,-1804 # 80017780 <bcache>
    80002e94:	ffffe097          	auipc	ra,0xffffe
    80002e98:	e1e080e7          	jalr	-482(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    80002e9c:	01048513          	addi	a0,s1,16
    80002ea0:	00001097          	auipc	ra,0x1
    80002ea4:	3fe080e7          	jalr	1022(ra) # 8000429e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ea8:	409c                	lw	a5,0(s1)
    80002eaa:	cb89                	beqz	a5,80002ebc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002eac:	8526                	mv	a0,s1
    80002eae:	70a2                	ld	ra,40(sp)
    80002eb0:	7402                	ld	s0,32(sp)
    80002eb2:	64e2                	ld	s1,24(sp)
    80002eb4:	6942                	ld	s2,16(sp)
    80002eb6:	69a2                	ld	s3,8(sp)
    80002eb8:	6145                	addi	sp,sp,48
    80002eba:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ebc:	4581                	li	a1,0
    80002ebe:	8526                	mv	a0,s1
    80002ec0:	00003097          	auipc	ra,0x3
    80002ec4:	f2c080e7          	jalr	-212(ra) # 80005dec <virtio_disk_rw>
    b->valid = 1;
    80002ec8:	4785                	li	a5,1
    80002eca:	c09c                	sw	a5,0(s1)
  return b;
    80002ecc:	b7c5                	j	80002eac <bread+0xd0>

0000000080002ece <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ece:	1101                	addi	sp,sp,-32
    80002ed0:	ec06                	sd	ra,24(sp)
    80002ed2:	e822                	sd	s0,16(sp)
    80002ed4:	e426                	sd	s1,8(sp)
    80002ed6:	1000                	addi	s0,sp,32
    80002ed8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002eda:	0541                	addi	a0,a0,16
    80002edc:	00001097          	auipc	ra,0x1
    80002ee0:	45c080e7          	jalr	1116(ra) # 80004338 <holdingsleep>
    80002ee4:	cd01                	beqz	a0,80002efc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ee6:	4585                	li	a1,1
    80002ee8:	8526                	mv	a0,s1
    80002eea:	00003097          	auipc	ra,0x3
    80002eee:	f02080e7          	jalr	-254(ra) # 80005dec <virtio_disk_rw>
}
    80002ef2:	60e2                	ld	ra,24(sp)
    80002ef4:	6442                	ld	s0,16(sp)
    80002ef6:	64a2                	ld	s1,8(sp)
    80002ef8:	6105                	addi	sp,sp,32
    80002efa:	8082                	ret
    panic("bwrite");
    80002efc:	00005517          	auipc	a0,0x5
    80002f00:	65450513          	addi	a0,a0,1620 # 80008550 <syscalls+0xd8>
    80002f04:	ffffd097          	auipc	ra,0xffffd
    80002f08:	63e080e7          	jalr	1598(ra) # 80000542 <panic>

0000000080002f0c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f0c:	1101                	addi	sp,sp,-32
    80002f0e:	ec06                	sd	ra,24(sp)
    80002f10:	e822                	sd	s0,16(sp)
    80002f12:	e426                	sd	s1,8(sp)
    80002f14:	e04a                	sd	s2,0(sp)
    80002f16:	1000                	addi	s0,sp,32
    80002f18:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f1a:	01050913          	addi	s2,a0,16
    80002f1e:	854a                	mv	a0,s2
    80002f20:	00001097          	auipc	ra,0x1
    80002f24:	418080e7          	jalr	1048(ra) # 80004338 <holdingsleep>
    80002f28:	c92d                	beqz	a0,80002f9a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f2a:	854a                	mv	a0,s2
    80002f2c:	00001097          	auipc	ra,0x1
    80002f30:	3c8080e7          	jalr	968(ra) # 800042f4 <releasesleep>

  acquire(&bcache.lock);
    80002f34:	00015517          	auipc	a0,0x15
    80002f38:	84c50513          	addi	a0,a0,-1972 # 80017780 <bcache>
    80002f3c:	ffffe097          	auipc	ra,0xffffe
    80002f40:	cc2080e7          	jalr	-830(ra) # 80000bfe <acquire>
  b->refcnt--;
    80002f44:	40bc                	lw	a5,64(s1)
    80002f46:	37fd                	addiw	a5,a5,-1
    80002f48:	0007871b          	sext.w	a4,a5
    80002f4c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f4e:	eb05                	bnez	a4,80002f7e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f50:	68bc                	ld	a5,80(s1)
    80002f52:	64b8                	ld	a4,72(s1)
    80002f54:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f56:	64bc                	ld	a5,72(s1)
    80002f58:	68b8                	ld	a4,80(s1)
    80002f5a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f5c:	0001d797          	auipc	a5,0x1d
    80002f60:	82478793          	addi	a5,a5,-2012 # 8001f780 <bcache+0x8000>
    80002f64:	2b87b703          	ld	a4,696(a5)
    80002f68:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f6a:	0001d717          	auipc	a4,0x1d
    80002f6e:	a7e70713          	addi	a4,a4,-1410 # 8001f9e8 <bcache+0x8268>
    80002f72:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f74:	2b87b703          	ld	a4,696(a5)
    80002f78:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f7a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f7e:	00015517          	auipc	a0,0x15
    80002f82:	80250513          	addi	a0,a0,-2046 # 80017780 <bcache>
    80002f86:	ffffe097          	auipc	ra,0xffffe
    80002f8a:	d2c080e7          	jalr	-724(ra) # 80000cb2 <release>
}
    80002f8e:	60e2                	ld	ra,24(sp)
    80002f90:	6442                	ld	s0,16(sp)
    80002f92:	64a2                	ld	s1,8(sp)
    80002f94:	6902                	ld	s2,0(sp)
    80002f96:	6105                	addi	sp,sp,32
    80002f98:	8082                	ret
    panic("brelse");
    80002f9a:	00005517          	auipc	a0,0x5
    80002f9e:	5be50513          	addi	a0,a0,1470 # 80008558 <syscalls+0xe0>
    80002fa2:	ffffd097          	auipc	ra,0xffffd
    80002fa6:	5a0080e7          	jalr	1440(ra) # 80000542 <panic>

0000000080002faa <bpin>:

void
bpin(struct buf *b) {
    80002faa:	1101                	addi	sp,sp,-32
    80002fac:	ec06                	sd	ra,24(sp)
    80002fae:	e822                	sd	s0,16(sp)
    80002fb0:	e426                	sd	s1,8(sp)
    80002fb2:	1000                	addi	s0,sp,32
    80002fb4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fb6:	00014517          	auipc	a0,0x14
    80002fba:	7ca50513          	addi	a0,a0,1994 # 80017780 <bcache>
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	c40080e7          	jalr	-960(ra) # 80000bfe <acquire>
  b->refcnt++;
    80002fc6:	40bc                	lw	a5,64(s1)
    80002fc8:	2785                	addiw	a5,a5,1
    80002fca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fcc:	00014517          	auipc	a0,0x14
    80002fd0:	7b450513          	addi	a0,a0,1972 # 80017780 <bcache>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	cde080e7          	jalr	-802(ra) # 80000cb2 <release>
}
    80002fdc:	60e2                	ld	ra,24(sp)
    80002fde:	6442                	ld	s0,16(sp)
    80002fe0:	64a2                	ld	s1,8(sp)
    80002fe2:	6105                	addi	sp,sp,32
    80002fe4:	8082                	ret

0000000080002fe6 <bunpin>:

void
bunpin(struct buf *b) {
    80002fe6:	1101                	addi	sp,sp,-32
    80002fe8:	ec06                	sd	ra,24(sp)
    80002fea:	e822                	sd	s0,16(sp)
    80002fec:	e426                	sd	s1,8(sp)
    80002fee:	1000                	addi	s0,sp,32
    80002ff0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ff2:	00014517          	auipc	a0,0x14
    80002ff6:	78e50513          	addi	a0,a0,1934 # 80017780 <bcache>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	c04080e7          	jalr	-1020(ra) # 80000bfe <acquire>
  b->refcnt--;
    80003002:	40bc                	lw	a5,64(s1)
    80003004:	37fd                	addiw	a5,a5,-1
    80003006:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003008:	00014517          	auipc	a0,0x14
    8000300c:	77850513          	addi	a0,a0,1912 # 80017780 <bcache>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	ca2080e7          	jalr	-862(ra) # 80000cb2 <release>
}
    80003018:	60e2                	ld	ra,24(sp)
    8000301a:	6442                	ld	s0,16(sp)
    8000301c:	64a2                	ld	s1,8(sp)
    8000301e:	6105                	addi	sp,sp,32
    80003020:	8082                	ret

0000000080003022 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003022:	1101                	addi	sp,sp,-32
    80003024:	ec06                	sd	ra,24(sp)
    80003026:	e822                	sd	s0,16(sp)
    80003028:	e426                	sd	s1,8(sp)
    8000302a:	e04a                	sd	s2,0(sp)
    8000302c:	1000                	addi	s0,sp,32
    8000302e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003030:	00d5d59b          	srliw	a1,a1,0xd
    80003034:	0001d797          	auipc	a5,0x1d
    80003038:	e287a783          	lw	a5,-472(a5) # 8001fe5c <sb+0x1c>
    8000303c:	9dbd                	addw	a1,a1,a5
    8000303e:	00000097          	auipc	ra,0x0
    80003042:	d9e080e7          	jalr	-610(ra) # 80002ddc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003046:	0074f713          	andi	a4,s1,7
    8000304a:	4785                	li	a5,1
    8000304c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003050:	14ce                	slli	s1,s1,0x33
    80003052:	90d9                	srli	s1,s1,0x36
    80003054:	00950733          	add	a4,a0,s1
    80003058:	05874703          	lbu	a4,88(a4)
    8000305c:	00e7f6b3          	and	a3,a5,a4
    80003060:	c69d                	beqz	a3,8000308e <bfree+0x6c>
    80003062:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003064:	94aa                	add	s1,s1,a0
    80003066:	fff7c793          	not	a5,a5
    8000306a:	8ff9                	and	a5,a5,a4
    8000306c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003070:	00001097          	auipc	ra,0x1
    80003074:	106080e7          	jalr	262(ra) # 80004176 <log_write>
  brelse(bp);
    80003078:	854a                	mv	a0,s2
    8000307a:	00000097          	auipc	ra,0x0
    8000307e:	e92080e7          	jalr	-366(ra) # 80002f0c <brelse>
}
    80003082:	60e2                	ld	ra,24(sp)
    80003084:	6442                	ld	s0,16(sp)
    80003086:	64a2                	ld	s1,8(sp)
    80003088:	6902                	ld	s2,0(sp)
    8000308a:	6105                	addi	sp,sp,32
    8000308c:	8082                	ret
    panic("freeing free block");
    8000308e:	00005517          	auipc	a0,0x5
    80003092:	4d250513          	addi	a0,a0,1234 # 80008560 <syscalls+0xe8>
    80003096:	ffffd097          	auipc	ra,0xffffd
    8000309a:	4ac080e7          	jalr	1196(ra) # 80000542 <panic>

000000008000309e <balloc>:
{
    8000309e:	711d                	addi	sp,sp,-96
    800030a0:	ec86                	sd	ra,88(sp)
    800030a2:	e8a2                	sd	s0,80(sp)
    800030a4:	e4a6                	sd	s1,72(sp)
    800030a6:	e0ca                	sd	s2,64(sp)
    800030a8:	fc4e                	sd	s3,56(sp)
    800030aa:	f852                	sd	s4,48(sp)
    800030ac:	f456                	sd	s5,40(sp)
    800030ae:	f05a                	sd	s6,32(sp)
    800030b0:	ec5e                	sd	s7,24(sp)
    800030b2:	e862                	sd	s8,16(sp)
    800030b4:	e466                	sd	s9,8(sp)
    800030b6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030b8:	0001d797          	auipc	a5,0x1d
    800030bc:	d8c7a783          	lw	a5,-628(a5) # 8001fe44 <sb+0x4>
    800030c0:	cbd1                	beqz	a5,80003154 <balloc+0xb6>
    800030c2:	8baa                	mv	s7,a0
    800030c4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030c6:	0001db17          	auipc	s6,0x1d
    800030ca:	d7ab0b13          	addi	s6,s6,-646 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030ce:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030d0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030d2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030d4:	6c89                	lui	s9,0x2
    800030d6:	a831                	j	800030f2 <balloc+0x54>
    brelse(bp);
    800030d8:	854a                	mv	a0,s2
    800030da:	00000097          	auipc	ra,0x0
    800030de:	e32080e7          	jalr	-462(ra) # 80002f0c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030e2:	015c87bb          	addw	a5,s9,s5
    800030e6:	00078a9b          	sext.w	s5,a5
    800030ea:	004b2703          	lw	a4,4(s6)
    800030ee:	06eaf363          	bgeu	s5,a4,80003154 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800030f2:	41fad79b          	sraiw	a5,s5,0x1f
    800030f6:	0137d79b          	srliw	a5,a5,0x13
    800030fa:	015787bb          	addw	a5,a5,s5
    800030fe:	40d7d79b          	sraiw	a5,a5,0xd
    80003102:	01cb2583          	lw	a1,28(s6)
    80003106:	9dbd                	addw	a1,a1,a5
    80003108:	855e                	mv	a0,s7
    8000310a:	00000097          	auipc	ra,0x0
    8000310e:	cd2080e7          	jalr	-814(ra) # 80002ddc <bread>
    80003112:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003114:	004b2503          	lw	a0,4(s6)
    80003118:	000a849b          	sext.w	s1,s5
    8000311c:	8662                	mv	a2,s8
    8000311e:	faa4fde3          	bgeu	s1,a0,800030d8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003122:	41f6579b          	sraiw	a5,a2,0x1f
    80003126:	01d7d69b          	srliw	a3,a5,0x1d
    8000312a:	00c6873b          	addw	a4,a3,a2
    8000312e:	00777793          	andi	a5,a4,7
    80003132:	9f95                	subw	a5,a5,a3
    80003134:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003138:	4037571b          	sraiw	a4,a4,0x3
    8000313c:	00e906b3          	add	a3,s2,a4
    80003140:	0586c683          	lbu	a3,88(a3)
    80003144:	00d7f5b3          	and	a1,a5,a3
    80003148:	cd91                	beqz	a1,80003164 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000314a:	2605                	addiw	a2,a2,1
    8000314c:	2485                	addiw	s1,s1,1
    8000314e:	fd4618e3          	bne	a2,s4,8000311e <balloc+0x80>
    80003152:	b759                	j	800030d8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003154:	00005517          	auipc	a0,0x5
    80003158:	42450513          	addi	a0,a0,1060 # 80008578 <syscalls+0x100>
    8000315c:	ffffd097          	auipc	ra,0xffffd
    80003160:	3e6080e7          	jalr	998(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003164:	974a                	add	a4,a4,s2
    80003166:	8fd5                	or	a5,a5,a3
    80003168:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000316c:	854a                	mv	a0,s2
    8000316e:	00001097          	auipc	ra,0x1
    80003172:	008080e7          	jalr	8(ra) # 80004176 <log_write>
        brelse(bp);
    80003176:	854a                	mv	a0,s2
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	d94080e7          	jalr	-620(ra) # 80002f0c <brelse>
  bp = bread(dev, bno);
    80003180:	85a6                	mv	a1,s1
    80003182:	855e                	mv	a0,s7
    80003184:	00000097          	auipc	ra,0x0
    80003188:	c58080e7          	jalr	-936(ra) # 80002ddc <bread>
    8000318c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000318e:	40000613          	li	a2,1024
    80003192:	4581                	li	a1,0
    80003194:	05850513          	addi	a0,a0,88
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	b62080e7          	jalr	-1182(ra) # 80000cfa <memset>
  log_write(bp);
    800031a0:	854a                	mv	a0,s2
    800031a2:	00001097          	auipc	ra,0x1
    800031a6:	fd4080e7          	jalr	-44(ra) # 80004176 <log_write>
  brelse(bp);
    800031aa:	854a                	mv	a0,s2
    800031ac:	00000097          	auipc	ra,0x0
    800031b0:	d60080e7          	jalr	-672(ra) # 80002f0c <brelse>
}
    800031b4:	8526                	mv	a0,s1
    800031b6:	60e6                	ld	ra,88(sp)
    800031b8:	6446                	ld	s0,80(sp)
    800031ba:	64a6                	ld	s1,72(sp)
    800031bc:	6906                	ld	s2,64(sp)
    800031be:	79e2                	ld	s3,56(sp)
    800031c0:	7a42                	ld	s4,48(sp)
    800031c2:	7aa2                	ld	s5,40(sp)
    800031c4:	7b02                	ld	s6,32(sp)
    800031c6:	6be2                	ld	s7,24(sp)
    800031c8:	6c42                	ld	s8,16(sp)
    800031ca:	6ca2                	ld	s9,8(sp)
    800031cc:	6125                	addi	sp,sp,96
    800031ce:	8082                	ret

00000000800031d0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031d0:	7179                	addi	sp,sp,-48
    800031d2:	f406                	sd	ra,40(sp)
    800031d4:	f022                	sd	s0,32(sp)
    800031d6:	ec26                	sd	s1,24(sp)
    800031d8:	e84a                	sd	s2,16(sp)
    800031da:	e44e                	sd	s3,8(sp)
    800031dc:	e052                	sd	s4,0(sp)
    800031de:	1800                	addi	s0,sp,48
    800031e0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031e2:	47ad                	li	a5,11
    800031e4:	04b7fe63          	bgeu	a5,a1,80003240 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031e8:	ff45849b          	addiw	s1,a1,-12
    800031ec:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031f0:	0ff00793          	li	a5,255
    800031f4:	0ae7e463          	bltu	a5,a4,8000329c <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800031f8:	08052583          	lw	a1,128(a0)
    800031fc:	c5b5                	beqz	a1,80003268 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800031fe:	00092503          	lw	a0,0(s2)
    80003202:	00000097          	auipc	ra,0x0
    80003206:	bda080e7          	jalr	-1062(ra) # 80002ddc <bread>
    8000320a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000320c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003210:	02049713          	slli	a4,s1,0x20
    80003214:	01e75593          	srli	a1,a4,0x1e
    80003218:	00b784b3          	add	s1,a5,a1
    8000321c:	0004a983          	lw	s3,0(s1)
    80003220:	04098e63          	beqz	s3,8000327c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003224:	8552                	mv	a0,s4
    80003226:	00000097          	auipc	ra,0x0
    8000322a:	ce6080e7          	jalr	-794(ra) # 80002f0c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000322e:	854e                	mv	a0,s3
    80003230:	70a2                	ld	ra,40(sp)
    80003232:	7402                	ld	s0,32(sp)
    80003234:	64e2                	ld	s1,24(sp)
    80003236:	6942                	ld	s2,16(sp)
    80003238:	69a2                	ld	s3,8(sp)
    8000323a:	6a02                	ld	s4,0(sp)
    8000323c:	6145                	addi	sp,sp,48
    8000323e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003240:	02059793          	slli	a5,a1,0x20
    80003244:	01e7d593          	srli	a1,a5,0x1e
    80003248:	00b504b3          	add	s1,a0,a1
    8000324c:	0504a983          	lw	s3,80(s1)
    80003250:	fc099fe3          	bnez	s3,8000322e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003254:	4108                	lw	a0,0(a0)
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	e48080e7          	jalr	-440(ra) # 8000309e <balloc>
    8000325e:	0005099b          	sext.w	s3,a0
    80003262:	0534a823          	sw	s3,80(s1)
    80003266:	b7e1                	j	8000322e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003268:	4108                	lw	a0,0(a0)
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	e34080e7          	jalr	-460(ra) # 8000309e <balloc>
    80003272:	0005059b          	sext.w	a1,a0
    80003276:	08b92023          	sw	a1,128(s2)
    8000327a:	b751                	j	800031fe <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000327c:	00092503          	lw	a0,0(s2)
    80003280:	00000097          	auipc	ra,0x0
    80003284:	e1e080e7          	jalr	-482(ra) # 8000309e <balloc>
    80003288:	0005099b          	sext.w	s3,a0
    8000328c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003290:	8552                	mv	a0,s4
    80003292:	00001097          	auipc	ra,0x1
    80003296:	ee4080e7          	jalr	-284(ra) # 80004176 <log_write>
    8000329a:	b769                	j	80003224 <bmap+0x54>
  panic("bmap: out of range");
    8000329c:	00005517          	auipc	a0,0x5
    800032a0:	2f450513          	addi	a0,a0,756 # 80008590 <syscalls+0x118>
    800032a4:	ffffd097          	auipc	ra,0xffffd
    800032a8:	29e080e7          	jalr	670(ra) # 80000542 <panic>

00000000800032ac <iget>:
{
    800032ac:	7179                	addi	sp,sp,-48
    800032ae:	f406                	sd	ra,40(sp)
    800032b0:	f022                	sd	s0,32(sp)
    800032b2:	ec26                	sd	s1,24(sp)
    800032b4:	e84a                	sd	s2,16(sp)
    800032b6:	e44e                	sd	s3,8(sp)
    800032b8:	e052                	sd	s4,0(sp)
    800032ba:	1800                	addi	s0,sp,48
    800032bc:	89aa                	mv	s3,a0
    800032be:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800032c0:	0001d517          	auipc	a0,0x1d
    800032c4:	ba050513          	addi	a0,a0,-1120 # 8001fe60 <icache>
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	936080e7          	jalr	-1738(ra) # 80000bfe <acquire>
  empty = 0;
    800032d0:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800032d2:	0001d497          	auipc	s1,0x1d
    800032d6:	ba648493          	addi	s1,s1,-1114 # 8001fe78 <icache+0x18>
    800032da:	0001e697          	auipc	a3,0x1e
    800032de:	62e68693          	addi	a3,a3,1582 # 80021908 <log>
    800032e2:	a039                	j	800032f0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032e4:	02090b63          	beqz	s2,8000331a <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800032e8:	08848493          	addi	s1,s1,136
    800032ec:	02d48a63          	beq	s1,a3,80003320 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800032f0:	449c                	lw	a5,8(s1)
    800032f2:	fef059e3          	blez	a5,800032e4 <iget+0x38>
    800032f6:	4098                	lw	a4,0(s1)
    800032f8:	ff3716e3          	bne	a4,s3,800032e4 <iget+0x38>
    800032fc:	40d8                	lw	a4,4(s1)
    800032fe:	ff4713e3          	bne	a4,s4,800032e4 <iget+0x38>
      ip->ref++;
    80003302:	2785                	addiw	a5,a5,1
    80003304:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003306:	0001d517          	auipc	a0,0x1d
    8000330a:	b5a50513          	addi	a0,a0,-1190 # 8001fe60 <icache>
    8000330e:	ffffe097          	auipc	ra,0xffffe
    80003312:	9a4080e7          	jalr	-1628(ra) # 80000cb2 <release>
      return ip;
    80003316:	8926                	mv	s2,s1
    80003318:	a03d                	j	80003346 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000331a:	f7f9                	bnez	a5,800032e8 <iget+0x3c>
    8000331c:	8926                	mv	s2,s1
    8000331e:	b7e9                	j	800032e8 <iget+0x3c>
  if(empty == 0)
    80003320:	02090c63          	beqz	s2,80003358 <iget+0xac>
  ip->dev = dev;
    80003324:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003328:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000332c:	4785                	li	a5,1
    8000332e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003332:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003336:	0001d517          	auipc	a0,0x1d
    8000333a:	b2a50513          	addi	a0,a0,-1238 # 8001fe60 <icache>
    8000333e:	ffffe097          	auipc	ra,0xffffe
    80003342:	974080e7          	jalr	-1676(ra) # 80000cb2 <release>
}
    80003346:	854a                	mv	a0,s2
    80003348:	70a2                	ld	ra,40(sp)
    8000334a:	7402                	ld	s0,32(sp)
    8000334c:	64e2                	ld	s1,24(sp)
    8000334e:	6942                	ld	s2,16(sp)
    80003350:	69a2                	ld	s3,8(sp)
    80003352:	6a02                	ld	s4,0(sp)
    80003354:	6145                	addi	sp,sp,48
    80003356:	8082                	ret
    panic("iget: no inodes");
    80003358:	00005517          	auipc	a0,0x5
    8000335c:	25050513          	addi	a0,a0,592 # 800085a8 <syscalls+0x130>
    80003360:	ffffd097          	auipc	ra,0xffffd
    80003364:	1e2080e7          	jalr	482(ra) # 80000542 <panic>

0000000080003368 <fsinit>:
fsinit(int dev) {
    80003368:	7179                	addi	sp,sp,-48
    8000336a:	f406                	sd	ra,40(sp)
    8000336c:	f022                	sd	s0,32(sp)
    8000336e:	ec26                	sd	s1,24(sp)
    80003370:	e84a                	sd	s2,16(sp)
    80003372:	e44e                	sd	s3,8(sp)
    80003374:	1800                	addi	s0,sp,48
    80003376:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003378:	4585                	li	a1,1
    8000337a:	00000097          	auipc	ra,0x0
    8000337e:	a62080e7          	jalr	-1438(ra) # 80002ddc <bread>
    80003382:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003384:	0001d997          	auipc	s3,0x1d
    80003388:	abc98993          	addi	s3,s3,-1348 # 8001fe40 <sb>
    8000338c:	02000613          	li	a2,32
    80003390:	05850593          	addi	a1,a0,88
    80003394:	854e                	mv	a0,s3
    80003396:	ffffe097          	auipc	ra,0xffffe
    8000339a:	9c0080e7          	jalr	-1600(ra) # 80000d56 <memmove>
  brelse(bp);
    8000339e:	8526                	mv	a0,s1
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	b6c080e7          	jalr	-1172(ra) # 80002f0c <brelse>
  if(sb.magic != FSMAGIC)
    800033a8:	0009a703          	lw	a4,0(s3)
    800033ac:	102037b7          	lui	a5,0x10203
    800033b0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033b4:	02f71263          	bne	a4,a5,800033d8 <fsinit+0x70>
  initlog(dev, &sb);
    800033b8:	0001d597          	auipc	a1,0x1d
    800033bc:	a8858593          	addi	a1,a1,-1400 # 8001fe40 <sb>
    800033c0:	854a                	mv	a0,s2
    800033c2:	00001097          	auipc	ra,0x1
    800033c6:	b3a080e7          	jalr	-1222(ra) # 80003efc <initlog>
}
    800033ca:	70a2                	ld	ra,40(sp)
    800033cc:	7402                	ld	s0,32(sp)
    800033ce:	64e2                	ld	s1,24(sp)
    800033d0:	6942                	ld	s2,16(sp)
    800033d2:	69a2                	ld	s3,8(sp)
    800033d4:	6145                	addi	sp,sp,48
    800033d6:	8082                	ret
    panic("invalid file system");
    800033d8:	00005517          	auipc	a0,0x5
    800033dc:	1e050513          	addi	a0,a0,480 # 800085b8 <syscalls+0x140>
    800033e0:	ffffd097          	auipc	ra,0xffffd
    800033e4:	162080e7          	jalr	354(ra) # 80000542 <panic>

00000000800033e8 <iinit>:
{
    800033e8:	7179                	addi	sp,sp,-48
    800033ea:	f406                	sd	ra,40(sp)
    800033ec:	f022                	sd	s0,32(sp)
    800033ee:	ec26                	sd	s1,24(sp)
    800033f0:	e84a                	sd	s2,16(sp)
    800033f2:	e44e                	sd	s3,8(sp)
    800033f4:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800033f6:	00005597          	auipc	a1,0x5
    800033fa:	1da58593          	addi	a1,a1,474 # 800085d0 <syscalls+0x158>
    800033fe:	0001d517          	auipc	a0,0x1d
    80003402:	a6250513          	addi	a0,a0,-1438 # 8001fe60 <icache>
    80003406:	ffffd097          	auipc	ra,0xffffd
    8000340a:	768080e7          	jalr	1896(ra) # 80000b6e <initlock>
  for(i = 0; i < NINODE; i++) {
    8000340e:	0001d497          	auipc	s1,0x1d
    80003412:	a7a48493          	addi	s1,s1,-1414 # 8001fe88 <icache+0x28>
    80003416:	0001e997          	auipc	s3,0x1e
    8000341a:	50298993          	addi	s3,s3,1282 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000341e:	00005917          	auipc	s2,0x5
    80003422:	1ba90913          	addi	s2,s2,442 # 800085d8 <syscalls+0x160>
    80003426:	85ca                	mv	a1,s2
    80003428:	8526                	mv	a0,s1
    8000342a:	00001097          	auipc	ra,0x1
    8000342e:	e3a080e7          	jalr	-454(ra) # 80004264 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003432:	08848493          	addi	s1,s1,136
    80003436:	ff3498e3          	bne	s1,s3,80003426 <iinit+0x3e>
}
    8000343a:	70a2                	ld	ra,40(sp)
    8000343c:	7402                	ld	s0,32(sp)
    8000343e:	64e2                	ld	s1,24(sp)
    80003440:	6942                	ld	s2,16(sp)
    80003442:	69a2                	ld	s3,8(sp)
    80003444:	6145                	addi	sp,sp,48
    80003446:	8082                	ret

0000000080003448 <ialloc>:
{
    80003448:	715d                	addi	sp,sp,-80
    8000344a:	e486                	sd	ra,72(sp)
    8000344c:	e0a2                	sd	s0,64(sp)
    8000344e:	fc26                	sd	s1,56(sp)
    80003450:	f84a                	sd	s2,48(sp)
    80003452:	f44e                	sd	s3,40(sp)
    80003454:	f052                	sd	s4,32(sp)
    80003456:	ec56                	sd	s5,24(sp)
    80003458:	e85a                	sd	s6,16(sp)
    8000345a:	e45e                	sd	s7,8(sp)
    8000345c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000345e:	0001d717          	auipc	a4,0x1d
    80003462:	9ee72703          	lw	a4,-1554(a4) # 8001fe4c <sb+0xc>
    80003466:	4785                	li	a5,1
    80003468:	04e7fa63          	bgeu	a5,a4,800034bc <ialloc+0x74>
    8000346c:	8aaa                	mv	s5,a0
    8000346e:	8bae                	mv	s7,a1
    80003470:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003472:	0001da17          	auipc	s4,0x1d
    80003476:	9cea0a13          	addi	s4,s4,-1586 # 8001fe40 <sb>
    8000347a:	00048b1b          	sext.w	s6,s1
    8000347e:	0044d793          	srli	a5,s1,0x4
    80003482:	018a2583          	lw	a1,24(s4)
    80003486:	9dbd                	addw	a1,a1,a5
    80003488:	8556                	mv	a0,s5
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	952080e7          	jalr	-1710(ra) # 80002ddc <bread>
    80003492:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003494:	05850993          	addi	s3,a0,88
    80003498:	00f4f793          	andi	a5,s1,15
    8000349c:	079a                	slli	a5,a5,0x6
    8000349e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034a0:	00099783          	lh	a5,0(s3)
    800034a4:	c785                	beqz	a5,800034cc <ialloc+0x84>
    brelse(bp);
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	a66080e7          	jalr	-1434(ra) # 80002f0c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034ae:	0485                	addi	s1,s1,1
    800034b0:	00ca2703          	lw	a4,12(s4)
    800034b4:	0004879b          	sext.w	a5,s1
    800034b8:	fce7e1e3          	bltu	a5,a4,8000347a <ialloc+0x32>
  panic("ialloc: no inodes");
    800034bc:	00005517          	auipc	a0,0x5
    800034c0:	12450513          	addi	a0,a0,292 # 800085e0 <syscalls+0x168>
    800034c4:	ffffd097          	auipc	ra,0xffffd
    800034c8:	07e080e7          	jalr	126(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    800034cc:	04000613          	li	a2,64
    800034d0:	4581                	li	a1,0
    800034d2:	854e                	mv	a0,s3
    800034d4:	ffffe097          	auipc	ra,0xffffe
    800034d8:	826080e7          	jalr	-2010(ra) # 80000cfa <memset>
      dip->type = type;
    800034dc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034e0:	854a                	mv	a0,s2
    800034e2:	00001097          	auipc	ra,0x1
    800034e6:	c94080e7          	jalr	-876(ra) # 80004176 <log_write>
      brelse(bp);
    800034ea:	854a                	mv	a0,s2
    800034ec:	00000097          	auipc	ra,0x0
    800034f0:	a20080e7          	jalr	-1504(ra) # 80002f0c <brelse>
      return iget(dev, inum);
    800034f4:	85da                	mv	a1,s6
    800034f6:	8556                	mv	a0,s5
    800034f8:	00000097          	auipc	ra,0x0
    800034fc:	db4080e7          	jalr	-588(ra) # 800032ac <iget>
}
    80003500:	60a6                	ld	ra,72(sp)
    80003502:	6406                	ld	s0,64(sp)
    80003504:	74e2                	ld	s1,56(sp)
    80003506:	7942                	ld	s2,48(sp)
    80003508:	79a2                	ld	s3,40(sp)
    8000350a:	7a02                	ld	s4,32(sp)
    8000350c:	6ae2                	ld	s5,24(sp)
    8000350e:	6b42                	ld	s6,16(sp)
    80003510:	6ba2                	ld	s7,8(sp)
    80003512:	6161                	addi	sp,sp,80
    80003514:	8082                	ret

0000000080003516 <iupdate>:
{
    80003516:	1101                	addi	sp,sp,-32
    80003518:	ec06                	sd	ra,24(sp)
    8000351a:	e822                	sd	s0,16(sp)
    8000351c:	e426                	sd	s1,8(sp)
    8000351e:	e04a                	sd	s2,0(sp)
    80003520:	1000                	addi	s0,sp,32
    80003522:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003524:	415c                	lw	a5,4(a0)
    80003526:	0047d79b          	srliw	a5,a5,0x4
    8000352a:	0001d597          	auipc	a1,0x1d
    8000352e:	92e5a583          	lw	a1,-1746(a1) # 8001fe58 <sb+0x18>
    80003532:	9dbd                	addw	a1,a1,a5
    80003534:	4108                	lw	a0,0(a0)
    80003536:	00000097          	auipc	ra,0x0
    8000353a:	8a6080e7          	jalr	-1882(ra) # 80002ddc <bread>
    8000353e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003540:	05850793          	addi	a5,a0,88
    80003544:	40c8                	lw	a0,4(s1)
    80003546:	893d                	andi	a0,a0,15
    80003548:	051a                	slli	a0,a0,0x6
    8000354a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000354c:	04449703          	lh	a4,68(s1)
    80003550:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003554:	04649703          	lh	a4,70(s1)
    80003558:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000355c:	04849703          	lh	a4,72(s1)
    80003560:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003564:	04a49703          	lh	a4,74(s1)
    80003568:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000356c:	44f8                	lw	a4,76(s1)
    8000356e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003570:	03400613          	li	a2,52
    80003574:	05048593          	addi	a1,s1,80
    80003578:	0531                	addi	a0,a0,12
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	7dc080e7          	jalr	2012(ra) # 80000d56 <memmove>
  log_write(bp);
    80003582:	854a                	mv	a0,s2
    80003584:	00001097          	auipc	ra,0x1
    80003588:	bf2080e7          	jalr	-1038(ra) # 80004176 <log_write>
  brelse(bp);
    8000358c:	854a                	mv	a0,s2
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	97e080e7          	jalr	-1666(ra) # 80002f0c <brelse>
}
    80003596:	60e2                	ld	ra,24(sp)
    80003598:	6442                	ld	s0,16(sp)
    8000359a:	64a2                	ld	s1,8(sp)
    8000359c:	6902                	ld	s2,0(sp)
    8000359e:	6105                	addi	sp,sp,32
    800035a0:	8082                	ret

00000000800035a2 <idup>:
{
    800035a2:	1101                	addi	sp,sp,-32
    800035a4:	ec06                	sd	ra,24(sp)
    800035a6:	e822                	sd	s0,16(sp)
    800035a8:	e426                	sd	s1,8(sp)
    800035aa:	1000                	addi	s0,sp,32
    800035ac:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800035ae:	0001d517          	auipc	a0,0x1d
    800035b2:	8b250513          	addi	a0,a0,-1870 # 8001fe60 <icache>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	648080e7          	jalr	1608(ra) # 80000bfe <acquire>
  ip->ref++;
    800035be:	449c                	lw	a5,8(s1)
    800035c0:	2785                	addiw	a5,a5,1
    800035c2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800035c4:	0001d517          	auipc	a0,0x1d
    800035c8:	89c50513          	addi	a0,a0,-1892 # 8001fe60 <icache>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	6e6080e7          	jalr	1766(ra) # 80000cb2 <release>
}
    800035d4:	8526                	mv	a0,s1
    800035d6:	60e2                	ld	ra,24(sp)
    800035d8:	6442                	ld	s0,16(sp)
    800035da:	64a2                	ld	s1,8(sp)
    800035dc:	6105                	addi	sp,sp,32
    800035de:	8082                	ret

00000000800035e0 <ilock>:
{
    800035e0:	1101                	addi	sp,sp,-32
    800035e2:	ec06                	sd	ra,24(sp)
    800035e4:	e822                	sd	s0,16(sp)
    800035e6:	e426                	sd	s1,8(sp)
    800035e8:	e04a                	sd	s2,0(sp)
    800035ea:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800035ec:	c115                	beqz	a0,80003610 <ilock+0x30>
    800035ee:	84aa                	mv	s1,a0
    800035f0:	451c                	lw	a5,8(a0)
    800035f2:	00f05f63          	blez	a5,80003610 <ilock+0x30>
  acquiresleep(&ip->lock);
    800035f6:	0541                	addi	a0,a0,16
    800035f8:	00001097          	auipc	ra,0x1
    800035fc:	ca6080e7          	jalr	-858(ra) # 8000429e <acquiresleep>
  if(ip->valid == 0){
    80003600:	40bc                	lw	a5,64(s1)
    80003602:	cf99                	beqz	a5,80003620 <ilock+0x40>
}
    80003604:	60e2                	ld	ra,24(sp)
    80003606:	6442                	ld	s0,16(sp)
    80003608:	64a2                	ld	s1,8(sp)
    8000360a:	6902                	ld	s2,0(sp)
    8000360c:	6105                	addi	sp,sp,32
    8000360e:	8082                	ret
    panic("ilock");
    80003610:	00005517          	auipc	a0,0x5
    80003614:	fe850513          	addi	a0,a0,-24 # 800085f8 <syscalls+0x180>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	f2a080e7          	jalr	-214(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003620:	40dc                	lw	a5,4(s1)
    80003622:	0047d79b          	srliw	a5,a5,0x4
    80003626:	0001d597          	auipc	a1,0x1d
    8000362a:	8325a583          	lw	a1,-1998(a1) # 8001fe58 <sb+0x18>
    8000362e:	9dbd                	addw	a1,a1,a5
    80003630:	4088                	lw	a0,0(s1)
    80003632:	fffff097          	auipc	ra,0xfffff
    80003636:	7aa080e7          	jalr	1962(ra) # 80002ddc <bread>
    8000363a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000363c:	05850593          	addi	a1,a0,88
    80003640:	40dc                	lw	a5,4(s1)
    80003642:	8bbd                	andi	a5,a5,15
    80003644:	079a                	slli	a5,a5,0x6
    80003646:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003648:	00059783          	lh	a5,0(a1)
    8000364c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003650:	00259783          	lh	a5,2(a1)
    80003654:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003658:	00459783          	lh	a5,4(a1)
    8000365c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003660:	00659783          	lh	a5,6(a1)
    80003664:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003668:	459c                	lw	a5,8(a1)
    8000366a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000366c:	03400613          	li	a2,52
    80003670:	05b1                	addi	a1,a1,12
    80003672:	05048513          	addi	a0,s1,80
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	6e0080e7          	jalr	1760(ra) # 80000d56 <memmove>
    brelse(bp);
    8000367e:	854a                	mv	a0,s2
    80003680:	00000097          	auipc	ra,0x0
    80003684:	88c080e7          	jalr	-1908(ra) # 80002f0c <brelse>
    ip->valid = 1;
    80003688:	4785                	li	a5,1
    8000368a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000368c:	04449783          	lh	a5,68(s1)
    80003690:	fbb5                	bnez	a5,80003604 <ilock+0x24>
      panic("ilock: no type");
    80003692:	00005517          	auipc	a0,0x5
    80003696:	f6e50513          	addi	a0,a0,-146 # 80008600 <syscalls+0x188>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	ea8080e7          	jalr	-344(ra) # 80000542 <panic>

00000000800036a2 <iunlock>:
{
    800036a2:	1101                	addi	sp,sp,-32
    800036a4:	ec06                	sd	ra,24(sp)
    800036a6:	e822                	sd	s0,16(sp)
    800036a8:	e426                	sd	s1,8(sp)
    800036aa:	e04a                	sd	s2,0(sp)
    800036ac:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036ae:	c905                	beqz	a0,800036de <iunlock+0x3c>
    800036b0:	84aa                	mv	s1,a0
    800036b2:	01050913          	addi	s2,a0,16
    800036b6:	854a                	mv	a0,s2
    800036b8:	00001097          	auipc	ra,0x1
    800036bc:	c80080e7          	jalr	-896(ra) # 80004338 <holdingsleep>
    800036c0:	cd19                	beqz	a0,800036de <iunlock+0x3c>
    800036c2:	449c                	lw	a5,8(s1)
    800036c4:	00f05d63          	blez	a5,800036de <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036c8:	854a                	mv	a0,s2
    800036ca:	00001097          	auipc	ra,0x1
    800036ce:	c2a080e7          	jalr	-982(ra) # 800042f4 <releasesleep>
}
    800036d2:	60e2                	ld	ra,24(sp)
    800036d4:	6442                	ld	s0,16(sp)
    800036d6:	64a2                	ld	s1,8(sp)
    800036d8:	6902                	ld	s2,0(sp)
    800036da:	6105                	addi	sp,sp,32
    800036dc:	8082                	ret
    panic("iunlock");
    800036de:	00005517          	auipc	a0,0x5
    800036e2:	f3250513          	addi	a0,a0,-206 # 80008610 <syscalls+0x198>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	e5c080e7          	jalr	-420(ra) # 80000542 <panic>

00000000800036ee <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800036ee:	7179                	addi	sp,sp,-48
    800036f0:	f406                	sd	ra,40(sp)
    800036f2:	f022                	sd	s0,32(sp)
    800036f4:	ec26                	sd	s1,24(sp)
    800036f6:	e84a                	sd	s2,16(sp)
    800036f8:	e44e                	sd	s3,8(sp)
    800036fa:	e052                	sd	s4,0(sp)
    800036fc:	1800                	addi	s0,sp,48
    800036fe:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003700:	05050493          	addi	s1,a0,80
    80003704:	08050913          	addi	s2,a0,128
    80003708:	a021                	j	80003710 <itrunc+0x22>
    8000370a:	0491                	addi	s1,s1,4
    8000370c:	01248d63          	beq	s1,s2,80003726 <itrunc+0x38>
    if(ip->addrs[i]){
    80003710:	408c                	lw	a1,0(s1)
    80003712:	dde5                	beqz	a1,8000370a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003714:	0009a503          	lw	a0,0(s3)
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	90a080e7          	jalr	-1782(ra) # 80003022 <bfree>
      ip->addrs[i] = 0;
    80003720:	0004a023          	sw	zero,0(s1)
    80003724:	b7dd                	j	8000370a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003726:	0809a583          	lw	a1,128(s3)
    8000372a:	e185                	bnez	a1,8000374a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000372c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003730:	854e                	mv	a0,s3
    80003732:	00000097          	auipc	ra,0x0
    80003736:	de4080e7          	jalr	-540(ra) # 80003516 <iupdate>
}
    8000373a:	70a2                	ld	ra,40(sp)
    8000373c:	7402                	ld	s0,32(sp)
    8000373e:	64e2                	ld	s1,24(sp)
    80003740:	6942                	ld	s2,16(sp)
    80003742:	69a2                	ld	s3,8(sp)
    80003744:	6a02                	ld	s4,0(sp)
    80003746:	6145                	addi	sp,sp,48
    80003748:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000374a:	0009a503          	lw	a0,0(s3)
    8000374e:	fffff097          	auipc	ra,0xfffff
    80003752:	68e080e7          	jalr	1678(ra) # 80002ddc <bread>
    80003756:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003758:	05850493          	addi	s1,a0,88
    8000375c:	45850913          	addi	s2,a0,1112
    80003760:	a021                	j	80003768 <itrunc+0x7a>
    80003762:	0491                	addi	s1,s1,4
    80003764:	01248b63          	beq	s1,s2,8000377a <itrunc+0x8c>
      if(a[j])
    80003768:	408c                	lw	a1,0(s1)
    8000376a:	dde5                	beqz	a1,80003762 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000376c:	0009a503          	lw	a0,0(s3)
    80003770:	00000097          	auipc	ra,0x0
    80003774:	8b2080e7          	jalr	-1870(ra) # 80003022 <bfree>
    80003778:	b7ed                	j	80003762 <itrunc+0x74>
    brelse(bp);
    8000377a:	8552                	mv	a0,s4
    8000377c:	fffff097          	auipc	ra,0xfffff
    80003780:	790080e7          	jalr	1936(ra) # 80002f0c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003784:	0809a583          	lw	a1,128(s3)
    80003788:	0009a503          	lw	a0,0(s3)
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	896080e7          	jalr	-1898(ra) # 80003022 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003794:	0809a023          	sw	zero,128(s3)
    80003798:	bf51                	j	8000372c <itrunc+0x3e>

000000008000379a <iput>:
{
    8000379a:	1101                	addi	sp,sp,-32
    8000379c:	ec06                	sd	ra,24(sp)
    8000379e:	e822                	sd	s0,16(sp)
    800037a0:	e426                	sd	s1,8(sp)
    800037a2:	e04a                	sd	s2,0(sp)
    800037a4:	1000                	addi	s0,sp,32
    800037a6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037a8:	0001c517          	auipc	a0,0x1c
    800037ac:	6b850513          	addi	a0,a0,1720 # 8001fe60 <icache>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	44e080e7          	jalr	1102(ra) # 80000bfe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037b8:	4498                	lw	a4,8(s1)
    800037ba:	4785                	li	a5,1
    800037bc:	02f70363          	beq	a4,a5,800037e2 <iput+0x48>
  ip->ref--;
    800037c0:	449c                	lw	a5,8(s1)
    800037c2:	37fd                	addiw	a5,a5,-1
    800037c4:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037c6:	0001c517          	auipc	a0,0x1c
    800037ca:	69a50513          	addi	a0,a0,1690 # 8001fe60 <icache>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	4e4080e7          	jalr	1252(ra) # 80000cb2 <release>
}
    800037d6:	60e2                	ld	ra,24(sp)
    800037d8:	6442                	ld	s0,16(sp)
    800037da:	64a2                	ld	s1,8(sp)
    800037dc:	6902                	ld	s2,0(sp)
    800037de:	6105                	addi	sp,sp,32
    800037e0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037e2:	40bc                	lw	a5,64(s1)
    800037e4:	dff1                	beqz	a5,800037c0 <iput+0x26>
    800037e6:	04a49783          	lh	a5,74(s1)
    800037ea:	fbf9                	bnez	a5,800037c0 <iput+0x26>
    acquiresleep(&ip->lock);
    800037ec:	01048913          	addi	s2,s1,16
    800037f0:	854a                	mv	a0,s2
    800037f2:	00001097          	auipc	ra,0x1
    800037f6:	aac080e7          	jalr	-1364(ra) # 8000429e <acquiresleep>
    release(&icache.lock);
    800037fa:	0001c517          	auipc	a0,0x1c
    800037fe:	66650513          	addi	a0,a0,1638 # 8001fe60 <icache>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	4b0080e7          	jalr	1200(ra) # 80000cb2 <release>
    itrunc(ip);
    8000380a:	8526                	mv	a0,s1
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	ee2080e7          	jalr	-286(ra) # 800036ee <itrunc>
    ip->type = 0;
    80003814:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003818:	8526                	mv	a0,s1
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	cfc080e7          	jalr	-772(ra) # 80003516 <iupdate>
    ip->valid = 0;
    80003822:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003826:	854a                	mv	a0,s2
    80003828:	00001097          	auipc	ra,0x1
    8000382c:	acc080e7          	jalr	-1332(ra) # 800042f4 <releasesleep>
    acquire(&icache.lock);
    80003830:	0001c517          	auipc	a0,0x1c
    80003834:	63050513          	addi	a0,a0,1584 # 8001fe60 <icache>
    80003838:	ffffd097          	auipc	ra,0xffffd
    8000383c:	3c6080e7          	jalr	966(ra) # 80000bfe <acquire>
    80003840:	b741                	j	800037c0 <iput+0x26>

0000000080003842 <iunlockput>:
{
    80003842:	1101                	addi	sp,sp,-32
    80003844:	ec06                	sd	ra,24(sp)
    80003846:	e822                	sd	s0,16(sp)
    80003848:	e426                	sd	s1,8(sp)
    8000384a:	1000                	addi	s0,sp,32
    8000384c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	e54080e7          	jalr	-428(ra) # 800036a2 <iunlock>
  iput(ip);
    80003856:	8526                	mv	a0,s1
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	f42080e7          	jalr	-190(ra) # 8000379a <iput>
}
    80003860:	60e2                	ld	ra,24(sp)
    80003862:	6442                	ld	s0,16(sp)
    80003864:	64a2                	ld	s1,8(sp)
    80003866:	6105                	addi	sp,sp,32
    80003868:	8082                	ret

000000008000386a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000386a:	1141                	addi	sp,sp,-16
    8000386c:	e422                	sd	s0,8(sp)
    8000386e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003870:	411c                	lw	a5,0(a0)
    80003872:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003874:	415c                	lw	a5,4(a0)
    80003876:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003878:	04451783          	lh	a5,68(a0)
    8000387c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003880:	04a51783          	lh	a5,74(a0)
    80003884:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003888:	04c56783          	lwu	a5,76(a0)
    8000388c:	e99c                	sd	a5,16(a1)
}
    8000388e:	6422                	ld	s0,8(sp)
    80003890:	0141                	addi	sp,sp,16
    80003892:	8082                	ret

0000000080003894 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003894:	457c                	lw	a5,76(a0)
    80003896:	0ed7e863          	bltu	a5,a3,80003986 <readi+0xf2>
{
    8000389a:	7159                	addi	sp,sp,-112
    8000389c:	f486                	sd	ra,104(sp)
    8000389e:	f0a2                	sd	s0,96(sp)
    800038a0:	eca6                	sd	s1,88(sp)
    800038a2:	e8ca                	sd	s2,80(sp)
    800038a4:	e4ce                	sd	s3,72(sp)
    800038a6:	e0d2                	sd	s4,64(sp)
    800038a8:	fc56                	sd	s5,56(sp)
    800038aa:	f85a                	sd	s6,48(sp)
    800038ac:	f45e                	sd	s7,40(sp)
    800038ae:	f062                	sd	s8,32(sp)
    800038b0:	ec66                	sd	s9,24(sp)
    800038b2:	e86a                	sd	s10,16(sp)
    800038b4:	e46e                	sd	s11,8(sp)
    800038b6:	1880                	addi	s0,sp,112
    800038b8:	8baa                	mv	s7,a0
    800038ba:	8c2e                	mv	s8,a1
    800038bc:	8ab2                	mv	s5,a2
    800038be:	84b6                	mv	s1,a3
    800038c0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038c2:	9f35                	addw	a4,a4,a3
    return 0;
    800038c4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038c6:	08d76f63          	bltu	a4,a3,80003964 <readi+0xd0>
  if(off + n > ip->size)
    800038ca:	00e7f463          	bgeu	a5,a4,800038d2 <readi+0x3e>
    n = ip->size - off;
    800038ce:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038d2:	0a0b0863          	beqz	s6,80003982 <readi+0xee>
    800038d6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038d8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038dc:	5cfd                	li	s9,-1
    800038de:	a82d                	j	80003918 <readi+0x84>
    800038e0:	020a1d93          	slli	s11,s4,0x20
    800038e4:	020ddd93          	srli	s11,s11,0x20
    800038e8:	05890793          	addi	a5,s2,88
    800038ec:	86ee                	mv	a3,s11
    800038ee:	963e                	add	a2,a2,a5
    800038f0:	85d6                	mv	a1,s5
    800038f2:	8562                	mv	a0,s8
    800038f4:	fffff097          	auipc	ra,0xfffff
    800038f8:	b2c080e7          	jalr	-1236(ra) # 80002420 <either_copyout>
    800038fc:	05950d63          	beq	a0,s9,80003956 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003900:	854a                	mv	a0,s2
    80003902:	fffff097          	auipc	ra,0xfffff
    80003906:	60a080e7          	jalr	1546(ra) # 80002f0c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000390a:	013a09bb          	addw	s3,s4,s3
    8000390e:	009a04bb          	addw	s1,s4,s1
    80003912:	9aee                	add	s5,s5,s11
    80003914:	0569f663          	bgeu	s3,s6,80003960 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003918:	000ba903          	lw	s2,0(s7)
    8000391c:	00a4d59b          	srliw	a1,s1,0xa
    80003920:	855e                	mv	a0,s7
    80003922:	00000097          	auipc	ra,0x0
    80003926:	8ae080e7          	jalr	-1874(ra) # 800031d0 <bmap>
    8000392a:	0005059b          	sext.w	a1,a0
    8000392e:	854a                	mv	a0,s2
    80003930:	fffff097          	auipc	ra,0xfffff
    80003934:	4ac080e7          	jalr	1196(ra) # 80002ddc <bread>
    80003938:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000393a:	3ff4f613          	andi	a2,s1,1023
    8000393e:	40cd07bb          	subw	a5,s10,a2
    80003942:	413b073b          	subw	a4,s6,s3
    80003946:	8a3e                	mv	s4,a5
    80003948:	2781                	sext.w	a5,a5
    8000394a:	0007069b          	sext.w	a3,a4
    8000394e:	f8f6f9e3          	bgeu	a3,a5,800038e0 <readi+0x4c>
    80003952:	8a3a                	mv	s4,a4
    80003954:	b771                	j	800038e0 <readi+0x4c>
      brelse(bp);
    80003956:	854a                	mv	a0,s2
    80003958:	fffff097          	auipc	ra,0xfffff
    8000395c:	5b4080e7          	jalr	1460(ra) # 80002f0c <brelse>
  }
  return tot;
    80003960:	0009851b          	sext.w	a0,s3
}
    80003964:	70a6                	ld	ra,104(sp)
    80003966:	7406                	ld	s0,96(sp)
    80003968:	64e6                	ld	s1,88(sp)
    8000396a:	6946                	ld	s2,80(sp)
    8000396c:	69a6                	ld	s3,72(sp)
    8000396e:	6a06                	ld	s4,64(sp)
    80003970:	7ae2                	ld	s5,56(sp)
    80003972:	7b42                	ld	s6,48(sp)
    80003974:	7ba2                	ld	s7,40(sp)
    80003976:	7c02                	ld	s8,32(sp)
    80003978:	6ce2                	ld	s9,24(sp)
    8000397a:	6d42                	ld	s10,16(sp)
    8000397c:	6da2                	ld	s11,8(sp)
    8000397e:	6165                	addi	sp,sp,112
    80003980:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003982:	89da                	mv	s3,s6
    80003984:	bff1                	j	80003960 <readi+0xcc>
    return 0;
    80003986:	4501                	li	a0,0
}
    80003988:	8082                	ret

000000008000398a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000398a:	457c                	lw	a5,76(a0)
    8000398c:	10d7e663          	bltu	a5,a3,80003a98 <writei+0x10e>
{
    80003990:	7159                	addi	sp,sp,-112
    80003992:	f486                	sd	ra,104(sp)
    80003994:	f0a2                	sd	s0,96(sp)
    80003996:	eca6                	sd	s1,88(sp)
    80003998:	e8ca                	sd	s2,80(sp)
    8000399a:	e4ce                	sd	s3,72(sp)
    8000399c:	e0d2                	sd	s4,64(sp)
    8000399e:	fc56                	sd	s5,56(sp)
    800039a0:	f85a                	sd	s6,48(sp)
    800039a2:	f45e                	sd	s7,40(sp)
    800039a4:	f062                	sd	s8,32(sp)
    800039a6:	ec66                	sd	s9,24(sp)
    800039a8:	e86a                	sd	s10,16(sp)
    800039aa:	e46e                	sd	s11,8(sp)
    800039ac:	1880                	addi	s0,sp,112
    800039ae:	8baa                	mv	s7,a0
    800039b0:	8c2e                	mv	s8,a1
    800039b2:	8ab2                	mv	s5,a2
    800039b4:	8936                	mv	s2,a3
    800039b6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039b8:	00e687bb          	addw	a5,a3,a4
    800039bc:	0ed7e063          	bltu	a5,a3,80003a9c <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039c0:	00043737          	lui	a4,0x43
    800039c4:	0cf76e63          	bltu	a4,a5,80003aa0 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039c8:	0a0b0763          	beqz	s6,80003a76 <writei+0xec>
    800039cc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039ce:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039d2:	5cfd                	li	s9,-1
    800039d4:	a091                	j	80003a18 <writei+0x8e>
    800039d6:	02099d93          	slli	s11,s3,0x20
    800039da:	020ddd93          	srli	s11,s11,0x20
    800039de:	05848793          	addi	a5,s1,88
    800039e2:	86ee                	mv	a3,s11
    800039e4:	8656                	mv	a2,s5
    800039e6:	85e2                	mv	a1,s8
    800039e8:	953e                	add	a0,a0,a5
    800039ea:	fffff097          	auipc	ra,0xfffff
    800039ee:	a8c080e7          	jalr	-1396(ra) # 80002476 <either_copyin>
    800039f2:	07950263          	beq	a0,s9,80003a56 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800039f6:	8526                	mv	a0,s1
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	77e080e7          	jalr	1918(ra) # 80004176 <log_write>
    brelse(bp);
    80003a00:	8526                	mv	a0,s1
    80003a02:	fffff097          	auipc	ra,0xfffff
    80003a06:	50a080e7          	jalr	1290(ra) # 80002f0c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a0a:	01498a3b          	addw	s4,s3,s4
    80003a0e:	0129893b          	addw	s2,s3,s2
    80003a12:	9aee                	add	s5,s5,s11
    80003a14:	056a7663          	bgeu	s4,s6,80003a60 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a18:	000ba483          	lw	s1,0(s7)
    80003a1c:	00a9559b          	srliw	a1,s2,0xa
    80003a20:	855e                	mv	a0,s7
    80003a22:	fffff097          	auipc	ra,0xfffff
    80003a26:	7ae080e7          	jalr	1966(ra) # 800031d0 <bmap>
    80003a2a:	0005059b          	sext.w	a1,a0
    80003a2e:	8526                	mv	a0,s1
    80003a30:	fffff097          	auipc	ra,0xfffff
    80003a34:	3ac080e7          	jalr	940(ra) # 80002ddc <bread>
    80003a38:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a3a:	3ff97513          	andi	a0,s2,1023
    80003a3e:	40ad07bb          	subw	a5,s10,a0
    80003a42:	414b073b          	subw	a4,s6,s4
    80003a46:	89be                	mv	s3,a5
    80003a48:	2781                	sext.w	a5,a5
    80003a4a:	0007069b          	sext.w	a3,a4
    80003a4e:	f8f6f4e3          	bgeu	a3,a5,800039d6 <writei+0x4c>
    80003a52:	89ba                	mv	s3,a4
    80003a54:	b749                	j	800039d6 <writei+0x4c>
      brelse(bp);
    80003a56:	8526                	mv	a0,s1
    80003a58:	fffff097          	auipc	ra,0xfffff
    80003a5c:	4b4080e7          	jalr	1204(ra) # 80002f0c <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003a60:	04cba783          	lw	a5,76(s7)
    80003a64:	0127f463          	bgeu	a5,s2,80003a6c <writei+0xe2>
      ip->size = off;
    80003a68:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003a6c:	855e                	mv	a0,s7
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	aa8080e7          	jalr	-1368(ra) # 80003516 <iupdate>
  }

  return n;
    80003a76:	000b051b          	sext.w	a0,s6
}
    80003a7a:	70a6                	ld	ra,104(sp)
    80003a7c:	7406                	ld	s0,96(sp)
    80003a7e:	64e6                	ld	s1,88(sp)
    80003a80:	6946                	ld	s2,80(sp)
    80003a82:	69a6                	ld	s3,72(sp)
    80003a84:	6a06                	ld	s4,64(sp)
    80003a86:	7ae2                	ld	s5,56(sp)
    80003a88:	7b42                	ld	s6,48(sp)
    80003a8a:	7ba2                	ld	s7,40(sp)
    80003a8c:	7c02                	ld	s8,32(sp)
    80003a8e:	6ce2                	ld	s9,24(sp)
    80003a90:	6d42                	ld	s10,16(sp)
    80003a92:	6da2                	ld	s11,8(sp)
    80003a94:	6165                	addi	sp,sp,112
    80003a96:	8082                	ret
    return -1;
    80003a98:	557d                	li	a0,-1
}
    80003a9a:	8082                	ret
    return -1;
    80003a9c:	557d                	li	a0,-1
    80003a9e:	bff1                	j	80003a7a <writei+0xf0>
    return -1;
    80003aa0:	557d                	li	a0,-1
    80003aa2:	bfe1                	j	80003a7a <writei+0xf0>

0000000080003aa4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003aa4:	1141                	addi	sp,sp,-16
    80003aa6:	e406                	sd	ra,8(sp)
    80003aa8:	e022                	sd	s0,0(sp)
    80003aaa:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003aac:	4639                	li	a2,14
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	324080e7          	jalr	804(ra) # 80000dd2 <strncmp>
}
    80003ab6:	60a2                	ld	ra,8(sp)
    80003ab8:	6402                	ld	s0,0(sp)
    80003aba:	0141                	addi	sp,sp,16
    80003abc:	8082                	ret

0000000080003abe <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003abe:	7139                	addi	sp,sp,-64
    80003ac0:	fc06                	sd	ra,56(sp)
    80003ac2:	f822                	sd	s0,48(sp)
    80003ac4:	f426                	sd	s1,40(sp)
    80003ac6:	f04a                	sd	s2,32(sp)
    80003ac8:	ec4e                	sd	s3,24(sp)
    80003aca:	e852                	sd	s4,16(sp)
    80003acc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ace:	04451703          	lh	a4,68(a0)
    80003ad2:	4785                	li	a5,1
    80003ad4:	00f71a63          	bne	a4,a5,80003ae8 <dirlookup+0x2a>
    80003ad8:	892a                	mv	s2,a0
    80003ada:	89ae                	mv	s3,a1
    80003adc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ade:	457c                	lw	a5,76(a0)
    80003ae0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ae2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ae4:	e79d                	bnez	a5,80003b12 <dirlookup+0x54>
    80003ae6:	a8a5                	j	80003b5e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ae8:	00005517          	auipc	a0,0x5
    80003aec:	b3050513          	addi	a0,a0,-1232 # 80008618 <syscalls+0x1a0>
    80003af0:	ffffd097          	auipc	ra,0xffffd
    80003af4:	a52080e7          	jalr	-1454(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003af8:	00005517          	auipc	a0,0x5
    80003afc:	b3850513          	addi	a0,a0,-1224 # 80008630 <syscalls+0x1b8>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	a42080e7          	jalr	-1470(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b08:	24c1                	addiw	s1,s1,16
    80003b0a:	04c92783          	lw	a5,76(s2)
    80003b0e:	04f4f763          	bgeu	s1,a5,80003b5c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b12:	4741                	li	a4,16
    80003b14:	86a6                	mv	a3,s1
    80003b16:	fc040613          	addi	a2,s0,-64
    80003b1a:	4581                	li	a1,0
    80003b1c:	854a                	mv	a0,s2
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	d76080e7          	jalr	-650(ra) # 80003894 <readi>
    80003b26:	47c1                	li	a5,16
    80003b28:	fcf518e3          	bne	a0,a5,80003af8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b2c:	fc045783          	lhu	a5,-64(s0)
    80003b30:	dfe1                	beqz	a5,80003b08 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b32:	fc240593          	addi	a1,s0,-62
    80003b36:	854e                	mv	a0,s3
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	f6c080e7          	jalr	-148(ra) # 80003aa4 <namecmp>
    80003b40:	f561                	bnez	a0,80003b08 <dirlookup+0x4a>
      if(poff)
    80003b42:	000a0463          	beqz	s4,80003b4a <dirlookup+0x8c>
        *poff = off;
    80003b46:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b4a:	fc045583          	lhu	a1,-64(s0)
    80003b4e:	00092503          	lw	a0,0(s2)
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	75a080e7          	jalr	1882(ra) # 800032ac <iget>
    80003b5a:	a011                	j	80003b5e <dirlookup+0xa0>
  return 0;
    80003b5c:	4501                	li	a0,0
}
    80003b5e:	70e2                	ld	ra,56(sp)
    80003b60:	7442                	ld	s0,48(sp)
    80003b62:	74a2                	ld	s1,40(sp)
    80003b64:	7902                	ld	s2,32(sp)
    80003b66:	69e2                	ld	s3,24(sp)
    80003b68:	6a42                	ld	s4,16(sp)
    80003b6a:	6121                	addi	sp,sp,64
    80003b6c:	8082                	ret

0000000080003b6e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b6e:	711d                	addi	sp,sp,-96
    80003b70:	ec86                	sd	ra,88(sp)
    80003b72:	e8a2                	sd	s0,80(sp)
    80003b74:	e4a6                	sd	s1,72(sp)
    80003b76:	e0ca                	sd	s2,64(sp)
    80003b78:	fc4e                	sd	s3,56(sp)
    80003b7a:	f852                	sd	s4,48(sp)
    80003b7c:	f456                	sd	s5,40(sp)
    80003b7e:	f05a                	sd	s6,32(sp)
    80003b80:	ec5e                	sd	s7,24(sp)
    80003b82:	e862                	sd	s8,16(sp)
    80003b84:	e466                	sd	s9,8(sp)
    80003b86:	1080                	addi	s0,sp,96
    80003b88:	84aa                	mv	s1,a0
    80003b8a:	8aae                	mv	s5,a1
    80003b8c:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003b8e:	00054703          	lbu	a4,0(a0)
    80003b92:	02f00793          	li	a5,47
    80003b96:	02f70363          	beq	a4,a5,80003bbc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003b9a:	ffffe097          	auipc	ra,0xffffe
    80003b9e:	e20080e7          	jalr	-480(ra) # 800019ba <myproc>
    80003ba2:	15053503          	ld	a0,336(a0)
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	9fc080e7          	jalr	-1540(ra) # 800035a2 <idup>
    80003bae:	89aa                	mv	s3,a0
  while(*path == '/')
    80003bb0:	02f00913          	li	s2,47
  len = path - s;
    80003bb4:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003bb6:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bb8:	4b85                	li	s7,1
    80003bba:	a865                	j	80003c72 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003bbc:	4585                	li	a1,1
    80003bbe:	4505                	li	a0,1
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	6ec080e7          	jalr	1772(ra) # 800032ac <iget>
    80003bc8:	89aa                	mv	s3,a0
    80003bca:	b7dd                	j	80003bb0 <namex+0x42>
      iunlockput(ip);
    80003bcc:	854e                	mv	a0,s3
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	c74080e7          	jalr	-908(ra) # 80003842 <iunlockput>
      return 0;
    80003bd6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003bd8:	854e                	mv	a0,s3
    80003bda:	60e6                	ld	ra,88(sp)
    80003bdc:	6446                	ld	s0,80(sp)
    80003bde:	64a6                	ld	s1,72(sp)
    80003be0:	6906                	ld	s2,64(sp)
    80003be2:	79e2                	ld	s3,56(sp)
    80003be4:	7a42                	ld	s4,48(sp)
    80003be6:	7aa2                	ld	s5,40(sp)
    80003be8:	7b02                	ld	s6,32(sp)
    80003bea:	6be2                	ld	s7,24(sp)
    80003bec:	6c42                	ld	s8,16(sp)
    80003bee:	6ca2                	ld	s9,8(sp)
    80003bf0:	6125                	addi	sp,sp,96
    80003bf2:	8082                	ret
      iunlock(ip);
    80003bf4:	854e                	mv	a0,s3
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	aac080e7          	jalr	-1364(ra) # 800036a2 <iunlock>
      return ip;
    80003bfe:	bfe9                	j	80003bd8 <namex+0x6a>
      iunlockput(ip);
    80003c00:	854e                	mv	a0,s3
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	c40080e7          	jalr	-960(ra) # 80003842 <iunlockput>
      return 0;
    80003c0a:	89e6                	mv	s3,s9
    80003c0c:	b7f1                	j	80003bd8 <namex+0x6a>
  len = path - s;
    80003c0e:	40b48633          	sub	a2,s1,a1
    80003c12:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c16:	099c5463          	bge	s8,s9,80003c9e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c1a:	4639                	li	a2,14
    80003c1c:	8552                	mv	a0,s4
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	138080e7          	jalr	312(ra) # 80000d56 <memmove>
  while(*path == '/')
    80003c26:	0004c783          	lbu	a5,0(s1)
    80003c2a:	01279763          	bne	a5,s2,80003c38 <namex+0xca>
    path++;
    80003c2e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c30:	0004c783          	lbu	a5,0(s1)
    80003c34:	ff278de3          	beq	a5,s2,80003c2e <namex+0xc0>
    ilock(ip);
    80003c38:	854e                	mv	a0,s3
    80003c3a:	00000097          	auipc	ra,0x0
    80003c3e:	9a6080e7          	jalr	-1626(ra) # 800035e0 <ilock>
    if(ip->type != T_DIR){
    80003c42:	04499783          	lh	a5,68(s3)
    80003c46:	f97793e3          	bne	a5,s7,80003bcc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c4a:	000a8563          	beqz	s5,80003c54 <namex+0xe6>
    80003c4e:	0004c783          	lbu	a5,0(s1)
    80003c52:	d3cd                	beqz	a5,80003bf4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c54:	865a                	mv	a2,s6
    80003c56:	85d2                	mv	a1,s4
    80003c58:	854e                	mv	a0,s3
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	e64080e7          	jalr	-412(ra) # 80003abe <dirlookup>
    80003c62:	8caa                	mv	s9,a0
    80003c64:	dd51                	beqz	a0,80003c00 <namex+0x92>
    iunlockput(ip);
    80003c66:	854e                	mv	a0,s3
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	bda080e7          	jalr	-1062(ra) # 80003842 <iunlockput>
    ip = next;
    80003c70:	89e6                	mv	s3,s9
  while(*path == '/')
    80003c72:	0004c783          	lbu	a5,0(s1)
    80003c76:	05279763          	bne	a5,s2,80003cc4 <namex+0x156>
    path++;
    80003c7a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c7c:	0004c783          	lbu	a5,0(s1)
    80003c80:	ff278de3          	beq	a5,s2,80003c7a <namex+0x10c>
  if(*path == 0)
    80003c84:	c79d                	beqz	a5,80003cb2 <namex+0x144>
    path++;
    80003c86:	85a6                	mv	a1,s1
  len = path - s;
    80003c88:	8cda                	mv	s9,s6
    80003c8a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003c8c:	01278963          	beq	a5,s2,80003c9e <namex+0x130>
    80003c90:	dfbd                	beqz	a5,80003c0e <namex+0xa0>
    path++;
    80003c92:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003c94:	0004c783          	lbu	a5,0(s1)
    80003c98:	ff279ce3          	bne	a5,s2,80003c90 <namex+0x122>
    80003c9c:	bf8d                	j	80003c0e <namex+0xa0>
    memmove(name, s, len);
    80003c9e:	2601                	sext.w	a2,a2
    80003ca0:	8552                	mv	a0,s4
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	0b4080e7          	jalr	180(ra) # 80000d56 <memmove>
    name[len] = 0;
    80003caa:	9cd2                	add	s9,s9,s4
    80003cac:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003cb0:	bf9d                	j	80003c26 <namex+0xb8>
  if(nameiparent){
    80003cb2:	f20a83e3          	beqz	s5,80003bd8 <namex+0x6a>
    iput(ip);
    80003cb6:	854e                	mv	a0,s3
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	ae2080e7          	jalr	-1310(ra) # 8000379a <iput>
    return 0;
    80003cc0:	4981                	li	s3,0
    80003cc2:	bf19                	j	80003bd8 <namex+0x6a>
  if(*path == 0)
    80003cc4:	d7fd                	beqz	a5,80003cb2 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003cc6:	0004c783          	lbu	a5,0(s1)
    80003cca:	85a6                	mv	a1,s1
    80003ccc:	b7d1                	j	80003c90 <namex+0x122>

0000000080003cce <dirlink>:
{
    80003cce:	7139                	addi	sp,sp,-64
    80003cd0:	fc06                	sd	ra,56(sp)
    80003cd2:	f822                	sd	s0,48(sp)
    80003cd4:	f426                	sd	s1,40(sp)
    80003cd6:	f04a                	sd	s2,32(sp)
    80003cd8:	ec4e                	sd	s3,24(sp)
    80003cda:	e852                	sd	s4,16(sp)
    80003cdc:	0080                	addi	s0,sp,64
    80003cde:	892a                	mv	s2,a0
    80003ce0:	8a2e                	mv	s4,a1
    80003ce2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ce4:	4601                	li	a2,0
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	dd8080e7          	jalr	-552(ra) # 80003abe <dirlookup>
    80003cee:	e93d                	bnez	a0,80003d64 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf0:	04c92483          	lw	s1,76(s2)
    80003cf4:	c49d                	beqz	s1,80003d22 <dirlink+0x54>
    80003cf6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cf8:	4741                	li	a4,16
    80003cfa:	86a6                	mv	a3,s1
    80003cfc:	fc040613          	addi	a2,s0,-64
    80003d00:	4581                	li	a1,0
    80003d02:	854a                	mv	a0,s2
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	b90080e7          	jalr	-1136(ra) # 80003894 <readi>
    80003d0c:	47c1                	li	a5,16
    80003d0e:	06f51163          	bne	a0,a5,80003d70 <dirlink+0xa2>
    if(de.inum == 0)
    80003d12:	fc045783          	lhu	a5,-64(s0)
    80003d16:	c791                	beqz	a5,80003d22 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d18:	24c1                	addiw	s1,s1,16
    80003d1a:	04c92783          	lw	a5,76(s2)
    80003d1e:	fcf4ede3          	bltu	s1,a5,80003cf8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d22:	4639                	li	a2,14
    80003d24:	85d2                	mv	a1,s4
    80003d26:	fc240513          	addi	a0,s0,-62
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	0e4080e7          	jalr	228(ra) # 80000e0e <strncpy>
  de.inum = inum;
    80003d32:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d36:	4741                	li	a4,16
    80003d38:	86a6                	mv	a3,s1
    80003d3a:	fc040613          	addi	a2,s0,-64
    80003d3e:	4581                	li	a1,0
    80003d40:	854a                	mv	a0,s2
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	c48080e7          	jalr	-952(ra) # 8000398a <writei>
    80003d4a:	872a                	mv	a4,a0
    80003d4c:	47c1                	li	a5,16
  return 0;
    80003d4e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d50:	02f71863          	bne	a4,a5,80003d80 <dirlink+0xb2>
}
    80003d54:	70e2                	ld	ra,56(sp)
    80003d56:	7442                	ld	s0,48(sp)
    80003d58:	74a2                	ld	s1,40(sp)
    80003d5a:	7902                	ld	s2,32(sp)
    80003d5c:	69e2                	ld	s3,24(sp)
    80003d5e:	6a42                	ld	s4,16(sp)
    80003d60:	6121                	addi	sp,sp,64
    80003d62:	8082                	ret
    iput(ip);
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	a36080e7          	jalr	-1482(ra) # 8000379a <iput>
    return -1;
    80003d6c:	557d                	li	a0,-1
    80003d6e:	b7dd                	j	80003d54 <dirlink+0x86>
      panic("dirlink read");
    80003d70:	00005517          	auipc	a0,0x5
    80003d74:	8d050513          	addi	a0,a0,-1840 # 80008640 <syscalls+0x1c8>
    80003d78:	ffffc097          	auipc	ra,0xffffc
    80003d7c:	7ca080e7          	jalr	1994(ra) # 80000542 <panic>
    panic("dirlink");
    80003d80:	00005517          	auipc	a0,0x5
    80003d84:	9e050513          	addi	a0,a0,-1568 # 80008760 <syscalls+0x2e8>
    80003d88:	ffffc097          	auipc	ra,0xffffc
    80003d8c:	7ba080e7          	jalr	1978(ra) # 80000542 <panic>

0000000080003d90 <namei>:

struct inode*
namei(char *path)
{
    80003d90:	1101                	addi	sp,sp,-32
    80003d92:	ec06                	sd	ra,24(sp)
    80003d94:	e822                	sd	s0,16(sp)
    80003d96:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003d98:	fe040613          	addi	a2,s0,-32
    80003d9c:	4581                	li	a1,0
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	dd0080e7          	jalr	-560(ra) # 80003b6e <namex>
}
    80003da6:	60e2                	ld	ra,24(sp)
    80003da8:	6442                	ld	s0,16(sp)
    80003daa:	6105                	addi	sp,sp,32
    80003dac:	8082                	ret

0000000080003dae <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dae:	1141                	addi	sp,sp,-16
    80003db0:	e406                	sd	ra,8(sp)
    80003db2:	e022                	sd	s0,0(sp)
    80003db4:	0800                	addi	s0,sp,16
    80003db6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003db8:	4585                	li	a1,1
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	db4080e7          	jalr	-588(ra) # 80003b6e <namex>
}
    80003dc2:	60a2                	ld	ra,8(sp)
    80003dc4:	6402                	ld	s0,0(sp)
    80003dc6:	0141                	addi	sp,sp,16
    80003dc8:	8082                	ret

0000000080003dca <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003dca:	1101                	addi	sp,sp,-32
    80003dcc:	ec06                	sd	ra,24(sp)
    80003dce:	e822                	sd	s0,16(sp)
    80003dd0:	e426                	sd	s1,8(sp)
    80003dd2:	e04a                	sd	s2,0(sp)
    80003dd4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003dd6:	0001e917          	auipc	s2,0x1e
    80003dda:	b3290913          	addi	s2,s2,-1230 # 80021908 <log>
    80003dde:	01892583          	lw	a1,24(s2)
    80003de2:	02892503          	lw	a0,40(s2)
    80003de6:	fffff097          	auipc	ra,0xfffff
    80003dea:	ff6080e7          	jalr	-10(ra) # 80002ddc <bread>
    80003dee:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003df0:	02c92683          	lw	a3,44(s2)
    80003df4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003df6:	02d05863          	blez	a3,80003e26 <write_head+0x5c>
    80003dfa:	0001e797          	auipc	a5,0x1e
    80003dfe:	b3e78793          	addi	a5,a5,-1218 # 80021938 <log+0x30>
    80003e02:	05c50713          	addi	a4,a0,92
    80003e06:	36fd                	addiw	a3,a3,-1
    80003e08:	02069613          	slli	a2,a3,0x20
    80003e0c:	01e65693          	srli	a3,a2,0x1e
    80003e10:	0001e617          	auipc	a2,0x1e
    80003e14:	b2c60613          	addi	a2,a2,-1236 # 8002193c <log+0x34>
    80003e18:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e1a:	4390                	lw	a2,0(a5)
    80003e1c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e1e:	0791                	addi	a5,a5,4
    80003e20:	0711                	addi	a4,a4,4
    80003e22:	fed79ce3          	bne	a5,a3,80003e1a <write_head+0x50>
  }
  bwrite(buf);
    80003e26:	8526                	mv	a0,s1
    80003e28:	fffff097          	auipc	ra,0xfffff
    80003e2c:	0a6080e7          	jalr	166(ra) # 80002ece <bwrite>
  brelse(buf);
    80003e30:	8526                	mv	a0,s1
    80003e32:	fffff097          	auipc	ra,0xfffff
    80003e36:	0da080e7          	jalr	218(ra) # 80002f0c <brelse>
}
    80003e3a:	60e2                	ld	ra,24(sp)
    80003e3c:	6442                	ld	s0,16(sp)
    80003e3e:	64a2                	ld	s1,8(sp)
    80003e40:	6902                	ld	s2,0(sp)
    80003e42:	6105                	addi	sp,sp,32
    80003e44:	8082                	ret

0000000080003e46 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e46:	0001e797          	auipc	a5,0x1e
    80003e4a:	aee7a783          	lw	a5,-1298(a5) # 80021934 <log+0x2c>
    80003e4e:	0af05663          	blez	a5,80003efa <install_trans+0xb4>
{
    80003e52:	7139                	addi	sp,sp,-64
    80003e54:	fc06                	sd	ra,56(sp)
    80003e56:	f822                	sd	s0,48(sp)
    80003e58:	f426                	sd	s1,40(sp)
    80003e5a:	f04a                	sd	s2,32(sp)
    80003e5c:	ec4e                	sd	s3,24(sp)
    80003e5e:	e852                	sd	s4,16(sp)
    80003e60:	e456                	sd	s5,8(sp)
    80003e62:	0080                	addi	s0,sp,64
    80003e64:	0001ea97          	auipc	s5,0x1e
    80003e68:	ad4a8a93          	addi	s5,s5,-1324 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e6c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e6e:	0001e997          	auipc	s3,0x1e
    80003e72:	a9a98993          	addi	s3,s3,-1382 # 80021908 <log>
    80003e76:	0189a583          	lw	a1,24(s3)
    80003e7a:	014585bb          	addw	a1,a1,s4
    80003e7e:	2585                	addiw	a1,a1,1
    80003e80:	0289a503          	lw	a0,40(s3)
    80003e84:	fffff097          	auipc	ra,0xfffff
    80003e88:	f58080e7          	jalr	-168(ra) # 80002ddc <bread>
    80003e8c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003e8e:	000aa583          	lw	a1,0(s5)
    80003e92:	0289a503          	lw	a0,40(s3)
    80003e96:	fffff097          	auipc	ra,0xfffff
    80003e9a:	f46080e7          	jalr	-186(ra) # 80002ddc <bread>
    80003e9e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ea0:	40000613          	li	a2,1024
    80003ea4:	05890593          	addi	a1,s2,88
    80003ea8:	05850513          	addi	a0,a0,88
    80003eac:	ffffd097          	auipc	ra,0xffffd
    80003eb0:	eaa080e7          	jalr	-342(ra) # 80000d56 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003eb4:	8526                	mv	a0,s1
    80003eb6:	fffff097          	auipc	ra,0xfffff
    80003eba:	018080e7          	jalr	24(ra) # 80002ece <bwrite>
    bunpin(dbuf);
    80003ebe:	8526                	mv	a0,s1
    80003ec0:	fffff097          	auipc	ra,0xfffff
    80003ec4:	126080e7          	jalr	294(ra) # 80002fe6 <bunpin>
    brelse(lbuf);
    80003ec8:	854a                	mv	a0,s2
    80003eca:	fffff097          	auipc	ra,0xfffff
    80003ece:	042080e7          	jalr	66(ra) # 80002f0c <brelse>
    brelse(dbuf);
    80003ed2:	8526                	mv	a0,s1
    80003ed4:	fffff097          	auipc	ra,0xfffff
    80003ed8:	038080e7          	jalr	56(ra) # 80002f0c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003edc:	2a05                	addiw	s4,s4,1
    80003ede:	0a91                	addi	s5,s5,4
    80003ee0:	02c9a783          	lw	a5,44(s3)
    80003ee4:	f8fa49e3          	blt	s4,a5,80003e76 <install_trans+0x30>
}
    80003ee8:	70e2                	ld	ra,56(sp)
    80003eea:	7442                	ld	s0,48(sp)
    80003eec:	74a2                	ld	s1,40(sp)
    80003eee:	7902                	ld	s2,32(sp)
    80003ef0:	69e2                	ld	s3,24(sp)
    80003ef2:	6a42                	ld	s4,16(sp)
    80003ef4:	6aa2                	ld	s5,8(sp)
    80003ef6:	6121                	addi	sp,sp,64
    80003ef8:	8082                	ret
    80003efa:	8082                	ret

0000000080003efc <initlog>:
{
    80003efc:	7179                	addi	sp,sp,-48
    80003efe:	f406                	sd	ra,40(sp)
    80003f00:	f022                	sd	s0,32(sp)
    80003f02:	ec26                	sd	s1,24(sp)
    80003f04:	e84a                	sd	s2,16(sp)
    80003f06:	e44e                	sd	s3,8(sp)
    80003f08:	1800                	addi	s0,sp,48
    80003f0a:	892a                	mv	s2,a0
    80003f0c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f0e:	0001e497          	auipc	s1,0x1e
    80003f12:	9fa48493          	addi	s1,s1,-1542 # 80021908 <log>
    80003f16:	00004597          	auipc	a1,0x4
    80003f1a:	73a58593          	addi	a1,a1,1850 # 80008650 <syscalls+0x1d8>
    80003f1e:	8526                	mv	a0,s1
    80003f20:	ffffd097          	auipc	ra,0xffffd
    80003f24:	c4e080e7          	jalr	-946(ra) # 80000b6e <initlock>
  log.start = sb->logstart;
    80003f28:	0149a583          	lw	a1,20(s3)
    80003f2c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f2e:	0109a783          	lw	a5,16(s3)
    80003f32:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f34:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f38:	854a                	mv	a0,s2
    80003f3a:	fffff097          	auipc	ra,0xfffff
    80003f3e:	ea2080e7          	jalr	-350(ra) # 80002ddc <bread>
  log.lh.n = lh->n;
    80003f42:	4d34                	lw	a3,88(a0)
    80003f44:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f46:	02d05663          	blez	a3,80003f72 <initlog+0x76>
    80003f4a:	05c50793          	addi	a5,a0,92
    80003f4e:	0001e717          	auipc	a4,0x1e
    80003f52:	9ea70713          	addi	a4,a4,-1558 # 80021938 <log+0x30>
    80003f56:	36fd                	addiw	a3,a3,-1
    80003f58:	02069613          	slli	a2,a3,0x20
    80003f5c:	01e65693          	srli	a3,a2,0x1e
    80003f60:	06050613          	addi	a2,a0,96
    80003f64:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003f66:	4390                	lw	a2,0(a5)
    80003f68:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f6a:	0791                	addi	a5,a5,4
    80003f6c:	0711                	addi	a4,a4,4
    80003f6e:	fed79ce3          	bne	a5,a3,80003f66 <initlog+0x6a>
  brelse(buf);
    80003f72:	fffff097          	auipc	ra,0xfffff
    80003f76:	f9a080e7          	jalr	-102(ra) # 80002f0c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	ecc080e7          	jalr	-308(ra) # 80003e46 <install_trans>
  log.lh.n = 0;
    80003f82:	0001e797          	auipc	a5,0x1e
    80003f86:	9a07a923          	sw	zero,-1614(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	e40080e7          	jalr	-448(ra) # 80003dca <write_head>
}
    80003f92:	70a2                	ld	ra,40(sp)
    80003f94:	7402                	ld	s0,32(sp)
    80003f96:	64e2                	ld	s1,24(sp)
    80003f98:	6942                	ld	s2,16(sp)
    80003f9a:	69a2                	ld	s3,8(sp)
    80003f9c:	6145                	addi	sp,sp,48
    80003f9e:	8082                	ret

0000000080003fa0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fa0:	1101                	addi	sp,sp,-32
    80003fa2:	ec06                	sd	ra,24(sp)
    80003fa4:	e822                	sd	s0,16(sp)
    80003fa6:	e426                	sd	s1,8(sp)
    80003fa8:	e04a                	sd	s2,0(sp)
    80003faa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fac:	0001e517          	auipc	a0,0x1e
    80003fb0:	95c50513          	addi	a0,a0,-1700 # 80021908 <log>
    80003fb4:	ffffd097          	auipc	ra,0xffffd
    80003fb8:	c4a080e7          	jalr	-950(ra) # 80000bfe <acquire>
  while(1){
    if(log.committing){
    80003fbc:	0001e497          	auipc	s1,0x1e
    80003fc0:	94c48493          	addi	s1,s1,-1716 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fc4:	4979                	li	s2,30
    80003fc6:	a039                	j	80003fd4 <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fc8:	85a6                	mv	a1,s1
    80003fca:	8526                	mv	a0,s1
    80003fcc:	ffffe097          	auipc	ra,0xffffe
    80003fd0:	1fa080e7          	jalr	506(ra) # 800021c6 <sleep>
    if(log.committing){
    80003fd4:	50dc                	lw	a5,36(s1)
    80003fd6:	fbed                	bnez	a5,80003fc8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fd8:	509c                	lw	a5,32(s1)
    80003fda:	0017871b          	addiw	a4,a5,1
    80003fde:	0007069b          	sext.w	a3,a4
    80003fe2:	0027179b          	slliw	a5,a4,0x2
    80003fe6:	9fb9                	addw	a5,a5,a4
    80003fe8:	0017979b          	slliw	a5,a5,0x1
    80003fec:	54d8                	lw	a4,44(s1)
    80003fee:	9fb9                	addw	a5,a5,a4
    80003ff0:	00f95963          	bge	s2,a5,80004002 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003ff4:	85a6                	mv	a1,s1
    80003ff6:	8526                	mv	a0,s1
    80003ff8:	ffffe097          	auipc	ra,0xffffe
    80003ffc:	1ce080e7          	jalr	462(ra) # 800021c6 <sleep>
    80004000:	bfd1                	j	80003fd4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004002:	0001e517          	auipc	a0,0x1e
    80004006:	90650513          	addi	a0,a0,-1786 # 80021908 <log>
    8000400a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000400c:	ffffd097          	auipc	ra,0xffffd
    80004010:	ca6080e7          	jalr	-858(ra) # 80000cb2 <release>
      break;
    }
  }
}
    80004014:	60e2                	ld	ra,24(sp)
    80004016:	6442                	ld	s0,16(sp)
    80004018:	64a2                	ld	s1,8(sp)
    8000401a:	6902                	ld	s2,0(sp)
    8000401c:	6105                	addi	sp,sp,32
    8000401e:	8082                	ret

0000000080004020 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004020:	7139                	addi	sp,sp,-64
    80004022:	fc06                	sd	ra,56(sp)
    80004024:	f822                	sd	s0,48(sp)
    80004026:	f426                	sd	s1,40(sp)
    80004028:	f04a                	sd	s2,32(sp)
    8000402a:	ec4e                	sd	s3,24(sp)
    8000402c:	e852                	sd	s4,16(sp)
    8000402e:	e456                	sd	s5,8(sp)
    80004030:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004032:	0001e497          	auipc	s1,0x1e
    80004036:	8d648493          	addi	s1,s1,-1834 # 80021908 <log>
    8000403a:	8526                	mv	a0,s1
    8000403c:	ffffd097          	auipc	ra,0xffffd
    80004040:	bc2080e7          	jalr	-1086(ra) # 80000bfe <acquire>
  log.outstanding -= 1;
    80004044:	509c                	lw	a5,32(s1)
    80004046:	37fd                	addiw	a5,a5,-1
    80004048:	0007891b          	sext.w	s2,a5
    8000404c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000404e:	50dc                	lw	a5,36(s1)
    80004050:	e7b9                	bnez	a5,8000409e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004052:	04091e63          	bnez	s2,800040ae <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004056:	0001e497          	auipc	s1,0x1e
    8000405a:	8b248493          	addi	s1,s1,-1870 # 80021908 <log>
    8000405e:	4785                	li	a5,1
    80004060:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004062:	8526                	mv	a0,s1
    80004064:	ffffd097          	auipc	ra,0xffffd
    80004068:	c4e080e7          	jalr	-946(ra) # 80000cb2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000406c:	54dc                	lw	a5,44(s1)
    8000406e:	06f04763          	bgtz	a5,800040dc <end_op+0xbc>
    acquire(&log.lock);
    80004072:	0001e497          	auipc	s1,0x1e
    80004076:	89648493          	addi	s1,s1,-1898 # 80021908 <log>
    8000407a:	8526                	mv	a0,s1
    8000407c:	ffffd097          	auipc	ra,0xffffd
    80004080:	b82080e7          	jalr	-1150(ra) # 80000bfe <acquire>
    log.committing = 0;
    80004084:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004088:	8526                	mv	a0,s1
    8000408a:	ffffe097          	auipc	ra,0xffffe
    8000408e:	2bc080e7          	jalr	700(ra) # 80002346 <wakeup>
    release(&log.lock);
    80004092:	8526                	mv	a0,s1
    80004094:	ffffd097          	auipc	ra,0xffffd
    80004098:	c1e080e7          	jalr	-994(ra) # 80000cb2 <release>
}
    8000409c:	a03d                	j	800040ca <end_op+0xaa>
    panic("log.committing");
    8000409e:	00004517          	auipc	a0,0x4
    800040a2:	5ba50513          	addi	a0,a0,1466 # 80008658 <syscalls+0x1e0>
    800040a6:	ffffc097          	auipc	ra,0xffffc
    800040aa:	49c080e7          	jalr	1180(ra) # 80000542 <panic>
    wakeup(&log);
    800040ae:	0001e497          	auipc	s1,0x1e
    800040b2:	85a48493          	addi	s1,s1,-1958 # 80021908 <log>
    800040b6:	8526                	mv	a0,s1
    800040b8:	ffffe097          	auipc	ra,0xffffe
    800040bc:	28e080e7          	jalr	654(ra) # 80002346 <wakeup>
  release(&log.lock);
    800040c0:	8526                	mv	a0,s1
    800040c2:	ffffd097          	auipc	ra,0xffffd
    800040c6:	bf0080e7          	jalr	-1040(ra) # 80000cb2 <release>
}
    800040ca:	70e2                	ld	ra,56(sp)
    800040cc:	7442                	ld	s0,48(sp)
    800040ce:	74a2                	ld	s1,40(sp)
    800040d0:	7902                	ld	s2,32(sp)
    800040d2:	69e2                	ld	s3,24(sp)
    800040d4:	6a42                	ld	s4,16(sp)
    800040d6:	6aa2                	ld	s5,8(sp)
    800040d8:	6121                	addi	sp,sp,64
    800040da:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800040dc:	0001ea97          	auipc	s5,0x1e
    800040e0:	85ca8a93          	addi	s5,s5,-1956 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800040e4:	0001ea17          	auipc	s4,0x1e
    800040e8:	824a0a13          	addi	s4,s4,-2012 # 80021908 <log>
    800040ec:	018a2583          	lw	a1,24(s4)
    800040f0:	012585bb          	addw	a1,a1,s2
    800040f4:	2585                	addiw	a1,a1,1
    800040f6:	028a2503          	lw	a0,40(s4)
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	ce2080e7          	jalr	-798(ra) # 80002ddc <bread>
    80004102:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004104:	000aa583          	lw	a1,0(s5)
    80004108:	028a2503          	lw	a0,40(s4)
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	cd0080e7          	jalr	-816(ra) # 80002ddc <bread>
    80004114:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004116:	40000613          	li	a2,1024
    8000411a:	05850593          	addi	a1,a0,88
    8000411e:	05848513          	addi	a0,s1,88
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	c34080e7          	jalr	-972(ra) # 80000d56 <memmove>
    bwrite(to);  // write the log
    8000412a:	8526                	mv	a0,s1
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	da2080e7          	jalr	-606(ra) # 80002ece <bwrite>
    brelse(from);
    80004134:	854e                	mv	a0,s3
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	dd6080e7          	jalr	-554(ra) # 80002f0c <brelse>
    brelse(to);
    8000413e:	8526                	mv	a0,s1
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	dcc080e7          	jalr	-564(ra) # 80002f0c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004148:	2905                	addiw	s2,s2,1
    8000414a:	0a91                	addi	s5,s5,4
    8000414c:	02ca2783          	lw	a5,44(s4)
    80004150:	f8f94ee3          	blt	s2,a5,800040ec <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004154:	00000097          	auipc	ra,0x0
    80004158:	c76080e7          	jalr	-906(ra) # 80003dca <write_head>
    install_trans(); // Now install writes to home locations
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	cea080e7          	jalr	-790(ra) # 80003e46 <install_trans>
    log.lh.n = 0;
    80004164:	0001d797          	auipc	a5,0x1d
    80004168:	7c07a823          	sw	zero,2000(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	c5e080e7          	jalr	-930(ra) # 80003dca <write_head>
    80004174:	bdfd                	j	80004072 <end_op+0x52>

0000000080004176 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004176:	1101                	addi	sp,sp,-32
    80004178:	ec06                	sd	ra,24(sp)
    8000417a:	e822                	sd	s0,16(sp)
    8000417c:	e426                	sd	s1,8(sp)
    8000417e:	e04a                	sd	s2,0(sp)
    80004180:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004182:	0001d717          	auipc	a4,0x1d
    80004186:	7b272703          	lw	a4,1970(a4) # 80021934 <log+0x2c>
    8000418a:	47f5                	li	a5,29
    8000418c:	08e7c063          	blt	a5,a4,8000420c <log_write+0x96>
    80004190:	84aa                	mv	s1,a0
    80004192:	0001d797          	auipc	a5,0x1d
    80004196:	7927a783          	lw	a5,1938(a5) # 80021924 <log+0x1c>
    8000419a:	37fd                	addiw	a5,a5,-1
    8000419c:	06f75863          	bge	a4,a5,8000420c <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041a0:	0001d797          	auipc	a5,0x1d
    800041a4:	7887a783          	lw	a5,1928(a5) # 80021928 <log+0x20>
    800041a8:	06f05a63          	blez	a5,8000421c <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800041ac:	0001d917          	auipc	s2,0x1d
    800041b0:	75c90913          	addi	s2,s2,1884 # 80021908 <log>
    800041b4:	854a                	mv	a0,s2
    800041b6:	ffffd097          	auipc	ra,0xffffd
    800041ba:	a48080e7          	jalr	-1464(ra) # 80000bfe <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800041be:	02c92603          	lw	a2,44(s2)
    800041c2:	06c05563          	blez	a2,8000422c <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041c6:	44cc                	lw	a1,12(s1)
    800041c8:	0001d717          	auipc	a4,0x1d
    800041cc:	77070713          	addi	a4,a4,1904 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041d0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041d2:	4314                	lw	a3,0(a4)
    800041d4:	04b68d63          	beq	a3,a1,8000422e <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800041d8:	2785                	addiw	a5,a5,1
    800041da:	0711                	addi	a4,a4,4
    800041dc:	fec79be3          	bne	a5,a2,800041d2 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041e0:	0621                	addi	a2,a2,8
    800041e2:	060a                	slli	a2,a2,0x2
    800041e4:	0001d797          	auipc	a5,0x1d
    800041e8:	72478793          	addi	a5,a5,1828 # 80021908 <log>
    800041ec:	963e                	add	a2,a2,a5
    800041ee:	44dc                	lw	a5,12(s1)
    800041f0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800041f2:	8526                	mv	a0,s1
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	db6080e7          	jalr	-586(ra) # 80002faa <bpin>
    log.lh.n++;
    800041fc:	0001d717          	auipc	a4,0x1d
    80004200:	70c70713          	addi	a4,a4,1804 # 80021908 <log>
    80004204:	575c                	lw	a5,44(a4)
    80004206:	2785                	addiw	a5,a5,1
    80004208:	d75c                	sw	a5,44(a4)
    8000420a:	a83d                	j	80004248 <log_write+0xd2>
    panic("too big a transaction");
    8000420c:	00004517          	auipc	a0,0x4
    80004210:	45c50513          	addi	a0,a0,1116 # 80008668 <syscalls+0x1f0>
    80004214:	ffffc097          	auipc	ra,0xffffc
    80004218:	32e080e7          	jalr	814(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    8000421c:	00004517          	auipc	a0,0x4
    80004220:	46450513          	addi	a0,a0,1124 # 80008680 <syscalls+0x208>
    80004224:	ffffc097          	auipc	ra,0xffffc
    80004228:	31e080e7          	jalr	798(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000422c:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000422e:	00878713          	addi	a4,a5,8
    80004232:	00271693          	slli	a3,a4,0x2
    80004236:	0001d717          	auipc	a4,0x1d
    8000423a:	6d270713          	addi	a4,a4,1746 # 80021908 <log>
    8000423e:	9736                	add	a4,a4,a3
    80004240:	44d4                	lw	a3,12(s1)
    80004242:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004244:	faf607e3          	beq	a2,a5,800041f2 <log_write+0x7c>
  }
  release(&log.lock);
    80004248:	0001d517          	auipc	a0,0x1d
    8000424c:	6c050513          	addi	a0,a0,1728 # 80021908 <log>
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	a62080e7          	jalr	-1438(ra) # 80000cb2 <release>
}
    80004258:	60e2                	ld	ra,24(sp)
    8000425a:	6442                	ld	s0,16(sp)
    8000425c:	64a2                	ld	s1,8(sp)
    8000425e:	6902                	ld	s2,0(sp)
    80004260:	6105                	addi	sp,sp,32
    80004262:	8082                	ret

0000000080004264 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004264:	1101                	addi	sp,sp,-32
    80004266:	ec06                	sd	ra,24(sp)
    80004268:	e822                	sd	s0,16(sp)
    8000426a:	e426                	sd	s1,8(sp)
    8000426c:	e04a                	sd	s2,0(sp)
    8000426e:	1000                	addi	s0,sp,32
    80004270:	84aa                	mv	s1,a0
    80004272:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004274:	00004597          	auipc	a1,0x4
    80004278:	42c58593          	addi	a1,a1,1068 # 800086a0 <syscalls+0x228>
    8000427c:	0521                	addi	a0,a0,8
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	8f0080e7          	jalr	-1808(ra) # 80000b6e <initlock>
  lk->name = name;
    80004286:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000428a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000428e:	0204a423          	sw	zero,40(s1)
}
    80004292:	60e2                	ld	ra,24(sp)
    80004294:	6442                	ld	s0,16(sp)
    80004296:	64a2                	ld	s1,8(sp)
    80004298:	6902                	ld	s2,0(sp)
    8000429a:	6105                	addi	sp,sp,32
    8000429c:	8082                	ret

000000008000429e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000429e:	1101                	addi	sp,sp,-32
    800042a0:	ec06                	sd	ra,24(sp)
    800042a2:	e822                	sd	s0,16(sp)
    800042a4:	e426                	sd	s1,8(sp)
    800042a6:	e04a                	sd	s2,0(sp)
    800042a8:	1000                	addi	s0,sp,32
    800042aa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042ac:	00850913          	addi	s2,a0,8
    800042b0:	854a                	mv	a0,s2
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	94c080e7          	jalr	-1716(ra) # 80000bfe <acquire>
  while (lk->locked) {
    800042ba:	409c                	lw	a5,0(s1)
    800042bc:	cb89                	beqz	a5,800042ce <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042be:	85ca                	mv	a1,s2
    800042c0:	8526                	mv	a0,s1
    800042c2:	ffffe097          	auipc	ra,0xffffe
    800042c6:	f04080e7          	jalr	-252(ra) # 800021c6 <sleep>
  while (lk->locked) {
    800042ca:	409c                	lw	a5,0(s1)
    800042cc:	fbed                	bnez	a5,800042be <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042ce:	4785                	li	a5,1
    800042d0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	6e8080e7          	jalr	1768(ra) # 800019ba <myproc>
    800042da:	5d1c                	lw	a5,56(a0)
    800042dc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042de:	854a                	mv	a0,s2
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	9d2080e7          	jalr	-1582(ra) # 80000cb2 <release>
}
    800042e8:	60e2                	ld	ra,24(sp)
    800042ea:	6442                	ld	s0,16(sp)
    800042ec:	64a2                	ld	s1,8(sp)
    800042ee:	6902                	ld	s2,0(sp)
    800042f0:	6105                	addi	sp,sp,32
    800042f2:	8082                	ret

00000000800042f4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800042f4:	1101                	addi	sp,sp,-32
    800042f6:	ec06                	sd	ra,24(sp)
    800042f8:	e822                	sd	s0,16(sp)
    800042fa:	e426                	sd	s1,8(sp)
    800042fc:	e04a                	sd	s2,0(sp)
    800042fe:	1000                	addi	s0,sp,32
    80004300:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004302:	00850913          	addi	s2,a0,8
    80004306:	854a                	mv	a0,s2
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	8f6080e7          	jalr	-1802(ra) # 80000bfe <acquire>
  lk->locked = 0;
    80004310:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004314:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004318:	8526                	mv	a0,s1
    8000431a:	ffffe097          	auipc	ra,0xffffe
    8000431e:	02c080e7          	jalr	44(ra) # 80002346 <wakeup>
  release(&lk->lk);
    80004322:	854a                	mv	a0,s2
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	98e080e7          	jalr	-1650(ra) # 80000cb2 <release>
}
    8000432c:	60e2                	ld	ra,24(sp)
    8000432e:	6442                	ld	s0,16(sp)
    80004330:	64a2                	ld	s1,8(sp)
    80004332:	6902                	ld	s2,0(sp)
    80004334:	6105                	addi	sp,sp,32
    80004336:	8082                	ret

0000000080004338 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004338:	7179                	addi	sp,sp,-48
    8000433a:	f406                	sd	ra,40(sp)
    8000433c:	f022                	sd	s0,32(sp)
    8000433e:	ec26                	sd	s1,24(sp)
    80004340:	e84a                	sd	s2,16(sp)
    80004342:	e44e                	sd	s3,8(sp)
    80004344:	1800                	addi	s0,sp,48
    80004346:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004348:	00850913          	addi	s2,a0,8
    8000434c:	854a                	mv	a0,s2
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	8b0080e7          	jalr	-1872(ra) # 80000bfe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004356:	409c                	lw	a5,0(s1)
    80004358:	ef99                	bnez	a5,80004376 <holdingsleep+0x3e>
    8000435a:	4481                	li	s1,0
  release(&lk->lk);
    8000435c:	854a                	mv	a0,s2
    8000435e:	ffffd097          	auipc	ra,0xffffd
    80004362:	954080e7          	jalr	-1708(ra) # 80000cb2 <release>
  return r;
}
    80004366:	8526                	mv	a0,s1
    80004368:	70a2                	ld	ra,40(sp)
    8000436a:	7402                	ld	s0,32(sp)
    8000436c:	64e2                	ld	s1,24(sp)
    8000436e:	6942                	ld	s2,16(sp)
    80004370:	69a2                	ld	s3,8(sp)
    80004372:	6145                	addi	sp,sp,48
    80004374:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004376:	0284a983          	lw	s3,40(s1)
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	640080e7          	jalr	1600(ra) # 800019ba <myproc>
    80004382:	5d04                	lw	s1,56(a0)
    80004384:	413484b3          	sub	s1,s1,s3
    80004388:	0014b493          	seqz	s1,s1
    8000438c:	bfc1                	j	8000435c <holdingsleep+0x24>

000000008000438e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000438e:	1141                	addi	sp,sp,-16
    80004390:	e406                	sd	ra,8(sp)
    80004392:	e022                	sd	s0,0(sp)
    80004394:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004396:	00004597          	auipc	a1,0x4
    8000439a:	31a58593          	addi	a1,a1,794 # 800086b0 <syscalls+0x238>
    8000439e:	0001d517          	auipc	a0,0x1d
    800043a2:	6b250513          	addi	a0,a0,1714 # 80021a50 <ftable>
    800043a6:	ffffc097          	auipc	ra,0xffffc
    800043aa:	7c8080e7          	jalr	1992(ra) # 80000b6e <initlock>
}
    800043ae:	60a2                	ld	ra,8(sp)
    800043b0:	6402                	ld	s0,0(sp)
    800043b2:	0141                	addi	sp,sp,16
    800043b4:	8082                	ret

00000000800043b6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043b6:	1101                	addi	sp,sp,-32
    800043b8:	ec06                	sd	ra,24(sp)
    800043ba:	e822                	sd	s0,16(sp)
    800043bc:	e426                	sd	s1,8(sp)
    800043be:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043c0:	0001d517          	auipc	a0,0x1d
    800043c4:	69050513          	addi	a0,a0,1680 # 80021a50 <ftable>
    800043c8:	ffffd097          	auipc	ra,0xffffd
    800043cc:	836080e7          	jalr	-1994(ra) # 80000bfe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043d0:	0001d497          	auipc	s1,0x1d
    800043d4:	69848493          	addi	s1,s1,1688 # 80021a68 <ftable+0x18>
    800043d8:	0001e717          	auipc	a4,0x1e
    800043dc:	63070713          	addi	a4,a4,1584 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    800043e0:	40dc                	lw	a5,4(s1)
    800043e2:	cf99                	beqz	a5,80004400 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043e4:	02848493          	addi	s1,s1,40
    800043e8:	fee49ce3          	bne	s1,a4,800043e0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800043ec:	0001d517          	auipc	a0,0x1d
    800043f0:	66450513          	addi	a0,a0,1636 # 80021a50 <ftable>
    800043f4:	ffffd097          	auipc	ra,0xffffd
    800043f8:	8be080e7          	jalr	-1858(ra) # 80000cb2 <release>
  return 0;
    800043fc:	4481                	li	s1,0
    800043fe:	a819                	j	80004414 <filealloc+0x5e>
      f->ref = 1;
    80004400:	4785                	li	a5,1
    80004402:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004404:	0001d517          	auipc	a0,0x1d
    80004408:	64c50513          	addi	a0,a0,1612 # 80021a50 <ftable>
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	8a6080e7          	jalr	-1882(ra) # 80000cb2 <release>
}
    80004414:	8526                	mv	a0,s1
    80004416:	60e2                	ld	ra,24(sp)
    80004418:	6442                	ld	s0,16(sp)
    8000441a:	64a2                	ld	s1,8(sp)
    8000441c:	6105                	addi	sp,sp,32
    8000441e:	8082                	ret

0000000080004420 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004420:	1101                	addi	sp,sp,-32
    80004422:	ec06                	sd	ra,24(sp)
    80004424:	e822                	sd	s0,16(sp)
    80004426:	e426                	sd	s1,8(sp)
    80004428:	1000                	addi	s0,sp,32
    8000442a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000442c:	0001d517          	auipc	a0,0x1d
    80004430:	62450513          	addi	a0,a0,1572 # 80021a50 <ftable>
    80004434:	ffffc097          	auipc	ra,0xffffc
    80004438:	7ca080e7          	jalr	1994(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    8000443c:	40dc                	lw	a5,4(s1)
    8000443e:	02f05263          	blez	a5,80004462 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004442:	2785                	addiw	a5,a5,1
    80004444:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004446:	0001d517          	auipc	a0,0x1d
    8000444a:	60a50513          	addi	a0,a0,1546 # 80021a50 <ftable>
    8000444e:	ffffd097          	auipc	ra,0xffffd
    80004452:	864080e7          	jalr	-1948(ra) # 80000cb2 <release>
  return f;
}
    80004456:	8526                	mv	a0,s1
    80004458:	60e2                	ld	ra,24(sp)
    8000445a:	6442                	ld	s0,16(sp)
    8000445c:	64a2                	ld	s1,8(sp)
    8000445e:	6105                	addi	sp,sp,32
    80004460:	8082                	ret
    panic("filedup");
    80004462:	00004517          	auipc	a0,0x4
    80004466:	25650513          	addi	a0,a0,598 # 800086b8 <syscalls+0x240>
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	0d8080e7          	jalr	216(ra) # 80000542 <panic>

0000000080004472 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004472:	7139                	addi	sp,sp,-64
    80004474:	fc06                	sd	ra,56(sp)
    80004476:	f822                	sd	s0,48(sp)
    80004478:	f426                	sd	s1,40(sp)
    8000447a:	f04a                	sd	s2,32(sp)
    8000447c:	ec4e                	sd	s3,24(sp)
    8000447e:	e852                	sd	s4,16(sp)
    80004480:	e456                	sd	s5,8(sp)
    80004482:	0080                	addi	s0,sp,64
    80004484:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004486:	0001d517          	auipc	a0,0x1d
    8000448a:	5ca50513          	addi	a0,a0,1482 # 80021a50 <ftable>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	770080e7          	jalr	1904(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    80004496:	40dc                	lw	a5,4(s1)
    80004498:	06f05163          	blez	a5,800044fa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000449c:	37fd                	addiw	a5,a5,-1
    8000449e:	0007871b          	sext.w	a4,a5
    800044a2:	c0dc                	sw	a5,4(s1)
    800044a4:	06e04363          	bgtz	a4,8000450a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044a8:	0004a903          	lw	s2,0(s1)
    800044ac:	0094ca83          	lbu	s5,9(s1)
    800044b0:	0104ba03          	ld	s4,16(s1)
    800044b4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044b8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044bc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044c0:	0001d517          	auipc	a0,0x1d
    800044c4:	59050513          	addi	a0,a0,1424 # 80021a50 <ftable>
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	7ea080e7          	jalr	2026(ra) # 80000cb2 <release>

  if(ff.type == FD_PIPE){
    800044d0:	4785                	li	a5,1
    800044d2:	04f90d63          	beq	s2,a5,8000452c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044d6:	3979                	addiw	s2,s2,-2
    800044d8:	4785                	li	a5,1
    800044da:	0527e063          	bltu	a5,s2,8000451a <fileclose+0xa8>
    begin_op();
    800044de:	00000097          	auipc	ra,0x0
    800044e2:	ac2080e7          	jalr	-1342(ra) # 80003fa0 <begin_op>
    iput(ff.ip);
    800044e6:	854e                	mv	a0,s3
    800044e8:	fffff097          	auipc	ra,0xfffff
    800044ec:	2b2080e7          	jalr	690(ra) # 8000379a <iput>
    end_op();
    800044f0:	00000097          	auipc	ra,0x0
    800044f4:	b30080e7          	jalr	-1232(ra) # 80004020 <end_op>
    800044f8:	a00d                	j	8000451a <fileclose+0xa8>
    panic("fileclose");
    800044fa:	00004517          	auipc	a0,0x4
    800044fe:	1c650513          	addi	a0,a0,454 # 800086c0 <syscalls+0x248>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	040080e7          	jalr	64(ra) # 80000542 <panic>
    release(&ftable.lock);
    8000450a:	0001d517          	auipc	a0,0x1d
    8000450e:	54650513          	addi	a0,a0,1350 # 80021a50 <ftable>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	7a0080e7          	jalr	1952(ra) # 80000cb2 <release>
  }
}
    8000451a:	70e2                	ld	ra,56(sp)
    8000451c:	7442                	ld	s0,48(sp)
    8000451e:	74a2                	ld	s1,40(sp)
    80004520:	7902                	ld	s2,32(sp)
    80004522:	69e2                	ld	s3,24(sp)
    80004524:	6a42                	ld	s4,16(sp)
    80004526:	6aa2                	ld	s5,8(sp)
    80004528:	6121                	addi	sp,sp,64
    8000452a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000452c:	85d6                	mv	a1,s5
    8000452e:	8552                	mv	a0,s4
    80004530:	00000097          	auipc	ra,0x0
    80004534:	372080e7          	jalr	882(ra) # 800048a2 <pipeclose>
    80004538:	b7cd                	j	8000451a <fileclose+0xa8>

000000008000453a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000453a:	715d                	addi	sp,sp,-80
    8000453c:	e486                	sd	ra,72(sp)
    8000453e:	e0a2                	sd	s0,64(sp)
    80004540:	fc26                	sd	s1,56(sp)
    80004542:	f84a                	sd	s2,48(sp)
    80004544:	f44e                	sd	s3,40(sp)
    80004546:	0880                	addi	s0,sp,80
    80004548:	84aa                	mv	s1,a0
    8000454a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000454c:	ffffd097          	auipc	ra,0xffffd
    80004550:	46e080e7          	jalr	1134(ra) # 800019ba <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004554:	409c                	lw	a5,0(s1)
    80004556:	37f9                	addiw	a5,a5,-2
    80004558:	4705                	li	a4,1
    8000455a:	04f76763          	bltu	a4,a5,800045a8 <filestat+0x6e>
    8000455e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004560:	6c88                	ld	a0,24(s1)
    80004562:	fffff097          	auipc	ra,0xfffff
    80004566:	07e080e7          	jalr	126(ra) # 800035e0 <ilock>
    stati(f->ip, &st);
    8000456a:	fb840593          	addi	a1,s0,-72
    8000456e:	6c88                	ld	a0,24(s1)
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	2fa080e7          	jalr	762(ra) # 8000386a <stati>
    iunlock(f->ip);
    80004578:	6c88                	ld	a0,24(s1)
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	128080e7          	jalr	296(ra) # 800036a2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004582:	46e1                	li	a3,24
    80004584:	fb840613          	addi	a2,s0,-72
    80004588:	85ce                	mv	a1,s3
    8000458a:	05093503          	ld	a0,80(s2)
    8000458e:	ffffd097          	auipc	ra,0xffffd
    80004592:	11e080e7          	jalr	286(ra) # 800016ac <copyout>
    80004596:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000459a:	60a6                	ld	ra,72(sp)
    8000459c:	6406                	ld	s0,64(sp)
    8000459e:	74e2                	ld	s1,56(sp)
    800045a0:	7942                	ld	s2,48(sp)
    800045a2:	79a2                	ld	s3,40(sp)
    800045a4:	6161                	addi	sp,sp,80
    800045a6:	8082                	ret
  return -1;
    800045a8:	557d                	li	a0,-1
    800045aa:	bfc5                	j	8000459a <filestat+0x60>

00000000800045ac <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045ac:	7179                	addi	sp,sp,-48
    800045ae:	f406                	sd	ra,40(sp)
    800045b0:	f022                	sd	s0,32(sp)
    800045b2:	ec26                	sd	s1,24(sp)
    800045b4:	e84a                	sd	s2,16(sp)
    800045b6:	e44e                	sd	s3,8(sp)
    800045b8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045ba:	00854783          	lbu	a5,8(a0)
    800045be:	c3d5                	beqz	a5,80004662 <fileread+0xb6>
    800045c0:	84aa                	mv	s1,a0
    800045c2:	89ae                	mv	s3,a1
    800045c4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045c6:	411c                	lw	a5,0(a0)
    800045c8:	4705                	li	a4,1
    800045ca:	04e78963          	beq	a5,a4,8000461c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045ce:	470d                	li	a4,3
    800045d0:	04e78d63          	beq	a5,a4,8000462a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045d4:	4709                	li	a4,2
    800045d6:	06e79e63          	bne	a5,a4,80004652 <fileread+0xa6>
    ilock(f->ip);
    800045da:	6d08                	ld	a0,24(a0)
    800045dc:	fffff097          	auipc	ra,0xfffff
    800045e0:	004080e7          	jalr	4(ra) # 800035e0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045e4:	874a                	mv	a4,s2
    800045e6:	5094                	lw	a3,32(s1)
    800045e8:	864e                	mv	a2,s3
    800045ea:	4585                	li	a1,1
    800045ec:	6c88                	ld	a0,24(s1)
    800045ee:	fffff097          	auipc	ra,0xfffff
    800045f2:	2a6080e7          	jalr	678(ra) # 80003894 <readi>
    800045f6:	892a                	mv	s2,a0
    800045f8:	00a05563          	blez	a0,80004602 <fileread+0x56>
      f->off += r;
    800045fc:	509c                	lw	a5,32(s1)
    800045fe:	9fa9                	addw	a5,a5,a0
    80004600:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004602:	6c88                	ld	a0,24(s1)
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	09e080e7          	jalr	158(ra) # 800036a2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000460c:	854a                	mv	a0,s2
    8000460e:	70a2                	ld	ra,40(sp)
    80004610:	7402                	ld	s0,32(sp)
    80004612:	64e2                	ld	s1,24(sp)
    80004614:	6942                	ld	s2,16(sp)
    80004616:	69a2                	ld	s3,8(sp)
    80004618:	6145                	addi	sp,sp,48
    8000461a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000461c:	6908                	ld	a0,16(a0)
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	3f4080e7          	jalr	1012(ra) # 80004a12 <piperead>
    80004626:	892a                	mv	s2,a0
    80004628:	b7d5                	j	8000460c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000462a:	02451783          	lh	a5,36(a0)
    8000462e:	03079693          	slli	a3,a5,0x30
    80004632:	92c1                	srli	a3,a3,0x30
    80004634:	4725                	li	a4,9
    80004636:	02d76863          	bltu	a4,a3,80004666 <fileread+0xba>
    8000463a:	0792                	slli	a5,a5,0x4
    8000463c:	0001d717          	auipc	a4,0x1d
    80004640:	37470713          	addi	a4,a4,884 # 800219b0 <devsw>
    80004644:	97ba                	add	a5,a5,a4
    80004646:	639c                	ld	a5,0(a5)
    80004648:	c38d                	beqz	a5,8000466a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000464a:	4505                	li	a0,1
    8000464c:	9782                	jalr	a5
    8000464e:	892a                	mv	s2,a0
    80004650:	bf75                	j	8000460c <fileread+0x60>
    panic("fileread");
    80004652:	00004517          	auipc	a0,0x4
    80004656:	07e50513          	addi	a0,a0,126 # 800086d0 <syscalls+0x258>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	ee8080e7          	jalr	-280(ra) # 80000542 <panic>
    return -1;
    80004662:	597d                	li	s2,-1
    80004664:	b765                	j	8000460c <fileread+0x60>
      return -1;
    80004666:	597d                	li	s2,-1
    80004668:	b755                	j	8000460c <fileread+0x60>
    8000466a:	597d                	li	s2,-1
    8000466c:	b745                	j	8000460c <fileread+0x60>

000000008000466e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000466e:	00954783          	lbu	a5,9(a0)
    80004672:	14078563          	beqz	a5,800047bc <filewrite+0x14e>
{
    80004676:	715d                	addi	sp,sp,-80
    80004678:	e486                	sd	ra,72(sp)
    8000467a:	e0a2                	sd	s0,64(sp)
    8000467c:	fc26                	sd	s1,56(sp)
    8000467e:	f84a                	sd	s2,48(sp)
    80004680:	f44e                	sd	s3,40(sp)
    80004682:	f052                	sd	s4,32(sp)
    80004684:	ec56                	sd	s5,24(sp)
    80004686:	e85a                	sd	s6,16(sp)
    80004688:	e45e                	sd	s7,8(sp)
    8000468a:	e062                	sd	s8,0(sp)
    8000468c:	0880                	addi	s0,sp,80
    8000468e:	892a                	mv	s2,a0
    80004690:	8aae                	mv	s5,a1
    80004692:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004694:	411c                	lw	a5,0(a0)
    80004696:	4705                	li	a4,1
    80004698:	02e78263          	beq	a5,a4,800046bc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000469c:	470d                	li	a4,3
    8000469e:	02e78563          	beq	a5,a4,800046c8 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046a2:	4709                	li	a4,2
    800046a4:	10e79463          	bne	a5,a4,800047ac <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046a8:	0ec05e63          	blez	a2,800047a4 <filewrite+0x136>
    int i = 0;
    800046ac:	4981                	li	s3,0
    800046ae:	6b05                	lui	s6,0x1
    800046b0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800046b4:	6b85                	lui	s7,0x1
    800046b6:	c00b8b9b          	addiw	s7,s7,-1024
    800046ba:	a851                	j	8000474e <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800046bc:	6908                	ld	a0,16(a0)
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	254080e7          	jalr	596(ra) # 80004912 <pipewrite>
    800046c6:	a85d                	j	8000477c <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046c8:	02451783          	lh	a5,36(a0)
    800046cc:	03079693          	slli	a3,a5,0x30
    800046d0:	92c1                	srli	a3,a3,0x30
    800046d2:	4725                	li	a4,9
    800046d4:	0ed76663          	bltu	a4,a3,800047c0 <filewrite+0x152>
    800046d8:	0792                	slli	a5,a5,0x4
    800046da:	0001d717          	auipc	a4,0x1d
    800046de:	2d670713          	addi	a4,a4,726 # 800219b0 <devsw>
    800046e2:	97ba                	add	a5,a5,a4
    800046e4:	679c                	ld	a5,8(a5)
    800046e6:	cff9                	beqz	a5,800047c4 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800046e8:	4505                	li	a0,1
    800046ea:	9782                	jalr	a5
    800046ec:	a841                	j	8000477c <filewrite+0x10e>
    800046ee:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800046f2:	00000097          	auipc	ra,0x0
    800046f6:	8ae080e7          	jalr	-1874(ra) # 80003fa0 <begin_op>
      ilock(f->ip);
    800046fa:	01893503          	ld	a0,24(s2)
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	ee2080e7          	jalr	-286(ra) # 800035e0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004706:	8762                	mv	a4,s8
    80004708:	02092683          	lw	a3,32(s2)
    8000470c:	01598633          	add	a2,s3,s5
    80004710:	4585                	li	a1,1
    80004712:	01893503          	ld	a0,24(s2)
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	274080e7          	jalr	628(ra) # 8000398a <writei>
    8000471e:	84aa                	mv	s1,a0
    80004720:	02a05f63          	blez	a0,8000475e <filewrite+0xf0>
        f->off += r;
    80004724:	02092783          	lw	a5,32(s2)
    80004728:	9fa9                	addw	a5,a5,a0
    8000472a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000472e:	01893503          	ld	a0,24(s2)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	f70080e7          	jalr	-144(ra) # 800036a2 <iunlock>
      end_op();
    8000473a:	00000097          	auipc	ra,0x0
    8000473e:	8e6080e7          	jalr	-1818(ra) # 80004020 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004742:	049c1963          	bne	s8,s1,80004794 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004746:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000474a:	0349d663          	bge	s3,s4,80004776 <filewrite+0x108>
      int n1 = n - i;
    8000474e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004752:	84be                	mv	s1,a5
    80004754:	2781                	sext.w	a5,a5
    80004756:	f8fb5ce3          	bge	s6,a5,800046ee <filewrite+0x80>
    8000475a:	84de                	mv	s1,s7
    8000475c:	bf49                	j	800046ee <filewrite+0x80>
      iunlock(f->ip);
    8000475e:	01893503          	ld	a0,24(s2)
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	f40080e7          	jalr	-192(ra) # 800036a2 <iunlock>
      end_op();
    8000476a:	00000097          	auipc	ra,0x0
    8000476e:	8b6080e7          	jalr	-1866(ra) # 80004020 <end_op>
      if(r < 0)
    80004772:	fc04d8e3          	bgez	s1,80004742 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004776:	8552                	mv	a0,s4
    80004778:	033a1863          	bne	s4,s3,800047a8 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000477c:	60a6                	ld	ra,72(sp)
    8000477e:	6406                	ld	s0,64(sp)
    80004780:	74e2                	ld	s1,56(sp)
    80004782:	7942                	ld	s2,48(sp)
    80004784:	79a2                	ld	s3,40(sp)
    80004786:	7a02                	ld	s4,32(sp)
    80004788:	6ae2                	ld	s5,24(sp)
    8000478a:	6b42                	ld	s6,16(sp)
    8000478c:	6ba2                	ld	s7,8(sp)
    8000478e:	6c02                	ld	s8,0(sp)
    80004790:	6161                	addi	sp,sp,80
    80004792:	8082                	ret
        panic("short filewrite");
    80004794:	00004517          	auipc	a0,0x4
    80004798:	f4c50513          	addi	a0,a0,-180 # 800086e0 <syscalls+0x268>
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	da6080e7          	jalr	-602(ra) # 80000542 <panic>
    int i = 0;
    800047a4:	4981                	li	s3,0
    800047a6:	bfc1                	j	80004776 <filewrite+0x108>
    ret = (i == n ? n : -1);
    800047a8:	557d                	li	a0,-1
    800047aa:	bfc9                	j	8000477c <filewrite+0x10e>
    panic("filewrite");
    800047ac:	00004517          	auipc	a0,0x4
    800047b0:	f4450513          	addi	a0,a0,-188 # 800086f0 <syscalls+0x278>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	d8e080e7          	jalr	-626(ra) # 80000542 <panic>
    return -1;
    800047bc:	557d                	li	a0,-1
}
    800047be:	8082                	ret
      return -1;
    800047c0:	557d                	li	a0,-1
    800047c2:	bf6d                	j	8000477c <filewrite+0x10e>
    800047c4:	557d                	li	a0,-1
    800047c6:	bf5d                	j	8000477c <filewrite+0x10e>

00000000800047c8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047c8:	7179                	addi	sp,sp,-48
    800047ca:	f406                	sd	ra,40(sp)
    800047cc:	f022                	sd	s0,32(sp)
    800047ce:	ec26                	sd	s1,24(sp)
    800047d0:	e84a                	sd	s2,16(sp)
    800047d2:	e44e                	sd	s3,8(sp)
    800047d4:	e052                	sd	s4,0(sp)
    800047d6:	1800                	addi	s0,sp,48
    800047d8:	84aa                	mv	s1,a0
    800047da:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047dc:	0005b023          	sd	zero,0(a1)
    800047e0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047e4:	00000097          	auipc	ra,0x0
    800047e8:	bd2080e7          	jalr	-1070(ra) # 800043b6 <filealloc>
    800047ec:	e088                	sd	a0,0(s1)
    800047ee:	c551                	beqz	a0,8000487a <pipealloc+0xb2>
    800047f0:	00000097          	auipc	ra,0x0
    800047f4:	bc6080e7          	jalr	-1082(ra) # 800043b6 <filealloc>
    800047f8:	00aa3023          	sd	a0,0(s4)
    800047fc:	c92d                	beqz	a0,8000486e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	310080e7          	jalr	784(ra) # 80000b0e <kalloc>
    80004806:	892a                	mv	s2,a0
    80004808:	c125                	beqz	a0,80004868 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000480a:	4985                	li	s3,1
    8000480c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004810:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004814:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004818:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000481c:	00004597          	auipc	a1,0x4
    80004820:	ee458593          	addi	a1,a1,-284 # 80008700 <syscalls+0x288>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	34a080e7          	jalr	842(ra) # 80000b6e <initlock>
  (*f0)->type = FD_PIPE;
    8000482c:	609c                	ld	a5,0(s1)
    8000482e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004832:	609c                	ld	a5,0(s1)
    80004834:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004838:	609c                	ld	a5,0(s1)
    8000483a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000483e:	609c                	ld	a5,0(s1)
    80004840:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004844:	000a3783          	ld	a5,0(s4)
    80004848:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000484c:	000a3783          	ld	a5,0(s4)
    80004850:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004854:	000a3783          	ld	a5,0(s4)
    80004858:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000485c:	000a3783          	ld	a5,0(s4)
    80004860:	0127b823          	sd	s2,16(a5)
  return 0;
    80004864:	4501                	li	a0,0
    80004866:	a025                	j	8000488e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004868:	6088                	ld	a0,0(s1)
    8000486a:	e501                	bnez	a0,80004872 <pipealloc+0xaa>
    8000486c:	a039                	j	8000487a <pipealloc+0xb2>
    8000486e:	6088                	ld	a0,0(s1)
    80004870:	c51d                	beqz	a0,8000489e <pipealloc+0xd6>
    fileclose(*f0);
    80004872:	00000097          	auipc	ra,0x0
    80004876:	c00080e7          	jalr	-1024(ra) # 80004472 <fileclose>
  if(*f1)
    8000487a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000487e:	557d                	li	a0,-1
  if(*f1)
    80004880:	c799                	beqz	a5,8000488e <pipealloc+0xc6>
    fileclose(*f1);
    80004882:	853e                	mv	a0,a5
    80004884:	00000097          	auipc	ra,0x0
    80004888:	bee080e7          	jalr	-1042(ra) # 80004472 <fileclose>
  return -1;
    8000488c:	557d                	li	a0,-1
}
    8000488e:	70a2                	ld	ra,40(sp)
    80004890:	7402                	ld	s0,32(sp)
    80004892:	64e2                	ld	s1,24(sp)
    80004894:	6942                	ld	s2,16(sp)
    80004896:	69a2                	ld	s3,8(sp)
    80004898:	6a02                	ld	s4,0(sp)
    8000489a:	6145                	addi	sp,sp,48
    8000489c:	8082                	ret
  return -1;
    8000489e:	557d                	li	a0,-1
    800048a0:	b7fd                	j	8000488e <pipealloc+0xc6>

00000000800048a2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048a2:	1101                	addi	sp,sp,-32
    800048a4:	ec06                	sd	ra,24(sp)
    800048a6:	e822                	sd	s0,16(sp)
    800048a8:	e426                	sd	s1,8(sp)
    800048aa:	e04a                	sd	s2,0(sp)
    800048ac:	1000                	addi	s0,sp,32
    800048ae:	84aa                	mv	s1,a0
    800048b0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048b2:	ffffc097          	auipc	ra,0xffffc
    800048b6:	34c080e7          	jalr	844(ra) # 80000bfe <acquire>
  if(writable){
    800048ba:	02090d63          	beqz	s2,800048f4 <pipeclose+0x52>
    pi->writeopen = 0;
    800048be:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048c2:	21848513          	addi	a0,s1,536
    800048c6:	ffffe097          	auipc	ra,0xffffe
    800048ca:	a80080e7          	jalr	-1408(ra) # 80002346 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048ce:	2204b783          	ld	a5,544(s1)
    800048d2:	eb95                	bnez	a5,80004906 <pipeclose+0x64>
    release(&pi->lock);
    800048d4:	8526                	mv	a0,s1
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	3dc080e7          	jalr	988(ra) # 80000cb2 <release>
    kfree((char*)pi);
    800048de:	8526                	mv	a0,s1
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	132080e7          	jalr	306(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    800048e8:	60e2                	ld	ra,24(sp)
    800048ea:	6442                	ld	s0,16(sp)
    800048ec:	64a2                	ld	s1,8(sp)
    800048ee:	6902                	ld	s2,0(sp)
    800048f0:	6105                	addi	sp,sp,32
    800048f2:	8082                	ret
    pi->readopen = 0;
    800048f4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048f8:	21c48513          	addi	a0,s1,540
    800048fc:	ffffe097          	auipc	ra,0xffffe
    80004900:	a4a080e7          	jalr	-1462(ra) # 80002346 <wakeup>
    80004904:	b7e9                	j	800048ce <pipeclose+0x2c>
    release(&pi->lock);
    80004906:	8526                	mv	a0,s1
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	3aa080e7          	jalr	938(ra) # 80000cb2 <release>
}
    80004910:	bfe1                	j	800048e8 <pipeclose+0x46>

0000000080004912 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004912:	711d                	addi	sp,sp,-96
    80004914:	ec86                	sd	ra,88(sp)
    80004916:	e8a2                	sd	s0,80(sp)
    80004918:	e4a6                	sd	s1,72(sp)
    8000491a:	e0ca                	sd	s2,64(sp)
    8000491c:	fc4e                	sd	s3,56(sp)
    8000491e:	f852                	sd	s4,48(sp)
    80004920:	f456                	sd	s5,40(sp)
    80004922:	f05a                	sd	s6,32(sp)
    80004924:	ec5e                	sd	s7,24(sp)
    80004926:	e862                	sd	s8,16(sp)
    80004928:	1080                	addi	s0,sp,96
    8000492a:	84aa                	mv	s1,a0
    8000492c:	8b2e                	mv	s6,a1
    8000492e:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004930:	ffffd097          	auipc	ra,0xffffd
    80004934:	08a080e7          	jalr	138(ra) # 800019ba <myproc>
    80004938:	892a                	mv	s2,a0

  acquire(&pi->lock);
    8000493a:	8526                	mv	a0,s1
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	2c2080e7          	jalr	706(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80004944:	09505763          	blez	s5,800049d2 <pipewrite+0xc0>
    80004948:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    8000494a:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000494e:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004952:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004954:	2184a783          	lw	a5,536(s1)
    80004958:	21c4a703          	lw	a4,540(s1)
    8000495c:	2007879b          	addiw	a5,a5,512
    80004960:	02f71b63          	bne	a4,a5,80004996 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004964:	2204a783          	lw	a5,544(s1)
    80004968:	c3d1                	beqz	a5,800049ec <pipewrite+0xda>
    8000496a:	03092783          	lw	a5,48(s2)
    8000496e:	efbd                	bnez	a5,800049ec <pipewrite+0xda>
      wakeup(&pi->nread);
    80004970:	8552                	mv	a0,s4
    80004972:	ffffe097          	auipc	ra,0xffffe
    80004976:	9d4080e7          	jalr	-1580(ra) # 80002346 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000497a:	85a6                	mv	a1,s1
    8000497c:	854e                	mv	a0,s3
    8000497e:	ffffe097          	auipc	ra,0xffffe
    80004982:	848080e7          	jalr	-1976(ra) # 800021c6 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004986:	2184a783          	lw	a5,536(s1)
    8000498a:	21c4a703          	lw	a4,540(s1)
    8000498e:	2007879b          	addiw	a5,a5,512
    80004992:	fcf709e3          	beq	a4,a5,80004964 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004996:	4685                	li	a3,1
    80004998:	865a                	mv	a2,s6
    8000499a:	faf40593          	addi	a1,s0,-81
    8000499e:	05093503          	ld	a0,80(s2)
    800049a2:	ffffd097          	auipc	ra,0xffffd
    800049a6:	d96080e7          	jalr	-618(ra) # 80001738 <copyin>
    800049aa:	03850563          	beq	a0,s8,800049d4 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049ae:	21c4a783          	lw	a5,540(s1)
    800049b2:	0017871b          	addiw	a4,a5,1
    800049b6:	20e4ae23          	sw	a4,540(s1)
    800049ba:	1ff7f793          	andi	a5,a5,511
    800049be:	97a6                	add	a5,a5,s1
    800049c0:	faf44703          	lbu	a4,-81(s0)
    800049c4:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    800049c8:	2b85                	addiw	s7,s7,1
    800049ca:	0b05                	addi	s6,s6,1
    800049cc:	f97a94e3          	bne	s5,s7,80004954 <pipewrite+0x42>
    800049d0:	a011                	j	800049d4 <pipewrite+0xc2>
    800049d2:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    800049d4:	21848513          	addi	a0,s1,536
    800049d8:	ffffe097          	auipc	ra,0xffffe
    800049dc:	96e080e7          	jalr	-1682(ra) # 80002346 <wakeup>
  release(&pi->lock);
    800049e0:	8526                	mv	a0,s1
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	2d0080e7          	jalr	720(ra) # 80000cb2 <release>
  return i;
    800049ea:	a039                	j	800049f8 <pipewrite+0xe6>
        release(&pi->lock);
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	2c4080e7          	jalr	708(ra) # 80000cb2 <release>
        return -1;
    800049f6:	5bfd                	li	s7,-1
}
    800049f8:	855e                	mv	a0,s7
    800049fa:	60e6                	ld	ra,88(sp)
    800049fc:	6446                	ld	s0,80(sp)
    800049fe:	64a6                	ld	s1,72(sp)
    80004a00:	6906                	ld	s2,64(sp)
    80004a02:	79e2                	ld	s3,56(sp)
    80004a04:	7a42                	ld	s4,48(sp)
    80004a06:	7aa2                	ld	s5,40(sp)
    80004a08:	7b02                	ld	s6,32(sp)
    80004a0a:	6be2                	ld	s7,24(sp)
    80004a0c:	6c42                	ld	s8,16(sp)
    80004a0e:	6125                	addi	sp,sp,96
    80004a10:	8082                	ret

0000000080004a12 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a12:	715d                	addi	sp,sp,-80
    80004a14:	e486                	sd	ra,72(sp)
    80004a16:	e0a2                	sd	s0,64(sp)
    80004a18:	fc26                	sd	s1,56(sp)
    80004a1a:	f84a                	sd	s2,48(sp)
    80004a1c:	f44e                	sd	s3,40(sp)
    80004a1e:	f052                	sd	s4,32(sp)
    80004a20:	ec56                	sd	s5,24(sp)
    80004a22:	e85a                	sd	s6,16(sp)
    80004a24:	0880                	addi	s0,sp,80
    80004a26:	84aa                	mv	s1,a0
    80004a28:	892e                	mv	s2,a1
    80004a2a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a2c:	ffffd097          	auipc	ra,0xffffd
    80004a30:	f8e080e7          	jalr	-114(ra) # 800019ba <myproc>
    80004a34:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a36:	8526                	mv	a0,s1
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	1c6080e7          	jalr	454(ra) # 80000bfe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a40:	2184a703          	lw	a4,536(s1)
    80004a44:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a48:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a4c:	02f71463          	bne	a4,a5,80004a74 <piperead+0x62>
    80004a50:	2244a783          	lw	a5,548(s1)
    80004a54:	c385                	beqz	a5,80004a74 <piperead+0x62>
    if(pr->killed){
    80004a56:	030a2783          	lw	a5,48(s4)
    80004a5a:	ebc1                	bnez	a5,80004aea <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a5c:	85a6                	mv	a1,s1
    80004a5e:	854e                	mv	a0,s3
    80004a60:	ffffd097          	auipc	ra,0xffffd
    80004a64:	766080e7          	jalr	1894(ra) # 800021c6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a68:	2184a703          	lw	a4,536(s1)
    80004a6c:	21c4a783          	lw	a5,540(s1)
    80004a70:	fef700e3          	beq	a4,a5,80004a50 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a74:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a76:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a78:	05505363          	blez	s5,80004abe <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004a7c:	2184a783          	lw	a5,536(s1)
    80004a80:	21c4a703          	lw	a4,540(s1)
    80004a84:	02f70d63          	beq	a4,a5,80004abe <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a88:	0017871b          	addiw	a4,a5,1
    80004a8c:	20e4ac23          	sw	a4,536(s1)
    80004a90:	1ff7f793          	andi	a5,a5,511
    80004a94:	97a6                	add	a5,a5,s1
    80004a96:	0187c783          	lbu	a5,24(a5)
    80004a9a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a9e:	4685                	li	a3,1
    80004aa0:	fbf40613          	addi	a2,s0,-65
    80004aa4:	85ca                	mv	a1,s2
    80004aa6:	050a3503          	ld	a0,80(s4)
    80004aaa:	ffffd097          	auipc	ra,0xffffd
    80004aae:	c02080e7          	jalr	-1022(ra) # 800016ac <copyout>
    80004ab2:	01650663          	beq	a0,s6,80004abe <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ab6:	2985                	addiw	s3,s3,1
    80004ab8:	0905                	addi	s2,s2,1
    80004aba:	fd3a91e3          	bne	s5,s3,80004a7c <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004abe:	21c48513          	addi	a0,s1,540
    80004ac2:	ffffe097          	auipc	ra,0xffffe
    80004ac6:	884080e7          	jalr	-1916(ra) # 80002346 <wakeup>
  release(&pi->lock);
    80004aca:	8526                	mv	a0,s1
    80004acc:	ffffc097          	auipc	ra,0xffffc
    80004ad0:	1e6080e7          	jalr	486(ra) # 80000cb2 <release>
  return i;
}
    80004ad4:	854e                	mv	a0,s3
    80004ad6:	60a6                	ld	ra,72(sp)
    80004ad8:	6406                	ld	s0,64(sp)
    80004ada:	74e2                	ld	s1,56(sp)
    80004adc:	7942                	ld	s2,48(sp)
    80004ade:	79a2                	ld	s3,40(sp)
    80004ae0:	7a02                	ld	s4,32(sp)
    80004ae2:	6ae2                	ld	s5,24(sp)
    80004ae4:	6b42                	ld	s6,16(sp)
    80004ae6:	6161                	addi	sp,sp,80
    80004ae8:	8082                	ret
      release(&pi->lock);
    80004aea:	8526                	mv	a0,s1
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	1c6080e7          	jalr	454(ra) # 80000cb2 <release>
      return -1;
    80004af4:	59fd                	li	s3,-1
    80004af6:	bff9                	j	80004ad4 <piperead+0xc2>

0000000080004af8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004af8:	de010113          	addi	sp,sp,-544
    80004afc:	20113c23          	sd	ra,536(sp)
    80004b00:	20813823          	sd	s0,528(sp)
    80004b04:	20913423          	sd	s1,520(sp)
    80004b08:	21213023          	sd	s2,512(sp)
    80004b0c:	ffce                	sd	s3,504(sp)
    80004b0e:	fbd2                	sd	s4,496(sp)
    80004b10:	f7d6                	sd	s5,488(sp)
    80004b12:	f3da                	sd	s6,480(sp)
    80004b14:	efde                	sd	s7,472(sp)
    80004b16:	ebe2                	sd	s8,464(sp)
    80004b18:	e7e6                	sd	s9,456(sp)
    80004b1a:	e3ea                	sd	s10,448(sp)
    80004b1c:	ff6e                	sd	s11,440(sp)
    80004b1e:	1400                	addi	s0,sp,544
    80004b20:	892a                	mv	s2,a0
    80004b22:	dea43423          	sd	a0,-536(s0)
    80004b26:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b2a:	ffffd097          	auipc	ra,0xffffd
    80004b2e:	e90080e7          	jalr	-368(ra) # 800019ba <myproc>
    80004b32:	84aa                	mv	s1,a0

  begin_op();
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	46c080e7          	jalr	1132(ra) # 80003fa0 <begin_op>

  if((ip = namei(path)) == 0){
    80004b3c:	854a                	mv	a0,s2
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	252080e7          	jalr	594(ra) # 80003d90 <namei>
    80004b46:	c93d                	beqz	a0,80004bbc <exec+0xc4>
    80004b48:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b4a:	fffff097          	auipc	ra,0xfffff
    80004b4e:	a96080e7          	jalr	-1386(ra) # 800035e0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b52:	04000713          	li	a4,64
    80004b56:	4681                	li	a3,0
    80004b58:	e4840613          	addi	a2,s0,-440
    80004b5c:	4581                	li	a1,0
    80004b5e:	8556                	mv	a0,s5
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	d34080e7          	jalr	-716(ra) # 80003894 <readi>
    80004b68:	04000793          	li	a5,64
    80004b6c:	00f51a63          	bne	a0,a5,80004b80 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b70:	e4842703          	lw	a4,-440(s0)
    80004b74:	464c47b7          	lui	a5,0x464c4
    80004b78:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b7c:	04f70663          	beq	a4,a5,80004bc8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b80:	8556                	mv	a0,s5
    80004b82:	fffff097          	auipc	ra,0xfffff
    80004b86:	cc0080e7          	jalr	-832(ra) # 80003842 <iunlockput>
    end_op();
    80004b8a:	fffff097          	auipc	ra,0xfffff
    80004b8e:	496080e7          	jalr	1174(ra) # 80004020 <end_op>
  }
  return -1;
    80004b92:	557d                	li	a0,-1
}
    80004b94:	21813083          	ld	ra,536(sp)
    80004b98:	21013403          	ld	s0,528(sp)
    80004b9c:	20813483          	ld	s1,520(sp)
    80004ba0:	20013903          	ld	s2,512(sp)
    80004ba4:	79fe                	ld	s3,504(sp)
    80004ba6:	7a5e                	ld	s4,496(sp)
    80004ba8:	7abe                	ld	s5,488(sp)
    80004baa:	7b1e                	ld	s6,480(sp)
    80004bac:	6bfe                	ld	s7,472(sp)
    80004bae:	6c5e                	ld	s8,464(sp)
    80004bb0:	6cbe                	ld	s9,456(sp)
    80004bb2:	6d1e                	ld	s10,448(sp)
    80004bb4:	7dfa                	ld	s11,440(sp)
    80004bb6:	22010113          	addi	sp,sp,544
    80004bba:	8082                	ret
    end_op();
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	464080e7          	jalr	1124(ra) # 80004020 <end_op>
    return -1;
    80004bc4:	557d                	li	a0,-1
    80004bc6:	b7f9                	j	80004b94 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffd097          	auipc	ra,0xffffd
    80004bce:	eb4080e7          	jalr	-332(ra) # 80001a7e <proc_pagetable>
    80004bd2:	8b2a                	mv	s6,a0
    80004bd4:	d555                	beqz	a0,80004b80 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bd6:	e6842783          	lw	a5,-408(s0)
    80004bda:	e8045703          	lhu	a4,-384(s0)
    80004bde:	c735                	beqz	a4,80004c4a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004be0:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004be2:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004be6:	6a05                	lui	s4,0x1
    80004be8:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004bec:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004bf0:	6d85                	lui	s11,0x1
    80004bf2:	7d7d                	lui	s10,0xfffff
    80004bf4:	ac1d                	j	80004e2a <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bf6:	00004517          	auipc	a0,0x4
    80004bfa:	b1250513          	addi	a0,a0,-1262 # 80008708 <syscalls+0x290>
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	944080e7          	jalr	-1724(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c06:	874a                	mv	a4,s2
    80004c08:	009c86bb          	addw	a3,s9,s1
    80004c0c:	4581                	li	a1,0
    80004c0e:	8556                	mv	a0,s5
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	c84080e7          	jalr	-892(ra) # 80003894 <readi>
    80004c18:	2501                	sext.w	a0,a0
    80004c1a:	1aa91863          	bne	s2,a0,80004dca <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004c1e:	009d84bb          	addw	s1,s11,s1
    80004c22:	013d09bb          	addw	s3,s10,s3
    80004c26:	1f74f263          	bgeu	s1,s7,80004e0a <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004c2a:	02049593          	slli	a1,s1,0x20
    80004c2e:	9181                	srli	a1,a1,0x20
    80004c30:	95e2                	add	a1,a1,s8
    80004c32:	855a                	mv	a0,s6
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	444080e7          	jalr	1092(ra) # 80001078 <walkaddr>
    80004c3c:	862a                	mv	a2,a0
    if(pa == 0)
    80004c3e:	dd45                	beqz	a0,80004bf6 <exec+0xfe>
      n = PGSIZE;
    80004c40:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004c42:	fd49f2e3          	bgeu	s3,s4,80004c06 <exec+0x10e>
      n = sz - i;
    80004c46:	894e                	mv	s2,s3
    80004c48:	bf7d                	j	80004c06 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c4a:	4481                	li	s1,0
  iunlockput(ip);
    80004c4c:	8556                	mv	a0,s5
    80004c4e:	fffff097          	auipc	ra,0xfffff
    80004c52:	bf4080e7          	jalr	-1036(ra) # 80003842 <iunlockput>
  end_op();
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	3ca080e7          	jalr	970(ra) # 80004020 <end_op>
  p = myproc();
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	d5c080e7          	jalr	-676(ra) # 800019ba <myproc>
    80004c66:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004c68:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c6c:	6785                	lui	a5,0x1
    80004c6e:	17fd                	addi	a5,a5,-1
    80004c70:	94be                	add	s1,s1,a5
    80004c72:	77fd                	lui	a5,0xfffff
    80004c74:	8fe5                	and	a5,a5,s1
    80004c76:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c7a:	6609                	lui	a2,0x2
    80004c7c:	963e                	add	a2,a2,a5
    80004c7e:	85be                	mv	a1,a5
    80004c80:	855a                	mv	a0,s6
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	7da080e7          	jalr	2010(ra) # 8000145c <uvmalloc>
    80004c8a:	8c2a                	mv	s8,a0
  ip = 0;
    80004c8c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c8e:	12050e63          	beqz	a0,80004dca <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c92:	75f9                	lui	a1,0xffffe
    80004c94:	95aa                	add	a1,a1,a0
    80004c96:	855a                	mv	a0,s6
    80004c98:	ffffd097          	auipc	ra,0xffffd
    80004c9c:	9e2080e7          	jalr	-1566(ra) # 8000167a <uvmclear>
  stackbase = sp - PGSIZE;
    80004ca0:	7afd                	lui	s5,0xfffff
    80004ca2:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ca4:	df043783          	ld	a5,-528(s0)
    80004ca8:	6388                	ld	a0,0(a5)
    80004caa:	c925                	beqz	a0,80004d1a <exec+0x222>
    80004cac:	e8840993          	addi	s3,s0,-376
    80004cb0:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004cb4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004cb6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	1c6080e7          	jalr	454(ra) # 80000e7e <strlen>
    80004cc0:	0015079b          	addiw	a5,a0,1
    80004cc4:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cc8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ccc:	13596363          	bltu	s2,s5,80004df2 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cd0:	df043d83          	ld	s11,-528(s0)
    80004cd4:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004cd8:	8552                	mv	a0,s4
    80004cda:	ffffc097          	auipc	ra,0xffffc
    80004cde:	1a4080e7          	jalr	420(ra) # 80000e7e <strlen>
    80004ce2:	0015069b          	addiw	a3,a0,1
    80004ce6:	8652                	mv	a2,s4
    80004ce8:	85ca                	mv	a1,s2
    80004cea:	855a                	mv	a0,s6
    80004cec:	ffffd097          	auipc	ra,0xffffd
    80004cf0:	9c0080e7          	jalr	-1600(ra) # 800016ac <copyout>
    80004cf4:	10054363          	bltz	a0,80004dfa <exec+0x302>
    ustack[argc] = sp;
    80004cf8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004cfc:	0485                	addi	s1,s1,1
    80004cfe:	008d8793          	addi	a5,s11,8
    80004d02:	def43823          	sd	a5,-528(s0)
    80004d06:	008db503          	ld	a0,8(s11)
    80004d0a:	c911                	beqz	a0,80004d1e <exec+0x226>
    if(argc >= MAXARG)
    80004d0c:	09a1                	addi	s3,s3,8
    80004d0e:	fb3c95e3          	bne	s9,s3,80004cb8 <exec+0x1c0>
  sz = sz1;
    80004d12:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d16:	4a81                	li	s5,0
    80004d18:	a84d                	j	80004dca <exec+0x2d2>
  sp = sz;
    80004d1a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d1c:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d1e:	00349793          	slli	a5,s1,0x3
    80004d22:	f9040713          	addi	a4,s0,-112
    80004d26:	97ba                	add	a5,a5,a4
    80004d28:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004d2c:	00148693          	addi	a3,s1,1
    80004d30:	068e                	slli	a3,a3,0x3
    80004d32:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d36:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d3a:	01597663          	bgeu	s2,s5,80004d46 <exec+0x24e>
  sz = sz1;
    80004d3e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d42:	4a81                	li	s5,0
    80004d44:	a059                	j	80004dca <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d46:	e8840613          	addi	a2,s0,-376
    80004d4a:	85ca                	mv	a1,s2
    80004d4c:	855a                	mv	a0,s6
    80004d4e:	ffffd097          	auipc	ra,0xffffd
    80004d52:	95e080e7          	jalr	-1698(ra) # 800016ac <copyout>
    80004d56:	0a054663          	bltz	a0,80004e02 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004d5a:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004d5e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d62:	de843783          	ld	a5,-536(s0)
    80004d66:	0007c703          	lbu	a4,0(a5)
    80004d6a:	cf11                	beqz	a4,80004d86 <exec+0x28e>
    80004d6c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d6e:	02f00693          	li	a3,47
    80004d72:	a039                	j	80004d80 <exec+0x288>
      last = s+1;
    80004d74:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004d78:	0785                	addi	a5,a5,1
    80004d7a:	fff7c703          	lbu	a4,-1(a5)
    80004d7e:	c701                	beqz	a4,80004d86 <exec+0x28e>
    if(*s == '/')
    80004d80:	fed71ce3          	bne	a4,a3,80004d78 <exec+0x280>
    80004d84:	bfc5                	j	80004d74 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d86:	4641                	li	a2,16
    80004d88:	de843583          	ld	a1,-536(s0)
    80004d8c:	158b8513          	addi	a0,s7,344
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	0bc080e7          	jalr	188(ra) # 80000e4c <safestrcpy>
  oldpagetable = p->pagetable;
    80004d98:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004d9c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004da0:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004da4:	058bb783          	ld	a5,88(s7)
    80004da8:	e6043703          	ld	a4,-416(s0)
    80004dac:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004dae:	058bb783          	ld	a5,88(s7)
    80004db2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004db6:	85ea                	mv	a1,s10
    80004db8:	ffffd097          	auipc	ra,0xffffd
    80004dbc:	d62080e7          	jalr	-670(ra) # 80001b1a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004dc0:	0004851b          	sext.w	a0,s1
    80004dc4:	bbc1                	j	80004b94 <exec+0x9c>
    80004dc6:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004dca:	df843583          	ld	a1,-520(s0)
    80004dce:	855a                	mv	a0,s6
    80004dd0:	ffffd097          	auipc	ra,0xffffd
    80004dd4:	d4a080e7          	jalr	-694(ra) # 80001b1a <proc_freepagetable>
  if(ip){
    80004dd8:	da0a94e3          	bnez	s5,80004b80 <exec+0x88>
  return -1;
    80004ddc:	557d                	li	a0,-1
    80004dde:	bb5d                	j	80004b94 <exec+0x9c>
    80004de0:	de943c23          	sd	s1,-520(s0)
    80004de4:	b7dd                	j	80004dca <exec+0x2d2>
    80004de6:	de943c23          	sd	s1,-520(s0)
    80004dea:	b7c5                	j	80004dca <exec+0x2d2>
    80004dec:	de943c23          	sd	s1,-520(s0)
    80004df0:	bfe9                	j	80004dca <exec+0x2d2>
  sz = sz1;
    80004df2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004df6:	4a81                	li	s5,0
    80004df8:	bfc9                	j	80004dca <exec+0x2d2>
  sz = sz1;
    80004dfa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dfe:	4a81                	li	s5,0
    80004e00:	b7e9                	j	80004dca <exec+0x2d2>
  sz = sz1;
    80004e02:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e06:	4a81                	li	s5,0
    80004e08:	b7c9                	j	80004dca <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e0a:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e0e:	e0843783          	ld	a5,-504(s0)
    80004e12:	0017869b          	addiw	a3,a5,1
    80004e16:	e0d43423          	sd	a3,-504(s0)
    80004e1a:	e0043783          	ld	a5,-512(s0)
    80004e1e:	0387879b          	addiw	a5,a5,56
    80004e22:	e8045703          	lhu	a4,-384(s0)
    80004e26:	e2e6d3e3          	bge	a3,a4,80004c4c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e2a:	2781                	sext.w	a5,a5
    80004e2c:	e0f43023          	sd	a5,-512(s0)
    80004e30:	03800713          	li	a4,56
    80004e34:	86be                	mv	a3,a5
    80004e36:	e1040613          	addi	a2,s0,-496
    80004e3a:	4581                	li	a1,0
    80004e3c:	8556                	mv	a0,s5
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	a56080e7          	jalr	-1450(ra) # 80003894 <readi>
    80004e46:	03800793          	li	a5,56
    80004e4a:	f6f51ee3          	bne	a0,a5,80004dc6 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004e4e:	e1042783          	lw	a5,-496(s0)
    80004e52:	4705                	li	a4,1
    80004e54:	fae79de3          	bne	a5,a4,80004e0e <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004e58:	e3843603          	ld	a2,-456(s0)
    80004e5c:	e3043783          	ld	a5,-464(s0)
    80004e60:	f8f660e3          	bltu	a2,a5,80004de0 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e64:	e2043783          	ld	a5,-480(s0)
    80004e68:	963e                	add	a2,a2,a5
    80004e6a:	f6f66ee3          	bltu	a2,a5,80004de6 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e6e:	85a6                	mv	a1,s1
    80004e70:	855a                	mv	a0,s6
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	5ea080e7          	jalr	1514(ra) # 8000145c <uvmalloc>
    80004e7a:	dea43c23          	sd	a0,-520(s0)
    80004e7e:	d53d                	beqz	a0,80004dec <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004e80:	e2043c03          	ld	s8,-480(s0)
    80004e84:	de043783          	ld	a5,-544(s0)
    80004e88:	00fc77b3          	and	a5,s8,a5
    80004e8c:	ff9d                	bnez	a5,80004dca <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e8e:	e1842c83          	lw	s9,-488(s0)
    80004e92:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e96:	f60b8ae3          	beqz	s7,80004e0a <exec+0x312>
    80004e9a:	89de                	mv	s3,s7
    80004e9c:	4481                	li	s1,0
    80004e9e:	b371                	j	80004c2a <exec+0x132>

0000000080004ea0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ea0:	7179                	addi	sp,sp,-48
    80004ea2:	f406                	sd	ra,40(sp)
    80004ea4:	f022                	sd	s0,32(sp)
    80004ea6:	ec26                	sd	s1,24(sp)
    80004ea8:	e84a                	sd	s2,16(sp)
    80004eaa:	1800                	addi	s0,sp,48
    80004eac:	892e                	mv	s2,a1
    80004eae:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004eb0:	fdc40593          	addi	a1,s0,-36
    80004eb4:	ffffe097          	auipc	ra,0xffffe
    80004eb8:	bba080e7          	jalr	-1094(ra) # 80002a6e <argint>
    80004ebc:	04054063          	bltz	a0,80004efc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ec0:	fdc42703          	lw	a4,-36(s0)
    80004ec4:	47bd                	li	a5,15
    80004ec6:	02e7ed63          	bltu	a5,a4,80004f00 <argfd+0x60>
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	af0080e7          	jalr	-1296(ra) # 800019ba <myproc>
    80004ed2:	fdc42703          	lw	a4,-36(s0)
    80004ed6:	01a70793          	addi	a5,a4,26
    80004eda:	078e                	slli	a5,a5,0x3
    80004edc:	953e                	add	a0,a0,a5
    80004ede:	611c                	ld	a5,0(a0)
    80004ee0:	c395                	beqz	a5,80004f04 <argfd+0x64>
    return -1;
  if(pfd)
    80004ee2:	00090463          	beqz	s2,80004eea <argfd+0x4a>
    *pfd = fd;
    80004ee6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004eea:	4501                	li	a0,0
  if(pf)
    80004eec:	c091                	beqz	s1,80004ef0 <argfd+0x50>
    *pf = f;
    80004eee:	e09c                	sd	a5,0(s1)
}
    80004ef0:	70a2                	ld	ra,40(sp)
    80004ef2:	7402                	ld	s0,32(sp)
    80004ef4:	64e2                	ld	s1,24(sp)
    80004ef6:	6942                	ld	s2,16(sp)
    80004ef8:	6145                	addi	sp,sp,48
    80004efa:	8082                	ret
    return -1;
    80004efc:	557d                	li	a0,-1
    80004efe:	bfcd                	j	80004ef0 <argfd+0x50>
    return -1;
    80004f00:	557d                	li	a0,-1
    80004f02:	b7fd                	j	80004ef0 <argfd+0x50>
    80004f04:	557d                	li	a0,-1
    80004f06:	b7ed                	j	80004ef0 <argfd+0x50>

0000000080004f08 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f08:	1101                	addi	sp,sp,-32
    80004f0a:	ec06                	sd	ra,24(sp)
    80004f0c:	e822                	sd	s0,16(sp)
    80004f0e:	e426                	sd	s1,8(sp)
    80004f10:	1000                	addi	s0,sp,32
    80004f12:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f14:	ffffd097          	auipc	ra,0xffffd
    80004f18:	aa6080e7          	jalr	-1370(ra) # 800019ba <myproc>
    80004f1c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f1e:	0d050793          	addi	a5,a0,208
    80004f22:	4501                	li	a0,0
    80004f24:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f26:	6398                	ld	a4,0(a5)
    80004f28:	cb19                	beqz	a4,80004f3e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f2a:	2505                	addiw	a0,a0,1
    80004f2c:	07a1                	addi	a5,a5,8
    80004f2e:	fed51ce3          	bne	a0,a3,80004f26 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f32:	557d                	li	a0,-1
}
    80004f34:	60e2                	ld	ra,24(sp)
    80004f36:	6442                	ld	s0,16(sp)
    80004f38:	64a2                	ld	s1,8(sp)
    80004f3a:	6105                	addi	sp,sp,32
    80004f3c:	8082                	ret
      p->ofile[fd] = f;
    80004f3e:	01a50793          	addi	a5,a0,26
    80004f42:	078e                	slli	a5,a5,0x3
    80004f44:	963e                	add	a2,a2,a5
    80004f46:	e204                	sd	s1,0(a2)
      return fd;
    80004f48:	b7f5                	j	80004f34 <fdalloc+0x2c>

0000000080004f4a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f4a:	715d                	addi	sp,sp,-80
    80004f4c:	e486                	sd	ra,72(sp)
    80004f4e:	e0a2                	sd	s0,64(sp)
    80004f50:	fc26                	sd	s1,56(sp)
    80004f52:	f84a                	sd	s2,48(sp)
    80004f54:	f44e                	sd	s3,40(sp)
    80004f56:	f052                	sd	s4,32(sp)
    80004f58:	ec56                	sd	s5,24(sp)
    80004f5a:	0880                	addi	s0,sp,80
    80004f5c:	89ae                	mv	s3,a1
    80004f5e:	8ab2                	mv	s5,a2
    80004f60:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f62:	fb040593          	addi	a1,s0,-80
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	e48080e7          	jalr	-440(ra) # 80003dae <nameiparent>
    80004f6e:	892a                	mv	s2,a0
    80004f70:	12050e63          	beqz	a0,800050ac <create+0x162>
    return 0;

  ilock(dp);
    80004f74:	ffffe097          	auipc	ra,0xffffe
    80004f78:	66c080e7          	jalr	1644(ra) # 800035e0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f7c:	4601                	li	a2,0
    80004f7e:	fb040593          	addi	a1,s0,-80
    80004f82:	854a                	mv	a0,s2
    80004f84:	fffff097          	auipc	ra,0xfffff
    80004f88:	b3a080e7          	jalr	-1222(ra) # 80003abe <dirlookup>
    80004f8c:	84aa                	mv	s1,a0
    80004f8e:	c921                	beqz	a0,80004fde <create+0x94>
    iunlockput(dp);
    80004f90:	854a                	mv	a0,s2
    80004f92:	fffff097          	auipc	ra,0xfffff
    80004f96:	8b0080e7          	jalr	-1872(ra) # 80003842 <iunlockput>
    ilock(ip);
    80004f9a:	8526                	mv	a0,s1
    80004f9c:	ffffe097          	auipc	ra,0xffffe
    80004fa0:	644080e7          	jalr	1604(ra) # 800035e0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fa4:	2981                	sext.w	s3,s3
    80004fa6:	4789                	li	a5,2
    80004fa8:	02f99463          	bne	s3,a5,80004fd0 <create+0x86>
    80004fac:	0444d783          	lhu	a5,68(s1)
    80004fb0:	37f9                	addiw	a5,a5,-2
    80004fb2:	17c2                	slli	a5,a5,0x30
    80004fb4:	93c1                	srli	a5,a5,0x30
    80004fb6:	4705                	li	a4,1
    80004fb8:	00f76c63          	bltu	a4,a5,80004fd0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004fbc:	8526                	mv	a0,s1
    80004fbe:	60a6                	ld	ra,72(sp)
    80004fc0:	6406                	ld	s0,64(sp)
    80004fc2:	74e2                	ld	s1,56(sp)
    80004fc4:	7942                	ld	s2,48(sp)
    80004fc6:	79a2                	ld	s3,40(sp)
    80004fc8:	7a02                	ld	s4,32(sp)
    80004fca:	6ae2                	ld	s5,24(sp)
    80004fcc:	6161                	addi	sp,sp,80
    80004fce:	8082                	ret
    iunlockput(ip);
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	870080e7          	jalr	-1936(ra) # 80003842 <iunlockput>
    return 0;
    80004fda:	4481                	li	s1,0
    80004fdc:	b7c5                	j	80004fbc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004fde:	85ce                	mv	a1,s3
    80004fe0:	00092503          	lw	a0,0(s2)
    80004fe4:	ffffe097          	auipc	ra,0xffffe
    80004fe8:	464080e7          	jalr	1124(ra) # 80003448 <ialloc>
    80004fec:	84aa                	mv	s1,a0
    80004fee:	c521                	beqz	a0,80005036 <create+0xec>
  ilock(ip);
    80004ff0:	ffffe097          	auipc	ra,0xffffe
    80004ff4:	5f0080e7          	jalr	1520(ra) # 800035e0 <ilock>
  ip->major = major;
    80004ff8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004ffc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005000:	4a05                	li	s4,1
    80005002:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005006:	8526                	mv	a0,s1
    80005008:	ffffe097          	auipc	ra,0xffffe
    8000500c:	50e080e7          	jalr	1294(ra) # 80003516 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005010:	2981                	sext.w	s3,s3
    80005012:	03498a63          	beq	s3,s4,80005046 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005016:	40d0                	lw	a2,4(s1)
    80005018:	fb040593          	addi	a1,s0,-80
    8000501c:	854a                	mv	a0,s2
    8000501e:	fffff097          	auipc	ra,0xfffff
    80005022:	cb0080e7          	jalr	-848(ra) # 80003cce <dirlink>
    80005026:	06054b63          	bltz	a0,8000509c <create+0x152>
  iunlockput(dp);
    8000502a:	854a                	mv	a0,s2
    8000502c:	fffff097          	auipc	ra,0xfffff
    80005030:	816080e7          	jalr	-2026(ra) # 80003842 <iunlockput>
  return ip;
    80005034:	b761                	j	80004fbc <create+0x72>
    panic("create: ialloc");
    80005036:	00003517          	auipc	a0,0x3
    8000503a:	6f250513          	addi	a0,a0,1778 # 80008728 <syscalls+0x2b0>
    8000503e:	ffffb097          	auipc	ra,0xffffb
    80005042:	504080e7          	jalr	1284(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    80005046:	04a95783          	lhu	a5,74(s2)
    8000504a:	2785                	addiw	a5,a5,1
    8000504c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005050:	854a                	mv	a0,s2
    80005052:	ffffe097          	auipc	ra,0xffffe
    80005056:	4c4080e7          	jalr	1220(ra) # 80003516 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000505a:	40d0                	lw	a2,4(s1)
    8000505c:	00003597          	auipc	a1,0x3
    80005060:	6dc58593          	addi	a1,a1,1756 # 80008738 <syscalls+0x2c0>
    80005064:	8526                	mv	a0,s1
    80005066:	fffff097          	auipc	ra,0xfffff
    8000506a:	c68080e7          	jalr	-920(ra) # 80003cce <dirlink>
    8000506e:	00054f63          	bltz	a0,8000508c <create+0x142>
    80005072:	00492603          	lw	a2,4(s2)
    80005076:	00003597          	auipc	a1,0x3
    8000507a:	6ca58593          	addi	a1,a1,1738 # 80008740 <syscalls+0x2c8>
    8000507e:	8526                	mv	a0,s1
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	c4e080e7          	jalr	-946(ra) # 80003cce <dirlink>
    80005088:	f80557e3          	bgez	a0,80005016 <create+0xcc>
      panic("create dots");
    8000508c:	00003517          	auipc	a0,0x3
    80005090:	6bc50513          	addi	a0,a0,1724 # 80008748 <syscalls+0x2d0>
    80005094:	ffffb097          	auipc	ra,0xffffb
    80005098:	4ae080e7          	jalr	1198(ra) # 80000542 <panic>
    panic("create: dirlink");
    8000509c:	00003517          	auipc	a0,0x3
    800050a0:	6bc50513          	addi	a0,a0,1724 # 80008758 <syscalls+0x2e0>
    800050a4:	ffffb097          	auipc	ra,0xffffb
    800050a8:	49e080e7          	jalr	1182(ra) # 80000542 <panic>
    return 0;
    800050ac:	84aa                	mv	s1,a0
    800050ae:	b739                	j	80004fbc <create+0x72>

00000000800050b0 <sys_dup>:
{
    800050b0:	7179                	addi	sp,sp,-48
    800050b2:	f406                	sd	ra,40(sp)
    800050b4:	f022                	sd	s0,32(sp)
    800050b6:	ec26                	sd	s1,24(sp)
    800050b8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050ba:	fd840613          	addi	a2,s0,-40
    800050be:	4581                	li	a1,0
    800050c0:	4501                	li	a0,0
    800050c2:	00000097          	auipc	ra,0x0
    800050c6:	dde080e7          	jalr	-546(ra) # 80004ea0 <argfd>
    return -1;
    800050ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050cc:	02054363          	bltz	a0,800050f2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800050d0:	fd843503          	ld	a0,-40(s0)
    800050d4:	00000097          	auipc	ra,0x0
    800050d8:	e34080e7          	jalr	-460(ra) # 80004f08 <fdalloc>
    800050dc:	84aa                	mv	s1,a0
    return -1;
    800050de:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050e0:	00054963          	bltz	a0,800050f2 <sys_dup+0x42>
  filedup(f);
    800050e4:	fd843503          	ld	a0,-40(s0)
    800050e8:	fffff097          	auipc	ra,0xfffff
    800050ec:	338080e7          	jalr	824(ra) # 80004420 <filedup>
  return fd;
    800050f0:	87a6                	mv	a5,s1
}
    800050f2:	853e                	mv	a0,a5
    800050f4:	70a2                	ld	ra,40(sp)
    800050f6:	7402                	ld	s0,32(sp)
    800050f8:	64e2                	ld	s1,24(sp)
    800050fa:	6145                	addi	sp,sp,48
    800050fc:	8082                	ret

00000000800050fe <sys_read>:
{
    800050fe:	7179                	addi	sp,sp,-48
    80005100:	f406                	sd	ra,40(sp)
    80005102:	f022                	sd	s0,32(sp)
    80005104:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005106:	fe840613          	addi	a2,s0,-24
    8000510a:	4581                	li	a1,0
    8000510c:	4501                	li	a0,0
    8000510e:	00000097          	auipc	ra,0x0
    80005112:	d92080e7          	jalr	-622(ra) # 80004ea0 <argfd>
    return -1;
    80005116:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005118:	04054163          	bltz	a0,8000515a <sys_read+0x5c>
    8000511c:	fe440593          	addi	a1,s0,-28
    80005120:	4509                	li	a0,2
    80005122:	ffffe097          	auipc	ra,0xffffe
    80005126:	94c080e7          	jalr	-1716(ra) # 80002a6e <argint>
    return -1;
    8000512a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000512c:	02054763          	bltz	a0,8000515a <sys_read+0x5c>
    80005130:	fd840593          	addi	a1,s0,-40
    80005134:	4505                	li	a0,1
    80005136:	ffffe097          	auipc	ra,0xffffe
    8000513a:	95a080e7          	jalr	-1702(ra) # 80002a90 <argaddr>
    return -1;
    8000513e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005140:	00054d63          	bltz	a0,8000515a <sys_read+0x5c>
  return fileread(f, p, n);
    80005144:	fe442603          	lw	a2,-28(s0)
    80005148:	fd843583          	ld	a1,-40(s0)
    8000514c:	fe843503          	ld	a0,-24(s0)
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	45c080e7          	jalr	1116(ra) # 800045ac <fileread>
    80005158:	87aa                	mv	a5,a0
}
    8000515a:	853e                	mv	a0,a5
    8000515c:	70a2                	ld	ra,40(sp)
    8000515e:	7402                	ld	s0,32(sp)
    80005160:	6145                	addi	sp,sp,48
    80005162:	8082                	ret

0000000080005164 <sys_write>:
{
    80005164:	7179                	addi	sp,sp,-48
    80005166:	f406                	sd	ra,40(sp)
    80005168:	f022                	sd	s0,32(sp)
    8000516a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000516c:	fe840613          	addi	a2,s0,-24
    80005170:	4581                	li	a1,0
    80005172:	4501                	li	a0,0
    80005174:	00000097          	auipc	ra,0x0
    80005178:	d2c080e7          	jalr	-724(ra) # 80004ea0 <argfd>
    return -1;
    8000517c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000517e:	04054163          	bltz	a0,800051c0 <sys_write+0x5c>
    80005182:	fe440593          	addi	a1,s0,-28
    80005186:	4509                	li	a0,2
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	8e6080e7          	jalr	-1818(ra) # 80002a6e <argint>
    return -1;
    80005190:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005192:	02054763          	bltz	a0,800051c0 <sys_write+0x5c>
    80005196:	fd840593          	addi	a1,s0,-40
    8000519a:	4505                	li	a0,1
    8000519c:	ffffe097          	auipc	ra,0xffffe
    800051a0:	8f4080e7          	jalr	-1804(ra) # 80002a90 <argaddr>
    return -1;
    800051a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051a6:	00054d63          	bltz	a0,800051c0 <sys_write+0x5c>
  return filewrite(f, p, n);
    800051aa:	fe442603          	lw	a2,-28(s0)
    800051ae:	fd843583          	ld	a1,-40(s0)
    800051b2:	fe843503          	ld	a0,-24(s0)
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	4b8080e7          	jalr	1208(ra) # 8000466e <filewrite>
    800051be:	87aa                	mv	a5,a0
}
    800051c0:	853e                	mv	a0,a5
    800051c2:	70a2                	ld	ra,40(sp)
    800051c4:	7402                	ld	s0,32(sp)
    800051c6:	6145                	addi	sp,sp,48
    800051c8:	8082                	ret

00000000800051ca <sys_close>:
{
    800051ca:	1101                	addi	sp,sp,-32
    800051cc:	ec06                	sd	ra,24(sp)
    800051ce:	e822                	sd	s0,16(sp)
    800051d0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051d2:	fe040613          	addi	a2,s0,-32
    800051d6:	fec40593          	addi	a1,s0,-20
    800051da:	4501                	li	a0,0
    800051dc:	00000097          	auipc	ra,0x0
    800051e0:	cc4080e7          	jalr	-828(ra) # 80004ea0 <argfd>
    return -1;
    800051e4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051e6:	02054463          	bltz	a0,8000520e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051ea:	ffffc097          	auipc	ra,0xffffc
    800051ee:	7d0080e7          	jalr	2000(ra) # 800019ba <myproc>
    800051f2:	fec42783          	lw	a5,-20(s0)
    800051f6:	07e9                	addi	a5,a5,26
    800051f8:	078e                	slli	a5,a5,0x3
    800051fa:	97aa                	add	a5,a5,a0
    800051fc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005200:	fe043503          	ld	a0,-32(s0)
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	26e080e7          	jalr	622(ra) # 80004472 <fileclose>
  return 0;
    8000520c:	4781                	li	a5,0
}
    8000520e:	853e                	mv	a0,a5
    80005210:	60e2                	ld	ra,24(sp)
    80005212:	6442                	ld	s0,16(sp)
    80005214:	6105                	addi	sp,sp,32
    80005216:	8082                	ret

0000000080005218 <sys_fstat>:
{
    80005218:	1101                	addi	sp,sp,-32
    8000521a:	ec06                	sd	ra,24(sp)
    8000521c:	e822                	sd	s0,16(sp)
    8000521e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005220:	fe840613          	addi	a2,s0,-24
    80005224:	4581                	li	a1,0
    80005226:	4501                	li	a0,0
    80005228:	00000097          	auipc	ra,0x0
    8000522c:	c78080e7          	jalr	-904(ra) # 80004ea0 <argfd>
    return -1;
    80005230:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005232:	02054563          	bltz	a0,8000525c <sys_fstat+0x44>
    80005236:	fe040593          	addi	a1,s0,-32
    8000523a:	4505                	li	a0,1
    8000523c:	ffffe097          	auipc	ra,0xffffe
    80005240:	854080e7          	jalr	-1964(ra) # 80002a90 <argaddr>
    return -1;
    80005244:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005246:	00054b63          	bltz	a0,8000525c <sys_fstat+0x44>
  return filestat(f, st);
    8000524a:	fe043583          	ld	a1,-32(s0)
    8000524e:	fe843503          	ld	a0,-24(s0)
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	2e8080e7          	jalr	744(ra) # 8000453a <filestat>
    8000525a:	87aa                	mv	a5,a0
}
    8000525c:	853e                	mv	a0,a5
    8000525e:	60e2                	ld	ra,24(sp)
    80005260:	6442                	ld	s0,16(sp)
    80005262:	6105                	addi	sp,sp,32
    80005264:	8082                	ret

0000000080005266 <sys_link>:
{
    80005266:	7169                	addi	sp,sp,-304
    80005268:	f606                	sd	ra,296(sp)
    8000526a:	f222                	sd	s0,288(sp)
    8000526c:	ee26                	sd	s1,280(sp)
    8000526e:	ea4a                	sd	s2,272(sp)
    80005270:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005272:	08000613          	li	a2,128
    80005276:	ed040593          	addi	a1,s0,-304
    8000527a:	4501                	li	a0,0
    8000527c:	ffffe097          	auipc	ra,0xffffe
    80005280:	836080e7          	jalr	-1994(ra) # 80002ab2 <argstr>
    return -1;
    80005284:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005286:	10054e63          	bltz	a0,800053a2 <sys_link+0x13c>
    8000528a:	08000613          	li	a2,128
    8000528e:	f5040593          	addi	a1,s0,-176
    80005292:	4505                	li	a0,1
    80005294:	ffffe097          	auipc	ra,0xffffe
    80005298:	81e080e7          	jalr	-2018(ra) # 80002ab2 <argstr>
    return -1;
    8000529c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000529e:	10054263          	bltz	a0,800053a2 <sys_link+0x13c>
  begin_op();
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	cfe080e7          	jalr	-770(ra) # 80003fa0 <begin_op>
  if((ip = namei(old)) == 0){
    800052aa:	ed040513          	addi	a0,s0,-304
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	ae2080e7          	jalr	-1310(ra) # 80003d90 <namei>
    800052b6:	84aa                	mv	s1,a0
    800052b8:	c551                	beqz	a0,80005344 <sys_link+0xde>
  ilock(ip);
    800052ba:	ffffe097          	auipc	ra,0xffffe
    800052be:	326080e7          	jalr	806(ra) # 800035e0 <ilock>
  if(ip->type == T_DIR){
    800052c2:	04449703          	lh	a4,68(s1)
    800052c6:	4785                	li	a5,1
    800052c8:	08f70463          	beq	a4,a5,80005350 <sys_link+0xea>
  ip->nlink++;
    800052cc:	04a4d783          	lhu	a5,74(s1)
    800052d0:	2785                	addiw	a5,a5,1
    800052d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052d6:	8526                	mv	a0,s1
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	23e080e7          	jalr	574(ra) # 80003516 <iupdate>
  iunlock(ip);
    800052e0:	8526                	mv	a0,s1
    800052e2:	ffffe097          	auipc	ra,0xffffe
    800052e6:	3c0080e7          	jalr	960(ra) # 800036a2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052ea:	fd040593          	addi	a1,s0,-48
    800052ee:	f5040513          	addi	a0,s0,-176
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	abc080e7          	jalr	-1348(ra) # 80003dae <nameiparent>
    800052fa:	892a                	mv	s2,a0
    800052fc:	c935                	beqz	a0,80005370 <sys_link+0x10a>
  ilock(dp);
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	2e2080e7          	jalr	738(ra) # 800035e0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005306:	00092703          	lw	a4,0(s2)
    8000530a:	409c                	lw	a5,0(s1)
    8000530c:	04f71d63          	bne	a4,a5,80005366 <sys_link+0x100>
    80005310:	40d0                	lw	a2,4(s1)
    80005312:	fd040593          	addi	a1,s0,-48
    80005316:	854a                	mv	a0,s2
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	9b6080e7          	jalr	-1610(ra) # 80003cce <dirlink>
    80005320:	04054363          	bltz	a0,80005366 <sys_link+0x100>
  iunlockput(dp);
    80005324:	854a                	mv	a0,s2
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	51c080e7          	jalr	1308(ra) # 80003842 <iunlockput>
  iput(ip);
    8000532e:	8526                	mv	a0,s1
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	46a080e7          	jalr	1130(ra) # 8000379a <iput>
  end_op();
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	ce8080e7          	jalr	-792(ra) # 80004020 <end_op>
  return 0;
    80005340:	4781                	li	a5,0
    80005342:	a085                	j	800053a2 <sys_link+0x13c>
    end_op();
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	cdc080e7          	jalr	-804(ra) # 80004020 <end_op>
    return -1;
    8000534c:	57fd                	li	a5,-1
    8000534e:	a891                	j	800053a2 <sys_link+0x13c>
    iunlockput(ip);
    80005350:	8526                	mv	a0,s1
    80005352:	ffffe097          	auipc	ra,0xffffe
    80005356:	4f0080e7          	jalr	1264(ra) # 80003842 <iunlockput>
    end_op();
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	cc6080e7          	jalr	-826(ra) # 80004020 <end_op>
    return -1;
    80005362:	57fd                	li	a5,-1
    80005364:	a83d                	j	800053a2 <sys_link+0x13c>
    iunlockput(dp);
    80005366:	854a                	mv	a0,s2
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	4da080e7          	jalr	1242(ra) # 80003842 <iunlockput>
  ilock(ip);
    80005370:	8526                	mv	a0,s1
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	26e080e7          	jalr	622(ra) # 800035e0 <ilock>
  ip->nlink--;
    8000537a:	04a4d783          	lhu	a5,74(s1)
    8000537e:	37fd                	addiw	a5,a5,-1
    80005380:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005384:	8526                	mv	a0,s1
    80005386:	ffffe097          	auipc	ra,0xffffe
    8000538a:	190080e7          	jalr	400(ra) # 80003516 <iupdate>
  iunlockput(ip);
    8000538e:	8526                	mv	a0,s1
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	4b2080e7          	jalr	1202(ra) # 80003842 <iunlockput>
  end_op();
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	c88080e7          	jalr	-888(ra) # 80004020 <end_op>
  return -1;
    800053a0:	57fd                	li	a5,-1
}
    800053a2:	853e                	mv	a0,a5
    800053a4:	70b2                	ld	ra,296(sp)
    800053a6:	7412                	ld	s0,288(sp)
    800053a8:	64f2                	ld	s1,280(sp)
    800053aa:	6952                	ld	s2,272(sp)
    800053ac:	6155                	addi	sp,sp,304
    800053ae:	8082                	ret

00000000800053b0 <sys_unlink>:
{
    800053b0:	7151                	addi	sp,sp,-240
    800053b2:	f586                	sd	ra,232(sp)
    800053b4:	f1a2                	sd	s0,224(sp)
    800053b6:	eda6                	sd	s1,216(sp)
    800053b8:	e9ca                	sd	s2,208(sp)
    800053ba:	e5ce                	sd	s3,200(sp)
    800053bc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053be:	08000613          	li	a2,128
    800053c2:	f3040593          	addi	a1,s0,-208
    800053c6:	4501                	li	a0,0
    800053c8:	ffffd097          	auipc	ra,0xffffd
    800053cc:	6ea080e7          	jalr	1770(ra) # 80002ab2 <argstr>
    800053d0:	18054163          	bltz	a0,80005552 <sys_unlink+0x1a2>
  begin_op();
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	bcc080e7          	jalr	-1076(ra) # 80003fa0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053dc:	fb040593          	addi	a1,s0,-80
    800053e0:	f3040513          	addi	a0,s0,-208
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	9ca080e7          	jalr	-1590(ra) # 80003dae <nameiparent>
    800053ec:	84aa                	mv	s1,a0
    800053ee:	c979                	beqz	a0,800054c4 <sys_unlink+0x114>
  ilock(dp);
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	1f0080e7          	jalr	496(ra) # 800035e0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053f8:	00003597          	auipc	a1,0x3
    800053fc:	34058593          	addi	a1,a1,832 # 80008738 <syscalls+0x2c0>
    80005400:	fb040513          	addi	a0,s0,-80
    80005404:	ffffe097          	auipc	ra,0xffffe
    80005408:	6a0080e7          	jalr	1696(ra) # 80003aa4 <namecmp>
    8000540c:	14050a63          	beqz	a0,80005560 <sys_unlink+0x1b0>
    80005410:	00003597          	auipc	a1,0x3
    80005414:	33058593          	addi	a1,a1,816 # 80008740 <syscalls+0x2c8>
    80005418:	fb040513          	addi	a0,s0,-80
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	688080e7          	jalr	1672(ra) # 80003aa4 <namecmp>
    80005424:	12050e63          	beqz	a0,80005560 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005428:	f2c40613          	addi	a2,s0,-212
    8000542c:	fb040593          	addi	a1,s0,-80
    80005430:	8526                	mv	a0,s1
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	68c080e7          	jalr	1676(ra) # 80003abe <dirlookup>
    8000543a:	892a                	mv	s2,a0
    8000543c:	12050263          	beqz	a0,80005560 <sys_unlink+0x1b0>
  ilock(ip);
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	1a0080e7          	jalr	416(ra) # 800035e0 <ilock>
  if(ip->nlink < 1)
    80005448:	04a91783          	lh	a5,74(s2)
    8000544c:	08f05263          	blez	a5,800054d0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005450:	04491703          	lh	a4,68(s2)
    80005454:	4785                	li	a5,1
    80005456:	08f70563          	beq	a4,a5,800054e0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000545a:	4641                	li	a2,16
    8000545c:	4581                	li	a1,0
    8000545e:	fc040513          	addi	a0,s0,-64
    80005462:	ffffc097          	auipc	ra,0xffffc
    80005466:	898080e7          	jalr	-1896(ra) # 80000cfa <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000546a:	4741                	li	a4,16
    8000546c:	f2c42683          	lw	a3,-212(s0)
    80005470:	fc040613          	addi	a2,s0,-64
    80005474:	4581                	li	a1,0
    80005476:	8526                	mv	a0,s1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	512080e7          	jalr	1298(ra) # 8000398a <writei>
    80005480:	47c1                	li	a5,16
    80005482:	0af51563          	bne	a0,a5,8000552c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005486:	04491703          	lh	a4,68(s2)
    8000548a:	4785                	li	a5,1
    8000548c:	0af70863          	beq	a4,a5,8000553c <sys_unlink+0x18c>
  iunlockput(dp);
    80005490:	8526                	mv	a0,s1
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	3b0080e7          	jalr	944(ra) # 80003842 <iunlockput>
  ip->nlink--;
    8000549a:	04a95783          	lhu	a5,74(s2)
    8000549e:	37fd                	addiw	a5,a5,-1
    800054a0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800054a4:	854a                	mv	a0,s2
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	070080e7          	jalr	112(ra) # 80003516 <iupdate>
  iunlockput(ip);
    800054ae:	854a                	mv	a0,s2
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	392080e7          	jalr	914(ra) # 80003842 <iunlockput>
  end_op();
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	b68080e7          	jalr	-1176(ra) # 80004020 <end_op>
  return 0;
    800054c0:	4501                	li	a0,0
    800054c2:	a84d                	j	80005574 <sys_unlink+0x1c4>
    end_op();
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	b5c080e7          	jalr	-1188(ra) # 80004020 <end_op>
    return -1;
    800054cc:	557d                	li	a0,-1
    800054ce:	a05d                	j	80005574 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054d0:	00003517          	auipc	a0,0x3
    800054d4:	29850513          	addi	a0,a0,664 # 80008768 <syscalls+0x2f0>
    800054d8:	ffffb097          	auipc	ra,0xffffb
    800054dc:	06a080e7          	jalr	106(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054e0:	04c92703          	lw	a4,76(s2)
    800054e4:	02000793          	li	a5,32
    800054e8:	f6e7f9e3          	bgeu	a5,a4,8000545a <sys_unlink+0xaa>
    800054ec:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054f0:	4741                	li	a4,16
    800054f2:	86ce                	mv	a3,s3
    800054f4:	f1840613          	addi	a2,s0,-232
    800054f8:	4581                	li	a1,0
    800054fa:	854a                	mv	a0,s2
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	398080e7          	jalr	920(ra) # 80003894 <readi>
    80005504:	47c1                	li	a5,16
    80005506:	00f51b63          	bne	a0,a5,8000551c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000550a:	f1845783          	lhu	a5,-232(s0)
    8000550e:	e7a1                	bnez	a5,80005556 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005510:	29c1                	addiw	s3,s3,16
    80005512:	04c92783          	lw	a5,76(s2)
    80005516:	fcf9ede3          	bltu	s3,a5,800054f0 <sys_unlink+0x140>
    8000551a:	b781                	j	8000545a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000551c:	00003517          	auipc	a0,0x3
    80005520:	26450513          	addi	a0,a0,612 # 80008780 <syscalls+0x308>
    80005524:	ffffb097          	auipc	ra,0xffffb
    80005528:	01e080e7          	jalr	30(ra) # 80000542 <panic>
    panic("unlink: writei");
    8000552c:	00003517          	auipc	a0,0x3
    80005530:	26c50513          	addi	a0,a0,620 # 80008798 <syscalls+0x320>
    80005534:	ffffb097          	auipc	ra,0xffffb
    80005538:	00e080e7          	jalr	14(ra) # 80000542 <panic>
    dp->nlink--;
    8000553c:	04a4d783          	lhu	a5,74(s1)
    80005540:	37fd                	addiw	a5,a5,-1
    80005542:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005546:	8526                	mv	a0,s1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	fce080e7          	jalr	-50(ra) # 80003516 <iupdate>
    80005550:	b781                	j	80005490 <sys_unlink+0xe0>
    return -1;
    80005552:	557d                	li	a0,-1
    80005554:	a005                	j	80005574 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005556:	854a                	mv	a0,s2
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	2ea080e7          	jalr	746(ra) # 80003842 <iunlockput>
  iunlockput(dp);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	2e0080e7          	jalr	736(ra) # 80003842 <iunlockput>
  end_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	ab6080e7          	jalr	-1354(ra) # 80004020 <end_op>
  return -1;
    80005572:	557d                	li	a0,-1
}
    80005574:	70ae                	ld	ra,232(sp)
    80005576:	740e                	ld	s0,224(sp)
    80005578:	64ee                	ld	s1,216(sp)
    8000557a:	694e                	ld	s2,208(sp)
    8000557c:	69ae                	ld	s3,200(sp)
    8000557e:	616d                	addi	sp,sp,240
    80005580:	8082                	ret

0000000080005582 <sys_open>:

uint64
sys_open(void)
{
    80005582:	7131                	addi	sp,sp,-192
    80005584:	fd06                	sd	ra,184(sp)
    80005586:	f922                	sd	s0,176(sp)
    80005588:	f526                	sd	s1,168(sp)
    8000558a:	f14a                	sd	s2,160(sp)
    8000558c:	ed4e                	sd	s3,152(sp)
    8000558e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005590:	08000613          	li	a2,128
    80005594:	f5040593          	addi	a1,s0,-176
    80005598:	4501                	li	a0,0
    8000559a:	ffffd097          	auipc	ra,0xffffd
    8000559e:	518080e7          	jalr	1304(ra) # 80002ab2 <argstr>
    return -1;
    800055a2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055a4:	0c054163          	bltz	a0,80005666 <sys_open+0xe4>
    800055a8:	f4c40593          	addi	a1,s0,-180
    800055ac:	4505                	li	a0,1
    800055ae:	ffffd097          	auipc	ra,0xffffd
    800055b2:	4c0080e7          	jalr	1216(ra) # 80002a6e <argint>
    800055b6:	0a054863          	bltz	a0,80005666 <sys_open+0xe4>

  begin_op();
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	9e6080e7          	jalr	-1562(ra) # 80003fa0 <begin_op>

  if(omode & O_CREATE){
    800055c2:	f4c42783          	lw	a5,-180(s0)
    800055c6:	2007f793          	andi	a5,a5,512
    800055ca:	cbdd                	beqz	a5,80005680 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055cc:	4681                	li	a3,0
    800055ce:	4601                	li	a2,0
    800055d0:	4589                	li	a1,2
    800055d2:	f5040513          	addi	a0,s0,-176
    800055d6:	00000097          	auipc	ra,0x0
    800055da:	974080e7          	jalr	-1676(ra) # 80004f4a <create>
    800055de:	892a                	mv	s2,a0
    if(ip == 0){
    800055e0:	c959                	beqz	a0,80005676 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055e2:	04491703          	lh	a4,68(s2)
    800055e6:	478d                	li	a5,3
    800055e8:	00f71763          	bne	a4,a5,800055f6 <sys_open+0x74>
    800055ec:	04695703          	lhu	a4,70(s2)
    800055f0:	47a5                	li	a5,9
    800055f2:	0ce7ec63          	bltu	a5,a4,800056ca <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	dc0080e7          	jalr	-576(ra) # 800043b6 <filealloc>
    800055fe:	89aa                	mv	s3,a0
    80005600:	10050263          	beqz	a0,80005704 <sys_open+0x182>
    80005604:	00000097          	auipc	ra,0x0
    80005608:	904080e7          	jalr	-1788(ra) # 80004f08 <fdalloc>
    8000560c:	84aa                	mv	s1,a0
    8000560e:	0e054663          	bltz	a0,800056fa <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005612:	04491703          	lh	a4,68(s2)
    80005616:	478d                	li	a5,3
    80005618:	0cf70463          	beq	a4,a5,800056e0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000561c:	4789                	li	a5,2
    8000561e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005622:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005626:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000562a:	f4c42783          	lw	a5,-180(s0)
    8000562e:	0017c713          	xori	a4,a5,1
    80005632:	8b05                	andi	a4,a4,1
    80005634:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005638:	0037f713          	andi	a4,a5,3
    8000563c:	00e03733          	snez	a4,a4
    80005640:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005644:	4007f793          	andi	a5,a5,1024
    80005648:	c791                	beqz	a5,80005654 <sys_open+0xd2>
    8000564a:	04491703          	lh	a4,68(s2)
    8000564e:	4789                	li	a5,2
    80005650:	08f70f63          	beq	a4,a5,800056ee <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005654:	854a                	mv	a0,s2
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	04c080e7          	jalr	76(ra) # 800036a2 <iunlock>
  end_op();
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	9c2080e7          	jalr	-1598(ra) # 80004020 <end_op>

  return fd;
}
    80005666:	8526                	mv	a0,s1
    80005668:	70ea                	ld	ra,184(sp)
    8000566a:	744a                	ld	s0,176(sp)
    8000566c:	74aa                	ld	s1,168(sp)
    8000566e:	790a                	ld	s2,160(sp)
    80005670:	69ea                	ld	s3,152(sp)
    80005672:	6129                	addi	sp,sp,192
    80005674:	8082                	ret
      end_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	9aa080e7          	jalr	-1622(ra) # 80004020 <end_op>
      return -1;
    8000567e:	b7e5                	j	80005666 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005680:	f5040513          	addi	a0,s0,-176
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	70c080e7          	jalr	1804(ra) # 80003d90 <namei>
    8000568c:	892a                	mv	s2,a0
    8000568e:	c905                	beqz	a0,800056be <sys_open+0x13c>
    ilock(ip);
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	f50080e7          	jalr	-176(ra) # 800035e0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005698:	04491703          	lh	a4,68(s2)
    8000569c:	4785                	li	a5,1
    8000569e:	f4f712e3          	bne	a4,a5,800055e2 <sys_open+0x60>
    800056a2:	f4c42783          	lw	a5,-180(s0)
    800056a6:	dba1                	beqz	a5,800055f6 <sys_open+0x74>
      iunlockput(ip);
    800056a8:	854a                	mv	a0,s2
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	198080e7          	jalr	408(ra) # 80003842 <iunlockput>
      end_op();
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	96e080e7          	jalr	-1682(ra) # 80004020 <end_op>
      return -1;
    800056ba:	54fd                	li	s1,-1
    800056bc:	b76d                	j	80005666 <sys_open+0xe4>
      end_op();
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	962080e7          	jalr	-1694(ra) # 80004020 <end_op>
      return -1;
    800056c6:	54fd                	li	s1,-1
    800056c8:	bf79                	j	80005666 <sys_open+0xe4>
    iunlockput(ip);
    800056ca:	854a                	mv	a0,s2
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	176080e7          	jalr	374(ra) # 80003842 <iunlockput>
    end_op();
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	94c080e7          	jalr	-1716(ra) # 80004020 <end_op>
    return -1;
    800056dc:	54fd                	li	s1,-1
    800056de:	b761                	j	80005666 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056e0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056e4:	04691783          	lh	a5,70(s2)
    800056e8:	02f99223          	sh	a5,36(s3)
    800056ec:	bf2d                	j	80005626 <sys_open+0xa4>
    itrunc(ip);
    800056ee:	854a                	mv	a0,s2
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	ffe080e7          	jalr	-2(ra) # 800036ee <itrunc>
    800056f8:	bfb1                	j	80005654 <sys_open+0xd2>
      fileclose(f);
    800056fa:	854e                	mv	a0,s3
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	d76080e7          	jalr	-650(ra) # 80004472 <fileclose>
    iunlockput(ip);
    80005704:	854a                	mv	a0,s2
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	13c080e7          	jalr	316(ra) # 80003842 <iunlockput>
    end_op();
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	912080e7          	jalr	-1774(ra) # 80004020 <end_op>
    return -1;
    80005716:	54fd                	li	s1,-1
    80005718:	b7b9                	j	80005666 <sys_open+0xe4>

000000008000571a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000571a:	7175                	addi	sp,sp,-144
    8000571c:	e506                	sd	ra,136(sp)
    8000571e:	e122                	sd	s0,128(sp)
    80005720:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	87e080e7          	jalr	-1922(ra) # 80003fa0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000572a:	08000613          	li	a2,128
    8000572e:	f7040593          	addi	a1,s0,-144
    80005732:	4501                	li	a0,0
    80005734:	ffffd097          	auipc	ra,0xffffd
    80005738:	37e080e7          	jalr	894(ra) # 80002ab2 <argstr>
    8000573c:	02054963          	bltz	a0,8000576e <sys_mkdir+0x54>
    80005740:	4681                	li	a3,0
    80005742:	4601                	li	a2,0
    80005744:	4585                	li	a1,1
    80005746:	f7040513          	addi	a0,s0,-144
    8000574a:	00000097          	auipc	ra,0x0
    8000574e:	800080e7          	jalr	-2048(ra) # 80004f4a <create>
    80005752:	cd11                	beqz	a0,8000576e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	0ee080e7          	jalr	238(ra) # 80003842 <iunlockput>
  end_op();
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	8c4080e7          	jalr	-1852(ra) # 80004020 <end_op>
  return 0;
    80005764:	4501                	li	a0,0
}
    80005766:	60aa                	ld	ra,136(sp)
    80005768:	640a                	ld	s0,128(sp)
    8000576a:	6149                	addi	sp,sp,144
    8000576c:	8082                	ret
    end_op();
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	8b2080e7          	jalr	-1870(ra) # 80004020 <end_op>
    return -1;
    80005776:	557d                	li	a0,-1
    80005778:	b7fd                	j	80005766 <sys_mkdir+0x4c>

000000008000577a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000577a:	7135                	addi	sp,sp,-160
    8000577c:	ed06                	sd	ra,152(sp)
    8000577e:	e922                	sd	s0,144(sp)
    80005780:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	81e080e7          	jalr	-2018(ra) # 80003fa0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000578a:	08000613          	li	a2,128
    8000578e:	f7040593          	addi	a1,s0,-144
    80005792:	4501                	li	a0,0
    80005794:	ffffd097          	auipc	ra,0xffffd
    80005798:	31e080e7          	jalr	798(ra) # 80002ab2 <argstr>
    8000579c:	04054a63          	bltz	a0,800057f0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800057a0:	f6c40593          	addi	a1,s0,-148
    800057a4:	4505                	li	a0,1
    800057a6:	ffffd097          	auipc	ra,0xffffd
    800057aa:	2c8080e7          	jalr	712(ra) # 80002a6e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057ae:	04054163          	bltz	a0,800057f0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800057b2:	f6840593          	addi	a1,s0,-152
    800057b6:	4509                	li	a0,2
    800057b8:	ffffd097          	auipc	ra,0xffffd
    800057bc:	2b6080e7          	jalr	694(ra) # 80002a6e <argint>
     argint(1, &major) < 0 ||
    800057c0:	02054863          	bltz	a0,800057f0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057c4:	f6841683          	lh	a3,-152(s0)
    800057c8:	f6c41603          	lh	a2,-148(s0)
    800057cc:	458d                	li	a1,3
    800057ce:	f7040513          	addi	a0,s0,-144
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	778080e7          	jalr	1912(ra) # 80004f4a <create>
     argint(2, &minor) < 0 ||
    800057da:	c919                	beqz	a0,800057f0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	066080e7          	jalr	102(ra) # 80003842 <iunlockput>
  end_op();
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	83c080e7          	jalr	-1988(ra) # 80004020 <end_op>
  return 0;
    800057ec:	4501                	li	a0,0
    800057ee:	a031                	j	800057fa <sys_mknod+0x80>
    end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	830080e7          	jalr	-2000(ra) # 80004020 <end_op>
    return -1;
    800057f8:	557d                	li	a0,-1
}
    800057fa:	60ea                	ld	ra,152(sp)
    800057fc:	644a                	ld	s0,144(sp)
    800057fe:	610d                	addi	sp,sp,160
    80005800:	8082                	ret

0000000080005802 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005802:	7135                	addi	sp,sp,-160
    80005804:	ed06                	sd	ra,152(sp)
    80005806:	e922                	sd	s0,144(sp)
    80005808:	e526                	sd	s1,136(sp)
    8000580a:	e14a                	sd	s2,128(sp)
    8000580c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000580e:	ffffc097          	auipc	ra,0xffffc
    80005812:	1ac080e7          	jalr	428(ra) # 800019ba <myproc>
    80005816:	892a                	mv	s2,a0
  
  begin_op();
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	788080e7          	jalr	1928(ra) # 80003fa0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005820:	08000613          	li	a2,128
    80005824:	f6040593          	addi	a1,s0,-160
    80005828:	4501                	li	a0,0
    8000582a:	ffffd097          	auipc	ra,0xffffd
    8000582e:	288080e7          	jalr	648(ra) # 80002ab2 <argstr>
    80005832:	04054b63          	bltz	a0,80005888 <sys_chdir+0x86>
    80005836:	f6040513          	addi	a0,s0,-160
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	556080e7          	jalr	1366(ra) # 80003d90 <namei>
    80005842:	84aa                	mv	s1,a0
    80005844:	c131                	beqz	a0,80005888 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	d9a080e7          	jalr	-614(ra) # 800035e0 <ilock>
  if(ip->type != T_DIR){
    8000584e:	04449703          	lh	a4,68(s1)
    80005852:	4785                	li	a5,1
    80005854:	04f71063          	bne	a4,a5,80005894 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005858:	8526                	mv	a0,s1
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	e48080e7          	jalr	-440(ra) # 800036a2 <iunlock>
  iput(p->cwd);
    80005862:	15093503          	ld	a0,336(s2)
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	f34080e7          	jalr	-204(ra) # 8000379a <iput>
  end_op();
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	7b2080e7          	jalr	1970(ra) # 80004020 <end_op>
  p->cwd = ip;
    80005876:	14993823          	sd	s1,336(s2)
  return 0;
    8000587a:	4501                	li	a0,0
}
    8000587c:	60ea                	ld	ra,152(sp)
    8000587e:	644a                	ld	s0,144(sp)
    80005880:	64aa                	ld	s1,136(sp)
    80005882:	690a                	ld	s2,128(sp)
    80005884:	610d                	addi	sp,sp,160
    80005886:	8082                	ret
    end_op();
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	798080e7          	jalr	1944(ra) # 80004020 <end_op>
    return -1;
    80005890:	557d                	li	a0,-1
    80005892:	b7ed                	j	8000587c <sys_chdir+0x7a>
    iunlockput(ip);
    80005894:	8526                	mv	a0,s1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	fac080e7          	jalr	-84(ra) # 80003842 <iunlockput>
    end_op();
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	782080e7          	jalr	1922(ra) # 80004020 <end_op>
    return -1;
    800058a6:	557d                	li	a0,-1
    800058a8:	bfd1                	j	8000587c <sys_chdir+0x7a>

00000000800058aa <sys_exec>:

uint64
sys_exec(void)
{
    800058aa:	7145                	addi	sp,sp,-464
    800058ac:	e786                	sd	ra,456(sp)
    800058ae:	e3a2                	sd	s0,448(sp)
    800058b0:	ff26                	sd	s1,440(sp)
    800058b2:	fb4a                	sd	s2,432(sp)
    800058b4:	f74e                	sd	s3,424(sp)
    800058b6:	f352                	sd	s4,416(sp)
    800058b8:	ef56                	sd	s5,408(sp)
    800058ba:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058bc:	08000613          	li	a2,128
    800058c0:	f4040593          	addi	a1,s0,-192
    800058c4:	4501                	li	a0,0
    800058c6:	ffffd097          	auipc	ra,0xffffd
    800058ca:	1ec080e7          	jalr	492(ra) # 80002ab2 <argstr>
    return -1;
    800058ce:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058d0:	0c054a63          	bltz	a0,800059a4 <sys_exec+0xfa>
    800058d4:	e3840593          	addi	a1,s0,-456
    800058d8:	4505                	li	a0,1
    800058da:	ffffd097          	auipc	ra,0xffffd
    800058de:	1b6080e7          	jalr	438(ra) # 80002a90 <argaddr>
    800058e2:	0c054163          	bltz	a0,800059a4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800058e6:	10000613          	li	a2,256
    800058ea:	4581                	li	a1,0
    800058ec:	e4040513          	addi	a0,s0,-448
    800058f0:	ffffb097          	auipc	ra,0xffffb
    800058f4:	40a080e7          	jalr	1034(ra) # 80000cfa <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058f8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800058fc:	89a6                	mv	s3,s1
    800058fe:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005900:	02000a13          	li	s4,32
    80005904:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005908:	00391793          	slli	a5,s2,0x3
    8000590c:	e3040593          	addi	a1,s0,-464
    80005910:	e3843503          	ld	a0,-456(s0)
    80005914:	953e                	add	a0,a0,a5
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	0be080e7          	jalr	190(ra) # 800029d4 <fetchaddr>
    8000591e:	02054a63          	bltz	a0,80005952 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005922:	e3043783          	ld	a5,-464(s0)
    80005926:	c3b9                	beqz	a5,8000596c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005928:	ffffb097          	auipc	ra,0xffffb
    8000592c:	1e6080e7          	jalr	486(ra) # 80000b0e <kalloc>
    80005930:	85aa                	mv	a1,a0
    80005932:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005936:	cd11                	beqz	a0,80005952 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005938:	6605                	lui	a2,0x1
    8000593a:	e3043503          	ld	a0,-464(s0)
    8000593e:	ffffd097          	auipc	ra,0xffffd
    80005942:	0e8080e7          	jalr	232(ra) # 80002a26 <fetchstr>
    80005946:	00054663          	bltz	a0,80005952 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000594a:	0905                	addi	s2,s2,1
    8000594c:	09a1                	addi	s3,s3,8
    8000594e:	fb491be3          	bne	s2,s4,80005904 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005952:	10048913          	addi	s2,s1,256
    80005956:	6088                	ld	a0,0(s1)
    80005958:	c529                	beqz	a0,800059a2 <sys_exec+0xf8>
    kfree(argv[i]);
    8000595a:	ffffb097          	auipc	ra,0xffffb
    8000595e:	0b8080e7          	jalr	184(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005962:	04a1                	addi	s1,s1,8
    80005964:	ff2499e3          	bne	s1,s2,80005956 <sys_exec+0xac>
  return -1;
    80005968:	597d                	li	s2,-1
    8000596a:	a82d                	j	800059a4 <sys_exec+0xfa>
      argv[i] = 0;
    8000596c:	0a8e                	slli	s5,s5,0x3
    8000596e:	fc040793          	addi	a5,s0,-64
    80005972:	9abe                	add	s5,s5,a5
    80005974:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005978:	e4040593          	addi	a1,s0,-448
    8000597c:	f4040513          	addi	a0,s0,-192
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	178080e7          	jalr	376(ra) # 80004af8 <exec>
    80005988:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000598a:	10048993          	addi	s3,s1,256
    8000598e:	6088                	ld	a0,0(s1)
    80005990:	c911                	beqz	a0,800059a4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005992:	ffffb097          	auipc	ra,0xffffb
    80005996:	080080e7          	jalr	128(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000599a:	04a1                	addi	s1,s1,8
    8000599c:	ff3499e3          	bne	s1,s3,8000598e <sys_exec+0xe4>
    800059a0:	a011                	j	800059a4 <sys_exec+0xfa>
  return -1;
    800059a2:	597d                	li	s2,-1
}
    800059a4:	854a                	mv	a0,s2
    800059a6:	60be                	ld	ra,456(sp)
    800059a8:	641e                	ld	s0,448(sp)
    800059aa:	74fa                	ld	s1,440(sp)
    800059ac:	795a                	ld	s2,432(sp)
    800059ae:	79ba                	ld	s3,424(sp)
    800059b0:	7a1a                	ld	s4,416(sp)
    800059b2:	6afa                	ld	s5,408(sp)
    800059b4:	6179                	addi	sp,sp,464
    800059b6:	8082                	ret

00000000800059b8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800059b8:	7139                	addi	sp,sp,-64
    800059ba:	fc06                	sd	ra,56(sp)
    800059bc:	f822                	sd	s0,48(sp)
    800059be:	f426                	sd	s1,40(sp)
    800059c0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059c2:	ffffc097          	auipc	ra,0xffffc
    800059c6:	ff8080e7          	jalr	-8(ra) # 800019ba <myproc>
    800059ca:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059cc:	fd840593          	addi	a1,s0,-40
    800059d0:	4501                	li	a0,0
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	0be080e7          	jalr	190(ra) # 80002a90 <argaddr>
    return -1;
    800059da:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059dc:	0e054063          	bltz	a0,80005abc <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059e0:	fc840593          	addi	a1,s0,-56
    800059e4:	fd040513          	addi	a0,s0,-48
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	de0080e7          	jalr	-544(ra) # 800047c8 <pipealloc>
    return -1;
    800059f0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059f2:	0c054563          	bltz	a0,80005abc <sys_pipe+0x104>
  fd0 = -1;
    800059f6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059fa:	fd043503          	ld	a0,-48(s0)
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	50a080e7          	jalr	1290(ra) # 80004f08 <fdalloc>
    80005a06:	fca42223          	sw	a0,-60(s0)
    80005a0a:	08054c63          	bltz	a0,80005aa2 <sys_pipe+0xea>
    80005a0e:	fc843503          	ld	a0,-56(s0)
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	4f6080e7          	jalr	1270(ra) # 80004f08 <fdalloc>
    80005a1a:	fca42023          	sw	a0,-64(s0)
    80005a1e:	06054863          	bltz	a0,80005a8e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a22:	4691                	li	a3,4
    80005a24:	fc440613          	addi	a2,s0,-60
    80005a28:	fd843583          	ld	a1,-40(s0)
    80005a2c:	68a8                	ld	a0,80(s1)
    80005a2e:	ffffc097          	auipc	ra,0xffffc
    80005a32:	c7e080e7          	jalr	-898(ra) # 800016ac <copyout>
    80005a36:	02054063          	bltz	a0,80005a56 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a3a:	4691                	li	a3,4
    80005a3c:	fc040613          	addi	a2,s0,-64
    80005a40:	fd843583          	ld	a1,-40(s0)
    80005a44:	0591                	addi	a1,a1,4
    80005a46:	68a8                	ld	a0,80(s1)
    80005a48:	ffffc097          	auipc	ra,0xffffc
    80005a4c:	c64080e7          	jalr	-924(ra) # 800016ac <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a50:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a52:	06055563          	bgez	a0,80005abc <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a56:	fc442783          	lw	a5,-60(s0)
    80005a5a:	07e9                	addi	a5,a5,26
    80005a5c:	078e                	slli	a5,a5,0x3
    80005a5e:	97a6                	add	a5,a5,s1
    80005a60:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a64:	fc042503          	lw	a0,-64(s0)
    80005a68:	0569                	addi	a0,a0,26
    80005a6a:	050e                	slli	a0,a0,0x3
    80005a6c:	9526                	add	a0,a0,s1
    80005a6e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a72:	fd043503          	ld	a0,-48(s0)
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	9fc080e7          	jalr	-1540(ra) # 80004472 <fileclose>
    fileclose(wf);
    80005a7e:	fc843503          	ld	a0,-56(s0)
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	9f0080e7          	jalr	-1552(ra) # 80004472 <fileclose>
    return -1;
    80005a8a:	57fd                	li	a5,-1
    80005a8c:	a805                	j	80005abc <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a8e:	fc442783          	lw	a5,-60(s0)
    80005a92:	0007c863          	bltz	a5,80005aa2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a96:	01a78513          	addi	a0,a5,26
    80005a9a:	050e                	slli	a0,a0,0x3
    80005a9c:	9526                	add	a0,a0,s1
    80005a9e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005aa2:	fd043503          	ld	a0,-48(s0)
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	9cc080e7          	jalr	-1588(ra) # 80004472 <fileclose>
    fileclose(wf);
    80005aae:	fc843503          	ld	a0,-56(s0)
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	9c0080e7          	jalr	-1600(ra) # 80004472 <fileclose>
    return -1;
    80005aba:	57fd                	li	a5,-1
}
    80005abc:	853e                	mv	a0,a5
    80005abe:	70e2                	ld	ra,56(sp)
    80005ac0:	7442                	ld	s0,48(sp)
    80005ac2:	74a2                	ld	s1,40(sp)
    80005ac4:	6121                	addi	sp,sp,64
    80005ac6:	8082                	ret
	...

0000000080005ad0 <kernelvec>:
    80005ad0:	7111                	addi	sp,sp,-256
    80005ad2:	e006                	sd	ra,0(sp)
    80005ad4:	e40a                	sd	sp,8(sp)
    80005ad6:	e80e                	sd	gp,16(sp)
    80005ad8:	ec12                	sd	tp,24(sp)
    80005ada:	f016                	sd	t0,32(sp)
    80005adc:	f41a                	sd	t1,40(sp)
    80005ade:	f81e                	sd	t2,48(sp)
    80005ae0:	fc22                	sd	s0,56(sp)
    80005ae2:	e0a6                	sd	s1,64(sp)
    80005ae4:	e4aa                	sd	a0,72(sp)
    80005ae6:	e8ae                	sd	a1,80(sp)
    80005ae8:	ecb2                	sd	a2,88(sp)
    80005aea:	f0b6                	sd	a3,96(sp)
    80005aec:	f4ba                	sd	a4,104(sp)
    80005aee:	f8be                	sd	a5,112(sp)
    80005af0:	fcc2                	sd	a6,120(sp)
    80005af2:	e146                	sd	a7,128(sp)
    80005af4:	e54a                	sd	s2,136(sp)
    80005af6:	e94e                	sd	s3,144(sp)
    80005af8:	ed52                	sd	s4,152(sp)
    80005afa:	f156                	sd	s5,160(sp)
    80005afc:	f55a                	sd	s6,168(sp)
    80005afe:	f95e                	sd	s7,176(sp)
    80005b00:	fd62                	sd	s8,184(sp)
    80005b02:	e1e6                	sd	s9,192(sp)
    80005b04:	e5ea                	sd	s10,200(sp)
    80005b06:	e9ee                	sd	s11,208(sp)
    80005b08:	edf2                	sd	t3,216(sp)
    80005b0a:	f1f6                	sd	t4,224(sp)
    80005b0c:	f5fa                	sd	t5,232(sp)
    80005b0e:	f9fe                	sd	t6,240(sp)
    80005b10:	d91fc0ef          	jal	ra,800028a0 <kerneltrap>
    80005b14:	6082                	ld	ra,0(sp)
    80005b16:	6122                	ld	sp,8(sp)
    80005b18:	61c2                	ld	gp,16(sp)
    80005b1a:	7282                	ld	t0,32(sp)
    80005b1c:	7322                	ld	t1,40(sp)
    80005b1e:	73c2                	ld	t2,48(sp)
    80005b20:	7462                	ld	s0,56(sp)
    80005b22:	6486                	ld	s1,64(sp)
    80005b24:	6526                	ld	a0,72(sp)
    80005b26:	65c6                	ld	a1,80(sp)
    80005b28:	6666                	ld	a2,88(sp)
    80005b2a:	7686                	ld	a3,96(sp)
    80005b2c:	7726                	ld	a4,104(sp)
    80005b2e:	77c6                	ld	a5,112(sp)
    80005b30:	7866                	ld	a6,120(sp)
    80005b32:	688a                	ld	a7,128(sp)
    80005b34:	692a                	ld	s2,136(sp)
    80005b36:	69ca                	ld	s3,144(sp)
    80005b38:	6a6a                	ld	s4,152(sp)
    80005b3a:	7a8a                	ld	s5,160(sp)
    80005b3c:	7b2a                	ld	s6,168(sp)
    80005b3e:	7bca                	ld	s7,176(sp)
    80005b40:	7c6a                	ld	s8,184(sp)
    80005b42:	6c8e                	ld	s9,192(sp)
    80005b44:	6d2e                	ld	s10,200(sp)
    80005b46:	6dce                	ld	s11,208(sp)
    80005b48:	6e6e                	ld	t3,216(sp)
    80005b4a:	7e8e                	ld	t4,224(sp)
    80005b4c:	7f2e                	ld	t5,232(sp)
    80005b4e:	7fce                	ld	t6,240(sp)
    80005b50:	6111                	addi	sp,sp,256
    80005b52:	10200073          	sret
    80005b56:	00000013          	nop
    80005b5a:	00000013          	nop
    80005b5e:	0001                	nop

0000000080005b60 <timervec>:
    80005b60:	34051573          	csrrw	a0,mscratch,a0
    80005b64:	e10c                	sd	a1,0(a0)
    80005b66:	e510                	sd	a2,8(a0)
    80005b68:	e914                	sd	a3,16(a0)
    80005b6a:	710c                	ld	a1,32(a0)
    80005b6c:	7510                	ld	a2,40(a0)
    80005b6e:	6194                	ld	a3,0(a1)
    80005b70:	96b2                	add	a3,a3,a2
    80005b72:	e194                	sd	a3,0(a1)
    80005b74:	4589                	li	a1,2
    80005b76:	14459073          	csrw	sip,a1
    80005b7a:	6914                	ld	a3,16(a0)
    80005b7c:	6510                	ld	a2,8(a0)
    80005b7e:	610c                	ld	a1,0(a0)
    80005b80:	34051573          	csrrw	a0,mscratch,a0
    80005b84:	30200073          	mret
	...

0000000080005b8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b8a:	1141                	addi	sp,sp,-16
    80005b8c:	e422                	sd	s0,8(sp)
    80005b8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b90:	0c0007b7          	lui	a5,0xc000
    80005b94:	4705                	li	a4,1
    80005b96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b98:	c3d8                	sw	a4,4(a5)
}
    80005b9a:	6422                	ld	s0,8(sp)
    80005b9c:	0141                	addi	sp,sp,16
    80005b9e:	8082                	ret

0000000080005ba0 <plicinithart>:

void
plicinithart(void)
{
    80005ba0:	1141                	addi	sp,sp,-16
    80005ba2:	e406                	sd	ra,8(sp)
    80005ba4:	e022                	sd	s0,0(sp)
    80005ba6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ba8:	ffffc097          	auipc	ra,0xffffc
    80005bac:	de6080e7          	jalr	-538(ra) # 8000198e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005bb0:	0085171b          	slliw	a4,a0,0x8
    80005bb4:	0c0027b7          	lui	a5,0xc002
    80005bb8:	97ba                	add	a5,a5,a4
    80005bba:	40200713          	li	a4,1026
    80005bbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005bc2:	00d5151b          	slliw	a0,a0,0xd
    80005bc6:	0c2017b7          	lui	a5,0xc201
    80005bca:	953e                	add	a0,a0,a5
    80005bcc:	00052023          	sw	zero,0(a0)
}
    80005bd0:	60a2                	ld	ra,8(sp)
    80005bd2:	6402                	ld	s0,0(sp)
    80005bd4:	0141                	addi	sp,sp,16
    80005bd6:	8082                	ret

0000000080005bd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005bd8:	1141                	addi	sp,sp,-16
    80005bda:	e406                	sd	ra,8(sp)
    80005bdc:	e022                	sd	s0,0(sp)
    80005bde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005be0:	ffffc097          	auipc	ra,0xffffc
    80005be4:	dae080e7          	jalr	-594(ra) # 8000198e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005be8:	00d5179b          	slliw	a5,a0,0xd
    80005bec:	0c201537          	lui	a0,0xc201
    80005bf0:	953e                	add	a0,a0,a5
  return irq;
}
    80005bf2:	4148                	lw	a0,4(a0)
    80005bf4:	60a2                	ld	ra,8(sp)
    80005bf6:	6402                	ld	s0,0(sp)
    80005bf8:	0141                	addi	sp,sp,16
    80005bfa:	8082                	ret

0000000080005bfc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bfc:	1101                	addi	sp,sp,-32
    80005bfe:	ec06                	sd	ra,24(sp)
    80005c00:	e822                	sd	s0,16(sp)
    80005c02:	e426                	sd	s1,8(sp)
    80005c04:	1000                	addi	s0,sp,32
    80005c06:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c08:	ffffc097          	auipc	ra,0xffffc
    80005c0c:	d86080e7          	jalr	-634(ra) # 8000198e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c10:	00d5151b          	slliw	a0,a0,0xd
    80005c14:	0c2017b7          	lui	a5,0xc201
    80005c18:	97aa                	add	a5,a5,a0
    80005c1a:	c3c4                	sw	s1,4(a5)
}
    80005c1c:	60e2                	ld	ra,24(sp)
    80005c1e:	6442                	ld	s0,16(sp)
    80005c20:	64a2                	ld	s1,8(sp)
    80005c22:	6105                	addi	sp,sp,32
    80005c24:	8082                	ret

0000000080005c26 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c26:	1141                	addi	sp,sp,-16
    80005c28:	e406                	sd	ra,8(sp)
    80005c2a:	e022                	sd	s0,0(sp)
    80005c2c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c2e:	479d                	li	a5,7
    80005c30:	04a7cc63          	blt	a5,a0,80005c88 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005c34:	0001d797          	auipc	a5,0x1d
    80005c38:	3cc78793          	addi	a5,a5,972 # 80023000 <disk>
    80005c3c:	00a78733          	add	a4,a5,a0
    80005c40:	6789                	lui	a5,0x2
    80005c42:	97ba                	add	a5,a5,a4
    80005c44:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c48:	eba1                	bnez	a5,80005c98 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005c4a:	00451713          	slli	a4,a0,0x4
    80005c4e:	0001f797          	auipc	a5,0x1f
    80005c52:	3b27b783          	ld	a5,946(a5) # 80025000 <disk+0x2000>
    80005c56:	97ba                	add	a5,a5,a4
    80005c58:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005c5c:	0001d797          	auipc	a5,0x1d
    80005c60:	3a478793          	addi	a5,a5,932 # 80023000 <disk>
    80005c64:	97aa                	add	a5,a5,a0
    80005c66:	6509                	lui	a0,0x2
    80005c68:	953e                	add	a0,a0,a5
    80005c6a:	4785                	li	a5,1
    80005c6c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c70:	0001f517          	auipc	a0,0x1f
    80005c74:	3a850513          	addi	a0,a0,936 # 80025018 <disk+0x2018>
    80005c78:	ffffc097          	auipc	ra,0xffffc
    80005c7c:	6ce080e7          	jalr	1742(ra) # 80002346 <wakeup>
}
    80005c80:	60a2                	ld	ra,8(sp)
    80005c82:	6402                	ld	s0,0(sp)
    80005c84:	0141                	addi	sp,sp,16
    80005c86:	8082                	ret
    panic("virtio_disk_intr 1");
    80005c88:	00003517          	auipc	a0,0x3
    80005c8c:	b2050513          	addi	a0,a0,-1248 # 800087a8 <syscalls+0x330>
    80005c90:	ffffb097          	auipc	ra,0xffffb
    80005c94:	8b2080e7          	jalr	-1870(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005c98:	00003517          	auipc	a0,0x3
    80005c9c:	b2850513          	addi	a0,a0,-1240 # 800087c0 <syscalls+0x348>
    80005ca0:	ffffb097          	auipc	ra,0xffffb
    80005ca4:	8a2080e7          	jalr	-1886(ra) # 80000542 <panic>

0000000080005ca8 <virtio_disk_init>:
{
    80005ca8:	1101                	addi	sp,sp,-32
    80005caa:	ec06                	sd	ra,24(sp)
    80005cac:	e822                	sd	s0,16(sp)
    80005cae:	e426                	sd	s1,8(sp)
    80005cb0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005cb2:	00003597          	auipc	a1,0x3
    80005cb6:	b2658593          	addi	a1,a1,-1242 # 800087d8 <syscalls+0x360>
    80005cba:	0001f517          	auipc	a0,0x1f
    80005cbe:	3ee50513          	addi	a0,a0,1006 # 800250a8 <disk+0x20a8>
    80005cc2:	ffffb097          	auipc	ra,0xffffb
    80005cc6:	eac080e7          	jalr	-340(ra) # 80000b6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cca:	100017b7          	lui	a5,0x10001
    80005cce:	4398                	lw	a4,0(a5)
    80005cd0:	2701                	sext.w	a4,a4
    80005cd2:	747277b7          	lui	a5,0x74727
    80005cd6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005cda:	0ef71163          	bne	a4,a5,80005dbc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cde:	100017b7          	lui	a5,0x10001
    80005ce2:	43dc                	lw	a5,4(a5)
    80005ce4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ce6:	4705                	li	a4,1
    80005ce8:	0ce79a63          	bne	a5,a4,80005dbc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cec:	100017b7          	lui	a5,0x10001
    80005cf0:	479c                	lw	a5,8(a5)
    80005cf2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cf4:	4709                	li	a4,2
    80005cf6:	0ce79363          	bne	a5,a4,80005dbc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005cfa:	100017b7          	lui	a5,0x10001
    80005cfe:	47d8                	lw	a4,12(a5)
    80005d00:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d02:	554d47b7          	lui	a5,0x554d4
    80005d06:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d0a:	0af71963          	bne	a4,a5,80005dbc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d0e:	100017b7          	lui	a5,0x10001
    80005d12:	4705                	li	a4,1
    80005d14:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d16:	470d                	li	a4,3
    80005d18:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d1a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d1c:	c7ffe737          	lui	a4,0xc7ffe
    80005d20:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d24:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d26:	2701                	sext.w	a4,a4
    80005d28:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d2a:	472d                	li	a4,11
    80005d2c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d2e:	473d                	li	a4,15
    80005d30:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d32:	6705                	lui	a4,0x1
    80005d34:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d36:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d3a:	5bdc                	lw	a5,52(a5)
    80005d3c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d3e:	c7d9                	beqz	a5,80005dcc <virtio_disk_init+0x124>
  if(max < NUM)
    80005d40:	471d                	li	a4,7
    80005d42:	08f77d63          	bgeu	a4,a5,80005ddc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d46:	100014b7          	lui	s1,0x10001
    80005d4a:	47a1                	li	a5,8
    80005d4c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d4e:	6609                	lui	a2,0x2
    80005d50:	4581                	li	a1,0
    80005d52:	0001d517          	auipc	a0,0x1d
    80005d56:	2ae50513          	addi	a0,a0,686 # 80023000 <disk>
    80005d5a:	ffffb097          	auipc	ra,0xffffb
    80005d5e:	fa0080e7          	jalr	-96(ra) # 80000cfa <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d62:	0001d717          	auipc	a4,0x1d
    80005d66:	29e70713          	addi	a4,a4,670 # 80023000 <disk>
    80005d6a:	00c75793          	srli	a5,a4,0xc
    80005d6e:	2781                	sext.w	a5,a5
    80005d70:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005d72:	0001f797          	auipc	a5,0x1f
    80005d76:	28e78793          	addi	a5,a5,654 # 80025000 <disk+0x2000>
    80005d7a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005d7c:	0001d717          	auipc	a4,0x1d
    80005d80:	30470713          	addi	a4,a4,772 # 80023080 <disk+0x80>
    80005d84:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005d86:	0001e717          	auipc	a4,0x1e
    80005d8a:	27a70713          	addi	a4,a4,634 # 80024000 <disk+0x1000>
    80005d8e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005d90:	4705                	li	a4,1
    80005d92:	00e78c23          	sb	a4,24(a5)
    80005d96:	00e78ca3          	sb	a4,25(a5)
    80005d9a:	00e78d23          	sb	a4,26(a5)
    80005d9e:	00e78da3          	sb	a4,27(a5)
    80005da2:	00e78e23          	sb	a4,28(a5)
    80005da6:	00e78ea3          	sb	a4,29(a5)
    80005daa:	00e78f23          	sb	a4,30(a5)
    80005dae:	00e78fa3          	sb	a4,31(a5)
}
    80005db2:	60e2                	ld	ra,24(sp)
    80005db4:	6442                	ld	s0,16(sp)
    80005db6:	64a2                	ld	s1,8(sp)
    80005db8:	6105                	addi	sp,sp,32
    80005dba:	8082                	ret
    panic("could not find virtio disk");
    80005dbc:	00003517          	auipc	a0,0x3
    80005dc0:	a2c50513          	addi	a0,a0,-1492 # 800087e8 <syscalls+0x370>
    80005dc4:	ffffa097          	auipc	ra,0xffffa
    80005dc8:	77e080e7          	jalr	1918(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    80005dcc:	00003517          	auipc	a0,0x3
    80005dd0:	a3c50513          	addi	a0,a0,-1476 # 80008808 <syscalls+0x390>
    80005dd4:	ffffa097          	auipc	ra,0xffffa
    80005dd8:	76e080e7          	jalr	1902(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    80005ddc:	00003517          	auipc	a0,0x3
    80005de0:	a4c50513          	addi	a0,a0,-1460 # 80008828 <syscalls+0x3b0>
    80005de4:	ffffa097          	auipc	ra,0xffffa
    80005de8:	75e080e7          	jalr	1886(ra) # 80000542 <panic>

0000000080005dec <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005dec:	7175                	addi	sp,sp,-144
    80005dee:	e506                	sd	ra,136(sp)
    80005df0:	e122                	sd	s0,128(sp)
    80005df2:	fca6                	sd	s1,120(sp)
    80005df4:	f8ca                	sd	s2,112(sp)
    80005df6:	f4ce                	sd	s3,104(sp)
    80005df8:	f0d2                	sd	s4,96(sp)
    80005dfa:	ecd6                	sd	s5,88(sp)
    80005dfc:	e8da                	sd	s6,80(sp)
    80005dfe:	e4de                	sd	s7,72(sp)
    80005e00:	e0e2                	sd	s8,64(sp)
    80005e02:	fc66                	sd	s9,56(sp)
    80005e04:	f86a                	sd	s10,48(sp)
    80005e06:	f46e                	sd	s11,40(sp)
    80005e08:	0900                	addi	s0,sp,144
    80005e0a:	8aaa                	mv	s5,a0
    80005e0c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e0e:	00c52c83          	lw	s9,12(a0)
    80005e12:	001c9c9b          	slliw	s9,s9,0x1
    80005e16:	1c82                	slli	s9,s9,0x20
    80005e18:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e1c:	0001f517          	auipc	a0,0x1f
    80005e20:	28c50513          	addi	a0,a0,652 # 800250a8 <disk+0x20a8>
    80005e24:	ffffb097          	auipc	ra,0xffffb
    80005e28:	dda080e7          	jalr	-550(ra) # 80000bfe <acquire>
  for(int i = 0; i < 3; i++){
    80005e2c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e2e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005e30:	0001dc17          	auipc	s8,0x1d
    80005e34:	1d0c0c13          	addi	s8,s8,464 # 80023000 <disk>
    80005e38:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005e3a:	4b0d                	li	s6,3
    80005e3c:	a0ad                	j	80005ea6 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005e3e:	00fc0733          	add	a4,s8,a5
    80005e42:	975e                	add	a4,a4,s7
    80005e44:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005e48:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005e4a:	0207c563          	bltz	a5,80005e74 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e4e:	2905                	addiw	s2,s2,1
    80005e50:	0611                	addi	a2,a2,4
    80005e52:	19690d63          	beq	s2,s6,80005fec <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005e56:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005e58:	0001f717          	auipc	a4,0x1f
    80005e5c:	1c070713          	addi	a4,a4,448 # 80025018 <disk+0x2018>
    80005e60:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005e62:	00074683          	lbu	a3,0(a4)
    80005e66:	fee1                	bnez	a3,80005e3e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e68:	2785                	addiw	a5,a5,1
    80005e6a:	0705                	addi	a4,a4,1
    80005e6c:	fe979be3          	bne	a5,s1,80005e62 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e70:	57fd                	li	a5,-1
    80005e72:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005e74:	01205d63          	blez	s2,80005e8e <virtio_disk_rw+0xa2>
    80005e78:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005e7a:	000a2503          	lw	a0,0(s4)
    80005e7e:	00000097          	auipc	ra,0x0
    80005e82:	da8080e7          	jalr	-600(ra) # 80005c26 <free_desc>
      for(int j = 0; j < i; j++)
    80005e86:	2d85                	addiw	s11,s11,1
    80005e88:	0a11                	addi	s4,s4,4
    80005e8a:	ffb918e3          	bne	s2,s11,80005e7a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005e8e:	0001f597          	auipc	a1,0x1f
    80005e92:	21a58593          	addi	a1,a1,538 # 800250a8 <disk+0x20a8>
    80005e96:	0001f517          	auipc	a0,0x1f
    80005e9a:	18250513          	addi	a0,a0,386 # 80025018 <disk+0x2018>
    80005e9e:	ffffc097          	auipc	ra,0xffffc
    80005ea2:	328080e7          	jalr	808(ra) # 800021c6 <sleep>
  for(int i = 0; i < 3; i++){
    80005ea6:	f8040a13          	addi	s4,s0,-128
{
    80005eaa:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005eac:	894e                	mv	s2,s3
    80005eae:	b765                	j	80005e56 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005eb0:	0001f717          	auipc	a4,0x1f
    80005eb4:	15073703          	ld	a4,336(a4) # 80025000 <disk+0x2000>
    80005eb8:	973e                	add	a4,a4,a5
    80005eba:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005ebe:	0001d517          	auipc	a0,0x1d
    80005ec2:	14250513          	addi	a0,a0,322 # 80023000 <disk>
    80005ec6:	0001f717          	auipc	a4,0x1f
    80005eca:	13a70713          	addi	a4,a4,314 # 80025000 <disk+0x2000>
    80005ece:	6314                	ld	a3,0(a4)
    80005ed0:	96be                	add	a3,a3,a5
    80005ed2:	00c6d603          	lhu	a2,12(a3)
    80005ed6:	00166613          	ori	a2,a2,1
    80005eda:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005ede:	f8842683          	lw	a3,-120(s0)
    80005ee2:	6310                	ld	a2,0(a4)
    80005ee4:	97b2                	add	a5,a5,a2
    80005ee6:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80005eea:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    80005eee:	0612                	slli	a2,a2,0x4
    80005ef0:	962a                	add	a2,a2,a0
    80005ef2:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005ef6:	00469793          	slli	a5,a3,0x4
    80005efa:	630c                	ld	a1,0(a4)
    80005efc:	95be                	add	a1,a1,a5
    80005efe:	6689                	lui	a3,0x2
    80005f00:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80005f04:	96ca                	add	a3,a3,s2
    80005f06:	96aa                	add	a3,a3,a0
    80005f08:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80005f0a:	6314                	ld	a3,0(a4)
    80005f0c:	96be                	add	a3,a3,a5
    80005f0e:	4585                	li	a1,1
    80005f10:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005f12:	6314                	ld	a3,0(a4)
    80005f14:	96be                	add	a3,a3,a5
    80005f16:	4509                	li	a0,2
    80005f18:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80005f1c:	6314                	ld	a3,0(a4)
    80005f1e:	97b6                	add	a5,a5,a3
    80005f20:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005f24:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80005f28:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80005f2c:	6714                	ld	a3,8(a4)
    80005f2e:	0026d783          	lhu	a5,2(a3)
    80005f32:	8b9d                	andi	a5,a5,7
    80005f34:	0789                	addi	a5,a5,2
    80005f36:	0786                	slli	a5,a5,0x1
    80005f38:	97b6                	add	a5,a5,a3
    80005f3a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    80005f3e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80005f42:	6718                	ld	a4,8(a4)
    80005f44:	00275783          	lhu	a5,2(a4)
    80005f48:	2785                	addiw	a5,a5,1
    80005f4a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005f4e:	100017b7          	lui	a5,0x10001
    80005f52:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005f56:	004aa783          	lw	a5,4(s5)
    80005f5a:	02b79163          	bne	a5,a1,80005f7c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80005f5e:	0001f917          	auipc	s2,0x1f
    80005f62:	14a90913          	addi	s2,s2,330 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80005f66:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005f68:	85ca                	mv	a1,s2
    80005f6a:	8556                	mv	a0,s5
    80005f6c:	ffffc097          	auipc	ra,0xffffc
    80005f70:	25a080e7          	jalr	602(ra) # 800021c6 <sleep>
  while(b->disk == 1) {
    80005f74:	004aa783          	lw	a5,4(s5)
    80005f78:	fe9788e3          	beq	a5,s1,80005f68 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80005f7c:	f8042483          	lw	s1,-128(s0)
    80005f80:	20048793          	addi	a5,s1,512
    80005f84:	00479713          	slli	a4,a5,0x4
    80005f88:	0001d797          	auipc	a5,0x1d
    80005f8c:	07878793          	addi	a5,a5,120 # 80023000 <disk>
    80005f90:	97ba                	add	a5,a5,a4
    80005f92:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80005f96:	0001f917          	auipc	s2,0x1f
    80005f9a:	06a90913          	addi	s2,s2,106 # 80025000 <disk+0x2000>
    80005f9e:	a019                	j	80005fa4 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80005fa0:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80005fa4:	8526                	mv	a0,s1
    80005fa6:	00000097          	auipc	ra,0x0
    80005faa:	c80080e7          	jalr	-896(ra) # 80005c26 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80005fae:	0492                	slli	s1,s1,0x4
    80005fb0:	00093783          	ld	a5,0(s2)
    80005fb4:	94be                	add	s1,s1,a5
    80005fb6:	00c4d783          	lhu	a5,12(s1)
    80005fba:	8b85                	andi	a5,a5,1
    80005fbc:	f3f5                	bnez	a5,80005fa0 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005fbe:	0001f517          	auipc	a0,0x1f
    80005fc2:	0ea50513          	addi	a0,a0,234 # 800250a8 <disk+0x20a8>
    80005fc6:	ffffb097          	auipc	ra,0xffffb
    80005fca:	cec080e7          	jalr	-788(ra) # 80000cb2 <release>
}
    80005fce:	60aa                	ld	ra,136(sp)
    80005fd0:	640a                	ld	s0,128(sp)
    80005fd2:	74e6                	ld	s1,120(sp)
    80005fd4:	7946                	ld	s2,112(sp)
    80005fd6:	79a6                	ld	s3,104(sp)
    80005fd8:	7a06                	ld	s4,96(sp)
    80005fda:	6ae6                	ld	s5,88(sp)
    80005fdc:	6b46                	ld	s6,80(sp)
    80005fde:	6ba6                	ld	s7,72(sp)
    80005fe0:	6c06                	ld	s8,64(sp)
    80005fe2:	7ce2                	ld	s9,56(sp)
    80005fe4:	7d42                	ld	s10,48(sp)
    80005fe6:	7da2                	ld	s11,40(sp)
    80005fe8:	6149                	addi	sp,sp,144
    80005fea:	8082                	ret
  if(write)
    80005fec:	01a037b3          	snez	a5,s10
    80005ff0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80005ff4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80005ff8:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80005ffc:	f8042483          	lw	s1,-128(s0)
    80006000:	00449913          	slli	s2,s1,0x4
    80006004:	0001f997          	auipc	s3,0x1f
    80006008:	ffc98993          	addi	s3,s3,-4 # 80025000 <disk+0x2000>
    8000600c:	0009ba03          	ld	s4,0(s3)
    80006010:	9a4a                	add	s4,s4,s2
    80006012:	f7040513          	addi	a0,s0,-144
    80006016:	ffffb097          	auipc	ra,0xffffb
    8000601a:	0a4080e7          	jalr	164(ra) # 800010ba <kvmpa>
    8000601e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006022:	0009b783          	ld	a5,0(s3)
    80006026:	97ca                	add	a5,a5,s2
    80006028:	4741                	li	a4,16
    8000602a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000602c:	0009b783          	ld	a5,0(s3)
    80006030:	97ca                	add	a5,a5,s2
    80006032:	4705                	li	a4,1
    80006034:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006038:	f8442783          	lw	a5,-124(s0)
    8000603c:	0009b703          	ld	a4,0(s3)
    80006040:	974a                	add	a4,a4,s2
    80006042:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006046:	0792                	slli	a5,a5,0x4
    80006048:	0009b703          	ld	a4,0(s3)
    8000604c:	973e                	add	a4,a4,a5
    8000604e:	058a8693          	addi	a3,s5,88
    80006052:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006054:	0009b703          	ld	a4,0(s3)
    80006058:	973e                	add	a4,a4,a5
    8000605a:	40000693          	li	a3,1024
    8000605e:	c714                	sw	a3,8(a4)
  if(write)
    80006060:	e40d18e3          	bnez	s10,80005eb0 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006064:	0001f717          	auipc	a4,0x1f
    80006068:	f9c73703          	ld	a4,-100(a4) # 80025000 <disk+0x2000>
    8000606c:	973e                	add	a4,a4,a5
    8000606e:	4689                	li	a3,2
    80006070:	00d71623          	sh	a3,12(a4)
    80006074:	b5a9                	j	80005ebe <virtio_disk_rw+0xd2>

0000000080006076 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006076:	1101                	addi	sp,sp,-32
    80006078:	ec06                	sd	ra,24(sp)
    8000607a:	e822                	sd	s0,16(sp)
    8000607c:	e426                	sd	s1,8(sp)
    8000607e:	e04a                	sd	s2,0(sp)
    80006080:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006082:	0001f517          	auipc	a0,0x1f
    80006086:	02650513          	addi	a0,a0,38 # 800250a8 <disk+0x20a8>
    8000608a:	ffffb097          	auipc	ra,0xffffb
    8000608e:	b74080e7          	jalr	-1164(ra) # 80000bfe <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006092:	0001f717          	auipc	a4,0x1f
    80006096:	f6e70713          	addi	a4,a4,-146 # 80025000 <disk+0x2000>
    8000609a:	02075783          	lhu	a5,32(a4)
    8000609e:	6b18                	ld	a4,16(a4)
    800060a0:	00275683          	lhu	a3,2(a4)
    800060a4:	8ebd                	xor	a3,a3,a5
    800060a6:	8a9d                	andi	a3,a3,7
    800060a8:	cab9                	beqz	a3,800060fe <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800060aa:	0001d917          	auipc	s2,0x1d
    800060ae:	f5690913          	addi	s2,s2,-170 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800060b2:	0001f497          	auipc	s1,0x1f
    800060b6:	f4e48493          	addi	s1,s1,-178 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800060ba:	078e                	slli	a5,a5,0x3
    800060bc:	97ba                	add	a5,a5,a4
    800060be:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800060c0:	20078713          	addi	a4,a5,512
    800060c4:	0712                	slli	a4,a4,0x4
    800060c6:	974a                	add	a4,a4,s2
    800060c8:	03074703          	lbu	a4,48(a4)
    800060cc:	ef21                	bnez	a4,80006124 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800060ce:	20078793          	addi	a5,a5,512
    800060d2:	0792                	slli	a5,a5,0x4
    800060d4:	97ca                	add	a5,a5,s2
    800060d6:	7798                	ld	a4,40(a5)
    800060d8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800060dc:	7788                	ld	a0,40(a5)
    800060de:	ffffc097          	auipc	ra,0xffffc
    800060e2:	268080e7          	jalr	616(ra) # 80002346 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800060e6:	0204d783          	lhu	a5,32(s1)
    800060ea:	2785                	addiw	a5,a5,1
    800060ec:	8b9d                	andi	a5,a5,7
    800060ee:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800060f2:	6898                	ld	a4,16(s1)
    800060f4:	00275683          	lhu	a3,2(a4)
    800060f8:	8a9d                	andi	a3,a3,7
    800060fa:	fcf690e3          	bne	a3,a5,800060ba <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060fe:	10001737          	lui	a4,0x10001
    80006102:	533c                	lw	a5,96(a4)
    80006104:	8b8d                	andi	a5,a5,3
    80006106:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006108:	0001f517          	auipc	a0,0x1f
    8000610c:	fa050513          	addi	a0,a0,-96 # 800250a8 <disk+0x20a8>
    80006110:	ffffb097          	auipc	ra,0xffffb
    80006114:	ba2080e7          	jalr	-1118(ra) # 80000cb2 <release>
}
    80006118:	60e2                	ld	ra,24(sp)
    8000611a:	6442                	ld	s0,16(sp)
    8000611c:	64a2                	ld	s1,8(sp)
    8000611e:	6902                	ld	s2,0(sp)
    80006120:	6105                	addi	sp,sp,32
    80006122:	8082                	ret
      panic("virtio_disk_intr status");
    80006124:	00002517          	auipc	a0,0x2
    80006128:	72450513          	addi	a0,a0,1828 # 80008848 <syscalls+0x3d0>
    8000612c:	ffffa097          	auipc	ra,0xffffa
    80006130:	416080e7          	jalr	1046(ra) # 80000542 <panic>
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
