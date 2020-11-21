
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
    80000016:	06e000ef          	jal	ra,80000084 <start>

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
  int interval = 10000; // cycles; about 1ms in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	6709                	lui	a4,0x2
    8000003a:	71070713          	addi	a4,a4,1808 # 2710 <_entry-0x7fffd8f0>
    8000003e:	963a                	add	a2,a2,a4
    80000040:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000042:	0057979b          	slliw	a5,a5,0x5
    80000046:	078e                	slli	a5,a5,0x3
    80000048:	00009617          	auipc	a2,0x9
    8000004c:	fe860613          	addi	a2,a2,-24 # 80009030 <mscratch0>
    80000050:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000052:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000054:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000056:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005a:	00006797          	auipc	a5,0x6
    8000005e:	dc678793          	addi	a5,a5,-570 # 80005e20 <timervec>
    80000062:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000066:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006a:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000006e:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000072:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000076:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007a:	30479073          	csrw	mie,a5
}
    8000007e:	6422                	ld	s0,8(sp)
    80000080:	0141                	addi	sp,sp,16
    80000082:	8082                	ret

0000000080000084 <start>:
{
    80000084:	1141                	addi	sp,sp,-16
    80000086:	e406                	sd	ra,8(sp)
    80000088:	e022                	sd	s0,0(sp)
    8000008a:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008c:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000090:	7779                	lui	a4,0xffffe
    80000092:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000096:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000098:	6705                	lui	a4,0x1
    8000009a:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000009e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a0:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a4:	00001797          	auipc	a5,0x1
    800000a8:	e0278793          	addi	a5,a5,-510 # 80000ea6 <main>
    800000ac:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b0:	4781                	li	a5,0
    800000b2:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b6:	67c1                	lui	a5,0x10
    800000b8:	17fd                	addi	a5,a5,-1
    800000ba:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000be:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c2:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c6:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000ca:	10479073          	csrw	sie,a5
  timerinit();
    800000ce:	00000097          	auipc	ra,0x0
    800000d2:	f4e080e7          	jalr	-178(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d6:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000da:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000dc:	823e                	mv	tp,a5
  asm volatile("mret");
    800000de:	30200073          	mret
}
    800000e2:	60a2                	ld	ra,8(sp)
    800000e4:	6402                	ld	s0,0(sp)
    800000e6:	0141                	addi	sp,sp,16
    800000e8:	8082                	ret

00000000800000ea <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ea:	715d                	addi	sp,sp,-80
    800000ec:	e486                	sd	ra,72(sp)
    800000ee:	e0a2                	sd	s0,64(sp)
    800000f0:	fc26                	sd	s1,56(sp)
    800000f2:	f84a                	sd	s2,48(sp)
    800000f4:	f44e                	sd	s3,40(sp)
    800000f6:	f052                	sd	s4,32(sp)
    800000f8:	ec56                	sd	s5,24(sp)
    800000fa:	0880                	addi	s0,sp,80
    800000fc:	8a2a                	mv	s4,a0
    800000fe:	84ae                	mv	s1,a1
    80000100:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000102:	00011517          	auipc	a0,0x11
    80000106:	72e50513          	addi	a0,a0,1838 # 80011830 <cons>
    8000010a:	00001097          	auipc	ra,0x1
    8000010e:	af2080e7          	jalr	-1294(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80000112:	05305b63          	blez	s3,80000168 <consolewrite+0x7e>
    80000116:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000118:	5afd                	li	s5,-1
    8000011a:	4685                	li	a3,1
    8000011c:	8626                	mv	a2,s1
    8000011e:	85d2                	mv	a1,s4
    80000120:	fbf40513          	addi	a0,s0,-65
    80000124:	00002097          	auipc	ra,0x2
    80000128:	5d2080e7          	jalr	1490(ra) # 800026f6 <either_copyin>
    8000012c:	01550c63          	beq	a0,s5,80000144 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000130:	fbf44503          	lbu	a0,-65(s0)
    80000134:	00000097          	auipc	ra,0x0
    80000138:	796080e7          	jalr	1942(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    8000013c:	2905                	addiw	s2,s2,1
    8000013e:	0485                	addi	s1,s1,1
    80000140:	fd299de3          	bne	s3,s2,8000011a <consolewrite+0x30>
  }
  release(&cons.lock);
    80000144:	00011517          	auipc	a0,0x11
    80000148:	6ec50513          	addi	a0,a0,1772 # 80011830 <cons>
    8000014c:	00001097          	auipc	ra,0x1
    80000150:	b64080e7          	jalr	-1180(ra) # 80000cb0 <release>

  return i;
}
    80000154:	854a                	mv	a0,s2
    80000156:	60a6                	ld	ra,72(sp)
    80000158:	6406                	ld	s0,64(sp)
    8000015a:	74e2                	ld	s1,56(sp)
    8000015c:	7942                	ld	s2,48(sp)
    8000015e:	79a2                	ld	s3,40(sp)
    80000160:	7a02                	ld	s4,32(sp)
    80000162:	6ae2                	ld	s5,24(sp)
    80000164:	6161                	addi	sp,sp,80
    80000166:	8082                	ret
  for(i = 0; i < n; i++){
    80000168:	4901                	li	s2,0
    8000016a:	bfe9                	j	80000144 <consolewrite+0x5a>

000000008000016c <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016c:	7159                	addi	sp,sp,-112
    8000016e:	f486                	sd	ra,104(sp)
    80000170:	f0a2                	sd	s0,96(sp)
    80000172:	eca6                	sd	s1,88(sp)
    80000174:	e8ca                	sd	s2,80(sp)
    80000176:	e4ce                	sd	s3,72(sp)
    80000178:	e0d2                	sd	s4,64(sp)
    8000017a:	fc56                	sd	s5,56(sp)
    8000017c:	f85a                	sd	s6,48(sp)
    8000017e:	f45e                	sd	s7,40(sp)
    80000180:	f062                	sd	s8,32(sp)
    80000182:	ec66                	sd	s9,24(sp)
    80000184:	e86a                	sd	s10,16(sp)
    80000186:	1880                	addi	s0,sp,112
    80000188:	8aaa                	mv	s5,a0
    8000018a:	8a2e                	mv	s4,a1
    8000018c:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000018e:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000192:	00011517          	auipc	a0,0x11
    80000196:	69e50513          	addi	a0,a0,1694 # 80011830 <cons>
    8000019a:	00001097          	auipc	ra,0x1
    8000019e:	a62080e7          	jalr	-1438(ra) # 80000bfc <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a2:	00011497          	auipc	s1,0x11
    800001a6:	68e48493          	addi	s1,s1,1678 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001aa:	00011917          	auipc	s2,0x11
    800001ae:	71e90913          	addi	s2,s2,1822 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b2:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b4:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b6:	4ca9                	li	s9,10
  while(n > 0){
    800001b8:	07305863          	blez	s3,80000228 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001bc:	0984a783          	lw	a5,152(s1)
    800001c0:	09c4a703          	lw	a4,156(s1)
    800001c4:	02f71463          	bne	a4,a5,800001ec <consoleread+0x80>
      if(myproc()->killed){
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	92a080e7          	jalr	-1750(ra) # 80001af2 <myproc>
    800001d0:	591c                	lw	a5,48(a0)
    800001d2:	e7b5                	bnez	a5,8000023e <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d4:	85a6                	mv	a1,s1
    800001d6:	854a                	mv	a0,s2
    800001d8:	00002097          	auipc	ra,0x2
    800001dc:	238080e7          	jalr	568(ra) # 80002410 <sleep>
    while(cons.r == cons.w){
    800001e0:	0984a783          	lw	a5,152(s1)
    800001e4:	09c4a703          	lw	a4,156(s1)
    800001e8:	fef700e3          	beq	a4,a5,800001c8 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ec:	0017871b          	addiw	a4,a5,1
    800001f0:	08e4ac23          	sw	a4,152(s1)
    800001f4:	07f7f713          	andi	a4,a5,127
    800001f8:	9726                	add	a4,a4,s1
    800001fa:	01874703          	lbu	a4,24(a4)
    800001fe:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000202:	077d0563          	beq	s10,s7,8000026c <consoleread+0x100>
    cbuf = c;
    80000206:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	f9f40613          	addi	a2,s0,-97
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	48c080e7          	jalr	1164(ra) # 800026a0 <either_copyout>
    8000021c:	01850663          	beq	a0,s8,80000228 <consoleread+0xbc>
    dst++;
    80000220:	0a05                	addi	s4,s4,1
    --n;
    80000222:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000224:	f99d1ae3          	bne	s10,s9,800001b8 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	60850513          	addi	a0,a0,1544 # 80011830 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a80080e7          	jalr	-1408(ra) # 80000cb0 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xe4>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	5f250513          	addi	a0,a0,1522 # 80011830 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a6a080e7          	jalr	-1430(ra) # 80000cb0 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	70a6                	ld	ra,104(sp)
    80000252:	7406                	ld	s0,96(sp)
    80000254:	64e6                	ld	s1,88(sp)
    80000256:	6946                	ld	s2,80(sp)
    80000258:	69a6                	ld	s3,72(sp)
    8000025a:	6a06                	ld	s4,64(sp)
    8000025c:	7ae2                	ld	s5,56(sp)
    8000025e:	7b42                	ld	s6,48(sp)
    80000260:	7ba2                	ld	s7,40(sp)
    80000262:	7c02                	ld	s8,32(sp)
    80000264:	6ce2                	ld	s9,24(sp)
    80000266:	6d42                	ld	s10,16(sp)
    80000268:	6165                	addi	sp,sp,112
    8000026a:	8082                	ret
      if(n < target){
    8000026c:	0009871b          	sext.w	a4,s3
    80000270:	fb677ce3          	bgeu	a4,s6,80000228 <consoleread+0xbc>
        cons.r--;
    80000274:	00011717          	auipc	a4,0x11
    80000278:	64f72a23          	sw	a5,1620(a4) # 800118c8 <cons+0x98>
    8000027c:	b775                	j	80000228 <consoleread+0xbc>

000000008000027e <consputc>:
{
    8000027e:	1141                	addi	sp,sp,-16
    80000280:	e406                	sd	ra,8(sp)
    80000282:	e022                	sd	s0,0(sp)
    80000284:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000286:	10000793          	li	a5,256
    8000028a:	00f50a63          	beq	a0,a5,8000029e <consputc+0x20>
    uartputc_sync(c);
    8000028e:	00000097          	auipc	ra,0x0
    80000292:	55e080e7          	jalr	1374(ra) # 800007ec <uartputc_sync>
}
    80000296:	60a2                	ld	ra,8(sp)
    80000298:	6402                	ld	s0,0(sp)
    8000029a:	0141                	addi	sp,sp,16
    8000029c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	54c080e7          	jalr	1356(ra) # 800007ec <uartputc_sync>
    800002a8:	02000513          	li	a0,32
    800002ac:	00000097          	auipc	ra,0x0
    800002b0:	540080e7          	jalr	1344(ra) # 800007ec <uartputc_sync>
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	536080e7          	jalr	1334(ra) # 800007ec <uartputc_sync>
    800002be:	bfe1                	j	80000296 <consputc+0x18>

00000000800002c0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c0:	1101                	addi	sp,sp,-32
    800002c2:	ec06                	sd	ra,24(sp)
    800002c4:	e822                	sd	s0,16(sp)
    800002c6:	e426                	sd	s1,8(sp)
    800002c8:	e04a                	sd	s2,0(sp)
    800002ca:	1000                	addi	s0,sp,32
    800002cc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002ce:	00011517          	auipc	a0,0x11
    800002d2:	56250513          	addi	a0,a0,1378 # 80011830 <cons>
    800002d6:	00001097          	auipc	ra,0x1
    800002da:	926080e7          	jalr	-1754(ra) # 80000bfc <acquire>

  switch(c){
    800002de:	47d5                	li	a5,21
    800002e0:	0af48663          	beq	s1,a5,8000038c <consoleintr+0xcc>
    800002e4:	0297ca63          	blt	a5,s1,80000318 <consoleintr+0x58>
    800002e8:	47a1                	li	a5,8
    800002ea:	0ef48763          	beq	s1,a5,800003d8 <consoleintr+0x118>
    800002ee:	47c1                	li	a5,16
    800002f0:	10f49a63          	bne	s1,a5,80000404 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f4:	00002097          	auipc	ra,0x2
    800002f8:	458080e7          	jalr	1112(ra) # 8000274c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fc:	00011517          	auipc	a0,0x11
    80000300:	53450513          	addi	a0,a0,1332 # 80011830 <cons>
    80000304:	00001097          	auipc	ra,0x1
    80000308:	9ac080e7          	jalr	-1620(ra) # 80000cb0 <release>
}
    8000030c:	60e2                	ld	ra,24(sp)
    8000030e:	6442                	ld	s0,16(sp)
    80000310:	64a2                	ld	s1,8(sp)
    80000312:	6902                	ld	s2,0(sp)
    80000314:	6105                	addi	sp,sp,32
    80000316:	8082                	ret
  switch(c){
    80000318:	07f00793          	li	a5,127
    8000031c:	0af48e63          	beq	s1,a5,800003d8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000320:	00011717          	auipc	a4,0x11
    80000324:	51070713          	addi	a4,a4,1296 # 80011830 <cons>
    80000328:	0a072783          	lw	a5,160(a4)
    8000032c:	09872703          	lw	a4,152(a4)
    80000330:	9f99                	subw	a5,a5,a4
    80000332:	07f00713          	li	a4,127
    80000336:	fcf763e3          	bltu	a4,a5,800002fc <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033a:	47b5                	li	a5,13
    8000033c:	0cf48763          	beq	s1,a5,8000040a <consoleintr+0x14a>
      consputc(c);
    80000340:	8526                	mv	a0,s1
    80000342:	00000097          	auipc	ra,0x0
    80000346:	f3c080e7          	jalr	-196(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034a:	00011797          	auipc	a5,0x11
    8000034e:	4e678793          	addi	a5,a5,1254 # 80011830 <cons>
    80000352:	0a07a703          	lw	a4,160(a5)
    80000356:	0017069b          	addiw	a3,a4,1
    8000035a:	0006861b          	sext.w	a2,a3
    8000035e:	0ad7a023          	sw	a3,160(a5)
    80000362:	07f77713          	andi	a4,a4,127
    80000366:	97ba                	add	a5,a5,a4
    80000368:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036c:	47a9                	li	a5,10
    8000036e:	0cf48563          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000372:	4791                	li	a5,4
    80000374:	0cf48263          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000378:	00011797          	auipc	a5,0x11
    8000037c:	5507a783          	lw	a5,1360(a5) # 800118c8 <cons+0x98>
    80000380:	0807879b          	addiw	a5,a5,128
    80000384:	f6f61ce3          	bne	a2,a5,800002fc <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000388:	863e                	mv	a2,a5
    8000038a:	a07d                	j	80000438 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038c:	00011717          	auipc	a4,0x11
    80000390:	4a470713          	addi	a4,a4,1188 # 80011830 <cons>
    80000394:	0a072783          	lw	a5,160(a4)
    80000398:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039c:	00011497          	auipc	s1,0x11
    800003a0:	49448493          	addi	s1,s1,1172 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a4:	4929                	li	s2,10
    800003a6:	f4f70be3          	beq	a4,a5,800002fc <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003aa:	37fd                	addiw	a5,a5,-1
    800003ac:	07f7f713          	andi	a4,a5,127
    800003b0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b2:	01874703          	lbu	a4,24(a4)
    800003b6:	f52703e3          	beq	a4,s2,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ba:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003be:	10000513          	li	a0,256
    800003c2:	00000097          	auipc	ra,0x0
    800003c6:	ebc080e7          	jalr	-324(ra) # 8000027e <consputc>
    while(cons.e != cons.w &&
    800003ca:	0a04a783          	lw	a5,160(s1)
    800003ce:	09c4a703          	lw	a4,156(s1)
    800003d2:	fcf71ce3          	bne	a4,a5,800003aa <consoleintr+0xea>
    800003d6:	b71d                	j	800002fc <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	45870713          	addi	a4,a4,1112 # 80011830 <cons>
    800003e0:	0a072783          	lw	a5,160(a4)
    800003e4:	09c72703          	lw	a4,156(a4)
    800003e8:	f0f70ae3          	beq	a4,a5,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ec:	37fd                	addiw	a5,a5,-1
    800003ee:	00011717          	auipc	a4,0x11
    800003f2:	4ef72123          	sw	a5,1250(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f6:	10000513          	li	a0,256
    800003fa:	00000097          	auipc	ra,0x0
    800003fe:	e84080e7          	jalr	-380(ra) # 8000027e <consputc>
    80000402:	bded                	j	800002fc <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000404:	ee048ce3          	beqz	s1,800002fc <consoleintr+0x3c>
    80000408:	bf21                	j	80000320 <consoleintr+0x60>
      consputc(c);
    8000040a:	4529                	li	a0,10
    8000040c:	00000097          	auipc	ra,0x0
    80000410:	e72080e7          	jalr	-398(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000414:	00011797          	auipc	a5,0x11
    80000418:	41c78793          	addi	a5,a5,1052 # 80011830 <cons>
    8000041c:	0a07a703          	lw	a4,160(a5)
    80000420:	0017069b          	addiw	a3,a4,1
    80000424:	0006861b          	sext.w	a2,a3
    80000428:	0ad7a023          	sw	a3,160(a5)
    8000042c:	07f77713          	andi	a4,a4,127
    80000430:	97ba                	add	a5,a5,a4
    80000432:	4729                	li	a4,10
    80000434:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000438:	00011797          	auipc	a5,0x11
    8000043c:	48c7aa23          	sw	a2,1172(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000440:	00011517          	auipc	a0,0x11
    80000444:	48850513          	addi	a0,a0,1160 # 800118c8 <cons+0x98>
    80000448:	00002097          	auipc	ra,0x2
    8000044c:	162080e7          	jalr	354(ra) # 800025aa <wakeup>
    80000450:	b575                	j	800002fc <consoleintr+0x3c>

0000000080000452 <consoleinit>:

void
consoleinit(void)
{
    80000452:	1141                	addi	sp,sp,-16
    80000454:	e406                	sd	ra,8(sp)
    80000456:	e022                	sd	s0,0(sp)
    80000458:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045a:	00008597          	auipc	a1,0x8
    8000045e:	bb658593          	addi	a1,a1,-1098 # 80008010 <etext+0x10>
    80000462:	00011517          	auipc	a0,0x11
    80000466:	3ce50513          	addi	a0,a0,974 # 80011830 <cons>
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	702080e7          	jalr	1794(ra) # 80000b6c <initlock>

  uartinit();
    80000472:	00000097          	auipc	ra,0x0
    80000476:	32a080e7          	jalr	810(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047a:	00022797          	auipc	a5,0x22
    8000047e:	13678793          	addi	a5,a5,310 # 800225b0 <devsw>
    80000482:	00000717          	auipc	a4,0x0
    80000486:	cea70713          	addi	a4,a4,-790 # 8000016c <consoleread>
    8000048a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048c:	00000717          	auipc	a4,0x0
    80000490:	c5e70713          	addi	a4,a4,-930 # 800000ea <consolewrite>
    80000494:	ef98                	sd	a4,24(a5)
}
    80000496:	60a2                	ld	ra,8(sp)
    80000498:	6402                	ld	s0,0(sp)
    8000049a:	0141                	addi	sp,sp,16
    8000049c:	8082                	ret

000000008000049e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049e:	7179                	addi	sp,sp,-48
    800004a0:	f406                	sd	ra,40(sp)
    800004a2:	f022                	sd	s0,32(sp)
    800004a4:	ec26                	sd	s1,24(sp)
    800004a6:	e84a                	sd	s2,16(sp)
    800004a8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004aa:	c219                	beqz	a2,800004b0 <printint+0x12>
    800004ac:	08054663          	bltz	a0,80000538 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b0:	2501                	sext.w	a0,a0
    800004b2:	4881                	li	a7,0
    800004b4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ba:	2581                	sext.w	a1,a1
    800004bc:	00008617          	auipc	a2,0x8
    800004c0:	b8460613          	addi	a2,a2,-1148 # 80008040 <digits>
    800004c4:	883a                	mv	a6,a4
    800004c6:	2705                	addiw	a4,a4,1
    800004c8:	02b577bb          	remuw	a5,a0,a1
    800004cc:	1782                	slli	a5,a5,0x20
    800004ce:	9381                	srli	a5,a5,0x20
    800004d0:	97b2                	add	a5,a5,a2
    800004d2:	0007c783          	lbu	a5,0(a5)
    800004d6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004da:	0005079b          	sext.w	a5,a0
    800004de:	02b5553b          	divuw	a0,a0,a1
    800004e2:	0685                	addi	a3,a3,1
    800004e4:	feb7f0e3          	bgeu	a5,a1,800004c4 <printint+0x26>

  if(sign)
    800004e8:	00088b63          	beqz	a7,800004fe <printint+0x60>
    buf[i++] = '-';
    800004ec:	fe040793          	addi	a5,s0,-32
    800004f0:	973e                	add	a4,a4,a5
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x8e>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d60080e7          	jalr	-672(ra) # 8000027e <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7c>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf9d                	j	800004b4 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	3a07a223          	sw	zero,932(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b7a50513          	addi	a0,a0,-1158 # 800080e8 <digits+0xa8>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00009717          	auipc	a4,0x9
    80000584:	a8f72023          	sw	a5,-1408(a4) # 80009000 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	334dad83          	lw	s11,820(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00011517          	auipc	a0,0x11
    800005fe:	2de50513          	addi	a0,a0,734 # 800118d8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5fa080e7          	jalr	1530(ra) # 80000bfc <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c62080e7          	jalr	-926(ra) # 8000027e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e32080e7          	jalr	-462(ra) # 8000049e <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0e080e7          	jalr	-498(ra) # 8000049e <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bd0080e7          	jalr	-1072(ra) # 8000027e <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc4080e7          	jalr	-1084(ra) # 8000027e <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bb0080e7          	jalr	-1104(ra) # 8000027e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b8a080e7          	jalr	-1142(ra) # 8000027e <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b68080e7          	jalr	-1176(ra) # 8000027e <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5c080e7          	jalr	-1188(ra) # 8000027e <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b52080e7          	jalr	-1198(ra) # 8000027e <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00011517          	auipc	a0,0x11
    8000075c:	18050513          	addi	a0,a0,384 # 800118d8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	550080e7          	jalr	1360(ra) # 80000cb0 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00011497          	auipc	s1,0x11
    80000778:	16448493          	addi	s1,s1,356 # 800118d8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3e6080e7          	jalr	998(ra) # 80000b6c <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00011517          	auipc	a0,0x11
    800007d8:	12450513          	addi	a0,a0,292 # 800118f8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	390080e7          	jalr	912(ra) # 80000b6c <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	3b8080e7          	jalr	952(ra) # 80000bb0 <push_off>

  if(panicked){
    80000800:	00009797          	auipc	a5,0x9
    80000804:	8007a783          	lw	a5,-2048(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	andi	a0,s1,255
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	42a080e7          	jalr	1066(ra) # 80000c50 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	7cc7a783          	lw	a5,1996(a5) # 80009004 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c872703          	lw	a4,1992(a4) # 80009008 <uart_tx_w>
    80000848:	08f70063          	beq	a4,a5,800008c8 <uartstart+0x90>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000862:	00011a97          	auipc	s5,0x11
    80000866:	096a8a93          	addi	s5,s5,150 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	79a48493          	addi	s1,s1,1946 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008a17          	auipc	s4,0x8
    80000876:	796a0a13          	addi	s4,s4,1942 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	cb15                	beqz	a4,800008b6 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000884:	00fa8733          	add	a4,s5,a5
    80000888:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088c:	2785                	addiw	a5,a5,1
    8000088e:	41f7d71b          	sraiw	a4,a5,0x1f
    80000892:	01b7571b          	srliw	a4,a4,0x1b
    80000896:	9fb9                	addw	a5,a5,a4
    80000898:	8bfd                	andi	a5,a5,31
    8000089a:	9f99                	subw	a5,a5,a4
    8000089c:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	d0a080e7          	jalr	-758(ra) # 800025aa <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	409c                	lw	a5,0(s1)
    800008ae:	000a2703          	lw	a4,0(s4)
    800008b2:	fcf714e3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	01c50513          	addi	a0,a0,28 # 800118f8 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	318080e7          	jalr	792(ra) # 80000bfc <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008f8:	00008697          	auipc	a3,0x8
    800008fc:	7106a683          	lw	a3,1808(a3) # 80009008 <uart_tx_w>
    80000900:	0016879b          	addiw	a5,a3,1
    80000904:	41f7d71b          	sraiw	a4,a5,0x1f
    80000908:	01b7571b          	srliw	a4,a4,0x1b
    8000090c:	9fb9                	addw	a5,a5,a4
    8000090e:	8bfd                	andi	a5,a5,31
    80000910:	9f99                	subw	a5,a5,a4
    80000912:	00008717          	auipc	a4,0x8
    80000916:	6f272703          	lw	a4,1778(a4) # 80009004 <uart_tx_r>
    8000091a:	04f71363          	bne	a4,a5,80000960 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091e:	00011a17          	auipc	s4,0x11
    80000922:	fdaa0a13          	addi	s4,s4,-38 # 800118f8 <uart_tx_lock>
    80000926:	00008917          	auipc	s2,0x8
    8000092a:	6de90913          	addi	s2,s2,1758 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000092e:	00008997          	auipc	s3,0x8
    80000932:	6da98993          	addi	s3,s3,1754 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000936:	85d2                	mv	a1,s4
    80000938:	854a                	mv	a0,s2
    8000093a:	00002097          	auipc	ra,0x2
    8000093e:	ad6080e7          	jalr	-1322(ra) # 80002410 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000942:	0009a683          	lw	a3,0(s3)
    80000946:	0016879b          	addiw	a5,a3,1
    8000094a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000094e:	01b7571b          	srliw	a4,a4,0x1b
    80000952:	9fb9                	addw	a5,a5,a4
    80000954:	8bfd                	andi	a5,a5,31
    80000956:	9f99                	subw	a5,a5,a4
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	fcf70de3          	beq	a4,a5,80000936 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000960:	00011917          	auipc	s2,0x11
    80000964:	f9890913          	addi	s2,s2,-104 # 800118f8 <uart_tx_lock>
    80000968:	96ca                	add	a3,a3,s2
    8000096a:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000096e:	00008717          	auipc	a4,0x8
    80000972:	68f72d23          	sw	a5,1690(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000976:	00000097          	auipc	ra,0x0
    8000097a:	ec2080e7          	jalr	-318(ra) # 80000838 <uartstart>
      release(&uart_tx_lock);
    8000097e:	854a                	mv	a0,s2
    80000980:	00000097          	auipc	ra,0x0
    80000984:	330080e7          	jalr	816(ra) # 80000cb0 <release>
}
    80000988:	70a2                	ld	ra,40(sp)
    8000098a:	7402                	ld	s0,32(sp)
    8000098c:	64e2                	ld	s1,24(sp)
    8000098e:	6942                	ld	s2,16(sp)
    80000990:	69a2                	ld	s3,8(sp)
    80000992:	6a02                	ld	s4,0(sp)
    80000994:	6145                	addi	sp,sp,48
    80000996:	8082                	ret

0000000080000998 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000998:	1141                	addi	sp,sp,-16
    8000099a:	e422                	sd	s0,8(sp)
    8000099c:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a6:	8b85                	andi	a5,a5,1
    800009a8:	cb91                	beqz	a5,800009bc <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009aa:	100007b7          	lui	a5,0x10000
    800009ae:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b2:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b6:	6422                	ld	s0,8(sp)
    800009b8:	0141                	addi	sp,sp,16
    800009ba:	8082                	ret
    return -1;
    800009bc:	557d                	li	a0,-1
    800009be:	bfe5                	j	800009b6 <uartgetc+0x1e>

00000000800009c0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c0:	1101                	addi	sp,sp,-32
    800009c2:	ec06                	sd	ra,24(sp)
    800009c4:	e822                	sd	s0,16(sp)
    800009c6:	e426                	sd	s1,8(sp)
    800009c8:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ca:	54fd                	li	s1,-1
    800009cc:	a029                	j	800009d6 <uartintr+0x16>
      break;
    consoleintr(c);
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	8f2080e7          	jalr	-1806(ra) # 800002c0 <consoleintr>
    int c = uartgetc();
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	fc2080e7          	jalr	-62(ra) # 80000998 <uartgetc>
    if(c == -1)
    800009de:	fe9518e3          	bne	a0,s1,800009ce <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e2:	00011497          	auipc	s1,0x11
    800009e6:	f1648493          	addi	s1,s1,-234 # 800118f8 <uart_tx_lock>
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	210080e7          	jalr	528(ra) # 80000bfc <acquire>
  uartstart();
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	e44080e7          	jalr	-444(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009fc:	8526                	mv	a0,s1
    800009fe:	00000097          	auipc	ra,0x0
    80000a02:	2b2080e7          	jalr	690(ra) # 80000cb0 <release>
}
    80000a06:	60e2                	ld	ra,24(sp)
    80000a08:	6442                	ld	s0,16(sp)
    80000a0a:	64a2                	ld	s1,8(sp)
    80000a0c:	6105                	addi	sp,sp,32
    80000a0e:	8082                	ret

0000000080000a10 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a10:	1101                	addi	sp,sp,-32
    80000a12:	ec06                	sd	ra,24(sp)
    80000a14:	e822                	sd	s0,16(sp)
    80000a16:	e426                	sd	s1,8(sp)
    80000a18:	e04a                	sd	s2,0(sp)
    80000a1a:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1c:	03451793          	slli	a5,a0,0x34
    80000a20:	ebb9                	bnez	a5,80000a76 <kfree+0x66>
    80000a22:	84aa                	mv	s1,a0
    80000a24:	00026797          	auipc	a5,0x26
    80000a28:	5dc78793          	addi	a5,a5,1500 # 80027000 <end>
    80000a2c:	04f56563          	bltu	a0,a5,80000a76 <kfree+0x66>
    80000a30:	47c5                	li	a5,17
    80000a32:	07ee                	slli	a5,a5,0x1b
    80000a34:	04f57163          	bgeu	a0,a5,80000a76 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a38:	6605                	lui	a2,0x1
    80000a3a:	4585                	li	a1,1
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	2bc080e7          	jalr	700(ra) # 80000cf8 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a44:	00011917          	auipc	s2,0x11
    80000a48:	eec90913          	addi	s2,s2,-276 # 80011930 <kmem>
    80000a4c:	854a                	mv	a0,s2
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	1ae080e7          	jalr	430(ra) # 80000bfc <acquire>
  r->next = kmem.freelist;
    80000a56:	01893783          	ld	a5,24(s2)
    80000a5a:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5c:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	24e080e7          	jalr	590(ra) # 80000cb0 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00007517          	auipc	a0,0x7
    80000a7a:	5ea50513          	addi	a0,a0,1514 # 80008060 <digits+0x20>
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	ac2080e7          	jalr	-1342(ra) # 80000540 <panic>

0000000080000a86 <freerange>:
{
    80000a86:	7179                	addi	sp,sp,-48
    80000a88:	f406                	sd	ra,40(sp)
    80000a8a:	f022                	sd	s0,32(sp)
    80000a8c:	ec26                	sd	s1,24(sp)
    80000a8e:	e84a                	sd	s2,16(sp)
    80000a90:	e44e                	sd	s3,8(sp)
    80000a92:	e052                	sd	s4,0(sp)
    80000a94:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a96:	6785                	lui	a5,0x1
    80000a98:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9c:	94aa                	add	s1,s1,a0
    80000a9e:	757d                	lui	a0,0xfffff
    80000aa0:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94be                	add	s1,s1,a5
    80000aa4:	0095ee63          	bltu	a1,s1,80000ac0 <freerange+0x3a>
    80000aa8:	892e                	mv	s2,a1
    kfree(p);
    80000aaa:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aac:	6985                	lui	s3,0x1
    kfree(p);
    80000aae:	01448533          	add	a0,s1,s4
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	f5e080e7          	jalr	-162(ra) # 80000a10 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aba:	94ce                	add	s1,s1,s3
    80000abc:	fe9979e3          	bgeu	s2,s1,80000aae <freerange+0x28>
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6942                	ld	s2,16(sp)
    80000ac8:	69a2                	ld	s3,8(sp)
    80000aca:	6a02                	ld	s4,0(sp)
    80000acc:	6145                	addi	sp,sp,48
    80000ace:	8082                	ret

0000000080000ad0 <kinit>:
{
    80000ad0:	1141                	addi	sp,sp,-16
    80000ad2:	e406                	sd	ra,8(sp)
    80000ad4:	e022                	sd	s0,0(sp)
    80000ad6:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad8:	00007597          	auipc	a1,0x7
    80000adc:	59058593          	addi	a1,a1,1424 # 80008068 <digits+0x28>
    80000ae0:	00011517          	auipc	a0,0x11
    80000ae4:	e5050513          	addi	a0,a0,-432 # 80011930 <kmem>
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	084080e7          	jalr	132(ra) # 80000b6c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af0:	45c5                	li	a1,17
    80000af2:	05ee                	slli	a1,a1,0x1b
    80000af4:	00026517          	auipc	a0,0x26
    80000af8:	50c50513          	addi	a0,a0,1292 # 80027000 <end>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	f8a080e7          	jalr	-118(ra) # 80000a86 <freerange>
}
    80000b04:	60a2                	ld	ra,8(sp)
    80000b06:	6402                	ld	s0,0(sp)
    80000b08:	0141                	addi	sp,sp,16
    80000b0a:	8082                	ret

0000000080000b0c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0c:	1101                	addi	sp,sp,-32
    80000b0e:	ec06                	sd	ra,24(sp)
    80000b10:	e822                	sd	s0,16(sp)
    80000b12:	e426                	sd	s1,8(sp)
    80000b14:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b16:	00011497          	auipc	s1,0x11
    80000b1a:	e1a48493          	addi	s1,s1,-486 # 80011930 <kmem>
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	0dc080e7          	jalr	220(ra) # 80000bfc <acquire>
  r = kmem.freelist;
    80000b28:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2a:	c885                	beqz	s1,80000b5a <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2c:	609c                	ld	a5,0(s1)
    80000b2e:	00011517          	auipc	a0,0x11
    80000b32:	e0250513          	addi	a0,a0,-510 # 80011930 <kmem>
    80000b36:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	178080e7          	jalr	376(ra) # 80000cb0 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b40:	6605                	lui	a2,0x1
    80000b42:	4595                	li	a1,5
    80000b44:	8526                	mv	a0,s1
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	1b2080e7          	jalr	434(ra) # 80000cf8 <memset>
  return (void*)r;
}
    80000b4e:	8526                	mv	a0,s1
    80000b50:	60e2                	ld	ra,24(sp)
    80000b52:	6442                	ld	s0,16(sp)
    80000b54:	64a2                	ld	s1,8(sp)
    80000b56:	6105                	addi	sp,sp,32
    80000b58:	8082                	ret
  release(&kmem.lock);
    80000b5a:	00011517          	auipc	a0,0x11
    80000b5e:	dd650513          	addi	a0,a0,-554 # 80011930 <kmem>
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	14e080e7          	jalr	334(ra) # 80000cb0 <release>
  if(r)
    80000b6a:	b7d5                	j	80000b4e <kalloc+0x42>

0000000080000b6c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6c:	1141                	addi	sp,sp,-16
    80000b6e:	e422                	sd	s0,8(sp)
    80000b70:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b72:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b74:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b78:	00053823          	sd	zero,16(a0)
}
    80000b7c:	6422                	ld	s0,8(sp)
    80000b7e:	0141                	addi	sp,sp,16
    80000b80:	8082                	ret

0000000080000b82 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	411c                	lw	a5,0(a0)
    80000b84:	e399                	bnez	a5,80000b8a <holding+0x8>
    80000b86:	4501                	li	a0,0
  return r;
}
    80000b88:	8082                	ret
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b94:	6904                	ld	s1,16(a0)
    80000b96:	00001097          	auipc	ra,0x1
    80000b9a:	f40080e7          	jalr	-192(ra) # 80001ad6 <mycpu>
    80000b9e:	40a48533          	sub	a0,s1,a0
    80000ba2:	00153513          	seqz	a0,a0
}
    80000ba6:	60e2                	ld	ra,24(sp)
    80000ba8:	6442                	ld	s0,16(sp)
    80000baa:	64a2                	ld	s1,8(sp)
    80000bac:	6105                	addi	sp,sp,32
    80000bae:	8082                	ret

0000000080000bb0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb0:	1101                	addi	sp,sp,-32
    80000bb2:	ec06                	sd	ra,24(sp)
    80000bb4:	e822                	sd	s0,16(sp)
    80000bb6:	e426                	sd	s1,8(sp)
    80000bb8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bba:	100024f3          	csrr	s1,sstatus
    80000bbe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bc8:	00001097          	auipc	ra,0x1
    80000bcc:	f0e080e7          	jalr	-242(ra) # 80001ad6 <mycpu>
    80000bd0:	5d3c                	lw	a5,120(a0)
    80000bd2:	cf89                	beqz	a5,80000bec <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	f02080e7          	jalr	-254(ra) # 80001ad6 <mycpu>
    80000bdc:	5d3c                	lw	a5,120(a0)
    80000bde:	2785                	addiw	a5,a5,1
    80000be0:	dd3c                	sw	a5,120(a0)
}
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	addi	sp,sp,32
    80000bea:	8082                	ret
    mycpu()->intena = old;
    80000bec:	00001097          	auipc	ra,0x1
    80000bf0:	eea080e7          	jalr	-278(ra) # 80001ad6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf4:	8085                	srli	s1,s1,0x1
    80000bf6:	8885                	andi	s1,s1,1
    80000bf8:	dd64                	sw	s1,124(a0)
    80000bfa:	bfe9                	j	80000bd4 <push_off+0x24>

0000000080000bfc <acquire>:
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
    80000c06:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	fa8080e7          	jalr	-88(ra) # 80000bb0 <push_off>
  if(holding(lk))
    80000c10:	8526                	mv	a0,s1
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	f70080e7          	jalr	-144(ra) # 80000b82 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1a:	4705                	li	a4,1
  if(holding(lk))
    80000c1c:	e115                	bnez	a0,80000c40 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1e:	87ba                	mv	a5,a4
    80000c20:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c24:	2781                	sext.w	a5,a5
    80000c26:	ffe5                	bnez	a5,80000c1e <acquire+0x22>
  __sync_synchronize();
    80000c28:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	eaa080e7          	jalr	-342(ra) # 80001ad6 <mycpu>
    80000c34:	e888                	sd	a0,16(s1)
}
    80000c36:	60e2                	ld	ra,24(sp)
    80000c38:	6442                	ld	s0,16(sp)
    80000c3a:	64a2                	ld	s1,8(sp)
    80000c3c:	6105                	addi	sp,sp,32
    80000c3e:	8082                	ret
    panic("acquire");
    80000c40:	00007517          	auipc	a0,0x7
    80000c44:	43050513          	addi	a0,a0,1072 # 80008070 <digits+0x30>
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	8f8080e7          	jalr	-1800(ra) # 80000540 <panic>

0000000080000c50 <pop_off>:

void
pop_off(void)
{
    80000c50:	1141                	addi	sp,sp,-16
    80000c52:	e406                	sd	ra,8(sp)
    80000c54:	e022                	sd	s0,0(sp)
    80000c56:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c58:	00001097          	auipc	ra,0x1
    80000c5c:	e7e080e7          	jalr	-386(ra) # 80001ad6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c64:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c66:	e78d                	bnez	a5,80000c90 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c68:	5d3c                	lw	a5,120(a0)
    80000c6a:	02f05b63          	blez	a5,80000ca0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c6e:	37fd                	addiw	a5,a5,-1
    80000c70:	0007871b          	sext.w	a4,a5
    80000c74:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c76:	eb09                	bnez	a4,80000c88 <pop_off+0x38>
    80000c78:	5d7c                	lw	a5,124(a0)
    80000c7a:	c799                	beqz	a5,80000c88 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c80:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c84:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c88:	60a2                	ld	ra,8(sp)
    80000c8a:	6402                	ld	s0,0(sp)
    80000c8c:	0141                	addi	sp,sp,16
    80000c8e:	8082                	ret
    panic("pop_off - interruptible");
    80000c90:	00007517          	auipc	a0,0x7
    80000c94:	3e850513          	addi	a0,a0,1000 # 80008078 <digits+0x38>
    80000c98:	00000097          	auipc	ra,0x0
    80000c9c:	8a8080e7          	jalr	-1880(ra) # 80000540 <panic>
    panic("pop_off");
    80000ca0:	00007517          	auipc	a0,0x7
    80000ca4:	3f050513          	addi	a0,a0,1008 # 80008090 <digits+0x50>
    80000ca8:	00000097          	auipc	ra,0x0
    80000cac:	898080e7          	jalr	-1896(ra) # 80000540 <panic>

0000000080000cb0 <release>:
{
    80000cb0:	1101                	addi	sp,sp,-32
    80000cb2:	ec06                	sd	ra,24(sp)
    80000cb4:	e822                	sd	s0,16(sp)
    80000cb6:	e426                	sd	s1,8(sp)
    80000cb8:	1000                	addi	s0,sp,32
    80000cba:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	ec6080e7          	jalr	-314(ra) # 80000b82 <holding>
    80000cc4:	c115                	beqz	a0,80000ce8 <release+0x38>
  lk->cpu = 0;
    80000cc6:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cca:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cce:	0f50000f          	fence	iorw,ow
    80000cd2:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd6:	00000097          	auipc	ra,0x0
    80000cda:	f7a080e7          	jalr	-134(ra) # 80000c50 <pop_off>
}
    80000cde:	60e2                	ld	ra,24(sp)
    80000ce0:	6442                	ld	s0,16(sp)
    80000ce2:	64a2                	ld	s1,8(sp)
    80000ce4:	6105                	addi	sp,sp,32
    80000ce6:	8082                	ret
    panic("release");
    80000ce8:	00007517          	auipc	a0,0x7
    80000cec:	3b050513          	addi	a0,a0,944 # 80008098 <digits+0x58>
    80000cf0:	00000097          	auipc	ra,0x0
    80000cf4:	850080e7          	jalr	-1968(ra) # 80000540 <panic>

0000000080000cf8 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cfe:	ca19                	beqz	a2,80000d14 <memset+0x1c>
    80000d00:	87aa                	mv	a5,a0
    80000d02:	1602                	slli	a2,a2,0x20
    80000d04:	9201                	srli	a2,a2,0x20
    80000d06:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d0e:	0785                	addi	a5,a5,1
    80000d10:	fee79de3          	bne	a5,a4,80000d0a <memset+0x12>
  }
  return dst;
}
    80000d14:	6422                	ld	s0,8(sp)
    80000d16:	0141                	addi	sp,sp,16
    80000d18:	8082                	ret

0000000080000d1a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d20:	ca05                	beqz	a2,80000d50 <memcmp+0x36>
    80000d22:	fff6069b          	addiw	a3,a2,-1
    80000d26:	1682                	slli	a3,a3,0x20
    80000d28:	9281                	srli	a3,a3,0x20
    80000d2a:	0685                	addi	a3,a3,1
    80000d2c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d2e:	00054783          	lbu	a5,0(a0)
    80000d32:	0005c703          	lbu	a4,0(a1)
    80000d36:	00e79863          	bne	a5,a4,80000d46 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3a:	0505                	addi	a0,a0,1
    80000d3c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d3e:	fed518e3          	bne	a0,a3,80000d2e <memcmp+0x14>
  }

  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	a019                	j	80000d4a <memcmp+0x30>
      return *s1 - *s2;
    80000d46:	40e7853b          	subw	a0,a5,a4
}
    80000d4a:	6422                	ld	s0,8(sp)
    80000d4c:	0141                	addi	sp,sp,16
    80000d4e:	8082                	ret
  return 0;
    80000d50:	4501                	li	a0,0
    80000d52:	bfe5                	j	80000d4a <memcmp+0x30>

0000000080000d54 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d54:	1141                	addi	sp,sp,-16
    80000d56:	e422                	sd	s0,8(sp)
    80000d58:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5a:	02a5e563          	bltu	a1,a0,80000d84 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5e:	fff6069b          	addiw	a3,a2,-1
    80000d62:	ce11                	beqz	a2,80000d7e <memmove+0x2a>
    80000d64:	1682                	slli	a3,a3,0x20
    80000d66:	9281                	srli	a3,a3,0x20
    80000d68:	0685                	addi	a3,a3,1
    80000d6a:	96ae                	add	a3,a3,a1
    80000d6c:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	fff5c703          	lbu	a4,-1(a1)
    80000d76:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7a:	fed59ae3          	bne	a1,a3,80000d6e <memmove+0x1a>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
  if(s < d && s + n > d){
    80000d84:	02061713          	slli	a4,a2,0x20
    80000d88:	9301                	srli	a4,a4,0x20
    80000d8a:	00e587b3          	add	a5,a1,a4
    80000d8e:	fcf578e3          	bgeu	a0,a5,80000d5e <memmove+0xa>
    d += n;
    80000d92:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d94:	fff6069b          	addiw	a3,a2,-1
    80000d98:	d27d                	beqz	a2,80000d7e <memmove+0x2a>
    80000d9a:	02069613          	slli	a2,a3,0x20
    80000d9e:	9201                	srli	a2,a2,0x20
    80000da0:	fff64613          	not	a2,a2
    80000da4:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da6:	17fd                	addi	a5,a5,-1
    80000da8:	177d                	addi	a4,a4,-1
    80000daa:	0007c683          	lbu	a3,0(a5)
    80000dae:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db2:	fef61ae3          	bne	a2,a5,80000da6 <memmove+0x52>
    80000db6:	b7e1                	j	80000d7e <memmove+0x2a>

0000000080000db8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e406                	sd	ra,8(sp)
    80000dbc:	e022                	sd	s0,0(sp)
    80000dbe:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc0:	00000097          	auipc	ra,0x0
    80000dc4:	f94080e7          	jalr	-108(ra) # 80000d54 <memmove>
}
    80000dc8:	60a2                	ld	ra,8(sp)
    80000dca:	6402                	ld	s0,0(sp)
    80000dcc:	0141                	addi	sp,sp,16
    80000dce:	8082                	ret

0000000080000dd0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e422                	sd	s0,8(sp)
    80000dd4:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd6:	ce11                	beqz	a2,80000df2 <strncmp+0x22>
    80000dd8:	00054783          	lbu	a5,0(a0)
    80000ddc:	cf89                	beqz	a5,80000df6 <strncmp+0x26>
    80000dde:	0005c703          	lbu	a4,0(a1)
    80000de2:	00f71a63          	bne	a4,a5,80000df6 <strncmp+0x26>
    n--, p++, q++;
    80000de6:	367d                	addiw	a2,a2,-1
    80000de8:	0505                	addi	a0,a0,1
    80000dea:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dec:	f675                	bnez	a2,80000dd8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dee:	4501                	li	a0,0
    80000df0:	a809                	j	80000e02 <strncmp+0x32>
    80000df2:	4501                	li	a0,0
    80000df4:	a039                	j	80000e02 <strncmp+0x32>
  if(n == 0)
    80000df6:	ca09                	beqz	a2,80000e08 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000df8:	00054503          	lbu	a0,0(a0)
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	9d1d                	subw	a0,a0,a5
}
    80000e02:	6422                	ld	s0,8(sp)
    80000e04:	0141                	addi	sp,sp,16
    80000e06:	8082                	ret
    return 0;
    80000e08:	4501                	li	a0,0
    80000e0a:	bfe5                	j	80000e02 <strncmp+0x32>

0000000080000e0c <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0c:	1141                	addi	sp,sp,-16
    80000e0e:	e422                	sd	s0,8(sp)
    80000e10:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e12:	872a                	mv	a4,a0
    80000e14:	8832                	mv	a6,a2
    80000e16:	367d                	addiw	a2,a2,-1
    80000e18:	01005963          	blez	a6,80000e2a <strncpy+0x1e>
    80000e1c:	0705                	addi	a4,a4,1
    80000e1e:	0005c783          	lbu	a5,0(a1)
    80000e22:	fef70fa3          	sb	a5,-1(a4)
    80000e26:	0585                	addi	a1,a1,1
    80000e28:	f7f5                	bnez	a5,80000e14 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2a:	86ba                	mv	a3,a4
    80000e2c:	00c05c63          	blez	a2,80000e44 <strncpy+0x38>
    *s++ = 0;
    80000e30:	0685                	addi	a3,a3,1
    80000e32:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e36:	fff6c793          	not	a5,a3
    80000e3a:	9fb9                	addw	a5,a5,a4
    80000e3c:	010787bb          	addw	a5,a5,a6
    80000e40:	fef048e3          	bgtz	a5,80000e30 <strncpy+0x24>
  return os;
}
    80000e44:	6422                	ld	s0,8(sp)
    80000e46:	0141                	addi	sp,sp,16
    80000e48:	8082                	ret

0000000080000e4a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4a:	1141                	addi	sp,sp,-16
    80000e4c:	e422                	sd	s0,8(sp)
    80000e4e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e50:	02c05363          	blez	a2,80000e76 <safestrcpy+0x2c>
    80000e54:	fff6069b          	addiw	a3,a2,-1
    80000e58:	1682                	slli	a3,a3,0x20
    80000e5a:	9281                	srli	a3,a3,0x20
    80000e5c:	96ae                	add	a3,a3,a1
    80000e5e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e60:	00d58963          	beq	a1,a3,80000e72 <safestrcpy+0x28>
    80000e64:	0585                	addi	a1,a1,1
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff5c703          	lbu	a4,-1(a1)
    80000e6c:	fee78fa3          	sb	a4,-1(a5)
    80000e70:	fb65                	bnez	a4,80000e60 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e72:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e76:	6422                	ld	s0,8(sp)
    80000e78:	0141                	addi	sp,sp,16
    80000e7a:	8082                	ret

0000000080000e7c <strlen>:

int
strlen(const char *s)
{
    80000e7c:	1141                	addi	sp,sp,-16
    80000e7e:	e422                	sd	s0,8(sp)
    80000e80:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e82:	00054783          	lbu	a5,0(a0)
    80000e86:	cf91                	beqz	a5,80000ea2 <strlen+0x26>
    80000e88:	0505                	addi	a0,a0,1
    80000e8a:	87aa                	mv	a5,a0
    80000e8c:	4685                	li	a3,1
    80000e8e:	9e89                	subw	a3,a3,a0
    80000e90:	00f6853b          	addw	a0,a3,a5
    80000e94:	0785                	addi	a5,a5,1
    80000e96:	fff7c703          	lbu	a4,-1(a5)
    80000e9a:	fb7d                	bnez	a4,80000e90 <strlen+0x14>
    ;
  return n;
}
    80000e9c:	6422                	ld	s0,8(sp)
    80000e9e:	0141                	addi	sp,sp,16
    80000ea0:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea2:	4501                	li	a0,0
    80000ea4:	bfe5                	j	80000e9c <strlen+0x20>

0000000080000ea6 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea6:	1141                	addi	sp,sp,-16
    80000ea8:	e406                	sd	ra,8(sp)
    80000eaa:	e022                	sd	s0,0(sp)
    80000eac:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eae:	00001097          	auipc	ra,0x1
    80000eb2:	c18080e7          	jalr	-1000(ra) # 80001ac6 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb6:	00008717          	auipc	a4,0x8
    80000eba:	15670713          	addi	a4,a4,342 # 8000900c <started>
  if(cpuid() == 0){
    80000ebe:	c139                	beqz	a0,80000f04 <main+0x5e>
    while(started == 0)
    80000ec0:	431c                	lw	a5,0(a4)
    80000ec2:	2781                	sext.w	a5,a5
    80000ec4:	dff5                	beqz	a5,80000ec0 <main+0x1a>
      ;
    __sync_synchronize();
    80000ec6:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	bfc080e7          	jalr	-1028(ra) # 80001ac6 <cpuid>
    80000ed2:	85aa                	mv	a1,a0
    80000ed4:	00007517          	auipc	a0,0x7
    80000ed8:	20450513          	addi	a0,a0,516 # 800080d8 <digits+0x98>
    80000edc:	fffff097          	auipc	ra,0xfffff
    80000ee0:	6ae080e7          	jalr	1710(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000ee4:	00000097          	auipc	ra,0x0
    80000ee8:	0c8080e7          	jalr	200(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eec:	00002097          	auipc	ra,0x2
    80000ef0:	9a2080e7          	jalr	-1630(ra) # 8000288e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef4:	00005097          	auipc	ra,0x5
    80000ef8:	f6c080e7          	jalr	-148(ra) # 80005e60 <plicinithart>
  }

  scheduler();        
    80000efc:	00001097          	auipc	ra,0x1
    80000f00:	1b2080e7          	jalr	434(ra) # 800020ae <scheduler>
    consoleinit();
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	54e080e7          	jalr	1358(ra) # 80000452 <consoleinit>
    printfinit();
    80000f0c:	00000097          	auipc	ra,0x0
    80000f10:	85e080e7          	jalr	-1954(ra) # 8000076a <printfinit>
    printf("\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	1d450513          	addi	a0,a0,468 # 800080e8 <digits+0xa8>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66e080e7          	jalr	1646(ra) # 8000058a <printf>
    printf("EEE3535 Operating Systems: booting xv6-riscv kernel\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	17c50513          	addi	a0,a0,380 # 800080a0 <digits+0x60>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65e080e7          	jalr	1630(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b9c080e7          	jalr	-1124(ra) # 80000ad0 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	2a0080e7          	jalr	672(ra) # 800011dc <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	aaa080e7          	jalr	-1366(ra) # 800019f6 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	912080e7          	jalr	-1774(ra) # 80002866 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	932080e7          	jalr	-1742(ra) # 8000288e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	ee6080e7          	jalr	-282(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	ef4080e7          	jalr	-268(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	09e080e7          	jalr	158(ra) # 80003012 <binit>
    iinit();         // inode cache
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	730080e7          	jalr	1840(ra) # 800036ac <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	6ce080e7          	jalr	1742(ra) # 80004652 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	fdc080e7          	jalr	-36(ra) # 80005f68 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	e98080e7          	jalr	-360(ra) # 80001e2c <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72523          	sw	a5,106(a4) # 8000900c <started>
    80000faa:	bf89                	j	80000efc <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	05e7b783          	ld	a5,94(a5) # 80009010 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0fa50513          	addi	a0,a0,250 # 800080f0 <digits+0xb0>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	542080e7          	jalr	1346(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	b02080e7          	jalr	-1278(ra) # 80000b0c <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cde080e7          	jalr	-802(ra) # 80000cf8 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010b8:	1101                	addi	sp,sp,-32
    800010ba:	ec06                	sd	ra,24(sp)
    800010bc:	e822                	sd	s0,16(sp)
    800010be:	e426                	sd	s1,8(sp)
    800010c0:	1000                	addi	s0,sp,32
    800010c2:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010c4:	1552                	slli	a0,a0,0x34
    800010c6:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010ca:	4601                	li	a2,0
    800010cc:	00008517          	auipc	a0,0x8
    800010d0:	f4453503          	ld	a0,-188(a0) # 80009010 <kernel_pagetable>
    800010d4:	00000097          	auipc	ra,0x0
    800010d8:	efc080e7          	jalr	-260(ra) # 80000fd0 <walk>
  if(pte == 0)
    800010dc:	cd09                	beqz	a0,800010f6 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010de:	6108                	ld	a0,0(a0)
    800010e0:	00157793          	andi	a5,a0,1
    800010e4:	c38d                	beqz	a5,80001106 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010e6:	8129                	srli	a0,a0,0xa
    800010e8:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010ea:	9526                	add	a0,a0,s1
    800010ec:	60e2                	ld	ra,24(sp)
    800010ee:	6442                	ld	s0,16(sp)
    800010f0:	64a2                	ld	s1,8(sp)
    800010f2:	6105                	addi	sp,sp,32
    800010f4:	8082                	ret
    panic("kvmpa");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	00250513          	addi	a0,a0,2 # 800080f8 <digits+0xb8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	442080e7          	jalr	1090(ra) # 80000540 <panic>
    panic("kvmpa");
    80001106:	00007517          	auipc	a0,0x7
    8000110a:	ff250513          	addi	a0,a0,-14 # 800080f8 <digits+0xb8>
    8000110e:	fffff097          	auipc	ra,0xfffff
    80001112:	432080e7          	jalr	1074(ra) # 80000540 <panic>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
    8000112c:	8aaa                	mv	s5,a0
    8000112e:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001130:	777d                	lui	a4,0xfffff
    80001132:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001136:	167d                	addi	a2,a2,-1
    80001138:	00b609b3          	add	s3,a2,a1
    8000113c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001140:	893e                	mv	s2,a5
    80001142:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001146:	6b85                	lui	s7,0x1
    80001148:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114c:	4605                	li	a2,1
    8000114e:	85ca                	mv	a1,s2
    80001150:	8556                	mv	a0,s5
    80001152:	00000097          	auipc	ra,0x0
    80001156:	e7e080e7          	jalr	-386(ra) # 80000fd0 <walk>
    8000115a:	c51d                	beqz	a0,80001188 <mappages+0x72>
    if(*pte & PTE_V)
    8000115c:	611c                	ld	a5,0(a0)
    8000115e:	8b85                	andi	a5,a5,1
    80001160:	ef81                	bnez	a5,80001178 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001162:	80b1                	srli	s1,s1,0xc
    80001164:	04aa                	slli	s1,s1,0xa
    80001166:	0164e4b3          	or	s1,s1,s6
    8000116a:	0014e493          	ori	s1,s1,1
    8000116e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001170:	03390863          	beq	s2,s3,800011a0 <mappages+0x8a>
    a += PGSIZE;
    80001174:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001176:	bfc9                	j	80001148 <mappages+0x32>
      panic("remap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8850513          	addi	a0,a0,-120 # 80008100 <digits+0xc0>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c0080e7          	jalr	960(ra) # 80000540 <panic>
      return -1;
    80001188:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000118a:	60a6                	ld	ra,72(sp)
    8000118c:	6406                	ld	s0,64(sp)
    8000118e:	74e2                	ld	s1,56(sp)
    80001190:	7942                	ld	s2,48(sp)
    80001192:	79a2                	ld	s3,40(sp)
    80001194:	7a02                	ld	s4,32(sp)
    80001196:	6ae2                	ld	s5,24(sp)
    80001198:	6b42                	ld	s6,16(sp)
    8000119a:	6ba2                	ld	s7,8(sp)
    8000119c:	6161                	addi	sp,sp,80
    8000119e:	8082                	ret
  return 0;
    800011a0:	4501                	li	a0,0
    800011a2:	b7e5                	j	8000118a <mappages+0x74>

00000000800011a4 <kvmmap>:
{
    800011a4:	1141                	addi	sp,sp,-16
    800011a6:	e406                	sd	ra,8(sp)
    800011a8:	e022                	sd	s0,0(sp)
    800011aa:	0800                	addi	s0,sp,16
    800011ac:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011ae:	86ae                	mv	a3,a1
    800011b0:	85aa                	mv	a1,a0
    800011b2:	00008517          	auipc	a0,0x8
    800011b6:	e5e53503          	ld	a0,-418(a0) # 80009010 <kernel_pagetable>
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	f5c080e7          	jalr	-164(ra) # 80001116 <mappages>
    800011c2:	e509                	bnez	a0,800011cc <kvmmap+0x28>
}
    800011c4:	60a2                	ld	ra,8(sp)
    800011c6:	6402                	ld	s0,0(sp)
    800011c8:	0141                	addi	sp,sp,16
    800011ca:	8082                	ret
    panic("kvmmap");
    800011cc:	00007517          	auipc	a0,0x7
    800011d0:	f3c50513          	addi	a0,a0,-196 # 80008108 <digits+0xc8>
    800011d4:	fffff097          	auipc	ra,0xfffff
    800011d8:	36c080e7          	jalr	876(ra) # 80000540 <panic>

00000000800011dc <kvminit>:
{
    800011dc:	1101                	addi	sp,sp,-32
    800011de:	ec06                	sd	ra,24(sp)
    800011e0:	e822                	sd	s0,16(sp)
    800011e2:	e426                	sd	s1,8(sp)
    800011e4:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	926080e7          	jalr	-1754(ra) # 80000b0c <kalloc>
    800011ee:	00008797          	auipc	a5,0x8
    800011f2:	e2a7b123          	sd	a0,-478(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800011f6:	6605                	lui	a2,0x1
    800011f8:	4581                	li	a1,0
    800011fa:	00000097          	auipc	ra,0x0
    800011fe:	afe080e7          	jalr	-1282(ra) # 80000cf8 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001202:	4699                	li	a3,6
    80001204:	6605                	lui	a2,0x1
    80001206:	100005b7          	lui	a1,0x10000
    8000120a:	10000537          	lui	a0,0x10000
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f96080e7          	jalr	-106(ra) # 800011a4 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001216:	4699                	li	a3,6
    80001218:	6605                	lui	a2,0x1
    8000121a:	100015b7          	lui	a1,0x10001
    8000121e:	10001537          	lui	a0,0x10001
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f82080e7          	jalr	-126(ra) # 800011a4 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6641                	lui	a2,0x10
    8000122e:	020005b7          	lui	a1,0x2000
    80001232:	02000537          	lui	a0,0x2000
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f6e080e7          	jalr	-146(ra) # 800011a4 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	00400637          	lui	a2,0x400
    80001244:	0c0005b7          	lui	a1,0xc000
    80001248:	0c000537          	lui	a0,0xc000
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f58080e7          	jalr	-168(ra) # 800011a4 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001254:	00007497          	auipc	s1,0x7
    80001258:	dac48493          	addi	s1,s1,-596 # 80008000 <etext>
    8000125c:	46a9                	li	a3,10
    8000125e:	80007617          	auipc	a2,0x80007
    80001262:	da260613          	addi	a2,a2,-606 # 8000 <_entry-0x7fff8000>
    80001266:	4585                	li	a1,1
    80001268:	05fe                	slli	a1,a1,0x1f
    8000126a:	852e                	mv	a0,a1
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f38080e7          	jalr	-200(ra) # 800011a4 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	4645                	li	a2,17
    80001278:	066e                	slli	a2,a2,0x1b
    8000127a:	8e05                	sub	a2,a2,s1
    8000127c:	85a6                	mv	a1,s1
    8000127e:	8526                	mv	a0,s1
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f24080e7          	jalr	-220(ra) # 800011a4 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001288:	46a9                	li	a3,10
    8000128a:	6605                	lui	a2,0x1
    8000128c:	00006597          	auipc	a1,0x6
    80001290:	d7458593          	addi	a1,a1,-652 # 80007000 <_trampoline>
    80001294:	04000537          	lui	a0,0x4000
    80001298:	157d                	addi	a0,a0,-1
    8000129a:	0532                	slli	a0,a0,0xc
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f08080e7          	jalr	-248(ra) # 800011a4 <kvmmap>
}
    800012a4:	60e2                	ld	ra,24(sp)
    800012a6:	6442                	ld	s0,16(sp)
    800012a8:	64a2                	ld	s1,8(sp)
    800012aa:	6105                	addi	sp,sp,32
    800012ac:	8082                	ret

00000000800012ae <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ae:	715d                	addi	sp,sp,-80
    800012b0:	e486                	sd	ra,72(sp)
    800012b2:	e0a2                	sd	s0,64(sp)
    800012b4:	fc26                	sd	s1,56(sp)
    800012b6:	f84a                	sd	s2,48(sp)
    800012b8:	f44e                	sd	s3,40(sp)
    800012ba:	f052                	sd	s4,32(sp)
    800012bc:	ec56                	sd	s5,24(sp)
    800012be:	e85a                	sd	s6,16(sp)
    800012c0:	e45e                	sd	s7,8(sp)
    800012c2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c4:	03459793          	slli	a5,a1,0x34
    800012c8:	e795                	bnez	a5,800012f4 <uvmunmap+0x46>
    800012ca:	8a2a                	mv	s4,a0
    800012cc:	892e                	mv	s2,a1
    800012ce:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d0:	0632                	slli	a2,a2,0xc
    800012d2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d8:	6b05                	lui	s6,0x1
    800012da:	0735e263          	bltu	a1,s3,8000133e <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012de:	60a6                	ld	ra,72(sp)
    800012e0:	6406                	ld	s0,64(sp)
    800012e2:	74e2                	ld	s1,56(sp)
    800012e4:	7942                	ld	s2,48(sp)
    800012e6:	79a2                	ld	s3,40(sp)
    800012e8:	7a02                	ld	s4,32(sp)
    800012ea:	6ae2                	ld	s5,24(sp)
    800012ec:	6b42                	ld	s6,16(sp)
    800012ee:	6ba2                	ld	s7,8(sp)
    800012f0:	6161                	addi	sp,sp,80
    800012f2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e1c50513          	addi	a0,a0,-484 # 80008110 <digits+0xd0>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	244080e7          	jalr	580(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001304:	00007517          	auipc	a0,0x7
    80001308:	e2450513          	addi	a0,a0,-476 # 80008128 <digits+0xe8>
    8000130c:	fffff097          	auipc	ra,0xfffff
    80001310:	234080e7          	jalr	564(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001314:	00007517          	auipc	a0,0x7
    80001318:	e2450513          	addi	a0,a0,-476 # 80008138 <digits+0xf8>
    8000131c:	fffff097          	auipc	ra,0xfffff
    80001320:	224080e7          	jalr	548(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001324:	00007517          	auipc	a0,0x7
    80001328:	e2c50513          	addi	a0,a0,-468 # 80008150 <digits+0x110>
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	214080e7          	jalr	532(ra) # 80000540 <panic>
    *pte = 0;
    80001334:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001338:	995a                	add	s2,s2,s6
    8000133a:	fb3972e3          	bgeu	s2,s3,800012de <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000133e:	4601                	li	a2,0
    80001340:	85ca                	mv	a1,s2
    80001342:	8552                	mv	a0,s4
    80001344:	00000097          	auipc	ra,0x0
    80001348:	c8c080e7          	jalr	-884(ra) # 80000fd0 <walk>
    8000134c:	84aa                	mv	s1,a0
    8000134e:	d95d                	beqz	a0,80001304 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001350:	6108                	ld	a0,0(a0)
    80001352:	00157793          	andi	a5,a0,1
    80001356:	dfdd                	beqz	a5,80001314 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001358:	3ff57793          	andi	a5,a0,1023
    8000135c:	fd7784e3          	beq	a5,s7,80001324 <uvmunmap+0x76>
    if(do_free){
    80001360:	fc0a8ae3          	beqz	s5,80001334 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001364:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001366:	0532                	slli	a0,a0,0xc
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	6a8080e7          	jalr	1704(ra) # 80000a10 <kfree>
    80001370:	b7d1                	j	80001334 <uvmunmap+0x86>

0000000080001372 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001372:	1101                	addi	sp,sp,-32
    80001374:	ec06                	sd	ra,24(sp)
    80001376:	e822                	sd	s0,16(sp)
    80001378:	e426                	sd	s1,8(sp)
    8000137a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000137c:	fffff097          	auipc	ra,0xfffff
    80001380:	790080e7          	jalr	1936(ra) # 80000b0c <kalloc>
    80001384:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001386:	c519                	beqz	a0,80001394 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001388:	6605                	lui	a2,0x1
    8000138a:	4581                	li	a1,0
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	96c080e7          	jalr	-1684(ra) # 80000cf8 <memset>
  return pagetable;
}
    80001394:	8526                	mv	a0,s1
    80001396:	60e2                	ld	ra,24(sp)
    80001398:	6442                	ld	s0,16(sp)
    8000139a:	64a2                	ld	s1,8(sp)
    8000139c:	6105                	addi	sp,sp,32
    8000139e:	8082                	ret

00000000800013a0 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013a0:	7179                	addi	sp,sp,-48
    800013a2:	f406                	sd	ra,40(sp)
    800013a4:	f022                	sd	s0,32(sp)
    800013a6:	ec26                	sd	s1,24(sp)
    800013a8:	e84a                	sd	s2,16(sp)
    800013aa:	e44e                	sd	s3,8(sp)
    800013ac:	e052                	sd	s4,0(sp)
    800013ae:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013b0:	6785                	lui	a5,0x1
    800013b2:	04f67863          	bgeu	a2,a5,80001402 <uvminit+0x62>
    800013b6:	8a2a                	mv	s4,a0
    800013b8:	89ae                	mv	s3,a1
    800013ba:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013bc:	fffff097          	auipc	ra,0xfffff
    800013c0:	750080e7          	jalr	1872(ra) # 80000b0c <kalloc>
    800013c4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013c6:	6605                	lui	a2,0x1
    800013c8:	4581                	li	a1,0
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	92e080e7          	jalr	-1746(ra) # 80000cf8 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013d2:	4779                	li	a4,30
    800013d4:	86ca                	mv	a3,s2
    800013d6:	6605                	lui	a2,0x1
    800013d8:	4581                	li	a1,0
    800013da:	8552                	mv	a0,s4
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	d3a080e7          	jalr	-710(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    800013e4:	8626                	mv	a2,s1
    800013e6:	85ce                	mv	a1,s3
    800013e8:	854a                	mv	a0,s2
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	96a080e7          	jalr	-1686(ra) # 80000d54 <memmove>
}
    800013f2:	70a2                	ld	ra,40(sp)
    800013f4:	7402                	ld	s0,32(sp)
    800013f6:	64e2                	ld	s1,24(sp)
    800013f8:	6942                	ld	s2,16(sp)
    800013fa:	69a2                	ld	s3,8(sp)
    800013fc:	6a02                	ld	s4,0(sp)
    800013fe:	6145                	addi	sp,sp,48
    80001400:	8082                	ret
    panic("inituvm: more than a page");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	d6650513          	addi	a0,a0,-666 # 80008168 <digits+0x128>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	136080e7          	jalr	310(ra) # 80000540 <panic>

0000000080001412 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001412:	1101                	addi	sp,sp,-32
    80001414:	ec06                	sd	ra,24(sp)
    80001416:	e822                	sd	s0,16(sp)
    80001418:	e426                	sd	s1,8(sp)
    8000141a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000141c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000141e:	00b67d63          	bgeu	a2,a1,80001438 <uvmdealloc+0x26>
    80001422:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001424:	6785                	lui	a5,0x1
    80001426:	17fd                	addi	a5,a5,-1
    80001428:	00f60733          	add	a4,a2,a5
    8000142c:	767d                	lui	a2,0xfffff
    8000142e:	8f71                	and	a4,a4,a2
    80001430:	97ae                	add	a5,a5,a1
    80001432:	8ff1                	and	a5,a5,a2
    80001434:	00f76863          	bltu	a4,a5,80001444 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001438:	8526                	mv	a0,s1
    8000143a:	60e2                	ld	ra,24(sp)
    8000143c:	6442                	ld	s0,16(sp)
    8000143e:	64a2                	ld	s1,8(sp)
    80001440:	6105                	addi	sp,sp,32
    80001442:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001444:	8f99                	sub	a5,a5,a4
    80001446:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001448:	4685                	li	a3,1
    8000144a:	0007861b          	sext.w	a2,a5
    8000144e:	85ba                	mv	a1,a4
    80001450:	00000097          	auipc	ra,0x0
    80001454:	e5e080e7          	jalr	-418(ra) # 800012ae <uvmunmap>
    80001458:	b7c5                	j	80001438 <uvmdealloc+0x26>

000000008000145a <uvmalloc>:
  if(newsz < oldsz)
    8000145a:	0ab66163          	bltu	a2,a1,800014fc <uvmalloc+0xa2>
{
    8000145e:	7139                	addi	sp,sp,-64
    80001460:	fc06                	sd	ra,56(sp)
    80001462:	f822                	sd	s0,48(sp)
    80001464:	f426                	sd	s1,40(sp)
    80001466:	f04a                	sd	s2,32(sp)
    80001468:	ec4e                	sd	s3,24(sp)
    8000146a:	e852                	sd	s4,16(sp)
    8000146c:	e456                	sd	s5,8(sp)
    8000146e:	0080                	addi	s0,sp,64
    80001470:	8aaa                	mv	s5,a0
    80001472:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001474:	6985                	lui	s3,0x1
    80001476:	19fd                	addi	s3,s3,-1
    80001478:	95ce                	add	a1,a1,s3
    8000147a:	79fd                	lui	s3,0xfffff
    8000147c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001480:	08c9f063          	bgeu	s3,a2,80001500 <uvmalloc+0xa6>
    80001484:	894e                	mv	s2,s3
    mem = kalloc();
    80001486:	fffff097          	auipc	ra,0xfffff
    8000148a:	686080e7          	jalr	1670(ra) # 80000b0c <kalloc>
    8000148e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001490:	c51d                	beqz	a0,800014be <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001492:	6605                	lui	a2,0x1
    80001494:	4581                	li	a1,0
    80001496:	00000097          	auipc	ra,0x0
    8000149a:	862080e7          	jalr	-1950(ra) # 80000cf8 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000149e:	4779                	li	a4,30
    800014a0:	86a6                	mv	a3,s1
    800014a2:	6605                	lui	a2,0x1
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	c6e080e7          	jalr	-914(ra) # 80001116 <mappages>
    800014b0:	e905                	bnez	a0,800014e0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b2:	6785                	lui	a5,0x1
    800014b4:	993e                	add	s2,s2,a5
    800014b6:	fd4968e3          	bltu	s2,s4,80001486 <uvmalloc+0x2c>
  return newsz;
    800014ba:	8552                	mv	a0,s4
    800014bc:	a809                	j	800014ce <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014be:	864e                	mv	a2,s3
    800014c0:	85ca                	mv	a1,s2
    800014c2:	8556                	mv	a0,s5
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	f4e080e7          	jalr	-178(ra) # 80001412 <uvmdealloc>
      return 0;
    800014cc:	4501                	li	a0,0
}
    800014ce:	70e2                	ld	ra,56(sp)
    800014d0:	7442                	ld	s0,48(sp)
    800014d2:	74a2                	ld	s1,40(sp)
    800014d4:	7902                	ld	s2,32(sp)
    800014d6:	69e2                	ld	s3,24(sp)
    800014d8:	6a42                	ld	s4,16(sp)
    800014da:	6aa2                	ld	s5,8(sp)
    800014dc:	6121                	addi	sp,sp,64
    800014de:	8082                	ret
      kfree(mem);
    800014e0:	8526                	mv	a0,s1
    800014e2:	fffff097          	auipc	ra,0xfffff
    800014e6:	52e080e7          	jalr	1326(ra) # 80000a10 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ea:	864e                	mv	a2,s3
    800014ec:	85ca                	mv	a1,s2
    800014ee:	8556                	mv	a0,s5
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	f22080e7          	jalr	-222(ra) # 80001412 <uvmdealloc>
      return 0;
    800014f8:	4501                	li	a0,0
    800014fa:	bfd1                	j	800014ce <uvmalloc+0x74>
    return oldsz;
    800014fc:	852e                	mv	a0,a1
}
    800014fe:	8082                	ret
  return newsz;
    80001500:	8532                	mv	a0,a2
    80001502:	b7f1                	j	800014ce <uvmalloc+0x74>

0000000080001504 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001504:	7179                	addi	sp,sp,-48
    80001506:	f406                	sd	ra,40(sp)
    80001508:	f022                	sd	s0,32(sp)
    8000150a:	ec26                	sd	s1,24(sp)
    8000150c:	e84a                	sd	s2,16(sp)
    8000150e:	e44e                	sd	s3,8(sp)
    80001510:	e052                	sd	s4,0(sp)
    80001512:	1800                	addi	s0,sp,48
    80001514:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001516:	84aa                	mv	s1,a0
    80001518:	6905                	lui	s2,0x1
    8000151a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000151c:	4985                	li	s3,1
    8000151e:	a821                	j	80001536 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001520:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001522:	0532                	slli	a0,a0,0xc
    80001524:	00000097          	auipc	ra,0x0
    80001528:	fe0080e7          	jalr	-32(ra) # 80001504 <freewalk>
      pagetable[i] = 0;
    8000152c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001530:	04a1                	addi	s1,s1,8
    80001532:	03248163          	beq	s1,s2,80001554 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001536:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001538:	00f57793          	andi	a5,a0,15
    8000153c:	ff3782e3          	beq	a5,s3,80001520 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001540:	8905                	andi	a0,a0,1
    80001542:	d57d                	beqz	a0,80001530 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001544:	00007517          	auipc	a0,0x7
    80001548:	c4450513          	addi	a0,a0,-956 # 80008188 <digits+0x148>
    8000154c:	fffff097          	auipc	ra,0xfffff
    80001550:	ff4080e7          	jalr	-12(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001554:	8552                	mv	a0,s4
    80001556:	fffff097          	auipc	ra,0xfffff
    8000155a:	4ba080e7          	jalr	1210(ra) # 80000a10 <kfree>
}
    8000155e:	70a2                	ld	ra,40(sp)
    80001560:	7402                	ld	s0,32(sp)
    80001562:	64e2                	ld	s1,24(sp)
    80001564:	6942                	ld	s2,16(sp)
    80001566:	69a2                	ld	s3,8(sp)
    80001568:	6a02                	ld	s4,0(sp)
    8000156a:	6145                	addi	sp,sp,48
    8000156c:	8082                	ret

000000008000156e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000156e:	1101                	addi	sp,sp,-32
    80001570:	ec06                	sd	ra,24(sp)
    80001572:	e822                	sd	s0,16(sp)
    80001574:	e426                	sd	s1,8(sp)
    80001576:	1000                	addi	s0,sp,32
    80001578:	84aa                	mv	s1,a0
  if(sz > 0)
    8000157a:	e999                	bnez	a1,80001590 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000157c:	8526                	mv	a0,s1
    8000157e:	00000097          	auipc	ra,0x0
    80001582:	f86080e7          	jalr	-122(ra) # 80001504 <freewalk>
}
    80001586:	60e2                	ld	ra,24(sp)
    80001588:	6442                	ld	s0,16(sp)
    8000158a:	64a2                	ld	s1,8(sp)
    8000158c:	6105                	addi	sp,sp,32
    8000158e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001590:	6605                	lui	a2,0x1
    80001592:	167d                	addi	a2,a2,-1
    80001594:	962e                	add	a2,a2,a1
    80001596:	4685                	li	a3,1
    80001598:	8231                	srli	a2,a2,0xc
    8000159a:	4581                	li	a1,0
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	d12080e7          	jalr	-750(ra) # 800012ae <uvmunmap>
    800015a4:	bfe1                	j	8000157c <uvmfree+0xe>

00000000800015a6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015a6:	c679                	beqz	a2,80001674 <uvmcopy+0xce>
{
    800015a8:	715d                	addi	sp,sp,-80
    800015aa:	e486                	sd	ra,72(sp)
    800015ac:	e0a2                	sd	s0,64(sp)
    800015ae:	fc26                	sd	s1,56(sp)
    800015b0:	f84a                	sd	s2,48(sp)
    800015b2:	f44e                	sd	s3,40(sp)
    800015b4:	f052                	sd	s4,32(sp)
    800015b6:	ec56                	sd	s5,24(sp)
    800015b8:	e85a                	sd	s6,16(sp)
    800015ba:	e45e                	sd	s7,8(sp)
    800015bc:	0880                	addi	s0,sp,80
    800015be:	8b2a                	mv	s6,a0
    800015c0:	8aae                	mv	s5,a1
    800015c2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015c4:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015c6:	4601                	li	a2,0
    800015c8:	85ce                	mv	a1,s3
    800015ca:	855a                	mv	a0,s6
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	a04080e7          	jalr	-1532(ra) # 80000fd0 <walk>
    800015d4:	c531                	beqz	a0,80001620 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015d6:	6118                	ld	a4,0(a0)
    800015d8:	00177793          	andi	a5,a4,1
    800015dc:	cbb1                	beqz	a5,80001630 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015de:	00a75593          	srli	a1,a4,0xa
    800015e2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015e6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	522080e7          	jalr	1314(ra) # 80000b0c <kalloc>
    800015f2:	892a                	mv	s2,a0
    800015f4:	c939                	beqz	a0,8000164a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015f6:	6605                	lui	a2,0x1
    800015f8:	85de                	mv	a1,s7
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	75a080e7          	jalr	1882(ra) # 80000d54 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001602:	8726                	mv	a4,s1
    80001604:	86ca                	mv	a3,s2
    80001606:	6605                	lui	a2,0x1
    80001608:	85ce                	mv	a1,s3
    8000160a:	8556                	mv	a0,s5
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	b0a080e7          	jalr	-1270(ra) # 80001116 <mappages>
    80001614:	e515                	bnez	a0,80001640 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001616:	6785                	lui	a5,0x1
    80001618:	99be                	add	s3,s3,a5
    8000161a:	fb49e6e3          	bltu	s3,s4,800015c6 <uvmcopy+0x20>
    8000161e:	a081                	j	8000165e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001620:	00007517          	auipc	a0,0x7
    80001624:	b7850513          	addi	a0,a0,-1160 # 80008198 <digits+0x158>
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	f18080e7          	jalr	-232(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    80001630:	00007517          	auipc	a0,0x7
    80001634:	b8850513          	addi	a0,a0,-1144 # 800081b8 <digits+0x178>
    80001638:	fffff097          	auipc	ra,0xfffff
    8000163c:	f08080e7          	jalr	-248(ra) # 80000540 <panic>
      kfree(mem);
    80001640:	854a                	mv	a0,s2
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	3ce080e7          	jalr	974(ra) # 80000a10 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000164a:	4685                	li	a3,1
    8000164c:	00c9d613          	srli	a2,s3,0xc
    80001650:	4581                	li	a1,0
    80001652:	8556                	mv	a0,s5
    80001654:	00000097          	auipc	ra,0x0
    80001658:	c5a080e7          	jalr	-934(ra) # 800012ae <uvmunmap>
  return -1;
    8000165c:	557d                	li	a0,-1
}
    8000165e:	60a6                	ld	ra,72(sp)
    80001660:	6406                	ld	s0,64(sp)
    80001662:	74e2                	ld	s1,56(sp)
    80001664:	7942                	ld	s2,48(sp)
    80001666:	79a2                	ld	s3,40(sp)
    80001668:	7a02                	ld	s4,32(sp)
    8000166a:	6ae2                	ld	s5,24(sp)
    8000166c:	6b42                	ld	s6,16(sp)
    8000166e:	6ba2                	ld	s7,8(sp)
    80001670:	6161                	addi	sp,sp,80
    80001672:	8082                	ret
  return 0;
    80001674:	4501                	li	a0,0
}
    80001676:	8082                	ret

0000000080001678 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001678:	1141                	addi	sp,sp,-16
    8000167a:	e406                	sd	ra,8(sp)
    8000167c:	e022                	sd	s0,0(sp)
    8000167e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001680:	4601                	li	a2,0
    80001682:	00000097          	auipc	ra,0x0
    80001686:	94e080e7          	jalr	-1714(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000168a:	c901                	beqz	a0,8000169a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000168c:	611c                	ld	a5,0(a0)
    8000168e:	9bbd                	andi	a5,a5,-17
    80001690:	e11c                	sd	a5,0(a0)
}
    80001692:	60a2                	ld	ra,8(sp)
    80001694:	6402                	ld	s0,0(sp)
    80001696:	0141                	addi	sp,sp,16
    80001698:	8082                	ret
    panic("uvmclear");
    8000169a:	00007517          	auipc	a0,0x7
    8000169e:	b3e50513          	addi	a0,a0,-1218 # 800081d8 <digits+0x198>
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	e9e080e7          	jalr	-354(ra) # 80000540 <panic>

00000000800016aa <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016aa:	c6bd                	beqz	a3,80001718 <copyout+0x6e>
{
    800016ac:	715d                	addi	sp,sp,-80
    800016ae:	e486                	sd	ra,72(sp)
    800016b0:	e0a2                	sd	s0,64(sp)
    800016b2:	fc26                	sd	s1,56(sp)
    800016b4:	f84a                	sd	s2,48(sp)
    800016b6:	f44e                	sd	s3,40(sp)
    800016b8:	f052                	sd	s4,32(sp)
    800016ba:	ec56                	sd	s5,24(sp)
    800016bc:	e85a                	sd	s6,16(sp)
    800016be:	e45e                	sd	s7,8(sp)
    800016c0:	e062                	sd	s8,0(sp)
    800016c2:	0880                	addi	s0,sp,80
    800016c4:	8b2a                	mv	s6,a0
    800016c6:	8c2e                	mv	s8,a1
    800016c8:	8a32                	mv	s4,a2
    800016ca:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016cc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ce:	6a85                	lui	s5,0x1
    800016d0:	a015                	j	800016f4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016d2:	9562                	add	a0,a0,s8
    800016d4:	0004861b          	sext.w	a2,s1
    800016d8:	85d2                	mv	a1,s4
    800016da:	41250533          	sub	a0,a0,s2
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	676080e7          	jalr	1654(ra) # 80000d54 <memmove>

    len -= n;
    800016e6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ea:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ec:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016f0:	02098263          	beqz	s3,80001714 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016f4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016f8:	85ca                	mv	a1,s2
    800016fa:	855a                	mv	a0,s6
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	97a080e7          	jalr	-1670(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001704:	cd01                	beqz	a0,8000171c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001706:	418904b3          	sub	s1,s2,s8
    8000170a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000170c:	fc99f3e3          	bgeu	s3,s1,800016d2 <copyout+0x28>
    80001710:	84ce                	mv	s1,s3
    80001712:	b7c1                	j	800016d2 <copyout+0x28>
  }
  return 0;
    80001714:	4501                	li	a0,0
    80001716:	a021                	j	8000171e <copyout+0x74>
    80001718:	4501                	li	a0,0
}
    8000171a:	8082                	ret
      return -1;
    8000171c:	557d                	li	a0,-1
}
    8000171e:	60a6                	ld	ra,72(sp)
    80001720:	6406                	ld	s0,64(sp)
    80001722:	74e2                	ld	s1,56(sp)
    80001724:	7942                	ld	s2,48(sp)
    80001726:	79a2                	ld	s3,40(sp)
    80001728:	7a02                	ld	s4,32(sp)
    8000172a:	6ae2                	ld	s5,24(sp)
    8000172c:	6b42                	ld	s6,16(sp)
    8000172e:	6ba2                	ld	s7,8(sp)
    80001730:	6c02                	ld	s8,0(sp)
    80001732:	6161                	addi	sp,sp,80
    80001734:	8082                	ret

0000000080001736 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001736:	caa5                	beqz	a3,800017a6 <copyin+0x70>
{
    80001738:	715d                	addi	sp,sp,-80
    8000173a:	e486                	sd	ra,72(sp)
    8000173c:	e0a2                	sd	s0,64(sp)
    8000173e:	fc26                	sd	s1,56(sp)
    80001740:	f84a                	sd	s2,48(sp)
    80001742:	f44e                	sd	s3,40(sp)
    80001744:	f052                	sd	s4,32(sp)
    80001746:	ec56                	sd	s5,24(sp)
    80001748:	e85a                	sd	s6,16(sp)
    8000174a:	e45e                	sd	s7,8(sp)
    8000174c:	e062                	sd	s8,0(sp)
    8000174e:	0880                	addi	s0,sp,80
    80001750:	8b2a                	mv	s6,a0
    80001752:	8a2e                	mv	s4,a1
    80001754:	8c32                	mv	s8,a2
    80001756:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001758:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000175a:	6a85                	lui	s5,0x1
    8000175c:	a01d                	j	80001782 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000175e:	018505b3          	add	a1,a0,s8
    80001762:	0004861b          	sext.w	a2,s1
    80001766:	412585b3          	sub	a1,a1,s2
    8000176a:	8552                	mv	a0,s4
    8000176c:	fffff097          	auipc	ra,0xfffff
    80001770:	5e8080e7          	jalr	1512(ra) # 80000d54 <memmove>

    len -= n;
    80001774:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001778:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000177a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000177e:	02098263          	beqz	s3,800017a2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001782:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001786:	85ca                	mv	a1,s2
    80001788:	855a                	mv	a0,s6
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	8ec080e7          	jalr	-1812(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001792:	cd01                	beqz	a0,800017aa <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001794:	418904b3          	sub	s1,s2,s8
    80001798:	94d6                	add	s1,s1,s5
    if(n > len)
    8000179a:	fc99f2e3          	bgeu	s3,s1,8000175e <copyin+0x28>
    8000179e:	84ce                	mv	s1,s3
    800017a0:	bf7d                	j	8000175e <copyin+0x28>
  }
  return 0;
    800017a2:	4501                	li	a0,0
    800017a4:	a021                	j	800017ac <copyin+0x76>
    800017a6:	4501                	li	a0,0
}
    800017a8:	8082                	ret
      return -1;
    800017aa:	557d                	li	a0,-1
}
    800017ac:	60a6                	ld	ra,72(sp)
    800017ae:	6406                	ld	s0,64(sp)
    800017b0:	74e2                	ld	s1,56(sp)
    800017b2:	7942                	ld	s2,48(sp)
    800017b4:	79a2                	ld	s3,40(sp)
    800017b6:	7a02                	ld	s4,32(sp)
    800017b8:	6ae2                	ld	s5,24(sp)
    800017ba:	6b42                	ld	s6,16(sp)
    800017bc:	6ba2                	ld	s7,8(sp)
    800017be:	6c02                	ld	s8,0(sp)
    800017c0:	6161                	addi	sp,sp,80
    800017c2:	8082                	ret

00000000800017c4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017c4:	c6c5                	beqz	a3,8000186c <copyinstr+0xa8>
{
    800017c6:	715d                	addi	sp,sp,-80
    800017c8:	e486                	sd	ra,72(sp)
    800017ca:	e0a2                	sd	s0,64(sp)
    800017cc:	fc26                	sd	s1,56(sp)
    800017ce:	f84a                	sd	s2,48(sp)
    800017d0:	f44e                	sd	s3,40(sp)
    800017d2:	f052                	sd	s4,32(sp)
    800017d4:	ec56                	sd	s5,24(sp)
    800017d6:	e85a                	sd	s6,16(sp)
    800017d8:	e45e                	sd	s7,8(sp)
    800017da:	0880                	addi	s0,sp,80
    800017dc:	8a2a                	mv	s4,a0
    800017de:	8b2e                	mv	s6,a1
    800017e0:	8bb2                	mv	s7,a2
    800017e2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017e4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e6:	6985                	lui	s3,0x1
    800017e8:	a035                	j	80001814 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ea:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ee:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017f0:	0017b793          	seqz	a5,a5
    800017f4:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017f8:	60a6                	ld	ra,72(sp)
    800017fa:	6406                	ld	s0,64(sp)
    800017fc:	74e2                	ld	s1,56(sp)
    800017fe:	7942                	ld	s2,48(sp)
    80001800:	79a2                	ld	s3,40(sp)
    80001802:	7a02                	ld	s4,32(sp)
    80001804:	6ae2                	ld	s5,24(sp)
    80001806:	6b42                	ld	s6,16(sp)
    80001808:	6ba2                	ld	s7,8(sp)
    8000180a:	6161                	addi	sp,sp,80
    8000180c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000180e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001812:	c8a9                	beqz	s1,80001864 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001814:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001818:	85ca                	mv	a1,s2
    8000181a:	8552                	mv	a0,s4
    8000181c:	00000097          	auipc	ra,0x0
    80001820:	85a080e7          	jalr	-1958(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001824:	c131                	beqz	a0,80001868 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001826:	41790833          	sub	a6,s2,s7
    8000182a:	984e                	add	a6,a6,s3
    if(n > max)
    8000182c:	0104f363          	bgeu	s1,a6,80001832 <copyinstr+0x6e>
    80001830:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001832:	955e                	add	a0,a0,s7
    80001834:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001838:	fc080be3          	beqz	a6,8000180e <copyinstr+0x4a>
    8000183c:	985a                	add	a6,a6,s6
    8000183e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001840:	41650633          	sub	a2,a0,s6
    80001844:	14fd                	addi	s1,s1,-1
    80001846:	9b26                	add	s6,s6,s1
    80001848:	00f60733          	add	a4,a2,a5
    8000184c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    80001850:	df49                	beqz	a4,800017ea <copyinstr+0x26>
        *dst = *p;
    80001852:	00e78023          	sb	a4,0(a5)
      --max;
    80001856:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000185a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000185c:	ff0796e3          	bne	a5,a6,80001848 <copyinstr+0x84>
      dst++;
    80001860:	8b42                	mv	s6,a6
    80001862:	b775                	j	8000180e <copyinstr+0x4a>
    80001864:	4781                	li	a5,0
    80001866:	b769                	j	800017f0 <copyinstr+0x2c>
      return -1;
    80001868:	557d                	li	a0,-1
    8000186a:	b779                	j	800017f8 <copyinstr+0x34>
  int got_null = 0;
    8000186c:	4781                	li	a5,0
  if(got_null){
    8000186e:	0017b793          	seqz	a5,a5
    80001872:	40f00533          	neg	a0,a5
}
    80001876:	8082                	ret

0000000080001878 <getportion>:

extern char trampoline[]; // trampoline.S

// Calculate time portion
void getportion(struct proc *p)
{
    80001878:	1141                	addi	sp,sp,-16
    8000187a:	e422                	sd	s0,8(sp)
    8000187c:	0800                	addi	s0,sp,16
  int total = p->end - p->start;
    8000187e:	17852703          	lw	a4,376(a0)
    80001882:	17452603          	lw	a2,372(a0)
    80001886:	40c7063b          	subw	a2,a4,a2

  p->Qtime[2] = p->Qtime[2] * 100 / total;
    8000188a:	06400693          	li	a3,100
    8000188e:	17052783          	lw	a5,368(a0)
    80001892:	02f687bb          	mulw	a5,a3,a5
    80001896:	02c7c7bb          	divw	a5,a5,a2
    8000189a:	16f52823          	sw	a5,368(a0)
  p->Qtime[1] = p->Qtime[1] * 100 / total;
    8000189e:	16c52703          	lw	a4,364(a0)
    800018a2:	02e6873b          	mulw	a4,a3,a4
    800018a6:	02c7473b          	divw	a4,a4,a2
    800018aa:	16e52623          	sw	a4,364(a0)
  p->Qtime[0] = 100 - (p->Qtime[1] + p->Qtime[2]);
    800018ae:	9fb9                	addw	a5,a5,a4
    800018b0:	40f687bb          	subw	a5,a3,a5
    800018b4:	16f52423          	sw	a5,360(a0)
}
    800018b8:	6422                	ld	s0,8(sp)
    800018ba:	0141                	addi	sp,sp,16
    800018bc:	8082                	ret

00000000800018be <findproc>:

// find where 'obj' process resides in
// the Q[priority] queue
int findproc(struct proc *obj, int priority)
{
    800018be:	1141                	addi	sp,sp,-16
    800018c0:	e422                	sd	s0,8(sp)
    800018c2:	0800                	addi	s0,sp,16
  int index = 0;
  while (1)
  {
    if (Q[priority][index] == obj)
    800018c4:	00959713          	slli	a4,a1,0x9
    800018c8:	00010797          	auipc	a5,0x10
    800018cc:	08878793          	addi	a5,a5,136 # 80011950 <Q>
    800018d0:	97ba                	add	a5,a5,a4
    800018d2:	639c                	ld	a5,0(a5)
    800018d4:	02f50263          	beq	a0,a5,800018f8 <findproc+0x3a>
    800018d8:	86aa                	mv	a3,a0
    800018da:	00010797          	auipc	a5,0x10
    800018de:	07e78793          	addi	a5,a5,126 # 80011958 <Q+0x8>
    800018e2:	97ba                	add	a5,a5,a4
  int index = 0;
    800018e4:	4501                	li	a0,0
      break;
    index++;
    800018e6:	2505                	addiw	a0,a0,1
    if (Q[priority][index] == obj)
    800018e8:	07a1                	addi	a5,a5,8
    800018ea:	ff87b703          	ld	a4,-8(a5)
    800018ee:	fed71ce3          	bne	a4,a3,800018e6 <findproc+0x28>
  }
  return index;
}
    800018f2:	6422                	ld	s0,8(sp)
    800018f4:	0141                	addi	sp,sp,16
    800018f6:	8082                	ret
  int index = 0;
    800018f8:	4501                	li	a0,0
    800018fa:	bfe5                	j	800018f2 <findproc+0x34>

00000000800018fc <movequeue>:

// handle process change
void movequeue(struct proc *obj, int priority, int opt)
{
    800018fc:	7179                	addi	sp,sp,-48
    800018fe:	f406                	sd	ra,40(sp)
    80001900:	f022                	sd	s0,32(sp)
    80001902:	ec26                	sd	s1,24(sp)
    80001904:	e84a                	sd	s2,16(sp)
    80001906:	e44e                	sd	s3,8(sp)
    80001908:	1800                	addi	s0,sp,48
    8000190a:	84aa                	mv	s1,a0
    8000190c:	892e                	mv	s2,a1
  // INSERT means pushing process to empty process
  // so doesn't need to handle this operation
  if (opt != INSERT)
    8000190e:	4785                	li	a5,1
    80001910:	06f60163          	beq	a2,a5,80001972 <movequeue+0x76>
    80001914:	89b2                	mv	s3,a2
  {
    // delete the obj process from queue where it was in
    // and pull up the processes behind
    // obj process is in Q[obj.priority][pos]
    int pos = findproc(obj, obj->priority);
    80001916:	17c52583          	lw	a1,380(a0)
    8000191a:	00000097          	auipc	ra,0x0
    8000191e:	fa4080e7          	jalr	-92(ra) # 800018be <findproc>
    for (int i = pos; i < NPROC - 1; i++)
    80001922:	03e00793          	li	a5,62
    80001926:	02a7c863          	blt	a5,a0,80001956 <movequeue+0x5a>
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    8000192a:	00010697          	auipc	a3,0x10
    8000192e:	02668693          	addi	a3,a3,38 # 80011950 <Q>
    for (int i = pos; i < NPROC - 1; i++)
    80001932:	03f00593          	li	a1,63
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    80001936:	17c4a783          	lw	a5,380(s1)
    8000193a:	862a                	mv	a2,a0
    8000193c:	2505                	addiw	a0,a0,1
    8000193e:	079a                	slli	a5,a5,0x6
    80001940:	00a78733          	add	a4,a5,a0
    80001944:	070e                	slli	a4,a4,0x3
    80001946:	9736                	add	a4,a4,a3
    80001948:	6318                	ld	a4,0(a4)
    8000194a:	97b2                	add	a5,a5,a2
    8000194c:	078e                	slli	a5,a5,0x3
    8000194e:	97b6                	add	a5,a5,a3
    80001950:	e398                	sd	a4,0(a5)
    for (int i = pos; i < NPROC - 1; i++)
    80001952:	feb512e3          	bne	a0,a1,80001936 <movequeue+0x3a>
    Q[obj->priority][NPROC - 1] = 0;
    80001956:	17c4a783          	lw	a5,380(s1)
    8000195a:	00979713          	slli	a4,a5,0x9
    8000195e:	00010797          	auipc	a5,0x10
    80001962:	ff278793          	addi	a5,a5,-14 # 80011950 <Q>
    80001966:	97ba                	add	a5,a5,a4
    80001968:	1e07bc23          	sd	zero,504(a5)
  }

  // DELETE means just delete the process from all Qs,
  // so doesn't have to handle this operation
  if (opt != DELETE)
    8000196c:	4789                	li	a5,2
    8000196e:	02f98463          	beq	s3,a5,80001996 <movequeue+0x9a>
  {
    // insert obj process in another queue. insertback
    // endstart indicates the position right after the tail
    // which can be found by finding NULL process in the queue
    int endstart = findproc(0, priority);
    80001972:	85ca                	mv	a1,s2
    80001974:	4501                	li	a0,0
    80001976:	00000097          	auipc	ra,0x0
    8000197a:	f48080e7          	jalr	-184(ra) # 800018be <findproc>
    Q[priority][endstart] = obj;
    8000197e:	00691793          	slli	a5,s2,0x6
    80001982:	97aa                	add	a5,a5,a0
    80001984:	078e                	slli	a5,a5,0x3
    80001986:	00010717          	auipc	a4,0x10
    8000198a:	fca70713          	addi	a4,a4,-54 # 80011950 <Q>
    8000198e:	97ba                	add	a5,a5,a4
    80001990:	e384                	sd	s1,0(a5)
    obj->priority = priority;
    80001992:	1724ae23          	sw	s2,380(s1)
  }
}
    80001996:	70a2                	ld	ra,40(sp)
    80001998:	7402                	ld	s0,32(sp)
    8000199a:	64e2                	ld	s1,24(sp)
    8000199c:	6942                	ld	s2,16(sp)
    8000199e:	69a2                	ld	s3,8(sp)
    800019a0:	6145                	addi	sp,sp,48
    800019a2:	8082                	ret

00000000800019a4 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800019a4:	1101                	addi	sp,sp,-32
    800019a6:	ec06                	sd	ra,24(sp)
    800019a8:	e822                	sd	s0,16(sp)
    800019aa:	e426                	sd	s1,8(sp)
    800019ac:	1000                	addi	s0,sp,32
    800019ae:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	1d2080e7          	jalr	466(ra) # 80000b82 <holding>
    800019b8:	c909                	beqz	a0,800019ca <wakeup1+0x26>
    panic("wakeup1");
  if (p->chan == p && p->state == SLEEPING)
    800019ba:	749c                	ld	a5,40(s1)
    800019bc:	00978f63          	beq	a5,s1,800019da <wakeup1+0x36>
  {
    p->state = RUNNABLE;
    // should be moved to Q2
    movequeue(p, 2, MOVE);
  }
}
    800019c0:	60e2                	ld	ra,24(sp)
    800019c2:	6442                	ld	s0,16(sp)
    800019c4:	64a2                	ld	s1,8(sp)
    800019c6:	6105                	addi	sp,sp,32
    800019c8:	8082                	ret
    panic("wakeup1");
    800019ca:	00007517          	auipc	a0,0x7
    800019ce:	81e50513          	addi	a0,a0,-2018 # 800081e8 <digits+0x1a8>
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	b6e080e7          	jalr	-1170(ra) # 80000540 <panic>
  if (p->chan == p && p->state == SLEEPING)
    800019da:	4c98                	lw	a4,24(s1)
    800019dc:	4785                	li	a5,1
    800019de:	fef711e3          	bne	a4,a5,800019c0 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019e2:	4789                	li	a5,2
    800019e4:	cc9c                	sw	a5,24(s1)
    movequeue(p, 2, MOVE);
    800019e6:	4601                	li	a2,0
    800019e8:	4589                	li	a1,2
    800019ea:	8526                	mv	a0,s1
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	f10080e7          	jalr	-240(ra) # 800018fc <movequeue>
}
    800019f4:	b7f1                	j	800019c0 <wakeup1+0x1c>

00000000800019f6 <procinit>:
{
    800019f6:	715d                	addi	sp,sp,-80
    800019f8:	e486                	sd	ra,72(sp)
    800019fa:	e0a2                	sd	s0,64(sp)
    800019fc:	fc26                	sd	s1,56(sp)
    800019fe:	f84a                	sd	s2,48(sp)
    80001a00:	f44e                	sd	s3,40(sp)
    80001a02:	f052                	sd	s4,32(sp)
    80001a04:	ec56                	sd	s5,24(sp)
    80001a06:	e85a                	sd	s6,16(sp)
    80001a08:	e45e                	sd	s7,8(sp)
    80001a0a:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a0c:	00006597          	auipc	a1,0x6
    80001a10:	7e458593          	addi	a1,a1,2020 # 800081f0 <digits+0x1b0>
    80001a14:	00010517          	auipc	a0,0x10
    80001a18:	53c50513          	addi	a0,a0,1340 # 80011f50 <pid_lock>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	150080e7          	jalr	336(ra) # 80000b6c <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a24:	00011917          	auipc	s2,0x11
    80001a28:	94490913          	addi	s2,s2,-1724 # 80012368 <proc>
    initlock(&p->lock, "proc");
    80001a2c:	00006b97          	auipc	s7,0x6
    80001a30:	7ccb8b93          	addi	s7,s7,1996 # 800081f8 <digits+0x1b8>
    uint64 va = KSTACK((int)(p - proc));
    80001a34:	8b4a                	mv	s6,s2
    80001a36:	00006a97          	auipc	s5,0x6
    80001a3a:	5caa8a93          	addi	s5,s5,1482 # 80008000 <etext>
    80001a3e:	040009b7          	lui	s3,0x4000
    80001a42:	19fd                	addi	s3,s3,-1
    80001a44:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a46:	00017a17          	auipc	s4,0x17
    80001a4a:	922a0a13          	addi	s4,s4,-1758 # 80018368 <tickslock>
    initlock(&p->lock, "proc");
    80001a4e:	85de                	mv	a1,s7
    80001a50:	854a                	mv	a0,s2
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	11a080e7          	jalr	282(ra) # 80000b6c <initlock>
    char *pa = kalloc();
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	0b2080e7          	jalr	178(ra) # 80000b0c <kalloc>
    80001a62:	85aa                	mv	a1,a0
    if (pa == 0)
    80001a64:	c929                	beqz	a0,80001ab6 <procinit+0xc0>
    uint64 va = KSTACK((int)(p - proc));
    80001a66:	416904b3          	sub	s1,s2,s6
    80001a6a:	849d                	srai	s1,s1,0x7
    80001a6c:	000ab783          	ld	a5,0(s5)
    80001a70:	02f484b3          	mul	s1,s1,a5
    80001a74:	2485                	addiw	s1,s1,1
    80001a76:	00d4949b          	slliw	s1,s1,0xd
    80001a7a:	409984b3          	sub	s1,s3,s1
    kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a7e:	4699                	li	a3,6
    80001a80:	6605                	lui	a2,0x1
    80001a82:	8526                	mv	a0,s1
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	720080e7          	jalr	1824(ra) # 800011a4 <kvmmap>
    p->kstack = va;
    80001a8c:	04993023          	sd	s1,64(s2)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a90:	18090913          	addi	s2,s2,384
    80001a94:	fb491de3          	bne	s2,s4,80001a4e <procinit+0x58>
  kvminithart();
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	514080e7          	jalr	1300(ra) # 80000fac <kvminithart>
}
    80001aa0:	60a6                	ld	ra,72(sp)
    80001aa2:	6406                	ld	s0,64(sp)
    80001aa4:	74e2                	ld	s1,56(sp)
    80001aa6:	7942                	ld	s2,48(sp)
    80001aa8:	79a2                	ld	s3,40(sp)
    80001aaa:	7a02                	ld	s4,32(sp)
    80001aac:	6ae2                	ld	s5,24(sp)
    80001aae:	6b42                	ld	s6,16(sp)
    80001ab0:	6ba2                	ld	s7,8(sp)
    80001ab2:	6161                	addi	sp,sp,80
    80001ab4:	8082                	ret
      panic("kalloc");
    80001ab6:	00006517          	auipc	a0,0x6
    80001aba:	74a50513          	addi	a0,a0,1866 # 80008200 <digits+0x1c0>
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	a82080e7          	jalr	-1406(ra) # 80000540 <panic>

0000000080001ac6 <cpuid>:
{
    80001ac6:	1141                	addi	sp,sp,-16
    80001ac8:	e422                	sd	s0,8(sp)
    80001aca:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001acc:	8512                	mv	a0,tp
}
    80001ace:	2501                	sext.w	a0,a0
    80001ad0:	6422                	ld	s0,8(sp)
    80001ad2:	0141                	addi	sp,sp,16
    80001ad4:	8082                	ret

0000000080001ad6 <mycpu>:
{
    80001ad6:	1141                	addi	sp,sp,-16
    80001ad8:	e422                	sd	s0,8(sp)
    80001ada:	0800                	addi	s0,sp,16
    80001adc:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ade:	2781                	sext.w	a5,a5
    80001ae0:	079e                	slli	a5,a5,0x7
}
    80001ae2:	00010517          	auipc	a0,0x10
    80001ae6:	48650513          	addi	a0,a0,1158 # 80011f68 <cpus>
    80001aea:	953e                	add	a0,a0,a5
    80001aec:	6422                	ld	s0,8(sp)
    80001aee:	0141                	addi	sp,sp,16
    80001af0:	8082                	ret

0000000080001af2 <myproc>:
{
    80001af2:	1101                	addi	sp,sp,-32
    80001af4:	ec06                	sd	ra,24(sp)
    80001af6:	e822                	sd	s0,16(sp)
    80001af8:	e426                	sd	s1,8(sp)
    80001afa:	1000                	addi	s0,sp,32
  push_off();
    80001afc:	fffff097          	auipc	ra,0xfffff
    80001b00:	0b4080e7          	jalr	180(ra) # 80000bb0 <push_off>
    80001b04:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b06:	2781                	sext.w	a5,a5
    80001b08:	079e                	slli	a5,a5,0x7
    80001b0a:	00010717          	auipc	a4,0x10
    80001b0e:	e4670713          	addi	a4,a4,-442 # 80011950 <Q>
    80001b12:	97ba                	add	a5,a5,a4
    80001b14:	6187b483          	ld	s1,1560(a5)
  pop_off();
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	138080e7          	jalr	312(ra) # 80000c50 <pop_off>
}
    80001b20:	8526                	mv	a0,s1
    80001b22:	60e2                	ld	ra,24(sp)
    80001b24:	6442                	ld	s0,16(sp)
    80001b26:	64a2                	ld	s1,8(sp)
    80001b28:	6105                	addi	sp,sp,32
    80001b2a:	8082                	ret

0000000080001b2c <forkret>:
{
    80001b2c:	1141                	addi	sp,sp,-16
    80001b2e:	e406                	sd	ra,8(sp)
    80001b30:	e022                	sd	s0,0(sp)
    80001b32:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	fbe080e7          	jalr	-66(ra) # 80001af2 <myproc>
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	174080e7          	jalr	372(ra) # 80000cb0 <release>
  if (first)
    80001b44:	00007797          	auipc	a5,0x7
    80001b48:	d1c7a783          	lw	a5,-740(a5) # 80008860 <first.1>
    80001b4c:	eb89                	bnez	a5,80001b5e <forkret+0x32>
  usertrapret();
    80001b4e:	00001097          	auipc	ra,0x1
    80001b52:	d58080e7          	jalr	-680(ra) # 800028a6 <usertrapret>
}
    80001b56:	60a2                	ld	ra,8(sp)
    80001b58:	6402                	ld	s0,0(sp)
    80001b5a:	0141                	addi	sp,sp,16
    80001b5c:	8082                	ret
    first = 0;
    80001b5e:	00007797          	auipc	a5,0x7
    80001b62:	d007a123          	sw	zero,-766(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001b66:	4505                	li	a0,1
    80001b68:	00002097          	auipc	ra,0x2
    80001b6c:	ac4080e7          	jalr	-1340(ra) # 8000362c <fsinit>
    80001b70:	bff9                	j	80001b4e <forkret+0x22>

0000000080001b72 <allocpid>:
{
    80001b72:	1101                	addi	sp,sp,-32
    80001b74:	ec06                	sd	ra,24(sp)
    80001b76:	e822                	sd	s0,16(sp)
    80001b78:	e426                	sd	s1,8(sp)
    80001b7a:	e04a                	sd	s2,0(sp)
    80001b7c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b7e:	00010917          	auipc	s2,0x10
    80001b82:	3d290913          	addi	s2,s2,978 # 80011f50 <pid_lock>
    80001b86:	854a                	mv	a0,s2
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	074080e7          	jalr	116(ra) # 80000bfc <acquire>
  pid = nextpid;
    80001b90:	00007797          	auipc	a5,0x7
    80001b94:	cd478793          	addi	a5,a5,-812 # 80008864 <nextpid>
    80001b98:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b9a:	0014871b          	addiw	a4,s1,1
    80001b9e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ba0:	854a                	mv	a0,s2
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	10e080e7          	jalr	270(ra) # 80000cb0 <release>
}
    80001baa:	8526                	mv	a0,s1
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6902                	ld	s2,0(sp)
    80001bb4:	6105                	addi	sp,sp,32
    80001bb6:	8082                	ret

0000000080001bb8 <proc_pagetable>:
{
    80001bb8:	1101                	addi	sp,sp,-32
    80001bba:	ec06                	sd	ra,24(sp)
    80001bbc:	e822                	sd	s0,16(sp)
    80001bbe:	e426                	sd	s1,8(sp)
    80001bc0:	e04a                	sd	s2,0(sp)
    80001bc2:	1000                	addi	s0,sp,32
    80001bc4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	7ac080e7          	jalr	1964(ra) # 80001372 <uvmcreate>
    80001bce:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bd0:	c121                	beqz	a0,80001c10 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bd2:	4729                	li	a4,10
    80001bd4:	00005697          	auipc	a3,0x5
    80001bd8:	42c68693          	addi	a3,a3,1068 # 80007000 <_trampoline>
    80001bdc:	6605                	lui	a2,0x1
    80001bde:	040005b7          	lui	a1,0x4000
    80001be2:	15fd                	addi	a1,a1,-1
    80001be4:	05b2                	slli	a1,a1,0xc
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	530080e7          	jalr	1328(ra) # 80001116 <mappages>
    80001bee:	02054863          	bltz	a0,80001c1e <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bf2:	4719                	li	a4,6
    80001bf4:	05893683          	ld	a3,88(s2)
    80001bf8:	6605                	lui	a2,0x1
    80001bfa:	020005b7          	lui	a1,0x2000
    80001bfe:	15fd                	addi	a1,a1,-1
    80001c00:	05b6                	slli	a1,a1,0xd
    80001c02:	8526                	mv	a0,s1
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	512080e7          	jalr	1298(ra) # 80001116 <mappages>
    80001c0c:	02054163          	bltz	a0,80001c2e <proc_pagetable+0x76>
}
    80001c10:	8526                	mv	a0,s1
    80001c12:	60e2                	ld	ra,24(sp)
    80001c14:	6442                	ld	s0,16(sp)
    80001c16:	64a2                	ld	s1,8(sp)
    80001c18:	6902                	ld	s2,0(sp)
    80001c1a:	6105                	addi	sp,sp,32
    80001c1c:	8082                	ret
    uvmfree(pagetable, 0);
    80001c1e:	4581                	li	a1,0
    80001c20:	8526                	mv	a0,s1
    80001c22:	00000097          	auipc	ra,0x0
    80001c26:	94c080e7          	jalr	-1716(ra) # 8000156e <uvmfree>
    return 0;
    80001c2a:	4481                	li	s1,0
    80001c2c:	b7d5                	j	80001c10 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c2e:	4681                	li	a3,0
    80001c30:	4605                	li	a2,1
    80001c32:	040005b7          	lui	a1,0x4000
    80001c36:	15fd                	addi	a1,a1,-1
    80001c38:	05b2                	slli	a1,a1,0xc
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	672080e7          	jalr	1650(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001c44:	4581                	li	a1,0
    80001c46:	8526                	mv	a0,s1
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	926080e7          	jalr	-1754(ra) # 8000156e <uvmfree>
    return 0;
    80001c50:	4481                	li	s1,0
    80001c52:	bf7d                	j	80001c10 <proc_pagetable+0x58>

0000000080001c54 <proc_freepagetable>:
{
    80001c54:	1101                	addi	sp,sp,-32
    80001c56:	ec06                	sd	ra,24(sp)
    80001c58:	e822                	sd	s0,16(sp)
    80001c5a:	e426                	sd	s1,8(sp)
    80001c5c:	e04a                	sd	s2,0(sp)
    80001c5e:	1000                	addi	s0,sp,32
    80001c60:	84aa                	mv	s1,a0
    80001c62:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c64:	4681                	li	a3,0
    80001c66:	4605                	li	a2,1
    80001c68:	040005b7          	lui	a1,0x4000
    80001c6c:	15fd                	addi	a1,a1,-1
    80001c6e:	05b2                	slli	a1,a1,0xc
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	63e080e7          	jalr	1598(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c78:	4681                	li	a3,0
    80001c7a:	4605                	li	a2,1
    80001c7c:	020005b7          	lui	a1,0x2000
    80001c80:	15fd                	addi	a1,a1,-1
    80001c82:	05b6                	slli	a1,a1,0xd
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	628080e7          	jalr	1576(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001c8e:	85ca                	mv	a1,s2
    80001c90:	8526                	mv	a0,s1
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	8dc080e7          	jalr	-1828(ra) # 8000156e <uvmfree>
}
    80001c9a:	60e2                	ld	ra,24(sp)
    80001c9c:	6442                	ld	s0,16(sp)
    80001c9e:	64a2                	ld	s1,8(sp)
    80001ca0:	6902                	ld	s2,0(sp)
    80001ca2:	6105                	addi	sp,sp,32
    80001ca4:	8082                	ret

0000000080001ca6 <freeproc>:
{
    80001ca6:	1101                	addi	sp,sp,-32
    80001ca8:	ec06                	sd	ra,24(sp)
    80001caa:	e822                	sd	s0,16(sp)
    80001cac:	e426                	sd	s1,8(sp)
    80001cae:	1000                	addi	s0,sp,32
    80001cb0:	84aa                	mv	s1,a0
  p->end = ticks;
    80001cb2:	00007797          	auipc	a5,0x7
    80001cb6:	36e7a783          	lw	a5,878(a5) # 80009020 <ticks>
    80001cba:	16f52c23          	sw	a5,376(a0)
  getportion(p);
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	bba080e7          	jalr	-1094(ra) # 80001878 <getportion>
  printf("%s (pid=%d): Q2(%d%%), Q1(%d%%), Q0(%d%%)\n",
    80001cc6:	1684a783          	lw	a5,360(s1)
    80001cca:	16c4a703          	lw	a4,364(s1)
    80001cce:	1704a683          	lw	a3,368(s1)
    80001cd2:	5c90                	lw	a2,56(s1)
    80001cd4:	15848593          	addi	a1,s1,344
    80001cd8:	00006517          	auipc	a0,0x6
    80001cdc:	53050513          	addi	a0,a0,1328 # 80008208 <digits+0x1c8>
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	8aa080e7          	jalr	-1878(ra) # 8000058a <printf>
  if (p->trapframe)
    80001ce8:	6ca8                	ld	a0,88(s1)
    80001cea:	c509                	beqz	a0,80001cf4 <freeproc+0x4e>
    kfree((void *)p->trapframe);
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	d24080e7          	jalr	-732(ra) # 80000a10 <kfree>
  p->trapframe = 0;
    80001cf4:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001cf8:	68a8                	ld	a0,80(s1)
    80001cfa:	c511                	beqz	a0,80001d06 <freeproc+0x60>
    proc_freepagetable(p->pagetable, p->sz);
    80001cfc:	64ac                	ld	a1,72(s1)
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	f56080e7          	jalr	-170(ra) # 80001c54 <proc_freepagetable>
  p->pagetable = 0;
    80001d06:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d0a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d0e:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d12:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d16:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d1a:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d1e:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d22:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d26:	0004ac23          	sw	zero,24(s1)
  p->Qtime[2] = 0;
    80001d2a:	1604a823          	sw	zero,368(s1)
  p->Qtime[1] = 0;
    80001d2e:	1604a623          	sw	zero,364(s1)
  p->Qtime[0] = 0;
    80001d32:	1604a423          	sw	zero,360(s1)
  p->priority = 0;
    80001d36:	1604ae23          	sw	zero,380(s1)
  movequeue(p, 0, DELETE);
    80001d3a:	4609                	li	a2,2
    80001d3c:	4581                	li	a1,0
    80001d3e:	8526                	mv	a0,s1
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	bbc080e7          	jalr	-1092(ra) # 800018fc <movequeue>
}
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret

0000000080001d52 <allocproc>:
{
    80001d52:	1101                	addi	sp,sp,-32
    80001d54:	ec06                	sd	ra,24(sp)
    80001d56:	e822                	sd	s0,16(sp)
    80001d58:	e426                	sd	s1,8(sp)
    80001d5a:	e04a                	sd	s2,0(sp)
    80001d5c:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d5e:	00010497          	auipc	s1,0x10
    80001d62:	60a48493          	addi	s1,s1,1546 # 80012368 <proc>
    80001d66:	00016917          	auipc	s2,0x16
    80001d6a:	60290913          	addi	s2,s2,1538 # 80018368 <tickslock>
    acquire(&p->lock);
    80001d6e:	8526                	mv	a0,s1
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	e8c080e7          	jalr	-372(ra) # 80000bfc <acquire>
    if (p->state == UNUSED)
    80001d78:	4c9c                	lw	a5,24(s1)
    80001d7a:	cf81                	beqz	a5,80001d92 <allocproc+0x40>
      release(&p->lock);
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	f32080e7          	jalr	-206(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d86:	18048493          	addi	s1,s1,384
    80001d8a:	ff2492e3          	bne	s1,s2,80001d6e <allocproc+0x1c>
  return 0;
    80001d8e:	4481                	li	s1,0
    80001d90:	a0a5                	j	80001df8 <allocproc+0xa6>
  p->pid = allocpid();
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	de0080e7          	jalr	-544(ra) # 80001b72 <allocpid>
    80001d9a:	dc88                	sw	a0,56(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	d70080e7          	jalr	-656(ra) # 80000b0c <kalloc>
    80001da4:	892a                	mv	s2,a0
    80001da6:	eca8                	sd	a0,88(s1)
    80001da8:	cd39                	beqz	a0,80001e06 <allocproc+0xb4>
  p->pagetable = proc_pagetable(p);
    80001daa:	8526                	mv	a0,s1
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	e0c080e7          	jalr	-500(ra) # 80001bb8 <proc_pagetable>
    80001db4:	892a                	mv	s2,a0
    80001db6:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001db8:	cd31                	beqz	a0,80001e14 <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001dba:	07000613          	li	a2,112
    80001dbe:	4581                	li	a1,0
    80001dc0:	06048513          	addi	a0,s1,96
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	f34080e7          	jalr	-204(ra) # 80000cf8 <memset>
  p->context.ra = (uint64)forkret;
    80001dcc:	00000797          	auipc	a5,0x0
    80001dd0:	d6078793          	addi	a5,a5,-672 # 80001b2c <forkret>
    80001dd4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dd6:	60bc                	ld	a5,64(s1)
    80001dd8:	6705                	lui	a4,0x1
    80001dda:	97ba                	add	a5,a5,a4
    80001ddc:	f4bc                	sd	a5,104(s1)
  p->start = ticks;
    80001dde:	00007797          	auipc	a5,0x7
    80001de2:	2427a783          	lw	a5,578(a5) # 80009020 <ticks>
    80001de6:	16f4aa23          	sw	a5,372(s1)
  movequeue(p, 2, INSERT);
    80001dea:	4605                	li	a2,1
    80001dec:	4589                	li	a1,2
    80001dee:	8526                	mv	a0,s1
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	b0c080e7          	jalr	-1268(ra) # 800018fc <movequeue>
}
    80001df8:	8526                	mv	a0,s1
    80001dfa:	60e2                	ld	ra,24(sp)
    80001dfc:	6442                	ld	s0,16(sp)
    80001dfe:	64a2                	ld	s1,8(sp)
    80001e00:	6902                	ld	s2,0(sp)
    80001e02:	6105                	addi	sp,sp,32
    80001e04:	8082                	ret
    release(&p->lock);
    80001e06:	8526                	mv	a0,s1
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	ea8080e7          	jalr	-344(ra) # 80000cb0 <release>
    return 0;
    80001e10:	84ca                	mv	s1,s2
    80001e12:	b7dd                	j	80001df8 <allocproc+0xa6>
    freeproc(p);
    80001e14:	8526                	mv	a0,s1
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	e90080e7          	jalr	-368(ra) # 80001ca6 <freeproc>
    release(&p->lock);
    80001e1e:	8526                	mv	a0,s1
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	e90080e7          	jalr	-368(ra) # 80000cb0 <release>
    return 0;
    80001e28:	84ca                	mv	s1,s2
    80001e2a:	b7f9                	j	80001df8 <allocproc+0xa6>

0000000080001e2c <userinit>:
{
    80001e2c:	1101                	addi	sp,sp,-32
    80001e2e:	ec06                	sd	ra,24(sp)
    80001e30:	e822                	sd	s0,16(sp)
    80001e32:	e426                	sd	s1,8(sp)
    80001e34:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	f1c080e7          	jalr	-228(ra) # 80001d52 <allocproc>
    80001e3e:	84aa                	mv	s1,a0
  initproc = p;
    80001e40:	00007797          	auipc	a5,0x7
    80001e44:	1ca7bc23          	sd	a0,472(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e48:	03400613          	li	a2,52
    80001e4c:	00007597          	auipc	a1,0x7
    80001e50:	a2458593          	addi	a1,a1,-1500 # 80008870 <initcode>
    80001e54:	6928                	ld	a0,80(a0)
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	54a080e7          	jalr	1354(ra) # 800013a0 <uvminit>
  p->sz = PGSIZE;
    80001e5e:	6785                	lui	a5,0x1
    80001e60:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e62:	6cb8                	ld	a4,88(s1)
    80001e64:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e68:	6cb8                	ld	a4,88(s1)
    80001e6a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e6c:	4641                	li	a2,16
    80001e6e:	00006597          	auipc	a1,0x6
    80001e72:	3ca58593          	addi	a1,a1,970 # 80008238 <digits+0x1f8>
    80001e76:	15848513          	addi	a0,s1,344
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	fd0080e7          	jalr	-48(ra) # 80000e4a <safestrcpy>
  p->cwd = namei("/");
    80001e82:	00006517          	auipc	a0,0x6
    80001e86:	3c650513          	addi	a0,a0,966 # 80008248 <digits+0x208>
    80001e8a:	00002097          	auipc	ra,0x2
    80001e8e:	1ca080e7          	jalr	458(ra) # 80004054 <namei>
    80001e92:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e96:	4789                	li	a5,2
    80001e98:	cc9c                	sw	a5,24(s1)
  p->Qtime[2] = 0;
    80001e9a:	1604a823          	sw	zero,368(s1)
  p->Qtime[1] = 0;
    80001e9e:	1604a623          	sw	zero,364(s1)
  p->Qtime[0] = 0;
    80001ea2:	1604a423          	sw	zero,360(s1)
  release(&p->lock);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	e08080e7          	jalr	-504(ra) # 80000cb0 <release>
}
    80001eb0:	60e2                	ld	ra,24(sp)
    80001eb2:	6442                	ld	s0,16(sp)
    80001eb4:	64a2                	ld	s1,8(sp)
    80001eb6:	6105                	addi	sp,sp,32
    80001eb8:	8082                	ret

0000000080001eba <growproc>:
{
    80001eba:	1101                	addi	sp,sp,-32
    80001ebc:	ec06                	sd	ra,24(sp)
    80001ebe:	e822                	sd	s0,16(sp)
    80001ec0:	e426                	sd	s1,8(sp)
    80001ec2:	e04a                	sd	s2,0(sp)
    80001ec4:	1000                	addi	s0,sp,32
    80001ec6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	c2a080e7          	jalr	-982(ra) # 80001af2 <myproc>
    80001ed0:	892a                	mv	s2,a0
  sz = p->sz;
    80001ed2:	652c                	ld	a1,72(a0)
    80001ed4:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001ed8:	00904f63          	bgtz	s1,80001ef6 <growproc+0x3c>
  else if (n < 0)
    80001edc:	0204cc63          	bltz	s1,80001f14 <growproc+0x5a>
  p->sz = sz;
    80001ee0:	1602                	slli	a2,a2,0x20
    80001ee2:	9201                	srli	a2,a2,0x20
    80001ee4:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ee8:	4501                	li	a0,0
}
    80001eea:	60e2                	ld	ra,24(sp)
    80001eec:	6442                	ld	s0,16(sp)
    80001eee:	64a2                	ld	s1,8(sp)
    80001ef0:	6902                	ld	s2,0(sp)
    80001ef2:	6105                	addi	sp,sp,32
    80001ef4:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001ef6:	9e25                	addw	a2,a2,s1
    80001ef8:	1602                	slli	a2,a2,0x20
    80001efa:	9201                	srli	a2,a2,0x20
    80001efc:	1582                	slli	a1,a1,0x20
    80001efe:	9181                	srli	a1,a1,0x20
    80001f00:	6928                	ld	a0,80(a0)
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	558080e7          	jalr	1368(ra) # 8000145a <uvmalloc>
    80001f0a:	0005061b          	sext.w	a2,a0
    80001f0e:	fa69                	bnez	a2,80001ee0 <growproc+0x26>
      return -1;
    80001f10:	557d                	li	a0,-1
    80001f12:	bfe1                	j	80001eea <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f14:	9e25                	addw	a2,a2,s1
    80001f16:	1602                	slli	a2,a2,0x20
    80001f18:	9201                	srli	a2,a2,0x20
    80001f1a:	1582                	slli	a1,a1,0x20
    80001f1c:	9181                	srli	a1,a1,0x20
    80001f1e:	6928                	ld	a0,80(a0)
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	4f2080e7          	jalr	1266(ra) # 80001412 <uvmdealloc>
    80001f28:	0005061b          	sext.w	a2,a0
    80001f2c:	bf55                	j	80001ee0 <growproc+0x26>

0000000080001f2e <fork>:
{
    80001f2e:	7139                	addi	sp,sp,-64
    80001f30:	fc06                	sd	ra,56(sp)
    80001f32:	f822                	sd	s0,48(sp)
    80001f34:	f426                	sd	s1,40(sp)
    80001f36:	f04a                	sd	s2,32(sp)
    80001f38:	ec4e                	sd	s3,24(sp)
    80001f3a:	e852                	sd	s4,16(sp)
    80001f3c:	e456                	sd	s5,8(sp)
    80001f3e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f40:	00000097          	auipc	ra,0x0
    80001f44:	bb2080e7          	jalr	-1102(ra) # 80001af2 <myproc>
    80001f48:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	e08080e7          	jalr	-504(ra) # 80001d52 <allocproc>
    80001f52:	c96d                	beqz	a0,80002044 <fork+0x116>
    80001f54:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f56:	048ab603          	ld	a2,72(s5)
    80001f5a:	692c                	ld	a1,80(a0)
    80001f5c:	050ab503          	ld	a0,80(s5)
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	646080e7          	jalr	1606(ra) # 800015a6 <uvmcopy>
    80001f68:	04054a63          	bltz	a0,80001fbc <fork+0x8e>
  np->sz = p->sz;
    80001f6c:	048ab783          	ld	a5,72(s5)
    80001f70:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f74:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f78:	058ab683          	ld	a3,88(s5)
    80001f7c:	87b6                	mv	a5,a3
    80001f7e:	0589b703          	ld	a4,88(s3)
    80001f82:	12068693          	addi	a3,a3,288
    80001f86:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f8a:	6788                	ld	a0,8(a5)
    80001f8c:	6b8c                	ld	a1,16(a5)
    80001f8e:	6f90                	ld	a2,24(a5)
    80001f90:	01073023          	sd	a6,0(a4)
    80001f94:	e708                	sd	a0,8(a4)
    80001f96:	eb0c                	sd	a1,16(a4)
    80001f98:	ef10                	sd	a2,24(a4)
    80001f9a:	02078793          	addi	a5,a5,32
    80001f9e:	02070713          	addi	a4,a4,32
    80001fa2:	fed792e3          	bne	a5,a3,80001f86 <fork+0x58>
  np->trapframe->a0 = 0;
    80001fa6:	0589b783          	ld	a5,88(s3)
    80001faa:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001fae:	0d0a8493          	addi	s1,s5,208
    80001fb2:	0d098913          	addi	s2,s3,208
    80001fb6:	150a8a13          	addi	s4,s5,336
    80001fba:	a00d                	j	80001fdc <fork+0xae>
    freeproc(np);
    80001fbc:	854e                	mv	a0,s3
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	ce8080e7          	jalr	-792(ra) # 80001ca6 <freeproc>
    release(&np->lock);
    80001fc6:	854e                	mv	a0,s3
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	ce8080e7          	jalr	-792(ra) # 80000cb0 <release>
    return -1;
    80001fd0:	54fd                	li	s1,-1
    80001fd2:	a8b9                	j	80002030 <fork+0x102>
  for (i = 0; i < NOFILE; i++)
    80001fd4:	04a1                	addi	s1,s1,8
    80001fd6:	0921                	addi	s2,s2,8
    80001fd8:	01448b63          	beq	s1,s4,80001fee <fork+0xc0>
    if (p->ofile[i])
    80001fdc:	6088                	ld	a0,0(s1)
    80001fde:	d97d                	beqz	a0,80001fd4 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fe0:	00002097          	auipc	ra,0x2
    80001fe4:	704080e7          	jalr	1796(ra) # 800046e4 <filedup>
    80001fe8:	00a93023          	sd	a0,0(s2)
    80001fec:	b7e5                	j	80001fd4 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001fee:	150ab503          	ld	a0,336(s5)
    80001ff2:	00002097          	auipc	ra,0x2
    80001ff6:	874080e7          	jalr	-1932(ra) # 80003866 <idup>
    80001ffa:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ffe:	4641                	li	a2,16
    80002000:	158a8593          	addi	a1,s5,344
    80002004:	15898513          	addi	a0,s3,344
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	e42080e7          	jalr	-446(ra) # 80000e4a <safestrcpy>
  pid = np->pid;
    80002010:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002014:	4789                	li	a5,2
    80002016:	00f9ac23          	sw	a5,24(s3)
  np->Qtime[2] = 0;
    8000201a:	1609a823          	sw	zero,368(s3)
  np->Qtime[1] = 0;
    8000201e:	1609a623          	sw	zero,364(s3)
  np->Qtime[0] = 0;
    80002022:	1609a423          	sw	zero,360(s3)
  release(&np->lock);
    80002026:	854e                	mv	a0,s3
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	c88080e7          	jalr	-888(ra) # 80000cb0 <release>
}
    80002030:	8526                	mv	a0,s1
    80002032:	70e2                	ld	ra,56(sp)
    80002034:	7442                	ld	s0,48(sp)
    80002036:	74a2                	ld	s1,40(sp)
    80002038:	7902                	ld	s2,32(sp)
    8000203a:	69e2                	ld	s3,24(sp)
    8000203c:	6a42                	ld	s4,16(sp)
    8000203e:	6aa2                	ld	s5,8(sp)
    80002040:	6121                	addi	sp,sp,64
    80002042:	8082                	ret
    return -1;
    80002044:	54fd                	li	s1,-1
    80002046:	b7ed                	j	80002030 <fork+0x102>

0000000080002048 <reparent>:
{
    80002048:	7179                	addi	sp,sp,-48
    8000204a:	f406                	sd	ra,40(sp)
    8000204c:	f022                	sd	s0,32(sp)
    8000204e:	ec26                	sd	s1,24(sp)
    80002050:	e84a                	sd	s2,16(sp)
    80002052:	e44e                	sd	s3,8(sp)
    80002054:	e052                	sd	s4,0(sp)
    80002056:	1800                	addi	s0,sp,48
    80002058:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000205a:	00010497          	auipc	s1,0x10
    8000205e:	30e48493          	addi	s1,s1,782 # 80012368 <proc>
      pp->parent = initproc;
    80002062:	00007a17          	auipc	s4,0x7
    80002066:	fb6a0a13          	addi	s4,s4,-74 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000206a:	00016997          	auipc	s3,0x16
    8000206e:	2fe98993          	addi	s3,s3,766 # 80018368 <tickslock>
    80002072:	a029                	j	8000207c <reparent+0x34>
    80002074:	18048493          	addi	s1,s1,384
    80002078:	03348363          	beq	s1,s3,8000209e <reparent+0x56>
    if (pp->parent == p)
    8000207c:	709c                	ld	a5,32(s1)
    8000207e:	ff279be3          	bne	a5,s2,80002074 <reparent+0x2c>
      acquire(&pp->lock);
    80002082:	8526                	mv	a0,s1
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	b78080e7          	jalr	-1160(ra) # 80000bfc <acquire>
      pp->parent = initproc;
    8000208c:	000a3783          	ld	a5,0(s4)
    80002090:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002092:	8526                	mv	a0,s1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	c1c080e7          	jalr	-996(ra) # 80000cb0 <release>
    8000209c:	bfe1                	j	80002074 <reparent+0x2c>
}
    8000209e:	70a2                	ld	ra,40(sp)
    800020a0:	7402                	ld	s0,32(sp)
    800020a2:	64e2                	ld	s1,24(sp)
    800020a4:	6942                	ld	s2,16(sp)
    800020a6:	69a2                	ld	s3,8(sp)
    800020a8:	6a02                	ld	s4,0(sp)
    800020aa:	6145                	addi	sp,sp,48
    800020ac:	8082                	ret

00000000800020ae <scheduler>:
{
    800020ae:	711d                	addi	sp,sp,-96
    800020b0:	ec86                	sd	ra,88(sp)
    800020b2:	e8a2                	sd	s0,80(sp)
    800020b4:	e4a6                	sd	s1,72(sp)
    800020b6:	e0ca                	sd	s2,64(sp)
    800020b8:	fc4e                	sd	s3,56(sp)
    800020ba:	f852                	sd	s4,48(sp)
    800020bc:	f456                	sd	s5,40(sp)
    800020be:	f05a                	sd	s6,32(sp)
    800020c0:	ec5e                	sd	s7,24(sp)
    800020c2:	e862                	sd	s8,16(sp)
    800020c4:	e466                	sd	s9,8(sp)
    800020c6:	1080                	addi	s0,sp,96
    800020c8:	8792                	mv	a5,tp
  int id = r_tp();
    800020ca:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020cc:	00779b93          	slli	s7,a5,0x7
    800020d0:	00010717          	auipc	a4,0x10
    800020d4:	88070713          	addi	a4,a4,-1920 # 80011950 <Q>
    800020d8:	975e                	add	a4,a4,s7
    800020da:	60073c23          	sd	zero,1560(a4)
        swtch(&c->context, &p->context);
    800020de:	00010717          	auipc	a4,0x10
    800020e2:	e9270713          	addi	a4,a4,-366 # 80011f70 <cpus+0x8>
    800020e6:	9bba                	add	s7,s7,a4
  int exec = 0;
    800020e8:	4b01                	li	s6,0
    for (int i = 0; i < findproc(0, 2); i++)
    800020ea:	4a01                	li	s4,0
        p->state = RUNNING;
    800020ec:	4c0d                	li	s8,3
        c->proc = p;
    800020ee:	00010c97          	auipc	s9,0x10
    800020f2:	862c8c93          	addi	s9,s9,-1950 # 80011950 <Q>
    800020f6:	079e                	slli	a5,a5,0x7
    800020f8:	00fc8ab3          	add	s5,s9,a5
    800020fc:	a049                	j	8000217e <scheduler+0xd0>
      exec = 0;
    800020fe:	8b52                	mv	s6,s4
    80002100:	a8bd                	j	8000217e <scheduler+0xd0>
      release(&p->lock);
    80002102:	8526                	mv	a0,s1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	bac080e7          	jalr	-1108(ra) # 80000cb0 <release>
    for (int i = 0; i < findproc(0, 2); i++)
    8000210c:	2905                	addiw	s2,s2,1
    8000210e:	09a1                	addi	s3,s3,8
    80002110:	4589                	li	a1,2
    80002112:	8552                	mv	a0,s4
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	7aa080e7          	jalr	1962(ra) # 800018be <findproc>
    8000211c:	02a95c63          	bge	s2,a0,80002154 <scheduler+0xa6>
      p = Q[2][i];
    80002120:	0009b483          	ld	s1,0(s3)
      if (p == 0)
    80002124:	c885                	beqz	s1,80002154 <scheduler+0xa6>
      acquire(&p->lock);
    80002126:	8526                	mv	a0,s1
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	ad4080e7          	jalr	-1324(ra) # 80000bfc <acquire>
      if (p->state == RUNNABLE)
    80002130:	4c98                	lw	a4,24(s1)
    80002132:	4789                	li	a5,2
    80002134:	fcf717e3          	bne	a4,a5,80002102 <scheduler+0x54>
        p->state = RUNNING;
    80002138:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    8000213c:	609abc23          	sd	s1,1560(s5)
        swtch(&c->context, &p->context);
    80002140:	06048593          	addi	a1,s1,96
    80002144:	855e                	mv	a0,s7
    80002146:	00000097          	auipc	ra,0x0
    8000214a:	6b6080e7          	jalr	1718(ra) # 800027fc <swtch>
        c->proc = 0;
    8000214e:	600abc23          	sd	zero,1560(s5)
    80002152:	bf45                	j	80002102 <scheduler+0x54>
    p = Q[1][exec];
    80002154:	040b0793          	addi	a5,s6,64 # 1040 <_entry-0x7fffefc0>
    80002158:	078e                	slli	a5,a5,0x3
    8000215a:	97e6                	add	a5,a5,s9
    8000215c:	6384                	ld	s1,0(a5)
    if (p == 0)
    8000215e:	d0c5                	beqz	s1,800020fe <scheduler+0x50>
    acquire(&p->lock);
    80002160:	8526                	mv	a0,s1
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	a9a080e7          	jalr	-1382(ra) # 80000bfc <acquire>
    if (p->state == RUNNABLE)
    8000216a:	4c98                	lw	a4,24(s1)
    8000216c:	4789                	li	a5,2
    8000216e:	02f70463          	beq	a4,a5,80002196 <scheduler+0xe8>
    release(&p->lock);
    80002172:	8526                	mv	a0,s1
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	b3c080e7          	jalr	-1220(ra) # 80000cb0 <release>
    exec++;   
    8000217c:	2b05                	addiw	s6,s6,1
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000217e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002182:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002186:	10079073          	csrw	sstatus,a5
    for (int i = 0; i < findproc(0, 2); i++)
    8000218a:	00010997          	auipc	s3,0x10
    8000218e:	bc698993          	addi	s3,s3,-1082 # 80011d50 <Q+0x400>
    80002192:	8952                	mv	s2,s4
    80002194:	bfb5                	j	80002110 <scheduler+0x62>
      p->state = RUNNING;
    80002196:	0184ac23          	sw	s8,24(s1)
      c->proc = p;
    8000219a:	609abc23          	sd	s1,1560(s5)
      swtch(&c->context, &p->context);   
    8000219e:	06048593          	addi	a1,s1,96
    800021a2:	855e                	mv	a0,s7
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	658080e7          	jalr	1624(ra) # 800027fc <swtch>
      c->proc = 0;
    800021ac:	600abc23          	sd	zero,1560(s5)
    800021b0:	b7c9                	j	80002172 <scheduler+0xc4>

00000000800021b2 <sched>:
{
    800021b2:	7179                	addi	sp,sp,-48
    800021b4:	f406                	sd	ra,40(sp)
    800021b6:	f022                	sd	s0,32(sp)
    800021b8:	ec26                	sd	s1,24(sp)
    800021ba:	e84a                	sd	s2,16(sp)
    800021bc:	e44e                	sd	s3,8(sp)
    800021be:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	932080e7          	jalr	-1742(ra) # 80001af2 <myproc>
    800021c8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	9b8080e7          	jalr	-1608(ra) # 80000b82 <holding>
    800021d2:	c93d                	beqz	a0,80002248 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021d4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800021d6:	2781                	sext.w	a5,a5
    800021d8:	079e                	slli	a5,a5,0x7
    800021da:	0000f717          	auipc	a4,0xf
    800021de:	77670713          	addi	a4,a4,1910 # 80011950 <Q>
    800021e2:	97ba                	add	a5,a5,a4
    800021e4:	6907a703          	lw	a4,1680(a5)
    800021e8:	4785                	li	a5,1
    800021ea:	06f71763          	bne	a4,a5,80002258 <sched+0xa6>
  if (p->state == RUNNING)
    800021ee:	4c98                	lw	a4,24(s1)
    800021f0:	478d                	li	a5,3
    800021f2:	06f70b63          	beq	a4,a5,80002268 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021f6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021fa:	8b89                	andi	a5,a5,2
  if (intr_get())
    800021fc:	efb5                	bnez	a5,80002278 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021fe:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002200:	0000f917          	auipc	s2,0xf
    80002204:	75090913          	addi	s2,s2,1872 # 80011950 <Q>
    80002208:	2781                	sext.w	a5,a5
    8000220a:	079e                	slli	a5,a5,0x7
    8000220c:	97ca                	add	a5,a5,s2
    8000220e:	6947a983          	lw	s3,1684(a5)
    80002212:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002214:	2781                	sext.w	a5,a5
    80002216:	079e                	slli	a5,a5,0x7
    80002218:	00010597          	auipc	a1,0x10
    8000221c:	d5858593          	addi	a1,a1,-680 # 80011f70 <cpus+0x8>
    80002220:	95be                	add	a1,a1,a5
    80002222:	06048513          	addi	a0,s1,96
    80002226:	00000097          	auipc	ra,0x0
    8000222a:	5d6080e7          	jalr	1494(ra) # 800027fc <swtch>
    8000222e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002230:	2781                	sext.w	a5,a5
    80002232:	079e                	slli	a5,a5,0x7
    80002234:	97ca                	add	a5,a5,s2
    80002236:	6937aa23          	sw	s3,1684(a5)
}
    8000223a:	70a2                	ld	ra,40(sp)
    8000223c:	7402                	ld	s0,32(sp)
    8000223e:	64e2                	ld	s1,24(sp)
    80002240:	6942                	ld	s2,16(sp)
    80002242:	69a2                	ld	s3,8(sp)
    80002244:	6145                	addi	sp,sp,48
    80002246:	8082                	ret
    panic("sched p->lock");
    80002248:	00006517          	auipc	a0,0x6
    8000224c:	00850513          	addi	a0,a0,8 # 80008250 <digits+0x210>
    80002250:	ffffe097          	auipc	ra,0xffffe
    80002254:	2f0080e7          	jalr	752(ra) # 80000540 <panic>
    panic("sched locks");
    80002258:	00006517          	auipc	a0,0x6
    8000225c:	00850513          	addi	a0,a0,8 # 80008260 <digits+0x220>
    80002260:	ffffe097          	auipc	ra,0xffffe
    80002264:	2e0080e7          	jalr	736(ra) # 80000540 <panic>
    panic("sched running");
    80002268:	00006517          	auipc	a0,0x6
    8000226c:	00850513          	addi	a0,a0,8 # 80008270 <digits+0x230>
    80002270:	ffffe097          	auipc	ra,0xffffe
    80002274:	2d0080e7          	jalr	720(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002278:	00006517          	auipc	a0,0x6
    8000227c:	00850513          	addi	a0,a0,8 # 80008280 <digits+0x240>
    80002280:	ffffe097          	auipc	ra,0xffffe
    80002284:	2c0080e7          	jalr	704(ra) # 80000540 <panic>

0000000080002288 <exit>:
{
    80002288:	7179                	addi	sp,sp,-48
    8000228a:	f406                	sd	ra,40(sp)
    8000228c:	f022                	sd	s0,32(sp)
    8000228e:	ec26                	sd	s1,24(sp)
    80002290:	e84a                	sd	s2,16(sp)
    80002292:	e44e                	sd	s3,8(sp)
    80002294:	e052                	sd	s4,0(sp)
    80002296:	1800                	addi	s0,sp,48
    80002298:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	858080e7          	jalr	-1960(ra) # 80001af2 <myproc>
    800022a2:	89aa                	mv	s3,a0
  if (p == initproc)
    800022a4:	00007797          	auipc	a5,0x7
    800022a8:	d747b783          	ld	a5,-652(a5) # 80009018 <initproc>
    800022ac:	0d050493          	addi	s1,a0,208
    800022b0:	15050913          	addi	s2,a0,336
    800022b4:	02a79363          	bne	a5,a0,800022da <exit+0x52>
    panic("init exiting");
    800022b8:	00006517          	auipc	a0,0x6
    800022bc:	fe050513          	addi	a0,a0,-32 # 80008298 <digits+0x258>
    800022c0:	ffffe097          	auipc	ra,0xffffe
    800022c4:	280080e7          	jalr	640(ra) # 80000540 <panic>
      fileclose(f);
    800022c8:	00002097          	auipc	ra,0x2
    800022cc:	46e080e7          	jalr	1134(ra) # 80004736 <fileclose>
      p->ofile[fd] = 0;
    800022d0:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800022d4:	04a1                	addi	s1,s1,8
    800022d6:	01248563          	beq	s1,s2,800022e0 <exit+0x58>
    if (p->ofile[fd])
    800022da:	6088                	ld	a0,0(s1)
    800022dc:	f575                	bnez	a0,800022c8 <exit+0x40>
    800022de:	bfdd                	j	800022d4 <exit+0x4c>
  begin_op();
    800022e0:	00002097          	auipc	ra,0x2
    800022e4:	f84080e7          	jalr	-124(ra) # 80004264 <begin_op>
  iput(p->cwd);
    800022e8:	1509b503          	ld	a0,336(s3)
    800022ec:	00001097          	auipc	ra,0x1
    800022f0:	772080e7          	jalr	1906(ra) # 80003a5e <iput>
  end_op();
    800022f4:	00002097          	auipc	ra,0x2
    800022f8:	ff0080e7          	jalr	-16(ra) # 800042e4 <end_op>
  p->cwd = 0;
    800022fc:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002300:	00007497          	auipc	s1,0x7
    80002304:	d1848493          	addi	s1,s1,-744 # 80009018 <initproc>
    80002308:	6088                	ld	a0,0(s1)
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8f2080e7          	jalr	-1806(ra) # 80000bfc <acquire>
  wakeup1(initproc);
    80002312:	6088                	ld	a0,0(s1)
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	690080e7          	jalr	1680(ra) # 800019a4 <wakeup1>
  release(&initproc->lock);
    8000231c:	6088                	ld	a0,0(s1)
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	992080e7          	jalr	-1646(ra) # 80000cb0 <release>
  acquire(&p->lock);
    80002326:	854e                	mv	a0,s3
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	8d4080e7          	jalr	-1836(ra) # 80000bfc <acquire>
  struct proc *original_parent = p->parent;
    80002330:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002334:	854e                	mv	a0,s3
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	97a080e7          	jalr	-1670(ra) # 80000cb0 <release>
  acquire(&original_parent->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	8bc080e7          	jalr	-1860(ra) # 80000bfc <acquire>
  acquire(&p->lock);
    80002348:	854e                	mv	a0,s3
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	8b2080e7          	jalr	-1870(ra) # 80000bfc <acquire>
  reparent(p);
    80002352:	854e                	mv	a0,s3
    80002354:	00000097          	auipc	ra,0x0
    80002358:	cf4080e7          	jalr	-780(ra) # 80002048 <reparent>
  wakeup1(original_parent);
    8000235c:	8526                	mv	a0,s1
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	646080e7          	jalr	1606(ra) # 800019a4 <wakeup1>
  p->xstate = status;
    80002366:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000236a:	4791                	li	a5,4
    8000236c:	00f9ac23          	sw	a5,24(s3)
  movequeue(p, 0, MOVE);
    80002370:	4601                	li	a2,0
    80002372:	4581                	li	a1,0
    80002374:	854e                	mv	a0,s3
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	586080e7          	jalr	1414(ra) # 800018fc <movequeue>
  release(&original_parent->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	930080e7          	jalr	-1744(ra) # 80000cb0 <release>
  sched();
    80002388:	00000097          	auipc	ra,0x0
    8000238c:	e2a080e7          	jalr	-470(ra) # 800021b2 <sched>
  panic("zombie exit");
    80002390:	00006517          	auipc	a0,0x6
    80002394:	f1850513          	addi	a0,a0,-232 # 800082a8 <digits+0x268>
    80002398:	ffffe097          	auipc	ra,0xffffe
    8000239c:	1a8080e7          	jalr	424(ra) # 80000540 <panic>

00000000800023a0 <yield>:
{
    800023a0:	1101                	addi	sp,sp,-32
    800023a2:	ec06                	sd	ra,24(sp)
    800023a4:	e822                	sd	s0,16(sp)
    800023a6:	e426                	sd	s1,8(sp)
    800023a8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	748080e7          	jalr	1864(ra) # 80001af2 <myproc>
    800023b2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	848080e7          	jalr	-1976(ra) # 80000bfc <acquire>
  p->state = RUNNABLE;
    800023bc:	4789                	li	a5,2
    800023be:	cc9c                	sw	a5,24(s1)
  if (p->priority == 2)
    800023c0:	17c4a703          	lw	a4,380(s1)
    800023c4:	02f70363          	beq	a4,a5,800023ea <yield+0x4a>
  else if(p->priority == 1)
    800023c8:	4785                	li	a5,1
    800023ca:	02f70d63          	beq	a4,a5,80002404 <yield+0x64>
  sched();
    800023ce:	00000097          	auipc	ra,0x0
    800023d2:	de4080e7          	jalr	-540(ra) # 800021b2 <sched>
  release(&p->lock);
    800023d6:	8526                	mv	a0,s1
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	8d8080e7          	jalr	-1832(ra) # 80000cb0 <release>
}
    800023e0:	60e2                	ld	ra,24(sp)
    800023e2:	6442                	ld	s0,16(sp)
    800023e4:	64a2                	ld	s1,8(sp)
    800023e6:	6105                	addi	sp,sp,32
    800023e8:	8082                	ret
    movequeue(p, 1, MOVE);
    800023ea:	4601                	li	a2,0
    800023ec:	4585                	li	a1,1
    800023ee:	8526                	mv	a0,s1
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	50c080e7          	jalr	1292(ra) # 800018fc <movequeue>
    p->Qtime[2] = p->Qtime[2] + 1;
    800023f8:	1704a783          	lw	a5,368(s1)
    800023fc:	2785                	addiw	a5,a5,1
    800023fe:	16f4a823          	sw	a5,368(s1)
    80002402:	b7f1                	j	800023ce <yield+0x2e>
    p->Qtime[1] = p->Qtime[1] + 1;
    80002404:	16c4a783          	lw	a5,364(s1)
    80002408:	2785                	addiw	a5,a5,1
    8000240a:	16f4a623          	sw	a5,364(s1)
    8000240e:	b7c1                	j	800023ce <yield+0x2e>

0000000080002410 <sleep>:
{
    80002410:	7179                	addi	sp,sp,-48
    80002412:	f406                	sd	ra,40(sp)
    80002414:	f022                	sd	s0,32(sp)
    80002416:	ec26                	sd	s1,24(sp)
    80002418:	e84a                	sd	s2,16(sp)
    8000241a:	e44e                	sd	s3,8(sp)
    8000241c:	1800                	addi	s0,sp,48
    8000241e:	89aa                	mv	s3,a0
    80002420:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	6d0080e7          	jalr	1744(ra) # 80001af2 <myproc>
    8000242a:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    8000242c:	05250d63          	beq	a0,s2,80002486 <sleep+0x76>
    acquire(&p->lock); //DOC: sleeplock1
    80002430:	ffffe097          	auipc	ra,0xffffe
    80002434:	7cc080e7          	jalr	1996(ra) # 80000bfc <acquire>
    release(lk);
    80002438:	854a                	mv	a0,s2
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	876080e7          	jalr	-1930(ra) # 80000cb0 <release>
  p->chan = chan;
    80002442:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002446:	4785                	li	a5,1
    80002448:	cc9c                	sw	a5,24(s1)
  movequeue(p, 0, MOVE);
    8000244a:	4601                	li	a2,0
    8000244c:	4581                	li	a1,0
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	4ac080e7          	jalr	1196(ra) # 800018fc <movequeue>
  sched();
    80002458:	00000097          	auipc	ra,0x0
    8000245c:	d5a080e7          	jalr	-678(ra) # 800021b2 <sched>
  p->chan = 0;
    80002460:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	84a080e7          	jalr	-1974(ra) # 80000cb0 <release>
    acquire(lk);
    8000246e:	854a                	mv	a0,s2
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	78c080e7          	jalr	1932(ra) # 80000bfc <acquire>
}
    80002478:	70a2                	ld	ra,40(sp)
    8000247a:	7402                	ld	s0,32(sp)
    8000247c:	64e2                	ld	s1,24(sp)
    8000247e:	6942                	ld	s2,16(sp)
    80002480:	69a2                	ld	s3,8(sp)
    80002482:	6145                	addi	sp,sp,48
    80002484:	8082                	ret
  p->chan = chan;
    80002486:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000248a:	4785                	li	a5,1
    8000248c:	cd1c                	sw	a5,24(a0)
  movequeue(p, 0, MOVE);
    8000248e:	4601                	li	a2,0
    80002490:	4581                	li	a1,0
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	46a080e7          	jalr	1130(ra) # 800018fc <movequeue>
  sched();
    8000249a:	00000097          	auipc	ra,0x0
    8000249e:	d18080e7          	jalr	-744(ra) # 800021b2 <sched>
  p->chan = 0;
    800024a2:	0204b423          	sd	zero,40(s1)
  if (lk != &p->lock)
    800024a6:	bfc9                	j	80002478 <sleep+0x68>

00000000800024a8 <wait>:
{
    800024a8:	715d                	addi	sp,sp,-80
    800024aa:	e486                	sd	ra,72(sp)
    800024ac:	e0a2                	sd	s0,64(sp)
    800024ae:	fc26                	sd	s1,56(sp)
    800024b0:	f84a                	sd	s2,48(sp)
    800024b2:	f44e                	sd	s3,40(sp)
    800024b4:	f052                	sd	s4,32(sp)
    800024b6:	ec56                	sd	s5,24(sp)
    800024b8:	e85a                	sd	s6,16(sp)
    800024ba:	e45e                	sd	s7,8(sp)
    800024bc:	0880                	addi	s0,sp,80
    800024be:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	632080e7          	jalr	1586(ra) # 80001af2 <myproc>
    800024c8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	732080e7          	jalr	1842(ra) # 80000bfc <acquire>
    havekids = 0;
    800024d2:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800024d4:	4a11                	li	s4,4
        havekids = 1;
    800024d6:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800024d8:	00016997          	auipc	s3,0x16
    800024dc:	e9098993          	addi	s3,s3,-368 # 80018368 <tickslock>
    havekids = 0;
    800024e0:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800024e2:	00010497          	auipc	s1,0x10
    800024e6:	e8648493          	addi	s1,s1,-378 # 80012368 <proc>
    800024ea:	a08d                	j	8000254c <wait+0xa4>
          pid = np->pid;
    800024ec:	0384a983          	lw	s3,56(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024f0:	000b0e63          	beqz	s6,8000250c <wait+0x64>
    800024f4:	4691                	li	a3,4
    800024f6:	03448613          	addi	a2,s1,52
    800024fa:	85da                	mv	a1,s6
    800024fc:	05093503          	ld	a0,80(s2)
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	1aa080e7          	jalr	426(ra) # 800016aa <copyout>
    80002508:	02054263          	bltz	a0,8000252c <wait+0x84>
          freeproc(np);
    8000250c:	8526                	mv	a0,s1
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	798080e7          	jalr	1944(ra) # 80001ca6 <freeproc>
          release(&np->lock);
    80002516:	8526                	mv	a0,s1
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	798080e7          	jalr	1944(ra) # 80000cb0 <release>
          release(&p->lock);
    80002520:	854a                	mv	a0,s2
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	78e080e7          	jalr	1934(ra) # 80000cb0 <release>
          return pid;
    8000252a:	a8a9                	j	80002584 <wait+0xdc>
            release(&np->lock);
    8000252c:	8526                	mv	a0,s1
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	782080e7          	jalr	1922(ra) # 80000cb0 <release>
            release(&p->lock);
    80002536:	854a                	mv	a0,s2
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	778080e7          	jalr	1912(ra) # 80000cb0 <release>
            return -1;
    80002540:	59fd                	li	s3,-1
    80002542:	a089                	j	80002584 <wait+0xdc>
    for (np = proc; np < &proc[NPROC]; np++)
    80002544:	18048493          	addi	s1,s1,384
    80002548:	03348463          	beq	s1,s3,80002570 <wait+0xc8>
      if (np->parent == p)
    8000254c:	709c                	ld	a5,32(s1)
    8000254e:	ff279be3          	bne	a5,s2,80002544 <wait+0x9c>
        acquire(&np->lock);
    80002552:	8526                	mv	a0,s1
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	6a8080e7          	jalr	1704(ra) # 80000bfc <acquire>
        if (np->state == ZOMBIE)
    8000255c:	4c9c                	lw	a5,24(s1)
    8000255e:	f94787e3          	beq	a5,s4,800024ec <wait+0x44>
        release(&np->lock);
    80002562:	8526                	mv	a0,s1
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	74c080e7          	jalr	1868(ra) # 80000cb0 <release>
        havekids = 1;
    8000256c:	8756                	mv	a4,s5
    8000256e:	bfd9                	j	80002544 <wait+0x9c>
    if (!havekids || p->killed)
    80002570:	c701                	beqz	a4,80002578 <wait+0xd0>
    80002572:	03092783          	lw	a5,48(s2)
    80002576:	c39d                	beqz	a5,8000259c <wait+0xf4>
      release(&p->lock);
    80002578:	854a                	mv	a0,s2
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	736080e7          	jalr	1846(ra) # 80000cb0 <release>
      return -1;
    80002582:	59fd                	li	s3,-1
}
    80002584:	854e                	mv	a0,s3
    80002586:	60a6                	ld	ra,72(sp)
    80002588:	6406                	ld	s0,64(sp)
    8000258a:	74e2                	ld	s1,56(sp)
    8000258c:	7942                	ld	s2,48(sp)
    8000258e:	79a2                	ld	s3,40(sp)
    80002590:	7a02                	ld	s4,32(sp)
    80002592:	6ae2                	ld	s5,24(sp)
    80002594:	6b42                	ld	s6,16(sp)
    80002596:	6ba2                	ld	s7,8(sp)
    80002598:	6161                	addi	sp,sp,80
    8000259a:	8082                	ret
    sleep(p, &p->lock); //DOC: wait-sleep
    8000259c:	85ca                	mv	a1,s2
    8000259e:	854a                	mv	a0,s2
    800025a0:	00000097          	auipc	ra,0x0
    800025a4:	e70080e7          	jalr	-400(ra) # 80002410 <sleep>
    havekids = 0;
    800025a8:	bf25                	j	800024e0 <wait+0x38>

00000000800025aa <wakeup>:
{
    800025aa:	7139                	addi	sp,sp,-64
    800025ac:	fc06                	sd	ra,56(sp)
    800025ae:	f822                	sd	s0,48(sp)
    800025b0:	f426                	sd	s1,40(sp)
    800025b2:	f04a                	sd	s2,32(sp)
    800025b4:	ec4e                	sd	s3,24(sp)
    800025b6:	e852                	sd	s4,16(sp)
    800025b8:	e456                	sd	s5,8(sp)
    800025ba:	0080                	addi	s0,sp,64
    800025bc:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    800025be:	00010497          	auipc	s1,0x10
    800025c2:	daa48493          	addi	s1,s1,-598 # 80012368 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    800025c6:	4985                	li	s3,1
      p->state = RUNNABLE;
    800025c8:	4a89                	li	s5,2
  for (p = proc; p < &proc[NPROC]; p++)
    800025ca:	00016917          	auipc	s2,0x16
    800025ce:	d9e90913          	addi	s2,s2,-610 # 80018368 <tickslock>
    800025d2:	a811                	j	800025e6 <wakeup+0x3c>
    release(&p->lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	6da080e7          	jalr	1754(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025de:	18048493          	addi	s1,s1,384
    800025e2:	03248763          	beq	s1,s2,80002610 <wakeup+0x66>
    acquire(&p->lock);
    800025e6:	8526                	mv	a0,s1
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	614080e7          	jalr	1556(ra) # 80000bfc <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    800025f0:	4c9c                	lw	a5,24(s1)
    800025f2:	ff3791e3          	bne	a5,s3,800025d4 <wakeup+0x2a>
    800025f6:	749c                	ld	a5,40(s1)
    800025f8:	fd479ee3          	bne	a5,s4,800025d4 <wakeup+0x2a>
      p->state = RUNNABLE;
    800025fc:	0154ac23          	sw	s5,24(s1)
      movequeue(p, 2, MOVE);
    80002600:	4601                	li	a2,0
    80002602:	85d6                	mv	a1,s5
    80002604:	8526                	mv	a0,s1
    80002606:	fffff097          	auipc	ra,0xfffff
    8000260a:	2f6080e7          	jalr	758(ra) # 800018fc <movequeue>
    8000260e:	b7d9                	j	800025d4 <wakeup+0x2a>
}
    80002610:	70e2                	ld	ra,56(sp)
    80002612:	7442                	ld	s0,48(sp)
    80002614:	74a2                	ld	s1,40(sp)
    80002616:	7902                	ld	s2,32(sp)
    80002618:	69e2                	ld	s3,24(sp)
    8000261a:	6a42                	ld	s4,16(sp)
    8000261c:	6aa2                	ld	s5,8(sp)
    8000261e:	6121                	addi	sp,sp,64
    80002620:	8082                	ret

0000000080002622 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002622:	7179                	addi	sp,sp,-48
    80002624:	f406                	sd	ra,40(sp)
    80002626:	f022                	sd	s0,32(sp)
    80002628:	ec26                	sd	s1,24(sp)
    8000262a:	e84a                	sd	s2,16(sp)
    8000262c:	e44e                	sd	s3,8(sp)
    8000262e:	1800                	addi	s0,sp,48
    80002630:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002632:	00010497          	auipc	s1,0x10
    80002636:	d3648493          	addi	s1,s1,-714 # 80012368 <proc>
    8000263a:	00016997          	auipc	s3,0x16
    8000263e:	d2e98993          	addi	s3,s3,-722 # 80018368 <tickslock>
  {
    acquire(&p->lock);
    80002642:	8526                	mv	a0,s1
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	5b8080e7          	jalr	1464(ra) # 80000bfc <acquire>
    if (p->pid == pid)
    8000264c:	5c9c                	lw	a5,56(s1)
    8000264e:	01278d63          	beq	a5,s2,80002668 <kill+0x46>
        movequeue(p, 2, MOVE);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	65c080e7          	jalr	1628(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000265c:	18048493          	addi	s1,s1,384
    80002660:	ff3491e3          	bne	s1,s3,80002642 <kill+0x20>
  }
  return -1;
    80002664:	557d                	li	a0,-1
    80002666:	a821                	j	8000267e <kill+0x5c>
      p->killed = 1;
    80002668:	4785                	li	a5,1
    8000266a:	d89c                	sw	a5,48(s1)
      if (p->state == SLEEPING)
    8000266c:	4c98                	lw	a4,24(s1)
    8000266e:	00f70f63          	beq	a4,a5,8000268c <kill+0x6a>
      release(&p->lock);
    80002672:	8526                	mv	a0,s1
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	63c080e7          	jalr	1596(ra) # 80000cb0 <release>
      return 0;
    8000267c:	4501                	li	a0,0
}
    8000267e:	70a2                	ld	ra,40(sp)
    80002680:	7402                	ld	s0,32(sp)
    80002682:	64e2                	ld	s1,24(sp)
    80002684:	6942                	ld	s2,16(sp)
    80002686:	69a2                	ld	s3,8(sp)
    80002688:	6145                	addi	sp,sp,48
    8000268a:	8082                	ret
        p->state = RUNNABLE;
    8000268c:	4789                	li	a5,2
    8000268e:	cc9c                	sw	a5,24(s1)
        movequeue(p, 2, MOVE);
    80002690:	4601                	li	a2,0
    80002692:	4589                	li	a1,2
    80002694:	8526                	mv	a0,s1
    80002696:	fffff097          	auipc	ra,0xfffff
    8000269a:	266080e7          	jalr	614(ra) # 800018fc <movequeue>
    8000269e:	bfd1                	j	80002672 <kill+0x50>

00000000800026a0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026a0:	7179                	addi	sp,sp,-48
    800026a2:	f406                	sd	ra,40(sp)
    800026a4:	f022                	sd	s0,32(sp)
    800026a6:	ec26                	sd	s1,24(sp)
    800026a8:	e84a                	sd	s2,16(sp)
    800026aa:	e44e                	sd	s3,8(sp)
    800026ac:	e052                	sd	s4,0(sp)
    800026ae:	1800                	addi	s0,sp,48
    800026b0:	84aa                	mv	s1,a0
    800026b2:	892e                	mv	s2,a1
    800026b4:	89b2                	mv	s3,a2
    800026b6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026b8:	fffff097          	auipc	ra,0xfffff
    800026bc:	43a080e7          	jalr	1082(ra) # 80001af2 <myproc>
  if (user_dst)
    800026c0:	c08d                	beqz	s1,800026e2 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800026c2:	86d2                	mv	a3,s4
    800026c4:	864e                	mv	a2,s3
    800026c6:	85ca                	mv	a1,s2
    800026c8:	6928                	ld	a0,80(a0)
    800026ca:	fffff097          	auipc	ra,0xfffff
    800026ce:	fe0080e7          	jalr	-32(ra) # 800016aa <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026d2:	70a2                	ld	ra,40(sp)
    800026d4:	7402                	ld	s0,32(sp)
    800026d6:	64e2                	ld	s1,24(sp)
    800026d8:	6942                	ld	s2,16(sp)
    800026da:	69a2                	ld	s3,8(sp)
    800026dc:	6a02                	ld	s4,0(sp)
    800026de:	6145                	addi	sp,sp,48
    800026e0:	8082                	ret
    memmove((char *)dst, src, len);
    800026e2:	000a061b          	sext.w	a2,s4
    800026e6:	85ce                	mv	a1,s3
    800026e8:	854a                	mv	a0,s2
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	66a080e7          	jalr	1642(ra) # 80000d54 <memmove>
    return 0;
    800026f2:	8526                	mv	a0,s1
    800026f4:	bff9                	j	800026d2 <either_copyout+0x32>

00000000800026f6 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026f6:	7179                	addi	sp,sp,-48
    800026f8:	f406                	sd	ra,40(sp)
    800026fa:	f022                	sd	s0,32(sp)
    800026fc:	ec26                	sd	s1,24(sp)
    800026fe:	e84a                	sd	s2,16(sp)
    80002700:	e44e                	sd	s3,8(sp)
    80002702:	e052                	sd	s4,0(sp)
    80002704:	1800                	addi	s0,sp,48
    80002706:	892a                	mv	s2,a0
    80002708:	84ae                	mv	s1,a1
    8000270a:	89b2                	mv	s3,a2
    8000270c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	3e4080e7          	jalr	996(ra) # 80001af2 <myproc>
  if (user_src)
    80002716:	c08d                	beqz	s1,80002738 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002718:	86d2                	mv	a3,s4
    8000271a:	864e                	mv	a2,s3
    8000271c:	85ca                	mv	a1,s2
    8000271e:	6928                	ld	a0,80(a0)
    80002720:	fffff097          	auipc	ra,0xfffff
    80002724:	016080e7          	jalr	22(ra) # 80001736 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002728:	70a2                	ld	ra,40(sp)
    8000272a:	7402                	ld	s0,32(sp)
    8000272c:	64e2                	ld	s1,24(sp)
    8000272e:	6942                	ld	s2,16(sp)
    80002730:	69a2                	ld	s3,8(sp)
    80002732:	6a02                	ld	s4,0(sp)
    80002734:	6145                	addi	sp,sp,48
    80002736:	8082                	ret
    memmove(dst, (char *)src, len);
    80002738:	000a061b          	sext.w	a2,s4
    8000273c:	85ce                	mv	a1,s3
    8000273e:	854a                	mv	a0,s2
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	614080e7          	jalr	1556(ra) # 80000d54 <memmove>
    return 0;
    80002748:	8526                	mv	a0,s1
    8000274a:	bff9                	j	80002728 <either_copyin+0x32>

000000008000274c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000274c:	715d                	addi	sp,sp,-80
    8000274e:	e486                	sd	ra,72(sp)
    80002750:	e0a2                	sd	s0,64(sp)
    80002752:	fc26                	sd	s1,56(sp)
    80002754:	f84a                	sd	s2,48(sp)
    80002756:	f44e                	sd	s3,40(sp)
    80002758:	f052                	sd	s4,32(sp)
    8000275a:	ec56                	sd	s5,24(sp)
    8000275c:	e85a                	sd	s6,16(sp)
    8000275e:	e45e                	sd	s7,8(sp)
    80002760:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002762:	00006517          	auipc	a0,0x6
    80002766:	98650513          	addi	a0,a0,-1658 # 800080e8 <digits+0xa8>
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	e20080e7          	jalr	-480(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002772:	00010497          	auipc	s1,0x10
    80002776:	d4e48493          	addi	s1,s1,-690 # 800124c0 <proc+0x158>
    8000277a:	00016917          	auipc	s2,0x16
    8000277e:	d4690913          	addi	s2,s2,-698 # 800184c0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002782:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002784:	00006997          	auipc	s3,0x6
    80002788:	b3498993          	addi	s3,s3,-1228 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    8000278c:	00006a97          	auipc	s5,0x6
    80002790:	b34a8a93          	addi	s5,s5,-1228 # 800082c0 <digits+0x280>
    printf("\n");
    80002794:	00006a17          	auipc	s4,0x6
    80002798:	954a0a13          	addi	s4,s4,-1708 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000279c:	00006b97          	auipc	s7,0x6
    800027a0:	b5cb8b93          	addi	s7,s7,-1188 # 800082f8 <states.0>
    800027a4:	a00d                	j	800027c6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027a6:	ee06a583          	lw	a1,-288(a3)
    800027aa:	8556                	mv	a0,s5
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	dde080e7          	jalr	-546(ra) # 8000058a <printf>
    printf("\n");
    800027b4:	8552                	mv	a0,s4
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	dd4080e7          	jalr	-556(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027be:	18048493          	addi	s1,s1,384
    800027c2:	03248263          	beq	s1,s2,800027e6 <procdump+0x9a>
    if (p->state == UNUSED)
    800027c6:	86a6                	mv	a3,s1
    800027c8:	ec04a783          	lw	a5,-320(s1)
    800027cc:	dbed                	beqz	a5,800027be <procdump+0x72>
      state = "???";
    800027ce:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027d0:	fcfb6be3          	bltu	s6,a5,800027a6 <procdump+0x5a>
    800027d4:	02079713          	slli	a4,a5,0x20
    800027d8:	01d75793          	srli	a5,a4,0x1d
    800027dc:	97de                	add	a5,a5,s7
    800027de:	6390                	ld	a2,0(a5)
    800027e0:	f279                	bnez	a2,800027a6 <procdump+0x5a>
      state = "???";
    800027e2:	864e                	mv	a2,s3
    800027e4:	b7c9                	j	800027a6 <procdump+0x5a>
  }
}
    800027e6:	60a6                	ld	ra,72(sp)
    800027e8:	6406                	ld	s0,64(sp)
    800027ea:	74e2                	ld	s1,56(sp)
    800027ec:	7942                	ld	s2,48(sp)
    800027ee:	79a2                	ld	s3,40(sp)
    800027f0:	7a02                	ld	s4,32(sp)
    800027f2:	6ae2                	ld	s5,24(sp)
    800027f4:	6b42                	ld	s6,16(sp)
    800027f6:	6ba2                	ld	s7,8(sp)
    800027f8:	6161                	addi	sp,sp,80
    800027fa:	8082                	ret

00000000800027fc <swtch>:
    800027fc:	00153023          	sd	ra,0(a0)
    80002800:	00253423          	sd	sp,8(a0)
    80002804:	e900                	sd	s0,16(a0)
    80002806:	ed04                	sd	s1,24(a0)
    80002808:	03253023          	sd	s2,32(a0)
    8000280c:	03353423          	sd	s3,40(a0)
    80002810:	03453823          	sd	s4,48(a0)
    80002814:	03553c23          	sd	s5,56(a0)
    80002818:	05653023          	sd	s6,64(a0)
    8000281c:	05753423          	sd	s7,72(a0)
    80002820:	05853823          	sd	s8,80(a0)
    80002824:	05953c23          	sd	s9,88(a0)
    80002828:	07a53023          	sd	s10,96(a0)
    8000282c:	07b53423          	sd	s11,104(a0)
    80002830:	0005b083          	ld	ra,0(a1)
    80002834:	0085b103          	ld	sp,8(a1)
    80002838:	6980                	ld	s0,16(a1)
    8000283a:	6d84                	ld	s1,24(a1)
    8000283c:	0205b903          	ld	s2,32(a1)
    80002840:	0285b983          	ld	s3,40(a1)
    80002844:	0305ba03          	ld	s4,48(a1)
    80002848:	0385ba83          	ld	s5,56(a1)
    8000284c:	0405bb03          	ld	s6,64(a1)
    80002850:	0485bb83          	ld	s7,72(a1)
    80002854:	0505bc03          	ld	s8,80(a1)
    80002858:	0585bc83          	ld	s9,88(a1)
    8000285c:	0605bd03          	ld	s10,96(a1)
    80002860:	0685bd83          	ld	s11,104(a1)
    80002864:	8082                	ret

0000000080002866 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002866:	1141                	addi	sp,sp,-16
    80002868:	e406                	sd	ra,8(sp)
    8000286a:	e022                	sd	s0,0(sp)
    8000286c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000286e:	00006597          	auipc	a1,0x6
    80002872:	ab258593          	addi	a1,a1,-1358 # 80008320 <states.0+0x28>
    80002876:	00016517          	auipc	a0,0x16
    8000287a:	af250513          	addi	a0,a0,-1294 # 80018368 <tickslock>
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	2ee080e7          	jalr	750(ra) # 80000b6c <initlock>
}
    80002886:	60a2                	ld	ra,8(sp)
    80002888:	6402                	ld	s0,0(sp)
    8000288a:	0141                	addi	sp,sp,16
    8000288c:	8082                	ret

000000008000288e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000288e:	1141                	addi	sp,sp,-16
    80002890:	e422                	sd	s0,8(sp)
    80002892:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002894:	00003797          	auipc	a5,0x3
    80002898:	4fc78793          	addi	a5,a5,1276 # 80005d90 <kernelvec>
    8000289c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028a0:	6422                	ld	s0,8(sp)
    800028a2:	0141                	addi	sp,sp,16
    800028a4:	8082                	ret

00000000800028a6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028a6:	1141                	addi	sp,sp,-16
    800028a8:	e406                	sd	ra,8(sp)
    800028aa:	e022                	sd	s0,0(sp)
    800028ac:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028ae:	fffff097          	auipc	ra,0xfffff
    800028b2:	244080e7          	jalr	580(ra) # 80001af2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028ba:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028bc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028c0:	00004617          	auipc	a2,0x4
    800028c4:	74060613          	addi	a2,a2,1856 # 80007000 <_trampoline>
    800028c8:	00004697          	auipc	a3,0x4
    800028cc:	73868693          	addi	a3,a3,1848 # 80007000 <_trampoline>
    800028d0:	8e91                	sub	a3,a3,a2
    800028d2:	040007b7          	lui	a5,0x4000
    800028d6:	17fd                	addi	a5,a5,-1
    800028d8:	07b2                	slli	a5,a5,0xc
    800028da:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028dc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028e0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028e2:	180026f3          	csrr	a3,satp
    800028e6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028e8:	6d38                	ld	a4,88(a0)
    800028ea:	6134                	ld	a3,64(a0)
    800028ec:	6585                	lui	a1,0x1
    800028ee:	96ae                	add	a3,a3,a1
    800028f0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028f2:	6d38                	ld	a4,88(a0)
    800028f4:	00000697          	auipc	a3,0x0
    800028f8:	13868693          	addi	a3,a3,312 # 80002a2c <usertrap>
    800028fc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028fe:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002900:	8692                	mv	a3,tp
    80002902:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002904:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002908:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000290c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002910:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002914:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002916:	6f18                	ld	a4,24(a4)
    80002918:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000291c:	692c                	ld	a1,80(a0)
    8000291e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002920:	00004717          	auipc	a4,0x4
    80002924:	77070713          	addi	a4,a4,1904 # 80007090 <userret>
    80002928:	8f11                	sub	a4,a4,a2
    8000292a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000292c:	577d                	li	a4,-1
    8000292e:	177e                	slli	a4,a4,0x3f
    80002930:	8dd9                	or	a1,a1,a4
    80002932:	02000537          	lui	a0,0x2000
    80002936:	157d                	addi	a0,a0,-1
    80002938:	0536                	slli	a0,a0,0xd
    8000293a:	9782                	jalr	a5
}
    8000293c:	60a2                	ld	ra,8(sp)
    8000293e:	6402                	ld	s0,0(sp)
    80002940:	0141                	addi	sp,sp,16
    80002942:	8082                	ret

0000000080002944 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002944:	1101                	addi	sp,sp,-32
    80002946:	ec06                	sd	ra,24(sp)
    80002948:	e822                	sd	s0,16(sp)
    8000294a:	e426                	sd	s1,8(sp)
    8000294c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000294e:	00016497          	auipc	s1,0x16
    80002952:	a1a48493          	addi	s1,s1,-1510 # 80018368 <tickslock>
    80002956:	8526                	mv	a0,s1
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	2a4080e7          	jalr	676(ra) # 80000bfc <acquire>
  ticks++;
    80002960:	00006517          	auipc	a0,0x6
    80002964:	6c050513          	addi	a0,a0,1728 # 80009020 <ticks>
    80002968:	411c                	lw	a5,0(a0)
    8000296a:	2785                	addiw	a5,a5,1
    8000296c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000296e:	00000097          	auipc	ra,0x0
    80002972:	c3c080e7          	jalr	-964(ra) # 800025aa <wakeup>
  release(&tickslock);
    80002976:	8526                	mv	a0,s1
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	338080e7          	jalr	824(ra) # 80000cb0 <release>
}
    80002980:	60e2                	ld	ra,24(sp)
    80002982:	6442                	ld	s0,16(sp)
    80002984:	64a2                	ld	s1,8(sp)
    80002986:	6105                	addi	sp,sp,32
    80002988:	8082                	ret

000000008000298a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000298a:	1101                	addi	sp,sp,-32
    8000298c:	ec06                	sd	ra,24(sp)
    8000298e:	e822                	sd	s0,16(sp)
    80002990:	e426                	sd	s1,8(sp)
    80002992:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002994:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002998:	00074d63          	bltz	a4,800029b2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000299c:	57fd                	li	a5,-1
    8000299e:	17fe                	slli	a5,a5,0x3f
    800029a0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029a2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029a4:	06f70363          	beq	a4,a5,80002a0a <devintr+0x80>
  }
}
    800029a8:	60e2                	ld	ra,24(sp)
    800029aa:	6442                	ld	s0,16(sp)
    800029ac:	64a2                	ld	s1,8(sp)
    800029ae:	6105                	addi	sp,sp,32
    800029b0:	8082                	ret
     (scause & 0xff) == 9){
    800029b2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029b6:	46a5                	li	a3,9
    800029b8:	fed792e3          	bne	a5,a3,8000299c <devintr+0x12>
    int irq = plic_claim();
    800029bc:	00003097          	auipc	ra,0x3
    800029c0:	4dc080e7          	jalr	1244(ra) # 80005e98 <plic_claim>
    800029c4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029c6:	47a9                	li	a5,10
    800029c8:	02f50763          	beq	a0,a5,800029f6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029cc:	4785                	li	a5,1
    800029ce:	02f50963          	beq	a0,a5,80002a00 <devintr+0x76>
    return 1;
    800029d2:	4505                	li	a0,1
    } else if(irq){
    800029d4:	d8f1                	beqz	s1,800029a8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029d6:	85a6                	mv	a1,s1
    800029d8:	00006517          	auipc	a0,0x6
    800029dc:	95050513          	addi	a0,a0,-1712 # 80008328 <states.0+0x30>
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	baa080e7          	jalr	-1110(ra) # 8000058a <printf>
      plic_complete(irq);
    800029e8:	8526                	mv	a0,s1
    800029ea:	00003097          	auipc	ra,0x3
    800029ee:	4d2080e7          	jalr	1234(ra) # 80005ebc <plic_complete>
    return 1;
    800029f2:	4505                	li	a0,1
    800029f4:	bf55                	j	800029a8 <devintr+0x1e>
      uartintr();
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	fca080e7          	jalr	-54(ra) # 800009c0 <uartintr>
    800029fe:	b7ed                	j	800029e8 <devintr+0x5e>
      virtio_disk_intr();
    80002a00:	00004097          	auipc	ra,0x4
    80002a04:	936080e7          	jalr	-1738(ra) # 80006336 <virtio_disk_intr>
    80002a08:	b7c5                	j	800029e8 <devintr+0x5e>
    if(cpuid() == 0){
    80002a0a:	fffff097          	auipc	ra,0xfffff
    80002a0e:	0bc080e7          	jalr	188(ra) # 80001ac6 <cpuid>
    80002a12:	c901                	beqz	a0,80002a22 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a14:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a18:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a1a:	14479073          	csrw	sip,a5
    return 2;
    80002a1e:	4509                	li	a0,2
    80002a20:	b761                	j	800029a8 <devintr+0x1e>
      clockintr();
    80002a22:	00000097          	auipc	ra,0x0
    80002a26:	f22080e7          	jalr	-222(ra) # 80002944 <clockintr>
    80002a2a:	b7ed                	j	80002a14 <devintr+0x8a>

0000000080002a2c <usertrap>:
{
    80002a2c:	1101                	addi	sp,sp,-32
    80002a2e:	ec06                	sd	ra,24(sp)
    80002a30:	e822                	sd	s0,16(sp)
    80002a32:	e426                	sd	s1,8(sp)
    80002a34:	e04a                	sd	s2,0(sp)
    80002a36:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a38:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a3c:	1007f793          	andi	a5,a5,256
    80002a40:	e3ad                	bnez	a5,80002aa2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a42:	00003797          	auipc	a5,0x3
    80002a46:	34e78793          	addi	a5,a5,846 # 80005d90 <kernelvec>
    80002a4a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	0a4080e7          	jalr	164(ra) # 80001af2 <myproc>
    80002a56:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a58:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a5a:	14102773          	csrr	a4,sepc
    80002a5e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a60:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a64:	47a1                	li	a5,8
    80002a66:	04f71c63          	bne	a4,a5,80002abe <usertrap+0x92>
    if(p->killed)
    80002a6a:	591c                	lw	a5,48(a0)
    80002a6c:	e3b9                	bnez	a5,80002ab2 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a6e:	6cb8                	ld	a4,88(s1)
    80002a70:	6f1c                	ld	a5,24(a4)
    80002a72:	0791                	addi	a5,a5,4
    80002a74:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a7e:	10079073          	csrw	sstatus,a5
    syscall();
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	2f8080e7          	jalr	760(ra) # 80002d7a <syscall>
  if(p->killed)
    80002a8a:	589c                	lw	a5,48(s1)
    80002a8c:	ebc1                	bnez	a5,80002b1c <usertrap+0xf0>
  usertrapret();
    80002a8e:	00000097          	auipc	ra,0x0
    80002a92:	e18080e7          	jalr	-488(ra) # 800028a6 <usertrapret>
}
    80002a96:	60e2                	ld	ra,24(sp)
    80002a98:	6442                	ld	s0,16(sp)
    80002a9a:	64a2                	ld	s1,8(sp)
    80002a9c:	6902                	ld	s2,0(sp)
    80002a9e:	6105                	addi	sp,sp,32
    80002aa0:	8082                	ret
    panic("usertrap: not from user mode");
    80002aa2:	00006517          	auipc	a0,0x6
    80002aa6:	8a650513          	addi	a0,a0,-1882 # 80008348 <states.0+0x50>
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	a96080e7          	jalr	-1386(ra) # 80000540 <panic>
      exit(-1);
    80002ab2:	557d                	li	a0,-1
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	7d4080e7          	jalr	2004(ra) # 80002288 <exit>
    80002abc:	bf4d                	j	80002a6e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002abe:	00000097          	auipc	ra,0x0
    80002ac2:	ecc080e7          	jalr	-308(ra) # 8000298a <devintr>
    80002ac6:	892a                	mv	s2,a0
    80002ac8:	c501                	beqz	a0,80002ad0 <usertrap+0xa4>
  if(p->killed)
    80002aca:	589c                	lw	a5,48(s1)
    80002acc:	c3a1                	beqz	a5,80002b0c <usertrap+0xe0>
    80002ace:	a815                	j	80002b02 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ad0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ad4:	5c90                	lw	a2,56(s1)
    80002ad6:	00006517          	auipc	a0,0x6
    80002ada:	89250513          	addi	a0,a0,-1902 # 80008368 <states.0+0x70>
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	aac080e7          	jalr	-1364(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aea:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	8aa50513          	addi	a0,a0,-1878 # 80008398 <states.0+0xa0>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a94080e7          	jalr	-1388(ra) # 8000058a <printf>
    p->killed = 1;
    80002afe:	4785                	li	a5,1
    80002b00:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002b02:	557d                	li	a0,-1
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	784080e7          	jalr	1924(ra) # 80002288 <exit>
  if(which_dev == 2)
    80002b0c:	4789                	li	a5,2
    80002b0e:	f8f910e3          	bne	s2,a5,80002a8e <usertrap+0x62>
    yield();
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	88e080e7          	jalr	-1906(ra) # 800023a0 <yield>
    80002b1a:	bf95                	j	80002a8e <usertrap+0x62>
  int which_dev = 0;
    80002b1c:	4901                	li	s2,0
    80002b1e:	b7d5                	j	80002b02 <usertrap+0xd6>

0000000080002b20 <kerneltrap>:
{
    80002b20:	7179                	addi	sp,sp,-48
    80002b22:	f406                	sd	ra,40(sp)
    80002b24:	f022                	sd	s0,32(sp)
    80002b26:	ec26                	sd	s1,24(sp)
    80002b28:	e84a                	sd	s2,16(sp)
    80002b2a:	e44e                	sd	s3,8(sp)
    80002b2c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b2e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b32:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b36:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b3a:	1004f793          	andi	a5,s1,256
    80002b3e:	cb85                	beqz	a5,80002b6e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b40:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b44:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b46:	ef85                	bnez	a5,80002b7e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	e42080e7          	jalr	-446(ra) # 8000298a <devintr>
    80002b50:	cd1d                	beqz	a0,80002b8e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b52:	4789                	li	a5,2
    80002b54:	08f50663          	beq	a0,a5,80002be0 <kerneltrap+0xc0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b58:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b5c:	10049073          	csrw	sstatus,s1
}
    80002b60:	70a2                	ld	ra,40(sp)
    80002b62:	7402                	ld	s0,32(sp)
    80002b64:	64e2                	ld	s1,24(sp)
    80002b66:	6942                	ld	s2,16(sp)
    80002b68:	69a2                	ld	s3,8(sp)
    80002b6a:	6145                	addi	sp,sp,48
    80002b6c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b6e:	00006517          	auipc	a0,0x6
    80002b72:	84a50513          	addi	a0,a0,-1974 # 800083b8 <states.0+0xc0>
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	9ca080e7          	jalr	-1590(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b7e:	00006517          	auipc	a0,0x6
    80002b82:	86250513          	addi	a0,a0,-1950 # 800083e0 <states.0+0xe8>
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	9ba080e7          	jalr	-1606(ra) # 80000540 <panic>
    printf("%d\n", ticks);
    80002b8e:	00006597          	auipc	a1,0x6
    80002b92:	4925a583          	lw	a1,1170(a1) # 80009020 <ticks>
    80002b96:	00006517          	auipc	a0,0x6
    80002b9a:	8c250513          	addi	a0,a0,-1854 # 80008458 <states.0+0x160>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	9ec080e7          	jalr	-1556(ra) # 8000058a <printf>
    printf("scause %p\n", scause);
    80002ba6:	85ce                	mv	a1,s3
    80002ba8:	00006517          	auipc	a0,0x6
    80002bac:	85850513          	addi	a0,a0,-1960 # 80008400 <states.0+0x108>
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	9da080e7          	jalr	-1574(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bbc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bc0:	00006517          	auipc	a0,0x6
    80002bc4:	85050513          	addi	a0,a0,-1968 # 80008410 <states.0+0x118>
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	9c2080e7          	jalr	-1598(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002bd0:	00006517          	auipc	a0,0x6
    80002bd4:	85850513          	addi	a0,a0,-1960 # 80008428 <states.0+0x130>
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	968080e7          	jalr	-1688(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	f12080e7          	jalr	-238(ra) # 80001af2 <myproc>
    80002be8:	d925                	beqz	a0,80002b58 <kerneltrap+0x38>
    80002bea:	fffff097          	auipc	ra,0xfffff
    80002bee:	f08080e7          	jalr	-248(ra) # 80001af2 <myproc>
    80002bf2:	4d18                	lw	a4,24(a0)
    80002bf4:	478d                	li	a5,3
    80002bf6:	f6f711e3          	bne	a4,a5,80002b58 <kerneltrap+0x38>
    yield();
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	7a6080e7          	jalr	1958(ra) # 800023a0 <yield>
    80002c02:	bf99                	j	80002b58 <kerneltrap+0x38>

0000000080002c04 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c04:	1101                	addi	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	e426                	sd	s1,8(sp)
    80002c0c:	1000                	addi	s0,sp,32
    80002c0e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	ee2080e7          	jalr	-286(ra) # 80001af2 <myproc>
  switch (n)
    80002c18:	4795                	li	a5,5
    80002c1a:	0497e163          	bltu	a5,s1,80002c5c <argraw+0x58>
    80002c1e:	048a                	slli	s1,s1,0x2
    80002c20:	00006717          	auipc	a4,0x6
    80002c24:	84070713          	addi	a4,a4,-1984 # 80008460 <states.0+0x168>
    80002c28:	94ba                	add	s1,s1,a4
    80002c2a:	409c                	lw	a5,0(s1)
    80002c2c:	97ba                	add	a5,a5,a4
    80002c2e:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002c30:	6d3c                	ld	a5,88(a0)
    80002c32:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c34:	60e2                	ld	ra,24(sp)
    80002c36:	6442                	ld	s0,16(sp)
    80002c38:	64a2                	ld	s1,8(sp)
    80002c3a:	6105                	addi	sp,sp,32
    80002c3c:	8082                	ret
    return p->trapframe->a1;
    80002c3e:	6d3c                	ld	a5,88(a0)
    80002c40:	7fa8                	ld	a0,120(a5)
    80002c42:	bfcd                	j	80002c34 <argraw+0x30>
    return p->trapframe->a2;
    80002c44:	6d3c                	ld	a5,88(a0)
    80002c46:	63c8                	ld	a0,128(a5)
    80002c48:	b7f5                	j	80002c34 <argraw+0x30>
    return p->trapframe->a3;
    80002c4a:	6d3c                	ld	a5,88(a0)
    80002c4c:	67c8                	ld	a0,136(a5)
    80002c4e:	b7dd                	j	80002c34 <argraw+0x30>
    return p->trapframe->a4;
    80002c50:	6d3c                	ld	a5,88(a0)
    80002c52:	6bc8                	ld	a0,144(a5)
    80002c54:	b7c5                	j	80002c34 <argraw+0x30>
    return p->trapframe->a5;
    80002c56:	6d3c                	ld	a5,88(a0)
    80002c58:	6fc8                	ld	a0,152(a5)
    80002c5a:	bfe9                	j	80002c34 <argraw+0x30>
  panic("argraw");
    80002c5c:	00005517          	auipc	a0,0x5
    80002c60:	7dc50513          	addi	a0,a0,2012 # 80008438 <states.0+0x140>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	8dc080e7          	jalr	-1828(ra) # 80000540 <panic>

0000000080002c6c <fetchaddr>:
{
    80002c6c:	1101                	addi	sp,sp,-32
    80002c6e:	ec06                	sd	ra,24(sp)
    80002c70:	e822                	sd	s0,16(sp)
    80002c72:	e426                	sd	s1,8(sp)
    80002c74:	e04a                	sd	s2,0(sp)
    80002c76:	1000                	addi	s0,sp,32
    80002c78:	84aa                	mv	s1,a0
    80002c7a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	e76080e7          	jalr	-394(ra) # 80001af2 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002c84:	653c                	ld	a5,72(a0)
    80002c86:	02f4f863          	bgeu	s1,a5,80002cb6 <fetchaddr+0x4a>
    80002c8a:	00848713          	addi	a4,s1,8
    80002c8e:	02e7e663          	bltu	a5,a4,80002cba <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c92:	46a1                	li	a3,8
    80002c94:	8626                	mv	a2,s1
    80002c96:	85ca                	mv	a1,s2
    80002c98:	6928                	ld	a0,80(a0)
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	a9c080e7          	jalr	-1380(ra) # 80001736 <copyin>
    80002ca2:	00a03533          	snez	a0,a0
    80002ca6:	40a00533          	neg	a0,a0
}
    80002caa:	60e2                	ld	ra,24(sp)
    80002cac:	6442                	ld	s0,16(sp)
    80002cae:	64a2                	ld	s1,8(sp)
    80002cb0:	6902                	ld	s2,0(sp)
    80002cb2:	6105                	addi	sp,sp,32
    80002cb4:	8082                	ret
    return -1;
    80002cb6:	557d                	li	a0,-1
    80002cb8:	bfcd                	j	80002caa <fetchaddr+0x3e>
    80002cba:	557d                	li	a0,-1
    80002cbc:	b7fd                	j	80002caa <fetchaddr+0x3e>

0000000080002cbe <fetchstr>:
{
    80002cbe:	7179                	addi	sp,sp,-48
    80002cc0:	f406                	sd	ra,40(sp)
    80002cc2:	f022                	sd	s0,32(sp)
    80002cc4:	ec26                	sd	s1,24(sp)
    80002cc6:	e84a                	sd	s2,16(sp)
    80002cc8:	e44e                	sd	s3,8(sp)
    80002cca:	1800                	addi	s0,sp,48
    80002ccc:	892a                	mv	s2,a0
    80002cce:	84ae                	mv	s1,a1
    80002cd0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	e20080e7          	jalr	-480(ra) # 80001af2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cda:	86ce                	mv	a3,s3
    80002cdc:	864a                	mv	a2,s2
    80002cde:	85a6                	mv	a1,s1
    80002ce0:	6928                	ld	a0,80(a0)
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	ae2080e7          	jalr	-1310(ra) # 800017c4 <copyinstr>
  if (err < 0)
    80002cea:	00054763          	bltz	a0,80002cf8 <fetchstr+0x3a>
  return strlen(buf);
    80002cee:	8526                	mv	a0,s1
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	18c080e7          	jalr	396(ra) # 80000e7c <strlen>
}
    80002cf8:	70a2                	ld	ra,40(sp)
    80002cfa:	7402                	ld	s0,32(sp)
    80002cfc:	64e2                	ld	s1,24(sp)
    80002cfe:	6942                	ld	s2,16(sp)
    80002d00:	69a2                	ld	s3,8(sp)
    80002d02:	6145                	addi	sp,sp,48
    80002d04:	8082                	ret

0000000080002d06 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002d06:	1101                	addi	sp,sp,-32
    80002d08:	ec06                	sd	ra,24(sp)
    80002d0a:	e822                	sd	s0,16(sp)
    80002d0c:	e426                	sd	s1,8(sp)
    80002d0e:	1000                	addi	s0,sp,32
    80002d10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	ef2080e7          	jalr	-270(ra) # 80002c04 <argraw>
    80002d1a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d1c:	4501                	li	a0,0
    80002d1e:	60e2                	ld	ra,24(sp)
    80002d20:	6442                	ld	s0,16(sp)
    80002d22:	64a2                	ld	s1,8(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002d28:	1101                	addi	sp,sp,-32
    80002d2a:	ec06                	sd	ra,24(sp)
    80002d2c:	e822                	sd	s0,16(sp)
    80002d2e:	e426                	sd	s1,8(sp)
    80002d30:	1000                	addi	s0,sp,32
    80002d32:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	ed0080e7          	jalr	-304(ra) # 80002c04 <argraw>
    80002d3c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d3e:	4501                	li	a0,0
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	64a2                	ld	s1,8(sp)
    80002d46:	6105                	addi	sp,sp,32
    80002d48:	8082                	ret

0000000080002d4a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002d4a:	1101                	addi	sp,sp,-32
    80002d4c:	ec06                	sd	ra,24(sp)
    80002d4e:	e822                	sd	s0,16(sp)
    80002d50:	e426                	sd	s1,8(sp)
    80002d52:	e04a                	sd	s2,0(sp)
    80002d54:	1000                	addi	s0,sp,32
    80002d56:	84ae                	mv	s1,a1
    80002d58:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	eaa080e7          	jalr	-342(ra) # 80002c04 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d62:	864a                	mv	a2,s2
    80002d64:	85a6                	mv	a1,s1
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	f58080e7          	jalr	-168(ra) # 80002cbe <fetchstr>
}
    80002d6e:	60e2                	ld	ra,24(sp)
    80002d70:	6442                	ld	s0,16(sp)
    80002d72:	64a2                	ld	s1,8(sp)
    80002d74:	6902                	ld	s2,0(sp)
    80002d76:	6105                	addi	sp,sp,32
    80002d78:	8082                	ret

0000000080002d7a <syscall>:
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
};

void syscall(void)
{
    80002d7a:	1101                	addi	sp,sp,-32
    80002d7c:	ec06                	sd	ra,24(sp)
    80002d7e:	e822                	sd	s0,16(sp)
    80002d80:	e426                	sd	s1,8(sp)
    80002d82:	e04a                	sd	s2,0(sp)
    80002d84:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	d6c080e7          	jalr	-660(ra) # 80001af2 <myproc>
    80002d8e:	84aa                	mv	s1,a0

  // Assignment 4
  // when syscall is invoked and
  // its priority was not 2,
  // move to Q2 process
  if (p->priority != 2) 
    80002d90:	17c52703          	lw	a4,380(a0)
    80002d94:	4789                	li	a5,2
    80002d96:	02f71963          	bne	a4,a5,80002dc8 <syscall+0x4e>
    acquire(&p->lock);
    movequeue(p, 2, 0);
    release(&p->lock);
  }

  num = p->trapframe->a7;
    80002d9a:	0584b903          	ld	s2,88(s1)
    80002d9e:	0a893783          	ld	a5,168(s2)
    80002da2:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002da6:	37fd                	addiw	a5,a5,-1
    80002da8:	4751                	li	a4,20
    80002daa:	04f76063          	bltu	a4,a5,80002dea <syscall+0x70>
    80002dae:	00369713          	slli	a4,a3,0x3
    80002db2:	00005797          	auipc	a5,0x5
    80002db6:	6c678793          	addi	a5,a5,1734 # 80008478 <syscalls>
    80002dba:	97ba                	add	a5,a5,a4
    80002dbc:	639c                	ld	a5,0(a5)
    80002dbe:	c795                	beqz	a5,80002dea <syscall+0x70>
  {
    p->trapframe->a0 = syscalls[num]();
    80002dc0:	9782                	jalr	a5
    80002dc2:	06a93823          	sd	a0,112(s2)
    80002dc6:	a081                	j	80002e06 <syscall+0x8c>
    acquire(&p->lock);
    80002dc8:	ffffe097          	auipc	ra,0xffffe
    80002dcc:	e34080e7          	jalr	-460(ra) # 80000bfc <acquire>
    movequeue(p, 2, 0);
    80002dd0:	4601                	li	a2,0
    80002dd2:	4589                	li	a1,2
    80002dd4:	8526                	mv	a0,s1
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	b26080e7          	jalr	-1242(ra) # 800018fc <movequeue>
    release(&p->lock);
    80002dde:	8526                	mv	a0,s1
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	ed0080e7          	jalr	-304(ra) # 80000cb0 <release>
    80002de8:	bf4d                	j	80002d9a <syscall+0x20>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002dea:	15848613          	addi	a2,s1,344
    80002dee:	5c8c                	lw	a1,56(s1)
    80002df0:	00005517          	auipc	a0,0x5
    80002df4:	65050513          	addi	a0,a0,1616 # 80008440 <states.0+0x148>
    80002df8:	ffffd097          	auipc	ra,0xffffd
    80002dfc:	792080e7          	jalr	1938(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e00:	6cbc                	ld	a5,88(s1)
    80002e02:	577d                	li	a4,-1
    80002e04:	fbb8                	sd	a4,112(a5)
  }
}
    80002e06:	60e2                	ld	ra,24(sp)
    80002e08:	6442                	ld	s0,16(sp)
    80002e0a:	64a2                	ld	s1,8(sp)
    80002e0c:	6902                	ld	s2,0(sp)
    80002e0e:	6105                	addi	sp,sp,32
    80002e10:	8082                	ret

0000000080002e12 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e1a:	fec40593          	addi	a1,s0,-20
    80002e1e:	4501                	li	a0,0
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	ee6080e7          	jalr	-282(ra) # 80002d06 <argint>
    return -1;
    80002e28:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e2a:	00054963          	bltz	a0,80002e3c <sys_exit+0x2a>
  exit(n);
    80002e2e:	fec42503          	lw	a0,-20(s0)
    80002e32:	fffff097          	auipc	ra,0xfffff
    80002e36:	456080e7          	jalr	1110(ra) # 80002288 <exit>
  return 0;  // not reached
    80002e3a:	4781                	li	a5,0
}
    80002e3c:	853e                	mv	a0,a5
    80002e3e:	60e2                	ld	ra,24(sp)
    80002e40:	6442                	ld	s0,16(sp)
    80002e42:	6105                	addi	sp,sp,32
    80002e44:	8082                	ret

0000000080002e46 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e46:	1141                	addi	sp,sp,-16
    80002e48:	e406                	sd	ra,8(sp)
    80002e4a:	e022                	sd	s0,0(sp)
    80002e4c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	ca4080e7          	jalr	-860(ra) # 80001af2 <myproc>
}
    80002e56:	5d08                	lw	a0,56(a0)
    80002e58:	60a2                	ld	ra,8(sp)
    80002e5a:	6402                	ld	s0,0(sp)
    80002e5c:	0141                	addi	sp,sp,16
    80002e5e:	8082                	ret

0000000080002e60 <sys_fork>:

uint64
sys_fork(void)
{
    80002e60:	1141                	addi	sp,sp,-16
    80002e62:	e406                	sd	ra,8(sp)
    80002e64:	e022                	sd	s0,0(sp)
    80002e66:	0800                	addi	s0,sp,16
  return fork();
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	0c6080e7          	jalr	198(ra) # 80001f2e <fork>
}
    80002e70:	60a2                	ld	ra,8(sp)
    80002e72:	6402                	ld	s0,0(sp)
    80002e74:	0141                	addi	sp,sp,16
    80002e76:	8082                	ret

0000000080002e78 <sys_wait>:

uint64
sys_wait(void)
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e80:	fe840593          	addi	a1,s0,-24
    80002e84:	4501                	li	a0,0
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	ea2080e7          	jalr	-350(ra) # 80002d28 <argaddr>
    80002e8e:	87aa                	mv	a5,a0
    return -1;
    80002e90:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e92:	0007c863          	bltz	a5,80002ea2 <sys_wait+0x2a>
  return wait(p);
    80002e96:	fe843503          	ld	a0,-24(s0)
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	60e080e7          	jalr	1550(ra) # 800024a8 <wait>
}
    80002ea2:	60e2                	ld	ra,24(sp)
    80002ea4:	6442                	ld	s0,16(sp)
    80002ea6:	6105                	addi	sp,sp,32
    80002ea8:	8082                	ret

0000000080002eaa <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002eaa:	7179                	addi	sp,sp,-48
    80002eac:	f406                	sd	ra,40(sp)
    80002eae:	f022                	sd	s0,32(sp)
    80002eb0:	ec26                	sd	s1,24(sp)
    80002eb2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002eb4:	fdc40593          	addi	a1,s0,-36
    80002eb8:	4501                	li	a0,0
    80002eba:	00000097          	auipc	ra,0x0
    80002ebe:	e4c080e7          	jalr	-436(ra) # 80002d06 <argint>
    return -1;
    80002ec2:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002ec4:	00054f63          	bltz	a0,80002ee2 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	c2a080e7          	jalr	-982(ra) # 80001af2 <myproc>
    80002ed0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ed2:	fdc42503          	lw	a0,-36(s0)
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	fe4080e7          	jalr	-28(ra) # 80001eba <growproc>
    80002ede:	00054863          	bltz	a0,80002eee <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002ee2:	8526                	mv	a0,s1
    80002ee4:	70a2                	ld	ra,40(sp)
    80002ee6:	7402                	ld	s0,32(sp)
    80002ee8:	64e2                	ld	s1,24(sp)
    80002eea:	6145                	addi	sp,sp,48
    80002eec:	8082                	ret
    return -1;
    80002eee:	54fd                	li	s1,-1
    80002ef0:	bfcd                	j	80002ee2 <sys_sbrk+0x38>

0000000080002ef2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ef2:	7139                	addi	sp,sp,-64
    80002ef4:	fc06                	sd	ra,56(sp)
    80002ef6:	f822                	sd	s0,48(sp)
    80002ef8:	f426                	sd	s1,40(sp)
    80002efa:	f04a                	sd	s2,32(sp)
    80002efc:	ec4e                	sd	s3,24(sp)
    80002efe:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f00:	fcc40593          	addi	a1,s0,-52
    80002f04:	4501                	li	a0,0
    80002f06:	00000097          	auipc	ra,0x0
    80002f0a:	e00080e7          	jalr	-512(ra) # 80002d06 <argint>
    return -1;
    80002f0e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f10:	06054563          	bltz	a0,80002f7a <sys_sleep+0x88>
  acquire(&tickslock);
    80002f14:	00015517          	auipc	a0,0x15
    80002f18:	45450513          	addi	a0,a0,1108 # 80018368 <tickslock>
    80002f1c:	ffffe097          	auipc	ra,0xffffe
    80002f20:	ce0080e7          	jalr	-800(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    80002f24:	00006917          	auipc	s2,0x6
    80002f28:	0fc92903          	lw	s2,252(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f2c:	fcc42783          	lw	a5,-52(s0)
    80002f30:	cf85                	beqz	a5,80002f68 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f32:	00015997          	auipc	s3,0x15
    80002f36:	43698993          	addi	s3,s3,1078 # 80018368 <tickslock>
    80002f3a:	00006497          	auipc	s1,0x6
    80002f3e:	0e648493          	addi	s1,s1,230 # 80009020 <ticks>
    if(myproc()->killed){
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	bb0080e7          	jalr	-1104(ra) # 80001af2 <myproc>
    80002f4a:	591c                	lw	a5,48(a0)
    80002f4c:	ef9d                	bnez	a5,80002f8a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f4e:	85ce                	mv	a1,s3
    80002f50:	8526                	mv	a0,s1
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	4be080e7          	jalr	1214(ra) # 80002410 <sleep>
  while(ticks - ticks0 < n){
    80002f5a:	409c                	lw	a5,0(s1)
    80002f5c:	412787bb          	subw	a5,a5,s2
    80002f60:	fcc42703          	lw	a4,-52(s0)
    80002f64:	fce7efe3          	bltu	a5,a4,80002f42 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f68:	00015517          	auipc	a0,0x15
    80002f6c:	40050513          	addi	a0,a0,1024 # 80018368 <tickslock>
    80002f70:	ffffe097          	auipc	ra,0xffffe
    80002f74:	d40080e7          	jalr	-704(ra) # 80000cb0 <release>
  return 0;
    80002f78:	4781                	li	a5,0
}
    80002f7a:	853e                	mv	a0,a5
    80002f7c:	70e2                	ld	ra,56(sp)
    80002f7e:	7442                	ld	s0,48(sp)
    80002f80:	74a2                	ld	s1,40(sp)
    80002f82:	7902                	ld	s2,32(sp)
    80002f84:	69e2                	ld	s3,24(sp)
    80002f86:	6121                	addi	sp,sp,64
    80002f88:	8082                	ret
      release(&tickslock);
    80002f8a:	00015517          	auipc	a0,0x15
    80002f8e:	3de50513          	addi	a0,a0,990 # 80018368 <tickslock>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	d1e080e7          	jalr	-738(ra) # 80000cb0 <release>
      return -1;
    80002f9a:	57fd                	li	a5,-1
    80002f9c:	bff9                	j	80002f7a <sys_sleep+0x88>

0000000080002f9e <sys_kill>:

uint64
sys_kill(void)
{
    80002f9e:	1101                	addi	sp,sp,-32
    80002fa0:	ec06                	sd	ra,24(sp)
    80002fa2:	e822                	sd	s0,16(sp)
    80002fa4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fa6:	fec40593          	addi	a1,s0,-20
    80002faa:	4501                	li	a0,0
    80002fac:	00000097          	auipc	ra,0x0
    80002fb0:	d5a080e7          	jalr	-678(ra) # 80002d06 <argint>
    80002fb4:	87aa                	mv	a5,a0
    return -1;
    80002fb6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fb8:	0007c863          	bltz	a5,80002fc8 <sys_kill+0x2a>
  return kill(pid);
    80002fbc:	fec42503          	lw	a0,-20(s0)
    80002fc0:	fffff097          	auipc	ra,0xfffff
    80002fc4:	662080e7          	jalr	1634(ra) # 80002622 <kill>
}
    80002fc8:	60e2                	ld	ra,24(sp)
    80002fca:	6442                	ld	s0,16(sp)
    80002fcc:	6105                	addi	sp,sp,32
    80002fce:	8082                	ret

0000000080002fd0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fd0:	1101                	addi	sp,sp,-32
    80002fd2:	ec06                	sd	ra,24(sp)
    80002fd4:	e822                	sd	s0,16(sp)
    80002fd6:	e426                	sd	s1,8(sp)
    80002fd8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fda:	00015517          	auipc	a0,0x15
    80002fde:	38e50513          	addi	a0,a0,910 # 80018368 <tickslock>
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	c1a080e7          	jalr	-998(ra) # 80000bfc <acquire>
  xticks = ticks;
    80002fea:	00006497          	auipc	s1,0x6
    80002fee:	0364a483          	lw	s1,54(s1) # 80009020 <ticks>
  release(&tickslock);
    80002ff2:	00015517          	auipc	a0,0x15
    80002ff6:	37650513          	addi	a0,a0,886 # 80018368 <tickslock>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	cb6080e7          	jalr	-842(ra) # 80000cb0 <release>
  return xticks;
}
    80003002:	02049513          	slli	a0,s1,0x20
    80003006:	9101                	srli	a0,a0,0x20
    80003008:	60e2                	ld	ra,24(sp)
    8000300a:	6442                	ld	s0,16(sp)
    8000300c:	64a2                	ld	s1,8(sp)
    8000300e:	6105                	addi	sp,sp,32
    80003010:	8082                	ret

0000000080003012 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003012:	7179                	addi	sp,sp,-48
    80003014:	f406                	sd	ra,40(sp)
    80003016:	f022                	sd	s0,32(sp)
    80003018:	ec26                	sd	s1,24(sp)
    8000301a:	e84a                	sd	s2,16(sp)
    8000301c:	e44e                	sd	s3,8(sp)
    8000301e:	e052                	sd	s4,0(sp)
    80003020:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003022:	00005597          	auipc	a1,0x5
    80003026:	50658593          	addi	a1,a1,1286 # 80008528 <syscalls+0xb0>
    8000302a:	00015517          	auipc	a0,0x15
    8000302e:	35650513          	addi	a0,a0,854 # 80018380 <bcache>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	b3a080e7          	jalr	-1222(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000303a:	0001d797          	auipc	a5,0x1d
    8000303e:	34678793          	addi	a5,a5,838 # 80020380 <bcache+0x8000>
    80003042:	0001d717          	auipc	a4,0x1d
    80003046:	5a670713          	addi	a4,a4,1446 # 800205e8 <bcache+0x8268>
    8000304a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000304e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003052:	00015497          	auipc	s1,0x15
    80003056:	34648493          	addi	s1,s1,838 # 80018398 <bcache+0x18>
    b->next = bcache.head.next;
    8000305a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000305c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000305e:	00005a17          	auipc	s4,0x5
    80003062:	4d2a0a13          	addi	s4,s4,1234 # 80008530 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003066:	2b893783          	ld	a5,696(s2)
    8000306a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000306c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003070:	85d2                	mv	a1,s4
    80003072:	01048513          	addi	a0,s1,16
    80003076:	00001097          	auipc	ra,0x1
    8000307a:	4b2080e7          	jalr	1202(ra) # 80004528 <initsleeplock>
    bcache.head.next->prev = b;
    8000307e:	2b893783          	ld	a5,696(s2)
    80003082:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003084:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003088:	45848493          	addi	s1,s1,1112
    8000308c:	fd349de3          	bne	s1,s3,80003066 <binit+0x54>
  }
}
    80003090:	70a2                	ld	ra,40(sp)
    80003092:	7402                	ld	s0,32(sp)
    80003094:	64e2                	ld	s1,24(sp)
    80003096:	6942                	ld	s2,16(sp)
    80003098:	69a2                	ld	s3,8(sp)
    8000309a:	6a02                	ld	s4,0(sp)
    8000309c:	6145                	addi	sp,sp,48
    8000309e:	8082                	ret

00000000800030a0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030a0:	7179                	addi	sp,sp,-48
    800030a2:	f406                	sd	ra,40(sp)
    800030a4:	f022                	sd	s0,32(sp)
    800030a6:	ec26                	sd	s1,24(sp)
    800030a8:	e84a                	sd	s2,16(sp)
    800030aa:	e44e                	sd	s3,8(sp)
    800030ac:	1800                	addi	s0,sp,48
    800030ae:	892a                	mv	s2,a0
    800030b0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030b2:	00015517          	auipc	a0,0x15
    800030b6:	2ce50513          	addi	a0,a0,718 # 80018380 <bcache>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	b42080e7          	jalr	-1214(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030c2:	0001d497          	auipc	s1,0x1d
    800030c6:	5764b483          	ld	s1,1398(s1) # 80020638 <bcache+0x82b8>
    800030ca:	0001d797          	auipc	a5,0x1d
    800030ce:	51e78793          	addi	a5,a5,1310 # 800205e8 <bcache+0x8268>
    800030d2:	02f48f63          	beq	s1,a5,80003110 <bread+0x70>
    800030d6:	873e                	mv	a4,a5
    800030d8:	a021                	j	800030e0 <bread+0x40>
    800030da:	68a4                	ld	s1,80(s1)
    800030dc:	02e48a63          	beq	s1,a4,80003110 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030e0:	449c                	lw	a5,8(s1)
    800030e2:	ff279ce3          	bne	a5,s2,800030da <bread+0x3a>
    800030e6:	44dc                	lw	a5,12(s1)
    800030e8:	ff3799e3          	bne	a5,s3,800030da <bread+0x3a>
      b->refcnt++;
    800030ec:	40bc                	lw	a5,64(s1)
    800030ee:	2785                	addiw	a5,a5,1
    800030f0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030f2:	00015517          	auipc	a0,0x15
    800030f6:	28e50513          	addi	a0,a0,654 # 80018380 <bcache>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	bb6080e7          	jalr	-1098(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    80003102:	01048513          	addi	a0,s1,16
    80003106:	00001097          	auipc	ra,0x1
    8000310a:	45c080e7          	jalr	1116(ra) # 80004562 <acquiresleep>
      return b;
    8000310e:	a8b9                	j	8000316c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003110:	0001d497          	auipc	s1,0x1d
    80003114:	5204b483          	ld	s1,1312(s1) # 80020630 <bcache+0x82b0>
    80003118:	0001d797          	auipc	a5,0x1d
    8000311c:	4d078793          	addi	a5,a5,1232 # 800205e8 <bcache+0x8268>
    80003120:	00f48863          	beq	s1,a5,80003130 <bread+0x90>
    80003124:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003126:	40bc                	lw	a5,64(s1)
    80003128:	cf81                	beqz	a5,80003140 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000312a:	64a4                	ld	s1,72(s1)
    8000312c:	fee49de3          	bne	s1,a4,80003126 <bread+0x86>
  panic("bget: no buffers");
    80003130:	00005517          	auipc	a0,0x5
    80003134:	40850513          	addi	a0,a0,1032 # 80008538 <syscalls+0xc0>
    80003138:	ffffd097          	auipc	ra,0xffffd
    8000313c:	408080e7          	jalr	1032(ra) # 80000540 <panic>
      b->dev = dev;
    80003140:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003144:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003148:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000314c:	4785                	li	a5,1
    8000314e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003150:	00015517          	auipc	a0,0x15
    80003154:	23050513          	addi	a0,a0,560 # 80018380 <bcache>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	b58080e7          	jalr	-1192(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    80003160:	01048513          	addi	a0,s1,16
    80003164:	00001097          	auipc	ra,0x1
    80003168:	3fe080e7          	jalr	1022(ra) # 80004562 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000316c:	409c                	lw	a5,0(s1)
    8000316e:	cb89                	beqz	a5,80003180 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003170:	8526                	mv	a0,s1
    80003172:	70a2                	ld	ra,40(sp)
    80003174:	7402                	ld	s0,32(sp)
    80003176:	64e2                	ld	s1,24(sp)
    80003178:	6942                	ld	s2,16(sp)
    8000317a:	69a2                	ld	s3,8(sp)
    8000317c:	6145                	addi	sp,sp,48
    8000317e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003180:	4581                	li	a1,0
    80003182:	8526                	mv	a0,s1
    80003184:	00003097          	auipc	ra,0x3
    80003188:	f28080e7          	jalr	-216(ra) # 800060ac <virtio_disk_rw>
    b->valid = 1;
    8000318c:	4785                	li	a5,1
    8000318e:	c09c                	sw	a5,0(s1)
  return b;
    80003190:	b7c5                	j	80003170 <bread+0xd0>

0000000080003192 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	1000                	addi	s0,sp,32
    8000319c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000319e:	0541                	addi	a0,a0,16
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	45c080e7          	jalr	1116(ra) # 800045fc <holdingsleep>
    800031a8:	cd01                	beqz	a0,800031c0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031aa:	4585                	li	a1,1
    800031ac:	8526                	mv	a0,s1
    800031ae:	00003097          	auipc	ra,0x3
    800031b2:	efe080e7          	jalr	-258(ra) # 800060ac <virtio_disk_rw>
}
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6105                	addi	sp,sp,32
    800031be:	8082                	ret
    panic("bwrite");
    800031c0:	00005517          	auipc	a0,0x5
    800031c4:	39050513          	addi	a0,a0,912 # 80008550 <syscalls+0xd8>
    800031c8:	ffffd097          	auipc	ra,0xffffd
    800031cc:	378080e7          	jalr	888(ra) # 80000540 <panic>

00000000800031d0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031d0:	1101                	addi	sp,sp,-32
    800031d2:	ec06                	sd	ra,24(sp)
    800031d4:	e822                	sd	s0,16(sp)
    800031d6:	e426                	sd	s1,8(sp)
    800031d8:	e04a                	sd	s2,0(sp)
    800031da:	1000                	addi	s0,sp,32
    800031dc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031de:	01050913          	addi	s2,a0,16
    800031e2:	854a                	mv	a0,s2
    800031e4:	00001097          	auipc	ra,0x1
    800031e8:	418080e7          	jalr	1048(ra) # 800045fc <holdingsleep>
    800031ec:	c92d                	beqz	a0,8000325e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031ee:	854a                	mv	a0,s2
    800031f0:	00001097          	auipc	ra,0x1
    800031f4:	3c8080e7          	jalr	968(ra) # 800045b8 <releasesleep>

  acquire(&bcache.lock);
    800031f8:	00015517          	auipc	a0,0x15
    800031fc:	18850513          	addi	a0,a0,392 # 80018380 <bcache>
    80003200:	ffffe097          	auipc	ra,0xffffe
    80003204:	9fc080e7          	jalr	-1540(ra) # 80000bfc <acquire>
  b->refcnt--;
    80003208:	40bc                	lw	a5,64(s1)
    8000320a:	37fd                	addiw	a5,a5,-1
    8000320c:	0007871b          	sext.w	a4,a5
    80003210:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003212:	eb05                	bnez	a4,80003242 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003214:	68bc                	ld	a5,80(s1)
    80003216:	64b8                	ld	a4,72(s1)
    80003218:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000321a:	64bc                	ld	a5,72(s1)
    8000321c:	68b8                	ld	a4,80(s1)
    8000321e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003220:	0001d797          	auipc	a5,0x1d
    80003224:	16078793          	addi	a5,a5,352 # 80020380 <bcache+0x8000>
    80003228:	2b87b703          	ld	a4,696(a5)
    8000322c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000322e:	0001d717          	auipc	a4,0x1d
    80003232:	3ba70713          	addi	a4,a4,954 # 800205e8 <bcache+0x8268>
    80003236:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003238:	2b87b703          	ld	a4,696(a5)
    8000323c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000323e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003242:	00015517          	auipc	a0,0x15
    80003246:	13e50513          	addi	a0,a0,318 # 80018380 <bcache>
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	a66080e7          	jalr	-1434(ra) # 80000cb0 <release>
}
    80003252:	60e2                	ld	ra,24(sp)
    80003254:	6442                	ld	s0,16(sp)
    80003256:	64a2                	ld	s1,8(sp)
    80003258:	6902                	ld	s2,0(sp)
    8000325a:	6105                	addi	sp,sp,32
    8000325c:	8082                	ret
    panic("brelse");
    8000325e:	00005517          	auipc	a0,0x5
    80003262:	2fa50513          	addi	a0,a0,762 # 80008558 <syscalls+0xe0>
    80003266:	ffffd097          	auipc	ra,0xffffd
    8000326a:	2da080e7          	jalr	730(ra) # 80000540 <panic>

000000008000326e <bpin>:

void
bpin(struct buf *b) {
    8000326e:	1101                	addi	sp,sp,-32
    80003270:	ec06                	sd	ra,24(sp)
    80003272:	e822                	sd	s0,16(sp)
    80003274:	e426                	sd	s1,8(sp)
    80003276:	1000                	addi	s0,sp,32
    80003278:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000327a:	00015517          	auipc	a0,0x15
    8000327e:	10650513          	addi	a0,a0,262 # 80018380 <bcache>
    80003282:	ffffe097          	auipc	ra,0xffffe
    80003286:	97a080e7          	jalr	-1670(ra) # 80000bfc <acquire>
  b->refcnt++;
    8000328a:	40bc                	lw	a5,64(s1)
    8000328c:	2785                	addiw	a5,a5,1
    8000328e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003290:	00015517          	auipc	a0,0x15
    80003294:	0f050513          	addi	a0,a0,240 # 80018380 <bcache>
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	a18080e7          	jalr	-1512(ra) # 80000cb0 <release>
}
    800032a0:	60e2                	ld	ra,24(sp)
    800032a2:	6442                	ld	s0,16(sp)
    800032a4:	64a2                	ld	s1,8(sp)
    800032a6:	6105                	addi	sp,sp,32
    800032a8:	8082                	ret

00000000800032aa <bunpin>:

void
bunpin(struct buf *b) {
    800032aa:	1101                	addi	sp,sp,-32
    800032ac:	ec06                	sd	ra,24(sp)
    800032ae:	e822                	sd	s0,16(sp)
    800032b0:	e426                	sd	s1,8(sp)
    800032b2:	1000                	addi	s0,sp,32
    800032b4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032b6:	00015517          	auipc	a0,0x15
    800032ba:	0ca50513          	addi	a0,a0,202 # 80018380 <bcache>
    800032be:	ffffe097          	auipc	ra,0xffffe
    800032c2:	93e080e7          	jalr	-1730(ra) # 80000bfc <acquire>
  b->refcnt--;
    800032c6:	40bc                	lw	a5,64(s1)
    800032c8:	37fd                	addiw	a5,a5,-1
    800032ca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032cc:	00015517          	auipc	a0,0x15
    800032d0:	0b450513          	addi	a0,a0,180 # 80018380 <bcache>
    800032d4:	ffffe097          	auipc	ra,0xffffe
    800032d8:	9dc080e7          	jalr	-1572(ra) # 80000cb0 <release>
}
    800032dc:	60e2                	ld	ra,24(sp)
    800032de:	6442                	ld	s0,16(sp)
    800032e0:	64a2                	ld	s1,8(sp)
    800032e2:	6105                	addi	sp,sp,32
    800032e4:	8082                	ret

00000000800032e6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032e6:	1101                	addi	sp,sp,-32
    800032e8:	ec06                	sd	ra,24(sp)
    800032ea:	e822                	sd	s0,16(sp)
    800032ec:	e426                	sd	s1,8(sp)
    800032ee:	e04a                	sd	s2,0(sp)
    800032f0:	1000                	addi	s0,sp,32
    800032f2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032f4:	00d5d59b          	srliw	a1,a1,0xd
    800032f8:	0001d797          	auipc	a5,0x1d
    800032fc:	7647a783          	lw	a5,1892(a5) # 80020a5c <sb+0x1c>
    80003300:	9dbd                	addw	a1,a1,a5
    80003302:	00000097          	auipc	ra,0x0
    80003306:	d9e080e7          	jalr	-610(ra) # 800030a0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000330a:	0074f713          	andi	a4,s1,7
    8000330e:	4785                	li	a5,1
    80003310:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003314:	14ce                	slli	s1,s1,0x33
    80003316:	90d9                	srli	s1,s1,0x36
    80003318:	00950733          	add	a4,a0,s1
    8000331c:	05874703          	lbu	a4,88(a4)
    80003320:	00e7f6b3          	and	a3,a5,a4
    80003324:	c69d                	beqz	a3,80003352 <bfree+0x6c>
    80003326:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003328:	94aa                	add	s1,s1,a0
    8000332a:	fff7c793          	not	a5,a5
    8000332e:	8ff9                	and	a5,a5,a4
    80003330:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003334:	00001097          	auipc	ra,0x1
    80003338:	106080e7          	jalr	262(ra) # 8000443a <log_write>
  brelse(bp);
    8000333c:	854a                	mv	a0,s2
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	e92080e7          	jalr	-366(ra) # 800031d0 <brelse>
}
    80003346:	60e2                	ld	ra,24(sp)
    80003348:	6442                	ld	s0,16(sp)
    8000334a:	64a2                	ld	s1,8(sp)
    8000334c:	6902                	ld	s2,0(sp)
    8000334e:	6105                	addi	sp,sp,32
    80003350:	8082                	ret
    panic("freeing free block");
    80003352:	00005517          	auipc	a0,0x5
    80003356:	20e50513          	addi	a0,a0,526 # 80008560 <syscalls+0xe8>
    8000335a:	ffffd097          	auipc	ra,0xffffd
    8000335e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>

0000000080003362 <balloc>:
{
    80003362:	711d                	addi	sp,sp,-96
    80003364:	ec86                	sd	ra,88(sp)
    80003366:	e8a2                	sd	s0,80(sp)
    80003368:	e4a6                	sd	s1,72(sp)
    8000336a:	e0ca                	sd	s2,64(sp)
    8000336c:	fc4e                	sd	s3,56(sp)
    8000336e:	f852                	sd	s4,48(sp)
    80003370:	f456                	sd	s5,40(sp)
    80003372:	f05a                	sd	s6,32(sp)
    80003374:	ec5e                	sd	s7,24(sp)
    80003376:	e862                	sd	s8,16(sp)
    80003378:	e466                	sd	s9,8(sp)
    8000337a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000337c:	0001d797          	auipc	a5,0x1d
    80003380:	6c87a783          	lw	a5,1736(a5) # 80020a44 <sb+0x4>
    80003384:	cbd1                	beqz	a5,80003418 <balloc+0xb6>
    80003386:	8baa                	mv	s7,a0
    80003388:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000338a:	0001db17          	auipc	s6,0x1d
    8000338e:	6b6b0b13          	addi	s6,s6,1718 # 80020a40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003392:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003394:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003396:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003398:	6c89                	lui	s9,0x2
    8000339a:	a831                	j	800033b6 <balloc+0x54>
    brelse(bp);
    8000339c:	854a                	mv	a0,s2
    8000339e:	00000097          	auipc	ra,0x0
    800033a2:	e32080e7          	jalr	-462(ra) # 800031d0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033a6:	015c87bb          	addw	a5,s9,s5
    800033aa:	00078a9b          	sext.w	s5,a5
    800033ae:	004b2703          	lw	a4,4(s6)
    800033b2:	06eaf363          	bgeu	s5,a4,80003418 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033b6:	41fad79b          	sraiw	a5,s5,0x1f
    800033ba:	0137d79b          	srliw	a5,a5,0x13
    800033be:	015787bb          	addw	a5,a5,s5
    800033c2:	40d7d79b          	sraiw	a5,a5,0xd
    800033c6:	01cb2583          	lw	a1,28(s6)
    800033ca:	9dbd                	addw	a1,a1,a5
    800033cc:	855e                	mv	a0,s7
    800033ce:	00000097          	auipc	ra,0x0
    800033d2:	cd2080e7          	jalr	-814(ra) # 800030a0 <bread>
    800033d6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d8:	004b2503          	lw	a0,4(s6)
    800033dc:	000a849b          	sext.w	s1,s5
    800033e0:	8662                	mv	a2,s8
    800033e2:	faa4fde3          	bgeu	s1,a0,8000339c <balloc+0x3a>
      m = 1 << (bi % 8);
    800033e6:	41f6579b          	sraiw	a5,a2,0x1f
    800033ea:	01d7d69b          	srliw	a3,a5,0x1d
    800033ee:	00c6873b          	addw	a4,a3,a2
    800033f2:	00777793          	andi	a5,a4,7
    800033f6:	9f95                	subw	a5,a5,a3
    800033f8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033fc:	4037571b          	sraiw	a4,a4,0x3
    80003400:	00e906b3          	add	a3,s2,a4
    80003404:	0586c683          	lbu	a3,88(a3)
    80003408:	00d7f5b3          	and	a1,a5,a3
    8000340c:	cd91                	beqz	a1,80003428 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000340e:	2605                	addiw	a2,a2,1
    80003410:	2485                	addiw	s1,s1,1
    80003412:	fd4618e3          	bne	a2,s4,800033e2 <balloc+0x80>
    80003416:	b759                	j	8000339c <balloc+0x3a>
  panic("balloc: out of blocks");
    80003418:	00005517          	auipc	a0,0x5
    8000341c:	16050513          	addi	a0,a0,352 # 80008578 <syscalls+0x100>
    80003420:	ffffd097          	auipc	ra,0xffffd
    80003424:	120080e7          	jalr	288(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003428:	974a                	add	a4,a4,s2
    8000342a:	8fd5                	or	a5,a5,a3
    8000342c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003430:	854a                	mv	a0,s2
    80003432:	00001097          	auipc	ra,0x1
    80003436:	008080e7          	jalr	8(ra) # 8000443a <log_write>
        brelse(bp);
    8000343a:	854a                	mv	a0,s2
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	d94080e7          	jalr	-620(ra) # 800031d0 <brelse>
  bp = bread(dev, bno);
    80003444:	85a6                	mv	a1,s1
    80003446:	855e                	mv	a0,s7
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	c58080e7          	jalr	-936(ra) # 800030a0 <bread>
    80003450:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003452:	40000613          	li	a2,1024
    80003456:	4581                	li	a1,0
    80003458:	05850513          	addi	a0,a0,88
    8000345c:	ffffe097          	auipc	ra,0xffffe
    80003460:	89c080e7          	jalr	-1892(ra) # 80000cf8 <memset>
  log_write(bp);
    80003464:	854a                	mv	a0,s2
    80003466:	00001097          	auipc	ra,0x1
    8000346a:	fd4080e7          	jalr	-44(ra) # 8000443a <log_write>
  brelse(bp);
    8000346e:	854a                	mv	a0,s2
    80003470:	00000097          	auipc	ra,0x0
    80003474:	d60080e7          	jalr	-672(ra) # 800031d0 <brelse>
}
    80003478:	8526                	mv	a0,s1
    8000347a:	60e6                	ld	ra,88(sp)
    8000347c:	6446                	ld	s0,80(sp)
    8000347e:	64a6                	ld	s1,72(sp)
    80003480:	6906                	ld	s2,64(sp)
    80003482:	79e2                	ld	s3,56(sp)
    80003484:	7a42                	ld	s4,48(sp)
    80003486:	7aa2                	ld	s5,40(sp)
    80003488:	7b02                	ld	s6,32(sp)
    8000348a:	6be2                	ld	s7,24(sp)
    8000348c:	6c42                	ld	s8,16(sp)
    8000348e:	6ca2                	ld	s9,8(sp)
    80003490:	6125                	addi	sp,sp,96
    80003492:	8082                	ret

0000000080003494 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003494:	7179                	addi	sp,sp,-48
    80003496:	f406                	sd	ra,40(sp)
    80003498:	f022                	sd	s0,32(sp)
    8000349a:	ec26                	sd	s1,24(sp)
    8000349c:	e84a                	sd	s2,16(sp)
    8000349e:	e44e                	sd	s3,8(sp)
    800034a0:	e052                	sd	s4,0(sp)
    800034a2:	1800                	addi	s0,sp,48
    800034a4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034a6:	47ad                	li	a5,11
    800034a8:	04b7fe63          	bgeu	a5,a1,80003504 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034ac:	ff45849b          	addiw	s1,a1,-12
    800034b0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034b4:	0ff00793          	li	a5,255
    800034b8:	0ae7e463          	bltu	a5,a4,80003560 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034bc:	08052583          	lw	a1,128(a0)
    800034c0:	c5b5                	beqz	a1,8000352c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034c2:	00092503          	lw	a0,0(s2)
    800034c6:	00000097          	auipc	ra,0x0
    800034ca:	bda080e7          	jalr	-1062(ra) # 800030a0 <bread>
    800034ce:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034d0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034d4:	02049713          	slli	a4,s1,0x20
    800034d8:	01e75593          	srli	a1,a4,0x1e
    800034dc:	00b784b3          	add	s1,a5,a1
    800034e0:	0004a983          	lw	s3,0(s1)
    800034e4:	04098e63          	beqz	s3,80003540 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034e8:	8552                	mv	a0,s4
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	ce6080e7          	jalr	-794(ra) # 800031d0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034f2:	854e                	mv	a0,s3
    800034f4:	70a2                	ld	ra,40(sp)
    800034f6:	7402                	ld	s0,32(sp)
    800034f8:	64e2                	ld	s1,24(sp)
    800034fa:	6942                	ld	s2,16(sp)
    800034fc:	69a2                	ld	s3,8(sp)
    800034fe:	6a02                	ld	s4,0(sp)
    80003500:	6145                	addi	sp,sp,48
    80003502:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003504:	02059793          	slli	a5,a1,0x20
    80003508:	01e7d593          	srli	a1,a5,0x1e
    8000350c:	00b504b3          	add	s1,a0,a1
    80003510:	0504a983          	lw	s3,80(s1)
    80003514:	fc099fe3          	bnez	s3,800034f2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003518:	4108                	lw	a0,0(a0)
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	e48080e7          	jalr	-440(ra) # 80003362 <balloc>
    80003522:	0005099b          	sext.w	s3,a0
    80003526:	0534a823          	sw	s3,80(s1)
    8000352a:	b7e1                	j	800034f2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000352c:	4108                	lw	a0,0(a0)
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	e34080e7          	jalr	-460(ra) # 80003362 <balloc>
    80003536:	0005059b          	sext.w	a1,a0
    8000353a:	08b92023          	sw	a1,128(s2)
    8000353e:	b751                	j	800034c2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003540:	00092503          	lw	a0,0(s2)
    80003544:	00000097          	auipc	ra,0x0
    80003548:	e1e080e7          	jalr	-482(ra) # 80003362 <balloc>
    8000354c:	0005099b          	sext.w	s3,a0
    80003550:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003554:	8552                	mv	a0,s4
    80003556:	00001097          	auipc	ra,0x1
    8000355a:	ee4080e7          	jalr	-284(ra) # 8000443a <log_write>
    8000355e:	b769                	j	800034e8 <bmap+0x54>
  panic("bmap: out of range");
    80003560:	00005517          	auipc	a0,0x5
    80003564:	03050513          	addi	a0,a0,48 # 80008590 <syscalls+0x118>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	fd8080e7          	jalr	-40(ra) # 80000540 <panic>

0000000080003570 <iget>:
{
    80003570:	7179                	addi	sp,sp,-48
    80003572:	f406                	sd	ra,40(sp)
    80003574:	f022                	sd	s0,32(sp)
    80003576:	ec26                	sd	s1,24(sp)
    80003578:	e84a                	sd	s2,16(sp)
    8000357a:	e44e                	sd	s3,8(sp)
    8000357c:	e052                	sd	s4,0(sp)
    8000357e:	1800                	addi	s0,sp,48
    80003580:	89aa                	mv	s3,a0
    80003582:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003584:	0001d517          	auipc	a0,0x1d
    80003588:	4dc50513          	addi	a0,a0,1244 # 80020a60 <icache>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	670080e7          	jalr	1648(ra) # 80000bfc <acquire>
  empty = 0;
    80003594:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003596:	0001d497          	auipc	s1,0x1d
    8000359a:	4e248493          	addi	s1,s1,1250 # 80020a78 <icache+0x18>
    8000359e:	0001f697          	auipc	a3,0x1f
    800035a2:	f6a68693          	addi	a3,a3,-150 # 80022508 <log>
    800035a6:	a039                	j	800035b4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035a8:	02090b63          	beqz	s2,800035de <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035ac:	08848493          	addi	s1,s1,136
    800035b0:	02d48a63          	beq	s1,a3,800035e4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035b4:	449c                	lw	a5,8(s1)
    800035b6:	fef059e3          	blez	a5,800035a8 <iget+0x38>
    800035ba:	4098                	lw	a4,0(s1)
    800035bc:	ff3716e3          	bne	a4,s3,800035a8 <iget+0x38>
    800035c0:	40d8                	lw	a4,4(s1)
    800035c2:	ff4713e3          	bne	a4,s4,800035a8 <iget+0x38>
      ip->ref++;
    800035c6:	2785                	addiw	a5,a5,1
    800035c8:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800035ca:	0001d517          	auipc	a0,0x1d
    800035ce:	49650513          	addi	a0,a0,1174 # 80020a60 <icache>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	6de080e7          	jalr	1758(ra) # 80000cb0 <release>
      return ip;
    800035da:	8926                	mv	s2,s1
    800035dc:	a03d                	j	8000360a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035de:	f7f9                	bnez	a5,800035ac <iget+0x3c>
    800035e0:	8926                	mv	s2,s1
    800035e2:	b7e9                	j	800035ac <iget+0x3c>
  if(empty == 0)
    800035e4:	02090c63          	beqz	s2,8000361c <iget+0xac>
  ip->dev = dev;
    800035e8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035ec:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035f0:	4785                	li	a5,1
    800035f2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035f6:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800035fa:	0001d517          	auipc	a0,0x1d
    800035fe:	46650513          	addi	a0,a0,1126 # 80020a60 <icache>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	6ae080e7          	jalr	1710(ra) # 80000cb0 <release>
}
    8000360a:	854a                	mv	a0,s2
    8000360c:	70a2                	ld	ra,40(sp)
    8000360e:	7402                	ld	s0,32(sp)
    80003610:	64e2                	ld	s1,24(sp)
    80003612:	6942                	ld	s2,16(sp)
    80003614:	69a2                	ld	s3,8(sp)
    80003616:	6a02                	ld	s4,0(sp)
    80003618:	6145                	addi	sp,sp,48
    8000361a:	8082                	ret
    panic("iget: no inodes");
    8000361c:	00005517          	auipc	a0,0x5
    80003620:	f8c50513          	addi	a0,a0,-116 # 800085a8 <syscalls+0x130>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	f1c080e7          	jalr	-228(ra) # 80000540 <panic>

000000008000362c <fsinit>:
fsinit(int dev) {
    8000362c:	7179                	addi	sp,sp,-48
    8000362e:	f406                	sd	ra,40(sp)
    80003630:	f022                	sd	s0,32(sp)
    80003632:	ec26                	sd	s1,24(sp)
    80003634:	e84a                	sd	s2,16(sp)
    80003636:	e44e                	sd	s3,8(sp)
    80003638:	1800                	addi	s0,sp,48
    8000363a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000363c:	4585                	li	a1,1
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	a62080e7          	jalr	-1438(ra) # 800030a0 <bread>
    80003646:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003648:	0001d997          	auipc	s3,0x1d
    8000364c:	3f898993          	addi	s3,s3,1016 # 80020a40 <sb>
    80003650:	02000613          	li	a2,32
    80003654:	05850593          	addi	a1,a0,88
    80003658:	854e                	mv	a0,s3
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	6fa080e7          	jalr	1786(ra) # 80000d54 <memmove>
  brelse(bp);
    80003662:	8526                	mv	a0,s1
    80003664:	00000097          	auipc	ra,0x0
    80003668:	b6c080e7          	jalr	-1172(ra) # 800031d0 <brelse>
  if(sb.magic != FSMAGIC)
    8000366c:	0009a703          	lw	a4,0(s3)
    80003670:	102037b7          	lui	a5,0x10203
    80003674:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003678:	02f71263          	bne	a4,a5,8000369c <fsinit+0x70>
  initlog(dev, &sb);
    8000367c:	0001d597          	auipc	a1,0x1d
    80003680:	3c458593          	addi	a1,a1,964 # 80020a40 <sb>
    80003684:	854a                	mv	a0,s2
    80003686:	00001097          	auipc	ra,0x1
    8000368a:	b3a080e7          	jalr	-1222(ra) # 800041c0 <initlog>
}
    8000368e:	70a2                	ld	ra,40(sp)
    80003690:	7402                	ld	s0,32(sp)
    80003692:	64e2                	ld	s1,24(sp)
    80003694:	6942                	ld	s2,16(sp)
    80003696:	69a2                	ld	s3,8(sp)
    80003698:	6145                	addi	sp,sp,48
    8000369a:	8082                	ret
    panic("invalid file system");
    8000369c:	00005517          	auipc	a0,0x5
    800036a0:	f1c50513          	addi	a0,a0,-228 # 800085b8 <syscalls+0x140>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	e9c080e7          	jalr	-356(ra) # 80000540 <panic>

00000000800036ac <iinit>:
{
    800036ac:	7179                	addi	sp,sp,-48
    800036ae:	f406                	sd	ra,40(sp)
    800036b0:	f022                	sd	s0,32(sp)
    800036b2:	ec26                	sd	s1,24(sp)
    800036b4:	e84a                	sd	s2,16(sp)
    800036b6:	e44e                	sd	s3,8(sp)
    800036b8:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800036ba:	00005597          	auipc	a1,0x5
    800036be:	f1658593          	addi	a1,a1,-234 # 800085d0 <syscalls+0x158>
    800036c2:	0001d517          	auipc	a0,0x1d
    800036c6:	39e50513          	addi	a0,a0,926 # 80020a60 <icache>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	4a2080e7          	jalr	1186(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    800036d2:	0001d497          	auipc	s1,0x1d
    800036d6:	3b648493          	addi	s1,s1,950 # 80020a88 <icache+0x28>
    800036da:	0001f997          	auipc	s3,0x1f
    800036de:	e3e98993          	addi	s3,s3,-450 # 80022518 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800036e2:	00005917          	auipc	s2,0x5
    800036e6:	ef690913          	addi	s2,s2,-266 # 800085d8 <syscalls+0x160>
    800036ea:	85ca                	mv	a1,s2
    800036ec:	8526                	mv	a0,s1
    800036ee:	00001097          	auipc	ra,0x1
    800036f2:	e3a080e7          	jalr	-454(ra) # 80004528 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036f6:	08848493          	addi	s1,s1,136
    800036fa:	ff3498e3          	bne	s1,s3,800036ea <iinit+0x3e>
}
    800036fe:	70a2                	ld	ra,40(sp)
    80003700:	7402                	ld	s0,32(sp)
    80003702:	64e2                	ld	s1,24(sp)
    80003704:	6942                	ld	s2,16(sp)
    80003706:	69a2                	ld	s3,8(sp)
    80003708:	6145                	addi	sp,sp,48
    8000370a:	8082                	ret

000000008000370c <ialloc>:
{
    8000370c:	715d                	addi	sp,sp,-80
    8000370e:	e486                	sd	ra,72(sp)
    80003710:	e0a2                	sd	s0,64(sp)
    80003712:	fc26                	sd	s1,56(sp)
    80003714:	f84a                	sd	s2,48(sp)
    80003716:	f44e                	sd	s3,40(sp)
    80003718:	f052                	sd	s4,32(sp)
    8000371a:	ec56                	sd	s5,24(sp)
    8000371c:	e85a                	sd	s6,16(sp)
    8000371e:	e45e                	sd	s7,8(sp)
    80003720:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003722:	0001d717          	auipc	a4,0x1d
    80003726:	32a72703          	lw	a4,810(a4) # 80020a4c <sb+0xc>
    8000372a:	4785                	li	a5,1
    8000372c:	04e7fa63          	bgeu	a5,a4,80003780 <ialloc+0x74>
    80003730:	8aaa                	mv	s5,a0
    80003732:	8bae                	mv	s7,a1
    80003734:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003736:	0001da17          	auipc	s4,0x1d
    8000373a:	30aa0a13          	addi	s4,s4,778 # 80020a40 <sb>
    8000373e:	00048b1b          	sext.w	s6,s1
    80003742:	0044d793          	srli	a5,s1,0x4
    80003746:	018a2583          	lw	a1,24(s4)
    8000374a:	9dbd                	addw	a1,a1,a5
    8000374c:	8556                	mv	a0,s5
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	952080e7          	jalr	-1710(ra) # 800030a0 <bread>
    80003756:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003758:	05850993          	addi	s3,a0,88
    8000375c:	00f4f793          	andi	a5,s1,15
    80003760:	079a                	slli	a5,a5,0x6
    80003762:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003764:	00099783          	lh	a5,0(s3)
    80003768:	c785                	beqz	a5,80003790 <ialloc+0x84>
    brelse(bp);
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	a66080e7          	jalr	-1434(ra) # 800031d0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003772:	0485                	addi	s1,s1,1
    80003774:	00ca2703          	lw	a4,12(s4)
    80003778:	0004879b          	sext.w	a5,s1
    8000377c:	fce7e1e3          	bltu	a5,a4,8000373e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003780:	00005517          	auipc	a0,0x5
    80003784:	e6050513          	addi	a0,a0,-416 # 800085e0 <syscalls+0x168>
    80003788:	ffffd097          	auipc	ra,0xffffd
    8000378c:	db8080e7          	jalr	-584(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    80003790:	04000613          	li	a2,64
    80003794:	4581                	li	a1,0
    80003796:	854e                	mv	a0,s3
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	560080e7          	jalr	1376(ra) # 80000cf8 <memset>
      dip->type = type;
    800037a0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037a4:	854a                	mv	a0,s2
    800037a6:	00001097          	auipc	ra,0x1
    800037aa:	c94080e7          	jalr	-876(ra) # 8000443a <log_write>
      brelse(bp);
    800037ae:	854a                	mv	a0,s2
    800037b0:	00000097          	auipc	ra,0x0
    800037b4:	a20080e7          	jalr	-1504(ra) # 800031d0 <brelse>
      return iget(dev, inum);
    800037b8:	85da                	mv	a1,s6
    800037ba:	8556                	mv	a0,s5
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	db4080e7          	jalr	-588(ra) # 80003570 <iget>
}
    800037c4:	60a6                	ld	ra,72(sp)
    800037c6:	6406                	ld	s0,64(sp)
    800037c8:	74e2                	ld	s1,56(sp)
    800037ca:	7942                	ld	s2,48(sp)
    800037cc:	79a2                	ld	s3,40(sp)
    800037ce:	7a02                	ld	s4,32(sp)
    800037d0:	6ae2                	ld	s5,24(sp)
    800037d2:	6b42                	ld	s6,16(sp)
    800037d4:	6ba2                	ld	s7,8(sp)
    800037d6:	6161                	addi	sp,sp,80
    800037d8:	8082                	ret

00000000800037da <iupdate>:
{
    800037da:	1101                	addi	sp,sp,-32
    800037dc:	ec06                	sd	ra,24(sp)
    800037de:	e822                	sd	s0,16(sp)
    800037e0:	e426                	sd	s1,8(sp)
    800037e2:	e04a                	sd	s2,0(sp)
    800037e4:	1000                	addi	s0,sp,32
    800037e6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037e8:	415c                	lw	a5,4(a0)
    800037ea:	0047d79b          	srliw	a5,a5,0x4
    800037ee:	0001d597          	auipc	a1,0x1d
    800037f2:	26a5a583          	lw	a1,618(a1) # 80020a58 <sb+0x18>
    800037f6:	9dbd                	addw	a1,a1,a5
    800037f8:	4108                	lw	a0,0(a0)
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	8a6080e7          	jalr	-1882(ra) # 800030a0 <bread>
    80003802:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003804:	05850793          	addi	a5,a0,88
    80003808:	40c8                	lw	a0,4(s1)
    8000380a:	893d                	andi	a0,a0,15
    8000380c:	051a                	slli	a0,a0,0x6
    8000380e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003810:	04449703          	lh	a4,68(s1)
    80003814:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003818:	04649703          	lh	a4,70(s1)
    8000381c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003820:	04849703          	lh	a4,72(s1)
    80003824:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003828:	04a49703          	lh	a4,74(s1)
    8000382c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003830:	44f8                	lw	a4,76(s1)
    80003832:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003834:	03400613          	li	a2,52
    80003838:	05048593          	addi	a1,s1,80
    8000383c:	0531                	addi	a0,a0,12
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	516080e7          	jalr	1302(ra) # 80000d54 <memmove>
  log_write(bp);
    80003846:	854a                	mv	a0,s2
    80003848:	00001097          	auipc	ra,0x1
    8000384c:	bf2080e7          	jalr	-1038(ra) # 8000443a <log_write>
  brelse(bp);
    80003850:	854a                	mv	a0,s2
    80003852:	00000097          	auipc	ra,0x0
    80003856:	97e080e7          	jalr	-1666(ra) # 800031d0 <brelse>
}
    8000385a:	60e2                	ld	ra,24(sp)
    8000385c:	6442                	ld	s0,16(sp)
    8000385e:	64a2                	ld	s1,8(sp)
    80003860:	6902                	ld	s2,0(sp)
    80003862:	6105                	addi	sp,sp,32
    80003864:	8082                	ret

0000000080003866 <idup>:
{
    80003866:	1101                	addi	sp,sp,-32
    80003868:	ec06                	sd	ra,24(sp)
    8000386a:	e822                	sd	s0,16(sp)
    8000386c:	e426                	sd	s1,8(sp)
    8000386e:	1000                	addi	s0,sp,32
    80003870:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003872:	0001d517          	auipc	a0,0x1d
    80003876:	1ee50513          	addi	a0,a0,494 # 80020a60 <icache>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	382080e7          	jalr	898(ra) # 80000bfc <acquire>
  ip->ref++;
    80003882:	449c                	lw	a5,8(s1)
    80003884:	2785                	addiw	a5,a5,1
    80003886:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003888:	0001d517          	auipc	a0,0x1d
    8000388c:	1d850513          	addi	a0,a0,472 # 80020a60 <icache>
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	420080e7          	jalr	1056(ra) # 80000cb0 <release>
}
    80003898:	8526                	mv	a0,s1
    8000389a:	60e2                	ld	ra,24(sp)
    8000389c:	6442                	ld	s0,16(sp)
    8000389e:	64a2                	ld	s1,8(sp)
    800038a0:	6105                	addi	sp,sp,32
    800038a2:	8082                	ret

00000000800038a4 <ilock>:
{
    800038a4:	1101                	addi	sp,sp,-32
    800038a6:	ec06                	sd	ra,24(sp)
    800038a8:	e822                	sd	s0,16(sp)
    800038aa:	e426                	sd	s1,8(sp)
    800038ac:	e04a                	sd	s2,0(sp)
    800038ae:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038b0:	c115                	beqz	a0,800038d4 <ilock+0x30>
    800038b2:	84aa                	mv	s1,a0
    800038b4:	451c                	lw	a5,8(a0)
    800038b6:	00f05f63          	blez	a5,800038d4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038ba:	0541                	addi	a0,a0,16
    800038bc:	00001097          	auipc	ra,0x1
    800038c0:	ca6080e7          	jalr	-858(ra) # 80004562 <acquiresleep>
  if(ip->valid == 0){
    800038c4:	40bc                	lw	a5,64(s1)
    800038c6:	cf99                	beqz	a5,800038e4 <ilock+0x40>
}
    800038c8:	60e2                	ld	ra,24(sp)
    800038ca:	6442                	ld	s0,16(sp)
    800038cc:	64a2                	ld	s1,8(sp)
    800038ce:	6902                	ld	s2,0(sp)
    800038d0:	6105                	addi	sp,sp,32
    800038d2:	8082                	ret
    panic("ilock");
    800038d4:	00005517          	auipc	a0,0x5
    800038d8:	d2450513          	addi	a0,a0,-732 # 800085f8 <syscalls+0x180>
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	c64080e7          	jalr	-924(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038e4:	40dc                	lw	a5,4(s1)
    800038e6:	0047d79b          	srliw	a5,a5,0x4
    800038ea:	0001d597          	auipc	a1,0x1d
    800038ee:	16e5a583          	lw	a1,366(a1) # 80020a58 <sb+0x18>
    800038f2:	9dbd                	addw	a1,a1,a5
    800038f4:	4088                	lw	a0,0(s1)
    800038f6:	fffff097          	auipc	ra,0xfffff
    800038fa:	7aa080e7          	jalr	1962(ra) # 800030a0 <bread>
    800038fe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003900:	05850593          	addi	a1,a0,88
    80003904:	40dc                	lw	a5,4(s1)
    80003906:	8bbd                	andi	a5,a5,15
    80003908:	079a                	slli	a5,a5,0x6
    8000390a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000390c:	00059783          	lh	a5,0(a1)
    80003910:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003914:	00259783          	lh	a5,2(a1)
    80003918:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000391c:	00459783          	lh	a5,4(a1)
    80003920:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003924:	00659783          	lh	a5,6(a1)
    80003928:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000392c:	459c                	lw	a5,8(a1)
    8000392e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003930:	03400613          	li	a2,52
    80003934:	05b1                	addi	a1,a1,12
    80003936:	05048513          	addi	a0,s1,80
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	41a080e7          	jalr	1050(ra) # 80000d54 <memmove>
    brelse(bp);
    80003942:	854a                	mv	a0,s2
    80003944:	00000097          	auipc	ra,0x0
    80003948:	88c080e7          	jalr	-1908(ra) # 800031d0 <brelse>
    ip->valid = 1;
    8000394c:	4785                	li	a5,1
    8000394e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003950:	04449783          	lh	a5,68(s1)
    80003954:	fbb5                	bnez	a5,800038c8 <ilock+0x24>
      panic("ilock: no type");
    80003956:	00005517          	auipc	a0,0x5
    8000395a:	caa50513          	addi	a0,a0,-854 # 80008600 <syscalls+0x188>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	be2080e7          	jalr	-1054(ra) # 80000540 <panic>

0000000080003966 <iunlock>:
{
    80003966:	1101                	addi	sp,sp,-32
    80003968:	ec06                	sd	ra,24(sp)
    8000396a:	e822                	sd	s0,16(sp)
    8000396c:	e426                	sd	s1,8(sp)
    8000396e:	e04a                	sd	s2,0(sp)
    80003970:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003972:	c905                	beqz	a0,800039a2 <iunlock+0x3c>
    80003974:	84aa                	mv	s1,a0
    80003976:	01050913          	addi	s2,a0,16
    8000397a:	854a                	mv	a0,s2
    8000397c:	00001097          	auipc	ra,0x1
    80003980:	c80080e7          	jalr	-896(ra) # 800045fc <holdingsleep>
    80003984:	cd19                	beqz	a0,800039a2 <iunlock+0x3c>
    80003986:	449c                	lw	a5,8(s1)
    80003988:	00f05d63          	blez	a5,800039a2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000398c:	854a                	mv	a0,s2
    8000398e:	00001097          	auipc	ra,0x1
    80003992:	c2a080e7          	jalr	-982(ra) # 800045b8 <releasesleep>
}
    80003996:	60e2                	ld	ra,24(sp)
    80003998:	6442                	ld	s0,16(sp)
    8000399a:	64a2                	ld	s1,8(sp)
    8000399c:	6902                	ld	s2,0(sp)
    8000399e:	6105                	addi	sp,sp,32
    800039a0:	8082                	ret
    panic("iunlock");
    800039a2:	00005517          	auipc	a0,0x5
    800039a6:	c6e50513          	addi	a0,a0,-914 # 80008610 <syscalls+0x198>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	b96080e7          	jalr	-1130(ra) # 80000540 <panic>

00000000800039b2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039b2:	7179                	addi	sp,sp,-48
    800039b4:	f406                	sd	ra,40(sp)
    800039b6:	f022                	sd	s0,32(sp)
    800039b8:	ec26                	sd	s1,24(sp)
    800039ba:	e84a                	sd	s2,16(sp)
    800039bc:	e44e                	sd	s3,8(sp)
    800039be:	e052                	sd	s4,0(sp)
    800039c0:	1800                	addi	s0,sp,48
    800039c2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039c4:	05050493          	addi	s1,a0,80
    800039c8:	08050913          	addi	s2,a0,128
    800039cc:	a021                	j	800039d4 <itrunc+0x22>
    800039ce:	0491                	addi	s1,s1,4
    800039d0:	01248d63          	beq	s1,s2,800039ea <itrunc+0x38>
    if(ip->addrs[i]){
    800039d4:	408c                	lw	a1,0(s1)
    800039d6:	dde5                	beqz	a1,800039ce <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039d8:	0009a503          	lw	a0,0(s3)
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	90a080e7          	jalr	-1782(ra) # 800032e6 <bfree>
      ip->addrs[i] = 0;
    800039e4:	0004a023          	sw	zero,0(s1)
    800039e8:	b7dd                	j	800039ce <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039ea:	0809a583          	lw	a1,128(s3)
    800039ee:	e185                	bnez	a1,80003a0e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039f0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039f4:	854e                	mv	a0,s3
    800039f6:	00000097          	auipc	ra,0x0
    800039fa:	de4080e7          	jalr	-540(ra) # 800037da <iupdate>
}
    800039fe:	70a2                	ld	ra,40(sp)
    80003a00:	7402                	ld	s0,32(sp)
    80003a02:	64e2                	ld	s1,24(sp)
    80003a04:	6942                	ld	s2,16(sp)
    80003a06:	69a2                	ld	s3,8(sp)
    80003a08:	6a02                	ld	s4,0(sp)
    80003a0a:	6145                	addi	sp,sp,48
    80003a0c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a0e:	0009a503          	lw	a0,0(s3)
    80003a12:	fffff097          	auipc	ra,0xfffff
    80003a16:	68e080e7          	jalr	1678(ra) # 800030a0 <bread>
    80003a1a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a1c:	05850493          	addi	s1,a0,88
    80003a20:	45850913          	addi	s2,a0,1112
    80003a24:	a021                	j	80003a2c <itrunc+0x7a>
    80003a26:	0491                	addi	s1,s1,4
    80003a28:	01248b63          	beq	s1,s2,80003a3e <itrunc+0x8c>
      if(a[j])
    80003a2c:	408c                	lw	a1,0(s1)
    80003a2e:	dde5                	beqz	a1,80003a26 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a30:	0009a503          	lw	a0,0(s3)
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	8b2080e7          	jalr	-1870(ra) # 800032e6 <bfree>
    80003a3c:	b7ed                	j	80003a26 <itrunc+0x74>
    brelse(bp);
    80003a3e:	8552                	mv	a0,s4
    80003a40:	fffff097          	auipc	ra,0xfffff
    80003a44:	790080e7          	jalr	1936(ra) # 800031d0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a48:	0809a583          	lw	a1,128(s3)
    80003a4c:	0009a503          	lw	a0,0(s3)
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	896080e7          	jalr	-1898(ra) # 800032e6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a58:	0809a023          	sw	zero,128(s3)
    80003a5c:	bf51                	j	800039f0 <itrunc+0x3e>

0000000080003a5e <iput>:
{
    80003a5e:	1101                	addi	sp,sp,-32
    80003a60:	ec06                	sd	ra,24(sp)
    80003a62:	e822                	sd	s0,16(sp)
    80003a64:	e426                	sd	s1,8(sp)
    80003a66:	e04a                	sd	s2,0(sp)
    80003a68:	1000                	addi	s0,sp,32
    80003a6a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a6c:	0001d517          	auipc	a0,0x1d
    80003a70:	ff450513          	addi	a0,a0,-12 # 80020a60 <icache>
    80003a74:	ffffd097          	auipc	ra,0xffffd
    80003a78:	188080e7          	jalr	392(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a7c:	4498                	lw	a4,8(s1)
    80003a7e:	4785                	li	a5,1
    80003a80:	02f70363          	beq	a4,a5,80003aa6 <iput+0x48>
  ip->ref--;
    80003a84:	449c                	lw	a5,8(s1)
    80003a86:	37fd                	addiw	a5,a5,-1
    80003a88:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a8a:	0001d517          	auipc	a0,0x1d
    80003a8e:	fd650513          	addi	a0,a0,-42 # 80020a60 <icache>
    80003a92:	ffffd097          	auipc	ra,0xffffd
    80003a96:	21e080e7          	jalr	542(ra) # 80000cb0 <release>
}
    80003a9a:	60e2                	ld	ra,24(sp)
    80003a9c:	6442                	ld	s0,16(sp)
    80003a9e:	64a2                	ld	s1,8(sp)
    80003aa0:	6902                	ld	s2,0(sp)
    80003aa2:	6105                	addi	sp,sp,32
    80003aa4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aa6:	40bc                	lw	a5,64(s1)
    80003aa8:	dff1                	beqz	a5,80003a84 <iput+0x26>
    80003aaa:	04a49783          	lh	a5,74(s1)
    80003aae:	fbf9                	bnez	a5,80003a84 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ab0:	01048913          	addi	s2,s1,16
    80003ab4:	854a                	mv	a0,s2
    80003ab6:	00001097          	auipc	ra,0x1
    80003aba:	aac080e7          	jalr	-1364(ra) # 80004562 <acquiresleep>
    release(&icache.lock);
    80003abe:	0001d517          	auipc	a0,0x1d
    80003ac2:	fa250513          	addi	a0,a0,-94 # 80020a60 <icache>
    80003ac6:	ffffd097          	auipc	ra,0xffffd
    80003aca:	1ea080e7          	jalr	490(ra) # 80000cb0 <release>
    itrunc(ip);
    80003ace:	8526                	mv	a0,s1
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	ee2080e7          	jalr	-286(ra) # 800039b2 <itrunc>
    ip->type = 0;
    80003ad8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003adc:	8526                	mv	a0,s1
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	cfc080e7          	jalr	-772(ra) # 800037da <iupdate>
    ip->valid = 0;
    80003ae6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003aea:	854a                	mv	a0,s2
    80003aec:	00001097          	auipc	ra,0x1
    80003af0:	acc080e7          	jalr	-1332(ra) # 800045b8 <releasesleep>
    acquire(&icache.lock);
    80003af4:	0001d517          	auipc	a0,0x1d
    80003af8:	f6c50513          	addi	a0,a0,-148 # 80020a60 <icache>
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	100080e7          	jalr	256(ra) # 80000bfc <acquire>
    80003b04:	b741                	j	80003a84 <iput+0x26>

0000000080003b06 <iunlockput>:
{
    80003b06:	1101                	addi	sp,sp,-32
    80003b08:	ec06                	sd	ra,24(sp)
    80003b0a:	e822                	sd	s0,16(sp)
    80003b0c:	e426                	sd	s1,8(sp)
    80003b0e:	1000                	addi	s0,sp,32
    80003b10:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	e54080e7          	jalr	-428(ra) # 80003966 <iunlock>
  iput(ip);
    80003b1a:	8526                	mv	a0,s1
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	f42080e7          	jalr	-190(ra) # 80003a5e <iput>
}
    80003b24:	60e2                	ld	ra,24(sp)
    80003b26:	6442                	ld	s0,16(sp)
    80003b28:	64a2                	ld	s1,8(sp)
    80003b2a:	6105                	addi	sp,sp,32
    80003b2c:	8082                	ret

0000000080003b2e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b2e:	1141                	addi	sp,sp,-16
    80003b30:	e422                	sd	s0,8(sp)
    80003b32:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b34:	411c                	lw	a5,0(a0)
    80003b36:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b38:	415c                	lw	a5,4(a0)
    80003b3a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b3c:	04451783          	lh	a5,68(a0)
    80003b40:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b44:	04a51783          	lh	a5,74(a0)
    80003b48:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b4c:	04c56783          	lwu	a5,76(a0)
    80003b50:	e99c                	sd	a5,16(a1)
}
    80003b52:	6422                	ld	s0,8(sp)
    80003b54:	0141                	addi	sp,sp,16
    80003b56:	8082                	ret

0000000080003b58 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b58:	457c                	lw	a5,76(a0)
    80003b5a:	0ed7e863          	bltu	a5,a3,80003c4a <readi+0xf2>
{
    80003b5e:	7159                	addi	sp,sp,-112
    80003b60:	f486                	sd	ra,104(sp)
    80003b62:	f0a2                	sd	s0,96(sp)
    80003b64:	eca6                	sd	s1,88(sp)
    80003b66:	e8ca                	sd	s2,80(sp)
    80003b68:	e4ce                	sd	s3,72(sp)
    80003b6a:	e0d2                	sd	s4,64(sp)
    80003b6c:	fc56                	sd	s5,56(sp)
    80003b6e:	f85a                	sd	s6,48(sp)
    80003b70:	f45e                	sd	s7,40(sp)
    80003b72:	f062                	sd	s8,32(sp)
    80003b74:	ec66                	sd	s9,24(sp)
    80003b76:	e86a                	sd	s10,16(sp)
    80003b78:	e46e                	sd	s11,8(sp)
    80003b7a:	1880                	addi	s0,sp,112
    80003b7c:	8baa                	mv	s7,a0
    80003b7e:	8c2e                	mv	s8,a1
    80003b80:	8ab2                	mv	s5,a2
    80003b82:	84b6                	mv	s1,a3
    80003b84:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b86:	9f35                	addw	a4,a4,a3
    return 0;
    80003b88:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b8a:	08d76f63          	bltu	a4,a3,80003c28 <readi+0xd0>
  if(off + n > ip->size)
    80003b8e:	00e7f463          	bgeu	a5,a4,80003b96 <readi+0x3e>
    n = ip->size - off;
    80003b92:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b96:	0a0b0863          	beqz	s6,80003c46 <readi+0xee>
    80003b9a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b9c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ba0:	5cfd                	li	s9,-1
    80003ba2:	a82d                	j	80003bdc <readi+0x84>
    80003ba4:	020a1d93          	slli	s11,s4,0x20
    80003ba8:	020ddd93          	srli	s11,s11,0x20
    80003bac:	05890793          	addi	a5,s2,88
    80003bb0:	86ee                	mv	a3,s11
    80003bb2:	963e                	add	a2,a2,a5
    80003bb4:	85d6                	mv	a1,s5
    80003bb6:	8562                	mv	a0,s8
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	ae8080e7          	jalr	-1304(ra) # 800026a0 <either_copyout>
    80003bc0:	05950d63          	beq	a0,s9,80003c1a <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003bc4:	854a                	mv	a0,s2
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	60a080e7          	jalr	1546(ra) # 800031d0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bce:	013a09bb          	addw	s3,s4,s3
    80003bd2:	009a04bb          	addw	s1,s4,s1
    80003bd6:	9aee                	add	s5,s5,s11
    80003bd8:	0569f663          	bgeu	s3,s6,80003c24 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bdc:	000ba903          	lw	s2,0(s7)
    80003be0:	00a4d59b          	srliw	a1,s1,0xa
    80003be4:	855e                	mv	a0,s7
    80003be6:	00000097          	auipc	ra,0x0
    80003bea:	8ae080e7          	jalr	-1874(ra) # 80003494 <bmap>
    80003bee:	0005059b          	sext.w	a1,a0
    80003bf2:	854a                	mv	a0,s2
    80003bf4:	fffff097          	auipc	ra,0xfffff
    80003bf8:	4ac080e7          	jalr	1196(ra) # 800030a0 <bread>
    80003bfc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bfe:	3ff4f613          	andi	a2,s1,1023
    80003c02:	40cd07bb          	subw	a5,s10,a2
    80003c06:	413b073b          	subw	a4,s6,s3
    80003c0a:	8a3e                	mv	s4,a5
    80003c0c:	2781                	sext.w	a5,a5
    80003c0e:	0007069b          	sext.w	a3,a4
    80003c12:	f8f6f9e3          	bgeu	a3,a5,80003ba4 <readi+0x4c>
    80003c16:	8a3a                	mv	s4,a4
    80003c18:	b771                	j	80003ba4 <readi+0x4c>
      brelse(bp);
    80003c1a:	854a                	mv	a0,s2
    80003c1c:	fffff097          	auipc	ra,0xfffff
    80003c20:	5b4080e7          	jalr	1460(ra) # 800031d0 <brelse>
  }
  return tot;
    80003c24:	0009851b          	sext.w	a0,s3
}
    80003c28:	70a6                	ld	ra,104(sp)
    80003c2a:	7406                	ld	s0,96(sp)
    80003c2c:	64e6                	ld	s1,88(sp)
    80003c2e:	6946                	ld	s2,80(sp)
    80003c30:	69a6                	ld	s3,72(sp)
    80003c32:	6a06                	ld	s4,64(sp)
    80003c34:	7ae2                	ld	s5,56(sp)
    80003c36:	7b42                	ld	s6,48(sp)
    80003c38:	7ba2                	ld	s7,40(sp)
    80003c3a:	7c02                	ld	s8,32(sp)
    80003c3c:	6ce2                	ld	s9,24(sp)
    80003c3e:	6d42                	ld	s10,16(sp)
    80003c40:	6da2                	ld	s11,8(sp)
    80003c42:	6165                	addi	sp,sp,112
    80003c44:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c46:	89da                	mv	s3,s6
    80003c48:	bff1                	j	80003c24 <readi+0xcc>
    return 0;
    80003c4a:	4501                	li	a0,0
}
    80003c4c:	8082                	ret

0000000080003c4e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c4e:	457c                	lw	a5,76(a0)
    80003c50:	10d7e663          	bltu	a5,a3,80003d5c <writei+0x10e>
{
    80003c54:	7159                	addi	sp,sp,-112
    80003c56:	f486                	sd	ra,104(sp)
    80003c58:	f0a2                	sd	s0,96(sp)
    80003c5a:	eca6                	sd	s1,88(sp)
    80003c5c:	e8ca                	sd	s2,80(sp)
    80003c5e:	e4ce                	sd	s3,72(sp)
    80003c60:	e0d2                	sd	s4,64(sp)
    80003c62:	fc56                	sd	s5,56(sp)
    80003c64:	f85a                	sd	s6,48(sp)
    80003c66:	f45e                	sd	s7,40(sp)
    80003c68:	f062                	sd	s8,32(sp)
    80003c6a:	ec66                	sd	s9,24(sp)
    80003c6c:	e86a                	sd	s10,16(sp)
    80003c6e:	e46e                	sd	s11,8(sp)
    80003c70:	1880                	addi	s0,sp,112
    80003c72:	8baa                	mv	s7,a0
    80003c74:	8c2e                	mv	s8,a1
    80003c76:	8ab2                	mv	s5,a2
    80003c78:	8936                	mv	s2,a3
    80003c7a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c7c:	00e687bb          	addw	a5,a3,a4
    80003c80:	0ed7e063          	bltu	a5,a3,80003d60 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c84:	00043737          	lui	a4,0x43
    80003c88:	0cf76e63          	bltu	a4,a5,80003d64 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c8c:	0a0b0763          	beqz	s6,80003d3a <writei+0xec>
    80003c90:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c92:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c96:	5cfd                	li	s9,-1
    80003c98:	a091                	j	80003cdc <writei+0x8e>
    80003c9a:	02099d93          	slli	s11,s3,0x20
    80003c9e:	020ddd93          	srli	s11,s11,0x20
    80003ca2:	05848793          	addi	a5,s1,88
    80003ca6:	86ee                	mv	a3,s11
    80003ca8:	8656                	mv	a2,s5
    80003caa:	85e2                	mv	a1,s8
    80003cac:	953e                	add	a0,a0,a5
    80003cae:	fffff097          	auipc	ra,0xfffff
    80003cb2:	a48080e7          	jalr	-1464(ra) # 800026f6 <either_copyin>
    80003cb6:	07950263          	beq	a0,s9,80003d1a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cba:	8526                	mv	a0,s1
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	77e080e7          	jalr	1918(ra) # 8000443a <log_write>
    brelse(bp);
    80003cc4:	8526                	mv	a0,s1
    80003cc6:	fffff097          	auipc	ra,0xfffff
    80003cca:	50a080e7          	jalr	1290(ra) # 800031d0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cce:	01498a3b          	addw	s4,s3,s4
    80003cd2:	0129893b          	addw	s2,s3,s2
    80003cd6:	9aee                	add	s5,s5,s11
    80003cd8:	056a7663          	bgeu	s4,s6,80003d24 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cdc:	000ba483          	lw	s1,0(s7)
    80003ce0:	00a9559b          	srliw	a1,s2,0xa
    80003ce4:	855e                	mv	a0,s7
    80003ce6:	fffff097          	auipc	ra,0xfffff
    80003cea:	7ae080e7          	jalr	1966(ra) # 80003494 <bmap>
    80003cee:	0005059b          	sext.w	a1,a0
    80003cf2:	8526                	mv	a0,s1
    80003cf4:	fffff097          	auipc	ra,0xfffff
    80003cf8:	3ac080e7          	jalr	940(ra) # 800030a0 <bread>
    80003cfc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cfe:	3ff97513          	andi	a0,s2,1023
    80003d02:	40ad07bb          	subw	a5,s10,a0
    80003d06:	414b073b          	subw	a4,s6,s4
    80003d0a:	89be                	mv	s3,a5
    80003d0c:	2781                	sext.w	a5,a5
    80003d0e:	0007069b          	sext.w	a3,a4
    80003d12:	f8f6f4e3          	bgeu	a3,a5,80003c9a <writei+0x4c>
    80003d16:	89ba                	mv	s3,a4
    80003d18:	b749                	j	80003c9a <writei+0x4c>
      brelse(bp);
    80003d1a:	8526                	mv	a0,s1
    80003d1c:	fffff097          	auipc	ra,0xfffff
    80003d20:	4b4080e7          	jalr	1204(ra) # 800031d0 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003d24:	04cba783          	lw	a5,76(s7)
    80003d28:	0127f463          	bgeu	a5,s2,80003d30 <writei+0xe2>
      ip->size = off;
    80003d2c:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d30:	855e                	mv	a0,s7
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	aa8080e7          	jalr	-1368(ra) # 800037da <iupdate>
  }

  return n;
    80003d3a:	000b051b          	sext.w	a0,s6
}
    80003d3e:	70a6                	ld	ra,104(sp)
    80003d40:	7406                	ld	s0,96(sp)
    80003d42:	64e6                	ld	s1,88(sp)
    80003d44:	6946                	ld	s2,80(sp)
    80003d46:	69a6                	ld	s3,72(sp)
    80003d48:	6a06                	ld	s4,64(sp)
    80003d4a:	7ae2                	ld	s5,56(sp)
    80003d4c:	7b42                	ld	s6,48(sp)
    80003d4e:	7ba2                	ld	s7,40(sp)
    80003d50:	7c02                	ld	s8,32(sp)
    80003d52:	6ce2                	ld	s9,24(sp)
    80003d54:	6d42                	ld	s10,16(sp)
    80003d56:	6da2                	ld	s11,8(sp)
    80003d58:	6165                	addi	sp,sp,112
    80003d5a:	8082                	ret
    return -1;
    80003d5c:	557d                	li	a0,-1
}
    80003d5e:	8082                	ret
    return -1;
    80003d60:	557d                	li	a0,-1
    80003d62:	bff1                	j	80003d3e <writei+0xf0>
    return -1;
    80003d64:	557d                	li	a0,-1
    80003d66:	bfe1                	j	80003d3e <writei+0xf0>

0000000080003d68 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d68:	1141                	addi	sp,sp,-16
    80003d6a:	e406                	sd	ra,8(sp)
    80003d6c:	e022                	sd	s0,0(sp)
    80003d6e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d70:	4639                	li	a2,14
    80003d72:	ffffd097          	auipc	ra,0xffffd
    80003d76:	05e080e7          	jalr	94(ra) # 80000dd0 <strncmp>
}
    80003d7a:	60a2                	ld	ra,8(sp)
    80003d7c:	6402                	ld	s0,0(sp)
    80003d7e:	0141                	addi	sp,sp,16
    80003d80:	8082                	ret

0000000080003d82 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d82:	7139                	addi	sp,sp,-64
    80003d84:	fc06                	sd	ra,56(sp)
    80003d86:	f822                	sd	s0,48(sp)
    80003d88:	f426                	sd	s1,40(sp)
    80003d8a:	f04a                	sd	s2,32(sp)
    80003d8c:	ec4e                	sd	s3,24(sp)
    80003d8e:	e852                	sd	s4,16(sp)
    80003d90:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d92:	04451703          	lh	a4,68(a0)
    80003d96:	4785                	li	a5,1
    80003d98:	00f71a63          	bne	a4,a5,80003dac <dirlookup+0x2a>
    80003d9c:	892a                	mv	s2,a0
    80003d9e:	89ae                	mv	s3,a1
    80003da0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003da2:	457c                	lw	a5,76(a0)
    80003da4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003da6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003da8:	e79d                	bnez	a5,80003dd6 <dirlookup+0x54>
    80003daa:	a8a5                	j	80003e22 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dac:	00005517          	auipc	a0,0x5
    80003db0:	86c50513          	addi	a0,a0,-1940 # 80008618 <syscalls+0x1a0>
    80003db4:	ffffc097          	auipc	ra,0xffffc
    80003db8:	78c080e7          	jalr	1932(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003dbc:	00005517          	auipc	a0,0x5
    80003dc0:	87450513          	addi	a0,a0,-1932 # 80008630 <syscalls+0x1b8>
    80003dc4:	ffffc097          	auipc	ra,0xffffc
    80003dc8:	77c080e7          	jalr	1916(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dcc:	24c1                	addiw	s1,s1,16
    80003dce:	04c92783          	lw	a5,76(s2)
    80003dd2:	04f4f763          	bgeu	s1,a5,80003e20 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dd6:	4741                	li	a4,16
    80003dd8:	86a6                	mv	a3,s1
    80003dda:	fc040613          	addi	a2,s0,-64
    80003dde:	4581                	li	a1,0
    80003de0:	854a                	mv	a0,s2
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	d76080e7          	jalr	-650(ra) # 80003b58 <readi>
    80003dea:	47c1                	li	a5,16
    80003dec:	fcf518e3          	bne	a0,a5,80003dbc <dirlookup+0x3a>
    if(de.inum == 0)
    80003df0:	fc045783          	lhu	a5,-64(s0)
    80003df4:	dfe1                	beqz	a5,80003dcc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003df6:	fc240593          	addi	a1,s0,-62
    80003dfa:	854e                	mv	a0,s3
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	f6c080e7          	jalr	-148(ra) # 80003d68 <namecmp>
    80003e04:	f561                	bnez	a0,80003dcc <dirlookup+0x4a>
      if(poff)
    80003e06:	000a0463          	beqz	s4,80003e0e <dirlookup+0x8c>
        *poff = off;
    80003e0a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e0e:	fc045583          	lhu	a1,-64(s0)
    80003e12:	00092503          	lw	a0,0(s2)
    80003e16:	fffff097          	auipc	ra,0xfffff
    80003e1a:	75a080e7          	jalr	1882(ra) # 80003570 <iget>
    80003e1e:	a011                	j	80003e22 <dirlookup+0xa0>
  return 0;
    80003e20:	4501                	li	a0,0
}
    80003e22:	70e2                	ld	ra,56(sp)
    80003e24:	7442                	ld	s0,48(sp)
    80003e26:	74a2                	ld	s1,40(sp)
    80003e28:	7902                	ld	s2,32(sp)
    80003e2a:	69e2                	ld	s3,24(sp)
    80003e2c:	6a42                	ld	s4,16(sp)
    80003e2e:	6121                	addi	sp,sp,64
    80003e30:	8082                	ret

0000000080003e32 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e32:	711d                	addi	sp,sp,-96
    80003e34:	ec86                	sd	ra,88(sp)
    80003e36:	e8a2                	sd	s0,80(sp)
    80003e38:	e4a6                	sd	s1,72(sp)
    80003e3a:	e0ca                	sd	s2,64(sp)
    80003e3c:	fc4e                	sd	s3,56(sp)
    80003e3e:	f852                	sd	s4,48(sp)
    80003e40:	f456                	sd	s5,40(sp)
    80003e42:	f05a                	sd	s6,32(sp)
    80003e44:	ec5e                	sd	s7,24(sp)
    80003e46:	e862                	sd	s8,16(sp)
    80003e48:	e466                	sd	s9,8(sp)
    80003e4a:	1080                	addi	s0,sp,96
    80003e4c:	84aa                	mv	s1,a0
    80003e4e:	8aae                	mv	s5,a1
    80003e50:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e52:	00054703          	lbu	a4,0(a0)
    80003e56:	02f00793          	li	a5,47
    80003e5a:	02f70363          	beq	a4,a5,80003e80 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e5e:	ffffe097          	auipc	ra,0xffffe
    80003e62:	c94080e7          	jalr	-876(ra) # 80001af2 <myproc>
    80003e66:	15053503          	ld	a0,336(a0)
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	9fc080e7          	jalr	-1540(ra) # 80003866 <idup>
    80003e72:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e74:	02f00913          	li	s2,47
  len = path - s;
    80003e78:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e7a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e7c:	4b85                	li	s7,1
    80003e7e:	a865                	j	80003f36 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e80:	4585                	li	a1,1
    80003e82:	4505                	li	a0,1
    80003e84:	fffff097          	auipc	ra,0xfffff
    80003e88:	6ec080e7          	jalr	1772(ra) # 80003570 <iget>
    80003e8c:	89aa                	mv	s3,a0
    80003e8e:	b7dd                	j	80003e74 <namex+0x42>
      iunlockput(ip);
    80003e90:	854e                	mv	a0,s3
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	c74080e7          	jalr	-908(ra) # 80003b06 <iunlockput>
      return 0;
    80003e9a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e9c:	854e                	mv	a0,s3
    80003e9e:	60e6                	ld	ra,88(sp)
    80003ea0:	6446                	ld	s0,80(sp)
    80003ea2:	64a6                	ld	s1,72(sp)
    80003ea4:	6906                	ld	s2,64(sp)
    80003ea6:	79e2                	ld	s3,56(sp)
    80003ea8:	7a42                	ld	s4,48(sp)
    80003eaa:	7aa2                	ld	s5,40(sp)
    80003eac:	7b02                	ld	s6,32(sp)
    80003eae:	6be2                	ld	s7,24(sp)
    80003eb0:	6c42                	ld	s8,16(sp)
    80003eb2:	6ca2                	ld	s9,8(sp)
    80003eb4:	6125                	addi	sp,sp,96
    80003eb6:	8082                	ret
      iunlock(ip);
    80003eb8:	854e                	mv	a0,s3
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	aac080e7          	jalr	-1364(ra) # 80003966 <iunlock>
      return ip;
    80003ec2:	bfe9                	j	80003e9c <namex+0x6a>
      iunlockput(ip);
    80003ec4:	854e                	mv	a0,s3
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	c40080e7          	jalr	-960(ra) # 80003b06 <iunlockput>
      return 0;
    80003ece:	89e6                	mv	s3,s9
    80003ed0:	b7f1                	j	80003e9c <namex+0x6a>
  len = path - s;
    80003ed2:	40b48633          	sub	a2,s1,a1
    80003ed6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003eda:	099c5463          	bge	s8,s9,80003f62 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ede:	4639                	li	a2,14
    80003ee0:	8552                	mv	a0,s4
    80003ee2:	ffffd097          	auipc	ra,0xffffd
    80003ee6:	e72080e7          	jalr	-398(ra) # 80000d54 <memmove>
  while(*path == '/')
    80003eea:	0004c783          	lbu	a5,0(s1)
    80003eee:	01279763          	bne	a5,s2,80003efc <namex+0xca>
    path++;
    80003ef2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ef4:	0004c783          	lbu	a5,0(s1)
    80003ef8:	ff278de3          	beq	a5,s2,80003ef2 <namex+0xc0>
    ilock(ip);
    80003efc:	854e                	mv	a0,s3
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	9a6080e7          	jalr	-1626(ra) # 800038a4 <ilock>
    if(ip->type != T_DIR){
    80003f06:	04499783          	lh	a5,68(s3)
    80003f0a:	f97793e3          	bne	a5,s7,80003e90 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f0e:	000a8563          	beqz	s5,80003f18 <namex+0xe6>
    80003f12:	0004c783          	lbu	a5,0(s1)
    80003f16:	d3cd                	beqz	a5,80003eb8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f18:	865a                	mv	a2,s6
    80003f1a:	85d2                	mv	a1,s4
    80003f1c:	854e                	mv	a0,s3
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	e64080e7          	jalr	-412(ra) # 80003d82 <dirlookup>
    80003f26:	8caa                	mv	s9,a0
    80003f28:	dd51                	beqz	a0,80003ec4 <namex+0x92>
    iunlockput(ip);
    80003f2a:	854e                	mv	a0,s3
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	bda080e7          	jalr	-1062(ra) # 80003b06 <iunlockput>
    ip = next;
    80003f34:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f36:	0004c783          	lbu	a5,0(s1)
    80003f3a:	05279763          	bne	a5,s2,80003f88 <namex+0x156>
    path++;
    80003f3e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f40:	0004c783          	lbu	a5,0(s1)
    80003f44:	ff278de3          	beq	a5,s2,80003f3e <namex+0x10c>
  if(*path == 0)
    80003f48:	c79d                	beqz	a5,80003f76 <namex+0x144>
    path++;
    80003f4a:	85a6                	mv	a1,s1
  len = path - s;
    80003f4c:	8cda                	mv	s9,s6
    80003f4e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f50:	01278963          	beq	a5,s2,80003f62 <namex+0x130>
    80003f54:	dfbd                	beqz	a5,80003ed2 <namex+0xa0>
    path++;
    80003f56:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f58:	0004c783          	lbu	a5,0(s1)
    80003f5c:	ff279ce3          	bne	a5,s2,80003f54 <namex+0x122>
    80003f60:	bf8d                	j	80003ed2 <namex+0xa0>
    memmove(name, s, len);
    80003f62:	2601                	sext.w	a2,a2
    80003f64:	8552                	mv	a0,s4
    80003f66:	ffffd097          	auipc	ra,0xffffd
    80003f6a:	dee080e7          	jalr	-530(ra) # 80000d54 <memmove>
    name[len] = 0;
    80003f6e:	9cd2                	add	s9,s9,s4
    80003f70:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f74:	bf9d                	j	80003eea <namex+0xb8>
  if(nameiparent){
    80003f76:	f20a83e3          	beqz	s5,80003e9c <namex+0x6a>
    iput(ip);
    80003f7a:	854e                	mv	a0,s3
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	ae2080e7          	jalr	-1310(ra) # 80003a5e <iput>
    return 0;
    80003f84:	4981                	li	s3,0
    80003f86:	bf19                	j	80003e9c <namex+0x6a>
  if(*path == 0)
    80003f88:	d7fd                	beqz	a5,80003f76 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f8a:	0004c783          	lbu	a5,0(s1)
    80003f8e:	85a6                	mv	a1,s1
    80003f90:	b7d1                	j	80003f54 <namex+0x122>

0000000080003f92 <dirlink>:
{
    80003f92:	7139                	addi	sp,sp,-64
    80003f94:	fc06                	sd	ra,56(sp)
    80003f96:	f822                	sd	s0,48(sp)
    80003f98:	f426                	sd	s1,40(sp)
    80003f9a:	f04a                	sd	s2,32(sp)
    80003f9c:	ec4e                	sd	s3,24(sp)
    80003f9e:	e852                	sd	s4,16(sp)
    80003fa0:	0080                	addi	s0,sp,64
    80003fa2:	892a                	mv	s2,a0
    80003fa4:	8a2e                	mv	s4,a1
    80003fa6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fa8:	4601                	li	a2,0
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	dd8080e7          	jalr	-552(ra) # 80003d82 <dirlookup>
    80003fb2:	e93d                	bnez	a0,80004028 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fb4:	04c92483          	lw	s1,76(s2)
    80003fb8:	c49d                	beqz	s1,80003fe6 <dirlink+0x54>
    80003fba:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fbc:	4741                	li	a4,16
    80003fbe:	86a6                	mv	a3,s1
    80003fc0:	fc040613          	addi	a2,s0,-64
    80003fc4:	4581                	li	a1,0
    80003fc6:	854a                	mv	a0,s2
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	b90080e7          	jalr	-1136(ra) # 80003b58 <readi>
    80003fd0:	47c1                	li	a5,16
    80003fd2:	06f51163          	bne	a0,a5,80004034 <dirlink+0xa2>
    if(de.inum == 0)
    80003fd6:	fc045783          	lhu	a5,-64(s0)
    80003fda:	c791                	beqz	a5,80003fe6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fdc:	24c1                	addiw	s1,s1,16
    80003fde:	04c92783          	lw	a5,76(s2)
    80003fe2:	fcf4ede3          	bltu	s1,a5,80003fbc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fe6:	4639                	li	a2,14
    80003fe8:	85d2                	mv	a1,s4
    80003fea:	fc240513          	addi	a0,s0,-62
    80003fee:	ffffd097          	auipc	ra,0xffffd
    80003ff2:	e1e080e7          	jalr	-482(ra) # 80000e0c <strncpy>
  de.inum = inum;
    80003ff6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffa:	4741                	li	a4,16
    80003ffc:	86a6                	mv	a3,s1
    80003ffe:	fc040613          	addi	a2,s0,-64
    80004002:	4581                	li	a1,0
    80004004:	854a                	mv	a0,s2
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	c48080e7          	jalr	-952(ra) # 80003c4e <writei>
    8000400e:	872a                	mv	a4,a0
    80004010:	47c1                	li	a5,16
  return 0;
    80004012:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004014:	02f71863          	bne	a4,a5,80004044 <dirlink+0xb2>
}
    80004018:	70e2                	ld	ra,56(sp)
    8000401a:	7442                	ld	s0,48(sp)
    8000401c:	74a2                	ld	s1,40(sp)
    8000401e:	7902                	ld	s2,32(sp)
    80004020:	69e2                	ld	s3,24(sp)
    80004022:	6a42                	ld	s4,16(sp)
    80004024:	6121                	addi	sp,sp,64
    80004026:	8082                	ret
    iput(ip);
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	a36080e7          	jalr	-1482(ra) # 80003a5e <iput>
    return -1;
    80004030:	557d                	li	a0,-1
    80004032:	b7dd                	j	80004018 <dirlink+0x86>
      panic("dirlink read");
    80004034:	00004517          	auipc	a0,0x4
    80004038:	60c50513          	addi	a0,a0,1548 # 80008640 <syscalls+0x1c8>
    8000403c:	ffffc097          	auipc	ra,0xffffc
    80004040:	504080e7          	jalr	1284(ra) # 80000540 <panic>
    panic("dirlink");
    80004044:	00004517          	auipc	a0,0x4
    80004048:	71c50513          	addi	a0,a0,1820 # 80008760 <syscalls+0x2e8>
    8000404c:	ffffc097          	auipc	ra,0xffffc
    80004050:	4f4080e7          	jalr	1268(ra) # 80000540 <panic>

0000000080004054 <namei>:

struct inode*
namei(char *path)
{
    80004054:	1101                	addi	sp,sp,-32
    80004056:	ec06                	sd	ra,24(sp)
    80004058:	e822                	sd	s0,16(sp)
    8000405a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000405c:	fe040613          	addi	a2,s0,-32
    80004060:	4581                	li	a1,0
    80004062:	00000097          	auipc	ra,0x0
    80004066:	dd0080e7          	jalr	-560(ra) # 80003e32 <namex>
}
    8000406a:	60e2                	ld	ra,24(sp)
    8000406c:	6442                	ld	s0,16(sp)
    8000406e:	6105                	addi	sp,sp,32
    80004070:	8082                	ret

0000000080004072 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004072:	1141                	addi	sp,sp,-16
    80004074:	e406                	sd	ra,8(sp)
    80004076:	e022                	sd	s0,0(sp)
    80004078:	0800                	addi	s0,sp,16
    8000407a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000407c:	4585                	li	a1,1
    8000407e:	00000097          	auipc	ra,0x0
    80004082:	db4080e7          	jalr	-588(ra) # 80003e32 <namex>
}
    80004086:	60a2                	ld	ra,8(sp)
    80004088:	6402                	ld	s0,0(sp)
    8000408a:	0141                	addi	sp,sp,16
    8000408c:	8082                	ret

000000008000408e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000408e:	1101                	addi	sp,sp,-32
    80004090:	ec06                	sd	ra,24(sp)
    80004092:	e822                	sd	s0,16(sp)
    80004094:	e426                	sd	s1,8(sp)
    80004096:	e04a                	sd	s2,0(sp)
    80004098:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000409a:	0001e917          	auipc	s2,0x1e
    8000409e:	46e90913          	addi	s2,s2,1134 # 80022508 <log>
    800040a2:	01892583          	lw	a1,24(s2)
    800040a6:	02892503          	lw	a0,40(s2)
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	ff6080e7          	jalr	-10(ra) # 800030a0 <bread>
    800040b2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040b4:	02c92683          	lw	a3,44(s2)
    800040b8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040ba:	02d05863          	blez	a3,800040ea <write_head+0x5c>
    800040be:	0001e797          	auipc	a5,0x1e
    800040c2:	47a78793          	addi	a5,a5,1146 # 80022538 <log+0x30>
    800040c6:	05c50713          	addi	a4,a0,92
    800040ca:	36fd                	addiw	a3,a3,-1
    800040cc:	02069613          	slli	a2,a3,0x20
    800040d0:	01e65693          	srli	a3,a2,0x1e
    800040d4:	0001e617          	auipc	a2,0x1e
    800040d8:	46860613          	addi	a2,a2,1128 # 8002253c <log+0x34>
    800040dc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040de:	4390                	lw	a2,0(a5)
    800040e0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040e2:	0791                	addi	a5,a5,4
    800040e4:	0711                	addi	a4,a4,4
    800040e6:	fed79ce3          	bne	a5,a3,800040de <write_head+0x50>
  }
  bwrite(buf);
    800040ea:	8526                	mv	a0,s1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	0a6080e7          	jalr	166(ra) # 80003192 <bwrite>
  brelse(buf);
    800040f4:	8526                	mv	a0,s1
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	0da080e7          	jalr	218(ra) # 800031d0 <brelse>
}
    800040fe:	60e2                	ld	ra,24(sp)
    80004100:	6442                	ld	s0,16(sp)
    80004102:	64a2                	ld	s1,8(sp)
    80004104:	6902                	ld	s2,0(sp)
    80004106:	6105                	addi	sp,sp,32
    80004108:	8082                	ret

000000008000410a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000410a:	0001e797          	auipc	a5,0x1e
    8000410e:	42a7a783          	lw	a5,1066(a5) # 80022534 <log+0x2c>
    80004112:	0af05663          	blez	a5,800041be <install_trans+0xb4>
{
    80004116:	7139                	addi	sp,sp,-64
    80004118:	fc06                	sd	ra,56(sp)
    8000411a:	f822                	sd	s0,48(sp)
    8000411c:	f426                	sd	s1,40(sp)
    8000411e:	f04a                	sd	s2,32(sp)
    80004120:	ec4e                	sd	s3,24(sp)
    80004122:	e852                	sd	s4,16(sp)
    80004124:	e456                	sd	s5,8(sp)
    80004126:	0080                	addi	s0,sp,64
    80004128:	0001ea97          	auipc	s5,0x1e
    8000412c:	410a8a93          	addi	s5,s5,1040 # 80022538 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004130:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004132:	0001e997          	auipc	s3,0x1e
    80004136:	3d698993          	addi	s3,s3,982 # 80022508 <log>
    8000413a:	0189a583          	lw	a1,24(s3)
    8000413e:	014585bb          	addw	a1,a1,s4
    80004142:	2585                	addiw	a1,a1,1
    80004144:	0289a503          	lw	a0,40(s3)
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	f58080e7          	jalr	-168(ra) # 800030a0 <bread>
    80004150:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004152:	000aa583          	lw	a1,0(s5)
    80004156:	0289a503          	lw	a0,40(s3)
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	f46080e7          	jalr	-186(ra) # 800030a0 <bread>
    80004162:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004164:	40000613          	li	a2,1024
    80004168:	05890593          	addi	a1,s2,88
    8000416c:	05850513          	addi	a0,a0,88
    80004170:	ffffd097          	auipc	ra,0xffffd
    80004174:	be4080e7          	jalr	-1052(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004178:	8526                	mv	a0,s1
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	018080e7          	jalr	24(ra) # 80003192 <bwrite>
    bunpin(dbuf);
    80004182:	8526                	mv	a0,s1
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	126080e7          	jalr	294(ra) # 800032aa <bunpin>
    brelse(lbuf);
    8000418c:	854a                	mv	a0,s2
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	042080e7          	jalr	66(ra) # 800031d0 <brelse>
    brelse(dbuf);
    80004196:	8526                	mv	a0,s1
    80004198:	fffff097          	auipc	ra,0xfffff
    8000419c:	038080e7          	jalr	56(ra) # 800031d0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a0:	2a05                	addiw	s4,s4,1
    800041a2:	0a91                	addi	s5,s5,4
    800041a4:	02c9a783          	lw	a5,44(s3)
    800041a8:	f8fa49e3          	blt	s4,a5,8000413a <install_trans+0x30>
}
    800041ac:	70e2                	ld	ra,56(sp)
    800041ae:	7442                	ld	s0,48(sp)
    800041b0:	74a2                	ld	s1,40(sp)
    800041b2:	7902                	ld	s2,32(sp)
    800041b4:	69e2                	ld	s3,24(sp)
    800041b6:	6a42                	ld	s4,16(sp)
    800041b8:	6aa2                	ld	s5,8(sp)
    800041ba:	6121                	addi	sp,sp,64
    800041bc:	8082                	ret
    800041be:	8082                	ret

00000000800041c0 <initlog>:
{
    800041c0:	7179                	addi	sp,sp,-48
    800041c2:	f406                	sd	ra,40(sp)
    800041c4:	f022                	sd	s0,32(sp)
    800041c6:	ec26                	sd	s1,24(sp)
    800041c8:	e84a                	sd	s2,16(sp)
    800041ca:	e44e                	sd	s3,8(sp)
    800041cc:	1800                	addi	s0,sp,48
    800041ce:	892a                	mv	s2,a0
    800041d0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041d2:	0001e497          	auipc	s1,0x1e
    800041d6:	33648493          	addi	s1,s1,822 # 80022508 <log>
    800041da:	00004597          	auipc	a1,0x4
    800041de:	47658593          	addi	a1,a1,1142 # 80008650 <syscalls+0x1d8>
    800041e2:	8526                	mv	a0,s1
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	988080e7          	jalr	-1656(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    800041ec:	0149a583          	lw	a1,20(s3)
    800041f0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041f2:	0109a783          	lw	a5,16(s3)
    800041f6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041f8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041fc:	854a                	mv	a0,s2
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	ea2080e7          	jalr	-350(ra) # 800030a0 <bread>
  log.lh.n = lh->n;
    80004206:	4d34                	lw	a3,88(a0)
    80004208:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000420a:	02d05663          	blez	a3,80004236 <initlog+0x76>
    8000420e:	05c50793          	addi	a5,a0,92
    80004212:	0001e717          	auipc	a4,0x1e
    80004216:	32670713          	addi	a4,a4,806 # 80022538 <log+0x30>
    8000421a:	36fd                	addiw	a3,a3,-1
    8000421c:	02069613          	slli	a2,a3,0x20
    80004220:	01e65693          	srli	a3,a2,0x1e
    80004224:	06050613          	addi	a2,a0,96
    80004228:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000422a:	4390                	lw	a2,0(a5)
    8000422c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000422e:	0791                	addi	a5,a5,4
    80004230:	0711                	addi	a4,a4,4
    80004232:	fed79ce3          	bne	a5,a3,8000422a <initlog+0x6a>
  brelse(buf);
    80004236:	fffff097          	auipc	ra,0xfffff
    8000423a:	f9a080e7          	jalr	-102(ra) # 800031d0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	ecc080e7          	jalr	-308(ra) # 8000410a <install_trans>
  log.lh.n = 0;
    80004246:	0001e797          	auipc	a5,0x1e
    8000424a:	2e07a723          	sw	zero,750(a5) # 80022534 <log+0x2c>
  write_head(); // clear the log
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	e40080e7          	jalr	-448(ra) # 8000408e <write_head>
}
    80004256:	70a2                	ld	ra,40(sp)
    80004258:	7402                	ld	s0,32(sp)
    8000425a:	64e2                	ld	s1,24(sp)
    8000425c:	6942                	ld	s2,16(sp)
    8000425e:	69a2                	ld	s3,8(sp)
    80004260:	6145                	addi	sp,sp,48
    80004262:	8082                	ret

0000000080004264 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004264:	1101                	addi	sp,sp,-32
    80004266:	ec06                	sd	ra,24(sp)
    80004268:	e822                	sd	s0,16(sp)
    8000426a:	e426                	sd	s1,8(sp)
    8000426c:	e04a                	sd	s2,0(sp)
    8000426e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004270:	0001e517          	auipc	a0,0x1e
    80004274:	29850513          	addi	a0,a0,664 # 80022508 <log>
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	984080e7          	jalr	-1660(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    80004280:	0001e497          	auipc	s1,0x1e
    80004284:	28848493          	addi	s1,s1,648 # 80022508 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004288:	4979                	li	s2,30
    8000428a:	a039                	j	80004298 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000428c:	85a6                	mv	a1,s1
    8000428e:	8526                	mv	a0,s1
    80004290:	ffffe097          	auipc	ra,0xffffe
    80004294:	180080e7          	jalr	384(ra) # 80002410 <sleep>
    if(log.committing){
    80004298:	50dc                	lw	a5,36(s1)
    8000429a:	fbed                	bnez	a5,8000428c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000429c:	509c                	lw	a5,32(s1)
    8000429e:	0017871b          	addiw	a4,a5,1
    800042a2:	0007069b          	sext.w	a3,a4
    800042a6:	0027179b          	slliw	a5,a4,0x2
    800042aa:	9fb9                	addw	a5,a5,a4
    800042ac:	0017979b          	slliw	a5,a5,0x1
    800042b0:	54d8                	lw	a4,44(s1)
    800042b2:	9fb9                	addw	a5,a5,a4
    800042b4:	00f95963          	bge	s2,a5,800042c6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042b8:	85a6                	mv	a1,s1
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffe097          	auipc	ra,0xffffe
    800042c0:	154080e7          	jalr	340(ra) # 80002410 <sleep>
    800042c4:	bfd1                	j	80004298 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042c6:	0001e517          	auipc	a0,0x1e
    800042ca:	24250513          	addi	a0,a0,578 # 80022508 <log>
    800042ce:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042d0:	ffffd097          	auipc	ra,0xffffd
    800042d4:	9e0080e7          	jalr	-1568(ra) # 80000cb0 <release>
      break;
    }
  }
}
    800042d8:	60e2                	ld	ra,24(sp)
    800042da:	6442                	ld	s0,16(sp)
    800042dc:	64a2                	ld	s1,8(sp)
    800042de:	6902                	ld	s2,0(sp)
    800042e0:	6105                	addi	sp,sp,32
    800042e2:	8082                	ret

00000000800042e4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042e4:	7139                	addi	sp,sp,-64
    800042e6:	fc06                	sd	ra,56(sp)
    800042e8:	f822                	sd	s0,48(sp)
    800042ea:	f426                	sd	s1,40(sp)
    800042ec:	f04a                	sd	s2,32(sp)
    800042ee:	ec4e                	sd	s3,24(sp)
    800042f0:	e852                	sd	s4,16(sp)
    800042f2:	e456                	sd	s5,8(sp)
    800042f4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042f6:	0001e497          	auipc	s1,0x1e
    800042fa:	21248493          	addi	s1,s1,530 # 80022508 <log>
    800042fe:	8526                	mv	a0,s1
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	8fc080e7          	jalr	-1796(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    80004308:	509c                	lw	a5,32(s1)
    8000430a:	37fd                	addiw	a5,a5,-1
    8000430c:	0007891b          	sext.w	s2,a5
    80004310:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004312:	50dc                	lw	a5,36(s1)
    80004314:	e7b9                	bnez	a5,80004362 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004316:	04091e63          	bnez	s2,80004372 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000431a:	0001e497          	auipc	s1,0x1e
    8000431e:	1ee48493          	addi	s1,s1,494 # 80022508 <log>
    80004322:	4785                	li	a5,1
    80004324:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004326:	8526                	mv	a0,s1
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	988080e7          	jalr	-1656(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004330:	54dc                	lw	a5,44(s1)
    80004332:	06f04763          	bgtz	a5,800043a0 <end_op+0xbc>
    acquire(&log.lock);
    80004336:	0001e497          	auipc	s1,0x1e
    8000433a:	1d248493          	addi	s1,s1,466 # 80022508 <log>
    8000433e:	8526                	mv	a0,s1
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	8bc080e7          	jalr	-1860(ra) # 80000bfc <acquire>
    log.committing = 0;
    80004348:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000434c:	8526                	mv	a0,s1
    8000434e:	ffffe097          	auipc	ra,0xffffe
    80004352:	25c080e7          	jalr	604(ra) # 800025aa <wakeup>
    release(&log.lock);
    80004356:	8526                	mv	a0,s1
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	958080e7          	jalr	-1704(ra) # 80000cb0 <release>
}
    80004360:	a03d                	j	8000438e <end_op+0xaa>
    panic("log.committing");
    80004362:	00004517          	auipc	a0,0x4
    80004366:	2f650513          	addi	a0,a0,758 # 80008658 <syscalls+0x1e0>
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	1d6080e7          	jalr	470(ra) # 80000540 <panic>
    wakeup(&log);
    80004372:	0001e497          	auipc	s1,0x1e
    80004376:	19648493          	addi	s1,s1,406 # 80022508 <log>
    8000437a:	8526                	mv	a0,s1
    8000437c:	ffffe097          	auipc	ra,0xffffe
    80004380:	22e080e7          	jalr	558(ra) # 800025aa <wakeup>
  release(&log.lock);
    80004384:	8526                	mv	a0,s1
    80004386:	ffffd097          	auipc	ra,0xffffd
    8000438a:	92a080e7          	jalr	-1750(ra) # 80000cb0 <release>
}
    8000438e:	70e2                	ld	ra,56(sp)
    80004390:	7442                	ld	s0,48(sp)
    80004392:	74a2                	ld	s1,40(sp)
    80004394:	7902                	ld	s2,32(sp)
    80004396:	69e2                	ld	s3,24(sp)
    80004398:	6a42                	ld	s4,16(sp)
    8000439a:	6aa2                	ld	s5,8(sp)
    8000439c:	6121                	addi	sp,sp,64
    8000439e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a0:	0001ea97          	auipc	s5,0x1e
    800043a4:	198a8a93          	addi	s5,s5,408 # 80022538 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043a8:	0001ea17          	auipc	s4,0x1e
    800043ac:	160a0a13          	addi	s4,s4,352 # 80022508 <log>
    800043b0:	018a2583          	lw	a1,24(s4)
    800043b4:	012585bb          	addw	a1,a1,s2
    800043b8:	2585                	addiw	a1,a1,1
    800043ba:	028a2503          	lw	a0,40(s4)
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	ce2080e7          	jalr	-798(ra) # 800030a0 <bread>
    800043c6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043c8:	000aa583          	lw	a1,0(s5)
    800043cc:	028a2503          	lw	a0,40(s4)
    800043d0:	fffff097          	auipc	ra,0xfffff
    800043d4:	cd0080e7          	jalr	-816(ra) # 800030a0 <bread>
    800043d8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043da:	40000613          	li	a2,1024
    800043de:	05850593          	addi	a1,a0,88
    800043e2:	05848513          	addi	a0,s1,88
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	96e080e7          	jalr	-1682(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    800043ee:	8526                	mv	a0,s1
    800043f0:	fffff097          	auipc	ra,0xfffff
    800043f4:	da2080e7          	jalr	-606(ra) # 80003192 <bwrite>
    brelse(from);
    800043f8:	854e                	mv	a0,s3
    800043fa:	fffff097          	auipc	ra,0xfffff
    800043fe:	dd6080e7          	jalr	-554(ra) # 800031d0 <brelse>
    brelse(to);
    80004402:	8526                	mv	a0,s1
    80004404:	fffff097          	auipc	ra,0xfffff
    80004408:	dcc080e7          	jalr	-564(ra) # 800031d0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000440c:	2905                	addiw	s2,s2,1
    8000440e:	0a91                	addi	s5,s5,4
    80004410:	02ca2783          	lw	a5,44(s4)
    80004414:	f8f94ee3          	blt	s2,a5,800043b0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	c76080e7          	jalr	-906(ra) # 8000408e <write_head>
    install_trans(); // Now install writes to home locations
    80004420:	00000097          	auipc	ra,0x0
    80004424:	cea080e7          	jalr	-790(ra) # 8000410a <install_trans>
    log.lh.n = 0;
    80004428:	0001e797          	auipc	a5,0x1e
    8000442c:	1007a623          	sw	zero,268(a5) # 80022534 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004430:	00000097          	auipc	ra,0x0
    80004434:	c5e080e7          	jalr	-930(ra) # 8000408e <write_head>
    80004438:	bdfd                	j	80004336 <end_op+0x52>

000000008000443a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000443a:	1101                	addi	sp,sp,-32
    8000443c:	ec06                	sd	ra,24(sp)
    8000443e:	e822                	sd	s0,16(sp)
    80004440:	e426                	sd	s1,8(sp)
    80004442:	e04a                	sd	s2,0(sp)
    80004444:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004446:	0001e717          	auipc	a4,0x1e
    8000444a:	0ee72703          	lw	a4,238(a4) # 80022534 <log+0x2c>
    8000444e:	47f5                	li	a5,29
    80004450:	08e7c063          	blt	a5,a4,800044d0 <log_write+0x96>
    80004454:	84aa                	mv	s1,a0
    80004456:	0001e797          	auipc	a5,0x1e
    8000445a:	0ce7a783          	lw	a5,206(a5) # 80022524 <log+0x1c>
    8000445e:	37fd                	addiw	a5,a5,-1
    80004460:	06f75863          	bge	a4,a5,800044d0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004464:	0001e797          	auipc	a5,0x1e
    80004468:	0c47a783          	lw	a5,196(a5) # 80022528 <log+0x20>
    8000446c:	06f05a63          	blez	a5,800044e0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004470:	0001e917          	auipc	s2,0x1e
    80004474:	09890913          	addi	s2,s2,152 # 80022508 <log>
    80004478:	854a                	mv	a0,s2
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	782080e7          	jalr	1922(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004482:	02c92603          	lw	a2,44(s2)
    80004486:	06c05563          	blez	a2,800044f0 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000448a:	44cc                	lw	a1,12(s1)
    8000448c:	0001e717          	auipc	a4,0x1e
    80004490:	0ac70713          	addi	a4,a4,172 # 80022538 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004494:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004496:	4314                	lw	a3,0(a4)
    80004498:	04b68d63          	beq	a3,a1,800044f2 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000449c:	2785                	addiw	a5,a5,1
    8000449e:	0711                	addi	a4,a4,4
    800044a0:	fec79be3          	bne	a5,a2,80004496 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044a4:	0621                	addi	a2,a2,8
    800044a6:	060a                	slli	a2,a2,0x2
    800044a8:	0001e797          	auipc	a5,0x1e
    800044ac:	06078793          	addi	a5,a5,96 # 80022508 <log>
    800044b0:	963e                	add	a2,a2,a5
    800044b2:	44dc                	lw	a5,12(s1)
    800044b4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044b6:	8526                	mv	a0,s1
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	db6080e7          	jalr	-586(ra) # 8000326e <bpin>
    log.lh.n++;
    800044c0:	0001e717          	auipc	a4,0x1e
    800044c4:	04870713          	addi	a4,a4,72 # 80022508 <log>
    800044c8:	575c                	lw	a5,44(a4)
    800044ca:	2785                	addiw	a5,a5,1
    800044cc:	d75c                	sw	a5,44(a4)
    800044ce:	a83d                	j	8000450c <log_write+0xd2>
    panic("too big a transaction");
    800044d0:	00004517          	auipc	a0,0x4
    800044d4:	19850513          	addi	a0,a0,408 # 80008668 <syscalls+0x1f0>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	068080e7          	jalr	104(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800044e0:	00004517          	auipc	a0,0x4
    800044e4:	1a050513          	addi	a0,a0,416 # 80008680 <syscalls+0x208>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	058080e7          	jalr	88(ra) # 80000540 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800044f0:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800044f2:	00878713          	addi	a4,a5,8
    800044f6:	00271693          	slli	a3,a4,0x2
    800044fa:	0001e717          	auipc	a4,0x1e
    800044fe:	00e70713          	addi	a4,a4,14 # 80022508 <log>
    80004502:	9736                	add	a4,a4,a3
    80004504:	44d4                	lw	a3,12(s1)
    80004506:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004508:	faf607e3          	beq	a2,a5,800044b6 <log_write+0x7c>
  }
  release(&log.lock);
    8000450c:	0001e517          	auipc	a0,0x1e
    80004510:	ffc50513          	addi	a0,a0,-4 # 80022508 <log>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	79c080e7          	jalr	1948(ra) # 80000cb0 <release>
}
    8000451c:	60e2                	ld	ra,24(sp)
    8000451e:	6442                	ld	s0,16(sp)
    80004520:	64a2                	ld	s1,8(sp)
    80004522:	6902                	ld	s2,0(sp)
    80004524:	6105                	addi	sp,sp,32
    80004526:	8082                	ret

0000000080004528 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004528:	1101                	addi	sp,sp,-32
    8000452a:	ec06                	sd	ra,24(sp)
    8000452c:	e822                	sd	s0,16(sp)
    8000452e:	e426                	sd	s1,8(sp)
    80004530:	e04a                	sd	s2,0(sp)
    80004532:	1000                	addi	s0,sp,32
    80004534:	84aa                	mv	s1,a0
    80004536:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004538:	00004597          	auipc	a1,0x4
    8000453c:	16858593          	addi	a1,a1,360 # 800086a0 <syscalls+0x228>
    80004540:	0521                	addi	a0,a0,8
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	62a080e7          	jalr	1578(ra) # 80000b6c <initlock>
  lk->name = name;
    8000454a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000454e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004552:	0204a423          	sw	zero,40(s1)
}
    80004556:	60e2                	ld	ra,24(sp)
    80004558:	6442                	ld	s0,16(sp)
    8000455a:	64a2                	ld	s1,8(sp)
    8000455c:	6902                	ld	s2,0(sp)
    8000455e:	6105                	addi	sp,sp,32
    80004560:	8082                	ret

0000000080004562 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004562:	1101                	addi	sp,sp,-32
    80004564:	ec06                	sd	ra,24(sp)
    80004566:	e822                	sd	s0,16(sp)
    80004568:	e426                	sd	s1,8(sp)
    8000456a:	e04a                	sd	s2,0(sp)
    8000456c:	1000                	addi	s0,sp,32
    8000456e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004570:	00850913          	addi	s2,a0,8
    80004574:	854a                	mv	a0,s2
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	686080e7          	jalr	1670(ra) # 80000bfc <acquire>
  while (lk->locked) {
    8000457e:	409c                	lw	a5,0(s1)
    80004580:	cb89                	beqz	a5,80004592 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004582:	85ca                	mv	a1,s2
    80004584:	8526                	mv	a0,s1
    80004586:	ffffe097          	auipc	ra,0xffffe
    8000458a:	e8a080e7          	jalr	-374(ra) # 80002410 <sleep>
  while (lk->locked) {
    8000458e:	409c                	lw	a5,0(s1)
    80004590:	fbed                	bnez	a5,80004582 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004592:	4785                	li	a5,1
    80004594:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004596:	ffffd097          	auipc	ra,0xffffd
    8000459a:	55c080e7          	jalr	1372(ra) # 80001af2 <myproc>
    8000459e:	5d1c                	lw	a5,56(a0)
    800045a0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045a2:	854a                	mv	a0,s2
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	70c080e7          	jalr	1804(ra) # 80000cb0 <release>
}
    800045ac:	60e2                	ld	ra,24(sp)
    800045ae:	6442                	ld	s0,16(sp)
    800045b0:	64a2                	ld	s1,8(sp)
    800045b2:	6902                	ld	s2,0(sp)
    800045b4:	6105                	addi	sp,sp,32
    800045b6:	8082                	ret

00000000800045b8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045b8:	1101                	addi	sp,sp,-32
    800045ba:	ec06                	sd	ra,24(sp)
    800045bc:	e822                	sd	s0,16(sp)
    800045be:	e426                	sd	s1,8(sp)
    800045c0:	e04a                	sd	s2,0(sp)
    800045c2:	1000                	addi	s0,sp,32
    800045c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045c6:	00850913          	addi	s2,a0,8
    800045ca:	854a                	mv	a0,s2
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	630080e7          	jalr	1584(ra) # 80000bfc <acquire>
  lk->locked = 0;
    800045d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045d8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045dc:	8526                	mv	a0,s1
    800045de:	ffffe097          	auipc	ra,0xffffe
    800045e2:	fcc080e7          	jalr	-52(ra) # 800025aa <wakeup>
  release(&lk->lk);
    800045e6:	854a                	mv	a0,s2
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	6c8080e7          	jalr	1736(ra) # 80000cb0 <release>
}
    800045f0:	60e2                	ld	ra,24(sp)
    800045f2:	6442                	ld	s0,16(sp)
    800045f4:	64a2                	ld	s1,8(sp)
    800045f6:	6902                	ld	s2,0(sp)
    800045f8:	6105                	addi	sp,sp,32
    800045fa:	8082                	ret

00000000800045fc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045fc:	7179                	addi	sp,sp,-48
    800045fe:	f406                	sd	ra,40(sp)
    80004600:	f022                	sd	s0,32(sp)
    80004602:	ec26                	sd	s1,24(sp)
    80004604:	e84a                	sd	s2,16(sp)
    80004606:	e44e                	sd	s3,8(sp)
    80004608:	1800                	addi	s0,sp,48
    8000460a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000460c:	00850913          	addi	s2,a0,8
    80004610:	854a                	mv	a0,s2
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	5ea080e7          	jalr	1514(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000461a:	409c                	lw	a5,0(s1)
    8000461c:	ef99                	bnez	a5,8000463a <holdingsleep+0x3e>
    8000461e:	4481                	li	s1,0
  release(&lk->lk);
    80004620:	854a                	mv	a0,s2
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	68e080e7          	jalr	1678(ra) # 80000cb0 <release>
  return r;
}
    8000462a:	8526                	mv	a0,s1
    8000462c:	70a2                	ld	ra,40(sp)
    8000462e:	7402                	ld	s0,32(sp)
    80004630:	64e2                	ld	s1,24(sp)
    80004632:	6942                	ld	s2,16(sp)
    80004634:	69a2                	ld	s3,8(sp)
    80004636:	6145                	addi	sp,sp,48
    80004638:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000463a:	0284a983          	lw	s3,40(s1)
    8000463e:	ffffd097          	auipc	ra,0xffffd
    80004642:	4b4080e7          	jalr	1204(ra) # 80001af2 <myproc>
    80004646:	5d04                	lw	s1,56(a0)
    80004648:	413484b3          	sub	s1,s1,s3
    8000464c:	0014b493          	seqz	s1,s1
    80004650:	bfc1                	j	80004620 <holdingsleep+0x24>

0000000080004652 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004652:	1141                	addi	sp,sp,-16
    80004654:	e406                	sd	ra,8(sp)
    80004656:	e022                	sd	s0,0(sp)
    80004658:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000465a:	00004597          	auipc	a1,0x4
    8000465e:	05658593          	addi	a1,a1,86 # 800086b0 <syscalls+0x238>
    80004662:	0001e517          	auipc	a0,0x1e
    80004666:	fee50513          	addi	a0,a0,-18 # 80022650 <ftable>
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	502080e7          	jalr	1282(ra) # 80000b6c <initlock>
}
    80004672:	60a2                	ld	ra,8(sp)
    80004674:	6402                	ld	s0,0(sp)
    80004676:	0141                	addi	sp,sp,16
    80004678:	8082                	ret

000000008000467a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000467a:	1101                	addi	sp,sp,-32
    8000467c:	ec06                	sd	ra,24(sp)
    8000467e:	e822                	sd	s0,16(sp)
    80004680:	e426                	sd	s1,8(sp)
    80004682:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004684:	0001e517          	auipc	a0,0x1e
    80004688:	fcc50513          	addi	a0,a0,-52 # 80022650 <ftable>
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	570080e7          	jalr	1392(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004694:	0001e497          	auipc	s1,0x1e
    80004698:	fd448493          	addi	s1,s1,-44 # 80022668 <ftable+0x18>
    8000469c:	0001f717          	auipc	a4,0x1f
    800046a0:	f6c70713          	addi	a4,a4,-148 # 80023608 <ftable+0xfb8>
    if(f->ref == 0){
    800046a4:	40dc                	lw	a5,4(s1)
    800046a6:	cf99                	beqz	a5,800046c4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046a8:	02848493          	addi	s1,s1,40
    800046ac:	fee49ce3          	bne	s1,a4,800046a4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046b0:	0001e517          	auipc	a0,0x1e
    800046b4:	fa050513          	addi	a0,a0,-96 # 80022650 <ftable>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	5f8080e7          	jalr	1528(ra) # 80000cb0 <release>
  return 0;
    800046c0:	4481                	li	s1,0
    800046c2:	a819                	j	800046d8 <filealloc+0x5e>
      f->ref = 1;
    800046c4:	4785                	li	a5,1
    800046c6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046c8:	0001e517          	auipc	a0,0x1e
    800046cc:	f8850513          	addi	a0,a0,-120 # 80022650 <ftable>
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	5e0080e7          	jalr	1504(ra) # 80000cb0 <release>
}
    800046d8:	8526                	mv	a0,s1
    800046da:	60e2                	ld	ra,24(sp)
    800046dc:	6442                	ld	s0,16(sp)
    800046de:	64a2                	ld	s1,8(sp)
    800046e0:	6105                	addi	sp,sp,32
    800046e2:	8082                	ret

00000000800046e4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046e4:	1101                	addi	sp,sp,-32
    800046e6:	ec06                	sd	ra,24(sp)
    800046e8:	e822                	sd	s0,16(sp)
    800046ea:	e426                	sd	s1,8(sp)
    800046ec:	1000                	addi	s0,sp,32
    800046ee:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046f0:	0001e517          	auipc	a0,0x1e
    800046f4:	f6050513          	addi	a0,a0,-160 # 80022650 <ftable>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	504080e7          	jalr	1284(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    80004700:	40dc                	lw	a5,4(s1)
    80004702:	02f05263          	blez	a5,80004726 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004706:	2785                	addiw	a5,a5,1
    80004708:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000470a:	0001e517          	auipc	a0,0x1e
    8000470e:	f4650513          	addi	a0,a0,-186 # 80022650 <ftable>
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	59e080e7          	jalr	1438(ra) # 80000cb0 <release>
  return f;
}
    8000471a:	8526                	mv	a0,s1
    8000471c:	60e2                	ld	ra,24(sp)
    8000471e:	6442                	ld	s0,16(sp)
    80004720:	64a2                	ld	s1,8(sp)
    80004722:	6105                	addi	sp,sp,32
    80004724:	8082                	ret
    panic("filedup");
    80004726:	00004517          	auipc	a0,0x4
    8000472a:	f9250513          	addi	a0,a0,-110 # 800086b8 <syscalls+0x240>
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	e12080e7          	jalr	-494(ra) # 80000540 <panic>

0000000080004736 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004736:	7139                	addi	sp,sp,-64
    80004738:	fc06                	sd	ra,56(sp)
    8000473a:	f822                	sd	s0,48(sp)
    8000473c:	f426                	sd	s1,40(sp)
    8000473e:	f04a                	sd	s2,32(sp)
    80004740:	ec4e                	sd	s3,24(sp)
    80004742:	e852                	sd	s4,16(sp)
    80004744:	e456                	sd	s5,8(sp)
    80004746:	0080                	addi	s0,sp,64
    80004748:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000474a:	0001e517          	auipc	a0,0x1e
    8000474e:	f0650513          	addi	a0,a0,-250 # 80022650 <ftable>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	4aa080e7          	jalr	1194(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    8000475a:	40dc                	lw	a5,4(s1)
    8000475c:	06f05163          	blez	a5,800047be <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004760:	37fd                	addiw	a5,a5,-1
    80004762:	0007871b          	sext.w	a4,a5
    80004766:	c0dc                	sw	a5,4(s1)
    80004768:	06e04363          	bgtz	a4,800047ce <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000476c:	0004a903          	lw	s2,0(s1)
    80004770:	0094ca83          	lbu	s5,9(s1)
    80004774:	0104ba03          	ld	s4,16(s1)
    80004778:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000477c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004780:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004784:	0001e517          	auipc	a0,0x1e
    80004788:	ecc50513          	addi	a0,a0,-308 # 80022650 <ftable>
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	524080e7          	jalr	1316(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    80004794:	4785                	li	a5,1
    80004796:	04f90d63          	beq	s2,a5,800047f0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000479a:	3979                	addiw	s2,s2,-2
    8000479c:	4785                	li	a5,1
    8000479e:	0527e063          	bltu	a5,s2,800047de <fileclose+0xa8>
    begin_op();
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	ac2080e7          	jalr	-1342(ra) # 80004264 <begin_op>
    iput(ff.ip);
    800047aa:	854e                	mv	a0,s3
    800047ac:	fffff097          	auipc	ra,0xfffff
    800047b0:	2b2080e7          	jalr	690(ra) # 80003a5e <iput>
    end_op();
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	b30080e7          	jalr	-1232(ra) # 800042e4 <end_op>
    800047bc:	a00d                	j	800047de <fileclose+0xa8>
    panic("fileclose");
    800047be:	00004517          	auipc	a0,0x4
    800047c2:	f0250513          	addi	a0,a0,-254 # 800086c0 <syscalls+0x248>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	d7a080e7          	jalr	-646(ra) # 80000540 <panic>
    release(&ftable.lock);
    800047ce:	0001e517          	auipc	a0,0x1e
    800047d2:	e8250513          	addi	a0,a0,-382 # 80022650 <ftable>
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	4da080e7          	jalr	1242(ra) # 80000cb0 <release>
  }
}
    800047de:	70e2                	ld	ra,56(sp)
    800047e0:	7442                	ld	s0,48(sp)
    800047e2:	74a2                	ld	s1,40(sp)
    800047e4:	7902                	ld	s2,32(sp)
    800047e6:	69e2                	ld	s3,24(sp)
    800047e8:	6a42                	ld	s4,16(sp)
    800047ea:	6aa2                	ld	s5,8(sp)
    800047ec:	6121                	addi	sp,sp,64
    800047ee:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047f0:	85d6                	mv	a1,s5
    800047f2:	8552                	mv	a0,s4
    800047f4:	00000097          	auipc	ra,0x0
    800047f8:	372080e7          	jalr	882(ra) # 80004b66 <pipeclose>
    800047fc:	b7cd                	j	800047de <fileclose+0xa8>

00000000800047fe <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047fe:	715d                	addi	sp,sp,-80
    80004800:	e486                	sd	ra,72(sp)
    80004802:	e0a2                	sd	s0,64(sp)
    80004804:	fc26                	sd	s1,56(sp)
    80004806:	f84a                	sd	s2,48(sp)
    80004808:	f44e                	sd	s3,40(sp)
    8000480a:	0880                	addi	s0,sp,80
    8000480c:	84aa                	mv	s1,a0
    8000480e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004810:	ffffd097          	auipc	ra,0xffffd
    80004814:	2e2080e7          	jalr	738(ra) # 80001af2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004818:	409c                	lw	a5,0(s1)
    8000481a:	37f9                	addiw	a5,a5,-2
    8000481c:	4705                	li	a4,1
    8000481e:	04f76763          	bltu	a4,a5,8000486c <filestat+0x6e>
    80004822:	892a                	mv	s2,a0
    ilock(f->ip);
    80004824:	6c88                	ld	a0,24(s1)
    80004826:	fffff097          	auipc	ra,0xfffff
    8000482a:	07e080e7          	jalr	126(ra) # 800038a4 <ilock>
    stati(f->ip, &st);
    8000482e:	fb840593          	addi	a1,s0,-72
    80004832:	6c88                	ld	a0,24(s1)
    80004834:	fffff097          	auipc	ra,0xfffff
    80004838:	2fa080e7          	jalr	762(ra) # 80003b2e <stati>
    iunlock(f->ip);
    8000483c:	6c88                	ld	a0,24(s1)
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	128080e7          	jalr	296(ra) # 80003966 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004846:	46e1                	li	a3,24
    80004848:	fb840613          	addi	a2,s0,-72
    8000484c:	85ce                	mv	a1,s3
    8000484e:	05093503          	ld	a0,80(s2)
    80004852:	ffffd097          	auipc	ra,0xffffd
    80004856:	e58080e7          	jalr	-424(ra) # 800016aa <copyout>
    8000485a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000485e:	60a6                	ld	ra,72(sp)
    80004860:	6406                	ld	s0,64(sp)
    80004862:	74e2                	ld	s1,56(sp)
    80004864:	7942                	ld	s2,48(sp)
    80004866:	79a2                	ld	s3,40(sp)
    80004868:	6161                	addi	sp,sp,80
    8000486a:	8082                	ret
  return -1;
    8000486c:	557d                	li	a0,-1
    8000486e:	bfc5                	j	8000485e <filestat+0x60>

0000000080004870 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004870:	7179                	addi	sp,sp,-48
    80004872:	f406                	sd	ra,40(sp)
    80004874:	f022                	sd	s0,32(sp)
    80004876:	ec26                	sd	s1,24(sp)
    80004878:	e84a                	sd	s2,16(sp)
    8000487a:	e44e                	sd	s3,8(sp)
    8000487c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000487e:	00854783          	lbu	a5,8(a0)
    80004882:	c3d5                	beqz	a5,80004926 <fileread+0xb6>
    80004884:	84aa                	mv	s1,a0
    80004886:	89ae                	mv	s3,a1
    80004888:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000488a:	411c                	lw	a5,0(a0)
    8000488c:	4705                	li	a4,1
    8000488e:	04e78963          	beq	a5,a4,800048e0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004892:	470d                	li	a4,3
    80004894:	04e78d63          	beq	a5,a4,800048ee <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004898:	4709                	li	a4,2
    8000489a:	06e79e63          	bne	a5,a4,80004916 <fileread+0xa6>
    ilock(f->ip);
    8000489e:	6d08                	ld	a0,24(a0)
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	004080e7          	jalr	4(ra) # 800038a4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048a8:	874a                	mv	a4,s2
    800048aa:	5094                	lw	a3,32(s1)
    800048ac:	864e                	mv	a2,s3
    800048ae:	4585                	li	a1,1
    800048b0:	6c88                	ld	a0,24(s1)
    800048b2:	fffff097          	auipc	ra,0xfffff
    800048b6:	2a6080e7          	jalr	678(ra) # 80003b58 <readi>
    800048ba:	892a                	mv	s2,a0
    800048bc:	00a05563          	blez	a0,800048c6 <fileread+0x56>
      f->off += r;
    800048c0:	509c                	lw	a5,32(s1)
    800048c2:	9fa9                	addw	a5,a5,a0
    800048c4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048c6:	6c88                	ld	a0,24(s1)
    800048c8:	fffff097          	auipc	ra,0xfffff
    800048cc:	09e080e7          	jalr	158(ra) # 80003966 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048d0:	854a                	mv	a0,s2
    800048d2:	70a2                	ld	ra,40(sp)
    800048d4:	7402                	ld	s0,32(sp)
    800048d6:	64e2                	ld	s1,24(sp)
    800048d8:	6942                	ld	s2,16(sp)
    800048da:	69a2                	ld	s3,8(sp)
    800048dc:	6145                	addi	sp,sp,48
    800048de:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048e0:	6908                	ld	a0,16(a0)
    800048e2:	00000097          	auipc	ra,0x0
    800048e6:	3f4080e7          	jalr	1012(ra) # 80004cd6 <piperead>
    800048ea:	892a                	mv	s2,a0
    800048ec:	b7d5                	j	800048d0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048ee:	02451783          	lh	a5,36(a0)
    800048f2:	03079693          	slli	a3,a5,0x30
    800048f6:	92c1                	srli	a3,a3,0x30
    800048f8:	4725                	li	a4,9
    800048fa:	02d76863          	bltu	a4,a3,8000492a <fileread+0xba>
    800048fe:	0792                	slli	a5,a5,0x4
    80004900:	0001e717          	auipc	a4,0x1e
    80004904:	cb070713          	addi	a4,a4,-848 # 800225b0 <devsw>
    80004908:	97ba                	add	a5,a5,a4
    8000490a:	639c                	ld	a5,0(a5)
    8000490c:	c38d                	beqz	a5,8000492e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000490e:	4505                	li	a0,1
    80004910:	9782                	jalr	a5
    80004912:	892a                	mv	s2,a0
    80004914:	bf75                	j	800048d0 <fileread+0x60>
    panic("fileread");
    80004916:	00004517          	auipc	a0,0x4
    8000491a:	dba50513          	addi	a0,a0,-582 # 800086d0 <syscalls+0x258>
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	c22080e7          	jalr	-990(ra) # 80000540 <panic>
    return -1;
    80004926:	597d                	li	s2,-1
    80004928:	b765                	j	800048d0 <fileread+0x60>
      return -1;
    8000492a:	597d                	li	s2,-1
    8000492c:	b755                	j	800048d0 <fileread+0x60>
    8000492e:	597d                	li	s2,-1
    80004930:	b745                	j	800048d0 <fileread+0x60>

0000000080004932 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004932:	00954783          	lbu	a5,9(a0)
    80004936:	14078563          	beqz	a5,80004a80 <filewrite+0x14e>
{
    8000493a:	715d                	addi	sp,sp,-80
    8000493c:	e486                	sd	ra,72(sp)
    8000493e:	e0a2                	sd	s0,64(sp)
    80004940:	fc26                	sd	s1,56(sp)
    80004942:	f84a                	sd	s2,48(sp)
    80004944:	f44e                	sd	s3,40(sp)
    80004946:	f052                	sd	s4,32(sp)
    80004948:	ec56                	sd	s5,24(sp)
    8000494a:	e85a                	sd	s6,16(sp)
    8000494c:	e45e                	sd	s7,8(sp)
    8000494e:	e062                	sd	s8,0(sp)
    80004950:	0880                	addi	s0,sp,80
    80004952:	892a                	mv	s2,a0
    80004954:	8aae                	mv	s5,a1
    80004956:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004958:	411c                	lw	a5,0(a0)
    8000495a:	4705                	li	a4,1
    8000495c:	02e78263          	beq	a5,a4,80004980 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004960:	470d                	li	a4,3
    80004962:	02e78563          	beq	a5,a4,8000498c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004966:	4709                	li	a4,2
    80004968:	10e79463          	bne	a5,a4,80004a70 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000496c:	0ec05e63          	blez	a2,80004a68 <filewrite+0x136>
    int i = 0;
    80004970:	4981                	li	s3,0
    80004972:	6b05                	lui	s6,0x1
    80004974:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004978:	6b85                	lui	s7,0x1
    8000497a:	c00b8b9b          	addiw	s7,s7,-1024
    8000497e:	a851                	j	80004a12 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004980:	6908                	ld	a0,16(a0)
    80004982:	00000097          	auipc	ra,0x0
    80004986:	254080e7          	jalr	596(ra) # 80004bd6 <pipewrite>
    8000498a:	a85d                	j	80004a40 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000498c:	02451783          	lh	a5,36(a0)
    80004990:	03079693          	slli	a3,a5,0x30
    80004994:	92c1                	srli	a3,a3,0x30
    80004996:	4725                	li	a4,9
    80004998:	0ed76663          	bltu	a4,a3,80004a84 <filewrite+0x152>
    8000499c:	0792                	slli	a5,a5,0x4
    8000499e:	0001e717          	auipc	a4,0x1e
    800049a2:	c1270713          	addi	a4,a4,-1006 # 800225b0 <devsw>
    800049a6:	97ba                	add	a5,a5,a4
    800049a8:	679c                	ld	a5,8(a5)
    800049aa:	cff9                	beqz	a5,80004a88 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800049ac:	4505                	li	a0,1
    800049ae:	9782                	jalr	a5
    800049b0:	a841                	j	80004a40 <filewrite+0x10e>
    800049b2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	8ae080e7          	jalr	-1874(ra) # 80004264 <begin_op>
      ilock(f->ip);
    800049be:	01893503          	ld	a0,24(s2)
    800049c2:	fffff097          	auipc	ra,0xfffff
    800049c6:	ee2080e7          	jalr	-286(ra) # 800038a4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049ca:	8762                	mv	a4,s8
    800049cc:	02092683          	lw	a3,32(s2)
    800049d0:	01598633          	add	a2,s3,s5
    800049d4:	4585                	li	a1,1
    800049d6:	01893503          	ld	a0,24(s2)
    800049da:	fffff097          	auipc	ra,0xfffff
    800049de:	274080e7          	jalr	628(ra) # 80003c4e <writei>
    800049e2:	84aa                	mv	s1,a0
    800049e4:	02a05f63          	blez	a0,80004a22 <filewrite+0xf0>
        f->off += r;
    800049e8:	02092783          	lw	a5,32(s2)
    800049ec:	9fa9                	addw	a5,a5,a0
    800049ee:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049f2:	01893503          	ld	a0,24(s2)
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	f70080e7          	jalr	-144(ra) # 80003966 <iunlock>
      end_op();
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	8e6080e7          	jalr	-1818(ra) # 800042e4 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a06:	049c1963          	bne	s8,s1,80004a58 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a0a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a0e:	0349d663          	bge	s3,s4,80004a3a <filewrite+0x108>
      int n1 = n - i;
    80004a12:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a16:	84be                	mv	s1,a5
    80004a18:	2781                	sext.w	a5,a5
    80004a1a:	f8fb5ce3          	bge	s6,a5,800049b2 <filewrite+0x80>
    80004a1e:	84de                	mv	s1,s7
    80004a20:	bf49                	j	800049b2 <filewrite+0x80>
      iunlock(f->ip);
    80004a22:	01893503          	ld	a0,24(s2)
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	f40080e7          	jalr	-192(ra) # 80003966 <iunlock>
      end_op();
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	8b6080e7          	jalr	-1866(ra) # 800042e4 <end_op>
      if(r < 0)
    80004a36:	fc04d8e3          	bgez	s1,80004a06 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a3a:	8552                	mv	a0,s4
    80004a3c:	033a1863          	bne	s4,s3,80004a6c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a40:	60a6                	ld	ra,72(sp)
    80004a42:	6406                	ld	s0,64(sp)
    80004a44:	74e2                	ld	s1,56(sp)
    80004a46:	7942                	ld	s2,48(sp)
    80004a48:	79a2                	ld	s3,40(sp)
    80004a4a:	7a02                	ld	s4,32(sp)
    80004a4c:	6ae2                	ld	s5,24(sp)
    80004a4e:	6b42                	ld	s6,16(sp)
    80004a50:	6ba2                	ld	s7,8(sp)
    80004a52:	6c02                	ld	s8,0(sp)
    80004a54:	6161                	addi	sp,sp,80
    80004a56:	8082                	ret
        panic("short filewrite");
    80004a58:	00004517          	auipc	a0,0x4
    80004a5c:	c8850513          	addi	a0,a0,-888 # 800086e0 <syscalls+0x268>
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	ae0080e7          	jalr	-1312(ra) # 80000540 <panic>
    int i = 0;
    80004a68:	4981                	li	s3,0
    80004a6a:	bfc1                	j	80004a3a <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a6c:	557d                	li	a0,-1
    80004a6e:	bfc9                	j	80004a40 <filewrite+0x10e>
    panic("filewrite");
    80004a70:	00004517          	auipc	a0,0x4
    80004a74:	c8050513          	addi	a0,a0,-896 # 800086f0 <syscalls+0x278>
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	ac8080e7          	jalr	-1336(ra) # 80000540 <panic>
    return -1;
    80004a80:	557d                	li	a0,-1
}
    80004a82:	8082                	ret
      return -1;
    80004a84:	557d                	li	a0,-1
    80004a86:	bf6d                	j	80004a40 <filewrite+0x10e>
    80004a88:	557d                	li	a0,-1
    80004a8a:	bf5d                	j	80004a40 <filewrite+0x10e>

0000000080004a8c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a8c:	7179                	addi	sp,sp,-48
    80004a8e:	f406                	sd	ra,40(sp)
    80004a90:	f022                	sd	s0,32(sp)
    80004a92:	ec26                	sd	s1,24(sp)
    80004a94:	e84a                	sd	s2,16(sp)
    80004a96:	e44e                	sd	s3,8(sp)
    80004a98:	e052                	sd	s4,0(sp)
    80004a9a:	1800                	addi	s0,sp,48
    80004a9c:	84aa                	mv	s1,a0
    80004a9e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004aa0:	0005b023          	sd	zero,0(a1)
    80004aa4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aa8:	00000097          	auipc	ra,0x0
    80004aac:	bd2080e7          	jalr	-1070(ra) # 8000467a <filealloc>
    80004ab0:	e088                	sd	a0,0(s1)
    80004ab2:	c551                	beqz	a0,80004b3e <pipealloc+0xb2>
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	bc6080e7          	jalr	-1082(ra) # 8000467a <filealloc>
    80004abc:	00aa3023          	sd	a0,0(s4)
    80004ac0:	c92d                	beqz	a0,80004b32 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	04a080e7          	jalr	74(ra) # 80000b0c <kalloc>
    80004aca:	892a                	mv	s2,a0
    80004acc:	c125                	beqz	a0,80004b2c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ace:	4985                	li	s3,1
    80004ad0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ad4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ad8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004adc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ae0:	00004597          	auipc	a1,0x4
    80004ae4:	c2058593          	addi	a1,a1,-992 # 80008700 <syscalls+0x288>
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	084080e7          	jalr	132(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004af0:	609c                	ld	a5,0(s1)
    80004af2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004af6:	609c                	ld	a5,0(s1)
    80004af8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004afc:	609c                	ld	a5,0(s1)
    80004afe:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b02:	609c                	ld	a5,0(s1)
    80004b04:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b08:	000a3783          	ld	a5,0(s4)
    80004b0c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b10:	000a3783          	ld	a5,0(s4)
    80004b14:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b18:	000a3783          	ld	a5,0(s4)
    80004b1c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b20:	000a3783          	ld	a5,0(s4)
    80004b24:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b28:	4501                	li	a0,0
    80004b2a:	a025                	j	80004b52 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b2c:	6088                	ld	a0,0(s1)
    80004b2e:	e501                	bnez	a0,80004b36 <pipealloc+0xaa>
    80004b30:	a039                	j	80004b3e <pipealloc+0xb2>
    80004b32:	6088                	ld	a0,0(s1)
    80004b34:	c51d                	beqz	a0,80004b62 <pipealloc+0xd6>
    fileclose(*f0);
    80004b36:	00000097          	auipc	ra,0x0
    80004b3a:	c00080e7          	jalr	-1024(ra) # 80004736 <fileclose>
  if(*f1)
    80004b3e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b42:	557d                	li	a0,-1
  if(*f1)
    80004b44:	c799                	beqz	a5,80004b52 <pipealloc+0xc6>
    fileclose(*f1);
    80004b46:	853e                	mv	a0,a5
    80004b48:	00000097          	auipc	ra,0x0
    80004b4c:	bee080e7          	jalr	-1042(ra) # 80004736 <fileclose>
  return -1;
    80004b50:	557d                	li	a0,-1
}
    80004b52:	70a2                	ld	ra,40(sp)
    80004b54:	7402                	ld	s0,32(sp)
    80004b56:	64e2                	ld	s1,24(sp)
    80004b58:	6942                	ld	s2,16(sp)
    80004b5a:	69a2                	ld	s3,8(sp)
    80004b5c:	6a02                	ld	s4,0(sp)
    80004b5e:	6145                	addi	sp,sp,48
    80004b60:	8082                	ret
  return -1;
    80004b62:	557d                	li	a0,-1
    80004b64:	b7fd                	j	80004b52 <pipealloc+0xc6>

0000000080004b66 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b66:	1101                	addi	sp,sp,-32
    80004b68:	ec06                	sd	ra,24(sp)
    80004b6a:	e822                	sd	s0,16(sp)
    80004b6c:	e426                	sd	s1,8(sp)
    80004b6e:	e04a                	sd	s2,0(sp)
    80004b70:	1000                	addi	s0,sp,32
    80004b72:	84aa                	mv	s1,a0
    80004b74:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	086080e7          	jalr	134(ra) # 80000bfc <acquire>
  if(writable){
    80004b7e:	02090d63          	beqz	s2,80004bb8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b82:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b86:	21848513          	addi	a0,s1,536
    80004b8a:	ffffe097          	auipc	ra,0xffffe
    80004b8e:	a20080e7          	jalr	-1504(ra) # 800025aa <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b92:	2204b783          	ld	a5,544(s1)
    80004b96:	eb95                	bnez	a5,80004bca <pipeclose+0x64>
    release(&pi->lock);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	116080e7          	jalr	278(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	e6c080e7          	jalr	-404(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004bac:	60e2                	ld	ra,24(sp)
    80004bae:	6442                	ld	s0,16(sp)
    80004bb0:	64a2                	ld	s1,8(sp)
    80004bb2:	6902                	ld	s2,0(sp)
    80004bb4:	6105                	addi	sp,sp,32
    80004bb6:	8082                	ret
    pi->readopen = 0;
    80004bb8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bbc:	21c48513          	addi	a0,s1,540
    80004bc0:	ffffe097          	auipc	ra,0xffffe
    80004bc4:	9ea080e7          	jalr	-1558(ra) # 800025aa <wakeup>
    80004bc8:	b7e9                	j	80004b92 <pipeclose+0x2c>
    release(&pi->lock);
    80004bca:	8526                	mv	a0,s1
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	0e4080e7          	jalr	228(ra) # 80000cb0 <release>
}
    80004bd4:	bfe1                	j	80004bac <pipeclose+0x46>

0000000080004bd6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bd6:	711d                	addi	sp,sp,-96
    80004bd8:	ec86                	sd	ra,88(sp)
    80004bda:	e8a2                	sd	s0,80(sp)
    80004bdc:	e4a6                	sd	s1,72(sp)
    80004bde:	e0ca                	sd	s2,64(sp)
    80004be0:	fc4e                	sd	s3,56(sp)
    80004be2:	f852                	sd	s4,48(sp)
    80004be4:	f456                	sd	s5,40(sp)
    80004be6:	f05a                	sd	s6,32(sp)
    80004be8:	ec5e                	sd	s7,24(sp)
    80004bea:	e862                	sd	s8,16(sp)
    80004bec:	1080                	addi	s0,sp,96
    80004bee:	84aa                	mv	s1,a0
    80004bf0:	8b2e                	mv	s6,a1
    80004bf2:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	efe080e7          	jalr	-258(ra) # 80001af2 <myproc>
    80004bfc:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004bfe:	8526                	mv	a0,s1
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	ffc080e7          	jalr	-4(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004c08:	09505763          	blez	s5,80004c96 <pipewrite+0xc0>
    80004c0c:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c0e:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c12:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c16:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c18:	2184a783          	lw	a5,536(s1)
    80004c1c:	21c4a703          	lw	a4,540(s1)
    80004c20:	2007879b          	addiw	a5,a5,512
    80004c24:	02f71b63          	bne	a4,a5,80004c5a <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004c28:	2204a783          	lw	a5,544(s1)
    80004c2c:	c3d1                	beqz	a5,80004cb0 <pipewrite+0xda>
    80004c2e:	03092783          	lw	a5,48(s2)
    80004c32:	efbd                	bnez	a5,80004cb0 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004c34:	8552                	mv	a0,s4
    80004c36:	ffffe097          	auipc	ra,0xffffe
    80004c3a:	974080e7          	jalr	-1676(ra) # 800025aa <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c3e:	85a6                	mv	a1,s1
    80004c40:	854e                	mv	a0,s3
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	7ce080e7          	jalr	1998(ra) # 80002410 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c4a:	2184a783          	lw	a5,536(s1)
    80004c4e:	21c4a703          	lw	a4,540(s1)
    80004c52:	2007879b          	addiw	a5,a5,512
    80004c56:	fcf709e3          	beq	a4,a5,80004c28 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c5a:	4685                	li	a3,1
    80004c5c:	865a                	mv	a2,s6
    80004c5e:	faf40593          	addi	a1,s0,-81
    80004c62:	05093503          	ld	a0,80(s2)
    80004c66:	ffffd097          	auipc	ra,0xffffd
    80004c6a:	ad0080e7          	jalr	-1328(ra) # 80001736 <copyin>
    80004c6e:	03850563          	beq	a0,s8,80004c98 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c72:	21c4a783          	lw	a5,540(s1)
    80004c76:	0017871b          	addiw	a4,a5,1
    80004c7a:	20e4ae23          	sw	a4,540(s1)
    80004c7e:	1ff7f793          	andi	a5,a5,511
    80004c82:	97a6                	add	a5,a5,s1
    80004c84:	faf44703          	lbu	a4,-81(s0)
    80004c88:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c8c:	2b85                	addiw	s7,s7,1
    80004c8e:	0b05                	addi	s6,s6,1
    80004c90:	f97a94e3          	bne	s5,s7,80004c18 <pipewrite+0x42>
    80004c94:	a011                	j	80004c98 <pipewrite+0xc2>
    80004c96:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004c98:	21848513          	addi	a0,s1,536
    80004c9c:	ffffe097          	auipc	ra,0xffffe
    80004ca0:	90e080e7          	jalr	-1778(ra) # 800025aa <wakeup>
  release(&pi->lock);
    80004ca4:	8526                	mv	a0,s1
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	00a080e7          	jalr	10(ra) # 80000cb0 <release>
  return i;
    80004cae:	a039                	j	80004cbc <pipewrite+0xe6>
        release(&pi->lock);
    80004cb0:	8526                	mv	a0,s1
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	ffe080e7          	jalr	-2(ra) # 80000cb0 <release>
        return -1;
    80004cba:	5bfd                	li	s7,-1
}
    80004cbc:	855e                	mv	a0,s7
    80004cbe:	60e6                	ld	ra,88(sp)
    80004cc0:	6446                	ld	s0,80(sp)
    80004cc2:	64a6                	ld	s1,72(sp)
    80004cc4:	6906                	ld	s2,64(sp)
    80004cc6:	79e2                	ld	s3,56(sp)
    80004cc8:	7a42                	ld	s4,48(sp)
    80004cca:	7aa2                	ld	s5,40(sp)
    80004ccc:	7b02                	ld	s6,32(sp)
    80004cce:	6be2                	ld	s7,24(sp)
    80004cd0:	6c42                	ld	s8,16(sp)
    80004cd2:	6125                	addi	sp,sp,96
    80004cd4:	8082                	ret

0000000080004cd6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cd6:	715d                	addi	sp,sp,-80
    80004cd8:	e486                	sd	ra,72(sp)
    80004cda:	e0a2                	sd	s0,64(sp)
    80004cdc:	fc26                	sd	s1,56(sp)
    80004cde:	f84a                	sd	s2,48(sp)
    80004ce0:	f44e                	sd	s3,40(sp)
    80004ce2:	f052                	sd	s4,32(sp)
    80004ce4:	ec56                	sd	s5,24(sp)
    80004ce6:	e85a                	sd	s6,16(sp)
    80004ce8:	0880                	addi	s0,sp,80
    80004cea:	84aa                	mv	s1,a0
    80004cec:	892e                	mv	s2,a1
    80004cee:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	e02080e7          	jalr	-510(ra) # 80001af2 <myproc>
    80004cf8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	f00080e7          	jalr	-256(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d04:	2184a703          	lw	a4,536(s1)
    80004d08:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d0c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d10:	02f71463          	bne	a4,a5,80004d38 <piperead+0x62>
    80004d14:	2244a783          	lw	a5,548(s1)
    80004d18:	c385                	beqz	a5,80004d38 <piperead+0x62>
    if(pr->killed){
    80004d1a:	030a2783          	lw	a5,48(s4)
    80004d1e:	ebc1                	bnez	a5,80004dae <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d20:	85a6                	mv	a1,s1
    80004d22:	854e                	mv	a0,s3
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	6ec080e7          	jalr	1772(ra) # 80002410 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d2c:	2184a703          	lw	a4,536(s1)
    80004d30:	21c4a783          	lw	a5,540(s1)
    80004d34:	fef700e3          	beq	a4,a5,80004d14 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d38:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d3a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d3c:	05505363          	blez	s5,80004d82 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004d40:	2184a783          	lw	a5,536(s1)
    80004d44:	21c4a703          	lw	a4,540(s1)
    80004d48:	02f70d63          	beq	a4,a5,80004d82 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d4c:	0017871b          	addiw	a4,a5,1
    80004d50:	20e4ac23          	sw	a4,536(s1)
    80004d54:	1ff7f793          	andi	a5,a5,511
    80004d58:	97a6                	add	a5,a5,s1
    80004d5a:	0187c783          	lbu	a5,24(a5)
    80004d5e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d62:	4685                	li	a3,1
    80004d64:	fbf40613          	addi	a2,s0,-65
    80004d68:	85ca                	mv	a1,s2
    80004d6a:	050a3503          	ld	a0,80(s4)
    80004d6e:	ffffd097          	auipc	ra,0xffffd
    80004d72:	93c080e7          	jalr	-1732(ra) # 800016aa <copyout>
    80004d76:	01650663          	beq	a0,s6,80004d82 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7a:	2985                	addiw	s3,s3,1
    80004d7c:	0905                	addi	s2,s2,1
    80004d7e:	fd3a91e3          	bne	s5,s3,80004d40 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d82:	21c48513          	addi	a0,s1,540
    80004d86:	ffffe097          	auipc	ra,0xffffe
    80004d8a:	824080e7          	jalr	-2012(ra) # 800025aa <wakeup>
  release(&pi->lock);
    80004d8e:	8526                	mv	a0,s1
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	f20080e7          	jalr	-224(ra) # 80000cb0 <release>
  return i;
}
    80004d98:	854e                	mv	a0,s3
    80004d9a:	60a6                	ld	ra,72(sp)
    80004d9c:	6406                	ld	s0,64(sp)
    80004d9e:	74e2                	ld	s1,56(sp)
    80004da0:	7942                	ld	s2,48(sp)
    80004da2:	79a2                	ld	s3,40(sp)
    80004da4:	7a02                	ld	s4,32(sp)
    80004da6:	6ae2                	ld	s5,24(sp)
    80004da8:	6b42                	ld	s6,16(sp)
    80004daa:	6161                	addi	sp,sp,80
    80004dac:	8082                	ret
      release(&pi->lock);
    80004dae:	8526                	mv	a0,s1
    80004db0:	ffffc097          	auipc	ra,0xffffc
    80004db4:	f00080e7          	jalr	-256(ra) # 80000cb0 <release>
      return -1;
    80004db8:	59fd                	li	s3,-1
    80004dba:	bff9                	j	80004d98 <piperead+0xc2>

0000000080004dbc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004dbc:	de010113          	addi	sp,sp,-544
    80004dc0:	20113c23          	sd	ra,536(sp)
    80004dc4:	20813823          	sd	s0,528(sp)
    80004dc8:	20913423          	sd	s1,520(sp)
    80004dcc:	21213023          	sd	s2,512(sp)
    80004dd0:	ffce                	sd	s3,504(sp)
    80004dd2:	fbd2                	sd	s4,496(sp)
    80004dd4:	f7d6                	sd	s5,488(sp)
    80004dd6:	f3da                	sd	s6,480(sp)
    80004dd8:	efde                	sd	s7,472(sp)
    80004dda:	ebe2                	sd	s8,464(sp)
    80004ddc:	e7e6                	sd	s9,456(sp)
    80004dde:	e3ea                	sd	s10,448(sp)
    80004de0:	ff6e                	sd	s11,440(sp)
    80004de2:	1400                	addi	s0,sp,544
    80004de4:	892a                	mv	s2,a0
    80004de6:	dea43423          	sd	a0,-536(s0)
    80004dea:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dee:	ffffd097          	auipc	ra,0xffffd
    80004df2:	d04080e7          	jalr	-764(ra) # 80001af2 <myproc>
    80004df6:	84aa                	mv	s1,a0

  begin_op();
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	46c080e7          	jalr	1132(ra) # 80004264 <begin_op>

  if((ip = namei(path)) == 0){
    80004e00:	854a                	mv	a0,s2
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	252080e7          	jalr	594(ra) # 80004054 <namei>
    80004e0a:	c93d                	beqz	a0,80004e80 <exec+0xc4>
    80004e0c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	a96080e7          	jalr	-1386(ra) # 800038a4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e16:	04000713          	li	a4,64
    80004e1a:	4681                	li	a3,0
    80004e1c:	e4840613          	addi	a2,s0,-440
    80004e20:	4581                	li	a1,0
    80004e22:	8556                	mv	a0,s5
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	d34080e7          	jalr	-716(ra) # 80003b58 <readi>
    80004e2c:	04000793          	li	a5,64
    80004e30:	00f51a63          	bne	a0,a5,80004e44 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e34:	e4842703          	lw	a4,-440(s0)
    80004e38:	464c47b7          	lui	a5,0x464c4
    80004e3c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e40:	04f70663          	beq	a4,a5,80004e8c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e44:	8556                	mv	a0,s5
    80004e46:	fffff097          	auipc	ra,0xfffff
    80004e4a:	cc0080e7          	jalr	-832(ra) # 80003b06 <iunlockput>
    end_op();
    80004e4e:	fffff097          	auipc	ra,0xfffff
    80004e52:	496080e7          	jalr	1174(ra) # 800042e4 <end_op>
  }
  return -1;
    80004e56:	557d                	li	a0,-1
}
    80004e58:	21813083          	ld	ra,536(sp)
    80004e5c:	21013403          	ld	s0,528(sp)
    80004e60:	20813483          	ld	s1,520(sp)
    80004e64:	20013903          	ld	s2,512(sp)
    80004e68:	79fe                	ld	s3,504(sp)
    80004e6a:	7a5e                	ld	s4,496(sp)
    80004e6c:	7abe                	ld	s5,488(sp)
    80004e6e:	7b1e                	ld	s6,480(sp)
    80004e70:	6bfe                	ld	s7,472(sp)
    80004e72:	6c5e                	ld	s8,464(sp)
    80004e74:	6cbe                	ld	s9,456(sp)
    80004e76:	6d1e                	ld	s10,448(sp)
    80004e78:	7dfa                	ld	s11,440(sp)
    80004e7a:	22010113          	addi	sp,sp,544
    80004e7e:	8082                	ret
    end_op();
    80004e80:	fffff097          	auipc	ra,0xfffff
    80004e84:	464080e7          	jalr	1124(ra) # 800042e4 <end_op>
    return -1;
    80004e88:	557d                	li	a0,-1
    80004e8a:	b7f9                	j	80004e58 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	d2a080e7          	jalr	-726(ra) # 80001bb8 <proc_pagetable>
    80004e96:	8b2a                	mv	s6,a0
    80004e98:	d555                	beqz	a0,80004e44 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e9a:	e6842783          	lw	a5,-408(s0)
    80004e9e:	e8045703          	lhu	a4,-384(s0)
    80004ea2:	c735                	beqz	a4,80004f0e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ea4:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004eaa:	6a05                	lui	s4,0x1
    80004eac:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004eb0:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004eb4:	6d85                	lui	s11,0x1
    80004eb6:	7d7d                	lui	s10,0xfffff
    80004eb8:	ac1d                	j	800050ee <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004eba:	00004517          	auipc	a0,0x4
    80004ebe:	84e50513          	addi	a0,a0,-1970 # 80008708 <syscalls+0x290>
    80004ec2:	ffffb097          	auipc	ra,0xffffb
    80004ec6:	67e080e7          	jalr	1662(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eca:	874a                	mv	a4,s2
    80004ecc:	009c86bb          	addw	a3,s9,s1
    80004ed0:	4581                	li	a1,0
    80004ed2:	8556                	mv	a0,s5
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	c84080e7          	jalr	-892(ra) # 80003b58 <readi>
    80004edc:	2501                	sext.w	a0,a0
    80004ede:	1aa91863          	bne	s2,a0,8000508e <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004ee2:	009d84bb          	addw	s1,s11,s1
    80004ee6:	013d09bb          	addw	s3,s10,s3
    80004eea:	1f74f263          	bgeu	s1,s7,800050ce <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004eee:	02049593          	slli	a1,s1,0x20
    80004ef2:	9181                	srli	a1,a1,0x20
    80004ef4:	95e2                	add	a1,a1,s8
    80004ef6:	855a                	mv	a0,s6
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	17e080e7          	jalr	382(ra) # 80001076 <walkaddr>
    80004f00:	862a                	mv	a2,a0
    if(pa == 0)
    80004f02:	dd45                	beqz	a0,80004eba <exec+0xfe>
      n = PGSIZE;
    80004f04:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f06:	fd49f2e3          	bgeu	s3,s4,80004eca <exec+0x10e>
      n = sz - i;
    80004f0a:	894e                	mv	s2,s3
    80004f0c:	bf7d                	j	80004eca <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f0e:	4481                	li	s1,0
  iunlockput(ip);
    80004f10:	8556                	mv	a0,s5
    80004f12:	fffff097          	auipc	ra,0xfffff
    80004f16:	bf4080e7          	jalr	-1036(ra) # 80003b06 <iunlockput>
  end_op();
    80004f1a:	fffff097          	auipc	ra,0xfffff
    80004f1e:	3ca080e7          	jalr	970(ra) # 800042e4 <end_op>
  p = myproc();
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	bd0080e7          	jalr	-1072(ra) # 80001af2 <myproc>
    80004f2a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f2c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f30:	6785                	lui	a5,0x1
    80004f32:	17fd                	addi	a5,a5,-1
    80004f34:	94be                	add	s1,s1,a5
    80004f36:	77fd                	lui	a5,0xfffff
    80004f38:	8fe5                	and	a5,a5,s1
    80004f3a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f3e:	6609                	lui	a2,0x2
    80004f40:	963e                	add	a2,a2,a5
    80004f42:	85be                	mv	a1,a5
    80004f44:	855a                	mv	a0,s6
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	514080e7          	jalr	1300(ra) # 8000145a <uvmalloc>
    80004f4e:	8c2a                	mv	s8,a0
  ip = 0;
    80004f50:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f52:	12050e63          	beqz	a0,8000508e <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f56:	75f9                	lui	a1,0xffffe
    80004f58:	95aa                	add	a1,a1,a0
    80004f5a:	855a                	mv	a0,s6
    80004f5c:	ffffc097          	auipc	ra,0xffffc
    80004f60:	71c080e7          	jalr	1820(ra) # 80001678 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f64:	7afd                	lui	s5,0xfffff
    80004f66:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f68:	df043783          	ld	a5,-528(s0)
    80004f6c:	6388                	ld	a0,0(a5)
    80004f6e:	c925                	beqz	a0,80004fde <exec+0x222>
    80004f70:	e8840993          	addi	s3,s0,-376
    80004f74:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f78:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f7a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f7c:	ffffc097          	auipc	ra,0xffffc
    80004f80:	f00080e7          	jalr	-256(ra) # 80000e7c <strlen>
    80004f84:	0015079b          	addiw	a5,a0,1
    80004f88:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f8c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f90:	13596363          	bltu	s2,s5,800050b6 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f94:	df043d83          	ld	s11,-528(s0)
    80004f98:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f9c:	8552                	mv	a0,s4
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	ede080e7          	jalr	-290(ra) # 80000e7c <strlen>
    80004fa6:	0015069b          	addiw	a3,a0,1
    80004faa:	8652                	mv	a2,s4
    80004fac:	85ca                	mv	a1,s2
    80004fae:	855a                	mv	a0,s6
    80004fb0:	ffffc097          	auipc	ra,0xffffc
    80004fb4:	6fa080e7          	jalr	1786(ra) # 800016aa <copyout>
    80004fb8:	10054363          	bltz	a0,800050be <exec+0x302>
    ustack[argc] = sp;
    80004fbc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fc0:	0485                	addi	s1,s1,1
    80004fc2:	008d8793          	addi	a5,s11,8
    80004fc6:	def43823          	sd	a5,-528(s0)
    80004fca:	008db503          	ld	a0,8(s11)
    80004fce:	c911                	beqz	a0,80004fe2 <exec+0x226>
    if(argc >= MAXARG)
    80004fd0:	09a1                	addi	s3,s3,8
    80004fd2:	fb3c95e3          	bne	s9,s3,80004f7c <exec+0x1c0>
  sz = sz1;
    80004fd6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fda:	4a81                	li	s5,0
    80004fdc:	a84d                	j	8000508e <exec+0x2d2>
  sp = sz;
    80004fde:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fe0:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fe2:	00349793          	slli	a5,s1,0x3
    80004fe6:	f9040713          	addi	a4,s0,-112
    80004fea:	97ba                	add	a5,a5,a4
    80004fec:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004ff0:	00148693          	addi	a3,s1,1
    80004ff4:	068e                	slli	a3,a3,0x3
    80004ff6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ffa:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ffe:	01597663          	bgeu	s2,s5,8000500a <exec+0x24e>
  sz = sz1;
    80005002:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005006:	4a81                	li	s5,0
    80005008:	a059                	j	8000508e <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000500a:	e8840613          	addi	a2,s0,-376
    8000500e:	85ca                	mv	a1,s2
    80005010:	855a                	mv	a0,s6
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	698080e7          	jalr	1688(ra) # 800016aa <copyout>
    8000501a:	0a054663          	bltz	a0,800050c6 <exec+0x30a>
  p->trapframe->a1 = sp;
    8000501e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005022:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005026:	de843783          	ld	a5,-536(s0)
    8000502a:	0007c703          	lbu	a4,0(a5)
    8000502e:	cf11                	beqz	a4,8000504a <exec+0x28e>
    80005030:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005032:	02f00693          	li	a3,47
    80005036:	a039                	j	80005044 <exec+0x288>
      last = s+1;
    80005038:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000503c:	0785                	addi	a5,a5,1
    8000503e:	fff7c703          	lbu	a4,-1(a5)
    80005042:	c701                	beqz	a4,8000504a <exec+0x28e>
    if(*s == '/')
    80005044:	fed71ce3          	bne	a4,a3,8000503c <exec+0x280>
    80005048:	bfc5                	j	80005038 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000504a:	4641                	li	a2,16
    8000504c:	de843583          	ld	a1,-536(s0)
    80005050:	158b8513          	addi	a0,s7,344
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	df6080e7          	jalr	-522(ra) # 80000e4a <safestrcpy>
  oldpagetable = p->pagetable;
    8000505c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005060:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005064:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005068:	058bb783          	ld	a5,88(s7)
    8000506c:	e6043703          	ld	a4,-416(s0)
    80005070:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005072:	058bb783          	ld	a5,88(s7)
    80005076:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000507a:	85ea                	mv	a1,s10
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	bd8080e7          	jalr	-1064(ra) # 80001c54 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005084:	0004851b          	sext.w	a0,s1
    80005088:	bbc1                	j	80004e58 <exec+0x9c>
    8000508a:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000508e:	df843583          	ld	a1,-520(s0)
    80005092:	855a                	mv	a0,s6
    80005094:	ffffd097          	auipc	ra,0xffffd
    80005098:	bc0080e7          	jalr	-1088(ra) # 80001c54 <proc_freepagetable>
  if(ip){
    8000509c:	da0a94e3          	bnez	s5,80004e44 <exec+0x88>
  return -1;
    800050a0:	557d                	li	a0,-1
    800050a2:	bb5d                	j	80004e58 <exec+0x9c>
    800050a4:	de943c23          	sd	s1,-520(s0)
    800050a8:	b7dd                	j	8000508e <exec+0x2d2>
    800050aa:	de943c23          	sd	s1,-520(s0)
    800050ae:	b7c5                	j	8000508e <exec+0x2d2>
    800050b0:	de943c23          	sd	s1,-520(s0)
    800050b4:	bfe9                	j	8000508e <exec+0x2d2>
  sz = sz1;
    800050b6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ba:	4a81                	li	s5,0
    800050bc:	bfc9                	j	8000508e <exec+0x2d2>
  sz = sz1;
    800050be:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050c2:	4a81                	li	s5,0
    800050c4:	b7e9                	j	8000508e <exec+0x2d2>
  sz = sz1;
    800050c6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ca:	4a81                	li	s5,0
    800050cc:	b7c9                	j	8000508e <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050ce:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050d2:	e0843783          	ld	a5,-504(s0)
    800050d6:	0017869b          	addiw	a3,a5,1
    800050da:	e0d43423          	sd	a3,-504(s0)
    800050de:	e0043783          	ld	a5,-512(s0)
    800050e2:	0387879b          	addiw	a5,a5,56
    800050e6:	e8045703          	lhu	a4,-384(s0)
    800050ea:	e2e6d3e3          	bge	a3,a4,80004f10 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050ee:	2781                	sext.w	a5,a5
    800050f0:	e0f43023          	sd	a5,-512(s0)
    800050f4:	03800713          	li	a4,56
    800050f8:	86be                	mv	a3,a5
    800050fa:	e1040613          	addi	a2,s0,-496
    800050fe:	4581                	li	a1,0
    80005100:	8556                	mv	a0,s5
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	a56080e7          	jalr	-1450(ra) # 80003b58 <readi>
    8000510a:	03800793          	li	a5,56
    8000510e:	f6f51ee3          	bne	a0,a5,8000508a <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005112:	e1042783          	lw	a5,-496(s0)
    80005116:	4705                	li	a4,1
    80005118:	fae79de3          	bne	a5,a4,800050d2 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000511c:	e3843603          	ld	a2,-456(s0)
    80005120:	e3043783          	ld	a5,-464(s0)
    80005124:	f8f660e3          	bltu	a2,a5,800050a4 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005128:	e2043783          	ld	a5,-480(s0)
    8000512c:	963e                	add	a2,a2,a5
    8000512e:	f6f66ee3          	bltu	a2,a5,800050aa <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005132:	85a6                	mv	a1,s1
    80005134:	855a                	mv	a0,s6
    80005136:	ffffc097          	auipc	ra,0xffffc
    8000513a:	324080e7          	jalr	804(ra) # 8000145a <uvmalloc>
    8000513e:	dea43c23          	sd	a0,-520(s0)
    80005142:	d53d                	beqz	a0,800050b0 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005144:	e2043c03          	ld	s8,-480(s0)
    80005148:	de043783          	ld	a5,-544(s0)
    8000514c:	00fc77b3          	and	a5,s8,a5
    80005150:	ff9d                	bnez	a5,8000508e <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005152:	e1842c83          	lw	s9,-488(s0)
    80005156:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000515a:	f60b8ae3          	beqz	s7,800050ce <exec+0x312>
    8000515e:	89de                	mv	s3,s7
    80005160:	4481                	li	s1,0
    80005162:	b371                	j	80004eee <exec+0x132>

0000000080005164 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005164:	7179                	addi	sp,sp,-48
    80005166:	f406                	sd	ra,40(sp)
    80005168:	f022                	sd	s0,32(sp)
    8000516a:	ec26                	sd	s1,24(sp)
    8000516c:	e84a                	sd	s2,16(sp)
    8000516e:	1800                	addi	s0,sp,48
    80005170:	892e                	mv	s2,a1
    80005172:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005174:	fdc40593          	addi	a1,s0,-36
    80005178:	ffffe097          	auipc	ra,0xffffe
    8000517c:	b8e080e7          	jalr	-1138(ra) # 80002d06 <argint>
    80005180:	04054063          	bltz	a0,800051c0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005184:	fdc42703          	lw	a4,-36(s0)
    80005188:	47bd                	li	a5,15
    8000518a:	02e7ed63          	bltu	a5,a4,800051c4 <argfd+0x60>
    8000518e:	ffffd097          	auipc	ra,0xffffd
    80005192:	964080e7          	jalr	-1692(ra) # 80001af2 <myproc>
    80005196:	fdc42703          	lw	a4,-36(s0)
    8000519a:	01a70793          	addi	a5,a4,26
    8000519e:	078e                	slli	a5,a5,0x3
    800051a0:	953e                	add	a0,a0,a5
    800051a2:	611c                	ld	a5,0(a0)
    800051a4:	c395                	beqz	a5,800051c8 <argfd+0x64>
    return -1;
  if(pfd)
    800051a6:	00090463          	beqz	s2,800051ae <argfd+0x4a>
    *pfd = fd;
    800051aa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051ae:	4501                	li	a0,0
  if(pf)
    800051b0:	c091                	beqz	s1,800051b4 <argfd+0x50>
    *pf = f;
    800051b2:	e09c                	sd	a5,0(s1)
}
    800051b4:	70a2                	ld	ra,40(sp)
    800051b6:	7402                	ld	s0,32(sp)
    800051b8:	64e2                	ld	s1,24(sp)
    800051ba:	6942                	ld	s2,16(sp)
    800051bc:	6145                	addi	sp,sp,48
    800051be:	8082                	ret
    return -1;
    800051c0:	557d                	li	a0,-1
    800051c2:	bfcd                	j	800051b4 <argfd+0x50>
    return -1;
    800051c4:	557d                	li	a0,-1
    800051c6:	b7fd                	j	800051b4 <argfd+0x50>
    800051c8:	557d                	li	a0,-1
    800051ca:	b7ed                	j	800051b4 <argfd+0x50>

00000000800051cc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051cc:	1101                	addi	sp,sp,-32
    800051ce:	ec06                	sd	ra,24(sp)
    800051d0:	e822                	sd	s0,16(sp)
    800051d2:	e426                	sd	s1,8(sp)
    800051d4:	1000                	addi	s0,sp,32
    800051d6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	91a080e7          	jalr	-1766(ra) # 80001af2 <myproc>
    800051e0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051e2:	0d050793          	addi	a5,a0,208
    800051e6:	4501                	li	a0,0
    800051e8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051ea:	6398                	ld	a4,0(a5)
    800051ec:	cb19                	beqz	a4,80005202 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051ee:	2505                	addiw	a0,a0,1
    800051f0:	07a1                	addi	a5,a5,8
    800051f2:	fed51ce3          	bne	a0,a3,800051ea <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051f6:	557d                	li	a0,-1
}
    800051f8:	60e2                	ld	ra,24(sp)
    800051fa:	6442                	ld	s0,16(sp)
    800051fc:	64a2                	ld	s1,8(sp)
    800051fe:	6105                	addi	sp,sp,32
    80005200:	8082                	ret
      p->ofile[fd] = f;
    80005202:	01a50793          	addi	a5,a0,26
    80005206:	078e                	slli	a5,a5,0x3
    80005208:	963e                	add	a2,a2,a5
    8000520a:	e204                	sd	s1,0(a2)
      return fd;
    8000520c:	b7f5                	j	800051f8 <fdalloc+0x2c>

000000008000520e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000520e:	715d                	addi	sp,sp,-80
    80005210:	e486                	sd	ra,72(sp)
    80005212:	e0a2                	sd	s0,64(sp)
    80005214:	fc26                	sd	s1,56(sp)
    80005216:	f84a                	sd	s2,48(sp)
    80005218:	f44e                	sd	s3,40(sp)
    8000521a:	f052                	sd	s4,32(sp)
    8000521c:	ec56                	sd	s5,24(sp)
    8000521e:	0880                	addi	s0,sp,80
    80005220:	89ae                	mv	s3,a1
    80005222:	8ab2                	mv	s5,a2
    80005224:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005226:	fb040593          	addi	a1,s0,-80
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	e48080e7          	jalr	-440(ra) # 80004072 <nameiparent>
    80005232:	892a                	mv	s2,a0
    80005234:	12050e63          	beqz	a0,80005370 <create+0x162>
    return 0;

  ilock(dp);
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	66c080e7          	jalr	1644(ra) # 800038a4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005240:	4601                	li	a2,0
    80005242:	fb040593          	addi	a1,s0,-80
    80005246:	854a                	mv	a0,s2
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	b3a080e7          	jalr	-1222(ra) # 80003d82 <dirlookup>
    80005250:	84aa                	mv	s1,a0
    80005252:	c921                	beqz	a0,800052a2 <create+0x94>
    iunlockput(dp);
    80005254:	854a                	mv	a0,s2
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	8b0080e7          	jalr	-1872(ra) # 80003b06 <iunlockput>
    ilock(ip);
    8000525e:	8526                	mv	a0,s1
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	644080e7          	jalr	1604(ra) # 800038a4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005268:	2981                	sext.w	s3,s3
    8000526a:	4789                	li	a5,2
    8000526c:	02f99463          	bne	s3,a5,80005294 <create+0x86>
    80005270:	0444d783          	lhu	a5,68(s1)
    80005274:	37f9                	addiw	a5,a5,-2
    80005276:	17c2                	slli	a5,a5,0x30
    80005278:	93c1                	srli	a5,a5,0x30
    8000527a:	4705                	li	a4,1
    8000527c:	00f76c63          	bltu	a4,a5,80005294 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005280:	8526                	mv	a0,s1
    80005282:	60a6                	ld	ra,72(sp)
    80005284:	6406                	ld	s0,64(sp)
    80005286:	74e2                	ld	s1,56(sp)
    80005288:	7942                	ld	s2,48(sp)
    8000528a:	79a2                	ld	s3,40(sp)
    8000528c:	7a02                	ld	s4,32(sp)
    8000528e:	6ae2                	ld	s5,24(sp)
    80005290:	6161                	addi	sp,sp,80
    80005292:	8082                	ret
    iunlockput(ip);
    80005294:	8526                	mv	a0,s1
    80005296:	fffff097          	auipc	ra,0xfffff
    8000529a:	870080e7          	jalr	-1936(ra) # 80003b06 <iunlockput>
    return 0;
    8000529e:	4481                	li	s1,0
    800052a0:	b7c5                	j	80005280 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052a2:	85ce                	mv	a1,s3
    800052a4:	00092503          	lw	a0,0(s2)
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	464080e7          	jalr	1124(ra) # 8000370c <ialloc>
    800052b0:	84aa                	mv	s1,a0
    800052b2:	c521                	beqz	a0,800052fa <create+0xec>
  ilock(ip);
    800052b4:	ffffe097          	auipc	ra,0xffffe
    800052b8:	5f0080e7          	jalr	1520(ra) # 800038a4 <ilock>
  ip->major = major;
    800052bc:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052c0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052c4:	4a05                	li	s4,1
    800052c6:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800052ca:	8526                	mv	a0,s1
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	50e080e7          	jalr	1294(ra) # 800037da <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052d4:	2981                	sext.w	s3,s3
    800052d6:	03498a63          	beq	s3,s4,8000530a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800052da:	40d0                	lw	a2,4(s1)
    800052dc:	fb040593          	addi	a1,s0,-80
    800052e0:	854a                	mv	a0,s2
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	cb0080e7          	jalr	-848(ra) # 80003f92 <dirlink>
    800052ea:	06054b63          	bltz	a0,80005360 <create+0x152>
  iunlockput(dp);
    800052ee:	854a                	mv	a0,s2
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	816080e7          	jalr	-2026(ra) # 80003b06 <iunlockput>
  return ip;
    800052f8:	b761                	j	80005280 <create+0x72>
    panic("create: ialloc");
    800052fa:	00003517          	auipc	a0,0x3
    800052fe:	42e50513          	addi	a0,a0,1070 # 80008728 <syscalls+0x2b0>
    80005302:	ffffb097          	auipc	ra,0xffffb
    80005306:	23e080e7          	jalr	574(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    8000530a:	04a95783          	lhu	a5,74(s2)
    8000530e:	2785                	addiw	a5,a5,1
    80005310:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005314:	854a                	mv	a0,s2
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	4c4080e7          	jalr	1220(ra) # 800037da <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000531e:	40d0                	lw	a2,4(s1)
    80005320:	00003597          	auipc	a1,0x3
    80005324:	41858593          	addi	a1,a1,1048 # 80008738 <syscalls+0x2c0>
    80005328:	8526                	mv	a0,s1
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	c68080e7          	jalr	-920(ra) # 80003f92 <dirlink>
    80005332:	00054f63          	bltz	a0,80005350 <create+0x142>
    80005336:	00492603          	lw	a2,4(s2)
    8000533a:	00003597          	auipc	a1,0x3
    8000533e:	40658593          	addi	a1,a1,1030 # 80008740 <syscalls+0x2c8>
    80005342:	8526                	mv	a0,s1
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	c4e080e7          	jalr	-946(ra) # 80003f92 <dirlink>
    8000534c:	f80557e3          	bgez	a0,800052da <create+0xcc>
      panic("create dots");
    80005350:	00003517          	auipc	a0,0x3
    80005354:	3f850513          	addi	a0,a0,1016 # 80008748 <syscalls+0x2d0>
    80005358:	ffffb097          	auipc	ra,0xffffb
    8000535c:	1e8080e7          	jalr	488(ra) # 80000540 <panic>
    panic("create: dirlink");
    80005360:	00003517          	auipc	a0,0x3
    80005364:	3f850513          	addi	a0,a0,1016 # 80008758 <syscalls+0x2e0>
    80005368:	ffffb097          	auipc	ra,0xffffb
    8000536c:	1d8080e7          	jalr	472(ra) # 80000540 <panic>
    return 0;
    80005370:	84aa                	mv	s1,a0
    80005372:	b739                	j	80005280 <create+0x72>

0000000080005374 <sys_dup>:
{
    80005374:	7179                	addi	sp,sp,-48
    80005376:	f406                	sd	ra,40(sp)
    80005378:	f022                	sd	s0,32(sp)
    8000537a:	ec26                	sd	s1,24(sp)
    8000537c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000537e:	fd840613          	addi	a2,s0,-40
    80005382:	4581                	li	a1,0
    80005384:	4501                	li	a0,0
    80005386:	00000097          	auipc	ra,0x0
    8000538a:	dde080e7          	jalr	-546(ra) # 80005164 <argfd>
    return -1;
    8000538e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005390:	02054363          	bltz	a0,800053b6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005394:	fd843503          	ld	a0,-40(s0)
    80005398:	00000097          	auipc	ra,0x0
    8000539c:	e34080e7          	jalr	-460(ra) # 800051cc <fdalloc>
    800053a0:	84aa                	mv	s1,a0
    return -1;
    800053a2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053a4:	00054963          	bltz	a0,800053b6 <sys_dup+0x42>
  filedup(f);
    800053a8:	fd843503          	ld	a0,-40(s0)
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	338080e7          	jalr	824(ra) # 800046e4 <filedup>
  return fd;
    800053b4:	87a6                	mv	a5,s1
}
    800053b6:	853e                	mv	a0,a5
    800053b8:	70a2                	ld	ra,40(sp)
    800053ba:	7402                	ld	s0,32(sp)
    800053bc:	64e2                	ld	s1,24(sp)
    800053be:	6145                	addi	sp,sp,48
    800053c0:	8082                	ret

00000000800053c2 <sys_read>:
{
    800053c2:	7179                	addi	sp,sp,-48
    800053c4:	f406                	sd	ra,40(sp)
    800053c6:	f022                	sd	s0,32(sp)
    800053c8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ca:	fe840613          	addi	a2,s0,-24
    800053ce:	4581                	li	a1,0
    800053d0:	4501                	li	a0,0
    800053d2:	00000097          	auipc	ra,0x0
    800053d6:	d92080e7          	jalr	-622(ra) # 80005164 <argfd>
    return -1;
    800053da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053dc:	04054163          	bltz	a0,8000541e <sys_read+0x5c>
    800053e0:	fe440593          	addi	a1,s0,-28
    800053e4:	4509                	li	a0,2
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	920080e7          	jalr	-1760(ra) # 80002d06 <argint>
    return -1;
    800053ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f0:	02054763          	bltz	a0,8000541e <sys_read+0x5c>
    800053f4:	fd840593          	addi	a1,s0,-40
    800053f8:	4505                	li	a0,1
    800053fa:	ffffe097          	auipc	ra,0xffffe
    800053fe:	92e080e7          	jalr	-1746(ra) # 80002d28 <argaddr>
    return -1;
    80005402:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005404:	00054d63          	bltz	a0,8000541e <sys_read+0x5c>
  return fileread(f, p, n);
    80005408:	fe442603          	lw	a2,-28(s0)
    8000540c:	fd843583          	ld	a1,-40(s0)
    80005410:	fe843503          	ld	a0,-24(s0)
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	45c080e7          	jalr	1116(ra) # 80004870 <fileread>
    8000541c:	87aa                	mv	a5,a0
}
    8000541e:	853e                	mv	a0,a5
    80005420:	70a2                	ld	ra,40(sp)
    80005422:	7402                	ld	s0,32(sp)
    80005424:	6145                	addi	sp,sp,48
    80005426:	8082                	ret

0000000080005428 <sys_write>:
{
    80005428:	7179                	addi	sp,sp,-48
    8000542a:	f406                	sd	ra,40(sp)
    8000542c:	f022                	sd	s0,32(sp)
    8000542e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005430:	fe840613          	addi	a2,s0,-24
    80005434:	4581                	li	a1,0
    80005436:	4501                	li	a0,0
    80005438:	00000097          	auipc	ra,0x0
    8000543c:	d2c080e7          	jalr	-724(ra) # 80005164 <argfd>
    return -1;
    80005440:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005442:	04054163          	bltz	a0,80005484 <sys_write+0x5c>
    80005446:	fe440593          	addi	a1,s0,-28
    8000544a:	4509                	li	a0,2
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	8ba080e7          	jalr	-1862(ra) # 80002d06 <argint>
    return -1;
    80005454:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005456:	02054763          	bltz	a0,80005484 <sys_write+0x5c>
    8000545a:	fd840593          	addi	a1,s0,-40
    8000545e:	4505                	li	a0,1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	8c8080e7          	jalr	-1848(ra) # 80002d28 <argaddr>
    return -1;
    80005468:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546a:	00054d63          	bltz	a0,80005484 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000546e:	fe442603          	lw	a2,-28(s0)
    80005472:	fd843583          	ld	a1,-40(s0)
    80005476:	fe843503          	ld	a0,-24(s0)
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	4b8080e7          	jalr	1208(ra) # 80004932 <filewrite>
    80005482:	87aa                	mv	a5,a0
}
    80005484:	853e                	mv	a0,a5
    80005486:	70a2                	ld	ra,40(sp)
    80005488:	7402                	ld	s0,32(sp)
    8000548a:	6145                	addi	sp,sp,48
    8000548c:	8082                	ret

000000008000548e <sys_close>:
{
    8000548e:	1101                	addi	sp,sp,-32
    80005490:	ec06                	sd	ra,24(sp)
    80005492:	e822                	sd	s0,16(sp)
    80005494:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005496:	fe040613          	addi	a2,s0,-32
    8000549a:	fec40593          	addi	a1,s0,-20
    8000549e:	4501                	li	a0,0
    800054a0:	00000097          	auipc	ra,0x0
    800054a4:	cc4080e7          	jalr	-828(ra) # 80005164 <argfd>
    return -1;
    800054a8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054aa:	02054463          	bltz	a0,800054d2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054ae:	ffffc097          	auipc	ra,0xffffc
    800054b2:	644080e7          	jalr	1604(ra) # 80001af2 <myproc>
    800054b6:	fec42783          	lw	a5,-20(s0)
    800054ba:	07e9                	addi	a5,a5,26
    800054bc:	078e                	slli	a5,a5,0x3
    800054be:	97aa                	add	a5,a5,a0
    800054c0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054c4:	fe043503          	ld	a0,-32(s0)
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	26e080e7          	jalr	622(ra) # 80004736 <fileclose>
  return 0;
    800054d0:	4781                	li	a5,0
}
    800054d2:	853e                	mv	a0,a5
    800054d4:	60e2                	ld	ra,24(sp)
    800054d6:	6442                	ld	s0,16(sp)
    800054d8:	6105                	addi	sp,sp,32
    800054da:	8082                	ret

00000000800054dc <sys_fstat>:
{
    800054dc:	1101                	addi	sp,sp,-32
    800054de:	ec06                	sd	ra,24(sp)
    800054e0:	e822                	sd	s0,16(sp)
    800054e2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054e4:	fe840613          	addi	a2,s0,-24
    800054e8:	4581                	li	a1,0
    800054ea:	4501                	li	a0,0
    800054ec:	00000097          	auipc	ra,0x0
    800054f0:	c78080e7          	jalr	-904(ra) # 80005164 <argfd>
    return -1;
    800054f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054f6:	02054563          	bltz	a0,80005520 <sys_fstat+0x44>
    800054fa:	fe040593          	addi	a1,s0,-32
    800054fe:	4505                	li	a0,1
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	828080e7          	jalr	-2008(ra) # 80002d28 <argaddr>
    return -1;
    80005508:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000550a:	00054b63          	bltz	a0,80005520 <sys_fstat+0x44>
  return filestat(f, st);
    8000550e:	fe043583          	ld	a1,-32(s0)
    80005512:	fe843503          	ld	a0,-24(s0)
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	2e8080e7          	jalr	744(ra) # 800047fe <filestat>
    8000551e:	87aa                	mv	a5,a0
}
    80005520:	853e                	mv	a0,a5
    80005522:	60e2                	ld	ra,24(sp)
    80005524:	6442                	ld	s0,16(sp)
    80005526:	6105                	addi	sp,sp,32
    80005528:	8082                	ret

000000008000552a <sys_link>:
{
    8000552a:	7169                	addi	sp,sp,-304
    8000552c:	f606                	sd	ra,296(sp)
    8000552e:	f222                	sd	s0,288(sp)
    80005530:	ee26                	sd	s1,280(sp)
    80005532:	ea4a                	sd	s2,272(sp)
    80005534:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005536:	08000613          	li	a2,128
    8000553a:	ed040593          	addi	a1,s0,-304
    8000553e:	4501                	li	a0,0
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	80a080e7          	jalr	-2038(ra) # 80002d4a <argstr>
    return -1;
    80005548:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000554a:	10054e63          	bltz	a0,80005666 <sys_link+0x13c>
    8000554e:	08000613          	li	a2,128
    80005552:	f5040593          	addi	a1,s0,-176
    80005556:	4505                	li	a0,1
    80005558:	ffffd097          	auipc	ra,0xffffd
    8000555c:	7f2080e7          	jalr	2034(ra) # 80002d4a <argstr>
    return -1;
    80005560:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005562:	10054263          	bltz	a0,80005666 <sys_link+0x13c>
  begin_op();
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	cfe080e7          	jalr	-770(ra) # 80004264 <begin_op>
  if((ip = namei(old)) == 0){
    8000556e:	ed040513          	addi	a0,s0,-304
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	ae2080e7          	jalr	-1310(ra) # 80004054 <namei>
    8000557a:	84aa                	mv	s1,a0
    8000557c:	c551                	beqz	a0,80005608 <sys_link+0xde>
  ilock(ip);
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	326080e7          	jalr	806(ra) # 800038a4 <ilock>
  if(ip->type == T_DIR){
    80005586:	04449703          	lh	a4,68(s1)
    8000558a:	4785                	li	a5,1
    8000558c:	08f70463          	beq	a4,a5,80005614 <sys_link+0xea>
  ip->nlink++;
    80005590:	04a4d783          	lhu	a5,74(s1)
    80005594:	2785                	addiw	a5,a5,1
    80005596:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	23e080e7          	jalr	574(ra) # 800037da <iupdate>
  iunlock(ip);
    800055a4:	8526                	mv	a0,s1
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	3c0080e7          	jalr	960(ra) # 80003966 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055ae:	fd040593          	addi	a1,s0,-48
    800055b2:	f5040513          	addi	a0,s0,-176
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	abc080e7          	jalr	-1348(ra) # 80004072 <nameiparent>
    800055be:	892a                	mv	s2,a0
    800055c0:	c935                	beqz	a0,80005634 <sys_link+0x10a>
  ilock(dp);
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	2e2080e7          	jalr	738(ra) # 800038a4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055ca:	00092703          	lw	a4,0(s2)
    800055ce:	409c                	lw	a5,0(s1)
    800055d0:	04f71d63          	bne	a4,a5,8000562a <sys_link+0x100>
    800055d4:	40d0                	lw	a2,4(s1)
    800055d6:	fd040593          	addi	a1,s0,-48
    800055da:	854a                	mv	a0,s2
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	9b6080e7          	jalr	-1610(ra) # 80003f92 <dirlink>
    800055e4:	04054363          	bltz	a0,8000562a <sys_link+0x100>
  iunlockput(dp);
    800055e8:	854a                	mv	a0,s2
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	51c080e7          	jalr	1308(ra) # 80003b06 <iunlockput>
  iput(ip);
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	46a080e7          	jalr	1130(ra) # 80003a5e <iput>
  end_op();
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	ce8080e7          	jalr	-792(ra) # 800042e4 <end_op>
  return 0;
    80005604:	4781                	li	a5,0
    80005606:	a085                	j	80005666 <sys_link+0x13c>
    end_op();
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	cdc080e7          	jalr	-804(ra) # 800042e4 <end_op>
    return -1;
    80005610:	57fd                	li	a5,-1
    80005612:	a891                	j	80005666 <sys_link+0x13c>
    iunlockput(ip);
    80005614:	8526                	mv	a0,s1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	4f0080e7          	jalr	1264(ra) # 80003b06 <iunlockput>
    end_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	cc6080e7          	jalr	-826(ra) # 800042e4 <end_op>
    return -1;
    80005626:	57fd                	li	a5,-1
    80005628:	a83d                	j	80005666 <sys_link+0x13c>
    iunlockput(dp);
    8000562a:	854a                	mv	a0,s2
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	4da080e7          	jalr	1242(ra) # 80003b06 <iunlockput>
  ilock(ip);
    80005634:	8526                	mv	a0,s1
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	26e080e7          	jalr	622(ra) # 800038a4 <ilock>
  ip->nlink--;
    8000563e:	04a4d783          	lhu	a5,74(s1)
    80005642:	37fd                	addiw	a5,a5,-1
    80005644:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	190080e7          	jalr	400(ra) # 800037da <iupdate>
  iunlockput(ip);
    80005652:	8526                	mv	a0,s1
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	4b2080e7          	jalr	1202(ra) # 80003b06 <iunlockput>
  end_op();
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	c88080e7          	jalr	-888(ra) # 800042e4 <end_op>
  return -1;
    80005664:	57fd                	li	a5,-1
}
    80005666:	853e                	mv	a0,a5
    80005668:	70b2                	ld	ra,296(sp)
    8000566a:	7412                	ld	s0,288(sp)
    8000566c:	64f2                	ld	s1,280(sp)
    8000566e:	6952                	ld	s2,272(sp)
    80005670:	6155                	addi	sp,sp,304
    80005672:	8082                	ret

0000000080005674 <sys_unlink>:
{
    80005674:	7151                	addi	sp,sp,-240
    80005676:	f586                	sd	ra,232(sp)
    80005678:	f1a2                	sd	s0,224(sp)
    8000567a:	eda6                	sd	s1,216(sp)
    8000567c:	e9ca                	sd	s2,208(sp)
    8000567e:	e5ce                	sd	s3,200(sp)
    80005680:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005682:	08000613          	li	a2,128
    80005686:	f3040593          	addi	a1,s0,-208
    8000568a:	4501                	li	a0,0
    8000568c:	ffffd097          	auipc	ra,0xffffd
    80005690:	6be080e7          	jalr	1726(ra) # 80002d4a <argstr>
    80005694:	18054163          	bltz	a0,80005816 <sys_unlink+0x1a2>
  begin_op();
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	bcc080e7          	jalr	-1076(ra) # 80004264 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056a0:	fb040593          	addi	a1,s0,-80
    800056a4:	f3040513          	addi	a0,s0,-208
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	9ca080e7          	jalr	-1590(ra) # 80004072 <nameiparent>
    800056b0:	84aa                	mv	s1,a0
    800056b2:	c979                	beqz	a0,80005788 <sys_unlink+0x114>
  ilock(dp);
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	1f0080e7          	jalr	496(ra) # 800038a4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056bc:	00003597          	auipc	a1,0x3
    800056c0:	07c58593          	addi	a1,a1,124 # 80008738 <syscalls+0x2c0>
    800056c4:	fb040513          	addi	a0,s0,-80
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	6a0080e7          	jalr	1696(ra) # 80003d68 <namecmp>
    800056d0:	14050a63          	beqz	a0,80005824 <sys_unlink+0x1b0>
    800056d4:	00003597          	auipc	a1,0x3
    800056d8:	06c58593          	addi	a1,a1,108 # 80008740 <syscalls+0x2c8>
    800056dc:	fb040513          	addi	a0,s0,-80
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	688080e7          	jalr	1672(ra) # 80003d68 <namecmp>
    800056e8:	12050e63          	beqz	a0,80005824 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056ec:	f2c40613          	addi	a2,s0,-212
    800056f0:	fb040593          	addi	a1,s0,-80
    800056f4:	8526                	mv	a0,s1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	68c080e7          	jalr	1676(ra) # 80003d82 <dirlookup>
    800056fe:	892a                	mv	s2,a0
    80005700:	12050263          	beqz	a0,80005824 <sys_unlink+0x1b0>
  ilock(ip);
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	1a0080e7          	jalr	416(ra) # 800038a4 <ilock>
  if(ip->nlink < 1)
    8000570c:	04a91783          	lh	a5,74(s2)
    80005710:	08f05263          	blez	a5,80005794 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005714:	04491703          	lh	a4,68(s2)
    80005718:	4785                	li	a5,1
    8000571a:	08f70563          	beq	a4,a5,800057a4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000571e:	4641                	li	a2,16
    80005720:	4581                	li	a1,0
    80005722:	fc040513          	addi	a0,s0,-64
    80005726:	ffffb097          	auipc	ra,0xffffb
    8000572a:	5d2080e7          	jalr	1490(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000572e:	4741                	li	a4,16
    80005730:	f2c42683          	lw	a3,-212(s0)
    80005734:	fc040613          	addi	a2,s0,-64
    80005738:	4581                	li	a1,0
    8000573a:	8526                	mv	a0,s1
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	512080e7          	jalr	1298(ra) # 80003c4e <writei>
    80005744:	47c1                	li	a5,16
    80005746:	0af51563          	bne	a0,a5,800057f0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000574a:	04491703          	lh	a4,68(s2)
    8000574e:	4785                	li	a5,1
    80005750:	0af70863          	beq	a4,a5,80005800 <sys_unlink+0x18c>
  iunlockput(dp);
    80005754:	8526                	mv	a0,s1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	3b0080e7          	jalr	944(ra) # 80003b06 <iunlockput>
  ip->nlink--;
    8000575e:	04a95783          	lhu	a5,74(s2)
    80005762:	37fd                	addiw	a5,a5,-1
    80005764:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	070080e7          	jalr	112(ra) # 800037da <iupdate>
  iunlockput(ip);
    80005772:	854a                	mv	a0,s2
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	392080e7          	jalr	914(ra) # 80003b06 <iunlockput>
  end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	b68080e7          	jalr	-1176(ra) # 800042e4 <end_op>
  return 0;
    80005784:	4501                	li	a0,0
    80005786:	a84d                	j	80005838 <sys_unlink+0x1c4>
    end_op();
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	b5c080e7          	jalr	-1188(ra) # 800042e4 <end_op>
    return -1;
    80005790:	557d                	li	a0,-1
    80005792:	a05d                	j	80005838 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005794:	00003517          	auipc	a0,0x3
    80005798:	fd450513          	addi	a0,a0,-44 # 80008768 <syscalls+0x2f0>
    8000579c:	ffffb097          	auipc	ra,0xffffb
    800057a0:	da4080e7          	jalr	-604(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057a4:	04c92703          	lw	a4,76(s2)
    800057a8:	02000793          	li	a5,32
    800057ac:	f6e7f9e3          	bgeu	a5,a4,8000571e <sys_unlink+0xaa>
    800057b0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057b4:	4741                	li	a4,16
    800057b6:	86ce                	mv	a3,s3
    800057b8:	f1840613          	addi	a2,s0,-232
    800057bc:	4581                	li	a1,0
    800057be:	854a                	mv	a0,s2
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	398080e7          	jalr	920(ra) # 80003b58 <readi>
    800057c8:	47c1                	li	a5,16
    800057ca:	00f51b63          	bne	a0,a5,800057e0 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057ce:	f1845783          	lhu	a5,-232(s0)
    800057d2:	e7a1                	bnez	a5,8000581a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057d4:	29c1                	addiw	s3,s3,16
    800057d6:	04c92783          	lw	a5,76(s2)
    800057da:	fcf9ede3          	bltu	s3,a5,800057b4 <sys_unlink+0x140>
    800057de:	b781                	j	8000571e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057e0:	00003517          	auipc	a0,0x3
    800057e4:	fa050513          	addi	a0,a0,-96 # 80008780 <syscalls+0x308>
    800057e8:	ffffb097          	auipc	ra,0xffffb
    800057ec:	d58080e7          	jalr	-680(ra) # 80000540 <panic>
    panic("unlink: writei");
    800057f0:	00003517          	auipc	a0,0x3
    800057f4:	fa850513          	addi	a0,a0,-88 # 80008798 <syscalls+0x320>
    800057f8:	ffffb097          	auipc	ra,0xffffb
    800057fc:	d48080e7          	jalr	-696(ra) # 80000540 <panic>
    dp->nlink--;
    80005800:	04a4d783          	lhu	a5,74(s1)
    80005804:	37fd                	addiw	a5,a5,-1
    80005806:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000580a:	8526                	mv	a0,s1
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	fce080e7          	jalr	-50(ra) # 800037da <iupdate>
    80005814:	b781                	j	80005754 <sys_unlink+0xe0>
    return -1;
    80005816:	557d                	li	a0,-1
    80005818:	a005                	j	80005838 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000581a:	854a                	mv	a0,s2
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	2ea080e7          	jalr	746(ra) # 80003b06 <iunlockput>
  iunlockput(dp);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	2e0080e7          	jalr	736(ra) # 80003b06 <iunlockput>
  end_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	ab6080e7          	jalr	-1354(ra) # 800042e4 <end_op>
  return -1;
    80005836:	557d                	li	a0,-1
}
    80005838:	70ae                	ld	ra,232(sp)
    8000583a:	740e                	ld	s0,224(sp)
    8000583c:	64ee                	ld	s1,216(sp)
    8000583e:	694e                	ld	s2,208(sp)
    80005840:	69ae                	ld	s3,200(sp)
    80005842:	616d                	addi	sp,sp,240
    80005844:	8082                	ret

0000000080005846 <sys_open>:

uint64
sys_open(void)
{
    80005846:	7131                	addi	sp,sp,-192
    80005848:	fd06                	sd	ra,184(sp)
    8000584a:	f922                	sd	s0,176(sp)
    8000584c:	f526                	sd	s1,168(sp)
    8000584e:	f14a                	sd	s2,160(sp)
    80005850:	ed4e                	sd	s3,152(sp)
    80005852:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005854:	08000613          	li	a2,128
    80005858:	f5040593          	addi	a1,s0,-176
    8000585c:	4501                	li	a0,0
    8000585e:	ffffd097          	auipc	ra,0xffffd
    80005862:	4ec080e7          	jalr	1260(ra) # 80002d4a <argstr>
    return -1;
    80005866:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005868:	0c054163          	bltz	a0,8000592a <sys_open+0xe4>
    8000586c:	f4c40593          	addi	a1,s0,-180
    80005870:	4505                	li	a0,1
    80005872:	ffffd097          	auipc	ra,0xffffd
    80005876:	494080e7          	jalr	1172(ra) # 80002d06 <argint>
    8000587a:	0a054863          	bltz	a0,8000592a <sys_open+0xe4>

  begin_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	9e6080e7          	jalr	-1562(ra) # 80004264 <begin_op>

  if(omode & O_CREATE){
    80005886:	f4c42783          	lw	a5,-180(s0)
    8000588a:	2007f793          	andi	a5,a5,512
    8000588e:	cbdd                	beqz	a5,80005944 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005890:	4681                	li	a3,0
    80005892:	4601                	li	a2,0
    80005894:	4589                	li	a1,2
    80005896:	f5040513          	addi	a0,s0,-176
    8000589a:	00000097          	auipc	ra,0x0
    8000589e:	974080e7          	jalr	-1676(ra) # 8000520e <create>
    800058a2:	892a                	mv	s2,a0
    if(ip == 0){
    800058a4:	c959                	beqz	a0,8000593a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058a6:	04491703          	lh	a4,68(s2)
    800058aa:	478d                	li	a5,3
    800058ac:	00f71763          	bne	a4,a5,800058ba <sys_open+0x74>
    800058b0:	04695703          	lhu	a4,70(s2)
    800058b4:	47a5                	li	a5,9
    800058b6:	0ce7ec63          	bltu	a5,a4,8000598e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	dc0080e7          	jalr	-576(ra) # 8000467a <filealloc>
    800058c2:	89aa                	mv	s3,a0
    800058c4:	10050263          	beqz	a0,800059c8 <sys_open+0x182>
    800058c8:	00000097          	auipc	ra,0x0
    800058cc:	904080e7          	jalr	-1788(ra) # 800051cc <fdalloc>
    800058d0:	84aa                	mv	s1,a0
    800058d2:	0e054663          	bltz	a0,800059be <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058d6:	04491703          	lh	a4,68(s2)
    800058da:	478d                	li	a5,3
    800058dc:	0cf70463          	beq	a4,a5,800059a4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058e0:	4789                	li	a5,2
    800058e2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058e6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058ea:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058ee:	f4c42783          	lw	a5,-180(s0)
    800058f2:	0017c713          	xori	a4,a5,1
    800058f6:	8b05                	andi	a4,a4,1
    800058f8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058fc:	0037f713          	andi	a4,a5,3
    80005900:	00e03733          	snez	a4,a4
    80005904:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005908:	4007f793          	andi	a5,a5,1024
    8000590c:	c791                	beqz	a5,80005918 <sys_open+0xd2>
    8000590e:	04491703          	lh	a4,68(s2)
    80005912:	4789                	li	a5,2
    80005914:	08f70f63          	beq	a4,a5,800059b2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005918:	854a                	mv	a0,s2
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	04c080e7          	jalr	76(ra) # 80003966 <iunlock>
  end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	9c2080e7          	jalr	-1598(ra) # 800042e4 <end_op>

  return fd;
}
    8000592a:	8526                	mv	a0,s1
    8000592c:	70ea                	ld	ra,184(sp)
    8000592e:	744a                	ld	s0,176(sp)
    80005930:	74aa                	ld	s1,168(sp)
    80005932:	790a                	ld	s2,160(sp)
    80005934:	69ea                	ld	s3,152(sp)
    80005936:	6129                	addi	sp,sp,192
    80005938:	8082                	ret
      end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	9aa080e7          	jalr	-1622(ra) # 800042e4 <end_op>
      return -1;
    80005942:	b7e5                	j	8000592a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005944:	f5040513          	addi	a0,s0,-176
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	70c080e7          	jalr	1804(ra) # 80004054 <namei>
    80005950:	892a                	mv	s2,a0
    80005952:	c905                	beqz	a0,80005982 <sys_open+0x13c>
    ilock(ip);
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	f50080e7          	jalr	-176(ra) # 800038a4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000595c:	04491703          	lh	a4,68(s2)
    80005960:	4785                	li	a5,1
    80005962:	f4f712e3          	bne	a4,a5,800058a6 <sys_open+0x60>
    80005966:	f4c42783          	lw	a5,-180(s0)
    8000596a:	dba1                	beqz	a5,800058ba <sys_open+0x74>
      iunlockput(ip);
    8000596c:	854a                	mv	a0,s2
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	198080e7          	jalr	408(ra) # 80003b06 <iunlockput>
      end_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	96e080e7          	jalr	-1682(ra) # 800042e4 <end_op>
      return -1;
    8000597e:	54fd                	li	s1,-1
    80005980:	b76d                	j	8000592a <sys_open+0xe4>
      end_op();
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	962080e7          	jalr	-1694(ra) # 800042e4 <end_op>
      return -1;
    8000598a:	54fd                	li	s1,-1
    8000598c:	bf79                	j	8000592a <sys_open+0xe4>
    iunlockput(ip);
    8000598e:	854a                	mv	a0,s2
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	176080e7          	jalr	374(ra) # 80003b06 <iunlockput>
    end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	94c080e7          	jalr	-1716(ra) # 800042e4 <end_op>
    return -1;
    800059a0:	54fd                	li	s1,-1
    800059a2:	b761                	j	8000592a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059a4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059a8:	04691783          	lh	a5,70(s2)
    800059ac:	02f99223          	sh	a5,36(s3)
    800059b0:	bf2d                	j	800058ea <sys_open+0xa4>
    itrunc(ip);
    800059b2:	854a                	mv	a0,s2
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	ffe080e7          	jalr	-2(ra) # 800039b2 <itrunc>
    800059bc:	bfb1                	j	80005918 <sys_open+0xd2>
      fileclose(f);
    800059be:	854e                	mv	a0,s3
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	d76080e7          	jalr	-650(ra) # 80004736 <fileclose>
    iunlockput(ip);
    800059c8:	854a                	mv	a0,s2
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	13c080e7          	jalr	316(ra) # 80003b06 <iunlockput>
    end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	912080e7          	jalr	-1774(ra) # 800042e4 <end_op>
    return -1;
    800059da:	54fd                	li	s1,-1
    800059dc:	b7b9                	j	8000592a <sys_open+0xe4>

00000000800059de <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059de:	7175                	addi	sp,sp,-144
    800059e0:	e506                	sd	ra,136(sp)
    800059e2:	e122                	sd	s0,128(sp)
    800059e4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	87e080e7          	jalr	-1922(ra) # 80004264 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059ee:	08000613          	li	a2,128
    800059f2:	f7040593          	addi	a1,s0,-144
    800059f6:	4501                	li	a0,0
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	352080e7          	jalr	850(ra) # 80002d4a <argstr>
    80005a00:	02054963          	bltz	a0,80005a32 <sys_mkdir+0x54>
    80005a04:	4681                	li	a3,0
    80005a06:	4601                	li	a2,0
    80005a08:	4585                	li	a1,1
    80005a0a:	f7040513          	addi	a0,s0,-144
    80005a0e:	00000097          	auipc	ra,0x0
    80005a12:	800080e7          	jalr	-2048(ra) # 8000520e <create>
    80005a16:	cd11                	beqz	a0,80005a32 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	0ee080e7          	jalr	238(ra) # 80003b06 <iunlockput>
  end_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	8c4080e7          	jalr	-1852(ra) # 800042e4 <end_op>
  return 0;
    80005a28:	4501                	li	a0,0
}
    80005a2a:	60aa                	ld	ra,136(sp)
    80005a2c:	640a                	ld	s0,128(sp)
    80005a2e:	6149                	addi	sp,sp,144
    80005a30:	8082                	ret
    end_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	8b2080e7          	jalr	-1870(ra) # 800042e4 <end_op>
    return -1;
    80005a3a:	557d                	li	a0,-1
    80005a3c:	b7fd                	j	80005a2a <sys_mkdir+0x4c>

0000000080005a3e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a3e:	7135                	addi	sp,sp,-160
    80005a40:	ed06                	sd	ra,152(sp)
    80005a42:	e922                	sd	s0,144(sp)
    80005a44:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	81e080e7          	jalr	-2018(ra) # 80004264 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a4e:	08000613          	li	a2,128
    80005a52:	f7040593          	addi	a1,s0,-144
    80005a56:	4501                	li	a0,0
    80005a58:	ffffd097          	auipc	ra,0xffffd
    80005a5c:	2f2080e7          	jalr	754(ra) # 80002d4a <argstr>
    80005a60:	04054a63          	bltz	a0,80005ab4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a64:	f6c40593          	addi	a1,s0,-148
    80005a68:	4505                	li	a0,1
    80005a6a:	ffffd097          	auipc	ra,0xffffd
    80005a6e:	29c080e7          	jalr	668(ra) # 80002d06 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a72:	04054163          	bltz	a0,80005ab4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a76:	f6840593          	addi	a1,s0,-152
    80005a7a:	4509                	li	a0,2
    80005a7c:	ffffd097          	auipc	ra,0xffffd
    80005a80:	28a080e7          	jalr	650(ra) # 80002d06 <argint>
     argint(1, &major) < 0 ||
    80005a84:	02054863          	bltz	a0,80005ab4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a88:	f6841683          	lh	a3,-152(s0)
    80005a8c:	f6c41603          	lh	a2,-148(s0)
    80005a90:	458d                	li	a1,3
    80005a92:	f7040513          	addi	a0,s0,-144
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	778080e7          	jalr	1912(ra) # 8000520e <create>
     argint(2, &minor) < 0 ||
    80005a9e:	c919                	beqz	a0,80005ab4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	066080e7          	jalr	102(ra) # 80003b06 <iunlockput>
  end_op();
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	83c080e7          	jalr	-1988(ra) # 800042e4 <end_op>
  return 0;
    80005ab0:	4501                	li	a0,0
    80005ab2:	a031                	j	80005abe <sys_mknod+0x80>
    end_op();
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	830080e7          	jalr	-2000(ra) # 800042e4 <end_op>
    return -1;
    80005abc:	557d                	li	a0,-1
}
    80005abe:	60ea                	ld	ra,152(sp)
    80005ac0:	644a                	ld	s0,144(sp)
    80005ac2:	610d                	addi	sp,sp,160
    80005ac4:	8082                	ret

0000000080005ac6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ac6:	7135                	addi	sp,sp,-160
    80005ac8:	ed06                	sd	ra,152(sp)
    80005aca:	e922                	sd	s0,144(sp)
    80005acc:	e526                	sd	s1,136(sp)
    80005ace:	e14a                	sd	s2,128(sp)
    80005ad0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ad2:	ffffc097          	auipc	ra,0xffffc
    80005ad6:	020080e7          	jalr	32(ra) # 80001af2 <myproc>
    80005ada:	892a                	mv	s2,a0
  
  begin_op();
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	788080e7          	jalr	1928(ra) # 80004264 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ae4:	08000613          	li	a2,128
    80005ae8:	f6040593          	addi	a1,s0,-160
    80005aec:	4501                	li	a0,0
    80005aee:	ffffd097          	auipc	ra,0xffffd
    80005af2:	25c080e7          	jalr	604(ra) # 80002d4a <argstr>
    80005af6:	04054b63          	bltz	a0,80005b4c <sys_chdir+0x86>
    80005afa:	f6040513          	addi	a0,s0,-160
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	556080e7          	jalr	1366(ra) # 80004054 <namei>
    80005b06:	84aa                	mv	s1,a0
    80005b08:	c131                	beqz	a0,80005b4c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	d9a080e7          	jalr	-614(ra) # 800038a4 <ilock>
  if(ip->type != T_DIR){
    80005b12:	04449703          	lh	a4,68(s1)
    80005b16:	4785                	li	a5,1
    80005b18:	04f71063          	bne	a4,a5,80005b58 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b1c:	8526                	mv	a0,s1
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	e48080e7          	jalr	-440(ra) # 80003966 <iunlock>
  iput(p->cwd);
    80005b26:	15093503          	ld	a0,336(s2)
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	f34080e7          	jalr	-204(ra) # 80003a5e <iput>
  end_op();
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	7b2080e7          	jalr	1970(ra) # 800042e4 <end_op>
  p->cwd = ip;
    80005b3a:	14993823          	sd	s1,336(s2)
  return 0;
    80005b3e:	4501                	li	a0,0
}
    80005b40:	60ea                	ld	ra,152(sp)
    80005b42:	644a                	ld	s0,144(sp)
    80005b44:	64aa                	ld	s1,136(sp)
    80005b46:	690a                	ld	s2,128(sp)
    80005b48:	610d                	addi	sp,sp,160
    80005b4a:	8082                	ret
    end_op();
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	798080e7          	jalr	1944(ra) # 800042e4 <end_op>
    return -1;
    80005b54:	557d                	li	a0,-1
    80005b56:	b7ed                	j	80005b40 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b58:	8526                	mv	a0,s1
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	fac080e7          	jalr	-84(ra) # 80003b06 <iunlockput>
    end_op();
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	782080e7          	jalr	1922(ra) # 800042e4 <end_op>
    return -1;
    80005b6a:	557d                	li	a0,-1
    80005b6c:	bfd1                	j	80005b40 <sys_chdir+0x7a>

0000000080005b6e <sys_exec>:

uint64
sys_exec(void)
{
    80005b6e:	7145                	addi	sp,sp,-464
    80005b70:	e786                	sd	ra,456(sp)
    80005b72:	e3a2                	sd	s0,448(sp)
    80005b74:	ff26                	sd	s1,440(sp)
    80005b76:	fb4a                	sd	s2,432(sp)
    80005b78:	f74e                	sd	s3,424(sp)
    80005b7a:	f352                	sd	s4,416(sp)
    80005b7c:	ef56                	sd	s5,408(sp)
    80005b7e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b80:	08000613          	li	a2,128
    80005b84:	f4040593          	addi	a1,s0,-192
    80005b88:	4501                	li	a0,0
    80005b8a:	ffffd097          	auipc	ra,0xffffd
    80005b8e:	1c0080e7          	jalr	448(ra) # 80002d4a <argstr>
    return -1;
    80005b92:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b94:	0c054a63          	bltz	a0,80005c68 <sys_exec+0xfa>
    80005b98:	e3840593          	addi	a1,s0,-456
    80005b9c:	4505                	li	a0,1
    80005b9e:	ffffd097          	auipc	ra,0xffffd
    80005ba2:	18a080e7          	jalr	394(ra) # 80002d28 <argaddr>
    80005ba6:	0c054163          	bltz	a0,80005c68 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005baa:	10000613          	li	a2,256
    80005bae:	4581                	li	a1,0
    80005bb0:	e4040513          	addi	a0,s0,-448
    80005bb4:	ffffb097          	auipc	ra,0xffffb
    80005bb8:	144080e7          	jalr	324(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bbc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bc0:	89a6                	mv	s3,s1
    80005bc2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bc4:	02000a13          	li	s4,32
    80005bc8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bcc:	00391793          	slli	a5,s2,0x3
    80005bd0:	e3040593          	addi	a1,s0,-464
    80005bd4:	e3843503          	ld	a0,-456(s0)
    80005bd8:	953e                	add	a0,a0,a5
    80005bda:	ffffd097          	auipc	ra,0xffffd
    80005bde:	092080e7          	jalr	146(ra) # 80002c6c <fetchaddr>
    80005be2:	02054a63          	bltz	a0,80005c16 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005be6:	e3043783          	ld	a5,-464(s0)
    80005bea:	c3b9                	beqz	a5,80005c30 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bec:	ffffb097          	auipc	ra,0xffffb
    80005bf0:	f20080e7          	jalr	-224(ra) # 80000b0c <kalloc>
    80005bf4:	85aa                	mv	a1,a0
    80005bf6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bfa:	cd11                	beqz	a0,80005c16 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bfc:	6605                	lui	a2,0x1
    80005bfe:	e3043503          	ld	a0,-464(s0)
    80005c02:	ffffd097          	auipc	ra,0xffffd
    80005c06:	0bc080e7          	jalr	188(ra) # 80002cbe <fetchstr>
    80005c0a:	00054663          	bltz	a0,80005c16 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c0e:	0905                	addi	s2,s2,1
    80005c10:	09a1                	addi	s3,s3,8
    80005c12:	fb491be3          	bne	s2,s4,80005bc8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c16:	10048913          	addi	s2,s1,256
    80005c1a:	6088                	ld	a0,0(s1)
    80005c1c:	c529                	beqz	a0,80005c66 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c1e:	ffffb097          	auipc	ra,0xffffb
    80005c22:	df2080e7          	jalr	-526(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c26:	04a1                	addi	s1,s1,8
    80005c28:	ff2499e3          	bne	s1,s2,80005c1a <sys_exec+0xac>
  return -1;
    80005c2c:	597d                	li	s2,-1
    80005c2e:	a82d                	j	80005c68 <sys_exec+0xfa>
      argv[i] = 0;
    80005c30:	0a8e                	slli	s5,s5,0x3
    80005c32:	fc040793          	addi	a5,s0,-64
    80005c36:	9abe                	add	s5,s5,a5
    80005c38:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005c3c:	e4040593          	addi	a1,s0,-448
    80005c40:	f4040513          	addi	a0,s0,-192
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	178080e7          	jalr	376(ra) # 80004dbc <exec>
    80005c4c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c4e:	10048993          	addi	s3,s1,256
    80005c52:	6088                	ld	a0,0(s1)
    80005c54:	c911                	beqz	a0,80005c68 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c56:	ffffb097          	auipc	ra,0xffffb
    80005c5a:	dba080e7          	jalr	-582(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c5e:	04a1                	addi	s1,s1,8
    80005c60:	ff3499e3          	bne	s1,s3,80005c52 <sys_exec+0xe4>
    80005c64:	a011                	j	80005c68 <sys_exec+0xfa>
  return -1;
    80005c66:	597d                	li	s2,-1
}
    80005c68:	854a                	mv	a0,s2
    80005c6a:	60be                	ld	ra,456(sp)
    80005c6c:	641e                	ld	s0,448(sp)
    80005c6e:	74fa                	ld	s1,440(sp)
    80005c70:	795a                	ld	s2,432(sp)
    80005c72:	79ba                	ld	s3,424(sp)
    80005c74:	7a1a                	ld	s4,416(sp)
    80005c76:	6afa                	ld	s5,408(sp)
    80005c78:	6179                	addi	sp,sp,464
    80005c7a:	8082                	ret

0000000080005c7c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c7c:	7139                	addi	sp,sp,-64
    80005c7e:	fc06                	sd	ra,56(sp)
    80005c80:	f822                	sd	s0,48(sp)
    80005c82:	f426                	sd	s1,40(sp)
    80005c84:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c86:	ffffc097          	auipc	ra,0xffffc
    80005c8a:	e6c080e7          	jalr	-404(ra) # 80001af2 <myproc>
    80005c8e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c90:	fd840593          	addi	a1,s0,-40
    80005c94:	4501                	li	a0,0
    80005c96:	ffffd097          	auipc	ra,0xffffd
    80005c9a:	092080e7          	jalr	146(ra) # 80002d28 <argaddr>
    return -1;
    80005c9e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ca0:	0e054063          	bltz	a0,80005d80 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ca4:	fc840593          	addi	a1,s0,-56
    80005ca8:	fd040513          	addi	a0,s0,-48
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	de0080e7          	jalr	-544(ra) # 80004a8c <pipealloc>
    return -1;
    80005cb4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cb6:	0c054563          	bltz	a0,80005d80 <sys_pipe+0x104>
  fd0 = -1;
    80005cba:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cbe:	fd043503          	ld	a0,-48(s0)
    80005cc2:	fffff097          	auipc	ra,0xfffff
    80005cc6:	50a080e7          	jalr	1290(ra) # 800051cc <fdalloc>
    80005cca:	fca42223          	sw	a0,-60(s0)
    80005cce:	08054c63          	bltz	a0,80005d66 <sys_pipe+0xea>
    80005cd2:	fc843503          	ld	a0,-56(s0)
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	4f6080e7          	jalr	1270(ra) # 800051cc <fdalloc>
    80005cde:	fca42023          	sw	a0,-64(s0)
    80005ce2:	06054863          	bltz	a0,80005d52 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ce6:	4691                	li	a3,4
    80005ce8:	fc440613          	addi	a2,s0,-60
    80005cec:	fd843583          	ld	a1,-40(s0)
    80005cf0:	68a8                	ld	a0,80(s1)
    80005cf2:	ffffc097          	auipc	ra,0xffffc
    80005cf6:	9b8080e7          	jalr	-1608(ra) # 800016aa <copyout>
    80005cfa:	02054063          	bltz	a0,80005d1a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cfe:	4691                	li	a3,4
    80005d00:	fc040613          	addi	a2,s0,-64
    80005d04:	fd843583          	ld	a1,-40(s0)
    80005d08:	0591                	addi	a1,a1,4
    80005d0a:	68a8                	ld	a0,80(s1)
    80005d0c:	ffffc097          	auipc	ra,0xffffc
    80005d10:	99e080e7          	jalr	-1634(ra) # 800016aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d14:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d16:	06055563          	bgez	a0,80005d80 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d1a:	fc442783          	lw	a5,-60(s0)
    80005d1e:	07e9                	addi	a5,a5,26
    80005d20:	078e                	slli	a5,a5,0x3
    80005d22:	97a6                	add	a5,a5,s1
    80005d24:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d28:	fc042503          	lw	a0,-64(s0)
    80005d2c:	0569                	addi	a0,a0,26
    80005d2e:	050e                	slli	a0,a0,0x3
    80005d30:	9526                	add	a0,a0,s1
    80005d32:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d36:	fd043503          	ld	a0,-48(s0)
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	9fc080e7          	jalr	-1540(ra) # 80004736 <fileclose>
    fileclose(wf);
    80005d42:	fc843503          	ld	a0,-56(s0)
    80005d46:	fffff097          	auipc	ra,0xfffff
    80005d4a:	9f0080e7          	jalr	-1552(ra) # 80004736 <fileclose>
    return -1;
    80005d4e:	57fd                	li	a5,-1
    80005d50:	a805                	j	80005d80 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d52:	fc442783          	lw	a5,-60(s0)
    80005d56:	0007c863          	bltz	a5,80005d66 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d5a:	01a78513          	addi	a0,a5,26
    80005d5e:	050e                	slli	a0,a0,0x3
    80005d60:	9526                	add	a0,a0,s1
    80005d62:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d66:	fd043503          	ld	a0,-48(s0)
    80005d6a:	fffff097          	auipc	ra,0xfffff
    80005d6e:	9cc080e7          	jalr	-1588(ra) # 80004736 <fileclose>
    fileclose(wf);
    80005d72:	fc843503          	ld	a0,-56(s0)
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	9c0080e7          	jalr	-1600(ra) # 80004736 <fileclose>
    return -1;
    80005d7e:	57fd                	li	a5,-1
}
    80005d80:	853e                	mv	a0,a5
    80005d82:	70e2                	ld	ra,56(sp)
    80005d84:	7442                	ld	s0,48(sp)
    80005d86:	74a2                	ld	s1,40(sp)
    80005d88:	6121                	addi	sp,sp,64
    80005d8a:	8082                	ret
    80005d8c:	0000                	unimp
	...

0000000080005d90 <kernelvec>:
    80005d90:	7111                	addi	sp,sp,-256
    80005d92:	e006                	sd	ra,0(sp)
    80005d94:	e40a                	sd	sp,8(sp)
    80005d96:	e80e                	sd	gp,16(sp)
    80005d98:	ec12                	sd	tp,24(sp)
    80005d9a:	f016                	sd	t0,32(sp)
    80005d9c:	f41a                	sd	t1,40(sp)
    80005d9e:	f81e                	sd	t2,48(sp)
    80005da0:	fc22                	sd	s0,56(sp)
    80005da2:	e0a6                	sd	s1,64(sp)
    80005da4:	e4aa                	sd	a0,72(sp)
    80005da6:	e8ae                	sd	a1,80(sp)
    80005da8:	ecb2                	sd	a2,88(sp)
    80005daa:	f0b6                	sd	a3,96(sp)
    80005dac:	f4ba                	sd	a4,104(sp)
    80005dae:	f8be                	sd	a5,112(sp)
    80005db0:	fcc2                	sd	a6,120(sp)
    80005db2:	e146                	sd	a7,128(sp)
    80005db4:	e54a                	sd	s2,136(sp)
    80005db6:	e94e                	sd	s3,144(sp)
    80005db8:	ed52                	sd	s4,152(sp)
    80005dba:	f156                	sd	s5,160(sp)
    80005dbc:	f55a                	sd	s6,168(sp)
    80005dbe:	f95e                	sd	s7,176(sp)
    80005dc0:	fd62                	sd	s8,184(sp)
    80005dc2:	e1e6                	sd	s9,192(sp)
    80005dc4:	e5ea                	sd	s10,200(sp)
    80005dc6:	e9ee                	sd	s11,208(sp)
    80005dc8:	edf2                	sd	t3,216(sp)
    80005dca:	f1f6                	sd	t4,224(sp)
    80005dcc:	f5fa                	sd	t5,232(sp)
    80005dce:	f9fe                	sd	t6,240(sp)
    80005dd0:	d51fc0ef          	jal	ra,80002b20 <kerneltrap>
    80005dd4:	6082                	ld	ra,0(sp)
    80005dd6:	6122                	ld	sp,8(sp)
    80005dd8:	61c2                	ld	gp,16(sp)
    80005dda:	7282                	ld	t0,32(sp)
    80005ddc:	7322                	ld	t1,40(sp)
    80005dde:	73c2                	ld	t2,48(sp)
    80005de0:	7462                	ld	s0,56(sp)
    80005de2:	6486                	ld	s1,64(sp)
    80005de4:	6526                	ld	a0,72(sp)
    80005de6:	65c6                	ld	a1,80(sp)
    80005de8:	6666                	ld	a2,88(sp)
    80005dea:	7686                	ld	a3,96(sp)
    80005dec:	7726                	ld	a4,104(sp)
    80005dee:	77c6                	ld	a5,112(sp)
    80005df0:	7866                	ld	a6,120(sp)
    80005df2:	688a                	ld	a7,128(sp)
    80005df4:	692a                	ld	s2,136(sp)
    80005df6:	69ca                	ld	s3,144(sp)
    80005df8:	6a6a                	ld	s4,152(sp)
    80005dfa:	7a8a                	ld	s5,160(sp)
    80005dfc:	7b2a                	ld	s6,168(sp)
    80005dfe:	7bca                	ld	s7,176(sp)
    80005e00:	7c6a                	ld	s8,184(sp)
    80005e02:	6c8e                	ld	s9,192(sp)
    80005e04:	6d2e                	ld	s10,200(sp)
    80005e06:	6dce                	ld	s11,208(sp)
    80005e08:	6e6e                	ld	t3,216(sp)
    80005e0a:	7e8e                	ld	t4,224(sp)
    80005e0c:	7f2e                	ld	t5,232(sp)
    80005e0e:	7fce                	ld	t6,240(sp)
    80005e10:	6111                	addi	sp,sp,256
    80005e12:	10200073          	sret
    80005e16:	00000013          	nop
    80005e1a:	00000013          	nop
    80005e1e:	0001                	nop

0000000080005e20 <timervec>:
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	e10c                	sd	a1,0(a0)
    80005e26:	e510                	sd	a2,8(a0)
    80005e28:	e914                	sd	a3,16(a0)
    80005e2a:	710c                	ld	a1,32(a0)
    80005e2c:	7510                	ld	a2,40(a0)
    80005e2e:	6194                	ld	a3,0(a1)
    80005e30:	96b2                	add	a3,a3,a2
    80005e32:	e194                	sd	a3,0(a1)
    80005e34:	4589                	li	a1,2
    80005e36:	14459073          	csrw	sip,a1
    80005e3a:	6914                	ld	a3,16(a0)
    80005e3c:	6510                	ld	a2,8(a0)
    80005e3e:	610c                	ld	a1,0(a0)
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	30200073          	mret
	...

0000000080005e4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e4a:	1141                	addi	sp,sp,-16
    80005e4c:	e422                	sd	s0,8(sp)
    80005e4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e50:	0c0007b7          	lui	a5,0xc000
    80005e54:	4705                	li	a4,1
    80005e56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e58:	c3d8                	sw	a4,4(a5)
}
    80005e5a:	6422                	ld	s0,8(sp)
    80005e5c:	0141                	addi	sp,sp,16
    80005e5e:	8082                	ret

0000000080005e60 <plicinithart>:

void
plicinithart(void)
{
    80005e60:	1141                	addi	sp,sp,-16
    80005e62:	e406                	sd	ra,8(sp)
    80005e64:	e022                	sd	s0,0(sp)
    80005e66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	c5e080e7          	jalr	-930(ra) # 80001ac6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e70:	0085171b          	slliw	a4,a0,0x8
    80005e74:	0c0027b7          	lui	a5,0xc002
    80005e78:	97ba                	add	a5,a5,a4
    80005e7a:	40200713          	li	a4,1026
    80005e7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e82:	00d5151b          	slliw	a0,a0,0xd
    80005e86:	0c2017b7          	lui	a5,0xc201
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	00052023          	sw	zero,0(a0)
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret

0000000080005e98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e98:	1141                	addi	sp,sp,-16
    80005e9a:	e406                	sd	ra,8(sp)
    80005e9c:	e022                	sd	s0,0(sp)
    80005e9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	c26080e7          	jalr	-986(ra) # 80001ac6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ea8:	00d5179b          	slliw	a5,a0,0xd
    80005eac:	0c201537          	lui	a0,0xc201
    80005eb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005eb2:	4148                	lw	a0,4(a0)
    80005eb4:	60a2                	ld	ra,8(sp)
    80005eb6:	6402                	ld	s0,0(sp)
    80005eb8:	0141                	addi	sp,sp,16
    80005eba:	8082                	ret

0000000080005ebc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ebc:	1101                	addi	sp,sp,-32
    80005ebe:	ec06                	sd	ra,24(sp)
    80005ec0:	e822                	sd	s0,16(sp)
    80005ec2:	e426                	sd	s1,8(sp)
    80005ec4:	1000                	addi	s0,sp,32
    80005ec6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	bfe080e7          	jalr	-1026(ra) # 80001ac6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ed0:	00d5151b          	slliw	a0,a0,0xd
    80005ed4:	0c2017b7          	lui	a5,0xc201
    80005ed8:	97aa                	add	a5,a5,a0
    80005eda:	c3c4                	sw	s1,4(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret

0000000080005ee6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ee6:	1141                	addi	sp,sp,-16
    80005ee8:	e406                	sd	ra,8(sp)
    80005eea:	e022                	sd	s0,0(sp)
    80005eec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eee:	479d                	li	a5,7
    80005ef0:	04a7cc63          	blt	a5,a0,80005f48 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005ef4:	0001e797          	auipc	a5,0x1e
    80005ef8:	10c78793          	addi	a5,a5,268 # 80024000 <disk>
    80005efc:	00a78733          	add	a4,a5,a0
    80005f00:	6789                	lui	a5,0x2
    80005f02:	97ba                	add	a5,a5,a4
    80005f04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f08:	eba1                	bnez	a5,80005f58 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f0a:	00451713          	slli	a4,a0,0x4
    80005f0e:	00020797          	auipc	a5,0x20
    80005f12:	0f27b783          	ld	a5,242(a5) # 80026000 <disk+0x2000>
    80005f16:	97ba                	add	a5,a5,a4
    80005f18:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f1c:	0001e797          	auipc	a5,0x1e
    80005f20:	0e478793          	addi	a5,a5,228 # 80024000 <disk>
    80005f24:	97aa                	add	a5,a5,a0
    80005f26:	6509                	lui	a0,0x2
    80005f28:	953e                	add	a0,a0,a5
    80005f2a:	4785                	li	a5,1
    80005f2c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f30:	00020517          	auipc	a0,0x20
    80005f34:	0e850513          	addi	a0,a0,232 # 80026018 <disk+0x2018>
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	672080e7          	jalr	1650(ra) # 800025aa <wakeup>
}
    80005f40:	60a2                	ld	ra,8(sp)
    80005f42:	6402                	ld	s0,0(sp)
    80005f44:	0141                	addi	sp,sp,16
    80005f46:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f48:	00003517          	auipc	a0,0x3
    80005f4c:	86050513          	addi	a0,a0,-1952 # 800087a8 <syscalls+0x330>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	5f0080e7          	jalr	1520(ra) # 80000540 <panic>
    panic("virtio_disk_intr 2");
    80005f58:	00003517          	auipc	a0,0x3
    80005f5c:	86850513          	addi	a0,a0,-1944 # 800087c0 <syscalls+0x348>
    80005f60:	ffffa097          	auipc	ra,0xffffa
    80005f64:	5e0080e7          	jalr	1504(ra) # 80000540 <panic>

0000000080005f68 <virtio_disk_init>:
{
    80005f68:	1101                	addi	sp,sp,-32
    80005f6a:	ec06                	sd	ra,24(sp)
    80005f6c:	e822                	sd	s0,16(sp)
    80005f6e:	e426                	sd	s1,8(sp)
    80005f70:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f72:	00003597          	auipc	a1,0x3
    80005f76:	86658593          	addi	a1,a1,-1946 # 800087d8 <syscalls+0x360>
    80005f7a:	00020517          	auipc	a0,0x20
    80005f7e:	12e50513          	addi	a0,a0,302 # 800260a8 <disk+0x20a8>
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	bea080e7          	jalr	-1046(ra) # 80000b6c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f8a:	100017b7          	lui	a5,0x10001
    80005f8e:	4398                	lw	a4,0(a5)
    80005f90:	2701                	sext.w	a4,a4
    80005f92:	747277b7          	lui	a5,0x74727
    80005f96:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f9a:	0ef71163          	bne	a4,a5,8000607c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f9e:	100017b7          	lui	a5,0x10001
    80005fa2:	43dc                	lw	a5,4(a5)
    80005fa4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa6:	4705                	li	a4,1
    80005fa8:	0ce79a63          	bne	a5,a4,8000607c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fac:	100017b7          	lui	a5,0x10001
    80005fb0:	479c                	lw	a5,8(a5)
    80005fb2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fb4:	4709                	li	a4,2
    80005fb6:	0ce79363          	bne	a5,a4,8000607c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fba:	100017b7          	lui	a5,0x10001
    80005fbe:	47d8                	lw	a4,12(a5)
    80005fc0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fc2:	554d47b7          	lui	a5,0x554d4
    80005fc6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fca:	0af71963          	bne	a4,a5,8000607c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fce:	100017b7          	lui	a5,0x10001
    80005fd2:	4705                	li	a4,1
    80005fd4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd6:	470d                	li	a4,3
    80005fd8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fda:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fdc:	c7ffe737          	lui	a4,0xc7ffe
    80005fe0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80005fe4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fe6:	2701                	sext.w	a4,a4
    80005fe8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fea:	472d                	li	a4,11
    80005fec:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fee:	473d                	li	a4,15
    80005ff0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ff2:	6705                	lui	a4,0x1
    80005ff4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ff6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ffa:	5bdc                	lw	a5,52(a5)
    80005ffc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ffe:	c7d9                	beqz	a5,8000608c <virtio_disk_init+0x124>
  if(max < NUM)
    80006000:	471d                	li	a4,7
    80006002:	08f77d63          	bgeu	a4,a5,8000609c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006006:	100014b7          	lui	s1,0x10001
    8000600a:	47a1                	li	a5,8
    8000600c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000600e:	6609                	lui	a2,0x2
    80006010:	4581                	li	a1,0
    80006012:	0001e517          	auipc	a0,0x1e
    80006016:	fee50513          	addi	a0,a0,-18 # 80024000 <disk>
    8000601a:	ffffb097          	auipc	ra,0xffffb
    8000601e:	cde080e7          	jalr	-802(ra) # 80000cf8 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006022:	0001e717          	auipc	a4,0x1e
    80006026:	fde70713          	addi	a4,a4,-34 # 80024000 <disk>
    8000602a:	00c75793          	srli	a5,a4,0xc
    8000602e:	2781                	sext.w	a5,a5
    80006030:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006032:	00020797          	auipc	a5,0x20
    80006036:	fce78793          	addi	a5,a5,-50 # 80026000 <disk+0x2000>
    8000603a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000603c:	0001e717          	auipc	a4,0x1e
    80006040:	04470713          	addi	a4,a4,68 # 80024080 <disk+0x80>
    80006044:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006046:	0001f717          	auipc	a4,0x1f
    8000604a:	fba70713          	addi	a4,a4,-70 # 80025000 <disk+0x1000>
    8000604e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006050:	4705                	li	a4,1
    80006052:	00e78c23          	sb	a4,24(a5)
    80006056:	00e78ca3          	sb	a4,25(a5)
    8000605a:	00e78d23          	sb	a4,26(a5)
    8000605e:	00e78da3          	sb	a4,27(a5)
    80006062:	00e78e23          	sb	a4,28(a5)
    80006066:	00e78ea3          	sb	a4,29(a5)
    8000606a:	00e78f23          	sb	a4,30(a5)
    8000606e:	00e78fa3          	sb	a4,31(a5)
}
    80006072:	60e2                	ld	ra,24(sp)
    80006074:	6442                	ld	s0,16(sp)
    80006076:	64a2                	ld	s1,8(sp)
    80006078:	6105                	addi	sp,sp,32
    8000607a:	8082                	ret
    panic("could not find virtio disk");
    8000607c:	00002517          	auipc	a0,0x2
    80006080:	76c50513          	addi	a0,a0,1900 # 800087e8 <syscalls+0x370>
    80006084:	ffffa097          	auipc	ra,0xffffa
    80006088:	4bc080e7          	jalr	1212(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    8000608c:	00002517          	auipc	a0,0x2
    80006090:	77c50513          	addi	a0,a0,1916 # 80008808 <syscalls+0x390>
    80006094:	ffffa097          	auipc	ra,0xffffa
    80006098:	4ac080e7          	jalr	1196(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    8000609c:	00002517          	auipc	a0,0x2
    800060a0:	78c50513          	addi	a0,a0,1932 # 80008828 <syscalls+0x3b0>
    800060a4:	ffffa097          	auipc	ra,0xffffa
    800060a8:	49c080e7          	jalr	1180(ra) # 80000540 <panic>

00000000800060ac <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060ac:	7175                	addi	sp,sp,-144
    800060ae:	e506                	sd	ra,136(sp)
    800060b0:	e122                	sd	s0,128(sp)
    800060b2:	fca6                	sd	s1,120(sp)
    800060b4:	f8ca                	sd	s2,112(sp)
    800060b6:	f4ce                	sd	s3,104(sp)
    800060b8:	f0d2                	sd	s4,96(sp)
    800060ba:	ecd6                	sd	s5,88(sp)
    800060bc:	e8da                	sd	s6,80(sp)
    800060be:	e4de                	sd	s7,72(sp)
    800060c0:	e0e2                	sd	s8,64(sp)
    800060c2:	fc66                	sd	s9,56(sp)
    800060c4:	f86a                	sd	s10,48(sp)
    800060c6:	f46e                	sd	s11,40(sp)
    800060c8:	0900                	addi	s0,sp,144
    800060ca:	8aaa                	mv	s5,a0
    800060cc:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060ce:	00c52c83          	lw	s9,12(a0)
    800060d2:	001c9c9b          	slliw	s9,s9,0x1
    800060d6:	1c82                	slli	s9,s9,0x20
    800060d8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060dc:	00020517          	auipc	a0,0x20
    800060e0:	fcc50513          	addi	a0,a0,-52 # 800260a8 <disk+0x20a8>
    800060e4:	ffffb097          	auipc	ra,0xffffb
    800060e8:	b18080e7          	jalr	-1256(ra) # 80000bfc <acquire>
  for(int i = 0; i < 3; i++){
    800060ec:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060ee:	44a1                	li	s1,8
      disk.free[i] = 0;
    800060f0:	0001ec17          	auipc	s8,0x1e
    800060f4:	f10c0c13          	addi	s8,s8,-240 # 80024000 <disk>
    800060f8:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800060fa:	4b0d                	li	s6,3
    800060fc:	a0ad                	j	80006166 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800060fe:	00fc0733          	add	a4,s8,a5
    80006102:	975e                	add	a4,a4,s7
    80006104:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006108:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000610a:	0207c563          	bltz	a5,80006134 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000610e:	2905                	addiw	s2,s2,1
    80006110:	0611                	addi	a2,a2,4
    80006112:	19690d63          	beq	s2,s6,800062ac <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006116:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006118:	00020717          	auipc	a4,0x20
    8000611c:	f0070713          	addi	a4,a4,-256 # 80026018 <disk+0x2018>
    80006120:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006122:	00074683          	lbu	a3,0(a4)
    80006126:	fee1                	bnez	a3,800060fe <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006128:	2785                	addiw	a5,a5,1
    8000612a:	0705                	addi	a4,a4,1
    8000612c:	fe979be3          	bne	a5,s1,80006122 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006130:	57fd                	li	a5,-1
    80006132:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006134:	01205d63          	blez	s2,8000614e <virtio_disk_rw+0xa2>
    80006138:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000613a:	000a2503          	lw	a0,0(s4)
    8000613e:	00000097          	auipc	ra,0x0
    80006142:	da8080e7          	jalr	-600(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    80006146:	2d85                	addiw	s11,s11,1
    80006148:	0a11                	addi	s4,s4,4
    8000614a:	ffb918e3          	bne	s2,s11,8000613a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000614e:	00020597          	auipc	a1,0x20
    80006152:	f5a58593          	addi	a1,a1,-166 # 800260a8 <disk+0x20a8>
    80006156:	00020517          	auipc	a0,0x20
    8000615a:	ec250513          	addi	a0,a0,-318 # 80026018 <disk+0x2018>
    8000615e:	ffffc097          	auipc	ra,0xffffc
    80006162:	2b2080e7          	jalr	690(ra) # 80002410 <sleep>
  for(int i = 0; i < 3; i++){
    80006166:	f8040a13          	addi	s4,s0,-128
{
    8000616a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000616c:	894e                	mv	s2,s3
    8000616e:	b765                	j	80006116 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006170:	00020717          	auipc	a4,0x20
    80006174:	e9073703          	ld	a4,-368(a4) # 80026000 <disk+0x2000>
    80006178:	973e                	add	a4,a4,a5
    8000617a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000617e:	0001e517          	auipc	a0,0x1e
    80006182:	e8250513          	addi	a0,a0,-382 # 80024000 <disk>
    80006186:	00020717          	auipc	a4,0x20
    8000618a:	e7a70713          	addi	a4,a4,-390 # 80026000 <disk+0x2000>
    8000618e:	6314                	ld	a3,0(a4)
    80006190:	96be                	add	a3,a3,a5
    80006192:	00c6d603          	lhu	a2,12(a3)
    80006196:	00166613          	ori	a2,a2,1
    8000619a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000619e:	f8842683          	lw	a3,-120(s0)
    800061a2:	6310                	ld	a2,0(a4)
    800061a4:	97b2                	add	a5,a5,a2
    800061a6:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    800061aa:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    800061ae:	0612                	slli	a2,a2,0x4
    800061b0:	962a                	add	a2,a2,a0
    800061b2:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061b6:	00469793          	slli	a5,a3,0x4
    800061ba:	630c                	ld	a1,0(a4)
    800061bc:	95be                	add	a1,a1,a5
    800061be:	6689                	lui	a3,0x2
    800061c0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800061c4:	96ca                	add	a3,a3,s2
    800061c6:	96aa                	add	a3,a3,a0
    800061c8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800061ca:	6314                	ld	a3,0(a4)
    800061cc:	96be                	add	a3,a3,a5
    800061ce:	4585                	li	a1,1
    800061d0:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061d2:	6314                	ld	a3,0(a4)
    800061d4:	96be                	add	a3,a3,a5
    800061d6:	4509                	li	a0,2
    800061d8:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800061dc:	6314                	ld	a3,0(a4)
    800061de:	97b6                	add	a5,a5,a3
    800061e0:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061e4:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800061e8:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800061ec:	6714                	ld	a3,8(a4)
    800061ee:	0026d783          	lhu	a5,2(a3)
    800061f2:	8b9d                	andi	a5,a5,7
    800061f4:	0789                	addi	a5,a5,2
    800061f6:	0786                	slli	a5,a5,0x1
    800061f8:	97b6                	add	a5,a5,a3
    800061fa:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800061fe:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006202:	6718                	ld	a4,8(a4)
    80006204:	00275783          	lhu	a5,2(a4)
    80006208:	2785                	addiw	a5,a5,1
    8000620a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000620e:	100017b7          	lui	a5,0x10001
    80006212:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006216:	004aa783          	lw	a5,4(s5)
    8000621a:	02b79163          	bne	a5,a1,8000623c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000621e:	00020917          	auipc	s2,0x20
    80006222:	e8a90913          	addi	s2,s2,-374 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006226:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006228:	85ca                	mv	a1,s2
    8000622a:	8556                	mv	a0,s5
    8000622c:	ffffc097          	auipc	ra,0xffffc
    80006230:	1e4080e7          	jalr	484(ra) # 80002410 <sleep>
  while(b->disk == 1) {
    80006234:	004aa783          	lw	a5,4(s5)
    80006238:	fe9788e3          	beq	a5,s1,80006228 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000623c:	f8042483          	lw	s1,-128(s0)
    80006240:	20048793          	addi	a5,s1,512
    80006244:	00479713          	slli	a4,a5,0x4
    80006248:	0001e797          	auipc	a5,0x1e
    8000624c:	db878793          	addi	a5,a5,-584 # 80024000 <disk>
    80006250:	97ba                	add	a5,a5,a4
    80006252:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006256:	00020917          	auipc	s2,0x20
    8000625a:	daa90913          	addi	s2,s2,-598 # 80026000 <disk+0x2000>
    8000625e:	a019                	j	80006264 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006260:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006264:	8526                	mv	a0,s1
    80006266:	00000097          	auipc	ra,0x0
    8000626a:	c80080e7          	jalr	-896(ra) # 80005ee6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000626e:	0492                	slli	s1,s1,0x4
    80006270:	00093783          	ld	a5,0(s2)
    80006274:	94be                	add	s1,s1,a5
    80006276:	00c4d783          	lhu	a5,12(s1)
    8000627a:	8b85                	andi	a5,a5,1
    8000627c:	f3f5                	bnez	a5,80006260 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000627e:	00020517          	auipc	a0,0x20
    80006282:	e2a50513          	addi	a0,a0,-470 # 800260a8 <disk+0x20a8>
    80006286:	ffffb097          	auipc	ra,0xffffb
    8000628a:	a2a080e7          	jalr	-1494(ra) # 80000cb0 <release>
}
    8000628e:	60aa                	ld	ra,136(sp)
    80006290:	640a                	ld	s0,128(sp)
    80006292:	74e6                	ld	s1,120(sp)
    80006294:	7946                	ld	s2,112(sp)
    80006296:	79a6                	ld	s3,104(sp)
    80006298:	7a06                	ld	s4,96(sp)
    8000629a:	6ae6                	ld	s5,88(sp)
    8000629c:	6b46                	ld	s6,80(sp)
    8000629e:	6ba6                	ld	s7,72(sp)
    800062a0:	6c06                	ld	s8,64(sp)
    800062a2:	7ce2                	ld	s9,56(sp)
    800062a4:	7d42                	ld	s10,48(sp)
    800062a6:	7da2                	ld	s11,40(sp)
    800062a8:	6149                	addi	sp,sp,144
    800062aa:	8082                	ret
  if(write)
    800062ac:	01a037b3          	snez	a5,s10
    800062b0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800062b4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800062b8:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800062bc:	f8042483          	lw	s1,-128(s0)
    800062c0:	00449913          	slli	s2,s1,0x4
    800062c4:	00020997          	auipc	s3,0x20
    800062c8:	d3c98993          	addi	s3,s3,-708 # 80026000 <disk+0x2000>
    800062cc:	0009ba03          	ld	s4,0(s3)
    800062d0:	9a4a                	add	s4,s4,s2
    800062d2:	f7040513          	addi	a0,s0,-144
    800062d6:	ffffb097          	auipc	ra,0xffffb
    800062da:	de2080e7          	jalr	-542(ra) # 800010b8 <kvmpa>
    800062de:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800062e2:	0009b783          	ld	a5,0(s3)
    800062e6:	97ca                	add	a5,a5,s2
    800062e8:	4741                	li	a4,16
    800062ea:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062ec:	0009b783          	ld	a5,0(s3)
    800062f0:	97ca                	add	a5,a5,s2
    800062f2:	4705                	li	a4,1
    800062f4:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800062f8:	f8442783          	lw	a5,-124(s0)
    800062fc:	0009b703          	ld	a4,0(s3)
    80006300:	974a                	add	a4,a4,s2
    80006302:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006306:	0792                	slli	a5,a5,0x4
    80006308:	0009b703          	ld	a4,0(s3)
    8000630c:	973e                	add	a4,a4,a5
    8000630e:	058a8693          	addi	a3,s5,88
    80006312:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006314:	0009b703          	ld	a4,0(s3)
    80006318:	973e                	add	a4,a4,a5
    8000631a:	40000693          	li	a3,1024
    8000631e:	c714                	sw	a3,8(a4)
  if(write)
    80006320:	e40d18e3          	bnez	s10,80006170 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006324:	00020717          	auipc	a4,0x20
    80006328:	cdc73703          	ld	a4,-804(a4) # 80026000 <disk+0x2000>
    8000632c:	973e                	add	a4,a4,a5
    8000632e:	4689                	li	a3,2
    80006330:	00d71623          	sh	a3,12(a4)
    80006334:	b5a9                	j	8000617e <virtio_disk_rw+0xd2>

0000000080006336 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006336:	1101                	addi	sp,sp,-32
    80006338:	ec06                	sd	ra,24(sp)
    8000633a:	e822                	sd	s0,16(sp)
    8000633c:	e426                	sd	s1,8(sp)
    8000633e:	e04a                	sd	s2,0(sp)
    80006340:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006342:	00020517          	auipc	a0,0x20
    80006346:	d6650513          	addi	a0,a0,-666 # 800260a8 <disk+0x20a8>
    8000634a:	ffffb097          	auipc	ra,0xffffb
    8000634e:	8b2080e7          	jalr	-1870(ra) # 80000bfc <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006352:	00020717          	auipc	a4,0x20
    80006356:	cae70713          	addi	a4,a4,-850 # 80026000 <disk+0x2000>
    8000635a:	02075783          	lhu	a5,32(a4)
    8000635e:	6b18                	ld	a4,16(a4)
    80006360:	00275683          	lhu	a3,2(a4)
    80006364:	8ebd                	xor	a3,a3,a5
    80006366:	8a9d                	andi	a3,a3,7
    80006368:	cab9                	beqz	a3,800063be <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000636a:	0001e917          	auipc	s2,0x1e
    8000636e:	c9690913          	addi	s2,s2,-874 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006372:	00020497          	auipc	s1,0x20
    80006376:	c8e48493          	addi	s1,s1,-882 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000637a:	078e                	slli	a5,a5,0x3
    8000637c:	97ba                	add	a5,a5,a4
    8000637e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006380:	20078713          	addi	a4,a5,512
    80006384:	0712                	slli	a4,a4,0x4
    80006386:	974a                	add	a4,a4,s2
    80006388:	03074703          	lbu	a4,48(a4)
    8000638c:	ef21                	bnez	a4,800063e4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000638e:	20078793          	addi	a5,a5,512
    80006392:	0792                	slli	a5,a5,0x4
    80006394:	97ca                	add	a5,a5,s2
    80006396:	7798                	ld	a4,40(a5)
    80006398:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000639c:	7788                	ld	a0,40(a5)
    8000639e:	ffffc097          	auipc	ra,0xffffc
    800063a2:	20c080e7          	jalr	524(ra) # 800025aa <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063a6:	0204d783          	lhu	a5,32(s1)
    800063aa:	2785                	addiw	a5,a5,1
    800063ac:	8b9d                	andi	a5,a5,7
    800063ae:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063b2:	6898                	ld	a4,16(s1)
    800063b4:	00275683          	lhu	a3,2(a4)
    800063b8:	8a9d                	andi	a3,a3,7
    800063ba:	fcf690e3          	bne	a3,a5,8000637a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063be:	10001737          	lui	a4,0x10001
    800063c2:	533c                	lw	a5,96(a4)
    800063c4:	8b8d                	andi	a5,a5,3
    800063c6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800063c8:	00020517          	auipc	a0,0x20
    800063cc:	ce050513          	addi	a0,a0,-800 # 800260a8 <disk+0x20a8>
    800063d0:	ffffb097          	auipc	ra,0xffffb
    800063d4:	8e0080e7          	jalr	-1824(ra) # 80000cb0 <release>
}
    800063d8:	60e2                	ld	ra,24(sp)
    800063da:	6442                	ld	s0,16(sp)
    800063dc:	64a2                	ld	s1,8(sp)
    800063de:	6902                	ld	s2,0(sp)
    800063e0:	6105                	addi	sp,sp,32
    800063e2:	8082                	ret
      panic("virtio_disk_intr status");
    800063e4:	00002517          	auipc	a0,0x2
    800063e8:	46450513          	addi	a0,a0,1124 # 80008848 <syscalls+0x3d0>
    800063ec:	ffffa097          	auipc	ra,0xffffa
    800063f0:	154080e7          	jalr	340(ra) # 80000540 <panic>
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
