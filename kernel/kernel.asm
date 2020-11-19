
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
    80000128:	5c8080e7          	jalr	1480(ra) # 800026ec <either_copyin>
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
    800001cc:	90a080e7          	jalr	-1782(ra) # 80001ad2 <myproc>
    800001d0:	591c                	lw	a5,48(a0)
    800001d2:	e7b5                	bnez	a5,8000023e <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d4:	85a6                	mv	a1,s1
    800001d6:	854a                	mv	a0,s2
    800001d8:	00002097          	auipc	ra,0x2
    800001dc:	22e080e7          	jalr	558(ra) # 80002406 <sleep>
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
    80000218:	482080e7          	jalr	1154(ra) # 80002696 <either_copyout>
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
    800002f8:	44e080e7          	jalr	1102(ra) # 80002742 <procdump>
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
    8000044c:	158080e7          	jalr	344(ra) # 800025a0 <wakeup>
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
    800008a4:	d00080e7          	jalr	-768(ra) # 800025a0 <wakeup>
    
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
    8000093e:	acc080e7          	jalr	-1332(ra) # 80002406 <sleep>
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
    80000b9a:	f20080e7          	jalr	-224(ra) # 80001ab6 <mycpu>
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
    80000bcc:	eee080e7          	jalr	-274(ra) # 80001ab6 <mycpu>
    80000bd0:	5d3c                	lw	a5,120(a0)
    80000bd2:	cf89                	beqz	a5,80000bec <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	ee2080e7          	jalr	-286(ra) # 80001ab6 <mycpu>
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
    80000bf0:	eca080e7          	jalr	-310(ra) # 80001ab6 <mycpu>
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
    80000c30:	e8a080e7          	jalr	-374(ra) # 80001ab6 <mycpu>
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
    80000c5c:	e5e080e7          	jalr	-418(ra) # 80001ab6 <mycpu>
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
    80000eb2:	bf8080e7          	jalr	-1032(ra) # 80001aa6 <cpuid>
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
    80000ece:	bdc080e7          	jalr	-1060(ra) # 80001aa6 <cpuid>
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
    80000ef0:	998080e7          	jalr	-1640(ra) # 80002884 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef4:	00005097          	auipc	ra,0x5
    80000ef8:	f6c080e7          	jalr	-148(ra) # 80005e60 <plicinithart>
  }

  scheduler();        
    80000efc:	00001097          	auipc	ra,0x1
    80000f00:	192080e7          	jalr	402(ra) # 8000208e <scheduler>
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
    80000f50:	a8a080e7          	jalr	-1398(ra) # 800019d6 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	908080e7          	jalr	-1784(ra) # 8000285c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	928080e7          	jalr	-1752(ra) # 80002884 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	ee6080e7          	jalr	-282(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	ef4080e7          	jalr	-268(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	094080e7          	jalr	148(ra) # 80003008 <binit>
    iinit();         // inode cache
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	726080e7          	jalr	1830(ra) # 800036a2 <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	6c4080e7          	jalr	1732(ra) # 80004648 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	fdc080e7          	jalr	-36(ra) # 80005f68 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	e78080e7          	jalr	-392(ra) # 80001e0c <userinit>
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
    8000187e:	17852783          	lw	a5,376(a0)
    80001882:	17452703          	lw	a4,372(a0)
    80001886:	9f99                	subw	a5,a5,a4
  p->Qtime[0] = total - (p->Qtime[2] + p->Qtime[1]);
    80001888:	17052703          	lw	a4,368(a0)
    8000188c:	16c52683          	lw	a3,364(a0)
    80001890:	9f35                	addw	a4,a4,a3
    80001892:	9f99                	subw	a5,a5,a4
    80001894:	16f52423          	sw	a5,360(a0)

  // p->Qtime[2] = p->Qtime[2] * 100 / total;
  // p->Qtime[1] = p->Qtime[1] * 100 / total;
  // p->Qtime[0] = p->Qtime[0] * 100 / total;
}
    80001898:	6422                	ld	s0,8(sp)
    8000189a:	0141                	addi	sp,sp,16
    8000189c:	8082                	ret

000000008000189e <findproc>:

// find where 'obj' process resides in
// the Q[priority] queue
int findproc(struct proc *obj, int priority)
{
    8000189e:	1141                	addi	sp,sp,-16
    800018a0:	e422                	sd	s0,8(sp)
    800018a2:	0800                	addi	s0,sp,16
  int index = 0;
  while (1)
  {
    if (Q[priority][index] == obj)
    800018a4:	00959713          	slli	a4,a1,0x9
    800018a8:	00010797          	auipc	a5,0x10
    800018ac:	0a878793          	addi	a5,a5,168 # 80011950 <Q>
    800018b0:	97ba                	add	a5,a5,a4
    800018b2:	639c                	ld	a5,0(a5)
    800018b4:	02f50263          	beq	a0,a5,800018d8 <findproc+0x3a>
    800018b8:	86aa                	mv	a3,a0
    800018ba:	00010797          	auipc	a5,0x10
    800018be:	09e78793          	addi	a5,a5,158 # 80011958 <Q+0x8>
    800018c2:	97ba                	add	a5,a5,a4
  int index = 0;
    800018c4:	4501                	li	a0,0
      break;
    index++;
    800018c6:	2505                	addiw	a0,a0,1
    if (Q[priority][index] == obj)
    800018c8:	07a1                	addi	a5,a5,8
    800018ca:	ff87b703          	ld	a4,-8(a5)
    800018ce:	fed71ce3          	bne	a4,a3,800018c6 <findproc+0x28>
  }
  return index;
}
    800018d2:	6422                	ld	s0,8(sp)
    800018d4:	0141                	addi	sp,sp,16
    800018d6:	8082                	ret
  int index = 0;
    800018d8:	4501                	li	a0,0
    800018da:	bfe5                	j	800018d2 <findproc+0x34>

00000000800018dc <movequeue>:

// handle process change
void movequeue(struct proc *obj, int priority, int opt)
{
    800018dc:	7179                	addi	sp,sp,-48
    800018de:	f406                	sd	ra,40(sp)
    800018e0:	f022                	sd	s0,32(sp)
    800018e2:	ec26                	sd	s1,24(sp)
    800018e4:	e84a                	sd	s2,16(sp)
    800018e6:	e44e                	sd	s3,8(sp)
    800018e8:	1800                	addi	s0,sp,48
    800018ea:	84aa                	mv	s1,a0
    800018ec:	892e                	mv	s2,a1
  // INSERT means pushing process to empty process
  // so doesn't need to handle this operation
  if (opt != INSERT)
    800018ee:	4785                	li	a5,1
    800018f0:	06f60163          	beq	a2,a5,80001952 <movequeue+0x76>
    800018f4:	89b2                	mv	s3,a2
  {
    // delete the obj process from queue where it was in
    // and pull up the processes behind
    // obj process is in Q[obj.priority][pos]
    int pos = findproc(obj, obj->priority);
    800018f6:	17c52583          	lw	a1,380(a0)
    800018fa:	00000097          	auipc	ra,0x0
    800018fe:	fa4080e7          	jalr	-92(ra) # 8000189e <findproc>
    for (int i = pos; i < NPROC - 1; i++)
    80001902:	03e00793          	li	a5,62
    80001906:	02a7c863          	blt	a5,a0,80001936 <movequeue+0x5a>
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    8000190a:	00010697          	auipc	a3,0x10
    8000190e:	04668693          	addi	a3,a3,70 # 80011950 <Q>
    for (int i = pos; i < NPROC - 1; i++)
    80001912:	03f00593          	li	a1,63
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    80001916:	17c4a783          	lw	a5,380(s1)
    8000191a:	862a                	mv	a2,a0
    8000191c:	2505                	addiw	a0,a0,1
    8000191e:	079a                	slli	a5,a5,0x6
    80001920:	00a78733          	add	a4,a5,a0
    80001924:	070e                	slli	a4,a4,0x3
    80001926:	9736                	add	a4,a4,a3
    80001928:	6318                	ld	a4,0(a4)
    8000192a:	97b2                	add	a5,a5,a2
    8000192c:	078e                	slli	a5,a5,0x3
    8000192e:	97b6                	add	a5,a5,a3
    80001930:	e398                	sd	a4,0(a5)
    for (int i = pos; i < NPROC - 1; i++)
    80001932:	feb512e3          	bne	a0,a1,80001916 <movequeue+0x3a>
    Q[obj->priority][NPROC - 1] = 0;
    80001936:	17c4a783          	lw	a5,380(s1)
    8000193a:	00979713          	slli	a4,a5,0x9
    8000193e:	00010797          	auipc	a5,0x10
    80001942:	01278793          	addi	a5,a5,18 # 80011950 <Q>
    80001946:	97ba                	add	a5,a5,a4
    80001948:	1e07bc23          	sd	zero,504(a5)
  }

  // DELETE means just delete the process from all Qs,
  // so doesn't have to handle this operation
  if (opt != DELETE)
    8000194c:	4789                	li	a5,2
    8000194e:	02f98463          	beq	s3,a5,80001976 <movequeue+0x9a>
  {
    // insert obj process in another queue. insertback
    // endstart indicates the position right after the tail
    // which can be found by finding NULL process in the queue
    int endstart = findproc(0, priority);
    80001952:	85ca                	mv	a1,s2
    80001954:	4501                	li	a0,0
    80001956:	00000097          	auipc	ra,0x0
    8000195a:	f48080e7          	jalr	-184(ra) # 8000189e <findproc>
    Q[priority][endstart] = obj;
    8000195e:	00691793          	slli	a5,s2,0x6
    80001962:	97aa                	add	a5,a5,a0
    80001964:	078e                	slli	a5,a5,0x3
    80001966:	00010717          	auipc	a4,0x10
    8000196a:	fea70713          	addi	a4,a4,-22 # 80011950 <Q>
    8000196e:	97ba                	add	a5,a5,a4
    80001970:	e384                	sd	s1,0(a5)
    obj->priority = priority;
    80001972:	1724ae23          	sw	s2,380(s1)
  }
}
    80001976:	70a2                	ld	ra,40(sp)
    80001978:	7402                	ld	s0,32(sp)
    8000197a:	64e2                	ld	s1,24(sp)
    8000197c:	6942                	ld	s2,16(sp)
    8000197e:	69a2                	ld	s3,8(sp)
    80001980:	6145                	addi	sp,sp,48
    80001982:	8082                	ret

0000000080001984 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001984:	1101                	addi	sp,sp,-32
    80001986:	ec06                	sd	ra,24(sp)
    80001988:	e822                	sd	s0,16(sp)
    8000198a:	e426                	sd	s1,8(sp)
    8000198c:	1000                	addi	s0,sp,32
    8000198e:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	1f2080e7          	jalr	498(ra) # 80000b82 <holding>
    80001998:	c909                	beqz	a0,800019aa <wakeup1+0x26>
    panic("wakeup1");
  if (p->chan == p && p->state == SLEEPING)
    8000199a:	749c                	ld	a5,40(s1)
    8000199c:	00978f63          	beq	a5,s1,800019ba <wakeup1+0x36>
  {
    p->state = RUNNABLE;
    // should be moved to Q2
    movequeue(p, 2, MOVE);
  }
}
    800019a0:	60e2                	ld	ra,24(sp)
    800019a2:	6442                	ld	s0,16(sp)
    800019a4:	64a2                	ld	s1,8(sp)
    800019a6:	6105                	addi	sp,sp,32
    800019a8:	8082                	ret
    panic("wakeup1");
    800019aa:	00007517          	auipc	a0,0x7
    800019ae:	83e50513          	addi	a0,a0,-1986 # 800081e8 <digits+0x1a8>
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	b8e080e7          	jalr	-1138(ra) # 80000540 <panic>
  if (p->chan == p && p->state == SLEEPING)
    800019ba:	4c98                	lw	a4,24(s1)
    800019bc:	4785                	li	a5,1
    800019be:	fef711e3          	bne	a4,a5,800019a0 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019c2:	4789                	li	a5,2
    800019c4:	cc9c                	sw	a5,24(s1)
    movequeue(p, 2, MOVE);
    800019c6:	4601                	li	a2,0
    800019c8:	4589                	li	a1,2
    800019ca:	8526                	mv	a0,s1
    800019cc:	00000097          	auipc	ra,0x0
    800019d0:	f10080e7          	jalr	-240(ra) # 800018dc <movequeue>
}
    800019d4:	b7f1                	j	800019a0 <wakeup1+0x1c>

00000000800019d6 <procinit>:
{
    800019d6:	715d                	addi	sp,sp,-80
    800019d8:	e486                	sd	ra,72(sp)
    800019da:	e0a2                	sd	s0,64(sp)
    800019dc:	fc26                	sd	s1,56(sp)
    800019de:	f84a                	sd	s2,48(sp)
    800019e0:	f44e                	sd	s3,40(sp)
    800019e2:	f052                	sd	s4,32(sp)
    800019e4:	ec56                	sd	s5,24(sp)
    800019e6:	e85a                	sd	s6,16(sp)
    800019e8:	e45e                	sd	s7,8(sp)
    800019ea:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800019ec:	00007597          	auipc	a1,0x7
    800019f0:	80458593          	addi	a1,a1,-2044 # 800081f0 <digits+0x1b0>
    800019f4:	00010517          	auipc	a0,0x10
    800019f8:	55c50513          	addi	a0,a0,1372 # 80011f50 <pid_lock>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	170080e7          	jalr	368(ra) # 80000b6c <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a04:	00011917          	auipc	s2,0x11
    80001a08:	96490913          	addi	s2,s2,-1692 # 80012368 <proc>
    initlock(&p->lock, "proc");
    80001a0c:	00006b97          	auipc	s7,0x6
    80001a10:	7ecb8b93          	addi	s7,s7,2028 # 800081f8 <digits+0x1b8>
    uint64 va = KSTACK((int)(p - proc));
    80001a14:	8b4a                	mv	s6,s2
    80001a16:	00006a97          	auipc	s5,0x6
    80001a1a:	5eaa8a93          	addi	s5,s5,1514 # 80008000 <etext>
    80001a1e:	040009b7          	lui	s3,0x4000
    80001a22:	19fd                	addi	s3,s3,-1
    80001a24:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a26:	00017a17          	auipc	s4,0x17
    80001a2a:	942a0a13          	addi	s4,s4,-1726 # 80018368 <tickslock>
    initlock(&p->lock, "proc");
    80001a2e:	85de                	mv	a1,s7
    80001a30:	854a                	mv	a0,s2
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	13a080e7          	jalr	314(ra) # 80000b6c <initlock>
    char *pa = kalloc();
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	0d2080e7          	jalr	210(ra) # 80000b0c <kalloc>
    80001a42:	85aa                	mv	a1,a0
    if (pa == 0)
    80001a44:	c929                	beqz	a0,80001a96 <procinit+0xc0>
    uint64 va = KSTACK((int)(p - proc));
    80001a46:	416904b3          	sub	s1,s2,s6
    80001a4a:	849d                	srai	s1,s1,0x7
    80001a4c:	000ab783          	ld	a5,0(s5)
    80001a50:	02f484b3          	mul	s1,s1,a5
    80001a54:	2485                	addiw	s1,s1,1
    80001a56:	00d4949b          	slliw	s1,s1,0xd
    80001a5a:	409984b3          	sub	s1,s3,s1
    kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a5e:	4699                	li	a3,6
    80001a60:	6605                	lui	a2,0x1
    80001a62:	8526                	mv	a0,s1
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	740080e7          	jalr	1856(ra) # 800011a4 <kvmmap>
    p->kstack = va;
    80001a6c:	04993023          	sd	s1,64(s2)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a70:	18090913          	addi	s2,s2,384
    80001a74:	fb491de3          	bne	s2,s4,80001a2e <procinit+0x58>
  kvminithart();
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	534080e7          	jalr	1332(ra) # 80000fac <kvminithart>
}
    80001a80:	60a6                	ld	ra,72(sp)
    80001a82:	6406                	ld	s0,64(sp)
    80001a84:	74e2                	ld	s1,56(sp)
    80001a86:	7942                	ld	s2,48(sp)
    80001a88:	79a2                	ld	s3,40(sp)
    80001a8a:	7a02                	ld	s4,32(sp)
    80001a8c:	6ae2                	ld	s5,24(sp)
    80001a8e:	6b42                	ld	s6,16(sp)
    80001a90:	6ba2                	ld	s7,8(sp)
    80001a92:	6161                	addi	sp,sp,80
    80001a94:	8082                	ret
      panic("kalloc");
    80001a96:	00006517          	auipc	a0,0x6
    80001a9a:	76a50513          	addi	a0,a0,1898 # 80008200 <digits+0x1c0>
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	aa2080e7          	jalr	-1374(ra) # 80000540 <panic>

0000000080001aa6 <cpuid>:
{
    80001aa6:	1141                	addi	sp,sp,-16
    80001aa8:	e422                	sd	s0,8(sp)
    80001aaa:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aac:	8512                	mv	a0,tp
}
    80001aae:	2501                	sext.w	a0,a0
    80001ab0:	6422                	ld	s0,8(sp)
    80001ab2:	0141                	addi	sp,sp,16
    80001ab4:	8082                	ret

0000000080001ab6 <mycpu>:
{
    80001ab6:	1141                	addi	sp,sp,-16
    80001ab8:	e422                	sd	s0,8(sp)
    80001aba:	0800                	addi	s0,sp,16
    80001abc:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001abe:	2781                	sext.w	a5,a5
    80001ac0:	079e                	slli	a5,a5,0x7
}
    80001ac2:	00010517          	auipc	a0,0x10
    80001ac6:	4a650513          	addi	a0,a0,1190 # 80011f68 <cpus>
    80001aca:	953e                	add	a0,a0,a5
    80001acc:	6422                	ld	s0,8(sp)
    80001ace:	0141                	addi	sp,sp,16
    80001ad0:	8082                	ret

0000000080001ad2 <myproc>:
{
    80001ad2:	1101                	addi	sp,sp,-32
    80001ad4:	ec06                	sd	ra,24(sp)
    80001ad6:	e822                	sd	s0,16(sp)
    80001ad8:	e426                	sd	s1,8(sp)
    80001ada:	1000                	addi	s0,sp,32
  push_off();
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	0d4080e7          	jalr	212(ra) # 80000bb0 <push_off>
    80001ae4:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001ae6:	2781                	sext.w	a5,a5
    80001ae8:	079e                	slli	a5,a5,0x7
    80001aea:	00010717          	auipc	a4,0x10
    80001aee:	e6670713          	addi	a4,a4,-410 # 80011950 <Q>
    80001af2:	97ba                	add	a5,a5,a4
    80001af4:	6187b483          	ld	s1,1560(a5)
  pop_off();
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	158080e7          	jalr	344(ra) # 80000c50 <pop_off>
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
    80001b18:	fbe080e7          	jalr	-66(ra) # 80001ad2 <myproc>
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	194080e7          	jalr	404(ra) # 80000cb0 <release>
  if (first)
    80001b24:	00007797          	auipc	a5,0x7
    80001b28:	d3c7a783          	lw	a5,-708(a5) # 80008860 <first.1>
    80001b2c:	eb89                	bnez	a5,80001b3e <forkret+0x32>
  usertrapret();
    80001b2e:	00001097          	auipc	ra,0x1
    80001b32:	d6e080e7          	jalr	-658(ra) # 8000289c <usertrapret>
}
    80001b36:	60a2                	ld	ra,8(sp)
    80001b38:	6402                	ld	s0,0(sp)
    80001b3a:	0141                	addi	sp,sp,16
    80001b3c:	8082                	ret
    first = 0;
    80001b3e:	00007797          	auipc	a5,0x7
    80001b42:	d207a123          	sw	zero,-734(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001b46:	4505                	li	a0,1
    80001b48:	00002097          	auipc	ra,0x2
    80001b4c:	ada080e7          	jalr	-1318(ra) # 80003622 <fsinit>
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
    80001b62:	3f290913          	addi	s2,s2,1010 # 80011f50 <pid_lock>
    80001b66:	854a                	mv	a0,s2
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	094080e7          	jalr	148(ra) # 80000bfc <acquire>
  pid = nextpid;
    80001b70:	00007797          	auipc	a5,0x7
    80001b74:	cf478793          	addi	a5,a5,-780 # 80008864 <nextpid>
    80001b78:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b7a:	0014871b          	addiw	a4,s1,1
    80001b7e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b80:	854a                	mv	a0,s2
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	12e080e7          	jalr	302(ra) # 80000cb0 <release>
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
    80001baa:	7cc080e7          	jalr	1996(ra) # 80001372 <uvmcreate>
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
    80001bca:	550080e7          	jalr	1360(ra) # 80001116 <mappages>
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
    80001be8:	532080e7          	jalr	1330(ra) # 80001116 <mappages>
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
    80001c06:	96c080e7          	jalr	-1684(ra) # 8000156e <uvmfree>
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
    80001c20:	692080e7          	jalr	1682(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001c24:	4581                	li	a1,0
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	946080e7          	jalr	-1722(ra) # 8000156e <uvmfree>
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
    80001c54:	65e080e7          	jalr	1630(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c58:	4681                	li	a3,0
    80001c5a:	4605                	li	a2,1
    80001c5c:	020005b7          	lui	a1,0x2000
    80001c60:	15fd                	addi	a1,a1,-1
    80001c62:	05b6                	slli	a1,a1,0xd
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	648080e7          	jalr	1608(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001c6e:	85ca                	mv	a1,s2
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	8fc080e7          	jalr	-1796(ra) # 8000156e <uvmfree>
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
  p->end = ticks;
    80001c92:	00007797          	auipc	a5,0x7
    80001c96:	38e7a783          	lw	a5,910(a5) # 80009020 <ticks>
    80001c9a:	16f52c23          	sw	a5,376(a0)
  getportion(p);
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	bda080e7          	jalr	-1062(ra) # 80001878 <getportion>
  printf("%s (pid=%d): Q2(%d%%), Q1(%d%%), Q0(%d%%)\n",
    80001ca6:	1684a783          	lw	a5,360(s1)
    80001caa:	16c4a703          	lw	a4,364(s1)
    80001cae:	1704a683          	lw	a3,368(s1)
    80001cb2:	5c90                	lw	a2,56(s1)
    80001cb4:	15848593          	addi	a1,s1,344
    80001cb8:	00006517          	auipc	a0,0x6
    80001cbc:	55050513          	addi	a0,a0,1360 # 80008208 <digits+0x1c8>
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	8ca080e7          	jalr	-1846(ra) # 8000058a <printf>
  if (p->trapframe)
    80001cc8:	6ca8                	ld	a0,88(s1)
    80001cca:	c509                	beqz	a0,80001cd4 <freeproc+0x4e>
    kfree((void *)p->trapframe);
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	d44080e7          	jalr	-700(ra) # 80000a10 <kfree>
  p->trapframe = 0;
    80001cd4:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001cd8:	68a8                	ld	a0,80(s1)
    80001cda:	c511                	beqz	a0,80001ce6 <freeproc+0x60>
    proc_freepagetable(p->pagetable, p->sz);
    80001cdc:	64ac                	ld	a1,72(s1)
    80001cde:	00000097          	auipc	ra,0x0
    80001ce2:	f56080e7          	jalr	-170(ra) # 80001c34 <proc_freepagetable>
  p->pagetable = 0;
    80001ce6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cea:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cee:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001cf2:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001cf6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cfa:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001cfe:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d02:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d06:	0004ac23          	sw	zero,24(s1)
  p->Qtime[2] = 0;
    80001d0a:	1604a823          	sw	zero,368(s1)
  p->Qtime[1] = 0;
    80001d0e:	1604a623          	sw	zero,364(s1)
  p->Qtime[0] = 0;
    80001d12:	1604a423          	sw	zero,360(s1)
  p->priority = 0;
    80001d16:	1604ae23          	sw	zero,380(s1)
  movequeue(p, 0, DELETE);
    80001d1a:	4609                	li	a2,2
    80001d1c:	4581                	li	a1,0
    80001d1e:	8526                	mv	a0,s1
    80001d20:	00000097          	auipc	ra,0x0
    80001d24:	bbc080e7          	jalr	-1092(ra) # 800018dc <movequeue>
}
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret

0000000080001d32 <allocproc>:
{
    80001d32:	1101                	addi	sp,sp,-32
    80001d34:	ec06                	sd	ra,24(sp)
    80001d36:	e822                	sd	s0,16(sp)
    80001d38:	e426                	sd	s1,8(sp)
    80001d3a:	e04a                	sd	s2,0(sp)
    80001d3c:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d3e:	00010497          	auipc	s1,0x10
    80001d42:	62a48493          	addi	s1,s1,1578 # 80012368 <proc>
    80001d46:	00016917          	auipc	s2,0x16
    80001d4a:	62290913          	addi	s2,s2,1570 # 80018368 <tickslock>
    acquire(&p->lock);
    80001d4e:	8526                	mv	a0,s1
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	eac080e7          	jalr	-340(ra) # 80000bfc <acquire>
    if (p->state == UNUSED)
    80001d58:	4c9c                	lw	a5,24(s1)
    80001d5a:	cf81                	beqz	a5,80001d72 <allocproc+0x40>
      release(&p->lock);
    80001d5c:	8526                	mv	a0,s1
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	f52080e7          	jalr	-174(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d66:	18048493          	addi	s1,s1,384
    80001d6a:	ff2492e3          	bne	s1,s2,80001d4e <allocproc+0x1c>
  return 0;
    80001d6e:	4481                	li	s1,0
    80001d70:	a0a5                	j	80001dd8 <allocproc+0xa6>
  p->pid = allocpid();
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	de0080e7          	jalr	-544(ra) # 80001b52 <allocpid>
    80001d7a:	dc88                	sw	a0,56(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	d90080e7          	jalr	-624(ra) # 80000b0c <kalloc>
    80001d84:	892a                	mv	s2,a0
    80001d86:	eca8                	sd	a0,88(s1)
    80001d88:	cd39                	beqz	a0,80001de6 <allocproc+0xb4>
  p->pagetable = proc_pagetable(p);
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	e0c080e7          	jalr	-500(ra) # 80001b98 <proc_pagetable>
    80001d94:	892a                	mv	s2,a0
    80001d96:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d98:	cd31                	beqz	a0,80001df4 <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001d9a:	07000613          	li	a2,112
    80001d9e:	4581                	li	a1,0
    80001da0:	06048513          	addi	a0,s1,96
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	f54080e7          	jalr	-172(ra) # 80000cf8 <memset>
  p->context.ra = (uint64)forkret;
    80001dac:	00000797          	auipc	a5,0x0
    80001db0:	d6078793          	addi	a5,a5,-672 # 80001b0c <forkret>
    80001db4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001db6:	60bc                	ld	a5,64(s1)
    80001db8:	6705                	lui	a4,0x1
    80001dba:	97ba                	add	a5,a5,a4
    80001dbc:	f4bc                	sd	a5,104(s1)
  p->start = ticks;
    80001dbe:	00007797          	auipc	a5,0x7
    80001dc2:	2627a783          	lw	a5,610(a5) # 80009020 <ticks>
    80001dc6:	16f4aa23          	sw	a5,372(s1)
  movequeue(p, 2, INSERT);
    80001dca:	4605                	li	a2,1
    80001dcc:	4589                	li	a1,2
    80001dce:	8526                	mv	a0,s1
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	b0c080e7          	jalr	-1268(ra) # 800018dc <movequeue>
}
    80001dd8:	8526                	mv	a0,s1
    80001dda:	60e2                	ld	ra,24(sp)
    80001ddc:	6442                	ld	s0,16(sp)
    80001dde:	64a2                	ld	s1,8(sp)
    80001de0:	6902                	ld	s2,0(sp)
    80001de2:	6105                	addi	sp,sp,32
    80001de4:	8082                	ret
    release(&p->lock);
    80001de6:	8526                	mv	a0,s1
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	ec8080e7          	jalr	-312(ra) # 80000cb0 <release>
    return 0;
    80001df0:	84ca                	mv	s1,s2
    80001df2:	b7dd                	j	80001dd8 <allocproc+0xa6>
    freeproc(p);
    80001df4:	8526                	mv	a0,s1
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	e90080e7          	jalr	-368(ra) # 80001c86 <freeproc>
    release(&p->lock);
    80001dfe:	8526                	mv	a0,s1
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	eb0080e7          	jalr	-336(ra) # 80000cb0 <release>
    return 0;
    80001e08:	84ca                	mv	s1,s2
    80001e0a:	b7f9                	j	80001dd8 <allocproc+0xa6>

0000000080001e0c <userinit>:
{
    80001e0c:	1101                	addi	sp,sp,-32
    80001e0e:	ec06                	sd	ra,24(sp)
    80001e10:	e822                	sd	s0,16(sp)
    80001e12:	e426                	sd	s1,8(sp)
    80001e14:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	f1c080e7          	jalr	-228(ra) # 80001d32 <allocproc>
    80001e1e:	84aa                	mv	s1,a0
  initproc = p;
    80001e20:	00007797          	auipc	a5,0x7
    80001e24:	1ea7bc23          	sd	a0,504(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e28:	03400613          	li	a2,52
    80001e2c:	00007597          	auipc	a1,0x7
    80001e30:	a4458593          	addi	a1,a1,-1468 # 80008870 <initcode>
    80001e34:	6928                	ld	a0,80(a0)
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	56a080e7          	jalr	1386(ra) # 800013a0 <uvminit>
  p->sz = PGSIZE;
    80001e3e:	6785                	lui	a5,0x1
    80001e40:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e42:	6cb8                	ld	a4,88(s1)
    80001e44:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e48:	6cb8                	ld	a4,88(s1)
    80001e4a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e4c:	4641                	li	a2,16
    80001e4e:	00006597          	auipc	a1,0x6
    80001e52:	3ea58593          	addi	a1,a1,1002 # 80008238 <digits+0x1f8>
    80001e56:	15848513          	addi	a0,s1,344
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	ff0080e7          	jalr	-16(ra) # 80000e4a <safestrcpy>
  p->cwd = namei("/");
    80001e62:	00006517          	auipc	a0,0x6
    80001e66:	3e650513          	addi	a0,a0,998 # 80008248 <digits+0x208>
    80001e6a:	00002097          	auipc	ra,0x2
    80001e6e:	1e0080e7          	jalr	480(ra) # 8000404a <namei>
    80001e72:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e76:	4789                	li	a5,2
    80001e78:	cc9c                	sw	a5,24(s1)
  p->Qtime[2] = 0;
    80001e7a:	1604a823          	sw	zero,368(s1)
  p->Qtime[1] = 0;
    80001e7e:	1604a623          	sw	zero,364(s1)
  p->Qtime[0] = 0;
    80001e82:	1604a423          	sw	zero,360(s1)
  release(&p->lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e28080e7          	jalr	-472(ra) # 80000cb0 <release>
}
    80001e90:	60e2                	ld	ra,24(sp)
    80001e92:	6442                	ld	s0,16(sp)
    80001e94:	64a2                	ld	s1,8(sp)
    80001e96:	6105                	addi	sp,sp,32
    80001e98:	8082                	ret

0000000080001e9a <growproc>:
{
    80001e9a:	1101                	addi	sp,sp,-32
    80001e9c:	ec06                	sd	ra,24(sp)
    80001e9e:	e822                	sd	s0,16(sp)
    80001ea0:	e426                	sd	s1,8(sp)
    80001ea2:	e04a                	sd	s2,0(sp)
    80001ea4:	1000                	addi	s0,sp,32
    80001ea6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	c2a080e7          	jalr	-982(ra) # 80001ad2 <myproc>
    80001eb0:	892a                	mv	s2,a0
  sz = p->sz;
    80001eb2:	652c                	ld	a1,72(a0)
    80001eb4:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001eb8:	00904f63          	bgtz	s1,80001ed6 <growproc+0x3c>
  else if (n < 0)
    80001ebc:	0204cc63          	bltz	s1,80001ef4 <growproc+0x5a>
  p->sz = sz;
    80001ec0:	1602                	slli	a2,a2,0x20
    80001ec2:	9201                	srli	a2,a2,0x20
    80001ec4:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ec8:	4501                	li	a0,0
}
    80001eca:	60e2                	ld	ra,24(sp)
    80001ecc:	6442                	ld	s0,16(sp)
    80001ece:	64a2                	ld	s1,8(sp)
    80001ed0:	6902                	ld	s2,0(sp)
    80001ed2:	6105                	addi	sp,sp,32
    80001ed4:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001ed6:	9e25                	addw	a2,a2,s1
    80001ed8:	1602                	slli	a2,a2,0x20
    80001eda:	9201                	srli	a2,a2,0x20
    80001edc:	1582                	slli	a1,a1,0x20
    80001ede:	9181                	srli	a1,a1,0x20
    80001ee0:	6928                	ld	a0,80(a0)
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	578080e7          	jalr	1400(ra) # 8000145a <uvmalloc>
    80001eea:	0005061b          	sext.w	a2,a0
    80001eee:	fa69                	bnez	a2,80001ec0 <growproc+0x26>
      return -1;
    80001ef0:	557d                	li	a0,-1
    80001ef2:	bfe1                	j	80001eca <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ef4:	9e25                	addw	a2,a2,s1
    80001ef6:	1602                	slli	a2,a2,0x20
    80001ef8:	9201                	srli	a2,a2,0x20
    80001efa:	1582                	slli	a1,a1,0x20
    80001efc:	9181                	srli	a1,a1,0x20
    80001efe:	6928                	ld	a0,80(a0)
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	512080e7          	jalr	1298(ra) # 80001412 <uvmdealloc>
    80001f08:	0005061b          	sext.w	a2,a0
    80001f0c:	bf55                	j	80001ec0 <growproc+0x26>

0000000080001f0e <fork>:
{
    80001f0e:	7139                	addi	sp,sp,-64
    80001f10:	fc06                	sd	ra,56(sp)
    80001f12:	f822                	sd	s0,48(sp)
    80001f14:	f426                	sd	s1,40(sp)
    80001f16:	f04a                	sd	s2,32(sp)
    80001f18:	ec4e                	sd	s3,24(sp)
    80001f1a:	e852                	sd	s4,16(sp)
    80001f1c:	e456                	sd	s5,8(sp)
    80001f1e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f20:	00000097          	auipc	ra,0x0
    80001f24:	bb2080e7          	jalr	-1102(ra) # 80001ad2 <myproc>
    80001f28:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f2a:	00000097          	auipc	ra,0x0
    80001f2e:	e08080e7          	jalr	-504(ra) # 80001d32 <allocproc>
    80001f32:	c96d                	beqz	a0,80002024 <fork+0x116>
    80001f34:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f36:	048ab603          	ld	a2,72(s5)
    80001f3a:	692c                	ld	a1,80(a0)
    80001f3c:	050ab503          	ld	a0,80(s5)
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	666080e7          	jalr	1638(ra) # 800015a6 <uvmcopy>
    80001f48:	04054a63          	bltz	a0,80001f9c <fork+0x8e>
  np->sz = p->sz;
    80001f4c:	048ab783          	ld	a5,72(s5)
    80001f50:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f54:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f58:	058ab683          	ld	a3,88(s5)
    80001f5c:	87b6                	mv	a5,a3
    80001f5e:	0589b703          	ld	a4,88(s3)
    80001f62:	12068693          	addi	a3,a3,288
    80001f66:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f6a:	6788                	ld	a0,8(a5)
    80001f6c:	6b8c                	ld	a1,16(a5)
    80001f6e:	6f90                	ld	a2,24(a5)
    80001f70:	01073023          	sd	a6,0(a4)
    80001f74:	e708                	sd	a0,8(a4)
    80001f76:	eb0c                	sd	a1,16(a4)
    80001f78:	ef10                	sd	a2,24(a4)
    80001f7a:	02078793          	addi	a5,a5,32
    80001f7e:	02070713          	addi	a4,a4,32
    80001f82:	fed792e3          	bne	a5,a3,80001f66 <fork+0x58>
  np->trapframe->a0 = 0;
    80001f86:	0589b783          	ld	a5,88(s3)
    80001f8a:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f8e:	0d0a8493          	addi	s1,s5,208
    80001f92:	0d098913          	addi	s2,s3,208
    80001f96:	150a8a13          	addi	s4,s5,336
    80001f9a:	a00d                	j	80001fbc <fork+0xae>
    freeproc(np);
    80001f9c:	854e                	mv	a0,s3
    80001f9e:	00000097          	auipc	ra,0x0
    80001fa2:	ce8080e7          	jalr	-792(ra) # 80001c86 <freeproc>
    release(&np->lock);
    80001fa6:	854e                	mv	a0,s3
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	d08080e7          	jalr	-760(ra) # 80000cb0 <release>
    return -1;
    80001fb0:	54fd                	li	s1,-1
    80001fb2:	a8b9                	j	80002010 <fork+0x102>
  for (i = 0; i < NOFILE; i++)
    80001fb4:	04a1                	addi	s1,s1,8
    80001fb6:	0921                	addi	s2,s2,8
    80001fb8:	01448b63          	beq	s1,s4,80001fce <fork+0xc0>
    if (p->ofile[i])
    80001fbc:	6088                	ld	a0,0(s1)
    80001fbe:	d97d                	beqz	a0,80001fb4 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fc0:	00002097          	auipc	ra,0x2
    80001fc4:	71a080e7          	jalr	1818(ra) # 800046da <filedup>
    80001fc8:	00a93023          	sd	a0,0(s2)
    80001fcc:	b7e5                	j	80001fb4 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001fce:	150ab503          	ld	a0,336(s5)
    80001fd2:	00002097          	auipc	ra,0x2
    80001fd6:	88a080e7          	jalr	-1910(ra) # 8000385c <idup>
    80001fda:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fde:	4641                	li	a2,16
    80001fe0:	158a8593          	addi	a1,s5,344
    80001fe4:	15898513          	addi	a0,s3,344
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	e62080e7          	jalr	-414(ra) # 80000e4a <safestrcpy>
  pid = np->pid;
    80001ff0:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ff4:	4789                	li	a5,2
    80001ff6:	00f9ac23          	sw	a5,24(s3)
  np->Qtime[2] = 0;
    80001ffa:	1609a823          	sw	zero,368(s3)
  np->Qtime[1] = 0;
    80001ffe:	1609a623          	sw	zero,364(s3)
  np->Qtime[0] = 0;
    80002002:	1609a423          	sw	zero,360(s3)
  release(&np->lock);
    80002006:	854e                	mv	a0,s3
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	ca8080e7          	jalr	-856(ra) # 80000cb0 <release>
}
    80002010:	8526                	mv	a0,s1
    80002012:	70e2                	ld	ra,56(sp)
    80002014:	7442                	ld	s0,48(sp)
    80002016:	74a2                	ld	s1,40(sp)
    80002018:	7902                	ld	s2,32(sp)
    8000201a:	69e2                	ld	s3,24(sp)
    8000201c:	6a42                	ld	s4,16(sp)
    8000201e:	6aa2                	ld	s5,8(sp)
    80002020:	6121                	addi	sp,sp,64
    80002022:	8082                	ret
    return -1;
    80002024:	54fd                	li	s1,-1
    80002026:	b7ed                	j	80002010 <fork+0x102>

0000000080002028 <reparent>:
{
    80002028:	7179                	addi	sp,sp,-48
    8000202a:	f406                	sd	ra,40(sp)
    8000202c:	f022                	sd	s0,32(sp)
    8000202e:	ec26                	sd	s1,24(sp)
    80002030:	e84a                	sd	s2,16(sp)
    80002032:	e44e                	sd	s3,8(sp)
    80002034:	e052                	sd	s4,0(sp)
    80002036:	1800                	addi	s0,sp,48
    80002038:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000203a:	00010497          	auipc	s1,0x10
    8000203e:	32e48493          	addi	s1,s1,814 # 80012368 <proc>
      pp->parent = initproc;
    80002042:	00007a17          	auipc	s4,0x7
    80002046:	fd6a0a13          	addi	s4,s4,-42 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000204a:	00016997          	auipc	s3,0x16
    8000204e:	31e98993          	addi	s3,s3,798 # 80018368 <tickslock>
    80002052:	a029                	j	8000205c <reparent+0x34>
    80002054:	18048493          	addi	s1,s1,384
    80002058:	03348363          	beq	s1,s3,8000207e <reparent+0x56>
    if (pp->parent == p)
    8000205c:	709c                	ld	a5,32(s1)
    8000205e:	ff279be3          	bne	a5,s2,80002054 <reparent+0x2c>
      acquire(&pp->lock);
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	b98080e7          	jalr	-1128(ra) # 80000bfc <acquire>
      pp->parent = initproc;
    8000206c:	000a3783          	ld	a5,0(s4)
    80002070:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002072:	8526                	mv	a0,s1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	c3c080e7          	jalr	-964(ra) # 80000cb0 <release>
    8000207c:	bfe1                	j	80002054 <reparent+0x2c>
}
    8000207e:	70a2                	ld	ra,40(sp)
    80002080:	7402                	ld	s0,32(sp)
    80002082:	64e2                	ld	s1,24(sp)
    80002084:	6942                	ld	s2,16(sp)
    80002086:	69a2                	ld	s3,8(sp)
    80002088:	6a02                	ld	s4,0(sp)
    8000208a:	6145                	addi	sp,sp,48
    8000208c:	8082                	ret

000000008000208e <scheduler>:
{
    8000208e:	711d                	addi	sp,sp,-96
    80002090:	ec86                	sd	ra,88(sp)
    80002092:	e8a2                	sd	s0,80(sp)
    80002094:	e4a6                	sd	s1,72(sp)
    80002096:	e0ca                	sd	s2,64(sp)
    80002098:	fc4e                	sd	s3,56(sp)
    8000209a:	f852                	sd	s4,48(sp)
    8000209c:	f456                	sd	s5,40(sp)
    8000209e:	f05a                	sd	s6,32(sp)
    800020a0:	ec5e                	sd	s7,24(sp)
    800020a2:	e862                	sd	s8,16(sp)
    800020a4:	e466                	sd	s9,8(sp)
    800020a6:	e06a                	sd	s10,0(sp)
    800020a8:	1080                	addi	s0,sp,96
    800020aa:	8792                	mv	a5,tp
  int id = r_tp();
    800020ac:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020ae:	00779b13          	slli	s6,a5,0x7
    800020b2:	00010717          	auipc	a4,0x10
    800020b6:	89e70713          	addi	a4,a4,-1890 # 80011950 <Q>
    800020ba:	975a                	add	a4,a4,s6
    800020bc:	60073c23          	sd	zero,1560(a4)
        swtch(&c->context, &p->context);
    800020c0:	00010717          	auipc	a4,0x10
    800020c4:	eb070713          	addi	a4,a4,-336 # 80011f70 <cpus+0x8>
    800020c8:	9b3a                	add	s6,s6,a4
  int exec = 0;
    800020ca:	4a81                	li	s5,0
    800020cc:	00010c97          	auipc	s9,0x10
    800020d0:	c8cc8c93          	addi	s9,s9,-884 # 80011d58 <Q+0x408>
        p->state = RUNNING;
    800020d4:	4b8d                	li	s7,3
        c->proc = p;
    800020d6:	00010c17          	auipc	s8,0x10
    800020da:	87ac0c13          	addi	s8,s8,-1926 # 80011950 <Q>
    800020de:	079e                	slli	a5,a5,0x7
    800020e0:	00fc0a33          	add	s4,s8,a5
    800020e4:	a88d                	j	80002156 <scheduler+0xc8>
      exec = 0;
    800020e6:	4a81                	li	s5,0
    800020e8:	a0bd                	j	80002156 <scheduler+0xc8>
      release(&p->lock);
    800020ea:	8526                	mv	a0,s1
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	bc4080e7          	jalr	-1084(ra) # 80000cb0 <release>
    for (int i = 0; i < Q2_tail; i++)
    800020f4:	0921                	addi	s2,s2,8
    800020f6:	03390b63          	beq	s2,s3,8000212c <scheduler+0x9e>
      p = Q[2][i];
    800020fa:	00093483          	ld	s1,0(s2)
      if (p == 0)
    800020fe:	c49d                	beqz	s1,8000212c <scheduler+0x9e>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	afa080e7          	jalr	-1286(ra) # 80000bfc <acquire>
      if (p->state == RUNNABLE)
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fda79fe3          	bne	a5,s10,800020ea <scheduler+0x5c>
        p->state = RUNNING;
    80002110:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002114:	609a3c23          	sd	s1,1560(s4)
        swtch(&c->context, &p->context);
    80002118:	06048593          	addi	a1,s1,96
    8000211c:	855a                	mv	a0,s6
    8000211e:	00000097          	auipc	ra,0x0
    80002122:	6d4080e7          	jalr	1748(ra) # 800027f2 <swtch>
        c->proc = 0;
    80002126:	600a3c23          	sd	zero,1560(s4)
    8000212a:	b7c1                	j	800020ea <scheduler+0x5c>
    p = Q[1][exec];
    8000212c:	040a8793          	addi	a5,s5,64
    80002130:	078e                	slli	a5,a5,0x3
    80002132:	97e2                	add	a5,a5,s8
    80002134:	6384                	ld	s1,0(a5)
    if (p == 0)
    80002136:	d8c5                	beqz	s1,800020e6 <scheduler+0x58>
    acquire(&p->lock);
    80002138:	8526                	mv	a0,s1
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	ac2080e7          	jalr	-1342(ra) # 80000bfc <acquire>
    if (p->state == RUNNABLE)
    80002142:	4c98                	lw	a4,24(s1)
    80002144:	4789                	li	a5,2
    80002146:	04f70363          	beq	a4,a5,8000218c <scheduler+0xfe>
    release(&p->lock);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b64080e7          	jalr	-1180(ra) # 80000cb0 <release>
    exec++;   
    80002154:	2a85                	addiw	s5,s5,1
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002156:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000215a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000215e:	10079073          	csrw	sstatus,a5
    int Q2_tail = findproc(0, 2);
    80002162:	4589                	li	a1,2
    80002164:	4501                	li	a0,0
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	738080e7          	jalr	1848(ra) # 8000189e <findproc>
    for (int i = 0; i < Q2_tail; i++)
    8000216e:	faa05fe3          	blez	a0,8000212c <scheduler+0x9e>
    80002172:	00010917          	auipc	s2,0x10
    80002176:	bde90913          	addi	s2,s2,-1058 # 80011d50 <Q+0x400>
    8000217a:	fff5099b          	addiw	s3,a0,-1
    8000217e:	02099793          	slli	a5,s3,0x20
    80002182:	01d7d993          	srli	s3,a5,0x1d
    80002186:	99e6                	add	s3,s3,s9
      if (p->state == RUNNABLE)
    80002188:	4d09                	li	s10,2
    8000218a:	bf85                	j	800020fa <scheduler+0x6c>
      p->state = RUNNING;
    8000218c:	0174ac23          	sw	s7,24(s1)
      c->proc = p;
    80002190:	609a3c23          	sd	s1,1560(s4)
      swtch(&c->context, &p->context);   
    80002194:	06048593          	addi	a1,s1,96
    80002198:	855a                	mv	a0,s6
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	658080e7          	jalr	1624(ra) # 800027f2 <swtch>
      c->proc = 0;
    800021a2:	600a3c23          	sd	zero,1560(s4)
    800021a6:	b755                	j	8000214a <scheduler+0xbc>

00000000800021a8 <sched>:
{
    800021a8:	7179                	addi	sp,sp,-48
    800021aa:	f406                	sd	ra,40(sp)
    800021ac:	f022                	sd	s0,32(sp)
    800021ae:	ec26                	sd	s1,24(sp)
    800021b0:	e84a                	sd	s2,16(sp)
    800021b2:	e44e                	sd	s3,8(sp)
    800021b4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	91c080e7          	jalr	-1764(ra) # 80001ad2 <myproc>
    800021be:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	9c2080e7          	jalr	-1598(ra) # 80000b82 <holding>
    800021c8:	c93d                	beqz	a0,8000223e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021ca:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800021cc:	2781                	sext.w	a5,a5
    800021ce:	079e                	slli	a5,a5,0x7
    800021d0:	0000f717          	auipc	a4,0xf
    800021d4:	78070713          	addi	a4,a4,1920 # 80011950 <Q>
    800021d8:	97ba                	add	a5,a5,a4
    800021da:	6907a703          	lw	a4,1680(a5)
    800021de:	4785                	li	a5,1
    800021e0:	06f71763          	bne	a4,a5,8000224e <sched+0xa6>
  if (p->state == RUNNING)
    800021e4:	4c98                	lw	a4,24(s1)
    800021e6:	478d                	li	a5,3
    800021e8:	06f70b63          	beq	a4,a5,8000225e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021ec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021f0:	8b89                	andi	a5,a5,2
  if (intr_get())
    800021f2:	efb5                	bnez	a5,8000226e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021f4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021f6:	0000f917          	auipc	s2,0xf
    800021fa:	75a90913          	addi	s2,s2,1882 # 80011950 <Q>
    800021fe:	2781                	sext.w	a5,a5
    80002200:	079e                	slli	a5,a5,0x7
    80002202:	97ca                	add	a5,a5,s2
    80002204:	6947a983          	lw	s3,1684(a5)
    80002208:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000220a:	2781                	sext.w	a5,a5
    8000220c:	079e                	slli	a5,a5,0x7
    8000220e:	00010597          	auipc	a1,0x10
    80002212:	d6258593          	addi	a1,a1,-670 # 80011f70 <cpus+0x8>
    80002216:	95be                	add	a1,a1,a5
    80002218:	06048513          	addi	a0,s1,96
    8000221c:	00000097          	auipc	ra,0x0
    80002220:	5d6080e7          	jalr	1494(ra) # 800027f2 <swtch>
    80002224:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002226:	2781                	sext.w	a5,a5
    80002228:	079e                	slli	a5,a5,0x7
    8000222a:	97ca                	add	a5,a5,s2
    8000222c:	6937aa23          	sw	s3,1684(a5)
}
    80002230:	70a2                	ld	ra,40(sp)
    80002232:	7402                	ld	s0,32(sp)
    80002234:	64e2                	ld	s1,24(sp)
    80002236:	6942                	ld	s2,16(sp)
    80002238:	69a2                	ld	s3,8(sp)
    8000223a:	6145                	addi	sp,sp,48
    8000223c:	8082                	ret
    panic("sched p->lock");
    8000223e:	00006517          	auipc	a0,0x6
    80002242:	01250513          	addi	a0,a0,18 # 80008250 <digits+0x210>
    80002246:	ffffe097          	auipc	ra,0xffffe
    8000224a:	2fa080e7          	jalr	762(ra) # 80000540 <panic>
    panic("sched locks");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	01250513          	addi	a0,a0,18 # 80008260 <digits+0x220>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>
    panic("sched running");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	01250513          	addi	a0,a0,18 # 80008270 <digits+0x230>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2da080e7          	jalr	730(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	01250513          	addi	a0,a0,18 # 80008280 <digits+0x240>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	2ca080e7          	jalr	714(ra) # 80000540 <panic>

000000008000227e <exit>:
{
    8000227e:	7179                	addi	sp,sp,-48
    80002280:	f406                	sd	ra,40(sp)
    80002282:	f022                	sd	s0,32(sp)
    80002284:	ec26                	sd	s1,24(sp)
    80002286:	e84a                	sd	s2,16(sp)
    80002288:	e44e                	sd	s3,8(sp)
    8000228a:	e052                	sd	s4,0(sp)
    8000228c:	1800                	addi	s0,sp,48
    8000228e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002290:	00000097          	auipc	ra,0x0
    80002294:	842080e7          	jalr	-1982(ra) # 80001ad2 <myproc>
    80002298:	89aa                	mv	s3,a0
  if (p == initproc)
    8000229a:	00007797          	auipc	a5,0x7
    8000229e:	d7e7b783          	ld	a5,-642(a5) # 80009018 <initproc>
    800022a2:	0d050493          	addi	s1,a0,208
    800022a6:	15050913          	addi	s2,a0,336
    800022aa:	02a79363          	bne	a5,a0,800022d0 <exit+0x52>
    panic("init exiting");
    800022ae:	00006517          	auipc	a0,0x6
    800022b2:	fea50513          	addi	a0,a0,-22 # 80008298 <digits+0x258>
    800022b6:	ffffe097          	auipc	ra,0xffffe
    800022ba:	28a080e7          	jalr	650(ra) # 80000540 <panic>
      fileclose(f);
    800022be:	00002097          	auipc	ra,0x2
    800022c2:	46e080e7          	jalr	1134(ra) # 8000472c <fileclose>
      p->ofile[fd] = 0;
    800022c6:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800022ca:	04a1                	addi	s1,s1,8
    800022cc:	01248563          	beq	s1,s2,800022d6 <exit+0x58>
    if (p->ofile[fd])
    800022d0:	6088                	ld	a0,0(s1)
    800022d2:	f575                	bnez	a0,800022be <exit+0x40>
    800022d4:	bfdd                	j	800022ca <exit+0x4c>
  begin_op();
    800022d6:	00002097          	auipc	ra,0x2
    800022da:	f84080e7          	jalr	-124(ra) # 8000425a <begin_op>
  iput(p->cwd);
    800022de:	1509b503          	ld	a0,336(s3)
    800022e2:	00001097          	auipc	ra,0x1
    800022e6:	772080e7          	jalr	1906(ra) # 80003a54 <iput>
  end_op();
    800022ea:	00002097          	auipc	ra,0x2
    800022ee:	ff0080e7          	jalr	-16(ra) # 800042da <end_op>
  p->cwd = 0;
    800022f2:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800022f6:	00007497          	auipc	s1,0x7
    800022fa:	d2248493          	addi	s1,s1,-734 # 80009018 <initproc>
    800022fe:	6088                	ld	a0,0(s1)
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	8fc080e7          	jalr	-1796(ra) # 80000bfc <acquire>
  wakeup1(initproc);
    80002308:	6088                	ld	a0,0(s1)
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	67a080e7          	jalr	1658(ra) # 80001984 <wakeup1>
  release(&initproc->lock);
    80002312:	6088                	ld	a0,0(s1)
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	99c080e7          	jalr	-1636(ra) # 80000cb0 <release>
  acquire(&p->lock);
    8000231c:	854e                	mv	a0,s3
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	8de080e7          	jalr	-1826(ra) # 80000bfc <acquire>
  struct proc *original_parent = p->parent;
    80002326:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000232a:	854e                	mv	a0,s3
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	984080e7          	jalr	-1660(ra) # 80000cb0 <release>
  acquire(&original_parent->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	8c6080e7          	jalr	-1850(ra) # 80000bfc <acquire>
  acquire(&p->lock);
    8000233e:	854e                	mv	a0,s3
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	8bc080e7          	jalr	-1860(ra) # 80000bfc <acquire>
  reparent(p);
    80002348:	854e                	mv	a0,s3
    8000234a:	00000097          	auipc	ra,0x0
    8000234e:	cde080e7          	jalr	-802(ra) # 80002028 <reparent>
  wakeup1(original_parent);
    80002352:	8526                	mv	a0,s1
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	630080e7          	jalr	1584(ra) # 80001984 <wakeup1>
  p->xstate = status;
    8000235c:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002360:	4791                	li	a5,4
    80002362:	00f9ac23          	sw	a5,24(s3)
  movequeue(p, 0, MOVE);
    80002366:	4601                	li	a2,0
    80002368:	4581                	li	a1,0
    8000236a:	854e                	mv	a0,s3
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	570080e7          	jalr	1392(ra) # 800018dc <movequeue>
  release(&original_parent->lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	93a080e7          	jalr	-1734(ra) # 80000cb0 <release>
  sched();
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	e2a080e7          	jalr	-470(ra) # 800021a8 <sched>
  panic("zombie exit");
    80002386:	00006517          	auipc	a0,0x6
    8000238a:	f2250513          	addi	a0,a0,-222 # 800082a8 <digits+0x268>
    8000238e:	ffffe097          	auipc	ra,0xffffe
    80002392:	1b2080e7          	jalr	434(ra) # 80000540 <panic>

0000000080002396 <yield>:
{
    80002396:	1101                	addi	sp,sp,-32
    80002398:	ec06                	sd	ra,24(sp)
    8000239a:	e822                	sd	s0,16(sp)
    8000239c:	e426                	sd	s1,8(sp)
    8000239e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	732080e7          	jalr	1842(ra) # 80001ad2 <myproc>
    800023a8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	852080e7          	jalr	-1966(ra) # 80000bfc <acquire>
  p->state = RUNNABLE;
    800023b2:	4789                	li	a5,2
    800023b4:	cc9c                	sw	a5,24(s1)
  if (p->priority == 2)
    800023b6:	17c4a703          	lw	a4,380(s1)
    800023ba:	02f70363          	beq	a4,a5,800023e0 <yield+0x4a>
  else if(p->priority == 1)
    800023be:	4785                	li	a5,1
    800023c0:	02f70d63          	beq	a4,a5,800023fa <yield+0x64>
  sched();
    800023c4:	00000097          	auipc	ra,0x0
    800023c8:	de4080e7          	jalr	-540(ra) # 800021a8 <sched>
  release(&p->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8e2080e7          	jalr	-1822(ra) # 80000cb0 <release>
}
    800023d6:	60e2                	ld	ra,24(sp)
    800023d8:	6442                	ld	s0,16(sp)
    800023da:	64a2                	ld	s1,8(sp)
    800023dc:	6105                	addi	sp,sp,32
    800023de:	8082                	ret
    movequeue(p, 1, MOVE);
    800023e0:	4601                	li	a2,0
    800023e2:	4585                	li	a1,1
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	4f6080e7          	jalr	1270(ra) # 800018dc <movequeue>
    p->Qtime[2] = p->Qtime[2] + 1;
    800023ee:	1704a783          	lw	a5,368(s1)
    800023f2:	2785                	addiw	a5,a5,1
    800023f4:	16f4a823          	sw	a5,368(s1)
    800023f8:	b7f1                	j	800023c4 <yield+0x2e>
    p->Qtime[1] = p->Qtime[1] + 1;
    800023fa:	16c4a783          	lw	a5,364(s1)
    800023fe:	2785                	addiw	a5,a5,1
    80002400:	16f4a623          	sw	a5,364(s1)
    80002404:	b7c1                	j	800023c4 <yield+0x2e>

0000000080002406 <sleep>:
{
    80002406:	7179                	addi	sp,sp,-48
    80002408:	f406                	sd	ra,40(sp)
    8000240a:	f022                	sd	s0,32(sp)
    8000240c:	ec26                	sd	s1,24(sp)
    8000240e:	e84a                	sd	s2,16(sp)
    80002410:	e44e                	sd	s3,8(sp)
    80002412:	1800                	addi	s0,sp,48
    80002414:	89aa                	mv	s3,a0
    80002416:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	6ba080e7          	jalr	1722(ra) # 80001ad2 <myproc>
    80002420:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    80002422:	05250d63          	beq	a0,s2,8000247c <sleep+0x76>
    acquire(&p->lock); //DOC: sleeplock1
    80002426:	ffffe097          	auipc	ra,0xffffe
    8000242a:	7d6080e7          	jalr	2006(ra) # 80000bfc <acquire>
    release(lk);
    8000242e:	854a                	mv	a0,s2
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	880080e7          	jalr	-1920(ra) # 80000cb0 <release>
  p->chan = chan;
    80002438:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000243c:	4785                	li	a5,1
    8000243e:	cc9c                	sw	a5,24(s1)
  movequeue(p, 0, MOVE);
    80002440:	4601                	li	a2,0
    80002442:	4581                	li	a1,0
    80002444:	8526                	mv	a0,s1
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	496080e7          	jalr	1174(ra) # 800018dc <movequeue>
  sched();
    8000244e:	00000097          	auipc	ra,0x0
    80002452:	d5a080e7          	jalr	-678(ra) # 800021a8 <sched>
  p->chan = 0;
    80002456:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000245a:	8526                	mv	a0,s1
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	854080e7          	jalr	-1964(ra) # 80000cb0 <release>
    acquire(lk);
    80002464:	854a                	mv	a0,s2
    80002466:	ffffe097          	auipc	ra,0xffffe
    8000246a:	796080e7          	jalr	1942(ra) # 80000bfc <acquire>
}
    8000246e:	70a2                	ld	ra,40(sp)
    80002470:	7402                	ld	s0,32(sp)
    80002472:	64e2                	ld	s1,24(sp)
    80002474:	6942                	ld	s2,16(sp)
    80002476:	69a2                	ld	s3,8(sp)
    80002478:	6145                	addi	sp,sp,48
    8000247a:	8082                	ret
  p->chan = chan;
    8000247c:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002480:	4785                	li	a5,1
    80002482:	cd1c                	sw	a5,24(a0)
  movequeue(p, 0, MOVE);
    80002484:	4601                	li	a2,0
    80002486:	4581                	li	a1,0
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	454080e7          	jalr	1108(ra) # 800018dc <movequeue>
  sched();
    80002490:	00000097          	auipc	ra,0x0
    80002494:	d18080e7          	jalr	-744(ra) # 800021a8 <sched>
  p->chan = 0;
    80002498:	0204b423          	sd	zero,40(s1)
  if (lk != &p->lock)
    8000249c:	bfc9                	j	8000246e <sleep+0x68>

000000008000249e <wait>:
{
    8000249e:	715d                	addi	sp,sp,-80
    800024a0:	e486                	sd	ra,72(sp)
    800024a2:	e0a2                	sd	s0,64(sp)
    800024a4:	fc26                	sd	s1,56(sp)
    800024a6:	f84a                	sd	s2,48(sp)
    800024a8:	f44e                	sd	s3,40(sp)
    800024aa:	f052                	sd	s4,32(sp)
    800024ac:	ec56                	sd	s5,24(sp)
    800024ae:	e85a                	sd	s6,16(sp)
    800024b0:	e45e                	sd	s7,8(sp)
    800024b2:	0880                	addi	s0,sp,80
    800024b4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	61c080e7          	jalr	1564(ra) # 80001ad2 <myproc>
    800024be:	892a                	mv	s2,a0
  acquire(&p->lock);
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	73c080e7          	jalr	1852(ra) # 80000bfc <acquire>
    havekids = 0;
    800024c8:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800024ca:	4a11                	li	s4,4
        havekids = 1;
    800024cc:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800024ce:	00016997          	auipc	s3,0x16
    800024d2:	e9a98993          	addi	s3,s3,-358 # 80018368 <tickslock>
    havekids = 0;
    800024d6:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800024d8:	00010497          	auipc	s1,0x10
    800024dc:	e9048493          	addi	s1,s1,-368 # 80012368 <proc>
    800024e0:	a08d                	j	80002542 <wait+0xa4>
          pid = np->pid;
    800024e2:	0384a983          	lw	s3,56(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024e6:	000b0e63          	beqz	s6,80002502 <wait+0x64>
    800024ea:	4691                	li	a3,4
    800024ec:	03448613          	addi	a2,s1,52
    800024f0:	85da                	mv	a1,s6
    800024f2:	05093503          	ld	a0,80(s2)
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	1b4080e7          	jalr	436(ra) # 800016aa <copyout>
    800024fe:	02054263          	bltz	a0,80002522 <wait+0x84>
          freeproc(np);
    80002502:	8526                	mv	a0,s1
    80002504:	fffff097          	auipc	ra,0xfffff
    80002508:	782080e7          	jalr	1922(ra) # 80001c86 <freeproc>
          release(&np->lock);
    8000250c:	8526                	mv	a0,s1
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	7a2080e7          	jalr	1954(ra) # 80000cb0 <release>
          release(&p->lock);
    80002516:	854a                	mv	a0,s2
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	798080e7          	jalr	1944(ra) # 80000cb0 <release>
          return pid;
    80002520:	a8a9                	j	8000257a <wait+0xdc>
            release(&np->lock);
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	78c080e7          	jalr	1932(ra) # 80000cb0 <release>
            release(&p->lock);
    8000252c:	854a                	mv	a0,s2
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	782080e7          	jalr	1922(ra) # 80000cb0 <release>
            return -1;
    80002536:	59fd                	li	s3,-1
    80002538:	a089                	j	8000257a <wait+0xdc>
    for (np = proc; np < &proc[NPROC]; np++)
    8000253a:	18048493          	addi	s1,s1,384
    8000253e:	03348463          	beq	s1,s3,80002566 <wait+0xc8>
      if (np->parent == p)
    80002542:	709c                	ld	a5,32(s1)
    80002544:	ff279be3          	bne	a5,s2,8000253a <wait+0x9c>
        acquire(&np->lock);
    80002548:	8526                	mv	a0,s1
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	6b2080e7          	jalr	1714(ra) # 80000bfc <acquire>
        if (np->state == ZOMBIE)
    80002552:	4c9c                	lw	a5,24(s1)
    80002554:	f94787e3          	beq	a5,s4,800024e2 <wait+0x44>
        release(&np->lock);
    80002558:	8526                	mv	a0,s1
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	756080e7          	jalr	1878(ra) # 80000cb0 <release>
        havekids = 1;
    80002562:	8756                	mv	a4,s5
    80002564:	bfd9                	j	8000253a <wait+0x9c>
    if (!havekids || p->killed)
    80002566:	c701                	beqz	a4,8000256e <wait+0xd0>
    80002568:	03092783          	lw	a5,48(s2)
    8000256c:	c39d                	beqz	a5,80002592 <wait+0xf4>
      release(&p->lock);
    8000256e:	854a                	mv	a0,s2
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	740080e7          	jalr	1856(ra) # 80000cb0 <release>
      return -1;
    80002578:	59fd                	li	s3,-1
}
    8000257a:	854e                	mv	a0,s3
    8000257c:	60a6                	ld	ra,72(sp)
    8000257e:	6406                	ld	s0,64(sp)
    80002580:	74e2                	ld	s1,56(sp)
    80002582:	7942                	ld	s2,48(sp)
    80002584:	79a2                	ld	s3,40(sp)
    80002586:	7a02                	ld	s4,32(sp)
    80002588:	6ae2                	ld	s5,24(sp)
    8000258a:	6b42                	ld	s6,16(sp)
    8000258c:	6ba2                	ld	s7,8(sp)
    8000258e:	6161                	addi	sp,sp,80
    80002590:	8082                	ret
    sleep(p, &p->lock); //DOC: wait-sleep
    80002592:	85ca                	mv	a1,s2
    80002594:	854a                	mv	a0,s2
    80002596:	00000097          	auipc	ra,0x0
    8000259a:	e70080e7          	jalr	-400(ra) # 80002406 <sleep>
    havekids = 0;
    8000259e:	bf25                	j	800024d6 <wait+0x38>

00000000800025a0 <wakeup>:
{
    800025a0:	7139                	addi	sp,sp,-64
    800025a2:	fc06                	sd	ra,56(sp)
    800025a4:	f822                	sd	s0,48(sp)
    800025a6:	f426                	sd	s1,40(sp)
    800025a8:	f04a                	sd	s2,32(sp)
    800025aa:	ec4e                	sd	s3,24(sp)
    800025ac:	e852                	sd	s4,16(sp)
    800025ae:	e456                	sd	s5,8(sp)
    800025b0:	0080                	addi	s0,sp,64
    800025b2:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    800025b4:	00010497          	auipc	s1,0x10
    800025b8:	db448493          	addi	s1,s1,-588 # 80012368 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    800025bc:	4985                	li	s3,1
      p->state = RUNNABLE;
    800025be:	4a89                	li	s5,2
  for (p = proc; p < &proc[NPROC]; p++)
    800025c0:	00016917          	auipc	s2,0x16
    800025c4:	da890913          	addi	s2,s2,-600 # 80018368 <tickslock>
    800025c8:	a811                	j	800025dc <wakeup+0x3c>
    release(&p->lock);
    800025ca:	8526                	mv	a0,s1
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	6e4080e7          	jalr	1764(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025d4:	18048493          	addi	s1,s1,384
    800025d8:	03248763          	beq	s1,s2,80002606 <wakeup+0x66>
    acquire(&p->lock);
    800025dc:	8526                	mv	a0,s1
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	61e080e7          	jalr	1566(ra) # 80000bfc <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    800025e6:	4c9c                	lw	a5,24(s1)
    800025e8:	ff3791e3          	bne	a5,s3,800025ca <wakeup+0x2a>
    800025ec:	749c                	ld	a5,40(s1)
    800025ee:	fd479ee3          	bne	a5,s4,800025ca <wakeup+0x2a>
      p->state = RUNNABLE;
    800025f2:	0154ac23          	sw	s5,24(s1)
      movequeue(p, 2, MOVE);
    800025f6:	4601                	li	a2,0
    800025f8:	85d6                	mv	a1,s5
    800025fa:	8526                	mv	a0,s1
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	2e0080e7          	jalr	736(ra) # 800018dc <movequeue>
    80002604:	b7d9                	j	800025ca <wakeup+0x2a>
}
    80002606:	70e2                	ld	ra,56(sp)
    80002608:	7442                	ld	s0,48(sp)
    8000260a:	74a2                	ld	s1,40(sp)
    8000260c:	7902                	ld	s2,32(sp)
    8000260e:	69e2                	ld	s3,24(sp)
    80002610:	6a42                	ld	s4,16(sp)
    80002612:	6aa2                	ld	s5,8(sp)
    80002614:	6121                	addi	sp,sp,64
    80002616:	8082                	ret

0000000080002618 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002618:	7179                	addi	sp,sp,-48
    8000261a:	f406                	sd	ra,40(sp)
    8000261c:	f022                	sd	s0,32(sp)
    8000261e:	ec26                	sd	s1,24(sp)
    80002620:	e84a                	sd	s2,16(sp)
    80002622:	e44e                	sd	s3,8(sp)
    80002624:	1800                	addi	s0,sp,48
    80002626:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002628:	00010497          	auipc	s1,0x10
    8000262c:	d4048493          	addi	s1,s1,-704 # 80012368 <proc>
    80002630:	00016997          	auipc	s3,0x16
    80002634:	d3898993          	addi	s3,s3,-712 # 80018368 <tickslock>
  {
    acquire(&p->lock);
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	5c2080e7          	jalr	1474(ra) # 80000bfc <acquire>
    if (p->pid == pid)
    80002642:	5c9c                	lw	a5,56(s1)
    80002644:	01278d63          	beq	a5,s2,8000265e <kill+0x46>
        movequeue(p, 2, MOVE);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002648:	8526                	mv	a0,s1
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	666080e7          	jalr	1638(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002652:	18048493          	addi	s1,s1,384
    80002656:	ff3491e3          	bne	s1,s3,80002638 <kill+0x20>
  }
  return -1;
    8000265a:	557d                	li	a0,-1
    8000265c:	a821                	j	80002674 <kill+0x5c>
      p->killed = 1;
    8000265e:	4785                	li	a5,1
    80002660:	d89c                	sw	a5,48(s1)
      if (p->state == SLEEPING)
    80002662:	4c98                	lw	a4,24(s1)
    80002664:	00f70f63          	beq	a4,a5,80002682 <kill+0x6a>
      release(&p->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	646080e7          	jalr	1606(ra) # 80000cb0 <release>
      return 0;
    80002672:	4501                	li	a0,0
}
    80002674:	70a2                	ld	ra,40(sp)
    80002676:	7402                	ld	s0,32(sp)
    80002678:	64e2                	ld	s1,24(sp)
    8000267a:	6942                	ld	s2,16(sp)
    8000267c:	69a2                	ld	s3,8(sp)
    8000267e:	6145                	addi	sp,sp,48
    80002680:	8082                	ret
        p->state = RUNNABLE;
    80002682:	4789                	li	a5,2
    80002684:	cc9c                	sw	a5,24(s1)
        movequeue(p, 2, MOVE);
    80002686:	4601                	li	a2,0
    80002688:	4589                	li	a1,2
    8000268a:	8526                	mv	a0,s1
    8000268c:	fffff097          	auipc	ra,0xfffff
    80002690:	250080e7          	jalr	592(ra) # 800018dc <movequeue>
    80002694:	bfd1                	j	80002668 <kill+0x50>

0000000080002696 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002696:	7179                	addi	sp,sp,-48
    80002698:	f406                	sd	ra,40(sp)
    8000269a:	f022                	sd	s0,32(sp)
    8000269c:	ec26                	sd	s1,24(sp)
    8000269e:	e84a                	sd	s2,16(sp)
    800026a0:	e44e                	sd	s3,8(sp)
    800026a2:	e052                	sd	s4,0(sp)
    800026a4:	1800                	addi	s0,sp,48
    800026a6:	84aa                	mv	s1,a0
    800026a8:	892e                	mv	s2,a1
    800026aa:	89b2                	mv	s3,a2
    800026ac:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	424080e7          	jalr	1060(ra) # 80001ad2 <myproc>
  if (user_dst)
    800026b6:	c08d                	beqz	s1,800026d8 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800026b8:	86d2                	mv	a3,s4
    800026ba:	864e                	mv	a2,s3
    800026bc:	85ca                	mv	a1,s2
    800026be:	6928                	ld	a0,80(a0)
    800026c0:	fffff097          	auipc	ra,0xfffff
    800026c4:	fea080e7          	jalr	-22(ra) # 800016aa <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026c8:	70a2                	ld	ra,40(sp)
    800026ca:	7402                	ld	s0,32(sp)
    800026cc:	64e2                	ld	s1,24(sp)
    800026ce:	6942                	ld	s2,16(sp)
    800026d0:	69a2                	ld	s3,8(sp)
    800026d2:	6a02                	ld	s4,0(sp)
    800026d4:	6145                	addi	sp,sp,48
    800026d6:	8082                	ret
    memmove((char *)dst, src, len);
    800026d8:	000a061b          	sext.w	a2,s4
    800026dc:	85ce                	mv	a1,s3
    800026de:	854a                	mv	a0,s2
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	674080e7          	jalr	1652(ra) # 80000d54 <memmove>
    return 0;
    800026e8:	8526                	mv	a0,s1
    800026ea:	bff9                	j	800026c8 <either_copyout+0x32>

00000000800026ec <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026ec:	7179                	addi	sp,sp,-48
    800026ee:	f406                	sd	ra,40(sp)
    800026f0:	f022                	sd	s0,32(sp)
    800026f2:	ec26                	sd	s1,24(sp)
    800026f4:	e84a                	sd	s2,16(sp)
    800026f6:	e44e                	sd	s3,8(sp)
    800026f8:	e052                	sd	s4,0(sp)
    800026fa:	1800                	addi	s0,sp,48
    800026fc:	892a                	mv	s2,a0
    800026fe:	84ae                	mv	s1,a1
    80002700:	89b2                	mv	s3,a2
    80002702:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	3ce080e7          	jalr	974(ra) # 80001ad2 <myproc>
  if (user_src)
    8000270c:	c08d                	beqz	s1,8000272e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000270e:	86d2                	mv	a3,s4
    80002710:	864e                	mv	a2,s3
    80002712:	85ca                	mv	a1,s2
    80002714:	6928                	ld	a0,80(a0)
    80002716:	fffff097          	auipc	ra,0xfffff
    8000271a:	020080e7          	jalr	32(ra) # 80001736 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000271e:	70a2                	ld	ra,40(sp)
    80002720:	7402                	ld	s0,32(sp)
    80002722:	64e2                	ld	s1,24(sp)
    80002724:	6942                	ld	s2,16(sp)
    80002726:	69a2                	ld	s3,8(sp)
    80002728:	6a02                	ld	s4,0(sp)
    8000272a:	6145                	addi	sp,sp,48
    8000272c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000272e:	000a061b          	sext.w	a2,s4
    80002732:	85ce                	mv	a1,s3
    80002734:	854a                	mv	a0,s2
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	61e080e7          	jalr	1566(ra) # 80000d54 <memmove>
    return 0;
    8000273e:	8526                	mv	a0,s1
    80002740:	bff9                	j	8000271e <either_copyin+0x32>

0000000080002742 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002742:	715d                	addi	sp,sp,-80
    80002744:	e486                	sd	ra,72(sp)
    80002746:	e0a2                	sd	s0,64(sp)
    80002748:	fc26                	sd	s1,56(sp)
    8000274a:	f84a                	sd	s2,48(sp)
    8000274c:	f44e                	sd	s3,40(sp)
    8000274e:	f052                	sd	s4,32(sp)
    80002750:	ec56                	sd	s5,24(sp)
    80002752:	e85a                	sd	s6,16(sp)
    80002754:	e45e                	sd	s7,8(sp)
    80002756:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002758:	00006517          	auipc	a0,0x6
    8000275c:	99050513          	addi	a0,a0,-1648 # 800080e8 <digits+0xa8>
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	e2a080e7          	jalr	-470(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002768:	00010497          	auipc	s1,0x10
    8000276c:	d5848493          	addi	s1,s1,-680 # 800124c0 <proc+0x158>
    80002770:	00016917          	auipc	s2,0x16
    80002774:	d5090913          	addi	s2,s2,-688 # 800184c0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002778:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000277a:	00006997          	auipc	s3,0x6
    8000277e:	b3e98993          	addi	s3,s3,-1218 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    80002782:	00006a97          	auipc	s5,0x6
    80002786:	b3ea8a93          	addi	s5,s5,-1218 # 800082c0 <digits+0x280>
    printf("\n");
    8000278a:	00006a17          	auipc	s4,0x6
    8000278e:	95ea0a13          	addi	s4,s4,-1698 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002792:	00006b97          	auipc	s7,0x6
    80002796:	b66b8b93          	addi	s7,s7,-1178 # 800082f8 <states.0>
    8000279a:	a00d                	j	800027bc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000279c:	ee06a583          	lw	a1,-288(a3)
    800027a0:	8556                	mv	a0,s5
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	de8080e7          	jalr	-536(ra) # 8000058a <printf>
    printf("\n");
    800027aa:	8552                	mv	a0,s4
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	dde080e7          	jalr	-546(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027b4:	18048493          	addi	s1,s1,384
    800027b8:	03248263          	beq	s1,s2,800027dc <procdump+0x9a>
    if (p->state == UNUSED)
    800027bc:	86a6                	mv	a3,s1
    800027be:	ec04a783          	lw	a5,-320(s1)
    800027c2:	dbed                	beqz	a5,800027b4 <procdump+0x72>
      state = "???";
    800027c4:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c6:	fcfb6be3          	bltu	s6,a5,8000279c <procdump+0x5a>
    800027ca:	02079713          	slli	a4,a5,0x20
    800027ce:	01d75793          	srli	a5,a4,0x1d
    800027d2:	97de                	add	a5,a5,s7
    800027d4:	6390                	ld	a2,0(a5)
    800027d6:	f279                	bnez	a2,8000279c <procdump+0x5a>
      state = "???";
    800027d8:	864e                	mv	a2,s3
    800027da:	b7c9                	j	8000279c <procdump+0x5a>
  }
}
    800027dc:	60a6                	ld	ra,72(sp)
    800027de:	6406                	ld	s0,64(sp)
    800027e0:	74e2                	ld	s1,56(sp)
    800027e2:	7942                	ld	s2,48(sp)
    800027e4:	79a2                	ld	s3,40(sp)
    800027e6:	7a02                	ld	s4,32(sp)
    800027e8:	6ae2                	ld	s5,24(sp)
    800027ea:	6b42                	ld	s6,16(sp)
    800027ec:	6ba2                	ld	s7,8(sp)
    800027ee:	6161                	addi	sp,sp,80
    800027f0:	8082                	ret

00000000800027f2 <swtch>:
    800027f2:	00153023          	sd	ra,0(a0)
    800027f6:	00253423          	sd	sp,8(a0)
    800027fa:	e900                	sd	s0,16(a0)
    800027fc:	ed04                	sd	s1,24(a0)
    800027fe:	03253023          	sd	s2,32(a0)
    80002802:	03353423          	sd	s3,40(a0)
    80002806:	03453823          	sd	s4,48(a0)
    8000280a:	03553c23          	sd	s5,56(a0)
    8000280e:	05653023          	sd	s6,64(a0)
    80002812:	05753423          	sd	s7,72(a0)
    80002816:	05853823          	sd	s8,80(a0)
    8000281a:	05953c23          	sd	s9,88(a0)
    8000281e:	07a53023          	sd	s10,96(a0)
    80002822:	07b53423          	sd	s11,104(a0)
    80002826:	0005b083          	ld	ra,0(a1)
    8000282a:	0085b103          	ld	sp,8(a1)
    8000282e:	6980                	ld	s0,16(a1)
    80002830:	6d84                	ld	s1,24(a1)
    80002832:	0205b903          	ld	s2,32(a1)
    80002836:	0285b983          	ld	s3,40(a1)
    8000283a:	0305ba03          	ld	s4,48(a1)
    8000283e:	0385ba83          	ld	s5,56(a1)
    80002842:	0405bb03          	ld	s6,64(a1)
    80002846:	0485bb83          	ld	s7,72(a1)
    8000284a:	0505bc03          	ld	s8,80(a1)
    8000284e:	0585bc83          	ld	s9,88(a1)
    80002852:	0605bd03          	ld	s10,96(a1)
    80002856:	0685bd83          	ld	s11,104(a1)
    8000285a:	8082                	ret

000000008000285c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000285c:	1141                	addi	sp,sp,-16
    8000285e:	e406                	sd	ra,8(sp)
    80002860:	e022                	sd	s0,0(sp)
    80002862:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002864:	00006597          	auipc	a1,0x6
    80002868:	abc58593          	addi	a1,a1,-1348 # 80008320 <states.0+0x28>
    8000286c:	00016517          	auipc	a0,0x16
    80002870:	afc50513          	addi	a0,a0,-1284 # 80018368 <tickslock>
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	2f8080e7          	jalr	760(ra) # 80000b6c <initlock>
}
    8000287c:	60a2                	ld	ra,8(sp)
    8000287e:	6402                	ld	s0,0(sp)
    80002880:	0141                	addi	sp,sp,16
    80002882:	8082                	ret

0000000080002884 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002884:	1141                	addi	sp,sp,-16
    80002886:	e422                	sd	s0,8(sp)
    80002888:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000288a:	00003797          	auipc	a5,0x3
    8000288e:	50678793          	addi	a5,a5,1286 # 80005d90 <kernelvec>
    80002892:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002896:	6422                	ld	s0,8(sp)
    80002898:	0141                	addi	sp,sp,16
    8000289a:	8082                	ret

000000008000289c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000289c:	1141                	addi	sp,sp,-16
    8000289e:	e406                	sd	ra,8(sp)
    800028a0:	e022                	sd	s0,0(sp)
    800028a2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028a4:	fffff097          	auipc	ra,0xfffff
    800028a8:	22e080e7          	jalr	558(ra) # 80001ad2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028b0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028b2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028b6:	00004617          	auipc	a2,0x4
    800028ba:	74a60613          	addi	a2,a2,1866 # 80007000 <_trampoline>
    800028be:	00004697          	auipc	a3,0x4
    800028c2:	74268693          	addi	a3,a3,1858 # 80007000 <_trampoline>
    800028c6:	8e91                	sub	a3,a3,a2
    800028c8:	040007b7          	lui	a5,0x4000
    800028cc:	17fd                	addi	a5,a5,-1
    800028ce:	07b2                	slli	a5,a5,0xc
    800028d0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028d6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028d8:	180026f3          	csrr	a3,satp
    800028dc:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028de:	6d38                	ld	a4,88(a0)
    800028e0:	6134                	ld	a3,64(a0)
    800028e2:	6585                	lui	a1,0x1
    800028e4:	96ae                	add	a3,a3,a1
    800028e6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028e8:	6d38                	ld	a4,88(a0)
    800028ea:	00000697          	auipc	a3,0x0
    800028ee:	13868693          	addi	a3,a3,312 # 80002a22 <usertrap>
    800028f2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028f4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028f6:	8692                	mv	a3,tp
    800028f8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fa:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028fe:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002902:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002906:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000290a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000290c:	6f18                	ld	a4,24(a4)
    8000290e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002912:	692c                	ld	a1,80(a0)
    80002914:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002916:	00004717          	auipc	a4,0x4
    8000291a:	77a70713          	addi	a4,a4,1914 # 80007090 <userret>
    8000291e:	8f11                	sub	a4,a4,a2
    80002920:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002922:	577d                	li	a4,-1
    80002924:	177e                	slli	a4,a4,0x3f
    80002926:	8dd9                	or	a1,a1,a4
    80002928:	02000537          	lui	a0,0x2000
    8000292c:	157d                	addi	a0,a0,-1
    8000292e:	0536                	slli	a0,a0,0xd
    80002930:	9782                	jalr	a5
}
    80002932:	60a2                	ld	ra,8(sp)
    80002934:	6402                	ld	s0,0(sp)
    80002936:	0141                	addi	sp,sp,16
    80002938:	8082                	ret

000000008000293a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000293a:	1101                	addi	sp,sp,-32
    8000293c:	ec06                	sd	ra,24(sp)
    8000293e:	e822                	sd	s0,16(sp)
    80002940:	e426                	sd	s1,8(sp)
    80002942:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002944:	00016497          	auipc	s1,0x16
    80002948:	a2448493          	addi	s1,s1,-1500 # 80018368 <tickslock>
    8000294c:	8526                	mv	a0,s1
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	2ae080e7          	jalr	686(ra) # 80000bfc <acquire>
  ticks++;
    80002956:	00006517          	auipc	a0,0x6
    8000295a:	6ca50513          	addi	a0,a0,1738 # 80009020 <ticks>
    8000295e:	411c                	lw	a5,0(a0)
    80002960:	2785                	addiw	a5,a5,1
    80002962:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002964:	00000097          	auipc	ra,0x0
    80002968:	c3c080e7          	jalr	-964(ra) # 800025a0 <wakeup>
  release(&tickslock);
    8000296c:	8526                	mv	a0,s1
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	342080e7          	jalr	834(ra) # 80000cb0 <release>
}
    80002976:	60e2                	ld	ra,24(sp)
    80002978:	6442                	ld	s0,16(sp)
    8000297a:	64a2                	ld	s1,8(sp)
    8000297c:	6105                	addi	sp,sp,32
    8000297e:	8082                	ret

0000000080002980 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002980:	1101                	addi	sp,sp,-32
    80002982:	ec06                	sd	ra,24(sp)
    80002984:	e822                	sd	s0,16(sp)
    80002986:	e426                	sd	s1,8(sp)
    80002988:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000298a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000298e:	00074d63          	bltz	a4,800029a8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002992:	57fd                	li	a5,-1
    80002994:	17fe                	slli	a5,a5,0x3f
    80002996:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002998:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000299a:	06f70363          	beq	a4,a5,80002a00 <devintr+0x80>
  }
}
    8000299e:	60e2                	ld	ra,24(sp)
    800029a0:	6442                	ld	s0,16(sp)
    800029a2:	64a2                	ld	s1,8(sp)
    800029a4:	6105                	addi	sp,sp,32
    800029a6:	8082                	ret
     (scause & 0xff) == 9){
    800029a8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029ac:	46a5                	li	a3,9
    800029ae:	fed792e3          	bne	a5,a3,80002992 <devintr+0x12>
    int irq = plic_claim();
    800029b2:	00003097          	auipc	ra,0x3
    800029b6:	4e6080e7          	jalr	1254(ra) # 80005e98 <plic_claim>
    800029ba:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029bc:	47a9                	li	a5,10
    800029be:	02f50763          	beq	a0,a5,800029ec <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029c2:	4785                	li	a5,1
    800029c4:	02f50963          	beq	a0,a5,800029f6 <devintr+0x76>
    return 1;
    800029c8:	4505                	li	a0,1
    } else if(irq){
    800029ca:	d8f1                	beqz	s1,8000299e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029cc:	85a6                	mv	a1,s1
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	95a50513          	addi	a0,a0,-1702 # 80008328 <states.0+0x30>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	bb4080e7          	jalr	-1100(ra) # 8000058a <printf>
      plic_complete(irq);
    800029de:	8526                	mv	a0,s1
    800029e0:	00003097          	auipc	ra,0x3
    800029e4:	4dc080e7          	jalr	1244(ra) # 80005ebc <plic_complete>
    return 1;
    800029e8:	4505                	li	a0,1
    800029ea:	bf55                	j	8000299e <devintr+0x1e>
      uartintr();
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	fd4080e7          	jalr	-44(ra) # 800009c0 <uartintr>
    800029f4:	b7ed                	j	800029de <devintr+0x5e>
      virtio_disk_intr();
    800029f6:	00004097          	auipc	ra,0x4
    800029fa:	940080e7          	jalr	-1728(ra) # 80006336 <virtio_disk_intr>
    800029fe:	b7c5                	j	800029de <devintr+0x5e>
    if(cpuid() == 0){
    80002a00:	fffff097          	auipc	ra,0xfffff
    80002a04:	0a6080e7          	jalr	166(ra) # 80001aa6 <cpuid>
    80002a08:	c901                	beqz	a0,80002a18 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a0a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a0e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a10:	14479073          	csrw	sip,a5
    return 2;
    80002a14:	4509                	li	a0,2
    80002a16:	b761                	j	8000299e <devintr+0x1e>
      clockintr();
    80002a18:	00000097          	auipc	ra,0x0
    80002a1c:	f22080e7          	jalr	-222(ra) # 8000293a <clockintr>
    80002a20:	b7ed                	j	80002a0a <devintr+0x8a>

0000000080002a22 <usertrap>:
{
    80002a22:	1101                	addi	sp,sp,-32
    80002a24:	ec06                	sd	ra,24(sp)
    80002a26:	e822                	sd	s0,16(sp)
    80002a28:	e426                	sd	s1,8(sp)
    80002a2a:	e04a                	sd	s2,0(sp)
    80002a2c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a2e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a32:	1007f793          	andi	a5,a5,256
    80002a36:	e3ad                	bnez	a5,80002a98 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a38:	00003797          	auipc	a5,0x3
    80002a3c:	35878793          	addi	a5,a5,856 # 80005d90 <kernelvec>
    80002a40:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a44:	fffff097          	auipc	ra,0xfffff
    80002a48:	08e080e7          	jalr	142(ra) # 80001ad2 <myproc>
    80002a4c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a4e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a50:	14102773          	csrr	a4,sepc
    80002a54:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a56:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a5a:	47a1                	li	a5,8
    80002a5c:	04f71c63          	bne	a4,a5,80002ab4 <usertrap+0x92>
    if(p->killed)
    80002a60:	591c                	lw	a5,48(a0)
    80002a62:	e3b9                	bnez	a5,80002aa8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a64:	6cb8                	ld	a4,88(s1)
    80002a66:	6f1c                	ld	a5,24(a4)
    80002a68:	0791                	addi	a5,a5,4
    80002a6a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a70:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a74:	10079073          	csrw	sstatus,a5
    syscall();
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	2f8080e7          	jalr	760(ra) # 80002d70 <syscall>
  if(p->killed)
    80002a80:	589c                	lw	a5,48(s1)
    80002a82:	ebc1                	bnez	a5,80002b12 <usertrap+0xf0>
  usertrapret();
    80002a84:	00000097          	auipc	ra,0x0
    80002a88:	e18080e7          	jalr	-488(ra) # 8000289c <usertrapret>
}
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6902                	ld	s2,0(sp)
    80002a94:	6105                	addi	sp,sp,32
    80002a96:	8082                	ret
    panic("usertrap: not from user mode");
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	8b050513          	addi	a0,a0,-1872 # 80008348 <states.0+0x50>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	aa0080e7          	jalr	-1376(ra) # 80000540 <panic>
      exit(-1);
    80002aa8:	557d                	li	a0,-1
    80002aaa:	fffff097          	auipc	ra,0xfffff
    80002aae:	7d4080e7          	jalr	2004(ra) # 8000227e <exit>
    80002ab2:	bf4d                	j	80002a64 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	ecc080e7          	jalr	-308(ra) # 80002980 <devintr>
    80002abc:	892a                	mv	s2,a0
    80002abe:	c501                	beqz	a0,80002ac6 <usertrap+0xa4>
  if(p->killed)
    80002ac0:	589c                	lw	a5,48(s1)
    80002ac2:	c3a1                	beqz	a5,80002b02 <usertrap+0xe0>
    80002ac4:	a815                	j	80002af8 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002aca:	5c90                	lw	a2,56(s1)
    80002acc:	00006517          	auipc	a0,0x6
    80002ad0:	89c50513          	addi	a0,a0,-1892 # 80008368 <states.0+0x70>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	ab6080e7          	jalr	-1354(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002adc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ae0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	8b450513          	addi	a0,a0,-1868 # 80008398 <states.0+0xa0>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	a9e080e7          	jalr	-1378(ra) # 8000058a <printf>
    p->killed = 1;
    80002af4:	4785                	li	a5,1
    80002af6:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002af8:	557d                	li	a0,-1
    80002afa:	fffff097          	auipc	ra,0xfffff
    80002afe:	784080e7          	jalr	1924(ra) # 8000227e <exit>
  if(which_dev == 2)
    80002b02:	4789                	li	a5,2
    80002b04:	f8f910e3          	bne	s2,a5,80002a84 <usertrap+0x62>
    yield();
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	88e080e7          	jalr	-1906(ra) # 80002396 <yield>
    80002b10:	bf95                	j	80002a84 <usertrap+0x62>
  int which_dev = 0;
    80002b12:	4901                	li	s2,0
    80002b14:	b7d5                	j	80002af8 <usertrap+0xd6>

0000000080002b16 <kerneltrap>:
{
    80002b16:	7179                	addi	sp,sp,-48
    80002b18:	f406                	sd	ra,40(sp)
    80002b1a:	f022                	sd	s0,32(sp)
    80002b1c:	ec26                	sd	s1,24(sp)
    80002b1e:	e84a                	sd	s2,16(sp)
    80002b20:	e44e                	sd	s3,8(sp)
    80002b22:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b24:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b28:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b2c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b30:	1004f793          	andi	a5,s1,256
    80002b34:	cb85                	beqz	a5,80002b64 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b3a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b3c:	ef85                	bnez	a5,80002b74 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b3e:	00000097          	auipc	ra,0x0
    80002b42:	e42080e7          	jalr	-446(ra) # 80002980 <devintr>
    80002b46:	cd1d                	beqz	a0,80002b84 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b48:	4789                	li	a5,2
    80002b4a:	08f50663          	beq	a0,a5,80002bd6 <kerneltrap+0xc0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b4e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b52:	10049073          	csrw	sstatus,s1
}
    80002b56:	70a2                	ld	ra,40(sp)
    80002b58:	7402                	ld	s0,32(sp)
    80002b5a:	64e2                	ld	s1,24(sp)
    80002b5c:	6942                	ld	s2,16(sp)
    80002b5e:	69a2                	ld	s3,8(sp)
    80002b60:	6145                	addi	sp,sp,48
    80002b62:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b64:	00006517          	auipc	a0,0x6
    80002b68:	85450513          	addi	a0,a0,-1964 # 800083b8 <states.0+0xc0>
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	9d4080e7          	jalr	-1580(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b74:	00006517          	auipc	a0,0x6
    80002b78:	86c50513          	addi	a0,a0,-1940 # 800083e0 <states.0+0xe8>
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	9c4080e7          	jalr	-1596(ra) # 80000540 <panic>
    printf("%d\n", ticks);
    80002b84:	00006597          	auipc	a1,0x6
    80002b88:	49c5a583          	lw	a1,1180(a1) # 80009020 <ticks>
    80002b8c:	00006517          	auipc	a0,0x6
    80002b90:	8cc50513          	addi	a0,a0,-1844 # 80008458 <states.0+0x160>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9f6080e7          	jalr	-1546(ra) # 8000058a <printf>
    printf("scause %p\n", scause);
    80002b9c:	85ce                	mv	a1,s3
    80002b9e:	00006517          	auipc	a0,0x6
    80002ba2:	86250513          	addi	a0,a0,-1950 # 80008400 <states.0+0x108>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	9e4080e7          	jalr	-1564(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bb2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bb6:	00006517          	auipc	a0,0x6
    80002bba:	85a50513          	addi	a0,a0,-1958 # 80008410 <states.0+0x118>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	9cc080e7          	jalr	-1588(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002bc6:	00006517          	auipc	a0,0x6
    80002bca:	86250513          	addi	a0,a0,-1950 # 80008428 <states.0+0x130>
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	972080e7          	jalr	-1678(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	efc080e7          	jalr	-260(ra) # 80001ad2 <myproc>
    80002bde:	d925                	beqz	a0,80002b4e <kerneltrap+0x38>
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	ef2080e7          	jalr	-270(ra) # 80001ad2 <myproc>
    80002be8:	4d18                	lw	a4,24(a0)
    80002bea:	478d                	li	a5,3
    80002bec:	f6f711e3          	bne	a4,a5,80002b4e <kerneltrap+0x38>
    yield();
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	7a6080e7          	jalr	1958(ra) # 80002396 <yield>
    80002bf8:	bf99                	j	80002b4e <kerneltrap+0x38>

0000000080002bfa <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bfa:	1101                	addi	sp,sp,-32
    80002bfc:	ec06                	sd	ra,24(sp)
    80002bfe:	e822                	sd	s0,16(sp)
    80002c00:	e426                	sd	s1,8(sp)
    80002c02:	1000                	addi	s0,sp,32
    80002c04:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	ecc080e7          	jalr	-308(ra) # 80001ad2 <myproc>
  switch (n)
    80002c0e:	4795                	li	a5,5
    80002c10:	0497e163          	bltu	a5,s1,80002c52 <argraw+0x58>
    80002c14:	048a                	slli	s1,s1,0x2
    80002c16:	00006717          	auipc	a4,0x6
    80002c1a:	84a70713          	addi	a4,a4,-1974 # 80008460 <states.0+0x168>
    80002c1e:	94ba                	add	s1,s1,a4
    80002c20:	409c                	lw	a5,0(s1)
    80002c22:	97ba                	add	a5,a5,a4
    80002c24:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002c26:	6d3c                	ld	a5,88(a0)
    80002c28:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c2a:	60e2                	ld	ra,24(sp)
    80002c2c:	6442                	ld	s0,16(sp)
    80002c2e:	64a2                	ld	s1,8(sp)
    80002c30:	6105                	addi	sp,sp,32
    80002c32:	8082                	ret
    return p->trapframe->a1;
    80002c34:	6d3c                	ld	a5,88(a0)
    80002c36:	7fa8                	ld	a0,120(a5)
    80002c38:	bfcd                	j	80002c2a <argraw+0x30>
    return p->trapframe->a2;
    80002c3a:	6d3c                	ld	a5,88(a0)
    80002c3c:	63c8                	ld	a0,128(a5)
    80002c3e:	b7f5                	j	80002c2a <argraw+0x30>
    return p->trapframe->a3;
    80002c40:	6d3c                	ld	a5,88(a0)
    80002c42:	67c8                	ld	a0,136(a5)
    80002c44:	b7dd                	j	80002c2a <argraw+0x30>
    return p->trapframe->a4;
    80002c46:	6d3c                	ld	a5,88(a0)
    80002c48:	6bc8                	ld	a0,144(a5)
    80002c4a:	b7c5                	j	80002c2a <argraw+0x30>
    return p->trapframe->a5;
    80002c4c:	6d3c                	ld	a5,88(a0)
    80002c4e:	6fc8                	ld	a0,152(a5)
    80002c50:	bfe9                	j	80002c2a <argraw+0x30>
  panic("argraw");
    80002c52:	00005517          	auipc	a0,0x5
    80002c56:	7e650513          	addi	a0,a0,2022 # 80008438 <states.0+0x140>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	8e6080e7          	jalr	-1818(ra) # 80000540 <panic>

0000000080002c62 <fetchaddr>:
{
    80002c62:	1101                	addi	sp,sp,-32
    80002c64:	ec06                	sd	ra,24(sp)
    80002c66:	e822                	sd	s0,16(sp)
    80002c68:	e426                	sd	s1,8(sp)
    80002c6a:	e04a                	sd	s2,0(sp)
    80002c6c:	1000                	addi	s0,sp,32
    80002c6e:	84aa                	mv	s1,a0
    80002c70:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	e60080e7          	jalr	-416(ra) # 80001ad2 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002c7a:	653c                	ld	a5,72(a0)
    80002c7c:	02f4f863          	bgeu	s1,a5,80002cac <fetchaddr+0x4a>
    80002c80:	00848713          	addi	a4,s1,8
    80002c84:	02e7e663          	bltu	a5,a4,80002cb0 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c88:	46a1                	li	a3,8
    80002c8a:	8626                	mv	a2,s1
    80002c8c:	85ca                	mv	a1,s2
    80002c8e:	6928                	ld	a0,80(a0)
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	aa6080e7          	jalr	-1370(ra) # 80001736 <copyin>
    80002c98:	00a03533          	snez	a0,a0
    80002c9c:	40a00533          	neg	a0,a0
}
    80002ca0:	60e2                	ld	ra,24(sp)
    80002ca2:	6442                	ld	s0,16(sp)
    80002ca4:	64a2                	ld	s1,8(sp)
    80002ca6:	6902                	ld	s2,0(sp)
    80002ca8:	6105                	addi	sp,sp,32
    80002caa:	8082                	ret
    return -1;
    80002cac:	557d                	li	a0,-1
    80002cae:	bfcd                	j	80002ca0 <fetchaddr+0x3e>
    80002cb0:	557d                	li	a0,-1
    80002cb2:	b7fd                	j	80002ca0 <fetchaddr+0x3e>

0000000080002cb4 <fetchstr>:
{
    80002cb4:	7179                	addi	sp,sp,-48
    80002cb6:	f406                	sd	ra,40(sp)
    80002cb8:	f022                	sd	s0,32(sp)
    80002cba:	ec26                	sd	s1,24(sp)
    80002cbc:	e84a                	sd	s2,16(sp)
    80002cbe:	e44e                	sd	s3,8(sp)
    80002cc0:	1800                	addi	s0,sp,48
    80002cc2:	892a                	mv	s2,a0
    80002cc4:	84ae                	mv	s1,a1
    80002cc6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	e0a080e7          	jalr	-502(ra) # 80001ad2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cd0:	86ce                	mv	a3,s3
    80002cd2:	864a                	mv	a2,s2
    80002cd4:	85a6                	mv	a1,s1
    80002cd6:	6928                	ld	a0,80(a0)
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	aec080e7          	jalr	-1300(ra) # 800017c4 <copyinstr>
  if (err < 0)
    80002ce0:	00054763          	bltz	a0,80002cee <fetchstr+0x3a>
  return strlen(buf);
    80002ce4:	8526                	mv	a0,s1
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	196080e7          	jalr	406(ra) # 80000e7c <strlen>
}
    80002cee:	70a2                	ld	ra,40(sp)
    80002cf0:	7402                	ld	s0,32(sp)
    80002cf2:	64e2                	ld	s1,24(sp)
    80002cf4:	6942                	ld	s2,16(sp)
    80002cf6:	69a2                	ld	s3,8(sp)
    80002cf8:	6145                	addi	sp,sp,48
    80002cfa:	8082                	ret

0000000080002cfc <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	e426                	sd	s1,8(sp)
    80002d04:	1000                	addi	s0,sp,32
    80002d06:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	ef2080e7          	jalr	-270(ra) # 80002bfa <argraw>
    80002d10:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d12:	4501                	li	a0,0
    80002d14:	60e2                	ld	ra,24(sp)
    80002d16:	6442                	ld	s0,16(sp)
    80002d18:	64a2                	ld	s1,8(sp)
    80002d1a:	6105                	addi	sp,sp,32
    80002d1c:	8082                	ret

0000000080002d1e <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002d1e:	1101                	addi	sp,sp,-32
    80002d20:	ec06                	sd	ra,24(sp)
    80002d22:	e822                	sd	s0,16(sp)
    80002d24:	e426                	sd	s1,8(sp)
    80002d26:	1000                	addi	s0,sp,32
    80002d28:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	ed0080e7          	jalr	-304(ra) # 80002bfa <argraw>
    80002d32:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d34:	4501                	li	a0,0
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	64a2                	ld	s1,8(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret

0000000080002d40 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002d40:	1101                	addi	sp,sp,-32
    80002d42:	ec06                	sd	ra,24(sp)
    80002d44:	e822                	sd	s0,16(sp)
    80002d46:	e426                	sd	s1,8(sp)
    80002d48:	e04a                	sd	s2,0(sp)
    80002d4a:	1000                	addi	s0,sp,32
    80002d4c:	84ae                	mv	s1,a1
    80002d4e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	eaa080e7          	jalr	-342(ra) # 80002bfa <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d58:	864a                	mv	a2,s2
    80002d5a:	85a6                	mv	a1,s1
    80002d5c:	00000097          	auipc	ra,0x0
    80002d60:	f58080e7          	jalr	-168(ra) # 80002cb4 <fetchstr>
}
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	64a2                	ld	s1,8(sp)
    80002d6a:	6902                	ld	s2,0(sp)
    80002d6c:	6105                	addi	sp,sp,32
    80002d6e:	8082                	ret

0000000080002d70 <syscall>:
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
};

void syscall(void)
{
    80002d70:	1101                	addi	sp,sp,-32
    80002d72:	ec06                	sd	ra,24(sp)
    80002d74:	e822                	sd	s0,16(sp)
    80002d76:	e426                	sd	s1,8(sp)
    80002d78:	e04a                	sd	s2,0(sp)
    80002d7a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	d56080e7          	jalr	-682(ra) # 80001ad2 <myproc>
    80002d84:	84aa                	mv	s1,a0

  // Assignment 4
  // when syscall is invoked and
  // its priority was not 2,
  // move to Q2 process
  if (p->priority != 2) 
    80002d86:	17c52703          	lw	a4,380(a0)
    80002d8a:	4789                	li	a5,2
    80002d8c:	02f71963          	bne	a4,a5,80002dbe <syscall+0x4e>
    acquire(&p->lock);
    movequeue(p, 2, 0);
    release(&p->lock);
  }

  num = p->trapframe->a7;
    80002d90:	0584b903          	ld	s2,88(s1)
    80002d94:	0a893783          	ld	a5,168(s2)
    80002d98:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002d9c:	37fd                	addiw	a5,a5,-1
    80002d9e:	4751                	li	a4,20
    80002da0:	04f76063          	bltu	a4,a5,80002de0 <syscall+0x70>
    80002da4:	00369713          	slli	a4,a3,0x3
    80002da8:	00005797          	auipc	a5,0x5
    80002dac:	6d078793          	addi	a5,a5,1744 # 80008478 <syscalls>
    80002db0:	97ba                	add	a5,a5,a4
    80002db2:	639c                	ld	a5,0(a5)
    80002db4:	c795                	beqz	a5,80002de0 <syscall+0x70>
  {
    p->trapframe->a0 = syscalls[num]();
    80002db6:	9782                	jalr	a5
    80002db8:	06a93823          	sd	a0,112(s2)
    80002dbc:	a081                	j	80002dfc <syscall+0x8c>
    acquire(&p->lock);
    80002dbe:	ffffe097          	auipc	ra,0xffffe
    80002dc2:	e3e080e7          	jalr	-450(ra) # 80000bfc <acquire>
    movequeue(p, 2, 0);
    80002dc6:	4601                	li	a2,0
    80002dc8:	4589                	li	a1,2
    80002dca:	8526                	mv	a0,s1
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	b10080e7          	jalr	-1264(ra) # 800018dc <movequeue>
    release(&p->lock);
    80002dd4:	8526                	mv	a0,s1
    80002dd6:	ffffe097          	auipc	ra,0xffffe
    80002dda:	eda080e7          	jalr	-294(ra) # 80000cb0 <release>
    80002dde:	bf4d                	j	80002d90 <syscall+0x20>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002de0:	15848613          	addi	a2,s1,344
    80002de4:	5c8c                	lw	a1,56(s1)
    80002de6:	00005517          	auipc	a0,0x5
    80002dea:	65a50513          	addi	a0,a0,1626 # 80008440 <states.0+0x148>
    80002dee:	ffffd097          	auipc	ra,0xffffd
    80002df2:	79c080e7          	jalr	1948(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002df6:	6cbc                	ld	a5,88(s1)
    80002df8:	577d                	li	a4,-1
    80002dfa:	fbb8                	sd	a4,112(a5)
  }
}
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	64a2                	ld	s1,8(sp)
    80002e02:	6902                	ld	s2,0(sp)
    80002e04:	6105                	addi	sp,sp,32
    80002e06:	8082                	ret

0000000080002e08 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e08:	1101                	addi	sp,sp,-32
    80002e0a:	ec06                	sd	ra,24(sp)
    80002e0c:	e822                	sd	s0,16(sp)
    80002e0e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e10:	fec40593          	addi	a1,s0,-20
    80002e14:	4501                	li	a0,0
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	ee6080e7          	jalr	-282(ra) # 80002cfc <argint>
    return -1;
    80002e1e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e20:	00054963          	bltz	a0,80002e32 <sys_exit+0x2a>
  exit(n);
    80002e24:	fec42503          	lw	a0,-20(s0)
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	456080e7          	jalr	1110(ra) # 8000227e <exit>
  return 0;  // not reached
    80002e30:	4781                	li	a5,0
}
    80002e32:	853e                	mv	a0,a5
    80002e34:	60e2                	ld	ra,24(sp)
    80002e36:	6442                	ld	s0,16(sp)
    80002e38:	6105                	addi	sp,sp,32
    80002e3a:	8082                	ret

0000000080002e3c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e3c:	1141                	addi	sp,sp,-16
    80002e3e:	e406                	sd	ra,8(sp)
    80002e40:	e022                	sd	s0,0(sp)
    80002e42:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	c8e080e7          	jalr	-882(ra) # 80001ad2 <myproc>
}
    80002e4c:	5d08                	lw	a0,56(a0)
    80002e4e:	60a2                	ld	ra,8(sp)
    80002e50:	6402                	ld	s0,0(sp)
    80002e52:	0141                	addi	sp,sp,16
    80002e54:	8082                	ret

0000000080002e56 <sys_fork>:

uint64
sys_fork(void)
{
    80002e56:	1141                	addi	sp,sp,-16
    80002e58:	e406                	sd	ra,8(sp)
    80002e5a:	e022                	sd	s0,0(sp)
    80002e5c:	0800                	addi	s0,sp,16
  return fork();
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	0b0080e7          	jalr	176(ra) # 80001f0e <fork>
}
    80002e66:	60a2                	ld	ra,8(sp)
    80002e68:	6402                	ld	s0,0(sp)
    80002e6a:	0141                	addi	sp,sp,16
    80002e6c:	8082                	ret

0000000080002e6e <sys_wait>:

uint64
sys_wait(void)
{
    80002e6e:	1101                	addi	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e76:	fe840593          	addi	a1,s0,-24
    80002e7a:	4501                	li	a0,0
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	ea2080e7          	jalr	-350(ra) # 80002d1e <argaddr>
    80002e84:	87aa                	mv	a5,a0
    return -1;
    80002e86:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e88:	0007c863          	bltz	a5,80002e98 <sys_wait+0x2a>
  return wait(p);
    80002e8c:	fe843503          	ld	a0,-24(s0)
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	60e080e7          	jalr	1550(ra) # 8000249e <wait>
}
    80002e98:	60e2                	ld	ra,24(sp)
    80002e9a:	6442                	ld	s0,16(sp)
    80002e9c:	6105                	addi	sp,sp,32
    80002e9e:	8082                	ret

0000000080002ea0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ea0:	7179                	addi	sp,sp,-48
    80002ea2:	f406                	sd	ra,40(sp)
    80002ea4:	f022                	sd	s0,32(sp)
    80002ea6:	ec26                	sd	s1,24(sp)
    80002ea8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002eaa:	fdc40593          	addi	a1,s0,-36
    80002eae:	4501                	li	a0,0
    80002eb0:	00000097          	auipc	ra,0x0
    80002eb4:	e4c080e7          	jalr	-436(ra) # 80002cfc <argint>
    return -1;
    80002eb8:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002eba:	00054f63          	bltz	a0,80002ed8 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	c14080e7          	jalr	-1004(ra) # 80001ad2 <myproc>
    80002ec6:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ec8:	fdc42503          	lw	a0,-36(s0)
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	fce080e7          	jalr	-50(ra) # 80001e9a <growproc>
    80002ed4:	00054863          	bltz	a0,80002ee4 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002ed8:	8526                	mv	a0,s1
    80002eda:	70a2                	ld	ra,40(sp)
    80002edc:	7402                	ld	s0,32(sp)
    80002ede:	64e2                	ld	s1,24(sp)
    80002ee0:	6145                	addi	sp,sp,48
    80002ee2:	8082                	ret
    return -1;
    80002ee4:	54fd                	li	s1,-1
    80002ee6:	bfcd                	j	80002ed8 <sys_sbrk+0x38>

0000000080002ee8 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ee8:	7139                	addi	sp,sp,-64
    80002eea:	fc06                	sd	ra,56(sp)
    80002eec:	f822                	sd	s0,48(sp)
    80002eee:	f426                	sd	s1,40(sp)
    80002ef0:	f04a                	sd	s2,32(sp)
    80002ef2:	ec4e                	sd	s3,24(sp)
    80002ef4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ef6:	fcc40593          	addi	a1,s0,-52
    80002efa:	4501                	li	a0,0
    80002efc:	00000097          	auipc	ra,0x0
    80002f00:	e00080e7          	jalr	-512(ra) # 80002cfc <argint>
    return -1;
    80002f04:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f06:	06054563          	bltz	a0,80002f70 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f0a:	00015517          	auipc	a0,0x15
    80002f0e:	45e50513          	addi	a0,a0,1118 # 80018368 <tickslock>
    80002f12:	ffffe097          	auipc	ra,0xffffe
    80002f16:	cea080e7          	jalr	-790(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    80002f1a:	00006917          	auipc	s2,0x6
    80002f1e:	10692903          	lw	s2,262(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f22:	fcc42783          	lw	a5,-52(s0)
    80002f26:	cf85                	beqz	a5,80002f5e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f28:	00015997          	auipc	s3,0x15
    80002f2c:	44098993          	addi	s3,s3,1088 # 80018368 <tickslock>
    80002f30:	00006497          	auipc	s1,0x6
    80002f34:	0f048493          	addi	s1,s1,240 # 80009020 <ticks>
    if(myproc()->killed){
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	b9a080e7          	jalr	-1126(ra) # 80001ad2 <myproc>
    80002f40:	591c                	lw	a5,48(a0)
    80002f42:	ef9d                	bnez	a5,80002f80 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f44:	85ce                	mv	a1,s3
    80002f46:	8526                	mv	a0,s1
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	4be080e7          	jalr	1214(ra) # 80002406 <sleep>
  while(ticks - ticks0 < n){
    80002f50:	409c                	lw	a5,0(s1)
    80002f52:	412787bb          	subw	a5,a5,s2
    80002f56:	fcc42703          	lw	a4,-52(s0)
    80002f5a:	fce7efe3          	bltu	a5,a4,80002f38 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f5e:	00015517          	auipc	a0,0x15
    80002f62:	40a50513          	addi	a0,a0,1034 # 80018368 <tickslock>
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	d4a080e7          	jalr	-694(ra) # 80000cb0 <release>
  return 0;
    80002f6e:	4781                	li	a5,0
}
    80002f70:	853e                	mv	a0,a5
    80002f72:	70e2                	ld	ra,56(sp)
    80002f74:	7442                	ld	s0,48(sp)
    80002f76:	74a2                	ld	s1,40(sp)
    80002f78:	7902                	ld	s2,32(sp)
    80002f7a:	69e2                	ld	s3,24(sp)
    80002f7c:	6121                	addi	sp,sp,64
    80002f7e:	8082                	ret
      release(&tickslock);
    80002f80:	00015517          	auipc	a0,0x15
    80002f84:	3e850513          	addi	a0,a0,1000 # 80018368 <tickslock>
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	d28080e7          	jalr	-728(ra) # 80000cb0 <release>
      return -1;
    80002f90:	57fd                	li	a5,-1
    80002f92:	bff9                	j	80002f70 <sys_sleep+0x88>

0000000080002f94 <sys_kill>:

uint64
sys_kill(void)
{
    80002f94:	1101                	addi	sp,sp,-32
    80002f96:	ec06                	sd	ra,24(sp)
    80002f98:	e822                	sd	s0,16(sp)
    80002f9a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f9c:	fec40593          	addi	a1,s0,-20
    80002fa0:	4501                	li	a0,0
    80002fa2:	00000097          	auipc	ra,0x0
    80002fa6:	d5a080e7          	jalr	-678(ra) # 80002cfc <argint>
    80002faa:	87aa                	mv	a5,a0
    return -1;
    80002fac:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fae:	0007c863          	bltz	a5,80002fbe <sys_kill+0x2a>
  return kill(pid);
    80002fb2:	fec42503          	lw	a0,-20(s0)
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	662080e7          	jalr	1634(ra) # 80002618 <kill>
}
    80002fbe:	60e2                	ld	ra,24(sp)
    80002fc0:	6442                	ld	s0,16(sp)
    80002fc2:	6105                	addi	sp,sp,32
    80002fc4:	8082                	ret

0000000080002fc6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fc6:	1101                	addi	sp,sp,-32
    80002fc8:	ec06                	sd	ra,24(sp)
    80002fca:	e822                	sd	s0,16(sp)
    80002fcc:	e426                	sd	s1,8(sp)
    80002fce:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fd0:	00015517          	auipc	a0,0x15
    80002fd4:	39850513          	addi	a0,a0,920 # 80018368 <tickslock>
    80002fd8:	ffffe097          	auipc	ra,0xffffe
    80002fdc:	c24080e7          	jalr	-988(ra) # 80000bfc <acquire>
  xticks = ticks;
    80002fe0:	00006497          	auipc	s1,0x6
    80002fe4:	0404a483          	lw	s1,64(s1) # 80009020 <ticks>
  release(&tickslock);
    80002fe8:	00015517          	auipc	a0,0x15
    80002fec:	38050513          	addi	a0,a0,896 # 80018368 <tickslock>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	cc0080e7          	jalr	-832(ra) # 80000cb0 <release>
  return xticks;
}
    80002ff8:	02049513          	slli	a0,s1,0x20
    80002ffc:	9101                	srli	a0,a0,0x20
    80002ffe:	60e2                	ld	ra,24(sp)
    80003000:	6442                	ld	s0,16(sp)
    80003002:	64a2                	ld	s1,8(sp)
    80003004:	6105                	addi	sp,sp,32
    80003006:	8082                	ret

0000000080003008 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003008:	7179                	addi	sp,sp,-48
    8000300a:	f406                	sd	ra,40(sp)
    8000300c:	f022                	sd	s0,32(sp)
    8000300e:	ec26                	sd	s1,24(sp)
    80003010:	e84a                	sd	s2,16(sp)
    80003012:	e44e                	sd	s3,8(sp)
    80003014:	e052                	sd	s4,0(sp)
    80003016:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003018:	00005597          	auipc	a1,0x5
    8000301c:	51058593          	addi	a1,a1,1296 # 80008528 <syscalls+0xb0>
    80003020:	00015517          	auipc	a0,0x15
    80003024:	36050513          	addi	a0,a0,864 # 80018380 <bcache>
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	b44080e7          	jalr	-1212(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003030:	0001d797          	auipc	a5,0x1d
    80003034:	35078793          	addi	a5,a5,848 # 80020380 <bcache+0x8000>
    80003038:	0001d717          	auipc	a4,0x1d
    8000303c:	5b070713          	addi	a4,a4,1456 # 800205e8 <bcache+0x8268>
    80003040:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003044:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003048:	00015497          	auipc	s1,0x15
    8000304c:	35048493          	addi	s1,s1,848 # 80018398 <bcache+0x18>
    b->next = bcache.head.next;
    80003050:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003052:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003054:	00005a17          	auipc	s4,0x5
    80003058:	4dca0a13          	addi	s4,s4,1244 # 80008530 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000305c:	2b893783          	ld	a5,696(s2)
    80003060:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003062:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003066:	85d2                	mv	a1,s4
    80003068:	01048513          	addi	a0,s1,16
    8000306c:	00001097          	auipc	ra,0x1
    80003070:	4b2080e7          	jalr	1202(ra) # 8000451e <initsleeplock>
    bcache.head.next->prev = b;
    80003074:	2b893783          	ld	a5,696(s2)
    80003078:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000307a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000307e:	45848493          	addi	s1,s1,1112
    80003082:	fd349de3          	bne	s1,s3,8000305c <binit+0x54>
  }
}
    80003086:	70a2                	ld	ra,40(sp)
    80003088:	7402                	ld	s0,32(sp)
    8000308a:	64e2                	ld	s1,24(sp)
    8000308c:	6942                	ld	s2,16(sp)
    8000308e:	69a2                	ld	s3,8(sp)
    80003090:	6a02                	ld	s4,0(sp)
    80003092:	6145                	addi	sp,sp,48
    80003094:	8082                	ret

0000000080003096 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003096:	7179                	addi	sp,sp,-48
    80003098:	f406                	sd	ra,40(sp)
    8000309a:	f022                	sd	s0,32(sp)
    8000309c:	ec26                	sd	s1,24(sp)
    8000309e:	e84a                	sd	s2,16(sp)
    800030a0:	e44e                	sd	s3,8(sp)
    800030a2:	1800                	addi	s0,sp,48
    800030a4:	892a                	mv	s2,a0
    800030a6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030a8:	00015517          	auipc	a0,0x15
    800030ac:	2d850513          	addi	a0,a0,728 # 80018380 <bcache>
    800030b0:	ffffe097          	auipc	ra,0xffffe
    800030b4:	b4c080e7          	jalr	-1204(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030b8:	0001d497          	auipc	s1,0x1d
    800030bc:	5804b483          	ld	s1,1408(s1) # 80020638 <bcache+0x82b8>
    800030c0:	0001d797          	auipc	a5,0x1d
    800030c4:	52878793          	addi	a5,a5,1320 # 800205e8 <bcache+0x8268>
    800030c8:	02f48f63          	beq	s1,a5,80003106 <bread+0x70>
    800030cc:	873e                	mv	a4,a5
    800030ce:	a021                	j	800030d6 <bread+0x40>
    800030d0:	68a4                	ld	s1,80(s1)
    800030d2:	02e48a63          	beq	s1,a4,80003106 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030d6:	449c                	lw	a5,8(s1)
    800030d8:	ff279ce3          	bne	a5,s2,800030d0 <bread+0x3a>
    800030dc:	44dc                	lw	a5,12(s1)
    800030de:	ff3799e3          	bne	a5,s3,800030d0 <bread+0x3a>
      b->refcnt++;
    800030e2:	40bc                	lw	a5,64(s1)
    800030e4:	2785                	addiw	a5,a5,1
    800030e6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030e8:	00015517          	auipc	a0,0x15
    800030ec:	29850513          	addi	a0,a0,664 # 80018380 <bcache>
    800030f0:	ffffe097          	auipc	ra,0xffffe
    800030f4:	bc0080e7          	jalr	-1088(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    800030f8:	01048513          	addi	a0,s1,16
    800030fc:	00001097          	auipc	ra,0x1
    80003100:	45c080e7          	jalr	1116(ra) # 80004558 <acquiresleep>
      return b;
    80003104:	a8b9                	j	80003162 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003106:	0001d497          	auipc	s1,0x1d
    8000310a:	52a4b483          	ld	s1,1322(s1) # 80020630 <bcache+0x82b0>
    8000310e:	0001d797          	auipc	a5,0x1d
    80003112:	4da78793          	addi	a5,a5,1242 # 800205e8 <bcache+0x8268>
    80003116:	00f48863          	beq	s1,a5,80003126 <bread+0x90>
    8000311a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000311c:	40bc                	lw	a5,64(s1)
    8000311e:	cf81                	beqz	a5,80003136 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003120:	64a4                	ld	s1,72(s1)
    80003122:	fee49de3          	bne	s1,a4,8000311c <bread+0x86>
  panic("bget: no buffers");
    80003126:	00005517          	auipc	a0,0x5
    8000312a:	41250513          	addi	a0,a0,1042 # 80008538 <syscalls+0xc0>
    8000312e:	ffffd097          	auipc	ra,0xffffd
    80003132:	412080e7          	jalr	1042(ra) # 80000540 <panic>
      b->dev = dev;
    80003136:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000313a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000313e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003142:	4785                	li	a5,1
    80003144:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003146:	00015517          	auipc	a0,0x15
    8000314a:	23a50513          	addi	a0,a0,570 # 80018380 <bcache>
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	b62080e7          	jalr	-1182(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    80003156:	01048513          	addi	a0,s1,16
    8000315a:	00001097          	auipc	ra,0x1
    8000315e:	3fe080e7          	jalr	1022(ra) # 80004558 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003162:	409c                	lw	a5,0(s1)
    80003164:	cb89                	beqz	a5,80003176 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003166:	8526                	mv	a0,s1
    80003168:	70a2                	ld	ra,40(sp)
    8000316a:	7402                	ld	s0,32(sp)
    8000316c:	64e2                	ld	s1,24(sp)
    8000316e:	6942                	ld	s2,16(sp)
    80003170:	69a2                	ld	s3,8(sp)
    80003172:	6145                	addi	sp,sp,48
    80003174:	8082                	ret
    virtio_disk_rw(b, 0);
    80003176:	4581                	li	a1,0
    80003178:	8526                	mv	a0,s1
    8000317a:	00003097          	auipc	ra,0x3
    8000317e:	f32080e7          	jalr	-206(ra) # 800060ac <virtio_disk_rw>
    b->valid = 1;
    80003182:	4785                	li	a5,1
    80003184:	c09c                	sw	a5,0(s1)
  return b;
    80003186:	b7c5                	j	80003166 <bread+0xd0>

0000000080003188 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003188:	1101                	addi	sp,sp,-32
    8000318a:	ec06                	sd	ra,24(sp)
    8000318c:	e822                	sd	s0,16(sp)
    8000318e:	e426                	sd	s1,8(sp)
    80003190:	1000                	addi	s0,sp,32
    80003192:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003194:	0541                	addi	a0,a0,16
    80003196:	00001097          	auipc	ra,0x1
    8000319a:	45c080e7          	jalr	1116(ra) # 800045f2 <holdingsleep>
    8000319e:	cd01                	beqz	a0,800031b6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031a0:	4585                	li	a1,1
    800031a2:	8526                	mv	a0,s1
    800031a4:	00003097          	auipc	ra,0x3
    800031a8:	f08080e7          	jalr	-248(ra) # 800060ac <virtio_disk_rw>
}
    800031ac:	60e2                	ld	ra,24(sp)
    800031ae:	6442                	ld	s0,16(sp)
    800031b0:	64a2                	ld	s1,8(sp)
    800031b2:	6105                	addi	sp,sp,32
    800031b4:	8082                	ret
    panic("bwrite");
    800031b6:	00005517          	auipc	a0,0x5
    800031ba:	39a50513          	addi	a0,a0,922 # 80008550 <syscalls+0xd8>
    800031be:	ffffd097          	auipc	ra,0xffffd
    800031c2:	382080e7          	jalr	898(ra) # 80000540 <panic>

00000000800031c6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	e426                	sd	s1,8(sp)
    800031ce:	e04a                	sd	s2,0(sp)
    800031d0:	1000                	addi	s0,sp,32
    800031d2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031d4:	01050913          	addi	s2,a0,16
    800031d8:	854a                	mv	a0,s2
    800031da:	00001097          	auipc	ra,0x1
    800031de:	418080e7          	jalr	1048(ra) # 800045f2 <holdingsleep>
    800031e2:	c92d                	beqz	a0,80003254 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031e4:	854a                	mv	a0,s2
    800031e6:	00001097          	auipc	ra,0x1
    800031ea:	3c8080e7          	jalr	968(ra) # 800045ae <releasesleep>

  acquire(&bcache.lock);
    800031ee:	00015517          	auipc	a0,0x15
    800031f2:	19250513          	addi	a0,a0,402 # 80018380 <bcache>
    800031f6:	ffffe097          	auipc	ra,0xffffe
    800031fa:	a06080e7          	jalr	-1530(ra) # 80000bfc <acquire>
  b->refcnt--;
    800031fe:	40bc                	lw	a5,64(s1)
    80003200:	37fd                	addiw	a5,a5,-1
    80003202:	0007871b          	sext.w	a4,a5
    80003206:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003208:	eb05                	bnez	a4,80003238 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000320a:	68bc                	ld	a5,80(s1)
    8000320c:	64b8                	ld	a4,72(s1)
    8000320e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003210:	64bc                	ld	a5,72(s1)
    80003212:	68b8                	ld	a4,80(s1)
    80003214:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003216:	0001d797          	auipc	a5,0x1d
    8000321a:	16a78793          	addi	a5,a5,362 # 80020380 <bcache+0x8000>
    8000321e:	2b87b703          	ld	a4,696(a5)
    80003222:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003224:	0001d717          	auipc	a4,0x1d
    80003228:	3c470713          	addi	a4,a4,964 # 800205e8 <bcache+0x8268>
    8000322c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000322e:	2b87b703          	ld	a4,696(a5)
    80003232:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003234:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003238:	00015517          	auipc	a0,0x15
    8000323c:	14850513          	addi	a0,a0,328 # 80018380 <bcache>
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	a70080e7          	jalr	-1424(ra) # 80000cb0 <release>
}
    80003248:	60e2                	ld	ra,24(sp)
    8000324a:	6442                	ld	s0,16(sp)
    8000324c:	64a2                	ld	s1,8(sp)
    8000324e:	6902                	ld	s2,0(sp)
    80003250:	6105                	addi	sp,sp,32
    80003252:	8082                	ret
    panic("brelse");
    80003254:	00005517          	auipc	a0,0x5
    80003258:	30450513          	addi	a0,a0,772 # 80008558 <syscalls+0xe0>
    8000325c:	ffffd097          	auipc	ra,0xffffd
    80003260:	2e4080e7          	jalr	740(ra) # 80000540 <panic>

0000000080003264 <bpin>:

void
bpin(struct buf *b) {
    80003264:	1101                	addi	sp,sp,-32
    80003266:	ec06                	sd	ra,24(sp)
    80003268:	e822                	sd	s0,16(sp)
    8000326a:	e426                	sd	s1,8(sp)
    8000326c:	1000                	addi	s0,sp,32
    8000326e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003270:	00015517          	auipc	a0,0x15
    80003274:	11050513          	addi	a0,a0,272 # 80018380 <bcache>
    80003278:	ffffe097          	auipc	ra,0xffffe
    8000327c:	984080e7          	jalr	-1660(ra) # 80000bfc <acquire>
  b->refcnt++;
    80003280:	40bc                	lw	a5,64(s1)
    80003282:	2785                	addiw	a5,a5,1
    80003284:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003286:	00015517          	auipc	a0,0x15
    8000328a:	0fa50513          	addi	a0,a0,250 # 80018380 <bcache>
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	a22080e7          	jalr	-1502(ra) # 80000cb0 <release>
}
    80003296:	60e2                	ld	ra,24(sp)
    80003298:	6442                	ld	s0,16(sp)
    8000329a:	64a2                	ld	s1,8(sp)
    8000329c:	6105                	addi	sp,sp,32
    8000329e:	8082                	ret

00000000800032a0 <bunpin>:

void
bunpin(struct buf *b) {
    800032a0:	1101                	addi	sp,sp,-32
    800032a2:	ec06                	sd	ra,24(sp)
    800032a4:	e822                	sd	s0,16(sp)
    800032a6:	e426                	sd	s1,8(sp)
    800032a8:	1000                	addi	s0,sp,32
    800032aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032ac:	00015517          	auipc	a0,0x15
    800032b0:	0d450513          	addi	a0,a0,212 # 80018380 <bcache>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	948080e7          	jalr	-1720(ra) # 80000bfc <acquire>
  b->refcnt--;
    800032bc:	40bc                	lw	a5,64(s1)
    800032be:	37fd                	addiw	a5,a5,-1
    800032c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032c2:	00015517          	auipc	a0,0x15
    800032c6:	0be50513          	addi	a0,a0,190 # 80018380 <bcache>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	9e6080e7          	jalr	-1562(ra) # 80000cb0 <release>
}
    800032d2:	60e2                	ld	ra,24(sp)
    800032d4:	6442                	ld	s0,16(sp)
    800032d6:	64a2                	ld	s1,8(sp)
    800032d8:	6105                	addi	sp,sp,32
    800032da:	8082                	ret

00000000800032dc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032dc:	1101                	addi	sp,sp,-32
    800032de:	ec06                	sd	ra,24(sp)
    800032e0:	e822                	sd	s0,16(sp)
    800032e2:	e426                	sd	s1,8(sp)
    800032e4:	e04a                	sd	s2,0(sp)
    800032e6:	1000                	addi	s0,sp,32
    800032e8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032ea:	00d5d59b          	srliw	a1,a1,0xd
    800032ee:	0001d797          	auipc	a5,0x1d
    800032f2:	76e7a783          	lw	a5,1902(a5) # 80020a5c <sb+0x1c>
    800032f6:	9dbd                	addw	a1,a1,a5
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	d9e080e7          	jalr	-610(ra) # 80003096 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003300:	0074f713          	andi	a4,s1,7
    80003304:	4785                	li	a5,1
    80003306:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000330a:	14ce                	slli	s1,s1,0x33
    8000330c:	90d9                	srli	s1,s1,0x36
    8000330e:	00950733          	add	a4,a0,s1
    80003312:	05874703          	lbu	a4,88(a4)
    80003316:	00e7f6b3          	and	a3,a5,a4
    8000331a:	c69d                	beqz	a3,80003348 <bfree+0x6c>
    8000331c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000331e:	94aa                	add	s1,s1,a0
    80003320:	fff7c793          	not	a5,a5
    80003324:	8ff9                	and	a5,a5,a4
    80003326:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000332a:	00001097          	auipc	ra,0x1
    8000332e:	106080e7          	jalr	262(ra) # 80004430 <log_write>
  brelse(bp);
    80003332:	854a                	mv	a0,s2
    80003334:	00000097          	auipc	ra,0x0
    80003338:	e92080e7          	jalr	-366(ra) # 800031c6 <brelse>
}
    8000333c:	60e2                	ld	ra,24(sp)
    8000333e:	6442                	ld	s0,16(sp)
    80003340:	64a2                	ld	s1,8(sp)
    80003342:	6902                	ld	s2,0(sp)
    80003344:	6105                	addi	sp,sp,32
    80003346:	8082                	ret
    panic("freeing free block");
    80003348:	00005517          	auipc	a0,0x5
    8000334c:	21850513          	addi	a0,a0,536 # 80008560 <syscalls+0xe8>
    80003350:	ffffd097          	auipc	ra,0xffffd
    80003354:	1f0080e7          	jalr	496(ra) # 80000540 <panic>

0000000080003358 <balloc>:
{
    80003358:	711d                	addi	sp,sp,-96
    8000335a:	ec86                	sd	ra,88(sp)
    8000335c:	e8a2                	sd	s0,80(sp)
    8000335e:	e4a6                	sd	s1,72(sp)
    80003360:	e0ca                	sd	s2,64(sp)
    80003362:	fc4e                	sd	s3,56(sp)
    80003364:	f852                	sd	s4,48(sp)
    80003366:	f456                	sd	s5,40(sp)
    80003368:	f05a                	sd	s6,32(sp)
    8000336a:	ec5e                	sd	s7,24(sp)
    8000336c:	e862                	sd	s8,16(sp)
    8000336e:	e466                	sd	s9,8(sp)
    80003370:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003372:	0001d797          	auipc	a5,0x1d
    80003376:	6d27a783          	lw	a5,1746(a5) # 80020a44 <sb+0x4>
    8000337a:	cbd1                	beqz	a5,8000340e <balloc+0xb6>
    8000337c:	8baa                	mv	s7,a0
    8000337e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003380:	0001db17          	auipc	s6,0x1d
    80003384:	6c0b0b13          	addi	s6,s6,1728 # 80020a40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003388:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000338a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000338c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000338e:	6c89                	lui	s9,0x2
    80003390:	a831                	j	800033ac <balloc+0x54>
    brelse(bp);
    80003392:	854a                	mv	a0,s2
    80003394:	00000097          	auipc	ra,0x0
    80003398:	e32080e7          	jalr	-462(ra) # 800031c6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000339c:	015c87bb          	addw	a5,s9,s5
    800033a0:	00078a9b          	sext.w	s5,a5
    800033a4:	004b2703          	lw	a4,4(s6)
    800033a8:	06eaf363          	bgeu	s5,a4,8000340e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033ac:	41fad79b          	sraiw	a5,s5,0x1f
    800033b0:	0137d79b          	srliw	a5,a5,0x13
    800033b4:	015787bb          	addw	a5,a5,s5
    800033b8:	40d7d79b          	sraiw	a5,a5,0xd
    800033bc:	01cb2583          	lw	a1,28(s6)
    800033c0:	9dbd                	addw	a1,a1,a5
    800033c2:	855e                	mv	a0,s7
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	cd2080e7          	jalr	-814(ra) # 80003096 <bread>
    800033cc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ce:	004b2503          	lw	a0,4(s6)
    800033d2:	000a849b          	sext.w	s1,s5
    800033d6:	8662                	mv	a2,s8
    800033d8:	faa4fde3          	bgeu	s1,a0,80003392 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033dc:	41f6579b          	sraiw	a5,a2,0x1f
    800033e0:	01d7d69b          	srliw	a3,a5,0x1d
    800033e4:	00c6873b          	addw	a4,a3,a2
    800033e8:	00777793          	andi	a5,a4,7
    800033ec:	9f95                	subw	a5,a5,a3
    800033ee:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033f2:	4037571b          	sraiw	a4,a4,0x3
    800033f6:	00e906b3          	add	a3,s2,a4
    800033fa:	0586c683          	lbu	a3,88(a3)
    800033fe:	00d7f5b3          	and	a1,a5,a3
    80003402:	cd91                	beqz	a1,8000341e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003404:	2605                	addiw	a2,a2,1
    80003406:	2485                	addiw	s1,s1,1
    80003408:	fd4618e3          	bne	a2,s4,800033d8 <balloc+0x80>
    8000340c:	b759                	j	80003392 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000340e:	00005517          	auipc	a0,0x5
    80003412:	16a50513          	addi	a0,a0,362 # 80008578 <syscalls+0x100>
    80003416:	ffffd097          	auipc	ra,0xffffd
    8000341a:	12a080e7          	jalr	298(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000341e:	974a                	add	a4,a4,s2
    80003420:	8fd5                	or	a5,a5,a3
    80003422:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003426:	854a                	mv	a0,s2
    80003428:	00001097          	auipc	ra,0x1
    8000342c:	008080e7          	jalr	8(ra) # 80004430 <log_write>
        brelse(bp);
    80003430:	854a                	mv	a0,s2
    80003432:	00000097          	auipc	ra,0x0
    80003436:	d94080e7          	jalr	-620(ra) # 800031c6 <brelse>
  bp = bread(dev, bno);
    8000343a:	85a6                	mv	a1,s1
    8000343c:	855e                	mv	a0,s7
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	c58080e7          	jalr	-936(ra) # 80003096 <bread>
    80003446:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003448:	40000613          	li	a2,1024
    8000344c:	4581                	li	a1,0
    8000344e:	05850513          	addi	a0,a0,88
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	8a6080e7          	jalr	-1882(ra) # 80000cf8 <memset>
  log_write(bp);
    8000345a:	854a                	mv	a0,s2
    8000345c:	00001097          	auipc	ra,0x1
    80003460:	fd4080e7          	jalr	-44(ra) # 80004430 <log_write>
  brelse(bp);
    80003464:	854a                	mv	a0,s2
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	d60080e7          	jalr	-672(ra) # 800031c6 <brelse>
}
    8000346e:	8526                	mv	a0,s1
    80003470:	60e6                	ld	ra,88(sp)
    80003472:	6446                	ld	s0,80(sp)
    80003474:	64a6                	ld	s1,72(sp)
    80003476:	6906                	ld	s2,64(sp)
    80003478:	79e2                	ld	s3,56(sp)
    8000347a:	7a42                	ld	s4,48(sp)
    8000347c:	7aa2                	ld	s5,40(sp)
    8000347e:	7b02                	ld	s6,32(sp)
    80003480:	6be2                	ld	s7,24(sp)
    80003482:	6c42                	ld	s8,16(sp)
    80003484:	6ca2                	ld	s9,8(sp)
    80003486:	6125                	addi	sp,sp,96
    80003488:	8082                	ret

000000008000348a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000348a:	7179                	addi	sp,sp,-48
    8000348c:	f406                	sd	ra,40(sp)
    8000348e:	f022                	sd	s0,32(sp)
    80003490:	ec26                	sd	s1,24(sp)
    80003492:	e84a                	sd	s2,16(sp)
    80003494:	e44e                	sd	s3,8(sp)
    80003496:	e052                	sd	s4,0(sp)
    80003498:	1800                	addi	s0,sp,48
    8000349a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000349c:	47ad                	li	a5,11
    8000349e:	04b7fe63          	bgeu	a5,a1,800034fa <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034a2:	ff45849b          	addiw	s1,a1,-12
    800034a6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034aa:	0ff00793          	li	a5,255
    800034ae:	0ae7e463          	bltu	a5,a4,80003556 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034b2:	08052583          	lw	a1,128(a0)
    800034b6:	c5b5                	beqz	a1,80003522 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034b8:	00092503          	lw	a0,0(s2)
    800034bc:	00000097          	auipc	ra,0x0
    800034c0:	bda080e7          	jalr	-1062(ra) # 80003096 <bread>
    800034c4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034c6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034ca:	02049713          	slli	a4,s1,0x20
    800034ce:	01e75593          	srli	a1,a4,0x1e
    800034d2:	00b784b3          	add	s1,a5,a1
    800034d6:	0004a983          	lw	s3,0(s1)
    800034da:	04098e63          	beqz	s3,80003536 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034de:	8552                	mv	a0,s4
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	ce6080e7          	jalr	-794(ra) # 800031c6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034e8:	854e                	mv	a0,s3
    800034ea:	70a2                	ld	ra,40(sp)
    800034ec:	7402                	ld	s0,32(sp)
    800034ee:	64e2                	ld	s1,24(sp)
    800034f0:	6942                	ld	s2,16(sp)
    800034f2:	69a2                	ld	s3,8(sp)
    800034f4:	6a02                	ld	s4,0(sp)
    800034f6:	6145                	addi	sp,sp,48
    800034f8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034fa:	02059793          	slli	a5,a1,0x20
    800034fe:	01e7d593          	srli	a1,a5,0x1e
    80003502:	00b504b3          	add	s1,a0,a1
    80003506:	0504a983          	lw	s3,80(s1)
    8000350a:	fc099fe3          	bnez	s3,800034e8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000350e:	4108                	lw	a0,0(a0)
    80003510:	00000097          	auipc	ra,0x0
    80003514:	e48080e7          	jalr	-440(ra) # 80003358 <balloc>
    80003518:	0005099b          	sext.w	s3,a0
    8000351c:	0534a823          	sw	s3,80(s1)
    80003520:	b7e1                	j	800034e8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003522:	4108                	lw	a0,0(a0)
    80003524:	00000097          	auipc	ra,0x0
    80003528:	e34080e7          	jalr	-460(ra) # 80003358 <balloc>
    8000352c:	0005059b          	sext.w	a1,a0
    80003530:	08b92023          	sw	a1,128(s2)
    80003534:	b751                	j	800034b8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003536:	00092503          	lw	a0,0(s2)
    8000353a:	00000097          	auipc	ra,0x0
    8000353e:	e1e080e7          	jalr	-482(ra) # 80003358 <balloc>
    80003542:	0005099b          	sext.w	s3,a0
    80003546:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000354a:	8552                	mv	a0,s4
    8000354c:	00001097          	auipc	ra,0x1
    80003550:	ee4080e7          	jalr	-284(ra) # 80004430 <log_write>
    80003554:	b769                	j	800034de <bmap+0x54>
  panic("bmap: out of range");
    80003556:	00005517          	auipc	a0,0x5
    8000355a:	03a50513          	addi	a0,a0,58 # 80008590 <syscalls+0x118>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	fe2080e7          	jalr	-30(ra) # 80000540 <panic>

0000000080003566 <iget>:
{
    80003566:	7179                	addi	sp,sp,-48
    80003568:	f406                	sd	ra,40(sp)
    8000356a:	f022                	sd	s0,32(sp)
    8000356c:	ec26                	sd	s1,24(sp)
    8000356e:	e84a                	sd	s2,16(sp)
    80003570:	e44e                	sd	s3,8(sp)
    80003572:	e052                	sd	s4,0(sp)
    80003574:	1800                	addi	s0,sp,48
    80003576:	89aa                	mv	s3,a0
    80003578:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000357a:	0001d517          	auipc	a0,0x1d
    8000357e:	4e650513          	addi	a0,a0,1254 # 80020a60 <icache>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	67a080e7          	jalr	1658(ra) # 80000bfc <acquire>
  empty = 0;
    8000358a:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000358c:	0001d497          	auipc	s1,0x1d
    80003590:	4ec48493          	addi	s1,s1,1260 # 80020a78 <icache+0x18>
    80003594:	0001f697          	auipc	a3,0x1f
    80003598:	f7468693          	addi	a3,a3,-140 # 80022508 <log>
    8000359c:	a039                	j	800035aa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000359e:	02090b63          	beqz	s2,800035d4 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035a2:	08848493          	addi	s1,s1,136
    800035a6:	02d48a63          	beq	s1,a3,800035da <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035aa:	449c                	lw	a5,8(s1)
    800035ac:	fef059e3          	blez	a5,8000359e <iget+0x38>
    800035b0:	4098                	lw	a4,0(s1)
    800035b2:	ff3716e3          	bne	a4,s3,8000359e <iget+0x38>
    800035b6:	40d8                	lw	a4,4(s1)
    800035b8:	ff4713e3          	bne	a4,s4,8000359e <iget+0x38>
      ip->ref++;
    800035bc:	2785                	addiw	a5,a5,1
    800035be:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800035c0:	0001d517          	auipc	a0,0x1d
    800035c4:	4a050513          	addi	a0,a0,1184 # 80020a60 <icache>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	6e8080e7          	jalr	1768(ra) # 80000cb0 <release>
      return ip;
    800035d0:	8926                	mv	s2,s1
    800035d2:	a03d                	j	80003600 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035d4:	f7f9                	bnez	a5,800035a2 <iget+0x3c>
    800035d6:	8926                	mv	s2,s1
    800035d8:	b7e9                	j	800035a2 <iget+0x3c>
  if(empty == 0)
    800035da:	02090c63          	beqz	s2,80003612 <iget+0xac>
  ip->dev = dev;
    800035de:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035e2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035e6:	4785                	li	a5,1
    800035e8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035ec:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800035f0:	0001d517          	auipc	a0,0x1d
    800035f4:	47050513          	addi	a0,a0,1136 # 80020a60 <icache>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	6b8080e7          	jalr	1720(ra) # 80000cb0 <release>
}
    80003600:	854a                	mv	a0,s2
    80003602:	70a2                	ld	ra,40(sp)
    80003604:	7402                	ld	s0,32(sp)
    80003606:	64e2                	ld	s1,24(sp)
    80003608:	6942                	ld	s2,16(sp)
    8000360a:	69a2                	ld	s3,8(sp)
    8000360c:	6a02                	ld	s4,0(sp)
    8000360e:	6145                	addi	sp,sp,48
    80003610:	8082                	ret
    panic("iget: no inodes");
    80003612:	00005517          	auipc	a0,0x5
    80003616:	f9650513          	addi	a0,a0,-106 # 800085a8 <syscalls+0x130>
    8000361a:	ffffd097          	auipc	ra,0xffffd
    8000361e:	f26080e7          	jalr	-218(ra) # 80000540 <panic>

0000000080003622 <fsinit>:
fsinit(int dev) {
    80003622:	7179                	addi	sp,sp,-48
    80003624:	f406                	sd	ra,40(sp)
    80003626:	f022                	sd	s0,32(sp)
    80003628:	ec26                	sd	s1,24(sp)
    8000362a:	e84a                	sd	s2,16(sp)
    8000362c:	e44e                	sd	s3,8(sp)
    8000362e:	1800                	addi	s0,sp,48
    80003630:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003632:	4585                	li	a1,1
    80003634:	00000097          	auipc	ra,0x0
    80003638:	a62080e7          	jalr	-1438(ra) # 80003096 <bread>
    8000363c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000363e:	0001d997          	auipc	s3,0x1d
    80003642:	40298993          	addi	s3,s3,1026 # 80020a40 <sb>
    80003646:	02000613          	li	a2,32
    8000364a:	05850593          	addi	a1,a0,88
    8000364e:	854e                	mv	a0,s3
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	704080e7          	jalr	1796(ra) # 80000d54 <memmove>
  brelse(bp);
    80003658:	8526                	mv	a0,s1
    8000365a:	00000097          	auipc	ra,0x0
    8000365e:	b6c080e7          	jalr	-1172(ra) # 800031c6 <brelse>
  if(sb.magic != FSMAGIC)
    80003662:	0009a703          	lw	a4,0(s3)
    80003666:	102037b7          	lui	a5,0x10203
    8000366a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000366e:	02f71263          	bne	a4,a5,80003692 <fsinit+0x70>
  initlog(dev, &sb);
    80003672:	0001d597          	auipc	a1,0x1d
    80003676:	3ce58593          	addi	a1,a1,974 # 80020a40 <sb>
    8000367a:	854a                	mv	a0,s2
    8000367c:	00001097          	auipc	ra,0x1
    80003680:	b3a080e7          	jalr	-1222(ra) # 800041b6 <initlog>
}
    80003684:	70a2                	ld	ra,40(sp)
    80003686:	7402                	ld	s0,32(sp)
    80003688:	64e2                	ld	s1,24(sp)
    8000368a:	6942                	ld	s2,16(sp)
    8000368c:	69a2                	ld	s3,8(sp)
    8000368e:	6145                	addi	sp,sp,48
    80003690:	8082                	ret
    panic("invalid file system");
    80003692:	00005517          	auipc	a0,0x5
    80003696:	f2650513          	addi	a0,a0,-218 # 800085b8 <syscalls+0x140>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	ea6080e7          	jalr	-346(ra) # 80000540 <panic>

00000000800036a2 <iinit>:
{
    800036a2:	7179                	addi	sp,sp,-48
    800036a4:	f406                	sd	ra,40(sp)
    800036a6:	f022                	sd	s0,32(sp)
    800036a8:	ec26                	sd	s1,24(sp)
    800036aa:	e84a                	sd	s2,16(sp)
    800036ac:	e44e                	sd	s3,8(sp)
    800036ae:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800036b0:	00005597          	auipc	a1,0x5
    800036b4:	f2058593          	addi	a1,a1,-224 # 800085d0 <syscalls+0x158>
    800036b8:	0001d517          	auipc	a0,0x1d
    800036bc:	3a850513          	addi	a0,a0,936 # 80020a60 <icache>
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	4ac080e7          	jalr	1196(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    800036c8:	0001d497          	auipc	s1,0x1d
    800036cc:	3c048493          	addi	s1,s1,960 # 80020a88 <icache+0x28>
    800036d0:	0001f997          	auipc	s3,0x1f
    800036d4:	e4898993          	addi	s3,s3,-440 # 80022518 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800036d8:	00005917          	auipc	s2,0x5
    800036dc:	f0090913          	addi	s2,s2,-256 # 800085d8 <syscalls+0x160>
    800036e0:	85ca                	mv	a1,s2
    800036e2:	8526                	mv	a0,s1
    800036e4:	00001097          	auipc	ra,0x1
    800036e8:	e3a080e7          	jalr	-454(ra) # 8000451e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036ec:	08848493          	addi	s1,s1,136
    800036f0:	ff3498e3          	bne	s1,s3,800036e0 <iinit+0x3e>
}
    800036f4:	70a2                	ld	ra,40(sp)
    800036f6:	7402                	ld	s0,32(sp)
    800036f8:	64e2                	ld	s1,24(sp)
    800036fa:	6942                	ld	s2,16(sp)
    800036fc:	69a2                	ld	s3,8(sp)
    800036fe:	6145                	addi	sp,sp,48
    80003700:	8082                	ret

0000000080003702 <ialloc>:
{
    80003702:	715d                	addi	sp,sp,-80
    80003704:	e486                	sd	ra,72(sp)
    80003706:	e0a2                	sd	s0,64(sp)
    80003708:	fc26                	sd	s1,56(sp)
    8000370a:	f84a                	sd	s2,48(sp)
    8000370c:	f44e                	sd	s3,40(sp)
    8000370e:	f052                	sd	s4,32(sp)
    80003710:	ec56                	sd	s5,24(sp)
    80003712:	e85a                	sd	s6,16(sp)
    80003714:	e45e                	sd	s7,8(sp)
    80003716:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003718:	0001d717          	auipc	a4,0x1d
    8000371c:	33472703          	lw	a4,820(a4) # 80020a4c <sb+0xc>
    80003720:	4785                	li	a5,1
    80003722:	04e7fa63          	bgeu	a5,a4,80003776 <ialloc+0x74>
    80003726:	8aaa                	mv	s5,a0
    80003728:	8bae                	mv	s7,a1
    8000372a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000372c:	0001da17          	auipc	s4,0x1d
    80003730:	314a0a13          	addi	s4,s4,788 # 80020a40 <sb>
    80003734:	00048b1b          	sext.w	s6,s1
    80003738:	0044d793          	srli	a5,s1,0x4
    8000373c:	018a2583          	lw	a1,24(s4)
    80003740:	9dbd                	addw	a1,a1,a5
    80003742:	8556                	mv	a0,s5
    80003744:	00000097          	auipc	ra,0x0
    80003748:	952080e7          	jalr	-1710(ra) # 80003096 <bread>
    8000374c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000374e:	05850993          	addi	s3,a0,88
    80003752:	00f4f793          	andi	a5,s1,15
    80003756:	079a                	slli	a5,a5,0x6
    80003758:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000375a:	00099783          	lh	a5,0(s3)
    8000375e:	c785                	beqz	a5,80003786 <ialloc+0x84>
    brelse(bp);
    80003760:	00000097          	auipc	ra,0x0
    80003764:	a66080e7          	jalr	-1434(ra) # 800031c6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003768:	0485                	addi	s1,s1,1
    8000376a:	00ca2703          	lw	a4,12(s4)
    8000376e:	0004879b          	sext.w	a5,s1
    80003772:	fce7e1e3          	bltu	a5,a4,80003734 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003776:	00005517          	auipc	a0,0x5
    8000377a:	e6a50513          	addi	a0,a0,-406 # 800085e0 <syscalls+0x168>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	dc2080e7          	jalr	-574(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    80003786:	04000613          	li	a2,64
    8000378a:	4581                	li	a1,0
    8000378c:	854e                	mv	a0,s3
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	56a080e7          	jalr	1386(ra) # 80000cf8 <memset>
      dip->type = type;
    80003796:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000379a:	854a                	mv	a0,s2
    8000379c:	00001097          	auipc	ra,0x1
    800037a0:	c94080e7          	jalr	-876(ra) # 80004430 <log_write>
      brelse(bp);
    800037a4:	854a                	mv	a0,s2
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	a20080e7          	jalr	-1504(ra) # 800031c6 <brelse>
      return iget(dev, inum);
    800037ae:	85da                	mv	a1,s6
    800037b0:	8556                	mv	a0,s5
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	db4080e7          	jalr	-588(ra) # 80003566 <iget>
}
    800037ba:	60a6                	ld	ra,72(sp)
    800037bc:	6406                	ld	s0,64(sp)
    800037be:	74e2                	ld	s1,56(sp)
    800037c0:	7942                	ld	s2,48(sp)
    800037c2:	79a2                	ld	s3,40(sp)
    800037c4:	7a02                	ld	s4,32(sp)
    800037c6:	6ae2                	ld	s5,24(sp)
    800037c8:	6b42                	ld	s6,16(sp)
    800037ca:	6ba2                	ld	s7,8(sp)
    800037cc:	6161                	addi	sp,sp,80
    800037ce:	8082                	ret

00000000800037d0 <iupdate>:
{
    800037d0:	1101                	addi	sp,sp,-32
    800037d2:	ec06                	sd	ra,24(sp)
    800037d4:	e822                	sd	s0,16(sp)
    800037d6:	e426                	sd	s1,8(sp)
    800037d8:	e04a                	sd	s2,0(sp)
    800037da:	1000                	addi	s0,sp,32
    800037dc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037de:	415c                	lw	a5,4(a0)
    800037e0:	0047d79b          	srliw	a5,a5,0x4
    800037e4:	0001d597          	auipc	a1,0x1d
    800037e8:	2745a583          	lw	a1,628(a1) # 80020a58 <sb+0x18>
    800037ec:	9dbd                	addw	a1,a1,a5
    800037ee:	4108                	lw	a0,0(a0)
    800037f0:	00000097          	auipc	ra,0x0
    800037f4:	8a6080e7          	jalr	-1882(ra) # 80003096 <bread>
    800037f8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037fa:	05850793          	addi	a5,a0,88
    800037fe:	40c8                	lw	a0,4(s1)
    80003800:	893d                	andi	a0,a0,15
    80003802:	051a                	slli	a0,a0,0x6
    80003804:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003806:	04449703          	lh	a4,68(s1)
    8000380a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000380e:	04649703          	lh	a4,70(s1)
    80003812:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003816:	04849703          	lh	a4,72(s1)
    8000381a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000381e:	04a49703          	lh	a4,74(s1)
    80003822:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003826:	44f8                	lw	a4,76(s1)
    80003828:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000382a:	03400613          	li	a2,52
    8000382e:	05048593          	addi	a1,s1,80
    80003832:	0531                	addi	a0,a0,12
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	520080e7          	jalr	1312(ra) # 80000d54 <memmove>
  log_write(bp);
    8000383c:	854a                	mv	a0,s2
    8000383e:	00001097          	auipc	ra,0x1
    80003842:	bf2080e7          	jalr	-1038(ra) # 80004430 <log_write>
  brelse(bp);
    80003846:	854a                	mv	a0,s2
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	97e080e7          	jalr	-1666(ra) # 800031c6 <brelse>
}
    80003850:	60e2                	ld	ra,24(sp)
    80003852:	6442                	ld	s0,16(sp)
    80003854:	64a2                	ld	s1,8(sp)
    80003856:	6902                	ld	s2,0(sp)
    80003858:	6105                	addi	sp,sp,32
    8000385a:	8082                	ret

000000008000385c <idup>:
{
    8000385c:	1101                	addi	sp,sp,-32
    8000385e:	ec06                	sd	ra,24(sp)
    80003860:	e822                	sd	s0,16(sp)
    80003862:	e426                	sd	s1,8(sp)
    80003864:	1000                	addi	s0,sp,32
    80003866:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003868:	0001d517          	auipc	a0,0x1d
    8000386c:	1f850513          	addi	a0,a0,504 # 80020a60 <icache>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	38c080e7          	jalr	908(ra) # 80000bfc <acquire>
  ip->ref++;
    80003878:	449c                	lw	a5,8(s1)
    8000387a:	2785                	addiw	a5,a5,1
    8000387c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000387e:	0001d517          	auipc	a0,0x1d
    80003882:	1e250513          	addi	a0,a0,482 # 80020a60 <icache>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	42a080e7          	jalr	1066(ra) # 80000cb0 <release>
}
    8000388e:	8526                	mv	a0,s1
    80003890:	60e2                	ld	ra,24(sp)
    80003892:	6442                	ld	s0,16(sp)
    80003894:	64a2                	ld	s1,8(sp)
    80003896:	6105                	addi	sp,sp,32
    80003898:	8082                	ret

000000008000389a <ilock>:
{
    8000389a:	1101                	addi	sp,sp,-32
    8000389c:	ec06                	sd	ra,24(sp)
    8000389e:	e822                	sd	s0,16(sp)
    800038a0:	e426                	sd	s1,8(sp)
    800038a2:	e04a                	sd	s2,0(sp)
    800038a4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038a6:	c115                	beqz	a0,800038ca <ilock+0x30>
    800038a8:	84aa                	mv	s1,a0
    800038aa:	451c                	lw	a5,8(a0)
    800038ac:	00f05f63          	blez	a5,800038ca <ilock+0x30>
  acquiresleep(&ip->lock);
    800038b0:	0541                	addi	a0,a0,16
    800038b2:	00001097          	auipc	ra,0x1
    800038b6:	ca6080e7          	jalr	-858(ra) # 80004558 <acquiresleep>
  if(ip->valid == 0){
    800038ba:	40bc                	lw	a5,64(s1)
    800038bc:	cf99                	beqz	a5,800038da <ilock+0x40>
}
    800038be:	60e2                	ld	ra,24(sp)
    800038c0:	6442                	ld	s0,16(sp)
    800038c2:	64a2                	ld	s1,8(sp)
    800038c4:	6902                	ld	s2,0(sp)
    800038c6:	6105                	addi	sp,sp,32
    800038c8:	8082                	ret
    panic("ilock");
    800038ca:	00005517          	auipc	a0,0x5
    800038ce:	d2e50513          	addi	a0,a0,-722 # 800085f8 <syscalls+0x180>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	c6e080e7          	jalr	-914(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038da:	40dc                	lw	a5,4(s1)
    800038dc:	0047d79b          	srliw	a5,a5,0x4
    800038e0:	0001d597          	auipc	a1,0x1d
    800038e4:	1785a583          	lw	a1,376(a1) # 80020a58 <sb+0x18>
    800038e8:	9dbd                	addw	a1,a1,a5
    800038ea:	4088                	lw	a0,0(s1)
    800038ec:	fffff097          	auipc	ra,0xfffff
    800038f0:	7aa080e7          	jalr	1962(ra) # 80003096 <bread>
    800038f4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038f6:	05850593          	addi	a1,a0,88
    800038fa:	40dc                	lw	a5,4(s1)
    800038fc:	8bbd                	andi	a5,a5,15
    800038fe:	079a                	slli	a5,a5,0x6
    80003900:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003902:	00059783          	lh	a5,0(a1)
    80003906:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000390a:	00259783          	lh	a5,2(a1)
    8000390e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003912:	00459783          	lh	a5,4(a1)
    80003916:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000391a:	00659783          	lh	a5,6(a1)
    8000391e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003922:	459c                	lw	a5,8(a1)
    80003924:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003926:	03400613          	li	a2,52
    8000392a:	05b1                	addi	a1,a1,12
    8000392c:	05048513          	addi	a0,s1,80
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	424080e7          	jalr	1060(ra) # 80000d54 <memmove>
    brelse(bp);
    80003938:	854a                	mv	a0,s2
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	88c080e7          	jalr	-1908(ra) # 800031c6 <brelse>
    ip->valid = 1;
    80003942:	4785                	li	a5,1
    80003944:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003946:	04449783          	lh	a5,68(s1)
    8000394a:	fbb5                	bnez	a5,800038be <ilock+0x24>
      panic("ilock: no type");
    8000394c:	00005517          	auipc	a0,0x5
    80003950:	cb450513          	addi	a0,a0,-844 # 80008600 <syscalls+0x188>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	bec080e7          	jalr	-1044(ra) # 80000540 <panic>

000000008000395c <iunlock>:
{
    8000395c:	1101                	addi	sp,sp,-32
    8000395e:	ec06                	sd	ra,24(sp)
    80003960:	e822                	sd	s0,16(sp)
    80003962:	e426                	sd	s1,8(sp)
    80003964:	e04a                	sd	s2,0(sp)
    80003966:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003968:	c905                	beqz	a0,80003998 <iunlock+0x3c>
    8000396a:	84aa                	mv	s1,a0
    8000396c:	01050913          	addi	s2,a0,16
    80003970:	854a                	mv	a0,s2
    80003972:	00001097          	auipc	ra,0x1
    80003976:	c80080e7          	jalr	-896(ra) # 800045f2 <holdingsleep>
    8000397a:	cd19                	beqz	a0,80003998 <iunlock+0x3c>
    8000397c:	449c                	lw	a5,8(s1)
    8000397e:	00f05d63          	blez	a5,80003998 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003982:	854a                	mv	a0,s2
    80003984:	00001097          	auipc	ra,0x1
    80003988:	c2a080e7          	jalr	-982(ra) # 800045ae <releasesleep>
}
    8000398c:	60e2                	ld	ra,24(sp)
    8000398e:	6442                	ld	s0,16(sp)
    80003990:	64a2                	ld	s1,8(sp)
    80003992:	6902                	ld	s2,0(sp)
    80003994:	6105                	addi	sp,sp,32
    80003996:	8082                	ret
    panic("iunlock");
    80003998:	00005517          	auipc	a0,0x5
    8000399c:	c7850513          	addi	a0,a0,-904 # 80008610 <syscalls+0x198>
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	ba0080e7          	jalr	-1120(ra) # 80000540 <panic>

00000000800039a8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039a8:	7179                	addi	sp,sp,-48
    800039aa:	f406                	sd	ra,40(sp)
    800039ac:	f022                	sd	s0,32(sp)
    800039ae:	ec26                	sd	s1,24(sp)
    800039b0:	e84a                	sd	s2,16(sp)
    800039b2:	e44e                	sd	s3,8(sp)
    800039b4:	e052                	sd	s4,0(sp)
    800039b6:	1800                	addi	s0,sp,48
    800039b8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039ba:	05050493          	addi	s1,a0,80
    800039be:	08050913          	addi	s2,a0,128
    800039c2:	a021                	j	800039ca <itrunc+0x22>
    800039c4:	0491                	addi	s1,s1,4
    800039c6:	01248d63          	beq	s1,s2,800039e0 <itrunc+0x38>
    if(ip->addrs[i]){
    800039ca:	408c                	lw	a1,0(s1)
    800039cc:	dde5                	beqz	a1,800039c4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039ce:	0009a503          	lw	a0,0(s3)
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	90a080e7          	jalr	-1782(ra) # 800032dc <bfree>
      ip->addrs[i] = 0;
    800039da:	0004a023          	sw	zero,0(s1)
    800039de:	b7dd                	j	800039c4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039e0:	0809a583          	lw	a1,128(s3)
    800039e4:	e185                	bnez	a1,80003a04 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039e6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039ea:	854e                	mv	a0,s3
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	de4080e7          	jalr	-540(ra) # 800037d0 <iupdate>
}
    800039f4:	70a2                	ld	ra,40(sp)
    800039f6:	7402                	ld	s0,32(sp)
    800039f8:	64e2                	ld	s1,24(sp)
    800039fa:	6942                	ld	s2,16(sp)
    800039fc:	69a2                	ld	s3,8(sp)
    800039fe:	6a02                	ld	s4,0(sp)
    80003a00:	6145                	addi	sp,sp,48
    80003a02:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a04:	0009a503          	lw	a0,0(s3)
    80003a08:	fffff097          	auipc	ra,0xfffff
    80003a0c:	68e080e7          	jalr	1678(ra) # 80003096 <bread>
    80003a10:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a12:	05850493          	addi	s1,a0,88
    80003a16:	45850913          	addi	s2,a0,1112
    80003a1a:	a021                	j	80003a22 <itrunc+0x7a>
    80003a1c:	0491                	addi	s1,s1,4
    80003a1e:	01248b63          	beq	s1,s2,80003a34 <itrunc+0x8c>
      if(a[j])
    80003a22:	408c                	lw	a1,0(s1)
    80003a24:	dde5                	beqz	a1,80003a1c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a26:	0009a503          	lw	a0,0(s3)
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	8b2080e7          	jalr	-1870(ra) # 800032dc <bfree>
    80003a32:	b7ed                	j	80003a1c <itrunc+0x74>
    brelse(bp);
    80003a34:	8552                	mv	a0,s4
    80003a36:	fffff097          	auipc	ra,0xfffff
    80003a3a:	790080e7          	jalr	1936(ra) # 800031c6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a3e:	0809a583          	lw	a1,128(s3)
    80003a42:	0009a503          	lw	a0,0(s3)
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	896080e7          	jalr	-1898(ra) # 800032dc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a4e:	0809a023          	sw	zero,128(s3)
    80003a52:	bf51                	j	800039e6 <itrunc+0x3e>

0000000080003a54 <iput>:
{
    80003a54:	1101                	addi	sp,sp,-32
    80003a56:	ec06                	sd	ra,24(sp)
    80003a58:	e822                	sd	s0,16(sp)
    80003a5a:	e426                	sd	s1,8(sp)
    80003a5c:	e04a                	sd	s2,0(sp)
    80003a5e:	1000                	addi	s0,sp,32
    80003a60:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a62:	0001d517          	auipc	a0,0x1d
    80003a66:	ffe50513          	addi	a0,a0,-2 # 80020a60 <icache>
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	192080e7          	jalr	402(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a72:	4498                	lw	a4,8(s1)
    80003a74:	4785                	li	a5,1
    80003a76:	02f70363          	beq	a4,a5,80003a9c <iput+0x48>
  ip->ref--;
    80003a7a:	449c                	lw	a5,8(s1)
    80003a7c:	37fd                	addiw	a5,a5,-1
    80003a7e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a80:	0001d517          	auipc	a0,0x1d
    80003a84:	fe050513          	addi	a0,a0,-32 # 80020a60 <icache>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	228080e7          	jalr	552(ra) # 80000cb0 <release>
}
    80003a90:	60e2                	ld	ra,24(sp)
    80003a92:	6442                	ld	s0,16(sp)
    80003a94:	64a2                	ld	s1,8(sp)
    80003a96:	6902                	ld	s2,0(sp)
    80003a98:	6105                	addi	sp,sp,32
    80003a9a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a9c:	40bc                	lw	a5,64(s1)
    80003a9e:	dff1                	beqz	a5,80003a7a <iput+0x26>
    80003aa0:	04a49783          	lh	a5,74(s1)
    80003aa4:	fbf9                	bnez	a5,80003a7a <iput+0x26>
    acquiresleep(&ip->lock);
    80003aa6:	01048913          	addi	s2,s1,16
    80003aaa:	854a                	mv	a0,s2
    80003aac:	00001097          	auipc	ra,0x1
    80003ab0:	aac080e7          	jalr	-1364(ra) # 80004558 <acquiresleep>
    release(&icache.lock);
    80003ab4:	0001d517          	auipc	a0,0x1d
    80003ab8:	fac50513          	addi	a0,a0,-84 # 80020a60 <icache>
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	1f4080e7          	jalr	500(ra) # 80000cb0 <release>
    itrunc(ip);
    80003ac4:	8526                	mv	a0,s1
    80003ac6:	00000097          	auipc	ra,0x0
    80003aca:	ee2080e7          	jalr	-286(ra) # 800039a8 <itrunc>
    ip->type = 0;
    80003ace:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ad2:	8526                	mv	a0,s1
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	cfc080e7          	jalr	-772(ra) # 800037d0 <iupdate>
    ip->valid = 0;
    80003adc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	00001097          	auipc	ra,0x1
    80003ae6:	acc080e7          	jalr	-1332(ra) # 800045ae <releasesleep>
    acquire(&icache.lock);
    80003aea:	0001d517          	auipc	a0,0x1d
    80003aee:	f7650513          	addi	a0,a0,-138 # 80020a60 <icache>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	10a080e7          	jalr	266(ra) # 80000bfc <acquire>
    80003afa:	b741                	j	80003a7a <iput+0x26>

0000000080003afc <iunlockput>:
{
    80003afc:	1101                	addi	sp,sp,-32
    80003afe:	ec06                	sd	ra,24(sp)
    80003b00:	e822                	sd	s0,16(sp)
    80003b02:	e426                	sd	s1,8(sp)
    80003b04:	1000                	addi	s0,sp,32
    80003b06:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	e54080e7          	jalr	-428(ra) # 8000395c <iunlock>
  iput(ip);
    80003b10:	8526                	mv	a0,s1
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	f42080e7          	jalr	-190(ra) # 80003a54 <iput>
}
    80003b1a:	60e2                	ld	ra,24(sp)
    80003b1c:	6442                	ld	s0,16(sp)
    80003b1e:	64a2                	ld	s1,8(sp)
    80003b20:	6105                	addi	sp,sp,32
    80003b22:	8082                	ret

0000000080003b24 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b24:	1141                	addi	sp,sp,-16
    80003b26:	e422                	sd	s0,8(sp)
    80003b28:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b2a:	411c                	lw	a5,0(a0)
    80003b2c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b2e:	415c                	lw	a5,4(a0)
    80003b30:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b32:	04451783          	lh	a5,68(a0)
    80003b36:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b3a:	04a51783          	lh	a5,74(a0)
    80003b3e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b42:	04c56783          	lwu	a5,76(a0)
    80003b46:	e99c                	sd	a5,16(a1)
}
    80003b48:	6422                	ld	s0,8(sp)
    80003b4a:	0141                	addi	sp,sp,16
    80003b4c:	8082                	ret

0000000080003b4e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b4e:	457c                	lw	a5,76(a0)
    80003b50:	0ed7e863          	bltu	a5,a3,80003c40 <readi+0xf2>
{
    80003b54:	7159                	addi	sp,sp,-112
    80003b56:	f486                	sd	ra,104(sp)
    80003b58:	f0a2                	sd	s0,96(sp)
    80003b5a:	eca6                	sd	s1,88(sp)
    80003b5c:	e8ca                	sd	s2,80(sp)
    80003b5e:	e4ce                	sd	s3,72(sp)
    80003b60:	e0d2                	sd	s4,64(sp)
    80003b62:	fc56                	sd	s5,56(sp)
    80003b64:	f85a                	sd	s6,48(sp)
    80003b66:	f45e                	sd	s7,40(sp)
    80003b68:	f062                	sd	s8,32(sp)
    80003b6a:	ec66                	sd	s9,24(sp)
    80003b6c:	e86a                	sd	s10,16(sp)
    80003b6e:	e46e                	sd	s11,8(sp)
    80003b70:	1880                	addi	s0,sp,112
    80003b72:	8baa                	mv	s7,a0
    80003b74:	8c2e                	mv	s8,a1
    80003b76:	8ab2                	mv	s5,a2
    80003b78:	84b6                	mv	s1,a3
    80003b7a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b7c:	9f35                	addw	a4,a4,a3
    return 0;
    80003b7e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b80:	08d76f63          	bltu	a4,a3,80003c1e <readi+0xd0>
  if(off + n > ip->size)
    80003b84:	00e7f463          	bgeu	a5,a4,80003b8c <readi+0x3e>
    n = ip->size - off;
    80003b88:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b8c:	0a0b0863          	beqz	s6,80003c3c <readi+0xee>
    80003b90:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b92:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b96:	5cfd                	li	s9,-1
    80003b98:	a82d                	j	80003bd2 <readi+0x84>
    80003b9a:	020a1d93          	slli	s11,s4,0x20
    80003b9e:	020ddd93          	srli	s11,s11,0x20
    80003ba2:	05890793          	addi	a5,s2,88
    80003ba6:	86ee                	mv	a3,s11
    80003ba8:	963e                	add	a2,a2,a5
    80003baa:	85d6                	mv	a1,s5
    80003bac:	8562                	mv	a0,s8
    80003bae:	fffff097          	auipc	ra,0xfffff
    80003bb2:	ae8080e7          	jalr	-1304(ra) # 80002696 <either_copyout>
    80003bb6:	05950d63          	beq	a0,s9,80003c10 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003bba:	854a                	mv	a0,s2
    80003bbc:	fffff097          	auipc	ra,0xfffff
    80003bc0:	60a080e7          	jalr	1546(ra) # 800031c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc4:	013a09bb          	addw	s3,s4,s3
    80003bc8:	009a04bb          	addw	s1,s4,s1
    80003bcc:	9aee                	add	s5,s5,s11
    80003bce:	0569f663          	bgeu	s3,s6,80003c1a <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bd2:	000ba903          	lw	s2,0(s7)
    80003bd6:	00a4d59b          	srliw	a1,s1,0xa
    80003bda:	855e                	mv	a0,s7
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	8ae080e7          	jalr	-1874(ra) # 8000348a <bmap>
    80003be4:	0005059b          	sext.w	a1,a0
    80003be8:	854a                	mv	a0,s2
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	4ac080e7          	jalr	1196(ra) # 80003096 <bread>
    80003bf2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf4:	3ff4f613          	andi	a2,s1,1023
    80003bf8:	40cd07bb          	subw	a5,s10,a2
    80003bfc:	413b073b          	subw	a4,s6,s3
    80003c00:	8a3e                	mv	s4,a5
    80003c02:	2781                	sext.w	a5,a5
    80003c04:	0007069b          	sext.w	a3,a4
    80003c08:	f8f6f9e3          	bgeu	a3,a5,80003b9a <readi+0x4c>
    80003c0c:	8a3a                	mv	s4,a4
    80003c0e:	b771                	j	80003b9a <readi+0x4c>
      brelse(bp);
    80003c10:	854a                	mv	a0,s2
    80003c12:	fffff097          	auipc	ra,0xfffff
    80003c16:	5b4080e7          	jalr	1460(ra) # 800031c6 <brelse>
  }
  return tot;
    80003c1a:	0009851b          	sext.w	a0,s3
}
    80003c1e:	70a6                	ld	ra,104(sp)
    80003c20:	7406                	ld	s0,96(sp)
    80003c22:	64e6                	ld	s1,88(sp)
    80003c24:	6946                	ld	s2,80(sp)
    80003c26:	69a6                	ld	s3,72(sp)
    80003c28:	6a06                	ld	s4,64(sp)
    80003c2a:	7ae2                	ld	s5,56(sp)
    80003c2c:	7b42                	ld	s6,48(sp)
    80003c2e:	7ba2                	ld	s7,40(sp)
    80003c30:	7c02                	ld	s8,32(sp)
    80003c32:	6ce2                	ld	s9,24(sp)
    80003c34:	6d42                	ld	s10,16(sp)
    80003c36:	6da2                	ld	s11,8(sp)
    80003c38:	6165                	addi	sp,sp,112
    80003c3a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c3c:	89da                	mv	s3,s6
    80003c3e:	bff1                	j	80003c1a <readi+0xcc>
    return 0;
    80003c40:	4501                	li	a0,0
}
    80003c42:	8082                	ret

0000000080003c44 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c44:	457c                	lw	a5,76(a0)
    80003c46:	10d7e663          	bltu	a5,a3,80003d52 <writei+0x10e>
{
    80003c4a:	7159                	addi	sp,sp,-112
    80003c4c:	f486                	sd	ra,104(sp)
    80003c4e:	f0a2                	sd	s0,96(sp)
    80003c50:	eca6                	sd	s1,88(sp)
    80003c52:	e8ca                	sd	s2,80(sp)
    80003c54:	e4ce                	sd	s3,72(sp)
    80003c56:	e0d2                	sd	s4,64(sp)
    80003c58:	fc56                	sd	s5,56(sp)
    80003c5a:	f85a                	sd	s6,48(sp)
    80003c5c:	f45e                	sd	s7,40(sp)
    80003c5e:	f062                	sd	s8,32(sp)
    80003c60:	ec66                	sd	s9,24(sp)
    80003c62:	e86a                	sd	s10,16(sp)
    80003c64:	e46e                	sd	s11,8(sp)
    80003c66:	1880                	addi	s0,sp,112
    80003c68:	8baa                	mv	s7,a0
    80003c6a:	8c2e                	mv	s8,a1
    80003c6c:	8ab2                	mv	s5,a2
    80003c6e:	8936                	mv	s2,a3
    80003c70:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c72:	00e687bb          	addw	a5,a3,a4
    80003c76:	0ed7e063          	bltu	a5,a3,80003d56 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c7a:	00043737          	lui	a4,0x43
    80003c7e:	0cf76e63          	bltu	a4,a5,80003d5a <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c82:	0a0b0763          	beqz	s6,80003d30 <writei+0xec>
    80003c86:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c88:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c8c:	5cfd                	li	s9,-1
    80003c8e:	a091                	j	80003cd2 <writei+0x8e>
    80003c90:	02099d93          	slli	s11,s3,0x20
    80003c94:	020ddd93          	srli	s11,s11,0x20
    80003c98:	05848793          	addi	a5,s1,88
    80003c9c:	86ee                	mv	a3,s11
    80003c9e:	8656                	mv	a2,s5
    80003ca0:	85e2                	mv	a1,s8
    80003ca2:	953e                	add	a0,a0,a5
    80003ca4:	fffff097          	auipc	ra,0xfffff
    80003ca8:	a48080e7          	jalr	-1464(ra) # 800026ec <either_copyin>
    80003cac:	07950263          	beq	a0,s9,80003d10 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cb0:	8526                	mv	a0,s1
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	77e080e7          	jalr	1918(ra) # 80004430 <log_write>
    brelse(bp);
    80003cba:	8526                	mv	a0,s1
    80003cbc:	fffff097          	auipc	ra,0xfffff
    80003cc0:	50a080e7          	jalr	1290(ra) # 800031c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cc4:	01498a3b          	addw	s4,s3,s4
    80003cc8:	0129893b          	addw	s2,s3,s2
    80003ccc:	9aee                	add	s5,s5,s11
    80003cce:	056a7663          	bgeu	s4,s6,80003d1a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cd2:	000ba483          	lw	s1,0(s7)
    80003cd6:	00a9559b          	srliw	a1,s2,0xa
    80003cda:	855e                	mv	a0,s7
    80003cdc:	fffff097          	auipc	ra,0xfffff
    80003ce0:	7ae080e7          	jalr	1966(ra) # 8000348a <bmap>
    80003ce4:	0005059b          	sext.w	a1,a0
    80003ce8:	8526                	mv	a0,s1
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	3ac080e7          	jalr	940(ra) # 80003096 <bread>
    80003cf2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf4:	3ff97513          	andi	a0,s2,1023
    80003cf8:	40ad07bb          	subw	a5,s10,a0
    80003cfc:	414b073b          	subw	a4,s6,s4
    80003d00:	89be                	mv	s3,a5
    80003d02:	2781                	sext.w	a5,a5
    80003d04:	0007069b          	sext.w	a3,a4
    80003d08:	f8f6f4e3          	bgeu	a3,a5,80003c90 <writei+0x4c>
    80003d0c:	89ba                	mv	s3,a4
    80003d0e:	b749                	j	80003c90 <writei+0x4c>
      brelse(bp);
    80003d10:	8526                	mv	a0,s1
    80003d12:	fffff097          	auipc	ra,0xfffff
    80003d16:	4b4080e7          	jalr	1204(ra) # 800031c6 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003d1a:	04cba783          	lw	a5,76(s7)
    80003d1e:	0127f463          	bgeu	a5,s2,80003d26 <writei+0xe2>
      ip->size = off;
    80003d22:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d26:	855e                	mv	a0,s7
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	aa8080e7          	jalr	-1368(ra) # 800037d0 <iupdate>
  }

  return n;
    80003d30:	000b051b          	sext.w	a0,s6
}
    80003d34:	70a6                	ld	ra,104(sp)
    80003d36:	7406                	ld	s0,96(sp)
    80003d38:	64e6                	ld	s1,88(sp)
    80003d3a:	6946                	ld	s2,80(sp)
    80003d3c:	69a6                	ld	s3,72(sp)
    80003d3e:	6a06                	ld	s4,64(sp)
    80003d40:	7ae2                	ld	s5,56(sp)
    80003d42:	7b42                	ld	s6,48(sp)
    80003d44:	7ba2                	ld	s7,40(sp)
    80003d46:	7c02                	ld	s8,32(sp)
    80003d48:	6ce2                	ld	s9,24(sp)
    80003d4a:	6d42                	ld	s10,16(sp)
    80003d4c:	6da2                	ld	s11,8(sp)
    80003d4e:	6165                	addi	sp,sp,112
    80003d50:	8082                	ret
    return -1;
    80003d52:	557d                	li	a0,-1
}
    80003d54:	8082                	ret
    return -1;
    80003d56:	557d                	li	a0,-1
    80003d58:	bff1                	j	80003d34 <writei+0xf0>
    return -1;
    80003d5a:	557d                	li	a0,-1
    80003d5c:	bfe1                	j	80003d34 <writei+0xf0>

0000000080003d5e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d5e:	1141                	addi	sp,sp,-16
    80003d60:	e406                	sd	ra,8(sp)
    80003d62:	e022                	sd	s0,0(sp)
    80003d64:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d66:	4639                	li	a2,14
    80003d68:	ffffd097          	auipc	ra,0xffffd
    80003d6c:	068080e7          	jalr	104(ra) # 80000dd0 <strncmp>
}
    80003d70:	60a2                	ld	ra,8(sp)
    80003d72:	6402                	ld	s0,0(sp)
    80003d74:	0141                	addi	sp,sp,16
    80003d76:	8082                	ret

0000000080003d78 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d78:	7139                	addi	sp,sp,-64
    80003d7a:	fc06                	sd	ra,56(sp)
    80003d7c:	f822                	sd	s0,48(sp)
    80003d7e:	f426                	sd	s1,40(sp)
    80003d80:	f04a                	sd	s2,32(sp)
    80003d82:	ec4e                	sd	s3,24(sp)
    80003d84:	e852                	sd	s4,16(sp)
    80003d86:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d88:	04451703          	lh	a4,68(a0)
    80003d8c:	4785                	li	a5,1
    80003d8e:	00f71a63          	bne	a4,a5,80003da2 <dirlookup+0x2a>
    80003d92:	892a                	mv	s2,a0
    80003d94:	89ae                	mv	s3,a1
    80003d96:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d98:	457c                	lw	a5,76(a0)
    80003d9a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d9c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d9e:	e79d                	bnez	a5,80003dcc <dirlookup+0x54>
    80003da0:	a8a5                	j	80003e18 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003da2:	00005517          	auipc	a0,0x5
    80003da6:	87650513          	addi	a0,a0,-1930 # 80008618 <syscalls+0x1a0>
    80003daa:	ffffc097          	auipc	ra,0xffffc
    80003dae:	796080e7          	jalr	1942(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003db2:	00005517          	auipc	a0,0x5
    80003db6:	87e50513          	addi	a0,a0,-1922 # 80008630 <syscalls+0x1b8>
    80003dba:	ffffc097          	auipc	ra,0xffffc
    80003dbe:	786080e7          	jalr	1926(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc2:	24c1                	addiw	s1,s1,16
    80003dc4:	04c92783          	lw	a5,76(s2)
    80003dc8:	04f4f763          	bgeu	s1,a5,80003e16 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dcc:	4741                	li	a4,16
    80003dce:	86a6                	mv	a3,s1
    80003dd0:	fc040613          	addi	a2,s0,-64
    80003dd4:	4581                	li	a1,0
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	d76080e7          	jalr	-650(ra) # 80003b4e <readi>
    80003de0:	47c1                	li	a5,16
    80003de2:	fcf518e3          	bne	a0,a5,80003db2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003de6:	fc045783          	lhu	a5,-64(s0)
    80003dea:	dfe1                	beqz	a5,80003dc2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dec:	fc240593          	addi	a1,s0,-62
    80003df0:	854e                	mv	a0,s3
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	f6c080e7          	jalr	-148(ra) # 80003d5e <namecmp>
    80003dfa:	f561                	bnez	a0,80003dc2 <dirlookup+0x4a>
      if(poff)
    80003dfc:	000a0463          	beqz	s4,80003e04 <dirlookup+0x8c>
        *poff = off;
    80003e00:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e04:	fc045583          	lhu	a1,-64(s0)
    80003e08:	00092503          	lw	a0,0(s2)
    80003e0c:	fffff097          	auipc	ra,0xfffff
    80003e10:	75a080e7          	jalr	1882(ra) # 80003566 <iget>
    80003e14:	a011                	j	80003e18 <dirlookup+0xa0>
  return 0;
    80003e16:	4501                	li	a0,0
}
    80003e18:	70e2                	ld	ra,56(sp)
    80003e1a:	7442                	ld	s0,48(sp)
    80003e1c:	74a2                	ld	s1,40(sp)
    80003e1e:	7902                	ld	s2,32(sp)
    80003e20:	69e2                	ld	s3,24(sp)
    80003e22:	6a42                	ld	s4,16(sp)
    80003e24:	6121                	addi	sp,sp,64
    80003e26:	8082                	ret

0000000080003e28 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e28:	711d                	addi	sp,sp,-96
    80003e2a:	ec86                	sd	ra,88(sp)
    80003e2c:	e8a2                	sd	s0,80(sp)
    80003e2e:	e4a6                	sd	s1,72(sp)
    80003e30:	e0ca                	sd	s2,64(sp)
    80003e32:	fc4e                	sd	s3,56(sp)
    80003e34:	f852                	sd	s4,48(sp)
    80003e36:	f456                	sd	s5,40(sp)
    80003e38:	f05a                	sd	s6,32(sp)
    80003e3a:	ec5e                	sd	s7,24(sp)
    80003e3c:	e862                	sd	s8,16(sp)
    80003e3e:	e466                	sd	s9,8(sp)
    80003e40:	1080                	addi	s0,sp,96
    80003e42:	84aa                	mv	s1,a0
    80003e44:	8aae                	mv	s5,a1
    80003e46:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e48:	00054703          	lbu	a4,0(a0)
    80003e4c:	02f00793          	li	a5,47
    80003e50:	02f70363          	beq	a4,a5,80003e76 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e54:	ffffe097          	auipc	ra,0xffffe
    80003e58:	c7e080e7          	jalr	-898(ra) # 80001ad2 <myproc>
    80003e5c:	15053503          	ld	a0,336(a0)
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	9fc080e7          	jalr	-1540(ra) # 8000385c <idup>
    80003e68:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e6a:	02f00913          	li	s2,47
  len = path - s;
    80003e6e:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e70:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e72:	4b85                	li	s7,1
    80003e74:	a865                	j	80003f2c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e76:	4585                	li	a1,1
    80003e78:	4505                	li	a0,1
    80003e7a:	fffff097          	auipc	ra,0xfffff
    80003e7e:	6ec080e7          	jalr	1772(ra) # 80003566 <iget>
    80003e82:	89aa                	mv	s3,a0
    80003e84:	b7dd                	j	80003e6a <namex+0x42>
      iunlockput(ip);
    80003e86:	854e                	mv	a0,s3
    80003e88:	00000097          	auipc	ra,0x0
    80003e8c:	c74080e7          	jalr	-908(ra) # 80003afc <iunlockput>
      return 0;
    80003e90:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e92:	854e                	mv	a0,s3
    80003e94:	60e6                	ld	ra,88(sp)
    80003e96:	6446                	ld	s0,80(sp)
    80003e98:	64a6                	ld	s1,72(sp)
    80003e9a:	6906                	ld	s2,64(sp)
    80003e9c:	79e2                	ld	s3,56(sp)
    80003e9e:	7a42                	ld	s4,48(sp)
    80003ea0:	7aa2                	ld	s5,40(sp)
    80003ea2:	7b02                	ld	s6,32(sp)
    80003ea4:	6be2                	ld	s7,24(sp)
    80003ea6:	6c42                	ld	s8,16(sp)
    80003ea8:	6ca2                	ld	s9,8(sp)
    80003eaa:	6125                	addi	sp,sp,96
    80003eac:	8082                	ret
      iunlock(ip);
    80003eae:	854e                	mv	a0,s3
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	aac080e7          	jalr	-1364(ra) # 8000395c <iunlock>
      return ip;
    80003eb8:	bfe9                	j	80003e92 <namex+0x6a>
      iunlockput(ip);
    80003eba:	854e                	mv	a0,s3
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	c40080e7          	jalr	-960(ra) # 80003afc <iunlockput>
      return 0;
    80003ec4:	89e6                	mv	s3,s9
    80003ec6:	b7f1                	j	80003e92 <namex+0x6a>
  len = path - s;
    80003ec8:	40b48633          	sub	a2,s1,a1
    80003ecc:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003ed0:	099c5463          	bge	s8,s9,80003f58 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ed4:	4639                	li	a2,14
    80003ed6:	8552                	mv	a0,s4
    80003ed8:	ffffd097          	auipc	ra,0xffffd
    80003edc:	e7c080e7          	jalr	-388(ra) # 80000d54 <memmove>
  while(*path == '/')
    80003ee0:	0004c783          	lbu	a5,0(s1)
    80003ee4:	01279763          	bne	a5,s2,80003ef2 <namex+0xca>
    path++;
    80003ee8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eea:	0004c783          	lbu	a5,0(s1)
    80003eee:	ff278de3          	beq	a5,s2,80003ee8 <namex+0xc0>
    ilock(ip);
    80003ef2:	854e                	mv	a0,s3
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	9a6080e7          	jalr	-1626(ra) # 8000389a <ilock>
    if(ip->type != T_DIR){
    80003efc:	04499783          	lh	a5,68(s3)
    80003f00:	f97793e3          	bne	a5,s7,80003e86 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f04:	000a8563          	beqz	s5,80003f0e <namex+0xe6>
    80003f08:	0004c783          	lbu	a5,0(s1)
    80003f0c:	d3cd                	beqz	a5,80003eae <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f0e:	865a                	mv	a2,s6
    80003f10:	85d2                	mv	a1,s4
    80003f12:	854e                	mv	a0,s3
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	e64080e7          	jalr	-412(ra) # 80003d78 <dirlookup>
    80003f1c:	8caa                	mv	s9,a0
    80003f1e:	dd51                	beqz	a0,80003eba <namex+0x92>
    iunlockput(ip);
    80003f20:	854e                	mv	a0,s3
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	bda080e7          	jalr	-1062(ra) # 80003afc <iunlockput>
    ip = next;
    80003f2a:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f2c:	0004c783          	lbu	a5,0(s1)
    80003f30:	05279763          	bne	a5,s2,80003f7e <namex+0x156>
    path++;
    80003f34:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f36:	0004c783          	lbu	a5,0(s1)
    80003f3a:	ff278de3          	beq	a5,s2,80003f34 <namex+0x10c>
  if(*path == 0)
    80003f3e:	c79d                	beqz	a5,80003f6c <namex+0x144>
    path++;
    80003f40:	85a6                	mv	a1,s1
  len = path - s;
    80003f42:	8cda                	mv	s9,s6
    80003f44:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f46:	01278963          	beq	a5,s2,80003f58 <namex+0x130>
    80003f4a:	dfbd                	beqz	a5,80003ec8 <namex+0xa0>
    path++;
    80003f4c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f4e:	0004c783          	lbu	a5,0(s1)
    80003f52:	ff279ce3          	bne	a5,s2,80003f4a <namex+0x122>
    80003f56:	bf8d                	j	80003ec8 <namex+0xa0>
    memmove(name, s, len);
    80003f58:	2601                	sext.w	a2,a2
    80003f5a:	8552                	mv	a0,s4
    80003f5c:	ffffd097          	auipc	ra,0xffffd
    80003f60:	df8080e7          	jalr	-520(ra) # 80000d54 <memmove>
    name[len] = 0;
    80003f64:	9cd2                	add	s9,s9,s4
    80003f66:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f6a:	bf9d                	j	80003ee0 <namex+0xb8>
  if(nameiparent){
    80003f6c:	f20a83e3          	beqz	s5,80003e92 <namex+0x6a>
    iput(ip);
    80003f70:	854e                	mv	a0,s3
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	ae2080e7          	jalr	-1310(ra) # 80003a54 <iput>
    return 0;
    80003f7a:	4981                	li	s3,0
    80003f7c:	bf19                	j	80003e92 <namex+0x6a>
  if(*path == 0)
    80003f7e:	d7fd                	beqz	a5,80003f6c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f80:	0004c783          	lbu	a5,0(s1)
    80003f84:	85a6                	mv	a1,s1
    80003f86:	b7d1                	j	80003f4a <namex+0x122>

0000000080003f88 <dirlink>:
{
    80003f88:	7139                	addi	sp,sp,-64
    80003f8a:	fc06                	sd	ra,56(sp)
    80003f8c:	f822                	sd	s0,48(sp)
    80003f8e:	f426                	sd	s1,40(sp)
    80003f90:	f04a                	sd	s2,32(sp)
    80003f92:	ec4e                	sd	s3,24(sp)
    80003f94:	e852                	sd	s4,16(sp)
    80003f96:	0080                	addi	s0,sp,64
    80003f98:	892a                	mv	s2,a0
    80003f9a:	8a2e                	mv	s4,a1
    80003f9c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f9e:	4601                	li	a2,0
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	dd8080e7          	jalr	-552(ra) # 80003d78 <dirlookup>
    80003fa8:	e93d                	bnez	a0,8000401e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003faa:	04c92483          	lw	s1,76(s2)
    80003fae:	c49d                	beqz	s1,80003fdc <dirlink+0x54>
    80003fb0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb2:	4741                	li	a4,16
    80003fb4:	86a6                	mv	a3,s1
    80003fb6:	fc040613          	addi	a2,s0,-64
    80003fba:	4581                	li	a1,0
    80003fbc:	854a                	mv	a0,s2
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	b90080e7          	jalr	-1136(ra) # 80003b4e <readi>
    80003fc6:	47c1                	li	a5,16
    80003fc8:	06f51163          	bne	a0,a5,8000402a <dirlink+0xa2>
    if(de.inum == 0)
    80003fcc:	fc045783          	lhu	a5,-64(s0)
    80003fd0:	c791                	beqz	a5,80003fdc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fd2:	24c1                	addiw	s1,s1,16
    80003fd4:	04c92783          	lw	a5,76(s2)
    80003fd8:	fcf4ede3          	bltu	s1,a5,80003fb2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fdc:	4639                	li	a2,14
    80003fde:	85d2                	mv	a1,s4
    80003fe0:	fc240513          	addi	a0,s0,-62
    80003fe4:	ffffd097          	auipc	ra,0xffffd
    80003fe8:	e28080e7          	jalr	-472(ra) # 80000e0c <strncpy>
  de.inum = inum;
    80003fec:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff0:	4741                	li	a4,16
    80003ff2:	86a6                	mv	a3,s1
    80003ff4:	fc040613          	addi	a2,s0,-64
    80003ff8:	4581                	li	a1,0
    80003ffa:	854a                	mv	a0,s2
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	c48080e7          	jalr	-952(ra) # 80003c44 <writei>
    80004004:	872a                	mv	a4,a0
    80004006:	47c1                	li	a5,16
  return 0;
    80004008:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000400a:	02f71863          	bne	a4,a5,8000403a <dirlink+0xb2>
}
    8000400e:	70e2                	ld	ra,56(sp)
    80004010:	7442                	ld	s0,48(sp)
    80004012:	74a2                	ld	s1,40(sp)
    80004014:	7902                	ld	s2,32(sp)
    80004016:	69e2                	ld	s3,24(sp)
    80004018:	6a42                	ld	s4,16(sp)
    8000401a:	6121                	addi	sp,sp,64
    8000401c:	8082                	ret
    iput(ip);
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	a36080e7          	jalr	-1482(ra) # 80003a54 <iput>
    return -1;
    80004026:	557d                	li	a0,-1
    80004028:	b7dd                	j	8000400e <dirlink+0x86>
      panic("dirlink read");
    8000402a:	00004517          	auipc	a0,0x4
    8000402e:	61650513          	addi	a0,a0,1558 # 80008640 <syscalls+0x1c8>
    80004032:	ffffc097          	auipc	ra,0xffffc
    80004036:	50e080e7          	jalr	1294(ra) # 80000540 <panic>
    panic("dirlink");
    8000403a:	00004517          	auipc	a0,0x4
    8000403e:	72650513          	addi	a0,a0,1830 # 80008760 <syscalls+0x2e8>
    80004042:	ffffc097          	auipc	ra,0xffffc
    80004046:	4fe080e7          	jalr	1278(ra) # 80000540 <panic>

000000008000404a <namei>:

struct inode*
namei(char *path)
{
    8000404a:	1101                	addi	sp,sp,-32
    8000404c:	ec06                	sd	ra,24(sp)
    8000404e:	e822                	sd	s0,16(sp)
    80004050:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004052:	fe040613          	addi	a2,s0,-32
    80004056:	4581                	li	a1,0
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	dd0080e7          	jalr	-560(ra) # 80003e28 <namex>
}
    80004060:	60e2                	ld	ra,24(sp)
    80004062:	6442                	ld	s0,16(sp)
    80004064:	6105                	addi	sp,sp,32
    80004066:	8082                	ret

0000000080004068 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004068:	1141                	addi	sp,sp,-16
    8000406a:	e406                	sd	ra,8(sp)
    8000406c:	e022                	sd	s0,0(sp)
    8000406e:	0800                	addi	s0,sp,16
    80004070:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004072:	4585                	li	a1,1
    80004074:	00000097          	auipc	ra,0x0
    80004078:	db4080e7          	jalr	-588(ra) # 80003e28 <namex>
}
    8000407c:	60a2                	ld	ra,8(sp)
    8000407e:	6402                	ld	s0,0(sp)
    80004080:	0141                	addi	sp,sp,16
    80004082:	8082                	ret

0000000080004084 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004084:	1101                	addi	sp,sp,-32
    80004086:	ec06                	sd	ra,24(sp)
    80004088:	e822                	sd	s0,16(sp)
    8000408a:	e426                	sd	s1,8(sp)
    8000408c:	e04a                	sd	s2,0(sp)
    8000408e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004090:	0001e917          	auipc	s2,0x1e
    80004094:	47890913          	addi	s2,s2,1144 # 80022508 <log>
    80004098:	01892583          	lw	a1,24(s2)
    8000409c:	02892503          	lw	a0,40(s2)
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	ff6080e7          	jalr	-10(ra) # 80003096 <bread>
    800040a8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040aa:	02c92683          	lw	a3,44(s2)
    800040ae:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040b0:	02d05863          	blez	a3,800040e0 <write_head+0x5c>
    800040b4:	0001e797          	auipc	a5,0x1e
    800040b8:	48478793          	addi	a5,a5,1156 # 80022538 <log+0x30>
    800040bc:	05c50713          	addi	a4,a0,92
    800040c0:	36fd                	addiw	a3,a3,-1
    800040c2:	02069613          	slli	a2,a3,0x20
    800040c6:	01e65693          	srli	a3,a2,0x1e
    800040ca:	0001e617          	auipc	a2,0x1e
    800040ce:	47260613          	addi	a2,a2,1138 # 8002253c <log+0x34>
    800040d2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040d4:	4390                	lw	a2,0(a5)
    800040d6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040d8:	0791                	addi	a5,a5,4
    800040da:	0711                	addi	a4,a4,4
    800040dc:	fed79ce3          	bne	a5,a3,800040d4 <write_head+0x50>
  }
  bwrite(buf);
    800040e0:	8526                	mv	a0,s1
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	0a6080e7          	jalr	166(ra) # 80003188 <bwrite>
  brelse(buf);
    800040ea:	8526                	mv	a0,s1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	0da080e7          	jalr	218(ra) # 800031c6 <brelse>
}
    800040f4:	60e2                	ld	ra,24(sp)
    800040f6:	6442                	ld	s0,16(sp)
    800040f8:	64a2                	ld	s1,8(sp)
    800040fa:	6902                	ld	s2,0(sp)
    800040fc:	6105                	addi	sp,sp,32
    800040fe:	8082                	ret

0000000080004100 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004100:	0001e797          	auipc	a5,0x1e
    80004104:	4347a783          	lw	a5,1076(a5) # 80022534 <log+0x2c>
    80004108:	0af05663          	blez	a5,800041b4 <install_trans+0xb4>
{
    8000410c:	7139                	addi	sp,sp,-64
    8000410e:	fc06                	sd	ra,56(sp)
    80004110:	f822                	sd	s0,48(sp)
    80004112:	f426                	sd	s1,40(sp)
    80004114:	f04a                	sd	s2,32(sp)
    80004116:	ec4e                	sd	s3,24(sp)
    80004118:	e852                	sd	s4,16(sp)
    8000411a:	e456                	sd	s5,8(sp)
    8000411c:	0080                	addi	s0,sp,64
    8000411e:	0001ea97          	auipc	s5,0x1e
    80004122:	41aa8a93          	addi	s5,s5,1050 # 80022538 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004126:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004128:	0001e997          	auipc	s3,0x1e
    8000412c:	3e098993          	addi	s3,s3,992 # 80022508 <log>
    80004130:	0189a583          	lw	a1,24(s3)
    80004134:	014585bb          	addw	a1,a1,s4
    80004138:	2585                	addiw	a1,a1,1
    8000413a:	0289a503          	lw	a0,40(s3)
    8000413e:	fffff097          	auipc	ra,0xfffff
    80004142:	f58080e7          	jalr	-168(ra) # 80003096 <bread>
    80004146:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004148:	000aa583          	lw	a1,0(s5)
    8000414c:	0289a503          	lw	a0,40(s3)
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	f46080e7          	jalr	-186(ra) # 80003096 <bread>
    80004158:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000415a:	40000613          	li	a2,1024
    8000415e:	05890593          	addi	a1,s2,88
    80004162:	05850513          	addi	a0,a0,88
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	bee080e7          	jalr	-1042(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000416e:	8526                	mv	a0,s1
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	018080e7          	jalr	24(ra) # 80003188 <bwrite>
    bunpin(dbuf);
    80004178:	8526                	mv	a0,s1
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	126080e7          	jalr	294(ra) # 800032a0 <bunpin>
    brelse(lbuf);
    80004182:	854a                	mv	a0,s2
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	042080e7          	jalr	66(ra) # 800031c6 <brelse>
    brelse(dbuf);
    8000418c:	8526                	mv	a0,s1
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	038080e7          	jalr	56(ra) # 800031c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004196:	2a05                	addiw	s4,s4,1
    80004198:	0a91                	addi	s5,s5,4
    8000419a:	02c9a783          	lw	a5,44(s3)
    8000419e:	f8fa49e3          	blt	s4,a5,80004130 <install_trans+0x30>
}
    800041a2:	70e2                	ld	ra,56(sp)
    800041a4:	7442                	ld	s0,48(sp)
    800041a6:	74a2                	ld	s1,40(sp)
    800041a8:	7902                	ld	s2,32(sp)
    800041aa:	69e2                	ld	s3,24(sp)
    800041ac:	6a42                	ld	s4,16(sp)
    800041ae:	6aa2                	ld	s5,8(sp)
    800041b0:	6121                	addi	sp,sp,64
    800041b2:	8082                	ret
    800041b4:	8082                	ret

00000000800041b6 <initlog>:
{
    800041b6:	7179                	addi	sp,sp,-48
    800041b8:	f406                	sd	ra,40(sp)
    800041ba:	f022                	sd	s0,32(sp)
    800041bc:	ec26                	sd	s1,24(sp)
    800041be:	e84a                	sd	s2,16(sp)
    800041c0:	e44e                	sd	s3,8(sp)
    800041c2:	1800                	addi	s0,sp,48
    800041c4:	892a                	mv	s2,a0
    800041c6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041c8:	0001e497          	auipc	s1,0x1e
    800041cc:	34048493          	addi	s1,s1,832 # 80022508 <log>
    800041d0:	00004597          	auipc	a1,0x4
    800041d4:	48058593          	addi	a1,a1,1152 # 80008650 <syscalls+0x1d8>
    800041d8:	8526                	mv	a0,s1
    800041da:	ffffd097          	auipc	ra,0xffffd
    800041de:	992080e7          	jalr	-1646(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    800041e2:	0149a583          	lw	a1,20(s3)
    800041e6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041e8:	0109a783          	lw	a5,16(s3)
    800041ec:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041ee:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041f2:	854a                	mv	a0,s2
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	ea2080e7          	jalr	-350(ra) # 80003096 <bread>
  log.lh.n = lh->n;
    800041fc:	4d34                	lw	a3,88(a0)
    800041fe:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004200:	02d05663          	blez	a3,8000422c <initlog+0x76>
    80004204:	05c50793          	addi	a5,a0,92
    80004208:	0001e717          	auipc	a4,0x1e
    8000420c:	33070713          	addi	a4,a4,816 # 80022538 <log+0x30>
    80004210:	36fd                	addiw	a3,a3,-1
    80004212:	02069613          	slli	a2,a3,0x20
    80004216:	01e65693          	srli	a3,a2,0x1e
    8000421a:	06050613          	addi	a2,a0,96
    8000421e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004220:	4390                	lw	a2,0(a5)
    80004222:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004224:	0791                	addi	a5,a5,4
    80004226:	0711                	addi	a4,a4,4
    80004228:	fed79ce3          	bne	a5,a3,80004220 <initlog+0x6a>
  brelse(buf);
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	f9a080e7          	jalr	-102(ra) # 800031c6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004234:	00000097          	auipc	ra,0x0
    80004238:	ecc080e7          	jalr	-308(ra) # 80004100 <install_trans>
  log.lh.n = 0;
    8000423c:	0001e797          	auipc	a5,0x1e
    80004240:	2e07ac23          	sw	zero,760(a5) # 80022534 <log+0x2c>
  write_head(); // clear the log
    80004244:	00000097          	auipc	ra,0x0
    80004248:	e40080e7          	jalr	-448(ra) # 80004084 <write_head>
}
    8000424c:	70a2                	ld	ra,40(sp)
    8000424e:	7402                	ld	s0,32(sp)
    80004250:	64e2                	ld	s1,24(sp)
    80004252:	6942                	ld	s2,16(sp)
    80004254:	69a2                	ld	s3,8(sp)
    80004256:	6145                	addi	sp,sp,48
    80004258:	8082                	ret

000000008000425a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000425a:	1101                	addi	sp,sp,-32
    8000425c:	ec06                	sd	ra,24(sp)
    8000425e:	e822                	sd	s0,16(sp)
    80004260:	e426                	sd	s1,8(sp)
    80004262:	e04a                	sd	s2,0(sp)
    80004264:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004266:	0001e517          	auipc	a0,0x1e
    8000426a:	2a250513          	addi	a0,a0,674 # 80022508 <log>
    8000426e:	ffffd097          	auipc	ra,0xffffd
    80004272:	98e080e7          	jalr	-1650(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    80004276:	0001e497          	auipc	s1,0x1e
    8000427a:	29248493          	addi	s1,s1,658 # 80022508 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000427e:	4979                	li	s2,30
    80004280:	a039                	j	8000428e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004282:	85a6                	mv	a1,s1
    80004284:	8526                	mv	a0,s1
    80004286:	ffffe097          	auipc	ra,0xffffe
    8000428a:	180080e7          	jalr	384(ra) # 80002406 <sleep>
    if(log.committing){
    8000428e:	50dc                	lw	a5,36(s1)
    80004290:	fbed                	bnez	a5,80004282 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004292:	509c                	lw	a5,32(s1)
    80004294:	0017871b          	addiw	a4,a5,1
    80004298:	0007069b          	sext.w	a3,a4
    8000429c:	0027179b          	slliw	a5,a4,0x2
    800042a0:	9fb9                	addw	a5,a5,a4
    800042a2:	0017979b          	slliw	a5,a5,0x1
    800042a6:	54d8                	lw	a4,44(s1)
    800042a8:	9fb9                	addw	a5,a5,a4
    800042aa:	00f95963          	bge	s2,a5,800042bc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042ae:	85a6                	mv	a1,s1
    800042b0:	8526                	mv	a0,s1
    800042b2:	ffffe097          	auipc	ra,0xffffe
    800042b6:	154080e7          	jalr	340(ra) # 80002406 <sleep>
    800042ba:	bfd1                	j	8000428e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042bc:	0001e517          	auipc	a0,0x1e
    800042c0:	24c50513          	addi	a0,a0,588 # 80022508 <log>
    800042c4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	9ea080e7          	jalr	-1558(ra) # 80000cb0 <release>
      break;
    }
  }
}
    800042ce:	60e2                	ld	ra,24(sp)
    800042d0:	6442                	ld	s0,16(sp)
    800042d2:	64a2                	ld	s1,8(sp)
    800042d4:	6902                	ld	s2,0(sp)
    800042d6:	6105                	addi	sp,sp,32
    800042d8:	8082                	ret

00000000800042da <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042da:	7139                	addi	sp,sp,-64
    800042dc:	fc06                	sd	ra,56(sp)
    800042de:	f822                	sd	s0,48(sp)
    800042e0:	f426                	sd	s1,40(sp)
    800042e2:	f04a                	sd	s2,32(sp)
    800042e4:	ec4e                	sd	s3,24(sp)
    800042e6:	e852                	sd	s4,16(sp)
    800042e8:	e456                	sd	s5,8(sp)
    800042ea:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042ec:	0001e497          	auipc	s1,0x1e
    800042f0:	21c48493          	addi	s1,s1,540 # 80022508 <log>
    800042f4:	8526                	mv	a0,s1
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	906080e7          	jalr	-1786(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    800042fe:	509c                	lw	a5,32(s1)
    80004300:	37fd                	addiw	a5,a5,-1
    80004302:	0007891b          	sext.w	s2,a5
    80004306:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004308:	50dc                	lw	a5,36(s1)
    8000430a:	e7b9                	bnez	a5,80004358 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000430c:	04091e63          	bnez	s2,80004368 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004310:	0001e497          	auipc	s1,0x1e
    80004314:	1f848493          	addi	s1,s1,504 # 80022508 <log>
    80004318:	4785                	li	a5,1
    8000431a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000431c:	8526                	mv	a0,s1
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	992080e7          	jalr	-1646(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004326:	54dc                	lw	a5,44(s1)
    80004328:	06f04763          	bgtz	a5,80004396 <end_op+0xbc>
    acquire(&log.lock);
    8000432c:	0001e497          	auipc	s1,0x1e
    80004330:	1dc48493          	addi	s1,s1,476 # 80022508 <log>
    80004334:	8526                	mv	a0,s1
    80004336:	ffffd097          	auipc	ra,0xffffd
    8000433a:	8c6080e7          	jalr	-1850(ra) # 80000bfc <acquire>
    log.committing = 0;
    8000433e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004342:	8526                	mv	a0,s1
    80004344:	ffffe097          	auipc	ra,0xffffe
    80004348:	25c080e7          	jalr	604(ra) # 800025a0 <wakeup>
    release(&log.lock);
    8000434c:	8526                	mv	a0,s1
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	962080e7          	jalr	-1694(ra) # 80000cb0 <release>
}
    80004356:	a03d                	j	80004384 <end_op+0xaa>
    panic("log.committing");
    80004358:	00004517          	auipc	a0,0x4
    8000435c:	30050513          	addi	a0,a0,768 # 80008658 <syscalls+0x1e0>
    80004360:	ffffc097          	auipc	ra,0xffffc
    80004364:	1e0080e7          	jalr	480(ra) # 80000540 <panic>
    wakeup(&log);
    80004368:	0001e497          	auipc	s1,0x1e
    8000436c:	1a048493          	addi	s1,s1,416 # 80022508 <log>
    80004370:	8526                	mv	a0,s1
    80004372:	ffffe097          	auipc	ra,0xffffe
    80004376:	22e080e7          	jalr	558(ra) # 800025a0 <wakeup>
  release(&log.lock);
    8000437a:	8526                	mv	a0,s1
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	934080e7          	jalr	-1740(ra) # 80000cb0 <release>
}
    80004384:	70e2                	ld	ra,56(sp)
    80004386:	7442                	ld	s0,48(sp)
    80004388:	74a2                	ld	s1,40(sp)
    8000438a:	7902                	ld	s2,32(sp)
    8000438c:	69e2                	ld	s3,24(sp)
    8000438e:	6a42                	ld	s4,16(sp)
    80004390:	6aa2                	ld	s5,8(sp)
    80004392:	6121                	addi	sp,sp,64
    80004394:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004396:	0001ea97          	auipc	s5,0x1e
    8000439a:	1a2a8a93          	addi	s5,s5,418 # 80022538 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000439e:	0001ea17          	auipc	s4,0x1e
    800043a2:	16aa0a13          	addi	s4,s4,362 # 80022508 <log>
    800043a6:	018a2583          	lw	a1,24(s4)
    800043aa:	012585bb          	addw	a1,a1,s2
    800043ae:	2585                	addiw	a1,a1,1
    800043b0:	028a2503          	lw	a0,40(s4)
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	ce2080e7          	jalr	-798(ra) # 80003096 <bread>
    800043bc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043be:	000aa583          	lw	a1,0(s5)
    800043c2:	028a2503          	lw	a0,40(s4)
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	cd0080e7          	jalr	-816(ra) # 80003096 <bread>
    800043ce:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043d0:	40000613          	li	a2,1024
    800043d4:	05850593          	addi	a1,a0,88
    800043d8:	05848513          	addi	a0,s1,88
    800043dc:	ffffd097          	auipc	ra,0xffffd
    800043e0:	978080e7          	jalr	-1672(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    800043e4:	8526                	mv	a0,s1
    800043e6:	fffff097          	auipc	ra,0xfffff
    800043ea:	da2080e7          	jalr	-606(ra) # 80003188 <bwrite>
    brelse(from);
    800043ee:	854e                	mv	a0,s3
    800043f0:	fffff097          	auipc	ra,0xfffff
    800043f4:	dd6080e7          	jalr	-554(ra) # 800031c6 <brelse>
    brelse(to);
    800043f8:	8526                	mv	a0,s1
    800043fa:	fffff097          	auipc	ra,0xfffff
    800043fe:	dcc080e7          	jalr	-564(ra) # 800031c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004402:	2905                	addiw	s2,s2,1
    80004404:	0a91                	addi	s5,s5,4
    80004406:	02ca2783          	lw	a5,44(s4)
    8000440a:	f8f94ee3          	blt	s2,a5,800043a6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000440e:	00000097          	auipc	ra,0x0
    80004412:	c76080e7          	jalr	-906(ra) # 80004084 <write_head>
    install_trans(); // Now install writes to home locations
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	cea080e7          	jalr	-790(ra) # 80004100 <install_trans>
    log.lh.n = 0;
    8000441e:	0001e797          	auipc	a5,0x1e
    80004422:	1007ab23          	sw	zero,278(a5) # 80022534 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004426:	00000097          	auipc	ra,0x0
    8000442a:	c5e080e7          	jalr	-930(ra) # 80004084 <write_head>
    8000442e:	bdfd                	j	8000432c <end_op+0x52>

0000000080004430 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004430:	1101                	addi	sp,sp,-32
    80004432:	ec06                	sd	ra,24(sp)
    80004434:	e822                	sd	s0,16(sp)
    80004436:	e426                	sd	s1,8(sp)
    80004438:	e04a                	sd	s2,0(sp)
    8000443a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000443c:	0001e717          	auipc	a4,0x1e
    80004440:	0f872703          	lw	a4,248(a4) # 80022534 <log+0x2c>
    80004444:	47f5                	li	a5,29
    80004446:	08e7c063          	blt	a5,a4,800044c6 <log_write+0x96>
    8000444a:	84aa                	mv	s1,a0
    8000444c:	0001e797          	auipc	a5,0x1e
    80004450:	0d87a783          	lw	a5,216(a5) # 80022524 <log+0x1c>
    80004454:	37fd                	addiw	a5,a5,-1
    80004456:	06f75863          	bge	a4,a5,800044c6 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000445a:	0001e797          	auipc	a5,0x1e
    8000445e:	0ce7a783          	lw	a5,206(a5) # 80022528 <log+0x20>
    80004462:	06f05a63          	blez	a5,800044d6 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004466:	0001e917          	auipc	s2,0x1e
    8000446a:	0a290913          	addi	s2,s2,162 # 80022508 <log>
    8000446e:	854a                	mv	a0,s2
    80004470:	ffffc097          	auipc	ra,0xffffc
    80004474:	78c080e7          	jalr	1932(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004478:	02c92603          	lw	a2,44(s2)
    8000447c:	06c05563          	blez	a2,800044e6 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004480:	44cc                	lw	a1,12(s1)
    80004482:	0001e717          	auipc	a4,0x1e
    80004486:	0b670713          	addi	a4,a4,182 # 80022538 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000448a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000448c:	4314                	lw	a3,0(a4)
    8000448e:	04b68d63          	beq	a3,a1,800044e8 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004492:	2785                	addiw	a5,a5,1
    80004494:	0711                	addi	a4,a4,4
    80004496:	fec79be3          	bne	a5,a2,8000448c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000449a:	0621                	addi	a2,a2,8
    8000449c:	060a                	slli	a2,a2,0x2
    8000449e:	0001e797          	auipc	a5,0x1e
    800044a2:	06a78793          	addi	a5,a5,106 # 80022508 <log>
    800044a6:	963e                	add	a2,a2,a5
    800044a8:	44dc                	lw	a5,12(s1)
    800044aa:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044ac:	8526                	mv	a0,s1
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	db6080e7          	jalr	-586(ra) # 80003264 <bpin>
    log.lh.n++;
    800044b6:	0001e717          	auipc	a4,0x1e
    800044ba:	05270713          	addi	a4,a4,82 # 80022508 <log>
    800044be:	575c                	lw	a5,44(a4)
    800044c0:	2785                	addiw	a5,a5,1
    800044c2:	d75c                	sw	a5,44(a4)
    800044c4:	a83d                	j	80004502 <log_write+0xd2>
    panic("too big a transaction");
    800044c6:	00004517          	auipc	a0,0x4
    800044ca:	1a250513          	addi	a0,a0,418 # 80008668 <syscalls+0x1f0>
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	072080e7          	jalr	114(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800044d6:	00004517          	auipc	a0,0x4
    800044da:	1aa50513          	addi	a0,a0,426 # 80008680 <syscalls+0x208>
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	062080e7          	jalr	98(ra) # 80000540 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800044e6:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800044e8:	00878713          	addi	a4,a5,8
    800044ec:	00271693          	slli	a3,a4,0x2
    800044f0:	0001e717          	auipc	a4,0x1e
    800044f4:	01870713          	addi	a4,a4,24 # 80022508 <log>
    800044f8:	9736                	add	a4,a4,a3
    800044fa:	44d4                	lw	a3,12(s1)
    800044fc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044fe:	faf607e3          	beq	a2,a5,800044ac <log_write+0x7c>
  }
  release(&log.lock);
    80004502:	0001e517          	auipc	a0,0x1e
    80004506:	00650513          	addi	a0,a0,6 # 80022508 <log>
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	7a6080e7          	jalr	1958(ra) # 80000cb0 <release>
}
    80004512:	60e2                	ld	ra,24(sp)
    80004514:	6442                	ld	s0,16(sp)
    80004516:	64a2                	ld	s1,8(sp)
    80004518:	6902                	ld	s2,0(sp)
    8000451a:	6105                	addi	sp,sp,32
    8000451c:	8082                	ret

000000008000451e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000451e:	1101                	addi	sp,sp,-32
    80004520:	ec06                	sd	ra,24(sp)
    80004522:	e822                	sd	s0,16(sp)
    80004524:	e426                	sd	s1,8(sp)
    80004526:	e04a                	sd	s2,0(sp)
    80004528:	1000                	addi	s0,sp,32
    8000452a:	84aa                	mv	s1,a0
    8000452c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000452e:	00004597          	auipc	a1,0x4
    80004532:	17258593          	addi	a1,a1,370 # 800086a0 <syscalls+0x228>
    80004536:	0521                	addi	a0,a0,8
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	634080e7          	jalr	1588(ra) # 80000b6c <initlock>
  lk->name = name;
    80004540:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004544:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004548:	0204a423          	sw	zero,40(s1)
}
    8000454c:	60e2                	ld	ra,24(sp)
    8000454e:	6442                	ld	s0,16(sp)
    80004550:	64a2                	ld	s1,8(sp)
    80004552:	6902                	ld	s2,0(sp)
    80004554:	6105                	addi	sp,sp,32
    80004556:	8082                	ret

0000000080004558 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004558:	1101                	addi	sp,sp,-32
    8000455a:	ec06                	sd	ra,24(sp)
    8000455c:	e822                	sd	s0,16(sp)
    8000455e:	e426                	sd	s1,8(sp)
    80004560:	e04a                	sd	s2,0(sp)
    80004562:	1000                	addi	s0,sp,32
    80004564:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004566:	00850913          	addi	s2,a0,8
    8000456a:	854a                	mv	a0,s2
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	690080e7          	jalr	1680(ra) # 80000bfc <acquire>
  while (lk->locked) {
    80004574:	409c                	lw	a5,0(s1)
    80004576:	cb89                	beqz	a5,80004588 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004578:	85ca                	mv	a1,s2
    8000457a:	8526                	mv	a0,s1
    8000457c:	ffffe097          	auipc	ra,0xffffe
    80004580:	e8a080e7          	jalr	-374(ra) # 80002406 <sleep>
  while (lk->locked) {
    80004584:	409c                	lw	a5,0(s1)
    80004586:	fbed                	bnez	a5,80004578 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004588:	4785                	li	a5,1
    8000458a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000458c:	ffffd097          	auipc	ra,0xffffd
    80004590:	546080e7          	jalr	1350(ra) # 80001ad2 <myproc>
    80004594:	5d1c                	lw	a5,56(a0)
    80004596:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004598:	854a                	mv	a0,s2
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	716080e7          	jalr	1814(ra) # 80000cb0 <release>
}
    800045a2:	60e2                	ld	ra,24(sp)
    800045a4:	6442                	ld	s0,16(sp)
    800045a6:	64a2                	ld	s1,8(sp)
    800045a8:	6902                	ld	s2,0(sp)
    800045aa:	6105                	addi	sp,sp,32
    800045ac:	8082                	ret

00000000800045ae <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045ae:	1101                	addi	sp,sp,-32
    800045b0:	ec06                	sd	ra,24(sp)
    800045b2:	e822                	sd	s0,16(sp)
    800045b4:	e426                	sd	s1,8(sp)
    800045b6:	e04a                	sd	s2,0(sp)
    800045b8:	1000                	addi	s0,sp,32
    800045ba:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045bc:	00850913          	addi	s2,a0,8
    800045c0:	854a                	mv	a0,s2
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	63a080e7          	jalr	1594(ra) # 80000bfc <acquire>
  lk->locked = 0;
    800045ca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045ce:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045d2:	8526                	mv	a0,s1
    800045d4:	ffffe097          	auipc	ra,0xffffe
    800045d8:	fcc080e7          	jalr	-52(ra) # 800025a0 <wakeup>
  release(&lk->lk);
    800045dc:	854a                	mv	a0,s2
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	6d2080e7          	jalr	1746(ra) # 80000cb0 <release>
}
    800045e6:	60e2                	ld	ra,24(sp)
    800045e8:	6442                	ld	s0,16(sp)
    800045ea:	64a2                	ld	s1,8(sp)
    800045ec:	6902                	ld	s2,0(sp)
    800045ee:	6105                	addi	sp,sp,32
    800045f0:	8082                	ret

00000000800045f2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045f2:	7179                	addi	sp,sp,-48
    800045f4:	f406                	sd	ra,40(sp)
    800045f6:	f022                	sd	s0,32(sp)
    800045f8:	ec26                	sd	s1,24(sp)
    800045fa:	e84a                	sd	s2,16(sp)
    800045fc:	e44e                	sd	s3,8(sp)
    800045fe:	1800                	addi	s0,sp,48
    80004600:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004602:	00850913          	addi	s2,a0,8
    80004606:	854a                	mv	a0,s2
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	5f4080e7          	jalr	1524(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004610:	409c                	lw	a5,0(s1)
    80004612:	ef99                	bnez	a5,80004630 <holdingsleep+0x3e>
    80004614:	4481                	li	s1,0
  release(&lk->lk);
    80004616:	854a                	mv	a0,s2
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	698080e7          	jalr	1688(ra) # 80000cb0 <release>
  return r;
}
    80004620:	8526                	mv	a0,s1
    80004622:	70a2                	ld	ra,40(sp)
    80004624:	7402                	ld	s0,32(sp)
    80004626:	64e2                	ld	s1,24(sp)
    80004628:	6942                	ld	s2,16(sp)
    8000462a:	69a2                	ld	s3,8(sp)
    8000462c:	6145                	addi	sp,sp,48
    8000462e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004630:	0284a983          	lw	s3,40(s1)
    80004634:	ffffd097          	auipc	ra,0xffffd
    80004638:	49e080e7          	jalr	1182(ra) # 80001ad2 <myproc>
    8000463c:	5d04                	lw	s1,56(a0)
    8000463e:	413484b3          	sub	s1,s1,s3
    80004642:	0014b493          	seqz	s1,s1
    80004646:	bfc1                	j	80004616 <holdingsleep+0x24>

0000000080004648 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004648:	1141                	addi	sp,sp,-16
    8000464a:	e406                	sd	ra,8(sp)
    8000464c:	e022                	sd	s0,0(sp)
    8000464e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004650:	00004597          	auipc	a1,0x4
    80004654:	06058593          	addi	a1,a1,96 # 800086b0 <syscalls+0x238>
    80004658:	0001e517          	auipc	a0,0x1e
    8000465c:	ff850513          	addi	a0,a0,-8 # 80022650 <ftable>
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	50c080e7          	jalr	1292(ra) # 80000b6c <initlock>
}
    80004668:	60a2                	ld	ra,8(sp)
    8000466a:	6402                	ld	s0,0(sp)
    8000466c:	0141                	addi	sp,sp,16
    8000466e:	8082                	ret

0000000080004670 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004670:	1101                	addi	sp,sp,-32
    80004672:	ec06                	sd	ra,24(sp)
    80004674:	e822                	sd	s0,16(sp)
    80004676:	e426                	sd	s1,8(sp)
    80004678:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000467a:	0001e517          	auipc	a0,0x1e
    8000467e:	fd650513          	addi	a0,a0,-42 # 80022650 <ftable>
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	57a080e7          	jalr	1402(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000468a:	0001e497          	auipc	s1,0x1e
    8000468e:	fde48493          	addi	s1,s1,-34 # 80022668 <ftable+0x18>
    80004692:	0001f717          	auipc	a4,0x1f
    80004696:	f7670713          	addi	a4,a4,-138 # 80023608 <ftable+0xfb8>
    if(f->ref == 0){
    8000469a:	40dc                	lw	a5,4(s1)
    8000469c:	cf99                	beqz	a5,800046ba <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000469e:	02848493          	addi	s1,s1,40
    800046a2:	fee49ce3          	bne	s1,a4,8000469a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046a6:	0001e517          	auipc	a0,0x1e
    800046aa:	faa50513          	addi	a0,a0,-86 # 80022650 <ftable>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	602080e7          	jalr	1538(ra) # 80000cb0 <release>
  return 0;
    800046b6:	4481                	li	s1,0
    800046b8:	a819                	j	800046ce <filealloc+0x5e>
      f->ref = 1;
    800046ba:	4785                	li	a5,1
    800046bc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046be:	0001e517          	auipc	a0,0x1e
    800046c2:	f9250513          	addi	a0,a0,-110 # 80022650 <ftable>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	5ea080e7          	jalr	1514(ra) # 80000cb0 <release>
}
    800046ce:	8526                	mv	a0,s1
    800046d0:	60e2                	ld	ra,24(sp)
    800046d2:	6442                	ld	s0,16(sp)
    800046d4:	64a2                	ld	s1,8(sp)
    800046d6:	6105                	addi	sp,sp,32
    800046d8:	8082                	ret

00000000800046da <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046da:	1101                	addi	sp,sp,-32
    800046dc:	ec06                	sd	ra,24(sp)
    800046de:	e822                	sd	s0,16(sp)
    800046e0:	e426                	sd	s1,8(sp)
    800046e2:	1000                	addi	s0,sp,32
    800046e4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046e6:	0001e517          	auipc	a0,0x1e
    800046ea:	f6a50513          	addi	a0,a0,-150 # 80022650 <ftable>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	50e080e7          	jalr	1294(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    800046f6:	40dc                	lw	a5,4(s1)
    800046f8:	02f05263          	blez	a5,8000471c <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046fc:	2785                	addiw	a5,a5,1
    800046fe:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004700:	0001e517          	auipc	a0,0x1e
    80004704:	f5050513          	addi	a0,a0,-176 # 80022650 <ftable>
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	5a8080e7          	jalr	1448(ra) # 80000cb0 <release>
  return f;
}
    80004710:	8526                	mv	a0,s1
    80004712:	60e2                	ld	ra,24(sp)
    80004714:	6442                	ld	s0,16(sp)
    80004716:	64a2                	ld	s1,8(sp)
    80004718:	6105                	addi	sp,sp,32
    8000471a:	8082                	ret
    panic("filedup");
    8000471c:	00004517          	auipc	a0,0x4
    80004720:	f9c50513          	addi	a0,a0,-100 # 800086b8 <syscalls+0x240>
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	e1c080e7          	jalr	-484(ra) # 80000540 <panic>

000000008000472c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000472c:	7139                	addi	sp,sp,-64
    8000472e:	fc06                	sd	ra,56(sp)
    80004730:	f822                	sd	s0,48(sp)
    80004732:	f426                	sd	s1,40(sp)
    80004734:	f04a                	sd	s2,32(sp)
    80004736:	ec4e                	sd	s3,24(sp)
    80004738:	e852                	sd	s4,16(sp)
    8000473a:	e456                	sd	s5,8(sp)
    8000473c:	0080                	addi	s0,sp,64
    8000473e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004740:	0001e517          	auipc	a0,0x1e
    80004744:	f1050513          	addi	a0,a0,-240 # 80022650 <ftable>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	4b4080e7          	jalr	1204(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    80004750:	40dc                	lw	a5,4(s1)
    80004752:	06f05163          	blez	a5,800047b4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004756:	37fd                	addiw	a5,a5,-1
    80004758:	0007871b          	sext.w	a4,a5
    8000475c:	c0dc                	sw	a5,4(s1)
    8000475e:	06e04363          	bgtz	a4,800047c4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004762:	0004a903          	lw	s2,0(s1)
    80004766:	0094ca83          	lbu	s5,9(s1)
    8000476a:	0104ba03          	ld	s4,16(s1)
    8000476e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004772:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004776:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000477a:	0001e517          	auipc	a0,0x1e
    8000477e:	ed650513          	addi	a0,a0,-298 # 80022650 <ftable>
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	52e080e7          	jalr	1326(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    8000478a:	4785                	li	a5,1
    8000478c:	04f90d63          	beq	s2,a5,800047e6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004790:	3979                	addiw	s2,s2,-2
    80004792:	4785                	li	a5,1
    80004794:	0527e063          	bltu	a5,s2,800047d4 <fileclose+0xa8>
    begin_op();
    80004798:	00000097          	auipc	ra,0x0
    8000479c:	ac2080e7          	jalr	-1342(ra) # 8000425a <begin_op>
    iput(ff.ip);
    800047a0:	854e                	mv	a0,s3
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	2b2080e7          	jalr	690(ra) # 80003a54 <iput>
    end_op();
    800047aa:	00000097          	auipc	ra,0x0
    800047ae:	b30080e7          	jalr	-1232(ra) # 800042da <end_op>
    800047b2:	a00d                	j	800047d4 <fileclose+0xa8>
    panic("fileclose");
    800047b4:	00004517          	auipc	a0,0x4
    800047b8:	f0c50513          	addi	a0,a0,-244 # 800086c0 <syscalls+0x248>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	d84080e7          	jalr	-636(ra) # 80000540 <panic>
    release(&ftable.lock);
    800047c4:	0001e517          	auipc	a0,0x1e
    800047c8:	e8c50513          	addi	a0,a0,-372 # 80022650 <ftable>
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	4e4080e7          	jalr	1252(ra) # 80000cb0 <release>
  }
}
    800047d4:	70e2                	ld	ra,56(sp)
    800047d6:	7442                	ld	s0,48(sp)
    800047d8:	74a2                	ld	s1,40(sp)
    800047da:	7902                	ld	s2,32(sp)
    800047dc:	69e2                	ld	s3,24(sp)
    800047de:	6a42                	ld	s4,16(sp)
    800047e0:	6aa2                	ld	s5,8(sp)
    800047e2:	6121                	addi	sp,sp,64
    800047e4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047e6:	85d6                	mv	a1,s5
    800047e8:	8552                	mv	a0,s4
    800047ea:	00000097          	auipc	ra,0x0
    800047ee:	372080e7          	jalr	882(ra) # 80004b5c <pipeclose>
    800047f2:	b7cd                	j	800047d4 <fileclose+0xa8>

00000000800047f4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047f4:	715d                	addi	sp,sp,-80
    800047f6:	e486                	sd	ra,72(sp)
    800047f8:	e0a2                	sd	s0,64(sp)
    800047fa:	fc26                	sd	s1,56(sp)
    800047fc:	f84a                	sd	s2,48(sp)
    800047fe:	f44e                	sd	s3,40(sp)
    80004800:	0880                	addi	s0,sp,80
    80004802:	84aa                	mv	s1,a0
    80004804:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004806:	ffffd097          	auipc	ra,0xffffd
    8000480a:	2cc080e7          	jalr	716(ra) # 80001ad2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000480e:	409c                	lw	a5,0(s1)
    80004810:	37f9                	addiw	a5,a5,-2
    80004812:	4705                	li	a4,1
    80004814:	04f76763          	bltu	a4,a5,80004862 <filestat+0x6e>
    80004818:	892a                	mv	s2,a0
    ilock(f->ip);
    8000481a:	6c88                	ld	a0,24(s1)
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	07e080e7          	jalr	126(ra) # 8000389a <ilock>
    stati(f->ip, &st);
    80004824:	fb840593          	addi	a1,s0,-72
    80004828:	6c88                	ld	a0,24(s1)
    8000482a:	fffff097          	auipc	ra,0xfffff
    8000482e:	2fa080e7          	jalr	762(ra) # 80003b24 <stati>
    iunlock(f->ip);
    80004832:	6c88                	ld	a0,24(s1)
    80004834:	fffff097          	auipc	ra,0xfffff
    80004838:	128080e7          	jalr	296(ra) # 8000395c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000483c:	46e1                	li	a3,24
    8000483e:	fb840613          	addi	a2,s0,-72
    80004842:	85ce                	mv	a1,s3
    80004844:	05093503          	ld	a0,80(s2)
    80004848:	ffffd097          	auipc	ra,0xffffd
    8000484c:	e62080e7          	jalr	-414(ra) # 800016aa <copyout>
    80004850:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004854:	60a6                	ld	ra,72(sp)
    80004856:	6406                	ld	s0,64(sp)
    80004858:	74e2                	ld	s1,56(sp)
    8000485a:	7942                	ld	s2,48(sp)
    8000485c:	79a2                	ld	s3,40(sp)
    8000485e:	6161                	addi	sp,sp,80
    80004860:	8082                	ret
  return -1;
    80004862:	557d                	li	a0,-1
    80004864:	bfc5                	j	80004854 <filestat+0x60>

0000000080004866 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004866:	7179                	addi	sp,sp,-48
    80004868:	f406                	sd	ra,40(sp)
    8000486a:	f022                	sd	s0,32(sp)
    8000486c:	ec26                	sd	s1,24(sp)
    8000486e:	e84a                	sd	s2,16(sp)
    80004870:	e44e                	sd	s3,8(sp)
    80004872:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004874:	00854783          	lbu	a5,8(a0)
    80004878:	c3d5                	beqz	a5,8000491c <fileread+0xb6>
    8000487a:	84aa                	mv	s1,a0
    8000487c:	89ae                	mv	s3,a1
    8000487e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004880:	411c                	lw	a5,0(a0)
    80004882:	4705                	li	a4,1
    80004884:	04e78963          	beq	a5,a4,800048d6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004888:	470d                	li	a4,3
    8000488a:	04e78d63          	beq	a5,a4,800048e4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000488e:	4709                	li	a4,2
    80004890:	06e79e63          	bne	a5,a4,8000490c <fileread+0xa6>
    ilock(f->ip);
    80004894:	6d08                	ld	a0,24(a0)
    80004896:	fffff097          	auipc	ra,0xfffff
    8000489a:	004080e7          	jalr	4(ra) # 8000389a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000489e:	874a                	mv	a4,s2
    800048a0:	5094                	lw	a3,32(s1)
    800048a2:	864e                	mv	a2,s3
    800048a4:	4585                	li	a1,1
    800048a6:	6c88                	ld	a0,24(s1)
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	2a6080e7          	jalr	678(ra) # 80003b4e <readi>
    800048b0:	892a                	mv	s2,a0
    800048b2:	00a05563          	blez	a0,800048bc <fileread+0x56>
      f->off += r;
    800048b6:	509c                	lw	a5,32(s1)
    800048b8:	9fa9                	addw	a5,a5,a0
    800048ba:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048bc:	6c88                	ld	a0,24(s1)
    800048be:	fffff097          	auipc	ra,0xfffff
    800048c2:	09e080e7          	jalr	158(ra) # 8000395c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048c6:	854a                	mv	a0,s2
    800048c8:	70a2                	ld	ra,40(sp)
    800048ca:	7402                	ld	s0,32(sp)
    800048cc:	64e2                	ld	s1,24(sp)
    800048ce:	6942                	ld	s2,16(sp)
    800048d0:	69a2                	ld	s3,8(sp)
    800048d2:	6145                	addi	sp,sp,48
    800048d4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048d6:	6908                	ld	a0,16(a0)
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	3f4080e7          	jalr	1012(ra) # 80004ccc <piperead>
    800048e0:	892a                	mv	s2,a0
    800048e2:	b7d5                	j	800048c6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048e4:	02451783          	lh	a5,36(a0)
    800048e8:	03079693          	slli	a3,a5,0x30
    800048ec:	92c1                	srli	a3,a3,0x30
    800048ee:	4725                	li	a4,9
    800048f0:	02d76863          	bltu	a4,a3,80004920 <fileread+0xba>
    800048f4:	0792                	slli	a5,a5,0x4
    800048f6:	0001e717          	auipc	a4,0x1e
    800048fa:	cba70713          	addi	a4,a4,-838 # 800225b0 <devsw>
    800048fe:	97ba                	add	a5,a5,a4
    80004900:	639c                	ld	a5,0(a5)
    80004902:	c38d                	beqz	a5,80004924 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004904:	4505                	li	a0,1
    80004906:	9782                	jalr	a5
    80004908:	892a                	mv	s2,a0
    8000490a:	bf75                	j	800048c6 <fileread+0x60>
    panic("fileread");
    8000490c:	00004517          	auipc	a0,0x4
    80004910:	dc450513          	addi	a0,a0,-572 # 800086d0 <syscalls+0x258>
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	c2c080e7          	jalr	-980(ra) # 80000540 <panic>
    return -1;
    8000491c:	597d                	li	s2,-1
    8000491e:	b765                	j	800048c6 <fileread+0x60>
      return -1;
    80004920:	597d                	li	s2,-1
    80004922:	b755                	j	800048c6 <fileread+0x60>
    80004924:	597d                	li	s2,-1
    80004926:	b745                	j	800048c6 <fileread+0x60>

0000000080004928 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004928:	00954783          	lbu	a5,9(a0)
    8000492c:	14078563          	beqz	a5,80004a76 <filewrite+0x14e>
{
    80004930:	715d                	addi	sp,sp,-80
    80004932:	e486                	sd	ra,72(sp)
    80004934:	e0a2                	sd	s0,64(sp)
    80004936:	fc26                	sd	s1,56(sp)
    80004938:	f84a                	sd	s2,48(sp)
    8000493a:	f44e                	sd	s3,40(sp)
    8000493c:	f052                	sd	s4,32(sp)
    8000493e:	ec56                	sd	s5,24(sp)
    80004940:	e85a                	sd	s6,16(sp)
    80004942:	e45e                	sd	s7,8(sp)
    80004944:	e062                	sd	s8,0(sp)
    80004946:	0880                	addi	s0,sp,80
    80004948:	892a                	mv	s2,a0
    8000494a:	8aae                	mv	s5,a1
    8000494c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000494e:	411c                	lw	a5,0(a0)
    80004950:	4705                	li	a4,1
    80004952:	02e78263          	beq	a5,a4,80004976 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004956:	470d                	li	a4,3
    80004958:	02e78563          	beq	a5,a4,80004982 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000495c:	4709                	li	a4,2
    8000495e:	10e79463          	bne	a5,a4,80004a66 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004962:	0ec05e63          	blez	a2,80004a5e <filewrite+0x136>
    int i = 0;
    80004966:	4981                	li	s3,0
    80004968:	6b05                	lui	s6,0x1
    8000496a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000496e:	6b85                	lui	s7,0x1
    80004970:	c00b8b9b          	addiw	s7,s7,-1024
    80004974:	a851                	j	80004a08 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004976:	6908                	ld	a0,16(a0)
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	254080e7          	jalr	596(ra) # 80004bcc <pipewrite>
    80004980:	a85d                	j	80004a36 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004982:	02451783          	lh	a5,36(a0)
    80004986:	03079693          	slli	a3,a5,0x30
    8000498a:	92c1                	srli	a3,a3,0x30
    8000498c:	4725                	li	a4,9
    8000498e:	0ed76663          	bltu	a4,a3,80004a7a <filewrite+0x152>
    80004992:	0792                	slli	a5,a5,0x4
    80004994:	0001e717          	auipc	a4,0x1e
    80004998:	c1c70713          	addi	a4,a4,-996 # 800225b0 <devsw>
    8000499c:	97ba                	add	a5,a5,a4
    8000499e:	679c                	ld	a5,8(a5)
    800049a0:	cff9                	beqz	a5,80004a7e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800049a2:	4505                	li	a0,1
    800049a4:	9782                	jalr	a5
    800049a6:	a841                	j	80004a36 <filewrite+0x10e>
    800049a8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049ac:	00000097          	auipc	ra,0x0
    800049b0:	8ae080e7          	jalr	-1874(ra) # 8000425a <begin_op>
      ilock(f->ip);
    800049b4:	01893503          	ld	a0,24(s2)
    800049b8:	fffff097          	auipc	ra,0xfffff
    800049bc:	ee2080e7          	jalr	-286(ra) # 8000389a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049c0:	8762                	mv	a4,s8
    800049c2:	02092683          	lw	a3,32(s2)
    800049c6:	01598633          	add	a2,s3,s5
    800049ca:	4585                	li	a1,1
    800049cc:	01893503          	ld	a0,24(s2)
    800049d0:	fffff097          	auipc	ra,0xfffff
    800049d4:	274080e7          	jalr	628(ra) # 80003c44 <writei>
    800049d8:	84aa                	mv	s1,a0
    800049da:	02a05f63          	blez	a0,80004a18 <filewrite+0xf0>
        f->off += r;
    800049de:	02092783          	lw	a5,32(s2)
    800049e2:	9fa9                	addw	a5,a5,a0
    800049e4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049e8:	01893503          	ld	a0,24(s2)
    800049ec:	fffff097          	auipc	ra,0xfffff
    800049f0:	f70080e7          	jalr	-144(ra) # 8000395c <iunlock>
      end_op();
    800049f4:	00000097          	auipc	ra,0x0
    800049f8:	8e6080e7          	jalr	-1818(ra) # 800042da <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800049fc:	049c1963          	bne	s8,s1,80004a4e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a00:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a04:	0349d663          	bge	s3,s4,80004a30 <filewrite+0x108>
      int n1 = n - i;
    80004a08:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a0c:	84be                	mv	s1,a5
    80004a0e:	2781                	sext.w	a5,a5
    80004a10:	f8fb5ce3          	bge	s6,a5,800049a8 <filewrite+0x80>
    80004a14:	84de                	mv	s1,s7
    80004a16:	bf49                	j	800049a8 <filewrite+0x80>
      iunlock(f->ip);
    80004a18:	01893503          	ld	a0,24(s2)
    80004a1c:	fffff097          	auipc	ra,0xfffff
    80004a20:	f40080e7          	jalr	-192(ra) # 8000395c <iunlock>
      end_op();
    80004a24:	00000097          	auipc	ra,0x0
    80004a28:	8b6080e7          	jalr	-1866(ra) # 800042da <end_op>
      if(r < 0)
    80004a2c:	fc04d8e3          	bgez	s1,800049fc <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a30:	8552                	mv	a0,s4
    80004a32:	033a1863          	bne	s4,s3,80004a62 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a36:	60a6                	ld	ra,72(sp)
    80004a38:	6406                	ld	s0,64(sp)
    80004a3a:	74e2                	ld	s1,56(sp)
    80004a3c:	7942                	ld	s2,48(sp)
    80004a3e:	79a2                	ld	s3,40(sp)
    80004a40:	7a02                	ld	s4,32(sp)
    80004a42:	6ae2                	ld	s5,24(sp)
    80004a44:	6b42                	ld	s6,16(sp)
    80004a46:	6ba2                	ld	s7,8(sp)
    80004a48:	6c02                	ld	s8,0(sp)
    80004a4a:	6161                	addi	sp,sp,80
    80004a4c:	8082                	ret
        panic("short filewrite");
    80004a4e:	00004517          	auipc	a0,0x4
    80004a52:	c9250513          	addi	a0,a0,-878 # 800086e0 <syscalls+0x268>
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>
    int i = 0;
    80004a5e:	4981                	li	s3,0
    80004a60:	bfc1                	j	80004a30 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a62:	557d                	li	a0,-1
    80004a64:	bfc9                	j	80004a36 <filewrite+0x10e>
    panic("filewrite");
    80004a66:	00004517          	auipc	a0,0x4
    80004a6a:	c8a50513          	addi	a0,a0,-886 # 800086f0 <syscalls+0x278>
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	ad2080e7          	jalr	-1326(ra) # 80000540 <panic>
    return -1;
    80004a76:	557d                	li	a0,-1
}
    80004a78:	8082                	ret
      return -1;
    80004a7a:	557d                	li	a0,-1
    80004a7c:	bf6d                	j	80004a36 <filewrite+0x10e>
    80004a7e:	557d                	li	a0,-1
    80004a80:	bf5d                	j	80004a36 <filewrite+0x10e>

0000000080004a82 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a82:	7179                	addi	sp,sp,-48
    80004a84:	f406                	sd	ra,40(sp)
    80004a86:	f022                	sd	s0,32(sp)
    80004a88:	ec26                	sd	s1,24(sp)
    80004a8a:	e84a                	sd	s2,16(sp)
    80004a8c:	e44e                	sd	s3,8(sp)
    80004a8e:	e052                	sd	s4,0(sp)
    80004a90:	1800                	addi	s0,sp,48
    80004a92:	84aa                	mv	s1,a0
    80004a94:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a96:	0005b023          	sd	zero,0(a1)
    80004a9a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a9e:	00000097          	auipc	ra,0x0
    80004aa2:	bd2080e7          	jalr	-1070(ra) # 80004670 <filealloc>
    80004aa6:	e088                	sd	a0,0(s1)
    80004aa8:	c551                	beqz	a0,80004b34 <pipealloc+0xb2>
    80004aaa:	00000097          	auipc	ra,0x0
    80004aae:	bc6080e7          	jalr	-1082(ra) # 80004670 <filealloc>
    80004ab2:	00aa3023          	sd	a0,0(s4)
    80004ab6:	c92d                	beqz	a0,80004b28 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	054080e7          	jalr	84(ra) # 80000b0c <kalloc>
    80004ac0:	892a                	mv	s2,a0
    80004ac2:	c125                	beqz	a0,80004b22 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ac4:	4985                	li	s3,1
    80004ac6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004aca:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ace:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ad2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ad6:	00004597          	auipc	a1,0x4
    80004ada:	c2a58593          	addi	a1,a1,-982 # 80008700 <syscalls+0x288>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	08e080e7          	jalr	142(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004ae6:	609c                	ld	a5,0(s1)
    80004ae8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004aec:	609c                	ld	a5,0(s1)
    80004aee:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004af2:	609c                	ld	a5,0(s1)
    80004af4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004af8:	609c                	ld	a5,0(s1)
    80004afa:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004afe:	000a3783          	ld	a5,0(s4)
    80004b02:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b06:	000a3783          	ld	a5,0(s4)
    80004b0a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b0e:	000a3783          	ld	a5,0(s4)
    80004b12:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b16:	000a3783          	ld	a5,0(s4)
    80004b1a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b1e:	4501                	li	a0,0
    80004b20:	a025                	j	80004b48 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b22:	6088                	ld	a0,0(s1)
    80004b24:	e501                	bnez	a0,80004b2c <pipealloc+0xaa>
    80004b26:	a039                	j	80004b34 <pipealloc+0xb2>
    80004b28:	6088                	ld	a0,0(s1)
    80004b2a:	c51d                	beqz	a0,80004b58 <pipealloc+0xd6>
    fileclose(*f0);
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	c00080e7          	jalr	-1024(ra) # 8000472c <fileclose>
  if(*f1)
    80004b34:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b38:	557d                	li	a0,-1
  if(*f1)
    80004b3a:	c799                	beqz	a5,80004b48 <pipealloc+0xc6>
    fileclose(*f1);
    80004b3c:	853e                	mv	a0,a5
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	bee080e7          	jalr	-1042(ra) # 8000472c <fileclose>
  return -1;
    80004b46:	557d                	li	a0,-1
}
    80004b48:	70a2                	ld	ra,40(sp)
    80004b4a:	7402                	ld	s0,32(sp)
    80004b4c:	64e2                	ld	s1,24(sp)
    80004b4e:	6942                	ld	s2,16(sp)
    80004b50:	69a2                	ld	s3,8(sp)
    80004b52:	6a02                	ld	s4,0(sp)
    80004b54:	6145                	addi	sp,sp,48
    80004b56:	8082                	ret
  return -1;
    80004b58:	557d                	li	a0,-1
    80004b5a:	b7fd                	j	80004b48 <pipealloc+0xc6>

0000000080004b5c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b5c:	1101                	addi	sp,sp,-32
    80004b5e:	ec06                	sd	ra,24(sp)
    80004b60:	e822                	sd	s0,16(sp)
    80004b62:	e426                	sd	s1,8(sp)
    80004b64:	e04a                	sd	s2,0(sp)
    80004b66:	1000                	addi	s0,sp,32
    80004b68:	84aa                	mv	s1,a0
    80004b6a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	090080e7          	jalr	144(ra) # 80000bfc <acquire>
  if(writable){
    80004b74:	02090d63          	beqz	s2,80004bae <pipeclose+0x52>
    pi->writeopen = 0;
    80004b78:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b7c:	21848513          	addi	a0,s1,536
    80004b80:	ffffe097          	auipc	ra,0xffffe
    80004b84:	a20080e7          	jalr	-1504(ra) # 800025a0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b88:	2204b783          	ld	a5,544(s1)
    80004b8c:	eb95                	bnez	a5,80004bc0 <pipeclose+0x64>
    release(&pi->lock);
    80004b8e:	8526                	mv	a0,s1
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	120080e7          	jalr	288(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	e76080e7          	jalr	-394(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004ba2:	60e2                	ld	ra,24(sp)
    80004ba4:	6442                	ld	s0,16(sp)
    80004ba6:	64a2                	ld	s1,8(sp)
    80004ba8:	6902                	ld	s2,0(sp)
    80004baa:	6105                	addi	sp,sp,32
    80004bac:	8082                	ret
    pi->readopen = 0;
    80004bae:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bb2:	21c48513          	addi	a0,s1,540
    80004bb6:	ffffe097          	auipc	ra,0xffffe
    80004bba:	9ea080e7          	jalr	-1558(ra) # 800025a0 <wakeup>
    80004bbe:	b7e9                	j	80004b88 <pipeclose+0x2c>
    release(&pi->lock);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	0ee080e7          	jalr	238(ra) # 80000cb0 <release>
}
    80004bca:	bfe1                	j	80004ba2 <pipeclose+0x46>

0000000080004bcc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bcc:	711d                	addi	sp,sp,-96
    80004bce:	ec86                	sd	ra,88(sp)
    80004bd0:	e8a2                	sd	s0,80(sp)
    80004bd2:	e4a6                	sd	s1,72(sp)
    80004bd4:	e0ca                	sd	s2,64(sp)
    80004bd6:	fc4e                	sd	s3,56(sp)
    80004bd8:	f852                	sd	s4,48(sp)
    80004bda:	f456                	sd	s5,40(sp)
    80004bdc:	f05a                	sd	s6,32(sp)
    80004bde:	ec5e                	sd	s7,24(sp)
    80004be0:	e862                	sd	s8,16(sp)
    80004be2:	1080                	addi	s0,sp,96
    80004be4:	84aa                	mv	s1,a0
    80004be6:	8b2e                	mv	s6,a1
    80004be8:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004bea:	ffffd097          	auipc	ra,0xffffd
    80004bee:	ee8080e7          	jalr	-280(ra) # 80001ad2 <myproc>
    80004bf2:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	006080e7          	jalr	6(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004bfe:	09505763          	blez	s5,80004c8c <pipewrite+0xc0>
    80004c02:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c04:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c08:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c0c:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c0e:	2184a783          	lw	a5,536(s1)
    80004c12:	21c4a703          	lw	a4,540(s1)
    80004c16:	2007879b          	addiw	a5,a5,512
    80004c1a:	02f71b63          	bne	a4,a5,80004c50 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004c1e:	2204a783          	lw	a5,544(s1)
    80004c22:	c3d1                	beqz	a5,80004ca6 <pipewrite+0xda>
    80004c24:	03092783          	lw	a5,48(s2)
    80004c28:	efbd                	bnez	a5,80004ca6 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004c2a:	8552                	mv	a0,s4
    80004c2c:	ffffe097          	auipc	ra,0xffffe
    80004c30:	974080e7          	jalr	-1676(ra) # 800025a0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c34:	85a6                	mv	a1,s1
    80004c36:	854e                	mv	a0,s3
    80004c38:	ffffd097          	auipc	ra,0xffffd
    80004c3c:	7ce080e7          	jalr	1998(ra) # 80002406 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c40:	2184a783          	lw	a5,536(s1)
    80004c44:	21c4a703          	lw	a4,540(s1)
    80004c48:	2007879b          	addiw	a5,a5,512
    80004c4c:	fcf709e3          	beq	a4,a5,80004c1e <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c50:	4685                	li	a3,1
    80004c52:	865a                	mv	a2,s6
    80004c54:	faf40593          	addi	a1,s0,-81
    80004c58:	05093503          	ld	a0,80(s2)
    80004c5c:	ffffd097          	auipc	ra,0xffffd
    80004c60:	ada080e7          	jalr	-1318(ra) # 80001736 <copyin>
    80004c64:	03850563          	beq	a0,s8,80004c8e <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c68:	21c4a783          	lw	a5,540(s1)
    80004c6c:	0017871b          	addiw	a4,a5,1
    80004c70:	20e4ae23          	sw	a4,540(s1)
    80004c74:	1ff7f793          	andi	a5,a5,511
    80004c78:	97a6                	add	a5,a5,s1
    80004c7a:	faf44703          	lbu	a4,-81(s0)
    80004c7e:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c82:	2b85                	addiw	s7,s7,1
    80004c84:	0b05                	addi	s6,s6,1
    80004c86:	f97a94e3          	bne	s5,s7,80004c0e <pipewrite+0x42>
    80004c8a:	a011                	j	80004c8e <pipewrite+0xc2>
    80004c8c:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004c8e:	21848513          	addi	a0,s1,536
    80004c92:	ffffe097          	auipc	ra,0xffffe
    80004c96:	90e080e7          	jalr	-1778(ra) # 800025a0 <wakeup>
  release(&pi->lock);
    80004c9a:	8526                	mv	a0,s1
    80004c9c:	ffffc097          	auipc	ra,0xffffc
    80004ca0:	014080e7          	jalr	20(ra) # 80000cb0 <release>
  return i;
    80004ca4:	a039                	j	80004cb2 <pipewrite+0xe6>
        release(&pi->lock);
    80004ca6:	8526                	mv	a0,s1
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	008080e7          	jalr	8(ra) # 80000cb0 <release>
        return -1;
    80004cb0:	5bfd                	li	s7,-1
}
    80004cb2:	855e                	mv	a0,s7
    80004cb4:	60e6                	ld	ra,88(sp)
    80004cb6:	6446                	ld	s0,80(sp)
    80004cb8:	64a6                	ld	s1,72(sp)
    80004cba:	6906                	ld	s2,64(sp)
    80004cbc:	79e2                	ld	s3,56(sp)
    80004cbe:	7a42                	ld	s4,48(sp)
    80004cc0:	7aa2                	ld	s5,40(sp)
    80004cc2:	7b02                	ld	s6,32(sp)
    80004cc4:	6be2                	ld	s7,24(sp)
    80004cc6:	6c42                	ld	s8,16(sp)
    80004cc8:	6125                	addi	sp,sp,96
    80004cca:	8082                	ret

0000000080004ccc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ccc:	715d                	addi	sp,sp,-80
    80004cce:	e486                	sd	ra,72(sp)
    80004cd0:	e0a2                	sd	s0,64(sp)
    80004cd2:	fc26                	sd	s1,56(sp)
    80004cd4:	f84a                	sd	s2,48(sp)
    80004cd6:	f44e                	sd	s3,40(sp)
    80004cd8:	f052                	sd	s4,32(sp)
    80004cda:	ec56                	sd	s5,24(sp)
    80004cdc:	e85a                	sd	s6,16(sp)
    80004cde:	0880                	addi	s0,sp,80
    80004ce0:	84aa                	mv	s1,a0
    80004ce2:	892e                	mv	s2,a1
    80004ce4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	dec080e7          	jalr	-532(ra) # 80001ad2 <myproc>
    80004cee:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	f0a080e7          	jalr	-246(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cfa:	2184a703          	lw	a4,536(s1)
    80004cfe:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d02:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d06:	02f71463          	bne	a4,a5,80004d2e <piperead+0x62>
    80004d0a:	2244a783          	lw	a5,548(s1)
    80004d0e:	c385                	beqz	a5,80004d2e <piperead+0x62>
    if(pr->killed){
    80004d10:	030a2783          	lw	a5,48(s4)
    80004d14:	ebc1                	bnez	a5,80004da4 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d16:	85a6                	mv	a1,s1
    80004d18:	854e                	mv	a0,s3
    80004d1a:	ffffd097          	auipc	ra,0xffffd
    80004d1e:	6ec080e7          	jalr	1772(ra) # 80002406 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d22:	2184a703          	lw	a4,536(s1)
    80004d26:	21c4a783          	lw	a5,540(s1)
    80004d2a:	fef700e3          	beq	a4,a5,80004d0a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d2e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d30:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d32:	05505363          	blez	s5,80004d78 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004d36:	2184a783          	lw	a5,536(s1)
    80004d3a:	21c4a703          	lw	a4,540(s1)
    80004d3e:	02f70d63          	beq	a4,a5,80004d78 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d42:	0017871b          	addiw	a4,a5,1
    80004d46:	20e4ac23          	sw	a4,536(s1)
    80004d4a:	1ff7f793          	andi	a5,a5,511
    80004d4e:	97a6                	add	a5,a5,s1
    80004d50:	0187c783          	lbu	a5,24(a5)
    80004d54:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d58:	4685                	li	a3,1
    80004d5a:	fbf40613          	addi	a2,s0,-65
    80004d5e:	85ca                	mv	a1,s2
    80004d60:	050a3503          	ld	a0,80(s4)
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	946080e7          	jalr	-1722(ra) # 800016aa <copyout>
    80004d6c:	01650663          	beq	a0,s6,80004d78 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d70:	2985                	addiw	s3,s3,1
    80004d72:	0905                	addi	s2,s2,1
    80004d74:	fd3a91e3          	bne	s5,s3,80004d36 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d78:	21c48513          	addi	a0,s1,540
    80004d7c:	ffffe097          	auipc	ra,0xffffe
    80004d80:	824080e7          	jalr	-2012(ra) # 800025a0 <wakeup>
  release(&pi->lock);
    80004d84:	8526                	mv	a0,s1
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	f2a080e7          	jalr	-214(ra) # 80000cb0 <release>
  return i;
}
    80004d8e:	854e                	mv	a0,s3
    80004d90:	60a6                	ld	ra,72(sp)
    80004d92:	6406                	ld	s0,64(sp)
    80004d94:	74e2                	ld	s1,56(sp)
    80004d96:	7942                	ld	s2,48(sp)
    80004d98:	79a2                	ld	s3,40(sp)
    80004d9a:	7a02                	ld	s4,32(sp)
    80004d9c:	6ae2                	ld	s5,24(sp)
    80004d9e:	6b42                	ld	s6,16(sp)
    80004da0:	6161                	addi	sp,sp,80
    80004da2:	8082                	ret
      release(&pi->lock);
    80004da4:	8526                	mv	a0,s1
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	f0a080e7          	jalr	-246(ra) # 80000cb0 <release>
      return -1;
    80004dae:	59fd                	li	s3,-1
    80004db0:	bff9                	j	80004d8e <piperead+0xc2>

0000000080004db2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004db2:	de010113          	addi	sp,sp,-544
    80004db6:	20113c23          	sd	ra,536(sp)
    80004dba:	20813823          	sd	s0,528(sp)
    80004dbe:	20913423          	sd	s1,520(sp)
    80004dc2:	21213023          	sd	s2,512(sp)
    80004dc6:	ffce                	sd	s3,504(sp)
    80004dc8:	fbd2                	sd	s4,496(sp)
    80004dca:	f7d6                	sd	s5,488(sp)
    80004dcc:	f3da                	sd	s6,480(sp)
    80004dce:	efde                	sd	s7,472(sp)
    80004dd0:	ebe2                	sd	s8,464(sp)
    80004dd2:	e7e6                	sd	s9,456(sp)
    80004dd4:	e3ea                	sd	s10,448(sp)
    80004dd6:	ff6e                	sd	s11,440(sp)
    80004dd8:	1400                	addi	s0,sp,544
    80004dda:	892a                	mv	s2,a0
    80004ddc:	dea43423          	sd	a0,-536(s0)
    80004de0:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	cee080e7          	jalr	-786(ra) # 80001ad2 <myproc>
    80004dec:	84aa                	mv	s1,a0

  begin_op();
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	46c080e7          	jalr	1132(ra) # 8000425a <begin_op>

  if((ip = namei(path)) == 0){
    80004df6:	854a                	mv	a0,s2
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	252080e7          	jalr	594(ra) # 8000404a <namei>
    80004e00:	c93d                	beqz	a0,80004e76 <exec+0xc4>
    80004e02:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	a96080e7          	jalr	-1386(ra) # 8000389a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e0c:	04000713          	li	a4,64
    80004e10:	4681                	li	a3,0
    80004e12:	e4840613          	addi	a2,s0,-440
    80004e16:	4581                	li	a1,0
    80004e18:	8556                	mv	a0,s5
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	d34080e7          	jalr	-716(ra) # 80003b4e <readi>
    80004e22:	04000793          	li	a5,64
    80004e26:	00f51a63          	bne	a0,a5,80004e3a <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e2a:	e4842703          	lw	a4,-440(s0)
    80004e2e:	464c47b7          	lui	a5,0x464c4
    80004e32:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e36:	04f70663          	beq	a4,a5,80004e82 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e3a:	8556                	mv	a0,s5
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	cc0080e7          	jalr	-832(ra) # 80003afc <iunlockput>
    end_op();
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	496080e7          	jalr	1174(ra) # 800042da <end_op>
  }
  return -1;
    80004e4c:	557d                	li	a0,-1
}
    80004e4e:	21813083          	ld	ra,536(sp)
    80004e52:	21013403          	ld	s0,528(sp)
    80004e56:	20813483          	ld	s1,520(sp)
    80004e5a:	20013903          	ld	s2,512(sp)
    80004e5e:	79fe                	ld	s3,504(sp)
    80004e60:	7a5e                	ld	s4,496(sp)
    80004e62:	7abe                	ld	s5,488(sp)
    80004e64:	7b1e                	ld	s6,480(sp)
    80004e66:	6bfe                	ld	s7,472(sp)
    80004e68:	6c5e                	ld	s8,464(sp)
    80004e6a:	6cbe                	ld	s9,456(sp)
    80004e6c:	6d1e                	ld	s10,448(sp)
    80004e6e:	7dfa                	ld	s11,440(sp)
    80004e70:	22010113          	addi	sp,sp,544
    80004e74:	8082                	ret
    end_op();
    80004e76:	fffff097          	auipc	ra,0xfffff
    80004e7a:	464080e7          	jalr	1124(ra) # 800042da <end_op>
    return -1;
    80004e7e:	557d                	li	a0,-1
    80004e80:	b7f9                	j	80004e4e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e82:	8526                	mv	a0,s1
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	d14080e7          	jalr	-748(ra) # 80001b98 <proc_pagetable>
    80004e8c:	8b2a                	mv	s6,a0
    80004e8e:	d555                	beqz	a0,80004e3a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e90:	e6842783          	lw	a5,-408(s0)
    80004e94:	e8045703          	lhu	a4,-384(s0)
    80004e98:	c735                	beqz	a4,80004f04 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e9a:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e9c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ea0:	6a05                	lui	s4,0x1
    80004ea2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ea6:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004eaa:	6d85                	lui	s11,0x1
    80004eac:	7d7d                	lui	s10,0xfffff
    80004eae:	ac1d                	j	800050e4 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004eb0:	00004517          	auipc	a0,0x4
    80004eb4:	85850513          	addi	a0,a0,-1960 # 80008708 <syscalls+0x290>
    80004eb8:	ffffb097          	auipc	ra,0xffffb
    80004ebc:	688080e7          	jalr	1672(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ec0:	874a                	mv	a4,s2
    80004ec2:	009c86bb          	addw	a3,s9,s1
    80004ec6:	4581                	li	a1,0
    80004ec8:	8556                	mv	a0,s5
    80004eca:	fffff097          	auipc	ra,0xfffff
    80004ece:	c84080e7          	jalr	-892(ra) # 80003b4e <readi>
    80004ed2:	2501                	sext.w	a0,a0
    80004ed4:	1aa91863          	bne	s2,a0,80005084 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004ed8:	009d84bb          	addw	s1,s11,s1
    80004edc:	013d09bb          	addw	s3,s10,s3
    80004ee0:	1f74f263          	bgeu	s1,s7,800050c4 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004ee4:	02049593          	slli	a1,s1,0x20
    80004ee8:	9181                	srli	a1,a1,0x20
    80004eea:	95e2                	add	a1,a1,s8
    80004eec:	855a                	mv	a0,s6
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	188080e7          	jalr	392(ra) # 80001076 <walkaddr>
    80004ef6:	862a                	mv	a2,a0
    if(pa == 0)
    80004ef8:	dd45                	beqz	a0,80004eb0 <exec+0xfe>
      n = PGSIZE;
    80004efa:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004efc:	fd49f2e3          	bgeu	s3,s4,80004ec0 <exec+0x10e>
      n = sz - i;
    80004f00:	894e                	mv	s2,s3
    80004f02:	bf7d                	j	80004ec0 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f04:	4481                	li	s1,0
  iunlockput(ip);
    80004f06:	8556                	mv	a0,s5
    80004f08:	fffff097          	auipc	ra,0xfffff
    80004f0c:	bf4080e7          	jalr	-1036(ra) # 80003afc <iunlockput>
  end_op();
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	3ca080e7          	jalr	970(ra) # 800042da <end_op>
  p = myproc();
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	bba080e7          	jalr	-1094(ra) # 80001ad2 <myproc>
    80004f20:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f22:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f26:	6785                	lui	a5,0x1
    80004f28:	17fd                	addi	a5,a5,-1
    80004f2a:	94be                	add	s1,s1,a5
    80004f2c:	77fd                	lui	a5,0xfffff
    80004f2e:	8fe5                	and	a5,a5,s1
    80004f30:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f34:	6609                	lui	a2,0x2
    80004f36:	963e                	add	a2,a2,a5
    80004f38:	85be                	mv	a1,a5
    80004f3a:	855a                	mv	a0,s6
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	51e080e7          	jalr	1310(ra) # 8000145a <uvmalloc>
    80004f44:	8c2a                	mv	s8,a0
  ip = 0;
    80004f46:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f48:	12050e63          	beqz	a0,80005084 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f4c:	75f9                	lui	a1,0xffffe
    80004f4e:	95aa                	add	a1,a1,a0
    80004f50:	855a                	mv	a0,s6
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	726080e7          	jalr	1830(ra) # 80001678 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f5a:	7afd                	lui	s5,0xfffff
    80004f5c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f5e:	df043783          	ld	a5,-528(s0)
    80004f62:	6388                	ld	a0,0(a5)
    80004f64:	c925                	beqz	a0,80004fd4 <exec+0x222>
    80004f66:	e8840993          	addi	s3,s0,-376
    80004f6a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f6e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f70:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	f0a080e7          	jalr	-246(ra) # 80000e7c <strlen>
    80004f7a:	0015079b          	addiw	a5,a0,1
    80004f7e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f82:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f86:	13596363          	bltu	s2,s5,800050ac <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f8a:	df043d83          	ld	s11,-528(s0)
    80004f8e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f92:	8552                	mv	a0,s4
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	ee8080e7          	jalr	-280(ra) # 80000e7c <strlen>
    80004f9c:	0015069b          	addiw	a3,a0,1
    80004fa0:	8652                	mv	a2,s4
    80004fa2:	85ca                	mv	a1,s2
    80004fa4:	855a                	mv	a0,s6
    80004fa6:	ffffc097          	auipc	ra,0xffffc
    80004faa:	704080e7          	jalr	1796(ra) # 800016aa <copyout>
    80004fae:	10054363          	bltz	a0,800050b4 <exec+0x302>
    ustack[argc] = sp;
    80004fb2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fb6:	0485                	addi	s1,s1,1
    80004fb8:	008d8793          	addi	a5,s11,8
    80004fbc:	def43823          	sd	a5,-528(s0)
    80004fc0:	008db503          	ld	a0,8(s11)
    80004fc4:	c911                	beqz	a0,80004fd8 <exec+0x226>
    if(argc >= MAXARG)
    80004fc6:	09a1                	addi	s3,s3,8
    80004fc8:	fb3c95e3          	bne	s9,s3,80004f72 <exec+0x1c0>
  sz = sz1;
    80004fcc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fd0:	4a81                	li	s5,0
    80004fd2:	a84d                	j	80005084 <exec+0x2d2>
  sp = sz;
    80004fd4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fd6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fd8:	00349793          	slli	a5,s1,0x3
    80004fdc:	f9040713          	addi	a4,s0,-112
    80004fe0:	97ba                	add	a5,a5,a4
    80004fe2:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004fe6:	00148693          	addi	a3,s1,1
    80004fea:	068e                	slli	a3,a3,0x3
    80004fec:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ff0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ff4:	01597663          	bgeu	s2,s5,80005000 <exec+0x24e>
  sz = sz1;
    80004ff8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ffc:	4a81                	li	s5,0
    80004ffe:	a059                	j	80005084 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005000:	e8840613          	addi	a2,s0,-376
    80005004:	85ca                	mv	a1,s2
    80005006:	855a                	mv	a0,s6
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	6a2080e7          	jalr	1698(ra) # 800016aa <copyout>
    80005010:	0a054663          	bltz	a0,800050bc <exec+0x30a>
  p->trapframe->a1 = sp;
    80005014:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005018:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000501c:	de843783          	ld	a5,-536(s0)
    80005020:	0007c703          	lbu	a4,0(a5)
    80005024:	cf11                	beqz	a4,80005040 <exec+0x28e>
    80005026:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005028:	02f00693          	li	a3,47
    8000502c:	a039                	j	8000503a <exec+0x288>
      last = s+1;
    8000502e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005032:	0785                	addi	a5,a5,1
    80005034:	fff7c703          	lbu	a4,-1(a5)
    80005038:	c701                	beqz	a4,80005040 <exec+0x28e>
    if(*s == '/')
    8000503a:	fed71ce3          	bne	a4,a3,80005032 <exec+0x280>
    8000503e:	bfc5                	j	8000502e <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005040:	4641                	li	a2,16
    80005042:	de843583          	ld	a1,-536(s0)
    80005046:	158b8513          	addi	a0,s7,344
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	e00080e7          	jalr	-512(ra) # 80000e4a <safestrcpy>
  oldpagetable = p->pagetable;
    80005052:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005056:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000505a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000505e:	058bb783          	ld	a5,88(s7)
    80005062:	e6043703          	ld	a4,-416(s0)
    80005066:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005068:	058bb783          	ld	a5,88(s7)
    8000506c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005070:	85ea                	mv	a1,s10
    80005072:	ffffd097          	auipc	ra,0xffffd
    80005076:	bc2080e7          	jalr	-1086(ra) # 80001c34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000507a:	0004851b          	sext.w	a0,s1
    8000507e:	bbc1                	j	80004e4e <exec+0x9c>
    80005080:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005084:	df843583          	ld	a1,-520(s0)
    80005088:	855a                	mv	a0,s6
    8000508a:	ffffd097          	auipc	ra,0xffffd
    8000508e:	baa080e7          	jalr	-1110(ra) # 80001c34 <proc_freepagetable>
  if(ip){
    80005092:	da0a94e3          	bnez	s5,80004e3a <exec+0x88>
  return -1;
    80005096:	557d                	li	a0,-1
    80005098:	bb5d                	j	80004e4e <exec+0x9c>
    8000509a:	de943c23          	sd	s1,-520(s0)
    8000509e:	b7dd                	j	80005084 <exec+0x2d2>
    800050a0:	de943c23          	sd	s1,-520(s0)
    800050a4:	b7c5                	j	80005084 <exec+0x2d2>
    800050a6:	de943c23          	sd	s1,-520(s0)
    800050aa:	bfe9                	j	80005084 <exec+0x2d2>
  sz = sz1;
    800050ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050b0:	4a81                	li	s5,0
    800050b2:	bfc9                	j	80005084 <exec+0x2d2>
  sz = sz1;
    800050b4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050b8:	4a81                	li	s5,0
    800050ba:	b7e9                	j	80005084 <exec+0x2d2>
  sz = sz1;
    800050bc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050c0:	4a81                	li	s5,0
    800050c2:	b7c9                	j	80005084 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050c4:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050c8:	e0843783          	ld	a5,-504(s0)
    800050cc:	0017869b          	addiw	a3,a5,1
    800050d0:	e0d43423          	sd	a3,-504(s0)
    800050d4:	e0043783          	ld	a5,-512(s0)
    800050d8:	0387879b          	addiw	a5,a5,56
    800050dc:	e8045703          	lhu	a4,-384(s0)
    800050e0:	e2e6d3e3          	bge	a3,a4,80004f06 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050e4:	2781                	sext.w	a5,a5
    800050e6:	e0f43023          	sd	a5,-512(s0)
    800050ea:	03800713          	li	a4,56
    800050ee:	86be                	mv	a3,a5
    800050f0:	e1040613          	addi	a2,s0,-496
    800050f4:	4581                	li	a1,0
    800050f6:	8556                	mv	a0,s5
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	a56080e7          	jalr	-1450(ra) # 80003b4e <readi>
    80005100:	03800793          	li	a5,56
    80005104:	f6f51ee3          	bne	a0,a5,80005080 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005108:	e1042783          	lw	a5,-496(s0)
    8000510c:	4705                	li	a4,1
    8000510e:	fae79de3          	bne	a5,a4,800050c8 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005112:	e3843603          	ld	a2,-456(s0)
    80005116:	e3043783          	ld	a5,-464(s0)
    8000511a:	f8f660e3          	bltu	a2,a5,8000509a <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000511e:	e2043783          	ld	a5,-480(s0)
    80005122:	963e                	add	a2,a2,a5
    80005124:	f6f66ee3          	bltu	a2,a5,800050a0 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005128:	85a6                	mv	a1,s1
    8000512a:	855a                	mv	a0,s6
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	32e080e7          	jalr	814(ra) # 8000145a <uvmalloc>
    80005134:	dea43c23          	sd	a0,-520(s0)
    80005138:	d53d                	beqz	a0,800050a6 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000513a:	e2043c03          	ld	s8,-480(s0)
    8000513e:	de043783          	ld	a5,-544(s0)
    80005142:	00fc77b3          	and	a5,s8,a5
    80005146:	ff9d                	bnez	a5,80005084 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005148:	e1842c83          	lw	s9,-488(s0)
    8000514c:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005150:	f60b8ae3          	beqz	s7,800050c4 <exec+0x312>
    80005154:	89de                	mv	s3,s7
    80005156:	4481                	li	s1,0
    80005158:	b371                	j	80004ee4 <exec+0x132>

000000008000515a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000515a:	7179                	addi	sp,sp,-48
    8000515c:	f406                	sd	ra,40(sp)
    8000515e:	f022                	sd	s0,32(sp)
    80005160:	ec26                	sd	s1,24(sp)
    80005162:	e84a                	sd	s2,16(sp)
    80005164:	1800                	addi	s0,sp,48
    80005166:	892e                	mv	s2,a1
    80005168:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000516a:	fdc40593          	addi	a1,s0,-36
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	b8e080e7          	jalr	-1138(ra) # 80002cfc <argint>
    80005176:	04054063          	bltz	a0,800051b6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000517a:	fdc42703          	lw	a4,-36(s0)
    8000517e:	47bd                	li	a5,15
    80005180:	02e7ed63          	bltu	a5,a4,800051ba <argfd+0x60>
    80005184:	ffffd097          	auipc	ra,0xffffd
    80005188:	94e080e7          	jalr	-1714(ra) # 80001ad2 <myproc>
    8000518c:	fdc42703          	lw	a4,-36(s0)
    80005190:	01a70793          	addi	a5,a4,26
    80005194:	078e                	slli	a5,a5,0x3
    80005196:	953e                	add	a0,a0,a5
    80005198:	611c                	ld	a5,0(a0)
    8000519a:	c395                	beqz	a5,800051be <argfd+0x64>
    return -1;
  if(pfd)
    8000519c:	00090463          	beqz	s2,800051a4 <argfd+0x4a>
    *pfd = fd;
    800051a0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051a4:	4501                	li	a0,0
  if(pf)
    800051a6:	c091                	beqz	s1,800051aa <argfd+0x50>
    *pf = f;
    800051a8:	e09c                	sd	a5,0(s1)
}
    800051aa:	70a2                	ld	ra,40(sp)
    800051ac:	7402                	ld	s0,32(sp)
    800051ae:	64e2                	ld	s1,24(sp)
    800051b0:	6942                	ld	s2,16(sp)
    800051b2:	6145                	addi	sp,sp,48
    800051b4:	8082                	ret
    return -1;
    800051b6:	557d                	li	a0,-1
    800051b8:	bfcd                	j	800051aa <argfd+0x50>
    return -1;
    800051ba:	557d                	li	a0,-1
    800051bc:	b7fd                	j	800051aa <argfd+0x50>
    800051be:	557d                	li	a0,-1
    800051c0:	b7ed                	j	800051aa <argfd+0x50>

00000000800051c2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051c2:	1101                	addi	sp,sp,-32
    800051c4:	ec06                	sd	ra,24(sp)
    800051c6:	e822                	sd	s0,16(sp)
    800051c8:	e426                	sd	s1,8(sp)
    800051ca:	1000                	addi	s0,sp,32
    800051cc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051ce:	ffffd097          	auipc	ra,0xffffd
    800051d2:	904080e7          	jalr	-1788(ra) # 80001ad2 <myproc>
    800051d6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051d8:	0d050793          	addi	a5,a0,208
    800051dc:	4501                	li	a0,0
    800051de:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051e0:	6398                	ld	a4,0(a5)
    800051e2:	cb19                	beqz	a4,800051f8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051e4:	2505                	addiw	a0,a0,1
    800051e6:	07a1                	addi	a5,a5,8
    800051e8:	fed51ce3          	bne	a0,a3,800051e0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051ec:	557d                	li	a0,-1
}
    800051ee:	60e2                	ld	ra,24(sp)
    800051f0:	6442                	ld	s0,16(sp)
    800051f2:	64a2                	ld	s1,8(sp)
    800051f4:	6105                	addi	sp,sp,32
    800051f6:	8082                	ret
      p->ofile[fd] = f;
    800051f8:	01a50793          	addi	a5,a0,26
    800051fc:	078e                	slli	a5,a5,0x3
    800051fe:	963e                	add	a2,a2,a5
    80005200:	e204                	sd	s1,0(a2)
      return fd;
    80005202:	b7f5                	j	800051ee <fdalloc+0x2c>

0000000080005204 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005204:	715d                	addi	sp,sp,-80
    80005206:	e486                	sd	ra,72(sp)
    80005208:	e0a2                	sd	s0,64(sp)
    8000520a:	fc26                	sd	s1,56(sp)
    8000520c:	f84a                	sd	s2,48(sp)
    8000520e:	f44e                	sd	s3,40(sp)
    80005210:	f052                	sd	s4,32(sp)
    80005212:	ec56                	sd	s5,24(sp)
    80005214:	0880                	addi	s0,sp,80
    80005216:	89ae                	mv	s3,a1
    80005218:	8ab2                	mv	s5,a2
    8000521a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000521c:	fb040593          	addi	a1,s0,-80
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	e48080e7          	jalr	-440(ra) # 80004068 <nameiparent>
    80005228:	892a                	mv	s2,a0
    8000522a:	12050e63          	beqz	a0,80005366 <create+0x162>
    return 0;

  ilock(dp);
    8000522e:	ffffe097          	auipc	ra,0xffffe
    80005232:	66c080e7          	jalr	1644(ra) # 8000389a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005236:	4601                	li	a2,0
    80005238:	fb040593          	addi	a1,s0,-80
    8000523c:	854a                	mv	a0,s2
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	b3a080e7          	jalr	-1222(ra) # 80003d78 <dirlookup>
    80005246:	84aa                	mv	s1,a0
    80005248:	c921                	beqz	a0,80005298 <create+0x94>
    iunlockput(dp);
    8000524a:	854a                	mv	a0,s2
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	8b0080e7          	jalr	-1872(ra) # 80003afc <iunlockput>
    ilock(ip);
    80005254:	8526                	mv	a0,s1
    80005256:	ffffe097          	auipc	ra,0xffffe
    8000525a:	644080e7          	jalr	1604(ra) # 8000389a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000525e:	2981                	sext.w	s3,s3
    80005260:	4789                	li	a5,2
    80005262:	02f99463          	bne	s3,a5,8000528a <create+0x86>
    80005266:	0444d783          	lhu	a5,68(s1)
    8000526a:	37f9                	addiw	a5,a5,-2
    8000526c:	17c2                	slli	a5,a5,0x30
    8000526e:	93c1                	srli	a5,a5,0x30
    80005270:	4705                	li	a4,1
    80005272:	00f76c63          	bltu	a4,a5,8000528a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005276:	8526                	mv	a0,s1
    80005278:	60a6                	ld	ra,72(sp)
    8000527a:	6406                	ld	s0,64(sp)
    8000527c:	74e2                	ld	s1,56(sp)
    8000527e:	7942                	ld	s2,48(sp)
    80005280:	79a2                	ld	s3,40(sp)
    80005282:	7a02                	ld	s4,32(sp)
    80005284:	6ae2                	ld	s5,24(sp)
    80005286:	6161                	addi	sp,sp,80
    80005288:	8082                	ret
    iunlockput(ip);
    8000528a:	8526                	mv	a0,s1
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	870080e7          	jalr	-1936(ra) # 80003afc <iunlockput>
    return 0;
    80005294:	4481                	li	s1,0
    80005296:	b7c5                	j	80005276 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005298:	85ce                	mv	a1,s3
    8000529a:	00092503          	lw	a0,0(s2)
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	464080e7          	jalr	1124(ra) # 80003702 <ialloc>
    800052a6:	84aa                	mv	s1,a0
    800052a8:	c521                	beqz	a0,800052f0 <create+0xec>
  ilock(ip);
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	5f0080e7          	jalr	1520(ra) # 8000389a <ilock>
  ip->major = major;
    800052b2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052b6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052ba:	4a05                	li	s4,1
    800052bc:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800052c0:	8526                	mv	a0,s1
    800052c2:	ffffe097          	auipc	ra,0xffffe
    800052c6:	50e080e7          	jalr	1294(ra) # 800037d0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052ca:	2981                	sext.w	s3,s3
    800052cc:	03498a63          	beq	s3,s4,80005300 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800052d0:	40d0                	lw	a2,4(s1)
    800052d2:	fb040593          	addi	a1,s0,-80
    800052d6:	854a                	mv	a0,s2
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	cb0080e7          	jalr	-848(ra) # 80003f88 <dirlink>
    800052e0:	06054b63          	bltz	a0,80005356 <create+0x152>
  iunlockput(dp);
    800052e4:	854a                	mv	a0,s2
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	816080e7          	jalr	-2026(ra) # 80003afc <iunlockput>
  return ip;
    800052ee:	b761                	j	80005276 <create+0x72>
    panic("create: ialloc");
    800052f0:	00003517          	auipc	a0,0x3
    800052f4:	43850513          	addi	a0,a0,1080 # 80008728 <syscalls+0x2b0>
    800052f8:	ffffb097          	auipc	ra,0xffffb
    800052fc:	248080e7          	jalr	584(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    80005300:	04a95783          	lhu	a5,74(s2)
    80005304:	2785                	addiw	a5,a5,1
    80005306:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000530a:	854a                	mv	a0,s2
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	4c4080e7          	jalr	1220(ra) # 800037d0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005314:	40d0                	lw	a2,4(s1)
    80005316:	00003597          	auipc	a1,0x3
    8000531a:	42258593          	addi	a1,a1,1058 # 80008738 <syscalls+0x2c0>
    8000531e:	8526                	mv	a0,s1
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	c68080e7          	jalr	-920(ra) # 80003f88 <dirlink>
    80005328:	00054f63          	bltz	a0,80005346 <create+0x142>
    8000532c:	00492603          	lw	a2,4(s2)
    80005330:	00003597          	auipc	a1,0x3
    80005334:	41058593          	addi	a1,a1,1040 # 80008740 <syscalls+0x2c8>
    80005338:	8526                	mv	a0,s1
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	c4e080e7          	jalr	-946(ra) # 80003f88 <dirlink>
    80005342:	f80557e3          	bgez	a0,800052d0 <create+0xcc>
      panic("create dots");
    80005346:	00003517          	auipc	a0,0x3
    8000534a:	40250513          	addi	a0,a0,1026 # 80008748 <syscalls+0x2d0>
    8000534e:	ffffb097          	auipc	ra,0xffffb
    80005352:	1f2080e7          	jalr	498(ra) # 80000540 <panic>
    panic("create: dirlink");
    80005356:	00003517          	auipc	a0,0x3
    8000535a:	40250513          	addi	a0,a0,1026 # 80008758 <syscalls+0x2e0>
    8000535e:	ffffb097          	auipc	ra,0xffffb
    80005362:	1e2080e7          	jalr	482(ra) # 80000540 <panic>
    return 0;
    80005366:	84aa                	mv	s1,a0
    80005368:	b739                	j	80005276 <create+0x72>

000000008000536a <sys_dup>:
{
    8000536a:	7179                	addi	sp,sp,-48
    8000536c:	f406                	sd	ra,40(sp)
    8000536e:	f022                	sd	s0,32(sp)
    80005370:	ec26                	sd	s1,24(sp)
    80005372:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005374:	fd840613          	addi	a2,s0,-40
    80005378:	4581                	li	a1,0
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	dde080e7          	jalr	-546(ra) # 8000515a <argfd>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005386:	02054363          	bltz	a0,800053ac <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000538a:	fd843503          	ld	a0,-40(s0)
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	e34080e7          	jalr	-460(ra) # 800051c2 <fdalloc>
    80005396:	84aa                	mv	s1,a0
    return -1;
    80005398:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000539a:	00054963          	bltz	a0,800053ac <sys_dup+0x42>
  filedup(f);
    8000539e:	fd843503          	ld	a0,-40(s0)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	338080e7          	jalr	824(ra) # 800046da <filedup>
  return fd;
    800053aa:	87a6                	mv	a5,s1
}
    800053ac:	853e                	mv	a0,a5
    800053ae:	70a2                	ld	ra,40(sp)
    800053b0:	7402                	ld	s0,32(sp)
    800053b2:	64e2                	ld	s1,24(sp)
    800053b4:	6145                	addi	sp,sp,48
    800053b6:	8082                	ret

00000000800053b8 <sys_read>:
{
    800053b8:	7179                	addi	sp,sp,-48
    800053ba:	f406                	sd	ra,40(sp)
    800053bc:	f022                	sd	s0,32(sp)
    800053be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c0:	fe840613          	addi	a2,s0,-24
    800053c4:	4581                	li	a1,0
    800053c6:	4501                	li	a0,0
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	d92080e7          	jalr	-622(ra) # 8000515a <argfd>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d2:	04054163          	bltz	a0,80005414 <sys_read+0x5c>
    800053d6:	fe440593          	addi	a1,s0,-28
    800053da:	4509                	li	a0,2
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	920080e7          	jalr	-1760(ra) # 80002cfc <argint>
    return -1;
    800053e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e6:	02054763          	bltz	a0,80005414 <sys_read+0x5c>
    800053ea:	fd840593          	addi	a1,s0,-40
    800053ee:	4505                	li	a0,1
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	92e080e7          	jalr	-1746(ra) # 80002d1e <argaddr>
    return -1;
    800053f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fa:	00054d63          	bltz	a0,80005414 <sys_read+0x5c>
  return fileread(f, p, n);
    800053fe:	fe442603          	lw	a2,-28(s0)
    80005402:	fd843583          	ld	a1,-40(s0)
    80005406:	fe843503          	ld	a0,-24(s0)
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	45c080e7          	jalr	1116(ra) # 80004866 <fileread>
    80005412:	87aa                	mv	a5,a0
}
    80005414:	853e                	mv	a0,a5
    80005416:	70a2                	ld	ra,40(sp)
    80005418:	7402                	ld	s0,32(sp)
    8000541a:	6145                	addi	sp,sp,48
    8000541c:	8082                	ret

000000008000541e <sys_write>:
{
    8000541e:	7179                	addi	sp,sp,-48
    80005420:	f406                	sd	ra,40(sp)
    80005422:	f022                	sd	s0,32(sp)
    80005424:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005426:	fe840613          	addi	a2,s0,-24
    8000542a:	4581                	li	a1,0
    8000542c:	4501                	li	a0,0
    8000542e:	00000097          	auipc	ra,0x0
    80005432:	d2c080e7          	jalr	-724(ra) # 8000515a <argfd>
    return -1;
    80005436:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005438:	04054163          	bltz	a0,8000547a <sys_write+0x5c>
    8000543c:	fe440593          	addi	a1,s0,-28
    80005440:	4509                	li	a0,2
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	8ba080e7          	jalr	-1862(ra) # 80002cfc <argint>
    return -1;
    8000544a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544c:	02054763          	bltz	a0,8000547a <sys_write+0x5c>
    80005450:	fd840593          	addi	a1,s0,-40
    80005454:	4505                	li	a0,1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	8c8080e7          	jalr	-1848(ra) # 80002d1e <argaddr>
    return -1;
    8000545e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005460:	00054d63          	bltz	a0,8000547a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005464:	fe442603          	lw	a2,-28(s0)
    80005468:	fd843583          	ld	a1,-40(s0)
    8000546c:	fe843503          	ld	a0,-24(s0)
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	4b8080e7          	jalr	1208(ra) # 80004928 <filewrite>
    80005478:	87aa                	mv	a5,a0
}
    8000547a:	853e                	mv	a0,a5
    8000547c:	70a2                	ld	ra,40(sp)
    8000547e:	7402                	ld	s0,32(sp)
    80005480:	6145                	addi	sp,sp,48
    80005482:	8082                	ret

0000000080005484 <sys_close>:
{
    80005484:	1101                	addi	sp,sp,-32
    80005486:	ec06                	sd	ra,24(sp)
    80005488:	e822                	sd	s0,16(sp)
    8000548a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000548c:	fe040613          	addi	a2,s0,-32
    80005490:	fec40593          	addi	a1,s0,-20
    80005494:	4501                	li	a0,0
    80005496:	00000097          	auipc	ra,0x0
    8000549a:	cc4080e7          	jalr	-828(ra) # 8000515a <argfd>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054a0:	02054463          	bltz	a0,800054c8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	62e080e7          	jalr	1582(ra) # 80001ad2 <myproc>
    800054ac:	fec42783          	lw	a5,-20(s0)
    800054b0:	07e9                	addi	a5,a5,26
    800054b2:	078e                	slli	a5,a5,0x3
    800054b4:	97aa                	add	a5,a5,a0
    800054b6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054ba:	fe043503          	ld	a0,-32(s0)
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	26e080e7          	jalr	622(ra) # 8000472c <fileclose>
  return 0;
    800054c6:	4781                	li	a5,0
}
    800054c8:	853e                	mv	a0,a5
    800054ca:	60e2                	ld	ra,24(sp)
    800054cc:	6442                	ld	s0,16(sp)
    800054ce:	6105                	addi	sp,sp,32
    800054d0:	8082                	ret

00000000800054d2 <sys_fstat>:
{
    800054d2:	1101                	addi	sp,sp,-32
    800054d4:	ec06                	sd	ra,24(sp)
    800054d6:	e822                	sd	s0,16(sp)
    800054d8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054da:	fe840613          	addi	a2,s0,-24
    800054de:	4581                	li	a1,0
    800054e0:	4501                	li	a0,0
    800054e2:	00000097          	auipc	ra,0x0
    800054e6:	c78080e7          	jalr	-904(ra) # 8000515a <argfd>
    return -1;
    800054ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054ec:	02054563          	bltz	a0,80005516 <sys_fstat+0x44>
    800054f0:	fe040593          	addi	a1,s0,-32
    800054f4:	4505                	li	a0,1
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	828080e7          	jalr	-2008(ra) # 80002d1e <argaddr>
    return -1;
    800054fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005500:	00054b63          	bltz	a0,80005516 <sys_fstat+0x44>
  return filestat(f, st);
    80005504:	fe043583          	ld	a1,-32(s0)
    80005508:	fe843503          	ld	a0,-24(s0)
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	2e8080e7          	jalr	744(ra) # 800047f4 <filestat>
    80005514:	87aa                	mv	a5,a0
}
    80005516:	853e                	mv	a0,a5
    80005518:	60e2                	ld	ra,24(sp)
    8000551a:	6442                	ld	s0,16(sp)
    8000551c:	6105                	addi	sp,sp,32
    8000551e:	8082                	ret

0000000080005520 <sys_link>:
{
    80005520:	7169                	addi	sp,sp,-304
    80005522:	f606                	sd	ra,296(sp)
    80005524:	f222                	sd	s0,288(sp)
    80005526:	ee26                	sd	s1,280(sp)
    80005528:	ea4a                	sd	s2,272(sp)
    8000552a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000552c:	08000613          	li	a2,128
    80005530:	ed040593          	addi	a1,s0,-304
    80005534:	4501                	li	a0,0
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	80a080e7          	jalr	-2038(ra) # 80002d40 <argstr>
    return -1;
    8000553e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005540:	10054e63          	bltz	a0,8000565c <sys_link+0x13c>
    80005544:	08000613          	li	a2,128
    80005548:	f5040593          	addi	a1,s0,-176
    8000554c:	4505                	li	a0,1
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	7f2080e7          	jalr	2034(ra) # 80002d40 <argstr>
    return -1;
    80005556:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005558:	10054263          	bltz	a0,8000565c <sys_link+0x13c>
  begin_op();
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	cfe080e7          	jalr	-770(ra) # 8000425a <begin_op>
  if((ip = namei(old)) == 0){
    80005564:	ed040513          	addi	a0,s0,-304
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	ae2080e7          	jalr	-1310(ra) # 8000404a <namei>
    80005570:	84aa                	mv	s1,a0
    80005572:	c551                	beqz	a0,800055fe <sys_link+0xde>
  ilock(ip);
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	326080e7          	jalr	806(ra) # 8000389a <ilock>
  if(ip->type == T_DIR){
    8000557c:	04449703          	lh	a4,68(s1)
    80005580:	4785                	li	a5,1
    80005582:	08f70463          	beq	a4,a5,8000560a <sys_link+0xea>
  ip->nlink++;
    80005586:	04a4d783          	lhu	a5,74(s1)
    8000558a:	2785                	addiw	a5,a5,1
    8000558c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005590:	8526                	mv	a0,s1
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	23e080e7          	jalr	574(ra) # 800037d0 <iupdate>
  iunlock(ip);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	3c0080e7          	jalr	960(ra) # 8000395c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055a4:	fd040593          	addi	a1,s0,-48
    800055a8:	f5040513          	addi	a0,s0,-176
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	abc080e7          	jalr	-1348(ra) # 80004068 <nameiparent>
    800055b4:	892a                	mv	s2,a0
    800055b6:	c935                	beqz	a0,8000562a <sys_link+0x10a>
  ilock(dp);
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	2e2080e7          	jalr	738(ra) # 8000389a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055c0:	00092703          	lw	a4,0(s2)
    800055c4:	409c                	lw	a5,0(s1)
    800055c6:	04f71d63          	bne	a4,a5,80005620 <sys_link+0x100>
    800055ca:	40d0                	lw	a2,4(s1)
    800055cc:	fd040593          	addi	a1,s0,-48
    800055d0:	854a                	mv	a0,s2
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	9b6080e7          	jalr	-1610(ra) # 80003f88 <dirlink>
    800055da:	04054363          	bltz	a0,80005620 <sys_link+0x100>
  iunlockput(dp);
    800055de:	854a                	mv	a0,s2
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	51c080e7          	jalr	1308(ra) # 80003afc <iunlockput>
  iput(ip);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	46a080e7          	jalr	1130(ra) # 80003a54 <iput>
  end_op();
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	ce8080e7          	jalr	-792(ra) # 800042da <end_op>
  return 0;
    800055fa:	4781                	li	a5,0
    800055fc:	a085                	j	8000565c <sys_link+0x13c>
    end_op();
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	cdc080e7          	jalr	-804(ra) # 800042da <end_op>
    return -1;
    80005606:	57fd                	li	a5,-1
    80005608:	a891                	j	8000565c <sys_link+0x13c>
    iunlockput(ip);
    8000560a:	8526                	mv	a0,s1
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	4f0080e7          	jalr	1264(ra) # 80003afc <iunlockput>
    end_op();
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	cc6080e7          	jalr	-826(ra) # 800042da <end_op>
    return -1;
    8000561c:	57fd                	li	a5,-1
    8000561e:	a83d                	j	8000565c <sys_link+0x13c>
    iunlockput(dp);
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	4da080e7          	jalr	1242(ra) # 80003afc <iunlockput>
  ilock(ip);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	26e080e7          	jalr	622(ra) # 8000389a <ilock>
  ip->nlink--;
    80005634:	04a4d783          	lhu	a5,74(s1)
    80005638:	37fd                	addiw	a5,a5,-1
    8000563a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	190080e7          	jalr	400(ra) # 800037d0 <iupdate>
  iunlockput(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	4b2080e7          	jalr	1202(ra) # 80003afc <iunlockput>
  end_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	c88080e7          	jalr	-888(ra) # 800042da <end_op>
  return -1;
    8000565a:	57fd                	li	a5,-1
}
    8000565c:	853e                	mv	a0,a5
    8000565e:	70b2                	ld	ra,296(sp)
    80005660:	7412                	ld	s0,288(sp)
    80005662:	64f2                	ld	s1,280(sp)
    80005664:	6952                	ld	s2,272(sp)
    80005666:	6155                	addi	sp,sp,304
    80005668:	8082                	ret

000000008000566a <sys_unlink>:
{
    8000566a:	7151                	addi	sp,sp,-240
    8000566c:	f586                	sd	ra,232(sp)
    8000566e:	f1a2                	sd	s0,224(sp)
    80005670:	eda6                	sd	s1,216(sp)
    80005672:	e9ca                	sd	s2,208(sp)
    80005674:	e5ce                	sd	s3,200(sp)
    80005676:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005678:	08000613          	li	a2,128
    8000567c:	f3040593          	addi	a1,s0,-208
    80005680:	4501                	li	a0,0
    80005682:	ffffd097          	auipc	ra,0xffffd
    80005686:	6be080e7          	jalr	1726(ra) # 80002d40 <argstr>
    8000568a:	18054163          	bltz	a0,8000580c <sys_unlink+0x1a2>
  begin_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	bcc080e7          	jalr	-1076(ra) # 8000425a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005696:	fb040593          	addi	a1,s0,-80
    8000569a:	f3040513          	addi	a0,s0,-208
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	9ca080e7          	jalr	-1590(ra) # 80004068 <nameiparent>
    800056a6:	84aa                	mv	s1,a0
    800056a8:	c979                	beqz	a0,8000577e <sys_unlink+0x114>
  ilock(dp);
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	1f0080e7          	jalr	496(ra) # 8000389a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056b2:	00003597          	auipc	a1,0x3
    800056b6:	08658593          	addi	a1,a1,134 # 80008738 <syscalls+0x2c0>
    800056ba:	fb040513          	addi	a0,s0,-80
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	6a0080e7          	jalr	1696(ra) # 80003d5e <namecmp>
    800056c6:	14050a63          	beqz	a0,8000581a <sys_unlink+0x1b0>
    800056ca:	00003597          	auipc	a1,0x3
    800056ce:	07658593          	addi	a1,a1,118 # 80008740 <syscalls+0x2c8>
    800056d2:	fb040513          	addi	a0,s0,-80
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	688080e7          	jalr	1672(ra) # 80003d5e <namecmp>
    800056de:	12050e63          	beqz	a0,8000581a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056e2:	f2c40613          	addi	a2,s0,-212
    800056e6:	fb040593          	addi	a1,s0,-80
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	68c080e7          	jalr	1676(ra) # 80003d78 <dirlookup>
    800056f4:	892a                	mv	s2,a0
    800056f6:	12050263          	beqz	a0,8000581a <sys_unlink+0x1b0>
  ilock(ip);
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	1a0080e7          	jalr	416(ra) # 8000389a <ilock>
  if(ip->nlink < 1)
    80005702:	04a91783          	lh	a5,74(s2)
    80005706:	08f05263          	blez	a5,8000578a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000570a:	04491703          	lh	a4,68(s2)
    8000570e:	4785                	li	a5,1
    80005710:	08f70563          	beq	a4,a5,8000579a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005714:	4641                	li	a2,16
    80005716:	4581                	li	a1,0
    80005718:	fc040513          	addi	a0,s0,-64
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	5dc080e7          	jalr	1500(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005724:	4741                	li	a4,16
    80005726:	f2c42683          	lw	a3,-212(s0)
    8000572a:	fc040613          	addi	a2,s0,-64
    8000572e:	4581                	li	a1,0
    80005730:	8526                	mv	a0,s1
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	512080e7          	jalr	1298(ra) # 80003c44 <writei>
    8000573a:	47c1                	li	a5,16
    8000573c:	0af51563          	bne	a0,a5,800057e6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005740:	04491703          	lh	a4,68(s2)
    80005744:	4785                	li	a5,1
    80005746:	0af70863          	beq	a4,a5,800057f6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000574a:	8526                	mv	a0,s1
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	3b0080e7          	jalr	944(ra) # 80003afc <iunlockput>
  ip->nlink--;
    80005754:	04a95783          	lhu	a5,74(s2)
    80005758:	37fd                	addiw	a5,a5,-1
    8000575a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000575e:	854a                	mv	a0,s2
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	070080e7          	jalr	112(ra) # 800037d0 <iupdate>
  iunlockput(ip);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	392080e7          	jalr	914(ra) # 80003afc <iunlockput>
  end_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	b68080e7          	jalr	-1176(ra) # 800042da <end_op>
  return 0;
    8000577a:	4501                	li	a0,0
    8000577c:	a84d                	j	8000582e <sys_unlink+0x1c4>
    end_op();
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	b5c080e7          	jalr	-1188(ra) # 800042da <end_op>
    return -1;
    80005786:	557d                	li	a0,-1
    80005788:	a05d                	j	8000582e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000578a:	00003517          	auipc	a0,0x3
    8000578e:	fde50513          	addi	a0,a0,-34 # 80008768 <syscalls+0x2f0>
    80005792:	ffffb097          	auipc	ra,0xffffb
    80005796:	dae080e7          	jalr	-594(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000579a:	04c92703          	lw	a4,76(s2)
    8000579e:	02000793          	li	a5,32
    800057a2:	f6e7f9e3          	bgeu	a5,a4,80005714 <sys_unlink+0xaa>
    800057a6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057aa:	4741                	li	a4,16
    800057ac:	86ce                	mv	a3,s3
    800057ae:	f1840613          	addi	a2,s0,-232
    800057b2:	4581                	li	a1,0
    800057b4:	854a                	mv	a0,s2
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	398080e7          	jalr	920(ra) # 80003b4e <readi>
    800057be:	47c1                	li	a5,16
    800057c0:	00f51b63          	bne	a0,a5,800057d6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057c4:	f1845783          	lhu	a5,-232(s0)
    800057c8:	e7a1                	bnez	a5,80005810 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ca:	29c1                	addiw	s3,s3,16
    800057cc:	04c92783          	lw	a5,76(s2)
    800057d0:	fcf9ede3          	bltu	s3,a5,800057aa <sys_unlink+0x140>
    800057d4:	b781                	j	80005714 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057d6:	00003517          	auipc	a0,0x3
    800057da:	faa50513          	addi	a0,a0,-86 # 80008780 <syscalls+0x308>
    800057de:	ffffb097          	auipc	ra,0xffffb
    800057e2:	d62080e7          	jalr	-670(ra) # 80000540 <panic>
    panic("unlink: writei");
    800057e6:	00003517          	auipc	a0,0x3
    800057ea:	fb250513          	addi	a0,a0,-78 # 80008798 <syscalls+0x320>
    800057ee:	ffffb097          	auipc	ra,0xffffb
    800057f2:	d52080e7          	jalr	-686(ra) # 80000540 <panic>
    dp->nlink--;
    800057f6:	04a4d783          	lhu	a5,74(s1)
    800057fa:	37fd                	addiw	a5,a5,-1
    800057fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005800:	8526                	mv	a0,s1
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	fce080e7          	jalr	-50(ra) # 800037d0 <iupdate>
    8000580a:	b781                	j	8000574a <sys_unlink+0xe0>
    return -1;
    8000580c:	557d                	li	a0,-1
    8000580e:	a005                	j	8000582e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005810:	854a                	mv	a0,s2
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	2ea080e7          	jalr	746(ra) # 80003afc <iunlockput>
  iunlockput(dp);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	2e0080e7          	jalr	736(ra) # 80003afc <iunlockput>
  end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	ab6080e7          	jalr	-1354(ra) # 800042da <end_op>
  return -1;
    8000582c:	557d                	li	a0,-1
}
    8000582e:	70ae                	ld	ra,232(sp)
    80005830:	740e                	ld	s0,224(sp)
    80005832:	64ee                	ld	s1,216(sp)
    80005834:	694e                	ld	s2,208(sp)
    80005836:	69ae                	ld	s3,200(sp)
    80005838:	616d                	addi	sp,sp,240
    8000583a:	8082                	ret

000000008000583c <sys_open>:

uint64
sys_open(void)
{
    8000583c:	7131                	addi	sp,sp,-192
    8000583e:	fd06                	sd	ra,184(sp)
    80005840:	f922                	sd	s0,176(sp)
    80005842:	f526                	sd	s1,168(sp)
    80005844:	f14a                	sd	s2,160(sp)
    80005846:	ed4e                	sd	s3,152(sp)
    80005848:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000584a:	08000613          	li	a2,128
    8000584e:	f5040593          	addi	a1,s0,-176
    80005852:	4501                	li	a0,0
    80005854:	ffffd097          	auipc	ra,0xffffd
    80005858:	4ec080e7          	jalr	1260(ra) # 80002d40 <argstr>
    return -1;
    8000585c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000585e:	0c054163          	bltz	a0,80005920 <sys_open+0xe4>
    80005862:	f4c40593          	addi	a1,s0,-180
    80005866:	4505                	li	a0,1
    80005868:	ffffd097          	auipc	ra,0xffffd
    8000586c:	494080e7          	jalr	1172(ra) # 80002cfc <argint>
    80005870:	0a054863          	bltz	a0,80005920 <sys_open+0xe4>

  begin_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	9e6080e7          	jalr	-1562(ra) # 8000425a <begin_op>

  if(omode & O_CREATE){
    8000587c:	f4c42783          	lw	a5,-180(s0)
    80005880:	2007f793          	andi	a5,a5,512
    80005884:	cbdd                	beqz	a5,8000593a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005886:	4681                	li	a3,0
    80005888:	4601                	li	a2,0
    8000588a:	4589                	li	a1,2
    8000588c:	f5040513          	addi	a0,s0,-176
    80005890:	00000097          	auipc	ra,0x0
    80005894:	974080e7          	jalr	-1676(ra) # 80005204 <create>
    80005898:	892a                	mv	s2,a0
    if(ip == 0){
    8000589a:	c959                	beqz	a0,80005930 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000589c:	04491703          	lh	a4,68(s2)
    800058a0:	478d                	li	a5,3
    800058a2:	00f71763          	bne	a4,a5,800058b0 <sys_open+0x74>
    800058a6:	04695703          	lhu	a4,70(s2)
    800058aa:	47a5                	li	a5,9
    800058ac:	0ce7ec63          	bltu	a5,a4,80005984 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	dc0080e7          	jalr	-576(ra) # 80004670 <filealloc>
    800058b8:	89aa                	mv	s3,a0
    800058ba:	10050263          	beqz	a0,800059be <sys_open+0x182>
    800058be:	00000097          	auipc	ra,0x0
    800058c2:	904080e7          	jalr	-1788(ra) # 800051c2 <fdalloc>
    800058c6:	84aa                	mv	s1,a0
    800058c8:	0e054663          	bltz	a0,800059b4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058cc:	04491703          	lh	a4,68(s2)
    800058d0:	478d                	li	a5,3
    800058d2:	0cf70463          	beq	a4,a5,8000599a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058d6:	4789                	li	a5,2
    800058d8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058dc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058e0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058e4:	f4c42783          	lw	a5,-180(s0)
    800058e8:	0017c713          	xori	a4,a5,1
    800058ec:	8b05                	andi	a4,a4,1
    800058ee:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058f2:	0037f713          	andi	a4,a5,3
    800058f6:	00e03733          	snez	a4,a4
    800058fa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058fe:	4007f793          	andi	a5,a5,1024
    80005902:	c791                	beqz	a5,8000590e <sys_open+0xd2>
    80005904:	04491703          	lh	a4,68(s2)
    80005908:	4789                	li	a5,2
    8000590a:	08f70f63          	beq	a4,a5,800059a8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000590e:	854a                	mv	a0,s2
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	04c080e7          	jalr	76(ra) # 8000395c <iunlock>
  end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	9c2080e7          	jalr	-1598(ra) # 800042da <end_op>

  return fd;
}
    80005920:	8526                	mv	a0,s1
    80005922:	70ea                	ld	ra,184(sp)
    80005924:	744a                	ld	s0,176(sp)
    80005926:	74aa                	ld	s1,168(sp)
    80005928:	790a                	ld	s2,160(sp)
    8000592a:	69ea                	ld	s3,152(sp)
    8000592c:	6129                	addi	sp,sp,192
    8000592e:	8082                	ret
      end_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	9aa080e7          	jalr	-1622(ra) # 800042da <end_op>
      return -1;
    80005938:	b7e5                	j	80005920 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000593a:	f5040513          	addi	a0,s0,-176
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	70c080e7          	jalr	1804(ra) # 8000404a <namei>
    80005946:	892a                	mv	s2,a0
    80005948:	c905                	beqz	a0,80005978 <sys_open+0x13c>
    ilock(ip);
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	f50080e7          	jalr	-176(ra) # 8000389a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005952:	04491703          	lh	a4,68(s2)
    80005956:	4785                	li	a5,1
    80005958:	f4f712e3          	bne	a4,a5,8000589c <sys_open+0x60>
    8000595c:	f4c42783          	lw	a5,-180(s0)
    80005960:	dba1                	beqz	a5,800058b0 <sys_open+0x74>
      iunlockput(ip);
    80005962:	854a                	mv	a0,s2
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	198080e7          	jalr	408(ra) # 80003afc <iunlockput>
      end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	96e080e7          	jalr	-1682(ra) # 800042da <end_op>
      return -1;
    80005974:	54fd                	li	s1,-1
    80005976:	b76d                	j	80005920 <sys_open+0xe4>
      end_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	962080e7          	jalr	-1694(ra) # 800042da <end_op>
      return -1;
    80005980:	54fd                	li	s1,-1
    80005982:	bf79                	j	80005920 <sys_open+0xe4>
    iunlockput(ip);
    80005984:	854a                	mv	a0,s2
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	176080e7          	jalr	374(ra) # 80003afc <iunlockput>
    end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	94c080e7          	jalr	-1716(ra) # 800042da <end_op>
    return -1;
    80005996:	54fd                	li	s1,-1
    80005998:	b761                	j	80005920 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000599a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000599e:	04691783          	lh	a5,70(s2)
    800059a2:	02f99223          	sh	a5,36(s3)
    800059a6:	bf2d                	j	800058e0 <sys_open+0xa4>
    itrunc(ip);
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	ffe080e7          	jalr	-2(ra) # 800039a8 <itrunc>
    800059b2:	bfb1                	j	8000590e <sys_open+0xd2>
      fileclose(f);
    800059b4:	854e                	mv	a0,s3
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	d76080e7          	jalr	-650(ra) # 8000472c <fileclose>
    iunlockput(ip);
    800059be:	854a                	mv	a0,s2
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	13c080e7          	jalr	316(ra) # 80003afc <iunlockput>
    end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	912080e7          	jalr	-1774(ra) # 800042da <end_op>
    return -1;
    800059d0:	54fd                	li	s1,-1
    800059d2:	b7b9                	j	80005920 <sys_open+0xe4>

00000000800059d4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059d4:	7175                	addi	sp,sp,-144
    800059d6:	e506                	sd	ra,136(sp)
    800059d8:	e122                	sd	s0,128(sp)
    800059da:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	87e080e7          	jalr	-1922(ra) # 8000425a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059e4:	08000613          	li	a2,128
    800059e8:	f7040593          	addi	a1,s0,-144
    800059ec:	4501                	li	a0,0
    800059ee:	ffffd097          	auipc	ra,0xffffd
    800059f2:	352080e7          	jalr	850(ra) # 80002d40 <argstr>
    800059f6:	02054963          	bltz	a0,80005a28 <sys_mkdir+0x54>
    800059fa:	4681                	li	a3,0
    800059fc:	4601                	li	a2,0
    800059fe:	4585                	li	a1,1
    80005a00:	f7040513          	addi	a0,s0,-144
    80005a04:	00000097          	auipc	ra,0x0
    80005a08:	800080e7          	jalr	-2048(ra) # 80005204 <create>
    80005a0c:	cd11                	beqz	a0,80005a28 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	0ee080e7          	jalr	238(ra) # 80003afc <iunlockput>
  end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	8c4080e7          	jalr	-1852(ra) # 800042da <end_op>
  return 0;
    80005a1e:	4501                	li	a0,0
}
    80005a20:	60aa                	ld	ra,136(sp)
    80005a22:	640a                	ld	s0,128(sp)
    80005a24:	6149                	addi	sp,sp,144
    80005a26:	8082                	ret
    end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	8b2080e7          	jalr	-1870(ra) # 800042da <end_op>
    return -1;
    80005a30:	557d                	li	a0,-1
    80005a32:	b7fd                	j	80005a20 <sys_mkdir+0x4c>

0000000080005a34 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a34:	7135                	addi	sp,sp,-160
    80005a36:	ed06                	sd	ra,152(sp)
    80005a38:	e922                	sd	s0,144(sp)
    80005a3a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	81e080e7          	jalr	-2018(ra) # 8000425a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a44:	08000613          	li	a2,128
    80005a48:	f7040593          	addi	a1,s0,-144
    80005a4c:	4501                	li	a0,0
    80005a4e:	ffffd097          	auipc	ra,0xffffd
    80005a52:	2f2080e7          	jalr	754(ra) # 80002d40 <argstr>
    80005a56:	04054a63          	bltz	a0,80005aaa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a5a:	f6c40593          	addi	a1,s0,-148
    80005a5e:	4505                	li	a0,1
    80005a60:	ffffd097          	auipc	ra,0xffffd
    80005a64:	29c080e7          	jalr	668(ra) # 80002cfc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a68:	04054163          	bltz	a0,80005aaa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a6c:	f6840593          	addi	a1,s0,-152
    80005a70:	4509                	li	a0,2
    80005a72:	ffffd097          	auipc	ra,0xffffd
    80005a76:	28a080e7          	jalr	650(ra) # 80002cfc <argint>
     argint(1, &major) < 0 ||
    80005a7a:	02054863          	bltz	a0,80005aaa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a7e:	f6841683          	lh	a3,-152(s0)
    80005a82:	f6c41603          	lh	a2,-148(s0)
    80005a86:	458d                	li	a1,3
    80005a88:	f7040513          	addi	a0,s0,-144
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	778080e7          	jalr	1912(ra) # 80005204 <create>
     argint(2, &minor) < 0 ||
    80005a94:	c919                	beqz	a0,80005aaa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	066080e7          	jalr	102(ra) # 80003afc <iunlockput>
  end_op();
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	83c080e7          	jalr	-1988(ra) # 800042da <end_op>
  return 0;
    80005aa6:	4501                	li	a0,0
    80005aa8:	a031                	j	80005ab4 <sys_mknod+0x80>
    end_op();
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	830080e7          	jalr	-2000(ra) # 800042da <end_op>
    return -1;
    80005ab2:	557d                	li	a0,-1
}
    80005ab4:	60ea                	ld	ra,152(sp)
    80005ab6:	644a                	ld	s0,144(sp)
    80005ab8:	610d                	addi	sp,sp,160
    80005aba:	8082                	ret

0000000080005abc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005abc:	7135                	addi	sp,sp,-160
    80005abe:	ed06                	sd	ra,152(sp)
    80005ac0:	e922                	sd	s0,144(sp)
    80005ac2:	e526                	sd	s1,136(sp)
    80005ac4:	e14a                	sd	s2,128(sp)
    80005ac6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ac8:	ffffc097          	auipc	ra,0xffffc
    80005acc:	00a080e7          	jalr	10(ra) # 80001ad2 <myproc>
    80005ad0:	892a                	mv	s2,a0
  
  begin_op();
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	788080e7          	jalr	1928(ra) # 8000425a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ada:	08000613          	li	a2,128
    80005ade:	f6040593          	addi	a1,s0,-160
    80005ae2:	4501                	li	a0,0
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	25c080e7          	jalr	604(ra) # 80002d40 <argstr>
    80005aec:	04054b63          	bltz	a0,80005b42 <sys_chdir+0x86>
    80005af0:	f6040513          	addi	a0,s0,-160
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	556080e7          	jalr	1366(ra) # 8000404a <namei>
    80005afc:	84aa                	mv	s1,a0
    80005afe:	c131                	beqz	a0,80005b42 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	d9a080e7          	jalr	-614(ra) # 8000389a <ilock>
  if(ip->type != T_DIR){
    80005b08:	04449703          	lh	a4,68(s1)
    80005b0c:	4785                	li	a5,1
    80005b0e:	04f71063          	bne	a4,a5,80005b4e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b12:	8526                	mv	a0,s1
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	e48080e7          	jalr	-440(ra) # 8000395c <iunlock>
  iput(p->cwd);
    80005b1c:	15093503          	ld	a0,336(s2)
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	f34080e7          	jalr	-204(ra) # 80003a54 <iput>
  end_op();
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	7b2080e7          	jalr	1970(ra) # 800042da <end_op>
  p->cwd = ip;
    80005b30:	14993823          	sd	s1,336(s2)
  return 0;
    80005b34:	4501                	li	a0,0
}
    80005b36:	60ea                	ld	ra,152(sp)
    80005b38:	644a                	ld	s0,144(sp)
    80005b3a:	64aa                	ld	s1,136(sp)
    80005b3c:	690a                	ld	s2,128(sp)
    80005b3e:	610d                	addi	sp,sp,160
    80005b40:	8082                	ret
    end_op();
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	798080e7          	jalr	1944(ra) # 800042da <end_op>
    return -1;
    80005b4a:	557d                	li	a0,-1
    80005b4c:	b7ed                	j	80005b36 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b4e:	8526                	mv	a0,s1
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	fac080e7          	jalr	-84(ra) # 80003afc <iunlockput>
    end_op();
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	782080e7          	jalr	1922(ra) # 800042da <end_op>
    return -1;
    80005b60:	557d                	li	a0,-1
    80005b62:	bfd1                	j	80005b36 <sys_chdir+0x7a>

0000000080005b64 <sys_exec>:

uint64
sys_exec(void)
{
    80005b64:	7145                	addi	sp,sp,-464
    80005b66:	e786                	sd	ra,456(sp)
    80005b68:	e3a2                	sd	s0,448(sp)
    80005b6a:	ff26                	sd	s1,440(sp)
    80005b6c:	fb4a                	sd	s2,432(sp)
    80005b6e:	f74e                	sd	s3,424(sp)
    80005b70:	f352                	sd	s4,416(sp)
    80005b72:	ef56                	sd	s5,408(sp)
    80005b74:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b76:	08000613          	li	a2,128
    80005b7a:	f4040593          	addi	a1,s0,-192
    80005b7e:	4501                	li	a0,0
    80005b80:	ffffd097          	auipc	ra,0xffffd
    80005b84:	1c0080e7          	jalr	448(ra) # 80002d40 <argstr>
    return -1;
    80005b88:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b8a:	0c054a63          	bltz	a0,80005c5e <sys_exec+0xfa>
    80005b8e:	e3840593          	addi	a1,s0,-456
    80005b92:	4505                	li	a0,1
    80005b94:	ffffd097          	auipc	ra,0xffffd
    80005b98:	18a080e7          	jalr	394(ra) # 80002d1e <argaddr>
    80005b9c:	0c054163          	bltz	a0,80005c5e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ba0:	10000613          	li	a2,256
    80005ba4:	4581                	li	a1,0
    80005ba6:	e4040513          	addi	a0,s0,-448
    80005baa:	ffffb097          	auipc	ra,0xffffb
    80005bae:	14e080e7          	jalr	334(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bb2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bb6:	89a6                	mv	s3,s1
    80005bb8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bba:	02000a13          	li	s4,32
    80005bbe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bc2:	00391793          	slli	a5,s2,0x3
    80005bc6:	e3040593          	addi	a1,s0,-464
    80005bca:	e3843503          	ld	a0,-456(s0)
    80005bce:	953e                	add	a0,a0,a5
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	092080e7          	jalr	146(ra) # 80002c62 <fetchaddr>
    80005bd8:	02054a63          	bltz	a0,80005c0c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bdc:	e3043783          	ld	a5,-464(s0)
    80005be0:	c3b9                	beqz	a5,80005c26 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	f2a080e7          	jalr	-214(ra) # 80000b0c <kalloc>
    80005bea:	85aa                	mv	a1,a0
    80005bec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bf0:	cd11                	beqz	a0,80005c0c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bf2:	6605                	lui	a2,0x1
    80005bf4:	e3043503          	ld	a0,-464(s0)
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	0bc080e7          	jalr	188(ra) # 80002cb4 <fetchstr>
    80005c00:	00054663          	bltz	a0,80005c0c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c04:	0905                	addi	s2,s2,1
    80005c06:	09a1                	addi	s3,s3,8
    80005c08:	fb491be3          	bne	s2,s4,80005bbe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0c:	10048913          	addi	s2,s1,256
    80005c10:	6088                	ld	a0,0(s1)
    80005c12:	c529                	beqz	a0,80005c5c <sys_exec+0xf8>
    kfree(argv[i]);
    80005c14:	ffffb097          	auipc	ra,0xffffb
    80005c18:	dfc080e7          	jalr	-516(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1c:	04a1                	addi	s1,s1,8
    80005c1e:	ff2499e3          	bne	s1,s2,80005c10 <sys_exec+0xac>
  return -1;
    80005c22:	597d                	li	s2,-1
    80005c24:	a82d                	j	80005c5e <sys_exec+0xfa>
      argv[i] = 0;
    80005c26:	0a8e                	slli	s5,s5,0x3
    80005c28:	fc040793          	addi	a5,s0,-64
    80005c2c:	9abe                	add	s5,s5,a5
    80005c2e:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005c32:	e4040593          	addi	a1,s0,-448
    80005c36:	f4040513          	addi	a0,s0,-192
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	178080e7          	jalr	376(ra) # 80004db2 <exec>
    80005c42:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c44:	10048993          	addi	s3,s1,256
    80005c48:	6088                	ld	a0,0(s1)
    80005c4a:	c911                	beqz	a0,80005c5e <sys_exec+0xfa>
    kfree(argv[i]);
    80005c4c:	ffffb097          	auipc	ra,0xffffb
    80005c50:	dc4080e7          	jalr	-572(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c54:	04a1                	addi	s1,s1,8
    80005c56:	ff3499e3          	bne	s1,s3,80005c48 <sys_exec+0xe4>
    80005c5a:	a011                	j	80005c5e <sys_exec+0xfa>
  return -1;
    80005c5c:	597d                	li	s2,-1
}
    80005c5e:	854a                	mv	a0,s2
    80005c60:	60be                	ld	ra,456(sp)
    80005c62:	641e                	ld	s0,448(sp)
    80005c64:	74fa                	ld	s1,440(sp)
    80005c66:	795a                	ld	s2,432(sp)
    80005c68:	79ba                	ld	s3,424(sp)
    80005c6a:	7a1a                	ld	s4,416(sp)
    80005c6c:	6afa                	ld	s5,408(sp)
    80005c6e:	6179                	addi	sp,sp,464
    80005c70:	8082                	ret

0000000080005c72 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c72:	7139                	addi	sp,sp,-64
    80005c74:	fc06                	sd	ra,56(sp)
    80005c76:	f822                	sd	s0,48(sp)
    80005c78:	f426                	sd	s1,40(sp)
    80005c7a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c7c:	ffffc097          	auipc	ra,0xffffc
    80005c80:	e56080e7          	jalr	-426(ra) # 80001ad2 <myproc>
    80005c84:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c86:	fd840593          	addi	a1,s0,-40
    80005c8a:	4501                	li	a0,0
    80005c8c:	ffffd097          	auipc	ra,0xffffd
    80005c90:	092080e7          	jalr	146(ra) # 80002d1e <argaddr>
    return -1;
    80005c94:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c96:	0e054063          	bltz	a0,80005d76 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c9a:	fc840593          	addi	a1,s0,-56
    80005c9e:	fd040513          	addi	a0,s0,-48
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	de0080e7          	jalr	-544(ra) # 80004a82 <pipealloc>
    return -1;
    80005caa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cac:	0c054563          	bltz	a0,80005d76 <sys_pipe+0x104>
  fd0 = -1;
    80005cb0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cb4:	fd043503          	ld	a0,-48(s0)
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	50a080e7          	jalr	1290(ra) # 800051c2 <fdalloc>
    80005cc0:	fca42223          	sw	a0,-60(s0)
    80005cc4:	08054c63          	bltz	a0,80005d5c <sys_pipe+0xea>
    80005cc8:	fc843503          	ld	a0,-56(s0)
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	4f6080e7          	jalr	1270(ra) # 800051c2 <fdalloc>
    80005cd4:	fca42023          	sw	a0,-64(s0)
    80005cd8:	06054863          	bltz	a0,80005d48 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cdc:	4691                	li	a3,4
    80005cde:	fc440613          	addi	a2,s0,-60
    80005ce2:	fd843583          	ld	a1,-40(s0)
    80005ce6:	68a8                	ld	a0,80(s1)
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	9c2080e7          	jalr	-1598(ra) # 800016aa <copyout>
    80005cf0:	02054063          	bltz	a0,80005d10 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cf4:	4691                	li	a3,4
    80005cf6:	fc040613          	addi	a2,s0,-64
    80005cfa:	fd843583          	ld	a1,-40(s0)
    80005cfe:	0591                	addi	a1,a1,4
    80005d00:	68a8                	ld	a0,80(s1)
    80005d02:	ffffc097          	auipc	ra,0xffffc
    80005d06:	9a8080e7          	jalr	-1624(ra) # 800016aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d0a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d0c:	06055563          	bgez	a0,80005d76 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d10:	fc442783          	lw	a5,-60(s0)
    80005d14:	07e9                	addi	a5,a5,26
    80005d16:	078e                	slli	a5,a5,0x3
    80005d18:	97a6                	add	a5,a5,s1
    80005d1a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d1e:	fc042503          	lw	a0,-64(s0)
    80005d22:	0569                	addi	a0,a0,26
    80005d24:	050e                	slli	a0,a0,0x3
    80005d26:	9526                	add	a0,a0,s1
    80005d28:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d2c:	fd043503          	ld	a0,-48(s0)
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	9fc080e7          	jalr	-1540(ra) # 8000472c <fileclose>
    fileclose(wf);
    80005d38:	fc843503          	ld	a0,-56(s0)
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	9f0080e7          	jalr	-1552(ra) # 8000472c <fileclose>
    return -1;
    80005d44:	57fd                	li	a5,-1
    80005d46:	a805                	j	80005d76 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d48:	fc442783          	lw	a5,-60(s0)
    80005d4c:	0007c863          	bltz	a5,80005d5c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d50:	01a78513          	addi	a0,a5,26
    80005d54:	050e                	slli	a0,a0,0x3
    80005d56:	9526                	add	a0,a0,s1
    80005d58:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d5c:	fd043503          	ld	a0,-48(s0)
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	9cc080e7          	jalr	-1588(ra) # 8000472c <fileclose>
    fileclose(wf);
    80005d68:	fc843503          	ld	a0,-56(s0)
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	9c0080e7          	jalr	-1600(ra) # 8000472c <fileclose>
    return -1;
    80005d74:	57fd                	li	a5,-1
}
    80005d76:	853e                	mv	a0,a5
    80005d78:	70e2                	ld	ra,56(sp)
    80005d7a:	7442                	ld	s0,48(sp)
    80005d7c:	74a2                	ld	s1,40(sp)
    80005d7e:	6121                	addi	sp,sp,64
    80005d80:	8082                	ret
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
    80005dd0:	d47fc0ef          	jal	ra,80002b16 <kerneltrap>
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
    80005e6c:	c3e080e7          	jalr	-962(ra) # 80001aa6 <cpuid>
  
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
    80005ea4:	c06080e7          	jalr	-1018(ra) # 80001aa6 <cpuid>
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
    80005ecc:	bde080e7          	jalr	-1058(ra) # 80001aa6 <cpuid>
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
    80005f3c:	668080e7          	jalr	1640(ra) # 800025a0 <wakeup>
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
    80006162:	2a8080e7          	jalr	680(ra) # 80002406 <sleep>
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
    80006230:	1da080e7          	jalr	474(ra) # 80002406 <sleep>
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
    800063a2:	202080e7          	jalr	514(ra) # 800025a0 <wakeup>
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
